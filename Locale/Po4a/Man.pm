#!/usr/bin/perl -w

=head1 NAME

Locale::Po4a::Man - Convert manual pages from/to PO files

=head1 DESCRIPTION

The goal po4a [po for anything] project is to ease translations (and more
interstingly, the maintainance of translation) using gettext tools on areas
where they were not expected like documentation.  

Locale::Po4a::Man is a module to help the translation of documentation in
the nroff format (the language of manual pages) into other [human]
languages.

=head1 SEE ALSO

L<po4a(7)>, L<Locale::Po4a::TransTranctor(3perl)>.

=head1 AUTHORS

 Denis Barbier <denis.barbier@linuxfr.org>
 Martin Quinson <martin.quinson@tuxfamily.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by SPI, inc.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see COPYING file).

=cut

package Locale::Po4a::Man;
require Exporter;
use vars qw($VERSION @ISA @EXPORT);
$VERSION = 0.1;
@ISA = qw(Locale::Po4a::TransTractor);
@EXPORT = qw(new initialize);
use Locale::Po4a::TransTractor;

use strict;
use File::Spec;
use Getopt::Std;

#####################
#### CONSTRUCTOR ####
#####################
# Herited from parent


###############################################
#### FUNCTION TO TRANSLATE OR NOT THE TEXT ####
###############################################
sub pushmacro {
    my $self=shift;
    if (scalar @_) { 
	$self->pushline(join(" ",map { defined($_) && m/ / ? "\"$_\"" : $_||"" } @_)."\n");
    } else {
	$self->pushline("\n");
    }
}

sub pre_trans {
    my ($self,$str,$ref,$type)=@_;
    # Preformating, so that translators don't see 
    # strange chars
    $str =~ s/>/E<gt>/g;
    $str =~ s/</E<lt>/g;
    $str =~ s/EE<lt>gt>/E<gt>/g; # could be done in a smarter way?
    
    $str =~ s/\\f([BI])(.*?)\\f[PR]/$1<$2>/g;
    $str =~ s|\\-|-|g;
    return $str;
}

sub post_trans {
    my ($self,$str,$ref,$type)=@_;
    my $transstr=$str;

    # Post formating, so that groff see the strange chars
    $str =~ s|-|\\-|mg;

    # Make sure we compute internal sequences right.
    # think about: B<AZE E<lt> EZA E<gt>>
#    warn "postrans($str)";
    while ($str =~ m/^(.*)([BI])<(.*)$/s) {
	my ($done,$rest)=($1."\\f$2",$3);
	my $lvl=1;
	while (length $rest && $lvl > 0) {
	    my $first=substr($rest,0,1);
	    if ($first eq '<') {
		$lvl++;
	    } elsif ($first eq '>') {
		$lvl--;
	    } 
	    $done .= $first  if ($lvl > 0);
	    $rest=substr($rest,1);
	}
	die sprintf(gettext("Unbalanced '<' and '>' in '%s' (reference=%s)\n"),$transstr,$ref||$self->{ref})
	    if ($lvl > 0);
	$done .= "\\fR$rest";
	$str=$done;
    }

    $str =~ s/E<gt>/>/mg;
    $str =~ s/E<lt>/</mg;
    $str =~ s/^\\f([BI])(.*?)\\fR$/\.$1 $2/mg;
    return $str;
}
sub translate {
    my ($self,$str,$ref,$type) = @_;
    my $origstr=$str;
    
    return $str unless (defined $str) && $str;

    $str=pre_trans($self,$str,$ref,$type);
    # Translate this
    $str = $self->SUPER::translate($str,
				   $ref||$self->{ref},
				   $type || $self->{type});
    $str=post_trans($self,$str,$ref,$type);
    return $str;
}

# shortcut
sub t { 
    my ($self,$str)=(shift,shift);
    return $self->translate($str);
}

##########################################
#### DEFINITION OF THE MACROS WE KNOW ####
##########################################
my %macro; # hash of known macro, with parsing sub
# Each sub is passed self as first arg,
#   plus the args present on the roff line
#   ie, <<.TH LS "1" "October 2002" "ls (coreutils) 4.5.2" "User Commands">>
#   is passed (".TH","LS","1","October 2002","ls (coreutils) 4.5.2","User Commands")
#   Macro name is also passed, because .B (bold) will be encoded in pod format (and mangeled).
# They should return a list, which will be join'ed(' ',..)
#   or undef when they don't want to add anything

# Some well known macro handeling

# For macro taking only one argument, but people may forget the quotes.
# Example: >>.SH Another Section<< which should be >>.SH "Another Section"<<
sub translate_joined {
    my ($self,$macroname,$macroarg)=(shift,shift,join(" ",@_));
    #section# .S[HS] name
    
    $self->pushmacro($macroname,
		     $self->t($macroarg));
}

# For macro taking several arguments, having to be translated separatly
sub translate_each {
   my ($self,$first)= (shift,0);
    $self->pushmacro( map { $first++ ? $_:$self->t($_) } @_);
}

# For macro which shouldn't be given any arg
sub noarg {
    my $self = shift;
    warn "Macro $_[0] does not accept any argument\n"
	if (defined ($_[1]));
    $self->pushmacro(@_);
}

# For macro whose arguments shouln't be translated
sub untranslated {
    my $self = shift;
    $self->pushmacro(@_);
}

###
### man 7 man
###

$macro{'TH'}= sub {
    my $self=shift;
    my ($th,$title,$section,$date,$source,$manual)=@_;
    #Preamble#.TH      title     section   date     source   manual
#    print STDERR "TH=$th;titre=$title;sec=$section;date=$date;source=$source;manual=$manual\n";
    $self->pushmacro($th,
		     $self->t($title),
		     $section,$date,
		     $self->t($source),
		     $self->t($manual));
};

# .SS t    Subheading t (like .SH, but used for a subsection inside a section).
$macro{'SS'}=$macro{'SH'}=\&translate_joined;

#Whole line style B=>bold;I=>italics;SM=>small
# B and I are handled as special case to join it to the rest of the paragraph
$macro{'SM'}=\&translate_joined;

# Whole line style with alternatives
# .BI bold alternating with italic
# .BR bold/roman
# .IB italic/bold
# .IR italic/roman
# .RB roman/bold
# .RI roman/italic
# .SB small/bold
$macro{'BI'}=$macro{'BR'}=$macro{'IB'}=$macro{'IR'}=$macro{'RB'}=$macro{'RI'}=$macro{'SB'}=
sub {
    my ($self,$i)=(shift,0);
    $self->pushmacro( map { $i==0? $_ : 
				   $i++ % 2 ? $self->t($_) : 
				              $self->t($_) 
			   } @_);
};

#Normal Paragraphs
#  .LP      Same as .PP (begin a new paragraph).
#  .P       Same as .PP (begin a new paragraph).
#  .PP      Begin a new paragraph and reset prevailing indent.
#Relative Margin Indent
#  .RS i    Start relative margin indent - moves the left margin i to the right 
#           As a result,  all  following  paragraph(s) will be indented until
#           the corresponding .RE.
#  .RE      End  relative  margin indent.
$macro{'LP'}=$macro{'P'}=$macro{'PP'}=$macro{'RE'}=\&noarg;
$macro{'RS'}=\&untranslated;

#Indented Paragraph Macros
#  .TP i    Begin  paragraph  with  hanging tag.  The tag is given on the next line,
#           but its results are like those of the .IP command.
$macro{'TP'}=sub {
    my $self=shift;
    my ($line,$l2,$ref2);
    $line .= $_[0] if defined($_[0]);
    $line .= ' '.$_[1] if defined($_[1]);
    $line .= "\n";
    ($l2,$ref2) = $self->shiftline();
    chomp($l2);
    $self->pushline($line.$self->t($l2)."\n");
};

#   Indented Paragraph Macros
#       .HP i    Begin paragraph with a hanging indent (the first line of  the  paragraph
#                is  at  the  left margin of normal paragraphs, and the rest of the para-
#                graph's lines are indented).
#
$macro{'HP'}=sub {
    my $self=shift;
    my ($line,$l2,$ref2);
    $line .= $_[0] if defined($_[0]);
    $line .= ' '.$_[1] if defined($_[1]);
    $line .= "\n";
    ($l2,$ref2) = $self->shiftline();
    chomp($l2);
    $self->pushline($line.$self->t($l2)."\n");
};

#Indented Paragraph Macros
#  .IP x i  Indented paragraph with optional hanging tag.  If the tag x is  omitted,
#           the  entire  following paragraph is indented by i.  If the tag x is pro-
#           vided, it is hung at the left margin before the following indented para-
#           graph (this is just like .TP except the tag is included with the command
#           instead of being on the following line).  If the tag is  too  long,  the
#           text after the tag will be moved down to the next line (text will not be
#           lost or garbled).  For bulleted lists, use this macro with \(bu (bullet)
#           or  \(em (em dash) as the tag, and for numbered lists, use the number or
#           letter followed by a period as the tag; this simplifies  translation  to
#           other formats.
$macro{'IP'}=sub {
    my $self=shift;
    if (defined $_[2]) {
	$self->pushmacro($_[0],$self->t($_[1]),$_[2]);
    } else {
	$self->pushmacro(@_);
    }
};


#Index. Where's the definition?
#.IX type content
$macro{'IX'}=sub {
    my $self=shift;
    $self->pushmacro($_[0],$_[1],$self->t($_[2]));
};

###
### groff macros
###
# .br 
$macro{'br'}=\&noarg;
#       .ad       Begin line adjustment for output lines in current adjust mode.
#       .ad c     Start line adjustment in mode c (c=l,r,b,n).
$macro{'ad'}=\&untranslated;
#       .fam      Return to previous font family.
#       .fam name Set the current font family to name.
$macro{'fam'}=\&untranslated;
# .sp     Skip one line vertically.
# .sp N   Space  vertical distance N
$macro{'sp'}=\&untranslated;

### 
### tbl macros
### 
$macro{'TS'}=sub {
    my $self=shift;
    my ($in_headers,$buffer)=(1,"");
    my ($line,$ref)=$self->shiftline();
    
    # Push table start
    $self->pushmacro(@_);
    while (defined($line)) {
	if ($line =~ /^\.TE/) {
	    # Table end
	    $self->pushline($line);
	    return;
	}
	if ($in_headers) {
	    if ($line =~ /\.$/) {
		$in_headers = 0;
	    }
	    $self->pushline($line);
	} elsif ($line =~ /\\$/) {
	    # Lines are continued on \ at the end of line
	    $buffer .= $line;
	} else {
	    $buffer .= $line;
	    # Arguments to translate are separated by \t
	    $self->pushline(join("\t",
				 map { $self->translate($buffer,
							$ref,
							'tbl table') 
				     } split (/\\t/,$line)));
	    $buffer = "";
	}
	($line,$ref)=$self->shiftline();
    }
};

sub do_paragraph {
    my ($self,$paragraph,$wrapped_mode) = (shift,shift,shift);

    if ($wrapped_mode) {
	$paragraph = $self->translate_wrapped($paragraph,$self->{ref},"Plain text");
	my @paragraph=split (/\n/,$paragraph);
	if (defined ($paragraph[0]) && $paragraph[0] eq '') {
	    shift @paragraph;
	}
	$paragraph = join("\n",@paragraph)."\n";
    } else {
	$paragraph = $self->translate($paragraph,$self->{ref},"Plain text");
    }
    $self->pushline( $paragraph );
}

#############################
#### MAIN PARSE FUNCTION ####
#############################
sub parse{
    my $self = shift;
    my ($line,$ref);
    my ($paragraph)=""; # Buffer where we put the paragraph while building
    my $wrapped_mode=1;   # Wheater we saw .nf or not

  LINE:
    ($line,$ref)=$self->shiftline();
    
    while (defined($line)) {
#	print STDERR "line=$line;ref=$ref";
	chomp($line);
	$self->{ref}="$ref";

	if ($line =~ /^\.(\S*)(.*)/) {
	    my $macro=$1;
	    
	    if ($macro eq 'B' || $macro eq 'I') {
		my $arg=$2;
		$arg =~ s/^ //;
		$paragraph .= "\\f$macro".$arg."\\fR\n";
		goto LINE;
	    }
	    if ($paragraph) {
		do_paragraph($self,$paragraph,$wrapped_mode);
		$paragraph="";
	    }

	    # Special case: Don't change these lines
	    # Check for comments indicating that the file was generated.
	    if ($macro eq '\"') {
		if ($line =~ /Pod::Man/) {
		    warn "This file was generated with Pod::Man. Translate the pod file.\n";
		    exit 0;
		} elsif ($line =~ /generated by help2man/)    {
		    warn "This file was generated with help2man. Translate the source file.\n";
		} elsif ($line =~ /with docbook-to-man/)      { 
		    warn "This file was generated with docbook-to-man. Translate the source file.\n";
		    exit 0;
		} elsif ($line =~ /generated by docbook2man/) { 
		    warn "This file was generated with docbook2man. Translate the source file.\n";
		    exit 0;
		} elsif ($line =~ /created with latex2man/)   { 
		    warn "This file was generated with latex2man. Translate the source file.\n";
		} elsif ($line =~ /Generated by db2man.xsl/)  { 
		    warn "This file was generated with db2man.xsl. Translate the source file.\n";
		    exit 0;
		} elsif ($line =~ /generated automatically by mtex2man/)  {
		    warn "This file was generated with mtex2man. Translate the source file.\n";
		} elsif ($line =~ /THIS FILE HAS BEEN AUTOMATICALLY GENERATED.  DO NOT EDIT./) {
		    warn "This file contains the line '$line'. Translate the source file.\n";
		} elsif ($line =~ /DO NOT EDIT/i || $line =~ /generated/i) {
		    warn "This file contains the line '$line'. Translate the source file.\n";
		}
	    }

	    # Special case: Don't change these lines
	    #  .\"  => comments
	    #  .    => empty point on the line
	    #  .tr abcd...
	    #       => Translate a to b, c to d, etc. on output.
	    if ($macro eq '\"' || $macro eq '' || $macro eq 'tr') {
		$self->pushline($line."\n");
		goto LINE;
	    }
	    # Special case:
	    #  .nf => stop wrapped mode
	    #  .fi => wrap again
	    if ($macro eq 'nf' || $macro eq 'fi') {
		$wrapped_mode=$macro eq 'fi';
		$self->pushline($line."\n");
		goto LINE;
	    }		

	    # Special case:
	    #  .Dd => Indicates that this is a mdoc page
	    if ($macro eq 'Dd') {
		die "This page seems to be a mdoc(7) formated one.\n".
		    "This is not supported (yet).\n";
	    }
		
	    # Split on spaces for arguments, but not spaces within double quotes
	    my @args=();
	    my $buffer="";
	    foreach (split (/ /,$line)) {
		#print ">>Seen $_(buffer=$buffer)\n";
		if (defined($buffer) && length $buffer) {
		    #print "Continuation of a quote\n";
		    $buffer .= " ".$_;
		    #print "buffer=$buffer.\n";
		    if ($buffer =~ m/^"(.*)"$/) {
			#print "End of a quote\n";
			push @args,$1;
			$buffer = "";
		    }
		} elsif (m/^"(.*)"$/) {
		    #print "Quoted, no space\n";
		    push @args,$1;
		} elsif (m/^"/) { #") {
		    #print "Begin of a quoting arg\n";
		    $buffer=$_;
		} else {
		    #print "Unquoted arg, nothing to declare\n";
		    push @args,$_;
		}
	    }
	    unshift @args,$self;
	    # Apply macro
	    $self->{type}=$macro;

	    if (defined ($macro{$macro})) {
		&{$macro{$macro}}(@args);
	    } else {
		$self->pushline($line."\n");
		die "Sorry, I don't know the macro >>$line<<.\n".
		    "Edit the man page to remove it, or provide a patch".
		    " to my maintainer to handle it.\n";
	    }

	} elsif ($line =~ /^( +)([^.].*)/) {
	    # Not a macro, but not a wrapped paragraph either
	    if ($paragraph) {
		do_paragraph($self,$paragraph,$wrapped_mode);
		$paragraph="";
	    }
	    $self->pushline($1.$self->translate($2)."\n");
	} elsif ($line =~ /^([^.].*)/) {
	    # Not a macro
	    $paragraph .= $line."\n";
	} else { #empty line
	    do_paragraph($self,$paragraph,$wrapped_mode);
	    $paragraph="";
	    $self->pushline($line."\n");
	} 
	# Reinit the loop
	($line,$ref)=$self->shiftline();
    }


#MISSING:
#
#
#   Hypertext Link Macros
#       .UR u    Begins a hypertext link to the URI (URL) u; it will end with the  corre-
#                sponding  UE  command.   When generating HTML this should translate into
#                the HTML command <A HREF="u">.  There is an exception: if u is the  spe-
#                cial  value  ":",  then  no hypertext link of any kind will be generated
#                until after the closing UE (this permits disabling  hypertext  links  in
#                phrases  like LALR(1) when linking is not appropriate).  These hypertext
#                link "macros" are new, and many tools won''t do anything with  them,  but 
#                since  many  tools (including troff) will simply ignore undefined macros
#                (or at worst insert their text) these are safe to insert.
#
#       .UE      Ends the corresponding UR command;  when  generating  HTML  this  should
#                translate into </A>.
#
#       .UN u    Creates a named hypertext location named u; do not include a correspond-
#                ing UE command.  When generating HTML this  should  translate  into  the
#                HTML  command  <A  NAME="u" id="u">&nbsp;</A> (the &nbsp; is optional if
#                support for Mosaic is unneeded).
#
#   Miscellaneous Macros
#       .DT      Reset tabs to default tab values (every 0.5 inches); does  not  cause  a
#                break.
#
#       .PD d    Set  inter-paragraph  vertical  distance to d (if omitted, d=0.4v); does
#                not cause a break.
#
#       .SS t    Subheading t (like .SH, but used for a subsection inside a section).
#
#   Predefined Strings
#       The man package has the following predefined strings:
#
#       \*R    Registration Symbol: (R)
#       \*S    Change to default font size
#       \*(Tm  Trademark Symbol: tm
#       \*(lq  Left angled doublequote: "
#       \*(rq  Right angled doublequote: "
#
#SAFE SUBSET
#       Although technically man is a troff macro package, in reality a large  number  of
#       other tools process man page files that don't implement all of troff's abilities.
#       Thus, it's best to avoid some of troff's more exotic abilities where possible  to
#       permit  these  other tools to work correctly.  Avoid using the various troff pre-
#       processors (if you must, go ahead and use tbl(1), but try to use the  IP  and  TP
#       commands  instead  for  two-column tables).  Avoid using computations; most other
#      tools can''t process them.  Use simple commands that  are  easy  to  translate  to
#       other  formats.   The  following  troff macros are believed to be safe (though in
#       many cases they will be ignored by translators): \", ., ad, bp, br, ce,  de,  ds,
#       el, ie, if, fi, ft, hy, ig, in, na, ne, nf, nh, ps, so, sp, ti, tr.
#
#       You  may also use many troff escape sequences (those sequences beginning with \).
#       When you need to include the backslash character as normal text, use  \e.   Other
#       sequences  you  may  use,  where  x  or xx are any characters and N is any digit,
#       include: \', \`, \-, \., \", \%, \*x, \*(xx, \(xx,  \$N,  \nx,  \n(xx,  \fx,  and
#       \f(xx.  Avoid using the escape sequences for drawing graphics.
#
#       Do  not use the optional parameter for bp (break page).  Use only positive values
#       for sp (vertical space).  Don''t define a macro (de) with the same name as a macro
#       in this or the mdoc macro package with a different meaning; it's likely that such
#       redefinitions will be ignored.  Every positive indent (in) should be paired  with
#       a  matching  negative  indent  (although you should be using the RS and RE macros
#       instead).  The condition test (if,ie) should only have 't' or 'n' as  the  condi-
#       tion.   Only  translations (tr) that can be ignored should be used.  Font changes
#       (ft and the \f escape sequence) should only have the values 1, 2, 3, 4, R, I,  B,
#       P, or CW (the ft command may also have no parameters).
#
#       If  you  use  capabilities  beyond  these, check the results carefully on several
#       tools.  Once you''ve confirmed that the additional capability  is  safe,  let  the
#       maintainer  of  this document know about the safe command or sequence that should
#       be added to this list.

	#Lists, the .PD stuff is questionable :-/
 # 	s/^\.PD\s*\d+\s*$/\n=over\n/;
 #	s/^\.PD\s*$/\n=back\n/;
	#XXX these are somewhat wrong, and IP needs to handle optional 2nd arg
 #   1 if s/^\.TP\s*\d*\s*$/\n=item /s ... s/$/\n/;


	#Characters
 #	s/\.br\b//;
 #	s/\\([-\s`'"])/$1/g;        #`]);
 #	s/"\\\(bu/o/g;              #";
	
    #	print;
#    }
    if ($paragraph) {
	do_paragraph($self,$paragraph,$wrapped_mode);
	$paragraph="";
    }
}


