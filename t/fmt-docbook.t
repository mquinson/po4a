# XML and XML-based modules tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'format'  => 'docbook',
    'input'   => 'fmt/docbook/debian-history.dbk',
    'doc'     => 'Reduced structure of the debian-history document, with the options used in the real package',
    'options' => "-M UTF-8 -o nodefault='<bookinfo>' -o break='<bookinfo>' -o untranslated='<bookinfo>'",
  },
  {
    'todo'      => 'This bug is not solved yet',
    'doc'       => 'GH#170: <?hard-pagebreak?> breaks processing',
    'normalize' => "-f docbook docbook/hard-pagebreak.xml",
  };

run_all_tests(@tests);
0;
