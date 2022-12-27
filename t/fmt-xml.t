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
for my $x (qw(attribute-novalue options)) {
    push @tests, { 'format' => 'xml', 'input' => "fmt/xml/$x.xml" };
}
push @tests, {
    'format' => 'xml',
    'input' => "fmt/xml/placeholder-empty.xml",
    'options' => "-o 'placeholder=<place>'",
}, {
    'format' => 'xml',
    'input' => "fmt/xml/inside-foldattribute.xml",
    'options' => "-o 'attributes=<image>alt' -o 'inline=<image>' -o foldattributes",
};

run_all_tests(@tests);
0;
