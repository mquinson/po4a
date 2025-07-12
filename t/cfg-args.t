#! /usr/bin/perl
# config file tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper qw( run_all_tests );

# TODO: alias option overriding generic option
# TODO: file-specific overriding alias option

my @tests;
push @tests, {
    'doc'            => '-k 20 in global options',
    'po4a.conf'      => 'cfg/args-global/po4a.conf',
    'modes'          => 'dstdir',                               # no need to test every mode
    'options'        => '--no-update',                          # no need for the produced po files
    'expected_files' => 'man.de.1 man.es.1 man.fr.1 man.it.1'

  },
  {
    'doc'              => '-k 100 on command line >> -k 20 in global options',
    'po4a.conf'        => 'cfg/args-global/po4a.conf',
    'modes'            => 'dstdir',
    'options'          => '--no-update --keep 100',
    'expected_outfile' => '_output-keep100',
    'expected_files'   => 'man.it.1'

  },
  {
    'doc'            => '-k 0 in type alias',
    'po4a.conf'      => 'cfg/args-alias/po4a.conf',
    'modes'          => 'dstdir',
    'options'        => '--no-update',
    'expected_files' => 'man.de.1 man.fr.1 man.fr.2 man.it.1 man.it.2'
  },
  {
    'doc'              => '-k 100 on command line >> -k 0 in type alias',
    'po4a.conf'        => 'cfg/args-alias/po4a.conf',
    'modes'            => 'dstdir',
    'options'          => '--no-update --keep 100',
    'expected_outfile' => '_output-keep100',
    'expected_files'   => 'man.it.1 man.it.2'

  },
  {
    'doc'            => '-k 0 in type alias, but with a redefinition of the same alias',
    'po4a.conf'      => 'cfg/args-alias-redef/po4a.conf',
    'modes'          => 'dstdir',
    'options'        => '--no-update',
    'expected_files' => 'man.de.1 man.fr.1 man.it.1'
  },
  {
    'doc'            => '-k 40 in master doc',
    'po4a.conf'      => 'cfg/args-master/po4a.conf',
    'modes'          => 'dstdir',
    'options'        => '--no-update',
    'expected_files' => 'man.fr.1 man.it.1'
  },
  {
    'doc'              => '-k 100 on command line >> -k 40 in master doc',
    'po4a.conf'        => 'cfg/args-master/po4a.conf',
    'modes'            => 'dstdir',
    'options'          => '--no-update --keep 100',
    'expected_outfile' => '_output-keep100',
    'expected_files'   => 'man.it.1'
  },
  {
    'doc'            => 'spaces in the directory and file names',
    'po4a.conf'      => 'cfg/space_in_name/po4a.conf',
    'closed_path'    => 'cfg/*/',
    'expected_files' => 'some\ directory space\ in\ name.fr.po  space\ in\ name.pot',
  },
  {
    'doc'            => 'Just like single-uptodate, but with the config file in DOS encoding',
    'po4a.conf'      => 'cfg/windows-CRLF/windows-CRLF.conf',
    'closed_path'    => 'cfg/*/',
    'expected_files' => 'single-uptodate.fr.po  single-uptodate.pot single-uptodate.man.fr.1',

  },
  {
    'doc'              => '--target-lang',
    'po4a.conf'        => 'cfg/args-global/po4a.conf',
    'options'          => '--no-update --target-lang=de --target-lang=fr',
    'expected_outfile' => '_output-target-lang',
    'expected_files'   => 'man.de.1 man.fr.1'
  };

run_all_tests(@tests);

0;
