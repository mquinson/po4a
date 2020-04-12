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
    'doc'      => "gettextize well simple xml documents",
    'run'      => "PATH/po4a-gettextize -f sgml -o force -m t-16-sgml/text.xml -p tmp/xml.po",
    'tests'    => ["PODIFF t-16-sgml/xml.po tmp/xml.po"],
    'requires' => "Text::WrapI18N",
  },
  {
    'doc'   => "normalisation test",
    'run'   => 'PATH/po4a-normalize --format sgml --localized tmp/test2.sgml --pot tmp/test2.pot t-16-sgml/test2.sgml ',
    'tests' => [ 'PODIFF t-16-sgml/test2.pot tmp/test2.pot', 'PODIFF t-16-sgml/test2-normalized.sgml tmp/test2.sgml', ],
  };

run_all_tests(@tests);
0;
