# Locale::Po4a::Po -- manipulation of po files 
# $Id: Po.pm,v 1.3 2003-02-12 07:58:33 mquinson Exp $
#
# Copyright 2002 by Martin Quinson <Martin.Quinson@ens-lyon.fr>
#
# This program is free software; you may redistribute it and/or modify it
# under the terms of GPL (see COPYING).

############################################################################
# Modules and declarations
############################################################################

=head1 NAME

Locale::Po4a::Po - po file manipulation module

=head1 SYNOPSIS    

    use Locale::Po4a::Po;
    my $pofile=Locale::Po4a::Po->new();

    # Read po file
    $pofile->load('file.po');

    # Add an entry
    $pofile->push('msgid' => 'Hello', 'msgstr' => 'bonjour', 
                  'flags' => "wrap", 'reference'=>'file.c:46');

    # Extract a translation
    $pofile->gettext("Hello"); # returns 'bonjour'

    # Write back to a file
    $pofile->write('otherfile.po');

=head1 DESCRIPTION

Locale::Po4a::Po is a module that allows you to manipulate message
catalogs. You can load and write from/to a file (which extension is often
I<po>), you can build new entries on the fly or request for the translation
of a string.

For a more complete description of message catalogs in the po format and
their use, please refer to the documentation of the gettext program.

This module is part of the PO4A project, which objectif is to use po files
(designed at origin to ease the translation of program messages) to
translate everything, including documentation (man page, info manual),
package description, debconf templates, and everything which may benefit
from this.


=cut

use IO::File;


require Exporter;

package Locale::Po4a::Po;

use Locale::Po4a::TransTractor;

use 5.006;
use strict;
use warnings;

use subs qw(makespace);
use vars qw($VERSION @ISA @EXPORT);
$VERSION=$Locale::Po4a::TransTractor::VERSION;
@ISA = ();
@EXPORT = qw(load write gettext);

use Carp qw(croak);
use Locale::gettext qw(dgettext);

my @known_flags=qw(wrap no-wrap c-format fuzzy);

=head1 Functions about whole message catalogs

=over 4

=item B<new()>

Creates a new message catalog. If an argument is provided, it's the name of
a po file we should load.

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;
    $self->initialize();
 
    my $filename = shift;
    $self->read($filename) if defined($filename) && $filename;
    return $self;
}

sub initialize {
    my $self = shift;
    my $date = `date +'%Y-%m-%d %k:%M%z'`;
    chomp $date;

    $self->{po}=();
    $self->{count}=0;
    $self->{header_comment}=
	escape_text( " SOME DESCRIPTIVE TITLE\n"
		    ." Copyright (C) YEAR Free Software Foundation, Inc.\n"
		    ." FIRST AUTHOR <EMAIL\@ADDRESS>, YEAR.\n"
		    ."\n"
		    .", fuzzy");
#    $self->header_tag="fuzzy";
    $self->{header}=escape_text("Project-Id-Version: PACKAGE VERSION\n".
				"POT-Creation-Date: $date\n".
				"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\n".
				"Last-Translator: FULL NAME <EMAIL\@ADDRESS>\n".
				"Language-Team: LANGUAGE <LL\@li.org>\n".
				"MIME-Version: 1.0\n".
				"Content-Type: text/plain; charset=CHARSET\n".
				"Content-Transfer-Encoding: ENCODING");

    # To make stats about gettext hits
    $self->stats_clear();
}

=item B<read()>

Reads a po file (which name is given as argument).  Previously existing
entries in self are not removed, the new one are added to the end of the
catalog.

=cut

sub read{
    my $self=shift;
    my $filename=shift 
	|| croak (dgettext("po4a","Please provide a non-nul filename to Locale::Po4a::Po::read()\n"));

    open INPUT,"<$filename" 
	|| croak (sprintf(dgettext("po4a","Can't read from %s: %s\n"),$filename,$!));

    ## Read paragraphs line-by-line
    my $pofile="";
    my $textline;
    while (defined ($textline = <INPUT>)) {
	$pofile .= $textline;
    }
    close INPUT || croak (sprintf(dgettext("po4a","Can't close %s after reading: %s\n"),$filename,$!));

    my $linenum=0;

    foreach my $msg (split (/\n\n/,$pofile)) {
        my ($msgid,$msgstr,$comment,$automatic,$reference,$flags,$buffer);
	foreach my $line (split (/\n/,$msg)) {
	    $linenum++;
	    if ($line =~ /^#\. ?(.*)/) {  # Automatic comment
		$automatic .= (defined($automatic) ? "\n" : "").$1;
		
	    } elsif ($line =~ /^#: ?(.*)/) { # reference
	        $reference .= (defined($reference) ? "\n" : "").$1;
		     
	    } elsif ($line =~ /^#, ?(.*)/) { # flags
		$flags .= (defined($flags) ? "\n" : "").$1;
		 
	    } elsif ($line =~ /^#(.*)/ || $line =~ /^#$/) {  # Translator comments 
	        $comment .= (defined($comment) ? "\n" : "").($1||"");

	    } elsif ($line =~ /^msgid (".*")/) { # begin of msgid
	        $buffer .= (defined($buffer) ? "\n" : "").$1;
		 
	    } elsif ($line =~ /^msgstr (".*")/) { # begin of msgstr, end of msgid
	        $msgid = $buffer;
	        $buffer = "$1";
	     
	    } elsif ($line =~ /^(".*")/) { # continuation of a line
	        $buffer .= "\n$1";
	    } else {
	        warn sprintf(dgettext("po4a","Strange line at line %s: -->%s<--\n"),
			     $linenum,$line);
	    }
	}
	$msgstr=$buffer;
	$msgid = unquote_text($msgid) if (defined($msgid));
	$msgstr = unquote_text($msgstr) if (defined($msgstr));
        $self->push_raw ('msgid'     => $msgid,
		        'msgstr'    => $msgstr,
		        'reference' => $reference,
		        'flags'     => $flags,
		        'comment'   => $comment,
		        'automatic' => $automatic);
    }
}

=item B<write()>

Writes the current catalog to the given file.

=cut

sub write{
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

    print $fh "".format_comment(unescape_text($self->{header_comment}),"") 
	if $self->{header_comment};

    print $fh "msgid \"\"\n";
    print $fh "msgstr ".quote_text($self->{header})."\n\n";


    my $first=1;
    foreach my $msgid ( sort { ($self->{po}{"$a"}{'pos'}) <=> 
 			       ($self->{po}{"$b"}{'pos'}) 
                             }  keys %{$self->{po}}) {
	my $output="";

	if ($first) {
	    $first=0;
	} else {
	    $output .= "\n";
	}
	
	$output .= format_comment($self->{po}{$msgid}{'comment'},"") 
	    if $self->{po}{$msgid}{'comment'};
	$output .= format_comment($self->{po}{$msgid}{'automatic'},". ") 
	    if $self->{po}{$msgid}{'automatic'};
	$output .= format_comment($self->{po}{$msgid}{'type'}," type: ") 
	    if $self->{po}{$msgid}{'type'};
	$output .= format_comment($self->{po}{$msgid}{'reference'},": ") 
	    if $self->{po}{$msgid}{'reference'};
	$output .= format_comment($self->{po}{$msgid}{'flags'},", ") 
	    if $self->{po}{$msgid}{'flags'};

	$output .= "msgid ".quote_text($msgid)."\n";
	$output .= "msgstr ".quote_text($self->{po}{$msgid}{'msgstr'})."\n";
	print $fh $output;
    }   
#    print STDERR "$fh";
#    if ($filename ne '-') {
#	close $fh || croak (sprintf(dgettext("po4a","Can't close %s after writing: %s\n"),$filename,$!));
#    }
}

=item gettextize()

This function produce one translated message catalog from two catalogs, an
original an a translation. This process is described in po4a(7), section
I<Gettextization: how does it work?>. 

=cut

sub gettextize { 
    my $this = shift;
    my $class = ref($this) || $this;
    my ($poorig,$potrans)=(shift,shift);
   
    my $pores=Locale::Po4a::Po->new();
 
    if ($poorig->count_entries() > $potrans->count_entries()) {
	warn sprintf(dgettext("po4a","po4a gettextize: Original have more strings that the translation (%d>%d). Please fix it by editing the translated version to add a dummy entry.\n"),
		    $poorig->count_entries() , $potrans->count_entries());
    } elsif ($poorig->count_entries() < $potrans->count_entries()) {
	warn sprintf(dgettext("po4a","po4a gettextize: Original have less strings that the translation (%d<%d). Please fix it by editing the translated file to remove the extra entry (you may want to create an adendum).\n"),
		    $poorig->count_entries() , $potrans->count_entries());
    }
    
    for (my ($o,$t)=(0,0) ;
	 $o<$poorig->count_entries() && $t<$potrans->count_entries();
	 $o++,$t++) {
	#
	# Extract some informations
	#
	my ($orig,$trans)=($poorig->msgid($o),$potrans->msgid($t));

	my ($reforig,$reftrans)=($poorig->{po}{$orig}{'reference'},
				 $potrans->{po}{$trans}{'reference'});
	my ($typeorig,$typetrans)=($poorig->{po}{$orig}{'type'},
				   $potrans->{po}{$trans}{'type'});

	#
	# Make sure the type of both string exist
	#
	die sprintf(dgettext("po4a","Internal error in gettextization: type of original string number %s isn't provided\n"),$o)
	    if ($typeorig eq '');
	
	die sprintf(dgettext("po4a","Internal error in gettextization: type of translated string number %s isn't provided\n"),$o)
	    if ($typetrans eq '');

	#
	# Make sure both type are the same
	#
	if ($typeorig ne $potrans->{po}{$trans}{'type'}){
	    die sprintf(dgettext("po4a","po4a gettextization: Structure disparity between original and translated files:\n msgid (at %s) is of type '%s' while\n msgstr (at %s) is of type '%s'.\nOriginal text: %s\nTranslated text:%s\n"),
			$reforig,$typeorig,$reftrans,$typetrans,$orig,$trans);
	}
	
	# 
	# Push the entry
	#
	$pores->push_raw('msgid' => $orig, 'msgstr' => $trans, 
			 'flags' => ($poorig->{po}{$orig}{'flags'} ? $poorig->{po}{$orig}{'flags'} :"").
                                    " fuzzy",
			 'reference' => $reforig);
    }
    return $pores;
}
=back

=head1 Functions to use a message catalogs for translations

=over 4

=item B<gettext($%)>

Request the translation of the string given as argument in the current catalog.
The function returns the empty string if the string was not found.

After the string to translate, you can pass an hash of extra
arguments. Here are the valid entries:

=over

=item wrap

boolean indicating wheather we can consider that whitespaces in string are
not important. If yes, the function canonize the string before looking for
a translation, and wraps the result.

=item wrapcol

The column at which we should wrap (default: 76).

=back

=cut

sub gettext {
    my $self=shift;
    my $text=shift;
    my (%opt)=@_;
    my $res;

    return "" unless defined($text) && length($text); # Avoid returning the header.
    my $validoption="wrap wrapcol";
    my %validoption;

    map { $validoption{$_}=1 } (split(/ /,$validoption));
    foreach (keys %opt) {
	Carp::confess "internal error:  unknown arg $_.\n".
	              "Here are the valid options: $validoption.\n"
	    unless $validoption{$_};
    }
    
    $text=canonize($text)     
	if ($opt{'wrap'});

    my $esc_text=escape_text($text);

    $self->{gettextqueries}++;
    
    if ($self->{po}{$esc_text}  && 
	defined( $self->{po}{$esc_text}{'msgstr'} ) &&
	length( $self->{po}{$esc_text}{'msgstr'} )) { 

	$self->{gettexthits}++;
	$res= unescape_text($self->{po}{$esc_text}{'msgstr'});
    } else {
	$res= $text;
    }

    if ($opt{'wrap'}) {
	$res=wrap ($res, $opt{'wrapcol'} || 76);
    }
#    print STDERR "Gettext >>>$text<<<(escaped=$esc_text)=[[[$res]]]\n\n";
    return $res;
}

=item B<stats_get()>

Returns stats about the hit ratio of gettext since the last time that
stats_clear() were called. Please note that it's not the same
statistics than the one printed by msgfmt --statistic. Here, it's stats
about recent usage of the po file, while msgfmt reports the status of the
file.  Example of use:

    [some use of the po file to translate stuff]

    ($percent,$hit,$queries) = $pofile->stats_get();
    print "So far, we found translations for $percent\%  ($hit of $queries) of strings.\n";

=cut

sub stats_get() {
    my $self=shift;
    my ($h,$q)=($self->{gettexthits},$self->{gettextqueries});
    my $p = ($q == 0 ? 0 : int($h/$q*10000)/100);

#    $p =~ s/\.00//;
#    $p =~ s/(\..)0/$1/;

    return ( $p,$h,$q );
}

=item B<stats_clear()>

Clears the stats about gettext hits.

=cut

sub stats_clear {
    my $self = shift;
    $self->{gettextqueries} = 0;
    $self->{gettexthits} = 0;
}

=back

=head1 Functions to build a message catalogs

=over 4

=item B<push()>

Push a new entry at the end of the current catalog. The arguments should
form an hash table. The valid keys are :

=over 4

=item msgid

the string in original language which is translated.

=item msgstr

the translation

=item reference

an indication of where this string was found. Example: file.c:46 (meaning
in 'file.c' at line 46). It can be a space separated list in case of
multiple occurences.

=item comment

a comment added here manually. The format here is free.

=item automatic

a comment which where automatically added by the string extraction
program. See the I<--add-comments> option of the B<xgettext> program for
more information.

=item flags

space-separated list of all defined flags for this entry. 

Valid flags are: c-text, python-text, lisp-text, elisp-text, librep-text,
smalltalk-text, java-text, awk-text, object-pascal-text, ycp-text,
tcl-text, wrap, no-wrap and fuzzy. 

See the gettext documentation for their meaning.

=item type

This is mostly an internal argument: it is used while gettextizing
documents. The idea here is to parse both the original and the translation
into a po object, and merge them, using one's msgid as msgid and the
other's msgid as msgstr. To make sure that things get ok, each msgid in po
objects are given a type, based on their structure (like "chapt", "sect1",
"p" and so on in docbook). If the types of strings are not the same, that
mean that both files do not share the same structure, and the process
repports an error.

This information is not written to the po file.

=item wrap

boolean indicating wheather we can consider that whitespaces in string are
not important. If yes, the function canonize the string before use.

This information is not written to the po file.

=item wrapcol 

The column at which we should wrap (default: 76).

This information is not written to the po file.

=back

=cut

sub push {
    my $self=shift;
    my %entry=@_;

    my $validoption="wrap wrapcol type msgid msgstr automatic flags reference";
    my %validoption;

    map { $validoption{$_}=1 } (split(/ /,$validoption));
    foreach (keys %entry) {
	Carp::confess "internal error:  unknown arg $_.\n".
	              "Here are the valid options: $validoption.\n"
	    unless $validoption{$_};
    }

    unless ($entry{'wrap'}) {
	$entry{'flags'} .= " no-wrap";
    }
    if (defined ($entry{'msgid'})) {
	$entry{'msgid'} = canonize($entry{'msgid'})
	    if ($entry{'wrap'});

	$entry{'msgid'} = escape_text($entry{'msgid'});
    }
    if (defined ($entry{'msgstr'})) {
	$entry{'msgstr'} = canonize($entry{'msgstr'})
	    if ($entry{'wrap'});

	$entry{'msgstr'} = escape_text($entry{'msgstr'});
    }

    $self->push_raw(%entry);
}

# The same as push(), but assuming that msgid and msgstr are already escaped
sub push_raw {
    my $self=shift;
    my %entry=@_;
    my ($msgid,$msgstr,$reference,$comment,$automatic,$flags,$type)=
	($entry{'msgid'},$entry{'msgstr'},
	 $entry{'reference'},$entry{'comment'},$entry{'automatic'},
	 $entry{'flags'},$entry{'type'});

#    print STDERR "Push_raw\n";
#    print STDERR " msgid=>>>$msgid<<<\n" if $msgid;
#    print STDERR " msgstr=[[[$msgstr]]]\n" if $msgstr;
    
    return unless defined($entry{'msgid'});

    #no msgid => header definition
    unless (length($entry{'msgid'})) { 
#	if (defined($self->{header}) && $self->{header} =~ /\S/) {
#	    warn dgettext("po4a","Redefinition of the header. The old one will be discarded\n");
#	} FIXME: do that iff the header isn't the default one.
	$self->{header}=$msgstr;
	$self->{header_comment}=$comment;
	return;
    }
    
    if (defined($self->{po}{$msgid})) {
        warn sprintf(dgettext("po4a","msgid defined twice: %s"),$msgid) if (0); # FIXME: put a verbose stuff
	if ($msgstr && $self->{po}{$msgid}{'msgstr'} 
	    && $self->{po}{$msgid}{'msgstr'} ne "$msgstr") {
	    my $txt=quote_text($msgid);
	    my ($first,$second)=
		(format_comment(". ",$self->{po}{$msgid}{'reference'}).
		 quote_text($self->{po}{$msgid}{'msgstr'}),
		 format_comment(". ",$reference).
		 quote_text($msgstr));

	    warn sprintf(dgettext("po4a","Translations don't match for:\n%s\n-->First translation: \n%s\n Second translation: \n%s\n Old translation discarded.\n"),$txt,$first,$second);
	}
    }
    $self->{po}{$msgid}{'reference'} = (defined($self->{po}{$msgid}{'reference'}) ? 
                                          $self->{po}{$msgid}{'reference'}." " : "")
                                         . $reference
       if (defined($reference));
    $self->{po}{$msgid}{'msgstr'} = $msgstr;
    $self->{po}{$msgid}{'comment'} = $comment;
    $self->{po}{$msgid}{'automatic'} = $automatic;
    unless (defined($self->{po}{$msgid}{'pos'})) {
      $self->{po}{$msgid}{'pos'} = $self->{count}++;
    }
    $self->{po}{$msgid}{'type'} = $type;
      
    if (defined($flags)) {
        $flags = " $flags ";
        $flags =~ s/,/ /g;
	foreach my $flag (@known_flags) {
	    if ($flags =~ /\s$flag\s/) {
	       $self->{po}{$msgid}{'flags'} .= (defined($self->{po}{$msgid}{'flags'}) ? 
                                                  "," : "")
                                                 .$flag;
            }
        }
    }
#    print STDERR "stored ((($msgid)))=>(((".$self->{po}{$msgid}{'msgstr'}.")))\n\n";

}

=back

=head1 Miscellaneous functions

=over 4

=item count_entries()

Returns the number of entries in the catalog (without the header).

=cut

sub count_entries($) {
    my $self=shift;
    return $self->{count};
}

=item msgid($)

Returns the msgid of the given number.

=cut

sub msgid($$) {
    my $self=shift;
    my $num=shift;
    
    foreach my $msgid ( keys %{$self->{po}} ) {
	return $msgid if ($self->{po}{$msgid}{'pos'} eq $num);
    }
    return undef;
}

#----[ helper functions ]---------------------------------------------------

# transforme the string from its po file representation to the form which 
#   should be used to print it
sub unescape_text {
    my $text = shift;

    $text = join("",split(/\n/,$text));
    $text =~ s/\\"/"/g;
    $text =~ s/\\n/\n/g;
    $text =~ s/\\t/\t/g;
    $text =~ s/\\\\/\\/g;

    return $text;
}

# transforme the string to its representation as it should be written in po files
sub escape_text {
    my $text = shift;
    
    $text =~ s/\\/\\\\/g;
    $text =~ s/"/\\"/g;
    $text =~ s/\n/\\n/g;
    $text =~ s/\t/\\t/g;
   
    return $text;
}

# put quotes around the string on each lines (without escaping it)
# It does also normalize the text (ie, make sure its representation is wraped 
#   on the 80th char, but without changing the meaning of the string) 
sub quote_text {
  my $string = shift;

  return '""' unless defined($string) && length($string);

  $string =~ s/\\n/!!DUMMYPOPM!!/gm;
  $string =~ s|!!DUMMYPOPM!!|\\n\n|gm;
  $string = wrap($string);
  my @string = split(/\n/,$string);
  $string = join ("\"\n\"",@string);
  $string = "\"$string\"";
  if (scalar @string > 1 && $string[0] ne '') {
      $string = "\"\"\n".$string;
  }

  return $string;
}

# undo the work of the quote_text function
sub unquote_text {
  my $string = shift;
  $string =~ s/^""\\n//s;
  $string =~ s/^"(.*)"$/$1/s;
  $string =~ s/"\n"//gm;
  $string =~ s/\\n\n/!!DUMMYPOPM!!/gm;
  $string =~ s|!!DUMMYPOPM!!|\\n|gm;
  return $string;
}

# canonize the string: write it on only one line, changing consecutive whitespace to
# only on space.
# Warning, it changes the string and should only be called if the string is plain text
sub canonize {
    my $text=shift;
    $text =~ s/^ *//s;
    $text =~ s/([.])\n/$1  /gm;
    $text =~ s/ \n/ /gm;
    $text =~ s/\n/ /gm;
    $text =~ s/([.)])  +/$1  /gm;
    $text =~ s/([^.)])  */$1 /gm;
    $text =~ s/ *$//s;
    return $text;
}

# wraps the string. We don't use Text::Wrap since it mangles whitespace at
# the end of splited line
sub wrap {
    my $text=shift;
    return "0" if ($text eq '0');
    my $col=shift || 76;
    my @lines=split(/\n/,"$text");
    my $res="";
    my $first=1;
    while (my $line=shift @lines) {
	if ($first && length($line) > $col - 10) {
	    $res .= "\n";
	    unshift @lines,$line;
	    $first=0;
	    next;
	}
	if (length($line) > $col) {
	    my $pos=rindex($line," ",$col);
	    while (substr($line,$pos-1,1) eq '.' && $pos != -1) {
		$pos=rindex($line," ",$pos-1);
	    }
	    if ($pos != -1) {
		my $end=substr($line,$pos+1);
		$line=substr($line,0,$pos+1);
		if ($end=~s/^( +)//) {
		    $line .= $1;
		}
		unshift @lines,$end;
	    }
	}
	$first=0;
	$res.="$line\n";
    }
    return $res;
}

# outputs properly a '# ... ' line to be put in the po file
sub format_comment {
  my $comment=shift;
  my $char=shift;
  my $result = "#". $char . $comment;
  $result =~ s/\n/\n#$char/gs;
  $result =~ s/^#$char$/#/gm; 
  $result .= "\n";
  return $result;
}


1;
__END__

=back

=head1 AUTHORS

 Denis Barbier <barbier@debian.org>;
 Martin Quinson <martin.quinson@tuxfamily.org>;

=cut
