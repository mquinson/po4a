all: Build
	@./Build

Build: Build.PL
	perl Build.PL

install: Build
	@./Build install destdir=$(DESTDIR)

clean: Build
	@./Build realclean

dist: Build
	./Build distmeta # regenerates META.yml
	@./Build dist

stats: Build
	@./Build postats

.PHONY: all install clean dist stats
