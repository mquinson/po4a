#! /usr/bin/perl
# Addenda modifiers tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests, {
    'doc'            => 'Many PO references',
    'po4a.conf'      => 'core/porefs/po4a.conf',
    'options'        => '--no-translations',
    'modes'          => 'dstdir',
    'expected_files' => 'list.pot up.po',
    'tests'          => [
        'PODIFF core/porefs/_base.pot tmp/core/porefs/list.pot',    # force tidyall to wrap here
        'PODIFF core/porefs/_base.po  tmp/core/porefs/up.po',
    ]
  },
  {
    'doc'            => 'Many PO references --porefs=none',
    'po4a.conf'      => 'core/porefs/po4a.conf',
    'options'        => '--no-translations --porefs=none',
    'modes'          => 'dstdir',
    'expected_files' => 'list.pot up.po',
    'tests'          => [
        'PODIFF core/porefs/_none.pot tmp/core/porefs/list.pot',    #
        'PODIFF core/porefs/_none.po  tmp/core/porefs/up.po',
    ]
  },
  {
    'doc'            => 'Many PO references --porefs=file',
    'po4a.conf'      => 'core/porefs/po4a.conf',
    'options'        => '--no-translations --porefs=file',
    'modes'          => 'dstdir',
    'expected_files' => 'list.pot up.po',
    'tests'          => [
        'PODIFF core/porefs/_file.pot tmp/core/porefs/list.pot',    #
        'PODIFF core/porefs/_file.po  tmp/core/porefs/up.po',
    ]
  },
  {
    'doc'            => 'Many PO references --porefs=counter',
    'po4a.conf'      => 'core/porefs/po4a.conf',
    'options'        => '--no-translations --porefs=counter',
    'modes'          => 'dstdir',
    'expected_files' => 'list.pot up.po',
    'tests'          => [
        'PODIFF core/porefs/_counter.pot tmp/core/porefs/list.pot',
        'PODIFF core/porefs/_counter.po  tmp/core/porefs/up.po',
    ]

  };

run_all_tests(@tests);
0;
