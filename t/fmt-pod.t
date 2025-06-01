#! /usr/bin/perl
# config file tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;
push @tests,
  {
    doc    => 'Basic testing of POD constructs',
    format => 'pod',
    input  => 'fmt/pod/basic.pod',
  },
  {
    format  => 'pod',
    input   => 'fmt/pod/no-warn-simple.pod',
    options => '-o no-warn-simple',
  },
  {
    doc          => 'Pertaining to the reported issues',
    format       => 'pod',
    input        => 'fmt/simplepod/issues.pod',
    norm         => 'fmt/pod/issues.norm',
    potfile      => 'fmt/pod/issues.pot',
    pofile       => 'fmt/pod/issues.po',
    norm_stderr  => 'fmt/pod/issues.norm.stderr',
    trans        => 'fmt/pod/issues.trans',
    trans_stderr => 'fmt/pod/issues.trans.stderr',
    options      => '-o no-warn-simple',
  },
  {
    doc          => 'Complete set of syntaxes from podlators',
    format       => 'pod',
    input        => 'fmt/simplepod/podlators.pod',
    norm         => 'fmt/pod/podlators.norm',
    potfile      => 'fmt/pod/podlators.pot',
    pofile       => 'fmt/pod/podlators.po',
    norm_stderr  => 'fmt/pod/podlators.norm.stderr',
    trans        => 'fmt/pod/podlators.trans',
    trans_stderr => 'fmt/pod/podlators.trans.stderr',
    options      => '-o no-warn-simple',
  },
  {
    doc          => 'Various miscellaneous test cases',
    format       => 'pod',
    input        => 'fmt/simplepod/misc.pod',
    norm         => 'fmt/pod/misc.norm',
    potfile      => 'fmt/pod/misc.pot',
    pofile       => 'fmt/pod/misc.po',
    norm_stderr  => 'fmt/pod/misc.norm.stderr',
    trans        => 'fmt/pod/misc.trans',
    trans_stderr => 'fmt/pod/misc.trans.stderr',
    options      => '-o no-warn-simple',
  };

run_all_tests(@tests);

0;
