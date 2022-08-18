#! /usr/bin/perl
# Man module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'doc'    => 'null arguments and null paragraphs',
    'format' => 'man',
    'input'  => 'fmt/man/null.man',
  },
  {
    'doc'    => 'escaped newlines and tabs',
    'format' => 'man',
    'input'  => 'fmt/man/escapes.man',
  },
  {
    'doc'     => 'hyphens (verbatim)',
    'input'   => 'fmt/man/hyphens-verbatim.man',
    'format'  => 'man',
    'options' => '-o groff_code=verbatim',
  },
  {
    'doc'     => 'hyphens (translate)',
    'input'   => 'fmt/man/hyphens-translate.man',
    'format'  => 'man',
    'options' => '-o groff_code=translate',
  };

foreach my $t ( qw(fonts dots2 macros mdoc
                   quotes quoted-comment spaces
                   tbl-textblock tbl-option-tab tbl-mdoc-mixed1 tbl-mdoc-mixed2 tbl-mdoc-mixed3 tbl-mdoc-mixed4 ) ) {
    push @tests,  { 'format' => 'man', 'input'  => "fmt/man/$t.man" };
}

foreach my $t (qw(dots-errors1 dots-errors2 dots-errors3)) {
    push @tests, { 'format' => 'man', 'input'  => "fmt/man/$t.man", 'error'  => 1 };

}

run_all_tests(@tests);
0;
