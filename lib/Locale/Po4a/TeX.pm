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

L<po4a(7)|po4a.7>,
L<Locale::Po4a::TransTractor(3pm)|Locale::Po4a::TransTractor>.

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

# hash of known commands and environments, with parsing sub.
# See end of this file
my %commands;
my %environments;

# The escape character used to introduce commands.
my $RE_ESCAPE = "\\\\"; # TODO: verify it can be overloaded. "@" in texinfo.
my $ESCAPE    = "\\";

# Space separated list of environments that should not be re-wrapped.
my $no_wrap_environments = "verbatim";
# Space separated list of commands that can be handle separately from
# when they appear at the beginning or end of a paragraph
my $separated_commands = "index label";

# Hash of categories and their associated commands.
# Commands are space separated.
# There are currently 2 categories:
# * untranslated
#   The command is written as is with its arguments.
# * translate_joined
#   All arguments are translated and the command is then reassembled
my %command_categories = (
    'untranslated'      => "vspace hspace label ",
    'translate_joined'  => "chapter section subsection subsubsection ".
                           "index"
);

#########################
#### DEBUGGING STUFF ####
#########################
my %debug=('pretrans'         => 0, # see pre-conditioning of translation
           'postrans'         => 0, # see post-conditioning of translation
           'translate'        => 0, # see translation
           'extract_commands' => 0, # see commands extraction
           'commands'         => 0, # see command subroutines
           'environments'     => 0  # see environment subroutines
           );

sub pre_trans {
    my ($self,$str,$ref,$type)=@_;
    # Preformating, so that translators don't see
    # strange chars
    my $origstr=$str;
    print STDERR "pre_trans($str)="
        if ($debug{'pretrans'});

    # Accentuated characters
    # FIXME: only do this if the encoding is UTF-8?
    $str =~ s/$RE_ESCAPE`a/à/g;
#    $str =~ s/$RE_ESCAPEc{c}/ç/g; # not in texinfo: @,{c}
    $str =~ s/$RE_ESCAPE^e/ê/g;
#    $str =~ s/$RE_ESCAPE'e/é/g;
    $str =~ s/$RE_ESCAPE`e/è/g;
    $str =~ s/$RE_ESCAPE`u/ù/g;
    $str =~ s/$RE_ESCAPE"i/ï/g;
    # Non breaking space. FIXME: should we change $\sim$ to ~
    $str =~ s/~/\xA0/g; # FIXME: not in texinfo: @w{ }

    print STDERR "$str\n" if ($debug{'pretrans'});
    return $str;
}

sub post_trans {
    my ($self,$str,$ref,$type)=@_;
    my $transstr=$str;

    print STDERR "post_trans($str)="
        if ($debug{'postrans'});

    # Accentuated characters
    $str =~ s/à/$RE_ESCAPE`a/g;
#    $str =~ s/ç/$RE_ESCAPEc{c}/g; # FIXME: not in texinfo
    $str =~ s/ê/$RE_ESCAPE^e/g;
#    $str =~ s/é/$RE_ESCAPE'e/g;
    $str =~ s/è/$RE_ESCAPE`e/g;
    $str =~ s/ù/$RE_ESCAPE`u/g;
    $str =~ s/ï/$RE_ESCAPE"i/g;
    # Non breaking space. FIXME: should we change ~ to $\sim$
    $str =~ s/\xA0/~/g; # FIXME: not in texinfo

    print STDERR "$str\n" if ($debug{'postrans'});
    return $str;
}

# Comments are extracted in the parse function.
# They are stored in the @comments array, and then displayed as a PO
# comment with the first translated string of the paragraph.
my @comments = ();
sub translate {
    my ($self,$str,$ref,$type) = @_;
    my (%options)=@_;
    my $origstr=$str;
    print STDERR "translate($str)="
        if ($debug{'translate'});

    return $str unless (defined $str) && length($str);
    return $str if ($str eq "\n");

    $str=pre_trans($self,$str,$ref||$self->{ref},$type);
    if (@comments) {
        $options{'comment'} .= join('\n', @comments);
        @comments = ();
    }
    # Translate this
    $str = $self->SUPER::translate($str,
                                   $ref||$self->{ref},
                                   $type || $self->{type},
                                   %options);
    $str=post_trans($self,$str,$ref||$self->{ref},$type);

    print STDERR "$str\n" if ($debug{'translate'});
    return $str;
}

###########################
### COMMANDS SEPARATION ###
###########################

# =item get_leading_command($buffer)
#
# This function returns:
#
# =over 4
#
# =item The command name
#
# If no command is found at the beginning of the given buffer, this
# string will be empty.
#
# =item A variant
#
# This indicate if a variant is used. For example, an asterisk (*) can
# be added at the end of sections command to specify that they should
# not be numbered. In this case, this field will contain "*". If there
# is not variant, the field is an empty string.
#
# =item An array of optional arguments
#
# =item An array of mandatory arguments
#
# =item The remaining buffer
#
# The rest of the buffer after the removal of this leading command and
# its arguments. If no command is found, the original buffer is not
# touched and returned in this field.
#
# =back
#
# =cut
sub get_leading_command {
    my ($self, $buffer) = (shift,shift);
    my $command = ""; # the command name
    my $variant = ""; # a varriant for the command (e.g. an asterisk)
    my @opts = (); # array of optional arguments
    my @args = (); # array of mandatory arguments
    print STDERR "get_leading_command($buffer)="
        if ($debug{'extract_commands'});

    if ($buffer =~ m/^\s*$RE_ESCAPE([[:alpha:]]*)(\*?)(.*)$/s) {
        # The buffer begin by a comand (possibly preceded by some
        # whitespaces).
        $command = $1;
        $variant = $2;
        $buffer  = $3;
        # read the optional arguments (if any)
        while ($buffer =~ m/^\s*\[(.*)$/s) {
            my $opt = "";
            my $count = 1;
            $buffer = $1;
            # stop reading the buffer when the number of ] matches the
            # the number of [.
            while ($count > 0) {
                if ($buffer =~ m/^(.*?)([\[\]])(.*)$/s) {
                    $opt .= $1;
                    $buffer = $3;
                    if ($2 eq "[") {
                        $count++;
                    } else { # ]
                        $count--;
                    }
                    if ($count > 0) {
                        $opt .= $2
                    }
                } else {
                    # FIXME: can an argument contain an empty line?
                    # If it happens, either we should change the parse
                    # subroutine (so that it doesn't break entity), or
                    # we have to shiftline here.
                    die sprintf "un-balanced [";
                }
            }
            push @opts, $opt;
        }

        # read the mandatory arguments (if any)
        while ($buffer =~ m/^\s*\{(.*)$/s) {
            my $arg = "";
            my $count = 1;
            $buffer = $1;
            # stop reading the buffer when the number of } matches the
            # the number of {.
            while ($count > 0) {
                if ($buffer =~ m/^(.*?)([\{\}])(.*)$/s) {
                    $arg .= $1;
                    $buffer = $3;
                    if ($2 eq "{") {
                        $count++;
                    } else {
                        $count--;
                    }
                    if ($count > 0) {
                        $arg .= $2;
                    }
                } else {
                    # FIXME: can an argument contain an empty line?
                    # If it happens, either we should change the parse
                    # subroutine (so that it doesn't break entity), or
                    # we have to shiftline here.
                    die sprintf "un-balanced {";
                }
            }
            push @args, $arg;
        }
    }

    print STDERR "($command,$variant,@opts,@args,$buffer)\n"
        if ($debug{'extract_commands'});
    return ($command,$variant,\@opts,\@args,$buffer);
}

# Same as get_leading_command, but for commands at the end of a buffer.
sub get_trailing_command {
    my ($self, $buffer) = (shift,shift);
    my $orig_buffer = $buffer;
    print STDERR "get_trailing_command($buffer)="
        if ($debug{'extract_commands'});

    my @args = ();
    my @opts = ();
    my $command = "";
    my $variant = "";

    # While the buffer ends by }, consider it is a mandatory argument
    # and extract this argument.
    while ($buffer =~ m/^(.*)\}\s*$/s) {
        my $arg = "";
        my $count = 1;
        $buffer = $1;
        # stop reading the buffer when the number of } matches the
        # the number of {.
        while ($count > 0) {
            if ($buffer =~ m/^(.*)([\{\}])(.*)$/s) {
                 $arg = $3.$arg;
                 $buffer = $1;
                 if ($2 eq "{") {
                     $count--;
                 } else {
                     $count++;
                 }
                 if ($count > 0) {
                     $arg = $2.$arg;
                 }
            } else {
                # FIXME: can an argument contain an empty line?
                # If it happens, either we should change the parse
                # subroutine (so that it doesn't break entity), or
                # we have to shiftline here.
                die sprintf "un-balanced }";
            }
        }
        unshift @args, $arg;
    }

    # While the buffer ends by ], consider it is a mandatory argument
    # and extract this argument.
    while ($buffer =~ m/^(.*)\]\s*$/s) {
        my $opt = "";
        my $count = 1;
        $buffer = $1;
        # stop reading the buffer when the number of ] matches the
        # the number of [.
        while ($count > 0) {
            if ($buffer =~ m/^(.*)([\[\]])(.*)$/s) {
                 $opt = $3.$opt;
                 $buffer = $1;
                 if ($2 eq "[") {
                     $count--;
                 } else {
                     $count++;
                 }
                 if ($count > 0) {
                     $opt = $2.$opt;
                 }
            } else {
                # FIXME: can an argument contain an empty line?
                # If it happens, either we should change the parse
                # subroutine (so that it doesn't break entity), or
                # we have to shiftline here.
                die sprintf "un-balanced ]";
            }
        }
        unshift @opts, $opt;
    }

    # There should now be a command, maybe followed by an asterisk.
    if ($buffer =~ m/^(.*)$RE_ESCAPE([[:alpha:]]*)(\*?)\s*$/s) {
        $buffer = $1;
        $command = $2;
        $variant = $3;
    }

    # sanitize return values if no command was found.
    if (!length($command)) {
        $command = "";
        $variant = "";
        @opts = ();
        @args = ();
        $buffer = $orig_buffer;
    }

    print STDERR "($command,$variant,@opts,@args,$buffer)\n"
        if ($debug{'extract_commands'});
    return ($command,$variant,\@opts,\@args,$buffer);
}

# Warning: may be reentrant.
sub translate_buffer {
    my ($self,$buffer,@env) = (shift,shift,@_);
#print STDERR "translate_buffer($buffer,@env)\n";
    my ($command,$variant) = ("","");
    my $opts = ();
    my $args = ();
    my $translated_buffer = "";
    my $end_translated_buffer = "";
    my $t = ""; # a temporary string

    # translate leading commands.
    do {
        ($command, $variant, $opts, $args, $buffer) =
            get_leading_command($self,$buffer);
        if (length($command)) {
            # call the command subroutine.
            # These command subroutine will probably call translate_buffer
            # with the content of the arguments which need a translation.
            if (defined ($commands{$command})) {
                ($t,@env) = &{$commands{$command}}($self,$command,$variant,
                                                   $opts,$args,\@env);
                $translated_buffer .= $t;
            } else {
                die sprintf("unknown command: '%s'", $command)."\n"
            }
        }
    } while (length($command));

    # array of trailing commands, which will be translated later.
    my @trailing_commands = ();
    do {
        ($command, $variant, $opts, $args, $buffer) =
            get_trailing_command($self,$buffer);
        if (length($command)) {
            unshift @trailing_commands, ($command, $variant, $opts, $args);
        }
    } while (length($command));

    # Now, $buffer is just a block that can be translated.
    if (length($buffer)) {
        my $wrap = 1;
        my ($e1, $e2);
        NO_WRAP_LOOP: foreach $e1 (@env) {
            foreach $e2 (split(' ', $no_wrap_environments)) {
                if ($e1 eq $e2) {
                    $wrap = 0;
                    last NO_WRAP_LOOP;
                }
            }
        }

        $translated_buffer .= $self->translate($buffer,$self->{ref},
                                               "Plain text",
                                               "wrap" => $wrap);
        chomp $translated_buffer if ($wrap);
    }

    while (@trailing_commands) {
        my $command = shift @trailing_commands;
        my $variant = shift @trailing_commands;
        my $opts    = shift @trailing_commands;
        my $args    = shift @trailing_commands;
        if (defined ($commands{$command})) {
            ($t,@env) = &{$commands{$command}}($self,$command,$variant,
                                               $opts,$args,\@env);
            $translated_buffer .= $t;
        } else {
            die sprintf("unknown command: '%s'", $command)."\n";
        }
    }

    return ($translated_buffer,@env);
}

################################
#### EXTERNAL CUSTOMIZATION ####
################################
sub parse_definition_file {}
sub parse_definition_line {}

#############################
#### MAIN PARSE FUNCTION ####
#############################
sub parse{
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

        # remove comments, and store them in @comments
        if ($line =~ /^([^%]*)%(.*)$/) {
            push @comments, $2;
            # Keep the % sign. It will be removed latter.
            $line = "$1%";
        }

        if ($line =~ /^$/) {
            # An empty line. This indicates the end of the current
            # paragraph.
            $paragraph =~ s/%$//;
            if (length($paragraph)) {
                ($t, @env) = translate_buffer($self,$paragraph,@env);
                $self->pushline($t."\n");
                $paragraph="";
            }
            $self->pushline($line."\n");
        } else {
            # continue the same paragraph
            if ($paragraph =~ /%$/) {
                $paragraph =~ s/%$//s;
                chomp $paragraph;
                $line =~ s/^ *//;
            }
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


sub docheader {
    return "% This file was generated with po4a. Translate the source file.\n".
           "%\n";
}


####################################
#### DEFINITION OF THE COMMANDS ####
####################################

# Rebuild the command with the original arguments.
sub untranslated {
    my $self = shift;
    my ($command,$variant,$opts,$args,$env) = (shift,shift,shift,shift,shift);
    print "untranslated($command,$variant,@$opts,@$args,@$env)="
        if ($debug{'commands'});

    my $translated = "$ESCAPE$command$variant";
    foreach my $opt (@$opts) {
        $translated .= "[$opt]";
    }
    foreach my $opt (@$args) {
        $translated .= "{$opt}";
    }

    print "($translated,@$env)\n"
        if ($debug{'commands'});
    return ($translated,@$env);
}

# Rebuild the command, with all arguments translated.
sub translate_joined {
    my $self = shift;
    my ($command,$variant,$opts,$args,$env) = (shift,shift,shift,shift,shift);
    print "translate_joined($command,$variant,@$opts,@$args,@$env)="
        if ($debug{'commands'});
    my ($t,@e)=("",());

    my $translated = "$ESCAPE$command$variant";
    foreach my $opt (@$opts) {
        ($t, @e) = translate_buffer($self,$opt,(@$env,$command));
        $translated .= "[".$t."]";
    }
    foreach my $opt (@$args) {
        ($t, @e) = translate_buffer($self,$opt,(@$env,$command));
        $translated .= "{".$t."}";
    }

    print "($translated,@$env)\n"
        if ($debug{'commands'});
    return ($translated,@$env);
}

# definition of environment related commands
$commands{'begin'}= sub {
    my $self = shift;
    my ($command,$variant,$opts,$args,$env) = (shift,shift,shift,shift,shift);
    print "begin($command,$variant,@$opts,@$args,@$env)="
        if ($debug{'commands'} || $debug{'environments'});
    my ($t,@e) = ("",());

    if (defined($args->[0]) && defined($environments{$args->[0]})) {
        ($t, @e) = &{$environments{$args->[0]}}($self,$command,$variant,
                                                $opts,$args,$env);
    } else {
        die sprintf("po4a::TeX: unknown environment: '%s'", $args->[0])."\n";
    }

    print "($t, @e)\n"
        if ($debug{'commands'} || $debug{'environments'});
    return ($t, @e);
};
$commands{'end'}= sub {
    my $self = shift;
    my ($command,$variant,$opts,$args,$env) = (shift,shift,shift,shift,shift);
    print "end($command,$variant,@$opts,@$args,@$env)="
        if ($debug{'commands'} || $debug{'environments'});

    # verify that this environment was the last pushed environment.
    if ((pop @$env) ne $args->[0]) {
        die sprintf("po4a::TeX: unmatched end of environment '%s'",
                    $args->[0])."\n";
    }

    my ($t,@e) = untranslated($self,$command,$variant,$opts,$args,$env);

    print "($t, @$env)\n"
        if ($debug{'commands'} || $debug{'environments'});
    return ($t, @$env);
};

########################################
#### DEFINITION OF THE ENVIRONMENTS ####
########################################
# push the environment in the environment stack, and do not translate
# the command
sub push_environment {
    my $self = shift;
    my ($command,$variant,$opts,$args,$env) = (shift,shift,shift,shift,shift);
    print "push_environment($command,$variant,$opts,$args,$env)="
        if ($debug{'environments'});

    my ($t,@e) = untranslated($self,$command,$variant,$opts,$args,$env);
    @e = (@$env, $args->[0]);

    print "($t,@e)\n"
        if ($debug{'environments'});
    return ($t,@e);
}

$environments{'verbatim'} = \&push_environment;
$environments{'document'} = \&push_environment;

# TODO: a tabular environment to translate cells separately

####################################
### INITIALIZATION OF THE PARSER ###
####################################
sub initialize {
    my $self = shift;
    my %options = @_;

    $self->{options}{'translate'}='';
    $self->{options}{'untranslated'}='';
    $self->{options}{'debug'}='';

    foreach my $opt (keys %options) {
        if ($options{$opt}) {
            die sprintf("po4a::sgml: ".
                        dgettext ("po4a","Unknown option: %s"), $opt).
                        "\n"
                unless exists $self->{options}{$opt};
            $self->{options}{$opt} = $options{$opt};
        }
    }

    if ($options{'debug'}) {
        foreach ($options{'debug'}) {
            $debug{$_} = 1;
        }
    }

    if ($options{'untranslated'}) {
        $command_categories{'untranslated'} .=
            join(' ', split(/,/, $options{'untranslated'}));
    }
    foreach (split(/ /, $command_categories{'untranslated'})) {
        if (defined($commands{$_})) {
            print "coucou $_\n";
        }
        $commands{$_} = \&untranslated;
    }

    if ($options{'translate'}) {
        $command_categories{'translate_joined'} .=
            join(' ', split(/,/, $options{'translate_joined'}));
    }
    foreach (split(/ /, $command_categories{'translate_joined'})) {
        if (defined($commands{$_})) {
            print "coucou $_\n";
        }
        $commands{$_} = \&translate_joined;
    }
}

