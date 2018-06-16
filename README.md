# Introduction to Po4a

[![Build Status](https://travis-ci.org/mquinson/po4a.svg?branch=master)](https://travis-ci.org/mquinson/po4a)

The po4a (PO for anything) project goal is to ease translations (and
more interestingly, the maintenance of translations) using gettext
tools on areas where they were not expected like documentation.

In po4a each documentation format is handled by a module. For now, we have a
module for the following formats:

  - asciidoc: AsciiDoc format.
  - dia: uncompressed Dia diagrams.
  - docbook: DocBook XML.
  - guide: Gentoo Linux's XML documentation format.
  - ini: INI format.
  - kernelhelp: Help messages of each kernel compilation option.
  - latex: LaTeX format.
  - man: Good old manual page format.
  - pod: Perl Online Documentation format.
  - sgml: either DebianDoc or DocBook DTD.
  - texinfo: The info page format.
  - tex: generic TeX documents (see also latex).
  - text: simple text document.
  - wml: WML documents.
  - xhtml: XHTML documents.
  - xml: generic XML documents (see also docbook).
  - yaml: YAML documents.

# Installation

To install this module type the following:

```
   perl Build.PL
   ./Build
   ./Build install
```

# Use without installation

If you want to use a version without installing it (e.g. directly from
the git tree), use the PERLLIB environment variable as such:

```
   PERLLIB=~/git-checkouts/po4a/lib ~/git-checkouts/po4a/po4a-gettextize [usual args]
```

# Po4a dependencies

* Locale::gettext (v1.01)

  This module being itself internationalized, it needs the Locale::gettext
  library to translate its own messages.
  If it is not present, then po4a's messages won't be translated, but
  po4a will remain fully functional.

* Text::WrapI18N

  This module is used to format po4a's warnings and error messages.  It
  permits to wrap long error messages without splitting words.
  If it is not present, the formatting of messages will be different,
  but po4a will remain fully functional.

* Term::ReadKey

  This module is used to retrieve the terminal's line width.  It is not
  used if Text::WrapI18N is not available.
  If it is not present, the line width can be specified with the COLUMN
  environment variable.


## SGML module specific dependencies

* SGMLS (1.03ii)

  This is a set of Perl5 routines for processing the output from the onsgmls
  SGML parser.

* opensp (1.5.2) OpenJade group's SGML parsing tools

  This is the SGML parser we use.

## Text module specific dependencies

* Unicode::GCString

  This module is used to compute text width; it is needed by AsciiDoc to
  determine two line titles in encodings different from ASCII.
  https://github.com/hatukanezumi/Unicode-LineBreak


## YAML module specific dependencies

* YAML::Tiny

  This module is used to parse and serialize the YAML file.

# Project hosting

 - Webpage: https://po4a.org
 - Source code: https://github.com/mquinson/po4a
 - Bug tracker: https://github.com/mquinson/po4a/issues
 - Source of the web pages: https://github.com/mquinson/po4a-website

# Copyright and license

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see COPYING file).

Copyright © 2002-2O18 by SPI, inc.

Authors:
- Denis Barbier <barbier@linuxfr.org>
- Martin Quinson (mquinson#debian.org)
