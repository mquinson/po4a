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
    'format' => 'man',
    'input'  => 'fmt/man/quotes.man'
  },
  {
    'format' => 'man',
    'input'  => 'fmt/man/quoted-comment.man',
  },
  {
    'format' => 'man',
    'input'  => 'fmt/man/dots1.man',
  },
  {
    'format' => 'man',
    'input'  => 'fmt/man/dots-errors1.man',
    'error'  => 1,
  },
  {
    'format' => 'man',
    'input'  => 'fmt/man/dots-errors2.man',
    'error'  => 1,
  },
  {
    'format' => 'man',
    'input'  => 'fmt/man/dots-errors3.man',
    'error'  => 1,
  },
  {
    'format' => 'man',
    'input'  => 'fmt/man/dots2.man',
  },
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

foreach my $t (
    qw(fonts mdoc tbl-textblock tbl-option-tab
    tbl-mdoc-mixed1 tbl-mdoc-mixed2 tbl-mdoc-mixed3 tbl-mdoc-mixed4
    spaces macros)
  )
{
    push @tests,
      {
        'format' => 'man',
        'input'  => "fmt/man/$t.man",
      };
}
run_all_tests(@tests);
0;
