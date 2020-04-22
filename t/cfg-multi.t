#! /usr/bin/perl
# config file tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;
push @tests, {
    'doc'         => 'Multiple languages, no pot no po',
    'po4a.conf'   => 'cfg/multiple-nopotpo/po4a.conf',
    'closed_path' => 'cfg/*/',                             # Do not use or modify the other tests
    'expected_files' => 'multiple.de.po multiple.es.po multiple.fr.po multiple.it.po multiple.pot',
  },
  {
    'doc'            => 'Multiple languages, no po',
    'po4a.conf'      => 'cfg/multiple-nopo/po4a.conf',
    'closed_path'    => 'cfg/*/',
    'expected_files' => 'multiple.de.po multiple.es.po multiple.fr.po multiple.it.po multiple.pot',

  },
  {
    'doc'              => 'Multiple languages, no po, --no-update',
    'po4a.conf'        => 'cfg/multiple-nopo/po4a.conf',
    'options'          => ' --no-update',
    'closed_path'      => 'cfg/*/',
    'expected_outfile' => 'cfg/multiple-nopo/_output-noupdate',
    'expected_files'   => '',

  },
  {
    'doc'            => 'Multiple languages, with translation to create',
    'po4a.conf'      => 'cfg/multiple/po4a.conf',
    'closed_path'    => 'cfg/*/',
    'expected_files' => 'multiple.de.po multiple.es.po multiple.fr.po multiple.it.po '
      . 'multiple.man.de.1 multiple.man.es.1 multiple.man.fr.1 multiple.man.it.1 multiple.pot',

  },
  {
    'doc'            => 'Multiple languages, translation uptodate',
    'po4a.conf'      => 'cfg/multiple-uptodate/po4a.conf',
    'closed_path'    => 'cfg/*/',
    'expected_files' => 'multiple.de.po multiple.es.po multiple.fr.po multiple.it.po '
      . 'multiple.man.de.1 multiple.man.es.1 multiple.man.fr.1 multiple.man.it.1 multiple.pot',

  },
  {
    'doc'            => 'Multiple languages, translation already fuzzy',
    'po4a.conf'      => 'cfg/multiple-fuzzy/po4a.conf',
    'closed_path'    => 'cfg/*/',
    'expected_files' => 'multiple.de.po multiple.es.po multiple.fr.po multiple.it.po multiple.pot',

  },
  {
    'doc'            => 'Multiple languages, translation fuzzied during the update',
    'po4a.conf'      => 'cfg/multiple-fuzzied/po4a.conf',
    'closed_path'    => 'cfg/*/',
    'expected_files' => 'multiple.de.po multiple.es.po multiple.fr.po multiple.it.po multiple.pot',

  },
  {
    'doc'            => 'Multiple languages, translation would be fuzzied if --no-update were not given',
    'po4a.conf'      => 'cfg/multiple-fuzzied-noup/po4a.conf',
    'options'        => '--no-update',
    'closed_path'    => 'cfg/*/',
    'expected_files' => '',

  },
  {
    'doc'            => 'Multiple languages, with a new string appearing in the master doc',
    'po4a.conf'      => 'cfg/multiple-newstr/po4a.conf',
    'closed_path'    => 'cfg/*/',
    'expected_files' => 'multiple.de.po multiple.es.po multiple.fr.po multiple.it.po '
      . 'multiple.man.de.1 multiple.man.es.1 multiple.man.fr.1 multiple.man.it.1 multiple.pot',

  },
  {
    'doc'            => 'Multiple languages, with a separate pot_in file',
    'po4a.conf'      => 'cfg/multiple-potin/po4a.conf',
    'closed_path'    => 'cfg/*/',
    'expected_files' => 'multiple.de.po multiple.es.po multiple.fr.po multiple.it.po '
      . 'multiple.man.de.1 multiple.man.es.1 multiple.man.fr.1 multiple.man.it.1 multiple.pot',
  };

run_all_tests(@tests);

0;
