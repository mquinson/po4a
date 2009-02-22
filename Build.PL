#!/usr/bin/perl

use Module::Build;
use strict;
use warnings;

use Encode;

my $builder = Module::Build->subclass
(
    class => 'My::Builder',
    code => q{
	sub ACTION_build {
	    my $self = shift;
	    $self->depends_on('code');
	    $self->depends_on('docs');
	    $self->depends_on('distmeta'); # regenerate META.yml
	    $self->depends_on('man');
	    $self->depends_on('postats');
	}
	sub perl_scripts {
	    return ('po4a-gettextize', 'po4a-updatepo', 'po4a-translate',
	            'po4a-normalize', 'po4a', 'scripts/msguntypot');
	}
	sub ACTION_install {
	    my $self = shift;

	    require ExtUtils::Install;
#	    $self->depends_on('build');

	    my %install_map = %{$self->install_map};

	    my $mandir = $self->install_map->{'blib/bindoc'};
	    $mandir =~ s/\/man1$//;
	    $install_map{'blib/man'} = $mandir;

	    my $localedir = $mandir;
	    $localedir =~ s/\/man$/\/locale/;
	    $install_map{'blib/po'} = $localedir;

	    ExtUtils::Install::install(\%install_map, 1, 0, $self->{args}{uninst}||0); 
	}
	sub ACTION_binpo {
	    my $self = shift;

	    my @files = sort((perl_scripts(), @{$self->rscan_dir('lib',qr{\.pm$})}));

	    unless ($self->up_to_date(\@files, "po/bin/po4a.pot")) {
		print "XX Update po/bin/po4a.pot\n";
		my $podfiles = join ("", map {" ../../".$_ } @files);
		my $cmd = "cd po/bin; xgettext ";
		$cmd .= "--from-code=utf-8 ";
		$cmd .= "-L Perl ";
		$cmd .= "--msgid-bugs-address po4a-devel\@lists.alioth.debian.org ";
		$cmd .= "--package-name po4a ";
		$cmd .= "--package-version ".$self->dist_version()." ";
		$cmd .= "$podfiles ";
		$cmd .= "-o po4a.pot.new";
		system($cmd) && die;
		if ( -e "po/bin/po4a.pot") {
		    $diff = qx(diff -q -I'#:' -I'POT-Creation-Date:' -I'PO-Revision-Date:' po/bin/po4a.pot po/bin/po4a.pot.new);
		    if ( $diff eq "" ) {
			unlink "po/bin/po4a.pot.new" || die;
			# touch it
			my ($atime, $mtime) = (time,time);
			utime $atime, $mtime, "po/bin/po4a.pot";
		    } else {
			rename "po/bin/po4a.pot.new", "po/bin/po4a.pot" || die;
		    }
		} else {
		    rename "po/bin/po4a.pot.new", "po/bin/po4a.pot" || die;
		}
	    } else {
		print "XX po/bin/po4a.pot uptodate.\n";
	    }

	    # update languages
	    @files = @{$self->rscan_dir('po/bin',qr{\.po$})};
	    foreach (@files) {
		next if m|/.#|;
		$_ =~ /.*\/(.*)\.po$/;
		my $lang = $1;

		unless ($self->up_to_date("po/bin/po4a.pot","po/bin/$lang.po")) {
		    print "XX Sync po/bin/$lang.po: ";
		    system("msgmerge --previous po/bin/$lang.po po/bin/po4a.pot -o po/bin/$lang.po.new") && die;
		    # Typically all that changes was a date. I'd
		    # prefer not to cvs commit such changes, so
		    # detect and ignore them.
		    $diff = qx(diff -q -I'#:' -I'POT-Creation-Date:' -I'PO-Revision-Date:' po/bin/$lang.po po/bin/$lang.po.new);
		    if ($diff eq "") {
			unlink "po/bin/$lang.po.new" || die;
			# touch it
			my ($atime, $mtime) = (time,time);
			utime $atime, $mtime, "po/bin/$lang.po";
		    } else {
			rename "po/bin/$lang.po.new", "po/bin/$lang.po" || die;
		    }
		} else {
		    print "XX po/bin/$lang.po uptodate.\n";
		}
		unless ($self->up_to_date("po/bin/$lang.po","blib/po/$lang/LC_MESSAGES/po4a.mo")) {
		    system("mkdir -p blib/po/$lang/LC_MESSAGES") && die;
		    system("msgfmt -o blib/po/$lang/LC_MESSAGES/po4a.mo po/bin/$lang.po") && die;
		} 
	    }

	}
	sub ACTION_manpo {
	    my $self = shift;

	    my $cmd = "PERL5LIB=lib perl po4a "; # Use this version of po4a
	    $cmd .= "--previous ";
	    $cmd .= "--no-translations ";
	    $cmd .= "--msgid-bugs-address po4a-devel\@lists.alioth.debian.org ";
	    $cmd .= "--package-name po4a ";
	    $cmd .= "--package-version ".$self->dist_version()." ";
	    $cmd .= "po/pod.cfg";
	    system($cmd)
		and die;
	}
	sub ACTION_man {
	    my $self = shift;

	    use Pod::Man;

	    # Translate binaries manpages
	    my %options;
	    $options{utf8} = 1;
	    my $parser = Pod::Man->new (%options);

	    system("PERL5LIB=lib perl po4a --previous po/pod.cfg") and die;
	    system("mkdir -p blib/man/man7") and die;
	    system("mkdir -p blib/man/man1") and die;
	    system("cp doc/po4a.7.pod blib/man/man7") and die;

	    foreach $file (@{$self->rscan_dir('blib/man',qr{\.pod$})}) {
		next if $file =~ m/^man7/;
		my $out = $file;
		$out =~ s/\.pod$//;
		$section = $2;
		$parser->{name} = $out;
		$parser->{name} =~ s/^.*\///;
		$parser->{name} =~ s/^(.*).(1p|3pm|7)/$1/;
		$parser->{section} = $2;
		if ($parser->{section} ne "3pm") {
		    $parser->{name} = uc $parser->{name};
		}

		my $lang = $out;
		$lang =~ s/^blib\/man\/([^\/]*)\/.*$/$1/;

		if ($lang eq "man7") {
			$parser->{release} = $parser->{center} = "Po4a Tools";
		} else {
			my $command;
			$command = "msggrep -K -E -e \"Po4a Tools\" po/pod/$lang.po |";
			$command .= "msgconv -t UTF-8 | ";
			$command .= "msgexec /bin/sh -c '[ -n \"\$MSGEXEC_MSGID\" ] ";
			$command .= "&& cat || cat > /dev/null'";

			my $title = `$command 2> /dev/null`;
			$title = "Po4a Tools" unless length $title;
			$title = Encode::decode_utf8($title);
			$parser->{release} = $parser->{center} = $title;
		}
		$parser->parse_from_file ($file, $out);

		system("gzip -9 -f $out") and die;
		system("rm -f $file") and die;
	    }

	    # Install the manpages of the Shell scripts
	    system ("cp scripts/po4aman-display-po.1 blib/man/man1/") and die;
	    foreach $file (@{$self->rscan_dir('blib/man',qr{\.1$})}) {
		system ("gzip -9 -f $file") and die;
	    }
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
	    $self->depends_on('binpo');
	    $self->depends_on('manpo');
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
	  'scripts/po4aman-display-po'],
      add_to_cleanup => ['t/tmp','messages.mo', 'blib',
	  'po/pod/po4a-pod.pot~', 'po4a.log'],
      dist_abstract => 'Tools for helping translation of documentation',
      dist_author => ['Martin Quinson (mquinson#debian.org)',
	  'Denis Barbier <barbier@linuxfr.org>']
  );

$b->create_build_script;

