# List here all source files with translatable strings.
SCRIPTS=po4a-gettextize po4a-updatepo po4a-translate po4a-normalize
LIBS=Po.pm TransTractor.pm Pod.pm Man.pm Sgml.pm Chooser.pm KernelHelp.pm Dia.pm
DOCS=po4a.7

FILES=$(SCRIPTS) $(foreach lib,$(LIBS),LocalePo4a$(lib)) $(DOCS)

PATHSCRIPTS=$(foreach file,$(SCRIPTS),../../$(file))
PATHLIBS=$(foreach file,$(LIBS),../../lib/Locale/Po4a/$(file))
PATHDOCS=$(foreach file,$(DOCS),../../doc/$(file).pod)

PATHFILES=$(PATHLIBS) $(PATHSCRIPTS) $(PATHDOCS)

LANGS=$(basename $(wildcard *.po))
TRANSLATIONS=$(foreach lang,$(LANGS),$(foreach file,$(FILES),$(file).$(lang).pod))

all: po4a-pod.pot $(TRANSLATIONS)

install: 
# install do nothing in po4a, because it would make po4a depend on itself.

po4a-pod.pot: $(PATHFILES)
	@echo TRANSLATION=$(TRANSLATIONS)
	@PERL5LIB=../../lib perl ../../po4a-updatepo -f pod $(foreach file,$(PATHFILES),-m $(file)) -p $@

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


##### BEGIN TEMPLATES #####
define TEMPLATES

LocalePo4a%.$(1).pod: ../../lib/Locale/Po4a/% $(1).po
	@PERL5LIB=../../lib perl ../../po4a-translate -f pod -v -m $$< -p $(1).po -l $$@
	@if [ -e $$@ ] ; then \
	  mv -f $$@ `echo $$@| \
	            sed 's/LocalePo4a/Locale::Po4a::/' | \
	            sed 's/\.pm//'` ; \
	fi

%.$(1).pod: ../../% $(1).po
	@PERL5LIB=../../lib perl ../../po4a-translate -f pod -v -m $$< -p $(1).po -l $$@ || true

%.$(1).pod: ../../doc/%.pod $(1).po
	@PERL5LIB=../../lib perl ../../po4a-translate -f pod -v -m $$< -p $(1).po -l $$@ || true

endef
##### END TEMPLATES #####

$(foreach lang,$(LANGS),$(eval $(call TEMPLATES,$(lang))))

clean:
	rm -f messages *.mo *.pod *~

check:
	@for lang in $(LANGS); do \
		printf "$$lang: "; \
		msgfmt -o /dev/null -c -v --statistics $$lang.po;\
	done

update: po4a-pod.pot $(addsuffix .po,$(LANGS)) $(TRANSLATIONS)

.PHONY:all check clean install update
