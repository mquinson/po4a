package Locale::Po4a::SimplePod::Parser;

use 5.16.0;
use strict;
use warnings;

use parent qw(Pod::Simple);

use Locale::Po4a::Common qw(wrap_mod dgettext);

sub new {
    my ( $class, $tractor ) = @_;
    my $self = $class->SUPER::new();
    $self->accept_targets('*');    # handle =for or =begin too
    $self->preserve_whitespace(1);
    $self->abandon_output_fh;
    $self->_output_is_for_JustPod(1);    # set ~bracket_count attribute
    $self->{tractor} = $tractor;
    return $self;
}

sub _handle_element_start {
    my ( $self, $name, $attrs ) = @_;
    if ( $name eq "Document" ) {
        push @{ $self->{elements} }, { name => $name };
        $self->{text} and die;

    } elsif ( $name =~ /\Ahead[1-6]\Z/m ) {
        push @{ $self->{elements} }, { name => $name, line => $attrs->{start_line} };
        $self->{tractor}->pushline("=head1 ");
        $self->{text} and die;

    } elsif ( $name =~ /\Aover-(block|bullet|number|text)\Z/ ) {
        push @{ $self->{elements} }, { name => $name };
        $self->{tractor}->pushline("=over $attrs->{indent}\n\n");
        $self->{text} and die;

    } elsif ( $name eq "item-bullet" ) {
        push @{ $self->{elements} }, { name => $name, line => $attrs->{start_line} };
        $self->{tractor}->pushline("=item *\n\n");
        $self->{text} and die;

    } elsif ( $name eq "item-number" ) {
        push @{ $self->{elements} }, { name => $name, line => $attrs->{start_line} };
        $self->{tractor}->pushline("=item $attrs->{number}\n\n");
        $self->{text} and die;

    } elsif ( $name eq "item-text" ) {
        push @{ $self->{elements} }, { name => $name, line => $attrs->{start_line} };
        $self->{tractor}->pushline("=item ");
        $self->{text} and die;

    } elsif ( $name eq "for" ) {
        if ( $attrs->{'~really'} eq "=for" ) {
            push @{ $self->{elements} }, { name => $name };
            $self->{tractor}->pushline("=for $attrs->{target}\n");
            $self->{text} and die;

        } elsif ( $attrs->{'~really'} eq "=begin" ) {
            push @{ $self->{elements} }, { name => "begin", target => $attrs->{target} };
            my $rest = $attrs->{title} ? " $attrs->{title}\n\n" : "\n\n";
            $self->{tractor}->pushline("=begin $attrs->{target}$rest");
            $self->{text} and die;

        } else {
            die "unreachable";
        }

    } elsif ( $name =~ m/\A(Para|Verbatim|Data)\Z/ ) {
        push @{ $self->{elements} }, { name => $name, line => $attrs->{start_line} };
        $self->{text} and die;

    } elsif ( $name =~ m/[BCFISUXEZ]/ ) {
        $self->push_formatting_code( $name, $attrs );

    } elsif ( $name eq "L" ) {
        $self->push_formatting_code( $name, $attrs );
        $self->{text} .= $attrs->{'raw'};

    } else {
        die "unexpected name $name";
    }
}

sub push_formatting_code {
    my ( $self, $name, $attrs ) = @_;
    my $count    = $attrs->{'~bracket_count'} // 1;
    my $lbracket = "<" x $count;
    my $rbracket = ">" x $count;
    my $rspacer  = $count > 1 ? $attrs->{'~rspacer'} // " " : "";
    push @{ $self->{elements} }, { name => $name, bracket => "$rspacer$rbracket" };
    my $lspacer = $count > 1 ? $attrs->{'~lspacer'} // " " : "";
    $self->{text} .= "$name$lbracket$lspacer";
}

sub _handle_element_end {
    my ( $self, $name ) = @_;
    if (
        $name =~ m{\A
                   ( Para
                   | head[1-6]
                   | item-(bullet|number|text)
                   )
                   \Z}xms
      )
    {
        my $element = $self->pop_last_element_and_validate($name);

        # Fix a pretty damned bug.
        #
        # Podlators don't wrap explicitelly the text, and groff won't seem to
        # wrap any line begining with a space.  So, we have to consider as
        # verbatim not only the paragraphs whose first line is indented, but
        # the paragraph containing an indented line.
        #
        # That way, we'll declare more paragraphs as verbatim than needed, but
        # that's harmless (only less confortable for translators).
        my $wrap = $self->{text} !~ m/^[ \t]/m;

        my $text = $self->translate( $element->{line}, $name, $wrap );
        $self->{tractor}->pushline("$text\n\n");

    } elsif ( $name =~ m/\A(Verbatim|Data)\Z/ ) {
        my $element = $self->pop_last_element_and_validate($name);
        my $text = $self->translate( $element->{line}, $name );
        $self->{tractor}->pushline("$text\n\n");

    } elsif ( $name =~ m/\Aover-(block|bullet|number|text)\Z/ ) {
        $self->pop_last_element_and_validate($name);
        $self->{tractor}->pushline("=back\n\n");

    } elsif ( $name eq "for" ) {
        my $element   = pop @{ $self->{elements} };
        my $last_name = $element->{name};
        if ( $last_name eq "for" ) {

            # nop

        } elsif ( $last_name eq "begin" ) {
            $self->{tractor}->pushline("=end $element->{target}\n\n");

        } else {
            die "unreachable";
        }

    } elsif ( $name =~ m/\A[LBCFISUXEZ]\Z/ ) {
        $self->{text} .= $self->pop_last_element_and_validate($name)->{bracket};

    } elsif ( $name eq "Document" ) {
        $self->pop_last_element_and_validate($name);

    } else {
        die "unreachable";
    }
}

sub translate {
    my ( $self, $line, $type, $wrap ) = @_;
    my $ref = "$self->{source_filename}:$line";
    my $text = $self->{tractor}->translate( $self->{text}, $ref, $type, wrap => $wrap );
    undef $self->{text};
    return $text;
}

sub pop_last_element_and_validate {
    my ( $self, $name ) = @_;
    my $element   = pop @{ $self->{elements} };
    my $last_name = $element->{name};
    ( $last_name eq $name ) or die "$last_name ne $name";
    return $element;
}

sub _handle_text {
    my ( $self, $text ) = @_;
    my $last_name = $self->{elements}[-1]->{name};
    if (
        $last_name =~ m{\A
                        ( Para
                        | Verbatim
                        | Data
                        | head[1-6]
                        | item-(bullet|number|text)
                        | [BCFISUXEZ]
                        )
                        \Z}xms
      )
    {
        $self->{text} .= $text;

    } elsif ( $last_name eq "L" ) {

        # nop since we used the raw attribute

    } else {
        die "unreachable";
    }
}

1;

__END__

=head1 NAME

Locale::Po4a::SimplePod::Parser - helper module to parse POD

=head1 DESCRIPTION

This module serves as a helper for L<Locale::Po4a::SimplePod> and is not meant
to be used directly by end users, such as translators.

TODO:
Reference the L<manpage/"section">
の閉じブラケットが消える。

=head1 SEE ALSO

L<Pod::Simple>, L<Locale::Po4a::SimplePod>.

=head1 AUTHORS

  gemmaro <gemmaro.dev@gmail.com>

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2025 gemmaro <gemmaro.dev@gmail.com>.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL v2.0 or later (see the COPYING file).
