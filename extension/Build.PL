#!/usr/bin/perl

use Module::Build;
use strict;
use warnings;

#my $builder = Module::Build->subclass
#(
#    code => q{
#        sub ACTION_test {
#            system("cd .. && PERL5LIB=\$(pwd)/extension/blib/arch:\$(pwd)/lib ./Build test verbose=1");
#        }
#    },
#);

#$builder->new
my $builder = Module::Build->new
  (
    module_name       => 'po4ac',
    dist_version_from => '../lib/Locale/Po4a/TransTractor.pm', # finds $VERSION
    license           => 'gpl',
    dist_abstract     => 'Tools for helping translation of documentation',
    dist_author       => ['Nicolas François <nicolas.francois@centraliens.net'],
#    test_files        => '../t',
    extra_linker_flags => '-lgettextpo -lgettextsrc'
  )->create_build_script;
