#! /usr/bin/perl
# Text module tester for fortunes files.

#########################

use strict;
use warnings;

my @tests;

unless (-e "t/tmp") {
    mkdir "t/tmp"
        or die "Can't create test directory t/tmp: $!\n";
}

my @FortunesTests = qw(SingleFortune SeveralFortunes MultipleLines);

foreach my $FortunesTest (@FortunesTests) {
    push @tests, {
        'run' => "perl ../../po4a-normalize -f text -o fortunes ../t-08-fortunes/$FortunesTest.txt >$FortunesTest.err 2>&1".
	         "&& mv po4a-normalize.po $FortunesTest.po ".
	         "&& mv po4a-normalize.output $FortunesTest.out ",
        'test'=> "perl ../compare-po.pl --no-ref ../t-08-fortunes/$FortunesTest.po $FortunesTest.po ".
                 "&& diff -u ../t-08-fortunes/$FortunesTest.out $FortunesTest.out 1>&2".
	         "&& diff -u ../t-08-fortunes/$FortunesTest.err $FortunesTest.err 1>&2",
        'doc' => "$FortunesTest test"
    };
}

use Test::More tests => 3 * 2;

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

chdir "../.." || die "Can't chdir back to my root";

0;
