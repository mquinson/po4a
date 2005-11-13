#!/usr/bin/perl -w

# Po4a::Text.pm
# 
# extract and translate translatable strings from a itext documents
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

Locale::Po4a::Text - Convert text documents from/to PO files

=head1 DESCRIPTION

The po4a (po for anything) project goal is to ease translations (and more
interestingly, the maintenance of translations) using gettext tools on
areas where they were not expected like documentation.

Locale::Po4a::Text is a module to help the translation of text documents into
other [human] languages.

Paragraphs are splitted on empty lines (or lines containing only spaces or
tabulations).

If a paragraph contains a line starting by a space (or tabulation), this
paragraph won't be rewrapped.

=head1 OPTIONS ACCEPTED BY THIS MODULE

NONE.

=head1 STATUS OF THIS MODULE

Still to be implemented.

=cut

package Locale::Po4a::Text;

use 5.006;
use strict;
use warnings;

require Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Locale::Po4a::TransTractor);
@EXPORT = qw();

use Locale::Po4a::TransTractor;
use Locale::Po4a::Common;

sub initialize {}

sub parse {
    my $self = shift;
    my ($line,$ref);
    my $paragraph="";
    my $wrapped_mode = 1;
    ($line,$ref)=$self->shiftline();
    while (defined($line)) {
        chomp($line);
        $self->{ref}="$ref";
        if ($line =~ /^\s*$/) {
            # Break paragraphs on lines containing only spaces
            do_paragraph($self,$paragraph,$wrapped_mode);
            $paragraph="";
            $wrapped_mode = 1;
            $self->pushline($line."\n");
        } else {
            if ($line =~ /^\s/) {
                # A line starting by a space indicates a non-wrap
                # paragraph
                $wrapped_mode = 0;
            }
            $paragraph .= $line."\n";
        }
        ($line,$ref)=$self->shiftline();
    }
    if (length $paragraph) {
        do_paragraph($self,$paragraph,$wrapped_mode);
    }
}

sub do_paragraph {
    my ($self, $paragraph, $wrap) = (shift, shift, shift);
    $self->pushline( $self->translate($paragraph,
                                      $self->{ref},
                                      "Plain text",
                                      "wrap" => $wrap) );
}

1;

=head1 AUTHORS

 Nicolas François <nicolas.francois@centraliens.net>

=head1 COPYRIGHT AND LICENSE

 Copyright 2005 by Nicolas FRANÇOIS <nicolas.francois@centraliens.net>.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see the COPYING file).
