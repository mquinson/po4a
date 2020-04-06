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
    'doc'  => "get only needed strings",
    'run'  => "PATH/po4a-gettextize -f dia -m t-06-dia/extract.dia -p tmp/dia_extract.po",
    'tests' => ["PODIFF t-06-dia/extract.po-ok tmp/dia_extract.po"],
  },
  {
    'doc' => "test translations with new-lines",
    'run' => "PATH/po4a-translate -f dia -m t-06-dia/transl.dia -p t-06-dia/transl.po -l tmp/transl.dia",
    'tests' => ["diff -u t-06-dia/transl.dia-ok tmp/transl.dia"],
  };

run_all_tests(@tests);
0;
