# Class tester. Tries to load all module to check their syntax

#########################

use Test::More tests =>8;

eval qq{use Locale::Po4a::Po};           ok(!$@, 'Po.pm loadable');
diag($@) if $@;
eval qq{use Locale::Po4a::TransTractor}; ok(!$@, 'TransTractor.pm loadable');
diag($@) if $@;

eval qq{use Locale::Po4a::KernelHelp};   ok(!$@, 'KernelHelp.pm loadable');
diag($@) if $@;
eval qq{use Locale::Po4a::Man};          ok(!$@, 'Man.pm loadable');
diag($@) if $@;
eval qq{use Locale::Po4a::Pod};          ok(!$@, 'Pod.pm loadable');
diag($@) if $@;
eval qq{use Locale::Po4a::Sgml};         ok(!$@, 'Sgml.pm loadable');
diag($@) if $@;

eval qq{use Locale::Po4a::Dia};          ok(!$@, 'Dia.pm loadable');
diag($@) if $@;
eval qq{use Locale::Po4a::Chooser};      ok(!$@, 'Chooser.pm loadable');
diag($@) if $@;

