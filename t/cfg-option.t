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
    'doc'            => 'space in option value',
    'po4a.conf'      => 'cfg/space-in-option-value/po4a.conf',
    'modes'          => 'dstdir',
    'expected_files' => 'man.pot man.ja.po man.ja.1'
  };

run_all_tests(@tests);

0;
