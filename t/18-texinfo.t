# Texinfo module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'doc'       => "longmenu normalization test",
    'normalize' => "-f texinfo t-18-texinfo/longmenu.texi",
  };

run_all_tests(@tests);
0;
