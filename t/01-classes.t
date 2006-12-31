# Class tester. Tries to load all module to check their syntax

#########################

use Test::More tests =>14;

# Core modules
eval qq{use Locale::Po4a::Po};           ok(!$@, 'Po.pm loadable');
diag($@) if $@;
eval qq{use Locale::Po4a::TransTractor}; ok(!$@, 'TransTractor.pm loadable');
diag($@) if $@;
eval qq{use Locale::Po4a::Chooser};      ok(!$@, 'Chooser.pm loadable');
diag($@) if $@;
eval qq{use Locale::Po4a::Common};       ok(!$@, 'Common.pm loadable');
diag($@) if $@;

# File format modules
eval qq{use Locale::Po4a::KernelHelp};   ok(!$@, 'KernelHelp.pm loadable');
diag($@) if $@;
eval qq{use Locale::Po4a::Man};          ok(!$@, 'Man.pm loadable');
diag($@) if $@;
eval qq{use Locale::Po4a::Pod};          ok(!$@, 'Pod.pm loadable');
diag($@) if $@;
SKIP: {
    skip "SGMLS required for this test", 1
        unless eval 'require SGMLS';
    eval qq{use Locale::Po4a::Sgml};         ok(!$@, 'Sgml.pm loadable');
    diag($@) if $@;
}
eval qq{use Locale::Po4a::Xml};          ok(!$@, 'Xml.pm loadable');
diag($@) if $@;
eval qq{use Locale::Po4a::Dia};          ok(!$@, 'Dia.pm loadable');
diag($@) if $@;
eval qq{use Locale::Po4a::Guide};        ok(!$@, 'Guide.pm loadable');
diag($@) if $@;
eval qq{use Locale::Po4a::Docbook};      ok(!$@, 'Docbook.pm loadable');
diag($@) if $@;
eval qq{use Locale::Po4a::TeX};          ok(!$@, 'TeX.pm loadable');
diag($@) if $@;
eval qq{use Locale::Po4a::LaTeX};        ok(!$@, 'LaTeX.pm loadable');
diag($@) if $@;

