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
	    $self->depends_on('man');
	    $self->depends_on('postats');
	}
	sub ACTION_install {
	    my $self = shift;
	    
	    require ExtUtils::Install;
#	    $self->depends_on('build');
	    
	    ExtUtils::Install::install($self->install_map, 1, 0, $self->{args}{uninst}||0); 
	}
	sub ACTION_binpo {
	    my $self = shift;
	    
	    my @files = sort((keys(%{$self->script_files()}), @{$self->rscan_dir('lib',qr{\.pm$})}));
	    
	    unless ($self->up_to_date(\@files, "po/bin/po4a.pot")) {
		print "XX Update po/bin/po4a.pot\n";
		my $podfiles = join ("", map {" ../../".$_ } @files);
		system("cd po/bin; xgettext -L Perl $podfiles -o po4a.pot.new") && die;
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
		    system("msgmerge po/bin/$lang.po po/bin/po4a.pot -o po/bin/$lang.po.new") && die;
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
	    
	    # update pot
	    my @files = sort((keys(%{$self->script_files()}), @{$self->rscan_dir('lib',qr{\.pm$})}, @{$self->rscan_dir('doc',qr{\.pod$})}));
	    unless ($self->up_to_date(\@files, "po/pod/po4a-pod.pot")) {
		my $podfiles = join ("", map {" -m ../../".$_ } @files);
		print "XX Update documentation pot files: ";
		system("cd po/pod; PERL5LIB=../../lib perl ../../po4a-updatepo -f pod $podfiles -M iso8859-1 -p po4a-pod.pot") 
		  && die;
		my ($atime, $mtime) = (time,time);
		utime $atime, $mtime, "po/pod/po4a-pod.pot";
		
	    } else {
		print "XX Documentation pot file uptodate.\n";
	    }
	    
	    # update languages
	    @files = @{$self->rscan_dir('po/pod',qr{\.po$})};
	    foreach (@files) {
		$_ =~ /.*\/(.*)\.po$/;
		my $lang = $1;
		
		unless ($self->up_to_date("po/pod/po4a-pod.pot","po/pod/$lang.po")) {
		    print "XX Update documentation $lang.po: ";
		    
		    system("msgmerge po/pod/$lang.po po/pod/po4a-pod.pot -o po/pod/$lang.po.new")
		      && die;

		    # Typically all that changes was a date. I'd
		    # prefer not to cvs commit such changes, so
		    # detect and ignore them.
		    $diff = qx(diff -q -I'#:' -I'POT-Creation-Date:' -I'PO-Revision-Date:' po/pod/$lang.po po/pod/$lang.po.new);
		    if ( $diff eq "" ) {
			unlink "po/pod/$lang.po.new" || die;
			my ($atime, $mtime) = (time,time);
			utime $atime, $mtime, "po/pod/$lang.po";
		    } else {
			rename "po/pod/$lang.po.new", "po/pod/$lang.po" || die;
		    }		    
		} else {
		    print "XX Documentation $lang.po uptodate.\n";
		}
	    }
	}
	sub ACTION_man {
	    my $self = shift;
	    
	    $self->depends_on('manpo');
	    use Pod::Man;

	    my $options = "-v -f pod -M iso8859-1 -L iso8859-1";
	    
	    #get the languages
	    my @langs = @{$self->rscan_dir('po/pod',qr{\.po$})};
	    my $i=0;
	    while ($i < @langs) {
		$langs[$i] =~ /.*\/(.*)\.po$/;
		$langs[$i] = $1;
		$i++;
	    }
	    
	    system("rm -rf blib/man") && die;
	    system("mkdir -p blib/man") && die;
	    
	    # Translate binaries manpages
	    my $parser = Pod::Man->new (release => "Po4a Tools",
		center => "Po4a Tools", section => "1p");
	    
	    foreach $lang (@langs) {
		print ("X Translate binary manpages to $lang\n");
		foreach $file (keys(%{$self->script_files()})) {
		    system("PERL5LIB=lib perl po4a-translate $options -m $file -p po/pod/$lang.po -l blib/man/$file -a doc/addendum.$lang")
		      && die;
		    if (-e "blib/man/$file") {
			system("mkdir -p blib/man/$lang/man1") && die;
			$parser->parse_from_file ("blib/man/$file", "blib/man/$lang/man1/$file.1p");
			system("gzip -9 blib/man/$lang/man1/$file.1p") && die;
			system("rm -f blib/man/$file")&& die;
		    }
		}
	    }
	    
	    # Translate modules manpages
	    $parser = Pod::Man->new (release => "Po4a Tools",
		center => "Po4a Tools", section => "3pm");
	    
	    foreach $lang (@langs) {
		print ("X Translate module manpages to $lang\n");
		foreach $file (@{$self->rscan_dir('lib',qr{\.pm$})}) {
		    $file =~ /.*\/(.*)\.pm$/;
		    my $filename = $1;
		    system("PERL5LIB=lib perl po4a-translate $options -m $file -p po/pod/$lang.po -l blib/man/$filename -a doc/addendum.$lang")
		      && die;
		    if (-e "blib/man/$filename") {
			system ("mkdir -p blib/man/$lang/man3") && die;
			$parser->parse_from_file ("blib/man/$filename", 
			    "blib/man/$lang/man3/Locale::Po4a::$filename.3pm") || die;
			system ("gzip -9 blib/man/$lang/man3/Locale::Po4a::$filename.3pm") 
			  && die "Cannot gzip blib/man/$lang/man3/Locale::Po4a::$filename.3pm";
			system ("rm -f blib/man/$filename") && die;
		    }
		}
	    }
	    
	    # Translate docs manpages
	    $parser = Pod::Man->new (release => "Po4a Tools",
		center => "Po4a Tools", section => 7);
	    
	    foreach $file (@{$self->rscan_dir('doc',qr{\.pod$})}) {
		$file =~ /.*\/(.*)\.pod$/;
		my $filename = $1;
		print "X Generate the man version of $file\n";
		system("mkdir -p blib/man/man7") && die;
		$parser->parse_from_file ($file, "blib/man/man7/$filename");
		system ("gzip -9 -f blib/man/man7/$filename") && die;
		foreach $lang (@langs) {
		    print "X Translate $file to $lang\n";
		    system ("PERL5LIB=lib perl po4a-translate $options -m $file -p po/pod/$lang.po -l blib/man/$filename -a doc/addendum.$lang")
		      && die;
		    if (-e "blib/man/$filename") {
			`mkdir -p blib/man/$lang/man7`;
			$parser->parse_from_file ("blib/man/$filename", "blib/man/$lang/man7/$filename");
			`gzip -9 blib/man/$lang/man7/$filename`;
			`rm -f blib/man/$filename`;
		    }
		}
	    }
	}
	sub ACTION_dist {
	    my ($self) = @_;

	    $self->depends_on('test');
	    $self->depends_on('distdir');

	    my $dist_dir = $self->dist_dir;

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
      requires => {'Locale::gettext' => '1.01',
	  'SGMLS' => 0},
      script_files => ['po4a-gettextize', 'po4a-updatepo',
	  'po4a-translate', 'po4a-normalize', 'po4a'],
      add_to_cleanup => ['t/tmp','messages.mo', 'blib', 'html',
	  'po/pod/po4a-pod.pot~', 'po4a.log'],
      install_path => {po => '/usr/share/locale',
	  man => '/usr/share/man'},
      dist_abstract => 'Tools for helping translation of documentation',
      dist_author => ['Martin Quinson <martin.quinson@tuxfamily.org>',
	  'Denis Barbier <barbier@linuxfr.org>']
  )->create_build_script;
