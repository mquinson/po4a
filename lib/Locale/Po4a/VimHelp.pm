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
          or $self->translate_columnheading( $line, $ref )
          or $self->skip_tags($line)
          or $self->skip_modeline($line)
          or $self->skip_blank($line)
          or $self->translate_codeblock_with_start_line($line)
          or $self->translate_paragraph( $line, $ref );

        ( $line, $ref ) = $self->shiftline();
    }
}

sub translate_firstline {
    my $self = shift;

    my ( $line, $ref ) = $self->shiftline();
    chomp $line;
    $line =~ / \A ([*] [^*]+ [*] \s+) (.*) /xms or warn "no first line";
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

sub translate_columnheading {
    my ( $self, $line, $ref ) = @_;

    my ( $content, $suffix ) = is_columnheading($line) or return;
    my $following_ref;
    ( $line, $following_ref ) = $self->shiftline();

    while ( defined $line ) {
        chomp $line;
        my ($following_content) = is_columnheading($line);

        if ( !$following_content ) {
            $self->unshiftline( "$line\n", $following_ref );
            last;
        }

        $content .= "\n$following_content";
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

    $line =~ / \A \s* [*] [^*]+ [*] (?: \s+ [*] [^*]+ [*] )* (\s+ [>] (vim)?)? \Z /xms or return;
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
    return shift =~ / \A [>] (vim)? \Z /xms;
}

sub translate_paragraph {
    my ( $self, $line, $initial_ref, $type ) = @_;

    $type //= "paragraph";
    my ( $content, $codeblock ) = parse_paragraph_line($line);

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

        my $following_content;
        ( $following_content, $codeblock ) = parse_paragraph_line($line);
        push @content, $following_content;
        $codeblock and last;

        ( $line, $ref ) = $self->shiftline();
    }

    $content = $self->translate_indented( \@content, $initial_ref, $type );
    $self->pushline("$content$codeblock\n");
    $codeblock and $self->translate_codeblock();

    return 1;
}

sub parse_paragraph_line {
    my $line = shift;

    $line =~ / \A (.*?) (\s+ [>] (vim)?)? \Z /xms or die "unreachable";
    my $content   = $1;
    my $codeblock = $2;

    return ( $content, $codeblock // "" );
}

sub paragraph_breakable {
    my $line = shift;
    return
         is_blank($line)
      || is_separator($line)
      || is_codeblock_start_line($line);
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
        $initial_ref //= $ref;

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

        } elsif ( is_blank($line) ) {
            if (@content) {
                my $content = $self->translate_indented( \@content, $initial_ref, "codeblock" );
                $self->pushline("$content\n");
                undef @content;
                undef $initial_ref;
            }
            $self->pushline("$line\n");

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
        $char =~ / \s /xms                              or last;
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

    return !$line || $line =~ / \A \s* \Z /xms;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Locale::Po4a::VimHelp - convert Vim help files from/to PO files

=head1 DESCRIPTION

The po4a (PO for anything) project goal is to ease translations (and
more interestingly, the maintenance of translations) using gettext
tools on areas where they were not expected like documentation.

C<Locale::Po4a::VimHelp> is a module to help the translation of Vim
help file.  See also L<Writing help
files|https://vimhelp.org/helphelp.txt.html#help-writing> for its
syntax.

=head1 STATUS OF THIS MODULE

This module is in an early stage of development.  It has been
successfully tested on simple files like C<helphelp.txt>.  However, it
has not yet been tested on full help files, and the way it parses them
may change for fixes and improvements, especially paragraph wrapping.

=head1 DEVELOPING

Parsing Vim help files for po4a is difficult.  Here are some obstacles
while developing this module.  If you have a better idea, feel free to
suggest a patch (with additional test cases).

=over

=item C<1. foo> sounds like an ordered list

Not necessarily.  Consider the following paragraph:

 There are 2 wandering tanukis, not
 1. He's using his cloning technique.

For the same reason, what appears to be a heading (e.g. C<1.1 bar>) or
an unordered list (e.g. C<o baz>) cannot be detected.

=item Flushed right tags should be excluded from translation target

This topic is also difficult since it relates to language differences
in localization.

Consider the following example

 Such a common and short concept in some languages *tags*

which might be translated to

 They are unfamiliar, there are no corresponding concepts and *tags*
 it takes a longer sentence to express them in this language

When this happens, you have to decide at what point you want to add a
tag I<nicely>.  This shouldn't be easy.  The Vim help file is in a
hard wrapped format, even for parts that are not code blocks.

The same applies to tag references such as C<|ref|>.

=item Leveraging C<--wrapcol> to monitor text widths

Using the C<--wrapcol> option to issue warnings when text width exceeds
specified limits seems like a reasonable approach.  The official Vim help
files feature a mode line, such as C<vim:tw=78:ts=8:noet:ft=help:norl:>, as
seen in
L<C<runtime/doc/if_perl.txt>|https://github.com/vim/vim/blob/04cc8975930b7b2c5d6753d3eddf57dab2816518/runtime/doc/if_perl.txt#L307>.
However, there are a few challenges to consider:

=over

=item File Parsing Behavior

If this option is implemented, it would be ideal to read the entire file
first, detect whether the mode line exists, and determine which sections are
affected.  Unfortunately, the progressive parsing mechanism is not employed in
this case.

=item Default vs. Custom Values

The generic default value of C<--wrapcol> is 76, whereas Vim help files
commonly use 78.  In most cases, the value in the options passed to this
module defaults to 76, but it is unclear whether this value was explicitly set
or implicitly applied.

=back

=back

=head1 SEE ALSO

L<Locale::Po4a::TransTractor(3pm)>, L<po4a(7)|po4a.7>

=head1 AUTHORS

 gemmaro <gemmaro.dev@gmail.com>

=head1 COPYRIGHT AND LICENSE

 Copyright © 2024, 2025 gemmaro.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL v2.0 or later (see the F<COPYING> file).
