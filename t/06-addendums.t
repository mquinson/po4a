#! /usr/bin/perl
# Addenda modifiers tester.

#########################

use strict;
use warnings;

my @tests;

mkdir "t/tmp" unless -e "t/tmp";

push @tests, {
  'run' => 'perl ../po4a-translate -k 0 -f text -m data-06/Titles.asciidoc -p /dev/null -l tmp/Titles.trans ' .
                '-a data-06/addendum1 -a data-06/addendum2 -a data-06/addendum3',
  'test'=> 'diff -U 50 data-06/Titles.trans.add123 tmp/Titles.trans',
  'doc' => 'translate with addendum1, 2 and 3'
  };

push @tests, {
  'run' => 'perl ../po4a-translate -k 0 -f text -m data-06/Titles.asciidoc -p /dev/null -l tmp/Titles.trans ' .
                '-a @data-06/addendum123.list',
  'test'=> 'diff -U 50 data-06/Titles.trans.add123 tmp/Titles.trans',
  'doc' => 'translate with @addendum'
  };

push @tests, {
  'run' => 'perl ../po4a-translate -k 0 -f text -m data-06/Titles.asciidoc -p /dev/null -l tmp/Titles.trans ' .
                '-a !data-06/addendum2 -a @data-06/addendum123.list',
  'test'=> 'diff -U 50 data-06/Titles.trans.add13 tmp/Titles.trans',
  'doc' => 'translate with !addendum'
  };

push @tests, {
  'run' => 'perl ../po4a-translate -k 0 -f text -m data-06/Titles.asciidoc -p /dev/null -l tmp/Titles.trans ' .
                '-a ?/does/not/exist',
  'test'=> 'diff -U 50 data-06/Titles.asciidoc tmp/Titles.trans',
  'doc' => 'translate with non-existing ?addendum'
  };

push @tests, {
  'run' => 'perl ../po4a-translate -k 0 -f text -m data-06/Titles.asciidoc -p /dev/null -l tmp/Titles.trans ' .
                '-a @data-06/addendum123.list2',
  'test'=> 'diff -U 50 data-06/Titles.trans.add1 tmp/Titles.trans',
  'doc' => 'translate with recursive @addendum'
  };

push @tests, {
  'run' => 'perl ../po4a -f data-06/test0.conf',
  'test'=> 'diff -U 50 data-06/Titles.trans.add123 tmp/Titles.trans',
  'doc' => '(po4a) translate with addendum1, 2 and 3'
  };

push @tests, {
  'run' => 'perl ../po4a -f data-06/test1.conf',
  'test'=> 'diff -U 50 data-06/Titles.trans.add123 tmp/Titles.trans',
  'doc' => '(po4a) translate with @addendum'
  };

push @tests, {
  'run' => 'perl ../po4a -f data-06/test2.conf',
  'test'=> 'diff -U 50 data-06/Titles.trans.add13 tmp/Titles.trans',
  'doc' => '(po4a) translate with !addendum'
  };

push @tests, {
  'run' => 'perl ../po4a -f data-06/test3.conf',
  'test'=> 'diff -U 50 data-06/Titles.asciidoc tmp/Titles.trans',
  'doc' => '(po4a) translate with non-existing ?addendum'
  };

push @tests, {
  'run' => 'perl ../po4a -f data-06/test4.conf',
  'test'=> 'diff -U 50 data-06/Titles.trans.add1 tmp/Titles.trans',
  'doc' => '(po4a) translate with recursive @addendum'
  };

use Test::More tests => 20; # tests * (run+validity)

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
