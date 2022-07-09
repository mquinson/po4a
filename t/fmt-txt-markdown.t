# Text module tester.

#########################

use strict;
use warnings;

use lib q(t);
use Testhelper;

my @tests;

# Generic tests

foreach my $t (qw(Basic Rules)) {
    push @tests, { 'format' => 'text', 'options' => '-o markdown', 'input' => "fmt/txt-markdown/$t.md" };
}

push @tests,
  {
    'format'  => 'text',
    'options' => "-o markdown --master-charset UTF-8 --wrap-po=newlines -o neverwrap",
    'input'   => "fmt/txt-markdown/NoWrap.md",
  },
  {
    'format'  => 'text',
    'options' => '-o markdown',
    'input'   => "fmt/txt-markdown/NestedLists.md",
  };

# Some tests specific to the Pandoc dialect of Markdown
# In particular regarding the headers

foreach my $pandoc (
    qw(HeaderTitle HeaderTitleMultilines HeaderTitleAuthors HeaderTitleDate HeaderOnlyAuthor HeaderTitleMultipleAuthors
    FencedCodeBlocks)
  )
{
    push @tests, { 'format' => 'text', 'options' => '-o markdown', 'input' => "fmt/txt-markdown/Pandoc$pandoc.md" };
}

# Some tests around the YAML Front Matter feature

push @tests,
  {
    'format'  => 'text',
    'options' => '-o markdown',
    'input'   => 'fmt/txt-markdown/YamlFrontMatter.md'
  },
  {
    'doc'     => "That the yfm_keys and yfm_skip_array options actually work",
    'format'  => 'text',
    'options' => "-o markdown -o yfm_skip_array -o yfm_keys='title , subtitle,paragraph'",
    'input'   => "fmt/txt-markdown/YamlFrontMatter_Options.md",
  },
  {
    'doc'     => "Allow markdown files to contain two horizontal rulers that do not denote a YFM.",
    'format'  => 'text',
    'options' => "-o markdown -o yfm_lenient ",
    'input'   => "fmt/txt-markdown/YamlFrontMatter_fake.md",
  };

run_all_tests(@tests);
0;
