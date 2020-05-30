#! /usr/bin/perl
# Text module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

foreach my $t (
    qw(Titles BlockTitles BlockId Paragraphs DelimitedBlocks Lists Footnotes Callouts Comments Tables TablesImageText Attributes StyleMacro)
  )
{
    push @tests, { 'format' => 'asciidoc', 'input' => "fmt/asciidoc/$t.adoc" };
}

push @tests,
  {
    'format'  => 'asciidoc',
    'options' => '-o compat=asciidoctor',
    'input'   => 'fmt/asciidoc/StrictDelimitedBlocks.adoc',
    'doc'     => 'asciidoctor block fence parsing',
  },
  {
    'format'  => 'asciidoc',
    'options' => '-o tablecells=1',
    'input'   => 'fmt/asciidoc/TablesCells.adoc',
    'doc'     => 'test table cells segmentation',
  },
  {
    'format'  => 'asciidoc',
    'options' => '-o noimagetargets=1',
    'input'   => "fmt/asciidoc/NoImageTarget.adoc",
    'doc'     => "test ignoring image targets",
  },
  {
    'format'  => 'asciidoc',
    'options' => '-M UTF-8',
    'input'   => "fmt/asciidoc/CharsetUtf.adoc",
  },
  {
    'format' => 'asciidoc',
    'input'  => "fmt/asciidoc/CharsetLatin1.adoc",
  };

run_all_tests(@tests);
0;
