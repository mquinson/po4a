#! /usr/bin/perl
# config file tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;
push @tests, {
    'doc'         => 'Split settings, no pot no po',
    'po4a.conf'   => 'cfg/split-nopotpo/po4a.conf',
    'closed_path' => 'cfg/*/',                         # Do not use or modify the other tests
    'expected_files' =>
      'first.man.de.po first.man.fr.po first.man.pot second.man.de.po second.man.fr.po second.man.pot',
  },
  {
    'doc'         => 'Split settings, no po',
    'po4a.conf'   => 'cfg/split-nopo/po4a.conf',
    'closed_path' => 'cfg/*/',
    'expected_files' =>
      'first.man.de.po first.man.fr.po first.man.pot second.man.de.po second.man.fr.po second.man.pot',

  },
  {
    'todo' => 'POT files created anyway',

    'doc'              => 'Split settings, no po, --no-update',
    'po4a.conf'        => 'cfg/split-nopo/po4a.conf',
    'options'          => ' --no-update',
    'closed_path'      => 'cfg/*/',
    'expected_outfile' => 'cfg/split-nopo/_output-noupdate',
    'expected_files'   => '',

  },
  {
    'doc'            => 'Split settings, with translation to create',
    'po4a.conf'      => 'cfg/split/po4a.conf',
    'closed_path'    => 'cfg/*/',
    'expected_files' => 'first.man.de first.man.de.po first.man.fr first.man.fr.po first.man.pot '
      . 'second.man.de second.man.de.po second.man.fr second.man.fr.po second.man.pot',

  },
  {
    'doc'            => 'Split settings, translation uptodate',
    'po4a.conf'      => 'cfg/split-uptodate/po4a.conf',
    'closed_path'    => 'cfg/*/',
    'expected_files' => 'first.man.de first.man.de.po first.man.fr first.man.fr.po first.man.pot '
      . 'second.man.de second.man.de.po second.man.fr second.man.fr.po second.man.pot',

  },
  {
    'doc'            => 'Split settings, translation already fuzzy',
    'po4a.conf'      => 'cfg/split-fuzzy/po4a.conf',
    'closed_path'    => 'cfg/*/',
    'expected_files' => 'first.man.de first.man.de.po first.man.fr first.man.fr.po first.man.pot '
      . 'second.man.de second.man.de.po second.man.fr second.man.fr.po second.man.pot',

  },
  {
    'doc'            => 'Split settings, translation fuzzied during the update',
    'po4a.conf'      => 'cfg/split-fuzzied/po4a.conf',
    'closed_path'    => 'cfg/*/',
    'expected_files' => 'first.man.de first.man.de.po first.man.fr first.man.fr.po first.man.pot '
      . 'second.man.de second.man.de.po second.man.fr second.man.fr.po second.man.pot',

  },
  {
    'todo' => 'POT files touched anyway',

    'doc'            => 'Split settings, translation would be fuzzied if --no-update were not given',
    'po4a.conf'      => 'cfg/split-fuzzied-noup/po4a.conf',
    'options'        => '--no-update',
    'closed_path'    => 'cfg/*/',
    'expected_files' => 'first.man.de first.man.fr second.man.de second.man.fr',

  },
  {
    'doc'            => 'Split settings, with a new string appearing in the master doc',
    'po4a.conf'      => 'cfg/split-newstr/po4a.conf',
    'closed_path'    => 'cfg/*/',
    'expected_files' => 'first.man.de first.man.de.po first.man.fr first.man.fr.po first.man.pot '
      . 'second.man.de second.man.de.po second.man.fr second.man.fr.po second.man.pot',
  },
  {
    'doc'            => 'Split settings, with a separate pot_in file',
    'po4a.conf'      => 'cfg/split-potin/po4a.conf',
    'closed_path'    => 'cfg/*/',
    'expected_files' => 'first.man.de first.man.de.po first.man.fr first.man.fr.po first.man.pot '
      . 'second.man.de second.man.de.po second.man.fr second.man.fr.po second.man.pot',
  };

run_all_tests(@tests);

0;
