#! /usr/bin/perl
# config file tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

# TODO: language-specific option overriding generic option
# TODO: command line option overriding generic option
# TODO: command line option overriding language-specific option

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

  };

my @ignored_tests;
push @ignored_tests, {

    'doc' => 'module alias (-k 0 -v is specified for the alias) + options ',
    'run' => 'cp t-05-config/test02.??.po tmp/ && '
      . 'chmod u+w tmp/test02.??.po && '
      . 'PATH/po4a  t-05-config/test04.conf > tmp/err',
    'tests' => [
        "diff -u t-05-config/test06.err tmp/err",
        "diff -u -I\'^#:\' -I'^\"POT-Creation-Date:' -I'^\"PO-Revision-Date:' -IContent-Type: t-05-config/test02.pot tmp/test02.pot",
        "diff -u -I\'^#:\' -I'^\"POT-Creation-Date:' -I'^\"PO-Revision-Date:' t-05-config/test02.fr.po tmp/test02.fr.po",
        "diff -u -I\'^#:\' -I'^\"POT-Creation-Date:' -I'^\"PO-Revision-Date:' t-05-config/test02.es.po tmp/test02.es.po",
        "diff -u -I\'^#:\' -I'^\"POT-Creation-Date:' -I'^\"PO-Revision-Date:' t-05-config/test02.it.po tmp/test02.it.po",
        "diff -u -I\'^#:\' -I'^\"POT-Creation-Date:' -I'^\"PO-Revision-Date:' t-05-config/test02.de.po tmp/test02.de.po",
        "diff -u t-05-config/test02_man.fr.1 tmp/test02_man.fr.1",
        "diff -u t-05-config/test02_man.es.1 tmp/test02_man.es.1",
        "diff -u t-05-config/test02_man.it.1 tmp/test02_man.it.1",
        "diff -u t-05-config/test02_man.de.1 tmp/test02_man.de.1"
    ]
  },
  {
    'doc'   => 'Detect broken po files',
    'run'   => 'cp t-05-config/test50.* tmp/ ' . '&& PATH/po4a -f t-05-config/test50.conf > tmp/test50.err 2>&1',
    'tests' => [ 'diff -u t-05-config/test50.err tmp/test50.err', 'test ! -e tmp/test50.en.1' ]

  };

run_all_tests(@tests);

0;
