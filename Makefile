all: Build
	./share/po4a-build -f po4a-build.conf
	@./Build

Build: Build.PL
	perl Build.PL

update-po: Build
	$(MAKE) -C po/bin update-po

install: Build
	@./Build install destdir=$(DESTDIR)
	$(MAKE) -C po/bin install DESTDIR=$(DESTDIR)
	find $(DESTDIR) -type d -empty -delete

clean: Build
	@./Build realclean
	$(MAKE) -C share clean
	$(MAKE) -C po/bin clean
	$(RM) po4a-build.sh

dist: Build
	./share/po4a-build --pot-only -f ./po4a-build.conf
	$(MAKE) -C po/bin pot
	@./Build dist

stats: Build
	@./Build postats

check:
	script -c 'perl -V;perl Build.PL;./Build clean;./Build test verbose=1' po4a.log

.PHONY: all install clean dist stats check
