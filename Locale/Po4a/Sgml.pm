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

It is not written yet ;)

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

$version = '$Id: Sgml.pm,v 1.1 2003-01-09 08:39:08 mquinson Exp $';

sub read {
    my ($self,$filename)=@_;

    push @{$self->{DOCPOD}{infile}}, $filename;
    $self->Locale::Po4a::TransTractor::read($filename);
}

sub parse {
    my $self=shift;
    map {$self->parse_file($_)} @{$self->{DOCPOD}{infile}};
}

sub initialize {
    my $self=shift;
    my %options=@_;

    $self->SUPER::initialize(%options);


    # FIXME: This is for debiandoc, put this in sysid handler, and 
    #  put the right one, depending on the sysid 
    #  (and handle the change of sysid, like debiandoc -> linuxdoc, when 
    #   several document are parsed)
    $self->set_tags_kind("translate" => "author version abstract title".
			                "date copyrightsummary heading p ".
			                "example tag email name title",
			 "empty"     => "date ref manref url toc",
			 "section"   => "chapt appendix sect sect1 sect2".
			                "sect3 sect4",
			 "verbatim"  => "example",
			 "list"      => "enumlist taglist list",
			 "listitem"  => "item tag",
			 "ignore"    => "debiandoc book titlepag ".
			                "package prgn file tt em var");
}

sub set_tags_kind {
    my $self=shift;
    my (%kinds)=@_;

    foreach (keys %kinds) {
	die "Internal error: set_tags_kind called with unrecognized arg $_"
	    if ($_ ne 'translate' && $_ ne 'empty' && $_ ne 'section' &&
		$_ ne 'verbatim'  && $_ ne 'list'  && $_ ne 'listitem' &&
		$_ ne 'ignore');
	
	$self->{SGML}->{k}{$_}=$kinds{$_};
    }    
}


#
# Do the actual work, using the SGMLS package and settings done elsewhere.
#
sub parse_file {
    my ($self,$filename)=@_;
    # Reads the document a first time, searching for:
    #  - optional inclusions
    #  - prolog
    my @opt_sect;
    my ($opt_sect,$prolog,$inprolog)=("","",1);
    open (IN,"<$filename") 
	|| die sprintf(gettext("Can't open %s: %s\n"),$filename,$!);
    while (<IN>) {
	if ($inprolog) {
	    if (/<debiandoc/i) {
		$inprolog = 0;
	    } else {
		$prolog .= $_;
	    }
	}
	if ( s/<!\[([^\[]*)\[/$1/ ) {
	    chomp;
	    s/%//g;
	    s/;//g;
	    map { push @opt_sect,$_ } split(/ /,$_);		
	}
    }
    close IN
	|| die sprintf(gettext("Can't close %s: %s\n"),$filename,$!);
    
    # kill duplicates in -i
    my $last='';
    map { if ($_ ne $last) { 
             $opt_sect .= "-i $_ "; 
          }
          $last=$_ 
        } sort @opt_sect;
     
    my $cmd="cat $filename|nsgmls -l $opt_sect|";
    print STDERR "CMD=$cmd\n";

    # FIXME: use po-debiandoc-fix
    open (IN,$cmd) || die sprintf(gettext("Can't run nsgmls: %s\n"),$!);
    
    # The parse object and the line number
    my ($parse,$line)= (new SGMLS(IN),0);

    # Some values for the parsing
    my $level = 0;     # level of sectionning
    my $listdepth = 0; # level in nested lists
    my $current = 0;   # current line  
    my $verbatim = 0;  # can we wrap or not
    my $lastchar = ''; # 


    # The kind of tags
    my (%translate,%empty,%section,%verbatim,%list,%listitem,%exist);
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
    foreach (split(/ /, ($self->{SGML}->{k}{'list'}||'') )) {
	$list{uc $_} = 1;
	$exist{uc $_} = 1;
    }
    foreach (split(/ /, ($self->{SGML}->{k}{'listitem'}||'') )) {
	$listitem{uc $_} = 1;
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
    
    # run the appropriate handler for each event
    EVENT: while ($event = $parse->next_event) {
	$line = max($parse->line,$line);
	my $type = $event->type;
	
	if ($type eq 'start_element') {
	    die sprintf(gettext("po4a::Sgml: %s:%d: Unknown tag %s\n"),
			$filename,$line,$event->data->name) 
		unless $exist{$event->data->name};
	    
	    $lastchar = ">";
	    $verbatim++ if $verbatim{$event->data->name()};
	    $listdepth++ if ($level && $list{$event->data->name()});

	    my $tag='';
	    $tag .= '<'.lc($event->data->name());
	    while (my ($attr, $val) = each %{$event->data->attributes()}) {
		if ($val->type() eq 'IMPLIED') {
		    $tag .= ' '.lc($attr).'="'.lc($attr).'"';
		} elsif ($val->type() eq 'CDATA') {
		    my $val = $val->value();
		    if ($val =~ m/"/) { #"
			$val = "'".$val."'";
		    } else {
			$val = '"'.$val.'"';
		    }
		    $tag .= ' '.lc($attr).'='.$val;
		} else {
		    $tag .= ' '.lc($attr).'="'.lc($val->value()).'"';
		}
	    }
	    $tag .= '>';
	    if ($level == 0) {		
		$self->pushline($tag);
		next EVENT unless $translate{$event->data->name()};
		push_output('string');
		$level ++;
	    } else {
		output($tag);
	    }
	} # end of type eq 'start_element'
	
	elsif ($type eq 'end_element') {
	    $lastchar = ">";
	    if ($translate{$event->data->name()}) {
		my ($string,$ref,$type)=(pop_output(),
				 	"$filename:".$parse->line(),
					 $event->data->name());

		$self->pushline(
                 ($verbatim ? 
		  $self->translate($string,$ref,$type)
		   :
		  $self->translate_wrapped($string,$ref,$type)
		  ).
				($empty{$event->data->name()} ? 
				 '' : '</'.lc($event->data->name()).'>').
				"\n");
		$level--;
		push_output('string') if ($level);
	    } else {		
		unless ($empty{$event->data->name()}) {
		    my $tag='</'.lc($event->data->name()).'>';
		    if ($level) {
			output($tag);
		    } else {
			$self->pushline($tag);
		    }
		}
	    }
	    $verbatim-- if $verbatim{$event->data->name()};
	} # end of type eq 'end_element'
	
	elsif ($type eq 'cdata') {
	    my $cdata = $event->data;
	    if (!$verbatim) {
		$cdata =~ s/\\t/ /g;
		$cdata =~ s/\s+/ /g;
		$cdata =~ s/^\s//s if $lastchar eq ' ';
	    }
	    $lastchar = substr($cdata, -1, 1);
	    output($cdata);

	} # end of type eq 'cdata'

	elsif ($type eq 'sdata') {
	    my $sdata = $event->data;
	    $sdata =~ s/^\[//;
	    $sdata =~ s/\s*\]$//;
	    $lastchar = substr($sdata, -1, 1);
	    output('&'.$sdata.';');
	} # end of type eq 'sdata'

	elsif ($type eq 're') {
	    $line ++;
	    if ($verbatim) {
		output("\n");
	    } elsif ($lastchar ne ' ') {
		output(" ");
	    }
	    $lastchar = ' ';
	} #end of type eq 're'

	elsif ($type eq 'conforming') {
	    
	}

	else {
	    die sprintf(gettext("%s:%d: Unknown SGML event type: %s\n"),
			$filename,$line,$type);
	    
	}
    }
				
    # What to do after parsing
    $self->pushline(pop_output());
    close(IN);
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
