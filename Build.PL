#!/usr/bin/perl

use Module::Build;
use strict;
use warnings;

my $builder = Module::Build->subclass
(
    class => 'My::Builder',
    code => q{
	sub ACTION_build {
	    my $self = shift;
	    $self->depends_on('code');
	    $self->depends_on('docs');
	    $self->depends_on('distmeta'); # regenerate META.yml
	    $self->depends_on('postats');
	}
	sub ACTION_install {
	    my $self = shift;

	    require ExtUtils::Install;
#	    $self->depends_on('build');

	    my %install_map = %{$self->install_map};

	    my $mandir = $self->install_map->{'blib/bindoc'};
	    $mandir =~ s/\/man1$//;
	    $install_map{'blib/man'} = $mandir;
	    system("mkdir -p blib/man/man7") and die;
	    system("mkdir -p blib/man/man1") and die;

	    ExtUtils::Install::install(\%install_map, 1, 0, $self->{args}{uninst}||0); 
	    system ("cp -R _build/po4a/man/* $mandir");
	    system ("find . -name '*.1p' -delete");
	    system ("find . -name '*.3pm' -delete");
	}

	sub ACTION_dist {
	    my ($self) = @_;

	    $self->depends_on('test');
	    $self->depends_on('distdir');

	    my $dist_dir = $self->dist_dir;

	    if ( -e "$dist_dir.tar.gz") {
		# Delete the distfile if it already exists
		system ("rm $dist_dir.tar.gz") && die;
	    }

	    $self->make_tarball($dist_dir);
	    $self->delete_filetree($dist_dir);
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
      requires => {},
      recommends => {'Text::WrapI18N' => 0, # Only used for wrapping long
                                            # error/wraning lines.

                     'Term::ReadKey' => 0,  # Needed to detect terminal
                                            # width. Not needed if you
                                            # don't have Text::WrapI18N.

                     'SGMLS' => 0,          # Needed for the Sgml module.

                     'Locale::gettext' => '1.01', # Only used for
                                                  # translating the
                                                  # po4a's messages.
                    },
      script_files => ['po4a-gettextize', 'po4a-updatepo',
	  'po4a-translate', 'po4a-normalize', 'po4a', 'scripts/msguntypot',
	  'scripts/po4aman-display-po', 'scripts/po4apod-display-po',
	  'share/po4a-build'],
      add_to_cleanup => ['t/tmp','messages.mo', 'blib',
	  'po/pod/po4a-pod.pot~', 'po4a.log', 'po/bin/*.gmo'],
      dist_abstract => 'Tools for helping translation of documentation',
      dist_author => ['Martin Quinson (mquinson#debian.org)',
	  'Denis Barbier <barbier@linuxfr.org>',
	  'Neil Williams <linux@codehelp.co.uk>']
  );

$b->create_build_script;

