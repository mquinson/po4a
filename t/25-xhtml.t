#! /usr/bin/perl
# Xhtml module tester.

#########################

use strict;
use warnings;

my @tests;

mkdir "t/tmp" unless -e "t/tmp" or die "Can't create test directory t/tmp\n";

push @tests, {
      'run' => 'perl ../../po4a-gettextize -f xhtml -m ../data-25/xhtml.html -p xhtml.po',
          'test'=> 'perl ../compare-po.pl ../data-25/xhtml.po xhtml.po',
          'doc' => 'Text extraction',
  }, {
  'run' => 'perl ../../po4a-normalize -f xhtml ../data-25/xhtml.html',
  'test'=> 'perl ../compare-po.pl ../data-25/xhtml.po po4a-normalize.po'.
            ' && perl ../compare-po.pl ../data-25/xhtml_normalized.html po4a-normalize.output',
  'doc' => 'normalisation test',
  }, {
  'run' => 'perl ../../po4a-normalize -f xhtml -o includessi ../data-25/includessi.html',
  'test'=> 'perl ../compare-po.pl ../data-25/includessi.po po4a-normalize.po'.
            ' && perl ../compare-po.pl ../data-25/includessi_normalized.html po4a-normalize.output',
  'doc' => 'includessi test',
  };

use Test::More tests => 6;

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
