# Locale::Po4a::Pod -- Convert POD data to PO file, for translation.
#
# This program is free software; you may redistribute it and/or modify it
# under the terms of GPL v2.0 or later (see COPYING file).
#
# This module converts POD to PO file, so that it becomes possible to
# translate POD formatted documentation. See gettext documentation for
# more info about PO files.

############################################################################
# Modules and declarations
############################################################################

use Pod::Parser;
use Locale::Po4a::TransTractor qw(process new get_in_charset get_out_charset);

package Locale::Po4a::Pod;

use 5.16.0;
use strict;
use warnings;

require Exporter;

use vars qw(@ISA);
@ISA = qw(Locale::Po4a::TransTractor Pod::Parser);

use Carp qw(croak confess);

use Locale::Po4a::Common;

sub initialize { }

sub translate {
    my ( $self, $str, $ref, $type ) = @_;
    my (%options) = @_;

    $str = $self->pre_trans( $str, $ref, $type );
    $str = $self->SUPER::translate( $str, $ref, $type, %options );
    $str = $self->post_trans( $str, $ref, $type );

    return $str;
}

sub pre_trans {
    my ( $self, $str, $ref, $type ) = @_;

    return $str;
}

sub post_trans {
    my ( $self, $str, $ref, $type ) = @_;

    # Change ascii non-breaking space to POD one
    my $nbs_out    = "\xA0";
    my $enc_length = Encode::from_to( $nbs_out, "latin1", $self->get_out_charset );
    if ( defined $enc_length ) {
        while ( $str =~ m/(^|.*\s)(\S+?)\Q$nbs_out\E(\S+?)(\s.*$|$)/s ) {
            my ( $begin, $m1, $m2, $end ) = ( $1, $2, $3, $4 );
            $str = ( defined $begin ) ? $begin : "";

            # Remove the non-breaking spaces in the string that will be
            # between S<...>
            $m2 =~ s/\Q$nbs_out\E/ /g;
            $str .= "S<$m1 $m2>";
            $str .= ( defined $end ) ? $end : "";
        }
    }

    return $str;
}

sub command {
    my ( $self, $command, $paragraph, $line_num ) = @_;

    #    print STDOUT "cmd: '$command' '$paragraph' at $line_num\n";
    if (   $command eq 'back'
        || $command eq 'cut'
        || $command eq 'pod' )
    {
        $self->pushline("=$command\n\n");
    } elsif ( $command eq 'over' ) {
        $self->pushline( "=$command $paragraph" . ( length($paragraph) ? "" : "\n\n" ) );
    } elsif ( $command eq 'encoding' ) {
        my $charset = $paragraph;
        $charset =~ s/^\s*(.*?)\s*$/$1/s;

        my $master_charset = $self->get_in_charset;

        # in POD at least, there is no difference between utf8 and UTF-8. The major POD parsers handle "both encodings" in the exact same way.
        # Despite https://perldoc.perl.org/Encode#UTF-8-vs.-utf8-vs.-UTF8
        $master_charset = 'UTF-8' if $master_charset // '' =~ /utf-?8/i;
        $charset        = 'UTF-8' if $charset              =~ /utf-?8/i;

        if ( length( $master_charset // '' ) > 0 && uc($charset) ne uc($master_charset) ) {
            croak wrap_mod(
                "po4a::pod",
                dgettext(
                    "po4a",
                    "The file %s declares %s as encoding, but you provided %s as master charset. Please change either setting."
                ),
                $self->{DOCPOD}{refname},
                $charset,
                $master_charset,
            );
        }

        # The =encoding line will be added by docheader
    } else {
        $paragraph = $self->translate( $paragraph, $self->{DOCPOD}{refname} . ":$line_num", "=$command", "wrap" => 1 );
        $self->pushline("=$command $paragraph\n\n");
    }
}

sub verbatim {
    my ( $self, $paragraph, $line_num ) = @_;

    #    print "verb: '$paragraph' at $line_num\n";

    if ( $paragraph eq "\n" ) {
        $self->pushline("$paragraph\n");
        return;
    }
    $paragraph = $self->translate( $paragraph, $self->{DOCPOD}{refname} . ":$line_num", "verbatim" );
    $paragraph =~ s/\n$//m;
    $self->pushline("$paragraph\n");
}

sub textblock {
    my ( $self, $paragraph, $line_num ) = @_;

    #    print "text: '$paragraph' at $line_num\n";

    if ( $paragraph eq "\n" ) {
        $self->pushline("$paragraph\n");
        return;
    }

    # Fix a pretty damned bug.
    # Podlators don't wrap explicitelly the text, and groff won't seem to
    #  wrap any line begining with a space. So, we have to consider as
    #  verbatim not only the paragraphs whose first line is indented, but
    #  the paragraph containing an indented line.
    # That way, we'll declare more paragraphs as verbatim than needed, but
    #  that's harmless (only less confortable for translators).
    if ( $paragraph =~ m/^[ \t]/m ) {
        $self->verbatim( $paragraph, $line_num );
        return;
    }

    $paragraph = $self->translate( $paragraph, $self->{DOCPOD}{refname} . ":$line_num", 'textblock', "wrap" => 1 );
    $paragraph =~ s/ *\n/ /gm;    # Unwrap the content, to ensure that C<> markup is not split on several lines
    $self->pushline("$paragraph\n\n");
}

sub end_pod { }

sub read {
    my ( $self, $filename, $refname, $charset ) = @_;
    $charset ||= "UTF-8";
    my $fh;
    open $fh, "<:encoding($charset)", $filename;
    push @{ $self->{DOCPOD}{infile} }, ( $fh, $refname );
    $self->Locale::Po4a::TransTractor::read( $filename, $refname, $charset );
}

sub parse {
    my $self = shift;

    my @list = @{ $self->{DOCPOD}{infile} };
    while ( scalar @list ) {
        my ( $fh, $refname ) = ( shift @list, shift @list );
        $self->{DOCPOD}{refname} = $refname;
        $self->parse_from_filehandle($fh);
        close $fh;
    }
}

sub docheader {
    my $self     = shift;
    my $encoding = $self->get_out_charset();
    if (    ( defined $encoding )
        and ( length $encoding )
        and ( $encoding ne "ascii" ) )
    {
        $encoding = "\n=encoding $encoding\n";
    } else {
        $encoding = "";
    }

    return <<EOT;

        *****************************************************
        *           GENERATED FILE, DO NOT EDIT             *
        * THIS IS NO SOURCE FILE, BUT RESULT OF COMPILATION *
        *****************************************************

This file was generated by po4a(7). Do not store it (in VCS, for example),
but store the PO file used as source file by po4a-translate.

In fact, consider this as a binary, and the PO file as a regular .c file:
If the PO get lost, keeping this translation up-to-date will be harder.
$encoding
EOT
}
1;

##############################################################################
# Module return value and documentation
##############################################################################

1;
__END__

=encoding UTF-8

=head1 NAME

Locale::Po4a::Pod - convert POD data from/to PO files

=head1 SYNOPSIS

    use Locale::Po4a::Pod;
    my $parser = Locale::Po4a::Pod->new();

    # Read POD from STDIN and write to STDOUT.
    $parser->parse_from_filehandle;

    # Read POD from file.pod and write to file.txt.
    $parser->parse_from_file ('file.pod', 'file.txt');

=head1 DESCRIPTION

Locale::Po4a::Pod is a module to help the translation of documentation in
the POD format (the preferred language for documenting Perl) into other
[human] languages.

=head1 STATUS OF THIS MODULE

I think that this module is rock stable, and there is only one known bug
with F</usr/lib/perl5/Tk/MainWindow.pod> (and some other
pages, see below) which contains:

  C<" #n">

Lack of luck, in the po4a version, this was split on the space by the
wrapping. As result, in the original version, the man page contains:

 " #n"

and mine contains:

 "" #n""

which is logic since CE<lt>foobarE<gt> is rewritten "foobar".

Complete list of pages having this problem on my box (from 564 pages; note
that it depends on the chosen wrapping column):

 /usr/lib/perl5/Tk/MainWindow.pod
 /usr/share/perl/5.8.0/overload.pod
 /usr/share/perl/5.8.0/pod/perlapi.pod
 /usr/share/perl/5.8.0/pod/perldelta.pod
 /usr/share/perl/5.8.0/pod/perlfaq5.pod
 /usr/share/perl/5.8.0/pod/perlpod.pod
 /usr/share/perl/5.8.0/pod/perlre.pod
 /usr/share/perl/5.8.0/pod/perlretut.pod



=head1 INTERNALS

As a derived class from Pod::Parser, Locale::Po4a::Pod supports the same
methods and interfaces.  See L<Pod::Parser> for all the details; briefly,
one creates a new parser with C<< Locale::Po4a::Pod->new() >> and then
calls either parse_from_filehandle() or parse_from_file().

=head1 SEE ALSO

L<Pod::Parser>,
L<Locale::Po4a::Man(3pm)>,
L<Locale::Po4a::TransTractor(3pm)>,
L<po4a(7)|po4a.7>

=head1 AUTHORS

 Denis Barbier <barbier@linuxfr.org>
 Martin Quinson (mquinson#debian.org)

=head1 COPYRIGHT AND LICENSE

Copyright © 2002 SPI, Inc.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL v2.0 or later (see the COPYING file).

=cut
