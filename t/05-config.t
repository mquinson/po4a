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
push @tests,
  {
    'doc' => 'template languages - command line arguments',
    'run' => 'cp t-05-config/test02.??.po tmp/ && '
      . 'chmod u+w tmp/test02.??.po && '
      . 'PATH -v -k 0 t-05-config/test02.conf >tmp/err',
    'tests' => [
        "sed -e 's,^\.* done\.,. done.,' -e 's,^tmp/test02\\.[^:]*\.po: ,,' tmp/err | diff -u t-05-config/test04.err - ",
        "diff -u -I\'^#:\' -I'^\"POT-Creation-Date:' -I'^\"PO-Revision-Date:' -IContent-Type t-05-config/test02.pot tmp/test02.pot",
        "diff -u -I\'^#:\' -I'^\"POT-Creation-Date:' -I'^\"PO-Revision-Date:' t-05-config/test02.fr.po tmp/test02.fr.po",
        "diff -u -I\'^#:\' -I'^\"POT-Creation-Date:' -I'^\"PO-Revision-Date:' t-05-config/test02.es.po tmp/test02.es.po",
        "diff -u -I\'^#:\' -I'^\"POT-Creation-Date:' -I'^\"PO-Revision-Date:' t-05-config/test02.it.po tmp/test02.it.po",
        "diff -u -I\'^#:\' -I'^\"POT-Creation-Date:' -I'^\"PO-Revision-Date:' t-05-config/test02.de.po tmp/test02.de.po",
        "diff -u t-05-config/test02_man.fr.1 tmp/test02_man.fr.1",
        "diff -u t-05-config/test02_man.es.1 tmp/test02_man.es.1",
        "diff -u t-05-config/test02_man.it.1 tmp/test02_man.it.1",
        "diff -u t-05-config/test02_man.de.1 tmp/test02_man.de.1",
    ]
  },
  {
    'doc' => 'command line arguments + options (-k 0 is specified in the file opt)',
    'run' => 'cp t-05-config/test02.??.po tmp/ && '
      . 'chmod u+w tmp/test02.??.po && '
      . 'PATH/po4a -v t-05-config/test03.conf',
    'tests' => [
        "sed -e 's,^\.* done\.,. done.,' -e 's,^tmp/test02\\.[^:]*\.po: ,,' tmp/err | diff -u t-05-config/test04.err - ",
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

    'doc' => 'module alias (-k 0 -v is specified for the alias) + options ',
    'run' => 'cp t-05-config/test02.??.po tmp/ && '
      . 'chmod u+w tmp/test02.??.po && '
      . 'PATH/po4a t-05-config/test04.conf > tmp/err',
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
    'doc' => 'module alias + options per language',
    'run' => 'cp t-05-config/test02.??.po tmp/ && '
      . 'chmod u+w tmp/test02.??.po && '
      . 'PATH/po4a t-05-config/test05.conf',
    'tests' => [
        "diff -u t-05-config/test07.err tmp/err",
        "diff -u -I\'^#:\' -I'^\"POT-Creation-Date:' -I'^\"PO-Revision-Date:' -IContent-Type: t-05-config/test02.pot tmp/test02.pot",
        "diff -u -I\'^#:\' -I'^\"POT-Creation-Date:' -I'^\"PO-Revision-Date:' t-05-config/test02.fr.po tmp/test02.fr.po",
        "diff -u -I\'^#:\' -I'^\"POT-Creation-Date:' -I'^\"PO-Revision-Date:' t-05-config/test02.es.po tmp/test02.es.po",
        "diff -u -I\'^#:\' -I'^\"POT-Creation-Date:' -I'^\"PO-Revision-Date:' t-05-config/test02.it.po tmp/test02.it.po",
        "diff -u -I\'^#:\' -I'^\"POT-Creation-Date:' -I'^\"PO-Revision-Date:' t-05-config/test02.de.po tmp/test02.de.po",
        "diff -u t-05-config/test02_man.fr.1 tmp/test02_man.fr.1",
        "diff -u t-05-config/test02_man.es.1 tmp/test02_man.es.1",
        "diff -u t-05-config/test02_man.it.1 tmp/test02_man.it.1",
        "test ! -e tmp/test02_man.de.1"
    ]
  },
  {
    'doc'   => 'Detect broken po files',
    'run'   => 'cp t-05-config/test50.* tmp/ ' . '&& PATH/po4a -f t-05-config/test50.conf > tmp/test50.err 2>&1',
    'tests' => [ 'diff -u t-05-config/test50.err tmp/test50.err', 'test ! -e tmp/test50.en.1' ]

  };

run_all_tests(@tests);

0;
