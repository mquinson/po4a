use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;
push @tests,
  {
    format => 'SimplePod',
    input  => 'fmt/simplepod/basic.pod',
  },
  {
    format => 'SimplePod',
    input  => 'fmt/simplepod/podlators.pod',
  };

run_all_tests(@tests);

0;
