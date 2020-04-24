#! /usr/bin/perl
# DIA module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'doc'    => "Extract only the strings that we should",
    'format' => 'dia',
    'input'  => 'fmt/xml-dia/basic.dia',
  },
  {
    'doc'    => "test translations with extraneous newlines",
    'format' => 'dia',
    'input'  => 'fmt/xml-dia/transl.dia',
  };

run_all_tests(@tests);
0;
