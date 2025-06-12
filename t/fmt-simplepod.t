# This test verifies the Locale::Po4a::SimplePod module, which processes the
# POD file format.
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

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;
push @tests,
  {
    doc          => 'Basic document used in the Pod module test',
    format       => 'SimplePod',
    input        => 'fmt/pod/basic.pod',
    norm         => 'fmt/simplepod/basic.norm',
    potfile      => 'fmt/simplepod/basic.pot',
    pofile       => 'fmt/simplepod/basic.po',
    norm_stderr  => 'fmt/simplepod/basic.norm.stderr',
    trans        => 'fmt/simplepod/basic.trans',
    trans_stderr => 'fmt/simplepod/basic.trans.stderr',
  },
  {
    doc    => 'Pertaining to the reported issues',
    format => 'SimplePod',
    input  => 'fmt/simplepod/issues.pod',
  },
  {
    doc    => 'Complete set of syntaxes from podlators',
    format => 'SimplePod',

    # The podlators.pod file comes from the podlators test data set [1].
    # [1] https://github.com/rra/podlators/blob/87dd36c591ffaca20e30bffe9b8d165dc49aa4ac/t/data/basic.pod
    input => 'fmt/simplepod/podlators.pod',
  },
  {
    doc    => 'Various miscellaneous test cases',
    format => 'SimplePod',
    input  => 'fmt/simplepod/misc.pod',
  },
  {
    doc          => 'ISO 8859',
    format       => 'SimplePod',
    input        => 'charset/po-iso8859/iso8859.pod',
    norm         => 'fmt/simplepod/iso8859.norm',
    potfile      => 'fmt/simplepod/iso8859.pot',
    pofile       => 'fmt/simplepod/iso8859.po',
    norm_stderr  => 'fmt/simplepod/iso8859.norm.stderr',
    trans        => 'fmt/simplepod/iso8859.trans',
    trans_stderr => 'fmt/simplepod/iso8859.trans.stderr',
  };

run_all_tests(@tests);

0;
