#!/usr/bin/env perl -w

# Po4a::Org.pm
#
# extract and translate translatable strings from a Org documents
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

package Locale::Po4a::Org;

use 5.006;
use strict;
use warnings;

use parent qw(Locale::Po4a::TransTractor);

use Locale::Po4a::Common qw(wrap_mod dgettext);

sub initialize {
    my ( $self, %options ) = @_;

    $self->{options}{skip_keywords}   = [];
    $self->{options}{skip_properties} = [];
    $self->{options}{skip_heading}    = 0;
    $self->{options}{debug}           = 0;
    $self->{options}{verbose}         = 0;

    foreach my $opt ( keys %options ) {
        exists $self->{options}{$opt}
          or die wrap_mod( 'po4a::org', dgettext( 'po4a', 'Unknown option: %s' ), $opt );
    }

    $self->{options}{skip_heading} = $options{skip_heading};
    $self->{options}{debug}        = $options{debug};
    $self->{options}{verbose}      = $options{verbose};

    foreach my $option_name ( 'skip_keywords', 'skip_properties' ) {
        my $option = $options{$option_name} or next;
        push @{ $self->{options}{$option_name} }, split / \s+ /xsm, $option;
    }

    return;
}

sub parse {
    my $self = shift;

    $self->{blocks}    = [];
    $self->{paragraph} = undef;

    my ( $line, $ref ) = $self->shiftline();

    while ( defined $line ) {
        chomp $line;

             $self->parse_keyword( $line, $ref )
          or $self->parse_properties( $line, $ref )
          or $self->parse_small_literal_block( $line, $ref )
          or $self->parse_heading( $line, $ref )
          or $self->parse_block_begin( $line, $ref )
          or $self->parse_block_end( $line, $ref )
          or $self->parse_plain_list( $line, $ref )
          or $self->parse_table( $line, $ref )
          or $self->parse_blank_line( $line, $ref )
          or $self->parse_comment( $line, $ref )
          or $self->parse_paragraph( $line, $ref );

        ( $line, $ref ) = $self->shiftline();
    }

    $self->handle_paragraph_if_any($ref);

    return;
}

sub parse_keyword {
    my ( $self, $line, $ref ) = @_;

    $line =~ m{ \A ( [#] [+] ( [^:]+ ) : [ ]+ ) (.+) }xsm or return;
    my $prefix  = $1;
    my $name    = $2;
    my $content = $3;

    for ( @{ $self->{options}{skip_keywords} } ) {
        if ( $_ eq $name ) {
            $self->pushline("$line\n");
            return 1;
        }
    }

    $content = $self->translate( $content, $ref, "keyword $name" );
    $self->pushline("$prefix$content\n");

    return 1;
}

sub parse_properties {
    my ( $self, $line, $ref ) = @_;

    $line eq ':PROPERTIES:' or return;

    $self->pushline("$line\n");
    ( $line, $ref ) = $self->shiftline();

    while ( defined $line ) {
        chomp $line;

        if ( $line eq ':END:' ) {
            $self->pushline("$line\n");
            return 1;
        }

        $line =~ m{ ( : ( [^:]+ ) : [ ]+ ) (.+) }xsm
          or die "invalid property entry: $line\n";
        my $pre     = $1;
        my $key     = $2;
        my $content = $3;

        my $translatable = 1;
        for ( @{ $self->{options}{skip_properties} } ) {
            if ( $_ eq $key ) {
                $translatable = 0;
            }
        }

        $translatable and $content = $self->translate( $content, $ref, "property ($key)" );
        $self->pushline("$pre$content\n");
        ( $line, $ref ) = $self->shiftline();
    }

    return;
}

sub parse_small_literal_block {
    my ( $self, $line, $ref ) = @_;

    $line =~ m{ \A ( [ ]*:[ ] ) (.*) }xsm or return;
    my $pre     = $1;
    my $content = $2;

    my $newref;
    ( $line, $newref ) = $self->shiftline();

    while ( defined $line ) {
        chomp $line;

        if ( $line =~ m{ \A (?: [ ]* : [ ] ) (.*) }xsm ) {
            $content .= "\n$1";
            ( $line, $newref ) = $self->shiftline();
            next;
        }

        my $type = 'small literal example';
        $self->annotate_blocks( \$type );
        $content = $self->translate( $content, $ref, $type );
        $content =~ s/ ^ /$pre/mgxs;
        $self->pushline("$content\n");
        $self->unshiftline( $line, $newref );

        return 1;
    }

    return;
}

sub parse_heading {
    my ( $self, $line, $ref ) = @_;

    $line =~ m{ \A ( ( [*]+ ) [ ]+ ) (.+?) (?: \s+ ( : (?: [^:]+ : )+ ) )? \Z }xsm
      or return;
    my $pre     = $1;
    my $level   = $2;
    my $content = $3;
    my $tags    = $4;

    if ( $self->{options}{skip_heading} ) {
        $self->pushline("$line\n");
    } else {
        my $result = $pre . $self->translate( $content, $ref, "heading $level" );
        $tags and $result .= " $tags";
        $self->pushline("$result\n");
    }

    return 1;
}

sub parse_block_begin {
    my ( $self, $line, $ref ) = @_;

    $line =~ m{ \A [ ]* [#] [+] begin_([[:lower:]]+) ([ ]*) (.*) }ixsm
      or return;
    my $name       = $1;
    my $postspaces = $2;
    my $args       = $3;

    push @{ $self->{blocks} }, $name;
    $self->pushline("$line\n");

    return 1;
}

sub parse_block_end {
    my ( $self, $line, $ref ) = @_;

    $line =~ m{ \A [ ]* [#] [+] end_(?:[[:lower:]]+) \Z }ixsm or return;

    $self->handle_paragraph_if_any($ref);
    pop @{ $self->{blocks} };
    $self->pushline("$line\n");

    return 1;
}

sub parse_plain_list {
    my ( $self, $line, $ref ) = @_;

    $line =~ m{ \A ( ( ([-+*]) | \d+[.)] ) [ ]+ ) (.*) }xsm or return;
    my $prefix   = $1;
    my $type     = $2;
    my $itemized = $3;
    my @content  = $4;

    my $margin = q{ } x length $prefix;

    if ( $content[0] =~ m{ (.*?) ([ ]::) \Z }xsm ) {
        my $term   = $1;
        my $suffix = $2;

        my $content = $self->translate( $term, $ref, "description list term $type" );
        $self->pushline("$prefix$content$suffix\n");
        pop @content;

        if (@content) {
            my $ref = $self->parse_plain_list_following_paragraph( \@content, $margin );
            $content = $self->translate( join( "\n", @content ), $ref, "description list $type" );
            $content =~ s/ ^ /$margin/mgxs;
            $self->pushline("$content\n");
        }
    } else {
        my $ref = $self->parse_plain_list_following_paragraph( \@content, $margin );
        my $content = $self->translate( join( "\n", @content ), $ref, "plain list $type" );
        $content =~ s/ ^ /$margin/mgxs;
        $content =~ s/ \A \Q$margin\E //xsm;
        $self->pushline("$prefix$content\n");
    }

    return 1;
}

sub parse_plain_list_following_paragraph {
    my ( $self, $content, $margin ) = @_;

    my ( $line, $ref ) = $self->shiftline();
    while ( defined $line ) {
        chomp $line;

        if ( $line =~ m/ \A \Q$margin\E (.*) /xsm ) {
            push @{$content}, $1;

            ( $line, $ref ) = $self->shiftline();
        } else {
            $self->unshiftline( $line, $ref );
            last;
        }
    }

    return $ref;
}

sub parse_table {
    my ( $self, $line, $ref ) = @_;

    $line =~ m{ \A ( [ ]* [|] [ ]* ) (.*) }xsm or return;
    my $prefix = $1;
    my $cells  = $2;

    if ( $cells =~ / \A [-+|]* \Z /xsm ) {
        $self->pushline("$line\n");
    } else {
        my @cells = split / [ ]* [|] [ ]* /xsm, $cells;
        my $content = join( ' | ', map { $self->translate( $cells[$_], $ref, "cell column $_" ) } ( 0 .. $#cells ) );
        $self->pushline("$prefix$content |\n");
    }

    return 1;
}

sub parse_blank_line {
    my ( $self, $line, $ref ) = @_;

    $line =~ / \A \s* \Z /xsm or return;
    $self->handle_paragraph_if_any($ref);
    $self->pushline("\n");

    return 1;
}

sub parse_comment {
    my ( $self, $line ) = @_;

    $line =~ / \A [ ]* [#] .* /xsm or return;
    $self->pushline("$line\n");

    return 1;
}

sub parse_paragraph {
    my ( $self, $line, $ref ) = @_;

    if ( $self->{paragraph} ) {

        # continuation

        if ( $line =~ s/ \A \Q$self->{paragraph_margin}\E //xms ) {
            $self->{paragraph} .= "\n$line";
        } else {
            $line =~ m{ \A ([ ]*) (.*) }xsm or return;
            my $margin  = $1;
            my $content = $2;

            $self->{paragraph} =~ s/ ^ /$self->{paragraph_margin}/mgxs;
            $self->{paragraph} =~ s/ ^ \Q$margin\E //mgxs;
            $self->{paragraph} .= "\n$content";
            $self->{paragraph_margin} = $margin;
        }
    } else {

        # start

        $line =~ m{ \A ([ ]*) (.+) }xsm or return;
        $self->{paragraph_margin} = $1;
        $self->{paragraph}        = $2;
    }

    return 1;
}

sub handle_paragraph_if_any {
    my ( $self, $ref ) = @_;

    $self->{paragraph} or return;
    my $type = 'paragraph';
    $self->annotate_blocks( \$type );

    my $wrap         = 1;
    my @nowrap_names = qw(src example);
  WRAP:
    for my $block ( @{ $self->{blocks} } ) {
        for my $nowrap_name (@nowrap_names) {
            if ( lc($block) eq $nowrap_name ) {
                undef $wrap;
                last WRAP;
            }
        }
    }

    my $content = $self->translate( $self->{paragraph}, $ref, $type, wrap => $wrap );
    $content =~ s/ ^ /$self->{paragraph_margin}/mgxs;
    $self->pushline("$content\n");

    undef $self->{paragraph};
    undef $self->{paragraph_margin};

    return;
}

sub annotate_blocks {
    my ( $self, $type ) = @_;

    if ( @{ $self->{blocks} } ) {
        my $blocks = join q{/}, @{ $self->{blocks} };
        ${$type} .= " in $blocks";
    }

    return;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Locale::Po4a::Org - convert Org documents from/to PO files.

=head1 SYNOPSIS

 [type:org] /path/to/master.org              \
        $lang:/path/to/translation.$lang.org \
        opt:"                                \
        --option skip_keywords='             \
            include                          \
            export_file_name                 \
            link'                            \
        --option skip_properties='           \
            copying                          \
            NOBLOCKING                       \
            ORDERED'"

=head1 DESCRIPTION

The po4a (PO for anything) project goal is to ease translations (and
more interestingly, the maintenance of translations) using gettext
tools on areas where they were not expected like documentation.

C<Locale::Po4a::Org> is a module to help the translation of
documentation in the Org format, used by the L<Org
Mode|https://orgmode.org/>.

=head1 CONFIGURATION

=over

=item B<skip_keywords>

Space-separated list of keywords which won't be translated.

=item B<skip_properties>

Space-separated list of properties which won't be translated.

=item B<skip_heading>

If this is a true value, skip translating headings.  When your
translation is converted to Texinfo format, the translation of
headings can cause node names to become bizarre.  This option prevents
that.

=back

=head1 STATUS OF THIS MODULE

This module is in an early stage of development.  It is tested
successfully on simple Org files, such as the L<Org Mode Compact
Guide|https://orgmode.org/guide/>.  However it does not support the
full L<Org syntax|https://orgmode.org/worg/org-syntax.html>; footnotes
and nested plain lists cannot currently be parsed, for example.

=head1 SEE ALSO

L<Locale::Po4a::TransTractor(3pm)>, L<po4a(7)|po4a.7>

=head1 AUTHORS

 gemmaro <gemmaro.dev@gmail.com>

=head1 COPYRIGHT AND LICENSE

 Copyright © 2024 gemmaro.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL v2.0 or later (see the F<COPYING> file).
