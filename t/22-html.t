#! /usr/bin/perl
# HTML module tester.

#########################

use strict;
use warnings;

my @tests;

mkdir "t/tmp" unless -e "t/tmp";

my $diff_po_flags = " -I '^# SOME' -I '^# Test' ".
  "-I '^\"POT-Creation-Date: ' -I '^\"Content-Transfer-Encoding:'";

push @tests, {
  'run' => 'perl ../../po4a-gettextize -f html -m ../data-22/html.html -p html.po',
  'test'=> "diff -u $diff_po_flags ../data-22/html.po html.po",
  'doc' => 'General',
}, {
  'run' => 'perl ../../po4a-normalize -f html ../data-22/spaces.html',
  'test'=> "diff -u $diff_po_flags ../data-22/spaces.po po4a-normalize.po".
            "&& diff -u $diff_po_flags ../data-22/spaces_out.html po4a-normalize.output",
  'doc' => 'Spaces',
}, {
  'run' => 'perl ../../po4a-gettextize -f html -m ../data-22/attribute.html -p attribute.po;'.
           'sed "s/msgstr \"\"/msgstr \"baz\"/" attribute.po > attribute2.po;'.
           'perl ../../po4a-translate -f html -m ../data-22/attribute.html -p attribute2.po -l attribute.html'
  ,
  'test'=> "diff -u $diff_po_flags ../data-22/attribute_out.html attribute.html",
  'doc' => 'Attribute replacement'
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
