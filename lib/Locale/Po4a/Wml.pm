#!/usr/bin/perl -w

# Po4a::Wml.pm
# 
# extract and translate translatable strings from a wml (web markup language) documents
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

Locale::Po4a::Wml - Convert wml (web markup language) documents from/to PO files

=head1 DESCRIPTION

The po4a (po for anything) project goal is to ease translations (and more
interestingly, the maintenance of translations) using gettext tools on
areas where they were not expected like documentation.

Locale::Po4a::Wml is a module to help the translation of wml documents into
other [human] languages. Do not mixup the WML we are speaking about here
(web markup language) and the WAP crap used on cell phones.

Please note that this module relies upon the Locale::Po4a::Xhtml
module, which also relies upon the Locale::Po4a::Xml module.  This
means that all tags for web page expressions are assumed to be written
in the XHTML syntax.

=head1 OPTIONS ACCEPTED BY THIS MODULE

NONE.

=head1 STATUS OF THIS MODULE

This module works for some simple documents, but is still young.
Currently, the biggest issue of the module is probably that it cannot
handle documents that contain non-XML inline tags such as <email
"foo@example.org">, which are often defined in the Wml.  Improvements
will be added in the future releases.

=cut
#
#=head1 TODO
# (translation from an IRC session)
#(12:11:26) adn: What about the # at the beginning?
#(12:11:57) adn: If there is a way to just extract the pagetitle="foo" into a <title>foo</title>, that would be even better.
#(00:42:51) adn: #use wml::debian::mainpage title="The universal operating system"

package Locale::Po4a::Wml;

use 5.006;
use strict;
use warnings;

require Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Locale::Po4a::TransTractor);
@EXPORT = qw();

use Locale::Po4a::TransTractor;
use Locale::Po4a::Common;
use File::Temp;

sub initialize {}

sub read {
    my ($self,$filename)=@_;
    
    push @{$self->{DOCWML}{infile}}, $filename;
}
    

sub parse {
    my $self = shift;

    my $tmp_filename;
    (undef,$tmp_filename)=File::Temp->tempfile("po4aXXXX",
                                                DIR    => "/tmp",
					        SUFFIX => ".xml",
                                                OPEN   => 0,
						UNLINK => 0)
        or die wrap_msg(gettext("Can't create a temporary xml file: %s"), $!);
    foreach my $filename (@{$self->{DOCWML}{infile}}) {
#      print STDERR "TMP: $tmp_filename\n";
      my $file;
      open FILEIN,"$filename" or die "Cannot read $filename: $!\n";
      {
        $/ = undef; 
        $file=<FILEIN>;
      }
      $/ = "\n"; 
      
      # Mask perl cruft out of XML sight
      while ($file =~ m|^(.*?)<perl>(.*?)</perl>(.*?)$|ms || $file =~ m|^(.*?)<:(.*?):>(.*)$|ms) {
        my ($pre,$in,$post) = ($1,$2,$3);
        $in =~ s/</PO4ALT/g;
        $in =~ s/>/PO4AGT/g;
        $file = "${pre}<!--PO4ABEGINPERL${in}PO4AENDPERL-->$post";
      }

      # Mask mp4h cruft         
      while ($file =~ s|^#(.*)$|<!--PO4ASHARPBEGIN$1PO4ASHARPEND-->|m) {
        my $line = $1;
        print STDERR "PROTECT HEADER: $line\n"
          if $self->debug();
        if ($line =~ m/title="([^"]*)"/) { #) {#"){
          warn "FIXME: We should translate the page title: $1\n";
        }          
      }

      # Validate define-tag tag's argument
      $file =~ s|(<define-tag\s+)([^\s>]+)|$1PO4ADUMMYATTR="$2"|g;
                
      # Flush the result to disk          
      open OUTFILE,">$tmp_filename";
      print OUTFILE $file;
      close INFILE;
      close OUTFILE or die "Cannot write $tmp_filename: $!\n";
      
      # Build the XML TransTractor which will do the job for us
      # FIXME: This is a hack. Wml should inherit from Xhtml if this is
      # FIXME: needed.
      my $xmlizer = Locale::Po4a::Chooser::new("xhtml");
      # FIXME: There might be more TT properties to be copied
      $xmlizer->{TT}{'file_in_charset'}=$self->{TT}{'file_in_charset'};
      $xmlizer->{TT}{'file_in_encoder'}=$self->{TT}{'file_in_encoder'};
      $xmlizer->{TT}{po_in}=$self->{TT}{po_in};
      $xmlizer->{TT}{po_out}=$self->{TT}{po_out};
      
      # Let it do the job
      $xmlizer->read("$tmp_filename");
      $xmlizer->parse();
      my ($percent,$hit,$queries) = $xmlizer->stats();
      print "We found translations for $percent\%  ($hit from $queries) of strings.\n";
                        
      # Get the output po file back
      $self->{TT}{po_out}=$xmlizer->{TT}{po_out};
      foreach my $msgid (keys %{$self->{TT}{po_out}{po}}) {
        $self->{TT}{po_out}{po}{$msgid}{'reference'} =~
           s|$tmp_filename(:\d+)|$filename$1|o;
      }
      
      # Get the document back (undoing our wml masking)
      $file = join("",@{$xmlizer->{TT}{doc_out}});
      $file =~ s/^<!--PO4ASHARPBEGIN(.*?)PO4ASHARPEND-->/#$1/mg;
      $file =~ s/<!--PO4ABEGINPERL(.*?)PO4AENDPERL-->/<:$1:>/msg;
      $file =~ s|(<define-tag\s+)PO4ADUMMYATTR="([^"]*)"|$1$2|g;
      $file =~ s/PO4ALT/</msg;
      $file =~ s/PO4AGT/>/msg;

      map { push @{$self->{TT}{doc_out}},"$_\n" } split(/\n/,$file);
    }
    unlink "$tmp_filename";
}

1;

=head1 AUTHORS

 Martin Quinson (mquinson#debian.org)
 Noriada Kobayashi <nori1@dolphin.c.u-tokyo.ac.jp>

=head1 COPYRIGHT AND LICENSE

 Copyright 2005 by SPI, inc.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see the COPYING file).
