#!/usr/bin/perl -w

package Locale::Po4a::TransTractor;

use 5.16.0;
use strict;
use warnings;

use subs qw(makespace);
use vars qw($VERSION);
$VERSION = "0.74-alpha";

use Carp qw(croak confess);
use Locale::Po4a::Po;
use Locale::Po4a::Common qw(wrap_msg wrap_mod gettext dgettext);

use File::Path;    # mkdir before write
use File::Spec;

=encoding UTF-8

=head1 NAME

Locale::Po4a::TransTractor - generic trans(lator ex)tractor.

=head1 DESCRIPTION

The po4a (PO for anything) project goal is to ease translations (and more
interestingly, the maintenance of translations) using gettext tools on
areas where they were not expected like documentation.

This class is the ancestor of every po4a parser used to parse a document, to
search translatable strings, to extract them to a PO file and to replace them by
their translation in the output document.

More formally, it takes the following arguments as input:

=over 2

=item -

a document to translate;

=item -

a PO file containing the translations to use.

=back

As output, it produces:

=over 2

=item -

another PO file, resulting of the extraction of translatable strings from
the input document;

=item -

a translated document, with the same structure than the one in input, but
with all translatable strings replaced with the translations found in the
PO file provided in input.

=back

Here is a graphical representation of this:

   Input document --\                             /---> Output document
                     \                           /       (translated)
                      +-> parse() function -----+
                     /                           \
   Input PO --------/                             \---> Output PO
                                                         (extracted)

=head1 FUNCTIONS YOUR PARSER SHOULD OVERRIDE

=over 4

=item parse()

This is where all the work takes place: the parsing of input documents, the
generation of output, and the extraction of the translatable strings. This
is pretty simple using the provided functions presented in the section
B<INTERNAL FUNCTIONS> below. See also the B<SYNOPSIS>, which presents an
example.

This function is called by the process() function below, but if you choose
to use the new() function, and to add content manually to your document,
you will have to call this function yourself.

=item docheader()

This function returns the header we should add to the produced document,
quoted properly to be a comment in the target language.  See the section
B<Educating developers about translations>, from L<po4a(7)|po4a.7>, for what
it is good for.

=back

=cut

sub docheader { }

sub parse { }

=head1 SYNOPSIS

The following example parses a list of paragraphs beginning with "<p>". For the sake
of simplicity, we assume that the document is well formatted, i.e. that '<p>'
tags are the only tags present, and that this tag is at the very beginning
of each paragraph.

 sub parse {
   my $self = shift;

   PARAGRAPH: while (1) {
       my ($paragraph,$pararef)=("","");
       my $first=1;
       my ($line,$lref)=$self->shiftline();
       while (defined($line)) {
           if ($line =~ m/<p>/ && !$first--; ) {
               # Not the first time we see <p>.
               # Reput the current line in input,
               #  and put the built paragraph to output
               $self->unshiftline($line,$lref);

               # Now that the document is formed, translate it:
               #   - Remove the leading tag
               $paragraph =~ s/^<p>//s;

               #   - push to output the leading tag (untranslated) and the
               #     rest of the paragraph (translated)
               $self->pushline(  "<p>"
                               . $self->translate($paragraph,$pararef)
                               );

               next PARAGRAPH;
           } else {
               # Append to the paragraph
               $paragraph .= $line;
               $pararef = $lref unless(length($pararef));
           }

           # Reinit the loop
           ($line,$lref)=$self->shiftline();
       }
       # Did not get a defined line? End of input file.
       return;
   }
 }

Once you've implemented the parse function, you can use your document
class, using the public interface presented in the next section.

=head1 PUBLIC INTERFACE for scripts using your parser

=head2 Constructor

=over 4

=item process(%)

This function can do all you need to do with a po4a document in one
invocation. Its arguments must be packed as a hash. ACTIONS:

=over 3

=item a.

Reads all the PO files specified in po_in_name

=item b.

Reads all original documents specified in file_in_name

=item c.

Parses the document

=item d.

Reads and applies all the addenda specified

=item e.

Writes the translated document to file_out_name (if given)

=item f.

Writes the extracted PO file to po_out_name (if given)

=back

ARGUMENTS, beside the ones accepted by new() (with expected type):

=over 4

=item file_in_name (@)

List of filenames where we should read the input document.

=item file_in_charset ($)

Charset used in the input document (if it isn't specified, use UTF-8).

=item file_out_name ($)

Filename where we should write the output document.

=item file_out_charset ($)

Charset used in the output document (if it isn't specified, use UTF-8).

=item po_in_name (@)

List of filenames where we should read the input PO files from, containing
the translation which will be used to translate the document.

=item po_out_name ($)

Filename where we should write the output PO file, containing the strings
extracted from the input document.

=item addendum (@)

List of filenames where we should read the addenda from.

=item addendum_charset ($)

Charset for the addenda.

=back

=item new(%)

Create a new po4a document. Accepted options (in the hash passed as a parameter):

=over 4

=item verbose ($)

Sets the verbosity.

=item debug ($)

Sets the debugging.

=item wrapcol ($)

The column at which we should wrap text in output document (default: 76).

The negative value means not to wrap lines at all.

=back

Also it accepts next options for underlying Po-files: B<porefs>,
B<copyright-holder>, B<msgid-bugs-address>, B<package-name>,
B<package-version>, B<wrap-po>.

=cut

sub process {
    my $self = shift;
    ## Parameters are passed as an hash to avoid long and error-prone parameter lists
    my %params = @_;

    # Parameter checking
    foreach ( keys %params ) {
        confess "Unexpected parameter to process(): $_. Please report that bug."
          unless ( $_ eq 'po_in_name'
            || $_ eq 'po_out_name'
            || $_ eq 'file_in_name'
            || $_ eq 'file_in_charset'
            || $_ eq 'file_out_name'
            || $_ eq 'file_out_charset'
            || $_ eq 'addendum'
            || $_ eq 'addendum_charset'
            || $_ eq 'srcdir'
            || $_ eq 'destdir'
            || $_ eq 'calldir' );
    }

    $self->{TT}{'file_in_charset'}  = $params{'file_in_charset'}  // 'UTF-8';
    $self->{TT}{'file_out_charset'} = $params{'file_out_charset'} // 'UTF-8';
    $self->{TT}{'addendum_charset'} = $params{'addendum_charset'};

    our ( $destdir, $srcdir, $calldir ) = ( $params{'destdir'}, $params{'srcdir'}, $params{'calldir'} );

    sub _input_file {
        my $filename = $_[0];
        return $filename if ( File::Spec->file_name_is_absolute($filename) );
        foreach ( ( $destdir, $srcdir, $calldir ) ) {
            next unless defined $_;
            my $p = File::Spec->catfile( $_, $filename );
            return $p if -e $p;
        }
        return $filename;
    }

    sub _output_file {
        my $filename = $_[0];
        return $filename if ( File::Spec->file_name_is_absolute($filename) );
        foreach ( ( $destdir, $calldir ) ) {
            next unless defined $_;
            return File::Spec->catfile( $_, $filename ) if -d $_ and -w $_;
        }
        return $filename;
    }

    foreach my $file ( @{ $params{'po_in_name'} } ) {
        my $infile = _input_file($file);
        print STDERR wrap_mod( "po4a::transtractor::process", "Read PO file $infile" )
          if $self->debug();
        $self->readpo($infile);
    }
    foreach my $file ( @{ $params{'file_in_name'} } ) {
        my $infile = _input_file($file);
        print STDERR wrap_mod( "po4a::transtractor::process", "Read document $infile" )
          if $self->debug();
        $self->read( $infile, $file, $params{'file_in_charset'} );
    }
    print STDERR wrap_mod( "po4a::transtractor::process", "Call parse()" ) if $self->debug();
    $self->parse();
    print STDERR wrap_mod( "po4a::transtractor::process", "Done parse()" ) if $self->debug();
    foreach my $file ( @{ $params{'addendum'} } ) {
        my $infile = _input_file($file);
        print STDERR wrap_mod( "po4a::transtractor::process", "Apply addendum $infile" )
          if $self->debug();
        $self->addendum($file) || die "An addendum failed\n";
    }

    if ( defined $params{'file_out_name'} ) {
        my $outfile = _output_file( $params{'file_out_name'} );
        print STDERR wrap_mod( "po4a::transtractor::process", "Write document $outfile" )
          if $self->debug();
        $self->write( $outfile, $self->{TT}{'file_out_charset'} );
    }
    if ( defined $params{'po_out_name'} ) {
        my $outfile = _output_file( $params{'po_out_name'} );
        print STDERR wrap_mod( "po4a::transtractor::process", "Write PO file $outfile" )
          if $self->debug();
        $self->writepo($outfile);
    }
    return $self;
}

sub new {
    ## Determine if we were called via an object-ref or a classname
    my $this    = shift;
    my $class   = ref($this) || $this;
    my $self    = {};
    my %options = @_;
    ## Bless ourselves into the desired class and perform any initialization
    bless $self, $class;

    ## initialize the plugin
    # prevent the plugin from croaking on the options intended for Po.pm or ourself
    $self->{options}{'porefs'}             = '';
    $self->{options}{'copyright-holder'}   = '';
    $self->{options}{'msgid-bugs-address'} = '';
    $self->{options}{'package-name'}       = '';
    $self->{options}{'package-version'}    = '';
    $self->{options}{'wrap-po'}            = '';
    $self->{options}{'wrapcol'}            = '';

    # let the plugin parse the options and such
    $self->initialize(%options);

    ## Create our private data
    my %po_options;
    $po_options{'porefs'}             = $options{'porefs'};
    $po_options{'copyright-holder'}   = $options{'copyright-holder'};
    $po_options{'msgid-bugs-address'} = $options{'msgid-bugs-address'};
    $po_options{'package-name'}       = $options{'package-name'};
    $po_options{'package-version'}    = $options{'package-version'};
    $po_options{'wrap-po'}            = $options{'wrap-po'};

    # private data
    $self->{TT}         = ();
    $self->{TT}{po_in}  = Locale::Po4a::Po->new( \%po_options );
    $self->{TT}{po_out} = Locale::Po4a::Po->new( \%po_options );

    # Warning, $self->{TT}{doc_in} is an array of array:
    #  The document is split on lines, and for each array in array
    #  [0] is the line content, [1] is the reference $filename:$linenum
    $self->{TT}{doc_in}  = ();
    $self->{TT}{doc_out} = ();
    if ( defined $options{'verbose'} ) {
        $self->{TT}{verbose} = $options{'verbose'};
    }
    if ( defined $options{'debug'} ) {
        $self->{TT}{debug} = $options{'debug'};
    }
    if ( defined $options{'wrapcol'} ) {
        if ( $options{'wrapcol'} < 0 ) {
            $self->{TT}{wrapcol} = 'Inf';
        } else {
            $self->{TT}{wrapcol} = $options{'wrapcol'};
        }
    } else {
        $self->{TT}{wrapcol} = 76;
    }

    return $self;
}

sub initialize { }

=back

=head2 Manipulating document files

=over 4

=item read($$$)

Add another input document data at the end of the existing array C<< @{$self->{TT}{doc_in}} >>.

This function takes two mandatory arguments and an optional one.
 * The filename to read on disk;
 * The name to use as filename when building the reference in the PO file;
 * The charset to use to read that file (UTF-8 by default)

This array C<< @{$self->{TT}{doc_in}} >> holds this input document data as an
array of strings with alternating meanings.
 * The string C<$textline> holding each line of the input text data.
 * The string C<< $filename:$linenum >> holding its location and called as
   "reference" (C<linenum> starts with 1).

Please note that it does not parse anything. You should use the parse()
function when you're done with packing input files into the document.

=cut

sub read() {
    my $self     = shift;
    my $filename = shift or confess "Cannot read from a file without filename";
    my $refname  = shift or confess "Cannot read from a file without refname";
    my $charset  = shift || 'UTF-8';
    my $linenum  = 0;

    use warnings FATAL => 'utf8';
    use Encode qw(:fallbacks);
    use PerlIO::encoding;
    $PerlIO::encoding::fallback = FB_CROAK;

    my $fh;
    open( $fh, "<:encoding($charset)", $filename )
      or croak wrap_msg( dgettext( "po4a", "Cannot read from %s: %s" ), $filename, $! );

    # If we see a BOM while not in UTF-8, we want to croak. But this code is in an eval to deal with
    # encoding issues. So save the BOM error until after the eval block
    my $BOM_detected = 0;

    eval {
        while ( defined( my $textline = <$fh> ) ) {
            $linenum++;
            if ( $linenum == 1 && $textline =~ m/^\N{BOM}/ ) {    # UTF-8 BOM detected
                $BOM_detected = 1 if ( uc($charset) ne 'UTF-8' );    # Save the error message for after the eval{} bloc
                $textline =~ s/^\N{BOM}//;
            }
            my $ref = "$refname:$linenum";
            $textline =~ s/\r$//;
            my @entry = ( $textline, $ref );
            push @{ $self->{TT}{doc_in} }, @entry;
        }
    };
    my $error = $@;
    if ( length($error) ) {
        chomp $error;
        die wrap_msg(
            dgettext(
                "po4a",
                "Malformed encoding while reading from file %s with charset %s: %s\nIf %s is not the expected charset, you need to configure the right one with with --master-charset or other similar flags."
            ),
            $filename,
            $charset, $error, $charset
        );
    }

    # Croak if we need to
    if ($BOM_detected) {
        croak wrap_msg(
            dgettext(
                "po4a",
                "The file %s starts with a BOM char indicating that its encoding is UTF-8, but you specified %s instead."
            ),
            $filename,
            $charset
        );
    }

    close $fh
      or croak wrap_msg( dgettext( "po4a", "Cannot close %s after reading: %s" ), $filename, $! );
}

=item write($)

Write the translated document to the given filename.

This translated document data are provided by:
 * C<< $self->docheader() >> holding the header text for the plugin, and
 * C<< @{$self->{TT}{doc_out}} >> holding each line of the main translated text in the array.

=cut

sub write {
    my $self     = shift;
    my $filename = shift or confess "Cannot write to a file without filename";
    my $charset  = shift || 'UTF-8';

    use warnings FATAL => 'utf8';

    my $fh;
    if ( $filename eq '-' ) {
        $fh = \*STDOUT;
    } else {

        # make sure the directory in which we should write the localized file exists
        my $dir = $filename;
        if ( $dir =~ m|/| ) {
            $dir =~ s|/[^/]*$||;

            File::Path::mkpath( $dir, 0, 0755 )    # Croaks on error
              if ( length($dir) && !-e $dir );
        }
        open( $fh, ">:encoding($charset)", $filename )
          or croak wrap_msg( dgettext( "po4a", "Cannot write to %s: %s" ), $filename, $! );
    }

    map { print $fh $_ } $self->docheader();
    eval {
        map { print $fh $_ } @{ $self->{TT}{doc_out} };

        # we use the "eval {} or do {}" approach to deal with exceptions, cf https://perlmaven.com/fatal-errors-in-external-modules
        # but we want it to fail only if there is an error. It seems to be some cases where "map" returns false even if there is no error.
        # Thus this final 1 to evaluate to true in absence of error.
        1;
    } or do {
        my $error = $@ || 'Unknown failure';
        chomp $error;
        if ( $charset ne 'UTF-8' && $error =~ /^"\\x\{([^"}]*)\}"/ ) {

            # Attempt to write the char that cannot be written. Very fragile code
            binmode STDERR, ':encoding(UTF-8)';
            my $char = chr( hex($1) );
            die wrap_msg(
                dgettext(
                    "po4a",
                    "Malformed encoding while writing char '%s' to file %s with charset %s: %s\nIf %s is not the expected charset, you need to configure the right one with with --localized-charset or other similar flags."
                ),
                $char,
                $filename,
                $charset, $error, $charset
            );
        } else {
            die wrap_msg(
                dgettext(
                    "po4a",
                    "Malformed encoding while writing to file %s with charset %s: %s\nIf %s is not the expected charset, you need to configure the right one with with --localized-charset or other similar flags."
                ),
                $filename,
                $charset, $error, $charset
            );
        }
    };

    if ( $filename ne '-' ) {
        close $fh or croak wrap_msg( dgettext( "po4a", "Cannot close %s after writing: %s" ), $filename, $! );
    }

}

=back

=head2 Manipulating PO files

=over 4

=item readpo($)

Add the content of a file (which name is passed as argument) to the
existing input PO. The old content is not discarded.

=item writepo($)

Write the extracted PO file to the given filename.

=item stats()

Returns some statistics about the translation done so far. Please note that
it's not the same statistics than the one printed by msgfmt
--statistic. Here, it's stats about recent usage of the PO file, while
msgfmt reports the status of the file. It is a wrapper to the
Locale::Po4a::Po::stats_get function applied to the input PO file. Example
of use:

    [normal use of the po4a document...]

    ($percent,$hit,$queries) = $document->stats();
    print "We found translations for $percent\%  ($hit from $queries) of strings.\n";

=back

=cut

sub getpoout {
    return $_[0]->{TT}{po_out};
}

sub setpoout {
    $_[0]->{TT}{po_out} = $_[1];
}

sub readpo {
    $_[0]->{TT}{po_in}->read( $_[1] );
}

sub writepo {
    $_[0]->{TT}{po_out}->write( $_[1] );
}

sub stats {
    return $_[0]->{TT}{po_in}->stats_get();
}

=head2 Manipulating addenda

=over 4

=item addendum($)

Please refer to L<po4a(7)|po4a.7> for more information on what addenda are,
and how translators should write them. To apply an addendum to the translated
document, simply pass its filename to this function and you are done ;)

This function returns a non-null integer on error.

=cut

# Internal function to read the header.
sub addendum_parse {
    my $filename = shift;
    my $charset  = shift || 'UTF-8';
    my $header;

    my ( $errcode, $mode, $position, $boundary, $bmode, $content ) = ( 1, "", "", "", "", "" );

    unless ( open( INS, "<:encoding($charset)", $filename ) ) {
        warn wrap_msg( dgettext( "po4a", "Cannot read from %s: %s" ), $filename, $! );
        goto END_PARSE_ADDFILE;
    }

    $PerlIO::encoding::fallback = FB_CROAK;
    eval {
        unless ( defined( $header = <INS> ) && $header ) {
            warn wrap_msg( dgettext( "po4a", "Cannot read po4a header from %s." ), $filename );
            goto END_PARSE_ADDFILE;
        }
    } or do {
        my $error = $@ || 'Unknown failure';
        chomp $error;
        die wrap_msg(
            dgettext(
                "po4a",
                "Malformed encoding while reading from file %s with charset %s: %s\nIf %s is not the expected charset, you need to configure the right one with with --master-charset or other similar flags."
            ),
            $filename,
            $charset, $error, $charset
        );
    };

    unless ( $header =~ s/PO4A-HEADER://i ) {
        warn wrap_msg( dgettext( "po4a", "First line of %s does not look like a po4a header." ), $filename );
        goto END_PARSE_ADDFILE;
    }
    foreach my $part ( split( /;/, $header ) ) {
        unless ( $part =~ m/^\s*([^=]*)=(.*)$/ ) {
            warn wrap_msg( dgettext( "po4a", "Syntax error in po4a header of %s, near \"%s\"" ), $filename, $part );
            goto END_PARSE_ADDFILE;
        }
        my ( $key, $value ) = ( $1, $2 );
        $key = lc($key);
        if ( $key eq 'mode' ) {
            $mode = lc($value);
        } elsif ( $key eq 'position' ) {
            $position = $value;
        } elsif ( $key eq 'endboundary' ) {
            $boundary = $value;
            $bmode    = 'after';
        } elsif ( $key eq 'beginboundary' ) {
            $boundary = $value;
            $bmode    = 'before';
        } else {
            warn wrap_msg( dgettext( "po4a", "Invalid argument in the po4a header of %s: %s" ), $filename, $key );
            goto END_PARSE_ADDFILE;
        }
    }

    unless ( length($mode) ) {
        warn wrap_msg( dgettext( "po4a", "The po4a header of %s does not define the mode." ), $filename );
        goto END_PARSE_ADDFILE;
    }
    unless ( $mode eq "before" || $mode eq "after" || $mode eq "eof" ) {
        warn wrap_msg(
            dgettext(
                "po4a",
                "Mode invalid in the po4a header of %s: should be 'before', 'after' or 'eof'. Instead, it is '%s'."
            ),
            $filename,
            $mode
        );
        goto END_PARSE_ADDFILE;
    }

    unless ( length($position) || $mode eq "eof" ) {
        warn wrap_msg( dgettext( "po4a", "The po4a header of %s does not define the position." ), $filename );
        goto END_PARSE_ADDFILE;
    }
    if ( $mode eq "after" && length($boundary) == 0 ) {
        warn wrap_msg( dgettext( "po4a", "No ending boundary given in the po4a header, but mode=after." ) );
        goto END_PARSE_ADDFILE;
    }
    if ( $mode eq "eof" && length($position) ) {
        warn wrap_msg( dgettext( "po4a", "No position needed when mode=eof." ) );
        goto END_PARSE_ADDFILE;
    }
    if ( $mode eq "eof" && length($boundary) ) {
        warn wrap_msg( dgettext( "po4a", "No ending boundary needed when mode=eof." ) );
        goto END_PARSE_ADDFILE;
    }

    eval {
        while ( defined( my $line = <INS> ) ) {
            $content .= $line;
        }
    };
    my $error = $@;
    if ( length($error) ) {
        chomp $error;
        die wrap_msg(
            dgettext(
                "po4a",
                "Malformed encoding while reading from file %s with charset %s: %s\nIf %s is not the expected charset, you need to configure the right one with with --master-charset or other similar flags."
            ),
            $filename,
            $charset, $error, $charset
        );
    }
    close INS;

    $errcode = 0;
  END_PARSE_ADDFILE:
    return ( $errcode, $mode, $position, $boundary, $bmode, $content );
}

sub mychomp {
    my ($str) = shift;
    chomp($str);
    return $str;
}

sub addendum {
    my ( $self, $filename ) = @_;

    print STDERR wrap_mod( "po4a::transtractor::addendum", "Apply addendum %s", $filename )
      if $self->debug();
    unless ($filename) {
        warn wrap_msg( dgettext( "po4a", "Cannot apply addendum when not given the filename" ) );
        return 0;
    }
    die wrap_msg( dgettext( "po4a", "Addendum %s does not exist." ), $filename )
      unless -e $filename;

    my ( $errcode, $mode, $position, $boundary, $bmode, $content ) =
      addendum_parse( $filename, $self->{TT}{'addendum_charset'} );
    return 0 if ($errcode);

    # In order to make addendum more intuitive, each array item of
    # @{$self->{TT}{doc_out}} must not have internal "\n".  But previous parser
    # code may put multiple internal "\n" to address things like placeholder
    # tag handling.  Let's normalize array content.
    # Use internal "\n" as delimiter but keep it by using the lookbehind trick.
    @{ $self->{TT}{doc_out} } = map { split /(?<=\n)/, $_ } @{ $self->{TT}{doc_out} };

    # Bugs around addendum is hard to understand.  So let's print involved data explicitly.
    if ( $self->debug() ) {
        print STDERR "Addendum position regex=$position\n";
        print STDERR "Addendum mode=$mode\n";
        if ( $mode eq "after" ) {
            print STDERR "Addendum boundary regex=$boundary\n";
            print STDERR "Addendum boundary mode=$bmode\n";
        }
        print STDERR "Addendum content (begin):\n";
        print STDERR "$content";
        print STDERR "Addendum content (end)\n";
        print STDERR "Output items searched for the addendum insertion position:\n";
        foreach my $item ( @{ $self->{TT}{doc_out} } ) {
            print STDERR $item;
            print STDERR "\n----- [ search item end marker with a preceding newline ] -----\n";
        }
        print STDERR "Start searching addendum insertion position...\n";
    }

    unless ( $mode eq 'eof' ) {
        my $found = scalar grep { /$position/ } @{ $self->{TT}{doc_out} };
        if ( $found == 0 ) {
            warn wrap_msg( dgettext( "po4a", "No candidate position for the addendum %s." ), $filename );
            return 0;
        }
        if ( $found > 1 ) {
            warn wrap_msg( dgettext( "po4a", "More than one candidate position found for the addendum %s." ),
                $filename );
            return 0;
        }
    }

    if ( $mode eq "eof" ) {
        push @{ $self->{TT}{doc_out} }, $content;
    } elsif ( $mode eq "before" ) {
        if ( $self->verbose() > 1 || $self->debug() ) {
            map {
                print STDERR wrap_msg( dgettext( "po4a", "Addendum '%s' applied before this line: %s" ), $filename, $_ )
                  if (/$position/);
            } @{ $self->{TT}{doc_out} };
        }
        @{ $self->{TT}{doc_out} } = map { /$position/ ? ( $content, $_ ) : $_ } @{ $self->{TT}{doc_out} };
    } else {
        my @newres = ();

        do {
            # make sure it doesn't whine on empty document
            my $line = scalar @{ $self->{TT}{doc_out} } ? shift @{ $self->{TT}{doc_out} } : "";
            push @newres, $line;
            my $outline = mychomp($line);
            $outline =~ s/^[ \t]*//;

            if ( $line =~ m/$position/ ) {
                while ( $line = shift @{ $self->{TT}{doc_out} } ) {
                    last if ( $line =~ /$boundary/ );
                    push @newres, $line;
                }
                if ( defined $line ) {
                    if ( $bmode eq 'before' ) {
                        print wrap_msg( dgettext( "po4a", "Addendum '%s' applied before this line: %s" ),
                            $filename, $outline )
                          if ( $self->verbose() > 1 || $self->debug() );
                        push @newres, $content;
                        push @newres, $line;
                    } else {
                        print wrap_msg( dgettext( "po4a", "Addendum '%s' applied after the line: %s." ),
                            $filename, $outline )
                          if ( $self->verbose() > 1 || $self->debug() );
                        push @newres, $line;
                        push @newres, $content;
                    }
                } else {
                    print wrap_msg( dgettext( "po4a", "Addendum '%s' applied at the end of the file." ), $filename )
                      if ( $self->verbose() > 1 || $self->debug() );
                    push @newres, $content;
                }
            }
        } while ( scalar @{ $self->{TT}{doc_out} } );
        @{ $self->{TT}{doc_out} } = @newres;
    }
    print STDERR wrap_mod( "po4a::transtractor::addendum", "Done with addendum %s", $filename )
      if $self->debug();
    return 1;
}

=back

=head1 INTERNAL FUNCTIONS used to write derivative parsers

=head2 Getting input, providing output

Four functions are provided to get input and return output. They are very
similar to shift/unshift and push/pop of Perl.

 * Perl shift returns the first array item and drop it from the array.
 * Perl unshift prepends an item to the array as the first array item.
 * Perl pop returns the last array item and drop it from the array.
 * Perl push appends an item to the array as the last array item.

The first pair is about input, while the second is about output. Mnemonic: in
input, you are interested in the first line, what shift gives, and in output
you want to add your result at the end, like push does.

=over 4

=item shiftline()

This function returns the first line to be parsed and its corresponding
reference (packed as an array) from the array C<< @{$self->{TT}{doc_in}} >> and
drop these first 2 array items.  Here, the reference is provided by a string
C<< $filename:$linenum >>.

=item unshiftline($$)

Unshifts the last shifted line of the input document and its corresponding
reference back to the head of C<< {$self->{TT}{doc_in}} >>.

=item pushline($)

Push a new line to the end of C<< {$self->{TT}{doc_out}} >>.

=item popline()

Pop the last pushed line from the end of C<< {$self->{TT}{doc_out}} >>.

=back

=cut

sub shiftline {
    my ( $line, $ref ) = ( shift @{ $_[0]->{TT}{doc_in} }, shift @{ $_[0]->{TT}{doc_in} } );
    return ( $line, $ref );
}

sub unshiftline {
    my $self = shift;
    unshift @{ $self->{TT}{doc_in} }, @_;
}

sub pushline { push @{ $_[0]->{TT}{doc_out} }, $_[1] if defined $_[1]; }
sub popline  { return pop @{ $_[0]->{TT}{doc_out} }; }

=head2 Marking strings as translatable

One function is provided to handle the text which should be translated.

=over 4

=item translate($$$)

Mandatory arguments:

=over 2

=item -

A string to translate

=item -

The reference of this string (i.e. position in inputfile)

=item -

The type of this string (i.e. the textual description of its structural role;
used in Locale::Po4a::Po::gettextization(); see also L<po4a(7)|po4a.7>,
section B<Gettextization: how does it work?>)

=back

This function can also take some extra arguments. They must be organized as
a hash. For example:

  $self->translate("string","ref","type",
                   'wrap' => 1);

=over

=item B<wrap>

boolean indicating whether we can consider that whitespaces in string are
not important. If yes, the function canonizes the string before looking for
a translation or extracting it, and wraps the translation.

=item B<wrapcol>

the column at which we should wrap (default: the value of B<wrapcol> specified
during creation of the TransTractor or 76).

The negative value will be substracted from the default.

=item B<comment>

an extra comment to add to the entry.

=back

Actions:

=over 2

=item -

Pushes the string, reference and type to po_out.

=item -

Returns the translation of the string (as found in po_in) so that the
parser can build the doc_out.

=item -

Handles the charsets to recode the strings before sending them to
po_out and before returning the translations.

=back

=back

=cut

sub translate {
    my $self = shift;
    my ( $string, $ref, $type ) = ( shift, shift, shift );
    my (%options) = @_;

    return "" unless length($string);

    # my %validoption;
    # map { $validoption{$_}=1 } (qw(wrap wrapcoll));
    # foreach (keys %options) {
    #        Carp::confess "internal error: translate() called with unknown arg $_. Valid options: $validoption"
    #            unless $validoption{$_};
    # }

    if ( !defined $options{'wrapcol'} ) {
        $options{'wrapcol'} = $self->{TT}{wrapcol};
    } elsif ( $options{'wrapcol'} < 0 ) {
        $options{'wrapcol'} = $self->{TT}{wrapcol} + $options{'wrapcol'};
    }
    my $transstring = $self->{TT}{po_in}->gettext(
        $string,
        'wrap'    => $options{'wrap'} || 0,
        'wrapcol' => $options{'wrapcol'}
    );

    # the comments provided by the modules are automatic comments from the PO point of view
    $self->{TT}{po_out}->push(
        'msgid'     => $string,
        'reference' => $ref,
        'type'      => $type,
        'automatic' => $options{'comment'},
        'flags'     => $options{'flags'},
        'wrap'      => $options{'wrap'} || 0,
    );

    if ( $options{'wrap'} || 0 ) {
        $transstring =~ s/( *)$//s;
        my $trailing_spaces = $1 || "";
        $transstring =~ s/(?<!\\) +$//gm;
        $transstring .= $trailing_spaces;
    }

    return $transstring;
}

=head2 Misc functions

=over 4

=item verbose()

Returns if the verbose option was passed during the creation of the
TransTractor.

=cut

sub verbose {
    if ( defined $_[1] ) {
        $_[0]->{TT}{verbose} = $_[1];
    } else {
        return $_[0]->{TT}{verbose} || 0;    # undef and 0 have the same meaning, but one generates warnings
    }
}

=item debug()

Returns if the debug option was passed during the creation of the
TransTractor.

=cut

sub debug {
    return $_[0]->{TT}{debug};
}

=item get_in_charset()

This function return the charset that was provided as master charset

=cut

sub get_in_charset() {
    return $_[0]->{TT}{'file_in_charset'};
}

=item get_out_charset()

This function will return the charset that should be used in the output
document (usually useful to substitute the input document's detected charset
where it has been found).

It will use the output charset specified in the command line. If it wasn't
specified, it will use the input PO's charset, and if the input PO has the
default "CHARSET", it will return the input document's charset, so that no
encoding is performed.

=cut

sub get_out_charset {
    my $self = shift;

    # Prefer the value specified on the command line
    return $self->{TT}{'file_out_charset'}
      if length( $self->{TT}{'file_out_charset'} );

    return $self->{TT}{po_in}->get_charset if $self->{TT}{po_in}->get_charset ne 'CHARSET';

    return $self->{TT}{'file_in_charset'} if length( $self->{TT}{'file_in_charset'} );

    return 'UTF-8';
}

# Push the translation of a Yaml document or Yaml Front-Matter header, parsed by YAML::Tiny in any case
# $is_yfm is a boolean indicating whether we are dealing with a Front Matter (true value) or whole document (false value)
sub handle_yaml {
    my ( $self, $is_yfm, $blockref, $yamlarray, $yfm_keys, $yfm_skip_array, $yfm_paths ) = @_;

    die "Empty YAML " . ( $is_yfm ? "Front Matter" : "document" ) unless ( length($yamlarray) > 0 );

    my ( $indent, $ctx ) = ( 0, "" );
    foreach my $cursor (@$yamlarray) {

        # An empty document
        if ( !defined $cursor ) {
            $self->pushline("---\n");

            # Do nothing

            # A scalar document
        } elsif ( !ref $cursor ) {
            $self->pushline("---\n");
            $self->pushline(
                format_scalar(
                    $self->translate(
                        $cursor, $blockref,
                        "YAML " . ( $is_yfm ? "Front Matter " : "" ) . "(scalar)",
                        "wrap" => 0
                    )
                )
            );

            # A list at the root
        } elsif ( ref $cursor eq 'ARRAY' ) {
            if (@$cursor) {
                $self->pushline("---\n");
                do_array( $self, $is_yfm, $blockref, $cursor, $indent, $ctx, $yfm_keys, $yfm_skip_array, $yfm_paths );
            } else {
                $self->pushline("---[]\n");
            }

            # A hash at the root
        } elsif ( ref $cursor eq 'HASH' ) {
            if (%$cursor) {
                $self->pushline("---\n");
                do_hash( $self, $is_yfm, $blockref, $cursor, $indent, $ctx, $yfm_keys, $yfm_skip_array, $yfm_paths );
            } else {
                $self->pushline("--- {}\n");
            }

        } else {
            die( "Cannot serialize " . ref($cursor) );
        }
    }

    # Escape the string to make it valid in YAML.
    # This is very similar to YAML::Tiny::_dump_scalar but does not do the internal->UTF-8 decoding,
    # as the translations that we feed into this function are already in UTF-8
    sub format_scalar {
        my $string = $_[0];
        my $is_key = $_[1];

        return '~'  unless defined $string;
        return "''" unless length $string;
        if ( Scalar::Util::looks_like_number($string) ) {

            # keys and values that have been used as strings get quoted
            if ($is_key) {
                return qq['$string'];
            } else {
                return $string;
            }
        }
        if ( $string =~ /[\\\'\n]/ ) {
            $string =~ s/\\/\\\\/g;
            $string =~ s/"/\\"/g;
            $string =~ s/\n/\\n/g;
            return qq|"$string"|;
        }
        if ( $string =~ /(?:^[~!@#%&*|>?:,'"`{}\[\]]|^-+$|\s|:\z)/ ) {
            return "'$string'";
        }
        return $string;
    }

    sub do_array {
        my ( $self, $is_yfm, $blockref, $array, $indent, $ctx, $yfm_keys, $yfm_skip_array, $yfm_paths ) = @_;
        foreach my $el (@$array) {
            my $header = ( '  ' x $indent ) . '- ';
            my $type   = ref $el;
            if ( !$type ) {
                if ($yfm_skip_array) {
                    $self->pushline( $header . YAML::Tiny::_dump_scalar( "dummy", $el, 0 ) . "\n" );
                } else {
                    $self->pushline(
                        $header
                          . format_scalar(
                            $self->translate(
                                $el,                                                            $blockref,
                                ( $is_yfm ? "Yaml Front Matter " : "" ) . "Array Element:$ctx", "wrap" => 0
                            )
                          )
                          . "\n"
                    );
                }

            } elsif ( $type eq 'ARRAY' ) {
                if (@$el) {
                    $self->pushline( $header . "\n" );
                    do_array( $self, $is_yfm, $blockref, $el, $indent + 1,
                        $ctx, $yfm_keys, $yfm_skip_array, $yfm_paths );
                } else {
                    $self->pushline( $header . " []\n" );
                }

            } elsif ( $type eq 'HASH' ) {
                if ( keys %$el ) {
                    $self->pushline( $header . "\n" );
                    do_hash( $self, $is_yfm, $blockref, $el, $indent + 1, $ctx, $yfm_keys, $yfm_skip_array,
                        $yfm_paths );
                } else {
                    $self->pushline( $header . " {}\n" );
                }

            } else {
                die "YAML $type references not supported";
            }
        }
    }

    sub do_hash {
        my ( $self, $is_yfm, $blockref, $hash, $indent, $ctx, $yfm_keys, $yfm_skip_array, $yfm_paths ) = @_;

        foreach my $name ( sort keys %$hash ) {
            my $el     = $hash->{$name} // "";
            my $header = ( '  ' x $indent ) . YAML::Tiny::_dump_scalar( "dummy", $name, 1 ) . ":";

            unless ( length($el) > 0 ) {    # empty element, as in "tags: " with nothing after the column
                $self->pushline( $header . "\n" );
                next;
            }

            my $type = ref $el;
            if ( !$type ) {
                my %keys  = %{$yfm_keys};
                my %paths = %{$yfm_paths};
                my $path  = "$ctx $name" =~ s/^\s+|\s+$//gr;  # Need to trim the path, at least when there is no ctx yet

                if ( ( $el eq 'false' ) or ( $el eq 'true' ) ) {    # Do not translate nor quote booleans
                    $self->pushline("$header $el\n");
                } elsif (
                    ( scalar %keys > 0  && exists $keys{$name} )  or    # the key we need is provided
                    ( scalar %paths > 0 && exists $paths{$path} ) or    # that path is provided
                    ( scalar %keys == 0 && scalar %paths == 0 )         # no key and no path provided
                  )
                {
                    my $translation = $self->translate(
                        $el, $blockref,
                        ( $is_yfm ? "Yaml Front Matter " : "" ) . "Hash Value:$ctx $name",
                        "wrap" => 0
                    );

                    # add extra quotes to the parameter, as a protection to the extra chars that the translator could add
                    $self->pushline( $header . ' ' . format_scalar($translation) . "\n" );
                } else {

                    # Work around a bug in YAML::Tiny that quotes numbers
                    # See https://github.com/Perl-Toolchain-Gang/YAML-Tiny#additional-perl-specific-notes
                    if ( Scalar::Util::looks_like_number($el) ) {
                        $self->pushline("$header $el\n");
                    } else {
                        $self->pushline( $header . ' ' . YAML::Tiny::_dump_scalar( "dummy", $el ) . "\n" );
                    }
                }

            } elsif ( $type eq 'ARRAY' ) {
                if (@$el) {
                    $self->pushline( $header . "\n" );
                    do_array(
                        $self,     $is_yfm,         $blockref, $el, $indent + 1, "$ctx $name",
                        $yfm_keys, $yfm_skip_array, $yfm_paths
                    );
                } else {
                    $self->pushline( $header . " []\n" );
                }

            } elsif ( $type eq 'HASH' ) {
                if ( keys %$el ) {
                    $self->pushline( $header . "\n" );
                    do_hash(
                        $self,     $is_yfm,         $blockref, $el, $indent + 1, "$ctx $name",
                        $yfm_keys, $yfm_skip_array, $yfm_paths
                    );
                } else {
                    $self->pushline( $header . " {}\n" );
                }

            } else {
                die "YAML $type references not supported";
            }
        }
    }
}

=back

=head1 FUTURE DIRECTIONS

One shortcoming of the current TransTractor is that it can't handle
translated document containing all languages, like debconf templates, or
.desktop files.

To address this problem, the only interface changes needed are:

=over 2

=item -

take a hash as po_in_name (a list per language)

=item -

add an argument to translate to indicate the target language

=item -

make a pushline_all function, which would make pushline of its content for
all languages, using a map-like syntax:

    $self->pushline_all({ "Description[".$langcode."]=".
                          $self->translate($line,$ref,$langcode)
                        });

=back

Will see if it's enough ;)

=head1 AUTHORS

 Denis Barbier <barbier@linuxfr.org>
 Martin Quinson (mquinson#debian.org)
 Jordi Vilalta <jvprat@gmail.com>

=cut

1;
