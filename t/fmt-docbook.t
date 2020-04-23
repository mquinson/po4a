# XML and XML-based modules tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'todo'      => 'This bug is not solved yet',
    'doc'       => 'GH#170: <?hard-pagebreak?> breaks processing',
    'normalize' => "-f docbook docbook/hard-pagebreak.xml",
  };

run_all_tests(@tests);
0;
