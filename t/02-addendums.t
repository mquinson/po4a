#! /usr/bin/perl
# Addenda modifiers tester.

#########################

use strict;
use warnings;

my @tests;

mkdir "t/tmp" unless -e "t/tmp";

push @tests, {
	'run'  => 'perl ../po4a-translate -f man -a t-02-addendums/man.addendum1 -m t-02-addendums/man -p t-02-addendums/man.po-ok -l tmp/man.fr',
	'test' => 'diff -U 50 t-02-addendums/man.fr.add1 tmp/man.fr',
	'doc'  => 'translate with addendum1'
};

push @tests, {
	'run'  => 'perl ../po4a-translate -f man -a t-02-addendums/man.addendum2 -m t-02-addendums/man -p t-02-addendums/man.po-ok -l tmp/man.fr',
	'test' => 'diff -U 50 t-02-addendums/man.fr.add2 tmp/man.fr',
	'doc'  => 'translate with addendum2'
};

push @tests, {
	'run'  => 'perl ../po4a-translate -f man -a t-02-addendums/man.addendum3 -m t-02-addendums/man -p t-02-addendums/man.po-ok -l tmp/man.fr',
	'test' => 'diff -U 50 t-02-addendums/man.fr.add3 tmp/man.fr',
	'doc'  => 'translate with addendum3'
};

push @tests, {
	'run'  => 'perl ../po4a-translate -f man -a t-02-addendums/man.addendum4 -m t-02-addendums/man -p t-02-addendums/man.po-ok -l tmp/man.fr',
	'test' => 'diff -U 50 t-02-addendums/man.fr.add4 tmp/man.fr',
	'doc'  => 'translate with addendum4'
};

push @tests, {
  'run' => 'perl ../po4a-translate -k 0 -f text -m t-02-addendums/Titles.asciidoc -p t-02-addendums/Titles.po -l tmp/Titles.trans ' .
                '-a t-02-addendums/addendum1 -a t-02-addendums/addendum2 -a t-02-addendums/addendum3',
  'test'=> 'diff -U 50 t-02-addendums/Titles.trans.add123 tmp/Titles.trans',
  'doc' => 'translate with addendum1, 2 and 3'
  };

push @tests, {
  'run' => 'perl ../po4a-translate -k 0 -f text -m t-02-addendums/Titles.asciidoc -p t-02-addendums/Titles.po -l tmp/Titles.trans ' .
                '-a @t-02-addendums/addendum123.list',
  'test'=> 'diff -U 50 t-02-addendums/Titles.trans.add123 tmp/Titles.trans',
  'doc' => 'translate with @addendum'
  };

push @tests, {
  'run' => 'perl ../po4a-translate -k 0 -f text -m t-02-addendums/Titles.asciidoc -p t-02-addendums/Titles.po -l tmp/Titles.trans ' .
                '-a !t-02-addendums/addendum2 -a @t-02-addendums/addendum123.list',
  'test'=> 'diff -U 50 t-02-addendums/Titles.trans.add13 tmp/Titles.trans',
  'doc' => 'translate with !addendum'
  };

push @tests, {
  'run' => 'perl ../po4a-translate -k 0 -f text -m t-02-addendums/Titles.asciidoc -p t-02-addendums/Titles.po -l tmp/Titles.trans ' .
                '-a ?/does/not/exist',
  'test'=> 'diff -U 50 t-02-addendums/Titles.asciidoc tmp/Titles.trans',
  'doc' => 'translate with non-existing ?addendum'
  };

push @tests, {
  'run' => 'perl ../po4a-translate -k 0 -f text -m t-02-addendums/Titles.asciidoc -p t-02-addendums/Titles.po -l tmp/Titles.trans ' .
                '-a @t-02-addendums/addendum123.list2',
  'test'=> 'diff -U 50 t-02-addendums/Titles.trans.add1 tmp/Titles.trans',
  'doc' => 'translate with recursive @addendum'
  };

push @tests, {
  'run' => 'perl ../po4a -f t-02-addendums/test0.conf',
  'test'=> 'diff -U 50 t-02-addendums/Titles.trans.add123 tmp/Titles.trans',
  'doc' => '(po4a) translate with addendum1, 2 and 3'
  };

push @tests, {
  'run' => 'perl ../po4a -f t-02-addendums/test1.conf',
  'test'=> 'diff -U 50 t-02-addendums/Titles.trans.add123 tmp/Titles.trans',
  'doc' => '(po4a) translate with @addendum'
  };

push @tests, {
  'run' => 'perl ../po4a -f t-02-addendums/test2.conf',
  'test'=> 'diff -U 50 t-02-addendums/Titles.trans.add13 tmp/Titles.trans',
  'doc' => '(po4a) translate with !addendum'
  };

push @tests, {
  'run' => 'perl ../po4a -f t-02-addendums/test3.conf',
  'test'=> 'diff -U 50 t-02-addendums/Titles.asciidoc tmp/Titles.trans',
  'doc' => '(po4a) translate with non-existing ?addendum'
  };

push @tests, {
  'run' => 'perl ../po4a -f t-02-addendums/test4.conf',
  'test'=> 'diff -U 50 t-02-addendums/Titles.trans.add1 tmp/Titles.trans',
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
