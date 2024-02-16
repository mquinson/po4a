# Gemtext module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'format' => 'gemtext',
    'input'  => "fmt/gemtext/basic.gmi",
  };

run_all_tests(@tests);
0;
