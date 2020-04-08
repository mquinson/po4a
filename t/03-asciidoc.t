#! /usr/bin/perl
# Text module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;


foreach my $AsciiDocTest (qw(Titles BlockTitles BlockId Paragraphs DelimitedBlocks Lists Footnotes Callouts Comments Tables Attributes StyleMacro)) {
    push @tests, {
        'normalize' => "-f asciidoc t-03-asciidoc/$AsciiDocTest.asciidoc",
	'doc'       => "$AsciiDocTest test"
    };
}

push @tests, {
    'normalize' => "-f asciidoc -o noimagetargets=1 t-03-asciidoc/NoImageTarget.asciidoc",
    'doc'      => "test ignoring image targets",
    'requires' => "Unicode::GCString"
  }, {
    'run' => "PATH/po4a-gettextize -f asciidoc -m t-03-asciidoc/Titles.asciidoc -l t-03-asciidoc/TitlesUTF8.asciidoc -L UTF-8 -p tmp/TitlesUTF8.po",
    'tests' => ["diff -u -I\'^# \' -I'^\"POT-Creation-Date:' -I'^\"PO-Revision-Date:' t-03-asciidoc/TitlesUTF8.po tmp/TitlesUTF8.po"],
    'doc'      => "test titles with UTF-8 encoding",
    'requires' => "Unicode::GCString"
  }, {
    'run'      => "msgattrib --clear-fuzzy -o tmp/TitlesUTF8.po tmp/TitlesUTF8.po && PATH/po4a-translate -f asciidoc -m t-03-asciidoc/Titles.asciidoc -l tmp/TitlesUTF8.asciidoc -p tmp/TitlesUTF8.po",
    'tests'    => ["diff tmp/TitlesUTF8.asciidoc t-03-asciidoc/TitlesUTF8.asciidoc"],
    'doc'      => "translate titles with UTF-8 encoding",
    'requires' => "Unicode::GCString"
  }, {
    'run' => "PATH/po4a-gettextize -f asciidoc -m t-03-asciidoc/Titles.asciidoc -l t-03-asciidoc/TitlesLatin1.asciidoc -L iso-8859-1 -p tmp/TitlesLatin1.po",
    'tests' => ["diff -u -I\'^# \' -I'^\"POT-Creation-Date:' -I'^\"PO-Revision-Date:'  t-03-asciidoc/TitlesLatin1.po tmp/TitlesLatin1.po"],
    'doc'      => "test titles with latin1 encoding",
    'requires' => "Unicode::GCString"
  }, {
    'normalize' => "-f asciidoc -o tablecells=1 t-03-asciidoc/TablesCells.asciidoc",
    'doc'       => "Table cells test"
  }, {
    'run' => "msgattrib --clear-fuzzy -o tmp/TitlesLatin1.po tmp/TitlesLatin1.po "
	." && PATH/po4a-translate -f asciidoc -m t-03-asciidoc/Titles.asciidoc -l tmp/TitlesLatin1.asciidoc -L iso-8859-1 -p tmp/TitlesLatin1.po",
    'tests' => ["diff -u tmp/TitlesLatin1.asciidoc t-03-asciidoc/TitlesLatin1.asciidoc"],
    'doc'      => "translate titles with latin1 encoding",
    'requires' => "Unicode::GCString"
  };

run_all_tests(@tests);
0;
