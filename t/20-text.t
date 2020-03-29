# Text module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'doc'       => "KeyValue test",
    'normalize' => "-f text -o keyvalue t-20-text/KeyValue.text",
  };

  # MarkDownNestedLists: currently broken (https://github.com/mquinson/po4a/issues/131)
my @markdown_tests = qw(MarkDown PandocHeaderMultipleLines PandocOnlyAuthor
  PandocTitleAndDate PandocMultipleAuthors PandocOnlyTitle PandocTitleAuthors
  PandocFencedCodeBlocks PandocYamlFrontMatter
  MarkDownRules);

for my $markdown_test (@markdown_tests) {    
    push @tests,
      {
        'doc'       => "$markdown_test test",
        'normalize' => "-f text -o markdown t-20-text/$markdown_test.md",
      };
}

run_all_tests(@tests);
0;
