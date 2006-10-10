#!/usr/bin/perl -w

# Po4a::Text.pm
# 
# extract and translate translatable strings from a text documents
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

my $bullets = 1;
sub initialize {
    my $self = shift;
    my %options = @_;

    $self->{options}{'nobullets'}='';

    if (defined $options{'nobullets'}) {
        $bullets = 0;
    }
}

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
            $self->pushline("\n") unless (   $wrapped_mode == 0
                                          or $paragraph eq "");
            $paragraph="";
            $wrapped_mode = 1;
            $self->pushline($line."\n");
        } elsif (   $line =~ /^=*$/
                 or $line =~ /^_*$/
                 or $line =~ /^-*$/) {
            $wrapped_mode = 0;
            $paragraph .= $line."\n";
            do_paragraph($self,$paragraph,$wrapped_mode);
            $paragraph="";
            $wrapped_mode = 1;
        } else {
            if ($line =~ /^\s/) {
                # A line starting by a space indicates a non-wrap
                # paragraph
                $wrapped_mode = 0;
            }
            $paragraph .= $line."\n";
        }
        # paragraphs starting by a bullet, or numbered
        # or paragraphs with a line containing many consecutive spaces
        # (more than 3)
        # are considered as verbatim paragraphs
        $wrapped_mode = 0 if (   $paragraph =~ m/^(\*|[0-9]+[.)] )/s
                              or $paragraph =~ m/[ \t][ \t][ \t]/s);
        ($line,$ref)=$self->shiftline();
    }
    if (length $paragraph) {
        do_paragraph($self,$paragraph,$wrapped_mode);
    }
}

sub do_paragraph {
    my ($self, $paragraph, $wrap) = (shift, shift, shift);
    return if ($paragraph eq "");

    if ($bullets) {
        # Detect bullets
        # |        * blah blah
        # |<spaces>  blah
        # |          ^-- aligned
        # <empty line>
        #
        # Other bullets supported:
        # - blah         o blah         + blah
        # 1. blah       1) blah       (1) blah
TEST_BULLET:
        if ($paragraph =~ m/^(\s*)((?:[-*o+]|([0-9]+[.\)])|\([0-9]+\))\s+)([^\n]*\n)(.*)$/s) {
            my $para = $5;
            my $bullet = $2;
            my $indent1 = $1;
            my $indent2 = "$1".(' ' x length $bullet);
            my $text = $4;
            while ($para =~ s/^$indent2(\S[^\n]*\n)//s) {
                $text .= $1;
            }
            # TODO: detect if a line starts with the same bullet
            if ($text !~ m/\S[ \t][ \t][ \t]+\S/s) {
                my $bullet_regex = quotemeta($indent1.$bullet);
                $bullet_regex =~ s/[0-9]+/\\d\+/;
                if ($para eq '' or $para =~ m/^$bullet_regex\S/s) {
                    my $trans = $self->translate($text,
                                                 $self->{ref},
                                                 "Bullet: '$indent1$bullet'",
                                                 "wrap" => 1,
                                                 "wrapcol" => - (length $indent2));
                    $trans =~ s/^/$indent1$bullet/s;
                    $trans =~ s/\n(.)/\n$indent2$1/sg;
                    $self->pushline( $trans."\n" );
                    if ($para eq '') {
                        return;
                    } else {
                        # Another bullet
                        $paragraph = $para;
                        goto TEST_BULLET;
                    }
                }
            }
        }
    }
    # TODO: detect indented paragraphs

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
