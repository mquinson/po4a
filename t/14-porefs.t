#! /usr/bin/perl
# config file tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'run' =>
      'perl ../po4a -f --porefs=none t-14-porefs/test1.conf > tmp/err 2>&1',
    'test' => "diff -u t-14-porefs/test1.err tmp/err 1>&2 "
      . "&& perl compare-po.pl t-14-porefs/none.pot tmp/test1.pot "
      . "&& perl compare-po.pl t-14-porefs/none.fr.po tmp/test1.fr.po "
      . "&& perl compare-po.pl t-14-porefs/none.de.po tmp/test1.de.po",
    'doc' => 'po4a --porefs=none flag',
  },
  {
    'run' =>
      'perl ../po4a -f --porefs=file t-14-porefs/test1.conf > tmp/err 2>&1',
    'test' => "diff -u t-14-porefs/test1.err tmp/err 1>&2 "
      . "&& perl compare-po.pl t-14-porefs/file.pot tmp/test1.pot "
      . "&& perl compare-po.pl t-14-porefs/file.fr.po tmp/test1.fr.po "
      . "&& perl compare-po.pl t-14-porefs/file.de.po tmp/test1.de.po",
    'doc' => 'po4a --porefs=file flag',
  },
  {
    'run' =>
'perl ../po4a-updatepo --porefs=file -f man -m t-21-TransTractors/man -p tmp/updatepo-file.pot  > tmp/updatepo.err 2>&1',
    'test' => "diff -u t-14-porefs/updatepo.err tmp/updatepo.err 1>&2 "
      . "&& perl compare-po.pl t-14-porefs/updatepo-file.pot tmp/updatepo-file.pot",
    'doc' => 'po4a-updatepo --porefs=file flag',
  },
  {
    'run' =>
'perl ../po4a -f --porefs=file,wrap t-14-porefs/test1.conf > tmp/err 2>&1',
    'test' => "diff -u t-14-porefs/test1.err tmp/err 1>&2 "
      . "&& perl compare-po.pl t-14-porefs/file_wrap.pot tmp/test1.pot "
      . "&& perl compare-po.pl t-14-porefs/file_wrap.fr.po tmp/test1.fr.po "
      . "&& perl compare-po.pl t-14-porefs/file_wrap.de.po tmp/test1.de.po",
    'doc' => 'po4a --porefs=file,wrap flag',
  },
  {
    'run' =>
'perl ../po4a -f --porefs=file,nowrap t-14-porefs/test1.conf > tmp/err 2>&1',
    'test' => "diff -u t-14-porefs/test1.err tmp/err 1>&2 "
      . "&& perl compare-po.pl t-14-porefs/file.pot tmp/test1.pot "
      . "&& perl compare-po.pl t-14-porefs/file.fr.po tmp/test1.fr.po "
      . "&& perl compare-po.pl t-14-porefs/file.de.po tmp/test1.de.po",
    'doc' => 'po4a --porefs=file,nowrap flag',
  },
  {
    'run' =>
      'perl ../po4a -f --porefs=counter t-14-porefs/test1.conf > tmp/err 2>&1',
    'test' => "diff -u t-14-porefs/test1.err tmp/err 1>&2 "
      . "&& perl compare-po.pl t-14-porefs/counter.pot tmp/test1.pot "
      . "&& perl compare-po.pl t-14-porefs/counter.fr.po tmp/test1.fr.po "
      . "&& perl compare-po.pl t-14-porefs/counter.de.po tmp/test1.de.po",
    'doc' => 'po4a --porefs=counter flag',
  },
  {
    'run' =>
'perl ../po4a -f --porefs=counter,wrap t-14-porefs/test1.conf > tmp/err 2>&1',
    'test' => "diff -u t-14-porefs/test1.err tmp/err 1>&2 "
      . "&& perl compare-po.pl t-14-porefs/counter_wrap.pot tmp/test1.pot "
      . "&& perl compare-po.pl t-14-porefs/counter_wrap.fr.po tmp/test1.fr.po "
      . "&& perl compare-po.pl t-14-porefs/counter_wrap.de.po tmp/test1.de.po",
    'doc' => 'po4a --porefs=counter,wrap flag',
  },
  {
    'run' =>
'perl ../po4a -f --porefs=counter,nowrap t-14-porefs/test1.conf > tmp/err 2>&1',
    'test' => "diff -u t-14-porefs/test1.err tmp/err 1>&2 "
      . "&& perl compare-po.pl t-14-porefs/counter.pot tmp/test1.pot "
      . "&& perl compare-po.pl t-14-porefs/counter.fr.po tmp/test1.fr.po "
      . "&& perl compare-po.pl t-14-porefs/counter.de.po tmp/test1.de.po",
    'doc' => 'po4a --porefs=counter,nowrap flag',
  },
  {
    'run' =>
'perl ../po4a -f --porefs=full,wrap t-14-porefs/test1.conf > tmp/err 2>&1',
    'test' => "diff -u t-14-porefs/test1.err tmp/err 1>&2 "
      . "&& perl compare-po.pl t-14-porefs/full_wrap.pot tmp/test1.pot "
      . "&& perl compare-po.pl t-14-porefs/full_wrap.fr.po tmp/test1.fr.po "
      . "&& perl compare-po.pl t-14-porefs/full_wrap.de.po tmp/test1.de.po",
    'doc' => 'po4a --porefs=full,wrap flag',
  },
  {
    'run' =>
'perl ../po4a -f --porefs=full,nowrap t-14-porefs/test1.conf > tmp/err 2>&1',
    'test' => "diff -u t-14-porefs/test1.err tmp/err 1>&2 "
      . "&& perl compare-po.pl t-14-porefs/full.pot tmp/test1.pot "
      . "&& perl compare-po.pl t-14-porefs/full.fr.po tmp/test1.fr.po "
      . "&& perl compare-po.pl t-14-porefs/full.de.po tmp/test1.de.po",
    'doc' => 'po4a --porefs=full,nowrap flag',
  };

run_all_tests(@tests);
0;
