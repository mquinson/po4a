#! /usr/bin/perl
# MAN module tester.

#########################

use strict;
use warnings;

my @tests;

$tests[0]{'run'}  = 'po4a-gettextize -t man data/man -o tmp/po';
$tests[0]{'test'} = 'diff -u data/man.po-empty tmp/po -I POT-Creation-Date';
$tests[0]{'doc'}  = 'gettextize man page with only the original';

$tests[1]{'run'}  = 'po4a-gettextize -t man data/man data/man.fr -o tmp/po';
$tests[1]{'test'} = "diff -u data/man.po tmp/po -I POT-Creation-Date -I '^#' -I '^\"Content-Type:' ".
                     "-I '^\"Content-Transfer-Encoding:'";
$tests[1]{'doc'}  = 'gettextize man page with original and translation';

$tests[2]{'run'}  = 'cp data/man.po tmp/po && po4a-updatepo -t man -m data/man --trans tmp/po >/dev/null 2>&1 ';
$tests[2]{'test'} = 'diff -u data/man.po tmp/po -I POT-Creation-Date';
$tests[2]{'doc'}  = 'updatepo';

$tests[3]{'run'}  = 'po4a-translate -t man data/man data/man.po -o tmp/man.fr';
$tests[3]{'test'} = 'diff -u data/man.fr tmp/man.fr';
$tests[3]{'doc'}  = 'translate';

$tests[4]{'run'}  = 'po4a-translate -t man -a data/man.addendum1 data/man data/man.po -o tmp/man.fr';
$tests[4]{'test'} = 'diff -u data/man.fr.add1 tmp/man.fr';
$tests[4]{'doc'}  = 'translate with addendum1';

$tests[5]{'run'}  = 'po4a-translate -t man -a data/man.addendum2 data/man data/man.po -o tmp/man.fr';
$tests[5]{'test'} = 'diff -u data/man.fr.add2 tmp/man.fr';
$tests[5]{'doc'}  = 'translate with addendum2';

$tests[6]{'run'}  = 'po4a-translate -t man -a data/man.addendum3 data/man data/man.po -o tmp/man.fr';
$tests[6]{'test'} = 'diff -u data/man.fr.add3 tmp/man.fr';
$tests[6]{'doc'}  = 'translate with addendum3';

$tests[7]{'run'}  = 'po4a-translate -t man -a data/man.addendum4 data/man data/man.po -o tmp/man.fr';
$tests[7]{'test'} = 'diff -u data/man.fr.add4 tmp/man.fr';
$tests[7]{'doc'}  = 'translate with addendum4';



use Test::More tests =>16;

for (my $i=0; $i<scalar @tests; $i++) {
    chdir "t" || die "Can't chdir to my test directory";
    
    my ($val,$name);

    $val=system($tests[$i]{'run'});
    $name=$tests[$i]{'doc'}.' runs';
    ok($val == 0,$name);
    print STDERR $tests[$i]{'run'} unless ($val == 0);

    SKIP: {
    	skip ("Command don't run, can't test the validity of its return",1)
	     if $val;
        $val=system($tests[$i]{'test'});	
    	$name=$tests[$i]{'doc'}.' returns what is expected';
        ok($val == 0,$name);
	print STDERR "Failed (retval=$val) on:\n".
	    $tests[$i]{'test'}."\nWas created with:\n".
	    $tests[$i]{'run'}."\n" unless ($val == 0);
    }

#    system("rm -f tmp/* 2>&1");

    chdir ".." || die "Can't chdir back to my root";
}

0;
