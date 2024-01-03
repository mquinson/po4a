#! /usr/bin/perl
# Character sets tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'doc'            => 'master encoding: ascii',
    'po4a.conf'      => 'charset/input-ascii/po4a.conf',
    'closed_path'    => 'charset/*/',
    'options'        => '--keep 0',
    'expected_files' => 'ascii.up.po ascii.pot ascii.up.pod ',
  },
  {
    'doc'            => 'master encoding: iso8859',
    'po4a.conf'      => 'charset/input-iso8859/po4a.conf',
    'closed_path'    => 'charset/*/',
    'options'        => '--keep 0',
    'expected_files' => 'iso8859.up.po iso8859.pot iso8859.up.pod ',
  },
  {
    'doc'            => 'master encoding: UTF-8 ',
    'po4a.conf'      => 'charset/input-utf8/po4a.conf',
    'closed_path'    => 'charset/*/',
    'options'        => '--keep 0',
    'expected_files' => 'utf8.up.po utf8.pot utf8.up.pod ',
  },
  {
    'format' => 'asciidoc',
    'input'  => "charset/asciidoc/CharsetUtf.adoc",
  },
  {
    'format'  => 'asciidoc',
    'options' => '-M iso-8859-1',
    'input'   => "charset/asciidoc/CharsetLatin1.adoc",
  },
  {
    'format'  => 'yaml',
    'options' => "-M UTF-8",
    'input'   => "charset/yaml/utf8.yaml",
  };

run_all_tests(@tests);
0;
