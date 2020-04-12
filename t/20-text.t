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

push @tests,
  {
    'doc' => "MarkDownNoWrap test",
    'normalize' =>
      "-f text --master-charset UTF-8 --wrap-po=newlines -o neverwrap -o markdown t-20-text/MarkDownNoWrap.md",
  },
  {
    'doc' => "That the yfm_keys and yfm_skip_array options actually work",
    'normalize' =>
      "-f text -o markdown -o yfm_skip_array -o yfm_keys='title , subtitle,paragraph' t-20-text/MarkDownYamlFrontMatterOptions.md",
  };

push @tests,
  {
    'todo'      => "MarkDownNestedLists: currently broken (https://github.com/mquinson/po4a/issues/131)",
    'normalize' => "-f text -o markdown t-20-text/MarkDownNestedLists.md",
  };

my @markdown_tests = qw(MarkDown MarkDownYamlFrontMatter
  PandocHeaderMultipleLines PandocOnlyAuthor
  PandocTitleAndDate PandocMultipleAuthors PandocOnlyTitle PandocTitleAuthors
  PandocFencedCodeBlocks
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
