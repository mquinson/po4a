SUBDIRS=bin pod

all:
	for dir in $(SUBDIRS) ; do make -C $$dir all || exit $$? ; done
	
install:
	for dir in $(SUBDIRS) ; do make -C $$dir install || exit $$? ; done

clean:
	for dir in $(SUBDIRS) ; do make -C $$dir clean || exit $$? ; done


stats:
	@for dir in $(SUBDIRS) ; do \
	  potsize=`(cd $$dir;ls -sh *.pot) | \
		   sed -n -e 's/^ *\([^[:blank:]]*\).*$$/\1/p'`  ; \
	  echo "$$dir/ (pot: $$potsize)"; \
	  for f in `ls $$dir/*.po` ; do \
	    stat=`msgfmt --statistics -o /dev/null $$f 2>&1` ; \
	    name=`basename $$f .po`; \
	    echo " $$name: $$stat"; \
	  done ; \
	done
	  
