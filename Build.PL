#!/usr/bin/perl

use Module::Build;

my $builder = Module::Build->subclass
(
	class => 'My::Builder',
	code => q{
		sub ACTION_build {
			my $self = shift;
			$self->depends_on('code');
			$self->depends_on('docs');
			$self->depends_on('test');
			$self->depends_on('distmeta');
			$self->depends_on('po');
			$self->depends_on('man');
		}
		sub ACTION_po {
			my $self = shift;

			#update pot
			my @files = (keys(%{$self->script_files()}), @{$self->rscan_dir('lib',qr{\.pm$})});
			if (!$self->up_to_date(\@files, "po/bin/po4a.pot")) {
				my $podfiles = "../../".join(" ../../",@files);
				$self->do_system("cd po/bin; xgettext -L Perl $podfiles -o po4a.pot.new") || die;
				if ($self->do_system("[ -e po/bin/po4a.pot ]")) {
					$diff = `diff -q -I'#:' -I'POT-Creation-Date:' -I'PO-Revision-Date:' po/bin/po4a.pot po/bin/po4a.pot.new 2> /dev/null`;
					if ( $diff eq "" ) {
						`rm -f po/bin/po4a.pot.new; touch po/bin/po4a.pot`;
					} else {
						`mv -f po/bin/po4a.pot.new po/bin/po4a.pot`;
					}
				} else {
					`mv -f po/bin/po4a.pot.new po/bin/po4a.pot`;
				}
			}

			#update languages
			@files = @{$self->rscan_dir('po/bin',qr{\.po$})};
			foreach (@files) {
				$_ =~ /.*\/(.*)\.po$/;
				my $lang = $1;

				if (!$self->up_to_date("po/bin/po4a.pot","po/bin/$lang.po")) {
					$self->do_system("msgmerge po/bin/$lang.po po/bin/po4a.pot -o po/bin/$lang.po.new");
				}
				# Typically all that changes was a date. I'd
				# prefer not to cvs commit such changes, so
				# detect and ignore them.
				$diff = `diff -q -I'#:' -I'POT-Creation-Date:' -I'PO-Revision-Date:' po/bin/$lang.po po/bin/$lang.po.new 2> /dev/null`;
				if ( $diff eq "" ) {
					`rm -f po/bin/$lang.po.new;`;
				} else {
					`mv -f po/bin/$lang.po.new po/bin/$lang.po`;
					`msgfmt --statistics po/bin/$lang.po`;
				}
				if (!$self->up_to_date("po/bin/$lang.po","blib/po/$lang/LC_MESSAGES/po4a.mo")) {
					`mkdir -p blib/po/$lang/LC_MESSAGES`;
					$self->do_system("msgfmt -o blib/po/$lang/LC_MESSAGES/po4a.mo po/bin/$lang.po");
				}
			}
		}
		sub ACTION_manpo {
			my $self = shift;

			#update pot
			my @files = (keys(%{$self->script_files()}), @{$self->rscan_dir('lib',qr{\.pm$})}, @{$self->rscan_dir('doc',qr{\.pod$})});
			if (!$self->up_to_date(\@files, "po/pod/po4a-pod.pot")) {
				my $podfiles = "-m ../../".join(" -m ../../",@files);
				$self->do_system("cd po/pod; PERL5LIB=../../lib perl ../../po4a-updatepo -f pod $podfiles -p po4a-pod.pot") || die;
			}

			#update languages
			@files = @{$self->rscan_dir('po/pod',qr{\.po$})};
			foreach (@files) {
				$_ =~ /.*\/(.*)\.po$/;
				my $lang = $1;

				if (!$self->up_to_date("po/pod/po4a-pod.pot","po/pod/$lang.po")) {
					$self->do_system("msgmerge po/pod/$lang.po po/pod/po4a-pod.pot -o po/pod/$lang.po.new");
				}
				# Typically all that changes was a date. I'd
				# prefer not to cvs commit such changes, so
				# detect and ignore them.
				$diff = `diff -q -I'#:' -I'POT-Creation-Date:' -I'PO-Revision-Date:' po/pod/$lang.po po/pod/$lang.po.new 2> /dev/null`;
				if ( $diff eq "" ) {
					`rm -f po/pod/$lang.po.new;`;
				} else {
					`mv -f po/pod/$lang.po.new po/pod/$lang.po`;
					`msgfmt --statistics po/pod/$lang.po`;
				}
			}
		}
		sub ACTION_man {
			my $self = shift;

			$self->depends_on('manpo');
			use Pod::Man;

			#get the languages
			my @langs = @{$self->rscan_dir('po/pod',qr{\.po$})};
			my $i=0;
			while ($i < @langs) {
				$langs[$i] =~ /.*\/(.*)\.po$/;
				$langs[$i] = $1;
				$i++;
			}

			`rm -rf blib/man`;
			`mkdir -p blib/man`;

			#Translate binaries manpages
			my $parser = Pod::Man->new (release => "Po4a Tools",
				center => "Po4a Tools", section => 1);

			foreach $file (keys(%{$self->script_files()})) {
				foreach $lang (@langs) {
					`PERL5LIB=lib perl po4a-translate -f pod -v -m $file -p po/pod/$lang.po -l blib/man/$file`;
					if ($self->do_system("[ -e blib/man/$file ]")) {
						`mkdir -p blib/man/$lang/man1`;
						$parser->parse_from_file ("blib/man/$file", "blib/man/$lang/man1/$file.1");
						`gzip -9 blib/man/$lang/man1/$file.1`;
						`rm -f blib/man/$file`;
					}
				}
			}

			#Translate modules manpages
			$parser = Pod::Man->new (release => "Po4a Tools",
				center => "Po4a Tools", section => 3);

			foreach $file (@{$self->rscan_dir('lib',qr{\.pm$})}) {
				$file =~ /.*\/(.*)\.pm$/;
				my $filename = $1;
				foreach $lang (@langs) {
					`PERL5LIB=lib perl po4a-translate -f pod -v -m $file -p po/pod/$lang.po -l blib/man/$filename`;
					if ($self->do_system("[ -e blib/man/$filename ]")) {
						`mkdir -p blib/man/$lang/man3`;
						$parser->parse_from_file ("blib/man/$filename", "blib/man/$lang/man3/Locale::Po4a::$filename.3pm");
						`gzip -9 blib/man/$lang/man3/Locale::Po4a::$filename.3pm`;
						`rm -f blib/man/$filename`;
					}
				}
			}

			#Translate docs manpages
			$parser = Pod::Man->new (release => "Po4a Tools",
				center => "Po4a Tools", section => 7);

			foreach $file (@{$self->rscan_dir('doc',qr{\.pod$})}) {
				$file =~ /.*\/(.*)\.pod$/;
				my $filename = $1;
				`mkdir -p blib/man/man7`;
				$parser->parse_from_file ($file, "blib/man/man7/$filename");
				`gzip -9 -f blib/man/man7/$filename`;
				foreach $lang (@langs) {
					`PERL5LIB=lib perl po4a-translate -f pod -v -m $file -p po/pod/$lang.po -l blib/man/$filename`;
					if ($self->do_system("[ -e blib/man/$filename ]")) {
						`mkdir -p blib/man/$lang/man7`;
						$parser->parse_from_file ("blib/man/$filename", "blib/man/$lang/man7/$filename");
						`gzip -9 blib/man/$lang/man7/$filename`;
						`rm -f blib/man/$filename`;
					}
				}
			}
		}
		sub ACTION_install {
			my $self = shift;

			require ExtUtils::Install;
			$self->depends_on('build');
			`gzip -9 -f blib/bindoc/*.1`;
			`gzip -9 -f blib/libdoc/*.3pm`;

			ExtUtils::Install::install($self->install_map, 1, 0, $self->{args}{uninst}||0); 
		}
		sub ACTION_postats {
			my $self = shift;
			$self->postats("po/bin");
			$self->postats("po/pod");
		}
		sub postats {
			my ($self,$dir) = (shift,shift);
			my $potsize = `(cd $dir;ls -sh *.pot) | sed -n -e 's/^ *\\\\([^[:blank:]]*\\\\).*\$/\\\\1/p'`;
			$potsize =~ /(.*)/;
			print "$dir (pot: $1)\n";
			my @files = @{$self->rscan_dir($dir,qr{\.po$})};
			foreach (@files) {
				$file = $_;
				$file =~ /.*\/(.*)\.po$/;
				my $lang = $1;
				my $stat = `msgfmt -o /dev/null -c -v --statistics $file 2>&1`;
				print "  $lang: $stat";
			}
		}
	},
);

my $b = $builder->new
	( module_name => 'po4a',
	license => 'gpl',
	dist_version_from => 'lib/Locale/Po4a/TransTractor.pm', # finds $VERSION
	requires => {Locale::gettext => '1.01',
		SGMLS => 0},
	script_files => ['po4a-gettextize', 'po4a-updatepo',
		'po4a-translate', 'po4a-normalize', 'po4a'],
	add_to_cleanup => ['t/tmp','messages.mo',
		'po/pod/po4a-pod.pot~'],
	install_path => {po => '/usr/share/locale',
		man => '/usr/share/man'},
	dist_abstract => 'Tools for helping translation of documentation',
	dist_author => ['Martin Quinson <martin.quinson@tuxfamily.org>',
		'Denis Barbier <barbier@linuxfr.org>']
	)->create_build_script;
