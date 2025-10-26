# Texinfo based on Parser module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

for my $test (
    qw(longmenu partialmenus comments tindex commandsinpara
    conditionals texifeatures macrovalue linemacro verbatimignore
    topinifnottex topinifnotdocbook invalidlineecount)
  )
{
    push @tests,
      {
        'format'  => 'texinfoparser',
        'input'   => "fmt/texinfoparser/$test.texi",
        'options' => '-o no-warn',
      };
}

for my $test (qw(tinclude verbatiminclude)) {
    push @tests,
      {
        'format'  => 'texinfoparser',
        'input'   => "fmt/texinfoparser/$test.texi",
        'options' => '-o no-warn -o include_directories=../xhtml',
      };
}

run_all_tests(@tests);
0;
