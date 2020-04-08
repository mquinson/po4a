# Provides a common test routine to avoid repeating the same
# code over and over again.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#
########################################################################

# This accepts several type of tests:
#
# 
# * po4a.conf test. List of accepted keys:
#   doc            (opt): Free string
#   po4a.conf      (req): path to a config file for po4a
#   options        (opt): extra parameters to pass to po4a, in addition to "--destdir tmp --verbose" that is unavoidable.

#   expected_files (opt): array of file names that are expected after the test execution. If provided:
#                          - Any missing or unexpected file is a test failure.
#                          - The expected content of $file must be provided in _$file or $file
#                            (use _$file for pure output files that are not supposed to be read by po4a).
#                            For that, a test is added automatically unless your tests already contain a line matching '$path/$file tmp/$path/$file'.
#                            This test is 'PODIFF -I#: $path/$file tmp/$path/$file' if your file is a po/pot file, or 'diff -u $path/$file tmp/$path/$file'
#   tests          (opt): array of shell commands to run after the test; any failure is reported as a test failure
#                         Automatic substitutions in each command:
#                           PATH   -> Path to po4a binaries
#                           PODIFF -> "diff -u -I'^\"POT-Creation-Date:' -I'^\"PO-Revision-Date:'"

#   setup          (opt): array of shell commands to run before running the test
#   teardown       (opt): array of shell commands to run after running the test
#   closed_path    (opt): a shell pattern to pass to chmod to close the other directories.
#                         If provided, setup/teardown commands are generated to:
#                           - 'chmod 0' the directories marked 'closed_path'
#                           - 'chmod +r-w+x' the test directory
#                           - 'chmod +r-w' all files in the test directory


package Testhelper;

use strict;
use warnings;
use Test::More 'no_plan';
use File::Path qw(make_path remove_tree);
use Cwd qw(cwd);

use Exporter qw(import);
our @EXPORT = qw(run_all_tests);

# Set the right environment variables to normalize the outputs
$ENV{'LC_ALL'}="C";
$ENV{'COLUMNS'}="80";

# Path to the tested executables. AUTOPKGTEST_TMP is set on salsa CI for Debian packages.
my $execpath = defined $ENV{AUTOPKGTEST_TMP} ? "/usr/bin" : "perl ..";

# small helper function to add an element in a list only if no existing element match with the provided pattern
sub add_unless_found {
    my ($list, $pattern, $to_add) = @_;
    map {return if (/$pattern/)} @{$list};
#    print STDERR "ADD because $pattern not found\n";
    push @{$list}, $to_add;
}

my $PODIFF = "-I'Copyright (C) 20.. Free Software Foundation, Inc.' -I'^# Automatically generated, 20...' -I'^\"POT-Creation-Date:' -I'^\"PO-Revision-Date:'";

sub show_files {
    my $basename = shift;
    foreach my $file (glob("${basename}*")) {
        if (-s $file) {
            diag("Produced file $file:");
            open FH, "$file" || die "Cannot open exisiting $file, I'm puzzled";
            while (<FH>) {
                diag("  $_");
            }
            diag("(end of $file)\n");
            diag("-------------------------------------------------------------");
            close(FH);
        }
    }
}
# Returns whether the details should be shown
sub system_failed {
    my ($cmd, $doc) = @_;
    my $exit_status = system($cmd);
    $cmd =~ s/diff -u -I'Copyright .C. 20.. Free Software Foundation, Inc.' -I'.. Automatically generated, 20...' -I'."POT-Creation-Date:' -I'."PO-Revision-Date:'/PODIFF/g;
    if ($exit_status == 0) {
        if ($doc ne '') {
            pass($doc);
            pass("  Command: $cmd");
        } else {
            pass("$cmd");
        }
        return 0;
    } else {
        $doc = 'Provided command' unless $doc ne '';
        fail($doc. " (retcode: $exit_status)");
        diag ("  Command: $cmd");
        return 1;
    }
}

sub teardown {
    my $test = shift;

    return unless $test->{'teardown'};

    my @cmds;
    push @cmds, @{$test->{'teardown'}} if (ref $test->{'teardown'} eq 'ARRAY');
    push @cmds, $test->{'teardown'} if (ref $test->{'teardown'} eq ref '');
    fail "Invalid key 'teardown'. It must be either an array or a string" unless scalar @cmds;

    foreach my $cmd (@cmds) {
        if (system("$cmd 1>&2")) {
            diag("Error during teardown: $!");
            diag("  Command: $cmd");
        } else {
            pass("Teardown command: $cmd")
        }
    }
}
sub setup {
    my $test = shift;

    return unless $test->{'setup'};

    my @cmds;
    push @cmds, @{$test->{'setup'}} if (ref $test->{'setup'} eq 'ARRAY');
    push @cmds, $test->{'setup'} if (ref $test->{'setup'} eq ref '');
    fail "Invalid key 'setup'. It must be either an array or a string" unless scalar @cmds;

    foreach my $cmd (@cmds) {
        if (system("$cmd 1>&2")) {
            diag("Error during setup: $!");
            diag("  Command: $cmd");
            teardown($test);
        } else {
            pass("Setup command: $cmd")
        }
    }
}

sub run_one_po4aconf {
    my ($test, $path, $basename, $ext) = @_;

    my %valid_options;
    map { $valid_options{$_} = 1 } qw(po4a.conf todo doc closed_path options setup tests teardown expected_files expected_outfile );
    map { die "Invalid test ".$test->{'doc'}.": invalid key '$_'\n" unless exists $valid_options{$_} } (keys %{$test});

    $test->{'options'} = "--destdir tmp --verbose ".($test->{'options'}?$test->{'options'}:""); 
    fail("Broken test: 'tests' is not an array as expected") if exists $test->{tests} && ref $test->{tests} ne 'ARRAY';
    $test->{'tests'} = [] unless exists $test->{'tests'};


    fail("Broken test: path $path does not exist") unless -e $path;
    fail("Broken test: config file $path/$basename.$ext does not exist") unless -e "$path/$basename.$ext";
    return unless -e "$path/$basename.$ext";

    system("rm -rf tmp/$path/")  && die "Cannot cleanup tmp/$path/ on startup: $!";
    system("mkdir -p tmp/$path/") && die "Cannot create tmp/$path/: $!";

    if ($test->{'closed_path'}) {
        $test->{'setup'} = ()    if (not exists $test->{'setup'});
        $test->{'teardown'} = () if (not exists $test->{'teardown'});
        push @{$test->{'setup'}},    "chmod -r-w-x ".$test->{'closed_path'}; # Don't even look at the closed path
        push @{$test->{'teardown'}}, "chmod +r+w+x ".$test->{'closed_path'}; # Restore permissions
        push @{$test->{'setup'}},    "chmod +r+x $path";  # Look into the path of this test
        push @{$test->{'setup'}},    "chmod -w -R $path"; # But don't change any file in there
        push @{$test->{'teardown'}}, "chmod +w -R $path"; # Restore permissions
    }
    setup($test);

    my $cmd = "${execpath}/po4a -f ".$test->{'po4a.conf'}." ".($test->{'options'}?$test->{'options'}:'')." > tmp/$path/output 2>&1";

#    print STDERR "Path: $path; Basename: $basename; Ext: $ext\n";
    system("mkdir -p tmp/$path/") && die "Cannot create tmp/$path/: $!";

    if (system_failed($cmd, "Executing po4a")) {
        diag("Produced output:");
        open FH, "tmp/$path/output" || die "Cannot open output file that I just created, I'm puzzled";
        while (<FH>) {
            diag("  $_");
        }
        diag("(end of command output)\n");

        teardown($test);
        show_files("tmp/$path/");
        return;
    }

    my $expected_outfile = $test->{'expected_outfile'} ? $test->{'expected_outfile'} : "$path/_output";
    unless (-e $expected_outfile) {
        teardown($test);
        die "Malformed test $basename (".$test->{'doc'}."): no expected output. Please touch $expected_outfile\n";
    }
    if (system_failed("diff -u $expected_outfile tmp/$path/output 1>&2", "Comparing output of po4a")) {
        teardown($test);
        show_files("tmp/$path/");
        return;
    }

    if (exists $test->{'expected_files'}) {
        my %expected;
        map { $expected{$_} = 1 } split / +/, $test->{'expected_files'};
        if (length $test->{expected_files} == 0) {
            note("Expecting no output file.");
        } else {
            note("Expecting ".(scalar %expected)." output files: ".$test->{'expected_files'});
        }
        $expected{'output'} = 1;
        FILE: foreach my $file (glob("tmp/${path}/*")) {
            $file =~ s|tmp/$path/||;
            unless ($expected{$file}) {
                teardown($test);
                fail "Unexpected file '$file'";
            }
            delete $expected{$file};

            next FILE if $file eq 'output';
            if (-e "$path/$file") {
                add_unless_found($test->{tests}, "$path/$file *tmp/$path/$file",
                                 ($file =~ 'pot?$' ? "PODIFF -I#: ": "diff -u")." $path/$file tmp/$path/$file");
            } elsif (-e "$path/_$file") {
                add_unless_found($test->{tests}, "$path/_$file *tmp/$path/$file",
                                 ($file =~ 'pot?$' ? "PODIFF -I#: ": "diff -u")." $path/_$file tmp/$path/$file");
            } else {
                teardown($test);
                fail("Broken test $path/$basename: $path/_$file should be the expected content of produced file $file");
            }
        }
        foreach my $file (keys %expected) {
            fail "Missing file '$file'";
        }
    }

    if (scalar $test->{tests}) {
        for my $tcmd (@{$test->{tests}}) {
            #        print STDERR "cmd: $tcmd\n";
            $tcmd =~ s/PATH/${execpath}/g;
            $tcmd =~ s/PODIFF/diff -u $PODIFF /g;
            if (system_failed("$tcmd 1>&2", "")) {
                teardown($test);
                show_files("tmp/$path/");
                return;
            }
        }
    }

    teardown($test);
}

sub run_one_format {
    my ( $test, $options, $test_directory, $basename, $ext ) = @_;

    system("mkdir -p tmp/$basename/") && die "Cannot create tmp/$basename/: $!";
    my $tmpbase = "tmp/$basename/$basename";

    ####
    # Normalize the document
    my $cmd = "${execpath}/po4a-normalize "
        . "--pot ${tmpbase}.pot --localized ${tmpbase}.out $options $test_directory/$basename.$ext"
        . " > ${tmpbase}.err 2>&1";
    my $name = "$basename (".$test->{'doc'}.")";

    my $exit_status = system($cmd);
    if ($exit_status == 0) {
        pass("Normalizing $name");
        pass("  Pass: $cmd");
    } else {
        fail("Normalizing $name: $exit_status");
        fail("  FAIL: $cmd");
    }

    ####
    # Check that the normalize result matches the expectations
    my $fail = 0;
    my @cmds;
    push @cmds, "PODIFF -I^#: $test_directory/$basename.pot ${tmpbase}.pot";
    push @cmds, "diff -u $test_directory/$basename.out ${tmpbase}.out";
    push @cmds, "diff -u $test_directory/$basename.err ${tmpbase}.err";

    foreach my $tcmd (@cmds) {
        $tcmd =~ s/PODIFF/diff -u $PODIFF/g;
        $exit_status = system($tcmd." 1>&2");
        $tcmd =~ s/diff -u -I'Copyright .C. 20.. Free Software Foundation, Inc.' -I'.. Automatically generated, 20...' -I'."POT-Creation-Date:' -I'."PO-Revision-Date:'/PODIFF/g;
        if ($exit_status == 0) {
            pass("  pass: $tcmd");
        } else {
            fail("Normalization result does not match.");
            diag("  Failed command: $tcmd");
            diag("  Files were produced with: $cmd");
            $fail++;
        }
    }
    unless ($fail == 0) {
        show_files($tmpbase);
        return;
    }

    ####
    # If there's a translation, also test the translated output.
    if ( -f "$test_directory/$basename.trans.po" ) {
        $cmd = "${execpath}/po4a-translate $options --master $test_directory/$basename.$ext"
            . " --po $test_directory/$basename.trans.po --localized ${tmpbase}.trans.out"
            . " > ${tmpbase}.trans.err 2>&1";

        $exit_status = system($cmd);
        if ($exit_status == 0) {
            pass("Translation of $name");
            pass("  Pass: $cmd");
        } else {
            fail("Translation of $name");
            fail("  FAIL: $cmd");
            show_files($tmpbase);
            return;
        }

        ####
        # Check that the translation result matches the expectations
        $fail = 0;
        @cmds = ();
        push @cmds, "diff -u $test_directory/$basename.trans.out ${tmpbase}.trans.out";
        push @cmds, "diff -u $test_directory/$basename.trans.err ${tmpbase}.trans.err";
        foreach my $tcmd (@cmds) {
            $exit_status = system($tcmd." 1>&2");
            if ($exit_status == 0) {
                pass("  pass: $tcmd");
            } else {
                fail("Translation result does not match.");
                fail("  FAIL: $tcmd");
                $fail ++;
            }
        }
        unless ($fail == 0) {
            show_files($tmpbase);
            return;
        }

    }
}

sub run_all_tests {
    my @cases = @_;

    # Change into test directory and create a temporary directory
    chdir "t" or die "Can't chdir to test directory t\n";

    remove_tree("tmp") if (-e "tmp");
    make_path("tmp");

    TEST: foreach my $test (@cases) {
        if ( exists $test->{'normalize'} ) {
            if ( $test->{'normalize'} =~ m|^(.*) (.*)/([^/]*)\.([^/]*)$| ) {
                my ( $options, $path, $basename, $ext ) = ( $1, $2, $3, $4 );

                $test->{'doc'} = "Normalizing $basename" unless exists $test->{'doc'};

                if ( exists $test->{'todo'} ) {
                  TODO: {
                      print STDERR "TODO: ".$test->{doc}."\n";
                      local our $TODO = $test->{'todo'};
                      subtest $test->{'doc'} => sub { run_one_format($test, $options, $path, $basename, $ext); }
                    }
                } else {
                    subtest $test->{'doc'} => sub { run_one_format($test, $options, $path, $basename, $ext); }
                }

            } else {
                die "Invalid 'normalize' key in test definition: $test->{'doc'}\n";
            }
        } elsif ( exists $test->{'po4a.conf'} ) {

            if ($test->{'po4a.conf'} =~ m|^(.*)/([^/]*)\.([^./]*)$|) {
                my ($path, $basename, $ext) = ($1, $2, $3);
                if (exists $test->{'todo'}) {
                  TODO: {
                      local our $TODO = $test->{'todo'};
                      subtest $test->{'doc'} => sub { run_one_po4aconf($test, $path, $basename, $ext); }
                    }
                } else {
                    subtest $test->{'doc'} => sub { run_one_po4aconf($test, $path, $basename, $ext);}
                }
            } else {
                fail "Test ".$test->{'doc'}." malformed. Cannot parse the conf filename.";
            }

        } elsif ( exists $test->{'run'} ) {

            my $cmd = $test->{'run'};
            $cmd =~ s/PATH/${execpath}/;
            my $exit_status = system($cmd);
            is( $exit_status, 0, "Executing ".$test->{'doc'}." -- Command: $cmd" );
            next TEST unless ($exit_status == 0);

            fail "Malformed test ".$test->{'doc'}.": missing tests." unless scalar $test->{tests};
            for my $cmd (@{$test->{tests}}) {
#                print STDERR "cmd: $cmd\n";
                $cmd =~ s/PODIFF/diff -u $PODIFF/g;
                $exit_status = system($cmd.' 1>&2');
                $cmd =~ s/diff -u -I'Copyright .C. 20.. Free Software Foundation, Inc.' -I'.. Automatically generated, 20...' -I'."POT-Creation-Date:' -I'."PO-Revision-Date:'/PODIFF/g;
                is( $exit_status, 0, "Test of ".$test->{'doc'}." -- Command: $cmd" );
                next TEST unless ($exit_status == 0);
            }

        } else {
            fail "Test ".$test->{'doc'}." does not have any 'po4a.conf' nor 'normalize' nor 'run' field";
        }
    }

    chdir ".." or die "Can't chdir back to root directory\n";
}

1;
