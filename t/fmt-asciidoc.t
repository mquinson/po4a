#! /usr/bin/perl
# Text module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

foreach my $t (
    qw(Titles BlockTitles BlockId Paragraphs DelimitedBlocks Lists Footnotes Callouts Comments Tables TablesImageText Attributes StyleMacro MacroIncludesHugo)
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
    'format'  => 'asciidoc',
    'options' => '-o nolinting=1',
    'input'   => "fmt/asciidoc/LineBreak.adoc",
  },
  {
    'format' => 'asciidoc',
    'input'  => "fmt/asciidoc/CharsetLatin1.adoc",
  },
  {
    'format' => 'asciidoc',
    'input'  => "fmt/asciidoc/YamlFrontMatter.adoc",
  },
  {
    'doc'     => "That the yfm_keys and yfm_skip_array options actually work",
    'format'  => 'asciidoc',
    'options' => "-o yfm_skip_array -o yfm_keys='title , subtitle,paragraph'",
    'input'   => "fmt/asciidoc/YamlFrontMatter_Option.adoc",
  };

run_all_tests(@tests);
0;
