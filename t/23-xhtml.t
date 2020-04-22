# Xhtml module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'doc'       => 'XHTML normalisation test',
    'normalize' => "-f xhtml t-23-xhtml/xhtml.html",
  },
  {
    'doc'       => 'includessi test',
    'normalize' => "-f xhtml -o includessi t-23-xhtml/includessi.html",
  },
  {
    'doc'       => 'closing tags are not mandatory in HTML',
    'normalize' => "-f xhtml t-23-xhtml/closing-tag.html",
  };

run_all_tests(@tests);
0;
