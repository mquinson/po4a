# XML and XML-based modules tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

for my $g (qw(basic comments cdata)) {
    push @tests, { 'format' => 'guide', 'input' => "fmt/xml/$g.xml" };
}
for my $x (qw(options attribute-novalue)) {
    push @tests, { 'format' => 'xml', 'input' => "fmt/xml/$x.xml" };
}

run_all_tests(@tests);
0;
