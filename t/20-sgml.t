#! /usr/bin/perl
# SGML module tester.

#########################

use strict;
use warnings;

my @tests;

my @formats=qw(sgml);

mkdir "t/tmp" unless -e "t/tmp";

$tests[0]{'run'}  = "perl ../po4a-gettextize -f #format# -o force -m data-20/text.xml -p tmp/xml.po";
$tests[0]{'test'} = "perl compare-po.pl data-20/xml.po tmp/xml.po";
$tests[0]{'doc'}  = "gettextize well simple xml documents";
$tests[0]{'requires'} = "Text::WrapI18N";

$tests[1]{'run'}  = 'cd tmp && perl ../../po4a-normalize -f sgml ../data-20/test2.sgml';
$tests[1]{'test'} = 'perl compare-po.pl data-20/test2.pot tmp/po4a-normalize.po'.
                    ' && perl compare-po.pl data-20/test2-normalized.sgml tmp/po4a-normalize.output';
$tests[1]{'doc'}  = 'normalisation test';

use Test::More tests =>4; # $formats * $tests * 2

foreach my $format (@formats) {
    for (my $i=0; $i<scalar @tests; $i++) {
        chdir "t" || die "Can't chdir to my test directory";

        my ($val,$name);

        my $cmd=$tests[$i]{'run'};
        $cmd =~ s/#format#/$format/g;
        $val=system($cmd);

        $name=$tests[$i]{'doc'}.' runs';
        $name =~ s/#format#/$format/g;
        SKIP: {
            if (defined $tests[$i]{'requires'}) {
                skip ($tests[$i]{'requires'}." required for this test", 1)
                    unless eval 'require '.$tests[$i]{'requires'};
            }
            ok($val == 0,$name);
            diag($cmd) unless ($val == 0);
        }

        SKIP: {
            if (defined $tests[$i]{'requires'}) {
                skip ($tests[$i]{'requires'}." required for this test", 1)
                    unless eval 'require '.$tests[$i]{'requires'};
            }
            skip ("Command don't run, can't test the validity of its return",1)
              if $val;
            my $testcmd=$tests[$i]{'test'};
            $testcmd =~ s/#format#/$format/g;

            $val=system($testcmd);
            $name=$tests[$i]{'doc'}.' returns what is expected';
            $name =~ s/#format#/$format/g;
            ok($val == 0,$name);
            unless ($val == 0) {
                diag ("Failed (retval=$val) on:");
                diag ($testcmd);
                diag ("Was created with:");
                diag ("perl -I../lib $cmd");
            }
        }

#    system("rm -f tmp/* 2>&1");

        chdir ".." || die "Can't chdir back to my root";
    }
}

0;

