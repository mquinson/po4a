package MinimalContext;

use strict;
use warnings;

# This file is a po4a context module. It is loaded automatically when using the --context-module=MinimalContext option of po4a (it must be in the PERL5LIB path)
#
# Such modules are required to have only one function: get_msgctxt() which receives a PO file entry (see the documentation of push(%) in Locale::Po4a::Po for 
# the syntax of such an entry) and returns a string that will be used as a context for the string during translations.
#
# In this example, the context is simply '1/title' for strings that are of Markdown type 'Title #', and '1/plain' for the rest.

sub get_msgctxt {
    my $args = shift;
    $args->{msgid} eq 'string 1' or return;
    if ( $args->{type} eq 'Title #' ) {
        return '1/title';
    } else {
        return '1/plain';
    }
}

1;
