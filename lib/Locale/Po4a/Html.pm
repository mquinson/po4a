#!/usr/bin/perl

# Po4a::Html.pm 
# 
# extract and translate translatable strings from a html document.
# 
# This code extracts plain text between html tags and some "alt" attributes 
# (images).
#
# Copyright (c) 2003 by Laurent Hausermann  <laurent@hausermann.org>
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

Locale::Po4a::Html - Convert html documents from/to PO files

=head1 DESCRIPTION

The goal po4a [po for anything] project is to ease translations (and more
interstingly, the maintainance of translation) using gettext tools on areas
where they were not expected like documentation.  

Locale::Po4a::Html is a module to help the translation of documentation in
the HTML format into other [human] languages.

=back

=cut

package Locale::Po4a::Html;
require Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Locale::Po4a::TransTractor);
@EXPORT = qw(new initialize);

use Locale::Po4a::TransTractor;
use Locale::gettext qw(gettext);

use strict;
use warnings;

use HTML::TokeParser;

use File::Temp;

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
    my $stream = HTML::TokeParser->new($filename)
        || die "Couldn't read HTML file $filename : $!";
    
    my @type=();
    NEXT : while (my $token = $stream->get_token) {
        if($token->[0] eq 'T') {
            my $text = trim($token->[1]);
            if (notranslation($text) == 1) {
                $self->pushline( get_tag( $token ) );
                next NEXT;
            }
#  FIXME : it should be useful to encode characters 
#  in UTF8 in the po, but converting them in HTML::Entities
#  in the doc_out, translate acts both way 
#  so we cant do that.
#  use HTML::Entities ();
#  $encoded = HTML::Entities::encode($a);
#  $decoded = HTML::Entities::decode($a);
	    #print STDERR $token->[0];
            $self->pushline( " ".$self->translate($text,
		                                  "FIXME:0",
		                                  (scalar @type ? $type[scalar @type-1]: "NOTYPE")
	                                         )." " );
            next NEXT;
	} elsif ($token->[0] eq 'S') {
	    push @type,$token->[1];
            $self->pushline( get_tag( $token ) );
        } elsif ($token->[0] eq 'E') {
	    pop @type;
            $self->pushline( get_tag( $token ) );
	} else	{ 
            $self->pushline( get_tag( $token ) );
        }       
    }
}

sub get_tag {
    my $token = shift;
    my $tag = "";

    if ($token->[0] eq 'S') {
        $tag = $token->[4];
    }
    if ( ($token->[0] eq 'C') || 
         ($token->[0] eq 'D') ||
         ($token->[0] eq 'T') ) {
        $tag =  $token->[1];
    }
    if ( ($token->[0] eq 'E') || 
         ($token->[0] eq 'PI') ) {
        $tag =  $token->[2];
    }

    return $tag;   
}

sub trim { 
    my $s=shift;
    $s =~ s/\n//g;  # remove \n in text
    $s =~ s/\r//g;  # remove \r in text
    $s =~ s/\t//g;  # remove tabulations
    $s =~ s/^\s+//; # remove leading spaces
    $s =~ s/\s+$//; # remove trailing spaces
    return $s;
} 

#
# This method says if a string must be 
# translated or not.
# To be improved with more test or regexp
# Maybe there is a way to do this in TransTractor
# for example ::^ should not be translated
sub notranslation {
    my $s=shift;
    return 1 if ( ($s cmp "")   == 0);
    return 1 if ( ($s cmp "-")  == 0);
    return 1 if ( ($s cmp "::") == 0);
    return 1 if ( ($s cmp ":")  == 0);
    return 1 if ( ($s cmp ".")  == 0);
    return 1 if ( ($s cmp "|")  == 0);
    return 1 if ( ($s cmp '"')  == 0);
    return 1 if ( ($s cmp "'")  == 0);
    # don't translate entries composed of one entity
    return 1 if ($s =~ /^&[^;]*;$/);
    
    return 0;          
}

=head1 AUTHORS

Laurent Hausermann <laurent@hausermann.org>

=head1 COPYRIGHT AND LICENSE

Laurent Hausermann <laurent@hausermann.org>

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see COPYING file).
