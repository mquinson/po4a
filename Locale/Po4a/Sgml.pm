#!/usr/bin/perl -w

# Po4a::Sgml.pm 
# 
# extract and translate translatable strings from a sgml based document.
# 
# This code is an adapted version of sgmlspl (SGML postprocesser for the
#   SGMLS and NSGMLS parsers) which was:
#
# Copyright (c) 1995 by David Megginson <dmeggins@aix1.uottawa.ca>
# 
# The adaptation for po4a was done by Denis Barbier <barbier@debian.org>,
# Martin Quinson <martin.quinson@tuxfamily.org> and others.
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

Locale::Po4a::Sgml - Convert sgml documents from/to PO files

=head1 DESCRIPTION

The goal po4a [po for anything] project is to ease translations (and more
interstingly, the maintainance of translation) using gettext tools on areas
where they were not expected like documentation.  

Locale::Po4a::Sgml is a module to help the translation of documentation in
the SGML format into other [human] languages.

=head1 STATUS OF THIS MODULE

The result is perfect. Ie, the generated documents are exactly the
same. But there is still some problems:

=over 2

=item * 

the source is awfull. No effort is done to keep it clean. I just wanted
this damned module to work.

=item * 

the error output of nsgmls is redirected to /dev/null, which is clearly
bad. I dunno how to avoid that.

The problem is that I have to "protect" the conditionnal inclusion (ie, the
C<E<lt>! [ %blah [> and C<]]E<gt>> stuff) from nsgml, because in the other
case, nsgmls eat them, and I dunno how to restore them in the final
document. To prevent that, I rewrite them to C<{PO4A-beg-blah}> and
C<{PO4A-end}>. 

The problem with this is that the C<{PO4A-end}> and such I add are valid in
the document (not in a E<lt>pE<gt> tag or so).

Everything works well with nsgmls's output redirected that way, but it will
prevent us to detect that the document is badly formated.

=item *

It does work only with the debiandoc dtd. Adding support for a new dtd
should be easy.

=back

=head1 INTERNALS

=cut

package Locale::Po4a::Sgml;
require Exporter;
use vars qw($VERSION @ISA @EXPORT);
$VERSION="0.12";
@ISA = qw(Locale::Po4a::TransTractor);
@EXPORT = qw(new initialize);

use Locale::Po4a::TransTractor;
use Locale::gettext qw(gettext);

use SGMLS;
use SGMLS::Output qw(push_output pop_output output);

use File::Temp;

my %debug=('tag' => 0);

$version = '$Id: Sgml.pm,v 1.2 2003-01-09 20:22:03 mquinson Exp $';

sub read {
    my ($self,$filename)=@_;

    push @{$self->{DOCPOD}{infile}}, $filename;
    $self->Locale::Po4a::TransTractor::read($filename);
}

sub parse {
    my $self=shift;
    map {$self->parse_file($_)} @{$self->{DOCPOD}{infile}};
}

sub pushline {
    my ($self,$line)=(shift,shift);
    # remove the protection on conditional inclusion before 
    # pushing line
    $line =~ s/{PO4A-end}/\]\]>/g;             # cond. incl. end
    $line =~ s/{PO4A-beg-([^\}]+)}/<!\[$1\[/g; # cond. incl. starts
    $self->SUPER::pushline($line);
}

#
# Filter out some unintersting strings for translation
#
sub want_translate {
    my $string=shift;

    # don't translate entries composed of entity only
    return 0 if ($string =~ /^&[^;]*;$/);
    return 0 if ($string =~ /^(((<[^>]*>)|\s)*)$/);
    return 1;
}
sub translate {
    my ($self)=(shift);
    my ($string,$ref,$type)=(shift,shift,shift);
    
    return (want_translate($string) ?
	    $self->SUPER::translate($string,$ref,$type) :
	    $string);
}
sub translate_wrapped {
    my ($self)=(shift);
    my ($string,$ref,$type,$wrapcol)=(shift,shift,shift,shift);
    
    return (want_translate($string) ?
	    $self->SUPER::translate_wrapped($string,$ref,$type,$wrapcol) :
	    $string);
}



sub set_tags_kind {
    my $self=shift;
    my (%kinds)=@_;

    foreach (qw(translate empty section verbatim ignore)) {
	$self->{SGML}->{k}{$_} = "";
    }
    
    foreach (keys %kinds) {
	die "Internal error: set_tags_kind called with unrecognized arg $_"
	    if ($_ ne 'translate' && $_ ne 'empty' && $_ ne 'section' &&
		$_ ne 'verbatim'  && $_ ne 'ignore');
	
	$self->{SGML}->{k}{$_}=$kinds{$_};
    }    
}


#
# Do the actual work, using the SGMLS package and settings done elsewhere.
#
sub parse_file {
    my ($self,$filename)=@_;
    my $dtd;
    # Reads the document a first time, searching for prolog

    # Rewrite the file to:
    #   - protect optionnal inclusion marker (ie, "<![ %str [" and "]]>")
    #   - protect entities from expension (ie "&release;")
    open (IN,"<$filename") 
	|| die sprintf(gettext("Can't open %s: %s\n"),$filename,$!);
    my $origfile="";
    while (<IN>) {
	$origfile .= $_;
    }
    close IN || die sprintf(gettext("Can't close %s: %s\n"),$filename,$!);
    # Get the prolog
    {
	my $lvl;    # number of '<' seen without matching '>'
	my $pos;    # where in the document (in chars)
	
	$prolog=$origfile;
	$prolog=~ s/^(.*<!DOCTYPE).*$/$1/is;
	$pos=length($prolog);
	$lvl=1;
	while ($lvl != 0) {
	    my ($c)=substr($origfile,$pos,1);
	    $lvl++ if ($c eq '<');
	    $lvl-- if ($c eq '>');
	    $prolog = "$prolog$c";
	    $pos++;
	}
    }
    print STDERR "PROLOG=$prolog\n------------\n";
    # Get dtd
    die sprintf(gettext("Can't guess the DTD of %s. Is this a valid document?")
		,$filename)
	unless ($origfile =~ m/<!DOCTYPE +([^ ]*) /i);
    $dtd=$1;
    print STDERR "DTD=$dtd\n";

    # Configure the tags for this dtd
    if (lc($dtd) eq 'debiandoc') {
	$self->set_tags_kind("translate" => "author version abstract title".
			                    "date copyrightsummary heading p ".
 			                    "example tag email name title",
			     "empty"     => "date ref manref url toc",
			     "section"   => "chapt appendix sect sect1 sect2".
			                    "sect3 sect4",
			     "verbatim"  => "example",
			     "ignore"    => "debiandoc book titlepag ".
                                            "enumlist taglist list item tag ".
			                    "package prgn file tt em var");
    } else {
	die sprintf(gettext("File %s have an unknown DTD: %s\n".
			    "Supported for now: debiandoc.\n"),
		    $filename,$dtd);
    }
    
    # protect what should be protected in the file
    $origfile =~ s/&/{PO4A-amp}/g;                    # &entities;
    $origfile =~ s/<!\[(\s*[^\[]+)\[/{PO4A-beg-$1}/g; # cond. incl. starts
    $origfile =~ s/\]\]>/{PO4A-end}/g;                # cond. incl. end
    
    my ($tmpfh,$tmpfile)=File::Temp->tempfile("po4a-sgml-XXXX",
					      DIR    => "/tmp",
					      UNLINK => 0);
    print $tmpfh $origfile;
    close $tmpfh || die sprintf(gettext("Can't close tempfile: %s\n"),$!);

    my $cmd="cat $tmpfile|nsgmls -l -E 0 2>/dev/null|";
    print STDERR "CMD=$cmd\n";

    # FIXME: use po-debiandoc-fix
    open (IN,$cmd) || die sprintf(gettext("Can't run nsgmls: %s\n"),$!);

    # The kind of tags
    my (%translate,%empty,%section,%verbatim,%exist);
    foreach (split(/ /, ($self->{SGML}->{k}{'translate'}||'') )) {
	$translate{uc $_} = 1;
	$exist{uc $_} = 1;
    }
    foreach (split(/ /, ($self->{SGML}->{k}{'empty'}||'') )) {
	$empty{uc $_} = 1;
	$exist{uc $_} = 1;
    }
    foreach (split(/ /, ($self->{SGML}->{k}{'section'}||'') )) {
	$section{uc $_} = 1;
	$exist{uc $_} = 1;
    }
    foreach (split(/ /, ($self->{SGML}->{k}{'verbatim'}||'') )) {
	$verbatim{uc $_} = 1;
	$exist{uc $_} = 1;
    }
    foreach (split(/ /, ($self->{SGML}->{k}{'ignore'}) || '')) {
	$ignore{uc $_} = 1;
	$exist{uc $_} = 1;
    }

    # What to do before parsing

    # push the prolog
    $self->pushline($prolog);
    push_output('string');
    
    # The parse object and the line number
    my $parse= new SGMLS(IN);

    # Some values for the parsing
    $self->{SGML}->{level}=0; # howmany translation container tags are open
    $self->{SGML}->{verb}=0;  # can we wrap or not
    my $lastchar = ''; # 

    # run the appropriate handler for each event
    EVENT: while ($event = $parse->next_event) {
	# to build po entries
	$self->{SGML}->{ref}="$filename:".$parse->line;
	$self->{SGML}->{type}=$event->type;
	
	if ($event->type eq 'start_element') {
	    die sprintf(gettext("po4a::Sgml: %s:%d: Unknown tag %s\n"),
			$filename,$line,$event->data->name) 
		unless $exist{$event->data->name};
	    
	    $lastchar = ">";
	    ($self->{SGML}->{verb})++ if $verbatim{$event->data->name()};

	    my $tag='';
	    $tag .= '<'.lc($event->data->name());
	    while (my ($attr, $val) = each %{$event->data->attributes()}) {
		my $value = $val->value();
#		if ($val->type() eq 'IMPLIED') {
#		    $tag .= ' '.lc($attr).'="'.lc($attr).'"';
#		} els
                if ($val->type() eq 'CDATA') {
		    if ($value =~ m/"/) { #"
			$value = "'".$value."'";
		    } else {
			$value = '"'.$value.'"';
		    }
		    $tag .= ' '.lc($attr).'='.$value
			if (defined $value && length($value));
		} else {
		    $tag .= ' '.lc($attr).'="'.lc($value).'"'
			if (defined $value && length($value));
		}
	    }
	    $tag .= '>';
	    $self->{SGML}->{type}=$tag;

	    print STDERR "                           Seen $tag, level=".$self->{SGML}->{level}."\n"
		if ($debug{'tag'});
		

	    if ($translate{$event->data->name()}) {
		if ($self->{SGML}->{level} > 0) {
		    $self->end_paragraph();
		} else {
		    $self->pushline(pop_output());
		}
		$self->pushline($tag);
		push_output('string');
		$self->{SGML}->{level}++;
	    } elsif ($section{$event->data->name()}) {
		die sprintf(gettext(
           "Closing tag for a translation container missing before %s, at %s\n"
				    ),$tag,$self->{SGML}->{ref})
		    if ($self->{SGML}->{level});
		output($tag);
	    } else {
		output($tag);
	    }
	} # end of type eq 'start_element'
	
	elsif ($event->type eq 'end_element') {
	    my $tag = ($empty{$event->data->name()} 
		           ? 
		       '' 
		           : 
		       '</'.lc($event->data->name()).'>');

	    print STDERR "                           Seen $tag, level=".$self->{SGML}->{level}."\n"
		if ($debug{'tag'});

	    $lastchar = ">";
	    $self->{SGML}->{type}='<'.lc($event->data->name()).'>';

	    if ($translate{$event->data->name()}) {
		$self->end_paragraph();
		push_output('string');
		output($tag);
		$self->{SGML}->{level}--;
	    } elsif ($section{$event->data->name()}) {
		die sprintf(gettext(
           "Closing tag for a translation container missing before %s, at %s\n"
				    ),$tag,$self->{SGML}->{ref})
		    if ($self->{SGML}->{level});
		output($tag);
	    } else {
		output($tag);
	    }
	    
	    ($self->{SGML}->{verb})-- if $verbatim{$event->data->name()};
	} # end of type eq 'end_element'
	
	elsif ($event->type eq 'cdata') {
	    my $cdata = $event->data;
	    if (!($self->{SGML}->{verb})) {
		$cdata =~ s/\\t/ /g;
		$cdata =~ s/\s+/ /g;
		$cdata =~ s/^\s//s if $lastchar eq ' ';
	    }
	    $lastchar = substr($cdata, -1, 1);
	    output($cdata);

	} # end of type eq 'cdata'

	elsif ($event->type eq 'sdata') {
	    my $sdata = $event->data;
	    $sdata =~ s/^\[//;
	    $sdata =~ s/\s*\]$//;
	    $lastchar = substr($sdata, -1, 1);
	    output('&'.$sdata.';');
	} # end of type eq 'sdata'

	elsif ($event->type eq 're') {
	    $line ++;
	    if ($self->{SGML}->{verb}) {
		output("\n");
	    } elsif ($lastchar ne ' ') {
		output(" ");
	    }
	    $lastchar = ' ';
	} #end of type eq 're'

	elsif ($event->type eq 'conforming') {
	    
	}

	else {
	    die sprintf(gettext("%s:%d: Unknown SGML event type: %s\n"),
			$filename,$line,$type);
	    
	}
    }
				
    # What to do after parsing
    $self->pushline(pop_output());
    close(IN);
    unlink ($tmpfile);
}

sub end_paragraph {
    my $self=shift;
    die "Internal error: level of opened paragraphs above 0!!" 
	unless $self->{SGML}->{level};
		
    $string=pop_output();
    return unless defined($string) && length($string);
    # unprotect stuff 
    $string =~ s/{PO4A-amp}/&/g;                 # &entities;
    $string =~ s/ name=\"\\\|\\\|\"//g;


    $self->pushline(($self->{SGML}->{verb} ? 
		     $self->translate($string,
				      $self->{SGML}->{ref},
				      $self->{SGML}->{type})
		     :
		     $self->translate_wrapped($string,
					      $self->{SGML}->{ref},
					      $self->{SGML}->{type})
		     ));
}

sub max {
        return ($_[0] > $_[1] ? $_[0] : $_[1]);
}

=head1 AUTHORS

This module is an adapted version of sgmlspl (SGML postprocesser for the
SGMLS and NSGMLS parsers) which was:

 Copyright (c) 1995 by David Megginson <dmeggins@aix1.uottawa.ca>
 
The adaptation for po4a was done by:

 Denis Barbier <denis.barbier@linuxfr.org>
 Martin Quinson <martin.quinson@tuxfamily.org>

=head1 COPYRIGHT AND LICENSE

 Copyright (c) 1995 by David Megginson <dmeggins@aix1.uottawa.ca>
 Copyright 2002 by SPI, inc.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see COPYING file).
