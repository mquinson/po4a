#!/usr/bin/perl -w

=head1 NAME

Locale::Po4a::Man - Convert manual pages from/to PO files

=head1 DESCRIPTION

The po4a (po for anything) project goal is to ease translations (and more
interestingly, the maintenance of translation) using gettext tools on areas
where they were not expected like documentation.  

Locale::Po4a::Man is a module to help the translation of documentation in
the nroff format (the language of manual pages) into other [human]
languages.

=head1 TRANSLATING WITH PO4A::MAN

This module tries pretty hard to make translator's life easier. For that,
the text presented to translators isn't a verbatim copy of the text found
in the man page. Indeed, the cruder parts of the nroff format are hiden, so
that translators can't mess up with it.

=head2 Text wrapping

Unindented paragraphs are automatically rewrapped for the translator.  This
can lead to some minor difference in the generated output, since the
rewrapping rules used by groff aren't very clear. For example, two spaces
after a parenthesis are sometimes preserved, while typographic rules only
ask to preserve the two spaces after the period sign (ok, I'm not native
speaker, and I'm not sure of that. If you have any other information,
you're welcome). 

Anyway, the difference will only be about the position of the extra spaces
in wrapped paragraph, and I think it's worth.

=head2 Font specification

The first change is about font change specifications.  In nroff, there is
several way to specify if a given word should be written in small, bold or
italics. In the text to translate, there is only one way, borrowed from the
pod (perl online documentation) format:

=over

=item IE<lt>textE<gt> -- italic text

equivalent to \fItext\fP or ".I text"

=item BE<lt>textE<gt> -- bold text

equivalent to \fBtext\fP or ".B text"

=item SE<lt>textE<gt> -- small text

equivalent to \fStext\fP

=back

Remark 1: SE<lt>textE<gt> don't exist in the pod format, don't try it in a
pod page. But this notation is usefull here.

Remark 2: Don't nest font specificator, since it does not work well in po4a for now.

=head2 Putting 'E<lt>' and 'E<gt>' in translations

Since these chars are used to delimit parts under font modification, you
can't use them verbatim. Use EE<lt>ltE<gt> and EE<lt>gtE<gt> instead (as in
pod, one more time).

=head1 AUTHORING MAN PAGES COMPLIANT WITH PO4A::MAN

This module is still very limited, and will always be, because it's not a
real nroff interpreter. It would be possible to do a real nroff
interpreter, to allow authors to use all the existing macros, or even to
define new ones in their pages, but we didn't want to. It would be too
difficult, and we didn't though it was necessary. We do think that if
manpage authors want to see their production translated, they may have to
adapt to ease the work of translaters. 

So, the man parser implemented in po4a have some known limitations we are
not really inclined to correct, and which will constitute some pitfalls
you'll have to avoid if you want to see translators taking care of your
documentation.

=head2 Don't use the mdoc macro set

The macro set described in mdoc(7) (and widly used under BSD, IIRC) isn't
supported at all by po4a, and won't be. It would need a completely separate
parser for this, and I'm not inclined to do so. On my machine, there is
only 63 pages based on mdoc, from 4323 pages. If someone implement the mdoc
support, I'll happilly include this, though.

=head2 Don't programm in nroff

nroff is a complete programming language, with macro definition,
conditionals and so on. Since this parser isn't a fully featured nroff
interpreter, it will fail on pages using these facilities (There is about
200 such pages on my box).

=head2 Avoid file inclusion when possible

The '.so' groff macro used to include another file in the current one is
supported, but from my personnal experiment, it makes harder to manipulate
the man page, since all files have to be installed in the right location so
that you can see the result (ie, it breaks somehow the '-l' option of man).

=head2 Use the plain macro set

There is still some macros which are not supported by po4a::man. This is
only because I failed to find any documentation about them. Here is the
list of unsupported macros used on my box. Note that this list isn't
exaustive since the program fails on the first encountered unsupported
macro. If you have any information about some of these macros, I'll
happilly add support for them. Because of these macros, about 250 pages on
my box are inaccessible to po4a::man.

 ..               ."              .AT             .b              .bank
 .BE              ..br            .Bu             .BUGS           .BY
 .ce              .dbmmanage      .do             .DS             .En
 .EP              .EX             .Fi             .hw             .i
 .Id              .l              .LO             .mf             .mso
 .N               .na             .NF             .nh             .nl
 .Nm              .ns             .NXR            .OPTIONS        .PB
 .pp              .PR             .PRE            .PU             .REq
 .RH              .rn             .S<             .sh             .SI
 .splitfont       .Sx             .T              .TF             .The
 .TT              .UC             .ul             .Vb             .zZ

=head2 Don't escape spaces to make them non-breaking.

Some authors escape spaces to make sure that the wrapping tool won't mangle
them. po4a::man I<will> eat them. Use the .nf/.fi groff macro to control
wheather the text should be wrapped or not.

=head2 Don't mess nest font specifier.

In order to make translator's life easier, po4a::man will change all font
specifiers in the way explained above. This process is sometimes fragile,
and need some love from you. For example, don't write the following:

  \fB bold text \fI italic text \fR back to roman

Instead, always close all font modifier like that:

  \fB bold text \fR\fI italic text \fR back to roman

Note that what is forbidden is to close several modifiers with only one
\fR. Nesting modifiers is not allowed either (for now), so the following
won't work:

  \fB bold \fI italic\fP bold again \fR

Likewise, using the '.ft' macro to change the font for several paragraphs
and commands is badly supported for now.

=head2 Conclusion

To summarise this section, keep simple, and don't try to be cleaver while
authoring your man pages. A lot of things are possible in nroff, and not
supported by this parser. For example, don't try to mess with \c to
interrupt the text processing (like 40 pages on my box do). Or, be sure to
put the macro arguments on the same line that the macro itself. I know that
it's valid in nroff, but would complicate too much the parser to be
handled.

Of course, another possibility is to use another format, more translator
friendly (like pod using po4a::pod, or one of the xml familly like sgml),
but thanks to po4a::man it isn't needed anymore. That being said, if the
source format of your documentation is pod, or xml, it may be cleaver to
translate the source format and not this generated one. In most case,
po4a::man will detect generated pages and issue a warning. It will even
refuse to process Pod generated pages, because those pages are perfectly
handled by po4a::pod, and because their nroff counterpart defines a lot of
new macros I didn't want to write support for. On my box, 1432 of the 4323
pages are generated from pod and will be ignored by po4a::man.

In most cases, po4a::man will detect the problem and refuse to process the
page, issuing an adapted message. In some rare cases, the program will
complete without warning, but the output will be wrong. Such cases are
called "bugs" ;) If you encounter such case, be sure to report this, along
with a fix when possible...

=head1 STATUS OF THIS MODULE

I think that this module is still beta, but could be used for most of the
existing man pages. I ran some test, processing all pages of my box and
diff'ing between the original and the version processed trough po4a. The
results are the following:

 # of pages         : 4323

 Ignored pages      : 1432 (33%)
 parser fails       :  850 (20% of all; 29% of unignored)

 works perfectly    : 1660 (38% of all; 57% of unignored; 81% of processed)
 change wrapping    :  239 ( 5% of all;  8% of unignored; 12% of processed)

 undetected problems:  142 ( 3% of all;  5% of unignored;  7% of processed)

Ignored pages are so, because they are generated from Pod, and should be
translated with po4a::pod.

Parser fails on pages based on mdoc(7), pages using conditionals with .if,
defining new macros with .de, and more generally, not following the advices
of previous section.

Pages with undetected problems are processed without complain by po4a::man,
but the generated output is different from the original one. In most cases,
only the formating did change (ie, which chars are italics, which ones are
bold, but it may be more serious). All of them are bugs, but I failed to
eradicated all of them so far.

So, it seems like since ignored pages are translatable with po4a::pod and
since wrapping changes are acceptables in most cases, the current version
of po4a can translate 76% of the man pages on my machine. Moreover, most of
the untranslatable pages could be fixed with some simple tricks given
above. Isn't that coooool?

=head1 SEE ALSO

L<po4a(7)>, L<Locale::Po4a::TransTranctor(3pm)>,
L<Locale::Po4a::Pod(3pm)>.

=head1 AUTHORS

 Denis Barbier <barbier@linuxfr.org>
 Martin Quinson <martin.quinson@tuxfamily.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by SPI, inc.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see COPYING file).

=cut

package Locale::Po4a::Man;

use 5.006;
use strict;
use warnings;

require Exporter;
use vars qw($VERSION @ISA @EXPORT);
$VERSION=$Locale::Po4a::TransTractor::VERSION;
@ISA = qw(Locale::Po4a::TransTractor);
@EXPORT = qw();#  new initialize);
use Locale::Po4a::TransTractor;
use Locale::gettext qw(gettext);

use File::Spec;
use Getopt::Std;

my %macro; # hash of known macro, with parsing sub. See end of this file

sub initialize {}

#########################
#### DEBUGGING STUFF ####
#########################
my %debug=('splitargs' => 0, # see how macro args are separated
	   'pretrans' => 0,  # see pre-conditioning of translation
	   'postrans' => 0,  # see post-conditioning of translation
	   );

###############################################
#### FUNCTION TO TRANSLATE OR NOT THE TEXT ####
###############################################
sub pushmacro {
    my $self=shift;
    if (scalar @_) { 
	$self->pushline(join(" ",map { defined $_ ? 
					 (
					   $_ eq '0' ? "0" 
					             : ( length($_) && m/ / ? "\"$_\"" 
							                    : "$_"||'""'
						       )
				         ) : ''
				     } @_)."\n");
    } else {
	$self->pushline("\n");
    }
}
sub this_macro_needs_args {
    my ($macroname,$ref,$args)=@_;
    unless (length($args)) {
	die sprintf(gettext(
		"po4a::man: %s: macro %s called without arguments.\n".
		"po4a::man: Even if placing the macro arguments on the next line is authorized\n".
		"po4a::man: by man(7), handling this would make the po4a parser too complicate.\n".
		"po4a::man: Please simply put the macro args on the same line."
		),$ref,$macroname)."\n";
    }
}

sub pre_trans {
    my ($self,$str,$ref,$type)=@_;
    # Preformating, so that translators don't see 
    # strange chars
    my $origstr=$str;
    print STDERR "pre_trans($str)="
	if ($debug{'pretrans'});
    $str =~ s/>/E<gt>/g;
    $str =~ s/</E<lt>/g;
    $str =~ s/EE<lt>gt>/E<gt>/g; # could be done in a smarter way?

    $str =~ s/\\f([SBI])(([^\\]*\\[^f])?.*?)\\f([PR])/$1<$2>/sg;
    $str =~ s/\\fR(.*?)\\f[RP]/$1/sg;
    if ($str =~ /\\f[RSBI]/) {
	die sprintf(gettext(
		"po4a::man: %s: Nested font modifiers, ie, something like:\n".
		"po4a::man:  \\fB bold text \\fI italic text \\fR back to roman\n".
		"po4a::man: This is not supported, modify the original page to something like:\n".
		"po4a::man:  \\fB bold text \\fR back to roman \\fI italic text \\fR back to roman\n".
		"po4a::man: Here is the faulty line:\n".
		" %s"),$ref,$origstr)."\n";
    }
    
# The next commented loop should take care of badly nested font modifiers,
#  if only it worked ;)
#
#    while ($str =~ /^(.*)\\f([BI])(.*?)\\f([PR])(.*)$/) {
#	my ($before,$kind,$txt,$end,$after)=($1,$2,$3,$4,$5);
#	if ($txt =~ /(.*)\\f([BI])(.*)/) {
#	    my ($inbefore,$kind2,$inafter)=($1,$2,$3);
#	    #damned, we have something like:
#	    # \fB bla\fI bli\fR
#	    if ($end eq 'R') {
#		# close the to modifier
#		$str = "$before$kind<$inbefore$kind2<$inafter>>$after";
#	    } else {
#		# move back to the first modifier. 
#		#Use another pass in the loop to handle external modifier
#		$str = "$before\\f$kind$inbefore$kind2<$inafter>$after";
#	    }
#	} else {
#	    # man authors are not always vicious (only often)
#	    $str = "$before$kind<$txt>$after";
#	}
#    }


#    $str =~ s|\\-|-|g;
    print STDERR "$str\n" if ($debug{'pretrans'});
    return $str;
}

sub post_trans {
    my ($self,$str,$ref,$type)=@_;
    my $transstr=$str;

    print STDERR "post_trans($str)="
	if ($debug{'postrans'});

    # Post formating, so that groff see the strange chars
#    $str =~ s|-|\\-|mg;

    # No . on first char, or nroff will think it's a macro
    $str =~ s/\n([.'"])/ $1/mg; #'

    # Make sure we compute internal sequences right.
    # think about: B<AZE E<lt> EZA E<gt>>
    while ($str =~ m/^(.*)([RSBI])<(.*)$/s) {
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
	die sprintf(gettext("po4a::man: %s: Unbalanced '<' and '>' in '%s'"),$ref||$self->{ref},$transstr)."\n"
	    if ($lvl > 0);
	$done .= "\\fR$rest";
	$str=$done;
    }

    $str =~ s/E<gt>/>/mg;
    $str =~ s/E<lt>/</mg;
    # Don't do that, because we'll go into trouble if previous line was .TP
    $str =~ s/^\\f([BI])(.*?)\\f[RP]$/\.$1 $2/mg;
    print STDERR "$str\n" if ($debug{'postrans'});
    return $str;
}
sub translate {
    my ($self,$str,$ref,$type) = @_;
    my (%options)=@_;
    my $origstr=$str;
    
    return $str unless (defined $str) && length($str);

    $str=pre_trans($self,$str,$ref||$self->{ref},$type);
    # Translate this
    $str = $self->SUPER::translate($str,
				   $ref||$self->{ref},
				   $type || $self->{type},
				   %options);
    if ($options{'wrap'}) {
	my (@paragraph);
	@paragraph=split (/\n/,$str);
	if (defined ($paragraph[0]) && $paragraph[0] eq '') {
	    shift @paragraph;
	}
	$str = join("\n",@paragraph)."\n";
    }
    $str=post_trans($self,$str,$ref||$self->{ref},$type);
    return $str;
}

# shortcut
sub t { 
    my ($self,$str)=(shift,shift);
    return $self->translate($str);
}


sub do_paragraph {
    my ($self,$paragraph,$wrapped_mode) = (shift,shift,shift);

    # Following needed because of 'ft' (at least, see ft macro below)
    unless ($paragraph =~ m/\n$/s) {
	my @paragraph = split(/\n/,$paragraph);

	$paragraph .= "\n"
	    unless scalar (@paragraph) == 1;
    }

    $self->pushline( $self->translate($paragraph,$self->{ref},"Plain text",
				      "wrap" => ($wrapped_mode eq 'YES') ) );
}

#############################
#### MAIN PARSE FUNCTION ####
#############################
sub parse{
    my $self = shift;
    my ($line,$ref);
    my ($paragraph)=""; # Buffer where we put the paragraph while building
    my $wrapped_mode='YES'; # Should we wrap the paragraph? Three possible values: 
                            # YES: do wrap
                            # NO: don't wrap because this paragraph contains indented lines
                            #     this status disapear after the end of the paragraph
                            # MACRONO: don't wrap because we saw the nf macro. It stays so 
                            #          until the next fi macro.

  LINE:
    ($line,$ref)=$self->shiftline();
    
    while (defined($line)) {
#	print STDERR "line=$line;ref=$ref";
	chomp($line);
	while ($line =~ /\\$/) {
	    my ($l2,$r2)=$self->shiftline();
	    chomp($l2);
	    $line =~ s/\\$//;
	    $line .= $l2;
	}
	$self->{ref}="$ref";
#	print STDERR "LINE=$line<<\n";
	die sprintf(gettext("po4a::man: %s: Escape sequence \\c encountered. This is not handled yet.")
			    ,$ref)."\n"
	    if ($line =~ /\\c/);


	if ($line =~ /^\./) {
	    die sprintf(gettext("po4a::man: Unparsable line: %s"),$line)."\n"
		unless ($line =~ /^\.+\\*?(\\\")(.*)/ ||
			$line =~ /^\.([BI])(\W.*)/ ||
			$line =~ /^\.(\S*)(.*)/);
	    my $macro=$1;
	    
	    # Split on spaces for arguments, but not spaces within double quotes
	    my @args=();
	    my $buffer="";
	    my $escaped=0;
	    foreach my $elem (split (/ +/,$line)) {
		print STDERR ">>Seen $elem(buffer=$buffer;esc=$escaped)\n"
		    if ($debug{'splitargs'});

		if (length $buffer && !($elem=~ /\\$/) ) {
		    $buffer .= " ".$elem;
		    print STDERR "Continuation of a quote\n"
			if ($debug{'splitargs'});
		    # print "buffer=$buffer.\n";
		    if ($buffer =~ m/^"(.*)"(.+)$/) {
			print STDERR "End of quote, with stuff after it\n"
			    if ($debug{'splitargs'});
			push @args,$1;
			push @args,$2;
			$buffer = "";
		    } elsif ($buffer =~ m/^"(.*)"$/) {
			print STDERR "End of a quote\n"
			    if ($debug{'splitargs'});
			push @args,$1;
			$buffer = "";
		    } elsif ($escaped) {
			print STDERR "End of an escaped sequence\n"
			    if ($debug{'splitargs'});
			unless(length($elem)){
				die sprintf(gettext(
					"po4a::man: %s: Escaped space at the end of macro arg. With high\n".
					"po4a::man: probability, it won't do the trick with po4a (because of\n".
					"po4a::man: wrapping). You may want to remove it and use the .nf/.fi groff\n".
					"po4a::man: macro to control the wrapping."),
					 $ref)."\n";
			}
			push @args,$buffer;
			$buffer = "";
			$escaped = 0;
		    }
		} elsif ($elem =~ m/^"(.*)"$/) {
		    print STDERR "Quoted, no space\n"
			if ($debug{'splitargs'});
		    push @args,$1;
		} elsif ($elem =~ m/^"/) { #") {
		    print STDERR "Begin of a quoting arg\n"
			if ($debug{'splitargs'});
		    $buffer=$elem;
		} elsif ($elem =~ m/^(.*)\\$/) {
		    print STDERR "escaped space after $1\n"
			if ($debug{'splitargs'});
		    # escaped space
		    $buffer = ($buffer?$buffer:'').$1." ";
		    $escaped = 1; 
		} else {
		    print STDERR "Unquoted arg, nothing to declare\n"
			if ($debug{'splitargs'});
		    push @args,$elem;
		    $buffer=""
		}
	    }
	    if ($buffer) {
		$buffer=~ s/"//g; #"
		push @args,$buffer;
	    }
	    if ($debug{'splitargs'}) {
		print STDERR "ARGS=";
		map { print STDERR "$_^"} @args;
		print STDERR "\n";
	    }
			  

	    if ($macro eq 'B' || $macro eq 'I') {
		# pass macro name
		shift @args;
		my $arg=join(" ",@args);
		$arg =~ s/^ //;
		this_macro_needs_args($macro,$ref,$arg);
		$paragraph .= "\\f$macro".$arg."\\fP\n";
		goto LINE;
	    }
	    # .BI bold alternating with italic
	    # .BR bold/roman
	    # .IB italic/bold
	    # .IR italic/roman
	    # .RB roman/bold
	    # .RI roman/italic
	    # .SB small/bold
	    if ($macro eq 'BI' || $macro eq 'BR' || $macro eq 'IB' || 
		$macro eq 'IR' || $macro eq 'RB' || $macro eq 'RI' ||
		$macro eq 'SB') {
		# pass macro name
		shift @args;
		# num of seen args, first letter of macro name, second one
		my ($i,$a,$b)=(0,substr($macro,0,1),substr($macro,1));
		# Do the job
#		$self->pushline(".br\n") unless (length($paragraph));
		$paragraph.= #($paragraph?"":" ").
		             join("",
				  map { $i++ % 2 ? 
					    "\\f$b$_\\fP" :
					    "\\f$a$_\\fP"
				      } @args)."\n";
		goto LINE;
	    }

	    if ($paragraph) {
		do_paragraph($self,$paragraph,$wrapped_mode);
		$paragraph="";
		$wrapped_mode = $wrapped_mode eq 'NO' ? 'YES' : $wrapped_mode;
	    }

	    # Special case: Don't change these lines
	    # Check for comments indicating that the file was generated.
	    if ($macro eq '\"' ||
		$macro eq '"') {
		if ($line =~ /Pod::Man/) {
		    warn gettext("This file was generated with Pod::Man. Translate the pod file with the pod module of po4a.")."\n";
		    exit 0;
		} elsif ($line =~ /generated by help2man/)    {
		    warn gettext("This file was generated with help2man. Translate the source file with the regular gettext.")."\n";
		} elsif ($line =~ /with docbook-to-man/)      { 
		    warn gettext("This file was generated with docbook-to-man. Translate the source file with the sgml module of po4a.")."\n";
		    exit 0;
		} elsif ($line =~ /generated by docbook2man/) { 
		    warn gettext("This file was generated with docbook2man. Translate the source file with the sgml module of po4a.")."\n";
		    exit 0;
		} elsif ($line =~ /created with latex2man/)   { 
		    warn sprintf(gettext(
					"This file was generated with %s.\n".
					"You should translate the source file, but continuing anyway."
					),"latex2man")."\n";
		} elsif ($line =~ /Generated by db2man.xsl/)  { 
		    warn sprintf(gettext(
					"This file was generated with %s.\n".
					"You should translate the source file, but continuing anyway."
					),"db2man.xsl")."\n";
		} elsif ($line =~ /generated automatically by mtex2man/)  {
		    warn sprintf(gettext(
					"This file was generated with %s.\n".
					"You should translate the source file, but continuing anyway."
					),"mtex2man")."\n";
		} elsif ($line =~ /THIS FILE HAS BEEN AUTOMATICALLY GENERATED.  DO NOT EDIT./ ||
		         $line =~ /DO NOT EDIT/i || $line =~ /generated/i) {
		    warn sprintf(gettext(
					"This file contains the line '%s'.\n".
					"You should translate the source file, but continuing anyway."
					),"$line")."\n";
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
		if ($macro eq 'fi') {
		    $wrapped_mode='MACRONO';
		} else {
		    $wrapped_mode='YES';
		}
		$self->pushline($line."\n");
		goto LINE;
	    }		

	    # Special case:
	    #  .Dd => Indicates that this is a mdoc page
	    if ($macro eq 'Dd') {
		die gettext(
			"po4a::man: This page seems to be a mdoc(7) formated one.\n".
			"po4a::man: This is not supported (yet).")."\n";
	    }
		
	    unshift @args,$self;
	    # Apply macro
	    $self->{type}=$macro;

	    if (defined ($macro{$macro})) {
		&{$macro{$macro}}(@args);
	    } else {
		$self->pushline($line."\n");
		die sprintf(gettext(
		    "po4a::man: Unknown macro '%s' (at %s).\n".
		    "po4a::man: Remove it from the document, or provide a patch to the po4a team."
				),$line,$ref)."\n";
	    }

	} elsif ($line =~ /^( +)([^.].*)/) {
	    # Not a macro, but not a wrapped paragraph either
	    $wrapped_mode='NO';
	    $paragraph .= $line."\n";
	} elsif ($line =~ /^([^.].*)/) {
	    # Not a macro
	    $paragraph .= $line."\n";
	} else { #empty line
	    do_paragraph($self,$paragraph,$wrapped_mode);
	    $paragraph="";
	    $wrapped_mode = $wrapped_mode eq 'NO' ? 'YES' : $wrapped_mode;
	    $self->pushline($line."\n");
	}

	# Reinit the loop
	($line,$ref)=$self->shiftline();
    }

    if ($paragraph) {
	do_paragraph($self,$paragraph,$wrapped_mode);
	$wrapped_mode = $wrapped_mode eq 'NO' ? 'YES' : $wrapped_mode;
	$paragraph="";
    }
} # end of main


sub docheader {
    return ".\\\" This file was generated with po4a. Translate the source file.\n".
           ".\\\" \n";
}


##########################################
#### DEFINITION OF THE MACROS WE KNOW ####
##########################################
# Each sub is passed self as first arg,
#   plus the args present on the roff line
#   ie, <<.TH LS "1" "October 2002" "ls (coreutils) 4.5.2" "User Commands">>
#   is passed (".TH","LS","1","October 2002","ls (coreutils) 4.5.2","User Commands")
#   Macro name is also passed, because .B (bold) will be encoded in pod format (and mangeled).
# They should return a list, which will be join'ed(' ',..)
#   or undef when they don't want to add anything

# Some well known macro handling

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
		     $section,
		     $self->t($date),
		     $self->t($source),
		     $self->t($manual));
};

# .SS t    Subheading t (like .SH, but used for a subsection inside a section).
$macro{'SS'}=$macro{'SH'}=\&translate_joined;

$macro{'SM'}=\&translate_joined;


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
    $self->pushline($line."\n");

    ($l2,$ref2) = $self->shiftline();
    chomp($l2);
    while ($l2 =~ /^\.PD/) {
	$self->pushline($l2."\n");
	($l2,$ref2) = $self->shiftline();
	chomp($l2);
    }
    $self->pushline($self->t($l2)."\n");
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

# Hypertext Link Macros
#  .UR u  Begins a hypertext link to the URI (URL) u; it will end with
#         the corresponding UE command. When generating HTML this should
#         translate into the HTML command <A HREF="u">.
#         There is an exception: if u is the special value ":", then no
#         hypertext link of any kind will be generated until after the
#         closing UE (this permits disabling hypertext links in
#         phrases like LALR(1) when linking is not appropriate). 
#  .UE    Ends the corresponding UR command; when generating HTML this
#         should translate into </A>.
#  .UN u  Creates a named hypertext location named u; do not include a
#         corresponding UE  command.
#         When generating HTML this should translate into the HTML command
#         <A  NAME="u" id="u">&nbsp;</A>
$macro{'UR'}=sub {
    return untranslated(@_) 
	if (defined($_[2]) && $_[2] eq ':');
    return translate_joined(@_);
};
$macro{'UE'}=\&noarg;
$macro{'UN'}=\&translate_joined;

# Miscellaneous Macros
#  .DT      Reset tabs to default tab values (every 0.5 inches); does not
#           cause a break.
#  .PD d    Set inter-paragraph vertical distance to d (if omitted, d=0.4v);
#            does not cause a break.
$macro{'DT'}=\&noarg;
$macro{'PD'}=\&untranslated;

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
# .bp N      Eject current page and begin new page.
$macro{'bp'}=\&untranslated;
# .ad       Begin line adjustment for output lines in current adjust mode.
# .ad c     Start line adjustment in mode c (c=l,r,b,n).
$macro{'ad'}=\&untranslated;
# .de macro Define or redefine macro until .. is encountered.
$macro{'de'}=sub {
    die gettext(
			"po4a::man: This page defines a new macro with '.de'. Since po4a is not a\n".
			"po4a::man: real groff parser, this is not supported.")."\n";
};
# .ds stringvar anything
#                 Set stringvar to anything.
$macro{'ds'}=\&untranslated;
#       .fam      Return to previous font family.
#       .fam name Set the current font family to name.
$macro{'fam'}=\&untranslated;
# .fc a b   Set field delimiter to a and pad character to b.
$macro{'fc'}=\&untranslated;
# .ft font  Change to font name or number font;
$macro{'ft'}=\&untranslated;
# .hc c     Set up additional hyphenation indicator character c.
$macro{'hc'}=\&untranslated;
# .hy N     Switch to hyphenation mode N.
# .hym n    Set the hyphenation margin to n (default scaling indicator m).
# .hys n    Set the hyphenation space to n.
$macro{'hy'}=$macro{'hym'}=$macro{'hys'}=\&untranslated;

# .ie cond anything  If cond then anything else goto .el.
# .if cond anything  If cond then anything; otherwise do nothing.
$macro{'ie'}=$macro{'if'}=sub {
    die sprintf(gettext(
			"po4a::man: This page uses conditionals with '%s'. Since po4a is not a real\n".
			"po4a::man: groff parser, this is not supported.",$_[1]))."\n";
};
# .in  N    Change indent according to N (default scaling indicator m).
$macro{'in'}=\&untranslated;

# .ig end   Ignore text until .end.
$macro{'ig'}=sub {
    my $self = shift;
    $self->pushmacro(@_);
    my ($name,$end) = (shift,shift||'');
    $end='' if ($end =~ m/^\\\"/);
    my ($line,$ref)=$self->shiftline();
    while (defined($line)) {
	$self->pushline($line);
	last if ($line =~ /^\.$end\./);
	($line,$ref)=$self->shiftline();
    }
};

# .lf N file  Set input line number to N and filename to file.
$macro{'lf'}=\&untranslated;
# .ll N     Set line length according to N
$macro{'ll'}=\&untranslated;

# .ne N     Need N vertical space
$macro{'ne'}=\&untranslated;
# .nr register N M
#         Define or modify register
$macro{'nr'}=\&untranslated;
# .ps N    Point size; same as \s[N]
$macro{'ps'}=\&untranslated;
# .so filename Include source file.
$macro{'so'}=\&translate_joined;
# .sp     Skip one line vertically.
# .sp N   Space  vertical distance N
$macro{'sp'}=\&untranslated;
# .ta T N   Set tabs after every position that is a multiple of N.
# .ta n1 n2 ... nn T r1 r2 ... rn
#           Set  tabs at positions n1, n2, ..., nn, [...]
$macro{'ta'}=\&untranslated;
# .ti +N    Temporary indent next line (default scaling indicator m).
$macro{'ti'}=\&untranslated;


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

###
### BSD compatibility macros: .AT and .UC
### (define the version of Berkley used)
### FIXME: the header ("3rd Berkeley Distribution" or such) declared 
###        by this macro isn't translatable we may want to remove 
###        this from the generated manpage, and declare our own header
###
$macro{'UC'}=$macro{'AT'}=\&untranslated;
