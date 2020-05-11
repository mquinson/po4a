#!/usr/bin/perl -w

# Po4a::Wml.pm
#
# extract and translate translatable strings from a WML (web markup language) documents
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

=encoding UTF-8

=head1 NAME

Locale::Po4a::Wml - convert WML (web markup language) documents from/to PO files

=head1 DESCRIPTION

The po4a (PO for anything) project goal is to ease translations (and more
interestingly, the maintenance of translations) using gettext tools on
areas where they were not expected like documentation.

Locale::Po4a::Wml is a module to help the translation of WML documents into
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
"foo@example.org">, which are often defined in the WML.  Improvements
will be added in the future releases.

=cut

package Locale::Po4a::Wml;

use 5.006;
use strict;
use warnings;

require Exporter;
use vars qw(@ISA @EXPORT);
@ISA    = qw(Locale::Po4a::Xhtml);
@EXPORT = qw();

use Locale::Po4a::Common;
use Locale::Po4a::Xhtml;
use File::Temp;

sub initialize {
    my $self    = shift;
    my %options = @_;

    $self->SUPER::initialize(%options);

    print "Call treat_options\n" if $self->{options}{'debug'};
    $self->treat_options;
}

sub read {
    my ( $self, $filename, $refname ) = @_;
    my $tmp_filename;
    ( undef, $tmp_filename ) = File::Temp::tempfile(
        "po4aXXXX",
        DIR    => $ENV{TMPDIR} || "/tmp",
        SUFFIX => ".xml",
        OPEN   => 0,
        UNLINK => 0
    ) or die wrap_msg( gettext("Cannot create a temporary XML file: %s"), $! );
    my $file;
    open FILEIN, "$filename" or die "Cannot read $filename: $!\n";
    {
        $/    = undef;
        $file = <FILEIN>;
    }
    $/ = "\n";

    # Mask perl cruft out of XML sight
    while (( $file =~ m|^(.*?)<perl>(.*?)</perl>(.*?)$|ms )
        or ( $file =~ m|^(.*?)<:(.*?):>(.*)$|ms ) )
    {
        my ( $pre, $in, $post ) = ( $1, $2, $3 );
        $in =~ s/</PO4ALT/g;
        $in =~ s/>/PO4AGT/g;
        $file = "${pre}<!--PO4ABEGINPERL${in}PO4AENDPERL-->$post";
    }

    # Mask mp4h cruft
    while ( $file =~ s|^#(.*)$|<!--PO4ASHARPBEGIN$1PO4ASHARPEND-->|m ) {
        my $line = $1;
        print STDERR "PROTECT HEADER: $line\n"
          if $self->{options}{'debug'};

        # If the wml tag has a title attribute, use a fake
        # <title> xml tag to enable the extraction
        # for translation in the xml parser.
        if ( $line =~ m/title="([^"]*)"/ ) {
            $file = "<title>$1</title>\n" . $file;
        }
    }

    # Validate define-tag tag's argument
    $file =~ s|(<define-tag\s+)([^\s>]+)|$1PO4ADUMMYATTR="$2"|g;

    # Flush the result to disk
    open OUTFILE, ">$tmp_filename";
    print OUTFILE $file;
    close INFILE;
    close OUTFILE or die "Cannot write $tmp_filename: $!\n";

    push @{ $self->{DOCXML}{infile} }, $tmp_filename;
    $self->{DOCWML}{$tmp_filename} = $filename;
    $self->Locale::Po4a::TransTractor::read( $tmp_filename, $refname );
    unlink "$tmp_filename";
}

sub parse {
    my $self = shift;

    foreach my $filename ( @{ $self->{DOCXML}{infile} } ) {
        $self->Locale::Po4a::Xml::parse_file($filename);
        my $org_filename = $self->{DOCWML}{$filename};

        # Fix the references
        foreach my $msgid ( keys %{ $self->{TT}{po_out}{po} } ) {
            $self->{TT}{po_out}{po}{$msgid}{'reference'} =~ s|$filename(:\d+)|$org_filename$1|o;
        }

        # Get the document back (undoing our WML masking)
        # FIXME: need to join the file first, and then split?
        my @doc_out;
        my $cnt = 0;
        my $title_node;
        my $title;

        foreach my $line ( @{ $self->{TT}{doc_out} } ) {
            if ( !$cnt ) {
                if ( !$title_node && $line =~ m/<title>/ ) {
                    $title_node = $line;
                } elsif ($title_node) {
                    $title_node .= $line;
                    if ( $title_node =~ m/<title>(.*?)<\/title>/ ) {
                        $title = $1;
                        $cnt   = 1;
                    }
                } else {
                    $cnt = 1;
                }
            } else {
                if ( $line =~ s/^<!--PO4ASHARPBEGIN(.*?)PO4ASHARPEND-->/#$1/mg && $title ) {
                    $line =~ s/title="[^"]*"$/title="$title"/mg;
                }
                $line =~ s/<!--PO4ABEGINPERL(.*?)PO4AENDPERL-->/<:$1:>/sg;
                $line =~ s/(<define-tag\s+)PO4ADUMMYATTR="([^"]*)"/$1$2/g;
                $line =~ s/PO4ALT/</sg;
                $line =~ s/PO4AGT/>/sg;
                push @doc_out, $line;
            }
        }

        # Do a simple left trim
        foreach my $line (@doc_out) {
            if ( $line =~ m/\s+/ ) {
                shift @doc_out;
            } else {
                last;
            }
        }

        $self->{TT}{doc_out} = \@doc_out;
    }
}

1;

=head1 AUTHORS

 Martin Quinson (mquinson#debian.org)
 Noriada Kobayashi <nori1@dolphin.c.u-tokyo.ac.jp>

=head1 COPYRIGHT AND LICENSE

 Copyright © 2005 SPI, Inc.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see the COPYING file).
