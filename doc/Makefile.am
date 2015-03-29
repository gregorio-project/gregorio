SRCFILES= Command_Index_gregorio.tex  Command_Index_internal.tex  Command_Index_User.tex GregorioRef.tex

GregorioRef.pdf: $(SRCFILES)
	latexmk -pdf -pdflatex='lualatex --shell-escape %O %S' GregorioRef.tex

doc: GregorioRef.pdf

clean:
	latexmk -quiet -C

EXTRA_DIST = $(SRCFILES) GregorioRef.pdf
