#! /usr/bin/perl
# MAN module tester.

#########################

use strict;
use warnings;

my @tests;

my %test;

$test{'run'}  = 'po4a-translate -f man -a data/man.addendum1 -m data/man -p data/man.po -l tmp/man.fr';
$test{'test'} = 'diff -u data/man.fr.add1 tmp/man.fr';
$test{'doc'}  = 'translate with addendum1';
push @tests,%test;

$test{'run'}  = 'po4a-translate -f man -a data/man.addendum2 -m data/man -p data/man.po -l tmp/man.fr';
$test{'test'} = 'diff -u data/man.fr.add2 tmp/man.fr';
$test{'doc'}  = 'translate with addendum2';
push @tests,%test;

$test{'run'}  = 'po4a-translate -f man -a data/man.addendum3 -m data/man -p data/man.po -l tmp/man.fr';
$test{'test'} = 'diff -u data/man.fr.add3 tmp/man.fr';
$test{'doc'}  = 'translate with addendum3';
push @tests,%test;

$test{'run'}  = 'po4a-translate -f man -a data/man.addendum4 -m data/man -p data/man.po -l tmp/man.fr';
$test{'test'} = 'diff -u data/man.fr.add4 tmp/man.fr';
$test{'doc'}  = 'translate with addendum4';
push @tests,%test;



use Test::More tests =>8;

for (my $i=0; $i<scalar @tests; $i++) {
    chdir "t" || die "Can't chdir to my test directory";
    
    my ($val,$name);

    $val=system($tests[$i]{'run'});
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
	    diag ("Failed (retval=$val) on:");
	    diag ($tests[$i]{'test'});
	    diag ("Was created with:");
	    diag ($tests[$i]{'run'});
	}
    }

#    system("rm -f tmp/* 2>&1");

    chdir ".." || die "Can't chdir back to my root";
}

0;
