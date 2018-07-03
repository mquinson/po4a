# Yaml module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'run' =>
"perl ../po4a-normalize -f yaml t-25-yaml/yamltest.yaml > tmp/yamltest.err 2>&1"
      . "&& mv po4a-normalize.po tmp/yamltest.po "
      . "&& mv po4a-normalize.output tmp/yamltest.out ",
    'test' => "perl compare-po.pl t-25-yaml/yamltest.po tmp/yamltest.po "
      . "&& diff -u t-25-yaml/yamltest.out tmp/yamltest.out 1>&2"
      . "&& diff -u t-25-yaml/yamltest.err tmp/yamltest.err 1>&2",
    'doc' => "yamltest test"
  };

push @tests,
  {
    'run' =>
"perl ../po4a-normalize -f yaml t-25-yaml/yamlkeysoption1.yaml -o keys=name > tmp/yamlkeysoption1.err 2>&1"
      . "&& mv po4a-normalize.po tmp/yamlkeysoption1.po "
      . "&& mv po4a-normalize.output tmp/yamlkeysoption1.out ",
    'test' =>
      "perl compare-po.pl t-25-yaml/yamlkeysoption1.po tmp/yamlkeysoption1.po "
      . "&& diff -u t-25-yaml/yamlkeysoption1.out tmp/yamlkeysoption1.out 1>&2"
      . "&& diff -u t-25-yaml/yamlkeysoption1.err tmp/yamlkeysoption1.err 1>&2",
    'doc' => "yamlkeysoption1 test"
  };

push @tests,
  {
    'run' =>
"perl ../po4a-normalize -f yaml t-25-yaml/yamlkeysoption2.yaml -o 'keys=name file' > tmp/yamlkeysoption2.err 2>&1"
      . "&& mv po4a-normalize.po tmp/yamlkeysoption2.po "
      . "&& mv po4a-normalize.output tmp/yamlkeysoption2.out ",
    'test' =>
      "perl compare-po.pl t-25-yaml/yamlkeysoption2.po tmp/yamlkeysoption2.po "
      . "&& diff -u t-25-yaml/yamlkeysoption2.out tmp/yamlkeysoption2.out 1>&2"
      . "&& diff -u t-25-yaml/yamlkeysoption2.err tmp/yamlkeysoption2.err 1>&2",
    'doc' => "yamlkeysoption2 test"
  };

push @tests,
  {
    'run' =>
"perl ../po4a-normalize -f yaml t-25-yaml/yamlutf8.yaml -M UTF-8 > tmp/yamlutf8.err 2>&1"
      . "&& mv po4a-normalize.po tmp/yamlutf8.po "
      . "&& mv po4a-normalize.output tmp/yamlutf8.out ",
    'test' => "perl compare-po.pl t-25-yaml/yamlutf8.po tmp/yamlutf8.po "
      . "&& diff -u t-25-yaml/yamlutf8.out tmp/yamlutf8.out 1>&2"
      . "&& diff -u t-25-yaml/yamlutf8.err tmp/yamlutf8.err 1>&2",
    'doc' => "yamlutf8 test"
  };

run_all_tests(@tests);
0;
