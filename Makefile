LATEX   = pdflatex
PANDOC  = pandoc
MAIN    = CPEX-0045-high-order-interpolation

.PHONY: all pdf md clean

all: pdf md

pdf: $(MAIN).pdf

md: $(MAIN).md

$(MAIN).pdf: $(MAIN).tex CGNS_logo_1.png
	$(LATEX) -interaction=nonstopmode $<
	$(LATEX) -interaction=nonstopmode $<

$(MAIN).md: $(MAIN).tex
	$(PANDOC) $< -o $@

clean:
	$(RM) $(MAIN).aux $(MAIN).log $(MAIN).out $(MAIN).toc \
	      $(MAIN).pdf $(MAIN).md
