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
  },
  {
    'doc'     => 'input command surrounded curly braces',
    'format'  => 'latex',
    'input'   => "fmt/tex/input-merge-basic-surrounded-curly-braces.tex",
    'norm'    => "fmt/tex/input-merge-basic-surrounded-curly-braces.norm",
    'potfile' => "fmt/tex/input-merge-basic-surrounded-curly-braces.pot",
    'pofile'  => "fmt/tex/input-merge-basic-surrounded-curly-braces.po",
    'trans'   => "fmt/tex/input-merge-basic-surrounded-curly-braces.trans"
  },
  {
    'doc'     => 'long text with --width=0 parameter',
    'format'  => 'latex',
    'options' => '--width=0',
    'input'   => "fmt/tex/width0.tex",
  },
  {
    'doc'     => 'long text with --width=-1 parameter',
    'format'  => 'latex',
    'options' => '--width=-1',
    'input'   => "fmt/tex/width0.tex",
  };

run_all_tests(@tests);
0;
