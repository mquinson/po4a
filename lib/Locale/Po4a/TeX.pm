#!/usr/bin/perl -w

# Copyright (c) 2004 by Nicolas FRANÃ‡OIS <nicolas.francois@centraliens.net>
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
# along with po4a; if not, write to the Free Software
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

=head1 TRANSLATING WITH PO4A::TEX

This module can be used directly to handle generic TeX documents.
This will split your document in smaller blocks (paragraphs, verbatim
blocks, or even smaller like titles or indexes).

There are some options (described in the next section) that can customize
this behavior.  If this doesn't fit to your document format you're encouraged
to write your own module derived from this, to describe your format's details.
See the section "Writing derivate modules" below, for the process description.

This module can also be customized by lines starting with "% po4a:" in the
TeX file.
These customization are described

=head1 OPTIONS ACCEPTED BY THIS MODULE

These are this module's particular options:

=over 4

=cut

package Locale::Po4a::TeX;

use 5.006;
use strict;
use warnings;

require Exporter;
use vars qw($VERSION @ISA @EXPORT);
$VERSION=$Locale::Po4a::TransTractor::VERSION;
@ISA = qw(Locale::Po4a::TransTractor);
@EXPORT = qw(%commands %environments
             $RE_ESCAPE $ESCAPE
             $no_wrap_environments $separated_commands
             %command_categories %separated
             &untranslated &translate_joined &push_environment);

use Locale::Po4a::TransTractor;
use Locale::Po4a::Common;
use Locale::gettext qw(dgettext);
use File::Basename qw(dirname);
use Carp qw(croak);

use Encode;
use Encode::Guess;

# hash of known commands and environments, with parsing sub.
# See end of this file
use vars qw(%commands %environments);

# The escape character used to introduce commands.
our $RE_ESCAPE = "\\\\";
our $ESCAPE    = "\\";

# Space separated list of environments that should not be re-wrapped.
our $no_wrap_environments = "verbatim";
# Space separated list of commands that can be handled separately from
# when they appear at the beginning or end of a paragraph
our $separated_commands = "index label";
# hash with these commands
our %separated = ();

# Hash of categories and their associated commands.
# Commands are space separated.
# There are currently 2 categories:
# * untranslated
#   The command is written as is with its arguments.
# * translate_joined
#   All arguments are translated and the command is then reassembled
our %command_categories = (
    'untranslated'      => "vspace hspace label",
    'translate_joined'  => "chapter section subsection subsubsection ".
                           "index"
);

=item translate

Coma separated list of commands whose arguments have to be proposed for
translation.
This list is appended to the default list containing
chapter, section, subsection, subsubsection and index.

=item untranslated

Coma-separated list of commands whose arguments shoud not be translated.
This list is appended to the default list containing
vspace, hspace and label.

=back

=cut

# Directory name of the main file.
# It is the directory where included files will be searched.
# See read_file.
my $my_dirname;

# Array of files that should not be included by read_file.
# See read_file.
our @exclude_include;

# TODO: define the directory were files have to be searched for (TEXINPUTS?).

#########################
#### DEBUGGING STUFF ####
#########################
my %debug=('pretrans'         => 0, # see pre-conditioning of translation
           'postrans'         => 0, # see post-conditioning of translation
           'translate'        => 0, # see translation
           'extract_commands' => 0, # see commands extraction
           'commands'         => 0, # see command subroutines
           'environments'     => 0, # see environment subroutines
           'translate_buffer' => 0  # see buffer translation
           );

=head1 WRITING DERIVATE MODULES

=head1 INTERNAL FUNCTIONS used to write derivated parsers

=cut

sub pre_trans {
    my ($self,$str,$ref,$type)=@_;
    # Preformating, so that translators don't see
    # strange chars
    my $origstr=$str;
    print STDERR "pre_trans($str)="
        if ($debug{'pretrans'});

    # Accentuated characters
    # FIXME: only do this if the encoding is UTF-8?
    $str =~ s/${RE_ESCAPE}`a/à/g;
#    $str =~ s/${RE_ESCAPE}c{c}/ç/g; # not in texinfo: @,{c}
    $str =~ s/${RE_ESCAPE}^e/ê/g;
    $str =~ s/${RE_ESCAPE}'e/é/g;
    $str =~ s/${RE_ESCAPE}`e/è/g;
    $str =~ s/${RE_ESCAPE}`u/ù/g;
    $str =~ s/${RE_ESCAPE}"i/ï/g;
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
    $str =~ s/à/${ESCAPE}`a/g;
#    $str =~ s/ç/$ESCAPEc{c}/g; # FIXME: not in texinfo
    $str =~ s/ê/${ESCAPE}^e/g;
    $str =~ s/é/${ESCAPE}'e/g;
    $str =~ s/è/${ESCAPE}`e/g;
    $str =~ s/ù/${ESCAPE}`u/g;
    $str =~ s/ï/${ESCAPE}"i/g;
    # Non breaking space. FIXME: should we change ~ to $\sim$
    $str =~ s/\xA0/~/g; # FIXME: not in texinfo

    print STDERR "$str\n" if ($debug{'postrans'});
    return $str;
}

# Comments are extracted in the parse function.
# They are stored in the @comments array, and then displayed as a PO
# comment with the first translated string of the paragraph.
my @comments = ();

# Wrapper arround Transtractor's translate, with pre- and post-processing
# filters.
# Comments of a paragraph are inserted as a PO comment for the first
# translated string of this paragraph.
sub translate {
    my ($self,$str,$ref,$type) = @_;
    my (%options)=@_;
    my $origstr=$str;
    print STDERR "translate($str)="
        if ($debug{'translate'});

    return $str unless (defined $str) && length($str);
    return $str if ($str eq "\n");

    $str=pre_trans($self,$str,$ref||$self->{ref},$type);

    # add comments (if any and not already added to the PO)
    if (@comments) {
        $options{'comment'} .= join('\n', @comments);
        @comments = ();
    }

# FIXME: translate may append a newline, keep the trailing spaces so we can
# recover them.
    my $spaces = "";
    if ($str =~ m/(\s+)$/s) {
        $spaces = $1;
    }

    # Translate this
    $str = $self->SUPER::translate($str,
                                   $ref||$self->{ref},
                                   $type || $self->{type},
                                   %options);

# FIXME: translate may append a newline, see above
    if ($options{'wrap'}) {
        chomp $str;
        $str .= $spaces;
    }

    $str=post_trans($self,$str,$ref||$self->{ref},$type);

    print STDERR "'$str'\n" if ($debug{'translate'});
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

    if ($buffer =~ m/^\s*$RE_ESCAPE([[:alpha:]]+)(\*?)(.*)$/s
        && $separated{$1}) {
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
                    # FIXME: an argument can contain an empty line.
                    # We should change the parse subroutine (so that it doesn't
                    # break entity).
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
                    # FIXME: an argument can contain an empty line.
                    # We should change the parse subroutine (so that it doesn't
                    # break entity).
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
    while ($buffer =~ m/^(.*\{.*)\}\s*$/s) {
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
                # FIXME: an argument can contain an empty line.
                # We should change the parse subroutine (so that it doesn't
                # break entity).
                die sprintf "un-balanced }";
            }
        }
        unshift @args, $arg;
    }

    # While the buffer ends by ], consider it is a mandatory argument
    # and extract this argument.
    while ($buffer =~ m/^(.*\[.*)\]\s*$/s) {
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
                # FIXME: an argument can contain an empty line.
                # We should change the parse subroutine (so that it doesn't
                # break entity).
                # FIXME: see ch06:267
                die sprintf "un-balanced ]";
            }
        }
        unshift @opts, $opt;
    }

    # There should now be a command, maybe followed by an asterisk.
    if ($buffer =~ m/^(.*)$RE_ESCAPE([[:alpha:]]+)(\*?)\s*$/s
        && $separated{$2}) {
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

# Recursively translate a buffer by separating leading and trailing
# commands (those which should be translatted separately) from the
# buffer.
sub translate_buffer {
    my ($self,$buffer,@env) = (shift,shift,@_);
    print STDERR "translate_buffer($buffer,@env)="
        if ($debug{'translate_buffer'});
    my ($command,$variant) = ("","");
    my $opts = ();
    my $args = ();
    my $translated_buffer = "";
    my $orig_buffer = $buffer;
    my $t = ""; # a temporary string

    # translate leading commands.
    do {
        # keep the leading space to put them back after the translation of
        # the command.
        my $spaces = "";
        if ($buffer =~ /^(\s+)(.*)$/s) {
            $spaces = $1;
            $buffer = $2;
        }
        ($command, $variant, $opts, $args, $buffer) =
            get_leading_command($self,$buffer);
        if (length($command)) {
            # call the command subroutine.
            # These command subroutines will probably call translate_buffer
            # with the content of each argument that need a translation.
            if (defined ($commands{$command})) {
                ($t,@env) = &{$commands{$command}}($self,$command,$variant,
                                                   $opts,$args,\@env);
                $translated_buffer .= $spaces.$t;
                # Handle spaces after a command.
                $spaces = "";
                if ($buffer =~ /^(\s+)(.*)$/s) {
                    $spaces = $1;
                    $buffer = $2;
                }
                $translated_buffer .= $spaces;
            } else {
                die sprintf("unknown command: '%s'", $command)."\n"
            }
        } else {
            $buffer = $spaces.$buffer;
        }
    } while (length($command));

    # array of trailing commands, which will be translated later.
    my @trailing_commands = ();
    do {
        my $spaces = "";
        if ($buffer =~ /^(.*)(\s+)$/s) {
            $buffer = $1;
            $spaces = $2;
        }
        ($command, $variant, $opts, $args, $buffer) =
            get_trailing_command($self,$buffer);
        if (length($command)) {
            unshift @trailing_commands, ($command, $variant, $opts, $args, $spaces);
        } else {
            $buffer .= $spaces;
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
        # Keep spaces at the end of the buffer.
        my $spaces = "";
        if ($buffer =~ /^(.*)(\s+)$/s) {
            $spaces = $2;
            $buffer = $1;
        }
        $translated_buffer .= $self->translate($buffer,$self->{ref},
                                               @env?$env[-1]:"Plain text",
                                               "wrap" => $wrap);
        # Restore spaces at the end of the buffer.
        $translated_buffer .= $spaces;
    }

    # append the translation of the trailing commands
    while (@trailing_commands) {
        my $command = shift @trailing_commands;
        my $variant = shift @trailing_commands;
        my $opts    = shift @trailing_commands;
        my $args    = shift @trailing_commands;
        my $spaces  = shift @trailing_commands;
        if (defined ($commands{$command})) {
            ($t,@env) = &{$commands{$command}}($self,$command,$variant,
                                               $opts,$args,\@env);
            $translated_buffer .= $t.$spaces;
        } else {
            die sprintf("unknown command: '%s'", $command)."\n";
        }
    }

    print STDERR "($translated_buffer,@env)\n"
        if ($debug{'translate_buffer'});
    return ($translated_buffer,@env);
}

################################
#### EXTERNAL CUSTOMIZATION ####
################################

# Overload Transtractor's read
sub read {
    my $self=shift;
    my $filename=shift;

    # keep the directory name of the main file.
    $my_dirname = dirname($filename);

    push @{$self->{TT}{doc_in}}, read_file($self, $filename);
}

# Recursively read a file, appending included files.
# Except from the file inclusion part, it is a cut and paste from
# Transtractor's read.
sub read_file {
    my $self=shift;
    my $filename=shift
        or croak wrap_mod("po4a::tex",
	    dgettext("po4a", "Can't read from file without having a filename"));
    my $linenum=0;
    my @entries=();

    open (my $in, $filename)
        or croak wrap_mod("po4a::tex",
	    dgettext("po4a", "Can't read from %s: %s"), $filename, $!);
    while (defined (my $textline = <$in>)) {
        $linenum++;
        my $ref="$filename:$linenum";
        while ($textline =~ /^(.*)\\include\{([^\{]*)\}(.*)$/) {
            my ($begin,$newfilename,$end) = ($1,$2,$3);
            my $include = 1;
            foreach my $f (@exclude_include) {
                if ($f eq $newfilename) {
                    $include = 0;
                    $begin .= "\\include{$newfilename}";
                    $textline = $end;
                }
            }
            if ($begin !~ /^\s*$/) {
                push @entries, ($begin,$ref);
            }
            if ($include) {
                push @entries, read_file($self,
                                         "$my_dirname/$newfilename.tex");
                $textline = $end;
            }
        }
        if (length($textline)) {
        my @entry=($textline,$ref);
        push @entries, @entry;

        # Detect if this file has non-ascii characters
        if($self->{TT}{ascii_input}) {

            my $decoder = guess_encoding($textline);
            if (!ref($decoder) or $decoder !~ /Encode::XS=/) {
                # We have detected a non-ascii line
                $self->{TT}{ascii_input} = 0;
                # Save the reference for future error message
                $self->{TT}{non_ascii_ref} ||= $ref;
            }
        }
        }
    }
    close $in
        or croak wrap_mod("po4a::tex",
	    dgettext("po4a", "Can't close %s after reading: %s"), $filename, $!);

    return @entries;
}

=head1 INLINE CUSTIOMIZATION OF THE TEX MODULE

The TeX module can be customized with lines starting by "% po4a:".
These lines are interpreted as commands to the parser.
The following commands are recognized:

=over 4

=item % po4a: command I<command1> alias I<command2>

Indicates that the arguments of the I<command1> command should be
treated as the arguments of the I<command2> command.

=item % po4a: command I<command1> I<function1>

Indicates that the I<command1> command should be handled by I<function1>.

=item % po4a: environment <env1> <function1>

Indicates that the I<env1> environment should be handled by I<function1>.

TODO

=item % po4a: command <command1> x,y,z,t

  * x is the number of optional arguments (between [])
      0 - no optional argument
     -1 - variable
      n - maximum number of optional arguments
  * y is the number of arguments
    maybe x and y are not needed
  * z indexes of the optional arguments that have to be translated
     -1 - all optional argument should be translated
      0 - none
  1 3 7 - the 1st, 3rd and 7th arguments should be translated
  * t indexes of the arguments that have to be translated
This permits a better control of the translated arguments and some
verifications and some verifications of the number of arguments.

It could be usefull to define commands without argument as "0,0,,"
instead of either translated or untranslated.

=cut

# Subroutine for parsing a file with po4a directive (definitions for
# newcommands).
sub parse_definition_file {
    my ($self,$filename)=@_;

    open (IN,"<$my_dirname/$filename")
        || die wrap_mod("po4a::tex",
	    dgettext("po4a", "Can't open %s: %s"), $filename, $!);
    while (<IN>) {
        if (/^%\s+po4a:/) {
            parse_definition_line($self, $_);
        }
    }
}
# Parse a definition line ("% po4a: ")
sub parse_definition_line {
    my ($self,$line)=@_;
    $line =~ s/^%\s+po4a:\s*//;

    if ($line =~ /^command\s+(\w+)\s+(.*)$/) {
        my $command = $1;
        $line = $2;
        if ($line =~ /^alias\s+(\w+)\s*$/) {
            if (defined ($commands{$1})) {
                $commands{$command} = $commands{$1};
            } else {
                die "Cannot use an alias to the unknown command $2\n";
            }
        } elsif ($line =~ /^(\w+)\s*$/) {
            if (defined &$1) {
                $commands{$command} = \&$1;
            } else {
                die "Unknown command ($1) for $command\n";
            }
        }
    } elsif ($line =~ /^environment\s+(\w+)\s+(.*)$/) {
        my $env = $1;
        $line = $2;
        if ($line =~ /^(\w+)\s*$/) {
            if (defined &$1) {
                $environments{$env} = \&$1;
            } else {
                die "Unknown environment ($1) for $env\n";
            }
        }
    }
}

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

        if ($line =~ /^\s*%\s*po4a\s*:/) {
            parse_definition_line($self, $line);
        # FIXME: not always, use return of parse_definition_line?
            $line = "%";
        } elsif ($line =~ /^([^%]*)(?<!\\)%(.*)$/) { # FIXME: even number of \ ...
        #FIXME: in Python-Doc, there is a % in a verbatim environment,which is not a comment.
            # remove comments, and store them in @comments
            push @comments, $2;
            # Keep the % sign. It will be removed latter.
            $line = "$1%";
        }

        if ($line =~ /^ *$/) {#FIXME: \s*?
            # An empty line. This indicates the end of the current
            # paragraph.
            $paragraph =~ s/(?<!\\)%$//; # FIXME: even number of \ ...
            if (length($paragraph)) {
                ($t, @env) = translate_buffer($self,$paragraph,@env);
                $self->pushline($t);
                $paragraph="";
            }
            $self->pushline($line."\n");
        } elsif ($line =~ /^\\begin\{/) {
            # break the paragraph at the beginning of a new environment.
            $paragraph =~ s/(?<!\\)%$//; # FIXME: even number of \ ...
            if (length($paragraph)) {
                ($t, @env) = translate_buffer($self,$paragraph,@env);
                $self->pushline($t);
            }
            $paragraph = $line."\n";
        } else {
            # continue the same paragraph
            if ($paragraph =~ /(?<!\\)%$/) { # FIXME: even number of \ ...
                $paragraph =~ s/%$//s;
                chomp $paragraph;
                $line =~ s/^ *//;
            }
            # FIXME: s/^\s+/ /
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
    my $arg=1;
    foreach my $opt (@$opts) {
        ($t, @e) = translate_buffer($self,$opt,(@$env,$command."[#$arg]"));
        $translated .= "[".$t."]";
        $arg+=1;
    }
    $arg=1;
    foreach my $opt (@$args) {
        ($t, @e) = translate_buffer($self,$opt,(@$env,$command."{#$arg}"));
        $translated .= "{".$t."}";
        $arg+=1;
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
        die wrap_mod("po4a::tex", "unknown environment: '%s'", $args->[0]);
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
    if (!@$env || @$env[-1] ne $args->[0]) {
        # a begin may have been hidden in the middle of a translated
        # buffer. FIXME: Just warn for now.
        warn wrap_mod("po4a::tex", "unmatched end of environment '%s'",
                     $args->[0]);
    } else {
        pop @$env;
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
# FIXME: a \begin{env} can be followed by an argument. For example:
# \begin{important}[the law of conservation of energy]
# FIXME: The environment name can be followed by a '*'
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
            die wrap_mod("po4a::tex",
                         dgettext("po4a", "Unknown option: %s"), $opt)
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
            # FIXME: Should we allow to redefine commands
            #        No die, because this function is called twice during
            #        gettextization.
        }
        $commands{$_} = \&untranslated;
    }

    if ($options{'translate'}) {
        $command_categories{'translate_joined'} .=
            join(' ', split(/,/, $options{'translate_joined'}));
    }
    foreach (split(/ /, $command_categories{'translate_joined'})) {
        if (defined($commands{$_})) {
            # FIXME: Should we allow to redefine commands
            #        No die, because this function is called twice during
            #        gettextization.
        }
        $commands{$_} = \&translate_joined;
    }

    # build an hash with keys in $separated_commands to ease searches.
    foreach (split(/ /, $separated_commands)){
        $separated{$_}=1;
    };
}

=head1 STATUS OF THIS MODULE

=head1 TODO LIST

=head1 SEE ALSO

L<po4a(7)|po4a.7>,
L<Locale::Po4a::TransTractor(3pm)|Locale::Po4a::TransTractor>.

=head1 AUTHORS

 Nicolas FranÃ§ois <nicolas.francois@centraliens.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Nicolas FRANÃ‡OIS <nicolas.francois@centraliens.net>.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see COPYING file).

=cut

1;
