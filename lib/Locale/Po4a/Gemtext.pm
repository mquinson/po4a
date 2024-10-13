#!/usr/bin/env perl -w

# Po4a::Gemtext.pm
#
# extract and translate translatable strings from a Gemtext documents
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

package Locale::Po4a::Gemtext;

use 5.006;
use strict;
use warnings;

use parent qw(Locale::Po4a::TransTractor);

require Exporter;

use vars qw(@EXPORT @AUTOLOAD);
@EXPORT = qw();

use Locale::Po4a::Common;

=encoding UTF-8

=head1 NAME

Locale::Po4a::Gemtext - convert Gemtext documents from/to PO files.

=head1 DESCRIPTION

The po4a (PO for anything) project goal is to ease translations (and more
interestingly, the maintenance of translations) using gettext tools on
areas where they were not expected like documentation.

Locale::Po4a::Gemtext is a module to help the translation of Gemtext documents into
other [human] languages.

=cut

sub initialize { }

sub parse {
    my $self = shift;

    my ( $line, $ref ) = $self->shiftline();

    while ( defined($line) ) {
        chomp($line);

             $self->parse_heading( $line, $ref )
          or $self->parse_preformatted_text( $line, $ref )
          or $self->parse_list( $line, $ref )
          or $self->parse_quote( $line, $ref )
          or $self->parse_link( $line, $ref )
          or $self->pushline( $self->translate( $line, $ref, "paragraph" ) . "\n" );

        ( $line, $ref ) = $self->shiftline();
    }
}

sub parse_heading() {
    my $self = shift;
    my $line = shift;
    my $ref  = shift;

    $line =~ m/^(#{1,3}) *(.+)/ or return;
    my $level   = $1;
    my $content = $2;

    $self->pushline( "$level " . $self->translate( $content, $ref, "heading $level" ) . "\n" );

    return 1;
}

sub parse_preformatted_text() {
    my $self = shift;
    my $line = shift;
    my $ref  = shift;

    $line =~ m/^(``` *)(.*)/ or return;
    my $prefix  = $1;
    my $content = $2;

    my $toggle_line = $prefix;
    $toggle_line .= $self->translate( $content, $ref, "alt text" ) if $content;
    $self->pushline("$toggle_line\n");

    my $paragraph;
    ( $line, $ref ) = $self->shiftline();

    while ( defined($line) ) {
        chomp($line);

        if ( $line =~ m/^```/ ) {
            $self->pushline( $self->translate( $paragraph, $ref, "preformatted text" ) . "\n" );
            $self->pushline("$line\n");

            return 1;
        }

        if ($paragraph) {
            $paragraph .= "\n$line";
        } else {
            $paragraph = $line;
        }

        ( $line, $ref ) = $self->shiftline();
    }
}

sub parse_list() {
    my $self = shift;
    my $line = shift;
    my $ref  = shift;

    $line =~ m/^\* (.+)/ or return;
    my $content = $1;

    $self->pushline( "* " . $self->translate( $content, $ref, "list" ) . "\n" );

    return 1;
}

sub parse_quote() {
    my $self = shift;
    my $line = shift;
    my $ref  = shift;

    $line =~ m/^(> *)(.+)/ or return;
    my $prefix  = $1;
    my $content = $2;

    $self->pushline( $prefix . $self->translate( $content, $ref, "quote" ) . "\n" );

    return 1;
}

sub parse_link() {
    my $self = shift;
    my $line = shift;
    my $ref  = shift;

    $line =~ m/^(=>[ \t]+[^ \t]+)(?:([ \t]+)(.*))?/ or return;
    my $prefix    = $1;
    my $separator = $2;
    my $content   = $3;

    my $result = $prefix;
    $result .= $separator . $self->translate( $content, $ref, "link" )
      if $content;
    $self->pushline( $result . "\n" );

    return 1;
}

1;

=head1 STATUS OF THIS MODULE

Tested successfully on simple Gemtext files, such as the official Gemtext documentation.

=head1 SEE ALSO

L<Locale::Po4a::TransTractor(3pm)>, L<po4a(7)|po4a.7>

=head1 AUTHORS

 gemmaro <gemmaro.dev@gmail.com>

=head1 COPYRIGHT AND LICENSE

 Copyright © 2024 gemmaro <gemmaro.dev@gmail.com>.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL v2.0 or later (see the COPYING file).

=cut
