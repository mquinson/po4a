#! /usr/bin/perl
# Text module tester for fortunes files.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

foreach my $t (qw(SingleFortune SeveralFortunes MultipleLines)) {
    push @tests,
      {
        'format'  => 'text',
        'options' => '-o fortunes',
        'input'   => "fmt/txt-fortunes/$t.txt"
      };
}

run_all_tests(@tests);
0;
