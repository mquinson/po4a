#! /usr/bin/perl
# msguntypot tester.

#########################

use strict;
use warnings;

use lib q(t);

use Test::More 'no_plan';
use File::Path qw(make_path remove_tree);

BAIL_OUT("Tests cannot be run as root. Please use a regular user ID instead.\n") if $> == 0;

my @cmds = (
    "chmod 755 t/cfg",
    "chmod 755 `find t/add t/cfg -maxdepth 1 -type d`",
    "chmod 755 `find t/add t/cfg -maxdepth 2 -type d`",
    "chmod 755 `find t/add t/cfg -type d`",
    "chmod 644 `find t -type f`"
);

foreach my $cmd (@cmds) {
    my $exit_status = system($cmd);
    if ( $exit_status == 0 ) {
        pass($cmd);
    } else {
        BAIL_OUT( $cmd . " (retcode: $exit_status)" );
    }
}

0;
