# Text module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'run' =>
"perl ../po4a-normalize -f text -o keyvalue t-20-text/KeyValue.text > tmp/KeyValue.err 2>&1"
      . "&& mv po4a-normalize.po tmp/KeyValue.po "
      . "&& mv po4a-normalize.output tmp/KeyValue.out ",
    'test' =>
      "perl compare-po.pl --no-ref t-20-text/KeyValue.po tmp/KeyValue.po "
      . "&& diff -u t-20-text/KeyValue.out tmp/KeyValue.out 1>&2"
      . "&& diff -u t-20-text/KeyValue.err tmp/KeyValue.err 1>&2",
    'doc' => "KeyValue test"
  };

my @markdown_tests = qw(MarkDown PandocHeaderMultipleLines PandocOnlyAuthor
  PandocTitleAndDate PandocMultipleAuthors PandocOnlyTitle PandocTitleAuthors
  MarkDownNestedLists);
for my $markdown_test (@markdown_tests) {

    # The nested lists currently fail for markdown.
    # Mark the test as TODO.
    my $todo = "";
    if ( $markdown_test eq "MarkDownNestedLists" ) {
        $todo = "https://github.com/mquinson/po4a/issues/131";
    }
    push @tests,
      {
        'todo' => $todo,
        'run' =>
"perl ../po4a-normalize -f text -o markdown t-20-text/$markdown_test.md > tmp/$markdown_test.err 2>&1"
          . "&& mv po4a-normalize.po tmp/$markdown_test.pot "
          . "&& mv po4a-normalize.output tmp/$markdown_test.out ",
        'test' =>
"perl compare-po.pl --no-ref t-20-text/$markdown_test.pot tmp/$markdown_test.pot "
          . "&& diff -u t-20-text/$markdown_test.out tmp/$markdown_test.out 1>&2"
          . "&& diff -u t-20-text/$markdown_test.err tmp/$markdown_test.err 1>&2",
        'doc' => "$markdown_test test"
      };
}

run_all_tests(@tests);
0;
