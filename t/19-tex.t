# TeX module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'doc'       => "gettextize well a simple tex document",
    'normalize' => "-f latex t-19-tex/simple.tex",
  };
push @tests,
  {
    'run' => "cp t-19-tex/simple.trans.po tmp && chmod u+w tmp/simple.trans.po"
      . " && LC_ALL=C COLUMNS=80 perl ../po4a-updatepo -f latex -m t-19-tex/simple.tex -p tmp/simple.trans.po > tmp/simple-updatepo.out 2>&1",
    'test' =>
"diff -u -I '^\.* done\.' t-19-tex/simple-updatepo.out tmp/simple-updatepo.out "
      . "&& perl compare-po.pl t-19-tex/simple.trans.po tmp/simple.trans.po",
    'doc' => "updatepo for this document",
  };
push @tests,
  {
    'doc'       => "gettextize well a LaTeX document with theorem environments",
    'normalize' => "-f latex t-19-tex/theorem.tex",
  };

run_all_tests(@tests);
0;
