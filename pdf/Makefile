LATEXMK=latexmk -xelatex

TEXS=$(wildcard *.tex)
PDFS=$(patsubst %.tex,%.pdf,$(TEXS))

.PHONY: all
all: $(PDFS)

.PHONY: clean
clean:
	$(LATEXMK) -C $(TEXS)
	$(RM) *.xdv

%.pdf: %.tex
	$(LATEXMK) $<
