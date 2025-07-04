package Locale::Po4a::SimplePod;

use 5.16.0;
use strict;
use warnings;

use parent qw(Locale::Po4a::TransTractor);

use Locale::Po4a::SimplePod::Parser;

sub initialize {
    my ( $self, %options ) = @_;
    $self->SUPER::initialize(%options);
    $self->{parser} = Locale::Po4a::SimplePod::Parser->new($self);
}

sub read {
    my ( $self, $filename, $refname, $charset ) = @_;
    push @{ $self->{inputs} }, { file => $filename, ref => $refname };
}

sub parse {
    my $self = shift;
    for my $input ( @{ $self->{inputs} } ) {
        $self->{parser}->{current_ref} = $input->{ref};
        $self->{parser}->parse_file( $input->{file} );
    }
}

# We cannot use =begin since parsing this file with POD parser might cause
# some troubles.
sub docheader {
    return "
        *****************************************************
        *           GENERATED FILE, DO NOT EDIT             *
        * THIS IS NO SOURCE FILE, BUT RESULT OF COMPILATION *
        *****************************************************

This file was generated by po4a(7). Do not store it (in VCS, for example),
but store the PO file used as source file by po4a-translate.

In fact, consider this as a binary, and the PO file as a regular .c file:
If the PO get lost, keeping this translation up-to-date will be harder.

=encoding UTF-8
"
}

1;

__END__

=head1 NAME

Locale::Po4a::SimplePod - convert POD data from/to PO files, with Pod::Simple

=head1 SYNOPSIS

  [po4a_paths] /path/to/pot $lang:/path/to/po
  [type:SimplePod] /path/to/source.pod $lang:/path/to/localized.pod

or

  [po4a_paths] /path/to/pot $lang:/path/to/po
  [po4a_alias:pod] SimplePod
  [type:pod] /path/to/source.pod $lang:/path/to/localized.pod

=head1 DESCRIPTION

This is a module to help the translation of documentation in the POD format
(the preferred language for documenting Perl) into other human languages.

The main differences between the current Pod format and the SimplePod format
are as follows:

=over

=item *

SimplePod format never includes additional newlines in messages to be
translated.  The current Pod format, however, may contain extra newlines,
particularly in verbatim message entries.

=item *

Paragraphs may be rendered with line wrapping.  The L<Pod::Parser> module
might apply special handling for line wrapping, making it difficult to
replicate with L<Pod::Simple>.  However, L<Pod::Simple> appears to produce a
more natural output.

=item *

In SimplePod, the C<=for> message (e.g., C<=for comment text>) does not
include a format name (such as C<comment>), so the message consists solely of
text.  In contrast, the current Pod format retains the format name, resulting
in a message like C<comment text>.  The former behavior is considered more
comfortable for translators.

=item *

Entries like the one below, which denote C<=end comment>, are no longer
present as seen in the current Pod module.  Since these are not translatable
messages, their absence is an improvement.

  #. type: =end
  #: sample.pod:10
  msgid "comment"
  msgstr ""

=item *

Text blocks whose POD format validity is uncertain are now treated as
C<no-wrap>.  This applies, for example, to the content within a C<=begin html>
block.  In the Pod module, these were not treated as C<no-wrap>, which
sometimes resulted in line wrapping.

=item *

The C<=begin> parameter section is no longer subject to translation.  In the
current Pod module, it is included.  If there is a demand to include it in
translation, please report it.

=back

=head1 STATUS OF THIS MODULE

This module is still newly developed, so it is less stable than
L<Locale::Po4a::Pod>.  It continues to evolve, and there is room for further
refinement.  Its behavior might change over time, and additional options may
be introduced to better optimize the translation experience for users.
Feedback and use cases from real-world applications will play a key role in
guiding its future development.

The code is fully covered by our test suite, and we're not aware of any
existing bugs.  However, as of 2025, it hasn't been battle-tested in
real-world translation workflows by external projects.  That said, we believe
the module is ready for production use, even if some bugs may inevitably be
discovered as it gains wider adoption.

This module is intended to replace the current L<Locale::Po4a::Pod> module.
The reason is that L<Pod::Parser>, which is used by the current
L<Locale::Po4a::Pod>, is now deprecated, and it is recommended to use
L<Pod::Simple> instead.  See also L<GitHub issue #256 "Consider migrating away
from deprecated C<Pod::Parser>"|https://github.com/mquinson/po4a/issues/256>.

=head1 SEE ALSO

L<Pod::Simple>, L<Locale::Po4a::Pod>, L<Locale::Po4a::TransTractor>,
L<po4a(7)|po4a.7>, L<Locale::Po4a::SimplePod::Parser>.

=head1 AUTHORS

  gemmaro <gemmaro.dev@gmail.com>

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2025 gemmaro <gemmaro.dev@gmail.com>.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL v2.0 or later (see the COPYING file).
