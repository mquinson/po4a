# Wml module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'doc'       => 'WML normalisation test',
    'normalize' => "-f wml t-22-wml/general.wml",
  };

run_all_tests(@tests);
0;
