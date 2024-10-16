# Locale::Po4a::RubyDoc -- Convert Ruby Document data to PO file, for translation
#
# Copyright © 2016-2017 Francesco Poli <invernomuto@paranoici.org>
#
# This program is free software; you may redistribute it and/or modify it
# under the terms of GPL v2.0 or later (see COPYING).
#
# This work is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This work is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this work; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#
# Parts of the code (such as many regular expressions) were adapted
# from the source of rdtool, under the terms of the GNU General Public
# License, version 2 or later.
# These parts are originally:
# Copyright © 2004       MoonWolf <moonwolf@moonwolf.com>
# Copyright © 2011-2012  Youhei SASAKI <uwabami@gfd-dennou.org>
#
# The initialize code was adapted from the source of Locale::Po4a::Text,
# under the terms of the GNU General Public License, version 2 or later.
# This code was originally:
# Copyright © 2005-2008  Nicolas FRANÇOIS <nicolas.francois@centraliens.net>
#
############################################################################
#
# This module converts Ruby Document (RD) format to PO files, so that Ruby
# Document formatted texts may be translated. See gettext documentation
# for more details about PO files.
#
############################################################################

package Locale::Po4a::RubyDoc;

use 5.16.0;
use strict;
use warnings;

use parent qw(Locale::Po4a::TransTractor);

use Locale::Po4a::Common;

require Exporter;

######################
#  Global variables  #
######################

my $insiderubydoc = 0;

#############
#  Methods  #
#############

sub initialize {
    my $self    = shift;
    my %options = @_;

    $self->{options}{'debug'}   = 1;
    $self->{options}{'verbose'} = 1;
    $self->{options}{'puredoc'} = 0;

    foreach my $opt ( keys %options ) {
        die wrap_mod( "po4a::rubydoc", dgettext( "po4a", "Unknown option: %s" ), $opt )
          unless exists $self->{options}{$opt};
        $self->{options}{$opt} = $options{$opt};
    }

    if ( defined $options{'puredoc'} ) {

        # initially assume to be already inside the Ruby Document
        $insiderubydoc = 1;
    } else {

        # initially assume to be outside the Ruby Document
        $insiderubydoc = 0;
    }
}

sub docheader {
    return <<EOT;
#
#       *****************************************************
#       *           GENERATED FILE, DO NOT EDIT             *
#       * THIS IS NO SOURCE FILE, BUT RESULT OF COMPILATION *
#       *****************************************************
#
# This file was generated by po4a-translate(1). Do not store it (in VCS,
# for example), but store the PO file used as source file by po4a-translate.
#
# In fact, consider this as a binary, and the PO file as a regular source file:
# If the PO gets lost, keeping this translation up-to-date will be harder.
#
EOT
}

sub parse {
    my $self = shift;

    # start with baseline and firstindent corresponding to no indentation
    my $baseline    = 0;
    my $firstindent = 0;

    # start in non-verbatim mode
    my $verbmode = 0;

    # we have not yet seen any Term, hence we are not yet waiting for a
    # Description
    my $waitfordesc = 0;
    my $methodterm  = "";

    # flag to remember that we have reached the end of the document
    my $eof = 0;

  PARAGRAPH: while () {

        # start accumulating a new paragraph and corresponding variables
        my ( $para, $pref, $ptype, $pwrap, $symbol, $tail ) = ( "", "", "", 1, "", "" );

      LINE: while () {

            # fetch next line and its reference
            my ( $line, $lref ) = $self->shiftline();

            unless ( defined($line) ) {

                # we reached the end of the document
                $eof = 1;
                last LINE;
            }

            if ( $line =~ /^=begin\s*(\bRD\b.*)?\s*$/ ) {

                # we are entering a Ruby Document part
                $insiderubydoc = 1;
                $baseline      = 0;
                $verbmode      = 0;
                $waitfordesc   = 0;
                $self->pushline($line);
                next PARAGRAPH;
            }

            if ( $line =~ /^=end/ ) {

                # we are exiting a Ruby Document part
                $insiderubydoc = 0;
                $baseline      = 0;
                $verbmode      = 0;
                $waitfordesc   = 0;
                $tail          = $line;
                last LINE;
            }

            # do nothing while outside the Ruby Document
            next PARAGRAPH unless ($insiderubydoc);

            # we encountered a Comment: ignore it entirely
            next LINE if ( $line =~ /^#/ );

            if (   $line =~ /^(={1,4})(?!=)\s*(?=\S)(.*)/
                or $line =~ /^(\+{1,2})(?!\+)\s*(?=\S)(.*)/ )
            {
                # we encountered a Headline: this is a paragraph on its own
                if ( length($para) ) {

                    # we already have some paragraph to be processed:
                    # reput the current line in input and end paragraph
                    $self->unshiftline( $line, $lref );
                    last LINE;
                } else {

                    # we are at the beginning of a paragraph, but a Headline
                    # is a single-line paragraph: define the variables
                    # and end paragraph
                    $symbol      = "$1 ";
                    $para        = $2;
                    $pref        = $lref;
                    $ptype       = "Headline $1";
                    $baseline    = 0;
                    $verbmode    = 0;
                    $waitfordesc = 0;
                    last LINE;
                }
            }

            if ( $line =~ /^<<<\s*(\S+)/ ) {

                # we encountered an Include line: end paragraph
                $tail = $line;
                last LINE;
            }

            # compute indentation
            $line =~ /^(\s*)/;
            my $indent = length($1);

            if ($verbmode) {

                # use verbatim mode rules
                # -----------------------

                if ( $indent >= $firstindent ) {

                    # indentation matches first line or is deeper:
                    # the Verbatim goes on
                    $para .= $line;
                    next LINE;
                } else {

                    # indentation is shallower than first line:
                    # reput the current line in input, exit verbatim mode
                    # and end paragraph
                    $self->unshiftline( $line, $lref );
                    $verbmode    = 0;
                    $waitfordesc = 0;
                    last LINE;
                }
            } else {

                # use non-verbatim mode rules
                # ---------------------------

                if ( $line =~ /^\s*$/ ) {

                    # we encountered a WHITELINE: end paragraph
                    $tail = $line;
                    last LINE;
                }

                if ( $line =~ /^(\s*)\*(\s*)(.*)/ ) {

                    # we encountered the first line of a ItemListItem
                    if ( length($para) ) {

                        # we already have some paragraph to be processed:
                        # reput the current line in input and end paragraph
                        $self->unshiftline( $line, $lref );
                        last LINE;
                    } else {

                        # we are at the beginning of a paragraph:
                        # define the variables
                        $symbol = "$1*$2";
                        $para .= $3;
                        $pref        = $lref;
                        $ptype       = "ItemListItem *";
                        $baseline    = length($symbol);
                        $waitfordesc = 0;
                        next LINE;
                    }
                }

                if ( $line =~ /^(\s*)(\(\d+\))(\s*)(.*)/ ) {

                    # we encountered the first line of an EnumListItem
                    if ( length($para) ) {

                        # we already have some paragraph to be processed:
                        # reput the current line in input and end paragraph
                        $self->unshiftline( $line, $lref );
                        last LINE;
                    } else {

                        # we are at the beginning of a paragraph:
                        # define the variables
                        $symbol = "$1$2$3";
                        $para .= $4;
                        $pref        = $lref;
                        $ptype       = "EnumListItem $2";
                        $baseline    = length($symbol);
                        $waitfordesc = 0;
                        next LINE;
                    }
                }

                if ( $line =~ /^(\s*):(\s*)(.*)/ ) {

                    # we encountered the Term line of a DescListItem
                    if ( length($para) ) {

                        # we already have some paragraph to be processed:
                        # reput the current line in input and end paragraph
                        $self->unshiftline( $line, $lref );
                        last LINE;
                    } else {

                        # we are at the beginning of a paragraph, but the Term
                        # part of a DescListItem is a single-line paragraph:
                        # define the variables and end paragraph
                        $symbol      = "$1:$2";
                        $para        = $3;
                        $pref        = $lref;
                        $ptype       = "DescListItem Term :";
                        $baseline    = length($symbol);
                        $waitfordesc = 1;
                        last LINE;
                    }
                }

                if ( $line =~ /^(\s*)---(?!-|\s*$)(\s*)(.*)/ ) {

                    # we encountered the Term line of a MethodListItem
                    if ( length($para) ) {

                        # we already have some paragraph to be processed:
                        # reput the current line in input and end paragraph
                        $self->unshiftline( $line, $lref );
                        last LINE;
                    } else {

                        # we are at the beginning of a paragraph, but the Term
                        # part of a MethodListItem is a single-line paragraph;
                        # moreover, it's not translatable: end paragraph
                        $baseline    = length("$1---$2");
                        $waitfordesc = 2;
                        $tail        = $line;
                        $methodterm  = "--- $3";
                        last LINE;
                    }
                }

                # we apparently encountered a STRINGLINE
                if ( length($para) ) {

                    # we already have some paragraph to be processed:
                    if ( $indent == $baseline ) {

                        # indentation matches baseline:
                        # append the STRINGLINE to the paragraph
                        $para .= $line;
                    } else {

                        # indentation differs from baseline:
                        # reput the current line in input and end paragraph
                        $self->unshiftline( $line, $lref );
                        last LINE;
                    }
                } else {

                    # we are at the beginning of a paragraph:
                    # define the variables
                    if ($waitfordesc) {

                        # we were waiting for a DescListItem Description:
                        # we have just found it
                        if ( $waitfordesc == 1 ) {
                            $ptype = "DescListItem Description";
                        } else {
                            $ptype = "MethodListItem Description $methodterm";
                        }
                        $baseline    = $indent;
                        $waitfordesc = 0;

                        # reproduce the original indentation
                        $symbol = " " x $indent;
                    } else {
                        if ( $indent > $baseline ) {

                            # indentation is deeper than baseline:
                            # we are entering a Verbatim
                            $verbmode    = 1;
                            $ptype       = "Verbatim";
                            $pwrap       = 0;
                            $firstindent = $indent;
                        } else {

                            # indentation is not deeper than baseline:
                            # this is a TextBlock
                            $ptype    = "TextBlock";
                            $baseline = $indent;

                            # reproduce the original indentation
                            $symbol = " " x $indent;
                        }
                    }
                    $para .= $line;
                    $pref = $lref;
                }
            }

        }

        if ( length($para) ) {

            # set wrap column at 76 - identation, but never less than 26
            my $ni = length($symbol);
            my $wc = 76 - $ni;
            $wc = 26 if ( $wc < 26 );

            # get the translated paragraph
            my $translated = $self->translate(
                $para,
                $pref,
                $ptype,
                'wrap'    => $pwrap,
                'wrapcol' => $wc
            );

            if ($pwrap) {

                # reformat the translated paragraph
                my $is = " " x $ni;
                chomp $translated;
                $translated =~ s/\n/\n$is/g;
                $translated .= "\n";
            }

            # push the paragraph to the translated document
            $self->pushline( $symbol . $translated );
        }

        if ( length($tail) ) {

            # push the non translatable tail to the translated document
            $self->pushline($tail);
        }

        # stop processing, if we have already reached the end of the document
        return if ($eof);
    }
}

##########################
#  Module documentation  #
##########################

1;
__END__

=encoding UTF-8

=head1 NAME

Locale::Po4a::RubyDoc -- Convert Ruby Document data from/to PO files

=head1 DESCRIPTION

The po4a (PO for anything) project goal is to ease translations (and more
interestingly, the maintenance of translations) using gettext tools on
areas where they were not expected like documentation.

Locale::Po4a::RubyDoc is a module to help the translation of documentation in
the Ruby Document (RD) format (a language used to document Ruby) into other
[human] languages.

=head1 STATUS OF THIS MODULE

This module has been successfully tested on simple Ruby Document files
covering a good part of the format syntax.

A known limitation is that it fails to properly recognize the stacked
structure of input Ruby Document: this implies that when, for instance,
an EnumListItem consists of more than one Block, only the first Block
is actually recognized as EnumListItem, while the subsequent ones are
considered just as TextBlocks...

=head1 OPTIONS ACCEPTED BY THIS MODULE

This module supports the following option:

=over

=item B<puredoc>

Handle files entirely made of Ruby Document formatted text (without
any "=begin" line).

By default, this module only handles Ruby Document formatted text
between "=begin" and "=end" lines (hence ignoring, among other things,
everything that precedes the first "=begin" line).

=back

=head1 SEE ALSO

L<Locale::Po4a::TransTractor(3pm)>

=head1 AUTHORS

Francesco Poli <invernomuto@paranoici.org>

=head1 COPYRIGHT AND LICENSE

 Copyright © 2016-2017 Francesco Poli <invernomuto@paranoici.org>

This work is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This work is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this work; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.


Parts of the code (such as many regular expressions) were adapted
from the source of rdtool, under the terms of the GNU General Public
License, version 2 or later.
These parts are originally:

 Copyright © 2004      MoonWolf <moonwolf@moonwolf.com>
 Copyright © 2011-2012 Youhei SASAKI <uwabami@gfd-dennou.org>

The initialize code was adapted from the source of Locale::Po4a::Text,
under the terms of the GNU General Public License, version 2 or later.
This code was originally:

 Copyright © 2005-2008 Nicolas FRANÇOIS <nicolas.francois@centraliens.net>

=cut
