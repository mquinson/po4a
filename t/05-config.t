#! /usr/bin/perl
# config file tester.

#########################

use strict;
use warnings;

my @tests;

mkdir "t/tmp" unless -e "t/tmp";

$tests[0]{'run'}  =
    'LC_ALL=C COLUMNS=80 perl ../po4a data-05/test0.conf > tmp/err 2>&1';
@{$tests[0]{'test'}} =
    ("diff -u data-05/test0.err tmp/err",
     "perl compare-po.pl data-05/test0.pot tmp/test0.pot",
     "perl compare-po.pl data-05/test0.fr.po-empty tmp/test0.fr.po",
     "test ! -e tmp/test0_man.fr.1");
$tests[0]{'doc'}  = 'simple config file - init';


$tests[1]{'run'}  =
    'cp data-05/test0.fr.po tmp/test0.fr.po && '.
    'chmod u+w tmp/test0.fr.po && '.
    'LC_ALL=C COLUMNS=80 perl ../po4a data-05/test0.conf > tmp/err 2>&1';
@{$tests[1]{'test'}} =
    ("diff -u data-05/test1.err tmp/err",
     "perl compare-po.pl data-05/test0.pot tmp/test0.pot",
     "perl compare-po.pl data-05/test0.fr.po tmp/test0.fr.po",
     "diff -u data-05/test0_man.fr.1 tmp/test0_man.fr.1");
$tests[1]{'doc'}  = 'simple config file - with translation';


$tests[2]{'run'}  =
    'LC_ALL=C COLUMNS=80 perl ../po4a data-05/test2.conf > tmp/err 2>&1';
@{$tests[2]{'test'}} =
    ("diff -u data-05/test2.err tmp/err",
     "perl compare-po.pl data-05/test2.pot tmp/test2.pot",
     "perl compare-po.pl data-05/test2.fr.po-empty tmp/test2.fr.po",
     "perl compare-po.pl data-05/test2.es.po-empty tmp/test2.es.po",
     "perl compare-po.pl data-05/test2.it.po-empty tmp/test2.it.po",
     "perl compare-po.pl data-05/test2.de.po-empty tmp/test2.de.po",
     "test ! -e tmp/test2_man.fr.1",
     "test ! -e tmp/test2_man.es.1",
     "test ! -e tmp/test2_man.it.1",
     "test ! -e tmp/test2_man.de.1");
$tests[2]{'doc'}  = 'template languages';


$tests[3]{'run'}  =
    'cp data-05/test2.??.po tmp/ && '.
    'chmod u+w tmp/test2.??.po && '.
    'LC_ALL=C COLUMNS=80 perl ../po4a data-05/test2.conf > tmp/err 2>&1';
@{$tests[3]{'test'}} =
    ("diff -u data-05/test3.err tmp/err",
     "perl compare-po.pl data-05/test2.pot tmp/test2.pot",
     "perl compare-po.pl data-05/test2.fr.po tmp/test2.fr.po",
     "perl compare-po.pl data-05/test2.es.po tmp/test2.es.po",
     "perl compare-po.pl data-05/test2.it.po tmp/test2.it.po",
     "perl compare-po.pl data-05/test2.de.po tmp/test2.de.po",
     "diff -u data-05/test2_man.fr.1 tmp/test2_man.fr.1",
     "test ! -e tmp/test2_man.es.1",
     "diff -u data-05/test2_man.it.1 tmp/test2_man.it.1",
     "test ! -e tmp/test2_man.de.1");
$tests[3]{'doc'}  = 'template languages - with translations';


$tests[4]{'run'}  =
    'cp data-05/test2.??.po tmp/ && '.
    'chmod u+w tmp/test2.??.po && '.
    'LC_ALL=C COLUMNS=80 perl ../po4a -v -k 0 data-05/test2.conf >tmp/err 2>&1';
@{$tests[4]{'test'}} =
    ("sed -e 's,^\.* done\.,. done.,' -e 's,^tmp/test2\\.[^:]*\.po: ,,' tmp/err | diff -u data-05/test4.err -",
     "perl compare-po.pl data-05/test2.pot tmp/test2.pot",
     "perl compare-po.pl data-05/test2.fr.po tmp/test2.fr.po",
     "perl compare-po.pl data-05/test2.es.po tmp/test2.es.po",
     "perl compare-po.pl data-05/test2.it.po tmp/test2.it.po",
     "perl compare-po.pl data-05/test2.de.po tmp/test2.de.po",
     "diff -u data-05/test2_man.fr.1 tmp/test2_man.fr.1",
     "diff -u data-05/test2_man.es.1 tmp/test2_man.es.1",
     "diff -u data-05/test2_man.it.1 tmp/test2_man.it.1",
     "diff -u data-05/test2_man.de.1 tmp/test2_man.de.1");
$tests[4]{'doc'}  = 'template languages - command line arguments';

# -k 0 is specified in the file opt:
$tests[5]{'run'}  =
    'cp data-05/test2.??.po tmp/ && '.
    'chmod u+w tmp/test2.??.po && '.
    'LC_ALL=C COLUMNS=80 perl ../po4a -v data-05/test3.conf > tmp/err 2>&1';
@{$tests[5]{'test'}} =
    ("sed -e 's,^\.* done\.,. done.,' -e 's,^tmp/test2\\.[^:]*\.po: ,,' tmp/err | diff -u data-05/test4.err -",
     "perl compare-po.pl data-05/test2.pot tmp/test2.pot",
     "perl compare-po.pl data-05/test2.fr.po tmp/test2.fr.po",
     "perl compare-po.pl data-05/test2.es.po tmp/test2.es.po",
     "perl compare-po.pl data-05/test2.it.po tmp/test2.it.po",
     "perl compare-po.pl data-05/test2.de.po tmp/test2.de.po",
     "diff -u data-05/test2_man.fr.1 tmp/test2_man.fr.1",
     "diff -u data-05/test2_man.es.1 tmp/test2_man.es.1",
     "diff -u data-05/test2_man.it.1 tmp/test2_man.it.1",
     "diff -u data-05/test2_man.de.1 tmp/test2_man.de.1");
$tests[5]{'doc'}  = 'command line arguments + options';

# -k 0 -v is specified for the alias
$tests[6]{'run'}  =
    'cp data-05/test2.??.po tmp/ && '.
    'chmod u+w tmp/test2.??.po && '.
    'LC_ALL=C COLUMNS=80 perl ../po4a data-05/test4.conf > tmp/err 2>&1';
@{$tests[6]{'test'}} =
    ("diff -u data-05/test6.err tmp/err",
     "perl compare-po.pl data-05/test2.pot tmp/test2.pot",
     "perl compare-po.pl data-05/test2.fr.po tmp/test2.fr.po",
     "perl compare-po.pl data-05/test2.es.po tmp/test2.es.po",
     "perl compare-po.pl data-05/test2.it.po tmp/test2.it.po",
     "perl compare-po.pl data-05/test2.de.po tmp/test2.de.po",
     "diff -u data-05/test2_man.fr.1 tmp/test2_man.fr.1",
     "diff -u data-05/test2_man.es.1 tmp/test2_man.es.1",
     "diff -u data-05/test2_man.it.1 tmp/test2_man.it.1",
     "diff -u data-05/test2_man.de.1 tmp/test2_man.de.1");
$tests[6]{'doc'}  = 'module alias + options';


$tests[7]{'run'}  =
    'cp data-05/test2.??.po tmp/ && '.
    'chmod u+w tmp/test2.??.po && '.
    'LC_ALL=C COLUMNS=80 perl ../po4a data-05/test5.conf > tmp/err 2>&1';
@{$tests[7]{'test'}} =
    ("diff -u data-05/test7.err tmp/err",
     "perl compare-po.pl data-05/test2.pot tmp/test2.pot",
     "perl compare-po.pl data-05/test2.fr.po tmp/test2.fr.po",
     "perl compare-po.pl data-05/test2.es.po tmp/test2.es.po",
     "perl compare-po.pl data-05/test2.it.po tmp/test2.it.po",
     "perl compare-po.pl data-05/test2.de.po tmp/test2.de.po",
     "diff -u data-05/test2_man.fr.1 tmp/test2_man.fr.1",
     "diff -u data-05/test2_man.es.1 tmp/test2_man.es.1",
     "diff -u data-05/test2_man.it.1 tmp/test2_man.it.1",
     "test ! -e tmp/test2_man.de.1");
$tests[7]{'doc'}  = 'module alias + options per language';

$tests[8]{'run'}  =
    'cp data-05/test2.??.po tmp/ && '.
    'chmod u+w tmp/test2.??.po && '.
    'LC_ALL=C COLUMNS=80 perl ../po4a -f data-05/test8.conf > tmp/err 2>&1';
@{$tests[8]{'test'}} =
    ("diff -u data-05/test3.err tmp/err",
     "perl compare-po.pl data-05/test2.pot tmp/test2.pot",
     "perl compare-po.pl data-05/test2.fr.po tmp/test2.fr.po",
     "perl compare-po.pl data-05/test2.es.po tmp/test2.es.po",
     "perl compare-po.pl data-05/test2.it.po tmp/test2.it.po",
     "perl compare-po.pl data-05/test2.de.po tmp/test2.de.po",
     "diff -u data-05/test2_man.fr.1 tmp/test2_man.fr.1",
     "test ! -e tmp/test2_man.es.1",
     "diff -u data-05/test2_man.it.1 tmp/test2_man.it.1",
     "test ! -e tmp/test2_man.de.1");
$tests[8]{'doc'}  = 'template languages in po4a_paths';


use Test::More tests =>87;

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
