SRCFILES= Command_Index_gregorio.tex  Command_Index_internal.tex  Command_Index_User.tex UserManual.tex

UserManual.pdf: $(SRCFILES)
	latexmk -pdf -pdflatex='lualatex --shell-escape %O %S' UserManual.tex

doc: UserManual.pdf

clean:
	latexmk -quiet -C

EXTRA_DIST = $(SRCFILES) UserManual.pdf
