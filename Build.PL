#!/usr/bin/perl

use lib q('.');
use Po4aBuilder;

my $build = Po4aBuilder->new
  ( module_name => 'po4a',
      license => 'gpl',
      dist_version_from => 'lib/Locale/Po4a/TransTractor.pm', # finds $VERSION
      requires => {},
      recommends => {'Text::WrapI18N' => 0, # Only used for wrapping long
                                            # error/wraning lines.

                     'Term::ReadKey' => 0,  # Needed to detect terminal
                                            # width. Not needed if you
                                            # don't have Text::WrapI18N.

                     'SGMLS' => 0,          # Needed for the Sgml module.

                     'Unicode::GCString' => 0, # Used by the Text module (asciidoc)

                     'Locale::gettext' => '1.01', # Only used for
                                                  # translating the
                                                  # po4a's messages.
                    },
      script_files => ['po4a-gettextize', 'po4a-updatepo',
	  'po4a-translate', 'po4a-normalize', 'po4a', 'scripts/msguntypot',
	  'scripts/po4aman-display-po', 'scripts/po4apod-display-po',
	  'share/po4a-build'],
      add_to_cleanup => ['t/tmp','po/bin/*.gmo', 'blib', '_build'],
      dist_abstract => 'Tools for helping translation of documentation',
      dist_author => ['Martin Quinson (mquinson#debian.org)',
	  'Denis Barbier <barbier@linuxfr.org>',
	  'Nicolas Francois <nicolas.francois@centraliens.net>',
	  'Neil Williams <linux@codehelp.co.uk>']
  );

$build->create_build_script;
