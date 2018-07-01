# Wml module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'run'  => 'perl ../../po4a-normalize -f wml ../t-22-wml/general.wml',
    'test' => 'perl ../compare-po.pl ../t-22-wml/general.po po4a-normalize.po'
      . ' && perl ../compare-po.pl ../t-22-wml/general-normalized.wml po4a-normalize.output',
    'doc' => 'normalisation test',
  };

run_all_tests(@tests);
0;
