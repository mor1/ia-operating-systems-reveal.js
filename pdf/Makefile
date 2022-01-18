LATEXMK=latexmk -xelatex
GS=gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH
TEXS=$(wildcard ia-os*.tex)
PDFS=$(patsubst %.tex,%-compressed.pdf,$(TEXS))

.PHONY: all
all: $(PDFS)

.PHONY: clean
clean:
	$(LATEXMK) -c $(TEXS)
	$(RM) *.xdv

.PHONY: distclean
distclean:
	$(LATEXMK) -C $(TEXS)
	$(RM) $(PDFS) $(wildcard %-compressed.pdf,%.pdf,$(PDFS))

%.pdf: %.tex $(wildcard [01]*.pdf) style.tex
	$(LATEXMK) $<

.PRECIOUS: %-compressed.pdf %.pdf
%-compressed.pdf: %.pdf
	$(GS) -sOutputFile=$@ $<

.PHONY: push
push:
	scp ia-os*.pdf ely.cl:~/public_html/x
