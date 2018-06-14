#! /usr/bin/perl
# Addenda modifiers tester.

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

push @tests, {
  'run' => 'perl ../po4a-translate -k 0 -f text -m data-06/Titles.asciidoc -p data-06/Titles.po -l tmp/Titles.trans ' .
                '-a data-06/addendum1 -a data-06/addendum2 -a data-06/addendum3',
  'test'=> 'diff -U 50 data-06/Titles.trans.add123 tmp/Titles.trans',
  'doc' => 'translate with addendum1, 2 and 3'
  };

push @tests, {
  'run' => 'perl ../po4a-translate -k 0 -f text -m data-06/Titles.asciidoc -p data-06/Titles.po -l tmp/Titles.trans ' .
                '-a @data-06/addendum123.list',
  'test'=> 'diff -U 50 data-06/Titles.trans.add123 tmp/Titles.trans',
  'doc' => 'translate with @addendum'
  };

push @tests, {
  'run' => 'perl ../po4a-translate -k 0 -f text -m data-06/Titles.asciidoc -p data-06/Titles.po -l tmp/Titles.trans ' .
                '-a !data-06/addendum2 -a @data-06/addendum123.list',
  'test'=> 'diff -U 50 data-06/Titles.trans.add13 tmp/Titles.trans',
  'doc' => 'translate with !addendum'
  };

push @tests, {
  'run' => 'perl ../po4a-translate -k 0 -f text -m data-06/Titles.asciidoc -p data-06/Titles.po -l tmp/Titles.trans ' .
                '-a ?/does/not/exist',
  'test'=> 'diff -U 50 data-06/Titles.asciidoc tmp/Titles.trans',
  'doc' => 'translate with non-existing ?addendum'
  };

push @tests, {
  'run' => 'perl ../po4a-translate -k 0 -f text -m data-06/Titles.asciidoc -p data-06/Titles.po -l tmp/Titles.trans ' .
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

use Test::More tests => 28; # tests * (run+validity)

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
