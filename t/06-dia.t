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
    'test' => "diff -u -I'^\"POT-Creation-Date:' -I'^\"PO-Revision-Date:' t-06-dia/extract.po-ok tmp/dia_extract.po 1>&2",
  },
  {
    'doc' => "test translations with new-lines",
    'run' => "PATH/po4a-translate -f dia -m t-06-dia/transl.dia -p t-06-dia/transl.po -l tmp/transl.dia",
    'test' => "diff -u t-06-dia/transl.dia-ok tmp/transl.dia 1>&2",
  };

run_all_tests(@tests);
0;
