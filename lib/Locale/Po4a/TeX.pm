#!/usr/bin/perl -w

# Copyright (c) 2004 by Nicolas FRANÇOIS <nicolas.francois@centraliens.net>
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

Locale::Po4a::TeX - Convert TeX documents and derivates from/to PO files

=head1 DESCRIPTION

The po4a (po for anything) project goal is to ease translations (and more
interestingly, the maintenance of translations) using gettext tools on
areas where they were not expected like documentation.

Locale::Po4a::TeX is a module to help the translation of TeX documents into
other [human] languages. It can also be used as a base to build modules for
TeX-based documents.

Please note that this module is still under heavy developement, and not
distributed in official po4a release since we don't feel it to be mature
enough. If you insist on trying, check the CVS out.

=head1 SEE ALSO

L<po4a(7)|po4a.7>, L<Locale::Po4a::TransTractor(3pm)|Locale::Po4a::TransTractor>.

=head1 AUTHORS

 Nicolas François <nicolas.francois@centraliens.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Nicolas FRANÇOIS <nicolas.francois@centraliens.net>.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see COPYING file).

=cut

package Locale::Po4a::TeX;

use 5.006;
use strict;
use warnings;

require Exporter;
use vars qw($VERSION @ISA @EXPORT);
$VERSION=$Locale::Po4a::TransTractor::VERSION;
@ISA = qw(Locale::Po4a::TransTractor);
@EXPORT = qw();

use Locale::Po4a::TransTractor;
use Locale::gettext qw(dgettext);

my %commands; # hash of known commands, with parsing sub. See end of this file

sub initialize {}

#########################
#### DEBUGGING STUFF ####
#########################
my %debug=('pretrans'  => 0,  # see pre-conditioning of translation
           'postrans'  => 0,  # see post-conditioning of translation
           'translate' => 0   # see translation
           );

sub pre_trans {
    my ($self,$str,$ref,$type)=@_;
    # Preformating, so that translators don't see 
    # strange chars
    my $origstr=$str;
    print STDERR "pre_trans($str)="
        if ($debug{'pretrans'});

    print STDERR "$str\n" if ($debug{'pretrans'});
    return $str;
}

sub post_trans {
    my ($self,$str,$ref,$type)=@_;
    my $transstr=$str;

    print STDERR "post_trans($str)="
        if ($debug{'postrans'});

    print STDERR "$str\n" if ($debug{'postrans'});
    return $str;
}
sub translate {
    my ($self,$str,$ref,$type) = @_;
    my (%options)=@_;
    my $origstr=$str;
    print STDERR "translate($str)="
        if ($debug{'translate'});

    return $str unless (defined $str) && length($str);
    return $str if ($str eq "\n");

    $str=pre_trans($self,$str,$ref||$self->{ref},$type);
    # Translate this
    $str = $self->SUPER::translate($str,
                                   $ref||$self->{ref},
                                   $type || $self->{type},
                                   %options);
    if ($options{'wrap'}) {
        my (@paragraph);
        @paragraph=split (/\n/,$str);
        if (defined ($paragraph[0]) && $paragraph[0] eq '') {
            shift @paragraph;
        }
        $str = join("\n",@paragraph)."\n";
    }
    $str=post_trans($self,$str,$ref||$self->{ref},$type);

    print STDERR "$str\n" if ($debug{'translate'});
    return $str;
}

sub do_paragraph {
    my ($self,$paragraph,$wrapped_mode) = (shift,shift,shift);

    # Handle paragraphs beginning by \index{...}:
    while ($paragraph =~ m/^\\index{([^{}]*)}\s*(.*)$/s) {
        $paragraph = $2;
        my $index = $self->translate($1,$self->{ref},
                                     "index", "wrap" => 1);
        chomp $index;
        $self->pushline( "\\index{".$index."}\n" );
    }

    # Handle paragraphs ending by an \index{...}
    # These commands are removed from the paragraph and will be
    # translated and pushed after the paragraph.
    # TODO: the content of the index{} could contain a command
    my @indexes=();
    while ($paragraph =~ m/^(.*)\s*\\index{([^{}]*)}\s*$/s) {
        unshift @indexes, $2;
        $paragraph = $1;
    }

    unless ($paragraph =~ m/\n$/s) {
        my @paragraph = split(/\n/,$paragraph);

        $paragraph .= "\n"
            unless scalar (@paragraph) == 1;
    }

    # Translate and push the translated paragraph
    $self->pushline( $self->translate($paragraph,$self->{ref},"Plain text",
                                      "wrap" => $wrapped_mode ) );

    # Translate and push the \index commands that were removed from
    # the end of the paragraph.
    foreach my $index (@indexes) {
        $index = $self->translate($index,$self->{ref},
                                  "index", "wrap" => 1);
        chomp $index;
        $self->pushline( "\\index{".$index."}\n" );
    }
}

#############################
#### MAIN PARSE FUNCTION ####
#############################
sub parse{
    my $self = shift;
    my ($line,$ref);
    my ($paragraph)=""; # Buffer where we put the paragraph while building
    my $wrapped_mode=1; # Should we wrap the paragraph?

  LINE:
    undef $self->{type};
    ($line,$ref)=$self->shiftline();
    
    while (defined($line)) {
        chomp($line);
        $self->{ref}="$ref";

        if ($line =~ /^\\([^{]*)([*]?){/) {
            my $command = $1;
            if (defined ($commands{$command})) {
                if (length($paragraph)) {
                    do_paragraph($self,$paragraph,$wrapped_mode);
                    $paragraph="";
                }
                &{$commands{$command}}($self,$line);
            } else {
                # continue the paragraph
                $paragraph .= $line."\n";
            }
        } elsif ($line =~ /^%/) {
            # a commented line
            if (length($paragraph)) {
                do_paragraph($self,$paragraph,$wrapped_mode);
                $paragraph="";
            }
            $self->pushline($line."\n");
        } elsif ($line =~ /^$/) {
            # end of a paragraph
            if (length($paragraph)) {
                do_paragraph($self,$paragraph,$wrapped_mode);
                $paragraph="";
            }
            $self->pushline($line."\n");
        } else {
            # continue the same paragraph
            $paragraph .= $line."\n";
        }

        # Reinit the loop
        ($line,$ref)=$self->shiftline();
        undef $self->{type};
    }

    if (length($paragraph)) {
        do_paragraph($self,$paragraph,$wrapped_mode);
        $paragraph="";
    }
} # end of parse


sub docheader {
    return "% This file was generated with po4a. Translate the source file.\n".
           "%\n";
}


####################################
#### DEFINITION OF THE COMMANDS ####
####################################

# separate the command and its parameters.
# TODO: another line could be needed.
sub parse_command {
    my $line = shift;
    if ($line =~ /^\\(.*?){(.*)}$/s) {
        # TODO: some verifications:
        #       * no { or } in $1
        #       * same number of { and } in $2
        my ($command,$param) = ($1,$2);
        return ($command,$param);
    } else {
        return ($line,"");
    }
}

$commands{'chapter'}=$commands{'section'}=$commands{'subsection'}= sub {
    my ($self,$line) = (shift,shift);
    my ($command,$param) = parse_command($line);
    my $label = "";
    # These title may end by a \label.
    # In these cases, remove the label in order to translate it separately.
    if ($param =~ /^(.*)\s*\\label{(.*)}$/) {
        $label = $2;
        $param = $1;
    }
    $param = $self->translate($param,$self->{ref},
                              $command, "wrap" => 1);
    chomp $param;
    if (length $label) {
        $label = $self->translate($label,$self->{ref},
                                  "label", "wrap" => 1);
        chomp $label;
        $self->pushline("\\".$command."{".$param."\\label{".$label."}}\n");
    } else {
        $self->pushline("\\".$command."{".$param."}\n");
    }
};

$commands{'begin'}= sub {
    my ($self,$line) = (shift,shift);
    my ($command,$param) = parse_command($line);
    if ($command eq "begin" && defined $commands{$param}) {
        &{$commands{$param}}($self,$line);
    } else {
        die sprintf("po4a::LaTeX: \\begin command not understood in:\n".
                    "po4a::LaTeX: '%s'\n", $line);
    }
};

$commands{'end'}= sub {
    my ($self,$line) = (shift,shift);

    # \end commands should be handled in the subroutine called by the
    # corresponding \begin command.
    die sprintf("po4a::LaTeX: \\end without a begin in:\n".
                "po4a::LaTeX: '%s'\n", $line);
};

$commands{'verbatim'}= sub {
# XXX: try to handle this with an environment stack ?
    my ($self,$line) = (shift,shift);
    my $paragraph = "";
    my $ref = "";
    # push the \begin line
    $self->pushline($line."\n");

    ($line,$ref) = $self->shiftline();
    while ($line !~ /^\\end{verbatim/) {
        $paragraph .= $line;
        ($line,$ref) = $self->shiftline();
    }
    $self->pushline($self->translate($paragraph,$self->{ref},
                                     "verbatim", "wrap" => 0));

    # push the \end line
    $self->pushline($line);
};

