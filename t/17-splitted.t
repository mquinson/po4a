# Splitted mode tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'run'   => 'PATH/po4a -f t-17-splitted/test0.conf > tmp/err 2>&1',
    'tests' => [
        "diff -u t-17-splitted/test0.err tmp/err",
        "cp t-05-config/test00.pot tmp/test0-mod.pot",
        "PODIFF -I^#: tmp/test0-mod.pot tmp/test00_man.1.pot",
        "cp t-11-man/dot1.pot tmp/dot1-mod.pot ",
        "PODIFF -I^#: tmp/dot1-mod.pot tmp/dot1.pot",
    ],
    'doc' => 'splitted mode'
  },
  {
    'run'   => 'PATH/po4a -f t-17-splitted/test1.conf > tmp/err 2>&1',
    'tests' => [
        "diff -u t-17-splitted/test1.err tmp/err",
        "PODIFF -I^#: t-21-TransTractors/man.po-empty tmp/man02.pot",
        "PODIFF -I^# t-17-splitted/_man03.pot tmp/man03.pot",
    ],
    'doc' => 'splitted mode'
  };

run_all_tests(@tests);
0;
