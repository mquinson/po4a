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

package Testhelper;

use strict;
use warnings;
use Test::More;
use File::Path qw(make_path remove_tree);

use Exporter qw(import);
our @EXPORT = qw(run_all_tests);

# Set the right environment variables to normalize the outputs
$ENV{'LC_ALL'}="C";
$ENV{'COLUMNS'}="80";

# The "normalize" hash key is a convenient shortcut
# to define a test with a po4a-normalize invocation.
# All those tests are similar, they generate a pot file,
# check for possible output on stderr and compare
# the resulting translated document with the
# one provided in the test directory.
sub create_tests_for_normalize {
    my $test = shift;
    if ( exists $test->{'normalize'} ) {
        if ( $test->{'normalize'} =~ /^(.*) (t-[0-9]+-[^\/]+)\/(.*)\.(.*)$/ ) {
            my ( $options, $test_directory, $basename, $ext ) =
              ( $1, $2, $3, $4 );
            my $run_cmd =
                "perl ../po4a-normalize"
              . " $options $test_directory/$basename.$ext"
              . " > tmp/$basename.err 2>&1"
              . " && mv po4a-normalize.po tmp/$basename.pot"
              . " && mv po4a-normalize.output tmp/$basename.out";

            # If there's a translation, also test the translated output.
            if ( -f "$test_directory/$basename.trans.po" ) {
                $run_cmd .=
                    " && perl ../po4a-translate"
                  . " $options -m $test_directory/$basename.$ext"
                  . " -p $test_directory/$basename.trans.po"
                  . " -l tmp/$basename.trans.out"
                  . " > tmp/$basename.trans.err 2>&1";
            }
            $test->{'run'} = $run_cmd;

            my $test_cmd =
                "perl compare-po.pl"
              . " $test_directory/$basename.pot tmp/$basename.pot"
              . " && diff -u $test_directory/$basename.out tmp/$basename.out 1>&2"
              . " && diff -u $test_directory/$basename.err tmp/$basename.err 1>&2";

            # If there's a translation, also check the translated output.
            if ( -f "$test_directory/$basename.trans.po" ) {
                $test_cmd .=
                    " && diff -u $test_directory/$basename.trans.out tmp/$basename.trans.out 1>&2"
                  . " && diff -u $test_directory/$basename.trans.err tmp/$basename.trans.err 1>&2";
            }
            $test->{'test'} = $test_cmd;
        }
        else {
            die "Invalid 'normalize' key in test definition: $test->{'doc'}\n";
        }
    }
    return $test;
}

sub run_all_tests {
    my @tests = @_;

    plan tests => 2 * scalar @tests;

    # Change into test directory and create a temporary directory
    chdir "t" or die "Can't chdir to test directory t\n";
    make_path("tmp");

    foreach my $test (@tests) {
        $test = create_tests_for_normalize($test);
        my $test_name   = $test->{'doc'} . ' runs';
        my $exit_status = system( $test->{'run'} );

        # Mark failing tests as TODO
        if ( defined $test->{'todo'} && length( $test->{'todo'} ) > 0 ) {
          TODO: {
                local our $TODO = $test->{'todo'};
                is( $exit_status, 0, $test_name ) or diag( $test->{'run'} );

                # Set the exit status to an error value, in order to be
                # able to skip the test for the command's output.
                $exit_status = 1;
            }
        }
        else {
            is( $exit_status, 0, $test_name ) or diag( $test->{'run'} );
        }

      SKIP: {
            skip "Command didn't run, can't test the validity of its return", 1
              if $exit_status;

            $test_name   = $test->{'doc'} . ' returns what is expected';
            $exit_status = system( $test->{'test'} );

            is( $exit_status, 0, $test_name );
            unless ( $exit_status == 0 ) {
                diag("Failed (retval=$exit_status) on:");
                diag( $test->{'test'} );
                diag("Was created with:");
                diag( $test->{'run'} );
            }
        }
    }

    # Clean up test files
    remove_tree("tmp");
    chdir ".." or die "Can't chdir back to root directory\n";
}

1;
