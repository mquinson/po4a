#!/usr/bin/perl -w

require Exporter;

package Locale::Po4a::TransTractor;
use strict;
use subs qw(makespace);
use vars qw($VERSION @ISA @EXPORT);
$VERSION="0.12";
@ISA = ();
@EXPORT = qw(process translate_wrapped translate 
	     read write readpo writepo);

use Carp qw(croak);
use Locale::Po4a::Po;

use Locale::gettext qw(dgettext);

eval q{use Locale::Po4a::Pod.pm};

=head1 NAME

Po4a TransTractor - Generic trans(later ex)tracor.

=head1 DESCRIPTION

The goal po4a [po for anything] project is to ease translations (and more
interstingly, the maintainance of translation) using gettext tools on areas
where they were not expected like documentation.  

This class is the ancestor of all po4a parsers used to parse a document to
search translatable strings, extract them to a po file and remplace them by
their translation in the output document. 

More formally, it takes the following arguments as input:

=over 2

=item -

a document to translate ;

=item -

a po file containing the translations to use.

=back

As output, it produces:

=over 2

=item -

another po file, resulting of the extraction of translatable strings from
the input document ;

=item -

a translated document, with the same structure than the one in input, but
with all translatable strings remplaced with the translations found in the
po file provided in input.

=back

Here is a graphical representation of this:

   Input document --\                             /---> Output document
                     \                           /       (translated)
                      +-> parse() function -----+
                     /                           \
   Input po --------/                             \---> Output po
                                                         (extracted)

=head1 FUNCTIONS YOUR PARSER SHOULD OVERRIDE

=over 4

=item parse()

This is where all the work take place: the parsing of input documents, the
generation of output, and the extraction of the translatable strings. This
is pretty simple using the provided functions presented in the section
"INTERNAL FUNCTIONS" below. See also the synopsis, which present an
example.

This function is called by the process() function bellow, but if you choose
to use the new() function, and to add content manually to your document,
you will have to call this function yourself.

=item docheader()

This function returns the header we should add to the produced document,
quoted properly to be comment in the target language.  See the section
"Educating developers about translations", from po4a(7), for what it is
good for.

=back

=cut

sub docheader {}

sub parse {}

=head1 SYNOPSIS

The following example parse a list paragraphs begining with "<p>". For sake
of simplicity, we assume that the document is well formatted, ie that '<p>'
tags are the only tags present, and that this tag is at the very begining
of each paragraph.

 sub parse {
   PARAGRAPH: while (1) {
       $my ($paragraph,$pararef,$line,$lref)=("","","","");
       $my $first=1;
       while (($line,$lref)=$document->shiftline() && defined($line)) {
	   ($line,$lref)=$document->shiftline();
	   if ($line =~ m/<p>/ && !$first--; ) {
	       # Not the first time we see <p>. 
	       # Reput the current line in input,
	       #  and put the builded paragraph to output
	       $document->unshiftline($line,$lref);
	      
	       # Now that the document is formed, translate it:
	       #   - Remove the leading tag
	       $paragraph =~ s/^<p>//s;

	       #   - push to output the leading tag (untranslated) and the
	       #     rest of the paragraph (translated)
	       $document->pushline(  "<p>"
                                   . $document->translate($paragraph,$pararef)
                                   );

 	       next PARAGRAPH;
	   } else {
	       # Append to the paragraph
	       $paragraph .= $line;
	       $pararef = $lref unless(length($pararef));
	   }
       }
       # Did not got a defined line? End of input file.
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
invocation:. Its arguments must be packed as a hash. ACTIONS:

=over 3

=item a.

Reads all the po files specified in po_in_name

=item b.

Reads all original documents specified in file_in_name

=item c.

Parse the document

=item d.

Read and apply all the addendum specified

=item e.

Writes the translated document to file_out_name (if given)

=item f.

Write the extracted po file to po_out_name (if given)

=back

ARGUMENTS, beside the ones accepted by new()(with expected type):

=over 4

=item file_in_name (@)

list of filenames where we should read the input document.

=item file_out_name ($)

filename where we should write the output document.

=item po_in_name (@)

list of filenames where we should read the input po files from, containing
the translation which will be used to translate the document.

=item po_out_name ($)

filename where we should write the output po file, containing the strings
extracted from the input document.

=item addendum (@)

list of filenames where we should read the addendum from.

=back

=item new(%)

Create a new Po4a document. Accepted options (but be in a hash):

=over 4

=item verbose ($)

Boolean indicating if we're verbose.

=back

=cut

sub process {
    ## Determine if we were called via an object-ref or a classname
    my $self = shift;

    ## Any remaining arguments are treated as initial values for the
    ## hash that is used to represent this object.
    my %params = @_;
    
    # Build the args for new()
    my %newparams = ();
    foreach (keys %params) {
	next if ($_ eq 'po_in_name' ||
		 $_ eq 'po_out_name' ||
		 $_ eq 'file_in_name' ||
		 $_ eq 'file_out_name' ||
		 $_ eq 'addendum');
	$newparams{$_}=$params{$_};
    }

    foreach my $file (@{$params{'po_in_name'}}) {
	print STDERR "readpo($file)... " if $self->debug();
	$self->readpo($file);
	print STDERR "done.\n" if $self->debug()
    }
    foreach my $file (@{$params{'file_in_name'}}) {
	print STDERR "read($file)..." if $self->debug();
	$self->read($file);
	print STDERR "done.\n"  if $self->debug();
    }
    print STDERR "parse..." if $self->debug();
    $self->parse();
    print STDERR "done.\n" if $self->debug();
    foreach my $file (@{$params{'addendum'}}) {
	print STDERR "addendum($file)..." if $self->debug();
	$self->addendum($file) || die "An addendum failed\n";
	print STDERR "done.\n" if $self->debug();
    }
    if (defined $params{'file_out_name'}) {
	print STDERR "write(".$params{'file_out_name'}.")... " 
	    if $self->debug();
	$self->write($params{'file_out_name'});
	print STDERR "done.\n" if $self->debug();
    }
    if (defined $params{'po_out_name'}) {
	print STDERR "writepo(".$params{'po_out_name'}.")... "
	     if $self->debug();
	$self->writepo($params{'po_out_name'});
	print STDERR "done.\n" if $self->debug();
    }
    return $self;
}

sub new {
    ## Determine if we were called via an object-ref or a classname
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = { };
    my %options=@_;
    ## Bless ourselves into the desired class and perform any initialization
    bless $self, $class;
    $self->initialize(%options);
    return $self;
}

sub initialize {
    my $self=shift;
    my %options=@_;

    # private data
    $self->{DOC}=(); 
    $self->{DOC}{po_in}=Locale::Po4a::Po->new();
    $self->{DOC}{po_out}=Locale::Po4a::Po->new();
    # Warning, this is an array of array:
    #  The document is splited on lines, and for each
    #  [0] is the line content, [1] is the reference [2] the type
    $self->{DOC}{doc_in}=();
    $self->{DOC}{doc_out}=();

    if (defined $options{'verbose'}) {
	$self->{DOC}{verbose}  =  $options{'verbose'};
    }
    if (defined $options{'debug'}) {
	$self->{DOC}{debug}  =  $options{'debug'};
    }
}

=back

=head2 manipulating document files

=over 4

=item read($)

Add another input document at the end of the existing one. The argument is
the filename to read. 

Please note that it does not parse anything. You should use the parse()
function when you're done with packing input files into the document. 

=cut

#'
sub read() {
    my $self=shift;
    my $filename=shift
	or croak(dgettext("po4a","Can't read from file without having a filename\n"));
    my $linenum=1;

    open INPUT,"<$filename" 
	or croak (sprintf(dgettext("po4a","Can't read from %s: %s\n"),$filename,$!));
    while (defined (my $textline = <INPUT>)) {
	$linenum++;
	my $ref="$filename:$linenum";
	my @entry=($textline,$ref);
	push @{$self->{DOC}{doc_in}}, @entry;
    }
    close INPUT 
	or croak (sprintf(dgettext("po4a","Can't close %s after reading: %s\n"),$filename,$!));

}

=item write($)

Write the translated document to the given filename.

=cut

sub write {
    my $self=shift;
    my $filename=shift
	or croak (dgettext("po4a","Can't write to a file without filename\n"));

    my $fh;
    if ($filename eq '-') {
	$fh=\*STDOUT;
    } else {
	open $fh,">$filename" 
	    || croak (sprintf((dgettext("po4a","can't write to %s: %s\n"),$filename,$!)));
    }
    
    map { print $fh $_ } $self->docheader();
    map { print $fh $_ } @{$self->{DOC}{doc_out}};

    if ($filename ne '-') {
	close $fh || croak (sprintf(dgettext("po4a","Can't close %s after writing: %s\n"),$filename,$!));
    }

}

=back

=head2 Manipulating po files

=over 4 

=item readpo($)

Add the content of a file (which name is passed in argument) to the
existing input po. The old content is not discarded.

=item writepo($)

Write the extracted po file to the given filename.

=item stats()

Returns some statistics about the translation done so far. Please note that
it's not the same statistics than the one printed by msgfmt
--statistic. Here, it's stats about recent usage of the po file, while
msgfmt reports the status of the file. It is a wrapper to the
Locale::Po4a::Po::stats_get function applied to the input po file. Example
of use:

    [normal use of the po4a document...]

    ($percent,$hit,$queries) = $document->stats();
    print "We found translations for $percent\%  ($hit from $queries) of strings.\n";

=back

=cut

sub getpoout {
    return $_[0]->{DOC}{po_out};
}
sub readpo  { 
    $_[0]->{DOC}{po_in}->read($_[1]);        
}
sub writepo { 
    $_[0]->{DOC}{po_out}->write( $_[1] );    
}
sub stats   { 
    return $_[0]->{DOC}{po_in}->stats_get(); 
}

=cut

=head2 Manipulating addendum

=over 4

=item addendum($)

Please refer to po4a(7) for more information on what addendum are, and how
translators should write them. To apply an addendum to the translated
document, simply pass its filename to this function and you are done ;)

This function returns a non-nul integer on error.

=cut

# Internal function to read the header.
sub addendum_parse {
    my ($filename,$header)=shift;

    my ($errcode,$mode,$position,$boundary,$bmode,$lang,$content)=
	(1,"","","","","");

    unless (open (INS, "<$filename")) {
	warn sprintf(dgettext("po4a","Can't read from %s: %s\n"),$filename,$!);
	goto END_PARSE_ADDFILE;
    } 

    unless (defined ($header=<INS>) && $header)  {
	warn sprintf(dgettext("po4a","Can't read Po4a header from %s.\n"),
		     $filename);
	goto END_PARSE_ADDFILE;
    }

    unless ($header =~ s/PO4A-HEADER://i) {
	warn sprintf(dgettext("po4a","First line of %s does not look like a Po4a header.\n"),
		     $filename);
	goto END_PARSE_ADDFILE;
    }
    foreach my $part (split(/;/,$header)) {
	unless ($part =~ m/^([^=]*)=(.*)$/) {
	    warn sprintf(dgettext("po4a","Syntax error in Po4a header of %s, near \"%s\"\n"),
			 $filename,$part);
	    goto END_PARSE_ADDFILE;
	}
	my ($key,$value)=($1,$2);
	$key=lc($key);
  	     if ($key eq 'mode')     {  $mode=lc($value);
	} elsif ($key eq 'lang')     {  $lang=$value;
	} elsif ($key eq 'position') {  $position=$value;
	} elsif ($key eq 'endboundary') {  
	    $boundary=$value;
	    $bmode='after';
	} elsif ($key eq 'beginboundary') {  
	    $boundary=$value;
	    $bmode='before';
	} else { 
	    warn sprintf(dgettext("po4a","Invalid argument in the Po4a header of %s: %s\n"),
			 $filename,$key);
	    goto END_PARSE_ADDFILE;
	}
    }

    unless (length($mode)) {
	warn sprintf(dgettext("po4a","The Po4a header of %s does not define the mode.\n"),
		     $filename);
	goto END_PARSE_ADDFILE;
    }
    unless ($mode eq "before" || $mode eq "after") {
	warn sprintf(dgettext("po4a","Mode invalid in the Po4a header of %s: should be 'before' or 'after' not %s.\n"),
		     $filename,$mode);
	goto END_PARSE_ADDFILE;
    }

    unless (length($position)) {
	warn sprintf(dgettext("po4a","The Po4a header of %s does not define the position.\n"),
		     $filename);
	goto END_PARSE_ADDFILE;
    }
    unless ($mode eq "before" || length($boundary)) {
    	warn dgettext("po4a","No ending boundary given in the Po4a header, but mode=after.\n");
	goto END_PARSE_ADDFILE;
    }

    while (defined(my $line = <INS>)) {
	$content .= $line;
    }
    close INS;

    $errcode=0;
  END_PARSE_ADDFILE: 
      return ($errcode,$mode,$position,$boundary,$bmode,$lang,$content);
}

sub addendum {
    my ($self,$filename) = @_;
    
    warn(dgettext("po4a",
		  "Can't insert addendum when not given the filename\n"))
	unless $filename;
  
    my ($errcode,$mode,$position,$boundary,$bmode,$lang,$content)=
	addendum_parse($filename);
    return 0 if ($errcode);

    my $found = scalar grep { /$position/ } @{$self->{DOC}{doc_out}};
    if ($found == 0) {
	warn sprintf(dgettext("po4a",
			      "No candidate position for the addendum %s.\n"),
		     $filename);
	return 0;
    }
    if ($found > 1) {
	warn sprintf(dgettext("po4a",
			      "More than one cadidate position found for the addendum %s.\n"),
		     $filename);
	return 0;
    }

    if ($mode eq "before") {
	@{$self->{DOC}{doc_out}} = map { /$position/ ? ($content,$_) : $_ 
                                        }  @{$self->{DOC}{doc_out}};
    } else {
	my @newres=();
	while (my $line=shift @{$self->{DOC}{doc_out}}) {
	    push @newres,$line;
	    if ($line =~ m/$position/) {
		while ($line=shift @{$self->{DOC}{doc_out}}) {
		    last if ($line=~/$boundary/);
		    push @newres,$line;
		}
		if ($bmode eq 'before') {
		    push @newres,$content;
		    push @newres,$line;
		} else {
		    push @newres,$line;
		    push @newres,$content;
		}
	    }
	}
	@{$self->{DOC}{doc_out}} = @newres;
    }
    return 1;
}


=head1 INTERNAL FUNCTIONS used to write derivated parsers

=head2 Getting input, providing output

Four functions are provided to get input and return output. They are very
similar to shift/unshift and push/pop. The first pair is about input, while
the second is about output. Mnemonic: in input, you are interested in the
first line, what shift gives, and in output you want to add your result at
the end, like pop does.

=over 4

=item shiftline()

This function returns the next line of the doc_in to be parsed and its
reference (packed as an array).

=item unshiftline($$)

Unshifts a line of the input document and its reference. 

=item pushline($)

Push a new line to the doc_out.

=item popline()

Pop the last pushed line from the doc_out.

=back

=cut

sub shiftline   {  
    my ($line,$ref)=(shift @{$_[0]->{DOC}{doc_in}},
		     shift @{$_[0]->{DOC}{doc_in}}); 
    return ($line,$ref);
}
sub unshiftline {  unshift @{$_[0]->{DOC}{doc_in}},($_[1],$_[2]);  }
		
sub pushline    {  push @{$_[0]->{DOC}{doc_out}}, $_[1] if defined $_[1]; }
sub popline     {  return pop @{$_[0]->{DOC}{doc_out}};            }

=head2 Marking strings as translatable

Two functions are provided to handle the text which should be translated. 

=over 4

=item translate($$$)

Arguments:

=over 2

=item -

A string to translate

=item -

The reference of this string (ie, position in inputfile)

=item -

The type of this string (ie, the textual description of its structural role
; used in Locale::Po4a::Po::fusion())

=back

Actions:

=over 2

=item -

Pushes the string, reference and type to po_out.

=item -

Returns the translation of the string (as found in po_in) so that the
parser can build the doc_out.

=back

=item translate_wrapped($$$$?)

Does the same thing than translate, but consider that whitespaces in string
are not important. Consequently, it canonize the string before looking for
a translation or extracting it, and wraps the translation.

If a fourth parameter is passed, it is the wrap column (default: 76).

=back

=cut

sub translate {
    my $self=shift;
    my ($string,$ref,$type)=(shift,shift,shift);

    return "" unless defined($string) && length($string);

    $self->{DOC}{po_out}->push('msgid'     => "$string",
			       'reference' => $ref,
			       'type'      => $type);

    return ($self->{DOC}{po_in}->gettext("$string"));
}

sub translate_wrapped {
    my $self=shift;
    my ($string,$ref,$type,$wrapcol)=(shift,shift,shift,shift|| 76);

    return "" unless defined($string) && length($string);

    $self->{DOC}{po_out}->push_wrapped('msgid'     => $string,
				       'reference' => $ref,
				       'type'      => $type);
    return $self->{DOC}{po_in}->gettext_wrapped($string);
}

=head2 Misc functions

=over 4

=item verbose()

Returns if the verbose option was passed during the creation of the
TransTractor.

=back

=cut

sub verbose {
    return $_[0]->{DOC}{verbose};
}

=item debug()

Returns if the debug option was passed during the creation of the
TransTractor.

=back

=cut

sub debug {
    return $_[0]->{DOC}{debug};
}

=head1 FUTURE DIRECTIONS

One shortcoming of the current TransTractor is that it can't handle
translated document containing all languages, like debconf templates, or
.desktop files.

To address this problem, the only interface changes needed are:

=over 2

=item - 

take an hash as po_in_name (a list per language)

=item -

add an argument to translate{,_wrapped} to indicate the target language

=item -

make a pushline_all function, which would make pushline of its content for
all language, using a map-like syntax:

    $self->pushline_all({ "Description[".$langcode."]=".
			  $self->translate($line,$ref,$langcode) 
		        });

=back

Will see if it's enough ;)

=cut

1;
