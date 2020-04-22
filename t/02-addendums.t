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
    'doc'            => 'Same path to addenda for all languages',
    'po4a.conf'      => 'add/path/po4a.conf',
    'closed_path'    => 'add/*/',
    'expected_files' => 'multiple.de.po multiple.es.po multiple.fr.po multiple.it.po '
      . 'multiple.man.de.1 multiple.man.es.1 multiple.man.fr.1 multiple.man.it.1 multiple.pot',

  };

my @ignored_tests;
push @ignored_tests,
  {
    'doc'       => '(po4a) article.xml with addendum',
    'po4a.conf' => 't-02-addendums/article.conf',
    'tests'     => ['diff -u tmp/article.ja.xml t-02-addendums/article.ja.xml-good']
  },
  {
    'doc'       => '(po4a) book.xml with addendum',
    'po4a.conf' => 't-02-addendums/book.conf',
    'tests'     => ['diff -u tmp/book.ja.xml t-02-addendums/book.ja.xml-good']
  },
  {
    'doc'       => '(po4a) book.xml with addendum and separate POT input',
    'po4a.conf' => 't-02-addendums/book-potin.conf',
    'tests'     => [
        'diff -u tmp/book-auto.ja.xml t-02-addendums/book-auto.ja.xml-good',
        'diff -u t-02-addendums/book.po.ja t-02-addendums/book.po.ja-good'
    ]
  },
  {
    'run' =>
      'PATH/po4a-translate -f man -a t-02-addendums/man.addendum1 -m t-02-addendums/man -p t-02-addendums/man.po-ok -l tmp/man.fr',
    'tests' => ['diff -u t-02-addendums/man.fr.add1 tmp/man.fr'],
    'doc'   => 'translate with addendum1'
  },
  {
    'run' =>
      'PATH/po4a-translate -f man -a t-02-addendums/man.addendum2 -m t-02-addendums/man -p t-02-addendums/man.po-ok -l tmp/man.fr',
    'tests' => ['diff -u t-02-addendums/man.fr.add2 tmp/man.fr'],
    'doc'   => 'translate with addendum2'
  },
  {
    'run' =>
      'PATH/po4a-translate -f man -a t-02-addendums/man.addendum3 -m t-02-addendums/man -p t-02-addendums/man.po-ok -l tmp/man.fr',
    'tests' => ['diff -u t-02-addendums/man.fr.add3 tmp/man.fr'],
    'doc'   => 'translate with addendum3'
  },
  {
    'run' =>
      'PATH/po4a-translate -f man -a t-02-addendums/man.addendum4 -m t-02-addendums/man -p t-02-addendums/man.po-ok -l tmp/man.fr',
    'tests' => ['diff -u t-02-addendums/man.fr.add4 tmp/man.fr'],
    'doc'   => 'translate with addendum4'
  },
  {
    'run' =>
      'PATH/po4a-translate -k 0 -f text -m t-02-addendums/Titles.asciidoc -p t-02-addendums/Titles.po -l tmp/Titles.trans '
      . '-a t-02-addendums/addendum1 -a t-02-addendums/addendum2 -a t-02-addendums/addendum3',
    'tests' => ['diff -u t-02-addendums/Titles.trans.add123 tmp/Titles.trans'],
    'doc'   => 'translate with addendum1, 2 and 3'
  },
  {
    'run' =>
      'PATH/po4a-translate -k 0 -f text -m t-02-addendums/Titles.asciidoc -p t-02-addendums/Titles.po -l tmp/Titles.trans '
      . '-a @t-02-addendums/addendum123.list',
    'tests' => ['diff -u t-02-addendums/Titles.trans.add123 tmp/Titles.trans'],
    'doc'   => 'translate with @addendum'
  },
  {
    'run' =>
      'PATH/po4a-translate -k 0 -f text -m t-02-addendums/Titles.asciidoc -p t-02-addendums/Titles.po -l tmp/Titles.trans '
      . '-a !t-02-addendums/addendum2 -a @t-02-addendums/addendum123.list',
    'tests' => ['diff -u t-02-addendums/Titles.trans.add13 tmp/Titles.trans'],
    'doc'   => 'translate with !addendum'
  },
  {
    'run' =>
      'PATH/po4a-translate -k 0 -f text -m t-02-addendums/Titles.asciidoc -p t-02-addendums/Titles.po -l tmp/Titles.trans '
      . '-a ?/does/not/exist',
    'tests' => ['diff -u t-02-addendums/Titles.asciidoc tmp/Titles.trans'],
    'doc'   => 'translate with non-existing ?addendum'
  },
  {
    'run' =>
      'PATH/po4a-translate -k 0 -f text -m t-02-addendums/Titles.asciidoc -p t-02-addendums/Titles.po -l tmp/Titles.trans '
      . '-a @t-02-addendums/addendum123.list2',
    'tests' => ['diff -u t-02-addendums/Titles.trans.add1 tmp/Titles.trans'],
    'doc'   => 'translate with recursive @addendum'
  },
  {
    'doc'       => '(po4a) translate with addendum1, 2 and 3',
    'po4a.conf' => 't-02-addendums/test0.conf',
    'tests'     => ['diff -u t-02-addendums/Titles.trans.add123 tmp/Titles.trans']
  },
  {
    'po4a.conf' => 't-02-addendums/test1.conf',
    'tests'     => ['diff -u t-02-addendums/Titles.trans.add123 tmp/Titles.trans'],
    'doc'       => '(po4a) translate with @addendum'
  },
  {
    'po4a.conf' => 't-02-addendums/test2.conf',
    'tests'     => ['diff -u t-02-addendums/Titles.trans.add13 tmp/Titles.trans'],
    'doc'       => '(po4a) translate with !addendum'
  },
  {
    'po4a.conf' => 't-02-addendums/test3.conf',
    'tests'     => ['diff -u t-02-addendums/Titles.asciidoc tmp/Titles.trans'],
    'doc'       => '(po4a) translate with non-existing ?addendum'
  },
  {
    'po4a.conf' => 't-02-addendums/test4.conf',
    'tests'     => ['diff -u t-02-addendums/Titles.trans.add1 tmp/Titles.trans'],
    'doc'       => '(po4a) translate with recursive @addendum'
  };

run_all_tests(@tests);
0;
