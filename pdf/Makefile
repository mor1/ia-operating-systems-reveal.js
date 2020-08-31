LATEXMK=latexmk -xelatex

TEXS=$(wildcard ia-os*.tex)
PDFS=$(patsubst %.tex,%.pdf,$(TEXS))

.PHONY: all
all: $(PDFS)

.PHONY: clean
clean:
	$(LATEXMK) -c $(TEXS)
	$(RM) *.xdv

.PHONY: distclean
distclean:
	$(LATEXMK) -C $(TEXS)

%.pdf: %.tex $(wildcard [01]*.pdf)
	$(LATEXMK) $<

.PHONY: push
push:
	scp ia-os*.pdf ely.cl:~/public_html/x
