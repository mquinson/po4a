#!/usr/bin/perl -w

# Po4a::Sgml.pm 
# 
# extract and translate translatable strings from a sgml based document.
# 
# This code is an adapted version of sgmlspl (SGML postprocesser for the
#   SGMLS and NSGMLS parsers) which was:
#
# Copyright (c) 1995 by David Megginson <dmeggins@aix1.uottawa.ca>
# 
# The adaptation for po4a was done by Denis Barbier <barbier@linuxfr.org>,
# Martin Quinson <martin.quinson@tuxfamily.org> and others.
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
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
########################################################################

=head1 NAME

Locale::Po4a::Sgml - Convert sgml documents from/to PO files

=head1 DESCRIPTION

The goal po4a [po for anything] project is to ease translations (and more
interestingly, the maintenance of translation) using gettext tools on areas
where they were not expected like documentation.  

Locale::Po4a::Sgml is a module to help the translation of documentation in
the SGML format into other [human] languages.

=head1 STATUS OF THIS MODULE

The result is perfect. Ie, the generated documents are exactly the
same. But there is still some problems:

=over 2

=item * 

the error output of nsgmls is redirected to /dev/null, which is clearly
bad. I dunno how to avoid that.

The problem is that I have to "protect" the conditionnal inclusion (ie, the
C<E<lt>! [ %blah [> and C<]]E<gt>> stuff) from nsgml, because in the other
case, nsgmls eat them, and I dunno how to restore them in the final
document. To prevent that, I rewrite them to C<{PO4A-beg-blah}> and
C<{PO4A-end}>. 

The problem with this is that the C<{PO4A-end}> and such I add are valid in
the document (not in a E<lt>pE<gt> tag or so).

Everything works well with nsgmls's output redirected that way, but it will
prevent us to detect that the document is badly formated.

=item *

It does work only with the debiandoc and docbook dtd. Adding support for a
new dtd should be very easy. The mecanism is the same for all dtd, you just
have to give a list of the existing tags and some of their characteristics.

I agree, this needs some more documentation, but it is still considered as
beta, and I hate to document stuff which may/will change.

=item *

Warning, support for dtds is quite experimental. I did not read any
reference manual to find the definition of all tags. I did add tag
definition to the module 'till it works for some documents I found on the
net. If your document use more tags than mine, it won't work. But as I said
above, fixing that should be quite easy.

I did test docbook against the SAG (System Administrator Guide) only, but
this document is quite big, and should use most of the docbook
specificities. 

For debiandoc, I tested some of the manual of the DDP, but not all yet.

=item * 

In case of file inclusion, string reference of messages in po files (ie,
lines like C<#: en/titletoc.sgml:9460>) will be wrong. 

This is because I preprocess the file to protect the conditional inclusion
(ie, the C<E<lt>! [ %blah [> and C<]]E<gt>> stuff) and some entities (like
&version;) from nsgmls because I want them verbatim to the generated
document. For that, I make a temp copy of the input file and do all the
changes I want to this before passing it to nsgmls for parsing.

So that it works, I replace the entities asking for a file inclusion by the
content of the given file (so that I can protect what needs to in subfile
also). But nothing is done so far to correct the references (ie, filename
and line number) afterward. I'm not sure what the best thing to do is.

=back

=cut

package Locale::Po4a::Sgml;

use 5.006;
use strict;
use warnings;


require Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Locale::Po4a::TransTractor);
@EXPORT = qw(); # new initialize);

use Locale::Po4a::TransTractor;
use Locale::gettext qw(gettext);

eval qq{use SGMLS};
if ($@) {
  die gettext("po4a::sgml: The needed module SGMLS.pm was not found and needs to be installed.\n".
      "po4a::sgml: It can be found on the CPAN, in package libsgmls-perl on debian, etc.\n");
}

use File::Temp;

my %debug=('tag' => 0, 
	   'generic' => 0,
	   'entities' => 0,
           'refs'   => 0);

my $xmlprolog = undef; # the '<?xml ... ?>' line if existing

sub read {
    my ($self,$filename)=@_;

    push @{$self->{DOCPOD}{infile}}, $filename;
    $self->Locale::Po4a::TransTractor::read($filename);
}

sub parse {
    my $self=shift;
    map {$self->parse_file($_)} @{$self->{DOCPOD}{infile}};
}

#
# Filter out some uninteresting strings for translation
#
sub translate {
    my ($self)=(shift);
    my ($string,$ref,$type)=(shift,shift,shift);
    my (%options)=@_;
 
    # don't translate entries composed of one entity
    if (($string =~ /^&[^;]*;$/) || ($options{'wrap'} && $string =~ /^\s*&[^;]*;\s*$/)){
	warn sprintf gettext ("po4a::sgml: msgid '%s' skipped since it contains only an entity (translator friendly feature ;)\n"), $string;
	return $string;
    }
    # don't translate entries composed of tags only
    if ($string =~ /^(((<[^>]*>)|\s)*)$/) {
	warn sprintf gettext ("po4a::sgml: msgid '%s' skipped since it contains only tags (translator friendly feature ;)\n"), $string;
	return $string;
    }

    return $self->SUPER::translate($string,$ref,$type,%options);
}

#
# Make sure our cruft is removed from the file
#
sub pushline {
    my ($self,$line)=@_;
    $line =~ s/{PO4A-amp}/&/g;
    $self->SUPER::pushline($line);
}

sub set_tags_kind {
    my $self=shift;
    my (%kinds)=@_;

    foreach (qw(translate empty section verbatim ignore)) {
	$self->{SGML}->{k}{$_} = "";
    }
    
    foreach (keys %kinds) {
	die "Internal error: set_tags_kind called with unrecognized arg $_"
	    if ($_ ne 'translate' && $_ ne 'empty' && $_ ne 'section' &&
		$_ ne 'verbatim'  && $_ ne 'ignore' && $_ ne 'indent');
	
	$self->{SGML}->{k}{$_}=$kinds{$_};
    }    
}


#
# Do the actual work, using the SGMLS package and settings done elsewhere.
#
sub parse_file {
    my ($self,$filename)=@_;
    my ($prolog);

    # Rewrite the file to:
    #   - protect optional inclusion marker (ie, "<![ %str [" and "]]>")
    #   - protect entities from expansion (ie "&release;")
    open (IN,"<$filename") 
	|| die sprintf(gettext("Can't open %s: %s\n"),$filename,$!);
    my $origfile="";
    while (<IN>) {
	$origfile .= $_;
    }
    close IN || die sprintf(gettext("po4a::sgml: can't close %s: %s\n"),$filename,$!);
    # Detect the XML pre-prolog
    if ($origfile =~ s/^(\s*<\?xml[^?]*\?>)//) {
	warn sprintf(gettext("po4a::sgml: %s seems to be a XML document.\n".
	    "po4a::sgml: It will be attempted to handle it as a SGML document.\n".
	    "po4a::sgml: Feel lucky if it works, help us implementing a proper XML backend if it does not.\n"),$filename);
	$xmlprolog=$1;
    }
    # Get the prolog
    {
	$prolog=$origfile;
	my $lvl;    # number of '<' seen without matching '>'
	my $pos = 0;  # where in the document (in chars) while detecting prolog boundaries
	
	unless ($prolog =~ s/^(.*<!DOCTYPE).*$/$1/is) {
	    die sprintf(gettext("po4a:sgml: %s does not seem to be a master SGML document (no DOCTYPE found).\n".
		"po4a::sgml: It may be a file to be included by another one, in which case it should not be passed to po4a directly.\n".
		"po4a::sgml: Text from included files is extracted/translated when handling the master file including them.\n"), $filename);
	}
	$pos += length($prolog);
	$lvl=1;
	while ($lvl != 0) {
	    my ($c)=substr($origfile,$pos,1);
	    $lvl++ if ($c eq '<');
	    $lvl-- if ($c eq '>');
	    $prolog = "$prolog$c";
	    $pos++;
	}
    }
    print STDERR "PROLOG=$prolog\n------------\n" if ($debug{'generic'});

    # Configure the tags for this dtd
    if ($prolog =~ /debiandoc/i) {
	$self->set_tags_kind("translate" => "author version abstract title".
			                    "date copyrightsummary heading p ".
 			                    "example tag title ",
			     "empty"     => "date ref manref url toc",
			     "section"   => "chapt appendix sect sect1 sect2 ".
			                    "sect3 sect4 debiandoc book",
			     "verbatim"  => "example",
			     "ignore"    => "package prgn file tt em var ".
					    "name email footnote ".
			                    "strong ftpsite ftppath",
			     "indent"    => "titlepag toc copyright ".
 			                    "enumlist taglist list item tag ");

    } elsif ($prolog =~ /docbook/i) {
	$self->set_tags_kind("translate" => "abbrev acronym arg artheader attribution ".
	                                    "date ".
	                                    "entry ".
	                                    "figure ".
	                                    "glosssee glossseealso glossterm ".
	                                    "holder ".
	                                    "member msgaud msglevel msgorig ".
	                                    "option orgname ".
	                                    "para phrase pubdate publishername primary ". 
	                                    "refclass refdescriptor refentrytitle refmiscinfo refname refpurpose releaseinfo remark revnumber ".
	                                    "screeninfo seg segtitle subtitle synopfragmentref ".
	                                    "term title titleabbrev",
			     "empty"     => "audiodata colspec graphic imagedata sbr textdata videodata xref",
			     "section"   => "",
			     "indent"    => "abstract answer appendix article articleinfo audioobject author authorgroup ".
	                                    "bibliodiv bibliography blockquote blockinfo book bookinfo ".
	                                    "callout calloutlist caption caution chapter cmdsynopsis copyright ".
	                                    "dedication ".
	                                    "entry ".
	                                    "formalpara ".
	                                    "glossary glossdef glossdiv glossentry glosslist group ".
	                                    "imageobject important index indexterm informaltable itemizedlist ".
	                                    "legalnotice listitem lot ".
	                                    "mediaobject msg msgentry msginfo msgexplan msgmain msgrel msgsub msgtext ".
	                                    "note ".
	                                    "objectinfo orderedlist ".
	                                    "part partintro preface procedure publisher ".
	                                    "qandadiv qandaentry qandaset question ".
	                                    "refsect1 refentry refentryinfo refmeta refnamediv refsect1 refsect1info refsect2 refsect2info refsect3 refsect3info refsection refsectioninfo refsynopsisdiv refsynopsisdivinfo revision revdescription row ".
	                                    "screenshot sect1 sect1info sect2 sect2info sect3 sect3info sect4 sect4info sect5 sect5info section sectioninfo seglistitem segmentedlist set setindex setinfo simplelist simplemsgentry simplesect step synopfragment ".
	                                    "table tbody textobject tgroup thead tip toc ".
	                                    "variablelist varlistentry videoobject ".
	                                    "warning",
			     "verbatim"  => "address programlisting literallayout screen",
			     "ignore"    => "action affiliation anchor application author authorinitials ".
	                                    "command citation citerefentry citetitle classname co computeroutput constant corpauthor ".
	                                    "database ".
	                                    "email emphasis envar errorcode errorname errortext errortype exceptionname ".
	                                    "filename firstname firstterm footnote footnoteref foreignphrase function ".
	                                    "glossterm guibutton guiicon guilabel guimenu guimenuitem guisubmenu ".
	                                    "hardware ".
	                                    "indexterm informalexample inlineequation inlinegraphic inlinemediaobject interface interfacename ".
	                                    "keycap keycode keycombo keysym ".
	                                    "link literal ".
	                                    "manvolnum markup medialabel menuchoice methodname modespec mousebutton ".
	                                    "nonterminal ".
	                                    "olink ooclass ooexception oointerface optional othercredit ".
	                                    "parameter personname phrase productname productnumber prompt property ".
	                                    "quote ".
	                                    "remark replaceable returnvalue revhistory ".
	                                    "sgmltag sidebar structfield structname subscript superscript surname symbol systemitem ".
	                                    "token trademark type ".
	                                    "ulink userinput ".
	                                    "varname ".
	                                    "wordasword ".
	                                    "xref ".
                                            "year");

    } else {
	die sprintf(gettext("File %s have an unknown DTD. (supported for now: debiandoc, docbook)\n".
	                    "The prolog follows:\n".
			    "%s\n"),
		    $filename,$prolog);
    }
    
    # Prepare the reference indirection stuff
    my @refs;
    my @lines = split(/\n/, $origfile);
    for (my $i=0; $i<scalar @lines; $i++) {
	push @refs,"$filename:$i";
    }

    # protect the conditional inclusions in the file
    $origfile =~ s/<!\[(\s*[^\[]+)\[/{PO4A-beg-$1}/g; # cond. incl. starts
    $origfile =~ s/\]\]>/{PO4A-end}/g;                # cond. incl. end
    # Protect &entities; (but the ones asking for a file inclusion)
    #   search the file inclusion entities
    my %entincl;
    my $searchprolog=$prolog;
    while ($searchprolog =~ /<!ENTITY\s(\S*)\s*SYSTEM\s*"([^>"]*)">(.*)$/is) {#})"{
	print STDERR "Seen the entity of inclusion $1 (=$2)\n"
	    if ($debug{'entities'});
	$entincl{$1}{'filename'}=$2;
	$searchprolog = $3;
    }
    #   Change the entities to their content
    foreach my $key (keys %entincl) {
	open IN,"<".$entincl{$key}{'filename'}  ||
	    die sprintf(gettext("Can't open %s: %s\n"),$entincl{$key},$!);
	local $/ = undef;
	$entincl{$key}{'content'} = <IN>;
	close IN;
	@lines= split(/\n/,$entincl{$key}{'content'});
	$entincl{$key}{'length'} = scalar @lines;
	print STDERR "read $entincl{$key}{'filename'} ($entincl{$key}{'length'} lines long)\n" 
	    if ($debug{'entities'});
    }
    #   Change the entities
    while ($origfile =~ /^(.*?)&([^;\s]*);(.*)$/s) {
	if (defined $entincl{$2}) {
	    my ($begin,$key,$end)=($1,$2,$3);
	    $end =~ s/^\s*\n//s;

	    # add the refs
	    my @refcpy;
	    my $i;
	    for ($i=0;$i<scalar @refs;$i++){
		$refcpy[$i]=$refs[$i];
	    }
	    my @begin = split(/\n/,$begin);
	    my @end = split(/\n/,$end);	    
	    for ($i=1; $i<=$entincl{$key}{'length'}; $i++) {
		$refs[$i+scalar @begin+1]="$entincl{$key}{'filename'}:$i";
	    }
	    for ($i=1; $i<=scalar @end; $i++) {
		$refs[$i+scalar @begin+1+$entincl{$key}{'length'}]=
		    $refcpy[$i+scalar @begin+2];
	    }

	    # Do the substitution
	    $origfile = "$begin".$entincl{$key}{'content'}."$end";
	    print STDERR "substitute $2\n" if ($debug{'entities'});
	} else {
	    $origfile = "$1".'{PO4A-amp}'."$2;$3";
	    print STDERR "preserve $2\n" if ($debug{'entities'});
	}
    }
    #   Reput the entities of inclusion in place
    $origfile =~ s/{PO4A-keep-amp}/&/g;
    if ($debug{'refs'}) {
	for (my $i=0; $i<scalar @refs; $i++) {
	    print STDERR "$filename:$i -> $refs[$i]\n";
	}
    }
    
    my ($tmpfh,$tmpfile)=File::Temp->tempfile("po4a-sgml-XXXX",
					      DIR    => "/tmp",
					      UNLINK => 0);
    print $tmpfh $origfile;
    close $tmpfh || die sprintf(gettext("Can't close tempfile: %s\n"),$!);

    my $cmd;
    if ($xmlprolog) {
	$cmd="cat $tmpfile|";
    } else {
	$cmd="cat $tmpfile|nsgmls -l -E 0 2>/dev/null|";
    }
    print STDERR "CMD=$cmd\n" if ($debug{'generic'});

    open (IN,$cmd) || die sprintf(gettext("Can't run nsgmls: %s\n"),$!);

    # The kind of tags
    my (%translate,%empty,%section,%verbatim,%indent,%exist);
    foreach (split(/ /, ($self->{SGML}->{k}{'translate'}||'') )) {
	$translate{uc $_} = 1;
	$indent{uc $_} = 1;
	$exist{uc $_} = 1;
    }
    foreach (split(/ /, ($self->{SGML}->{k}{'empty'}||'') )) {
	$empty{uc $_} = 1;
	$exist{uc $_} = 1;
    }
    foreach (split(/ /, ($self->{SGML}->{k}{'section'}||'') )) {
	$section{uc $_} = 1;
	$indent{uc $_} = 1;
	$exist{uc $_} = 1;
    }
    foreach (split(/ /, ($self->{SGML}->{k}{'verbatim'}||'') )) {
	$translate{uc $_} = 1;
	$verbatim{uc $_} = 1;
	$exist{uc $_} = 1;
    }
    foreach (split(/ /, ($self->{SGML}->{k}{'indent'}||'') )) {
	$translate{uc $_} = 1;
	$indent{uc $_} = 1;
	$exist{uc $_} = 1;
    }
    foreach (split(/ /, ($self->{SGML}->{k}{'ignore'}) || '')) {
	$exist{uc $_} = 1;
    }
   

    # What to do before parsing

    # push the XML prolog if existing
    $self->pushline($xmlprolog."\n") if ($xmlprolog);

    # Put the prolog into the file, allowing for entity definition translation
    #  <!ENTITY myentity "definition_of_my_entity">
    # and push("<!ENTITY myentity \"".$self->translate("definition_of_my_entity")
    if ($prolog =~ m/(.*?\[)(.*)(\]>)/s) {
        $self->pushline($1);
        $prolog=$2;					       
        my ($post) = $3;			
        while ($prolog =~ m/^(.*?)<!ENTITY\s(\S*)\s*"([^>"]*)">(.*)$/is) { #" ){ 
	   $self->pushline($1);
	   $self->pushline("<!ENTITY $2 \"".$self->translate($3,"","definition of entity \&$2;")."\">");
	   warn "Seen text entity $2" if ($debug{'entities'});
	   $prolog = $4;
	}
        $self->pushline($post);
    } else {
	warn "No entity declaration detected in ~~$prolog~~...\n" if ($debug{'entities'});
    } 
    $self->pushline($prolog);

    # The parse object.
    # Damn SGMLS. It makes me crude things.
    no strict "subs";
    my $parse= new SGMLS(IN);
    use strict;

    # Some values for the parsing
    my @open=(); # opened translation container tags
    my $verb=0;  # can we wrap or not
    my $seenfootnote=0;
    my $indent=0; # indent level
    my $lastchar = ''; # 
    my $buffer= ""; # what we will soon handle

    # run the appropriate handler for each event
    EVENT: while (my $event = $parse->next_event) {
	# to build po entries
	my $ref=$refs[$parse->line];
	my $type;
	
	if ($event->type eq 'start_element') {
	    die sprintf(gettext("po4a::Sgml: %s: Unknown tag %s\n"),
			$refs[$parse->line],$event->data->name) 
		unless $exist{$event->data->name};
	    
	    $lastchar = ">";

	    # Which tag did we see?
	    my $tag='';
	    $tag .= '<'.lc($event->data->name());
	    while (my ($attr, $val) = each %{$event->data->attributes()}) {
		my $value = $val->value();
#		if ($val->type() eq 'IMPLIED') {
#		    $tag .= ' '.lc($attr).'="'.lc($attr).'"';
#		} els
                if ($val->type() eq 'CDATA' ||
		    $val->type() eq 'IMPLIED') {
		    if (defined $value && length($value)) {
			if ($value =~ m/"/) { #"
			    $value = "'".$value."'";
			} else {
			    $value = '"'.$value.'"';
			}
			$tag .= ' '.lc($attr).'='.$value;
		    }
		} elsif ($val->type() eq 'NOTATION') {
		} else {
		    $tag .= ' '.lc($attr).'="'.lc($value).'"'
			if (defined $value && length($value));
		}
	    }
	    $tag .= '>';


	    # debug
	    print STDERR "Seen $tag, open level=".(scalar @open)."\n"
		if ($debug{'tag'});

	    if ($event->data->name() eq 'FOOTNOTE') {
		# we want to put the <para> inside the <footnote> in the same msgid
		$seenfootnote = 1;
	    }
	    
	    if ($seenfootnote) {
		$buffer .= $tag;
		next EVENT;
	    } 
	    if ($translate{$event->data->name()}) {
		# Build the type
		if (scalar @open > 0) {
		    $type=$open[$#open] . $tag;
		} else {
		    $type=$tag;
		}

		# do the job
		if (@open > 0) {
		    $self->end_paragraph($buffer,$ref,$type,$verb,$indent,
					 @open);
		} else {
		    $self->pushline($buffer);
		}
		$buffer="";
		push @open,$tag;
	    } elsif ($section{$event->data->name()}) {
		die sprintf(gettext(
           "Closing tag for a translation container missing before %s, at %s\n"
				    ),$tag,$ref)
		    if (scalar @open);
	    }

	    if ($indent{$event->data->name()}) {
		$self->pushline((" " x $indent).$tag."\n");
		$indent ++ unless $empty{$event->data->name()} ;
	    }  else {
		$buffer .= $tag;
	    }
	    $verb++ if $verbatim{$event->data->name()};
	} # end of type eq 'start_element'
	
	elsif ($event->type eq 'end_element') {
	    my $tag = ($empty{$event->data->name()} 
		           ? 
		       '' 
		           : 
		       '</'.lc($event->data->name()).'>');

	    print STDERR "Seen $tag, level=".(scalar @open)."\n"
		if ($debug{'tag'});

	    $lastchar = ">";
	    
	    if ($event->data->name() eq 'FOOTNOTE') {
		# we want to put the <para> inside the <footnote> in the same msgid
		$seenfootnote = 0;
	    }
	    
	    if ($seenfootnote) {
		$buffer .= $tag;
		next EVENT;
	    } 
	    if ($translate{$event->data->name()}) {
		$type = $open[$#open] . $tag;
		$self->end_paragraph($buffer,$ref,$type,$verb,$indent,
				     @open);
		$buffer = "";
		pop @open;
		if (@open > 0) {
		    pop @open;
		    push @open,$tag;
		}
	    } elsif ($section{$event->data->name()}) {
		die sprintf(gettext(
           "Closing tag for a translation container missing before %s, at %s\n"
				    ),$tag,$ref)
		    if (scalar @open);
	    }

	    if ($indent{$event->data->name()}) {
		$indent -- ;
		$self->pushline((" " x $indent).$tag."\n");
	    }  else {
		$buffer .= $tag;
	    }	    
	    $verb-- if $verbatim{$event->data->name()};
	} # end of type eq 'end_element'
	
	elsif ($event->type eq 'cdata') {
	    my $cdata = $event->data;
	    if ($cdata =~ /^(({PO4A-(beg|end)[^\}]*})|\s)+$/ &&
		$cdata =~ /\S/) {
		$cdata =~ s/\s*{PO4A-end}/\]\]>\n/g;
		$cdata =~ s/\s*{PO4A-beg-([^\}]+)}/<!\[$1\[\n/g;
		$self->pushline($cdata);
	    } else {
		if (!$verb) {
		    $cdata =~ s/\\t/ /g;
		    $cdata =~ s/\s+/ /g;
		    $cdata =~ s/^\s//s if $lastchar eq ' ';
		}
		$lastchar = substr($cdata, -1, 1);
		$buffer .= $cdata;
	    }
	} # end of type eq 'cdata'

	elsif ($event->type eq 'sdata') {
	    my $sdata = $event->data;
	    $sdata =~ s/^\[//;
	    $sdata =~ s/\s*\]$//;
	    $lastchar = substr($sdata, -1, 1);
	    $buffer .= '&'.$sdata.';';
	} # end of type eq 'sdata'

	elsif ($event->type eq 're') {
	    if ($verb) {
		$buffer .= "\n";
	    } elsif ($lastchar ne ' ') {
		$buffer .= " ";
	    }
	    $lastchar = ' ';
	} #end of type eq 're'

	elsif ($event->type eq 'conforming') {
	    
	}

	else {
	    die sprintf(gettext("%s:%d: Unknown SGML event type: %s\n"),
			$refs[$parse->line],$event->type);
	    
	}
    }
				
    # What to do after parsing
    $self->pushline($buffer);
    close(IN);
    unlink ($tmpfile);
}

sub end_paragraph {
    my ($self, $para,$ref, $type,$verb,$indent)=
	(shift,shift,shift,shift,shift,shift);
    my (@open)=@_;
    die "Internal error: no paragraph to end here!!" 
	unless scalar @open;
		
    return unless defined($para) && length($para);

    # unprotect &entities;
    $para =~ s/{PO4A-amp}/&/g;
    # remove the name"\|\|" nsgmls added as attributes
    $para =~ s/ name=\"\\\|\\\|\"//g;    
    $para =~ s/ moreinfo=\"none\"//g;

    $para = $self->translate($para,$ref,$type,
			     'wrap' => ! $verb,
			     'wrapcol' => (75 - $indent));
    $para =~ s/^\n//s;
    unless ($verb) {
	my $toadd=" " x ($indent+1);
	$para =~ s/^/$toadd/mg;
    }

    $self->pushline( $para );
}

1;
=head1 AUTHORS

This module is an adapted version of sgmlspl (SGML postprocesser for the
SGMLS and NSGMLS parsers) which was:

 Copyright (c) 1995 by David Megginson <dmeggins@aix1.uottawa.ca>
 
The adaptation for po4a was done by:

 Denis Barbier <barbier@linuxfr.org>
 Martin Quinson <martin.quinson@tuxfamily.org>

=head1 COPYRIGHT AND LICENSE

 Copyright (c) 1995 by David Megginson <dmeggins@aix1.uottawa.ca>
 Copyright 2002 by SPI, inc.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see COPYING file).
