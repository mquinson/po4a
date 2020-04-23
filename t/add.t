#! /usr/bin/perl
# Addenda modifiers tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests, {
    'doc'            => 'Several kind of positioning (examples of the doc) POD format',
    'po4a.conf'      => 'add/positioning/positioning.conf',
    'closed_path'    => 'add/*/',
    'expected_files' => 'file-before.pod.fr file-after.pod.fr file-eof.pod.fr fr.po positioning.pot',

  },
  {
    'doc'            => 'Lists of addendums (asciidoc format)',
    'po4a.conf'      => 'add/list/po4a.conf',
    'closed_path'    => 'add/*/',
    'expected_files' => 'output-1 output-2 output-3 output-123 output-list up.po list.pot',

  },
  {
    'doc'            => 'Modifiers (asciidoc format)',
    'po4a.conf'      => 'add/modifiers/po4a.conf',
    'closed_path'    => 'add/*/',
    'options'        => '--no-update',
    'expected_files' => 'with-1 without-2 without-3 without-4 without-5 without-6 with-7 without-8',
  },
  {
    'doc'            => 'Same path to addenda for all languages (and ? modifier)',
    'po4a.conf'      => 'add/path/po4a.conf',
    'closed_path'    => 'add/*/',
    'expected_files' => 'multiple.de.po multiple.es.po multiple.fr.po multiple.it.po '
      . 'multiple.man.de.1 multiple.man.es.1 multiple.man.fr.1 multiple.man.it.1 multiple.pot',

  };

run_all_tests(@tests);
0;
