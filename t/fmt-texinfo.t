# Texinfo module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

for my $test (qw(longmenu comments tindex)) {
    push @tests,
      {
        'format' => 'texinfo',
        'input'  => "fmt/texinfo/$test.texi",
      };
}

run_all_tests(@tests);
0;
