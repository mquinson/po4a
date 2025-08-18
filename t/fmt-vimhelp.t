# Vim help module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    doc    => 'A basic generic test',
    format => 'VimHelp',
    input  => 'fmt/vimhelp/basic.txt',
  },
  { # this should be the same result as the basic one but with slightly different POs
    doc     => '"split_codeblocks" module option',
    format  => 'VimHelp',
    input   => 'fmt/vimhelp/basic.txt',
    options => ' --option split_codeblocks',
    potfile => 'fmt/vimhelp/basic.split.pot',
    pofile  => 'fmt/vimhelp/basic.split.po'
  };

run_all_tests(@tests);
0;
