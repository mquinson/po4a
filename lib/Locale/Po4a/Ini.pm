# Locale::Po4a::Ini -- Convert ini files to PO file, for translation.
#
# This program is free software; you may redistribute it and/or modify it
# under the terms of GPL v2.0 or later (see COPYING).
#

############################################################################
# Modules and declarations
############################################################################

package Locale::Po4a::Ini;

use 5.16.0;
use strict;
use warnings;

use parent qw(Locale::Po4a::TransTractor);

use Locale::Po4a::Common;

require Exporter;

use vars qw(@EXPORT $AUTOLOAD);
@EXPORT = qw();

my $debug = 0;

sub parse {
    my $self = shift;
    my ( $line, $ref );
    my $par;

  LINE:
    ( $line, $ref ) = $self->shiftline();

    while ( defined($line) ) {
        chomp($line);
        print STDERR "begin\n" if $debug;

        if ( $line =~ /\"/ ) {
            print STDERR "Start of line containing \".\n" if $debug;

            # Text before the first quote
            $line =~ m/(^[^"\r\n]*)"/;
            my $pre_text = $1;
            print STDERR "  PreText=" . $pre_text . "\n" if $debug;

            # The text for translation
            $line =~ m/"([^\r\n]*)"/;
            my $quoted_text = $1;
            print STDERR "  QuotedText=" . $quoted_text . "\n" if $debug;

            # Text after last quote
            $line =~ m/"([^"\n]*$)/;
            my $post_text = $1;
            print STDERR "  PostText=" . $post_text . "\n" if $debug;

            # Translate the string it
            $par = $self->translate( $quoted_text, $ref, $pre_text );

            # Escape the \n characters
            $par =~ s/\n/\\n/g;

            # Now push the result
            $self->pushline( $pre_text . '"' . $par . '"' . $post_text . "\n" );
            print STDERR "End of line containing \".\n" if $debug;
        } else {
            print STDERR "Other stuff\n" if $debug;
            $self->pushline("$line\n");
        }

        # Reinit the loop
        ( $line, $ref ) = $self->shiftline();
    }
}

##############################################################################
# Module return value and documentation
##############################################################################

1;
__END__

=encoding UTF-8

=head1 NAME

Locale::Po4a::Ini - convert INI files from/to PO files

=head1 DESCRIPTION

Locale::Po4a::Ini is a module to help the translation of INI files into other
[human] languages.

The module searches for lines of the following format and extracts the quoted
text:

identificator="text than can be translated"

NOTE: If the text is not quoted, it will be ignored.

=head1 SEE ALSO

L<Locale::Po4a::TransTractor(3pm)>, L<po4a(7)|po4a.7>

=head1 AUTHORS

 Razvan Rusu <rrusu@bitdefender.com>
 Costin Stroie <cstroie@bitdefender.com>

=head1 COPYRIGHT AND LICENSE

Copyright © 2006 BitDefender

This program is free software; you may redistribute it and/or modify it
under the terms of GPL v2.0 or later (see the COPYING file).

=cut
