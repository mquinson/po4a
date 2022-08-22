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
    'doc'     => 'User macros definition (missing behavior)',
    'input'   => 'fmt/man/macro-def.man',
    'format'  => 'man',
    'norm_stderr' => 'fmt/man/macro-def.stderr-missing-behavior',
    'trans_stderr' => 'fmt/man/macro-def.stderr-missing-behavior',
    'options' => '--option groff_code=verbatim',
  },
  {
    'doc'     => 'User macros definition (untranslated)',
    'input'   => 'fmt/man/macro-def.man',
    'format'  => 'man',
    'options' => '--option groff_code=verbatim -o untranslated=Blob',
  },
  {
    'doc'     => 'User macros definition (noarg)',
    'input'   => 'fmt/man/macro-def.man',
    'format'  => 'man',
    'options' => ' --option groff_code=verbatim -o noarg=Blob',
  },

  {
    'doc'     => 'User macros definition and usage (missing behavior)',
    'input'   => 'fmt/man/macro-defuse.man',
    'norm_stderr' => 'fmt/man/macro-defuse.stderr-missing-behavior',
    'trans_stderr' => 'fmt/man/macro-defuse.stderr-missing-behavior',
    'format'  => 'man',
    'options' => '--option groff_code=verbatim',
    'error'   => 1,
  },
  {
    'doc'     => 'User macros definition and usage (inline)',
    'input'   => 'fmt/man/macro-defuse.man',
    'format'  => 'man',
    'options' => '--option groff_code=verbatim -o inline=Blob',
  },
  {
    'doc'     => 'User macros definition and usage (noarg)',
    'input'   => 'fmt/man/macro-defuse.man',
    'format'  => 'man',
    'options' => ' --option groff_code=verbatim -o noarg=Blob',
    'potfile' => 'fmt/man/macro-defuse.pot-noarg',
    'pofile'  => 'fmt/man/macro-defuse.po-noarg',
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
