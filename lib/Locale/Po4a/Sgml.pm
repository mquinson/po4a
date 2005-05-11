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
# Martin Quinson (mquinson#debian.org) and others.
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

The po4a (po for anything) project goal is to ease translations (and more
interestingly, the maintenance of translations) using gettext tools on
areas where they were not expected like documentation.

Locale::Po4a::Sgml is a module to help the translation of documentation in
the SGML format into other [human] languages.

=head1 OPTIONS ACCEPTED BY THIS MODULE

=over 4

=item debug

Space separated list of keywords indicating which part you want to debug. Possible values are: tag, generic, entities and refs.

=item verbose

Give more information about what's going on.

=item translate

Space separated list of extra tags (beside the dtd provided ones) whose
content should form an extra msgid.

=item section

Space separated list of extra tags (beside the dtd provided ones)
containing other tags, some of them being of category 'translate'.

=item indent

=item verbatim

The layout within those tags should not be changed. The paragraph won't get
wrapped, and no extra indentation space or new line will be added for
cosmetic purpose.

=item empty

Tags not needing to be closed.

=item ignore

Tags ignored and considered as plain char data by po4a. That is to say that
they can be part of a msgid. For example, E<lt>bE<gt> is a good candidate
for this category since putting it in the translate section would create
msgids not being whole sentences, which is bad.

=item force

Proceed even if the DTD is unknown.

=item include-all

By default, msgids containing only one entity (like '&version;') are skipped
for the translator comfort. Activating this option prevents this
optimisation. It can be useful if the document contains a construction like
"<title>&Aacute;</title>", even if I doubt such things to ever happen...

=back

=head1 STATUS OF THIS MODULE

The result is perfect. Ie, the generated documents are exactly the
same. But there is still some problems:

=over 2

=item * 

the error output of nsgmls is redirected to /dev/null, which is clearly
bad. I don't know how to avoid that.

The problem is that I have to "protect" the conditional inclusions (ie, the
C<E<lt>! [ %foo [> and C<]]E<gt>> stuff) from nsgmls. Otherwise
nsgmls eats them, and I don't know how to restore them in the final
document. To prevent that, I rewrite them to C<{PO4A-beg-foo}> and
C<{PO4A-end}>. 

The problem with this is that the C<{PO4A-end}> and such I add are valid in
the document (not in a E<lt>pE<gt> tag or so).

Everything works well with nsgmls's output redirected that way, but it will
prevent us to detect that the document is badly formatted.

=item *

It does work only with the debiandoc and docbook dtd. Adding support for a
new dtd should be very easy. The mechanism is the same for every dtd, you just
have to give a list of the existing tags and some of their characteristics.

I agree, this needs some more documentation, but it is still considered as
beta, and I hate to document stuff which may/will change.

=item *

Warning, support for dtds is quite experimental. I did not read any
reference manual to find the definition of every tag. I did add tag
definition to the module 'till it works for some documents I found on the
net. If your document use more tags than mine, it won't work. But as I said
above, fixing that should be quite easy.

I did test docbook against the SAG (System Administrator Guide) only, but
this document is quite big, and should use most of the docbook
specificities. 

For debiandoc, I tested some of the manuals from the DDP, but not all yet.

=item * 

In case of file inclusion, string reference of messages in po files (ie,
lines like C<#: en/titletoc.sgml:9460>) will be wrong. 

This is because I preprocess the file to protect the conditional inclusion
(ie, the C<E<lt>! [ %foo [> and C<]]E<gt>> stuff) and some entities (like
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
@EXPORT = qw();

use Locale::Po4a::TransTractor;
use Locale::Po4a::Common;
use Locale::gettext qw(dgettext);

eval qq{use SGMLS};
if ($@) {
  die wrap_mod("po4a::sgml", dgettext("po4a","The needed module SGMLS.pm was not found and needs to be installed. It can be found on the CPAN, in package libsgmls-perl on debian, etc."));
}

use File::Temp;

my %debug=('tag' => 0, 
	   'generic' => 0,
	   'entities' => 0,
           'refs'   => 0);

my $xmlprolog = undef; # the '<?xml ... ?>' line if existing

sub initialize {
    my $self = shift;
    my %options = @_;
    
    $self->{options}{'translate'}='';
    $self->{options}{'section'}='';
    $self->{options}{'indent'}='';
    $self->{options}{'empty'}='';
    $self->{options}{'verbatim'}='';
    $self->{options}{'ignore'}='';

    $self->{options}{'include-all'}='';

    $self->{options}{'force'}='';

    $self->{options}{'verbose'}='';
    $self->{options}{'debug'}='';
    
    foreach my $opt (keys %options) {
	if ($options{$opt}) {
	    die wrap_mod("po4a::sgml", dgettext ("po4a", "Unknown option: %s"), $opt) unless exists $self->{options}{$opt};
	    $self->{options}{$opt} = $options{$opt};
	}
    }
    if ($options{'debug'}) {
	foreach ($options{'debug'}) {
	    $debug{$_} = 1;
	}
    }
}

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
    if ( (($string =~ /^&[^;]*;$/) || ($options{'wrap'} && $string =~ /^\s*&[^;]*;\s*$/))
	 && !($self->{options}{'include-all'}) ){
	warn wrap_mod("po4a::sgml", dgettext("po4a", "msgid skipped to help translators (contains only an entity)"), $string)
	    unless $self->verbose() <= 0;
	return $string;
    }
    # don't translate entries composed of tags only
    if ( $string =~ /^(((<[^>]*>)|\s)*)$/
	 && !($self->{options}{'include-all'}) ) {
	warn wrap_mod("po4a::sgml", dgettext("po4a", "msgid skipped to help translators (contains only tags)"), $string)
	       unless $self->verbose() <= 0;
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
	$self->{SGML}->{k}{$_} = $self->{options}{$_} ? $self->{options}{$_}.' ' : '';
    }
    
    foreach (keys %kinds) {
	die "po4a::sgml: internal error: set_tags_kind called with unrecognized arg $_"
	    if ($_ ne 'translate' && $_ ne 'empty' && $_ ne 'verbatim'  && $_ ne 'ignore' && $_ ne 'indent');
	
	$self->{SGML}->{k}{$_} .= $kinds{$_};
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
	|| die wrap_mod("po4a::sgml", dgettext("po4a", "Can't open %s: %s"), $filename, $!);
    my $origfile="";
    while (<IN>) {
	$origfile .= $_;
    }
    close IN || die wrap_mod("po4a::sgml", dgettext("po4a", "Can't close %s: %s"), $filename, $!);
    # Detect the XML pre-prolog
    if ($origfile =~ s/^(\s*<\?xml[^?]*\?>)//) {
	warn wrap_mod("po4a::sgml", dgettext("po4a",
		"Trying to handle a XML document as a SGML one. ".
		"Feel lucky if it works, help us implementing a proper XML backend if it does not."), $filename)
	  unless $self->verbose() <= 0;
	$xmlprolog=$1;
    }
    # Get the prolog
    {
	$prolog=$origfile;
	my $lvl;    # number of '<' seen without matching '>'
	my $pos = 0;  # where in the document (in chars) while detecting prolog boundaries
	
	unless ($prolog =~ s/^(.*<!DOCTYPE).*$/$1/is) {
	    die wrap_mod("po4a::sgml", dgettext("po4a",
	    	"This file is not a master SGML document (no DOCTYPE). ".
		"It may be a file to be included by another one, in which case it should not be passed to po4a directly. Text from included files is extracted/translated when handling the master file including them."));
	}
	$pos += length($prolog);
	$lvl=1;
	while ($lvl != 0) {
	    # Eat comments in the prolog, since it may be some '>' or '<' in them.
	    if ($origfile =~ m/^.{$pos}?(<!--.*?-->)/s) {
		print "Found a comment in the prolog: $1\n" if ($debug{'generic'});
		$pos += length($1);
		# take care of the line numbers
		my @a = split(/\n/,$1);
		shift @a; # nb line - 1
		while (defined(shift @a)) {
		    $prolog .= "\n";
		}
		next;
	    }
	    # Search the closing '>'
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
			                    "example tag title contrib ".
			                    "epigraph",
			     "empty"     => "date ref manref url toc",
			     "verbatim"  => "example",
			     "ignore"    => "package prgn file tt em var ".
					    "name email footnote ".
			                    "strong ftpsite ftppath",
			     "indent"    => "appendix ".
	                                    "book ".
	                                    "chapt copyright ".
			                    "debiandoc ".
			                    "enumlist ".
			                    "item ".
			                    "list ".
	                                    "sect sect1 sect2 sect3 sect4 ".
			                    "tag taglist titlepag toc");

    } elsif ($prolog =~ /docbook/i) {
	$self->set_tags_kind("translate" => "abbrev acronym arg artheader attribution ".
	                                    "date ".
	                                    "editor entry ".
	                                    "figure ".
	                                    "glosssee glossseealso glossterm ".
	                                    "holder ".
	                                    "member msgaud msglevel msgorig ".
	                                    "option orgname othername ".
	                                    "para phrase pubdate publishername primary ". 
	                                    "refclass refdescriptor refentrytitle refmiscinfo refname refpurpose releaseinfo remark revnumber revremark ".
	                                    "screeninfo seg secondary segtitle simpara subtitle synopfragmentref synopsis ".
	                                    "term tertiary title titleabbrev",
			     "empty"     => "audiodata colspec graphic imagedata textdata sbr videodata xref",
			     "indent"    => "abstract answer appendix article articleinfo audioobject author authorgroup ".
	                                    "bibliodiv bibliography blockquote blockinfo book bookinfo bridgehead ".
	                                    "callout calloutlist caption caution chapter cmdsynopsis copyright ".
	                                    "dedication ".
	                                    "entry ".
	                                    "formalpara ".
	                                    "glossary glossdef glossdiv glossentry glosslist group ".
	                                    "imageobject important index indexterm informaltable itemizedlist ".
	                                    "keyword keywordset ".
	                                    "legalnotice listitem lot ".
	                                    "mediaobject msg msgentry msginfo msgexplan msgmain msgrel msgsub msgtext ".
	                                    "note ".
	                                    "objectinfo orderedlist ".
	                                    "part partintro preface procedure publisher ".
	                                    "qandadiv qandaentry qandaset question ".
	                                    "reference refsect1 refentry refentryinfo refmeta refnamediv refsect1 refsect1info refsect2 refsect2info refsect3 refsect3info refsection refsectioninfo refsynopsisdiv refsynopsisdivinfo revision revdescription row ".
	                                    "screenshot sect1 sect1info sect2 sect2info sect3 sect3info sect4 sect4info sect5 sect5info section sectioninfo seglistitem segmentedlist set setindex setinfo shortcut simplelist simplemsgentry simplesect step synopfragment ".
	                                    "table tbody textobject tgroup thead tip toc ".
	                                    "variablelist varlistentry videoobject ".
	                                    "warning",
			     "verbatim"  => "address holder literallayout option programlisting ".
	                                    "refentrytitle refname refpurpose screen title",
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
	if ($self->{options}{'force'}) {
	    warn wrap_mod("po4a::sgml", dgettext("po4a", "DTD of this file is unknown, but proceeding as requested."));
	    $self->set_tags_kind();
	} else {
	    die wrap_mod("po4a::sgml", dgettext("po4a",
		"DTD of this file is unknown. (supported: debiandoc, docbook). The prolog follows:")."\n$prolog");
	}
    }

    # Prepare the reference indirection stuff
    my @refs;
    my @lines = split(/\n/, $origfile);
    print "XX Prepare reference indirection stuff\n" if $debug{'refs'};
    for (my $i=1; $i<=scalar @lines; $i++) {
	push @refs,"$filename:$i";
	print "$filename:$i\n" if $debug{'refs'};
    }

    # protect the conditional inclusions in the file
    $origfile =~ s/<!\[(\s*[^\[]+)\[/{PO4A-beg-$1}/g; # cond. incl. starts
    $origfile =~ s/\]\]>/{PO4A-end}/g;                # cond. incl. end

    my $tmp1 = $origfile;
    $origfile = "";
    while ($tmp1 =~ m/^(.*?{PO4A-beg-[^}]*})(.+?)({PO4A-end}.*)$/s) {
        my ($begin, $tmp) = ($1, $2);
        $tmp1 = $3;
        $tmp =~ s/</{PO4A-lt}/gs;
        $tmp =~ s/>/{PO4A-gt}/gs;
        $tmp =~ s/&/{PO4A-amp}/gs;
        $origfile .= $begin.$tmp;
    }
    $origfile .= $tmp1;

    # Deal with the %entities; in the prolog. God damn it, this code is gross!
    # Try hard not to change the number of lines to not fuck up the references
    my %prologentincl;
    my $moretodo=1;
    while ($moretodo) { # non trivial loop to deal with recursiv inclusion
	$moretodo = 0;
	# Unprotect not yet defined inclusions
	$prolog =~ s/{PO4A-percent}/%/sg;
	while ($prolog =~ /(.*?)<!ENTITY\s*%\s*(\S*)\s*SYSTEM\s*"([^>"]*)">(.*)$/is) {  #})"{ (Stupid editor)
	    print STDERR "Seen the definition entity of prolog inclusion $2 (=$3)\n"
	      if ($debug{'entities'});
	    # Preload the content of the entity.
	    my $key = $2;
	    my $filename=$3;
	    $prolog = $1.$4;
	    (-e $filename && open IN,"<$filename")  ||
	      die wrap_mod("po4a::sgml", dgettext("po4a", "Can't open %s (content of entity %s%s;): %s"),
		  $filename, '%', $key, $!);
	    local $/ = undef;
	    $prologentincl{$key} = <IN>;
	    close IN;
	    my @lines = split(/\n/,$prologentincl{$key});
	    print STDERR "Content of \%$key; is $filename (".(scalar @lines)." lines long)\n"
	      if ($debug{'entities'});
	    # leave those damn references in peace by making sure it fits on one line
	    $prologentincl{$key} = join (" ", @lines);
	    print STDERR "content: ".$prologentincl{$key}."\n"
	      if ($debug{'entities'});
	    $moretodo = 1;
	}
        print STDERR "prolog=>>>>$prolog<<<<\n"
	      if ($debug{'entities'});
        while ($prolog =~ /^(.*?)%([^;\s]*);(.*)$/s) {
	    my ($pre,$ent,$post) = ($1,$2,$3);
	    # Yeah, right, the content of the entity can be defined in a not yet loaded entity
	    # It's easy to build a weird case where all that shit colapse poorly. But why the
	    # hell are you using those strange constructs in your document, damn it?
	    print STDERR "Seen prolog inclusion $ent\n" if ($debug{'entities'});
	    if (defined ($prologentincl{$ent})) {
		$prolog = $pre.$prologentincl{$ent}.$post;
		print STDERR "Change \%$ent; to its content in the prolog\n"
		  if $debug{'entities'};
		$moretodo = 1;
	    } else {
		# AAAARGH stupid document using %bla; and having then defined in another inclusion!
		# Protect it for this pass, and unprotect it on next one
		print STDERR "entity $ent not defined yet ?!\n"
		  if $debug{'entities'};
		$prolog = "$pre".'{PO4A-percent}'."$ent;$post";
	    }
	}
    }
    # Unprotect undefined inclusions, and die of them
    $prolog =~ s/{PO4A-percent}/%/sg;
    if ($prolog =~ /%([^;\s]*);/) {
       die wrap_mod("po4a::sgml", dgettext("po4a","unrecognized prolog inclusion entity: %%%s;"), $1);
    }
    # Protect &entities; (all but the ones asking for a file inclusion)
    #   search the file inclusion entities
    my %entincl;
    my $searchprolog=$prolog;
    while ($searchprolog =~ /(.*?)<!ENTITY\s(\S*)\s*SYSTEM\s*"([^>"]*)">(.*)$/is) {  #})"{
	print STDERR "Seen the entity of inclusion $2 (=$3)\n"
	  if ($debug{'entities'});
	my $key = $2;
	my $filename = $3;
	$searchprolog = $1.$4;
	$entincl{$key}{'filename'}=$filename;
	# Preload the content of the entity
	(-e $filename && open IN,"<$filename")  ||
	  die wrap_mod("po4a::sgml", dgettext("po4a", "Can't open %s (content of entity %s%s;): %s"),
	      $filename, '&', $key, $!);
	local $/ = undef;
	$entincl{$key}{'content'} = <IN>;
	close IN;
	@lines= split(/\n/,$entincl{$key}{'content'});
	$entincl{$key}{'length'} = scalar @lines;
	print STDERR "read $filename (content of \&$key;, $entincl{$key}{'length'} lines long)\n" 
	  if ($debug{'entities'});
    }

    #   Change the entities including files in the document
    while ($origfile =~ /^(.*?)&([A-Za-z_:][-_:.A-Za-z0-9]*);(.*)$/s) {
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
	    my ($pre,$len,$post) = (scalar @begin,$entincl{$key}{'length'},scalar @end);
	    # make sure pre and content have a line in common. It will be the case if the entity is
	    # indented ($begin contains the indenting spaces), but not if the entity is on the first
	    # column
	    $pre++ if ($begin =~ /\n$/s);
	    # same for post
	    $len++ if ($end =~ /^\n/s);
	    
	    print "XX Add a ref. pre=$pre; len=$len; post=$post\n" if $debug{'refs'};
	    my $main = $refs[$pre-1]; # Keep a reference of inclusion position in main file
	    for ($i=-1; $i<$len-1; $i++) {
		$refs[$i+$pre] = "$main $entincl{$key}{'filename'}:".($i+2);
	    }
	    for ($i=0; $i<$post; $i++) {
		    $refs[$pre+$i+$len-1] = # -1 since pre and len have a line in common
		  $refcpy[$pre+$i];
	    }

	    # Do the substitution
	    $origfile = "$begin".$entincl{$key}{'content'}."$end";
	    print STDERR "substitute $2\n" if ($debug{'entities'});
	} else {
	    $origfile = "$1".'{PO4A-amp}'."$2;$3";
	    print STDERR "preserve $2\n" if ($debug{'entities'});
	}
    }

    if ($debug{'refs'}) {
	print "XX Resulting shifts\n";
	for (my $i=0; $i<scalar @refs; $i++) {
	    print "$filename:".($i+1)." -> $refs[$i]\n";
	}
    }
    
    my ($tmpfh,$tmpfile)=File::Temp->tempfile("po4asgml-XXXX",
					      DIR    => "/tmp",
					      UNLINK => 0);
    print $tmpfh $origfile;
    close $tmpfh || die wrap_mod("po4a::sgml", dgettext("po4a", "Can't close tempfile: %s"), $!);

    my $cmd="cat $tmpfile|nsgmls -l -E 0 2>/dev/null|";
    print STDERR "CMD=$cmd\n" if ($debug{'generic'});

    open (IN,$cmd) || die wrap_mod("po4a::sgml", dgettext("po4a", "Can't run nsgmls: %s"), $!);

    # The kind of tags
    my (%translate,%empty,%verbatim,%indent,%exist);
    foreach (split(/ /, ($self->{SGML}->{k}{'translate'}||'') )) {
	$translate{uc $_} = 1;
	$indent{uc $_} = 1;
	$exist{uc $_} = 1;
    }
    foreach (split(/ /, ($self->{SGML}->{k}{'empty'}||'') )) {
	$empty{uc $_} = 1;
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
    $self->pushline($xmlprolog."\n") if (defined($xmlprolog) && length($xmlprolog));

    # Put the prolog into the file, allowing for entity definition translation
    #  <!ENTITY myentity "definition_of_my_entity">
    # and push("<!ENTITY myentity \"".$self->translate("definition_of_my_entity")
    if ($prolog =~ m/(.*?\[)(.*)(\]>)/s) {
	warn "Pre=~~$1~~;Post=~~$3~~\n" if ($debug{'entities'});
        $self->pushline($1."\n") if (length($1));
        $prolog=$2;					       
        my ($post) = $3;			
        while ($prolog =~ m/^(.*?)<!ENTITY\s+(\S*)\s+"([^"]*)">(.*)$/is) { #" ){ 
	   $self->pushline($1) if length($1);
	   $self->pushline("<!ENTITY $2 \"".$self->translate($3,"","definition of entity \&$2;")."\">");
	   warn "Seen text entity $2\n" if ($debug{'entities'});
	   $prolog = $4;
	}
        $self->pushline($post."\n") if (length($post));
    } else {
	warn "No entity declaration detected in ~~$prolog~~...\n" if ($debug{'entities'});
	$self->pushline($prolog) if length($prolog);
    } 

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
	    die wrap_ref_mod($ref, "po4a::sgml", dgettext("po4a", "Unknown tag %s"),
			$event->data->name)
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
	    print STDERR "Seen $tag, open level=".(scalar @open).", verb=$verb\n"
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
		    $self->pushline($buffer) if $buffer;
		}
		$buffer="";
		push @open,$tag;
	    } elsif ($indent{$event->data->name()}) {
		die wrap_ref_mod($ref, "po4a::sgml", dgettext("po4a",
		    "Closing tag for a translation container missing before %s"),$tag)
		    if (scalar @open);
	    }

	    $verb++ if $verbatim{$event->data->name()};
	    if ($indent{$event->data->name()}) {
		# push the indenting space only if not in verb before that tag
		# push tailing "\n" only if not in verbose afterward
		$self->pushline( ($verb>1?"": (" " x $indent)).$tag.($verb?"":"\n"));
		$indent ++ unless $empty{$event->data->name()} ;
	    }  else {
		$buffer .= $tag;
	    }
	} # end of type eq 'start_element'
	
	elsif ($event->type eq 'end_element') {
	    my $tag = ($empty{$event->data->name()} 
		           ? 
		       '' 
		           : 
		       '</'.lc($event->data->name()).'>');

	    print STDERR "Seen $tag, level=".(scalar @open).", verb=$verb\n"
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
	    } elsif ($indent{$event->data->name()}) {
		die wrap_ref_mod($ref, "po4a::sgml", dgettext("po4a",
           "Closing tag for a translation container missing before %s"), $tag)
		    if (scalar @open);
	    }

	    if ($indent{$event->data->name()}) {
		$indent -- ;
		# add indenting space only when not in verbatim
		# add the tailing \n only if out of verbatim after that tag
		$self->pushline(($verb?"":(" " x $indent)).$tag.($verb>1?"":"\n"));
	    }  else {
		$buffer .= $tag;
	    }	    
	    $verb-- if $verbatim{$event->data->name()};
	} # end of type eq 'end_element'
	
	elsif ($event->type eq 'cdata') {
	    my $cdata = $event->data;
	    $cdata =~ s/{PO4A-lt}/</g;
	    $cdata =~ s/{PO4A-gt}/>/g;
	    $cdata =~ s/{PO4A-amp}/&/g;
	    if ($cdata =~ /^(({PO4A-(beg|end)[^\}]*})|\s)+$/ &&
		$cdata =~ /\S/) {
		$cdata =~ s/\s*{PO4A-end}/\]\]>\n/g;
		$cdata =~ s/\s*{PO4A-beg-([^\}]+)}/<!\[$1\[\n/g;
	    } else {
		if (!$verb) {
		    $cdata =~ s/\\t/ /g;
		    $cdata =~ s/\s+/ /g;
		    $cdata =~ s/^\s//s if $lastchar eq ' ';
		}
	    }
	    $lastchar = substr($cdata, -1, 1);
	    $buffer .= $cdata;
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
	    die wrap_ref_mod($refs[$parse->line], "po4a::sgml", dgettext("po4a","Unknown SGML event type: %s"), $event->type);

	}
    }
				
    # What to do after parsing
    $self->pushline($buffer);
    close(IN);
    unlink ($tmpfile) unless $debug{'refs'};
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
 Martin Quinson (mquinson#debian.org)

=head1 COPYRIGHT AND LICENSE

 Copyright (c) 1995 by David Megginson <dmeggins@aix1.uottawa.ca>
 Copyright 2002, 2003, 2004, 2005 by SPI, inc.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see the COPYING file).
