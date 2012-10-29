#! /usr/bin/perl
# Splitted mode tester.

#########################

use strict;
use warnings;

my @tests;

mkdir "t/tmp" unless -e "t/tmp";

push @tests, {
  'run'  =>
    'LC_ALL=C COLUMNS=80 perl ../po4a -f data-13/test0.conf > tmp/err 2>&1',
  'test' =>
    ["diff -u data-13/test0.err tmp/err",
     "sed -e 's,#: data-23/dot1:1 data-23/dot1:1,#: data-23/dot1:1,' data-05/test0.pot > tmp/test0-mod.pot",
     "perl compare-po.pl tmp/test0-mod.pot tmp/test0_man.1.pot",
     "sed -e 's,#: data-23/dot1:1 data-23/dot1:1,#: data-23/dot1:1,' data-23/dot1.pot > tmp/dot1-mod.pot",
     "perl compare-po.pl tmp/dot1-mod.pot tmp/dot1.pot"],
  'doc'  => 'splitted mode'
},
{
  'run'  =>
    'LC_ALL=C COLUMNS=80 perl ../po4a -f data-13/test1.conf > tmp/err 2>&1',
  'test' =>
    ["diff -u data-13/test1.err tmp/err",
     "sed -e 's, data-03/man:[0-9]*,,' tmp/man02.pot > tmp/test1-man02.pot",
     "perl compare-po.pl data-02/man.po-empty tmp/test1-man02.pot",
     "msgfilter sed d < data-03/man.po-ok 2>/dev/null | sed -e '/^#[:,]/d' > tmp/test1-man03a.pot",
     "sed -e '/^#[:,]/d' tmp/man03.pot > tmp/test1-man03b.pot",
     "perl compare-po.pl tmp/test1-man03a.pot tmp/test1-man03b.pot"],
  'doc'  => 'splitted mode'
};

use Test::More tests => 13;

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
