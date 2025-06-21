#! /usr/bin/perl
# config file tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;
push @tests,
  {
    'doc'    => 'Basic testing of POD constructs',
    'format' => 'pod',
    'input'  => 'fmt/pod/basic.pod',
  },
  {
    'format'  => 'pod',
    'input'   => 'fmt/pod/no-warn-simple.pod',
    'options' => '-o no-warn-simple',
  };

run_all_tests(@tests);

0;
