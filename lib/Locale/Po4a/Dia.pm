#!/usr/bin/perl

# Po4a::Dia.pm 
# 
# extract and translate translatable strings from Dia diagrams.
# 
# This code extracts plain text from string tags on uncompressed Dia
# diagrams.
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

Locale::Po4a::Dia - Convert uncompressed Dia diagrams from/to PO files

=head1 DESCRIPTION

The goal po4a [po for anything] project is to ease translations (and more
interestingly, the maintenance of translation) using gettext tools on areas
where they were not expected like documentation. 

Locale::Po4a::Dia is a module to help the translation of diagrams in the
uncompressed Dia format into other [human] languages.

You can get Dia (the graphical editor for these diagrams) from:
  http://www.gnome.org/projects/dia/

=head1 TRANSLATING WITH PO4A::DIA

This module only translates uncompressed Dia diagrams.  You can save your
uncompressed diagrams with Dia itself, unchecking the "Compress diagram
files" at the "Save Diagram" dialog.

Another way is to uncompress the dia files from command line with:
  gunzip < original.dia > uncompressed.dia

=head1 STATUS OF THIS MODULE

It Works For Me (tm).  Currently it only searches for translateable strings,
without parsing the xml code around.  It's quite simple, but it works, and
gives a perfect output for valid input files.  It only translates the content
of the E<lt>dia:stringE<gt> tags, but it seems to be all the text present at the
diagrams.

It skips the content of the E<lt>dia:diagramdataE<gt> tag because there are usually
some strings that are for internal use of Dia (not interesting for translation).

Currently it tries to get the diagram encoding from the first line (the xml
declaration), and else it assumes UTF-8, and creates the .po contens in the
ISO-8859-1 character set.  It would be nice if it could read the command line
encoding options, but I haven't watched how to do it.

It uses Locale::Recode from the package libintl to recode the character
sets.  You can get it from http://search.cpan.org/~guido/libintl-perl-1.10/
There may be a better or more standard module to do this, but I didn't know.
You're welcome to improve it.

This module should work, and it shouldn't break anything, but it needs more
testing.

=head1 SEE ALSO

L<po4a(7)>, L<Locale::Po4a::TransTranctor(3pm)>, L<Locale::Po4a::Pod(3pm)>.

=head1 AUTHORS

Jordi Vilalta <jvprat@wanadoo.es>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004 by Jordi Vilalta  <jvprat@wanadoo.es>

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see COPYING file).

=cut

package Locale::Po4a::Dia;

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
use Locale::Recode;

sub initialize {}

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
# Parse file and translate it
#
sub parse_file {
	my ($self,$filename)=@_;
	my ($line,$ref);
	my ($paragraph,$reference); #The text to be translated

	#Initializing the recoding objects
	#	d2p: dia to po
	#	p2d: po to dia
	my ($d2p,$p2d,$charset_dia,$charset_po);

	($line,$ref)=$self->shiftline();
	if (defined($line)) {
		#Try to get the document encoding from the xml header
		if ( $line =~ /<\?xml.*?encoding="(.*)".*\?>/ ) {
			$charset_dia = $1;
		} else {
			#Dia's default is UTF-8
			$charset_dia = 'UTF-8';
			warn gettext("po4a::dia: Couldn't find file encoding. Assuming UTF-8.")."\n";
		}
		#how to get command line options to override it?
		$charset_po = 'ISO-8859-1';

		$d2p = Locale::Recode->new(from => $charset_dia,
					to => $charset_po);
		die $d2p->getError if $d2p->getError;

		$p2d = Locale::Recode->new(from => $charset_po,
					to => $charset_dia);
		die $p2d->getError if $p2d->getError;
	}
	while (defined($line)) {
		#don't translate any string between <dia:diagramdata> tags
		if ( $line =~ /^<dia:diagramdata>(.*)/s ) {
			$line = $1;
			$self->pushline("<dia:diagramdata>");
			while ( $line !~ /<\/dia:diagramdata>/ ) {
				$self->pushline($line);
				($line,$ref)=$self->shiftline();
			}
			$line =~ /(.*?<\/dia:diagramdata>)(.*)/s;
			$self->pushline($1);
			$line = $2;
		} else {
			if ( $line =~ /(.*?)(<dia:diagramdata>.*)/s ) {
				$self->unshiftline($2,$ref);
				$line = $1;
			}
		}

		#if current line has an opening <dia:string> tag, we get
		#all the paragraph to translate (posibly from next lines)
		if ( $line =~ /(.*?)<dia:string>#(.*)/s ) {
			#pushing the text before the tag as is
			$self->pushline($1);

			#save the beginning of the tag contens and its position
			$paragraph = $2;
			$reference = $ref;

			#append the following lines to the paragraph until we
			#find the closing tag
			while ( $paragraph !~ /.*#<\/dia:string>/ ) {
				($line,$ref)=$self->shiftline();
				$paragraph .= $line;
			}
			$paragraph =~ /(.*?)#<\/dia:string>(.*)/s;
			$paragraph = $1;

			#put the text after the closing tag back to the input
			#(there could be more than one string to translate on
			#the same line)
			$self->unshiftline($2,$ref);

			#recode the paragraph to the po character set
			$d2p->recode($paragraph);
			$paragraph = $self->translate($paragraph,$reference,"<dia:string>");
			#recode the translation to the dia character set
			$p2d->recode($paragraph);
			#inserts translation to output
			$self->pushline("<dia:string>#".$paragraph."#</dia:string>");
		} else {
			#doesn't have text to translate: push line as is
			$self->pushline($line);
		}

		#get next line
		($line,$ref)=$self->shiftline();
	}
}
