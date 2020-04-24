#! /usr/bin/perl
# RubyDoc module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

foreach my $t (qw(Headlines Lists)) {
    push @tests,
      {
        'format' => 'Rd',
        'input'  => "fmt/rubydoc/$t.rd"
      };
}

foreach my $pure (qw(Verbatim)) {
    push @tests,
      {
        'format'  => 'Rd',
        'options' => '-o puredoc',
        'input'   => "fmt/rubydoc/$pure.rd"
      };
}

run_all_tests(@tests);
0;
