#!/usr/bin/perl -w

# http://asciidoc.org/userguide.html

=encoding UTF-8

=head1 NAME

Locale::Po4a::AsciiDoc - convert AsciiDoc documents from/to PO files

=head1 DESCRIPTION

The po4a (PO for anything) project goal is to ease translations (and more
interestingly, the maintenance of translations) using gettext tools on
areas where they were not expected like documentation.

Locale::Po4a::AsciiDoc is a module to help the translation of documentation in
the AsciiDoc format.

=cut

package Locale::Po4a::AsciiDoc;

use 5.010;
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

=item B<definitions>

The name of a file containing definitions for po4a, as defined in the
B<INLINE CUSTOMIZATION> section.
You can use this option if it is not possible to put the definitions in
the document being translated.

In a definitions file, lines must not start by two slashes, but directly
by B<po4a:>.

=item B<entry>

Space-separated list of attribute entries you want to translate.  By default,
no attribute entries are translatable.

=item B<macro>

Space-separated list of macro definitions.

=item B<style>

Space-separated list of style definitions.

=item B<forcewrap>

Enable automatic line wrapping in non-verbatim blocks, even if the
result could be misinterpreted by AsciiDoc formatters.

By default, po4a will not wrap the produced AsciiDoc files because a
manual inspection is mandated to ensure that the wrapping does not
change the formatting. Consider for instance the following list
item:

 * a long sentence that is ending with a number 1. A second sentence.

If the wrapping leads to the following presentation, the item is
split into a numbered sub-list. To make things worse, only the
speakers of the language used in the translation can inspect the
situation.

 * a long sentence that is ending with a number
   1. A second sentence.

Note that not wrapping the files produced by po4a should not be a
problem since those files are meant to be processed automatically.
They should not be regarded as source files anyway.

With this option, po4a will produce better-looking source files, that
may lead to possibly erroneous formatted outputs.

=item B<noimagetargets>

By default, the targets of block images are translatable to give opportunity
to make the content point to translated images. This can be stopped by setting
this option.

=item B<tablecells>

This option is a flag that enables sub-table segmentation into cell content.
The segmentation is limited to cell content, without any parsing inside of it.

=item B<compat>

Switch parsing rules to compatibility with different tools. Available options are
"asciidoc" or "asciidoctor". Asciidoctor has stricter parsing rules, such as
equality of length of opening and closing block fences.

=item B<yfm_keys>

Comma-separated list of keys to process for translation in the YAML Front Matter
section. All other keys are skipped. Keys are matched with a case-insensitive
match. Array values are always translated, unless the B<yfm_skip_array> option
is provided.

=item B<nolinting>

Disable linting messages. When the source code cannot be fixed for clearer document structure, these messages are useless.

=cut

my %yfm_keys = ();

=item B<yfm_skip_array>

Do not translate array values in the YAML Front Matter section.

=cut

my $yfm_skip_array = 0;

=back

=head1 INLINE CUSTOMIZATION

The AsciiDoc module can be customized with lines starting by B<//po4a:>.
These lines are interpreted as commands to the parser.
The following commands are recognized:

=over 4

=item B<//po4a: macro >I<name>B<[>I<attribute list>B<]>

This permits to describe in detail the parameters of a B<macro>;
I<name> must be a valid macro name, and it ends with an underscore
if the target must be translated.

The I<attribute list> argument is a comma separated list which
contains informations about translatable arguments.  This list contains
either numbers, to define positional parameters, or named attributes.

If a plus sign (B<+>) is prepended to I<name>, then the macro and its
arguments are translated as a whole.  There is no need to define
attribute list in this case, but brackets must be present.

=item B<//po4a: style >B<[>I<attribute list>B<]>

This permits to describe in detail which attributes of a style must
be translated.

The I<attribute list> argument is a comma separated list which
contains informations about translatable arguments.  This list contains
either numbers, to define positional parameters, or named attributes.
The first attribute is the style name, it will not be translated.

If a plus sign (B<+>) is prepended to the style name, then the
attribute list is translated as a whole.  There is no need to define
translatable attributes.

If a minus sign (B<->) is prepended to the style name, then this
attribute is not translated.

=item B<//po4a: entry >I<name>

This declares an attribute entry as being translatable.  By default,
they are not translated.

=back

=cut

my @comments = ();

my %debug = (
    'split_attributelist' => 0,
    'join_attributelist'  => 0,
    'parse'               => 0,
);

sub initialize {
    my $self    = shift;
    my %options = @_;

    $self->{options}{'nobullets'}      = 1;
    $self->{options}{'forcewrap'}      = 0;
    $self->{options}{'debug'}          = '';
    $self->{options}{'verbose'}        = 1;
    $self->{options}{'entry'}          = '';
    $self->{options}{'macro'}          = '';
    $self->{options}{'style'}          = '';
    $self->{options}{'definitions'}    = '';
    $self->{options}{'noimagetargets'} = 0;
    $self->{options}{'tablecells'}     = 0;
    $self->{options}{'compat'}         = 'asciidoc';
    $self->{options}{'yfm_keys'}       = '';
    $self->{options}{'yfm_skip_array'} = 0;
    $self->{options}{'nolinting'}      = 0;

    foreach my $opt ( keys %options ) {
        die wrap_mod( "po4a::asciidoc", dgettext( "po4a", "Unknown option: %s" ), $opt )
          unless exists $self->{options}{$opt};
        $self->{options}{$opt} = $options{$opt};
    }

    my $compat = $self->{options}{'compat'};
    die wrap_mod( "po4a::asciidoc",
        dgettext( "po4a", "Invalid compatibility setting: '%s'. It must be either '%s' or '%s'." ),
        $compat, 'asciidoc', 'asciidoctor' )
      if ( defined $compat && $compat ne "asciidoc" && $compat ne "asciidoctor" );

    if ( $options{'debug'} ) {
        foreach ( $options{'debug'} ) {
            $debug{$_} = 1;
        }
    }
    map {
        $_ =~ s/^\s+|\s+$//g;    # Trim the keys before using them
        $yfm_keys{$_} = 1
    } ( split( ',', $self->{options}{'yfm_keys'} ) );

    #        map { print STDERR "key $_\n"; } (keys %yfm_keys);
    $yfm_skip_array = $self->{options}{'yfm_skip_array'};

    $self->{translate} = {
        macro => {},
        style => {},
        entry => {}
    };

    $self->register_attributelist('[verse,2,3,attribution,citetitle]');
    $self->register_attributelist('[quote,2,3,attribution,citetitle]');
    $self->register_attributelist('[icon]');
    $self->register_attributelist('[caption]');
    $self->register_attributelist('[-icons,caption]');
    $self->register_macro('image_[1,alt,title,link]') unless $self->{options}{'noimagetargets'};

    if ( $self->{options}{'definitions'} ) {
        $self->parse_definition_file( $self->{options}{'definitions'} );
    }
    $self->{options}{entry} =~ s/^\s*//;
    foreach my $attr ( split( /\s+/, $self->{options}{entry} ) ) {
        $self->{translate}->{entry}->{$attr} = 1;
    }
    $self->{options}{macro} =~ s/^\s*//;
    foreach my $attr ( split( /\s+/, $self->{options}{macro} ) ) {
        $self->register_macro($attr);
    }
    $self->{options}{style} =~ s/^\s*//;
    foreach my $attr ( split( /\s+/, $self->{options}{style} ) ) {
        $self->register_attributelist($attr);
    }

}

sub register_attributelist {
    my $self = shift;
    my $list = shift;
    my $type = shift || 'style';
    $list =~ s/^\[//;
    $list =~ s/\]$//;
    $list =~ s/\s+//;
    $list = "," . $list . ",";
    $list =~ m/^,([-+]?)([^,]*)/;
    my $command = $2;
    $self->{translate}->{$type}->{$command} = $list;
    print STDERR "Definition: $type $command: $list\n" if $debug{definitions};
}

sub register_macro {
    my $self = shift;
    my $text = shift;
    die wrap_mod( "po4a::asciidoc", dgettext( "po4a", "Unable to parse macro definition: %s" ), $text )
      unless $text =~ m/^(\+?)([\w\d][\w\d-]*?)(_?)\[(.*)\]$/;
    my $macroplus   = $1;
    my $macroname   = $2;
    my $macrotarget = $3;
    my $macroparam  = $macroname . "," . $4;
    $self->register_attributelist( $macroparam, 'macro' );

    if ( $macrotarget eq '_' ) {
        $self->{translate}->{macro}->{$macroname} .= '_';
    }
    if ( $macroplus eq '+' ) {
        $self->{translate}->{macro}->{$macroname} =~ s/^,/,+/;
    }
}

sub is_translated_target {
    my $self      = shift;
    my $macroname = shift;
    return defined( $self->{translate}->{macro}->{$macroname} )
      && $self->{translate}->{macro}->{$macroname} =~ m/_$/;
}

sub is_unsplitted_attributelist {
    my $self = shift;
    my $name = shift;
    my $type = shift;
    return defined( $self->{translate}->{$type}->{$name} )
      && $self->{translate}->{$type}->{$name} =~ m/^,\+/;
}

sub process_definition {
    my $self    = shift;
    my $command = shift;
    if ( $command =~ m/^po4a: macro\s+(.*\[.*\])\s*$/ ) {
        $self->register_macro($1);
    } elsif ( $command =~ m/^po4a: style\s*(\[.*\])\s*$/ ) {
        $self->register_attributelist($1);
    } elsif ( $command =~ m/^po4a: entry\s+(.+?)\s*$/ ) {
        $self->{translate}->{entry}->{$1} = 1;
    }
}

sub parse_definition_file {
    my $self     = shift;
    my $filename = shift;
    if ( !open( IN, "<", $filename ) ) {
        die wrap_mod( "po4a::asciidoc", dgettext( "po4a", "Cannot open %s: %s" ), $filename, $! );
    }
    while (<IN>) {
        chomp;
        process_definition( $self, $_ );
    }
    close IN;
}

my $RE_SECTION_TEMPLATES = "sect1|sect2|sect3|sect4|preface|colophon|dedication|synopsis|index";
my $RE_STYLE_ADMONITION  = "TIP|NOTE|IMPORTANT|WARNING|CAUTION";
my $RE_STYLE_PARAGRAPH =
  "normal|literal|verse|quote|listing|abstract|partintro|comment|example|sidebar|source|music|latex|graphviz";
my $RE_STYLE_NUMBERING = "arabic|loweralpha|upperalpha|lowerroman|upperroman";
my $RE_STYLE_LIST      = "appendix|horizontal|qanda|glossary|bibliography";
my $RE_STYLES =
  "$RE_SECTION_TEMPLATES|$RE_STYLE_ADMONITION|$RE_STYLE_PARAGRAPH|$RE_STYLE_NUMBERING|$RE_STYLE_LIST|float";

BEGIN {
    my $UnicodeGCString_available = 0;
    $UnicodeGCString_available = 1 if ( eval { require Unicode::GCString } );
    eval {
        sub chars($$$) {
            my $text    = shift;
            my $encoder = shift;
            $text = $encoder->decode($text) if ( defined($encoder) && $encoder->name ne "ascii" );
            if ($UnicodeGCString_available) {
                return Unicode::GCString->new($text)->chars();
            } else {
                $text =~ s/\n$//s;
                return length($text) if !( defined($encoder) && $encoder->name ne "ascii" );
                eval { require Unicode::GCString };
                die wrap_mod(
                    "po4a::asciidoc",
                    dgettext(
                        "po4a",
                        "Detection of two line titles failed at %s\nPlease install the Unicode::GCString module (error: %s)."
                    ),
                    shift, $@
                );
            }
        }
    };
}

sub parse {
    my $self = shift;
    my ( $line, $ref ) = $self->shiftline();

    # Handle the YAML Front Matter, if any
    if ( defined($line) && $line =~ /^---$/ ) {
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

        $self->handle_yaml( $ref, $yamlarray, \%yfm_keys, $yfm_skip_array );

        ( $line, $ref ) = $self->shiftline();    # Pass the final '---'
    }

    my $paragraph    = "";
    my $wrapped_mode = 1;
    my $file         = $ref;
    $file =~ s/:[0-9]+$// if defined($line);

    while ( defined($line) ) {
        $ref =~ m/^(.*):[0-9]+$/;
        if ( $1 ne $file ) {
            $file = $1;
            do_paragraph( $self, $paragraph, $wrapped_mode );
            $paragraph    = "";
            $wrapped_mode = 1;
        }

        chomp($line);
        print STDERR "Seen $ref $line\n"
          if ( $debug{parse} );
        $self->{ref} = "$ref";
        if ( ( defined $self->{verbatim} ) and ( $self->{verbatim} == 3 ) ) {

            # Untranslated blocks
            $self->pushline( $line . "\n" );
            if ( $line =~ m/^~{4,}$/ ) {
                undef $self->{verbatim};
                undef $self->{type};
                $wrapped_mode = 1;
            }
        } elsif ( ( defined $self->{verbatim} ) and ( $self->{verbatim} == 2 ) ) {

            # CommentBlock
            if ( $line =~ m/^\/{4,}$/ ) {
                undef $self->{verbatim};
                undef $self->{type};
                $wrapped_mode = 1;
            } else {
                push @comments, $line;
            }
            do_paragraph( $self, $paragraph, $wrapped_mode );
            $paragraph    = "";
            $wrapped_mode = 1 unless defined( $self->{verbatim} );
            $self->pushline( $line . "\n" );
        } elsif ( ( defined $self->{type} )
            and ( $self->{type} eq "Table" )
            and ( $line !~ m/^\|===/ )
            and ( $self->{options}{"tablecells"} )
			and (not defined $self->{disabletablecells}))
        {
            # inside a table, and we should split per cell
            my $new_line = "";
            my @texts    = split /(?:(?:\d+|\d*(?:\.\d+)?)(?:\+|\*))?[<^>]?(?:\.[<^>])?[demshalv]?\|/, $line;
            my @seps     = ($line) =~ m/(?:(?:\d+|\d*(?:\.\d+)?)(?:\+|\*))?[<^>]?(?:\.[<^>])?[demshalv]?\|/g;
            if ( ( scalar(@texts) and length( $texts[0] ) ) || ( !length($line) ) ) {
                if ( !length($line) ) { $texts[0] = ""; }
                if ( length($paragraph) ) {

                    # if we are in a continuation line
                    $paragraph .= "\n" . $texts[0];
                } else {
                    $paragraph = $texts[0];
                    $self->pushline("\n");
                }
            } elsif ( length($paragraph) ) {
                $new_line = "\n";
            }

            shift @texts;
            my @parts = map { ( $_, shift @texts ) } @seps;
            foreach my $part (@parts) {
                if ( not defined $part ) {
					# allows concatenation and will be stripped anyway
					$part = " "; }
                if ( $part =~ /\|$/ ) {

                    # this is a cell separator. End the previous cell
                    do_stripped_unwrapped_paragraph( $self, $paragraph, $wrapped_mode );
                    if ( $new_line eq "\n" ) {
                        $self->pushline("\n");
                        $new_line = "";
                    }
                    $paragraph = "";
                    $self->pushline($part);
                } else {

                    # this is content. Append it.
                    $paragraph .= $part;
                }
            }

        } elsif ( ( not defined( $self->{verbatim} ) ) and ( $line =~ m/^(\+|--)$/ ) ) {

            # List Item Continuation or List Block
            do_paragraph( $self, $paragraph, $wrapped_mode );
            $paragraph    = "";
            $wrapped_mode = 1 unless defined( $self->{verbatim} );
            $self->pushline( $line . "\n" );

            # TODO: add support for Open blocks
        } elsif (
            ( not defined( $self->{verbatim} ) )
            and ( $line =~ m/^(={2,}|-{2,}|~{2,}|\^{2,}|\+{2,})$/ )
            and ( defined($paragraph) )
            and ( $paragraph =~ m/^[^\n]*\n$/s )
            and

            # subtract one because chars includes the newline on the paragraph
            ( abs( ( chars( $paragraph, $self->{TT}{po_in}{encoder}, $ref ) - 1 ) - length($line) ) < 3 )
          )
        {
            # Found title

            $wrapped_mode = 0;
            my $level = $line;
            $level     =~ s/^(.).*$/$1/;
            $paragraph =~ s/\n$//s;

            warn wrap_mod(
                "$ref",
                dgettext(
                    "po4a",
                    "'%s' seems to be a two-lines title underlined with '%s', but the underlines are too short or too long compared to the title length. "
                      . "You may want to fix your master document."
                ),
                $paragraph,
                $level
              )
              if ( ( chars( $paragraph, $self->{TT}{po_in}{encoder}, $ref ) != length($line) )
                && ( !$self->{options}{'nolinting'} ) );

            my $t = $self->translate(
                $paragraph,
                $self->{ref},
                "Title $level",
                "comment" => join( "\n", @comments ),
                "wrap"    => 0
            );
            $self->pushline( $t . "\n" );
            $paragraph    = "";
            @comments     = ();
            $wrapped_mode = 1;
            $self->pushline( ( $level x ( chars( $t, $self->{TT}{po_in}{encoder}, $ref ) ) ) . "\n" );
        } elsif ( $line =~ m/^(={1,5})( +)(.*?)( +\1)?$/ ) {
            my $titlelevel1 = $1;
            my $titlespaces = $2;
            my $title       = $3;
            my $titlelevel2 = $4 || "";

            # Found one line title
            do_paragraph( $self, $paragraph, $wrapped_mode );
            $wrapped_mode = 0;
            $paragraph    = "";
            my $t = $self->translate(
                $title,
                $self->{ref},
                "Title $titlelevel1",
                "comment" => join( "\n", @comments ),
                "wrap"    => 0
            );
            $self->pushline( $titlelevel1 . $titlespaces . $t . $titlelevel2 . "\n" );
            @comments     = ();
            $wrapped_mode = 1;
        } elsif ( ( $line =~ m/^(\/{4,}|\+{4,}|-{4,}|\.{4,}|\*{4,}|_{4,}|={4,}|~{4,})$/ )
            and ( !defined( $self->{type} ) or ( defined( $self->{type} ) and ( $self->{type} !~ /^Table/i ) ) ) )
        {
            # Found one delimited block
            my $t = $line;
            $t =~ s/^(.).*$/$1/;
            my $l    = length $line;
            my $type = "delimited block $t";
            $type = "$type $l" if ( $self->{options}{'compat'} eq 'asciidoctor' );
            if ( defined $self->{verbatim} and ( $self->{type} ne $type ) ) {
                $paragraph .= "$line\n";
            } else {
                do_paragraph( $self, $paragraph, $wrapped_mode );
                if (    ( defined $self->{type} )
                    and ( $self->{type} eq $type ) )
                {
                    undef $self->{type};
                    undef $self->{verbatim};
                    undef $self->{bullet};
                    undef $self->{indent};
                    $wrapped_mode = 1;
                    print STDERR "Closing $t block\n" if $debug{parse};
                } else {
                    print STDERR "Begining $t block\n" if $debug{parse};
                    if ( $t eq "\/" ) {

                        # CommentBlock, should not be treated
                        $self->{verbatim} = 2;
                    } elsif ( $t eq "+" ) {

                        # PassthroughBlock
                        $wrapped_mode = 0;
                        $self->{verbatim} = 1;
                    } elsif ( $t eq "-" or $t eq "|" ) {

                        # ListingBlock
                        $wrapped_mode = 0;
                        $self->{verbatim} = 1;
                    } elsif ( $t eq "." ) {

                        # LiteralBlock
                        $wrapped_mode = 0;
                        $self->{verbatim} = 1;
                    } elsif ( $t eq "*" ) {

                        # SidebarBlock
                        $wrapped_mode = 1;
                    } elsif ( $t eq "_" ) {

                        # QuoteBlock
                        if (    ( defined $self->{type} )
                            and ( $self->{type} eq "verse" ) )
                        {
                            $wrapped_mode = 0;
                            $self->{verbatim} = 1;
                            print STDERR "QuoteBlock verse\n" if $debug{parse};
                        } else {
                            $wrapped_mode = 1;
                        }
                    } elsif ( $t eq "=" ) {

                        # ExampleBlock
                        $wrapped_mode = 1;
                    } elsif ( $t eq "~" ) {

                        # Filter blocks, TBC: not translated
                        $wrapped_mode = 0;
                        $self->{verbatim} = 3;
                    }
                    $self->{type} = $type;
                }
                $paragraph = "";
                $self->pushline( $line . "\n" );
            }
        } elsif ( ( not defined( $self->{verbatim} ) ) and ( $line =~ m/^\/\/(.*)/ ) ) {
            my $comment = $1;
            if ( $comment =~ m/^po4a: / ) {

                # Po4a command line
                $self->process_definition($comment);
            } else {

                # Comment line
                push @comments, $comment;
            }
            do_paragraph( $self, $paragraph, $wrapped_mode ) if length($paragraph);
            $paragraph    = "";
            $wrapped_mode = 1;

            $self->pushline( $line . "\n" );
        } elsif ( not defined $self->{verbatim}
            and ( $line =~ m/^\[\[([^\]]*)\]\]$/ ) )
        {
            # Found BlockId
            do_paragraph( $self, $paragraph, $wrapped_mode );
            $paragraph    = "";
            $wrapped_mode = 1;
            $self->pushline( $line . "\n" );
            undef $self->{bullet};
            undef $self->{indent};
        } elsif ( not defined $self->{verbatim}
            and ( $paragraph eq "" )
            and ( $line =~ m/^((?:$RE_STYLE_ADMONITION):\s+)(.*)$/ ) )
        {
            my $type = $1;
            my $text = $2;
            do_paragraph( $self, $paragraph, $wrapped_mode );
            $paragraph    = $text . "\n";
            $wrapped_mode = 1;
            $self->pushline($type);
            undef $self->{bullet};
            undef $self->{indent};
        } elsif ( not defined $self->{verbatim}
            and ( $line =~ m/^\[($RE_STYLES)\]$/ ) )
        {
            my $type = $1;
            do_paragraph( $self, $paragraph, $wrapped_mode );
            $paragraph    = "";
            $wrapped_mode = 1;
            $self->pushline( $line . "\n" );
            if ( $type eq "verse" ) {
                $wrapped_mode = 0;
            }
            undef $self->{bullet};
            undef $self->{indent};
        } elsif ( not defined $self->{verbatim}
            and ( $line =~ m/^\[.*\]$/ ) )
        {
            do_paragraph( $self, $paragraph, $wrapped_mode );
            $paragraph = "";
            my $t = $self->parse_style($line);
            $self->pushline("$t\n");
            @comments     = ();
            $wrapped_mode = 1;
            if ( $line =~ m/^\[(['"]?)(verse|quote)\1,/ ) {
                $self->{type} = $2;
                if ( $self->{type} eq 'verse' ) {
                    $wrapped_mode = 0;
                }
                print STDERR "Starting verse\n" if $debug{parse};
            }
            if ((( $line =~ m/^\[format=(['"]?)(csv|tsv|dsv)\1,/ ) ||
				( $line =~ m/^\[separator=[^\|]/ )) &&
				$self->{options}{'tablecells'}) {
                warn wrap_mod(
                    "$ref",
                    dgettext(
                        "po4a",
                        "Po4a's tablecells mode only supports PSV formatted tables with '|' separators. Disabling tablecells and falling back to block mode for this table."
                    )
                );
				$self->{disabletablecells} = 1;
            }
            undef $self->{bullet};
            undef $self->{indent};
        } elsif ( not defined $self->{verbatim}
            and ( $line =~ m/^(\s*)([-%~\$[*_+`'#<>[:alnum:]\\"(].*?)((?::::?|;;|\?\?|:-)(?: *\\)?)$/ ) )
        {
            my $indent   = $1;
            my $label    = $2;
            my $labelend = $3;

            # Found labeled list
            do_paragraph( $self, $paragraph, $wrapped_mode );
            $paragraph      = "";
            $wrapped_mode   = 1;
            $self->{bullet} = "";
            $self->{indent} = $indent;
            my $t = $self->translate(
                $label,
                $self->{ref},
                "Labeled list",
                "comment" => join( "\n", @comments ),
                "wrap"    => 0
            );
            $self->pushline("$indent$t$labelend\n");
            @comments = ();
        } elsif ( not defined $self->{verbatim}
            and ( $line =~ m/^(\s*)(\S.*?)((?::?::|;;)\s+)(.*)$/ ) )
        {
            my $indent    = $1;
            my $label     = $2;
            my $labelend  = $3;
            my $labeltext = $4;

            # Found Horizontal Labeled Lists
            do_paragraph( $self, $paragraph, $wrapped_mode );
            $paragraph      = $labeltext . "\n";
            $wrapped_mode   = 1;
            $self->{bullet} = "";
            $self->{indent} = $indent;
            my $t = $self->translate(
                $label,
                $self->{ref},
                "Labeled list",
                "comment" => join( "\n", @comments ),
                "wrap"    => 0
            );
            $self->pushline("$indent$t$labelend");
            @comments = ();
        } elsif ( not defined $self->{verbatim}
            and ( $line =~ m/^\:(\S.*?)(:\s*)(.*)$/ ) )
        {
            my $attrname  = $1;
            my $attrsep   = $2;
            my $attrvalue = $3;
            while ( $attrvalue =~ s/ \+$//s ) {
                ( $line, $ref ) = $self->shiftline();
                $ref  =~ m/^(.*):[0-9]+$/;
                $line =~ s/^\s+//;
                $attrvalue .= $line;
            }

            # Found an Attribute entry
            do_paragraph( $self, $paragraph, $wrapped_mode );
            $paragraph    = "";
            $wrapped_mode = 1;
            undef $self->{bullet};
            undef $self->{indent};
            if ( defined( $self->{translate}->{entry}->{$attrname} ) ) {
                my $t = $self->translate(
                    $attrvalue,
                    $self->{ref},
                    "Attribute :$attrname:",
                    "comment" => join( "\n", @comments ),
                    "wrap"    => 0
                );
                $self->pushline(":$attrname$attrsep$t\n");
            } else {
                $self->pushline(":$attrname$attrsep$attrvalue\n");
            }
            @comments = ();
        } elsif ( not defined $self->{verbatim}
            and ( $line =~ m/^([\w\d][\w\d-]*)(::)(\S*)\[(.*)\]$/ ) )
        {
            my $macroname   = $1;
            my $macrotype   = $2;
            my $macrotarget = $3;
            my $macroparam  = $4;

            # Found a macro
            #            print STDERR "macro: $macroname|type: $macrotype|target: $macrotarget|param: $macroparam\n";

            # Don't process include macros in tables, pass them through
            if (    ( $macroname eq "include" )
                and ( $macrotype eq '::' )
                and ( defined( $self->{type} ) and ( $self->{type} eq "Table" ) ) )
            {
                $paragraph .= $line . "\n";
            } elsif ( ( $macroname eq "include" || $macroname eq "ifeval" )
                and ( $macrotype eq '::' ) )
            {
                $self->pushline( $line . "\n" );
            } else {
                if ( $macrotype eq '::' ) {
                    do_paragraph( $self, $paragraph, $wrapped_mode );
                    $paragraph    = "";
                    $wrapped_mode = 1;
                    undef $self->{bullet};
                    undef $self->{indent};
                }
                my $t = $self->parse_macro( $macroname, $macrotype, $macrotarget, $macroparam );
                $self->pushline("$t\n");
                @comments = ();
            }
        } elsif ( not defined $self->{verbatim}
            and ( $line !~ m/^\.\./ )
            and ( $line =~ m/^\.(\S.*)$/ ) )
        {
            my $title = $1;

            # Found block title
            do_paragraph( $self, $paragraph, $wrapped_mode );
            $paragraph    = "";
            $wrapped_mode = 1;
            undef $self->{bullet};
            undef $self->{indent};
            my $t = $self->translate(
                $title,
                $self->{ref},
                "Block title",
                "comment" => join( "\n", @comments ),
                "wrap"    => 0
            );
            $self->pushline(".$t\n");
            @comments = ();
        } elsif ( not defined $self->{verbatim}
            and ( $line =~ m/^(\s*)((?:[-*o+\.]+|(?:[0-9]+[.\)])|(?:[a-z][.\)])|\([0-9]+\))\s+)(.*)$/ ) )
        {
            my $indent = $1 || "";
            my $bullet = $2;
            my $text   = $3;
            print STDERR "Item (bullet: '$bullet')\n" if ( $debug{parse} );
            do_paragraph( $self, $paragraph, $wrapped_mode );
            $paragraph      = $text . "\n";
            $self->{indent} = $indent;
            $self->{bullet} = $bullet;
        } elsif ( not defined $self->{verbatim}
            and ( $line =~ m/^((?:<?[0-9]+)?> +)(.*)$/ ) )
        {
            my $bullet = $1;
            my $text   = $2;
            do_paragraph( $self, $paragraph, $wrapped_mode );
            $paragraph      = $text . "\n";
            $self->{indent} = "";
            $self->{bullet} = $bullet;
        } elsif ( ( $line =~ /^\s*$/ ) and ( !defined( $self->{type} ) or ( $self->{type} ne "Table" ) ) ) {

            # When not in table, empty lines or lines containing only spaces do break paragraphs
            print STDERR "Empty new line. Wrap: " . ( defined( $self->{verbatim} ) ? "yes. " : "no. " ) . "\n"
              if $debug{parse};
            do_paragraph( $self, $paragraph, $wrapped_mode );
            $paragraph    = "";
            $wrapped_mode = 1 unless defined( $self->{verbatim} );
            $self->pushline( $line . "\n" );

        } elsif ( ( $line =~ /^\s*$/ ) ) {

            # When in table, empty lines are either added to the current paragraph if it not empty, or pushed verbatim if not
            if ( length $paragraph ) {
                $paragraph .= $line . "\n";
            } else {
                $self->pushline( $line . "\n" );
            }

            # print STDERR ">>$paragraph<<\n";
        } elsif ( not defined $self->{verbatim}
            and ( defined $self->{bullet} and $line =~ m/^(\s+)(.*)$/ ) )
        {
            my $indent = $1;
            my $text   = $2;
            print STDERR "bullet (" . ( $self->{bullet} ) . ") starting with " . length($indent) . " spaces\n"
              if $debug{'parse'};
            if ( $paragraph eq "" && length( $self->{bullet} ) && length($indent) ) {

                # starting a paragraph with a bullet (not an enum or so), and indented.
                # Thus a literal paragraph in a list.
                $wrapped_mode = 0;
            }
            if ( not defined $self->{indent} ) {

                # No indent level before => Starting a paragraph?
                $paragraph .= $text . "\n";
                $self->{indent} = $indent;
                print STDERR "Starting a paragraph\n" if ( $debug{parse} );
            } elsif ( length($paragraph)
                and ( length( $self->{bullet} ) + length( $self->{indent} ) == length($indent) ) )
            {
                # same indent level as before: append
                $paragraph .= $text . "\n";
            } elsif ( length($paragraph)
                and ( length( $self->{bullet} ) == 0 ) )
            {
                # definition list continuation
                $paragraph .= $text . "\n";
                $self->{indent} = "";
                print STDERR " definition list continuation\n" if ( $debug{parse} );
            } else {

                # not the same indent level: start a new translated paragraph
                print STDERR "New paragraph (indent: '" . ( $self->{indent} ) . "')\n" if ( $debug{parse} );
                do_paragraph( $self, $paragraph, $wrapped_mode );
                if ( length( $self->{indent} ) > 0 && length( $self->{indent} ) < length($indent) ) {

                    # increase indentation: the new block must not be wrapped
                    $wrapped_mode = 0;
                }
                $paragraph      = $text . "\n";
                $self->{indent} = $indent;
                $self->{bullet} = "";
            }
        } elsif ( $line =~ /^-- $/ ) {

            # Break paragraphs on email signature hint
            do_paragraph( $self, $paragraph, $wrapped_mode );
            $paragraph    = "";
            $wrapped_mode = 1;
            $self->pushline( $line . "\n" );
        } elsif ( $line =~ /^=+$/
            or $line =~ /^_+$/
            or $line =~ /^-+$/ )
        {
            $wrapped_mode = 0;
            $paragraph .= $line . "\n";
            do_paragraph( $self, $paragraph, $wrapped_mode );
            $paragraph    = "";
            $wrapped_mode = 1;
        } elsif ( $paragraph ne ""
            && $self->{bullet}
            && length( $self->{indent} || "" ) == 0
            && ( $line =~ m/^(\s*)((?:[-*o+]+|([0-9]+[.\)])|\([0-9]+\))\s+)/s ) )
        {
            # If the next line starts with a bullet, process this immediately and setup the next line
            do_paragraph( $self, $paragraph, $wrapped_mode );
            $paragraph    = "";
            $wrapped_mode = 0;
            $self->unshiftline( $line, $ref );
            $line = "";
            undef $self->{bullet};
            undef $self->{indent};
        } elsif ( $line =~ /^\|===/ ) {

            # This is a table, treat it as a non-wrapped paragraph
            print STDERR "Found Table delimiter\n" if ( $debug{parse} );
            if ( ( $paragraph eq "" ) or ( defined( $self->{type} ) and ( $self->{type} =~ /^delimited block/i ) ) ) {

                # Start the table
                $wrapped_mode = 0;
                $self->{type} = "Table";
            } else {

                # End the Table
                if ( $self->{options}{'tablecells'} and
					 not defined  $self->{disabletablecells} ) {
                    do_stripped_unwrapped_paragraph( $self, $paragraph, $wrapped_mode );
                    $self->pushline("\n");
                } else {
                    do_paragraph( $self, $paragraph, $wrapped_mode );
                }
                undef $self->{verbatim};
                undef $self->{type};
				undef $self->{disabletablecells};
                $paragraph = "";
            }
            $self->pushline( $line . "\n" );
        } else {

            # A stupid paragraph of text
            print STDERR "Regular line. "
              . "Bullet: '"
              . ( defined( $self->{bullet} ) ? $self->{bullet} : 'none' ) . "'; "
              . "Indent: '"
              . ( defined( $self->{indent} ) ? $self->{indent} : 'none' ) . "'\n"
              if ( $debug{parse} );

            if ( $line =~ /^\s/ ) {

                # A line starting by a space indicates a non-wrap
                # paragraph
                $wrapped_mode = 0;
            }

            if (   ( $paragraph ne "" && $self->{bullet} && length( $self->{indent} || "" ) == 0 )
                && ( !$self->{options}{'nolinting'} ) )
            {

                # Second line of an item block is not indented. It is unindented
                # (and allowed) additional text or a new list item.
                warn wrap_mod(
                    "$ref",
                    dgettext(
                        "po4a",
                        "It seems that you are adding unindented content to an item. "
                          . "The standard allows this, but you may still want to change your document "
                          . "to use indented text to provide better visual clues to writers."
                    )
                );
            } else {
                undef $self->{bullet};
                undef $self->{indent};
            }

            # TODO: comments
            $paragraph .= $line . "\n";
        }

        # paragraphs starting by a bullet, or numbered
        # or paragraphs with a line containing many consecutive spaces
        # (more than 3)
        # are considered as verbatim paragraphs
        $wrapped_mode = 0 if ( $paragraph =~ m/^(\*|[0-9]+[.)] )/s
            or $paragraph =~ m/[ \t][ \t][ \t]/s );
        ( $line, $ref ) = $self->shiftline();
    }
    if ( length $paragraph ) {
        do_paragraph( $self, $paragraph, $wrapped_mode );
    }
}

sub do_stripped_unwrapped_paragraph {
    my ( $self, $paragraph, $wrap ) = ( shift, shift, shift );
    my $type = shift || $self->{type} || "Plain text";
    my ( $pre, $trans, $post ) = $paragraph =~ /^(\s*)(.*?)(\s*)$/s;
    $self->pushline($pre);
    do_paragraph( $self, $trans, $wrap, $type );
    $self->pushline($post);
}

sub do_paragraph {
    my ( $self, $paragraph, $wrap ) = ( shift, shift, shift );
    my $type = shift || $self->{type} || "Plain text";
    return if ( $paragraph eq "" );

    # DEBUG
    #    my $b;
    #    if (defined $self->{bullet}) {
    #            $b = $self->{bullet};
    #    } else {
    #            $b = "UNDEF";
    #    }
    #    $type .= " verbatim: '".($self->{verbatim}||"NONE")."' bullet: '$b' indent: '".($self->{indent}||"NONE")."' type: '".($self->{type}||"NONE")."'";

    if ( not $wrap and not defined $self->{verbatim} ) {

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
            while ( $para !~ m/$indent2(?:[-*o+]|([0-9]+[.\)])|\([0-9]+\))\s+/
                and $para =~ s/^$indent2(\S[^\n]*\n)//s )
            {
                $text .= $1;
            }

            # TODO: detect if a line starts with the same bullet
            if ( $text !~ m/\S[ \t][ \t][ \t]+\S/s ) {
                my $bullet_regex = quotemeta( $indent1 . $bullet );
                $bullet_regex =~ s/[0-9]+/\\d\+/;
                if ( $para eq '' or $para =~ m/^$bullet_regex\S/s ) {
                    my $trans = $self->translate(
                        $text,
                        $self->{ref},
                        "Bullet: '$indent1$bullet'",
                        "wrap"    => 1,
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
        "wrap"    => $wrap
    );

    my $unwrap_result = !$self->{options}{'forcewrap'} && $wrap;
    if ($unwrap_result) {
        $t =~ s/(\n| )+/ /g;
    }

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

sub parse_style {
    my ( $self, $text ) = ( shift, shift );
    $text =~ s/^\[//;
    $text =~ s/\]$//;
    $text =~ m/^([^=,]+)/;
    if ( defined($1) && $self->is_unsplitted_attributelist( $1, 'style' ) ) {
        my $t = $self->translate(
            $text,
            $self->{ref},
            "Unsplitted AttributeList",
            "comment" => join( "\n", @comments ),
            "wrap"    => 0
        );
        return "[$t]";
    }
    my @attributes = $self->split_attributelist($text);
    return "[" . join( ", ", $self->join_attributelist( "style", @attributes ) ) . "]";
}

sub parse_macro {
    my ( $self, $macroname, $macrotype, $macrotarget, $macroparam ) = ( shift, shift, shift, shift, shift );
    if ( $self->is_unsplitted_attributelist( $macroname, 'macro' ) ) {
        my $t = $self->translate(
            "$macroname$macrotype$macrotarget\[$macroparam\]",
            $self->{ref},
            "Unsplitted macro call",
            "comment" => join( "\n", @comments ),
            "wrap"    => 0
        );
        return $t;
    }
    my @attributes = ();
    @attributes = $self->split_attributelist($macroparam) unless $macroparam eq "";

    unshift @attributes, $macroname;
    my @translated_attributes = $self->join_attributelist( "macro", @attributes );
    shift @translated_attributes;
    if ( $self->is_translated_target($macroname) ) {
        my $target = unquote_space($macrotarget);
        my $t      = $self->translate(
            $target,
            $self->{ref},
            "Target for macro $macroname",
            "comment" => join( "\n", @comments ),
            "wrap"    => 0
        );
        $macrotarget = quote_space($t);
    }
    return "$macroname$macrotype$macrotarget\[" . join( ", ", @translated_attributes ) . "]";
}

sub split_attributelist {
    my ( $self, $text ) = ( shift, shift );

    print STDERR "Splitting attributes in: $text\n" if $debug{split_attributelist};
    my @attributes = ();
    while (
        $text =~ m/\G(
         [^\W\d][-\w]*="(?:[^"\\]++|\\.)*+" # named attribute
       | [^\W\d][-\w]*=None                 # undefined named attribute
       | [^\W\d][-\w]*=\S+                  # invalid, but accept it anyway
       | "(?:[^"\\]++|\\.)*+"               # quoted attribute
       |  (?:[^,\\]++|\\.)++                # unquoted attribute
       | ^$                                 # Empty attribute list allowed

         )(?:,\s*+)?/gx
      )
    {
        print STDERR "  -> $1\n" if $debug{split_attributelist};
        push @attributes, $1;
    }
    return @attributes;
}

sub join_attributelist {
    my ( $self, $type ) = ( shift, shift );
    my @attributes = @_;
    my $command    = shift(@attributes);
    my $position;
    if ( $type eq 'macro' ) {
        $position = 0;    # macroname is passed through the first attribute
    } else {
        $position = 1;
    }
    my @text = ($command);
    if ( $command =~ m/=/ ) {
        my $attr = $command;
        $command =~ s/=.*//;
        @text = ();
        push @text, $self->translate_attributelist( $type, $command, $position, $attr );
    }
    foreach my $attr (@attributes) {
        $position++;
        push @text, $self->translate_attributelist( $type, $command, $position, $attr );
    }
    print STDERR "Joined attributes: " . join( ", ", @text ) . "\n" if $debug{join_attributelist};
    return @text;
}

sub translate_attributelist {
    my ( $self, $type, $command, $count, $attr ) = ( shift, shift, shift, shift, shift );
    return $attr unless defined $self->{translate}->{$type}->{$command};
    if ( $attr =~ m/^([^\W\d][-\w]*)=(.*)/ ) {
        my $attrname  = $1;
        my $attrvalue = $2;
        if ( $self->{translate}->{$type}->{$command} =~ m/,$attrname,/ ) {
            my $value = unquote($attrvalue);
            my $t     = $self->translate(
                $value,
                $self->{ref},
                "Named '$attrname' AttributeList argument for $type '$command'",
                "comment" => join( "\n", @comments ),
                "wrap"    => 0
            );
            if ( $attrvalue eq 'None' && $t eq 'None' ) {
                $attr = $attrname . "=None";
            } else {
                $attr = $attrname . "=" . quote($t);
            }
        }
    } else {
        if ( $self->{translate}->{$type}->{$command} =~ m/,$count,/ ) {
            my $attrvalue = unquote($attr);
            my $t         = $self->translate(
                $attrvalue,
                $self->{ref},
                "Positional (\$$count) AttributeList argument for $type '$command'",
                "comment" => join( "\n", @comments ),
                "wrap"    => 0
            );
            $attr = quote($t);
        }
    }
    return $attr;
}

sub unquote {
    my ($text) = shift;
    return $text unless $text =~ s/^"(.*)"$/$1/;
    $text =~ s/\\"/"/g;
    return $text;
}

sub quote {
    my $text = shift;
    $text =~ s/"/\\"/g;
    return '"' . $text . '"';
}

sub quote_space {
    my $text = shift;
    $text =~ s/ /%20/g;
    return $text;
}

sub unquote_space {
    my $text = shift;
    $text =~ s/%20/ /g;
    return $text;
}

1;

=head1 STATUS OF THIS MODULE

Tested successfully on simple AsciiDoc files.

=head1 AUTHORS

 Nicolas François <nicolas.francois@centraliens.net>
 Denis Barbier <barbier@linuxfr.org>

=head1 COPYRIGHT AND LICENSE

 Copyright © 2005-2008 Nicolas FRANÇOIS <nicolas.francois@centraliens.net>.
 Copyright © 2012 Denis BARBIER <barbier@linuxfr.org>.
 Copyright © 2017 Martin Quinson <mquinson#debian.org>.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see the COPYING file).
