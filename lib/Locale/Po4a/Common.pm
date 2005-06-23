# Locale::Po4a::Common -- Common parts of the po4a scripts and utils
# $Id: Common.pm,v 1.9 2005-06-23 15:42:37 jvprat-guest Exp $
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
@EXPORT = qw(wrap_msg wrap_mod wrap_ref_mod textdomain gettext dgettext);

use 5.006;
use strict;
use warnings;
use Text::WrapI18N qw(wrap $columns);
use Term::ReadKey;

sub setcolumns {
    my ($col,$h,$cp,$hp);
    eval {
	($col,$h,$cp,$hp) = Term::ReadKey::GetTerminalSize(); 
    };
    if ($@) {
       # GetTerminalSize failed. Maybe a terminal-less build or such strange condition. Let's play safe.
       $col = 76;
    }
    $columns = $ENV{'COLUMNS'} || $col || 76;
#    print "set col to $columns\n";
}

sub min {
    return $_[0] < $_[1] ? $_[0] : $_[1];
}

=head1 FUNCTIONS

=head2 Wrappers for other modules

=item textdomain($)

This is a wrapper for Locale::gettext's textdomain() so that po4a still
works if that module is missing. This wrapper also calls
setlocale(LC_MESSAGES, "") so callers don't depend on the POSIX module either.

=cut

sub textdomain
{
    my ($domain)=@_;
    return eval "use Locale::gettext; use POSIX; setlocale(LC_MESSAGES, ''); textdomain(\$domain)";
}

=item gettext($)

This is a wrapper for Locale::gettext's gettext() so that things still
work ok if that module is missing.

=cut

sub gettext
{
    my ($str)=@_;
    my $rc=eval "use Locale::gettext; Locale::gettext::gettext(\$str)";
    return ($@ ? $str : $rc);
}

=item dgettext($$)

This is a wrapper for Locale::gettext's dgettext() so that things still
work ok if that module is missing.

=cut

sub dgettext
{
    my ($domain, $str)=@_;
    my $rc=eval "use Locale::gettext; dgettext(\$domain, \$str)";
    return ($@ ? $str : $rc);
}

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
