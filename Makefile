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

.PHONY: all install clean dist stats
