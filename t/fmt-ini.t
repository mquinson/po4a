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
    'format' => 'ini',
    'input'  => 'fmt/ini/basic.ini'
  };

run_all_tests(@tests);
0;
