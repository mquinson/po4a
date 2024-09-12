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
    'doc'         => 'invalid input command (file does not exist), without ignore',
    'format'      => 'latex',
    'input'       => "fmt/tex/input-in-verbatim.tex",
    'error'       => 1,
    'norm_stderr' => 'fmt/tex/input-in-verbatim.stderr-without-ignore',
  },
  {
    'doc'     => 'invalid input command (file does not exist), with exclude_include',
    'format'  => 'latex',
    'input'   => "fmt/tex/input-in-verbatim.tex",
    'options' => '-o exclude_include=main.tex'
  },
  {
    'doc'     => 'valid input command (file exists and must be included)',
    'format'  => 'latex',
    'input'   => "fmt/tex/input-in-basic.tex",
    'norm'    => "fmt/tex/input-in-basic.norm",
    'potfile' => "fmt/tex/input-in-basic.pot",
    'pofile'  => "fmt/tex/input-in-basic.po",
    'trans'   => "fmt/tex/input-in-basic.trans"
  };

run_all_tests(@tests);
0;
