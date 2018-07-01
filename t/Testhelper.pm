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

use Exporter qw(import);
our @EXPORT = qw(run_all_tests);

sub run_all_tests {
    my @tests = @_;

    plan tests => 2 * scalar @tests;

    mkdir "t/tmp"
      unless -e "t/tmp" or die "Can't create test directory t/tmp\n";
    chdir "t/tmp" or die "Can't chdir to test directory t/tmp\n";

    foreach my $test (@tests) {
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
            skip( "Command didn't run, can't test the validity of its return",
                1 )
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

    chdir "../.." or die "Can't chdir back to root directory\n";
}

1;
