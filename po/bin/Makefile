# List here all source files with translatable strings.
MODULE=po4a
POTFILES=$(wildcard ../../lib/Locale/Po4a/*.pm) $(wildcard ../../po4a-*)

POFILES=$(wildcard *.po)
MOFILES=$(POFILES:.po=.mo)

all: $(MODULE).pot $(MOFILES)

install: all
	for file in $(MOFILES); do \
		lang=`echo $$file | sed 's/\.mo//'`; \
		install -d $(prefix)/usr/share/locale/$$lang/LC_MESSAGES/; \
		install -m 0644 $$file $(prefix)/usr/share/locale/$$lang/LC_MESSAGES/$(MODULE).mo; \
	done

$(MODULE).pot: $(POTFILES)
# xgettext can mostly handle perl files as C files, though it gets a bit
# confused about single quotes in comments, and the gettext() calls have to
# use double-quoted strings or it will ignore them.
	@echo "Rebuilding the pot file"
	xgettext $(POTFILES) -o $@.new -Lc 2>/dev/null
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
	rm -f (MOFILES) messages messages.mo *~

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
	@for file in $(POFILES); do \
		lang=`echo $$file | sed 's/\.po//'`; \
		printf "$$lang: "; \
		msgfmt -o /dev/null -c -v --statistics $$lang.po;\
	done
