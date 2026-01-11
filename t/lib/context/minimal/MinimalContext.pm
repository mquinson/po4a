package MinimalContext;

use strict;
use warnings;

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
