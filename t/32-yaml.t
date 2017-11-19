#! /usr/bin/perl
# Yaml module tester.

#########################

use strict;
use warnings;

my @tests;

mkdir "t/tmp" unless -e "t/tmp" or die "Can't create test directory t/tmp\n";

my @YamlTests = qw(yamltest);

foreach my $YamlTest (@YamlTests) {
    push @tests, {
        'run' => "perl ../../po4a-normalize -f yaml ../data-32/$YamlTest.yaml >$YamlTest.err 2>&1".
	         "&& mv po4a-normalize.po $YamlTest.po ".
	         "&& mv po4a-normalize.output $YamlTest.out ",
        'test'=> "perl ../compare-po.pl --no-ref ../data-32/$YamlTest.po $YamlTest.po ".
                 "&& diff -u ../data-32/$YamlTest.out $YamlTest.out 1>&2".
	         "&& diff -u ../data-32/$YamlTest.err $YamlTest.err 1>&2",
        'doc' => "$YamlTest test"
    };
}

push @tests, {
    'run' => "perl ../../po4a-normalize -f yaml ../data-32/yamlkeysoption1.yaml -o keys=name >yamlkeysoption1.err 2>&1".
	     "&& mv po4a-normalize.po yamlkeysoption1.po ".
	     "&& mv po4a-normalize.output yamlkeysoption1.out ",
    'test'=> "perl ../compare-po.pl --no-ref ../data-32/yamlkeysoption1.po yamlkeysoption1.po ".
             "&& diff -u ../data-32/yamlkeysoption1.out yamlkeysoption1.out 1>&2".
	     "&& diff -u ../data-32/yamlkeysoption1.err yamlkeysoption1.err 1>&2",
    'doc' => "yamlkeysoption1 test"
};

push @tests, {
    'run' => "perl ../../po4a-normalize -f yaml ../data-32/yamlkeysoption2.yaml -o 'keys=name file' >yamlkeysoption2.err 2>&1".
	     "&& mv po4a-normalize.po yamlkeysoption2.po ".
	     "&& mv po4a-normalize.output yamlkeysoption2.out ",
    'test'=> "perl ../compare-po.pl --no-ref ../data-32/yamlkeysoption2.po yamlkeysoption2.po ".
             "&& diff -u ../data-32/yamlkeysoption2.out yamlkeysoption2.out 1>&2".
	     "&& diff -u ../data-32/yamlkeysoption2.err yamlkeysoption2.err 1>&2",
    'doc' => "yamlkeysoption2 test"
};

use Test::More tests => 2 * 3;

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
