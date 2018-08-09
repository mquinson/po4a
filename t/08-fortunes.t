#! /usr/bin/perl
# Text module tester for fortunes files.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

my @FortunesTests = qw(SingleFortune SeveralFortunes MultipleLines);
foreach my $FortunesTest (@FortunesTests) {
    push @tests,
      {
        'doc'       => "$FortunesTest test",
        'normalize' => "-f text -o fortunes t-08-fortunes/$FortunesTest.txt",
      };
}

run_all_tests(@tests);
0;
