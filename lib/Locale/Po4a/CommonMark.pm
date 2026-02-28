#!/usr/bin/env perl -w

# Po4a::CommonMark.pm
#
# extract and translate translatable strings from a CommonMark documents
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#
########################################################################

package Locale::Po4a::CommonMark;

use 5.006;
use strict;
use warnings;

use parent qw(Locale::Po4a::TransTractor Locale::Po4a::YamlFrontMatter);

use CommonMark           qw(:node :event :list :delim);
use Locale::Po4a::Common qw(wrap_mod dgettext);

use constant {
    SKIP_NODE_TYPES => [

        # Not appeared as type in PO
        CommonMark::NODE_DOCUMENT,

        # untranslatable
        CommonMark::NODE_THEMATIC_BREAK,
        CommonMark::NODE_SOFTBREAK,
        CommonMark::NODE_LINEBREAK,

        # inlines
        CommonMark::NODE_TEXT,
        CommonMark::NODE_CODE,
        CommonMark::NODE_HTML_INLINE,
        CommonMark::NODE_CUSTOM_INLINE,
        CommonMark::NODE_EMPH,
        CommonMark::NODE_STRONG,
        CommonMark::NODE_LINK,
        CommonMark::NODE_IMAGE,
    ],

    # Nested blocks indirectly has inlines, and directly has other
    # blocks.  Inline content blocks directly has inlines.  Literal
    # blocks has its literal.
    NESTED_BLOCK_NODE_TYPES => [
        CommonMark::NODE_BLOCK_QUOTE, CommonMark::NODE_LIST,
        CommonMark::NODE_ITEM
    ],
    INLINE_CONTENT_BLOCK_NODE_TYPES =>
      [ CommonMark::NODE_PARAGRAPH, CommonMark::NODE_HEADING ],
    LITERAL_BLOCK_NODE_TYPES =>
      [ CommonMark::NODE_CODE_BLOCK, CommonMark::NODE_HTML_BLOCK ],
};

sub initialize {
    my ( $self, %options ) = @_;
    $self->{_commonmark_options}{neverwrap}       = $options{neverwrap};
    $self->{_commonmark_options}{skip_code_block} = $options{skip_code_block};
    $self->{_commonmark_options}{unsafe}          = $options{unsafe};
    $self->{_commonmark_options}{yaml_metadata}   = $options{yaml_metadata};
    $self->{_commonmark_options}{yfm_skip_array}  = $options{yfm_skip_array};
    $self->{_commonmark_options}{yfm_lenient}     = $options{yfm_lenient};
    $self->{_commonmark_options}{yfm_keys} =
      $self->parse_comma_separated_option( $options{yfm_keys} );
    $self->{_commonmark_options}{yfm_paths} =
      $self->parse_comma_separated_option( $options{yfm_paths} );
    return $self->SUPER::initialize;
}

sub parse {
    my $self = shift;

    $self->debug
      and warn wrap_mod(
        'po4a::commonmark',
        dgettext(
            'po4a', "Version information of libcmark: %s (compile time: %s)",
        ),
        CommonMark->version_string,
        CommonMark->compile_time_version_string,
      );

    my $document = $self->_slurp_and_parse_document;
    my $iterator = $document->iterator;
    while ( my ( $event_type, $node ) = $iterator->next ) {
        grep { $node->get_type == $_ } @{ (SKIP_NODE_TYPES) } and next;
        if ( grep { $node->get_type == $_ } @{ (NESTED_BLOCK_NODE_TYPES) } ) {
            $self->_update_container_stack(
                { event_type => $event_type, node => $node } );
        } elsif ( grep { $node->get_type == $_ }
            @{ (INLINE_CONTENT_BLOCK_NODE_TYPES) } )
        {
            my $line = $self->_update_container_stack(
                { event_type => $event_type, node => $node } );
            $event_type == CommonMark::EVENT_ENTER and next;
            $event_type == CommonMark::EVENT_EXIT or die "unreachable";
            $self->_translate_inline_content_block(
                {
                    node       => $node,
                    translator => sub {
                        my $string = shift;

                        return $self->_translate(
                            {
                                string => $string,
                                ref    => "$self->{_filename}:$line",
                                type   => $self->_generate_type($node),
                                wrap   => 0,
                            }
                        );
                    }
                }
            );
        } elsif ( grep { $node->get_type == $_ }
            @{ (LITERAL_BLOCK_NODE_TYPES) } )
        {
            (        $node->get_type == CommonMark::NODE_CODE_BLOCK
                  && $self->{_commonmark_options}{skip_code_block} )
              and next;
            my $line = $node->get_start_line;
            $node->set_literal(
                $self->_translate(
                    {
                        string => $node->get_literal,
                        ref    => "$self->{_filename}:$line",
                        type   => $self->_generate_type($node),
                        wrap   => 0,
                    }
                )
            );
        } else {
            die "unreachable";
        }
    }
    $self->pushline( $document->render_commonmark( $self->_render_options ) );
    return;
}

# Line wrapping can be done with the C<neverwrap> option, and it
# should work well.  Below is why the L<Text::WrapI18N> library cannot
# be used for this.
#
# In short, using that library (via the C<wrap> option of C<translate>
# subroutine) alters parsing behavior.  As you can see, this module
# renders and parses fragments for translation, and that reflow can
# change block nodes (say, paragraphs) and thereby affect how the
# parser interprets the text.  For example, consider the following
# paragraph:
#
#  [Entity references](@) consist of `&` + any of the valid
#  HTML5 entity names + `;`.
#
# This contains C<+> character.  Since list can be introduced with
# C<+>, wrapping it as below would cause the latter two lines to be
# interpreted as list items, which is not the intended result.
#
#  [Entity references](@) consist of `&`
#  + any of the valid HTML5 entity names
#  + `;`.
#
sub _translate_inline_content_block {
    my ( $self, $args ) = @_;
    my $node       = $args->{node};
    my $translator = $args->{translator};

    my %kept_attributes;
    $node->get_type == CommonMark::NODE_HEADER
      and $kept_attributes{level} = $node->get_header_level;

    # By unwrapping some block nodes and rewrapping them as paragraph
    # nodes, the resulting strings to be translated become simpler,
    # for instance, they no longer include header prefixes.
    my @children;
    my $current = $node->first_child;
    while ($current) {
        push @children, $current;
        $current = $current->next;
    }

    # Embed the translated fragment document into the main abstract
    # syntax tree.
    my $paragraph = CommonMark->parse_document(
        $translator->(
            CommonMark->create_paragraph( children => \@children )
              ->render_commonmark( $self->_render_options )
        )
    )->first_child;
    $paragraph->next
      and die wrap_mod(
        'po4a::commonmark',
        dgettext(
            'po4a',
            "Unexpectedly found two or more blocks.  Consider using an addendum if you're truly adding extra content."
        )
      );
    my $type = $node->get_type_string;
    $paragraph->get_type == CommonMark::NODE_PARAGRAPH
      or die wrap_mod( 'po4a::commonmark',
        dgettext( 'po4a', "Unexpected node type %s, expecting paragraph." ),
        $type );
    undef @children;    # recycle
    $current = $paragraph->first_child;
    while ($current) {
        push @children, $current;
        $current = $current->next;
    }
    my $method = "create_$type";
    $node->replace(
        CommonMark->$method( %kept_attributes, children => \@children ) );
    return;
}

sub _render_options {
    my $self   = shift;
    my $option = CommonMark::OPT_DEFAULT;
    $self->{_commonmark_options}{unsafe}
      and $option |= CommonMark::OPT_UNSAFE;
    $self->{_commonmark_options}{neverwrap}
      or $option |= CommonMark::OPT_NOBREAKS;
    return $option;
}

sub _generate_type {
    my ( $self, $node ) = @_;

    return join(
        " / ",
        map { _generate_single_type($_) } (
            @{ $self->{_container_stack} },
            _node_info_for_generating_type($node)
        )
    );
}

sub _generate_single_type {
    my $args         = shift;
    my $type         = $args->{type};
    my $type_string  = $args->{type_string};
    my $header_level = $args->{header_level};
    my $list_type    = $args->{list_type};
    my $list_delim   = $args->{list_delim};
    my $fence_info   = $args->{fence_info};

    if ( $type == CommonMark::NODE_LIST ) {
        if ( $list_type == CommonMark::NO_LIST ) {    # nop
        } elsif ( $list_type == CommonMark::BULLET_LIST ) {
            $type_string = "bullet list";
        } elsif ( $list_type == CommonMark::ORDERED_LIST ) {
            $type_string = "ordered list";
        } else {
            die "unreachable: $list_type";
        }

        if ( $list_delim == CommonMark::NO_DELIM ) {    # nop
        } elsif ( $list_delim == CommonMark::PERIOD_DELIM ) {
            $type_string .= " (period delim)";
        } elsif ( $list_delim == CommonMark::PAREN_DELIM ) {
            $type_string .= " (paren delim)";
        } else {
            die "unreachable";
        }
    } elsif ( $type == CommonMark::NODE_HEADING ) {
        $type_string .= $header_level;
    } elsif ( $type == CommonMark::NODE_CODE_BLOCK ) {
        $fence_info and $type_string .= " ($fence_info)";
    }

    return $type_string;
}

sub _translate {
    my ( $self, $args ) = @_;
    my $string = $args->{string};
    my $ref    = $args->{ref};
    my $type   = $args->{type};
    my $wrap   = $args->{wrap};

    $string =~ m/(.*?)(\n*)\Z/s or die "unreachable";
    my $target = $1;
    my $suffix = $2;

    return $self->translate( $target, $ref, $type, wrap => $wrap ) . $suffix;
}

# Keep track of the container block node stack so that the generated
# PO file includes informative type comments.
sub _update_container_stack {
    my ( $self, $args ) = @_;
    my $event_type = $args->{event_type};
    my $node       = $args->{node};

    if ( $event_type == CommonMark::EVENT_ENTER ) {
        push @{ $self->{_container_stack} },
          {
            line => $node->get_start_line,
            %{ _node_info_for_generating_type($node) },
          };
    } elsif ( $event_type == CommonMark::EVENT_EXIT ) {
        my $container = pop( @{ $self->{_container_stack} } );
        $container->{type} == $node->get_type or die "unreachable";
        return $container->{line};
    } else {
        die "unreachable";
    }
    return;
}

sub _node_info_for_generating_type {
    my $node = shift;

    return {
        type         => $node->get_type,
        type_string  => $node->get_type_string,
        header_level => $node->get_header_level,
        list_type    => $node->get_list_type,
        list_delim   => $node->get_list_delim,
        fence_info   => $node->get_fence_info,
    };
}

sub _slurp_and_parse_document {
    my $self = shift;

    my ( $line, $ref );
    if ( $self->{_commonmark_options}{yaml_metadata} ) {
        ( $line, $ref ) = $self->shiftline;
        chomp $line;
        ( defined $line && $line eq "---" )
          or die wrap_mod(
            'po4a::commonmark',
            dgettext(
                'po4a',
                'The first line must be triple hyphenes if the yaml_metadata option is enabled.',
            )
          );
        $self->parse_yaml_front_matter(
            $ref,
            {
                keys       => $self->{_commonmark_options}{yfm_keys},
                skip_array => $self->{_commonmark_options}{yfm_skip_array},
                paths      => $self->{_commonmark_options}{yfm_paths},
                lenient    => $self->{_commonmark_options}{yfm_lenient},
            }
        );
    }
    while ( ( $line, $ref ) = $self->shiftline and defined $line ) {
        my $chomped = $line;
        chomp $chomped;
        if ( $chomped =~ /\A\s*\Z/ ) {
            $self->pushline($line);
        } else {
            $self->unshiftline( $line, $ref );
            last;
        }
    }
    my $parser = CommonMark::Parser->new;
    while ( ( $line, $ref ) = $self->shiftline and defined $line ) {
        $parser->feed($line);

        # Record filename once.
        ( $self->{_filename} || !$ref ) and next;
        $ref =~ m/(.+?):\d+\Z/;
        $self->{_filename} = $1;
    }
    return $parser->finish;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Locale::Po4a::CommonMark - convert CommonMark documents from/to PO files.

=head1 SYNOPSIS

  [type:CommonMark] /path/to/master.md $lang:/path/to/translation.$lang.md

=head1 DESCRIPTION

The po4a (PO for anything) project goal is to ease translations (and
more interestingly, the maintenance of translations) using gettext
tools on areas where they were not expected like documentation.

L<Locale::Po4a::CommonMark> is a module to help the translation of
documentation in the L<CommonMark|https://commonmark.org/>.

In some cases, this format module can be used in place of the
L<Locale::Po4a::Text> module with the C<markdown> option enabled.
However, please note that CommonMark may not provide certain syntax
features you need, such as tables or footnotes, and this module does
not support them either.

=head1 CONFIGURATION

Some configuration options can be passed using C<option>.  Enabling
the C<debug> option causes the program to display libcmark version
information, which makes diagnosing issues easier by providing more
detailed context.

=over

=item C<neverwrap>

Prevent po4a from wrapping any lines. This means that every content is
handled verbatim, even simple paragraphs.  Disabled by default.
Internally, translates softbreak nodes in block nodes to spaces.  See
also the equivalent option by the L<Locale::Po4a::Text> module.

=item C<skip_code_block>

Code blocks are excluded from translation.  This option is disabled by
default.

=item C<yaml_metadata>

Enable the YAML metadata (YAML front matter) feature.  Disabled by
default.  It follows the L<lcmark's YAML
Metadata|https://github.com/jgm/lcmark/blob/debdae3235cf97312aa5d102bdcf7db062f4782f/README.md#yaml-metadata>
feature.  If this option is enabled, the C<yfm_keys>, C<yfm_lenient>,
C<yfm_paths>, and C<yfm_skip_array> options become available.  Please
refer to the L<Locale::Po4a::Text>.

=item C<unsafe>

Enable the unsafe option.  Disabled by default, so potentially
dangerous links are scrubbed.  Please be aware when you use this
option and see also the L<Security
section|https://github.com/commonmark/cmark/tree/7c3877921c69fc02f2ab076a71efea6899b481c0?tab=readme-ov-file#security>
in the cmark documentation.

=back

=head1 STATUS OF THIS MODULE

This module is in an early stage of development.  It has been tested
successfully against the CommonMark specification document, as far as
we know, but it may not handle more complex real-world documents yet.
In rare cases, libcmark may diverge from the specification or
something; if you encounter such a discrepancy, please report it to
the appropriate projects (for example, cmark or the Perl CommonMark
module).

=head1 CAVEATS

=over

=item The CommonMark specification

When translating the CommonMark specification file F<spec.txt>, take
care with character escaping in link markups.  If you pass the file
unchanged, extra normalization or escaping may occur.  For example, a
link-like token such as C<[foo]> (which is a reference link and with
no link destination) can be converted to C<\[foo\]> in the PO files
(and the generated translation files).

This happens because the source lacks explicit link definitions and
the parser generates them on the fly.  Please see the
F<tools/make_spec.lua> of the CommonMark specification repository for
implementation details.

=back

=head1 SEE ALSO

L<CommonMark>, L<Locale::Po4a::Text(3pm)>,
L<Locale::Po4a::TransTractor(3pm)>, L<po4a(7)|po4a.7>

=head1 AUTHORS

 gemmaro <gemmaro.dev@gmail.com>

=head1 COPYRIGHT AND LICENSE

 Copyright © 2026 gemmaro.

This program is free software; you may redistribute it and/or modify
it under the terms of GPL v2.0 or later (see the F<COPYING> file).
