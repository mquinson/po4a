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

my @TextTests = qw(KeyValue);

foreach my $TextTest (@TextTests) {
    push @tests, {
        'run' => "perl ../../po4a-normalize -f text -o keyvalue ../data-28/$TextTest.text >$TextTest.err 2>&1".
	         "&& mv po4a-normalize.po $TextTest.po ".
	         "&& mv po4a-normalize.output $TextTest.out ",
        'test'=> "perl ../compare-po.pl --no-ref ../data-28/$TextTest.po $TextTest.po ".
                 "&& diff -u ../data-28/$TextTest.out $TextTest.out 1>&2".
	         "&& diff -u ../data-28/$TextTest.err $TextTest.err 1>&2",
        'doc' => "$TextTest test"
    };
}

use Test::More tests => 2 * 1;

chdir "t/tmp" || die "Can't chdir to my test directory";

foreach my $test ( @tests ) {
    my ($val,$name);

    my $cmd=$test->{'run'};

    $name=$test->{'doc'}.' runs';

    SKIP: {
        if (defined $test->{'requires'}) {
            skip ($test->{'requires'}." required for this test", 1)
                unless eval 'require '.$test->{'requires'};
        }
        $val=system($cmd);
        ok($val == 0,$name);
        diag($cmd) unless ($val == 0);
    }
    SKIP: {
        if (defined $test->{'requires'}) {
            skip ($test->{'requires'}." required for this test", 1)
                unless eval 'require '.$test->{'requires'};
        }
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
