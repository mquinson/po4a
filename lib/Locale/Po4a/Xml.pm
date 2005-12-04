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

The po4a (po for anything) project goal is to ease translations (and more
interestingly, the maintenance of translations) using gettext tools on
areas where they were not expected like documentation.

Locale::Po4a::Xml is a module to help the translation of XML documents into
other [human] languages. It can also be used as a base to build modules for
XML-based documents.

Please note that this module is still under heavy development, and not
distributed in official po4a release since we don't feel it to be mature
enough. If you insist on trying, check the CVS out.

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
use Locale::Po4a::Common;

#It will mantain the path from the root tag to the current one
my @path;

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
extract all tag's content, and no attributes, since it's where the text is
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

The global debug option causes this module to show the excluded strings, in
order to see if it skips something important.

These are this module's particular options:

=over 4

=item nostrip

Prevents it to strip the spaces around the extracted strings.

=item wrap

Canonizes the string to translate, considering that whitespaces are not
important, and wraps the translated document. This option can be overridden
by custom tag options. See the "tags" option below.

=item caseinsensitive

It makes the tags and attributes searching to work in a case insensitive
way.  If it's defined, it will treat E<lt>BooKE<gt>laNG and E<lt>BOOKE<gt>Lang as E<lt>bookE<gt>lang.

=item tagsonly

Extracts only the specified tags in the "tags" option.  Otherwise, it
will extract all the tags except the ones specified.

=item doctype

String that will try to match with the first line of the document's doctype
(if defined). If it doesn't, the document will be considered of a bad type.

=item tags

Space-separated list of the tags you want to translate or skip.  By default,
the specified tags will be excluded, but if you use the "tagsonly" option,
the specified tags will be the only ones included.  The tags must be in the
form E<lt>aaaE<gt>, but you can join some (E<lt>bbbE<gt>E<lt>aaaE<gt>) to say that the content of
the tag E<lt>aaaE<gt> will only be translated when it's into a E<lt>bbbE<gt> tag.

You can also specify some tag options putting some characters in front of
the tag hierarchy. For example, you can put 'w' (wrap) or 'W' (don't wrap)
to override the default behavior specified by the global "wrap" option.

Example: WE<lt>chapterE<gt>E<lt>titleE<gt>

=item attributes

Space-separated list of the tag's attributes you want to translate.  You can
specify the attributes by their name (for example, "lang"), but you can
prefix it with a tag hierarchy, to specify that this attribute will only be
translated when it's into the specified tag. For example: E<lt>bbbE<gt>E<lt>aaaE<gt>lang
specifies that the lang attribute will only be translated if it's into an
E<lt>aaaE<gt> tag, and it's into a E<lt>bbbE<gt> tag.

=item inline

Space-separated list of the tags you want to treat as inline.  By default,
all tags break the sequence.  This follows the same syntax as the tags option.

=item nodefault

Space separated list of tags that the module should not try to set by
default in the "tags" or "inline" category.

=back

=cut

sub initialize {
	my $self = shift;
	my %options = @_;

	$self->{options}{'nostrip'}=0;
	$self->{options}{'wrap'}=0;
	$self->{options}{'caseinsensitive'}=0;
	$self->{options}{'tagsonly'}=0;
	$self->{options}{'tags'}='';
	$self->{options}{'attributes'}='';
	$self->{options}{'inline'}='';
	$self->{options}{'doctype'}='';
	$self->{options}{'nodefault'}='';

	$self->{options}{'verbose'}='';
	$self->{options}{'debug'}='';

	foreach my $opt (keys %options) {
		if ($options{$opt}) {
			die wrap_mod("po4a::xml",
				dgettext("po4a", "Unknown option: %s"), $opt)
				unless exists $self->{options}{$opt};
			$self->{options}{$opt} = $options{$opt};
		}
	}

	#It will maintain the list of the translatable tags
	$self->{tags}=();
	#It will maintain the list of the translatable attributes
	$self->{attributes}=();
	#It will maintain the list of the inline tags
	$self->{inline}=();
	#list of the tags that must not be set in the tags or inline category
	#by this module or sub-module (unless specified in an option)
	$self->{nodefault}=();

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

It receives the extracted text, the reference on where it was, and a hash
that contains extra information to control what strings to translate, how
to translate them and to generate the comment.

The content of these options depends on the kind of string it is (specified in an 
entry of this hash):

=over

=item type="tag"

The found string is the content of a translatable tag. The entry "tag_options"
contains the option characters in front of the tag hierarchy in the module
"tags" option.

=item type="attribute"

Means that the found string is the value of a translatable attribute. The
entry "attribute" has the name of the attribute.

=back

It must return the text that will replace the original in the translated
document. Here's a basic example of this function:

  sub found_string {
    my ($self,$text,$ref,$options)=@_;
    $text = $self->translate($text,$ref,"type ".$options->{'type'},
      'wrap'=>$self->{options}{'wrap'});
    return $text;
  }

There's another simple example in the new Dia module, which only filters
some strings.

=cut

sub found_string {
	my ($self,$text,$ref,$options)=@_;

	my $comment;
	my $wrap = $self->{options}{'wrap'};

	if ($options->{'type'} eq "tag") {
		$comment = "Content of: ".$self->get_path;

		if($options->{'tag_options'} =~ /w/) {
			$wrap = 1;
		}
		if($options->{'tag_options'} =~ /W/) {
			$wrap = 0;
		}
	} elsif ($options->{'type'} eq "attribute") {
		$comment = "Attribute '".$options->{'attribute'}."' of: ".$self->get_path;
	} else {
		die wrap_ref_mod($ref, "po4a::xml", dgettext("po4a", "Internal error: unknown type identifier '%s'."), $options->{'type'});
	}

	$text = $self->translate($text,$ref,$comment,'wrap'=>$wrap);
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

Specifies the beginning of the tag, after the "E<lt>".

=item end

Specifies the end of the tag, before the "E<gt>".

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

If you leave this key undefined, the generic extraction function will have to
extract the tag itself.  It's useful for tags that can have other tags or
special structures in them, so that the main parser doesn't get mad.  This
function receives a boolean that says if the tag should be removed from the
input stream or not.

=item f_translate

This function receives the tag (in the get_string_until() format) and returns
the translated tag (translated attributes or all needed transformations) as a
single string.

=back

=cut

##### Generic XML tag types #####' 

my @tag_types = ( 
	{	beginning	=> "!--",
		end		=> "--",
		breaking	=> 0,
		f_extract	=> \&tag_extract_comment,
		f_translate	=> \&tag_trans_comment},
	{	beginning	=> "?xml",
		end		=> "?",
		breaking	=> 1,
		f_translate	=> \&tag_trans_xmlhead},
	{	beginning	=> "?",
		end		=> "?",
		breaking	=> 1,
		f_translate	=> \&tag_trans_procins},
	{	beginning	=> "!DOCTYPE",
		end		=> "",
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
	my ($eof,@tag)=$self->get_string_until('-->',{include=>1,remove=>$remove});
	return ($eof,@tag);
}

sub tag_trans_comment {
	my ($self,@tag)=@_;
	return $self->join_lines(@tag);
}

sub tag_trans_xmlhead {
	my ($self,@tag)=@_;

	# We don't have to translate anything from here: throw away references
	my $tag = $self->join_lines(@tag);
	$tag =~ /encoding=(("|')|)(.*?)(\s|\2)/s;
	my $in_charset=$3;
	$self->detected_charset($in_charset);
	my $out_charset=$self->get_out_charset;

	if (defined $in_charset) {
		$tag =~ s/$in_charset/$out_charset/;
	} else {
		if ($tag =~ m/standalone/) {
			$tag =~ s/(standalone)/encoding="$out_charset" $1/;
		} else {
			$tag.= " encoding=\"$out_charset\"";
		}
	}

	return $tag;
}

sub tag_trans_procins {
	my ($self,@tag)=@_;
	return $self->join_lines(@tag);
}

sub tag_extract_doctype {
#TODO
	my ($self,$remove)=(shift,shift);
	my ($eof,@tag)=$self->get_string_until(']>',{include=>1,unquoted=>1});
	if ($eof) {
		($eof,@tag)=$self->get_string_until('>',{include=>1,remove=>$remove,unquoted=>1});
	} else {
		($eof,@tag)=$self->get_string_until(']>',{include=>1,remove=>$remove,unquoted=>1});
	}
	return ($eof,@tag);
}

sub tag_trans_doctype {
#TODO
	my ($self,@tag)=@_;
	if (defined $self->{options}{'doctype'} ) {
		my $doctype = $self->{options}{'doctype'};
		if ( $tag[0] !~ /\Q$doctype\E/i ) {
			die wrap_ref_mod($tag[1], "po4a::xml", dgettext("po4a", "Bad document type. '%s' expected."), $doctype);
		}
	}
	my $i = 0;
	while ( $i < $#tag ) {
		my $t = $tag[$i];
		my $ref = $tag[$i+1];
		if ( $t =~ /^(\s*<!ENTITY\s+)(.*)$/is ) {
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
			if ((not $file) and (not $includenow)) {
			    if ($part2 =~ m/^\s*(["'])(.*)\1(\s*>.*)$/s) {
				my $comment = "Content of the $name entity";
				my $text = $2;
				$part2 = $3;
				$text = $self->translate($text,
				                         $ref,
				                         $comment,
				                         'wrap'=>1);
				$t = $part1."\"$text\"$part2";
			    }
			}
#			print $part1."\n";
#			print $name."\n";
#			print $part2."\n";
		}
		$tag[$i] = $t;
		$i += 2;
	}
	return $self->join_lines(@tag);
}

sub tag_break_close {
	my ($self,@tag)=@_;
	if ($self->tag_in_list($self->get_path."<".
		$self->get_tag_name(@tag).">",@{$self->{inline}})) {
		return 0;
	} else {
		return 1;
	}
}

sub tag_trans_close {
	my ($self,@tag)=@_;
	my $name = $self->get_tag_name(@tag);

	my $test = pop @path;
	if (!defined($test) || $test ne $name ) {
		die wrap_ref_mod($tag[1], "po4a::xml", dgettext("po4a", "Unexpected closing tag </%s> found. The main document may be wrong."), $name);
	}
	return $self->join_lines(@tag);
}

sub tag_break_alone {
	my ($self,@tag)=@_;
	if ($self->tag_in_list($self->get_path."<".
		$self->get_tag_name(@tag).">",@{$self->{inline}})) {
		return 0;
	} else {
		return 1;
	}
}

sub tag_trans_alone {
	my ($self,@tag)=@_;
	my $name = $self->get_tag_name(@tag);
	push @path, $name;

	$name = $self->treat_attributes(@tag);

	pop @path;
	return $name;
}

sub tag_break_open {
	my ($self,@tag)=@_;
	if ($self->tag_in_list($self->get_path."<".
		$self->get_tag_name(@tag).">",@{$self->{inline}})) {
		return 0;
	} else {
		return 1;
	}
}

sub tag_trans_open {
	my ($self,@tag)=@_;
	my $name = $self->get_tag_name(@tag);
	push @path, $name;

	$name = $self->treat_attributes(@tag);

	return $name;
}

##### END of Generic XML tag types #####

=head1 INTERNAL FUNCTIONS used to write derivated parsers

=head2 WORKING WITH TAGS

=over 4

=item get_path()

This function returns the path to the current tag from the document's root,
in the form E<lt>htmlE<gt>E<lt>bodyE<gt>E<lt>pE<gt>.

=cut

sub get_path {
	my $self = shift;
	if ( @path > 0 ) {
		return "<".join("><",@path).">";
	} else {
		return "outside any tag (error?)";
	}
}

=item tag_type()

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
				my ($eof,@lines) = $self->get_string_until(">",{include=>1,unquoted=>1});
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
		die "po4a::xml: Unknown tag type: ".$line."\n";
	} else {
		return $i;
	}
}

=item extract_tag($$)

This function returns the next tag from the input stream without the beginning
and end, in an array form, to maintain the references from the input file.  It
has two parameters: the type of the tag (as returned by tag_type) and a
boolean, that indicates if it should be removed from the input stream.

=cut

sub extract_tag {
	my ($self,$type,$remove) = (shift,shift,shift);
	my ($match1,$match2) = ($tag_types[$type]->{beginning},$tag_types[$type]->{end});
	my ($eof,@tag);
	if (defined($tag_types[$type]->{f_extract})) {
		($eof,@tag) = &{$tag_types[$type]->{f_extract}}($self,$remove);
	} else {
		($eof,@tag) = $self->get_string_until($match2.">",{include=>1,remove=>$remove,unquoted=>1});
	}
	$tag[0] =~ /^<\Q$match1\E(.*)$/s;
	$tag[0] = $1;
	$tag[$#tag-1] =~ /^(.*)\Q$match2\E>$/s;
	$tag[$#tag-1] = $1;
	return ($eof,@tag);
}

=item get_tag_name(@)

This function returns the name of the tag passed as an argument, in the array
form returned by extract_tag.

=cut

sub get_tag_name {
	my ($self,@tag)=@_;
	$tag[0] =~ /^(\S*)/;
	return $1;
}

=item breaking_tag()

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

=item treat_tag()

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

=item tag_in_list($@)

This function returns a string value that says if the first argument (a tag
hierarchy) matches any of the tags from the second argument (a list of tags
or tag hierarchies). If it doesn't match, it returns 0. Else, it returns the
matched tag's options (the characters in front of the tag) or 1 (if that tag
doesn't have options).

=back

=cut

sub tag_in_list {
	my ($self,$tag,@list) = @_;
	my $found = 0;
	my $i = 0;
	
	while (!$found && $i < @list) {
		my $options;
		my $element;
		if ($list[$i] =~ /(.*?)(<.*)/) {
			$options = $1;
			$element = $2;
		} else {
			$element = $list[$i];
		}
		if ($self->{options}{'caseinsensitive'}) {
			if ( $tag =~ /\Q$element\E$/i ) {
				$found = 1;
			}
		} else {
			if ( $tag =~ /\Q$element\E$/ ) {
				$found = 1;
			}
		}
		if ($found) {
			if ($options) {
				$found = $options;
			}
		} else {
			$i++;
		}
	}
	return $found;
}

=head2 WORKING WITH ATTRIBUTES

=over 4

=item treat_attributes(@)

This function handles the translation of the tags' attributes. It receives the tag
without the beginning / end marks, and then it finds the attributes, and it
translates the translatable ones (specified by the module option "attributes").
This returns a plain string with the translated tag.

=back

=cut

sub treat_attributes {
	my ($self,@tag)=@_;

	$tag[0] =~ /^(\S*)(.*)/s;
	my $text = $1;
	$tag[0] = $2;

	while (@tag) {
		my $complete = 1;

		$text .= $self->skip_spaces(\@tag);
		if (@tag) {
			# Get the attribute's name
			$complete = 0;

			$tag[0] =~ /^([^\s=]+)(.*)/s;
			my $name = $1;
			my $ref = $tag[1];
			$tag[0] = $2;
			$text .= $name;
			$text .= $self->skip_spaces(\@tag);
			if (@tag) {
				# Get the '='
				if ($tag[0] =~ /^=(.*)/s) {
					$tag[0] = $1;
					$text .= "=";
					$text .= $self->skip_spaces(\@tag);
					if (@tag) {
						# Get the value
						my $value="";
						$ref=$tag[1];
						my $quot=substr($tag[0],0,1);
						if ($quot ne "\"" and $quot ne "'") {
							# Unquoted value
							$quot="";
							$tag[0] =~ /^(\S+)(.*)/s;
							$value = $1;
							$tag[0] = $2;
						} else {
							# Quoted value
							$text .= $quot;
							$tag[0] =~ /^\Q$quot\E(.*)/s;
							$tag[0] = $1;
							while ($tag[0] !~ /\Q$quot\E/) {
								$value .= $tag[0];
								shift @tag;
								shift @tag;
							}
							$tag[0] =~ /^(.*?)\Q$quot\E(.*)/;
							$value .= $1;
							$tag[0] = $2;
						}
						$complete = 1;
						if ($self->tag_in_list($self->get_path.$name,@{$self->{attributes}})) {
							$text .= $self->found_string($value, $ref, { type=>"attribute", attribute=>$name });
						} else {
							print wrap_ref_mod($ref, "po4a::xml", dgettext("po4a", "Content of attribute %s excluded: %s"), $self->get_path.$name, $value)
							       if $self->debug();
							$text .= $self->recode_skipped_text($value);
						}
						$text .= $quot;
					}
				}
			}
          
			die wrap_ref_mod($ref, "po4a::xml", dgettext ("po4a", "Bad attribute syntax"))
				unless ($complete);
		}
	}
	return $text;
}



sub treat_content {
	my $self = shift;
	my $blank="";
	# Indicates if the paragraph will have to be translated
	my $translate = 0;

	my ($eof,@paragraph)=$self->get_string_until('<',{remove=>1});

	# Check if this has to be translated
	if ($self->join_lines(@paragraph) !~ /^\s*$/s) {
		my $struc = $self->get_path;
		my $inlist = 0;
		if ($self->tag_in_list($struc,@{$self->{tags}})) {
			$inlist = 1;
		}
		if ($self->{options}{'tagsonly'} eq $inlist) {
			$translate = 1;
		}
	}

	while (!$eof and !$self->breaking_tag) {
	NEXT_TAG:
		my @text;
		my $type = $self->tag_type;
		my $f_extract = $tag_types[$type]->{'f_extract'};
		if (    defined($f_extract)
		    and $f_extract eq \&tag_extract_comment) {
			# Remove the content of the comments
			($eof, @text) = $self->extract_tag($type,1);
		} else {
			my ($tmpeof, @tag) = $self->extract_tag($type,0);
			# Append the found inline tag
			($eof,@text)=$self->get_string_until('>',
			                                     {include=>1,
			                                      remove=>1,
			                                      unquoted=>1});
			# Append or remove the opening/closing tag from
			# the tag path
			if ($tag_types[$type]->{'end'} eq "") {
				if ($tag_types[$type]->{'beginning'} eq "") {
					push @path, $self->get_tag_name(@tag);
				} elsif ($tag_types[$type]->{'beginning'} eq "/") {
					my $test = pop @path;
					if (!defined($test) ||
					    $test ne $tag[0] ) {
						die wrap_ref_mod($tag[1], "po4a::xml", dgettext("po4a", "Unexpected closing tag </%s> found. The main document may be wrong."), $tag[0]);
					}
				}
			}
			push @paragraph, @text;
		}

		# Next tag
		($eof,@text)=$self->get_string_until('<',{remove=>1});
		if ($#text > 0) {
			# Check if text (extracted after the inline tag)
			# has to be translated
			if ($self->join_lines(@text) !~ /^\s*$/s) {
				my $struc = $self->get_path;
				my $inlist = 0;
				if ($self->tag_in_list($struc,
				                       @{$self->{tags}})) {
					$inlist = 1;
				}
				if ($self->{options}{'tagsonly'} eq $inlist) {
					$translate = 1;
				}
			}
			push @paragraph, @text;
		}

		# If the next tag closes the last inline tag, we loop again
		# (In the case of <foo><bar> being the inline tag, we can't
		# loop back with the "while" because breaking_tag will check
		# for <foo><bar><bar>, hence the goto)
		$type = $self->tag_type;
		if (    ($tag_types[$type]->{'end'} eq "")
		    and ($tag_types[$type]->{'beginning'} eq "/") ) {
			my ($tmpeof, @tag) = $self->extract_tag($type,0);
			if ($self->get_tag_name(@tag) eq $path[$#path]) {
				# The next tag closes the last inline tag.
				# We nned to temporarily remove the tag from
				# the path before calling breaking_tag
				my $t = pop @path;
				if (!$tmpeof and !$self->breaking_tag) {
					push @path, $t;
					goto NEXT_TAG;
				}
				push @path, $t;
			}
		}
	}

	# This strips the extracted strings
	# (only if you don't specify the 'nostrip' option)
	if (!$self->{options}{'nostrip'}) {
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

	# Translate the string when needed
	if ( length($self->join_lines(@paragraph)) > 0 ) {
		my $struc = $self->get_path;
		my $options = $self->tag_in_list($struc,@{$self->{tags}});
		$options = "" if ($options eq 0 or $options eq 1);
		if ($translate) {
			# This tag should be translated
			$self->pushline($self->found_string(
				$self->join_lines(@paragraph),
				$paragraph[1], {
					type=>"tag",
					tag_options=>$options
				}));
		} else {
			# Inform that this tag isn't translated in debug mode
			print wrap_ref_mod($paragraph[1], "po4a::xml", dgettext ("po4a", "Content of tag %s excluded: %s"), $self->get_path, $self->join_lines(@paragraph))
			       if $self->debug();
			$self->pushline($self->recode_skipped_text($self->join_lines(@paragraph)));
		}
	}

	# Push the trailing blanks
	if ($blank ne "") {
		$self->pushline($blank);
	}
	return $eof;
}





=head2 WORKING WITH THE MODULE OPTIONS

=over 4

=item treat_options()

This function fills the internal structures that contain the tags, attributes
and inline data with the options of the module (specified in the command-line
or in the initialize function).

=back

=cut

sub treat_options {
	my $self = shift;

	$self->{options}{'tags'} =~ /\s*(.*)\s*/s;
	my @list_tags = split(/\s+/s,$1);
	$self->{tags} = \@list_tags;

	$self->{options}{'attributes'} =~ /\s*(.*)\s*/s;
	my @list_attr = split(/\s+/s,$1);
	$self->{attributes} = \@list_attr;

	$self->{options}{'inline'} =~ /\s*(.*)\s*/s;
	my @list_inline = split(/\s+/s,$1);
	$self->{inline} = \@list_inline;
        
	$self->{options}{'nodefault'} =~ /\s*(.*)\s*/s;
	my %list_nodefault;
	foreach (split(/\s+/s,$1)) {
	    $list_nodefault{$_} = 1;
	}
	$self->{nodefault} = \%list_nodefault;
}

=head2 GETTING TEXT FROM THE INPUT DOCUMENT

=over

=item get_string_until($%)

This function returns an array with the lines (and references) from the input
document until it finds the first argument.  The second argument is an options
hash. Value 0 means disabled (the default) and 1, enabled.

The valid options are:

=over 4

=item include

This makes the returned array to contain the searched text

=item remove

This removes the returned stream from the input

=item unquoted

This ensures that the searched text is outside any quotes

=back

=cut

sub get_string_until {
	my ($self,$search) = (shift,shift);
	my $options = shift;
	my ($include,$remove,$unquoted) = (0,0,0);

	if (defined($options->{include})) { $include = $options->{include}; }
	if (defined($options->{remove})) { $remove = $options->{remove}; }
	if (defined($options->{unquoted})) { $unquoted = $options->{unquoted}; }

	my ($line,$ref) = $self->shiftline();
	my (@text,$paragraph);
	my ($eof,$found) = (0,0);

	while (defined($line) and !$found) {
		push @text, ($line,$ref);
		$paragraph .= $line;
		if ($unquoted) {
			if ( $paragraph =~ /^((\".*?\")|(\'.*?\')|[^\"\'])*\Q$search\E.*/s ) {
				$found = 1;
			}
		} else {
			if ( $paragraph =~ /.*\Q$search\E.*/s ) {
				$found = 1;
			}
		}
		if (!$found) {
			($line,$ref)=$self->shiftline();
		}
	}

	if (!defined($line)) { $eof = 1; }

	if ( $found ) {
		$line = "";
		if($unquoted) {
			$text[$#text-1] =~ /^(((\".*?\")|(\'.*?\')|[^\"\'])*?\Q$search\E)(.*)/s;
			$text[$#text-1] = $1;
			$line = $5;
		} else {
			$text[$#text-1] =~ /(.*?\Q$search\E)(.*)/s;
			$text[$#text-1] = $1;
			$line = $2;
		}
		if(!$include) {
			$text[$#text-1] =~ /(.*)(\Q$search\E.*)/s;
			$text[$#text-1] = $1;
			$line = $2.$line;
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

=item skip_spaces(\@)

This function receives as argument the reference to a paragraph (in the format
returned by get_string_until), skips his heading spaces and returns them as
a simple string.

=cut

sub skip_spaces {
	my ($self,$pstring)=@_;
	my $space="";

	while (@$pstring and (@$pstring[0] =~ /^(\s+)(.*)$/s or @$pstring[0] eq "")) {
		if (@$pstring[0] ne "") {
			$space .= $1;
			@$pstring[0] = $2;
		}

		if (@$pstring[0] eq "") {
			shift @$pstring;
			shift @$pstring;
		}
	}
	return $space;
}

=item join_lines(@)

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

=back

=head1 STATUS OF THIS MODULE

This module can translate tags and attributes.

Support for entities and included files is in the TODO list.

The writing of derivate modules is rather limited.

=head1 TODO LIST

DOCTYPE (ENTITIES)

There is a minimal support for the translation of entities. They are
translated as a whole, and tags are not taken into account. Multilines
entities are not supported and entities are always rewrapped during the
translation.

INCLUDED FILES

MODIFY TAG TYPES FROM INHERITED MODULES
(move the tag_types structure inside the $self hash?)

breaking tag inside non-breaking tag (possible?) causes ugly comments

=head1 SEE ALSO

L<po4a(7)|po4a.7>, L<Locale::Po4a::TransTractor(3pm)|Locale::Po4a::TransTractor>.

=head1 AUTHORS

 Jordi Vilalta <jvprat@wanadoo.es>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004 by Jordi Vilalta  E<lt>jvprat@wanadoo.esE<gt>

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see the COPYING file).

=cut

1;
