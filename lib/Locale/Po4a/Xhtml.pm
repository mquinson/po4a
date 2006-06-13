#!/usr/bin/perl

# Po4a::Xhtml.pm 
# 
# extract and translate translatable strings from Xhtml documents.
# 
# This code extracts plain text from tags and attributes from strict Xhtml
# documents.
#
# Copyright (c) 2005 by Yves Rütschlé <po4a@rutschle.net>
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
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
########################################################################

=head1 NAME

Locale::Po4a::Xhtml - Convert Xhtml documents from/to PO files

=head1 DESCRIPTION

The goal of the po4a (po for anything) project is to ease translations (and
more interestingly, the maintenance of translations) using gettext tools on
areas where they were not originally expected like documentation.

Locale::Po4a::Xhtml is a module to help the translation of Xhtml documents into
other [human] languages.

Please note that this module is still experimental. It is not distributed in
the official po4a releases since we don't feel it to be mature enough. If you
insist on trying, check the CVS out.

=head1 STATUS OF THIS MODULE

This module is fully functional, as it relies in the L<Locale::Po4a::Xml>
module. This only defines the translatable tags and attributes.

It is derived from Jordi's DocBook module.

"It works for me", which means I use it successfully on my personal Web site.
However, YMMV: please let me know if something doesn't work for you. In
particular, tables are getting no testing whatsoever, as we don't use them.

=head1 SEE ALSO

L<po4a(7)|po4a.7>, L<Locale::Po4a::TransTractor(3pm)>, L<Locale::Po4a::Xml(3pm)>.

=head1 AUTHORS

 Yves Rütschlé <po4a@rutschle.net>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004 by Yves Rütschlé <po4a@rutschle.net>

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see the COPYING file).

=cut

package Locale::Po4a::Xhtml;

use 5.006;
use strict;
use warnings;

use Locale::Po4a::Xml;

use vars qw(@ISA);
@ISA = qw(Locale::Po4a::Xml);

sub initialize {
	my $self = shift;
	my %options = @_;

	$self->SUPER::initialize(%options);
	$self->{options}{'wrap'}=1;
        $self->{options}{'doctype'}=$self->{options}{'doctype'} || 'html';

	$self->{options}{'inline'}.='
                <a> 
                <object> 
                <br> 
                <span> 
                <bdo> 
                <map> 
                <tt> 
                <i> 
                <b> 
                <big> 
                <small> 
                <em> 
                <strong> 
                <dfn> 
                <code> 
                <q> 
                <samp> 
                <kbd> 
                <var> 
                <cite> 
                <abbr> 
                <acronym> 
                <sub> 
                <sup> 
                <input> 
                <select> 
                <textarea> 
                <label> 
                <button> 
                <ins> 
                <del>
	';

        # Ignored tags: <img>
        # Technically, <img> is an inline tag, but setting it as such is
        # annoying, and not usually useful, unless you use images to
        # write text (in which case you have bigger problems than this
        # program not inlining img: you now have to translate all your
        # images. That'll teach you).

	$self->{options}{'attributes'}.='
		lang
                alt
                title
                ';
	$self->treat_options;
}
