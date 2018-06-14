#! /usr/bin/perl
# XML and XML-based modules tester.

#########################

use strict;
use warnings;

my @tests;

mkdir "t/tmp" unless -e "t/tmp" or die "Can't create test directory t/tmp\n";

push @tests, {
  'run' => 'perl ../../po4a-normalize -f guide ../t-24-xml/general.xml',
  'test'=> 'perl ../compare-po.pl ../t-24-xml/general.po po4a-normalize.po'.
            ' && perl ../compare-po.pl ../t-24-xml/general-normalized.xml po4a-normalize.output',
  'doc' => 'normalisation test',
  };
push @tests, {
  'run' => 'perl ../../po4a-normalize -f guide ../t-24-xml/comments.xml',
  'test'=> 'perl ../compare-po.pl ../t-24-xml/comments.po po4a-normalize.po'.
            ' && perl ../compare-po.pl ../t-24-xml/comments-normalized.xml po4a-normalize.output',
  'doc' => 'normalisation test',
  };
push @tests, {
  'run' => "perl ../../po4a-normalize -f xml -o translated='w<translate1w> W<translate2W> <translate5> i<inline6> ' -o untranslated='<untranslated4>' ../t-24-xml/options.xml",
  'test'=> 'perl ../compare-po.pl ../t-24-xml/options.po po4a-normalize.po'.
            ' && perl ../compare-po.pl ../t-24-xml/options-normalized.xml po4a-normalize.output',
  'doc' => 'normalisation test',
  };
push @tests, {
  'run' => "perl ../../po4a-normalize -f guide ../t-24-xml/cdata.xml",
  'test'=> 'perl ../compare-po.pl ../t-24-xml/cdata.po po4a-normalize.po'.
            ' && perl ../compare-po.pl ../t-24-xml/cdata.xml po4a-normalize.output',
  'doc' => 'normalisation test',
  };

use Test::More tests => 8;

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
