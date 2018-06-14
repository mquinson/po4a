#! /usr/bin/perl
# Texinfo module tester.

#########################

use strict;
use warnings;

my @tests;

mkdir "t/tmp" unless -e "t/tmp" or die "Can't create test directory t/tmp\n";

my @all_tests = qw(longmenu);

foreach my $TexinfoTest (@all_tests) {
    push @tests, {
        'doc' => "$TexinfoTest normalization test",
        'run' => "perl ../../po4a-normalize -f texinfo ../t-18-texinfo/$TexinfoTest.texi >$TexinfoTest.err 2>&1".
	         "&& mv po4a-normalize.po $TexinfoTest.po ".
	         "&& mv po4a-normalize.output $TexinfoTest.out ",
        'test'=> "perl ../compare-po.pl ../t-18-texinfo/$TexinfoTest.pot $TexinfoTest.po ".
                 "&& diff -u ../t-18-texinfo/$TexinfoTest.out $TexinfoTest.out 1>&2".
	         "&& diff -u ../t-18-texinfo/$TexinfoTest.err $TexinfoTest.err 1>&2"
    };
    push @tests, {
        'doc' => "$TexinfoTest translation test",
        'run' => "perl ../../po4a-translate -f texinfo -m ../t-18-texinfo/$TexinfoTest.texi -l $TexinfoTest-trans.texi -p ../t-18-texinfo/$TexinfoTest.po",
        'test'=> "diff -u ../t-18-texinfo/$TexinfoTest-trans.texi $TexinfoTest-trans.texi 1>&2"
    };
}


use Test::More tests => 4 * 1;

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
