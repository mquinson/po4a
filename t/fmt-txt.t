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
  },
  {
    'doc'     => "Rewrap output of text file to the given width",
    'format'  => 'text',
    'options' => '-w 40',
    'input'   => "fmt/txt/Width.text",
    'skip'    => { 'updatepo' => 1 }
  },
  {
    'doc'     => "Don't wrap the output at all",
    'format'  => 'text',
    'options' => '--width -1',
    'input'   => "fmt/txt/Width.text",
    'norm'    => "fmt/txt/Width-nowrap.norm",
    'trans'   => "fmt/txt/Width-nowrap.trans",
    'skip'    => { 'updatepo' => 1 }
  };

run_all_tests(@tests);
0;
