use strict;
use warnings;

use lib q(t);
use Testhelper;
use File::Basename qw(dirname);
use Cwd            qw(abs_path);

my $dir = dirname( abs_path(__FILE__) );
run_all_tests(
    {
        doc            => 'minimal context usage',
        'po4a.conf'    => 'context/minimal/po4a.conf',
        perl_lib       => "$dir/lib/context/minimal",
        expected_files => 'master.pot trans.md trans.po',
    }
);

0;
