SRCFILES= Command_Index_gregorio.tex  Command_Index_internal.tex  Command_Index_User.tex UserManual.tex

UserManual.pdf: $(SRCFILES)
	latexmk -lualatex -e '$$pdflatex=q/lualatex %O --shell-escape %S/' UserManual.tex

doc: UserManual.pdf

clean:
	latexmk -quiet -C

EXTRA_DIST = $(SRCFILES) UserManual.pdf
