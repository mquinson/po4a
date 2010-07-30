#! /usr/bin/perl
# Character sets tester.

#########################

use strict;
use warnings;

my @tests;

mkdir "t/tmp" unless -e "t/tmp";

$tests[0]{'run'}  = 'perl ../po4a-gettextize -f pod -m data-04/text-ascii.pod -M iso-8859-1 -p tmp/ascii.po';
$tests[0]{'test'} = 'perl compare-po.pl data-04/ascii.po-ok tmp/ascii.po';
$tests[0]{'doc'}  = 'using ascii when it\'s enough';

$tests[1]{'run'}  = 'perl ../po4a-gettextize -f pod -m data-04/text-iso8859.pod -M iso-8859-1 -p tmp/iso8859.po';
$tests[1]{'test'} = 'perl compare-po.pl data-04/iso8859.po-ok tmp/iso8859.po';
$tests[1]{'doc'}  = 'use utf-8 when master file is non-ascii';

$tests[2]{'run'}  = 'perl ../po4a-gettextize -f pod -m data-04/text-ascii.pod -l data-04/text-iso8859.pod -L iso-8859-1 -p tmp/ascii-iso8859.po';
$tests[2]{'test'} = 'perl compare-po.pl data-04/ascii-iso8859.po-ok tmp/ascii-iso8859.po';
$tests[2]{'doc'}  = 'using translation\'s encoding when master is ascii';

$tests[3]{'run'}  = 'perl ../po4a-translate -f pod -m data-04/text-ascii.pod -p data-04/trans.po -l tmp/text-iso8859.pod';
$tests[3]{'test'} = 'perl compare-po.pl data-04/text-iso8859.pod-ok tmp/text-iso8859.pod';
$tests[3]{'doc'}  = 'translation without recoding output';

$tests[4]{'run'}  = 'perl ../po4a-gettextize -f pod -m data-04/text-iso8859_.pod -M iso-8859-1 -l data-04/text-iso8859.pod -L iso-8859-1 -p tmp/utf.po';
$tests[4]{'test'} = 'perl compare-po.pl data-04/utf.po-ok tmp/utf.po';
$tests[4]{'doc'}  = 'convert msgstrs to utf-8 when master file is non-ascii';

$tests[5]{'run'}  = 'perl ../po4a-translate -f pod -m data-04/text-ascii.pod -p data-04/utf.po -l tmp/utf.pod';
$tests[5]{'test'} = 'perl compare-po.pl data-04/utf.pod-ok tmp/utf.pod';
$tests[5]{'doc'}  = 'use input po\'s charset';

use Test::More tests =>12; # tests * (run+validity)

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
