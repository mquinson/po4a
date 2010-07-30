#! /usr/bin/perl
# Text module tester.

#########################

use strict;
use warnings;

my @tests;

unless (-e "t/tmp") {
    mkdir "t/tmp"
        or die "Can't create test directory t/tmp: $!\n";
}

my @AsciiDocTests = qw(Titles BlockTitles BlockId Paragraphs
DelimitedBlocks Lists Footnotes Callouts Tables Attributes);

foreach my $AsciiDocTest (@AsciiDocTests) {
    # Tables are currently badly supported.
    next if $AsciiDocTest =~ m/Tables/;
    push @tests, {
        'run' => "perl ../../po4a-normalize -f text -o asciidoc ../data-30/$AsciiDocTest.asciidoc",
        'test'=> "perl ../compare-po.pl ../data-30/$AsciiDocTest.po po4a-normalize.po".
                 "&& perl ../compare-po.pl ../data-30/$AsciiDocTest.out po4a-normalize.output",
        'doc' => "$AsciiDocTest test"
    };
}

#use Test::More tests => 2 * scalar(@AsciiDocTests);
use Test::More tests => 2 * 9;

chdir "t/tmp" || die "Can't chdir to my test directory";

foreach my $test ( @tests ) {
    my ($val,$name);

    my $cmd=$test->{'run'};
    $val=system($cmd);

    $name=$test->{'doc'}.' runs';
    ok($val == 0,$name);
    diag($test->{'run'}) unless ($val == 0);

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
