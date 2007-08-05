.PHONY: all test time clean distclean dist build distcheck upload distupload

all: test

build: Build
	./$<

dist distclean test tardist: Build
	./Build $@

Build: Build.PL
	perl $<

clean: distclean

time:
	perl -mlib=$(DVL_HOME)/lib -T -d:DProf ./profile-Path-Abstract.pl 5000 && dprofpp tmon.out
	perl -mlib=$(DVL_HOME)/lib -T -d:DProf ./profile-Path-Class.pl 5000 && dprofpp tmon.out

upload: distclean 
	perl Build.PL && ./Build dist
	ncftpput pause.perl.org incoming `basename $(PWD)`-?.??.tar.gz

distcheck:
	-@./Build $@
	-@./Build $@ 2>&1 | grep "Not in" | awk '{ print $$4 }' | grep -Ev "(Session.vim|GNUmakefile|^\.)"
