# Yaml module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'doc'       => "yamltest test",
    'normalize' => "-f yaml t-25-yaml/yamltest.yaml",
  },
  {
    'doc'       => "yamlkeysoption1 test",
    'normalize' => "-f yaml -o keys=name t-25-yaml/yamlkeysoption1.yaml",
  },
  {
    'doc'       => "yamlkeysoption2 test",
    'normalize' => "-f yaml -o 'keys=name file' t-25-yaml/yamlkeysoption2.yaml",
  },
  {
    'doc'       => "yamlutf8 test",
    'normalize' => "-f yaml -M UTF-8 t-25-yaml/yamlutf8.yaml",
  };

run_all_tests(@tests);
0;
