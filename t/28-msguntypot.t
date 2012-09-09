#! /usr/bin/perl
# msguntypot tester.

#########################

use strict;
use warnings;

my @tests;

unless (-e "t/tmp") {
    mkdir "t/tmp" or die "Can't create test directory t/tmp: $!\n";
}

push @tests, {
  'run' => 'cp ../data-28/test1.po . && chmod u+w test1.po && perl ../../scripts/msguntypot -o ../data-28/test1.old.pot -n ../data-28/test1.new.pot test1.po > /dev/null',
  'test'=> "perl ../compare-po.pl ../data-28/test1.new.po test1.po",
  'doc' => 'nominal test',
  };
push @tests, {
  'run' => 'cp ../data-28/test2.po . && chmod u+w test2.po && perl ../../scripts/msguntypot -o ../data-28/test2.old.pot -n ../data-28/test2.new.pot test2.po > /dev/null',
  'test'=> "perl ../compare-po.pl ../data-28/test2.new.po test2.po",
  'doc' => 'fuzzy test',
  };
# Moved strings are not supported.
# Only typo fixes!
#push @tests, {
#  'run' => 'cp ../data-28/test3.po . && chmod u+w test3.po && perl ../../scripts/msguntypot -o ../data-28/test3.old.pot -n ../data-28/test3.new.pot test3.po',
#  'test'=> "perl ../compare-po.pl test3.po ../data-28/test3.new.po",
#  'doc' => 'msg moved test',
#  };
push @tests, {
  'run' => 'cp ../data-28/test4.po . && chmod u+w test4.po && perl ../../scripts/msguntypot -o ../data-28/test4.old.pot -n ../data-28/test4.new.pot test4.po > /dev/null',
  'test'=> "perl ../compare-po.pl ../data-28/test4.new.po test4.po",
  'doc' => 'plural strings (typo in msgid) test',
  };
push @tests, {
  'run' => 'cp ../data-28/test5.po . && chmod u+w test5.po && perl ../../scripts/msguntypot -o ../data-28/test5.old.pot -n ../data-28/test5.new.pot test5.po > /dev/null',
  'test'=> "perl ../compare-po.pl ../data-28/test5.new.po test5.po",
  'doc' => 'plural strings (typo in msgid_plural) test',
  };
push @tests, {
  'run' => 'cp ../data-28/test6.po . && chmod u+w test6.po && perl ../../scripts/msguntypot -o ../data-28/test6.old.pot -n ../data-28/test6.new.pot test6.po > /dev/null',
  'test'=> "perl ../compare-po.pl ../data-28/test6.new.po test6.po",
  'doc' => 'plural strings (typo in another msgid) test',
  };
push @tests, {
  'run' => 'cp ../data-28/test7.po . && chmod u+w test7.po && perl ../../scripts/msguntypot -o ../data-28/test7.old.pot -n ../data-28/test7.new.pot test7.po > /dev/null',
  'test'=> "perl ../compare-po.pl ../data-28/test7.new.po test7.po",
  'doc' => 'plural fuzzy strings (typo in msgid) test',
  };
push @tests, {
  'run' => 'cp ../data-28/test8.po . && chmod u+w test8.po && perl ../../scripts/msguntypot -o ../data-28/test8.old.pot -n ../data-28/test8.new.pot test8.po > /dev/null',
  'test'=> "perl ../compare-po.pl ../data-28/test8.new.po test8.po",
  'doc' => 'plural fuzzy strings (typo in msgid_plural) test',
  };

use Test::More tests => 14;

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
