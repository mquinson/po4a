# Class tester.
# Tries to load all modules to check their syntax.

#########################

use strict;
use warnings;
use Test::More tests => 24;

note "Core modules";

use_ok "Locale::Po4a::Chooser";
use_ok "Locale::Po4a::Common";
use_ok "Locale::Po4a::Po";
use_ok "Locale::Po4a::TransTractor";

note "File format modules";

use_ok "Locale::Po4a::AsciiDoc";
use_ok "Locale::Po4a::BibTeX";
use_ok "Locale::Po4a::Dia";
use_ok "Locale::Po4a::Docbook";
use_ok "Locale::Po4a::Guide";
use_ok "Locale::Po4a::Halibut";
use_ok "Locale::Po4a::Ini";
use_ok "Locale::Po4a::KernelHelp";
use_ok "Locale::Po4a::LaTeX";
use_ok "Locale::Po4a::Man";
use_ok "Locale::Po4a::Pod";
use_ok "Locale::Po4a::RubyDoc";
use_ok "Locale::Po4a::Sgml";
use_ok "Locale::Po4a::TeX";
use_ok "Locale::Po4a::Texinfo";
use_ok "Locale::Po4a::Text";
use_ok "Locale::Po4a::Wml";
use_ok "Locale::Po4a::Xhtml";
use_ok "Locale::Po4a::Xml";
use_ok "Locale::Po4a::Yaml";
