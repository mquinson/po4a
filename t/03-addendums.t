#! /usr/bin/perl
# MAN module tester.

#########################

use strict;
use warnings;

my @tests;

mkdir "t/tmp" unless -e "t/tmp";

$tests[0]{'run'}  = 'perl ../po4a-translate -f man -a data-03/man.addendum1 -m data-03/man -p data-03/man.po-ok -l tmp/man.fr';
$tests[0]{'test'} = 'diff -U 50 data-03/man.fr.add1 tmp/man.fr';
$tests[0]{'doc'}  = 'translate with addendum1';

$tests[1]{'run'}  = 'perl ../po4a-translate -f man -a data-03/man.addendum2 -m data-03/man -p data-03/man.po-ok -l tmp/man.fr';
$tests[1]{'test'} = 'diff -U 50 data-03/man.fr.add2 tmp/man.fr';
$tests[1]{'doc'}  = 'translate with addendum2';

$tests[2]{'run'}  = 'perl ../po4a-translate -f man -a data-03/man.addendum3 -m data-03/man -p data-03/man.po-ok -l tmp/man.fr';
$tests[2]{'test'} = 'diff -U 50 data-03/man.fr.add3 tmp/man.fr';
$tests[2]{'doc'}  = 'translate with addendum3';

$tests[3]{'run'}  = 'perl ../po4a-translate -f man -a data-03/man.addendum4 -m data-03/man -p data-03/man.po-ok -l tmp/man.fr';
$tests[3]{'test'} = 'diff -U 50 data-03/man.fr.add4 tmp/man.fr';
$tests[3]{'doc'}  = 'translate with addendum4';


use Test::More tests =>8; # tests * (run+validity)

for (my $i=0; $i<scalar @tests; $i++) {
    chdir "t" || die "Can't chdir to my test directory";
    
    my ($val,$name);

    my $cmd=$tests[$i]{'run'};
    $val=system($cmd);
    
    $name=$tests[$i]{'doc'}.' runs';
    ok($val == 0,$name);
    diag(%{$tests[$i]{'run'}}) unless ($val == 0);

    SKIP: {
    	skip ("Command don't run, can't test the validity of its return",1)
	     if $val;
        $val=system($tests[$i]{'test'});	
    	$name=$tests[$i]{'doc'}.' returns what is expected';
        ok($val == 0,$name);
	unless ($val == 0) {
	    my $add = $tests[$i]{'run'};
	    $add =~ s/.*-a (\S*) .*/$1/;
	    $add = `cat $add | head -n 1`;
	    diag ("Failed (retval=$val) on:");
	    diag ($tests[$i]{'test'});
	    diag ("Was created with:");
	    diag ($tests[$i]{'run'});
	    diag ("Header was: $add");
	}
    }

#    system("rm -f tmp/* 2>&1");

    chdir ".." || die "Can't chdir back to my root";
}

0;
