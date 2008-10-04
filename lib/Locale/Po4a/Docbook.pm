#!/usr/bin/perl

# Po4a::Docbook.pm 
# 
# extract and translate translatable strings from Docbook XML documents.
# 
# This code extracts plain text from tags and attributes on Docbook XML
# documents.
#
# Copyright (c) 2004 by Jordi Vilalta  <jvprat@gmail.com>
# Copyright (c) 2007-2008 by Nicolas François <nicolas.francois@centraliens.net>
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

=head1 NAME

Locale::Po4a::Docbook - Convert Docbook XML documents from/to PO files

=head1 DESCRIPTION

The po4a (po for anything) project goal is to ease translations (and more
interestingly, the maintenance of translations) using gettext tools on
areas where they were not expected like documentation.

Locale::Po4a::Docbook is a module to help the translation of DocBook XML 
documents into other [human] languages.

Please note that this module is still under heavy development, and not 
distributed in official po4a release since we don't feel it to be mature 
enough. If you insist on trying, check the CVS out.

=head1 STATUS OF THIS MODULE

This module is fully functional, as it relies in the L<Locale::Po4a::Xml>
module. This only defines the translatable tags and attributes.

The only known issue is that it doesn't handle entities yet, and this includes
the file inclusion entities, but you can translate most of those files alone
(except the typical entities files), and it's usually better to maintain them
separated.

=head1 SEE ALSO

L<po4a(7)|po4a.7>, L<Locale::Po4a::TransTractor(3pm)>, L<Locale::Po4a::Xml(3pm)>.

=head1 AUTHORS

 Jordi Vilalta <jvprat@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004 by Jordi Vilalta  <jvprat@gmail.com>
Copyright (c) 2007-2008 by Nicolas François <nicolas.francois@centraliens.net>

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see the COPYING file).

=cut

package Locale::Po4a::Docbook;

use 5.006;
use strict;
use warnings;

use Locale::Po4a::Xml;

use vars qw(@ISA);
@ISA = qw(Locale::Po4a::Xml);

sub initialize {
	my $self = shift;
	my %options = @_;

	$self->SUPER::initialize(%options);
	$self->{options}{'tagsonly'}=1;
	$self->{options}{'wrap'}=1;
	$self->{options}{'doctype'}=$self->{options}{'doctype'} || 'docbook xml';
	$self->{options}{'_default_tags'} = '
		<abbrev>
		W<address>
		<affiliation>
		<appendixinfo>
		<arg>
		<artheader>
		<articleinfo>
		<attribution>
		<biblioentry>
		<bibliographyinfo>
		<blockinfo>
		<bookinfo>
		<citetitle>
		<cmdsynopsis>
		<confgroup>
		<confdates>
		<conftitle>
		<confnum>
		<confsponsor>
		<contrib>
		<chapterinfo>
		<collab>
		<computeroutput>
		<date>
		<entry>
		<figure>
		<glossaryinfo>
		<glosssee>
		<glossseealso>
		<glossterm>
		<holder>
		<indexinfo>
		<jobtitle>
		<keyword>
		<member>
		<msgaud>
		<msglevel>
		<msgorig>
		<objectinfo>
		<orgdiv>
		<othercredit>
		<para>
		<phrase>
		<prefaceinfo>
		<primary>
		<pubdate>
		<publishername>
		<pubsnumber>
		W<programlisting>
		<prompt>
		<quote>
		<refclass>
		<refdescriptor>
		<refmiscinfo>
		<refname>
		<refpurpose>
		<refsynopsisdivinfo>
		<releaseinfo>
		<remark>
		<revision>
		<revnumber>
		<revremark>
		W<screen>
		<screeninfo>
		<sect1info>
		<sect2info>
		<sect3info>
		<sect4info>
		<sect5info>
		<sectioninfo>
		<seg>
		<segtitle>
		<setinfo>
		<shortaffil>
		<simpara>
		<subtitle>
		<synopfragmentref>
		<synopsis>
		<term>
		<title>
		<titleabbrev>
		<userinput>';
	$self->{options}{'_default_inline'} = '
		<acronym>
		<action>
		<anchor>
		<application>
		<arg>
		<author>
		<authorinitials>
		<citation>
		<citerefentry>
		<citetitle>
		<city>
		<country>
		<classname>
		<co>
		<command>
		<computeroutput>
		<constant>
		<corpauthor>
		<database>
		<email>
		<emphasis>
		<envar>
		<errorcode>
		<errorname>
		<errortext>
		<errortype>
		<exceptionname>
		<filename>
		<firstname>
		<firstterm>
		<footnote>
		<footnoteref>
		<foreignphrase>
		<function>
		<glossterm>
		<group>
		<guibutton>
		<guiicon>
		<guilabel>
		<guimenu>
		<guimenuitem>
		<guisubmenu>
		<hardware>
		<imageobject>
		<imagedata>
		<indexterm>
		<informalexample>
		<inlineequation>
		<inlinegraphic>
		<inlinemediaobject>
		<interface>
		<interfacename>
		<keycap>
		<keycode>
		<keycombo>
		<keysym>
		<link>
		<literal>
		<manvolnum>
		<markup>
		<medialabel>
		<menuchoice>
		<methodname>
		<modespec>
		<mousebutton>
		<nonterminal>
		<olink>
		<ooclass>
		<ooexception>
		<oointerface>
		<option>
		<optional>
		<orgname>
		<othername>
		<parameter>
		<personname>
		<phrase>
		<postcode>
		<productname>
		<productnumber>
		<prompt>
		<property>
		<quote>
		<refentrytitle>
		<replaceable>
		<remark>
		<returnvalue>
		<sgmltag>
		<sidebar>
		<state>
		<street>
		<structfield>
		<structname>
		<subscript>
		<superscript>
		<surname>
		<symbol>
		<systemitem>
		<token>
		<trademark>
		<type>
		<ulink>
		<userinput>
		<varname>
		<wordasword>
		<xref>
		<year>';
	$self->{options}{'attributes'}.='
		lang';

	$self->treat_options;
}
