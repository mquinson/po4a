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
  {    # This is the buggy pre-0.58 behavior where the flow is broken by processing instructions
     # This triggers an unfortunate behavior as the break occurs on the path <screen><userinput> where <screen> is nowrap and <userinput> is inline|wrap.
     # As a result, when the PI breaks within <userinput>, the first part is translated with wrap.
     # When the second part (after the PI) is pushed, we are back in <screen> path, so this part is translated with no-wrap (as it should)
     # The default behavior was changed to ensure that PI are not breaking, but this option is still provided just in case somebody needs PI to be breaking
    'doc'     => 'GH#170: processing instructions should not be breaking',
    'format'  => 'docbook',
    'options' => '-o break-pi',
    'input'   => "fmt/docbook/PI-break.dbk",
  },
  {    # This is ensuring that GH#170 is gone
     # Since the PI is handled as inline, the input (that is the same as previously) now builds only one msgid, produced in <screen> path.
     # The <userinput> is inline as expected, and so is the PI.
    'doc'    => 'GH#170: processing instructions should be inline tags',
    'format' => 'docbook',
    'input'  => "fmt/docbook/PI-inline.dbk",
  };

run_all_tests(@tests);
0;
