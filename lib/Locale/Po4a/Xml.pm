#!/usr/bin/perl

# Po4a::Xml.pm 
# 
# extract and translate translatable strings from XML documents.
# 
# This code extracts plain text from tags and attributes from generic
# XML documents, and it can be used as a base to build modules for
# XML-based documents.
#
# Copyright (c) 2004 by Jordi Vilalta  <jvprat@wanadoo.es>
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

Locale::Po4a::Xml - Convert XML documents and derivates from/to PO files

=head1 DESCRIPTION

The goal po4a [po for anything] project is to ease translations (and more
interestingly, the maintenance of translation) using gettext tools on areas
where they were not expected like documentation. 

Locale::Po4a::Xml is a module to help the translation of XML documents into
other [human] languages. It can also be used as a base to build modules for
XML-based documents.

=cut

package Locale::Po4a::Xml;

use 5.006;
use strict;
use warnings;

require Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Locale::Po4a::TransTractor);
@EXPORT = qw(new initialize);

use Locale::Po4a::TransTractor;
use Locale::gettext qw(gettext);
#is there any better (or more standard) package than this to recode strings?
#use Locale::Recode;

#It will mantain the path from the root tag to the current one
my @structure;

sub read {
	my ($self,$filename)=@_;
	push @{$self->{DOCPOD}{infile}}, $filename;
	$self->Locale::Po4a::TransTractor::read($filename);
}

sub parse {
	my $self=shift;
	map {$self->parse_file($_)} @{$self->{DOCPOD}{infile}};
}

=head1 TRANSLATING WITH PO4A::XML

This module can be used directly to handle generic XML documents.  This will
extract all tag's contents, and no attributes, since it's where the text is
written in most XML based documents.

There are some options (described in the next section) that can customize
this behavior.  If this doesn't fit to your document format you're encouraged
to write your own module derived from this, to describe your format's details.
See the section "Writing derivate modules" below, for the process description.

=cut

#
# Parse file and translate it
#
sub parse_file {
	my ($self,$filename) = @_;
	my $eof = 0;

	while (!$eof) {
		# We get all the text until the next breaking tag (not
		# inline) and translate it
		$eof = $self->treat_content;
		if (!$eof) {
			# And then we treat the following breaking tag
			$eof = $self->treat_tag;
		}
	}
}

=head1 OPTIONS ACCEPTED BY THIS MODULE

=over 4

=item strip

Makes it strip the spaces around the extracted strings. (Typical)

=item wrap

Canonizes the string to translate, considering that whitespaces are not
important, and wraps the translated document.

=item caseinsensitive (TODO)

It makes the tags and attributes searching to work in a case insensitive
way.  If it's defined, it will treat <BooK>laNG and <BOOK>Lang as <book>lang.

=item tagsonly

Extracts only the specified tags in the "translate" option.  Otherwise, it
will extract all the tags except the ones specified.

=item doctype

String that will try to match with the first line of the document's doctype
(if defined). If it doesn't, the document will be considered of a bad type.

=item tags

Space-separated list of the tags you want to translate or skip.  By default,
the specified tags will be excluded, but if you use the "tagsonly" option,
the specified tags will be the only ones included.  The tags must be in the
form <aaa>, but you can join some (<bbb><aaa>) to say that the contents of
the tag <aaa> will only be translated when it's into a <bbb> tag.

=item attributes (TODO)

Space-separated list of the tag's attributes you want to translate.  You can
specify the attributes by their name (for example, "lang"), but you can
prefix it with a tag hierarchy, to specify that this tag will only be
translated when it's into the specified tag. For example: <bbb><aaa>lang
specifies that the lang attribute will only be translated if it's into an
<aaa> tag, and it's into a <bbb> tag.

=item inline

Space-separated list of the tags you want to treat as inline.  By default,
all tags break the sequence.  This follows the same syntax as the tags option.

=cut

sub initialize {
	my $self = shift;
	my %options = @_;

	$self->{options}{'strip'}=0;
	$self->{options}{'wrap'}=0;
	$self->{options}{'caseinsensitive'}=0;
	$self->{options}{'tagsonly'}=0;
	$self->{options}{'tags'}='';
	$self->{options}{'attributes'}='';
	$self->{options}{'inline'}='';
	$self->{options}{'doctype'}='';

	$self->{options}{'verbose'}='';
	$self->{options}{'debug'}='';

	foreach my $opt (keys %options) {
		if ($options{$opt}) {
			die sprintf(gettext ("po4a::xml: Unknown option: %s"), $opt)."\n" unless exists $self->{options}{$opt};
			$self->{options}{$opt} = $options{$opt};
		}
	}

	#It will mantain the list of the translateable tags
	$self->{tags}=();
	#It will mantain the list of the inline tags
	$self->{inline}=();

	$self->treat_options;
}

=head1 WRITING DERIVATE MODULES

=head2 DEFINE WHAT TAGS AND ATTRIBUTES TO TRANSLATE

The simplest customization is to define which tags and attributes you want
the parser to translate.  This should be done in the initialize function.
First you should call the main initialize, to get the command-line options,
and then, append your custom definitions to the options hash.  If you want
to treat some new options from command line, you should define them before
calling the main initialize:

  $self->{options}{'new_option'}='';
  $self->SUPER::initialize(%options);
  $self->{options}{'tags'}.=' <p> <head><title>';
  $self->{options}{'attributes'}.=' <p>lang id';
  $self->{options}{'inline'}.=' <br>';
  $self->treat_options;

=head2 OVERRIDING THE found_string FUNCTION

Another simple step is to override the function "found_string", which
receives the extracted strings from the parser, in order to translate them.
There you can control which strings you want to translate, and perform
transformations to them before or after the translation itself.

It receives the extracted text, the reference on where it was, and a
comment that tells if it's an attribute value, a tag content... It must
return the text that will replace the original in the translated document.
Here's a basic example of this function:

  sub found_string {
    my ($self,$text,$ref,$comment)=@_;
    $text = $self->translate($text,$ref,$comment,
      'wrap'=>$self->{options}{'wrap'});
    return $text;
  }

There's another simple example in the new Dia module, which only filters
some strings.

=cut

sub found_string {
	my ($self,$text,$ref,$comment)=@_;
	$text = $self->translate($text,$ref,$comment,
		'wrap'=>$self->{options}{'wrap'});
	return $text;
}

=head2 MODIFYING TAG TYPES (TODO)

This is a more complex one, but it enables a (almost) total customization.
It's based in a list of hashes, each one defining a tag type's behavior. The
list should be sorted so that the most general tags are after the most
concrete ones (sorted first by the beginning and then by the end keys). To
define a tag type you'll have to make a hash with the following keys:

=over 4

=item beginning

Specifies the beginning of the tag, after the "<".

=item end

Specifies the end of the tag, before the ">".

=item breaking

It says if this is a breaking tag class.  A non-breaking (inline) tag is one
that can be taken as part of the content of another tag.  It can take the
values false (0), true (1) or undefined.  If you leave this undefined, you'll
have to define the f_breaking function that will say whether a concrete tag of
this class is a breaking tag or not.

=item f_breaking

It's a function that will tell if the next tag is a breaking one or not.  It
should be defined if the "breaking" option is not.

=item f_extract

If you leave this key undefined, the extraction function will have to extract
the tag itself.  It's useful for tags that can have other tags or special
structures in them, so that the main parser doesn't get mad.  This function
receives a boolean that says if the tag should be removed from the input
stream or not.

=item f_translate

This function returns the translated tag (translated attributes or all needed
transformations) as a single string.

=cut

##### Generic XML tag types #####

my @tag_types = (
	{	beginning	=> "!--",
		end		=> "--",
		breaking	=> 1,
		f_extract	=> \&tag_extract_comment,
		f_translate	=> \&tag_trans_comment},
	{	beginning	=> "?xml",
		end		=> "?",
		breaking	=> 1,
		f_translate	=> \&tag_trans_xmlhead},
#	{	beginning	=> "?",
#		end		=> "?",
#		breaking	=> 1,
#		f_translate	=> \&tag_trans_...},
	{	beginning	=> "!DOCTYPE",
		end		=> "]",
		breaking	=> 1,
		f_extract	=> \&tag_extract_doctype,
		f_translate	=> \&tag_trans_doctype},
	{	beginning	=> "/",
		end		=> "",
		f_breaking	=> \&tag_break_close,
		f_translate	=> \&tag_trans_close},
	{	beginning	=> "",
		end		=> "/",
		f_breaking	=> \&tag_break_alone,
		f_translate	=> \&tag_trans_alone},
	{	beginning	=> "",
		end		=> "",
		f_breaking	=> \&tag_break_open,
		f_translate	=> \&tag_trans_open}
);

sub tag_extract_comment {
	my ($self,$remove)=(shift,shift);
	my ($eof,@tag)=$self->get_string_until('-->',1,$remove);
	return ($eof,@tag);
}

sub tag_trans_comment {
	my ($self,@tag)=@_;
	return $self->join_lines(@tag);
}

sub tag_trans_xmlhead {
#TODO
	my ($self,@tag)=@_;
my $tag = $self->join_lines(@tag);
	$tag =~ /^(\S*)(\s*)(.*)/s;
	my ($name,$spaces,$attr)=($1,$2,$3);

	#We get the file encoding
	#my $enc=$self->attribute($attr,"encoding");
	#print $enc."\n";
	return $tag;
}

sub tag_extract_doctype {
	my ($self,$remove)=(shift,shift);
	my ($eof,@tag)=$self->get_string_until(']>',1,$remove);
	return ($eof,@tag);
}

sub tag_trans_doctype {
	my ($self,@tag)=@_;
	if (defined $self->{options}{'doctype'} ) {
		my $doctype = $self->{options}{'doctype'};
		if ( $tag[0] !~ /\Q$doctype\E/i ) {
			die sprintf(gettext("po4a::xml: Bad document type. '%s' expected."),$doctype)."\n";
		}
	}
	my $i = 0;
	while ( $i < $#tag ) {
		if ( $tag[$i] =~ /^(<!ENTITY\s+)(.*)$/is ) {
			my $part1 = $1;
			my $part2 = $2;
			my $includenow = 0;
			my $file = 0;
			my $name = "";
			if ($part2 =~ /^(%\s+)(.*)$/s ) {
				$part1.= $1;
				$part2 = $2;
				$includenow = 1;
			}
			$part2 =~ /^(\S+)(\s+)(.*)$/s;
			$name = $1;
			$part1.= $1.$2;
			$part2 = $3;
			if ( $part2 =~ /^(SYSTEM\s+)(.*)$/is ) {
				$part1.= $1;
				$part2 = $2;
				$file = 1;
			}
#			print $part1."\n";
#			print $name."\n";
#			print $part2."\n";
		}
		$i++;
	}
	return $self->join_lines(@tag);
}

sub tag_break_close {
	my ($self,@tag)=@_;
	if ($self->tag_in_list($self->get_structure."<".
		$self->get_tag_name(@tag).">",@{$self->{inline}})) {
		return 0;
	} else {
		return 1;
	}
}

sub tag_trans_close {
#TODO
	my ($self,@tag)=@_;
	my $name = $self->get_tag_name(@tag);

	my $test = pop @structure;
	if ( $test ne $name ) {
		die gettext("po4a::xml: Unexpected closing tag. The main document may be wrong.")."\n";
	}
	return $self->join_lines(@tag);
}

sub tag_break_alone {
	my ($self,@tag)=@_;
	if ($self->tag_in_list($self->get_structure."<".
		$self->get_tag_name(@tag).">",@{$self->{inline}})) {
		return 0;
	} else {
		return 1;
	}
}

sub tag_trans_alone {
#TODO
	my ($self,@tag)=@_;
	my $name = $self->get_tag_name(@tag);
	my ($spaces,$attr);
	push @structure, $name;

my $tag = $self->join_lines(@tag);
	$tag =~ /^(\S*)(\s*)(.*)/s;
	($name,$spaces,$attr)=($1,$2,$3);

	#$attr = $self->treat_attributes(@tag); #should be only the attributes

	pop @structure;
	return $name.$spaces.$attr;
}

sub tag_break_open {
	my ($self,@tag)=@_;
	if ($self->tag_in_list($self->get_structure."<".
		$self->get_tag_name(@tag).">",@{$self->{inline}})) {
		return 0;
	} else {
		return 1;
	}
}

sub tag_trans_open {
#TODO
	my ($self,@tag)=@_;
	my ($spaces,$attr);
	my $name = $self->get_tag_name(@tag);
	push @structure, $name;

my $tag = $self->join_lines(@tag);
	$tag =~ /^(\S*)(\s*)(.*)/s;
	($name,$spaces,$attr)=($1,$2,$3);
	#$attr = $self->treat_attributes(@tag); #should be only the attributes
	return $name.$spaces.$attr;
}

##### END of Generic XML tag types #####

=head1 INTERNAL FUNCTIONS used to write derivated parsers

=head2 WORKING WITH TAGS

=item get_structure

This function returns the path to the current tag from the document's root,
in the form <html><body><p>.

=cut

sub get_structure {
	my $self = shift;
	if ( @structure > 0 ) {
		return "<".join("><",@structure).">";
	} else {
		return "outside any tag (error?)";
	}
}

=item tag_type

This function returns the index from the tag_types list that fits to the next
tag in the input stream, or -1 if it's at the end of the input file.

=cut

sub tag_type {
	my $self = shift;
	my ($line,$ref) = $self->shiftline();
	my ($match1,$match2);
	my $found = 0;
	my $i = 0;

	if (!defined($line)) { return -1; }

	$self->unshiftline($line,$ref);
	while (!$found && $i < @tag_types) {
		($match1,$match2) = ($tag_types[$i]->{beginning},$tag_types[$i]->{end});
		if ($line =~ /^<\Q$match1\E/) {
			if (!defined($tag_types[$i]->{f_extract})) {
				my ($eof,@lines) = $self->get_string_until(">",1,0);
				my $line2 = $self->join_lines(@lines);
#print substr($line2,length($line2)-1-length($match2),1+length($match2))."\n";
				if (defined($line2) and $line2 =~ /\Q$match2\E>$/) {
					$found = 1;
#print "YES: <".$match1." ".$match2.">\n";
				} else {
#print "NO: <".$match1." ".$match2.">\n";
					$i++;
				}
			} else {
				$found = 1;
			}
		} else {
			$i++;
		}
	}
	if (!$found) {
		#It should never enter here, unless you undefine the most
		#general tags (as <...>)
		print "po4a::xml: Unknown tag type: ".$line."\n";
		exit;
	} else {
		return $i;
	}
}

=item extract_tag

This function returns the next tag from the input stream without the beginning
and end, in an array form, to mantain the references from the input file.  It
has two parameters: the type of the tag (as returned by tag_type) and a
boolean, that says if it should be removed from the input stream.

=cut

sub extract_tag {
	my ($self,$type,$remove) = (shift,shift,shift);
	my ($match1,$match2) = ($tag_types[$type]->{beginning},$tag_types[$type]->{end});
	my ($eof,@tag);
	if (defined($tag_types[$type]->{f_extract})) {
		($eof,@tag) = &{$tag_types[$type]->{f_extract}}($self,$remove);
	} else {
		($eof,@tag) = $self->get_string_until($match2.">",1,$remove);
	}
	$tag[0] =~ /^<\Q$match1\E(.*)$/s;
	$tag[0] = $1;
	$tag[$#tag-1] =~ /^(.*)\Q$match2\E>$/s;
	$tag[$#tag-1] = $1;
	return ($eof,@tag);
}

=item get_tag_name

This function returns the name of the tag passed as an argument, in the array
form returned by extract_tag.

=cut

sub get_tag_name {
	my ($self,@tag)=@_;
	$tag[0] =~ /^(\S*)/;
	return $1;
}

=item breaking_tag

This function returns a boolean that says if the next tag in the input stream
is a breaking tag or not (inline tag).  It leaves the input stream intact.

=cut

sub breaking_tag {
	my $self = shift;
	my $break;

	my $type = $self->tag_type;
	if ($type == -1) { return 0; }

#print "TAG TYPE = ".$type."\n";
	$break = $tag_types[$type]->{breaking};
	if (!defined($break)) {
		# This tag's breaking depends on its content
		my ($eof,@lines) = $self->extract_tag($type,0);
		$break = &{$tag_types[$type]->{f_breaking}}($self,@lines);
	}
#print "break = ".$break."\n";
	return $break;
}

=item treat_tag

This function translates the next tag from the input stream.  Using each
tag type's custom translation functions.

=cut

sub treat_tag {
	my $self = shift;
	my $type = $self->tag_type;

	my ($match1,$match2) = ($tag_types[$type]->{beginning},$tag_types[$type]->{end});
	my ($eof,@lines) = $self->extract_tag($type,1);

	$lines[0] =~ /^(\s*)(.*)$/s;
	my $space1 = $1;
	$lines[0] = $2;
	$lines[$#lines-1] =~ /^(.*?)(\s*)$/s;
	my $space2 = $2;
	$lines[$#lines-1] = $1;

	# Calling this tag type's specific handling (translation of
	# attributes...)
	my $line = &{$tag_types[$type]->{f_translate}}($self,@lines);
	$self->pushline("<".$match1.$space1.$line.$space2.$match2.">");
	return $eof;
}

=item tag_in_list

This function returns a boolean value that says if the first argument (a tag
hierarchy) matches any of the tags from the second argument (a list of tags
or tag hierarchies).

=cut

sub tag_in_list {
	my ($self,$tag,@list) = @_;
	my $found = 0;
	my $i = 0;
	
	while (!$found && $i < @list) {
		my $element = $list[$i];
		if ( $tag =~ /\Q$element\E$/ ) {
#print $tag."==".$element."\n";
			$found = 1;
		}
		$i++;
	}
	return $found;
}









#TODO

=head2 WORKING WITH ATTRIBUTES

=item treat_attributes

TODO

=cut

sub treat_attributes {
	my ($self,@attribs)=@_;
my $attribs = $self->join_lines(@attribs);
	if ( $attribs ne "" ) {
#print $structure[$#structure]."\n";
#		print $attribs."\n";
		my $value=$self->attribute($attribs,"type");
#		print $value."\n";
		if ($value ne "") {
			$attribs=$self->attribute($attribs,"type","asereje");
			print $attribs."\n";
		}
	}
	return $attribs;
}

sub attribute {
	my ($self,@attribs,$attrib,$value)=(shift,shift,shift,shift);
my $attribs = $self->join_lines(@attribs);
	my ($val,$quotes)=("","");
	if ( $attribs =~ /\Q$attrib\E=(\")(.*?)\" |
			\Q$attrib\E=(\')(.*?)\' |
			\Q$attrib\E=()(\S*?)/sx ) {
		if (defined($2)) {
			$quotes=$1;
			$val=$2;
		} elsif (defined($4)) {
			$quotes=$3;
			$val=$4;
		} else {
			$quotes=$5;
			$val=$6;
		}
	}
	if (!defined($value)) {
		return $val;
	} else {
		$attribs =~ s/\Q$attrib\E=$quotes\Q$val\E$quotes/\Q$attrib\E=$quotes\Q$value\E$quotes/s;
		return $attribs;
	}
}



sub treat_content {
	my $self = shift;
	my $blank="";
	my ($eof,@paragraph)=$self->get_string_until('<',0,1);

	while (!$eof and !$self->breaking_tag) {
		my @text;
		# Append the found inline tag
		($eof,@text)=$self->get_string_until('>',1,1);
		push @paragraph, @text;

		($eof,@text)=$self->get_string_until('<',0,1);
		if ($#text > 0) {
			push @paragraph, @text;
		}
	}

	# This strips the extracted strings
	# (only if you specify the 'strip' option)
	if ($self->{options}{'strip'}) {
		my $clean = 0;
		# Clean the beginning
		while (!$clean and $#paragraph > 0) {
			$paragraph[0] =~ /^(\s*)(.*)/s;
			my $match = $1;
			if ($paragraph[0] eq $match) {
				if ($match ne "") {
					$self->pushline($match);
				}
				shift @paragraph;
				shift @paragraph;
			} else {
				$paragraph[0] = $2;
				if ($match ne "") {
					$self->pushline($match);
				}
				$clean = 1;
			}
		}
		$clean = 0;
		# Clean the end
		while (!$clean and $#paragraph > 0) {
			$paragraph[$#paragraph-1] =~ /^(.*?)(\s*)$/s;
			my $match = $2;
			if ($paragraph[$#paragraph-1] eq $match) {
				if ($match ne "") {
					$blank = $match.$blank;
				}
				pop @paragraph;
				pop @paragraph;
			} else {
				$paragraph[$#paragraph-1] = $1;
				if ($match ne "") {
					$blank = $match.$blank;
				}
				$clean = 1;
			}
		}
	}

	if ( length($self->join_lines(@paragraph)) > 0 ) {
		my $struc = $self->get_structure;
		my $inlist = $self->tag_in_list($struc,@{$self->{tags}});
#print $self->{options}{'tagsonly'}."==".$inlist."\n";
		if ( $self->{options}{'tagsonly'} eq $inlist ) {
#print "YES\n";
			$self->pushline($self->found_string($self->join_lines(@paragraph),
				$paragraph[1],"Content of tag ".$struc));
		} else {
#print "NO\n";
			$self->pushline($self->join_lines(@paragraph));
		}
	}

	if ($blank ne "") {
		$self->pushline($blank);
	}
	return $eof;
}





=head2 WORKING WITH THE MODULE OPTIONS

=item treat_options

This function fills the internal structures that contain the tags, attributes
and inline data with the options of the module (specified in the command-line
or in the initialize function).

=cut

sub treat_options {
	my $self = shift;

	$self->{options}{'tags'} =~ /\s*(.*)\s*/s;
	my @list = split(/\s+/s,$1);
	$self->{tags} = \@list;

#	$self->{options}{'attributes'}

	$self->{options}{'inline'} =~ /\s*(.*)\s*/s;
	my @list2 = split(/\s+/s,$1);
	$self->{inline} = \@list2;
}

=head2 GETTING TEXT FROM THE INPUT STREAM

=item get_string_until

This function returns an array with the lines (and references) from the input
stream until it finds the first argument.  The second argument is a boolean
that says if the returned array should contain the searched text or not.  The
third argument is another boolean that says if the returned stream should be
removed from the input or not.

=cut

sub get_string_until {
	# search = the text we want to find (at the moment it can't have \n's)
	# include = include the searched text in the returned paragraph
	# remove = remove the returned text from input or leave it intact
	my ($self,$search,$include,$remove) = (shift,shift,shift,shift);
	if (!defined($include)) { $include = 0; }
	if (!defined($remove)) { $remove = 0; }

	my ($line,$ref) = $self->shiftline();
	my (@text,$paragraph);
	my ($eof,$found) = (0,0);

	while (defined($line) and !$found) {
		push @text, ($line,$ref);
		$paragraph .= $line;
		if ( $paragraph =~ /.*\Q$search\E.*/s ) {
			$found = 1;
		} else {
			($line,$ref)=$self->shiftline();
		}
	}

	if (!defined($line)) { $eof = 1; }

	if ( $found ) {
		if(!$include) {
			$text[$#text-1] =~ /(.*?)(\Q$search\E.*)/s;
			$text[$#text-1] = $1;
			$line = $2;
		} else {
			$text[$#text-1] =~ /(.*?\Q$search\E)(.*)/s;
			$text[$#text-1] = $1;
			$line = $2;
		}
		if (defined($line) and ($line ne "")) {
			$self->unshiftline ($line,$text[$#text]);
		}
	}
	if (!$remove) {
		my $i = $#text;
		while ($i > 0) {
			$self->unshiftline ($text[$i-1],$text[$i]);
			$i -= 2;
		}
	}

	#If we get to the end of the file, we return the whole paragraph
	return ($eof,@text);
}

=item join_lines

This function returns a simple string with the text from the argument array
(discarding the references).

=cut

sub join_lines {
	my ($self,@lines)=@_;
	my ($line,$ref);
	my $text = "";
	while ($#lines > 0) {
		($line,$ref) = (shift @lines,shift @lines);
		$text .= $line;
	}
	return $text;
}

=head1 STATUS OF THIS MODULE

Well... hmm... If this works for you now, you're using a very simple
document format ;)

=head1 SEE ALSO

L<po4a(7)>, L<Locale::Po4a::TransTranctor(3pm)>.

=head1 AUTHORS

Jordi Vilalta <jvprat@wanadoo.es>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004 by Jordi Vilalta  <jvprat@wanadoo.es>

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see COPYING file).

=cut

1;


##### TODO LIST #####
#
#OPTIONS
#caseinsensitive
#attributes
#
#MODIFY TAG TYPES FROM INHERITED MODULES
#(move the tag_types structure inside the $self hash?)
#
#DOCTYPE (ENTITIES)
#INCLUDED FILES
#
#XML HEADER (ENCODING)
#
#breaking tag inside non-breaking tag (possible?) causes ugly comments
