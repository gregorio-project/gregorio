SRCFILES= Command_Index_gregorio.tex  Command_Index_internal.tex  Command_Index_User.tex GregorioRef.tex

GregorioRef-$(VERSION).pdf: $(SRCFILES)
	latexmk -pdf -pdflatex='lualatex --shell-escape %O %S' -jobname=GregorioRef-$(VERSION) GregorioRef.tex

doc: GregorioRef-$(VERSION).pdf

clean:
	latexmk -quiet -C

EXTRA_DIST = $(SRCFILES) GregorioRef-$(VERSION).pdf
