# Locale::Po4a::Common -- Common parts of the po4a scripts and utils
# $Id: Common.pm,v 1.6 2005-03-03 16:04:40 mquinson Exp $
#
# Copyright 2005 by Jordi Vilalta <jvprat@wanadoo.es>
#
# This program is free software; you may redistribute it and/or modify it
# under the terms of GPL (see COPYING).
#
# This module has common utilities for the various scripts of po4a

=head1 NAME

Locale::Po4a::Common - Common parts of the po4a scripts and utils

=head1 DESCRIPTION

Locale::Po4a::Common contains common parts of the po4a scripts and some useful
functions used along the other modules.

=cut

package Locale::Po4a::Common;

require Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(wrap_msg wrap_mod wrap_ref_mod load_config);

use 5.006;
use strict;
use warnings;
use Locale::gettext;
use Text::WrapI18N qw(wrap $columns);
use Term::ReadKey qw(GetTerminalSize);

sub setcolumns {
    my ($col,$h,$cp,$hp);
    ($col,$h,$cp,$hp) = GetTerminalSize();
    $columns = $ENV{'COLUMNS'} || $col || 80;
#    print "set col to $columns\n";
}

sub min {
    return $_[0] < $_[1] ? $_[0] : $_[1];
}

=head1 FUNCTIONS

=head2 Showing output messages

=item show_version($)

Shows the current version of the script, and a short copyright message. It
takes the name of the script as an argument.

=cut

sub show_version {
    my $name = shift;

    print sprintf(gettext(
	"%s version %s.\n".
	"written by Martin Quinson and Denis Barbier.\n\n".
	"Copyright (C) 2002, 2003, 2004 Software of Public Interest, Inc.\n".
	"This is free software; see source code for copying\n".
	"conditions. There is NO warranty; not even for\n".
	"MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE."
	), $name, $Locale::Po4a::TransTractor::VERSION)."\n";
}

=item wrap_msg($@)

This function wraps a message handling the parameters like sprintf does.

=cut

sub wrap_msg {
    my $msg = shift;
    my @args = @_;
    
    setcolumns();
    return wrap("", "", sprintf($msg, @args))."\n";
}

=item wrap_mod($$@)

This function works like wrap_msg(), but it takes a module name as the first
argument, and leaves a space at the left of the message.

=cut

sub wrap_mod {
    my ($mod, $msg) = (shift, shift);
    my @args = @_;

    setcolumns();
    $mod .= ": ";
    my $spaces = " " x min(length($mod), 15);
    return wrap($mod, $spaces, sprintf($msg, @args))."\n";
}

=item wrap_ref_mod($$$@)

This function works like wrap_msg(), but it takes a file:line reference as the
first argument, a module name as the second one, and leaves a space at the left
of the message.

=cut

sub wrap_ref_mod {
    my ($ref, $mod, $msg) = (shift, shift, shift);
    my @args = @_;

    setcolumns();
    if (!$mod) {
	# If we don't get a module name, show the message like wrap_mod does
	return wrap_mod($ref, $msg, @args);
    } else {
	$ref .= ": ";
	my $spaces = " " x min(length($ref), 15);
	$msg = "$ref($mod)\n$msg";
	return wrap("", $spaces, sprintf($msg, @args))."\n";
    }
}

1;
__END__

=head1 AUTHORS

 Jordi Vilalta <jvprat@wanadoo.es>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by SPI, inc.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see the COPYING file).

=cut
