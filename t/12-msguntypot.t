#! /usr/bin/perl
# msguntypot tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'run' => 'cp t-12-msguntypot/test1.po tmp && chmod u+w tmp/test1.po '
      . '&& perl ../scripts/msguntypot -o t-12-msguntypot/test1.old.pot -n t-12-msguntypot/test1.new.pot tmp/test1.po > /dev/null',
    'test' => "perl compare-po.pl t-12-msguntypot/test1.new.po tmp/test1.po",
    'doc'  => 'nominal test',
  },
  {
    'run' => 'cp t-12-msguntypot/test2.po tmp && chmod u+w tmp/test2.po'
      . '&& perl ../scripts/msguntypot -o t-12-msguntypot/test2.old.pot -n t-12-msguntypot/test2.new.pot tmp/test2.po > /dev/null',
    'test' => "perl compare-po.pl t-12-msguntypot/test2.new.po tmp/test2.po",
    'doc'  => 'fuzzy test',
  },
  {
    'run' => 'cp t-12-msguntypot/test3.po tmp && chmod u+w tmp/test3.po '
      . '&& perl ../scripts/msguntypot -o t-12-msguntypot/test3.old.pot -n t-12-msguntypot/test3.new.pot tmp/test3.po > /dev/null',
    'test' => "perl compare-po.pl t-12-msguntypot/test3.new.po tmp/test3.po",
    'doc'  => 'msg moved test',
    'todo' => "Moved strings are not supported. Only typo fixes!",
  },
  {
    'run' => 'cp t-12-msguntypot/test4.po tmp && chmod u+w tmp/test4.po '
      . '&& perl ../scripts/msguntypot -o t-12-msguntypot/test4.old.pot -n t-12-msguntypot/test4.new.pot tmp/test4.po > /dev/null',
    'test' => "perl compare-po.pl t-12-msguntypot/test4.new.po tmp/test4.po",
    'doc'  => 'plural strings (typo in msgid) test',
  },
  {
    'run' => 'cp t-12-msguntypot/test5.po tmp && chmod u+w tmp/test5.po '
      . '&& perl ../scripts/msguntypot -o t-12-msguntypot/test5.old.pot -n t-12-msguntypot/test5.new.pot tmp/test5.po > /dev/null',
    'test' => "perl compare-po.pl t-12-msguntypot/test5.new.po tmp/test5.po",
    'doc'  => 'plural strings (typo in msgid_plural) test',
  },
  {
    'run' => 'cp t-12-msguntypot/test6.po tmp && chmod u+w tmp/test6.po '
      . '&& perl ../scripts/msguntypot -o t-12-msguntypot/test6.old.pot -n t-12-msguntypot/test6.new.pot tmp/test6.po > /dev/null',
    'test' => "perl compare-po.pl t-12-msguntypot/test6.new.po tmp/test6.po",
    'doc'  => 'plural strings (typo in another msgid) test',
  },
  {
    'run' => 'cp t-12-msguntypot/test7.po tmp && chmod u+w tmp/test7.po '
      . '&& perl ../scripts/msguntypot -o t-12-msguntypot/test7.old.pot -n t-12-msguntypot/test7.new.pot tmp/test7.po > /dev/null',
    'test' => "perl compare-po.pl t-12-msguntypot/test7.new.po tmp/test7.po",
    'doc'  => 'plural fuzzy strings (typo in msgid) test',
  },
  {
    'run' => 'cp t-12-msguntypot/test8.po tmp && chmod u+w tmp/test8.po '
      . '&& perl ../scripts/msguntypot -o t-12-msguntypot/test8.old.pot -n t-12-msguntypot/test8.new.pot tmp/test8.po > /dev/null',
    'test' => "perl compare-po.pl t-12-msguntypot/test8.new.po tmp/test8.po",
    'doc'  => 'plural fuzzy strings (typo in msgid_plural) test',
  };

run_all_tests(@tests);
0;
