## This makefile is made to build to fonts from the sfd, it won't be useful for
## the average user.

SRCFILES = Makefile
DOCFILES = INSTALL FONTLOG 
TTFFILES = gregorio.ttf greciliae.ttf parmesan.ttf gresym.ttf greextra.ttf
FNTSRCFILES = gregorio-base.sfd parmesan-base.sfd greciliae-base.sfd squarize.py greextra.sfd gresym.sfd convertsfdtottf.py
TEXFILES = $(wildcard ../tex/*.tex) $(wildcard ../tex/gregorio*.sty) $(wildcard ../tex/*.lua)
ALLFILES = $(SRCFILES) $(DOCFILES) $(TEXFILES) $(TTFFILES) $(FNTSRCFILES)

TDS_ZIP = $(NAME).tds.zip

# Installation locations
FORMAT = luatex
NAME = gregoriotex
TEXHASH = texhash
TEXDIR = $(TEXMFROOT)/tex/$(FORMAT)/$(NAME)
DOCDIR = $(TEXMFROOT)/doc/$(FORMAT)/$(NAME)
TTFDIR = $(TEXMFROOT)/fonts/truetype/public/$(NAME)
SRCDIR = $(TEXMFROOT)/source/$(FORMAT)/$(NAME)
FNTSRCDIR = $(TEXMFROOT)/fonts/source/$(NAME)

# a default value
TEXMFROOT = `kpsewhich -var-value TEXMFLOCAL`

# installation rules
INSTALL_TEXFILES = @mkdir -p $(TEXDIR) && cp $(TEXFILES) $(TEXDIR)
INSTALL_DOCFILES = @mkdir -p $(DOCDIR) && cp $(DOCFILES) $(DOCDIR)
INSTALL_SRCFILES = @mkdir -p $(SRCDIR) && cp $(SRCFILES) $(SRCDIR)
INSTALL_TTFFILES = @mkdir -p $(TTFDIR) && cp $(TTFFILES) $(TTFDIR)
INSTALL_FNTSRCFILES = @mkdir -p $(FNTSRCDIR) && cp $(FNTSRCFILES) $(FNTSRCDIR)

installfiles: $(ALLFILES)
	@echo "Installing in '$(TEXMFROOT)'."
	@mkdir -p $(TEXMFROOT)
	$(INSTALL_TEXFILES)
	$(INSTALL_DOCFILES)
	$(INSTALL_SRCFILES)
	$(INSTALL_TTFFILES)
	$(INSTALL_FNTSRCFILES)

$(TDS_ZIP): TEXMFROOT=./tmp-texmf
$(TDS_ZIP): installfiles
	@echo "Making TDS-ready archive $@."
	@$(RM) -- $@
	@cd $(TEXMFROOT) && zip -9 ../$@ -r . >/dev/null
	@$(RM) -r -- $(TEXMFROOT)
	
install: installfiles
	$(TEXHASH)

localinstall: TEXMFROOT = `kpsewhich -var-value TEXMFHOME`
localinstall: install

gregorio.ttf: squarize.py gregorio-base.sfd
	python2 squarize.py gregorio

parmesan.ttf: squarize.py parmesan-base.sfd
	python2 squarize.py parmesan
	
greciliae.ttf: squarize.py greciliae-base.sfd
	python2 squarize.py greciliae

gresym.ttf: convertsfdtottf.py gresym.sfd
	python2 convertsfdtottf.py gresym.sfd

greextra.ttf: convertsfdtottf.py greextra.sfd
	python2 convertsfdtottf.py greextra.sfd

all: gregorio.ttf parmesan.ttf greciliae.ttf gresym.ttf greextra.ttf

gregorio: gregorio.ttf

greciliae: greciliae.ttf

parmesan: parmesan.ttf

gregoria: Gregoria.otf Gregoria-Auctae.otf Gregoria-Deminutae.otf gregoria2gregorio.py
	python2 gregoria2gregorio.py

gresym: gresym.ttf

greextra: greextra.ttf

tds: $(TDS_ZIP)

clean:
	rm $(TDS_ZIP)
	
.DEFAULT_GOAL := all
