#! /usr/bin/perl
# config file tester.

#########################

use strict;
use warnings;

my @tests;

mkdir "t/tmp" unless -e "t/tmp";

push @tests, {
  'run'  => 
    'LC_ALL=C COLUMNS=80 perl ../po4a -f --porefs=none data-12/test1.conf > tmp/err 2>&1',
  'test' =>
    ["diff -u data-12/test1.err tmp/err",
     "perl compare-po.pl data-12/none.pot tmp/test1.pot",
     "perl compare-po.pl data-12/none.fr.po tmp/test1.fr.po",
     "perl compare-po.pl data-12/none.de.po tmp/test1.de.po"],
  'doc'  => 'po4a --porefs=none flag'
},

{
  'run'  => 
    'LC_ALL=C COLUMNS=80 perl ../po4a -f --porefs=noline data-12/test1.conf > tmp/err 2>&1',
  'test' =>
    ["diff -u data-12/test1.err tmp/err",
     "perl compare-po.pl data-12/noline.pot tmp/test1.pot",
     "perl compare-po.pl data-12/noline.fr.po tmp/test1.fr.po",
     "perl compare-po.pl data-12/noline.de.po tmp/test1.de.po"],
  'doc'  => 'po4a --porefs=noline flag'
},

{
  'run'  => 
    'LC_ALL=C COLUMNS=80 perl ../po4a -f --porefs=noline,wrap data-12/test1.conf > tmp/err 2>&1',
  'test' =>
    ["diff -u data-12/test1.err tmp/err",
     "perl compare-po.pl data-12/noline_wrap.pot tmp/test1.pot",
     "perl compare-po.pl data-12/noline_wrap.fr.po tmp/test1.fr.po",
     "perl compare-po.pl data-12/noline_wrap.de.po tmp/test1.de.po"],
  'doc'  => 'po4a --porefs=noline,wrap flag'
},

{
  'run'  => 
    'LC_ALL=C COLUMNS=80 perl ../po4a -f --porefs=noline,nowrap data-12/test1.conf > tmp/err 2>&1',
  'test' =>
    ["diff -u data-12/test1.err tmp/err",
     "perl compare-po.pl data-12/noline.pot tmp/test1.pot",
     "perl compare-po.pl data-12/noline.fr.po tmp/test1.fr.po",
     "perl compare-po.pl data-12/noline.de.po tmp/test1.de.po"],
  'doc'  => 'po4a --porefs=noline,nowrap flag'
},

{
  'run'  => 
    'LC_ALL=C COLUMNS=80 perl ../po4a -f --porefs=counter data-12/test1.conf > tmp/err 2>&1',
  'test' =>
    ["diff -u data-12/test1.err tmp/err",
     "perl compare-po.pl data-12/counter.pot tmp/test1.pot",
     "perl compare-po.pl data-12/counter.fr.po tmp/test1.fr.po",
     "perl compare-po.pl data-12/counter.de.po tmp/test1.de.po"],
  'doc'  => 'po4a --porefs=counter flag'
},

{
  'run'  => 
    'LC_ALL=C COLUMNS=80 perl ../po4a -f --porefs=counter,wrap data-12/test1.conf > tmp/err 2>&1',
  'test' =>
    ["diff -u data-12/test1.err tmp/err",
     "perl compare-po.pl data-12/counter_wrap.pot tmp/test1.pot",
     "perl compare-po.pl data-12/counter_wrap.fr.po tmp/test1.fr.po",
     "perl compare-po.pl data-12/counter_wrap.de.po tmp/test1.de.po"],
  'doc'  => 'po4a --porefs=counter,wrap flag'
},

{
  'run'  => 
    'LC_ALL=C COLUMNS=80 perl ../po4a -f --porefs=counter,nowrap data-12/test1.conf > tmp/err 2>&1',
  'test' =>
    ["diff -u data-12/test1.err tmp/err",
     "perl compare-po.pl data-12/counter.pot tmp/test1.pot",
     "perl compare-po.pl data-12/counter.fr.po tmp/test1.fr.po",
     "perl compare-po.pl data-12/counter.de.po tmp/test1.de.po"],
  'doc'  => 'po4a --porefs=counter,nowrap flag'
},

{
  'run'  => 
    'LC_ALL=C COLUMNS=80 perl ../po4a -f --porefs=full,wrap data-12/test1.conf > tmp/err 2>&1',
  'test' =>
    ["diff -u data-12/test1.err tmp/err",
     "perl compare-po.pl data-12/full_wrap.pot tmp/test1.pot",
     "perl compare-po.pl data-12/full_wrap.fr.po tmp/test1.fr.po",
     "perl compare-po.pl data-12/full_wrap.de.po tmp/test1.de.po"],
  'doc'  => 'po4a --porefs=full,wrap flag'
},

{
  'run'  => 
    'LC_ALL=C COLUMNS=80 perl ../po4a -f --porefs=full,nowrap data-12/test1.conf > tmp/err 2>&1',
  'test' =>
    ["diff -u data-12/test1.err tmp/err",
     "perl compare-po.pl data-12/full.pot tmp/test1.pot",
     "perl compare-po.pl data-12/full.fr.po tmp/test1.fr.po",
     "perl compare-po.pl data-12/full.de.po tmp/test1.de.po"],
  'doc'  => 'po4a --porefs=full,nowrap flag'
};

use Test::More tests =>45;

for (my $i=0; $i<scalar @tests; $i++) {
    chdir "t" || die "Can't chdir to my test directory";

    system("rm -f tmp/* 2>&1");

    my ($val,$name);

    my $cmd=$tests[$i]{'run'};
    $val=system($cmd);

    $name=$tests[$i]{'doc'}.' runs';
    ok($val == 0,$name);
    diag($tests[$i]{'run'}) unless ($val == 0);

    SKIP: {
        skip ("Command don't run, can't test the validity of its return",1)
            if $val;
        my $nb = 0;
        foreach my $test (@{$tests[$i]{'test'}}) {
            $nb++;
            $val=system($test);
            $name=$tests[$i]{'doc'}."[$nb] returns what is expected";
            ok($val == 0,$name);
            unless ($val == 0) {
                diag ("Failed (retval=$val) on:");
                diag ($test);
                diag ("Was created with:");
                diag ($tests[$i]{'run'});
            }
        }
    }

    chdir ".." || die "Can't chdir back to my root";
}

0;
