use strict;
use warnings;

use lib q(t);
use Testhelper;
use File::Basename qw(dirname);
use Cwd            qw(abs_path);

my $dir = dirname( abs_path(__FILE__) );
run_all_tests(
    {
        doc => 'minimal context usage',

        # The following directory is added to the PERL5LIB path so that its content can be dynamically loaded
        perl_lib => "$dir/lib/context/minimal",

        # The specificity of this conf file is to add the --context-module=MinimalContext option, that dynamically loads
        # t/lib/context/minimal/MinimalContext.pm (that you want to read to understand what's going on)
        'po4a.conf' => 'context/minimal/po4a.conf',

        expected_files => 'master.pot trans.md trans.po',
    }
);

0;
