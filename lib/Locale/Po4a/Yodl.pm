#!/usr/bin/perl -w

=encoding UTF-8

=head1 NAME

Locale::Po4a::Yodl - convert YODL documents from/to PO files

=head1 DESCRIPTION

The po4a (PO for anything) project goal is to ease translations (and more
interestingly, the maintenance of translations) using gettext tools on
areas where they were not expected like documentation.

Locale::Po4a::Yodl is a module to help the translation of YODL ("Your Own
Document Language", see L<https://fbb-git.gitlab.io/yodl/> and
L<https://www.w3.org/Tools/YODL.html>) documents into other [human] languages.

A YODL document is plain text where formatting is expressed with C-style macro
calls, such as C<tt(yodl)> or C<center(...)>.  This module extracts translatable
strings at the block level: the text between two block macro calls is grouped
into paragraphs (blank lines separate paragraphs), and inline macro calls are
kept verbatim inside the paragraph they belong to.  Translators therefore get
complete sentences including their markup, for example the whole following
string is a single message:

 The tt(yodl) program reads one or more input files.

Arguments of block macros are extracted as standalone strings, so that the
title of C<chapter(Using the program)> can be translated separately from the
body of the chapter.  The enclosing block macros are reported as the type of
each message (C<chapter>, C<center>, C<itemization/it>, ...), which helps
L<po4a-gettextize(1)> detect structure mismatches.

=head1 OPTIONS ACCEPTED BY THIS MODULE

=over

=item B<block=I<macro1 macro2 ...>>

Space or comma separated list of macros which start a block.  Their arguments
are extracted as standalone translation units.  A call without argument (such
as the C<it()> item marker) only splits the surrounding text and becomes the
context of the text that follows it.

=item B<inline=I<macro1 macro2 ...>>

Space or comma separated list of macros which must be kept inside the
surrounding string, instead of being extracted as documented above.  Use this
option to demote a macro which is a block macro by default.

=item B<untranslated=I<macro1 macro2 ...>>

Space or comma separated list of macros whose arguments must not be translated.
Such a call is copied verbatim, and splits the surrounding text.

=item B<wrap> (default: B<yes>)

Whether extracted paragraphs are reformatted to the current line width (see
B<--wrap> in L<po4a(7)>).  Set it to 0 (C<-o wrap=0>) to keep the line breaks
of the original document inside the PO files.

=back

Macro names are matched case-sensitively.  When a macro is not listed in any of
the options above, it is handled as inline, which is the safest choice for the
user defined macros that populate YODL documents.

By default, the following YODL builtin macros are handled as block macros:

 abstract appendix article book center chapter description enumeration
 figure it itdesc itemization letter paragraph part quote report sect
 startdoc subsect subsubsect subsubsubsect table

and the following ones are never translated, since their arguments are either
raw output for a specific format or metadata such as index keys:

 evalsymbol gagmacrowarning htmlcommand htmltag includeverbatim latexcommand
 latexoptions latexpackage makeindex mancommand metaC metaCOMMENT metacomment
 mscommand roffcmd sgmlcommand sgmltag telycommand texinfocommand txtcommand
 verb verbinclude verbinsert xmlcommand xmltag

=head1 STATUS OF THIS MODULE

This module is in an early stage.  Two limitations are worth knowing about:

=over

=item *

Macros are classified by name, not by use.  A macro which is used as a block
construct in some places and as an inline construct in others cannot be
supported perfectly: select the category matching its most frequent use.

=item *

Since the arguments of inline macros are not parsed, a block macro nested
inside an inline macro call is copied verbatim and is not translated.

=back

If you use more advanced features and observe parsing issues, please report
them.

=head1 SEE ALSO

L<Locale::Po4a::TransTractor(3pm)>, L<po4a(7)|po4a.7>

=head1 AUTHORS

 po4a contributors

=head1 COPYRIGHT AND LICENSE

This program is free software; you may redistribute it and/or modify it
under the terms of GPL v2.0 or later (see the COPYING file).

=cut

package Locale::Po4a::Yodl;

use 5.16.0;
use strict;
use warnings;

use parent qw(Locale::Po4a::TransTractor);

use Locale::Po4a::Common qw(wrap_mod dgettext);

# YODL's builtin macros which format a whole block of text.
my @default_block = qw(
  abstract appendix article book center chapter description enumeration
  figure it itdesc itemization letter paragraph part quote report sect
  startdoc subsect subsubsect subsubsubsect table
);

# YODL's builtin macros whose argument is raw output, or metadata: they must
# never be translated.
my @default_untranslated = qw(
  evalsymbol gagmacrowarning htmlcommand htmltag includeverbatim latexcommand
  latexoptions latexpackage makeindex mancommand metaC metaCOMMENT metacomment
  mscommand roffcmd sgmlcommand sgmltag telycommand texinfocommand txtcommand
  verb verbinclude verbinsert xmlcommand xmltag
);

sub initialize {
    my ( $self, %options ) = @_;
    $self->{options}{block}        = '';
    $self->{options}{inline}       = '';
    $self->{options}{untranslated} = '';
    $self->{options}{wrap}         = 1;
    foreach my $opt ( keys %options ) {
        die wrap_mod( "po4a::yodl", dgettext( "po4a", "Unknown option: %s" ), $opt )
          unless exists $self->{options}{$opt};
        $self->{options}{$opt} = $options{$opt};
    }

    $self->{_yodl_block}        = { map { $_ => 1 } @default_block };
    $self->{_yodl_untranslated} = { map { $_ => 1 } @default_untranslated };

    my %category;
    foreach my $opt (qw(block inline untranslated)) {
        foreach my $name ( _split_names( $self->{options}{$opt} ) ) {
            die wrap_mod( "po4a::yodl",
                dgettext( "po4a", "Macro '%s' is assigned to conflicting categories: '%s' and '%s'." ),
                $name, $category{$name}, $opt )
              if exists $category{$name} && $category{$name} ne $opt;
            $category{$name} = $opt;
            delete $self->{_yodl_block}{$name}        if $opt ne 'block';
            delete $self->{_yodl_untranslated}{$name} if $opt ne 'untranslated';
            $self->{_yodl_block}{$name}        = 1 if $opt eq 'block';
            $self->{_yodl_untranslated}{$name} = 1 if $opt eq 'untranslated';
        }
    }

    return $self->SUPER::initialize;
}

sub _split_names {
    my ($raw) = @_;
    return () unless defined $raw && length $raw;
    return grep { length $_ } split /[,\s]+/, $raw;
}

sub _macro_category {
    my ( $self, $name ) = @_;
    return 'untranslated' if $self->{_yodl_untranslated}{$name};
    return 'block'        if $self->{_yodl_block}{$name};
    return 'inline';
}

sub parse {
    my $self = shift;

    my ( $line, $ref );
    my $content = '';
    my @starts  = ();
    my @refs    = ();

    while ( ( $line, $ref ) = $self->shiftline and defined $line ) {
        push @starts, length($content);
        push @refs,   $ref;
        $content .= $line;
    }

    $self->{_yodl_line_starts} = \@starts;
    $self->{_yodl_line_refs}   = \@refs;
    my $translated = $self->_parse_range( $content, 0, length($content), [] );
    $self->pushline($translated);
    return;
}

# Walk a range of the document, translating the plain text it contains and
# recursing into the arguments of the block macros.  $ctx is the chain of the
# enclosing block macros, used as the type of the extracted strings.
sub _parse_range {
    my ( $self, $text, $start, $end, $ctx ) = @_;
    my $out           = '';
    my $segment_start = $start;
    my @context       = @{$ctx};
    my $scope_depth   = @context;
    my $i             = $start;

    while ( $i < $end ) {
        my $ch = substr( $text, $i, 1 );
        if ( $ch eq '\\' ) {
            $i += 2;
            next;
        }

        my ( $name, $open ) = $self->_read_macro_start( $text, $i, $end );
        unless ( defined $name ) {
            $i++;
            next;
        }
        my $close = $self->_find_matching_paren( $text, $open, $end );
        die wrap_mod( "po4a::yodl", dgettext( "po4a", "Unbalanced parenthesis in YODL macro '%s' near %s." ),
            $name, $self->_ref_for_offset($open) )
          unless defined $close;

        my $category = $self->_macro_category($name);
        if ( $category eq 'inline' ) {

            # Leave the whole call alone: it is part of the surrounding string.
            $i = $close + 1;
            next;
        }

        $out .= $self->_emit_text( $text, $segment_start, $i, \@context );

        if ( $category eq 'untranslated' ) {
            $out .= substr( $text, $i, $close - $i + 1 );
        } else {
            my $marker      = $open + 1 == $close;
            my @arg_context = $marker ? ( @context[ 0 .. $scope_depth - 1 ], $name ) : ( @context, $name );
            $out .= $name . "(";
            $out .= $self->_parse_arguments( $text, $open + 1, $close, \@arg_context );
            $out .= ")";

            # A block macro call without argument only breaks the text flow:
            # keep it as the context of the text which follows.
            @context = @arg_context if $marker;
        }

        $i             = $close + 1;
        $segment_start = $i;
    }

    $out .= $self->_emit_text( $text, $segment_start, $end, \@context );
    return $out;
}

sub _read_macro_start {
    my ( $self, $text, $pos, $end ) = @_;
    return unless $pos < $end;

    my $first = substr( $text, $pos, 1 );
    return unless $first =~ /[[:alpha:]_]/;
    if ( $pos > 0 ) {
        my $prev = substr( $text, $pos - 1, 1 );
        return if $prev =~ /[[:alnum:]_-]/;
        return if $prev eq '\\';
    }

    my $j = $pos + 1;
    while ( $j < $end ) {
        my $cur = substr( $text, $j, 1 );
        last unless $cur =~ /[[:alnum:]_.-]/;
        $j++;
    }
    return unless $j < $end && substr( $text, $j, 1 ) eq '(';
    return ( substr( $text, $pos, $j - $pos ), $j );
}

sub _find_matching_paren {
    my ( $self, $text, $open, $end ) = @_;
    my $depth = 1;
    my $i     = $open + 1;
    while ( $i < $end ) {
        my $ch = substr( $text, $i, 1 );
        if ( $ch eq '\\' ) {
            $i += 2;
            next;
        }
        if ( $ch eq '(' ) {
            $depth++;
        } elsif ( $ch eq ')' ) {
            $depth--;
            return $i if $depth == 0;
        }
        $i++;
    }
    return;
}

sub _parse_arguments {
    my ( $self, $text, $start, $end, $ctx ) = @_;
    my $arg_start = $start;
    my $out       = '';
    my $depth     = 0;
    my $i         = $start;

    while ( $i < $end ) {
        my $ch = substr( $text, $i, 1 );
        if ( $ch eq '\\' ) {
            $i += 2;
            next;
        }
        if ( $ch eq '(' ) {
            $depth++;
        } elsif ( $ch eq ')' ) {
            $depth-- if $depth > 0;
        } elsif ( $ch eq ',' && $depth == 0 ) {
            $out .= $self->_parse_range( $text, $arg_start, $i, $ctx );
            $out .= ",";
            $arg_start = $i + 1;
        }
        $i++;
    }

    $out .= $self->_parse_range( $text, $arg_start, $end, $ctx );
    return $out;
}

# Emit the plain text between two block macro calls.  Blank lines separate the
# paragraphs, i.e. the gettext messages; the blanks surrounding a paragraph are
# copied verbatim so that the document can be rebuilt identically.
sub _emit_text {
    my ( $self, $text, $start, $end, $ctx ) = @_;
    return '' if $end <= $start;

    my $type = @{$ctx} ? join( '/', @{$ctx} ) : 'paragraph';
    my $out  = '';
    my $buf  = '';
    my $buf_start;
    my $offset = $start;

    foreach my $line ( split /(?<=\n)/, substr( $text, $start, $end - $start ), -1 ) {
        my $line_offset = $offset;
        $offset += length($line);
        next unless length $line;

        if ( $line =~ /\A[ \t]*(?:\n|\z)/ ) {
            $out .= $self->_emit_paragraph( $buf, $buf_start, $type ) . $line;
            $buf = '';
            undef $buf_start;
            next;
        }

        $buf_start = $line_offset unless defined $buf_start;
        $buf .= $line;
    }

    $out .= $self->_emit_paragraph( $buf, $buf_start, $type ) if length $buf;
    return $out;
}

sub _emit_paragraph {
    my ( $self, $text, $offset, $type ) = @_;
    return $text unless length $text;

    $text =~ /\A([ \t\n]*)(.*?)([ \t\n]*)\z/s;
    my ( $leading, $body, $trailing ) = ( $1, $2, $3 );
    return $text unless length $body;

    return
        $leading
      . $self->translate( $body, $self->_ref_for_offset($offset), $type, wrap => $self->{options}{wrap} )
      . $trailing;
}

sub _ref_for_offset {
    my ( $self, $offset ) = @_;
    my $starts = $self->{_yodl_line_starts} || [];
    my $refs   = $self->{_yodl_line_refs}   || [];
    return '' unless @{$refs};

    my ( $low, $high, $best ) = ( 0, $#$starts, 0 );
    while ( $low <= $high ) {
        my $mid = int( ( $low + $high ) / 2 );
        if ( $starts->[$mid] <= $offset ) {
            $best = $mid;
            $low  = $mid + 1;
        } else {
            $high = $mid - 1;
        }
    }
    return $refs->[$best];
}

1;

__END__
