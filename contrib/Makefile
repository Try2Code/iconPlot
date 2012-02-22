program = nclsh
version = 1.0.0
package = $(program)-$(version)

prefix = /usr/local
bindir = $(prefix)/bin
mandir = $(prefix)/share/man/man1
docdir = $(prefix)/share/doc/$(program)

all: doc

clean:
	rm -rf $(program).* $(package) $(package).tar.gz

doc: $(program).man $(program).pdf

dist: $(package).tar.gz

install: all
	mkdir -p $(bindir) $(mandir) $(docdir)
	cp $(program) $(bindir)/$(program)
	cp $(program).man $(mandir)/$(program).1
	cp $(program).pdf $(docdir)/$(program).pdf

$(program).man: $(program)
	pod2man -c 'User Commands' -r '$(program) $(version)' $< > $@

$(package).tar.gz: prefix=$(package)
$(package).tar.gz: install
	tar czvf $@ $(package)
	rm -rf $(package)

%.man: %
	pod2man -c 'User Commands' -r '$(program) $(version)' $< > $@

%.ps: %.man
	groff -man -P-pa4 $< > $@

%.pdf: %.ps
	ps2pdf $<
