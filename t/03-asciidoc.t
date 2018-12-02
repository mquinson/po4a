#! /usr/bin/perl
# Text module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

my @AsciiDocTests = qw(Titles BlockTitles BlockId Paragraphs
  DelimitedBlocks Lists Footnotes Callouts Comments Tables Attributes StyleMacro);
foreach my $AsciiDocTest (@AsciiDocTests) {

    # Tables are currently badly supported.
    # Mark the test as TODO.
    my $todo = "";
    push @tests,
      {
        'todo'      => $todo,
        'normalize' => "-f asciidoc t-03-asciidoc/$AsciiDocTest.asciidoc",
        'doc'       => "$AsciiDocTest test"
      };
}

push @tests,
  {
    'normalize' => "-f asciidoc -o noimagetargets=1 t-03-asciidoc/NoImageTarget.asciidoc",
    'doc'      => "test ignoring image targets",
    'requires' => "Unicode::GCString"
  },
  {
    'run' =>
"perl ../po4a-gettextize -f asciidoc -m t-03-asciidoc/Titles.asciidoc -l t-03-asciidoc/TitlesUTF8.asciidoc -L UTF-8 -p tmp/TitlesUTF8.po",
    'test' =>
"perl compare-po.pl --no-ref t-03-asciidoc/TitlesUTF8.po tmp/TitlesUTF8.po",
    'doc'      => "test titles with UTF-8 encoding",
    'requires' => "Unicode::GCString"
  },
  {
    'run' =>
"msgattrib --clear-fuzzy -o tmp/TitlesUTF8.po tmp/TitlesUTF8.po && perl ../po4a-translate -f asciidoc -m t-03-asciidoc/Titles.asciidoc -l tmp/TitlesUTF8.asciidoc -p tmp/TitlesUTF8.po",
    'test' =>
      "diff tmp/TitlesUTF8.asciidoc t-03-asciidoc/TitlesUTF8.asciidoc 1>&2",
    'doc'      => "translate titles with UTF-8 encoding",
    'requires' => "Unicode::GCString"
  },
  {
    'run' =>
"perl ../po4a-gettextize -f asciidoc -m t-03-asciidoc/Titles.asciidoc -l t-03-asciidoc/TitlesLatin1.asciidoc -L iso-8859-1 -p tmp/TitlesLatin1.po",
    'test' =>
"perl compare-po.pl --no-ref t-03-asciidoc/TitlesLatin1.po tmp/TitlesLatin1.po",
    'doc'      => "test titles with latin1 encoding",
    'requires' => "Unicode::GCString"
  },
  {
    'run' =>
"msgattrib --clear-fuzzy -o tmp/TitlesLatin1.po tmp/TitlesLatin1.po && perl ../po4a-translate -f asciidoc -m t-03-asciidoc/Titles.asciidoc -l tmp/TitlesLatin1.asciidoc -p tmp/TitlesLatin1.po",
    'test' =>
      "diff tmp/TitlesLatin1.asciidoc t-03-asciidoc/TitlesLatin1.asciidoc 1>&2",
    'doc'      => "translate titles with latin1 encoding",
    'requires' => "Unicode::GCString"
  };

run_all_tests(@tests);
0;
