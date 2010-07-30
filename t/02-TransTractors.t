#! /usr/bin/perl
# MAN module tester.

#########################

use strict;
use warnings;

my @tests;

my @formats=qw(man pod);

mkdir "t/tmp" unless -e "t/tmp";

$tests[0]{'run'}  = "perl ../po4a-gettextize -f #format# -m data-02/#format# -p tmp/po";
$tests[0]{'test'} = "perl compare-po.pl data-02/#format#.po-empty tmp/po";
$tests[0]{'doc'}  = "gettextize #format# document with only the original";

$tests[1]{'run'}  = "perl ../po4a-gettextize -f #format# -m data-02/#format# -l data-02/#format#.fr -L ISO-8859-1 -p tmp/po 2>/dev/null";
$tests[1]{'test'} = "perl compare-po.pl data-02/#format#.po tmp/po";
$tests[1]{'doc'}  = "gettextize #format# page with original and translation";

$tests[2]{'run'}  = "cp data-02/#format#.po tmp/po && perl ../po4a-updatepo -f #format# -m data-02/#format# -p tmp/po >/dev/null 2>&1 ";
$tests[2]{'test'} = "perl compare-po.pl data-02/#format#.po tmp/po";
$tests[2]{'doc'}  = "updatepo for #format# document";

$tests[3]{'run'}  = "perl ../po4a-translate -f #format# -m data-02/#format# -p data-02/#format#.po-ok -l tmp/#format#.fr";
$tests[3]{'test'} = "diff -u data-02/#format#.fr-normalized tmp/#format#.fr";
$tests[3]{'doc'}  = "translate #format# document";


use Test::More tests =>16; # $formats * $tests * 2 

foreach my $format (@formats) {
    for (my $i=0; $i<scalar @tests; $i++) {
	chdir "t" || die "Can't chdir to my test directory";
	
	my ($val,$name);
	
	my $cmd=$tests[$i]{'run'};
	$cmd =~ s/#format#/$format/g;
	$val=system($cmd);
	
	$name=$tests[$i]{'doc'}.' runs';
	$name =~ s/#format#/$format/g;
	ok($val == 0,$name);
	diag($cmd) unless ($val == 0);
	
	SKIP: {
	    skip ("Command don't run, can't test the validity of its return",1)
	      if $val;
	    my $testcmd=$tests[$i]{'test'};
	    $testcmd =~ s/#format#/$format/g;
	    
	    $val=system($testcmd);
	    $name=$tests[$i]{'doc'}.' returns what is expected';
	    $name =~ s/#format#/$format/g;
	    ok($val == 0,$name);
	    unless ($val == 0) {
		diag ("Failed (retval=$val) on:");
		diag ($testcmd);
		diag ("Was created with:");
		diag ("'$cmd', with -I../lib");
	    }
	}
	
#    system("rm -f tmp/* 2>&1");
	
	chdir ".." || die "Can't chdir back to my root";
    }
}

0;
    
