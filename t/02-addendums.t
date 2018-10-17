#! /usr/bin/perl
# Addenda modifiers tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

push @tests,
  {
    'run' => 'perl ../po4a -f t-02-addendums/article.conf',
    'test' =>
      'diff -u tmp/article.ja.xml t-02-addendums/article.ja.xml-good 1>&2',
    'doc' => '(po4a) article.xml with addendum'
  },
  {
    'run' => 'perl ../po4a -f t-02-addendums/book.conf',
    'test' =>
      'diff -u tmp/book.ja.xml t-02-addendums/book.ja.xml-good 1>&2',
    'doc' => '(po4a) book.xml with addendum'
  },
  {
    'run' => 'perl ../po4a -f t-02-addendums/book-potin.conf',
    'test' =>
      'diff -u tmp/book-auto.ja.xml t-02-addendums/book-auto.ja.xml-good 1>&2 && \
       diff -u t-02-addendums/book.po.ja t-02-addendums/book.po.ja-good 1>&2' ,
    'doc' => '(po4a) book.xml with addendum and separate POT input'
  },
  {
    'run' =>
'perl ../po4a-translate -f man -a t-02-addendums/man.addendum1 -m t-02-addendums/man -p t-02-addendums/man.po-ok -l tmp/man.fr',
    'test' => 'diff -u t-02-addendums/man.fr.add1 tmp/man.fr 1>&2',
    'doc'  => 'translate with addendum1'
  },
  {
    'run' =>
'perl ../po4a-translate -f man -a t-02-addendums/man.addendum2 -m t-02-addendums/man -p t-02-addendums/man.po-ok -l tmp/man.fr',
    'test' => 'diff -u t-02-addendums/man.fr.add2 tmp/man.fr 1>&2',
    'doc'  => 'translate with addendum2'
  },
  {
    'run' =>
'perl ../po4a-translate -f man -a t-02-addendums/man.addendum3 -m t-02-addendums/man -p t-02-addendums/man.po-ok -l tmp/man.fr',
    'test' => 'diff -u t-02-addendums/man.fr.add3 tmp/man.fr 1>&2',
    'doc'  => 'translate with addendum3'
  },
  {
    'run' =>
'perl ../po4a-translate -f man -a t-02-addendums/man.addendum4 -m t-02-addendums/man -p t-02-addendums/man.po-ok -l tmp/man.fr',
    'test' => 'diff -u t-02-addendums/man.fr.add4 tmp/man.fr 1>&2',
    'doc'  => 'translate with addendum4'
  },
  {
    'run' =>
'perl ../po4a-translate -k 0 -f text -m t-02-addendums/Titles.asciidoc -p t-02-addendums/Titles.po -l tmp/Titles.trans '
      . '-a t-02-addendums/addendum1 -a t-02-addendums/addendum2 -a t-02-addendums/addendum3',
    'test' =>
      'diff -u t-02-addendums/Titles.trans.add123 tmp/Titles.trans 1>&2',
    'doc' => 'translate with addendum1, 2 and 3'
  },
  {
    'run' =>
'perl ../po4a-translate -k 0 -f text -m t-02-addendums/Titles.asciidoc -p t-02-addendums/Titles.po -l tmp/Titles.trans '
      . '-a @t-02-addendums/addendum123.list',
    'test' =>
      'diff -u t-02-addendums/Titles.trans.add123 tmp/Titles.trans 1>&2',
    'doc' => 'translate with @addendum'
  },
  {
    'run' =>
'perl ../po4a-translate -k 0 -f text -m t-02-addendums/Titles.asciidoc -p t-02-addendums/Titles.po -l tmp/Titles.trans '
      . '-a !t-02-addendums/addendum2 -a @t-02-addendums/addendum123.list',
    'test' => 'diff -u t-02-addendums/Titles.trans.add13 tmp/Titles.trans 1>&2',
    'doc'  => 'translate with !addendum'
  },
  {
    'run' =>
'perl ../po4a-translate -k 0 -f text -m t-02-addendums/Titles.asciidoc -p t-02-addendums/Titles.po -l tmp/Titles.trans '
      . '-a ?/does/not/exist',
    'test' => 'diff -u t-02-addendums/Titles.asciidoc tmp/Titles.trans 1>&2',
    'doc'  => 'translate with non-existing ?addendum'
  },
  {
    'run' =>
'perl ../po4a-translate -k 0 -f text -m t-02-addendums/Titles.asciidoc -p t-02-addendums/Titles.po -l tmp/Titles.trans '
      . '-a @t-02-addendums/addendum123.list2',
    'test' => 'diff -u t-02-addendums/Titles.trans.add1 tmp/Titles.trans 1>&2',
    'doc'  => 'translate with recursive @addendum'
  },
  {
    'run' => 'perl ../po4a -f t-02-addendums/test0.conf',
    'test' =>
      'diff -u t-02-addendums/Titles.trans.add123 tmp/Titles.trans 1>&2',
    'doc' => '(po4a) translate with addendum1, 2 and 3'
  },
  {
    'run' => 'perl ../po4a -f t-02-addendums/test1.conf',
    'test' =>
      'diff -u t-02-addendums/Titles.trans.add123 tmp/Titles.trans 1>&2',
    'doc' => '(po4a) translate with @addendum'
  },
  {
    'run'  => 'perl ../po4a -f t-02-addendums/test2.conf',
    'test' => 'diff -u t-02-addendums/Titles.trans.add13 tmp/Titles.trans 1>&2',
    'doc'  => '(po4a) translate with !addendum'
  },
  {
    'run'  => 'perl ../po4a -f t-02-addendums/test3.conf',
    'test' => 'diff -u t-02-addendums/Titles.asciidoc tmp/Titles.trans 1>&2',
    'doc'  => '(po4a) translate with non-existing ?addendum'
  },
  {
    'run'  => 'perl ../po4a -f t-02-addendums/test4.conf',
    'test' => 'diff -u t-02-addendums/Titles.trans.add1 tmp/Titles.trans 1>&2',
    'doc'  => '(po4a) translate with recursive @addendum'
  };

run_all_tests(@tests);
0;
