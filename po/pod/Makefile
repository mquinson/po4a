# List here all source files with translatable strings.
SCRIPTS=po4a-gettextize po4a-updatepo po4a-translate po4a-normalize
LIBS=Po.pm TransTractor.pm Pod.pm Man.pm Sgml.pm Chooser.pm KernelHelp.pm 
DOCS=po4a.7

FILES=$(SCRIPTS) $(foreach lib,$(LIBS),LocalePo4a$(lib)) $(DOCS)

PATHSCRIPTS=$(foreach file,$(SCRIPTS),../../$(file))
PATHLIBS=$(foreach file,$(LIBS),../../lib/Locale/Po4a/$(file))
PATHDOCS=$(foreach file,$(DOCS),../../doc/$(file).pod)

PATHFILES=$(PATHLIBS) $(PATHSCRIPTS) $(PATHDOCS)

POFILES=$(wildcard *.po)

TARGET_LANG=fr
TRANSLATIONS=$(foreach lang,$(TARGET_LANG),$(foreach file,$(FILES),$(file).$(lang).pod))

all: po4a-pod.pot $(TRANSLATIONS)

install: 
# install do nothing in po4a, because it would make po4a depend on itself.

po4a-pod.pot: $(PATHFILES)
	@echo TRANSLATION=$(TRANSLATIONS)
	@PERL5LIB=../../lib ../../po4a-updatepo -f pod $(foreach file,$(PATHFILES),-m $(file)) -p $@

%.po: po4a-pod.pot
	@echo -n "Merging po4a-pod.pot and $@"
	@msgmerge $@ po4a-pod.pot -o $@.new
# Typically all that changes was a date. I'd prefer not to cvs commit such
# changes, so detect and ignore them.
# That's why I don't use po4a-updatepo on po files but on pot ones. It makes
# it easier to detect and ignore such changes.
	@if [ "`diff $@ $@.new | grep '[<>]' | wc -l`" -ne 2 ]; then \
		mv -f $@.new $@; \
	else \
		rm -f $@.new; \
	fi
	@msgfmt --statistics $@

LocalePo4a%.fr.pod: ../../lib/Locale/Po4a/% fr.po
	@PERL5LIB=../../lib ../../po4a-translate -f pod -v -m $< -p fr.po -l $@
	@if [ -e $@ ] ; then \
	  mv -f $@ `echo $@| \
	            sed 's/LocalePo4a/Locale::Po4a::/' | \
	            sed 's/\.pm//'` ; \
	fi

%.fr.pod: ../../% fr.po
	@PERL5LIB=../../lib ../../po4a-translate -f pod -v -m $< -p fr.po -l $@

%.fr.pod: ../../doc/%.pod fr.po
	@PERL5LIB=../../lib ../../po4a-translate -f pod -v -m $< -p fr.po -l $@

clean:
	rm -f messages messages.mo *.pod *~

check:
	@for file in $(POFILES); do \
		lang=`echo $$file | sed 's/\.po//'`; \
		printf "$$lang: "; \
		msgfmt -o /dev/null -c -v --statistics $$lang.po;\
	done

.PHONY:check clean install
