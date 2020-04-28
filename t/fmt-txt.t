# Text module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'format'  => 'text',
    'options' => '-o keyvalue',
    'input'   => "fmt/txt/KeyValue.text",
  };

run_all_tests(@tests);
0;
