package Po4aBuilder;

use Module::Build;
use File::Basename;
use File::Path qw(mkpath rmtree);
use File::Spec;
use File::Copy qw(copy);
use File::stat;

@ISA = qw(Module::Build);

sub ACTION_build {
    my $self = shift;
    $self->depends_on('code');
    $self->depends_on('docs');
    $self->depends_on('distmeta'); # regenerate META.yml
    $self->depends_on('man');
    $self->depends_on('postats');
}

sub make_files_writable {
    my $self = shift;
    my $dir = shift;
    my $files = $self->rscan_dir($dir, sub {-f});
    foreach my $file (@$files) {
        my $current_mode = stat($file)->mode;
        chmod $current_mode | oct(200), $file;
    }
}

sub perl_scripts {
    return ('po4a-gettextize', 'po4a-updatepo', 'po4a-translate',
            'po4a-normalize', 'po4a', 'msguntypot');
}

# Update po/bin/*.po files
sub ACTION_binpo {
    my $self = shift;
    my ($cmd, $sources);

    $self->depends_on('code');
    $self->make_files_writable("po/bin");

    my @all_files = sort((perl_scripts(), @{$self->rscan_dir('lib',qr{\.pm$})}));
    unless ($self->up_to_date(\@all_files, "po/bin/po4a.pot")) {
        print "XX Update po/bin/po4a.pot\n";
        chdir "po/bin";
        $sources = join ("", map {" ../../".$_ } @all_files);
        $cmd = "xgettext ";
        $cmd .= "--from-code=utf-8 ";
        $cmd .= "-L Perl ";
        $cmd .= "--add-comments ";
        $cmd .= "--msgid-bugs-address po4a\@packages.debian.org ";
        $cmd .= "--package-name po4a ";
        $cmd .= "--package-version ".$self->dist_version()." ";
        $cmd .= "$sources ";
        $cmd .= "-o po4a.pot.new";
        system($cmd) && die;
	
        chdir "../..";
	
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
    foreach (@{$self->rscan_dir('po/bin',qr{\.po$})}) {
        my $lang = fileparse($_, qw{.po});
        unless ($self->up_to_date("po/bin/po4a.pot", $_)) {
            print "XX Sync $_: ";
            system("msgmerge --previous $_ po/bin/po4a.pot -o $_.new") && die;
            # Typically all that changes was a date. I'd
            # prefer not to commit such changes, so detect
            # and ignore them.
            $diff = qx(diff -q -I'#:' -I'POT-Creation-Date:' -I'PO-Revision-Date:' $_ $_.new);
            if ($diff eq "") {
                unlink "$_.new" || die;
                # touch it
                my ($atime, $mtime) = (time,time);
                utime $atime, $mtime, $_;
            } else {
                rename "$_.new", $_ || die;
            }
        } else {
            print "XX $_ uptodate.\n";
        }
        unless ($self->up_to_date($_,"blib/po/$lang/LC_MESSAGES/po4a.mo")) {
            mkpath( File::Spec->catdir( 'blib', 'po', $lang, "LC_MESSAGES" ), 0, oct(755) );
            system("msgfmt -o blib/po/$lang/LC_MESSAGES/po4a.mo $_") && die;
        }
    }
}

sub ACTION_install {
    my $self = shift;

    require ExtUtils::Install;
#    print ("KEYS\n");
#    foreach my $k ($self->install_types()) {
#	print ("$k -> ".$self->install_destination($k)."\n");
#    }
    my $mandir = $self->install_destination('libdoc');
    $mandir =~ s,/man3$,,;
    $self->install_path(man => $mandir);

    my $localedir = $self->install_destination('libdoc');
    $localedir =~ s,/man/man3$,/locale,;
    $self->install_path(po => $localedir);

    ExtUtils::Install::install($self->install_map, !$self->quiet, 0, $self->{args}{uninst}||0);
}

sub ACTION_dist {
    my ($self) = @_;

    $ENV{PO4AFLAGS} ||= '--force';
    $self->depends_on('distcheck');
    $self->depends_on('test');
    $self->depends_on('binpo');
    $self->depends_on('docpo');
    $self->depends_on('distdir');

    my $dist_dir = $self->dist_dir;
    $self->make_files_writable($dist_dir);

    if ( -e "$dist_dir.tar.gz") {
        # Delete the distfile if it already exists
        unlink "$dist_dir.tar.gz" || die;
    }

    $self->make_tarball($dist_dir);
    $self->delete_filetree($dist_dir);
}

sub ACTION_docpo {
    my $self = shift;
    $self->depends_on('code');
    $self->make_files_writable("po/pod");

    my $cmd = "PERL5LIB=lib perl po4a "; # Use this version of po4a
    $cmd .= "--previous ";
    $cmd .= "--no-translations ";
    $cmd .= "--msgid-bugs-address devel\@lists.po4a.org ";
    $cmd .= "--package-name po4a ";
    $cmd .= "--package-version ".$self->dist_version()." ";
    $cmd .= $ENV{PO4AFLAGS}." " if defined($ENV{PO4AFLAGS});
    $cmd .= "po/pod.cfg";
    system($cmd)
        and die;
}

sub ACTION_man {
    my $self = shift;
    $self->depends_on('docpo');

    use Pod::Man;
    use Encode;

    # Translate binaries manpages
    my %options;
    $options{utf8} = 1;
    my $parser = Pod::Man->new (%options);

    my $manpath  = File::Spec->catdir( 'blib', 'man' );
    File::Path::rmtree( $manpath, 0, 1);

    my $cmd = "PERL5LIB=lib perl po4a "; # Use this version of po4a
    $cmd .= $ENV{PO4AFLAGS}." " if defined($ENV{PO4AFLAGS});
    $cmd .= "--previous po/pod.cfg";
    system($cmd) and die;

    my $man1path = File::Spec->catdir( $manpath, 'man1' );
    my $man3path = File::Spec->catdir( $manpath, 'man3' );
    my $man5path = File::Spec->catdir( $manpath, 'man5' );
    my $man7path = File::Spec->catdir( $manpath, 'man7' );
    File::Path::mkpath( $man1path, 0, oct(755) ) or die;
    File::Path::mkpath( $man3path, 0, oct(755) ) or die;
    File::Path::mkpath( $man5path, 0, oct(755) ) or die;
    File::Path::mkpath( $man7path, 0, oct(755) ) or die;
    copy ( File::Spec->catdir("doc", "po4a.7.pod"), $man7path) or die;
    foreach $file (perl_scripts()) {
        $file =~ m,([^/]*)$,;
        copy($file, File::Spec->catdir($man1path, "$1.1p.pod")) or die "Cannot copy $file over";
    }
    foreach $file (@{$self->rscan_dir('lib',qr{\.pm$})}) {
        $file =~ m,([^/]*).pm$,;
        copy($file, File::Spec->catdir($man3path, "Locale::Po4a::$1.3pm.pod")) or die;
    }
    $self->delete_filetree( File::Spec->catdir("blib", "bindoc") );
    $self->delete_filetree( File::Spec->catdir("blib", "libdoc") );

    foreach $file (@{$self->rscan_dir($manpath, qr{\.pod$})}) {
        next if $file =~ m/^man7/;
        my $out = $file;
        $out =~ s/\.pod$//;
        $parser->{name} = $out;
        $parser->{name} =~ s/^.*\///;
        $parser->{name} =~ s/^(.*).(1p|3pm|5|7)/$1/;
        $parser->{section} = $2;
        if ($parser->{section} ne "3pm") {
            $parser->{name} = uc $parser->{name};
        }

        my $lang = $out;
        $lang =~ s/^blib\/man\/([^\/]*)\/.*$/$1/;

        if ($lang =~ m/man\d/) {
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
        unlink "$file" || die;
    }

    # Install the manpages written in XML DocBook
    foreach $file (qw(po4a-display-man.xml po4a-display-pod.xml)) {
        copy ( File::Spec->catdir("share", "doc", $file), $man1path) or die;
    }
    foreach $file (@{$self->rscan_dir($manpath, qr{\.xml$})}) {
        if ($file =~ m,(.*/man(.))/([^/]*)\.xml$,) {
            my ($outdir, $section, $outfile) = ($1, $2, $3);
            system("xsltproc -o $outdir/$outfile.$section --nonet http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl $file") and die;
            system ("gzip -9 -f $outdir/$outfile.$section") and die;
        }
        unlink "$file" || die;
    }
}

sub ACTION_postats {
    my $self = shift;
    $self->depends_on('binpo');
    $self->depends_on('docpo');
    print("-------------\n");
    $self->postats( File::Spec->catdir("po", "bin"));
    print("-------------\n");
    $self->postats( File::Spec->catdir("po", "pod"));
    print("-------------\n");
    $self->postats( File::Spec->catdir("..", "po4a-website", "po")) if -d File::Spec->catdir("..", "po4a-website", "po");
}

sub postats {
    my ($self,$dir) = (shift,shift);
    my $potfiles = $self->rscan_dir($dir,qr{\.pot$});
    die "No POT file found in $dir" unless scalar $potfiles;
    my $potfile = pop @$potfiles;
    my $potsize = stat($potfile)->size;
    print "$dir (pot: $potsize)\n";
    my @files = @{$self->rscan_dir($dir,qr{\.po$})};
    my (@t100,@t95,@t90,@t80,@t70,@t50,@t33,@t20,@starting);
    foreach (sort @files) {
        $file = $_;
        my $lang = fileparse($file, qw{.po});
        my $stat = `msgfmt -o /dev/null -c --statistics $file 2>&1`;
	my ($trans, $fuzz, $untr) = (0,0,0);
	if ($stat =~ /(\d+)\D+?(\d+)\D+?(\d+)/) {
	  ($trans, $fuzz, $untr) = ($1,$2,$3);
	} elsif ($stat =~ /(\d+)\D+?(\d+)/) {
	  ($trans, $fuzz) = ($1,$2);
	} elsif ($stat =~ /(\d+)/) {
	  ($trans) = ($1);
	} else {
	  print "Unparsable content\n";
	}
        my $total = $trans+$fuzz+$untr;
	my $ratio = $trans / $total * 100;
#	print "ratio: $ratio| trans: $trans; fuzz: $fuzz; untr: $untr\n";
	my $Ratio = int($ratio);
        print "  $lang (".(int($ratio*100)/100)."%): $stat";
	if ($ratio == 100) {
	    push @t100, $lang;
	} elsif ($ratio >= 95) {
	    push @t95, "$lang ($Ratio%)";
	} elsif ($ratio >= 90) {
	    push @t90, "$lang ($Ratio%)";
	} elsif ($ratio >= 80) {
	    push @t80, "$lang ($Ratio%)";
	} elsif ($ratio >= 70) {
	    push @t70, "$lang ($Ratio%)";
	} elsif ($ratio >= 50) {
	    push @t50, "$lang ($Ratio%)";
	} elsif ($ratio >= 33) {
	    push @t33, "$lang ($Ratio%)";
	} elsif ($ratio >= 20) {
	    push @t20, "$lang ($Ratio%)";
	} else {
	    push @starting, "$lang ($Ratio%)";
	}
    }
    print "$dir (pot: $potsize)\n";
    print " ".(scalar (@t100))." language".(scalar (@t100)==1?' ':'s')." = 100%: ". (join(", ", @t100)).".\n" if (scalar(@t100)>0);
    print " ".(scalar (@t95))." language".(scalar (@t95)==1?' ':'s')." >= 95%: ". (join(", ", @t95)).".\n" if (scalar(@t95)>0);
    print " ".(scalar (@t90))." language".(scalar (@t90)==1?' ':'s')." >= 90%: ". (join(", ", @t90)).".\n" if (scalar(@t90)>0);
    print " ".(scalar (@t80))." language".(scalar (@t80)==1?' ':'s')." >= 80%: ". (join(", ", @t80)).".\n" if (scalar(@t80)>0);
    print " ".(scalar (@t70))." language".(scalar (@t70)==1?' ':'s')." >= 70%: ". (join(", ", @t70)).".\n" if (scalar(@t70)>0);
    print " ".(scalar (@t50))." language".(scalar (@t50)==1?' ':'s')." >= 50%: ". (join(", ", @t50)).".\n" if (scalar(@t50)>0);
    print " ".(scalar (@t33))." language".(scalar (@t33)==1?' ':'s')." >= 33%: ". (join(", ", @t33)).".\n" if (scalar(@t33)>0);
    print " ".(scalar (@t20))." language".(scalar (@t20)==1?' ':'s')." >= 20%: ". (join(", ", @t20)).".\n" if (scalar(@t20)>0);
    print " ".(scalar (@starting))." starting language".(scalar (@starting)==1?' ':'s').": ". (join(", ", @starting)).".\n" if (scalar(@starting)>0);
}

1;
