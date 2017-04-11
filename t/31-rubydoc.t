#! /usr/bin/perl
# RubyDoc module tester.

#########################

use strict;
use warnings;

my @tests;

unless (-e "t/tmp") {
    mkdir "t/tmp"
        or die "Can't create test directory t/tmp: $!\n";
}

my @RubyDocTests = qw(Headlines Verbatim_puredoc Lists);

foreach my $RubyDocTest (@RubyDocTests) {
    my $options = "";
    $options = "-o puredoc" if $RubyDocTest =~ m/_puredoc/;
    push @tests, {
        'run' => "perl ../../po4a-normalize -f Rd $options ../data-31/$RubyDocTest.rd ".
	         "&& mv po4a-normalize.po $RubyDocTest.po ".
	         "&& mv po4a-normalize.output $RubyDocTest.out ",
        'test'=> "perl ../compare-po.pl ../data-31/$RubyDocTest.po $RubyDocTest.po ".
                 "&& cmp ../data-31/$RubyDocTest.out $RubyDocTest.out",
        'doc' => "$RubyDocTest test"
    };
}

use Test::More tests => 2 * 3;

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
