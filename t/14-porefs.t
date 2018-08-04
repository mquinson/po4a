#! /usr/bin/perl
# config file tester.

#########################

use strict;
use warnings;

# Set the right environment variables to normalize the outputs
$ENV{'LC_ALL'}="C";
$ENV{'COLUMNS'}="80";

my @tests;

mkdir "t/tmp" unless -e "t/tmp";

push @tests, {
  'run'  =>
    'perl ../po4a -f --porefs=none t-14-porefs/test1.conf > tmp/err 2>&1',
  'test' =>
    ["diff -u t-14-porefs/test1.err tmp/err 1>&2",
     "perl compare-po.pl t-14-porefs/none.pot tmp/test1.pot",
     "perl compare-po.pl t-14-porefs/none.fr.po tmp/test1.fr.po",
     "perl compare-po.pl t-14-porefs/none.de.po tmp/test1.de.po"],
  'doc'  => 'po4a --porefs=none flag'
},

{
  'run'  =>
    'perl ../po4a -f --porefs=file t-14-porefs/test1.conf > tmp/err 2>&1',
  'test' =>
    ["diff -u t-14-porefs/test1.err tmp/err 1>&2",
     "perl compare-po.pl t-14-porefs/file.pot tmp/test1.pot",
     "perl compare-po.pl t-14-porefs/file.fr.po tmp/test1.fr.po",
     "perl compare-po.pl t-14-porefs/file.de.po tmp/test1.de.po"],
  'doc'  => 'po4a --porefs=file flag'
},

{
  'run'  =>
    'perl ../po4a-updatepo --porefs=file -f man -m t-21-TransTractors/man -p tmp/updatepo-file.pot  > tmp/updatepo.err 2>&1',
  'test' =>
    ["diff -u t-14-porefs/updatepo.err tmp/updatepo.err 1>&2",
     "perl compare-po.pl t-14-porefs/updatepo-file.pot tmp/updatepo-file.pot"],
  'doc'  => 'po4a-updatepo --porefs=file flag'
},

{
  'run'  =>
    'perl ../po4a -f --porefs=file,wrap t-14-porefs/test1.conf > tmp/err 2>&1',
  'test' =>
    ["diff -u t-14-porefs/test1.err tmp/err 1>&2",
     "perl compare-po.pl t-14-porefs/file_wrap.pot tmp/test1.pot",
     "perl compare-po.pl t-14-porefs/file_wrap.fr.po tmp/test1.fr.po",
     "perl compare-po.pl t-14-porefs/file_wrap.de.po tmp/test1.de.po"],
  'doc'  => 'po4a --porefs=file,wrap flag'
},

{
  'run'  =>
    'perl ../po4a -f --porefs=file,nowrap t-14-porefs/test1.conf > tmp/err 2>&1',
  'test' =>
    ["diff -u t-14-porefs/test1.err tmp/err 1>&2",
     "perl compare-po.pl t-14-porefs/file.pot tmp/test1.pot",
     "perl compare-po.pl t-14-porefs/file.fr.po tmp/test1.fr.po",
     "perl compare-po.pl t-14-porefs/file.de.po tmp/test1.de.po"],
  'doc'  => 'po4a --porefs=file,nowrap flag'
},

{
  'run'  =>
    'perl ../po4a -f --porefs=counter t-14-porefs/test1.conf > tmp/err 2>&1',
  'test' =>
    ["diff -u t-14-porefs/test1.err tmp/err 1>&2",
     "perl compare-po.pl t-14-porefs/counter.pot tmp/test1.pot",
     "perl compare-po.pl t-14-porefs/counter.fr.po tmp/test1.fr.po",
     "perl compare-po.pl t-14-porefs/counter.de.po tmp/test1.de.po"],
  'doc'  => 'po4a --porefs=counter flag'
},

{
  'run'  =>
    'perl ../po4a -f --porefs=counter,wrap t-14-porefs/test1.conf > tmp/err 2>&1',
  'test' =>
    ["diff -u t-14-porefs/test1.err tmp/err 1>&2",
     "perl compare-po.pl t-14-porefs/counter_wrap.pot tmp/test1.pot",
     "perl compare-po.pl t-14-porefs/counter_wrap.fr.po tmp/test1.fr.po",
     "perl compare-po.pl t-14-porefs/counter_wrap.de.po tmp/test1.de.po"],
  'doc'  => 'po4a --porefs=counter,wrap flag'
},

{
  'run'  =>
    'perl ../po4a -f --porefs=counter,nowrap t-14-porefs/test1.conf > tmp/err 2>&1',
  'test' =>
    ["diff -u t-14-porefs/test1.err tmp/err 1>&2",
     "perl compare-po.pl t-14-porefs/counter.pot tmp/test1.pot",
     "perl compare-po.pl t-14-porefs/counter.fr.po tmp/test1.fr.po",
     "perl compare-po.pl t-14-porefs/counter.de.po tmp/test1.de.po"],
  'doc'  => 'po4a --porefs=counter,nowrap flag'
},

{
  'run'  =>
    'perl ../po4a -f --porefs=full,wrap t-14-porefs/test1.conf > tmp/err 2>&1',
  'test' =>
    ["diff -u t-14-porefs/test1.err tmp/err 1>&2",
     "perl compare-po.pl t-14-porefs/full_wrap.pot tmp/test1.pot",
     "perl compare-po.pl t-14-porefs/full_wrap.fr.po tmp/test1.fr.po",
     "perl compare-po.pl t-14-porefs/full_wrap.de.po tmp/test1.de.po"],
  'doc'  => 'po4a --porefs=full,wrap flag'
},

{
  'run'  =>
    'perl ../po4a -f --porefs=full,nowrap t-14-porefs/test1.conf > tmp/err 2>&1',
  'test' =>
    ["diff -u t-14-porefs/test1.err tmp/err 1>&2",
     "perl compare-po.pl t-14-porefs/full.pot tmp/test1.pot",
     "perl compare-po.pl t-14-porefs/full.fr.po tmp/test1.fr.po",
     "perl compare-po.pl t-14-porefs/full.de.po tmp/test1.de.po"],
  'doc'  => 'po4a --porefs=full,nowrap flag'
};

use Test::More tests => 48;

system("rm -f t/tmp/* 2>&1");
for (my $i=0; $i<scalar @tests; $i++) {
    chdir "t" || die "Can't chdir to my test directory";


    my ($val,$name);

    my $cmd=$tests[$i]{'run'};
    $val=system($cmd);

    $name=$tests[$i]{'doc'}.' runs';
    ok($val == 0,$name);
    diag($tests[$i]{'run'}) unless ($val == 0);

    SKIP: {
        skip ("Command don't run, can't test the validity of its return",1)
            if $val;
	
	my $ret_dos2unix = system("dos2unix -qk tmp/*"); # Just in case this is Windows
 
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
		diag ("(dos2unix failed earlier)") unless ($ret_dos2unix == 0);
            }
        }
    }

    chdir ".." || die "Can't chdir back to my root";
}

0;
