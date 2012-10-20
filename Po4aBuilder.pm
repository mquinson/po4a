package Po4aBuilder;
use Module::Build;
use File::Basename;
use File::Path;
use File::Spec;
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
            'po4a-normalize', 'po4a', 'scripts/msguntypot');
}

sub shell_scripts {
    return ('share/po4a-build');
}

# Update po/bin/*.po files
sub ACTION_binpo {
    my $self = shift;
    my ($cmd, $sources);

    $self->depends_on('code');
    $self->make_files_writable("po/bin");

    my @perl_files = sort((perl_scripts(), @{$self->rscan_dir('lib',qr{\.pm$})}));
    my @shell_files = sort(shell_scripts());
    my @all_files = (@perl_files, @shell_files);
    unless ($self->up_to_date(\@all_files, "po/bin/po4a.pot")) {
        print "XX Update po/bin/po4a-perl.pot\n";
        $sources = join ("", map {" ../../".$_ } @perl_files);
        $cmd = "cd po/bin; xgettext ";
        $cmd .= "--from-code=utf-8 ";
        $cmd .= "-L Perl ";
        $cmd .= "--add-comments ";
        $cmd .= "--msgid-bugs-address po4a\@packages.debian.org ";
        $cmd .= "--package-name po4a ";
        $cmd .= "--package-version ".$self->dist_version()." ";
        $cmd .= "$sources ";
        $cmd .= "-o po4a-perl.pot";
        system($cmd) && die;

        print "XX Update po/bin/po4a-shell.pot\n";
        $sources = join ("", map {" ../../".$_ } @shell_files);
        $cmd = "cd po/bin; xgettext ";
        $cmd .= "--from-code=utf-8 ";
        $cmd .= "-L shell ";
        $cmd .= "--add-comments ";
        $cmd .= "--msgid-bugs-address po4a\@packages.debian.org ";
        $cmd .= "--package-name po4a ";
        $cmd .= "--package-version ".$self->dist_version()." ";
        $cmd .= "$sources ";
        $cmd .= "-o po4a-shell.pot";
        system($cmd) && die;

        $cmd = "msgcat po/bin/po4a-perl.pot po/bin/po4a-shell.pot -o po/bin/po4a.pot.new";
        system($cmd) && die;

        unlink "po/bin/po4a-perl.pot" || die;
        unlink "po/bin/po4a-shell.pot" || die;

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
            File::Path::mkpath( File::Spec->catdir( 'blib', 'po', $lang, "LC_MESSAGES" ), 0, oct(777) );
            system("msgfmt -o blib/po/$lang/LC_MESSAGES/po4a.mo $_") && die;
        } 
    }
}

sub ACTION_install {
    my $self = shift;

    require ExtUtils::Install;
#    $self->depends_on('build');
    my $mandir = $self->install_sets($self->installdirs)->{'bindoc'};
    $mandir =~ s,/man1$,,;
    $self->install_path(man => $mandir);
    $self->install_path(manl10n => $mandir);

    my $localedir = $mandir;
    $localedir =~ s,/man$,/locale,;
    $self->install_path(po => $localedir);

    ExtUtils::Install::install($self->install_map, !$self->quiet, 0, $self->{args}{uninst}||0);
}

sub ACTION_dist {
    my ($self) = @_;

    $ENV{PO4AFLAGS} ||= '--force';
    $self->depends_on('test');
    $self->depends_on('binpo');
    $self->depends_on('manpo');
    $self->depends_on('distdir');

    my $dist_dir = $self->dist_dir;

    if ( -e "$dist_dir.tar.gz") {
        # Delete the distfile if it already exists
        unlink "$dist_dir.tar.gz" || die;
    }

    $self->make_tarball($dist_dir);
    $self->delete_filetree($dist_dir);
} 

sub ACTION_manpo {
    my $self = shift;
    $self->depends_on('code');
    $self->make_files_writable("po/pod");

    my $cmd = "PERL5LIB=lib perl po4a "; # Use this version of po4a
    $cmd .= "--previous ";
    $cmd .= "--no-translations ";
    $cmd .= "--msgid-bugs-address po4a-devel\@lists.alioth.debian.org ";
    $cmd .= "--package-name po4a ";
    $cmd .= "--package-version ".$self->dist_version()." ";
    $cmd .= $ENV{PO4AFLAGS}." " if defined($ENV{PO4AFLAGS});
    $cmd .= "po/pod.cfg";
    system($cmd)
        and die;
}

sub ACTION_man {
    my $self = shift;
    $self->depends_on('manpo');

    use Pod::Man;
    use Encode;

    # Translate binaries manpages
    my %options;
    $options{utf8} = 1;
    my $parser = Pod::Man->new (%options);

    my $cmd = "PERL5LIB=lib perl po4a "; # Use this version of po4a
    $cmd .= $ENV{PO4AFLAGS}." " if defined($ENV{PO4AFLAGS});
    $cmd .= "--previous po/pod.cfg";
    system($cmd) and die;
    system("mkdir -p blib/man/man7") and die;
    system("mkdir -p blib/man/man1") and die;
    system("cp doc/po4a.7.pod blib/man/man7") and die;
    foreach $file (perl_scripts()) {
        $file =~ m,([^/]*)$,;
        system ("cp $file blib/man/man1/$1.1p.pod") and die;
    }
    $self->delete_filetree("blib/bindoc") || die;

    foreach $file (@{$self->rscan_dir('blib/man',qr{\.pod$})}) {
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
    system ("cp share/doc/po4a-build.xml share/doc/po4aman-display-po.xml share/doc/po4apod-display-po.xml blib/man/man1/") and die;
    foreach $file (@{$self->rscan_dir('blib/man',qr{\.xml$})}) {
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
    $self->postats("po/bin");
    $self->postats("po/pod");
    $self->postats("po/www") if -d "po/www";
}

sub postats {
    my ($self,$dir) = (shift,shift);
    my $potfiles = $self->rscan_dir($dir,qr{\.pot$});
    die "No POT file found in $dir" unless scalar $potfiles;
    my $potfile = pop @$potfiles;
    my $potsize = stat($potfile)->size;
    print "$dir (pot: $potsize)\n";
    my @files = @{$self->rscan_dir($dir,qr{\.po$})};
    foreach (sort @files) {
        $file = $_;
        my $lang = fileparse($file, qw{.po});
        my $stat = `msgfmt -o /dev/null -c -v --statistics $file 2>&1`;
        print "  $lang: $stat";
    }
}
    
1;
