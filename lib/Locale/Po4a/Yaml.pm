# Locale::Po4a::Yaml -- Convert yaml files to PO file, for translation.
#
# This program is free software; you may redistribute it and/or modify it
# under the terms of GPL v2.0 or later (see COPYING).
#

=encoding UTF-8

=head1 NAME

Locale::Po4a::Yaml - convert YAML files from/to PO files

=head1 DESCRIPTION

Locale::Po4a::Yaml is a module to help the translation of Yaml files into other
[human] languages.

The module extracts the value of YAML hashes and arrays. Hash keys are
not extracted.

NOTE: This module parses the YAML file with YAML::Tiny.

=head1 OPTIONS ACCEPTED BY THIS MODULE

These are this module's particular options:

=over

=item B<keys>

Space-separated list of hash keys to process for extraction, all
other keys are skipped.  Keys are matched with a case-sensitive match.
If B<paths> and B<keys> are used together, values are included if they are
matched by at least one of the options.
Arrays values are always returned unless the B<skip_array> option is
provided.

=item B<paths>

Comma-separated list of hash paths to process for extraction, all
other paths are skipped. Paths are matched with a case-sensitive match.
If B<paths> and B<keys> are used together, values are included if they are
matched by at least one of the options.
Arrays values are always returned unless the B<skip_array> option is
provided.

=item B<skip_array>

Do not translate array values.

=back

=head1 SEE ALSO

L<Locale::Po4a::TransTractor(3pm)>, L<po4a(7)|po4a.7>

=head1 AUTHORS

 Brian Exelbierd <bex@pobox.com>

=head1 COPYRIGHT AND LICENSE

 Copyright © 2017 Brian Exelbierd.
 Copyright © 2022 Martin Quinson <mquinson#debian.org>.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL v2.0 or later (see the COPYING file).

=cut

############################################################################
# Modules and declarations
############################################################################

package Locale::Po4a::Yaml;

use 5.16.0;
use strict;
use warnings;

use parent qw(Locale::Po4a::TransTractor);

use Locale::Po4a::Common qw(wrap_mod dgettext);
use YAML::Tiny;
use Scalar::Util;
use Encode;

use vars qw($AUTOLOAD);

my %yfm_keys  = ();
my %yfm_paths = ();

sub initialize {
    my $self    = shift;
    my %options = @_;

    $self->{options}{'keys'}       = '';
    $self->{options}{'paths'}      = '';
    $self->{options}{'skip_array'} = 0;

    foreach my $opt ( keys %options ) {
        die wrap_mod( "po4a::yaml", dgettext( "po4a", "Unknown option: %s" ), $opt )
          unless exists $self->{options}{$opt};
        $self->{options}{$opt} = $options{$opt};
    }

    map {
        $_ =~ s/^\s+|\s+$//g;    # Trim the keys before using them
        $yfm_keys{$_} = 1
    } ( split( /[, ]/, $self->{options}{keys} ) );

    # map { print STDERR "key: '$_'\n"; } (keys %yfm_keys);

    %yfm_paths = ( %yfm_paths, %{ $self->parse_comma_separated_option( $self->{options}{paths} ) } );
}

sub parse {
    my $self = shift;
    my $yfm;

    # Get the ref of the first line. We'll use it as the ref for the whole doc
    my ( $line, $ref ) = $self->shiftline();
    $self->unshiftline( $line, $ref );

    while (1) {
        my ( $nextline, $nextref ) = $self->shiftline();

        if ( not defined($nextline) ) {
            last;
        } elsif ( $nextline =~ /: [\[\{]/ ) {
            die wrap_mod(
                "po4a::text",
                dgettext(
                    "po4a",
                    "Inline lists and dictionaries on a single line are not correctly handled the parser we use (YAML::Tiny): they are interpreted as regular strings. "
                      . "Please use multi-lines definitions instead. Offending line:\n %s"
                ),
                $nextline
            );
        }

        $yfm .= $nextline;
    }

    my $yamlarray = YAML::Tiny->read_string($yfm)
      || die "YAML::Tiny failed to parse the content of $ref: $!";

    $self->handle_yaml( 0, $ref, $yamlarray, \%yfm_keys, $self->{options}{skip_array}, \%yfm_paths );
}

1;
__END__
