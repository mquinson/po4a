# Locale::Po4a::Pod -- Convert POD data to PO file, for translation.
# $Id: Chooser.pm,v 1.7 2003-11-28 00:08:58 barbier Exp $
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

use 5.006;
use strict;
use warnings;
use Locale::gettext;

sub new {
    my ($module)=shift;
    my (%options)=@_;

    my $modname;
    if ($module eq 'kernelhelp') {
        $modname = 'KernelHelp';
    } else {
        $modname = ucfirst($module);
    }
    if (! UNIVERSAL::can("Locale::Po4a::$modname", 'new')) {
        eval qq{use Locale::Po4a::$modname};
        if ($@) {
            warn sprintf(gettext("Unknown format type: %s.\n"), $module);
            list(1);
        }
    }
    return "Locale::Po4a::$modname"->new(%options);
}

sub list {
    warn gettext("This version of po4a knows the following formats:\n".
		 "  - kernelhelp: The help messages associated with each kernel compilation option.\n".
#		 "  - html: HTML documents (EXPERIMENTAL).\n".
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
L<Locale::Po4a::TransTranctor(3pm)>,
L<Locale::Po4a::Po(3pm)>

=item About modules:

L<Locale::Po4a::KernelHelp(3pm)>,
L<Locale::Po4a::Man(3pm)>,
L<Locale::Po4a::Pod(3pm)>,
L<Locale::Po4a::Sgml(3pm)>.
L<Locale::Po4a::Html(3pm)>.

=head1 AUTHORS

 Denis Barbier <barbier@linuxfr.org>
 Martin Quinson <martin.quinson@tuxfamily.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by SPI, inc.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see COPYING file).

=cut
