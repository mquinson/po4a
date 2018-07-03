# Texinfo module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'doc' => "longmenu normalization test",
    'run' =>
"perl ../po4a-normalize -f texinfo t-18-texinfo/longmenu.texi > tmp/longmenu.err 2>&1"
      . "&& mv po4a-normalize.po tmp/longmenu.po "
      . "&& mv po4a-normalize.output tmp/longmenu.out ",
    'test' => "perl compare-po.pl t-18-texinfo/longmenu.pot tmp/longmenu.po "
      . "&& diff -u t-18-texinfo/longmenu.out tmp/longmenu.out 1>&2"
      . "&& diff -u t-18-texinfo/longmenu.err tmp/longmenu.err 1>&2"
  };
push @tests,
  {
    'doc' => "longmenu translation test",
    'run' =>
"perl ../po4a-translate -f texinfo -m t-18-texinfo/longmenu.texi -l tmp/longmenu-trans.texi -p t-18-texinfo/longmenu.po",
    'test' =>
      "diff -u t-18-texinfo/longmenu-trans.texi tmp/longmenu-trans.texi 1>&2"
  };

run_all_tests(@tests);
0;
