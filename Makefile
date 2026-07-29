LATEX   = pdflatex
PANDOC  = pandoc
MAIN    = CPEX-0045-high-order-interpolation

.PHONY: all pdf md clean

all: pdf

pdf: $(MAIN).pdf

# Not built by "all": the .md is a generated convenience view, not a tracked
# artifact.  The .tex is the source of truth.
md: $(MAIN).md

$(MAIN).pdf: $(MAIN).tex CGNS_logo_1.png
	$(LATEX) -interaction=nonstopmode $<
	$(LATEX) -interaction=nonstopmode $<

$(MAIN).md: $(MAIN).tex
	$(PANDOC) $< -o $@

clean:
	$(RM) $(MAIN).aux $(MAIN).log $(MAIN).out $(MAIN).toc \
	      $(MAIN).pdf $(MAIN).md
