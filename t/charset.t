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
    'expected_files' => 'ascii.pod.up.po ascii.pod.pot ascii.up.pod',	
    # Ignoring any output line that contains the name of a tempfile
    'diff_outfile' => 'diff -u -Itmp/ charset/input/_output tmp/charset/input/output',
  };

run_all_tests(@tests);
0;
