# Locale::Po4a::Pod -- Convert POD data to PO file, for translation.
# $Id: Chooser.pm,v 1.3 2003-01-23 09:45:32 mquinson Exp $
#
# Copyright 2002 by Martin Quinson <Martin.Quinson@ens-lyon.fr>
#
# This program is free software; you may redistribute it and/or modify it
# under the terms of GPL (see COPYING).
#
# This module converts POD to PO file, so that it becomes possible to 
# translate POD formated documentation. See gettext documentation for
# more info about PO files.

############################################################################
# Modules and declarations
############################################################################


package Locale::Po4a::Chooser;
use strict;
require Exporter;

use vars qw($VERSION @ISA @EXPORT $AUTOLOAD);
$VERSION = $Locale::Po4a::TransTractor::VERSION;
@ISA = qw();
@EXPORT = qw(new list);

use Locale::gettext;

sub new {
    my ($module)=shift;
    my (%options)=@_;

    if (lc($module) eq 'kernelhelp') {
	return Locale::Po4a::KernelHelp->new(%options);
    } elsif (lc($module) eq 'man') {
	return Locale::Po4a::Man->new(%options);
    } elsif (lc($module) eq 'pod') {
	return Locale::Po4a::Pod->new(%options);
    } elsif (lc($module) eq 'sgml') {
	return Locale::Po4a::Sgml->new(%options);
    } else {
	warn sprintf(gettext("Unknown format type: %s.\n"),$module);
	list(1);
    }
}

sub list {
    warn gettext("This version of po4a knows the following formats:\n".
		 "  - kernelhelp: The help messages associated with each kernel compilation option.\n".
		 "  - man: Good old manual page format.\n".
		 "  - pod: Perl documentation format.\n".
		 "  - sgml: either debiandoc or docbook DTD.\n");
    exit shift;
}
##############################################################################
# Module return value and documentation
##############################################################################

1;
__END__

=head1 NAME

Locale::Po4a::Chooser - Manage po4a modules

=head1 DESCRIPTION

Locale::Po4a::Chooser is a module to manage po4a modules. Before, all po4a
binaries used to know all po4a modules (pod, man, sgml, etc). This made the
add of a new module a boring, to make sure the documentation is syncronized
in all modules, and that each of them can access the new module.

Now, you just have to call the Locale::Po4a::Chooser::new() function,
passing the name of module as argument.

You also have the Locale::Po4a::Chooser::list() function which lists the
available format and exits on the value passed as argument.

=head1 SEE ALSO

=over 4

=item About po4a:

L<po4a(7)>, 
L<Locale::Po4a::TransTranctor(3perl)>,
L<Locale::Po4a::Po(3perl)>

=item About modules:

L<Locale::Po4a::KernelHelp(3perl)>,
L<Locale::Po4a::Man(3perl)>,
L<Locale::Po4a::Pod(3perl)>,
L<Locale::Po4a::Sgml(3perl)>.

=head1 AUTHORS

 Denis Barbier <denis.barbier@linuxfr.org>
 Martin Quinson <martin.quinson@tuxfamily.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by SPI, inc.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see COPYING file).

=cut
