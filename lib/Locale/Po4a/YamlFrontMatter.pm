#!/usr/bin/perl -w

# Po4a::Text.pm
#
# extract and translate translatable strings from a text documents
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#
########################################################################

=encoding UTF-8

=head1 NAME

Locale::Po4a::YamlFrontMatter - parse YAML front matter

=head1 DESCRIPTION

The po4a (PO for anything) project goal is to ease translations (and more
interestingly, the maintenance of translations) using gettext tools on
areas where they were not expected like documentation.

Locale::Po4a::YamlFrontMatter is a module to parse YAML front matter,
especially in Markdown documents.  This is intended to be used by
other format modules such as C<Text> module.

=cut

package Locale::Po4a::YamlFrontMatter;

use 5.16.0;
use strict;
use warnings;

use parent qw(Locale::Po4a::TransTractor);

use Locale::Po4a::Common qw(wrap_mod dgettext);
use YAML::Tiny;
use Syntax::Keyword::Try;

=head1 FUNCTIONS

=head2 C<parse_yaml_front_matter>

Parse YAML Front Matter (especially in Markdown documents).

If the text starts with a YAML C<---\n> separator, the full text until
the next YAML C<---\n> separator is considered YAML metadata. The
C<...\n> "end of document" separator can be used at the end of the
YAML block.

It takes three arguments C<$ref>, and C<$options>.  C<$options> is a
hash reference which has keys C<keys>, C<skip_array>, C<paths>, and
C<lenient>.

Returns truthy value if it is a valid YAML, otherwise returns falthy
value.

=cut

sub parse_yaml_front_matter {
    my ( $self, $blockref, $options ) = @_;
    my $keys       = $options->{keys};
    my $skip_array = $options->{skip_array};
    my $paths      = $options->{paths};
    my $lenient    = $options->{lenient};

    my $yfm;
    my @saved_ctn;
    my ( $nextline, $nextref ) = $self->shiftline();
    push @saved_ctn, ( $nextline, $nextref );
    while ( defined($nextline) ) {
        last if ( $nextline =~ /^(---|\.\.\.)$/ );
        $yfm .= $nextline;
        ( $nextline, $nextref ) = $self->shiftline();
        if ( $nextline =~ /: [\[\{]/ ) {
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
        push @saved_ctn, ( $nextline, $nextref );
    }

    my $yamlarray;    # the parsed YFM content
    my $yamlres;      # containing the parse error, if any
    try {
        $yamlarray = YAML::Tiny->read_string($yfm);
    } catch {
        $yamlres = $@;
    }

    if ( defined($yamlres) ) {
        if ($lenient) {
            $yamlres =~ s/ at .*$//;    # Remove the error localisation in YAML::Tiny die message, if any (for our test)
            warn wrap_mod(
                "po4a::text",
                dgettext(
                    "po4a",
                    "Proceeding even if the YAML Front Matter could not be parsed. Remove the 'yfm_lenient' option for a stricter behavior.\nIgnored error: %s"
                ),
                $yamlres
            );
            my $len = ( scalar @saved_ctn ) - 1;
            while ( $len >= 0 ) {
                $self->unshiftline( $saved_ctn[ $len - 1 ], $saved_ctn[$len] );

                # print STDERR "Unshift ".$saved_ctn[ $len - 1] ." | ". $saved_ctn[$len] ."\n";
                $len -= 2;
            }
            return 0;    # Not a valid YAML
        } else {
            die wrap_mod(
                "po4a::text",
                dgettext(
                    "po4a",
                    "Could not get the YAML Front Matter from the file. If you did not intend to add a YAML front matter "
                      . "but an horizontal ruler, please use '----' instead, or pass the 'yfm_lenient' option.\nError: %s\nContent of the YFM: %s"
                ),
                $yamlres, $yfm
            );
        }
    }

    $self->handle_yaml(
        1, $blockref, $yamlarray,
        $self->{options}{yfm_keys},
        $self->{options}{yfm_skip_array},
        $self->{options}{yfm_paths}
    );
    $self->pushline("---\n");
    return 1;    # Valid YAML
}

1;

__END__

=head1 AUTHORS

 Nicolas François <nicolas.francois@centraliens.net>

=head1 COPYRIGHT AND LICENSE

 Copyright © 2005-2008 Nicolas FRANÇOIS <nicolas.francois@centraliens.net>.

 Copyright © 2008-2009, 2018 Jonas Smedegaard <dr@jones.dk>.
 Copyright © 2020 Martin Quinson <mquinson#debian.org>.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL v2.0 or later (see the COPYING file).

=cut
