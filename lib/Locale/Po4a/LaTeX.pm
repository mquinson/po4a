#!/usr/bin/perl -w

# Copyright (c) 2004, 2005 by Nicolas FRANÇOIS <nicolas.francois@centraliens.net>
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

Locale::Po4a::LaTeX - Convert LaTeX documents and derivates from/to PO files

=head1 DESCRIPTION

The po4a (po for anything) project goal is to ease translations (and more
interestingly, the maintenance of translations) using gettext tools on
areas where they were not expected like documentation.

Locale::Po4a::LaTeX is a module to help the translation of LaTeX documents into
other [human] languages. It can also be used as a base to build modules for
LaTeX-based documents.

This module contains the definitions of common LaTeX commands and
environments.

=head1 SEE ALSO

L<po4a(7)|po4a.7>,
L<Locale::Po4a::TransTractor(3pm)|Locale::Po4a::TransTractor>,
L<Locale::Po4a::TeX(3pm)|Locale::Po4a::TeX>.

=head1 AUTHORS

 Nicolas François <nicolas.francois@centraliens.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, 2005 by Nicolas FRANÇOIS <nicolas.francois@centraliens.net>.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see COPYING file).

=cut

package Locale::Po4a::LaTeX;

use 5.006;
use strict;
use warnings;

require Exporter;
use vars qw($VERSION @ISA @EXPORT);
$VERSION= $Locale::Po4a::TeX::VERSION;
@ISA= qw(Locale::Po4a::TeX);
@EXPORT= qw();

use Locale::Po4a::TeX;
use subs qw(&untranslated     &translate_joined
            &push_environment &parse_definition_file
            &register_generic);
*untranslated          = \&Locale::Po4a::TeX::untranslated;
*translate_joined      = \&Locale::Po4a::TeX::translate_joined;
*push_environment      = \&Locale::Po4a::TeX::push_environment;
*parse_definition_file = \&Locale::Po4a::TeX::parse_definition_file;
*register_generic      = \&Locale::Po4a::TeX::register_generic;
use vars qw($RE_ESCAPE            $ESCAPE
            $no_wrap_environments $separated_commands
            %commands             %environments
            %command_categories   %separated
            %env_separators
            @exclude_include);
*RE_ESCAPE             = \$Locale::Po4a::TeX::RE_ESCAPE;
*ESCAPE                = \$Locale::Po4a::TeX::ESCAPE;
*no_wrap_environments  = \$Locale::Po4a::TeX::no_wrap_environments;
*separated_commands    = \$Locale::Po4a::TeX::separated_commands;
*commands              = \%Locale::Po4a::TeX::commands;
*environments          = \%Locale::Po4a::TeX::environments;
*command_categories    = \%Locale::Po4a::TeX::command_categories;
*separated             = \%Locale::Po4a::TeX::separated;
*env_separators        = \%Locale::Po4a::TeX::env_separators;
*exclude_include       = \@Locale::Po4a::TeX::exclude_include;


# documentclass:
# Only read the documentclass in order to find some po4a directives.
# FIXME: The documentclass could contain translatable strings.
# Maybe it should be implemented as \include{}.
$separated_commands .= " documentclass";
$commands{'documentclass'} = sub {
    my $self = shift;
    my ($command,$variant,$opts,$args,$env) = (shift,shift,shift,shift,shift);

    # Only try to parse the file.  We don't want to fail or parse this file
    # if it is a standard documentclass.
    parse_definition_file($self, $args->[0].".cls", 1);

    my ($t,@e) = untranslated($self,$command,$variant,$opts,$args,$env);

    return ($t, @$env);
};

# LaTeX 2
# I choosed not to translate files, counters, lengths
register_generic("*addcontentsline,0,3,,3");
register_generic("address,0,1,,1");           # lines are seperated by \\
register_generic("*addtocontents,0,2,,2");
register_generic("*addtocounter,0,2,,");
register_generic("*addtolength,0,2,,");
register_generic("*addvspace,0,1,,");
register_generic("alph,0,1,,");               # another language may not want this alphabet
register_generic("arabic,0,1,,");             # another language may not want an arabic numbering
register_generic("*author,0,1,,1");           # authors are separated by \and
register_generic("bibitem,1,1,,");
register_generic("*bibliographystyle,0,1,,"); # BibTeX
register_generic("*bibliography,0,1,,");      # BibTeX
register_generic("*centerline,0,1,,1");
register_generic("*caption,1,1,,1");
register_generic("cc,0,1,,1");
register_generic("circle,1,1,,");
register_generic("cite,1,1,1,");
register_generic("cline,0,1,,");
register_generic("closing,0,1,,1");
register_generic("dashbox,0,1,,");            # followed by a (w,h) argument
register_generic("date,0,1,,1");
register_generic("*enlargethispage,0,1,,");
register_generic("ensuremath,0,1,,1");
register_generic("*fbox,0,1,,1");
register_generic("fnsymbol,0,1,,");
register_generic("*footnote,1,1,,1");
register_generic("*footnotemark,1,0,,");
register_generic("*footnotetext,1,1,,1");
register_generic("frac,0,2,,1 2");
register_generic("*frame,0,1,,1");
register_generic("*framebox,2,1,,1");         # There is another form in picture environment
register_generic("*hspace,1,1,,");
register_generic("*hyphenation,0,1,,1");      # Translators may wish to add/remove words
register_generic("include,0,1,,");            # file
#register_generic("includeonly,0,1,,");       # should not be supported for now
register_generic("input,0,1,,");              # file
register_generic("*item,1,0,1,");
register_generic("*label,0,1,,");
register_generic("lefteqn,0,1,,1");
register_generic("line,0,0,,");               # The first argument is (x,y)
register_generic("*linebreak,1,0,,");
register_generic("linethickness,0,1,,");
register_generic("location,0,1,,1");
register_generic("makebox,2,1,,1");           # There's another form in picture environment
register_generic("makelabels,0,1,,");
register_generic("*markboth,0,2,,1 2");
register_generic("*markright,0,1,,1");
register_generic("mathcal,0,1,,1");           #
register_generic("mathop,0,1,,1");
register_generic("mbox,0,1,,1");
register_generic("multicolumn,0,3,,3");
register_generic("multiput,0,0,,");           # The first arguments are (x,y)(dx,dy)
register_generic("name,0,1,,1");
register_generic("*newcommand,0,-1,,2");      # The second argument is [args]
register_generic("*newcounter,0,1,,");        # The second argument is [counter]
register_generic("*newenvironment,-1,-1,,");  # The second argument is [args]
register_generic("*newfont,0,2,,");
register_generic("*newlength,0,1,,");
register_generic("*newsavebox,0,1,,");
register_generic("*newtheorem,0,2,,2");       # Two forms, the optionnal arg is not the first one
register_generic("nocite,0,1,,");
register_generic("nolinebreak,1,0,,");
register_generic("*nopagebreak,1,0,,");
register_generic("opening,0,1,,1");
register_generic("oval,0,0,,");               # The first argument is (w,h)
register_generic("overbrace,0,1,,1");
register_generic("overline,0,1,,1");
register_generic("*pagebreak,1,0,,");
register_generic("*pagenumbering,0,1,,1");
register_generic("pageref,0,1,,");
register_generic("*pagestyle,0,1,,");
register_generic("*parbox,3,2,,2");
register_generic("providecommand,0,1,,");     #
register_generic("put,0,0,,");                # The first argument is (x,y)
register_generic("raisebox,0,1,,");           # Optional arguments in 2nd & 3rd position
register_generic("ref,0,1,,");
register_generic("*refstepcounter,0,1,,");
register_generic("*renewcommand,0,-1,,");     # The second argument is [args]
register_generic("*renewenvironment,0,1,,");  # The second argument is [args]
register_generic("roman,0,1,,");              # another language may not want a roman numbering
register_generic("rule,1,2,,,");
register_generic("savebox,0,1,,");            # Optional arguments in 2nd & 3rd position
register_generic("sbox,0,2,,2");
register_generic("*setcounter,0,2,,");
register_generic("*setlength,0,2,,");
register_generic("*settodepth,0,2,,2");
register_generic("*settoheight,0,2,,2");
register_generic("*settowidth,0,2,,2");
register_generic("shortstack,1,1,,1");
register_generic("signature,0,1,,1");
register_generic("sqrt,1,1,1,1");
register_generic("stackrel,0,2,,1 2");
register_generic("stepcounter,0,1,,");
register_generic("*subfigure,1,1,1,1");
register_generic("symbol,0,1,,1");
register_generic("telephone,0,1,,1");
register_generic("thanks,0,1,,1");
register_generic("*thispagestyle,0,1,,");
register_generic("*title,0,1,,1");
register_generic("typeout,0,1,,1");
register_generic("typein,1,1,,1");
register_generic("twocolumn,1,0,1,");
register_generic("underbrace,0,1,,1");
register_generic("underline,0,1,,1");
register_generic("*usebox,0,1,,");
register_generic("usecounter,0,1,,");
register_generic("*usepackage,1,1,,");
register_generic("value,0,1,,");
register_generic("vector,0,0,,");             # The first argument is (x,y)
register_generic("vphantom,0,1,,1");
register_generic("*vspace,1,1,,");

register_generic("*part,1,1,1,1");
register_generic("*chapter,1,1,1,1");
register_generic("*section,1,1,1,1");
register_generic("*subsection,1,1,1,1");
register_generic("*subsubsection,1,1,1,1");
register_generic("*paragraph,1,1,1,1");
register_generic("*subparagraph,1,1,1,1");

register_generic("textrm,0,1,,1");
register_generic("textit,0,1,,1");
register_generic("emph,0,1,,1");
register_generic("textmd,0,1,,1");
register_generic("textbf,0,1,,1");
register_generic("textup,0,1,,1");
register_generic("textsl,0,1,,1");
register_generic("textsf,0,1,,1");
register_generic("textsc,0,1,,1");
register_generic("texttt,0,1,,1");
register_generic("textnormal,0,1,,1");
register_generic("mathrm,0,1,,1");
register_generic("mathsf,0,1,,1");
register_generic("mathtt,0,1,,1");
register_generic("mathit,0,1,,1");
register_generic("mathnormal,0,1,,1");
register_generic("mathversion,0,1,,");

register_generic("*contentspage,0,0,,");
register_generic("*tablelistpage,0,0,,");
register_generic("*figurepage,0,0,,");

register_generic("*PassOptionsToPackage,0,2,,");

register_generic("*ifthenelse,0,3,,2 3");

# graphics
register_generic("*includegraphics,1,1,,");
register_generic("*graphicspath,0,1,,");
register_generic("*resizebox,0,3,,3");
register_generic("*scalebox,0,2,,2");
register_generic("*rotatebox,0,2,,2");

# url
register_generic("UrlFont,0,1,,");
register_generic("*urlstyle,0,1,,");

# hyperref
register_generic("href,0,2,0,2");             # 1:URL
register_generic("url,0,1,,");                # URL
register_generic("nolinkurl,0,1,,");          # URL
register_generic("hyperbaseurl,0,1,,");       # URL
register_generic("hyperimage,0,1,,");         # URL
register_generic("hyperdef,0,3,,3");          # 1:category, 2:name
register_generic("hyperref,0,4,,4");          # 1:URL, 2:category, 3:name
register_generic("hyperlink,0,2,,2");         # 1:name
register_generic("*hypersetup,0,1,,1");
register_generic("hypertarget,0,2,,2");       # 1:name
register_generic("autoref,0,1,,");            # 1:label

register_generic("*selectlanguage,0,1,,");

# color
register_generic("*definecolor,0,3,,");
register_generic("*textcolor,0,2,,2");
register_generic("*colorbox,0,2,,2");
register_generic("*fcolorbox,0,3,,3");
register_generic("*pagecolor,0,1,,1");
register_generic("*color,0,1,,1");

# equations/theorems
register_generic("*qedhere,0,0,,");
register_generic("*qedsymbol,0,0,,");
register_generic("*theoremstyle,0,1,,");
register_generic("*proclaim,0,1,,1");
register_generic("*endproclaim,0,0,,");
register_generic("*shoveleft,0,1,,1");
register_generic("*shoveright,0,1,,1");

# commands without arguments. This is better than untranslated or
# translate_joined because the number of arguments will be checked.
foreach (qw(a *appendix *backmatter backslash *baselineskip *baselinestretch bf
            *bigskip boldmath cal cdots *centering *cleardoublepage *clearpage
            ddots dotfill em flushbottom *footnotesize frenchspacing
            *frontmatter *glossary *hfill *hline hrulefill huge Huge indent it
            kill large Large LARGE ldots left linewidth listoffigures
            listoftables *mainmatter *makeatletter *makeglossary *makeindex
            *maketitle *medskip *newline *newpage noindent nonumber *normalsize
            not *null *onecolumn *par parindent *parskip *printindex protect ps
            pushtabs *qquad *quad raggedbottom raggedleft raggedright right rm
            sc scriptsize sf sl small *smallskip *startbreaks *stopbreaks
            *tableofcontents textwidth textheight tiny today tt unitlength
            vdots verb *vfill *vline *fussy *sloppy

            aleph hbar imath jmath ell wp Re Im prime nabla surd angle forall
            exists partial infty triangle Box Diamond flat natural sharp
            clubsuit diamondsuit heartsuit spadesuit dag ddag S P copyright
            pounds Delta ASCII

            rmfamily itshape mdseries bfseries upshape slshape sffamily scshape
            ttfamily *normalfont width height depth totalheight

            *fboxsep *fboxrule
            *itemi *itemii *itemiii *itemiv
            *theitemi *theitemii *theitemiii *theitemiv)) {
    register_generic("$_,0,0,,");
}


$separated_commands .= " begin end hbox vbox vcenter";
$command_categories{'translate_joined'} .= " hbox vbox vcenter";

# standard environments.
foreach (qw(abstract align array cases center description displaymath enumerate
            eqnarray equation figure flushleft flushright footnotesize itemize
            letter list lrbox minipage multicols multline picture proof quotation quote
            sloppypar tabbing table tabular thebibliography theorem titlepage
            trivlist verbatim verse wrapfigure)) {
    $environments{$_} = \&push_environment;
}


# Commands and environments with separators.

# & is the cell separator, \\ is the line separator
# '\' is escaped twice
$env_separators{'tabular'} = "(?:&|\\\\\\\\)";

$env_separators{'enumerate'} = $env_separators{'itemize'} = "\\\\item";

$env_separators{'author[#1]'} = $env_separators{'title[#1]'} = "\\\\\\\\";

1;
