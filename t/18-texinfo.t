# Texinfo module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

for my $test (qw(longmenu comments)) {
  push @tests,
    {
      'doc'       => "$test normalization test",
      'normalize' => "-f texinfo t-18-texinfo/$test.texi",
    };
}

run_all_tests(@tests);
0;
