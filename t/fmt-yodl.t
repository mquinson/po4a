#! /usr/bin/perl
# Yodl module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;
push @tests,
  {
    doc    => 'Basic YODL constructs',
    format => 'yodl',
    input  => 'fmt/yodl/basic.yo',
  };
push @tests,
  {
    format => 'yodl',
    input  => 'fmt/yodl/options.yo',
  };

run_all_tests(@tests);
0;
