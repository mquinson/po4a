# XML and XML-based modules tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'run'  => 'perl ../../po4a-normalize -f guide ../t-24-xml/general.xml',
    'test' => 'perl ../compare-po.pl ../t-24-xml/general.po po4a-normalize.po'
      . ' && perl ../compare-po.pl ../t-24-xml/general-normalized.xml po4a-normalize.output',
    'doc' => 'normalisation test',
  };
push @tests,
  {
    'run'  => 'perl ../../po4a-normalize -f guide ../t-24-xml/comments.xml',
    'test' => 'perl ../compare-po.pl ../t-24-xml/comments.po po4a-normalize.po'
      . ' && perl ../compare-po.pl ../t-24-xml/comments-normalized.xml po4a-normalize.output',
    'doc' => 'normalisation test',
  };
push @tests,
  {
    'run' =>
"perl ../../po4a-normalize -f xml -o translated='w<translate1w> W<translate2W> <translate5> i<inline6> ' -o untranslated='<untranslated4>' ../t-24-xml/options.xml",
    'test' => 'perl ../compare-po.pl ../t-24-xml/options.po po4a-normalize.po'
      . ' && perl ../compare-po.pl ../t-24-xml/options-normalized.xml po4a-normalize.output',
    'doc' => 'normalisation test',
  };
push @tests,
  {
    'run'  => "perl ../../po4a-normalize -f guide ../t-24-xml/cdata.xml",
    'test' => 'perl ../compare-po.pl ../t-24-xml/cdata.po po4a-normalize.po'
      . ' && perl ../compare-po.pl ../t-24-xml/cdata.xml po4a-normalize.output',
    'doc' => 'normalisation test',
  };

run_all_tests(@tests);
0;
