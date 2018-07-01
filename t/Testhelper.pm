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
        my ( $val, $name );

        my $cmd = $test->{'run'};
        $val = system($cmd);

        $name = $test->{'doc'} . ' runs';
        ok( $val == 0, $name );
        diag( $test->{'run'} ) unless ( $val == 0 );

      SKIP: {
            skip( "Command didn't run, can't test the validity of its return",
                1 )
              if $val;
            $val  = system( $test->{'test'} );
            $name = $test->{'doc'} . ' returns what is expected';
            ok( $val == 0, $name );
            unless ( $val == 0 ) {
                diag("Failed (retval=$val) on:");
                diag( $test->{'test'} );
                diag("Was created with:");
                diag( $test->{'run'} );
            }
        }
    }

    chdir "../.." or die "Can't chdir back to root directory\n";
}

1;
