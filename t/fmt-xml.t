# XML and XML-based modules tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

for my $g (qw(basic)) {
  push @tests, {'format'=>'guide','input'=>"fmt/xml/$g.xml"};
}

push @tests,
#  {
#  'format'=>'guide',
#  'input' =>'fmt/xml/basic.xml'
#    'doc'       => 'General normalisation test',
#    'normalize' => "-f guide t-24-xml/general.xml",
#  },
  {
    'doc'       => 'Comments normalisation test',
    'normalize' => "-f guide t-24-xml/comments.xml",
  },
  {
    'doc' => 'Options normalisation test',
    'normalize' =>
      "-f xml -o translated='w<translate1w> W<translate2W> <translate5> i<inline6> ' -o untranslated='<untranslated4>' t-24-xml/options.xml",
  },
  {
    'doc'       => 'CDATA normalisation test',
    'normalize' => "-f guide t-24-xml/cdata.xml",
  },
  {
    'doc'       => 'Attribute with no value',
    'normalize' => "-f xml -o attributes='<video>text' t-24-xml/attribute-without-value.xml",
  };

run_all_tests(@tests);
0;
