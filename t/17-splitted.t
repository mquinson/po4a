# Splitted mode tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'run' =>
'LC_ALL=C COLUMNS=80 perl ../../po4a -f ../t-17-splitted/test0.conf > err 2>&1',
    'test' => "diff -u ../t-17-splitted/test0.err err "
      . "&& cp ../t-05-config/test00.pot test0-mod.pot "
      . "&& perl ../compare-po.pl --no-ref test0-mod.pot test00_man.1.pot "
      . "&& cp ../t-11-man/dot1.pot dot1-mod.pot "
      . "&& perl ../compare-po.pl --no-ref dot1-mod.pot dot1.pot",
    'doc' => 'splitted mode'
  };
push @tests,
  {
    'run' =>
'LC_ALL=C COLUMNS=80 perl ../../po4a -f ../t-17-splitted/test1.conf > err 2>&1',
    'test' => "diff -u ../t-17-splitted/test1.err err "
      . "&& sed -e 's, ../t-02-addendums/man:[0-9]*,,' man02.pot > test1-man02.pot "
      . "&& perl ../compare-po.pl ../t-21-TransTractors/man.po-empty test1-man02.pot "
      . "&& msgfilter sed d < ../t-02-addendums/man.po-ok 2>/dev/null | sed -e '/^#[:,]/d' > test1-man03a.pot "
      . "&& sed -e '/^#[:,]/d' man03.pot > test1-man03b.pot "
      . "&& perl ../compare-po.pl test1-man03a.pot test1-man03b.pot",
    'doc' => 'splitted mode'
  };

run_all_tests(@tests);
0;
