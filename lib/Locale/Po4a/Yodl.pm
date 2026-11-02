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

A YODL document is plain text where formatting is expressed with macro calls:
an identifier made of letters, followed by one or more parenthesized argument
groups, as in C<chapter(Using the program)> or C<article(Title)(Author)(2026)>.
Commas do not separate arguments, they are ordinary text within an argument.

This module extracts translatable strings at the block level: the text between
two block level macro calls is grouped into paragraphs (blank lines separate
paragraphs), and inline macro calls are kept verbatim inside the paragraph they
belong to.  Translators therefore get complete sentences including their
markup, for example the whole following string is a single message:

 The tt(yodl) program reads one or more input files.

Each argument group of a block level macro is extracted as a standalone string,
so that the title of C<manpagename(yodl)(A document language)> can be
translated separately from the body of the manual page.  The enclosing macros
are reported as the type of each message (C<chapter>, C<center>,
C<itemization/it>, C<description/dit>, ...), which helps L<po4a-gettextize(1)>
detect structure mismatches.

=head1 OPTIONS ACCEPTED BY THIS MODULE

Every macro belongs to one of the five categories below, each of them being
configured with a space or comma separated list of macro names.  Macro names
are matched case-sensitively.  A macro which is listed in none of the options is
handled as an inline macro, which is the safest choice for the user defined
macros that populate YODL documents.

=over

=item B<block=I<macro1 macro2 ...>>

Macros which structure the document.  Such a call splits the surrounding text
and each of its argument groups is extracted as a standalone string.  The text
which follows the call keeps the context of the enclosing block macros.

=item B<open=I<macro1 macro2 ...>>

Macros which start a section which is not enclosed in an argument, such as the
C<it()> item marker or the C<manpagesynopsis()> section marker of a manual page.
Like a block macro, such a call splits the surrounding text and extracts its
arguments, and in addition the plain text which follows it is reported with the
name of the macro in its type.  Another B<open> macro of the same level replaces
it, so that consecutive items of a list all get the type C<itemization/it>.

=item B<close=I<macro1 macro2 ...>>

Macros which end the sections started by the B<open> macros of the same block,
such as C<ttend()> which closes the section started by C<ttbegin()>.  The text
which follows such a call is reported without the names of the macros it closes.
B<open> and B<close> macros must be properly nested.

=item B<inline=I<macro1 macro2 ...>>

Macros which must be kept inside the surrounding string, instead of being
extracted as documented above.  Use this option to demote a macro which is a
block macro by default.  The arguments of an inline macro are not parsed, so
they are never offered as separate messages: this is what keeps the label of
C<link(description)(labelname)> or the file name of
C<figure(file)(caption)(label)> intact while the text around them is translated.

=item B<untranslated=I<macro1 macro2 ...>>

Macros whose arguments must not be translated.  Such a call is copied verbatim,
and splits the surrounding text.

=item B<wrap> (default: B<yes>)

Whether extracted paragraphs are reformatted to the current line width (see
B<--wrap> in L<po4a(7)>).  Set it to 0 (C<-o wrap=0>) to keep the line breaks
of the original document inside the PO files.

=back

=head1 CLASSIFICATION OF THE PREDEFINED MACROS

All the macros documented in L<the YODL
reference|https://fbb-git.gitlab.io/yodl/yodl-doc/yodl04.html#l105> are
classified by this module.  The following ones are block macros, i.e. macros
whose arguments are text to be translated:

 abstract affiliation article book cell cells center chapter description
 enumerate enumeration itdesc itemization lchapter letter letteraddenda
 letteradmin letterfootitem letterreplyto letterto lsect lsubsect lsubsubsect
 lsubsubsubsect manpage manpagename nchapter nparagraph npart nsect nsubsect
 nsubsubsect nsubsubsubsect paragraph part plainhtml quote report row sect
 subsect subsubsect subsubsubsect table tableatt tac tbl tc tcell tnac tnc tr
 xmlmenu

These ones are open and close macros, i.e. markers which delimit a section
without enclosing its text:

 open:  appendix dit eit it manpageauthor manpagebugs manpagedescription
        manpagediagnostics manpagefiles manpageoptions manpagesection
        manpageseealso manpagesynopsis ttbegin xit
 close: ttend

The formatting commands which appear inside a sentence are inline macros:

 bf bind cite code dashes em ellipsis email euro fig figure file footnote LaTeX
 langle link lref lurl mbox nbsp nemail nl nop rangle ref sc strong subs sups
 TeX tt url

The remaining predefined macros are untranslated, because their arguments are
file names, index keys, macro definitions or text meant for one specific output
format rather than prose: the C<verb*>, C<when*>, C<html*>, C<latex*>, C<xml*>,
C<sgml*> and C<texinfocommand>, C<telycommand>, C<txtcommand>, C<mscommand>,
C<roffcmd>, C<mancommand> families, the C<def>, C<redef>, C<redefinemacro>,
C<evalsymbol>, C<addntosymbol> and C<ifnewparagraph> programming macros, the
C<metaC> and C<metaCOMMENT> comments, the C<makeindex>, C<printindex> and
C<*index> index macros, the C<includefile> and C<includeverbatim> inclusion
macros, the C<get...string>, C<set...string>, C<language*> and C<setlanguage>
header macros, and the switches of the document preamble such as C<clearpage>,
C<notableofcontents> or C<standardlayout>.  C<label> belongs to this group as
well, since translating the name of an anchor would break the C<ref> and
C<link> commands which refer to it.

=head1 STATUS OF THIS MODULE

This module is in an early stage.  Its limitations are worth knowing about:

=over

=item *

Macros are classified by name, not by use.  A macro which is used as a block
construct in some places and as an inline construct in others cannot be
supported perfectly: select the category matching its most frequent use.

=item *

The number of arguments a macro takes is not known, so a parenthesized group
which follows a macro call, blanks apart, is handled as one of its arguments.
This also means that the parentheses of an extracted call must be balanced, as
they must be for yodl itself: a literal parenthesis has to be written C<CHAR(40)>
or C<CHAR(41)>.

=item *

The arguments of an inline macro are not parsed, so a block macro written inside
an inline macro call is translated as a part of the surrounding message, instead
of being extracted as a message of its own.  This is the wanted behavior for the
commands which protect their argument, such as C<tt> or C<code>, and for the
markup which must not be split, such as C<link>.  A block macro written inside
an untranslated macro is not translated at all, which is what C<verb> and
friends are for.

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

# YODL's predefined macros, see
# <https://fbb-git.gitlab.io/yodl/yodl-doc/yodl04.html#l105>, classified as
# documented in the POD above.  A macro which is absent from this table is
# handled as an inline macro.
my %default_category = (
    block => [
        qw(
          abstract affiliation article book cell cells center chapter
          description enumerate enumeration itdesc itemization lchapter letter
          letteraddenda letteradmin letterfootitem letterreplyto letterto lsect
          lsubsect
          lsubsubsect lsubsubsubsect manpage manpagename nchapter nparagraph npart
          nsect nsubsect nsubsubsect nsubsubsubsect paragraph part plainhtml quote
          report row sect subsect subsubsect subsubsubsect table tableatt tac tbl
          tc tcell tnac tnc tr xmlmenu
        )
    ],

    # Markers which start a section: it(), dit(), the sections of a manual page,
    # and the ttbegin()/ttend() pair.
    open => [
        qw(
          appendix dit eit it manpageauthor manpagebugs manpagedescription
          manpagediagnostics manpagefiles manpageoptions manpagesection
          manpageseealso manpagesynopsis ttbegin xit
        )
    ],
    close => [qw( ttend )],

    # Commands which appear inside a sentence, including the ones whose arguments
    # are anchors, labels or file names which must not be translated alone.
    inline => [
        qw(
          bf bind cite code dashes em ellipsis email euro fig figure file
          footnote LaTeX langle link lref lurl mbox nbsp nemail nl nop rangle ref
          sc strong subs sups TeX tt url
        )
    ],

    # Raw output for one output format, file names, index keys, macro definitions
    # and settings of the document preamble.
    untranslated => [
        qw(
          addntosymbol AfourEnlarged attrib attribclear attribinsert cindex
          cellsline clearpage columnline def evalsymbol findex gagmacrowarning
          getaffilstring getauthorstring getchapterstring getdatestring
          getfigurestring getpartstring gettitlestring gettocstring htmlbodyopt
          htmlcommand htmlheadfile htmlheadopt htmlmetacharset htmlnewfile
          htmlstyle htmlstylesheet htmltag ifnewparagraph includefile
          includeverbatim kindex label languagedutch languageenglish
          languageportugese latexaddlayout latexcommand latexdocumentclass
          latexlayoutcmds latexoptions latexpackage mailto makeindex mancommand
          manttquoted metaC metaCOMMENT mscommand nodeprefix nodetext nohtmlfive
          nohtmlimgstyle nosloppyhfuzz notableofcontents notitleclearpage
          notocclearpage notransinclude noxlatin PageEnlarged pindex printindex
          redef redefinemacro roffcmd rowline setaffilstring setauthorstring
          setchapterstring setdatestring setfigureext setfigurestring
          sethtmlfigureext setincludepath setlanguage setlatexalign
          setlatexfigureext setlatexverbchar setmanalign setpartstring setrofftab
          setrofftableoptions settitlestring settocstring sgmlcommand sgmltag
          sloppyhfuzz standardlayout tao telycommand texinfocommand tindex
          titleclearpage tline tocclearpage twrap txtcommand verb verbinclude
          verbinsert verborg verbpipe vindex whenhtml whenlatex whenman whenms
          whensgml whentely whentexinfo whentxt whenxml xmlcommand xmlnewfile
          xmlsetdocumentbase xmltag
        )
    ],
);

my @CATEGORIES = sort keys %default_category;

sub initialize {
    my ( $self, %options ) = @_;
    $self->{options}{$_} = '' for @CATEGORIES;
    $self->{options}{wrap} = 1;
    foreach my $opt ( keys %options ) {
        die wrap_mod( "po4a::yodl", dgettext( "po4a", "Unknown option: %s" ), $opt )
          unless exists $self->{options}{$opt};
        $self->{options}{$opt} = $options{$opt};
    }

    $self->{_yodl_category} = {};
    while ( my ( $category, $names ) = each %default_category ) {
        $self->{_yodl_category}{$_} = $category for @{$names};
    }

    my %configured;
    foreach my $opt (@CATEGORIES) {
        foreach my $name ( _split_names( $self->{options}{$opt} ) ) {
            die wrap_mod( "po4a::yodl",
                dgettext( "po4a", "Macro '%s' is assigned to conflicting categories: '%s' and '%s'." ),
                $name, $configured{$name}, $opt )
              if exists $configured{$name} && $configured{$name} ne $opt;
            $configured{$name} = $opt;
            $self->{_yodl_category}{$name} = $opt;
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
    return $self->{_yodl_category}{$name} // 'inline';
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

# Walk a range of the document: translate the plain text it contains, recurse
# into the arguments of the macros which are not inlined, and maintain the chain
# of the enclosing macros, which is reported as the type of the extracted
# strings.
sub _parse_range {
    my ( $self, $text, $start, $end, $ctx ) = @_;
    my $out           = '';
    my $segment_start = $start;
    my @context       = @{$ctx};

    # An open macro pushes its name on top of the context this range started
    # with, and a close macro pops the names pushed by this range only: this is
    # what keeps a section marker from leaking in or out of the arguments of the
    # enclosing macro call, and what makes two consecutive items of a list share
    # the same type instead of nesting.
    my $scope_depth = @context;
    my $i           = $start;

    while ( $i < $end ) {
        my ( $name, $open ) = $self->_read_macro_start( $text, $i, $end );
        unless ( defined $name ) {
            $i++;
            next;
        }
        my $groups   = $self->_read_groups( $text, $open, $end, $name );
        my $call_end = $groups->[-1][1];
        my $category = $self->_macro_category($name);

        if ( $category eq 'inline' ) {

            # Leave the whole call alone: it is part of the surrounding string.
            $i = $call_end + 1;
            next;
        }

        $out .= $self->_emit_text( $text, $segment_start, $i, \@context );

        if ( $category eq 'untranslated' ) {
            $out .= substr( $text, $i, $call_end - $i + 1 );
        } else {
            if ( $category eq 'open' ) {
                @context = ( @context[ 0 .. $scope_depth - 1 ], $name );
            } elsif ( $category eq 'close' ) {
                @context = @context[ 0 .. $scope_depth - 1 ];
            }
            my @arg_context = $category eq 'block' ? ( @context, $name ) : @context;
            $out .= $self->_emit_call( $text, $groups, $name, \@arg_context );
        }

        $i             = $call_end + 1;
        $segment_start = $i;
    }

    $out .= $self->_emit_text( $text, $segment_start, $end, \@context );
    return $out;
}

# A YODL macro name consists of letters only, and a macro is called when a
# parenthesized group directly follows its name: this is how the yodl program
# itself splits its input (see DEFINEMACRO in the YODL manual, and
# l_isIdentChar() in its lexer).  Return the name of the macro called at $pos,
# together with the position of its opening parenthesis.
sub _read_macro_start {
    my ( $self, $text, $pos, $end ) = @_;
    return unless $pos < $end;

    my $first = substr( $text, $pos, 1 );
    return unless $first =~ /[[:alpha:]]/;
    if ( $pos > 0 ) {

        # The name must start a sequence of letters: yodl reads tt(foo_bar(x))
        # as the word tt, an underscore, and the macro call bar(x), but never
        # as a call to a macro named foo_bar.
        return if substr( $text, $pos - 1, 1 ) =~ /[[:alpha:]]/;
    }

    my $j = $pos + 1;
    $j++ while $j < $end    && substr( $text, $j, 1 ) =~ /[[:alpha:]]/;
    return unless $j < $end && substr( $text, $j, 1 ) eq '(';
    return ( substr( $text, $pos, $j - $pos ), $j );
}

# Collect the argument groups of a macro call: article(title)(author)(date) is
# one call with three groups.  Blanks between two groups are part of the call,
# because that is the preferred way of writing a call with several arguments.
sub _read_groups {
    my ( $self, $text, $open, $end, $name ) = @_;
    my @groups;
    my $pos = $open;

    while ( $pos < $end ) {
        my $close = $self->_find_matching_paren( $text, $pos, $end );
        die wrap_mod( "po4a::yodl", dgettext( "po4a", "Unbalanced parenthesis in YODL macro '%s' near %s." ),
            $name, $self->_ref_for_offset($pos) )
          unless defined $close;
        push @groups, [ $pos, $close ];

        $pos = $close + 1;
        my $next = $pos;
        $next++ while $next < $end && substr( $text, $next, 1 ) =~ /[ \t\r\n]/;
        last unless $next < $end   && substr( $text, $next, 1 ) eq '(';
        $pos = $next;
    }

    return \@groups;
}

sub _find_matching_paren {
    my ( $self, $text, $open, $end ) = @_;
    my $depth = 1;
    my $i     = $open + 1;
    while ( $i < $end ) {
        my $ch = substr( $text, $i, 1 );
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

# Rebuild a macro call, translating each argument group and copying everything
# else, the names and the blanks between the groups included, verbatim.
sub _emit_call {
    my ( $self, $text, $groups, $name, $ctx ) = @_;
    my $out = $name;
    my $prev;
    foreach my $group ( @{$groups} ) {
        my ( $open, $close ) = @{$group};

        # The blanks between two argument groups are not text.
        $out .= substr( $text, $prev, $open - $prev ) if defined $prev;
        $out .= '(' . $self->_parse_range( $text, $open + 1, $close, $ctx ) . ')';
        $prev = $close + 1;
    }
    return $out;
}

# Emit the plain text between two macro calls.  Blank lines separate the
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
