# TeX module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

foreach my $t (qw(basic theorem)) {
    push @tests,
      {
        'format' => 'latex',
        'input'  => "fmt/tex/$t.tex"
      };
}

run_all_tests(@tests);
0;
