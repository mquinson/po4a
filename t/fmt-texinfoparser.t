# Texinfo based on Parser module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;
use Test::More;

my @tests;

SKIP:
{
  eval {require Texinfo};
  skip "cannot load Texinfo module" if $@;

for my $test (
    qw(longmenu partialmenus comments tindex commandsinpara
    conditionals texifeatures macrovalue linemacro verbatimignore
    topinifnottex topinifnotdocbook invalidlineecount tsetfilename)
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

push @tests,
  {
    'format'  => 'texinfoparser',
    'input'   => "fmt/texinfoparser/tdocumentlanguage.texi",
    'pofile'  => 'fmt/texinfoparser/fr.po',
    'options' => '-o no-warn',
  };

run_all_tests(@tests);

}

0;
