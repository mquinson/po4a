#!/usr/bin/make -f
# This file is public domain software, originally written by Joey Hess.

bins = po4a po4a-gettextize po4a-updatepo po4a-translate po4a-normalize
libs = $(basename $(notdir $(wildcard lib/Locale/Po4a/*.pm)))
docs = $(subst .7.pod,,$(notdir $(wildcard doc/*.pod)))
langs = $(basename $(notdir $(wildcard po/pod/*.po)))

package = po4a

all: build-stamp po-bin-stamp man-stamp

Build: Build.PL
	perl Build.PL installdirs=vendor

build-stamp: Build
	./Build
	./Build test
	./Build distmeta #regenerates META.yml
	touch build-stamp

po-bin-stamp:
	@echo Update the locale translations
	$(MAKE) -C po/bin
	touch po-bin-stamp

po-pod-stamp:
	@echo Update the pod translations
	$(MAKE) -C po/pod
	touch po-pod-stamp

man-stamp: po-pod-stamp
	@echo Compile the localized man pages
	-rm -rf mantmp
	mkdir mantmp
#  Woody version of pod2man does not accept the --name option,
#  so input file is temporarily copied.
	for bin in $(bins) ; do \
	  for lang in $(langs) ; do \
	    if [ -e po/pod/$$bin.$$lang.pod ] ; then \
	      mkdir -p mantmp/$$lang/man1; \
	      cp po/pod/$$bin.$$lang.pod mantmp/$$bin.pod && \
	      pod2man --section=1 --center='Po4a Tools' --release='Po4a Tools' \
	       mantmp/$$bin.pod > mantmp/$$lang/man1/$$bin.1; \
	      gzip -9 mantmp/$$lang/man1/$$bin.1; \
	      rm -f mantmp/$$bin.pod; \
	    fi; \
	  done; \
	done
	for lib in $(libs) ; do \
	  for lang in $(langs) ; do \
	    if [ -e po/pod/Locale::Po4a::$$lib.$$lang.pod ] ; then \
	      mkdir -p mantmp/$$lang/man3; \
	      cp po/pod/Locale::Po4a::$$lib.$$lang.pod mantmp/$$lib.pod && \
	      pod2man --section=3pm --center='Po4a Tools' --release='Po4a Tools' \
	       mantmp/$$lib.pod > mantmp/$$lang/man3/Locale::Po4a::$$lib.3pm; \
	      gzip -9 mantmp/$$lang/man3/Locale::Po4a::$$lib.3pm; \
	      rm -f mantmp/$$lib.pod; \
	    fi; \
	  done; \
	done
	for doc in $(docs) ; do \
	  pod2man --section=7 --center='Po4a Tools' --release='Po4a Tools' \
	    doc/$$doc.7.pod > mantmp/$$doc.7; \
	  gzip -9 mantmp/$$doc.7; \
	  for lang in $(langs) ; do \
	    if [ -e po/pod/$$doc.$$lang.pod ] ; then \
	      mkdir -p mantmp/$$lang/man7; \
	      cp po/pod/$$doc.$$lang.pod mantmp/$$doc.pod && \
	      pod2man --section=7 --center='Po4a Tools' --release='Po4a Tools' \
	       mantmp/$$doc.pod > mantmp/$$lang/man7/$$doc.7; \
	      gzip -9 mantmp/$$lang/man7/$$doc.7; \
	      rm -f mantmp/$$doc.pod; \
	    fi; \
	  done; \
	done
	touch man-stamp

clean:
	./Build realclean || true
	$(MAKE) -C po clean
	find -name '.#*'|xargs rm -f || true
	rm -rf po4a.log
	rm -rf mantmp
	rm -f build-stamp po-bin-stamp po-pod-stamp man-stamp

install: build-install po-install man-install

build-install: build-stamp
	./Build install destdir=$(DESTDIR)

po-install: po-bin-stamp
	$(MAKE) -C po/bin install DESTDIR=$(DESTDIR)

man-install: man-stamp
	install -d $(DESTDIR)/usr/share/man/man7
	install -m 0644 mantmp/*.7.gz $(DESTDIR)/usr/share/man/man7
	for lang in $(langs); do \
	  for dir in `ls mantmp/$$lang`; do \
	    install -d $(DESTDIR)/usr/share/man/$$lang/$$dir; \
	    install -m 0644 mantmp/$$lang/$$dir/* $(DESTDIR)/usr/share/man/$$lang/$$dir; \
	  done \
	done

dist: Build
	./Build dist

.PHONY: build clean install build-install po-install man-install tar
