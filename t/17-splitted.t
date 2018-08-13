# Splitted mode tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'run'  => 'perl ../po4a -f t-17-splitted/test0.conf > tmp/err 2>&1',
    'test' => "diff -u t-17-splitted/test0.err tmp/err 1>&2 "
      . "&& cp t-05-config/test00.pot tmp/test0-mod.pot "
      . "&& perl compare-po.pl --no-ref tmp/test0-mod.pot tmp/test00_man.1.pot "
      . "&& cp t-11-man/dot1.pot tmp/dot1-mod.pot "
      . "&& perl compare-po.pl --no-ref tmp/dot1-mod.pot tmp/dot1.pot",
    'doc' => 'splitted mode'
  },
  {
    'run'  => 'perl ../po4a -f t-17-splitted/test1.conf > tmp/err 2>&1',
    'test' => "diff -u t-17-splitted/test1.err tmp/err 1>&2 "
      . "&& sed -e 's, t-02-addendums/man:[0-9]*,,' tmp/man02.pot > tmp/test1-man02.pot "
      . "&& perl compare-po.pl t-21-TransTractors/man.po-empty tmp/test1-man02.pot "
      . "&& msgfilter sed d < t-02-addendums/man.po-ok 2>/dev/null | sed -e '/^#[:,]/d' > tmp/test1-man03a.pot "
      . "&& sed -e '/^#[:,]/d' tmp/man03.pot > tmp/test1-man03b.pot "
      . "&& perl compare-po.pl tmp/test1-man03a.pot tmp/test1-man03b.pot",
    'doc' => 'splitted mode'
  };

run_all_tests(@tests);
0;
