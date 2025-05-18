package Locale::Po4a::SimplePod::Parser;

use 5.16.0;
use strict;
use warnings;

use parent qw(Pod::Simple);

use Locale::Po4a::Common qw(wrap_mod dgettext);
use Carp qw(confess);

use constant MODULE_NAME => "po4a::simplepod";

sub new {
    my ( $class, $tractor ) = @_;
    my $self = $class->SUPER::new;
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
        $self->{text} and die $self->unexpected_error;    # [1]
        push @{ $self->{elements} }, { name => $name };

    } elsif ( $name =~ /\Ahead[1-6]\Z/m ) {
        $self->{text} and die $self->unexpected_error;    # [1]
        push @{ $self->{elements} }, { name => $name, line => $attrs->{start_line} };
        $self->{tractor}->pushline("\n=$name ");

    } elsif ( $name =~ /\Aover-(block|bullet|number|text)\Z/ ) {
        $self->{text} and die $self->unexpected_error;    # [1]
        push @{ $self->{elements} }, { name => $name };
        my $content = $attrs->{'~orig_content'} ? " $attrs->{'~orig_content'}" : "";
        $self->{tractor}->pushline("\n=over$content\n");

    } elsif ( $name eq "item-bullet" ) {
        $self->{text} and die $self->unexpected_error;    # [1]
        push @{ $self->{elements} }, { name => $name, line => $attrs->{start_line} };

        # Even if ~type is bullet, ~orig_content may be empty.  Therefore, it
        # cannot be predetermined as "*".
        my $bullet = $attrs->{'~orig_content'} ? " $attrs->{'~orig_content'}" : "";

        $self->{tractor}->pushline("\n=item$bullet\n\n");

    } elsif ( $name eq "item-number" ) {
        $self->{text} and die $self->unexpected_error;    # [1]
        push @{ $self->{elements} }, { name => $name, line => $attrs->{start_line} };

        # $attrs->{number} cannot handle patterns like '1.'.
        $self->{tractor}->pushline("\n=item $attrs->{'~orig_content'}\n\n");

    } elsif ( $name eq "item-text" ) {
        $self->{text} and die $self->unexpected_error;    # [1]
        push @{ $self->{elements} }, { name => $name, line => $attrs->{start_line} };
        $self->{tractor}->pushline("\n=item ");

    } elsif ( $name eq "for" ) {
        $self->{text} and die $self->unexpected_error;    # [1]
        if ( $attrs->{'~really'} eq "=for" ) {

            # This is for deciding the following 2 cases:
            #
            #   =for format-name foo
            #
            # and
            #
            #   =for format-name
            #   foo
            #
            my $line = $attrs->{start_line};

            push @{ $self->{elements} }, { name => $name, line => $line };
            $self->{tractor}->pushline("\n=for $attrs->{target}");

        } elsif ( $attrs->{'~really'} eq "=begin" ) {
            push @{ $self->{elements} }, { name => "begin", target => $attrs->{target} };
            my $rest = $attrs->{title} ? " $attrs->{title}\n" : "\n";
            $self->{tractor}->pushline("\n=begin $attrs->{target}$rest");

        } else {
            die $self->unexpected_error;
        }

    } elsif ( $name =~ m/\A(Para|Verbatim|Data)\Z/ ) {
        $self->{text} and die $self->unexpected_error;    # [1]
        my $last_element = $self->{elements}[-1];
        my $pre = ( $last_element->{name} eq "for" and $last_element->{line} == $attrs->{start_line} ) ? " " : "\n";
        $self->{tractor}->pushline($pre);
        push @{ $self->{elements} }, { name => $name, line => $attrs->{start_line} };

    } elsif ( $name =~ m/[BCFISUXEZ]/ ) {
        $self->push_formatting_code( $name, $attrs ) unless $self->{in_hyperlink};

    } elsif ( $name eq "L" ) {
        $self->push_formatting_code( $name, $attrs );
        $self->{text} .= $attrs->{'raw'};

        # Check whether it's inside a hyperlink.  Alternatively, you can use
        # $self->{elements} to determine if they contain any hyperlink
        # formatting code, but this approach is quite slow.
        $self->{in_hyperlink} += 1;

    } else {
        $self->unsupported_element_name($name);
    }
}

# [1] The parser encountered an extra text attribute value, which should not
# be present.  The parser was expected to clean up text attributes when it
# detected a block end.

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
    if ( $name =~ m{\Ahead[1-6]\Z}xms ) {
        my $text = $self->translate_block( $self->pop_last_element($name)->{line}, "=$name", 1 );
        $self->{tractor}->pushline("$text\n");

    } elsif ( $name =~ m{\Aitem-(bullet|number|text)\Z}xms ) {
        my $text = $self->translate_block( $self->pop_last_element($name)->{line}, "=item", 1 );
        $self->{tractor}->pushline("$text\n");

    } elsif ( $name eq "Para" ) {
        my $element = $self->pop_last_element($name);

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

        my $text = $self->translate_block( $element->{line}, $wrap ? "textblock" : "verbatim", $wrap );
        $self->{tractor}->pushline("$text\n");

    } elsif ( $name eq "Verbatim" ) {
        my $text = $self->translate_block( $self->pop_last_element($name)->{line}, "verbatim" );
        $self->{tractor}->pushline("$text\n");

    } elsif ( $name eq "Data" ) {
        my $type;
        my $previous_element = $self->{elements}[-2]->{name};
        if ( $previous_element eq "for" ) {
            $type = "=for";
        } elsif ( $previous_element eq "begin" ) {
            $type = "textblock";
        } else {
            $self->{tractor}->debug and warn wrap_mod( MODULE_NAME, "Previous element name is $previous_element." );
            die $self->unexpected_error;
        }
        my $text = $self->translate_block( $self->pop_last_element($name)->{line}, $type );
        $self->{tractor}->pushline("$text\n");

    } elsif ( $name =~ m/\Aover-(block|bullet|number|text)\Z/ ) {
        $self->pop_last_element($name);
        $self->{tractor}->pushline("\n=back\n");

    } elsif ( $name eq "for" ) {
        my $element   = pop @{ $self->{elements} };
        my $last_name = $element->{name};
        if ( $last_name eq "for" ) {

            # nop

        } elsif ( $last_name eq "begin" ) {
            $self->{tractor}->pushline("\n=end $element->{target}\n");

        } else {
            die $self->unexpected_error;
        }

    } elsif ( $name eq "L" ) {
        $self->{text} .= $self->pop_last_element($name)->{bracket};
        $self->{in_hyperlink} -= 1;

    } elsif ( $name =~ m/\A[BCFISUXEZ]\Z/ ) {
        $self->{text} .= $self->pop_last_element($name)->{bracket} unless $self->{in_hyperlink};

    } elsif ( $name eq "Document" ) {
        $self->pop_last_element($name);

    } else {
        $self->unsupported_element_name($name);
    }
}

sub translate_block {
    my ( $self, $line, $type, $wrap ) = @_;
    my $ref = "$self->{source_filename}:$line";
    my $text = $self->{tractor}->translate( $self->{text}, $ref, $type, wrap => $wrap );
    undef $self->{text};
    return $text;
}

sub pop_last_element {
    my ( $self, $name ) = @_;
    my $element   = pop @{ $self->{elements} };
    my $last_name = $element->{name};
    unless ( $last_name eq $name ) {
        $self->{tractor}->debug
          and
          warn wrap_mod( MODULE_NAME, "The last element name is $last_name, but the current element name is $name." );
        die $self->unexpected_error;
    }

    return $element;
}

sub _handle_text {
    my ( $self, $text ) = @_;
    my $last_name = $self->{elements}[-1]->{name};
    if ( $self->{in_hyperlink} ) {

        # nop since we used the raw attribute

    } elsif (
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

    } else {
        die $self->unexpected_error;
    }
}

sub unexpected_error {
    my $self = shift;
    $self->{tractor}->debug and confess();
    return wrap_mod( MODULE_NAME,
        dgettext( "po4a", "An unexpected error has occurred.  Please report this issue to the po4a project." ) );
}

sub unsupported_element_name {
    my ( $self, $name ) = @_;
    $self->{tractor}->debug and warn wrap_mod( MODULE_NAME, "Unsupported element name %s.", $name );
    die $self->unexpected_error;
}

1;

__END__

=head1 NAME

Locale::Po4a::SimplePod::Parser - helper module to parse POD

=head1 DESCRIPTION

This module serves as a helper for L<Locale::Po4a::SimplePod> and is not meant
to be used directly by end users, such as translators.

=head1 TODO

Stripping indentation from verbatim blocks could be useful.  I'm considering
using the C<strip_verbatim_indent> function to control this behavior.

=head1 SEE ALSO

This module is based on L<Pod::Simple::JustPod>, which performs an identity
transformation from POD I<to POD>.  That module is particularly useful for
understanding how to serialize parsed POD document events into the POD file
format.

For a foundational overview of the library, see L<Pod::Simple>.  Additionally,
L<Locale::Po4a::SimplePod> utilizes this module within po4a.

=head1 AUTHORS

  gemmaro <gemmaro.dev@gmail.com>

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2025 gemmaro <gemmaro.dev@gmail.com>.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL v2.0 or later (see the COPYING file).
