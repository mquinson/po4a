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

Users should probably use the LaTeX module, which inherite from the TeX module
and contains the definitions of common LaTeX commands.

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
These customization are described in the B<INLINE CUSTOMIZATION> section.

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
             &untranslated &translate_joined &push_environment
             &register_generic);

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
# hash to describe the number of parameters and which one have to be
# translated. Used by generic commands
our %command_parameters = ();
# hash to describe the separators of environments.
our %env_separators =();

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

=item debug

Activate debugging for some internal mechanisms of this module.
Use the source to see which parts can be debugged.

=item translate

Coma-separated list of commands whose arguments have to be proposed for
translation.
This list is appended to the default list containing
chapter, section, subsection, subsubsection and index.

=item untranslated

Coma-separated list of commands whose arguments shoud not be translated.
This list is appended to the default list containing
vspace, hspace and label.

=item no_wrap

Coma-separated list of environments which should not be re-wrapped.

Note that there is a difference between verbatim and no_wrap environments.
There is no command and comments analysis in verbatim blocks.

=item exclude_include

Colon-separated list of files that should not be included by \input and
\include.

=back

Using these options permits to override the behaviour of the commands defined
in the default lists.

Note: currently, the behaviour of commands specified in the TeX files (see the
B<INLINE CUSTOMIZATION> section) cannot be overriden with these options.

If you don't want to translate the chapters and sections, then you can specify:
 -o untranslated=chapter,section

=head1 INLINE CUSTOMIZATION

The TeX module can be customized with lines starting by "% po4a:".
These lines are interpreted as commands to the parser.
The following commands are recognized:

=over 4

=item % po4a: command I<command1> alias I<command2>

Indicates that the arguments of the I<command1> command should be
treated as the arguments of the I<command2> command.

=item % po4a: command I<command1> I<function1>

Indicates that the I<command1> command should be handled by I<function1>.

=item % po4a: command <command1> x,y,z,t

This permits a better control of the translated arguments and some
verifications of the number of arguments.

The meaning of the x, y, z and t is the following:
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

It could be useful to define commands without argument as "0,0,,"
instead of either translated or untranslated.

=item % po4a: environment <env1> <function1>

Indicates that the I<env1> environment should be handled by I<function1>.

=item % po4a: separator <env> "<regex>"

Indicates that an environment should be split according to the given
regular expression.

The regular expression is delimited by quotes.
It should not create any backreference.
You should use (?:) if you need a group.
It may also need some escapes.  

For example, the LaTeX module uses the "(?:&|\\\\)" regular expression to
translate separately each cell of a table (lines are separated by '\\' and
cells by '&').

The notion of environment is expended to the type displayed in the PO file.
This can be used to split on "\\\\" in the first mandatory argument of the
title command.  In this case, the environment is title{#1}.

=back

See the B<INTERNAL FUNCTIONS> section for the list of function which could be
used for commands or environments.

=cut

# Directory name of the main file.
# It is the directory where included files will be searched.
# See read_file.
my $my_dirname;

# Array of files that should not be included by read_file.
# See read_file.
our @exclude_include;

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

=over 4

=item pre_trans

=cut

sub pre_trans {
    my ($self,$str,$ref,$type)=@_;
    # Preformatting, so that translators don't see
    # strange chars
    my $origstr=$str;
    print STDERR "pre_trans($str)="
        if ($debug{'pretrans'});

    # Accentuated characters
    # FIXME: only do this if the encoding is UTF-8?
#    $str =~ s/${RE_ESCAPE}`a/à/g;
##    $str =~ s/${RE_ESCAPE}c{c}/ç/g; # not in texinfo: @,{c}
#    $str =~ s/${RE_ESCAPE}^e/ê/g;
#    $str =~ s/${RE_ESCAPE}'e/é/g;
#    $str =~ s/${RE_ESCAPE}`e/è/g;
#    $str =~ s/${RE_ESCAPE}`u/ù/g;
#    $str =~ s/${RE_ESCAPE}"i/ï/g;
#    # Non breaking space. FIXME: should we change $\sim$ to ~
#    $str =~ s/~/\xA0/g; # FIXME: not in texinfo: @w{ }

    print STDERR "$str\n" if ($debug{'pretrans'});
    return $str;
}

=item post_trans

=cut

sub post_trans {
    my ($self,$str,$ref,$type)=@_;
    my $transstr=$str;

    print STDERR "post_trans($str)="
        if ($debug{'postrans'});

    # Accentuated characters
#    $str =~ s/à/${ESCAPE}`a/g;
##    $str =~ s/ç/$ESCAPEc{c}/g; # FIXME: not in texinfo
#    $str =~ s/ê/${ESCAPE}^e/g;
#    $str =~ s/é/${ESCAPE}'e/g;
#    $str =~ s/è/${ESCAPE}`e/g;
#    $str =~ s/ù/${ESCAPE}`u/g;
#    $str =~ s/ï/${ESCAPE}"i/g;
#    # Non breaking space. FIXME: should we change ~ to $\sim$
#    $str =~ s/\xA0/~/g; # FIXME: not in texinfo

    print STDERR "$str\n" if ($debug{'postrans'});
    return $str;
}

# Comments are extracted in the parse function.
# They are stored in the @comments array, and then displayed as a PO
# comment with the first translated string of the paragraph.
my @comments = ();

=item translate

Wrapper around Transtractor's translate, with pre- and post-processing
filters.

Comments of a paragraph are inserted as a PO comment for the first
translated string of this paragraph.

=cut

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
    if ($options{'wrap'} and $str =~ m/^(.*?)(\s+)$/s) {
        $str    = $1;
        $spaces = $2;
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

=item get_leading_command($buffer)

This function returns:

=over 4

=item A command name

If no command is found at the beginning of the given buffer, this string
will be empty.  Only commands that can be separated are considered.
The $separated_commands variable contains the space separated list of
these commands.

=item A variant

This indicate if a variant is used.  For example, an asterisk (*) can
be added at the end of sections command to specify that they should
not be numbered.  In this case, this field will contain "*".  If there
is no variant, the field is an empty string.

=item An array of optional arguments

=item An array of mandatory arguments

=item The remaining buffer

The rest of the buffer after the removal of this leading command and
its arguments.  If no command is found, the original buffer is not
touched and returned in this field.

=back

=cut

sub get_leading_command {
    my ($self, $buffer) = (shift,shift);
    my $command = ""; # the command name
    my $variant = ""; # a varriant for the command (e.g. an asterisk)
    my @opts = (); # array of optional arguments
    my @args = (); # array of mandatory arguments
    print STDERR "get_leading_command($buffer)="
        if ($debug{'extract_commands'});

    if ($buffer =~ m/^$RE_ESCAPE([[:alpha:]]+)(\*?)(.*)$/s
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
                    die wrap_ref_mod($self->{ref},
                                     "po4a::tex",
                                     dgettext("po4a", "un-balanced %s in '%s'"),
                                     "[",
                                     $buffer);
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
                    die wrap_ref_mod($self->{ref},
                                     "po4a::tex",
                                     dgettext("po4a", "un-balanced %s in '%s'"),
                                     "{",
                                     $buffer);
                }
            }
            push @args, $arg;
        }
    }

    print STDERR "($command,$variant,@opts,@args,$buffer)\n"
        if ($debug{'extract_commands'});
    return ($command,$variant,\@opts,\@args,$buffer);
}

=item get_trailing_command($buffer)

The same as get_leading_command, but for commands at the end of a buffer.

=cut

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
    while ($buffer =~ m/^(.*\{.*)\}$/s) {
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
                die wrap_ref_mod($self->{ref},
                                 "po4a::tex",
                                 dgettext("po4a", "un-balanced %s in '%s'"),
                                 "}",
                                 $buffer);
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
                die wrap_ref_mod($self->{ref},
                                 "po4a::tex",
                                 dgettext("po4a", "un-balanced %s in '%s'"),
                                 "]",
                                 $buffer);
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

=item translate_buffer

Recursively translate a buffer by separating leading and trailing
commands (those which should be translated separately) from the
buffer.

=cut

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

    if ($buffer =~ /^\s*$/s) {
        return ($buffer, @env);
    }
    # verbatim blocks.
    # Buffers starting by \end{verbatim} are handled after.
    if (@env and $env[-1] eq "verbatim" and $buffer !~ m/^\n?\\end\{verbatim\*?\}/) {
        if($buffer =~ m/^(.*?)(\n?\\end\{verbatim\*?\}.*)$/s) {
            # end of a verbatim block
            my ($begin, $end) = ($1?$1:"", $2);
            my ($t1, $t2) = ("", "");
            if (defined $begin) {
                $t1 = $self->translate($begin,$self->{ref},
                                       $env[-1],
                                       "wrap" => 0);
            }
            ($t2, @env) = translate_buffer($self, $end, @env);
            print STDERR "($t1.$t2,@env)\n"
                if ($debug{'translate_buffer'});
            return ($t1.$t2, @env);
        } else {
            $translated_buffer = $self->translate($buffer,$self->{ref},
                                                  $env[-1],
                                                  "wrap" => 0);
            print STDERR "($translated_buffer,@env)\n"
                if ($debug{'translate_buffer'});
            return ($translated_buffer, @env);
        }
    }
    # early detection of verbatim environment
    if ($buffer =~ /^(\\begin\{verbatim\*?\}\n?)(.*)$/s and length $2) {
        my ($begin, $end) = ($1, $2);
        my ($t1, $t2) = ("", "");
        ($t1, @env) = translate_buffer($self, $begin, @env);
        ($t2, @env) = translate_buffer($self, $end,   @env);

        print STDERR "($t1.$t2,@env)\n"
            if ($debug{'translate_buffer'});
        return ($t1.$t2, @env);
    }
    # detect \begin and \end (if they are not commented)
    if ($buffer =~ /^((?:.*?\n)?                # $1 is
                      (?:[^%]                   # either not a %
                        |                       # or
                         (?<!\\)(?:\\\\)*\\%)*? # a % preceded by an odd nb of \
                     )                          # $2 is a \begin{ with the end of the line
                      (\\(?:begin|end)\{.*)$/sx
        and length $1) {
        my ($begin, $end) = ($1, $2);
        my ($t1, $t2) = ("", "");
        if (is_closed($begin)) {
            ($t1, @env) = translate_buffer($self, $begin, @env);
            ($t2, @env) = translate_buffer($self, $end,   @env);

            print STDERR "($t1.$t2,@env)\n"
                if ($debug{'translate_buffer'});
            return ($t1.$t2, @env);
        }
    }

    # remove comments from the buffer.
    # Comments are stored in an array and shown as comments in the PO.
    while ($buffer =~ m/((?<!\\)(?:\\\\)*)%([^\n]*)(\n[ \t]*)(.*)$/s) {
        my $comment = $2;
        my $end = "";
        if ($4 =~ m/^\n/s and $buffer !~ m/^%/s) {
            # a line with comments, followed by an empty line.
            # Keep the empty line, but remove the comment.
            # This is an empirical heuristic, but seems to work;)
            $end = "\n";
        }
        if (defined $comment and $comment !~ /^\s*$/s) {
            push @comments, $comment;
        }
        $buffer =~ s/((?<!\\)(?:\\\\)*)%([^\n]*)(\n[ \t]*)/$1$end/s;
    }
    

    # translate leading commands.
    do {
        # keep the leading space to put them back after the translation of
        # the command.
        my $spaces = "";
        if ($buffer =~ /^(\s+)(.*?)$/s) {
            $spaces = $1;
#            $buffer = $2; # FIXME: this also remove trailing spaces!!
            $buffer =~ s/^\s*//;
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
                if ($buffer =~ /^(\s+)(.*?)$/s) {
                    $spaces = $1;
#                    $buffer = $2;  # FIXME: this also remove trailing spaces!!
                    $buffer =~ s/^\s*//;
                }
                $translated_buffer .= $spaces;
            } else {
                die wrap_ref_mod($self->{ref},
                                 "po4a::tex",
                                 dgettext("po4a", "Unknown command: '%s'"),
                                 $command);
            }
        } else {
            $buffer = $spaces.$buffer;
        }
    } while (length($command));

    # array of trailing commands, which will be translated later.
    my @trailing_commands = ();
    do {
        my $spaces = "";
        if ($buffer =~ /^(.*?)(\s+)$/s) {
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

    # environment specific treatment
    if (@env and defined $env_separators{$env[-1]}) {
        my $re_separator = $env_separators{$env[-1]};
        my $buf_begin = "";
        while ($buffer =~ m/^(.*?)(\s*$re_separator\s*)(.*)$/s) {
            my ($begin, $sep, $end) = ($1, $2, $3);
            $buf_begin .= $begin;
            if (is_closed($buf_begin)) {
                my $t = "";
                ($t, @env) = translate_buffer($self, $buf_begin, @env);
                $translated_buffer .= $t.$sep;
                $buf_begin = "";
            } else {
                # the command is in a command argument
                $buf_begin .= $sep;
            }
            $buffer = $end;
        }
    }

    # finally, translate
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
        if ($buffer =~ /^(.*?)(\s+)$/s) {
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
            die wrap_ref_mod($self->{ref},
                             "po4a::tex",
                             dgettext("po4a", "Unknown command: '%s'"),
                             $command);
        }
    }

    print STDERR "($translated_buffer,@env)\n"
        if ($debug{'translate_buffer'});
    return ($translated_buffer,@env);
}

################################
#### EXTERNAL CUSTOMIZATION ####
################################

=item read

Overload Transtractor's read

=cut

sub read {
    my $self=shift;
    my $filename=shift;

    # keep the directory name of the main file.
    $my_dirname = dirname($filename);

    push @{$self->{TT}{doc_in}}, read_file($self, $filename);
}

=item read_file

Recursively read a file, appending included files which are not listed in the
@exclude_include array.  Included files are searched in the directory of the
input document or in a directory listed in the TEXINPUTS environment variable.

Except from the file inclusion part, it is a cut and paste from
Transtractor's read.

=cut

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
        # TODO: add support for includeonly
        while ($textline =~ /^(.*)\\(include|input)\{([^\{]*)\}(.*)$/) {
            my ($begin,$newfilename,$end) = ($1,$3,$4);
            my $tag = $2;
            my $include = 1;
            foreach my $f (@exclude_include) {
                if ($f eq $newfilename) {
                    $include = 0;
                    $begin .= "\\$tag"."{$newfilename}";
                    $textline = $end;
                    last;
                }
            }
            if ($include and ($tag eq "include")) {
                $begin .= "\\clearpage";
            }
            if ($begin !~ /^\s*$/) {
                push @entries, ($begin,$ref);
            }
            if ($include) {
                # search the file
                foreach (($my_dirname,
                          defined($ENV{"TEXINPUTS"})?
                              split(/:/, $ENV{"TEXINPUTS"}):
                              ".")) {
                    if      (-r "$_/$newfilename") {
                        $newfilename = "$_/$newfilename";
                        last;
                    } elsif (-r "$_/$newfilename.tex") {
                        $newfilename = "$_/$newfilename.tex";
                        last;
                    }
                }
                push @entries, read_file($self,
                                         $newfilename);
                if ($tag eq "include") {
                    $textline = "\\clearpage".$end;
                } else {
                    $textline = $end;
                }
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

=back


=over 4

=item parse_definition_file

Subroutine for parsing a file with po4a directive (definitions for
newcommands).

=cut

sub parse_definition_file {
    my ($self,$filename,$only_try)=@_;

    foreach (($my_dirname,
              defined($ENV{"TEXINPUTS"})?
                  split(/:/, $ENV{"TEXINPUTS"}):
                  ".")) {
        if (-r $_."/".$filename) {
            $filename = $_."/".$filename;
            last;
        }
    }

    if (! open (IN,"<$filename")) {
        warn wrap_mod("po4a::tex",
            dgettext("po4a", "Can't open %s: %s"), $filename, $!);
        if (defined $only_try && $only_try) {
            return;
        } else {
            exit 1;
        }
    }
    while (<IN>) {
        if (/^\s*%\s*po4a\s*:/) {
            parse_definition_line($self, $_);
        }
    }
}

=item parse_definition_line

Parse a definition line of the form "% po4a: ".

See the INLINE CUSTOMIZATION section for more details.

=cut

sub parse_definition_line {
    my ($self,$line)=@_;
    $line =~ s/^\s*%\s*po4a\s*:\s*//;

    if ($line =~ /^command\s+(\*?)(\w+)\s+(.*)$/) {
        my $command = $2;
        $line = $3;
        if ($1) {
            $separated{$command} = 1;
        }
        if ($line =~ /^alias\s+(\w+)\s*$/) {
            if (defined ($commands{$1})) {
                $commands{$command} = $commands{$1};
                if ($commands{$command} eq \&generic_command) {
                    $command_parameters{$command} = $command_parameters{$1};
                }
            } else {
                die wrap_mod("po4a::tex",
                             dgettext("po4a", "Cannot use an alias to the unknown command '%s'"),
                             $2);
            }
        } elsif ($line =~ /^(-1|\d+),(-1|\d+),(-1|[ 0-9]*),(-1|[ 0-9]*?)\s*$/) {
            register_generic("$command,$1,$2,$3,$4");
        } elsif ($line =~ /^(\w+)\s*$/) {
            if (defined &$1) {
                $commands{$command} = \&$1;
            } else {
                die wrap_mod("po4a::tex",
                             dgettext("po4a", "Unknown function (%s) for '%s'"),
                             $1, $command);
            }
        }
    } elsif ($line =~ /^environment\s+(\w+)\s+(.*)$/) {
        my $env = $1;
        $line = $2;
        if ($line =~ /^(\w+)\s*$/) {
            if (defined &$1) {
                $environments{$env} = \&$1;
            } else {
                die wrap_mod("po4a::tex",
                             dgettext("po4a", "Unknown function (%s) for '%s'"),
                             $1, $env);
            }
        }
    } elsif ($line =~ /^separator\s+(\w+(?:\[#[0-9]+\]))\s+\"(.*)\"\s*$/) {
        my $env = $1; # This is not necessarily an environment.
                      # It can also be smth like 'title[#1]'.
        $env_separators{$env} = $2
    }
}

=item is_closed

=cut

sub is_closed {
    my $paragraph = shift;
# FIXME: [ and ] are more difficult to handle, because it is not easy to detect if it introduce an optional argument
    my $tmp = $paragraph;
    my $closing = 0;
    my $opening = 0;
    # FIXME: { and } should not be counted in verbatim blocks
    # Remove comments
    $tmp =~ s/(?<!\\)(?:\\\\)*%.*//mg;
    while ($tmp =~ /^.*?(?<!\\)(?:\\\\)*\{(.*)$/s) {
        $opening += 1;
        $tmp = $1;
    }
    $tmp = $paragraph;
    # Remove comments
    $tmp =~ s/(?<!\\)(?:\\\\)*%.*//mg;
    while ($tmp =~ /^.*?(?<!\\)(?:\\\\)*\}(.*)$/s) {
        $closing += 1;
        $tmp = $1;
    }
    return $opening eq $closing;
}

#############################
#### MAIN PARSE FUNCTION ####
#############################
=item parse

=cut

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

        if ($line =~ /^\s*%\s*po4a\s*:/) {
            parse_definition_line($self, $line);
            goto LINE;
        }

        my $closed = is_closed($paragraph);

        if ($closed and $line =~ /^\s*$/) {
            # An empty line. This indicates the end of the current
            # paragraph.
            $paragraph .= $line."\n";
            if (length($paragraph)) {
                ($t, @env) = translate_buffer($self,$paragraph,@env);
                $self->pushline($t);
                $paragraph="";
                @comments = ();
            }
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


=item docheader()

=back

=cut

sub docheader {
    return "% This file was generated with po4a. Translate the source file.\n".
           "%\n";
}


####################################
#### DEFINITION OF THE COMMANDS ####
####################################

=head1 INTERNAL FUNCTIONS used to write derivated parsers

Command and environment functions take the following arguments (in
addition to the $self object):

=over 4

=item A command name

=item A variant

=item An array of optional arguments

=item An array of mandatory arguments

=item The current environment

=back

The first 4 arguments are extracted by get_leading_command or
get_trailing_command.

Command and environment functions return the translation of the command
with its arguments and a new environment.

Environment functions are called when a \begin command is found. They are
called with the \begin command and its arguments.

=head2 Command functions

=over 4

=item translate_joined

Every argument of the command is translated separately, and the command is
reassembled with its arguments in the output document.

=item untranslated

No argument of the command is proposed for translation. The command is
reassembled with its arguments in the output document.

=back

=head2 Environment functions

=over 4

=item push_environment

This function push the environment name in a stack, and push the \begin command
untranslated in the output document.
This stack of environments is then used to change the behaviour of the parser
(e.g. blocks are not re-wrapped in the verbatim environment).
The type of PO strings is either set to the last environment of this stack or
to the name of the command (if the string is part of a command argument).

=back

=cut

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

# FIXME: a \begin{env} can be followed by an argument. For example:
# \begin{important}[the law of conservation of energy]
$commands{'begin'}= sub {
    my $self = shift;
    my ($command,$variant,$opts,$args,$env) = (shift,shift,shift,shift,shift);
    print "begin($command,$variant,@$opts,@$args,@$env)="
        if ($debug{'commands'} || $debug{'environments'});
    my ($t,@e) = ("",());

    my $envir = $args->[0];
    if (defined($envir) and $envir =~ /^(.*)\*$/) {
        $envir = $1;
    }

    if (defined($env) && defined($environments{$envir})) {
        ($t, @e) = &{$environments{$envir}}($self,$command,$variant,
                                            $opts,$args,$env);
    } else {
        die wrap_mod("po4a::tex",
                     dgettext("po4a", "unknown environment: '%s'"),
                     $args->[0]);
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
        warn wrap_mod("po4a::tex",
                      dgettext("po4a", "unmatched end of environment '%s'"),
                      $args->[0]);
    } else {
        pop @$env;
    }

    my ($t,@e) = untranslated($self,$command,$variant,$opts,$args,$env);

    print "($t, @$env)\n"
        if ($debug{'commands'} || $debug{'environments'});
    return ($t, @$env);
};

sub generic_command {
    my $self = shift;
    my ($command,$variant,$opts,$args,$env) = (shift,shift,shift,shift,shift);
    print "generic_command($command,$variant,@$opts,@$args,@$env)="
        if ($debug{'commands'} || $debug{'environments'});
    my ($t,@e)=("",());

    # check number of arguments
    die wrap_mod("po4a::tex",
                 dgettext("po4a", "wrong number of optional arguments for command '%s'"),
                 $command)
        if (    scalar($command_parameters{$command}{'nb_opts'}) lt scalar(@$opts)
            and $command_parameters{$command}{'nb_opts'} ne -1);
    if (    $command_parameters{$command}{'nb_args'} ne scalar(@$args)
        and $command_parameters{$command}{'nb_args'} ne -1) {
        unless (    $command_parameters{$command}{'nb_args'} eq (scalar(@$args) - 1)
                and !length(@$args[-1])) {
            die wrap_mod("po4a::tex",
                         dgettext("po4a",
                                  "wrong number of arguments for command '%s'"),
                         $command);
        }
    }

    my $translated = "$ESCAPE$command$variant";
    my $arg=1;
    # handle optional arguments
    foreach my $opt (@$opts) {
        my $have_to_be_translated = 0;
        # if translated_opts = -1, all arguments are translated
        # if translated_opts = 0, no argument is translated
        # else, translated_opts contains the space separated list
        #       of the translated arguments
        if ($command_parameters{$command}{'translated_opts'} eq -1) {
            $have_to_be_translated = 1;
        } elsif ($command_parameters{$command}{'translated_opts'} ne 0) {
            foreach (split(/ /, $command_parameters{$command}{'translated_opts'})) {
                $have_to_be_translated = 1 if ($_ eq $arg);
            }
        }
        if ($have_to_be_translated) {
            ($t, @e) = translate_buffer($self,$opt,(@$env,$command."{#$arg}"));
        } else {
            $t = $opt;
        }
        $translated .= "[".$t."]";
        $arg+=1;
    }
    # handle arguments
    $arg=1;
    foreach my $opt (@$args) {
        my $have_to_be_translated = 0;
        if ($command_parameters{$command}{'translated_args'} eq -1) {
            $have_to_be_translated = 1;
        } elsif ($command_parameters{$command}{'translated_args'} ne 0) {
            foreach (split(/ /, $command_parameters{$command}{'translated_args'})) {
                $have_to_be_translated = 1 if ($_ eq $arg);
            }
        }
        if ($have_to_be_translated) {
            ($t, @e) = translate_buffer($self,$opt,(@$env,$command."[#$arg]"));
        } else {
            $t = $opt;
        }
        $translated .= "{".$t."}";
        $arg+=1;
    }

    print "($translated, @$env)\n"
        if ($debug{'commands'} || $debug{'environments'});
    return ($translated, @$env);
}

sub register_generic {
    my ($command, $nb_opts, $nb_args, $translated_opts, $translated_args) = split(/,/, $_[0]);
    if ($command =~ /^\*(.*)$/) {
        $command = $1;
        $separated{$command}=1;
    }

    $command_parameters{$command} = {
        'nb_opts'         => $nb_opts,         # number of optional arguments
        'nb_args'         => $nb_args,         # number of arguments
        # space separated list of indexes of the optional arguments that have
        # to be translated. The first argument is 1 (not 0).
        'translated_opts' => $translated_opts,
        # space separated list of indexes of the arguments that have
        # to be translated. The first argument is 1 (not 0).
        'translated_args' => $translated_args
    };
    $commands{$command} = \&generic_command;
}

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

####################################
### INITIALIZATION OF THE PARSER ###
####################################
sub initialize {
    my $self = shift;
    my %options = @_;

    $self->{options}{'translate'}='';
    $self->{options}{'untranslated'}='';
    $self->{options}{'exclude_include'}='';
    $self->{options}{'no_wrap'}='';
    $self->{options}{'debug'}='';
    $self->{options}{'verbose'}='';

    %debug = ();
    # FIXME: %commands and %separated should also be restored to their
    #        default values.

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

    if ($options{'exclude_include'}) {
        foreach (split(/:/, $options{'exclude_include'})) {
            push  @exclude_include, $_;
        }
    }

    if ($options{'no_wrap'}) {
        foreach (split(/,/, $options{'no_wrap'})) {
            $no_wrap_environments .= " $_";
        }
    }

    foreach (split(/ /, $command_categories{'untranslated'})) {
        if (defined($commands{$_})) {
            # FIXME: Should we allow to redefine commands
            #        No die, because this function is called twice during
            #        gettextization.
        }
        $commands{$_} = \&untranslated;
    }

    foreach (split(/ /, $command_categories{'translate_joined'})) {
        if (defined($commands{$_})) {
            # FIXME: Should we allow to redefine commands
            #        No die, because this function is called twice during
            #        gettextization.
        }
        $commands{$_} = \&translate_joined;
    }

    # commands provided on the command line have an higher priority
    # FIXME: commands defined in the files have an even higher priority
    if ($options{'translate'}) {
        foreach (split(/,/, $options{'translate'})) {
            $commands{$_} = \&translate_joined;
        }
    }
    if ($options{'untranslated'}) {
        foreach (split(/,/, $options{'untranslated'})) {
            $commands{$_} = \&untranslated;
        }
    }

    # build an hash with keys in $separated_commands to ease searches.
    foreach (split(/ /, $separated_commands)){
        $separated{$_}=1;
    };
}

=head1 STATUS OF THIS MODULE

This module needs more tests.

It was tested on a book and with the Python documentation.

=head1 TODO LIST

=over 4

=item other categories

A verbatim category may be needed to indicate that po4a should not attempt
to rewrap lines, and that percent signs do not introduce any comment.

=item Others

Various other points are tagged TODO in the source.

=back

=head1 KNOWN BUGS

=over 4

=item environments

Arguments of the begin command are never translated.
There is currently only one environment function.
More functions should come in future releases.

=item commands

The parser assumes every command is followed by optional arguments (enclosed in
[]) and then by mandatory arguments (enclosed in {}).

=item Others

Various other points are tagged FIXME in the source.

=back

=head1 SEE ALSO

L<po4a(7)|po4a.7>,
L<Locale::Po4a::TransTractor(3pm)|Locale::Po4a::TransTractor>.

=head1 AUTHORS

 Nicolas François <nicolas.francois@centraliens.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, 2005 by Nicolas FRANÇOIS <nicolas.francois@centraliens.net>.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see the COPYING file).

=cut

1;
