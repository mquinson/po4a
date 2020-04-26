#! /usr/bin/perl
# SGML module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'format' => 'sgml',
    'input'  => "fmt/sgml/basic.sgml",
  };

run_all_tests(@tests);
0;
