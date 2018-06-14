#! /usr/bin/perl
# config file tester.

#########################

use strict;
use warnings;

my @tests;

mkdir "t/tmp" unless -e "t/tmp";

$tests[0]{'doc'}  = 'simple config file - init';
$tests[0]{'run'}  =
    'LC_ALL=C COLUMNS=80 perl ../po4a t-05-config/test00.conf > tmp/test00.err 2>&1';
@{$tests[0]{'test'}} =
    ("diff -u t-05-config/test00.err tmp/test00.err 1>&2",
     "perl compare-po.pl --no-ref t-05-config/test00.pot tmp/test00.pot",
     "perl compare-po.pl --no-ref t-05-config/test00.fr.po-empty tmp/test00.fr.po",
     "test ! -e tmp/test00_man.fr.1");


$tests[1]{'doc'}  = 'simple config file - with a provided translation';
$tests[1]{'run'}  =
    'cp t-05-config/test00.fr.po tmp/test00.fr.po && '.
    'chmod u+w tmp/test00.fr.po && '.
    'LC_ALL=C COLUMNS=80 perl ../po4a t-05-config/test00.conf > tmp/err 2>&1';
@{$tests[1]{'test'}} =
    ("diff -u t-05-config/test01.err tmp/err 1>&2",
     "perl compare-po.pl --no-ref t-05-config/test00.pot tmp/test00.pot",
     "perl compare-po.pl --no-ref t-05-config/test00.fr.po tmp/test00.fr.po",
     "diff -u t-05-config/test00_man.fr.1 tmp/test00_man.fr.1 1>&2");


$tests[2]{'doc'}  = 'template languages';
$tests[2]{'run'}  =
    'LC_ALL=C COLUMNS=80 perl ../po4a t-05-config/test02.conf > tmp/err 2>&1';
@{$tests[2]{'test'}} =
    ("diff -u t-05-config/test02.err tmp/err 1>&2",
     "perl compare-po.pl --no-ref t-05-config/test02.pot tmp/test02.pot",
     "perl compare-po.pl --no-ref t-05-config/test02.fr.po-empty tmp/test02.fr.po",
     "perl compare-po.pl --no-ref t-05-config/test02.es.po-empty tmp/test02.es.po",
     "perl compare-po.pl --no-ref t-05-config/test02.it.po-empty tmp/test02.it.po",
     "perl compare-po.pl --no-ref t-05-config/test02.de.po-empty tmp/test02.de.po",
     "test ! -e tmp/test02_man.fr.1",
     "test ! -e tmp/test02_man.es.1",
     "test ! -e tmp/test02_man.it.1",
     "test ! -e tmp/test02_man.de.1");


$tests[3]{'doc'}  = 'template languages - with translations';
$tests[3]{'run'}  =
    'cp t-05-config/test02.??.po tmp/ && '.
    'chmod u+w tmp/test02.??.po && '.
    'LC_ALL=C COLUMNS=80 perl ../po4a t-05-config/test02.conf > tmp/err 2>&1';
@{$tests[3]{'test'}} =
    ("diff -u t-05-config/test03.err tmp/err 1>&2",
     "perl compare-po.pl --no-ref t-05-config/test02.pot tmp/test02.pot",
     "perl compare-po.pl --no-ref t-05-config/test02.fr.po tmp/test02.fr.po",
     "perl compare-po.pl --no-ref t-05-config/test02.es.po tmp/test02.es.po",
     "perl compare-po.pl --no-ref t-05-config/test02.it.po tmp/test02.it.po",
     "perl compare-po.pl --no-ref t-05-config/test02.de.po tmp/test02.de.po",
     "diff -u t-05-config/test02_man.fr.1 tmp/test02_man.fr.1 1>&2",
     "test ! -e tmp/test02_man.es.1",
     "diff -u t-05-config/test02_man.it.1 tmp/test02_man.it.1 1>&2",
     "test ! -e tmp/test02_man.de.1");


$tests[4]{'doc'}  = 'template languages - command line arguments';
$tests[4]{'run'}  =
    'cp t-05-config/test02.??.po tmp/ && '.
    'chmod u+w tmp/test02.??.po && '.
    'LC_ALL=C COLUMNS=80 perl ../po4a -v -k 0 t-05-config/test02.conf >tmp/err 2>&1';
@{$tests[4]{'test'}} =
    ("sed -e 's,^\.* done\.,. done.,' -e 's,^tmp/test02\\.[^:]*\.po: ,,' tmp/err | diff -u t-05-config/test04.err -  1>&2",
     "perl compare-po.pl --no-ref t-05-config/test02.pot tmp/test02.pot",
     "perl compare-po.pl --no-ref t-05-config/test02.fr.po tmp/test02.fr.po",
     "perl compare-po.pl --no-ref t-05-config/test02.es.po tmp/test02.es.po",
     "perl compare-po.pl --no-ref t-05-config/test02.it.po tmp/test02.it.po",
     "perl compare-po.pl --no-ref t-05-config/test02.de.po tmp/test02.de.po",
     "diff -u t-05-config/test02_man.fr.1 tmp/test02_man.fr.1 1>&2",
     "diff -u t-05-config/test02_man.es.1 tmp/test02_man.es.1 1>&2",
     "diff -u t-05-config/test02_man.it.1 tmp/test02_man.it.1 1>&2",
     "diff -u t-05-config/test02_man.de.1 tmp/test02_man.de.1 1>&2");

# -k 0 is specified in the file opt:
$tests[5]{'doc'}  = 'command line arguments + options';
$tests[5]{'run'}  =
    'cp t-05-config/test02.??.po tmp/ && '.
    'chmod u+w tmp/test02.??.po && '.
    'LC_ALL=C COLUMNS=80 perl ../po4a -v t-05-config/test03.conf > tmp/err 2>&1';
@{$tests[5]{'test'}} =
    ("sed -e 's,^\.* done\.,. done.,' -e 's,^tmp/test02\\.[^:]*\.po: ,,' tmp/err | diff -u t-05-config/test04.err -  1>&2",
     "perl compare-po.pl --no-ref t-05-config/test02.pot tmp/test02.pot",
     "perl compare-po.pl --no-ref t-05-config/test02.fr.po tmp/test02.fr.po",
     "perl compare-po.pl --no-ref t-05-config/test02.es.po tmp/test02.es.po",
     "perl compare-po.pl --no-ref t-05-config/test02.it.po tmp/test02.it.po",
     "perl compare-po.pl --no-ref t-05-config/test02.de.po tmp/test02.de.po",
     "diff -u t-05-config/test02_man.fr.1 tmp/test02_man.fr.1 1>&2",
     "diff -u t-05-config/test02_man.es.1 tmp/test02_man.es.1 1>&2",
     "diff -u t-05-config/test02_man.it.1 tmp/test02_man.it.1 1>&2",
     "diff -u t-05-config/test02_man.de.1 tmp/test02_man.de.1 1>&2");

# -k 0 -v is specified for the alias
$tests[6]{'doc'}  = 'module alias + options';
$tests[6]{'run'}  =
    'cp t-05-config/test02.??.po tmp/ && '.
    'chmod u+w tmp/test02.??.po && '.
    'LC_ALL=C COLUMNS=80 perl ../po4a t-05-config/test04.conf > tmp/err 2>&1';
@{$tests[6]{'test'}} =
    ("diff -u t-05-config/test06.err tmp/err 1>&2",
     "perl compare-po.pl --no-ref t-05-config/test02.pot tmp/test02.pot",
     "perl compare-po.pl --no-ref t-05-config/test02.fr.po tmp/test02.fr.po",
     "perl compare-po.pl --no-ref t-05-config/test02.es.po tmp/test02.es.po",
     "perl compare-po.pl --no-ref t-05-config/test02.it.po tmp/test02.it.po",
     "perl compare-po.pl --no-ref t-05-config/test02.de.po tmp/test02.de.po",
     "diff -u t-05-config/test02_man.fr.1 tmp/test02_man.fr.1 1>&2",
     "diff -u t-05-config/test02_man.es.1 tmp/test02_man.es.1 1>&2",
     "diff -u t-05-config/test02_man.it.1 tmp/test02_man.it.1 1>&2",
     "diff -u t-05-config/test02_man.de.1 tmp/test02_man.de.1 1>&2");


$tests[7]{'doc'}  = 'module alias + options per language';
$tests[7]{'run'}  =
    'cp t-05-config/test02.??.po tmp/ && '.
    'chmod u+w tmp/test02.??.po && '.
    'LC_ALL=C COLUMNS=80 perl ../po4a t-05-config/test05.conf > tmp/err 2>&1';
@{$tests[7]{'test'}} =
    ("diff -u t-05-config/test07.err tmp/err 1>&2",
     "perl compare-po.pl --no-ref t-05-config/test02.pot tmp/test02.pot",
     "perl compare-po.pl --no-ref t-05-config/test02.fr.po tmp/test02.fr.po",
     "perl compare-po.pl --no-ref t-05-config/test02.es.po tmp/test02.es.po",
     "perl compare-po.pl --no-ref t-05-config/test02.it.po tmp/test02.it.po",
     "perl compare-po.pl --no-ref t-05-config/test02.de.po tmp/test02.de.po",
     "diff -u t-05-config/test02_man.fr.1 tmp/test02_man.fr.1 1>&2",
     "diff -u t-05-config/test02_man.es.1 tmp/test02_man.es.1 1>&2",
     "diff -u t-05-config/test02_man.it.1 tmp/test02_man.it.1 1>&2",
     "test ! -e tmp/test02_man.de.1");


$tests[8]{'doc'}  = 'template languages in po4a_paths';
$tests[8]{'run'}  =
    'cp t-05-config/test02.??.po tmp/ && '.
    'chmod u+w tmp/test02.??.po && '.
    'LC_ALL=C COLUMNS=80 perl ../po4a -f t-05-config/test08.conf > tmp/err 2>&1';
@{$tests[8]{'test'}} =
    ("diff -u t-05-config/test03.err tmp/err 1>&2",
     "perl compare-po.pl --no-ref t-05-config/test02.pot tmp/test02.pot",
     "perl compare-po.pl --no-ref t-05-config/test02.fr.po tmp/test02.fr.po",
     "perl compare-po.pl --no-ref t-05-config/test02.es.po tmp/test02.es.po",
     "perl compare-po.pl --no-ref t-05-config/test02.it.po tmp/test02.it.po",
     "perl compare-po.pl --no-ref t-05-config/test02.de.po tmp/test02.de.po",
     "diff -u t-05-config/test02_man.fr.1 tmp/test02_man.fr.1 1>&2",
     "test ! -e tmp/test02_man.es.1",
     "diff -u t-05-config/test02_man.it.1 tmp/test02_man.it.1 1>&2",
     "test ! -e tmp/test02_man.de.1");

$tests[9]{'doc'}  = 'Check that no-update actually does not update the po file';
$tests[9]{'run'}  =
    'cp t-05-config/test00.fr.po tmp '.
    '&& printf "\n#. Fake entry\nmsgid \"This entry will disappear if pofile is updated\"\nmsgstr \"\"\n" >> tmp/test00.fr.po '.
    '&& touch -d "2 hours ago" tmp/test00.fr.po '.
    '&& LC_ALL=C COLUMNS=80 perl ../po4a --no-update t-05-config/test00.conf >> tmp/test09.err 2>&1';
@{$tests[9]{'test'}} =
    ("diff -u t-05-config/test09.err tmp/test09.err 1>&2",
     "perl compare-po.pl --no-ref t-05-config/test09.fr tmp/test00.fr.po",
     "test tmp/test00.fr.po -ot tmp/test09.err");

use Test::More tests => 95;

for (my $i=0; $i<scalar @tests; $i++) {
    chdir "t" || die "Can't chdir to my test directory";

    system("rm -f tmp/* 2>&1");

    my $cmd=$tests[$i]{'run'};
    my $val=system($cmd);

    my $name=$tests[$i]{'doc'}.' runs';
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

# Detect broken po files
{
    chdir "t" || die "Can't chdir to my test directory";
    system("rm -f tmp/* 2>&1");

    my $ret = system('cp t-05-config/test50.* tmp/; ');
    is($ret,0, "cp did not went well");

    $ret = system('LC_ALL=C COLUMNS=80 perl ../po4a -f t-05-config/test50.conf > tmp/test50.err 2>&1');
    isnt($ret, 0, "Error was not detected");
    if ($ret == 0) {
	diag("Output reads:");
	diag(qx|cat tmp/test50.err|);
    }

    $ret = system('diff -u t-05-config/test50.err tmp/test50.err 1>&2');
    is($ret, 0, "diff command should return 0");
    if ($ret != 0) {
	diag("Output difference reads:");
	diag(qx|diff -u t-05-config/test50.err tmp/test50.err|);
    }

    ok(! -e "tmp/test50.en.1", "File tmp/test50.en.1 should not exist");
    chdir ".." || die "Can't chdir back to my root";
}

0;
