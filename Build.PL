use Module::Build;

Module::Build->new
	( module_name => 'po4a',
	license => 'gpl',
	dist_version_from => 'lib/Locale/Po4a/TransTractor.pm', # finds $VERSION
	requires => {Locale::gettext => '1.01',
		SGMLS => 0},
	script_files => ['po4a-gettextize', 'po4a-updatepo',
		'po4a-translate', 'po4a-normalize', 'po4a'],
	add_to_cleanup => ['t/tmp'],
	dist_abstract => 'Tools for helping translation of documentation',
	dist_author => ['Martin Quinson <martin.quinson@tuxfamily.org>',
		'Denis Barbier <barbier@linuxfr.org>']
	)->create_build_script;
