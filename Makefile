all: Build
	@./Build

Build: Build.PL
	perl Build.PL

update-po: Build
	./Build binpo

install: Build
	@./Build install destdir=$(DESTDIR)
	$(MAKE) -C po/bin install DESTDIR=$(DESTDIR)
	find $(DESTDIR) -type d -empty -delete

clean: Build
	@./Build realclean
	$(MAKE) -C share clean
	$(MAKE) -C po/bin clean

dist: Build
	@./Build dist

stats: Build
	@./Build postats

check:
	script -c 'perl -V;perl Build.PL;./Build clean;./Build test verbose=1' po4a.log

.PHONY: all install clean dist stats check
