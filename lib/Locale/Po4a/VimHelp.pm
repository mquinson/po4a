#!/usr/bin/env perl -w

# Po4a::VimHelp.pm
#
# extract and translate translatable strings from a Vim help files
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

package Locale::Po4a::VimHelp;

use 5.006;
use strict;
use warnings;

use parent qw(Locale::Po4a::TransTractor);

sub initialize {
    my ( $self, %options ) = @_;
    $self->{debug} = $options{debug};
    return;
}

sub parse {
    my $self = shift;

    $self->translate_firstline();

    my ( $line, $ref ) = $self->shiftline();

    while ( defined($line) ) {
        chomp $line;

             $self->skip_separator($line)
          or $self->translate_ordered( $line, $ref )
          or $self->translate_columnheading( $line, $ref )
          or $self->skip_tags($line)
          or $self->skip_modeline($line)
          or $self->skip_blank($line)
          or $self->translate_codeblock_with_start_line($line)
          or $self->translate_singleline( $line, $ref )
          or $self->translate_paragraph( $line, $ref )
          or die "unexpected pattern";

        ( $line, $ref ) = $self->shiftline();
    }
}

sub translate_firstline {
    my $self = shift;

    my ( $line, $ref ) = $self->shiftline();
    chomp $line;
    $line =~ / \A ([*] [^*]+ [*] \s+) (.*) /xms or die "no first line";
    my $pre         = $1;
    my $description = $2;

    $description = $self->translate( $description, $ref, "description" );
    $self->pushline("$pre$description\n");

    return;
}

sub skip_separator {
    my ( $self, $line ) = @_;

    is_separator($line) or return;
    $self->pushline("$line\n");
    return 1;
}

sub is_separator {
    return shift =~ / \A \s* ([=]+ | [-]+) \Z /xms;
}

sub translate_ordered {
    my ( $self, $line, $ref ) = @_;

    my $pre;
    ( $pre, $line ) = is_ordered($line);
    $pre or return;
    $self->pushline($pre);
    return (
             $self->translate_singleline( $line, $ref, "ordered" )
          or $self->translate_paragraph( $line, $ref, "ordered" )
    );
}

sub is_ordered {
    my $line = shift;

    if ( $line =~ / \A ((?: \d{1,2} [.] )+ [ ]) (\S .+) \Z /xms ) {
        my $pre     = $1;
        my $content = $2;

        return ( $pre, $content );
    } elsif (
        $line =~ m{ \A
                    ((?: \d{1,2} [.] )+ [ ]+)
                    (\S .+? (?: \s+ [|] [^|]+ [|] | (?: \s+ [*] [^*]+ [*] )+))
                    \Z }xms
      )
    {
        my $pre     = $1;
        my $content = $2;

        return ( $pre, $content );
    }

    return;
}

sub translate_columnheading {
    my ( $self, $line, $ref ) = @_;

    my ( $content, $suffix ) = is_columnheading($line) or return;
    my $following_ref;
    ( $line, $following_ref ) = $self->shiftline();
    while ( defined $line ) {
        chomp $line;
        my ($following_content) = is_columnheading($line);
        if ($following_content) {
            $content .= "\n$following_content";
        } else {
            $self->unshiftline( "$line\n", $following_ref );
            last;
        }
        ( $line, $following_ref ) = $self->shiftline();
    }

    $content = $self->translate( $content, $ref, "column heading" );
    $content =~ s/ $ /$suffix/xmsg;
    $self->pushline("$content\n");

    return 1;
}

sub is_columnheading {
    my $line = shift;

    $line =~ / \A (.+?) (\s* [~]) \Z /xms or return;
    my $content = $1;
    my $suffix  = $2;

    return ( $content, $suffix );
}

sub skip_tags {
    my ( $self, $line ) = @_;

    my $result = is_tags($line) or return;
    $self->pushline("$line\n");
    $result->{codeblock} and $self->translate_codeblock();
    return 1;
}

sub is_tags {
    my $line = shift;

    $line =~ / \A \s* [*] [^*]+ [*] (?: \s+ [*] [^*]+ [*] )* (\s+ [>])? \Z /xms or return;
    my $codeblock = $1;

    return { codeblock => $codeblock };
}

sub skip_modeline {
    my ( $self, $line ) = @_;

    $line =~ / \A \s* vim: /xms or return;

    $self->pushline("$line\n");

    return 1;
}

sub translate_codeblock_with_start_line {
    my ( $self, $line ) = @_;

    is_codeblock_start_line($line) or return;
    $self->pushline("$line\n");
    $self->translate_codeblock();
    return 1;
}

sub is_codeblock_start_line {
    return shift =~ / \A [>] \Z /xms;
}

sub translate_singleline {
    my ( $self, $line, $ref, $type ) = @_;

    $type //= "paragraph";

    $line =~ m{ \A
                (\s*)
                (.+?)
                ((?: \s+ [*] [^*]+ [*] )* | \s+ [|] [^|]+ [|])
                (\s+ [>])?
                \Z }xms or return;
    my $pre       = $1;
    my $content   = $2;
    my $tags      = $3;
    my $codeblock = $4;

    if ($codeblock) {
        $content = $self->translate( $content, $ref, $type );
        $self->pushline("$pre$content$tags$codeblock\n");
        $self->translate_codeblock();
        return 1;
    }

    my $following_ref;
    ( $line, $following_ref ) = $self->shiftline();
    $self->unshiftline( $line, $following_ref );
    paragraph_breakable($line) or return;

    $content = $self->translate( $content, $ref, $type );
    $self->pushline("$pre$content$tags\n");
    return 1;
}

sub translate_paragraph {
    my ( $self, $line, $initial_ref, $type ) = @_;

    $type //= "paragraph";

    $line =~ / \A (.*?) (\s+ [>])? \Z /xms or return;
    my $content   = $1;
    my $codeblock = $2 // "";

    if ($codeblock) {
        $content = $self->translate( $content, $initial_ref, $type );
        $self->pushline("$content$codeblock\n");
        $self->translate_codeblock();
        return 1;
    }

    my @content = $content;

    my $ref;
    ( $line, $ref ) = $self->shiftline();

    while ( defined $line ) {
        chomp $line;

        if ( paragraph_breakable($line) ) {
            $self->unshiftline( $line, $ref );
            last;
        }

        $line =~ / \A (.*?) (\s+ [>])? \Z /xms or die "unreachable";
        my $following_content = $1;
        $codeblock = $2 // "";

        push @content, $following_content;
        $codeblock and last;

        ( $line, $ref ) = $self->shiftline();
    }

    $content = $self->translate_indented( \@content, $initial_ref, $type );
    $self->pushline("$content$codeblock\n");
    $codeblock and $self->translate_codeblock();

    return 1;
}

sub paragraph_breakable {
    my $line = shift;
    return
         is_blank($line)
      || is_separator($line)
      || is_codeblock_start_line($line)
      || is_ordered($line);
}

sub translate_codeblock {
    my ($self) = @_;

    my ( $line, $ref ) = $self->shiftline();
    while ( defined $line ) {
        chomp $line;
        is_blank($line) or last;
        $self->pushline("$line\n");
        ( $line, $ref ) = $self->shiftline();
    }
    my $initial_ref = $ref;

    my @content;
    while ( defined $line ) {
        chomp $line;

        if ( $line =~ / \A ([<]) (.*) /xms ) {
            my $end = $1;
            $line = $2;

            if (@content) {
                my $content = $self->translate_indented( \@content, $initial_ref, "codeblock" );
                $self->pushline("$content\n$end");
            } else {
                $self->pushline($end);
            }
            $self->unshiftline( $line, $ref );
            last;

        } elsif ( $line =~ / \A \S /xms ) {
            if (@content) {
                my $content = $self->translate_indented( \@content, $initial_ref, "codeblock" );
                $self->pushline("$content\n");
            }
            $self->unshiftline( $line, $ref );
            last;

        } else {
            push @content, $line;
        }

        ( $line, $ref ) = $self->shiftline();
    }

    return;
}

sub translate_indented {
    my ( $self, $content, $ref, $type ) = @_;

    my $indent    = 0;
    my $firstline = shift @{$content};
    for my $char_index ( 0 .. length($firstline) - 1 ) {
        my $char = substr( $firstline, $char_index, 1 ) or last;
        $char =~ / \s /xms or last;
        my $common = 1;
        for my $line ( @{$content} ) {
            substr( $line, $char_index, 1 ) eq $char and next;
            undef $common;
            last;
        }
        $common or last;
        $indent += 1;
    }

    my $prefix = substr( $firstline, 0, $indent );
    unshift @{$content}, $firstline;
    @{$content} = map { substr( $_, $indent ) } @{$content};
    my $translation = $self->translate( join( "\n", @{$content} ), $ref, $type );
    $translation =~ s/ ^ /$prefix/xmsg;
    return $translation;
}

sub skip_blank {
    my ( $self, $line ) = @_;

    is_blank($line) or return;
    $self->pushline("$line\n");

    return 1;
}

sub is_blank {
    my $line = shift;

    return !defined($line) || $line =~ / \A \s* \Z /xms;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Locale::Po4a::VimHelp - convert Vim help files from/to PO files.

=head1 DESCRIPTION

The po4a (PO for anything) project goal is to ease translations (and
more interestingly, the maintenance of translations) using gettext
tools on areas where they were not expected like documentation.

C<Locale::Po4a::VimHelp> is a module to help the translation of Vim
help file.  See also L<Writing help
files|https://vimhelp.org/helphelp.txt.html#help-writing> for its
syntax.

=head1 CONFIGURATION

TODO

=head1 STATUS OF THIS MODULE

This module is in an early stage of development.  It has been
successfully tested on simple files like C<helphelp.txt>.  However, it
has not yet been tested on full help files, and the way it parses them
may change for fixes and improvements, especially paragraph wrapping.

=head1 SEE ALSO

L<Locale::Po4a::TransTractor(3pm)>, L<po4a(7)|po4a.7>

=head1 AUTHORS

 gemmaro <gemmaro.dev@gmail.com>

=head1 COPYRIGHT AND LICENSE

 Copyright © 2024 gemmaro.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL v2.0 or later (see the F<COPYING> file).
