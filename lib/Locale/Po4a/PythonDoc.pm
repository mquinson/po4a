#!/usr/bin/perl -w

# Copyright (c) 2004 by Nicolas FRANÇOIS <nicolas.francois@centraliens.net>
#
# This file is part of po4a.
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
# along with Foobar; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
########################################################################

=head1 NAME

Locale::Po4a::PythonDoc - 

=head1 SEE ALSO

L<po4a(7)|po4a.7>,
L<Locale::Po4a::TransTractor(3pm)|Locale::Po4a::TransTractor>,
L<Locale::Po4a::TeX(3pm)|Locale::Po4a::TeX>.

=head1 AUTHORS

 Nicolas François <nicolas.francois@centraliens.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Nicolas FRANÇOIS <nicolas.francois@centraliens.net>.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see COPYING file).

=cut

package Locale::Po4a::PythonDoc;

use 5.006;
use strict;
use warnings;

require Exporter;
use vars qw($VERSION @ISA @EXPORT);
$VERSION=$Locale::Po4a::TeX::VERSION;
@ISA = qw(Locale::Po4a::TeX);
@EXPORT = qw();

use Locale::Po4a::TeX;
use subs qw(&untranslated     &translate_joined
            &push_environment &parse_definition_file);
*untranslated          = \&Locale::Po4a::TeX::untranslated;
*translate_joined      = \&Locale::Po4a::TeX::translate_joined;
*push_environment      = \&Locale::Po4a::TeX::push_environment;
*parse_definition_file = \&Locale::Po4a::TeX::parse_definition_file;
use vars qw($RE_ESCAPE            $ESCAPE
            $no_wrap_environments $separated_commands
            %commands             %environments
            %command_categories   %separated
            @exclude_include);
*RE_ESCAPE             = \$Locale::Po4a::TeX::RE_ESCAPE;
*ESCAPE                = \$Locale::Po4a::TeX::ESCAPE;
*no_wrap_environments  = \$Locale::Po4a::TeX::no_wrap_environments;
*separated_commands    = \$Locale::Po4a::TeX::separated_commands;
*commands              = \%Locale::Po4a::TeX::commands;
*environments          = \%Locale::Po4a::TeX::environments;
*command_categories    = \%Locale::Po4a::TeX::command_categories;
*separated             = \%Locale::Po4a::TeX::separated;
*exclude_include       = \@Locale::Po4a::TeX::exclude_include;

push @exclude_include, qw(ref.ind boilerplate copyright ref6 ref5 license);
# TODO: indexii, The 2 parameters should not be separated,
#                if order to change the order.

$separated_commands .= " section chapter subsection ttindex item begin end".
    " stindex withsubitem bifuncindex indexii obindex indexiii footnote".
    " lineiv lineiii title ifhtml fi documentclass usepackage makeindex".
    " maketitle tableofcontents lineii refbimodindex input production".
    " kwindex";

$command_categories{'untranslated'} .= " makeindex maketitle ifhtml fi".
    " noindent tableofcontents appendix today release setreleaseinfo".
    " setshortversion ASCII e keyword hline kwindex version usepackage".
    " documentclass";

$command_categories{'translate_joined'} .= " title author authoraddress".
    " strong email date production productioncont token item code note".
    " lineiii var dfn indexii indexiii obindex withsubitem ttindex".
    " bifuncindex stindex member versionchanged versionadded samp".
    " exindex deprecated footnote opindex lineii optional refbimodindex".
    " seepep warning linev centerline input lineiv module function methodline".
    " emph";

$environments{'abstract'}  = $environments{'productionlist'} =
$environments{'seealso'}   = $environments{'description'} =
$environments{'itemize'}   = $environments{'methoddesc'} =
$environments{'notice'}    = $environments{'datadesc'} =
$environments{'tableii'}   = $environments{'tableiii'} =
$environments{'tableiv'}   = $environments{'tablev'} =
$environments{'enumerate'} =
    \&push_environment;

