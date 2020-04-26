#! /usr/bin/perl
# Ini module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'format' => 'halibut',
    'input'  => 'fmt/halibut/basic.but'
  };

run_all_tests(@tests);
0;
