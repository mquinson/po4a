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
    topinifnottex topinifnotdocbook invalidlineecount tsetfilename)
  )
{
    push @tests,
      {
        'format'  => 'texinfoparser',
        'input'   => "fmt/texinfoparser/$test.texi",
        'options' => '-o no-warn',
        'todo'    => 'No release of Texinfo module yet',
      };
}

for my $test (qw(tinclude verbatiminclude)) {
    push @tests,
      {
        'format'  => 'texinfoparser',
        'input'   => "fmt/texinfoparser/$test.texi",
        'options' => '-o no-warn -o include_directories=../xhtml',
        'todo'    => 'No release of Texinfo module yet',
      };
}

push @tests,
  {
    'format'  => 'texinfoparser',
    'input'   => "fmt/texinfoparser/tdocumentlanguage.texi",
    'pofile'  => 'fmt/texinfoparser/fr.po',
    'options' => '-o no-warn',
    'todo'    => 'No release of Texinfo module yet',
  };

run_all_tests(@tests);
0;
