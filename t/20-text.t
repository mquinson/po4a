#! /usr/bin/perl
# Text module tester.

#########################

use strict;
use warnings;
use Test::More;

my @tests;

unless (-e "t/tmp") {
    mkdir "t/tmp"
        or die "Can't create test directory t/tmp: $!\n";
}

push @tests, {
    'run' => "perl ../../po4a-normalize -f text -o keyvalue ../t-20-text/KeyValue.text >KeyValue.err 2>&1".
       "&& mv po4a-normalize.po KeyValue.po ".
       "&& mv po4a-normalize.output KeyValue.out ",
    'test'=> "perl ../compare-po.pl --no-ref ../t-20-text/KeyValue.po KeyValue.po ".
             "&& diff -u ../t-20-text/KeyValue.out KeyValue.out 1>&2".
       "&& diff -u ../t-20-text/KeyValue.err KeyValue.err 1>&2",
    'doc' => "KeyValue test"
};

my @markdown_tests = qw(MarkDown PandocHeaderMultipleLines PandocOnlyAuthor
    PandocTitleAndDate PandocMultipleAuthors PandocOnlyTitle PandocTitleAuthors
    MarkDownNestedLists);
for my $markdown_test (@markdown_tests) {
    push @tests, {
        'run' => "perl ../../po4a-normalize -f text -o markdown ../t-20-text/$markdown_test.md > $markdown_test.err 2>&1".
           "&& mv po4a-normalize.po $markdown_test.pot ".
           "&& mv po4a-normalize.output $markdown_test.out ",
        'test'=> "perl ../compare-po.pl --no-ref ../t-20-text/$markdown_test.pot $markdown_test.pot ".
                 "&& diff -u ../t-20-text/$markdown_test.out $markdown_test.out 1>&2".
           "&& diff -u ../t-20-text/$markdown_test.err $markdown_test.err 1>&2",
        'doc' => "$markdown_test test"
    };
}

plan tests => 2 * scalar @tests;

chdir "t/tmp" || die "Can't chdir to my test directory";

foreach my $test ( @tests ) {
    my ($val,$name);

    my $cmd=$test->{'run'};
    $val=system($cmd);

    $name=$test->{'doc'}.' runs';
    ok($val == 0,$name);
    diag($cmd) unless ($val == 0);

    SKIP: {
        skip ("Command didn't run, can't test the validity of its return",1)
            if $val;
        $val=system($test->{'test'});
        $name=$test->{'doc'}.' returns what is expected';
        ok($val == 0,$name);
        unless ($val == 0) {
            diag ("Failed (retval=$val) on:");
            diag ($test->{'test'});
            diag ("Was created with:");
            diag ($test->{'run'});
        }
    }
}

chdir "../.."
    or die "Can't chdir back to my root";

0;
