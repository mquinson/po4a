#! /usr/bin/perl
# SGML module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'doc' => "gettextize well simple xml documents",
    'run' =>
"perl ../po4a-gettextize -f sgml -o force -m t-16-sgml/text.xml -p tmp/xml.po",
    'test'     => "perl compare-po.pl t-16-sgml/xml.po tmp/xml.po",
    'requires' => "Text::WrapI18N",
  },
  {
    'doc' => "normalisation test",
    'run' => 'perl ../po4a-normalize -f sgml t-16-sgml/test2.sgml '
      . '&& mv po4a-normalize.po tmp '
      . '&& mv po4a-normalize.output tmp',
    'test' => 'perl compare-po.pl t-16-sgml/test2.pot tmp/po4a-normalize.po'
      . ' && perl compare-po.pl t-16-sgml/test2-normalized.sgml tmp/po4a-normalize.output',

  };

run_all_tests(@tests);
0;
