#! /usr/bin/perl
# Yaml module tester.

#########################

use strict;
use warnings;

my @tests;

mkdir "t/tmp" unless -e "t/tmp" or die "Can't create test directory t/tmp\n";

push @tests, {
    'run' => "perl ../../po4a-normalize -f yaml ../t-25-yaml/yamltest.yaml >yamltest.err 2>&1".
       "&& mv po4a-normalize.po yamltest.po ".
       "&& mv po4a-normalize.output yamltest.out ",
    'test'=> "perl ../compare-po.pl ../t-25-yaml/yamltest.po yamltest.po ".
             "&& diff -u ../t-25-yaml/yamltest.out yamltest.out 1>&2".
       "&& diff -u ../t-25-yaml/yamltest.err yamltest.err 1>&2",
    'doc' => "yamltest test"
};

push @tests, {
    'run' => "perl ../../po4a-normalize -f yaml ../t-25-yaml/yamlkeysoption1.yaml -o keys=name >yamlkeysoption1.err 2>&1".
	     "&& mv po4a-normalize.po yamlkeysoption1.po ".
	     "&& mv po4a-normalize.output yamlkeysoption1.out ",
    'test'=> "perl ../compare-po.pl ../t-25-yaml/yamlkeysoption1.po yamlkeysoption1.po ".
             "&& diff -u ../t-25-yaml/yamlkeysoption1.out yamlkeysoption1.out 1>&2".
	     "&& diff -u ../t-25-yaml/yamlkeysoption1.err yamlkeysoption1.err 1>&2",
    'doc' => "yamlkeysoption1 test"
};

push @tests, {
    'run' => "perl ../../po4a-normalize -f yaml ../t-25-yaml/yamlkeysoption2.yaml -o 'keys=name file' >yamlkeysoption2.err 2>&1".
	     "&& mv po4a-normalize.po yamlkeysoption2.po ".
	     "&& mv po4a-normalize.output yamlkeysoption2.out ",
    'test'=> "perl ../compare-po.pl ../t-25-yaml/yamlkeysoption2.po yamlkeysoption2.po ".
             "&& diff -u ../t-25-yaml/yamlkeysoption2.out yamlkeysoption2.out 1>&2".
	     "&& diff -u ../t-25-yaml/yamlkeysoption2.err yamlkeysoption2.err 1>&2",
    'doc' => "yamlkeysoption2 test"
};

push @tests, {
    'run' => "perl ../../po4a-normalize -f yaml ../t-25-yaml/yamlutf8.yaml -M UTF-8 >yamlutf8.err 2>&1".
	     "&& mv po4a-normalize.po yamlutf8.po ".
	     "&& mv po4a-normalize.output yamlutf8.out ",
    'test'=> "perl ../compare-po.pl ../t-25-yaml/yamlutf8.po yamlutf8.po ".
             "&& diff -u ../t-25-yaml/yamlutf8.out yamlutf8.out 1>&2".
	     "&& diff -u ../t-25-yaml/yamlutf8.err yamlutf8.err 1>&2",
    'doc' => "yamlutf8 test"
};

use Test::More tests => 2 * 4;

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
