#! /usr/bin/perl
# Text module tester.

#########################

use strict;
use warnings;

my @tests;

unless (-e "t/tmp") {
    mkdir "t/tmp"
        or die "Can't create test directory t/tmp: $!\n";
}

my $UGCS = '';
$UGCS = 'exit 0;' unless (eval { require Unicode::GCString });

my @AsciiDocTests = qw(Titles BlockTitles BlockId Paragraphs
DelimitedBlocks Lists Footnotes Callouts Comments Tables Attributes);

foreach my $AsciiDocTest (@AsciiDocTests) {
    # Tables are currently badly supported.
    next if $AsciiDocTest =~ m/Tables/;
    push @tests, {
        'run' => "perl ../../po4a-normalize -f text -o asciidoc ../data-30/$AsciiDocTest.asciidoc",
        'test'=> "perl ../compare-po.pl ../data-30/$AsciiDocTest.po po4a-normalize.po".
                 "&& cmp ../data-30/$AsciiDocTest.out po4a-normalize.output",
        'doc' => "$AsciiDocTest test"
    };
}

push @tests, {
    'run' => "$UGCS perl ../../po4a-gettextize -f text -o asciidoc -m ../data-30/Titles.asciidoc -l ../data-30/TitlesUTF8.asciidoc -L UTF-8 -p TitlesUTF8.po",
    'test'=> "$UGCS perl ../compare-po.pl ../data-30/TitlesUTF8.po TitlesUTF8.po",
    'doc' => "$UGCS test titles with UTF-8 encoding"
};
push @tests, {
    'run' => "$UGCS msgattrib --clear-fuzzy -o TitlesUTF8.po TitlesUTF8.po && perl ../../po4a-translate -f text -o asciidoc -m ../data-30/Titles.asciidoc -l TitlesUTF8.asciidoc -p TitlesUTF8.po",
    'test'=> "$UGCS diff TitlesUTF8.asciidoc ../data-30/TitlesUTF8.asciidoc",
    'doc' => "$UGCS translate titles with UTF-8 encoding"
};
push @tests, {
    'run' => "$UGCS perl ../../po4a-gettextize -f text -o asciidoc -m ../data-30/Titles.asciidoc -l ../data-30/TitlesLatin1.asciidoc -L iso-8859-1 -p TitlesLatin1.po",
    'test'=> "$UGCS perl ../compare-po.pl ../data-30/TitlesLatin1.po TitlesLatin1.po",
    'doc' => "$UGCS test titles with latin1 encoding"
};
push @tests, {
    'run' => "$UGCS msgattrib --clear-fuzzy -o TitlesLatin1.po TitlesLatin1.po && perl ../../po4a-translate -f text -o asciidoc -m ../data-30/Titles.asciidoc -l TitlesLatin1.asciidoc -p TitlesLatin1.po",
    'test'=> "$UGCS diff TitlesLatin1.asciidoc ../data-30/TitlesLatin1.asciidoc",
    'doc' => "$UGCS translate titles with latin1 encoding"
};
use Test::More tests => 2 * 14;

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

chdir "../.."
    or die "Can't chdir back to my root";

0;
