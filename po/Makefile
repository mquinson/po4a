SUBDIRS=bin pod

all:
	for dir in $(SUBDIRS) ; do make -C $$dir all || exit $$? ; done
	
install:
	for dir in $(SUBDIRS) ; do make -C $$dir install || exit $$? ; done
