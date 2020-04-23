#! /usr/bin/perl
# config file tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;
push @tests, {
    'doc'    => 'Basic testing of WML constructs',
    'format' => 'wml',
    'input'  => 'fmt/wml/basic.wml',

};

run_all_tests(@tests);

0;
