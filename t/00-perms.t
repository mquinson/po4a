#! /usr/bin/perl
# msguntypot tester.

#########################

use strict;
use warnings;

use lib q(t);

use Test::More 'no_plan';
use File::Path qw(make_path remove_tree);

# No need to test uid nor to play with chmod on windows
unless ( $^O eq 'MSWin32' ) {

    BAIL_OUT("Tests cannot be run as root. Please use a regular user ID instead.\n") if $> == 0;

    my @cmds = (
        "chmod 755 t/cfg",
        "find t/add t/cfg t/charset -maxdepth 1 -type d -exec chmod 755 {} \\;",
        "find t/add t/cfg t/charset -maxdepth 2 -type d -exec chmod 755 {} \\;",
        "find t/add t/cfg t/charset             -type d -exec chmod 755 {} \\;",
        "find t                                 -type f -exec chmod 644 {} \\;"
    );

    foreach my $cmd (@cmds) {
        my $exit_status = system($cmd);
        if ( $exit_status == 0 ) {
            pass($cmd);
        } else {
            BAIL_OUT( $cmd . " (retcode: $exit_status)" );
        }
    }
}

0;
