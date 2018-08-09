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
    'doc'       => 'normalisation test',
    'normalize' => "-f ini t-10-ini/test1.ini",
  };

run_all_tests(@tests);
0;
