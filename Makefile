all: Build
	@./Build

Build: Build.PL
	perl Build.PL

install: Build
	@./Build install destdir=$(DESTDIR)

clean: Build
	@./Build realclean

dist: Build
	@./Build dist

stats: Build
	@./Build postats

bugreport:
	script -c 'perl -V;perl Build.PL;./Build clean;./Build test verbose=1' po4a.log

.PHONY: all install clean dist stats bugreport
