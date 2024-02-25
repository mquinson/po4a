# Org module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'format' => 'org',
    'input'  => 'fmt/org/basic.org',
  };

run_all_tests(@tests);
0;
