# Xhtml module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'run' =>
'perl ../po4a-gettextize -f xhtml -m t-23-xhtml/xhtml.html -p tmp/xhtml.po',
    'test' => 'perl compare-po.pl t-23-xhtml/xhtml.po tmp/xhtml.po',
    'doc'  => 'Text extraction',
  };
push @tests,
  {
    'run'  => 'perl ../po4a-normalize -f xhtml t-23-xhtml/xhtml.html',
    'test' => 'perl compare-po.pl t-23-xhtml/xhtml.po po4a-normalize.po'
      . ' && perl compare-po.pl t-23-xhtml/xhtml_normalized.html po4a-normalize.output',
    'doc' => 'normalisation test',
  };
push @tests,
  {
    'run' =>
'perl ../po4a-normalize -f xhtml -o includessi t-23-xhtml/includessi.html',
    'test' =>
      'perl compare-po.pl t-23-xhtml/includessi.po po4a-normalize.po'
      . ' && perl compare-po.pl t-23-xhtml/includessi_normalized.html po4a-normalize.output',
    'doc' => 'includessi test',
  };

run_all_tests(@tests);
0;
