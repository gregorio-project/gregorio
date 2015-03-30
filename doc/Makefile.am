SRCFILES= Command_Index_gregorio.tex  Command_Index_internal.tex  Command_Index_User.tex UserManual.tex

UserManual-$(VERSION).pdf: $(SRCFILES)
	latexmk -pdf -pdflatex='lualatex --shell-escape %O %S' -jobname=UserManual-$(VERSION) UserManual.tex

doc: UserManual-$(VERSION).pdf

clean:
	latexmk -quiet -C

EXTRA_DIST = $(SRCFILES) UserManual-$(VERSION).pdf
