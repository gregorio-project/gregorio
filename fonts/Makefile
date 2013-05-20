## This makefile is made to build to fonts from the sfd, it won't be useful for
## the average user.

SRCFILES = Makefile gregorio-base.sfd parmesan-base.sfd greciliae-base.sfd squarize.py greextra.sfd gresym.sfd
DOCFILES = INSTALL FONTLOG 
TTFFILES = $(wildcard *.ttf)
FNTSRCFILES = $(wildcard *.sfd) squarize.py
TEXFILES = $(wildcard ../tex/*.tex) $(wildcard ../tex/gregorio*.sty) $(wildcard ../tex/*.lua)
ALLFILES = $(SRCFILES) $(DOCFILES) $(TEXFILES) $(TTFFILES) $(FNTSRCFILES)

TDS_ZIP = $(NAME).tds.zip

# Installation locations
FORMAT = luatex
NAME = gregoriotex
TEXDIR = $(TEXMFROOT)/tex/$(FORMAT)/$(NAME)
DOCDIR = $(TEXMFROOT)/doc/$(FORMAT)/$(NAME)
TTFDIR = $(TEXMFROOT)/fonts/truetype/public/$(NAME)
SRCDIR = $(TEXMFROOT)/source/$(FORMAT)/$(NAME)
FNTSRCDIR = $(TEXMFROOT)/fonts/source/$(NAME)

# a default value
TEXMFROOT = `kpsewhich -var-value TEXMFHOME`

# installation rules
INSTALL_TEXFILES = @mkdir -p $(TEXDIR) && cp $(TEXFILES) $(TEXDIR)
INSTALL_DOCFILES = @mkdir -p $(DOCDIR) && cp $(DOCFILES) $(DOCDIR)
INSTALL_SRCFILES = @mkdir -p $(SRCDIR) && cp $(SRCFILES) $(SRCDIR)
INSTALL_TTFFILES = @mkdir -p $(TTFDIR) && cp $(TTFFILES) $(TTFDIR)
INSTALL_TTFFILES = @mkdir -p $(FNTSRCDIR) && cp $(FNTSRCFILES) $(FNTSRCDIR)

$(TDS_ZIP): TEXMFROOT=./tmp-texmf
$(TDS_ZIP): $(ALLFILES)
	@echo "Making TDS-ready archive $@."
	@$(RM) -- $@
	$(INSTALL_TEXFILES)
	$(INSTALL_DOCFILES)
	$(INSTALL_SRCFILES)
	$(INSTALL_TTFFILES)
	$(INSTALL_FNTSRCFILES)
	@cd $(TEXMFROOT) && zip -9 ../$@ -r . >/dev/null
	@$(RM) -r -- $(TEXMFROOT)
	
install: $(ALLFILES)
	@echo "Installing in '$(TEXMFROOT)'."
	$(INSTALL_TEXFILES)
	$(INSTALL_DOCFILES)
	$(INSTALL_SRCFILES)
	$(INSTALL_TTFFILES)
	$(INSTALL_FNTSRCFILES)

gregorio.ttf: squarize.py gregorio-base.sfd
	python squarize.py gregorio

parmesan.ttf: squarize.py parmesan-base.sfd
	python squarize.py parmesan
	
greciliae.ttf: squarize.py greciliae-base.sfd
	python squarize.py greciliae

all: gregorio.ttf parmesan.ttf greciliae.ttf

gregorio: gregorio.ttf

greciliae: greciliae.ttf

parmesan: parmesan.ttf

gregoria: Gregoria.otf Gregoria-Auctae.otf Gregoria-Deminutae.otf
	python gregoria2gregorio.py

tds: $(TDS_ZIP)

clean:
	rm $(TDS_ZIP)
	
.DEFAULT_GOAL := all
