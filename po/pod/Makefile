# List here all source files with translatable strings.
PODFILES=$(wildcard ../../po4a-*)
PODPOFILES=$(wildcard pod-*.po)

LANG=fr
TRANSLATIONS=$(basename $(foreach lang,$(LANG),$(foreach file,$(PODFILES),$(file).$(lang).pod)))

# all can't depend on TRANSLATIONS because it would make po4a depend on itself,
# but make sure to decomment this if you copy this Makefile to another project
all: po4a-pod.pot $(TRANSLATIONS)

install: 
# install do nothing in po4a, because it would make po4a depend on itself.

po4a-pod.pot: $(PODFILES)
	po4a-updatepo -t pod $(foreach file,$(PODFILES),-i $(file)) -o $@

pod-%.po: po4a-pod.pot
	@echo -n "Merging po4a-pod.pot and $@"
	@msgmerge $@ po4a-pod.pot -o $@,new
# Typically all that changes was a date. I'd prefer not to cvs commit such
# changes, so detect and ignore them.
	@if [ "`diff $@ $@.new | grep '[<>]' | wc -l`" -ne 2 ]; then \
		mv -f $@.new $@; \
	else \
		rm -f $@.new; \
	fi
	@msgfmt --statistics $@

%.fr.pod: ../../% pod-fr.po
	po4a-translate -t pod -v $^ pod.fr.po -o $@

clean:
	rm -f $(MOFILES) messages messages.mo

check:
	@for file in $(PODPOFILES); do \
		lang=`echo $$file | sed 's/\.po//'`; \
		printf "$$lang: "; \
		msgfmt -o /dev/null -c -v --statistics $$lang.po;\
	done

.PHONY:check clean install
