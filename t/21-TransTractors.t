# Man and Pod module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

my @formats = qw(man pod);

for my $format (@formats) {
    push @tests,
      {
        'run' =>
"perl ../po4a-gettextize -f $format -m t-21-TransTractors/$format -p tmp/po",
        'test' =>
          "perl compare-po.pl t-21-TransTractors/$format.po-empty tmp/po",
        'doc' => "gettextize $format document with only the original",
      },
      {
        'run' =>
"perl ../po4a-gettextize -f $format -m t-21-TransTractors/$format -l t-21-TransTractors/$format.fr -L ISO-8859-1 -p tmp/po 2>/dev/null",
        'test' => "perl compare-po.pl t-21-TransTractors/$format.po tmp/po",
        'doc'  => "gettextize $format page with original and translation",
      },
      {
        'run' =>
"cp t-21-TransTractors/$format.po tmp/po && perl ../po4a-updatepo -f $format -m t-21-TransTractors/$format -p tmp/po >/dev/null 2>&1 ",
        'test' => "perl compare-po.pl t-21-TransTractors/$format.po tmp/po",
        'doc'  => "updatepo for $format document",
      },
      {
        'run' =>
"perl ../po4a-translate -f $format -m t-21-TransTractors/$format -p t-21-TransTractors/$format.po-ok -l tmp/$format.fr",
        'test' =>
"diff -u t-21-TransTractors/$format.fr-normalized tmp/$format.fr 1>&2",
        'doc' => "translate $format document",
      };
}

run_all_tests(@tests);
0;
