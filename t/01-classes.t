# Class tester. Tries to load all module to check their syntax

#########################

use Test::Simple tests =>7;

use Locale::Po4a::Po;           ok(1, 'Po.pm loadable');
use Locale::Po4a::TransTractor; ok(1, 'TransTractor.pm loadable');

use Locale::Po4a::KernelHelp;   ok(1, 'KernelHelp.pm loadable');
use Locale::Po4a::Man;          ok(1, 'Man.pm loadable');
use Locale::Po4a::Pod;          ok(1, 'Pod.pm loadable');
use Locale::Po4a::Sgml;         ok(1, 'Sgml.pm loadable');

use Locale::Po4a::Chooser;      ok(1, 'Chooser.pm loadable');

