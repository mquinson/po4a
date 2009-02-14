#!/usr/bin/perl -w
use strict;
use warnings;

# Copyright 2009 by Javier Fernández-Sanguino Peña <jfs@debian.org>
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



# Quick and dirty script to compare two msgids (when using PO files
# generated with --previous) with wdiff to find the differences between
# them.
# Usage: perl compare-msgids.pl < XX.po


use File::Temp;

my $DIFF1 = new File::Temp(TEMPLATE => "compare-msgids.XXXXXX");
my $DIFF2 = new File::Temp(TEMPLATE => "compare-msgids.XXXXXX");

my $fileh="";

my $diffblock = 0; # Does the current block has a --previous string?
my $nowrap = 0;    # Can the current be rewrapped?
my $ref = "";      # Line reference for the current block

while (my $line = <STDIN>) {
    $fileh="";
    chomp $line;

    $ref .= $line."\n" if $line =~ /^#: /;
    $ref = "" if ($line eq "");

    if ( $diffblock and $line =~ /^msgstr/ ) {
        $diffblock = 0;
        $nowrap = 0;
        print $DIFF1 "\n\n";
        print $DIFF2 "\n\n";
    }
    $diffblock = 1 if ( $line =~ /^\#\| msgid/ ) ;
    $nowrap = 1 if ( $line =~ /^#,.*no-wrap/ ) ;

    if ($diffblock) {
        if (length $ref) {
            print $DIFF1 $ref."\n";
            print $DIFF1 $ref."\n";
            print $DIFF2 $ref."\n";
            $ref = "";
        }
        $fileh = $DIFF1 if ( $line =~ /^\#\| msgid/ ) ;
        $fileh = $DIFF1 if ( $line =~ /^\#\| "/ ) ;
        $fileh = $DIFF2 if ( $line =~ /^msgid/ ) ;
        $fileh = $DIFF2 if ( $line =~ /^"/ ) ;

        if ($fileh ne "") {
            $line =~ s/^\#\| //;

            print $fileh "\n" if ( $line =~ /^msgid_plural "/);

            $line =~ s/^"//;
            $line =~ s/^msgid "//;
            $line =~ s/^msgid_plural "//;
            $line =~ s/"$//;

            print $fileh $line;
            print $fileh "\n" if ($nowrap and $line =~ m/\\n$/);
        }
    }
}

close $DIFF1; close $DIFF2;

system ("wdiff", "-3", $DIFF1->filename, $DIFF2->filename)
    or die "Failed to run wdiff.";


exit;
