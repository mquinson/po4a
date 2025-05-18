# Build.PL -- script in charge of building the po4a distribution when releasing
#
# This program is free software; you may redistribute it and/or modify it
# under the terms of GPL v2.0 or later (see COPYING).

#!/usr/bin/perl

use lib q(.);
use Po4aBuilder;

my $build = Po4aBuilder->new(
    module_name       => 'po4a',
    license           => 'gpl',
    dist_version_from => 'lib/Locale/Po4a/TransTractor.pm',    # finds $VERSION

    configure_requires => { 'Module::Build' => 0.42 },
    build_requires     => {
        'IPC::Open3' => 0,
        'Pod::Man'   => 0,
    },
    recommends => {
        'Pod::Parser' => 0,                                    # Used by KernelHelp and Pod modules.
        'Pod::Simple' => 0,                                    # Used by SimplePod module.

        'Text::WrapI18N' => 0,                                 # Only used for wrapping long
                                                               # error/wraning lines.

        'Term::ReadKey' => 0,                                  # Needed to detect terminal
                                                               # width. Not needed if you
                                                               # don't have Text::WrapI18N.

        'SGMLS' => 0,                                          # Needed for the Sgml module.

        'Unicode::GCString' => 0,                              # Used by the AsciiDoc and VimHelp modules

        'Locale::gettext' => '1.01',                           # Only used for
                                                               # translating the
                                                               # po4a's messages.
        'YAML::Tiny'      => 0,                                # Used by the Yaml module
    },
    test_requires => {
        'SGMLS'             => 0,                              # Needed for the Sgml module.
        'Unicode::GCString' => 0,                              # Used by the Text module (asciidoc)
    },
    script_files => [
        'po4a-gettextize',          'po4a-updatepo',
        'po4a-translate',           'po4a-normalize',
        'po4a',                     'msguntypot',
        'scripts/po4a-display-man', 'scripts/po4a-display-pod'
    ],
    add_to_cleanup => [ 't/tmp', 'po/bin/*.gmo', 'blib', '_build' ],
    dist_abstract  => 'Maintain the translations of your documentation with ease (PO for anything)',
    dist_author    => [
        'Martin Quinson (mquinson#debian.org)',
        'Denis Barbier <barbier@linuxfr.org>',
        'Nicolas François <nicolas.francois@centraliens.net>',
        'Neil Williams <linux@codehelp.co.uk>'
    ]
);

$build->create_build_script;
