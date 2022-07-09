# Xhtml module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

for my $t (qw(basic includessi closing-tag table)) {
    push @tests, { 'format' => 'xhtml', 'input' => "fmt/xhtml/$t.html" };
}

run_all_tests(@tests);
0;
