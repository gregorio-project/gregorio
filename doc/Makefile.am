SRCFILES= Command_Index_gregorio.tex  Command_Index_internal.tex  Command_Index_User.tex GregorioRef.tex

GregorioRef-$(FILENAME_VERSION).pdf: $(SRCFILES)
	latexmk -pdf -pdflatex='lualatex --shell-escape %O %S' -jobname=GregorioRef-$(FILENAME_VERSION) GregorioRef.tex

doc: GregorioRef-$(FILENAME_VERSION).pdf

distclean-local:
	latexmk -quiet -c -f -jobname=GregorioRef-$(FILENAME_VERSION) GregorioRef.tex
	rm -rf _minted*

EXTRA_DIST = $(SRCFILES) GregorioRef-$(FILENAME_VERSION).pdf
MAINTAINERCLEANFILES = GregorioRef-$(FILENAME_VERSION).pdf
