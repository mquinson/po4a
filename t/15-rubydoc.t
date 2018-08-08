#! /usr/bin/perl
# RubyDoc module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

my @RubyDocTests = qw(Headlines Verbatim_puredoc Lists);
foreach my $RubyDocTest (@RubyDocTests) {
    my $options = "";
    $options = "-o puredoc" if $RubyDocTest =~ m/_puredoc/;
    push @tests,
      {
        'normalize' => "-f Rd $options t-15-rubydoc/$RubyDocTest.rd",
        'doc'       => "$RubyDocTest test"
      };
}

run_all_tests(@tests);
0;
