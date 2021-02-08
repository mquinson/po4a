# Locale::Po4a::Yaml -- Convert yaml files to PO file, for translation.
#
# This program is free software; you may redistribute it and/or modify it
# under the terms of GPL (see COPYING).
#

############################################################################
# Modules and declarations
############################################################################

package Locale::Po4a::Yaml;

use Locale::Po4a::TransTractor;
use Locale::Po4a::Common;
use YAML::Tiny;
use Scalar::Util;
use Encode;

use 5.006;
use strict;
use warnings;

require Exporter;

use vars qw(@ISA @EXPORT $AUTOLOAD);
@ISA    = qw(Locale::Po4a::TransTractor);
@EXPORT = qw();

sub initialize {
    my $self    = shift;
    my %options = @_;

    $self->{options}{'keys'}       = '';
    $self->{options}{'debug'}      = 0;
    $self->{options}{'verbose'}    = 1;
    $self->{options}{'skip_array'} = 0;

    foreach my $opt ( keys %options ) {
        die wrap_mod( "po4a::yaml", dgettext( "po4a", "Unknown option: %s" ), $opt )
          unless exists $self->{options}{$opt};
        $self->{options}{$opt} = $options{$opt};
    }

    $self->{options}{keys} =~ s/^\s*//;
    foreach my $attr ( split( /\s+/, $self->{options}{keys} ) ) {
        $self->{keys}{ lc($attr) } = '';
    }
}

sub read {
    my ( $self, $filename, $refname ) = @_;
    push @{ $self->{DOCPOD}{infile} }, $filename;
    $self->Locale::Po4a::TransTractor::read( $filename, $refname );
}

sub parse {
    my $self = shift;
    map { $self->parse_file($_) } @{ $self->{DOCPOD}{infile} };
}

sub parse_file {
    my ( $self, $filename ) = @_;
    my $yaml = YAML::Tiny->read($filename)
      || die "Couldn't read YAML file $filename : $!";

    for my $i ( 0 .. $#{$yaml} ) {
        &walk_yaml( $self, $yaml->[$i], "" );
    }
    $self->pushline( Encode::encode_utf8( $yaml->write_string() ) );
}

sub walk_yaml {
    my $self = shift;
    my $el   = shift;
    my $ctx  = shift;

    my ( $line, $reference ) = $self->shiftline();
    $reference =~ s/:[0-9]+$/:0/;

    if ( ref $el eq 'HASH' ) {
        print STDERR "begin a hash\n" if $self->{'options'}{'debug'};
        foreach my $key ( sort keys %$el ) {
            if ( ref $el->{$key} ne ref "" ) {
                &walk_yaml( $self, $el->{$key}, "$ctx $key" );
            } else {
                next if ( ( $self->{options}{keys} ne "" ) and ( !exists $self->{keys}{ lc($key) } ) );
                my $trans = $self->translate(
                    Encode::encode_utf8( $el->{$key} ),
                    $reference,
                    "Hash Value:$ctx $key",
                    'wrap' => 0
                );
                $el->{$key} = Encode::decode_utf8($trans);    # Save the translation
            }
        }
    } elsif ( ref $el eq 'ARRAY' ) {
        print STDERR "begin an array\n" if $self->{'options'}{'debug'};
        for my $i ( 0 .. $#{$el} ) {
            if ( ref $el->[$i] ne ref "" ) {
                &walk_yaml( $self, $el->[$i], "$ctx" );
            } elsif ( !$self->{options}{skip_array} ) {       # translate that element only if not asked to skip arrays
                my $trans =
                  $self->translate( Encode::encode_utf8( $el->[$i] ), $reference, "Array Element:$ctx", 'wrap' => 0 );
                $el->[$i] = Encode::decode_utf8($trans);      # Save the translation
            }
        }
    } else {
        print STDERR "got a string - this is unexpected in yaml\n" if $self->{'options'}{'debug'};
        my $trans = $self->translate( Encode::encode_utf8($$el), $reference, "String:$ctx", 'wrap' => 0 );
        $$el = Encode::decode_utf8($trans);                   # Save the translation
    }
}

##############################################################################
# Module return value and documentation
##############################################################################

1;
__END__

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
other keys are skipped.  Keys are matched with a case-insentive match.
Arrays values are always returned unless if the B<skip_array> option is
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

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see the COPYING file).

=cut
