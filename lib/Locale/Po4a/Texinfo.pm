#!/usr/bin/perl -w

# Copyright (c) 2004, 2005 by Nicolas FRANÇOIS <nicolas.francois@centraliens.net>
#
# This file is part of po4a.
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
# along with Foobar; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
########################################################################

=head1 NAME

Locale::Po4a::Texinfo - Convert Texinfo documents and derivates from/to PO files

=head1 DESCRIPTION

The po4a (po for anything) project goal is to ease translations (and more
interestingly, the maintenance of translations) using gettext tools on
areas where they were not expected like documentation.

Locale::Po4a::Texinfo is a module to help the translation of Texinfo documents into
other [human] languages.

This module contains the definitions of common Texinfo commands and
environments.

=head1 STATUS OF THIS MODULE

This module is still beta.
Please send feedback and feature requests.

=head1 SEE ALSO

L<po4a(7)|po4a.7>,
L<Locale::Po4a::TransTractor(3pm)|Locale::Po4a::TransTractor>,
L<Locale::Po4a::TeX(3pm)|Locale::Po4a::TeX>.

=head1 AUTHORS

 Nicolas François <nicolas.francois@centraliens.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, 2005 by Nicolas FRANÇOIS <nicolas.francois@centraliens.net>.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see COPYING file).

=cut

package Locale::Po4a::Texinfo;

use 5.006;
use strict;
use warnings;

require Exporter;
use vars qw($VERSION @ISA @EXPORT);
$VERSION= $Locale::Po4a::TeX::VERSION;
@ISA= qw(Locale::Po4a::TeX);
@EXPORT= qw();

use Locale::Po4a::Common;
use Locale::Po4a::TeX;
use subs qw(&untranslated     &translate_joined
            &parse_definition_file
            &register_generic_command &is_closed &translate_buffer
            &register_verbatim_environment
            &generic_command
            &in_verbatim);
*untranslated                  = \&Locale::Po4a::TeX::untranslated;
*translate_joined              = \&Locale::Po4a::TeX::translate_joined;
*parse_definition_file         = \&Locale::Po4a::TeX::parse_definition_file;
*register_generic_command      = \&Locale::Po4a::TeX::register_generic_command;
*register_verbatim_environment = \&Locale::Po4a::TeX::register_verbatim_environment;
*generic_command               = \&Locale::Po4a::TeX::generic_command;
*is_closed                     = \&Locale::Po4a::TeX::is_closed;
*in_verbatim                   = \&Locale::Po4a::TeX::in_verbatim;
*translate_buffer              = \&Locale::Po4a::TeX::translate_buffer;
use vars qw($RE_ESCAPE            $ESCAPE
            $RE_VERBATIM
            $RE_COMMENT           $RE_PRE_COMMENT
            $no_wrap_environments $separated_commands
            %commands             %environments
            %command_categories   %separated
            %env_separators       %debug
            @exclude_include      @comments);
*RE_ESCAPE             = \$Locale::Po4a::TeX::RE_ESCAPE;
*ESCAPE                = \$Locale::Po4a::TeX::ESCAPE;
*RE_VERBATIM           = \$Locale::Po4a::TeX::RE_VERBATIM;
*RE_COMMENT            = \$Locale::Po4a::TeX::RE_COMMENT;
*RE_PRE_COMMENT        = \$Locale::Po4a::TeX::RE_PRE_COMMENT;
*no_wrap_environments  = \$Locale::Po4a::TeX::no_wrap_environments;
*separated_commands    = \$Locale::Po4a::TeX::separated_commands;
*commands              = \%Locale::Po4a::TeX::commands;
*environments          = \%Locale::Po4a::TeX::environments;
*command_categories    = \%Locale::Po4a::TeX::command_categories;
*separated             = \%Locale::Po4a::TeX::separated;
*env_separators        = \%Locale::Po4a::TeX::env_separators;
*debug                 = \%Locale::Po4a::TeX::debug;
*exclude_include       = \@Locale::Po4a::TeX::exclude_include;
*comments              = \@Locale::Po4a::TeX::comments;

$ESCAPE = "\@";
$RE_ESCAPE = "\@";
$RE_VERBATIM = "\@example";
$RE_COMMENT = "\\\@(?:c|comment)\\b";
register_verbatim_environment("example");

my %break_line = ();

sub docheader {
    return "\@c This file was generated with po4a. Translate the source file.\n".
           "\@c\n";
}

sub parse {
    my $self = shift;
    my ($line,$ref);
    my $paragraph = ""; # Buffer where we put the paragraph while building
    my @env = (); # environment stack
    my $t = "";

  LINE:
    undef $self->{type};
    ($line,$ref)=$self->shiftline();

    while (defined($line)) {
        chomp($line);
        $self->{ref}="$ref";

        if ($line =~ /^\s*@\s*po4a\s*:/) {
            parse_definition_line($self, $line);
            goto LINE;
        }

        my $closed = 1;
        if (!in_verbatim(@env)) {
            $closed = is_closed($paragraph);
        }
#        if (not $closed) {
#            print "not closed. line: '$line'\n            para: '$paragraph'\n";
#        }

        if ($closed and $line =~ /^\s*$/) {
            # An empty line. This indicates the end of the current
            # paragraph.
            $paragraph .= $line."\n";
            if (length($paragraph)) {
                ($t, @env) = translate_buffer($self,$paragraph,@env);
                $self->pushline($t);
                $paragraph="";
            }
        } elsif ($line =~ m/^$RE_COMMENT/) {
            $self->pushline($line."\n");
        } elsif (    $closed
                 and ($line =~ /^@([^ ]*?)(?: +(.*))?$/)
                 and (defined $commands{$1})
                 and ($break_line{$1})) {
            if (length($paragraph)) {
                ($t, @env) = translate_buffer($self,$paragraph,@env);
                $self->pushline($t);
                $paragraph="";
            }
            my $arg = $2;
            my @args = ();
            if (defined $arg and length $arg) {
                # FIXME: keep the spaces ?
                $arg =~ s/\s*$//s;
                @args= (" ", $arg);
            }
            ($t, @env) = &{$commands{$1}}($self, $1, "", \@args, \@env);
            $self->pushline($t."\n");
        } else {
            # continue the same paragraph
            $paragraph .= $line."\n";
        }

        # Reinit the loop
        ($line,$ref)=$self->shiftline();
        undef $self->{type};
    }

    if (length($paragraph)) {
        ($t, @env) = translate_buffer($self,$paragraph,@env);
        $self->pushline($t);
        $paragraph="";
    }
} # end of parse

sub line_command {
    my $self = shift;
    my ($command,$variant,$args,$env) = (shift,shift,shift,shift);
    print "line_command($command,$variant,@$args,@$env)="
        if ($debug{'commands'});

    my $translated = $ESCAPE.$command;
    my $line = $args->[1];
    if (defined $line and length $line) {
        $translated .= " ".$self->translate($line, $self->{ref},
                                            $command,
                                            "wrap" => 0);
    }
    print "($translated,@$env)\n"
        if ($debug{'commands'});
    return ($translated,@$env);
}

foreach (qw(c appendix section cindex pindex vindex comment subsection
            subsubsection refill top item chapter settitle setfilename
            title author bye deffnx defvrx sp summarycontents contents item)) {
    $commands{$_} = \&line_command;
    $break_line{$_} = 1;
}

register_generic_command("*node,");
$break_line{'node'} = 1;
$commands{'node'} = sub {
    my $self = shift;
    my ($command,$variant,$args,$env) = (shift,shift,shift,shift);
    print "node($command,$variant,@$args,@$env)="
        if ($debug{'commands'});

    my $translated = $ESCAPE.$command;
    my $line = $args->[1];
    if (defined $line and length $line) {
        my @pointers = split (/, */, $line);
        my @t;
        foreach (@pointers) {
           push @t, $self->translate($_, $self->{ref}, $command, "wrap" => 0);
        }
        $translated .= " ".join(", ", @t);
    }

    print "($translated,@$env)\n"
        if ($debug{'commands'});
    return ($translated,@$env);
};

sub environment_command {
    my $self = shift;
    my ($command,$variant,$args,$env) = (shift,shift,shift,shift);
    print "environment_command($command,$variant,@$args,@$env)="
        if ($debug{'commands'});
    my ($t,@e)=("",());

    ($t, @e) = generic_command($self,$command,$variant,$args,$env);
    @e = (@$env, $command);

    print "($t,@e)\n"
        if ($debug{'commands'});
    return ($t,@e);
}

## push the environment in the environment stack, and do not translate
## the command
#sub push_environment {
#    my $self = shift;
#    my ($command,$variant,$args,$env) = (shift,shift,shift,shift);
#    print "push_environment($command,$variant,@$args,@$env)="
#        if ($debug{'environments'});
#
#    my ($t,@e) = generic_command($self,$command,$variant,$args,$env);
#
#    print "($t,@e)\n"
#        if ($debug{'environments'});
#    return ($t,@e);
#}
#
#foreach (qw(itemize ignore menu smallexample titlepage ifinfo display example)) {
foreach (qw(menu example format ifinfo titlepage enumerate tex ifhtml)) {
    register_generic_command("*$_,");
    $commands{$_} = \&environment_command;
    $break_line{$_} = 1;
}
# FIXME: maybe format and menu should just be verbatim environments.
$env_separators{'menu'} = "(?:(?:^|\n)\\\*|::)";
$env_separators{'format'} = "(?:(?:^|\n)\\\*|END-INFO-DIR-ENTRY|START-INFO-DIR-ENTRY)";

my $end_command=$commands{'end'};
register_generic_command("*end,  ");
$commands{'end'} = $end_command;
$break_line{'end'} = 1;

register_generic_command("*deffn,  ");
$commands{'deffn'} = \&environment_command;
$break_line{'deffn'} = 1;
register_generic_command("*defvr,  ");
$commands{'defvr'} = \&environment_command;
$break_line{'defvr'} = 1;
register_generic_command("*macro,  ");
$commands{'macro'} = \&environment_command;
$break_line{'macro'} = 1;
register_generic_command("*itemize,  ");
$commands{'itemize'} = \&environment_command;
$break_line{'itemize'} = 1;
register_generic_command("*table,  ");
$commands{'table'} = \&environment_command;
$break_line{'table'} = 1;

register_generic_command("*setchapternewpage,  ");
$commands{'setchapternewpage'} = \&line_command;
$break_line{'setchapternewpage'} = 1;

# TODO: is_closed, use a regexp: \ does not escape the closing brace.
# TBC on LaTeX.
# In Texinfo, it appears with the "code" command. Maybe this command should
# be used as verbatim. (Expressions.texi)

# TODO: @include
# TODO: special function to split the deffn Function definitions
#       (maybe too maxima specific)
# TODO: special function for the indexes

# TBC: node Indices

1;
