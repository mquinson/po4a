# List here all source files with translatable strings.
MODULE=po4a
PODFILES=$(wildcard ../../lib/Locale/Po4a/*.pm) \
  ../../po4a-gettextize ../../po4a-normalize ../../po4a-translate ../../po4a-updatepo

LANGS=$(basename $(wildcard *.po))

all: $(MODULE).pot $(addsuffix .mo,$(LANGS))

install: all
	for lang in $(LANGS); do \
		install -d $(DESTDIR)/usr/share/locale/$$lang/LC_MESSAGES/; \
		install -m 0644 $$lang.mo $(DESTDIR)/usr/share/locale/$$lang/LC_MESSAGES/$(MODULE).mo; \
	done

$(MODULE).pot: $(PODFILES)
# xgettext can mostly handle perl files as C files, though it gets a bit
# confused about single quotes in comments, and the gettext() calls have to
# use double-quoted strings or it will ignore them.
	@echo "Rebuilding the pot file"
	xgettext -L Perl $(PODFILES) -o $@.new 2>/dev/null
	@if [ -e $@ ] ; then \
	   if diff -q -I'#:' -I'POT-Creation-Date:' -I'PO-Revision-Date:' $@ $@.new>/dev/null ; then \
		rm -f $@.new; \
		touch $@; \
	   else \
	   	mv -f $@.new $@; \
	   fi; \
	else \
	   mv -f $@.new $@; \
	fi
	
clean:
	rm -f messages *.mo *~

%.mo: %.po
	msgfmt -o $@ $<

%.po: $(MODULE).pot
	@echo -n "Merging $(MODULE).pot and $@"
	@msgmerge $@ $(MODULE).pot -o $@.new
# Typically all that changes was a date. I'd prefer not to cvs commit such
# changes, so detect and ignore them.
	@if diff -q -I'#:' -I'POT-Creation-Date:' -I'PO-Revision-Date:' $@ $@.new >/dev/null; then \
		rm -f $@.new; \
		touch $@; \
	else \
		mv -f $@.new $@; \
	fi
	@msgfmt --statistics $@

check:
	@for lang in $(LANGS); do \
		printf "$$lang: "; \
		msgfmt -o /dev/null -c -v --statistics $$lang.po;\
	done

update: $(MODULE).pot $(addsuffix .po,$(LANGS))
