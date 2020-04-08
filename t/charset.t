#! /usr/bin/perl
# Character sets tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'doc'  => 'various input encoding',
    'po4a.conf' => 'charset/input/po4a.conf',
    'closed_path' => 'charset/*/',
    'options' => '--verbose --keep 0',
    'expected_files' => 'ascii.up.po ascii.pot ascii.up.pod',
  };

run_all_tests(@tests);
0;
