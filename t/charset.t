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
    'doc'    => "UTF with BOM marker (code point of width 3 at the beginning of the doc to indicate that it's UTF-8)",
    'format' => 'asciidoc',
    'input'  => "charset/asciidoc/CharsetUtfBOM.adoc",
    'norm'   => "charset/asciidoc/CharsetUtf.norm",
    'trans'  => "charset/asciidoc/CharsetUtf.trans",
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
  },
  {
    'doc' => 'implicit encoding: iso8859',
    'po4a.conf' => 'charset/implicit-iso8859/po4a.conf',
    'closed_path'    => 'charset/*/',
    'options' => '--keep 0',
    'expected_files' => 'iso8859.pot iso8859.en.po iso8859.up.pod ',
  };

run_all_tests(@tests);
0;
