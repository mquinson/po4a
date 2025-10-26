#!/usr/bin/perl -w

# Copyright © 2025 Patrice Dumas <pertusus@free.fr>
#
# This file is part of po4a.
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
# along with po4a; if not, write to the Free Software
# Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#
########################################################################
#
# NOTE _convert, _text and _handle_source_marks are originally derived
# from GNU Texinfo tta/swig/perl/parse_refold.pl, mainly for the
# handling of source marks.

# TODO
# * use translations to change file names, for example @image file
#   name?
# * for brace no_paragraph command, the whole command is translated
#   it could be each of the arguments.
# * replace language argument of @documentlanguage
#   Using $self->{TT}{po_in}->{lang}
# * add @documentlanguage if there was none
#   Using $self->{TT}{po_in}->{lang}
# * do something relevant for @setfilename.  Maybe simply remove.

# PERL5LIB=../../../lib/ perl ../../../po4a-normalize -f texinfoparser ${file}.texi  -l ${file}.norm -p ${file}.pot
# PERL5LIB=../../../lib/ perl ../../../po4a-normalize -C -f texinfoparser ${file}.texi -l ${file}.trans -p ${file}.po
# for tests of includes: -o include_directories=../xhtml
#
# for file in comments longmenu partialmenus tindex commandsinpara conditionals texifeatures macrovalue linemacro verbatimignore topinifnottex topinifnotdocbook invalidlineecount; do PERL5LIB=../../../lib/ perl ../../../po4a-normalize -f texinfoparser ${file}.texi  -l ${file}.norm -p ${file}.pot ; PERL5LIB=../../../lib/ perl ../../../po4a-normalize -C -f texinfoparser ${file}.texi -l ${file}.trans -p ${file}.po ; done
#
# for file in tinclude verbatiminclude; do PERL5LIB=../../../lib/ perl ../../../po4a-normalize -f texinfoparser ${file}.texi  -l ${file}.norm -p ${file}.pot -o include_directories=../xhtml ; PERL5LIB=../../../lib/ perl ../../../po4a-normalize -C -f texinfoparser ${file}.texi -l ${file}.trans -p ${file}.po -o include_directories=../xhtml ; done

=encoding UTF-8

=head1 NAME

Locale::Po4a::TexinfoParser - convert Texinfo documents and derivates from/to PO files

=head1 DESCRIPTION

The po4a (PO for anything) project goal is to ease translations (and more
interestingly, the maintenance of translations) using gettext tools on
areas where they were not expected like documentation.

Locale::Po4a::TexinfoParser is a module to help the translation of Texinfo documents into
other [human] languages.

This module uses the GNU Texinfo Parser and Texinfo Tree reader to extract strings and paragraphs to translate.

=begin comment

Only the comments starting with 'TRANSLATORS' are added to the PO files to guide the translators.

=end comment

=head1 STATUS OF THIS MODULE

This module is still beta.

=head1 OPTIONS ACCEPTED BY THIS MODULE

These are this module's particular options:

=over 4

=item include_directories

Colon-separated list of Texinfo include directories.

=item no-warn

Do not warn about the current state of this module.

=back

=head1 SEE ALSO

L<Locale::Po4a::Texinfo(3pm)|Locale::Po4a::Texinfo>,
L<Locale::Po4a::TransTractor(3pm)|Locale::Po4a::TransTractor>,
L<po4a(7)|po4a.7>

=head1 AUTHORS

 Patrice Dumas <pertusus@free.fr>.

=head1 COPYRIGHT AND LICENSE

Copyright © 2025 Patrice Dumas <pertusus@free.fr>.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL v2.0 or later (see the COPYING file).

=cut

package Locale::Po4a::TexinfoParser;

use 5.16.0;
use strict;
use warnings;

use parent qw(Locale::Po4a::TransTractor);

use Carp qw(confess);

use File::Basename qw(fileparse);
use File::Spec;

use Locale::Po4a::Common qw(wrap_mod gettext);

# This is temporary, to be able to find the Texinfo SWIG interface.  Once
# the release with this interface is common enough, it should not be useful
# anymore.
BEGIN {
    my $home = $ENV{'HOME'};
    die if ( !defined($home) );
    my $t2a_builddir = join( '/', ( $home, 'src', 'texinfo', 'tta' ) );

    # for Texinfo.pm
    unshift @INC, join( '/', ( $t2a_builddir, 'swig', 'perl' ) );

    # for XS
    unshift @INC, join( '/', ( $t2a_builddir, 'swig', 'perl', '.libs' ) );
}

use Texinfo;

my $debug = 0;

my @include_directories;

my $curdir = File::Spec->curdir();

#$debug = 1;

my %additional_translated_line_commands;
foreach my $translated_line_cmdname (
    'xrefname',   'everyheading',   'everyfooting', 'evenheading', 'evenfooting', 'oddheading',
    'oddfooting', 'shorttitlepage', 'settitle',     'dircategory', 'c',           'comment'
  )
{
    $additional_translated_line_commands{$translated_line_cmdname} = 1;
}

# Other Parser options are not very interesting.  File name encoding
# related such as INPUT_FILE_NAME_ENCODING may be relevant.  Maybe also, but
# in very rare cases, clearing/adding expanded formats.
sub initialize {
    my $self    = shift;
    my %options = @_;

    Texinfo::setup( 0, $Texinfo::txi_interpreter_use_no_interpreter );

    $self->{options}{'include_directories'} = '';

    # Set in TeX.pm for the original Texinfo parser
    $self->{options}{'no-warn'} = 0;

    foreach my $opt ( keys %options ) {
        if ( $options{$opt} ) {
            die wrap_mod( "po4a::texinfo", dgettext( "po4a", "Unknown option: %s" ), $opt )
              unless exists $self->{options}{$opt};
            $self->{options}{$opt} = $options{$opt};
        }
    }
    if ( defined( $options{'include_directories'} ) and $options{'include_directories'} ne '' ) {
        foreach ( split( /:/, $options{'include_directories'} ) ) {
            push @include_directories, $_;
        }
    }
}

sub read ($$$$) {
    my ( $self, $filename, $refname, $charset ) = @_;

    push @{ $self->{file_charsets}{infile} }, [ $filename, $charset ];
}

sub parse {
    my $self = shift;

    print STDERR "The TexinfoParser module of po4a is not ready for production use.\n"
      . "(use -o no-warn to remove this message)\n"
      unless $self->{options}{'no-warn'};
    map { $self->parse_file($_) } @{ $self->{file_charsets}{infile} };
}

sub _output_txi_error_messages {
    my $error_messages_list = shift;

    my $msg_number = Texinfo::messages_list_messages_number($error_messages_list);
    if ( $msg_number > 0 ) {
        for ( my $i = 0 ; $i < $msg_number ; $i++ ) {
            my $error_msg     = Texinfo::messages_list_message_by_index( $error_messages_list, $i );
            my $formatted_msg = $error_msg->swig_formatted_get();
            if ( $error_msg->swig_continuation_get() ) {
                warn($formatted_msg);
            } else {
                chomp $formatted_msg;
                warn( wrap_mod( "po4a::texinfo", $formatted_msg ) );
            }
        }
    }
    Texinfo::destroy_error_messages_list($error_messages_list);
}

# SWIG always uses sv_setpvn returning bytes and C encodes in UTF-8, so we
# convert to Perl characters by decoding from UTF-8
sub _decode($) {
    my $text = shift;
    return Encode::decode( 'UTF-8', $text );
}

sub _current_smark($) {
    my $current_smark = shift;

    return defined($current_smark) ? "$current_smark->[0]:$current_smark->[1]" : '-';
}

sub _text($$$;$) {
    my ( $text, $from, $element_type, $to ) = @_;

    my $result = '';

    $from = 0 if ( !defined($from) );

    if ( $element_type eq 'bracketed_linemacro_arg' ) {

        # recreate the text the source marks are relative too
        $text = '{' . $text . '}';
    }

    my $length;
    if ( defined($to) ) {
        $length = $to - $from;
    }

    if ( defined($length) ) {
        $result .= substr( $text, $from, $length );
    } else {
        $result .= substr( $text, $from );
    }
    return $result;
}

sub _translation_begin_info($$$$) {
    my $inputs           = shift;
    my $wrap             = shift;
    my $translation_type = shift;
    my $result           = shift;

    my $to_translate = '';
    my $translation_info =
      [ \$to_translate, "$inputs->[-1]->[0]:$inputs->[-1]->[1]", $wrap, $translation_type, $result ];
    return ( $translation_info, $translation_info->[0] );
}

sub _translation_end($$$) {
    my $self             = shift;
    my $translation_info = shift;
    my $result           = shift;

    my ( $to_translate_reference, $ref, $wrap, $translation_type, $previous_result ) = @$translation_info;
    my $translated;
    if ( $to_translate_reference ne $result ) {
        warn "BUG: $translation_type $ref text $to_translate_reference != result $result\n";
    }
    if ($debug) {
        print STDERR "TT: $ref, $translation_type, $wrap!!$$to_translate_reference!!\n";
    }
    my $trailing_eol;
    if ( $$to_translate_reference =~ /\S/ ) {

        # always remove trailing end of line from translated strings
        if ( $$to_translate_reference =~ s/(\n)$// ) {
            $trailing_eol = $1;
        }
        $translated = $self->translate( $$to_translate_reference, $ref, $translation_type, 'wrap' => $wrap );
    } else {
        $translated = $$to_translate_reference;
    }
    $result = $previous_result;
    $$result .= $translated;
    if ( defined($trailing_eol) ) {
        $$result .= $trailing_eol;
    }
    return $result;
}

sub _handle_source_marks($$$$$$$$) {
    my ( $self, $result, $element, $document, $element_type, $inputs, $translation_info, $current_smark ) = @_;

    my $last_position;
    my $smark_e_text;
    my $source_marks_nr = Texinfo::element_source_marks_number($element);
    if ($source_marks_nr) {
        if ($debug) {
            print STDERR "_SOURCEMARKS ($source_marks_nr)\n";
        }
        for ( my $i = 0 ; $i < $source_marks_nr ; $i++ ) {
            my $source_mark         = Texinfo::element_get_source_mark( $element, $i );
            my $source_mark_counter = $source_mark->swig_counter_get();
            my $source_mark_type    = $source_mark->swig_type_get();

            if ($current_smark) {
                if (    $source_mark_counter == $current_smark->[1]
                    and $current_smark->[0] eq $source_mark_type )
                {
                    $last_position = $source_mark->swig_position_get();
                    if ($debug) {
                        print STDERR "END_SMARK($i): $source_mark_type;" . "c:$source_mark_counter;p:$last_position\n";
                    }
                    $current_smark = undef;
                }
            }

            my $source_mark_status = $source_mark->swig_status_get();

            my $source_mark_position = $source_mark->swig_position_get();
            if ( defined($source_mark_position) and $source_mark_position > 0 ) {
                if ( !$current_smark ) {

                    # source_mark_position > 0 only in text elements
                    my $text        = _decode( Texinfo::element_text($element) );
                    my $text_result = _text( $text, $last_position, $element_type, $source_mark_position );
                    if ($debug) {
                        print STDERR "TEXT_SMARK($i) "
                          . ( defined($last_position) ? $last_position : '-' )
                          . ":$source_mark_position"
                          . " '$text_result'\n";

                        #."\n";
                    }
                    $$result .= $text_result;

                    # there may be multiple end of line in macro_call_arg_text
                    my $count = ( $text_result =~ tr/\n// );
                    $inputs->[-1]->[1] += $count;
                }
            }
            $last_position = $source_mark_position;

            # value expansion has both a line and an element, the line
            # is the flag name, what we are interested in is the element
            my $source_mark_element = $source_mark->swig_element_get();
            if ( defined($source_mark_element) ) {
                if ($debug) {
                    print STDERR "_E_SMARK($i): "

                      #.Texinfo::tree_print_details($source_mark_element)."\n";
                      . "\n";
                }

                my $translation_type;
                if ( $source_mark_type == $Texinfo::SM_type_ignored_conditional_block
                    and !defined($translation_info) )
                {
                    # translate @if* ignored block
                    $translation_type = '@' . Texinfo::element_cmdname($source_mark_element);
                    ( $translation_info, $result ) = _translation_begin_info( $inputs, 0, $translation_type, $result );
                }
                ( $result, $current_smark ) =
                  _convert( $self, $result, $source_mark_element, $document, $inputs, $translation_info,
                    $current_smark );
                if ( defined($translation_type) ) {
                    $result           = _translation_end( $self, $translation_info, $result );
                    $translation_info = undef;
                }
            } elsif ( !$current_smark ) {
                if ( $source_mark_type == $Texinfo::SM_type_delcomment ) {
                    $$result .= "\x{7F}";
                } elsif ( $source_mark_type == $Texinfo::SM_type_macro_arg_escape_backslash ) {
                    $$result .= '\\';
                }
                my $source_mark_line = _decode( $source_mark->swig_line_get() );
                my $translation_type;
                if ( defined($source_mark_line) ) {
                    if ( $source_mark_type == $Texinfo::SM_type_delcomment
                        and !defined($translation_info) )
                    {
                        # translate DEL comment
                        $translation_type = 'DEL comment';
                        ( $translation_info, $result ) =
                          _translation_begin_info( $inputs, 0, $translation_type, $result );
                    }
                    $$result .= $source_mark_line;
                    $inputs->[-1]->[1] += 1 if ( $source_mark_line =~ /\n/ );
                    if ( defined($translation_type) ) {
                        $result           = _translation_end( $self, $translation_info, $result );
                        $translation_info = undef;
                    }
                } elsif ( $source_mark_type == $Texinfo::SM_type_defline_continuation ) {
                    $$result .= "@\n";
                    $inputs->[-1]->[1] += 1;
                }
            }
            if ( $source_mark_type eq $Texinfo::SM_type_include ) {
                if ( $source_mark_status eq $Texinfo::SM_status_start ) {
                    my $file_name = Texinfo::element_attribute_string( $source_mark_element, 'text_arg' );
                    if ($debug) {
                        print STDERR "INCLUDE($i) '$file_name' "
                          . "c:$source_mark_counter;s_m:"
                          . _current_smark($current_smark) . "\n";
                    }
                    my $result_text = '';
                    $result = \$result_text;
                    push @$inputs, [ $file_name, 1, $result, $source_mark_counter, $current_smark ];
                    $current_smark = undef;
                } elsif ( $source_mark_status eq $Texinfo::SM_status_end ) {
                    my $previous_input = pop @$inputs;
                    if ($debug) {
                        print STDERR "END_INCLUDE($i) c:$source_mark_counter"
                          . "|$previous_input->[3];s_m:"
                          . _current_smark( $inputs->[-1]->[4] ) . " \n";
                    }

                    #_write_output($previous_input);
                    $current_smark = $previous_input->[4];
                    $result        = $inputs->[-1]->[2];
                }
            } elsif ( !$current_smark ) {
                if (
                    $source_mark_status eq $Texinfo::SM_status_start

                    # expanded conditional has a start and an end, but the
                    # tree within is the expanded tree and should not be skipped
                    and $source_mark_type != $Texinfo::SM_type_expanded_conditional_command
                  )
                {
                    if ($debug) {
                        print STDERR "START_SMARK($i): $source_mark_type;" . "c:$source_mark_counter\n";
                    }
                    $current_smark = [ $source_mark_type, $source_mark_counter ];
                }
            }
        }
        if ($debug) {
            print STDERR "_OUTSMARKS [p:"
              . ( defined($last_position) ? $last_position : 0 ) . "] "
              . _current_smark($current_smark) . "\n";
        }
    }
    return $result, $last_position, $current_smark;
}

sub _arg_parent_element($) {
    my $element = shift;

    my $parent = Texinfo::element_parent($element);
    return undef if ( !defined($parent) );
    my $parent_type = Texinfo::element_type($parent);
    if ( defined($parent_type) and $parent_type eq 'arguments_line' ) {
        $parent = Texinfo::element_parent($parent);
        return undef if ( !defined($parent) );
    }
    my $cmdname = Texinfo::element_cmdname($parent);
    return undef if ( !defined($cmdname) );
    return $parent;
}

sub _translated_line_arg($) {
    my $element = shift;

    my $parent = _arg_parent_element($element);
    return undef if ( !defined($parent) );
    my $cmdname = Texinfo::element_cmdname($parent);
    if (   Texinfo::element_command_is_formatted_line($parent)
        or Texinfo::element_command_is_index_entry_command($parent)
        or exists( $additional_translated_line_commands{$cmdname} ) )
    {
        return $cmdname;
    }
    return undef;
}

sub _translated_block_line_arg($) {
    my $element = shift;

    my $parent = _arg_parent_element($element);
    return undef if ( !defined($parent) );
    my $cmdname = Texinfo::element_cmdname($parent);

    # @example is not there, as it is likely that @example arguments do
    # not need to be translated.
    if (   $cmdname eq 'quotation'
        or $cmdname eq 'smallquotation'
        or $cmdname eq 'float'
        or $cmdname eq 'cartouche' )
    {
        return $cmdname;
    } elsif ( $cmdname eq 'multitable' ) {
        my $elements_nr = Texinfo::element_children_number($element);
        if ( $elements_nr > 0 ) {
            my $first_element     = Texinfo::element_get_child( $element, 0 );
            my $first_elt_cmdname = Texinfo::element_cmdname($first_element);
            if ( defined($first_elt_cmdname)
                and $first_elt_cmdname eq 'columnfractions' )
            {
                return undef;
            }
        }
        return $cmdname;
    } elsif ( $cmdname eq 'itemize' ) {

        # text, not command, as itemize argument
        my $argument_command = Texinfo::block_line_argument_command($element);
        if ( !defined($argument_command) ) {
            return $cmdname;
        }
    }
    return undef;
}

sub _translated_def_arg($) {
    my $element = shift;

    my $parent = Texinfo::element_parent($element);
    return undef if ( !defined($parent) );

    my $def_cmdname = Texinfo::element_attribute_string( $parent, 'original_def_cmdname' );
    return $def_cmdname;
}

sub _print_translation_stack($) {
    my $translation_stack = shift;

    my @translation_on_stacks;
    foreach my $translation_on_stack (@$translation_stack) {
        if ( !defined($translation_on_stack) ) {
            push @translation_on_stacks, '-';
        } else {

            #push @translation_on_stacks, '('.join(',', @$translation_on_stack).')';
            push @translation_on_stacks, $translation_on_stack;
        }
    }
    return join( '', @translation_on_stacks );
}

sub _convert($$$$$;$$);

# NOTE interfaces of Locale::Po4a::TransTractor used:
# $self->translate($string, $ref, $type)
# type is something like line, paragraph, @node, can also hold argument number.
# In practice use @-command name, or element type and parent @-command name.
# $ref should be $file:$line_nr
# $self->pushline($text);

# input is a stack of input information.  An input information is
# an array reference with 5 elements:
#   file_name, line_number, result_text_accumulation_reference,
#   include_file_source_mark_counter, current_source_mark
# current_source_mark is an array reference with 2 elements, which
# contains the information about the current source mark expansion, if any:
#   source_mark_type, source_mark_counter
sub _convert($$$$$;$$) {
    my ( $self, $result, $tree, $document, $inputs, $translation_info, $current_smark ) = @_;

    if ( ref($inputs) ne 'ARRAY' or ref( $inputs->[-1] ) ne 'ARRAY' ) {
        confess();
    }
    if ($debug) {
        print STDERR "_CONVERT: " . _current_smark($current_smark) . "\n";
    }
    my $reader = Texinfo::new_reader( $tree, $document );

    my $args_stack         = [];
    my $translations_stack = [];
    my $translation_state;

    while (1) {
        my $next_token = Texinfo::reader_read($reader);
        last if ( !defined($next_token) );

        my $element  = $next_token->swig_element_get();
        my $category = $next_token->swig_category_get();

        my $element_type = Texinfo::element_type($element);
        $element_type = '' if ( !defined($element_type) );

        if ($debug) {
            print STDERR "R !$result! ["
              . join( '|', @$args_stack )
              . "] $category "
              . _current_smark($current_smark) . ' '
              . _print_translation_stack($translations_stack) . "\n" . ' '
              . Texinfo::element_print_details($element) . "\n";
        }

        if (   $category == $Texinfo::TXI_READ_TEXT
            or $category == $Texinfo::TXI_READ_IGNORABLE_TEXT )
        {
            my ( $last_position, $smark_result );
            ( $result, $last_position, $current_smark ) =
              _handle_source_marks( $self, $result, $element, $document, $element_type, $inputs, $translation_info,
                $current_smark );
            if ( !defined($current_smark) ) {
                if ( $element_type eq 'spaces' ) {
                    my ( $inserted, $status ) = Texinfo::element_attribute_integer( $element, 'inserted' );
                    next if ($inserted);
                }
                my $text        = _decode( Texinfo::element_text($element) );
                my $text_result = _text( $text, $last_position, $element_type );
                $$result .= $text_result;

                # there may be multiple end of line in macro_call_arg_text
                my $count = ( $text_result =~ tr/\n// );
                $inputs->[-1]->[1] += $count;
            }
            next;
        }

        my $translation_on_stack;
        my $cmdname = Texinfo::element_cmdname($element);

        if ( defined($cmdname) ) {

            # translated commands
            if ( $category == $Texinfo::TXI_READ_ELEMENT_START ) {
                if ( !defined($translation_info) ) {
                    if ( $cmdname eq 'documentlanguage' ) {

                        # In tests, this is never set.
                        my $translation_language;
                        if ( defined( $self->{TT}{po_in}->{lang} ) ) {
                            $translation_language = $self->{TT}{po_in}->{lang};
                        } else {
                            $translation_language = '-';
                        }

                        # TODO normalize and modify argument
                        if ($debug) {
                            print STDERR "LANGUAGE: $translation_language\n";
                        }
                    }
                    if (
                           $cmdname eq 'macro'
                        or $cmdname eq 'rmacro'
                        or $cmdname eq 'linemacro'
                        or $cmdname eq 'set'
                        or $cmdname eq 'ignore'
                        or $cmdname eq 'verbatim'
                        or $cmdname eq 'verbatiminclude'
                        or $cmdname eq 'displaymath'

                        # brace @-commands that happen outside of paragraphs.
                        # Need to do a check in commands data file that the
                        # arguments are to be translated, or special-case as done
                        # for @image
                        or (    Texinfo::element_command_is_brace($element)
                            and Texinfo::element_command_is_no_paragraph($element)
                            and $cmdname ne 'image' )
                      )
                    {
                        ( $translation_info, $result ) = _translation_begin_info( $inputs, 0, '@' . $cmdname, $result );
                        $translation_on_stack = 'C';
                    }
                }
                push @$translations_stack, $translation_on_stack;
            }
            if ( $category != $Texinfo::TXI_READ_ELEMENT_END ) {
                if ( !defined($current_smark) ) {
                    my $alias_of = Texinfo::element_attribute_string( $element, 'alias_of' );
                    $$result .= '@';
                    if ( defined($alias_of) ) {
                        $$result .= $alias_of;
                    } else {
                        $$result .= $cmdname;
                        $inputs->[-1]->[1] += 1 if ( $cmdname eq "\n" );
                    }
                }

                my $spaces_cmd_before_arg =
                  Texinfo::element_attribute_element( $element, 'spaces_after_cmd_before_arg' );
                if ( defined($spaces_cmd_before_arg) ) {
                    ( $result, $current_smark ) = _convert( $self, $result, $spaces_cmd_before_arg, $document,
                        $inputs, $translation_info, $current_smark );
                }
            }

            if ( $category == $Texinfo::TXI_READ_ELEMENT_START ) {
                if (   Texinfo::element_command_is_brace($element)
                    or $element_type eq 'definfoenclose_command'
                    or $element_type eq 'macro_call'
                    or $element_type eq 'rmacro_call' )
                {
                    if ( !defined($current_smark) ) {
                        if ( Texinfo::element_type( Texinfo::element_get_child( $element, 0 ) ) ne 'following_arg' ) {
                            $$result .= '{';
                        }
                        if ( $cmdname eq 'verb' ) {
                            my $verb_delimiter = _decode( Texinfo::element_attribute_string( $element, 'delimiter' ) );
                            $$result .= $verb_delimiter;
                            $inputs->[-1]->[1] += 1 if ( $verb_delimiter eq "\n" );
                        }
                    }
                    push @$args_stack, 0;
                } elsif ( !Texinfo::element_command_is_nobrace($element) ) {
                    push @$args_stack, 0;
                }

            } elsif ( $category == $Texinfo::TXI_READ_ELEMENT_END ) {
                if (   Texinfo::element_command_is_brace($element) or $element_type eq 'definfoenclose_command',
                    or $element_type eq 'macro_call'
                    or $element_type eq 'rmacro_call' )
                {
                    if ( !defined($current_smark) ) {
                        if ( $cmdname eq 'verb' ) {
                            my $verb_delimiter = _decode( Texinfo::element_attribute_string( $element, 'delimiter' ) );
                            $$result .= $verb_delimiter;
                            $inputs->[-1]->[1] += 1 if ( $verb_delimiter eq "\n" );
                        }
                        if ( Texinfo::element_type( Texinfo::element_get_child( $element, 0 ) ) ne 'following_arg' ) {
                            $$result .= '}';
                        }
                    }
                }
            }
        } else {    # !defined($cmdname)
            if ( $category == $Texinfo::TXI_READ_ELEMENT_START ) {
                my ( $inserted, $status ) = Texinfo::element_attribute_integer( $element, 'inserted' );
                if ($inserted) {
                    Texinfo::reader_skip_children( $reader, $element );
                    next;
                }
            }
            if (   $category == $Texinfo::TXI_READ_ELEMENT_START
                or $category == $Texinfo::TXI_READ_EMPTY )
            {
                if ( !defined($current_smark) ) {
                    if ( $element_type eq 'bracketed_arg' ) {
                        $$result .= '{';
                    }
                }
                if (   $element_type eq 'brace_arg'
                    or $element_type eq 'elided_brace_command_arg'
                    or $element_type eq 'line_arg'
                    or $element_type eq 'block_line_arg' )
                {
                    $args_stack->[-1]++;
                    if ( !defined($current_smark) ) {
                        if ( $args_stack->[-1] > 1 ) {
                            $$result .= ',';
                        }
                    }
                }
            }
        }
        if (   $category == $Texinfo::TXI_READ_ELEMENT_START
            or $category == $Texinfo::TXI_READ_EMPTY )
        {

            my $spaces_before_argument = Texinfo::element_attribute_element( $element, 'spaces_before_argument' );
            if ( defined($spaces_before_argument) ) {
                ( $result, $current_smark ) = _convert( $self, $result, $spaces_before_argument, $document,
                    $inputs, $translation_info, $current_smark );
            }
            my $source_info = Texinfo::element_source_info($element);
            if ( defined($source_info) ) {

                # TODO check if file name is synced too?
                my $line_nr = $source_info->swig_line_nr_get();
                if ( $line_nr != 0 and $line_nr != $inputs->[-1]->[1] ) {

                    # TODO only show for tests?
                    if ($debug) {
                        warn "WARNING: line nr out of sync $line_nr != $inputs->[-1]->[1]\n";
                    }
                    $inputs->[-1]->[1] = $line_nr;
                }
            }
        }

        # Setup element translation_info for a translation span on
        # command arguments, preformatted, paragraph and menu entry.
        if ( $category == $Texinfo::TXI_READ_ELEMENT_START
            and !defined($cmdname) )
        {
            # NOTE it could have been possible to do nothing if
            # !defined($current_smark).  This is not needed, however, since the
            # text is empty anyway and not translated because it is empty.
            #
            # Never nest translations, if there is already text to be translated
            # being gathered, the tree that would have been translated on its
            # own will instead be translated as part of the ongoing parent
            # tree element translation.
            if ( !defined($translation_info) ) {
                my $wrap;
                my $parent_cmdname;
                if ( $element_type eq 'paragraph' ) {

                    # Never wrap to keep the structure in paragraph as
                    # end of line delimitate comments and index entries, and also
                    # index entries should remain at line beginning.
                    #$wrap = 1;
                    $wrap = 0;
                } elsif ( $element_type eq 'preformatted' or $element_type eq 'menu_entry' ) {
                    $wrap = 0;
                } elsif ( $element_type eq 'block_line_arg'
                    and _translated_block_line_arg($element) )
                {
                    $parent_cmdname = _translated_block_line_arg($element);
                    $wrap           = 0;
                } elsif ( $element_type eq 'line_arg'
                    and _translated_line_arg($element) )
                {
                    $parent_cmdname = _translated_line_arg($element);
                    $wrap           = 0;
                } elsif ( ( $element_type eq 'block_line_arg' or $element_type eq 'line_arg' )
                    and defined( _translated_def_arg($element) ) )
                {
                    $parent_cmdname = _translated_def_arg($element);
                    $wrap           = 0;
                } elsif ( $element_type eq 'brace_arg'
                    and $args_stack->[-1] == 4
                    and _arg_parent_element($element)
                    and Texinfo::element_cmdname( _arg_parent_element($element) ) eq 'image' )
                {
                    $parent_cmdname = 'image';

                    # not sure.  comment could be possible even though it is
                    # not valid Texinfo
                    $wrap = 0;
                }
                if ( defined($wrap) ) {
                    my $translation_type = $element_type;

                    if ( defined($parent_cmdname) ) {
                        $translation_type .= " $args_stack->[-1] in \@$parent_cmdname";
                    }

                    ( $translation_info, $result ) =
                      _translation_begin_info( $inputs, $wrap, $translation_type, $result );
                    $translation_on_stack = 'A';
                    if ($debug) {
                        print STDERR "PUSH T $result: " . '(' . join( ',', @$translation_info ) . ')' . "\n";
                    }
                }
            }
            push @$translations_stack, $translation_on_stack;
        }
        if (   $category == $Texinfo::TXI_READ_EMPTY
            or $category == $Texinfo::TXI_READ_ELEMENT_END )
        {
            my $spaces_after_argument = Texinfo::element_attribute_element( $element, 'spaces_after_argument' );
            if ( defined($spaces_after_argument) ) {
                ( $result, $current_smark ) = _convert( $self, $result, $spaces_after_argument, $document,
                    $inputs, $translation_info, $current_smark );
            }

            if ( $element_type eq 'line_arg' or $element_type eq 'block_line_arg' ) {
                my $comment_e = Texinfo::element_attribute_element( $element, 'comment_at_end' );
                if ($comment_e) {
                    my $comment;
                    ( $result, $current_smark ) =
                      _convert( $self, $result, $comment_e, $document, $inputs, $translation_info, $current_smark );
                }
            }

            if ( !defined($current_smark) ) {
                if ( $element_type eq 'bracketed_arg' ) {
                    $$result .= '}';
                }
            }
        }

        if ( $category == $Texinfo::TXI_READ_ELEMENT_END ) {
            if ( defined($cmdname)
                and !Texinfo::element_command_is_nobrace($element) )
            {
                pop @$args_stack;
            }
        }

        if ( $category == $Texinfo::TXI_READ_ELEMENT_END ) {
            my $translation_on_stack = pop @$translations_stack;
            if ( defined($translation_on_stack) ) {
                if ( defined($cmdname) and $cmdname eq 'verbatiminclude' ) {
                    my $element_formatted_errors = Texinfo::expand_verbatiminclude(
                        $element,
                        $self->{'input_file_include_dirs'},
                        $self->{'input_file_charset'}
                    );
                    my $verbatim_element = $element_formatted_errors->swig_element_get();
                    my $error_messages   = $element_formatted_errors->swig_errors_get();
                    _output_txi_error_messages($error_messages);
                    if ( defined($verbatim_element) ) {
                        my $file_name = Texinfo::element_attribute_string( $element, 'text_arg' );

                        # replace the translation informations with the
                        # verbatiminclude file information and content and
                        # add a @verbatim and @end verbatim.

                        # ref
                        $translation_info->[1] = "$file_name:1";

                        # translation_type
                        $translation_info->[3] = "\@$cmdname $file_name";
                        my $elements_nr     = Texinfo::element_children_number($verbatim_element);
                        my $previous_result = $translation_info->[4];
                        $$previous_result .= "\@verbatim\n";

                        $$result = '';
                        for ( my $i = 0 ; $i < $elements_nr ; $i++ ) {
                            my $result_text   = '';
                            my $child_element = Texinfo::element_get_child( $verbatim_element, $i );
                            ( $result, $current_smark ) =
                              _convert( $self, $result, $child_element, $document, $inputs, $translation_info,
                                $current_smark );
                        }
                        $result = _translation_end( $self, $translation_info, $result );
                        $$result .= "\@end verbatim\n";
                    } else {

                        # do not really do a translation, simply output the
                        # @verbatiminclude command text that could have
                        # been translated.
                        my $previous_result = $translation_info->[4];
                        $$previous_result .= $$result;
                        $result = $previous_result;
                    }
                    Texinfo::destroy_element_formatted_errors($element_formatted_errors);
                } else {
                    $result = _translation_end( $self, $translation_info, $result );
                }
                $translation_info = undef;
            }
        }

        if (   $category == $Texinfo::TXI_READ_EMPTY
            or $category == $Texinfo::TXI_READ_ELEMENT_END )
        {
            my ( $last_position, $smark_result );
            ( $result, $last_position, $current_smark ) =
              _handle_source_marks( $self, $result, $element, $document, $element_type, $inputs, $translation_info,
                $current_smark );
        }
    }

    if ($debug) {
        print STDERR "_END " . _current_smark($current_smark) . "\n";

        #print STDERR "RESULT: '$$result'\n";
    }
    return ( $result, $current_smark );
}

sub parse_file {
    my $self             = shift;
    my $file_and_charset = shift;
    my ( $filename, $charset ) = @$file_and_charset;

    my $parser = Texinfo::parser;

    Texinfo::parser_conf_clear_expanded_formats($parser);

    # Only tex is not there
    foreach my $format ( 'info', 'plaintext', 'html', 'latex', 'docbook', 'xml' ) {
        Texinfo::parser_conf_add_expanded_format( $parser, $format );
    }

    # prepare include directories
    # Parse the input file
    my ( $input_filename, $input_directory, $suffix ) = fileparse($filename);

    my $canon_input_dir;
    if ( !defined($input_directory) or $input_directory eq '' ) {
        $input_directory = $curdir;
        $canon_input_dir = $curdir;
    } else {
        $canon_input_dir = File::Spec->canonpath($input_directory);
    }
    my @prepended_include_directories = ($curdir);
    push @prepended_include_directories, $input_directory
      if ( $canon_input_dir ne $curdir );

    my @include_dirs = @include_directories;
    unshift @include_dirs, @prepended_include_directories;

    Texinfo::parser_conf_clear_INCLUDE_DIRECTORIES($parser);
    foreach my $dir (@include_dirs) {
        Texinfo::parser_conf_add_include_directory( $parser, $dir );
    }

    my ( $document, $status ) = Texinfo::parse_file( $parser, $filename );

    my ( $parser_error_msgs, $error_nr ) = Texinfo::get_parser_error_messages($document);
    _output_txi_error_messages($parser_error_msgs);
    if ($status) {
        exit 1;
    }

    # check that the charset is the same as the Texinfo @documentencoding
    if ( defined($charset) ) {
        my $global_info = Texinfo::document_global_information($document);

        my $encoding = $global_info->swig_input_encoding_name_get();

        # not actually possible, encoding is set to in the default case.
        $encoding = 'UTF-8' if ( !defined($encoding) );

        # To support old manuals in which US-ASCII can be specified although
        # the encoding corresponds to any 8bit encoding compatible with ISO-8859-1,
        # we also consider US-ASCII as ISO-8859-1 to avoid errors for characters in
        # ISO-8859-1 but not in US-ASCII.
        my @encodings = ($encoding);
        if ( lc($encoding) eq 'us-ascii' ) {
            push @encodings, 'iso-8859-1';
        }

        my $encoding_found;
        foreach my $input_encoding (@encodings) {
            if ( lc($charset) eq lc($input_encoding) ) {
                $encoding_found = 1;
                last;
            }
        }
        if ( !$encoding_found ) {
            wrap_mod( "po4a::texinfo", gettext('Document encoding %s differs from encoding %s'),
                $encodings[0], $charset );
        }
    }

    my $tree = Texinfo::document_tree($document);

    # Not parallel safe
    $self->{'input_file_charset'}      = $charset;
    $self->{'input_file_include_dirs'} = Texinfo::parser_conf_get_INCLUDE_DIRECTORIES($parser);

    my $current_smark;
    my $inputs      = [ [ $filename, 1, undef, -1, undef ] ];
    my $elements_nr = Texinfo::element_children_number($tree);

    # NOTE this could possibly fail if there are macro expansions across
    # top-level elements boundaries, but also @if*.  @if* have been
    # tested to be ok.
    for ( my $i = 0 ; $i < $elements_nr ; $i++ ) {
        my $result_text = '';
        $inputs->[0]->[2] = \$result_text;
        my $result;
        my $element = Texinfo::element_get_child( $tree, $i );
        ( $result, $current_smark ) = _convert( $self, $inputs->[0]->[2], $element, $document, $inputs );
        $self->pushline($$result);
    }

    if ( defined($current_smark) ) {
        warn "REMARK: Source mark not closed\n";
    }
}

1;
