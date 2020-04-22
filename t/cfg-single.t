#! /usr/bin/perl
# config file tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;
push @tests, {
    'doc'            => 'Single language, no pot no po',
    'po4a.conf'      => 'cfg/single-nopotpo/po4a.conf',
    'closed_path'    => 'cfg/*/',                          # Do not use or modify the other tests
    'expected_files' => 'single.fr.po  single.pot',
  },
  {
    'doc'            => 'Single language, no po',
    'po4a.conf'      => 'cfg/single-nopo/po4a.conf',
    'closed_path'    => 'cfg/*/',
    'expected_files' => 'single.fr.po  single.pot',

  },
  {
    'doc'              => 'Single language, no po, --no-update',
    'po4a.conf'        => 'cfg/single-nopo/po4a.conf',
    'options'          => ' --no-update',
    'closed_path'      => 'cfg/*/',
    'expected_outfile' => 'cfg/single-nopo/_output-noupdate',
    'expected_files'   => '',

  },
  {
    'doc'            => 'Single language, with translation to create',
    'po4a.conf'      => 'cfg/single/single.conf',
    'closed_path'    => 'cfg/*/',
    'expected_files' => 'single.fr.po  single.pot single.man.fr.1',

  },
  {
    'doc'            => 'Single language, translation uptodate',
    'po4a.conf'      => 'cfg/single-uptodate/single-uptodate.conf',
    'closed_path'    => 'cfg/*/',
    'expected_files' => 'single-uptodate.fr.po  single-uptodate.pot single-uptodate.man.fr.1',

  },
  {
    'doc'            => 'Single language, translation already fuzzy',
    'po4a.conf'      => 'cfg/single-fuzzy/po4a.conf',
    'closed_path'    => 'cfg/*/',
    'expected_files' => 'single-fuzzy.fr.po single-fuzzy.pot',

  },
  {
    'doc'            => 'Single language, translation fuzzied during the update',
    'po4a.conf'      => 'cfg/single-fuzzied/po4a.conf',
    'closed_path'    => 'cfg/*/',
    'expected_files' => 'single-fuzzied.fr.po single-fuzzied.pot',

  },
  {
    'doc'            => 'Single language, translation would be fuzzied if --no-update were not given',
    'po4a.conf'      => 'cfg/single-fuzzied-noup/po4a.conf',
    'options'        => '--no-update',
    'closed_path'    => 'cfg/*/',
    'expected_files' => '',

  },
  {
    'doc'            => 'Single language, with a new string appearing in the master doc',
    'po4a.conf'      => 'cfg/single-newstr/po4a.conf',
    'closed_path'    => 'cfg/*/',
    'expected_files' => 'single-newstr.fr.po single-newstr.pot single-newstr.man.fr.1',
  },
  {
    'doc'              => 'Single language, with a validation error reported by msgfmt',
    'po4a.conf'        => 'cfg/single-invalid/po4a.conf',
    'closed_path'      => 'cfg/*/',
    'expected_retcode' => 256,
    'expected_files'   => 'single.fr.po single.pot',
  },
  {
    'doc'            => 'Single language, with a separate pot_in file',
    'po4a.conf'      => 'cfg/single-potin/po4a.conf',
    'closed_path'    => 'cfg/*/',
    'expected_files' => 'single.man.fr.1 single.fr.po single.pot',
  };

run_all_tests(@tests);

0;
