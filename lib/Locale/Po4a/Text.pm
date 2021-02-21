#!/usr/bin/perl -w

# Po4a::Text.pm
#
# extract and translate translatable strings from a text documents
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

=encoding UTF-8

=head1 NAME

Locale::Po4a::Text - convert text documents from/to PO files

=head1 DESCRIPTION

The po4a (PO for anything) project goal is to ease translations (and more
interestingly, the maintenance of translations) using gettext tools on
areas where they were not expected like documentation.

Locale::Po4a::Text is a module to help the translation of text documents into
other [human] languages.

Paragraphs are split on empty lines (or lines containing only spaces or
tabulations).

If a paragraph contains a line starting by a space (or tabulation), this
paragraph won't be rewrapped.

=cut

package Locale::Po4a::Text;

use 5.006;
use strict;
use warnings;

require Exporter;
use vars qw(@ISA @EXPORT);
@ISA    = qw(Locale::Po4a::TransTractor);
@EXPORT = qw();

use Locale::Po4a::TransTractor;
use Locale::Po4a::Common;
use YAML::Tiny;

=head1 OPTIONS ACCEPTED BY THIS MODULE

These are this module's particular options:

=over

=item B<keyvalue>

Treat paragraphs that look like a key value pair as verbatim (with the no-wrap flag in the PO file).
Key value pairs are defined as a line containing one or more non-colon
and non-space characters followed by a colon followed by at least one
non-space character before the end of the line.

=cut

my $keyvalue = 0;

=item B<nobullets>

Deactivate the detection of bullets.

By default, when a bullet is detected, the bullet paragraph is not considered
as a verbatim paragraph (with the no-wrap flag in the PO file). Instead, the
corresponding paragraph is rewrapped in the translation.

=cut

my $bullets = 1;

=item B<tabs=>I<mode>

Specify how tabulations shall be handled. The I<mode> can be any of:

=over

=item B<split>

Lines with tabulations introduce breaks in the current paragraph.

=item B<verbatim>

Paragraph containing tabulations will not be re-wrapped.

=back

By default, tabulations are considered as spaces.

=cut

my $tabs = "";

=item B<breaks=>I<regex>

A regular expression matching lines which introduce breaks.
The regular expression will be anchored so that the whole line must match.

=cut

my $breaks;

=item B<debianchangelog>

Handle the header and footer of
released versions, which only contain non translatable informations.

=cut

my $debianchangelog = 0;

=item B<fortunes>

Handle the fortunes format, which separate fortunes with a line which
consists in '%' or '%%', and use '%%' as the beginning of a comment.

=cut

my $fortunes = 0;

=item B<markdown>

Handle some special markup in Markdown-formatted texts.

=cut

my $markdown = 0;

=item B<yfm_keys> (markdown-only)

Comma-separated list of keys to process for translation in the YAML Front Matter
section. All other keys are skipped. Keys are matched with a case-insensitive
match. Array values are always translated, unless the B<yfm_skip_array> option
is provided.

=cut

my %yfm_keys = ();

=item B<yfm_skip_array> (markdown-only)

Do not translate array values in the YAML Front Matter section.

=cut

my $yfm_skip_array = 0;

=item B<control>[B<=>I<taglist>]

Handle control files.
A comma-separated list of tags to be translated can be provided.

=cut

my %control = ();

=item B<neverwrap>

Prevent po4a from wrapping any lines. This means that every content is handled verbatim, even simple paragraphs.

=cut

my $defaultwrap = 1;

my $parse_func = \&parse_fallback;

my @comments = ();

=back

=cut

sub initialize {
    my $self    = shift;
    my %options = @_;

    $self->{options}{'control'}         = "";
    $self->{options}{'breaks'}          = 1;
    $self->{options}{'debianchangelog'} = 1;
    $self->{options}{'debug'}           = 1;
    $self->{options}{'fortunes'}        = 1;
    $self->{options}{'markdown'}        = 1;
    $self->{options}{'yfm_keys'}        = '';
    $self->{options}{'yfm_skip_array'}  = 0;
    $self->{options}{'nobullets'}       = 0;
    $self->{options}{'keyvalue'}        = 1;
    $self->{options}{'tabs'}            = 1;
    $self->{options}{'verbose'}         = 1;
    $self->{options}{'neverwrap'}       = 1;

    foreach my $opt ( keys %options ) {
        die wrap_mod( "po4a::text", dgettext( "po4a", "Unknown option: %s" ), $opt )
          unless exists $self->{options}{$opt};
        $self->{options}{$opt} = $options{$opt};
    }

    $keyvalue    = 1                  if ( defined $options{'keyvalue'} );
    $bullets     = 0                  if ( defined $options{'nobullets'} );
    $tabs        = $options{'tabs'}   if ( defined $options{'tabs'} );
    $breaks      = $options{'breaks'} if ( defined $options{'breaks'} );
    $defaultwrap = 0                  if ( defined $options{'neverwrap'} );

    $parse_func = \&parse_debianchangelog if ( defined $options{'debianchangelog'} );
    $parse_func = \&parse_fortunes        if ( defined $options{'fortunes'} );

    if ( defined $options{'markdown'} ) {
        $parse_func = \&parse_markdown;
        $markdown   = 1;
        map {
            $_ =~ s/^\s+|\s+$//g;    # Trim the keys before using them
            $yfm_keys{$_} = 1
        } ( split( ',', $self->{options}{'yfm_keys'} ) );

        #        map { print STDERR "key $_\n"; } (keys %yfm_keys);
        $yfm_skip_array = $self->{options}{'yfm_skip_array'};
    } else {
        foreach my $opt (qw(yfm_keys yfm_skip_array)) {
            die wrap_mod( "po4a::text", dgettext( "po4a", "Option %s is only valid when parsing markdown files." ),
                $opt )
              if exists $options{$opt};
        }
    }

    if ( defined $options{'control'} ) {
        $parse_func = \&parse_control;
        if ( $options{'control'} eq "1" ) {
            $control{''} = 1;
        } else {
            foreach my $tag ( split( ',', $options{'control'} ) ) {
                $control{$tag} = 1;
            }
        }
    }
}

sub parse_fallback {
    my ( $self, $line, $ref, $paragraph, $wrapped_mode, $expect_header, $end_of_paragraph ) = @_;
    if (
        ( $line =~ /^\s*$/ )
        or ( defined $breaks
            and $line =~ m/^$breaks$/ )
      )
    {
        # Break paragraphs on lines containing only spaces
        do_paragraph( $self, $paragraph, $wrapped_mode );
        $paragraph    = "";
        $wrapped_mode = $defaultwrap unless defined( $self->{verbatim} );
        $self->pushline( $line . "\n" );
        undef $self->{controlkey};
    } elsif ( $line =~ /^-- $/ ) {

        # Break paragraphs on email signature hint
        do_paragraph( $self, $paragraph, $wrapped_mode );
        $paragraph    = "";
        $wrapped_mode = $defaultwrap;
        $self->pushline( $line . "\n" );
    } elsif ( $line =~ /^=+$/
        or $line =~ /^_+$/
        or $line =~ /^-+$/ )
    {
        $wrapped_mode = 0;
        $paragraph .= $line . "\n";
        do_paragraph( $self, $paragraph, $wrapped_mode );
        $paragraph    = "";
        $wrapped_mode = $defaultwrap;
    } elsif ( $tabs eq "split" and $line =~ m/\t/ and $paragraph !~ m/\t/s ) {
        $wrapped_mode = 0;
        do_paragraph( $self, $paragraph, $wrapped_mode );
        $paragraph    = "$line\n";
        $wrapped_mode = 0;
    } elsif ( $tabs eq "split" and $line !~ m/\t/ and $paragraph =~ m/\t/s ) {
        do_paragraph( $self, $paragraph, $wrapped_mode );
        $paragraph    = "$line\n";
        $wrapped_mode = $defaultwrap;
    } else {
        if ( $line =~ /^\s/ ) {

            # A line starting by a space indicates a non-wrap
            # paragraph
            $wrapped_mode = 0;
        }
        if (
            $markdown
            and (
                $line =~ /\S  $/     # explicit newline
                or $line =~ /"""$/
            )
          )
        {                            # """ textblock inside macro begin
                                     # Markdown markup needing separation _after_ this line
            $end_of_paragraph = 1;
        } else {
            undef $self->{bullet};
            undef $self->{indent};
        }

        # TODO: comments
        $paragraph .= $line . "\n";
    }
    return ( $paragraph, $wrapped_mode, $expect_header, $end_of_paragraph );
}

sub parse_debianchangelog {
    my ( $self, $line, $ref, $paragraph, $wrapped_mode, $expect_header, $end_of_paragraph ) = @_;
    if (
            $expect_header
        and $line =~ /^(\w[-+0-9a-z.]*)\ \(([^\(\) \t]+)\) # src, version
                   \s+([-+0-9a-z.]+);                 # distribution
                   \s*urgency\s*\=\s*(.*\S)\s*$/ix
      )
    {    #
        do_paragraph( $self, $paragraph, $wrapped_mode );
        $paragraph = "";
        $self->pushline("$line\n");
        $expect_header = 0;
    } elsif ( $line =~
        m/^ \-\- (.*) <(.*)>  ((\w+\,\s*)?\d{1,2}\s+\w+\s+\d{4}\s+\d{1,2}:\d\d:\d\d\s+[-+]\d{4}(\s+\([^\\\(\)]+\)))$/ )
    {
        # Found trailer
        do_paragraph( $self, $paragraph, $wrapped_mode );
        $paragraph = "";
        $self->pushline("$line\n");
        $expect_header = 1;
    } else {
        return parse_fallback( $self, $line, $ref, $paragraph, $wrapped_mode, $expect_header, $end_of_paragraph );
    }
    return ( $paragraph, $wrapped_mode, $expect_header, $end_of_paragraph );
}

sub parse_fortunes {
    my ( $self, $line, $ref, $paragraph, $wrapped_mode, $expect_header, $end_of_paragraph ) = @_;

    # Always include paragraphs in no-wrap mode,
    # because the formatting of the fortunes
    # is usually hand-crafted and matters.
    $wrapped_mode = 0;

    # Check if there are more lines in the file.
    my $last_line_of_file = 0;
    my ( $nextline, $nextref ) = $self->shiftline();
    if ( defined $nextline ) {

        # There is a next line, put it back.
        $self->unshiftline( $nextline, $nextref );
    } else {

        # Nope, no more lines available.
        $last_line_of_file = 1;
    }

    # Is the line the end of a fortune or the last line of the file?
    if ( $line =~ m/^%%?\s*$/ or $last_line_of_file ) {

        # Add the last line to the paragraph
        if ($last_line_of_file) {
            $paragraph .= $line;
        }

        # Remove the last newline for the translation.
        chomp($paragraph);
        do_paragraph( $self, $paragraph, $wrapped_mode );
        $paragraph = "";

        # Add the last newline again for the output.
        $self->pushline("\n");

        # Also add the separator line, if this is not the end of the file.
        if ( !$last_line_of_file ) {
            $self->pushline("$line\n");
        }
    } else {
        $paragraph .= $line . "\n";
    }
    return ( $paragraph, $wrapped_mode, $expect_header, $end_of_paragraph );
}

sub parse_control {
    my ( $self, $line, $ref, $paragraph, $wrapped_mode, $expect_header, $end_of_paragraph ) = @_;
    if ( $line =~ m/^([^ :]*): *(.*)$/ ) {
        warn wrap_mod( "po4a::text", dgettext( "po4a", "Unrecognized section: %s" ), $paragraph )
          unless $paragraph eq "";
        my $tag = $1;
        my $val = $2;
        my $t;
        if ( $control{''} or $control{$tag} ) {
            $t = $self->translate(
                $val, $self->{ref},
                $tag . ( defined $self->{controlkey} ? ", " . $self->{controlkey} : "" ),
                "wrap" => 0
            );
        } else {
            $t = $val;
        }
        if ( not defined $self->{controlkey} ) {
            $self->{controlkey} = "$tag: $val";
        }
        $self->pushline("$tag: $t\n");
        $paragraph      = "";
        $wrapped_mode   = $defaultwrap;
        $self->{bullet} = "";
        $self->{indent} = " ";
    } elsif ( $line eq " ." ) {
        do_paragraph( $self, $paragraph, $wrapped_mode,
            "Long Description" . ( defined $self->{controlkey} ? ", " . $self->{controlkey} : "" ) );
        $paragraph = "";
        $self->pushline( $line . "\n" );
        $self->{bullet} = "";
        $self->{indent} = " ";
    } elsif ( $line =~ m/^ Link: +(.*)$/ ) {
        do_paragraph( $self, $paragraph, $wrapped_mode,
            "Long Description" . ( defined $self->{controlkey} ? ", " . $self->{controlkey} : "" ) );
        my $link = $1;
        my $t1   = $self->translate( "Link: ", $self->{ref}, "Link", "wrap" => 0 );
        my $t2   = $self->translate(
            $link, $self->{ref},
            "Link" . ( defined $self->{controlkey} ? ", " . $self->{controlkey} : "" ),
            "wrap" => 0
        );
        $self->pushline(" $t1$t2\n");
        $paragraph = "";
    } elsif ( defined $self->{indent}
        and $line =~ m/^$self->{indent}\S/ )
    {
        $paragraph .= $line . "\n";
        $self->{type} = "Long Description" . ( defined $self->{controlkey} ? ", " . $self->{controlkey} : "" );
    } else {
        return parse_fallback( $self, $line, $ref, $paragraph, $wrapped_mode, $expect_header, $end_of_paragraph );
    }
    return ( $paragraph, $wrapped_mode, $expect_header, $end_of_paragraph );
}

# Support pandoc's format of specifying bibliographic information.
#
# If the first line starts with a percent sign, the following
# is considered to be title, author, and date.
#
# If the information spans multiple lines, the following
# lines must be indented with space.
# If information is omitted, it's just a percent sign
# and a blank line.
#
# Examples with missing title resp. missing authors:
#
# %
# % Author
#
# % My title
# %
# % June 14, 2018
sub parse_markdown_bibliographic_information {
    my ( $self, $line, $ref ) = @_;
    my ( $nextline, $nextref );

    # The first match is always the title or an empty string (no title).
    if ( $line =~ /^%(.*)$/ ) {
        my $title = $1;

        # Remove leading and trailing whitespace
        $title =~ s/^\s+|\s+$//g;

        # If there's some text, look for continuation lines
        if ( length($title) ) {
            ( $nextline, $nextref ) = $self->shiftline();
            while ( $nextline =~ /^\s+(.+)$/ ) {
                $nextline = $1;
                $nextline =~ s/^\s+|\s+$//g;
                $title .= " " . $nextline;
                ( $nextline, $nextref ) = $self->shiftline();
            }

            # Now the title should be complete, give it to translation.
            my $t = $self->translate( $title, $ref, "Pandoc title block", "wrap" => $defaultwrap );
            $t = Locale::Po4a::Po::wrap($t);
            my $first_line = 1;
            foreach my $translated_line ( split /\n/, $t ) {
                if ($first_line) {
                    $first_line = 0;
                    $self->pushline( "% " . $translated_line . "\n" );
                } else {
                    $self->pushline( "  " . $translated_line . "\n" );
                }
            }
        } else {

            # Title has been empty, fetch the next line
            # if that are the authors.
            $self->pushline("%\n");
            ( $nextline, $nextref ) = $self->shiftline();
        }

        # The next line can contain the author or an empty string.
        if ( $nextline =~ /^%(.*)$/ ) {
            my $author_ref = $nextref;
            my $authors    = $1;

            # If there's some text, look for continuation lines
            if ( length($authors) ) {
                ( $nextline, $nextref ) = $self->shiftline();
                while ( $nextline =~ /^\s+(.+)$/ ) {
                    $nextline = $1;
                    $authors .= ";" . $nextline;
                    ( $nextline, $nextref ) = $self->shiftline();
                }

                # Now the authors should be complete, split them by semicolon
                my $first_line = 1;
                foreach my $author ( split /;/, $authors ) {
                    $author =~ s/^\s+|\s+$//g;

                    # Skip empty authors
                    next unless length($author);
                    my $t = $self->translate( $author, $author_ref, "Pandoc title block" );
                    if ($first_line) {
                        $first_line = 0;
                        $self->pushline( "% " . $t . "\n" );
                    } else {
                        $self->pushline( "  " . $t . "\n" );
                    }
                }
            } else {

                # Authors has been empty, fetch the next line
                # if that is the date.
                $self->pushline("%\n");
                ( $nextline, $nextref ) = $self->shiftline();
            }

            # The next line can contain the date.
            if ( $nextline =~ /^%(.*)$/ ) {
                my $date = $1;

                # Remove leading and trailing whitespace
                $date =~ s/^\s+|\s+$//g;
                my $t = $self->translate( $date, $nextref, "Pandoc title block" );
                $self->pushline( "% " . $t . "\n" );

                # Now we're done with the bibliographic information
                return;
            }
        }

        # The line did not start with a percent sign, to stop
        # parsing bibliographic information and return the
        # line to the normal parsing.
        $self->unshiftline( $nextline, $nextref );
        return;
    }
}

# Support YAML Front Matter in Markdown documents
#
# If the text starts with a YAML ---\n separator, the full text until
# the next YAML ---\n separator is considered YAML metadata. The ...\n
# "end of document" separator can be used at the end of the YAML
# block.
#
sub parse_markdown_yaml_front_matter {
    my ( $self, $line, $blockref ) = @_;
    my $yfm;
    my ( $nextline, $nextref ) = $self->shiftline();
    while ( defined($nextline) ) {
        last if ( $nextline =~ /^(---|\.\.\.)$/ );
        $yfm .= $nextline;
        ( $nextline, $nextref ) = $self->shiftline();
    }
    die "Could not get the YAML Front Matter from the file." if ( length($yfm) == 0 );
    my $yamlarray = YAML::Tiny->read_string($yfm)
      || die "Couldn't read YAML Front Matter ($!)\n$yfm\n";

    $self->handle_yaml( $blockref, $yamlarray, \%yfm_keys, $yfm_skip_array );
    return;
}

sub parse_markdown {
    my ( $self, $line, $ref, $paragraph, $wrapped_mode, $expect_header, $end_of_paragraph ) = @_;
    if ($expect_header) {

        # It is only possible to find and parse the bibliographic
        # information or the YAML Front Matter from the first line.
        # Anyway, stop expecting header information for the next run.
        $expect_header = 0;
        if ( $line =~ /^%(.*)$/ ) {
            parse_markdown_bibliographic_information( $self, $line, $ref );
            return ( $paragraph, $wrapped_mode, $expect_header, $end_of_paragraph );
        } elsif ( $line =~ /^---$/ ) {
            parse_markdown_yaml_front_matter( $self, $line, $ref );
            return ( $paragraph, $wrapped_mode, $expect_header, $end_of_paragraph );
        }
    }
    if (    ( $line =~ m/^(={4,}|-{4,})$/ )
        and ( defined($paragraph) )
        and ( $paragraph =~ m/^[^\n]*\n$/s )
        and ( length($paragraph) == ( length($line) + 1 ) ) )
    {
        # XXX: There can be any number of underlining according
        #      to the documentation. This detection, which avoid
        #      translating the formatting, is only supported if
        #      the underlining has the same size as the header text.
        # Found title
        $wrapped_mode = 0;
        my $level = $line;
        $level =~ s/^(.).*$/$1/;

        # Remove the trailing newline from the title
        chomp($paragraph);
        my $t = $self->translate(
            $paragraph, $self->{ref}, "Title $level",
            "wrap"  => 0,
            "flags" => "markdown-text"
        );

        # Add the newline again for the output
        $self->pushline( $t . "\n" );
        $paragraph    = "";
        $wrapped_mode = $defaultwrap;
        $self->pushline( ( $level x length($t) ) . "\n" );
    } elsif ( $line =~ m/^(#{1,6})( +)(.*?)( +\1)?$/ ) {
        my $titlelevel1 = $1;
        my $titlespaces = $2;
        my $title       = $3;
        my $titlelevel2 = $4 || "";

        # Found one line title
        do_paragraph( $self, $paragraph, $wrapped_mode );
        $wrapped_mode = 0;
        $paragraph    = "";
        my $t = $self->translate(
            $title, $self->{ref}, "Title $titlelevel1",
            "wrap"  => 0,
            "flags" => "markdown-text"
        );
        $self->pushline( $titlelevel1 . $titlespaces . $t . $titlelevel2 . "\n" );
        $wrapped_mode = $defaultwrap;
    } elsif ( $line =~ /^[ ]{0,3}([*_-])\s*(?:\1\s*){2,}$/ ) {

        # Horizontal rule
        do_paragraph( $self, $paragraph, $wrapped_mode );
        $self->pushline( $line . "\n" );
        $paragraph        = "";
        $end_of_paragraph = 1;
    } elsif ( $line =~ /^([ ]{0,3})(([~`])\3{2,})(\s*)([^`]*)\s*$/ ) {
        my $fence_space_before  = $1;
        my $fence               = $2;
        my $fencechar           = $3;
        my $fence_space_between = $4;
        my $info_string         = $5;

        # fenced code block
        my $type = "Fenced code block" . ( $info_string ? " ($info_string)" : "" );
        do_paragraph( $self, $paragraph, $wrapped_mode );
        $wrapped_mode = 0;
        $paragraph    = "";
        $self->pushline("$line\n");
        do_paragraph( $self, $paragraph, $wrapped_mode );
        $paragraph = "";
        my ( $nextline, $nextref ) = $self->shiftline();

        while ( $nextline !~ /^\s{0,3}$fence$fencechar*\s*$/ ) {
            $paragraph .= "$nextline";
            ( $nextline, $nextref ) = $self->shiftline();
        }
        do_paragraph( $self, $paragraph, $wrapped_mode, $type );
        $self->pushline($nextline);
        $paragraph        = "";
        $end_of_paragraph = 1;
    } elsif (
        $line =~ /^\s*\[\[\!\S+\s*$/       # macro begin
        or $line =~ /^\s*"""\s*\]\]\s*$/
      )
    {                                      # """ textblock inside macro end
                                           # Avoid translating Markdown lines containing only markup
        do_paragraph( $self, $paragraph, $wrapped_mode );
        $paragraph    = "";
        $wrapped_mode = $defaultwrap;
        $self->pushline("$line\n");
    } elsif ( $line =~ /^\s*\[\[\!\S[^\]]*\]\]\s*$/ ) {    # sole macro
                                                           # Preserve some Markdown markup as a single line
        do_paragraph( $self, $paragraph, $wrapped_mode );
        $paragraph        = "$line\n";
        $wrapped_mode     = 0;
        $end_of_paragraph = 1;
    } elsif ( $line =~ /^"""/ ) {                          # """ textblock inside macro end
                                                           # Markdown markup needing separation _before_ this line
        do_paragraph( $self, $paragraph, $wrapped_mode );
        $paragraph    = "$line\n";
        $wrapped_mode = $defaultwrap;
    } else {
        return parse_fallback( $self, $line, $ref, $paragraph, $wrapped_mode, $expect_header, $end_of_paragraph );
    }
    return ( $paragraph, $wrapped_mode, $expect_header, $end_of_paragraph );
}

sub parse {
    my $self = shift;
    my ( $line, $ref );
    my $paragraph        = "";
    my $wrapped_mode     = $defaultwrap;
    my $expect_header    = 1;
    my $end_of_paragraph = 0;
    ( $line, $ref ) = $self->shiftline();
    my $file = $ref;
    $file =~ s/:[0-9]+$// if defined($line);

    while ( defined($line) ) {
        $ref =~ m/^(.*):[0-9]+$/;
        if ( $1 ne $file ) {
            $file = $1;
            do_paragraph( $self, $paragraph, $wrapped_mode );
            $paragraph     = "";
            $wrapped_mode  = $defaultwrap;
            $expect_header = 1;
        }

        chomp($line);
        $self->{ref} = "$ref";
        ( $paragraph, $wrapped_mode, $expect_header, $end_of_paragraph ) =
          &$parse_func( $self, $line, $ref, $paragraph, $wrapped_mode, $expect_header, $end_of_paragraph );

        # paragraphs starting by a bullet, or numbered
        # or paragraphs with a line containing many consecutive spaces
        # (more than 3)
        # are considered as verbatim paragraphs
        $wrapped_mode = 0 if ( $paragraph =~ m/^(\*|[0-9]+[.)] )/s
            or $paragraph =~ m/[ \t][ \t][ \t]/s );
        $wrapped_mode = 0 if ( $tabs eq "verbatim"
            and $paragraph =~ m/\t/s );

        # Also consider keyvalue paragraphs verbatim, if requested
        $wrapped_mode = 0 if ( $keyvalue == 1
            and $paragraph =~ m/^[^ :]+:.*[^\s].*$/s );
        if ($markdown) {

            # Some Markdown markup can (or might) not survive wrapping
            $wrapped_mode = 0
              if (
                $paragraph    =~ /^>/ms                     # blockquote
                or $paragraph =~ /^( {8}|\t)/ms             # monospaced
                or $paragraph =~ /^\$(\S+[{}]\S*\s*)+/ms    # Xapian macro
                or $paragraph =~ /<(?![a-z]+[:@])/ms        # maybe html (tags but not wiki <URI>)
                or $paragraph =~ /^[^<]+>/ms                # maybe html (tag with vertical space)
                or $paragraph =~ /\S  $/ms                  # explicit newline
                or $paragraph =~ /\[\[\!\S[^\]]+$/ms        # macro begin
              );
        }
        if ($end_of_paragraph) {
            do_paragraph( $self, $paragraph, $wrapped_mode );
            $paragraph        = "";
            $wrapped_mode     = $defaultwrap;
            $end_of_paragraph = 0;
        }
        ( $line, $ref ) = $self->shiftline();
    }
    if ( length $paragraph ) {
        do_paragraph( $self, $paragraph, $wrapped_mode );
    }
}

sub do_paragraph {
    my ( $self, $paragraph, $wrap ) = ( shift, shift, shift );
    my $type  = shift || $self->{type} || "Plain text";
    my $flags = "";
    if ( $type eq "Plain text" and $markdown ) {
        $flags = "markdown-text";
    }

    return if ( $paragraph eq "" );

    $wrap = 0 unless $defaultwrap;

    # DEBUG
    #    my $b;
    #    if (defined $self->{bullet}) {
    #            $b = $self->{bullet};
    #    } else {
    #            $b = "UNDEF";
    #    }
    #    $type .= " verbatim: '".($self->{verbatim}||"NONE")."' bullet: '$b' indent: '".($self->{indent}||"NONE")."' type: '".($self->{type}||"NONE")."'";

    if ( $bullets and not $wrap and not defined $self->{verbatim} ) {

        # Detect bullets
        # |        * blah blah
        # |<spaces>  blah
        # |          ^-- aligned
        # <empty line>
        #
        # Other bullets supported:
        # - blah         o blah         + blah
        # 1. blah       1) blah       (1) blah
      TEST_BULLET:
        if ( $paragraph =~ m/^(\s*)((?:[-*o+]|([0-9]+[.\)])|\([0-9]+\))\s+)([^\n]*\n)(.*)$/s ) {
            my $para    = $5;
            my $bullet  = $2;
            my $indent1 = $1;
            my $indent2 = "$1" . ( ' ' x length $bullet );
            my $text    = $4;
            while ( $para !~ m/^$indent2(?:[-*o+]|([0-9]+[.\)])|\([0-9]+\))\s+/
                and $para =~ s/^$indent2(\S[^\n]*\n)//s )
            {
                $text .= $1;
            }

            # TODO: detect if a line starts with the same bullet
            if ( $text !~ m/\S[ \t][ \t][ \t]+\S/s ) {
                my $bullet_regex = quotemeta( $indent1 . $bullet );
                $bullet_regex =~ s/[0-9]+/\\d\+/;
                if (   $para eq ''
                    or $para =~ m/^(\s*)((?:[-*o+]|([0-9]+[.\)])|\([0-9]+\))\s+)([^\n]*\n)(.*)$/s
                    or $para =~ m/^$bullet_regex\S/s )
                {
                    my $trans = $self->translate(
                        $text,
                        $self->{ref},
                        "Bullet: '$indent1$bullet'",
                        "flags"   => "markdown-text",
                        "wrap"    => $defaultwrap,
                        "wrapcol" => -( length $indent2 )
                    );
                    $trans =~ s/^/$indent1$bullet/s;
                    $trans =~ s/\n(.)/\n$indent2$1/sg;
                    $self->pushline( $trans . "\n" );
                    if ( $para eq '' ) {
                        return;
                    } else {

                        # Another bullet
                        $paragraph = $para;
                        goto TEST_BULLET;
                    }
                }
            }
        }
    }

    my $end = "";
    if ($wrap) {
        $paragraph =~ s/^(.*?)(\n*)$/$1/s;
        $end = $2 || "";
    }
    my $t = $self->translate(
        $paragraph,
        $self->{ref},
        $type,
        "comment" => join( "\n", @comments ),
        "flags"   => $flags,
        "wrap"    => $wrap
    );
    @comments = ();
    if ( defined $self->{bullet} ) {
        my $bullet  = $self->{bullet};
        my $indent1 = $self->{indent};
        my $indent2 = $indent1 . ( ' ' x length($bullet) );
        $t =~ s/^/$indent1$bullet/s;
        $t =~ s/\n(.)/\n$indent2$1/sg;
    }
    $self->pushline( $t . $end );
}

1;

=head1 STATUS OF THIS MODULE

Tested successfully on simple text files and NEWS.Debian files.

=head1 AUTHORS

 Nicolas François <nicolas.francois@centraliens.net>

=head1 COPYRIGHT AND LICENSE

 Copyright © 2005-2008 Nicolas FRANÇOIS <nicolas.francois@centraliens.net>.

 Copyright © 2008-2009, 2018 Jonas Smedegaard <dr@jones.dk>.
 Copyright © 2020 Martin Quinson <mquinson#debian.org>.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see the COPYING file).

=cut
