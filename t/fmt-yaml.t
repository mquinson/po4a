# Yaml module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'format' => 'yaml',
    'input'  => "fmt/yaml/basic.yaml"
  },
  {
    'doc'     => 'basic -o keys=name',
    'format'  => 'yaml',
    'input'   => "fmt/yaml/basic.yaml",
    'options' => "-o keys=name",
    'potfile' => 'fmt/yaml/keysoption1.pot',
    'pofile'  => 'fmt/yaml/keysoption1.po',
    'trans'   => 'fmt/yaml/keysoption1.trans',
  },
  {
    'doc'     => "basic -o keys='name file'",
    'format'  => 'yaml',
    'input'   => "fmt/yaml/basic.yaml",
    'options' => "-o 'keys=name file'",
    'potfile' => 'fmt/yaml/keysoption2.pot',
    'pofile'  => 'fmt/yaml/keysoption2.po',
    'trans'   => 'fmt/yaml/keysoption2.trans',
  },
  {
    'doc'     => "-o skip_array",
    'format'  => 'yaml',
    'options' => "-o keys=title -o skip_array",
    'input'   => "fmt/yaml/skiparray.yaml",
  },
  {
    'format'  => 'yaml',
    'options' => "-M UTF-8",
    'input'   => "fmt/yaml/utf8.yaml",
  },
  {
    'doc'     => "basic -o keys='name' -o paths='name,level1 dir,invoice,bill-to address city' -o skip_array",
    'format'  => 'yaml',
    'input'   => "fmt/yaml/basic.yaml",
    'options' => "-o keys='name' -o paths='name,level1 dir,invoice,bill-to address city' -o skip_array",
    'potfile' => 'fmt/yaml/keysandpaths1.pot',
    'pofile'  => 'fmt/yaml/keysandpaths1.po',
    'trans'   => 'fmt/yaml/keysandpaths1.trans',
  },
  {
    'doc'     => "basic -o paths='name,level1 dir ' -o skip_array",
    'format'  => 'yaml',
    'input'   => "fmt/yaml/basic.yaml",
    'options' => "-o paths='name,level1 dir' -o skip_array",
    'potfile' => 'fmt/yaml/pathsoption1.pot',
    'pofile'  => 'fmt/yaml/pathsoption1.po',
    'trans'   => 'fmt/yaml/pathsoption1.trans',
  };

run_all_tests(@tests);
0;
