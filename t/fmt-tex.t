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

push @tests,
  {
    'doc'         => 'invalid input command, without ignore',
    'format'      => 'latex',
    'input'       => "fmt/tex/input-in-verbatim.tex",
    'error'       => 1,
    'norm_stderr' => 'fmt/tex/input-in-verbatim.stderr-without-ignore',
  },
  {
    'doc'     => 'invalid input command, with exclude_include',
    'format'  => 'latex',
    'input'   => "fmt/tex/input-in-verbatim.tex",
    'options' => '-o exclude_include=main.tex'
  };

run_all_tests(@tests);
0;
