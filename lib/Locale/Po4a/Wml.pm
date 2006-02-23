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

=head1 OPTIONS ACCEPTED BY THIS MODULE

NONE.

=head1 STATUS OF THIS MODULE

Still to be implemented.

=head1 TODO

Dans le po, faut corriger les references pour pointer sur le fichier de depart, pas le temporaire 

(12:11:26) adn: et pour les # du debut ?
(12:11:57) adn: si y a moyen juste de sortir le pagetitle="foo" en <title>foo</title>, c'est encore mieux
(00:42:51) adn: #use wml::debian::mainpage title="Le systeme d'exploitation universel"

=cut

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
      
      # Mask perl cruft out of XML sight
      while ($file =~ m|^(.*?)<perl>(.*?)</perl>(.*?)$|ms || $file =~ m|^(.*?)<:(.*?):>(.*)$|ms) {
        my ($pre,$in,$post) = ($1,$2,$3);
        $in =~ s/</PO4ALT/g;
        $in =~ s/>/PO4AGT/g;
        $file = "${pre}<!--PO4ABEGINPERL${in}PO4AENDPERL-->$post";
      }

      # Mask mp4h cruft         
      while ($file =~ m|^#(.*)$|<!--PO4ASHARPBEGIN$1PO4ASHARPEND-->|m) {
        my $line = $1;
        print STDERR "PROTECT HEADER: $line\n";
        if ($line =~ m/title="([^"]*)"/) { #) {#"){
          warn "FIXME: We should translate the page title: $1\n";
        }          
      }
                
      # Flush the result to disk          
      open OUTFILE,">$tmp_filename";
      print OUTFILE $file;
      close INFILE;
      close OUTFILE or die "Cannot write $tmp_filename: $!\n";
      
      # Build the XML TransTractor which will do the job for us
      my $xmlizer = Locale::Po4a::Chooser::new("xhtml");
      $xmlizer->{TT}{po_in}=$self->{TT}{po_in};
      $xmlizer->{TT}{po_out}=$self->{TT}{po_out};
      
      # Let it do the job
      $xmlizer->read("$tmp_filename");
      $xmlizer->parse();
      my ($percent,$hit,$queries) = $xmlizer->stats();
      print "We found translations for $percent\%  ($hit from $queries) of strings.\n";
                        
      # Get the output po file back
      $self->{TT}{po_out}=$xmlizer->{TT}{po_out};
      
      # Get the document back (undoing our wml masking)
      $file = join("",@{$xmlizer->{TT}{doc_out}});
      $file =~ s/^<!--PO4ASHARPBEGIN(.*?)PO4ASHARPEND-->/#$1/mg;
      $file =~ s/<!--PO4ABEGINPERL(.*?)PO4AENDPERL-->/<:$1:>/msg;
      $file =~ s/PO4ALT/</msg;
      $file =~ s/PO4AGT/>/msg;

      map { push @{$self->{TT}{doc_out}},"$_\n" } split(/\n/,$file);
    }
    unlink "$tmp_filename";
}

1;

=head1 AUTHORS

This module will be implemented by Martin Quinson (mquinson#debian.org), amonst other (I hope).

=head1 COPYRIGHT AND LICENSE

 Copyright 2005 by SPI, inc.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see the COPYING file).
