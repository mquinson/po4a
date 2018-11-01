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

my @markdown_tests = qw(MarkDown PandocHeaderMultipleLines PandocOnlyAuthor
  PandocTitleAndDate PandocMultipleAuthors PandocOnlyTitle PandocTitleAuthors
  PandocFencedCodeBlocks
  MarkDownNestedLists MarkDownRules);
for my $markdown_test (@markdown_tests) {

    # The nested lists currently fail for markdown.
    # Mark the test as TODO.
    my $todo = "";
    if ( $markdown_test eq "MarkDownNestedLists" ) {
        $todo = "https://github.com/mquinson/po4a/issues/131";
    }
    push @tests,
      {
        'todo'      => $todo,
        'doc'       => "$markdown_test test",
        'normalize' => "-f text -o markdown t-20-text/$markdown_test.md",
      };
}

run_all_tests(@tests);
0;
