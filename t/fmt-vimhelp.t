# Vim help module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    format => 'VimHelp',
    input  => "fmt/vimhelp/basic.txt",
  };

run_all_tests(@tests);
0;
