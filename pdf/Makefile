LATEXMK=latexmk -xelatex

TEXS=$(wildcard *.tex)
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

%.pdf: %.tex
	$(LATEXMK) $<
