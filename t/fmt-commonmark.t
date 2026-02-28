# CommonMark module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

# Generic tests

foreach my $t (qw(Basic Rules Codeblocks)) {
    push @tests, { format => 'CommonMark', input => "fmt/commonmark/$t.md" };
}

push @tests,
  {
    format  => 'CommonMark',
    options => "--master-charset UTF-8 --wrap-po=newlines -o neverwrap",
    input   => "fmt/commonmark/NoWrap.md",
  },
  {
    format => 'CommonMark',
    input  => "fmt/commonmark/NestedLists.md",
  };

# Some tests around the YAML Front Matter feature

push @tests,
  {
    format  => 'CommonMark',
    options => '-o yaml_metadata',
    input   => 'fmt/commonmark/YamlFrontMatter.md'
  },
  {
    doc     => "That the yfm_keys and yfm_skip_array options actually work",
    format  => 'CommonMark',
    options => "-o yaml_metadata -o yfm_skip_array -o yfm_keys='title , subtitle,paragraph'",
    input   => "fmt/commonmark/YamlFrontMatter_Options.md",
  },
  {
    doc     => "That the yfm_keys and yfm_paths options actually work",
    format  => 'CommonMark',
    options =>
      "-o yaml_metadata -o yfm_skip_array -o yfm_keys='   subtitle     ,paragraph' -o yfm_paths='people title' ",
    input => "fmt/commonmark/YamlFrontMatter_KeysPaths.md",
  },
  {
    doc     => "Allow markdown files to contain two horizontal rulers that do not denote a YFM.",
    format  => 'CommonMark',
    options => "-o yaml_metadata -o yfm_lenient ",
    input   => "fmt/commonmark/YamlFrontMatter_fake.md",
  };

run_all_tests(@tests);
0;
