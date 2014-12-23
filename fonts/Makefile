## This makefile is made to build to fonts from the sfd, it won't be useful for
## the average user.

SRCFILES = Makefile
DOCFILES = INSTALL FONTLOG 
TTFFILES = gregorio.ttf greciliae.ttf parmesan.ttf gresym.ttf greextra.ttf
FNTSRCFILES = gregorio-base.sfd parmesan-base.sfd greciliae-base.sfd squarize.py greextra.sfd gresym.sfd
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
HOMETEXDIR = $(TEXMFHOMEROOT)/tex/$(FORMAT)/$(NAME)
HOMEDOCDIR = $(TEXMFHOMEROOT)/doc/$(FORMAT)/$(NAME)
HOMETTFDIR = $(TEXMFHOMEROOT)/fonts/truetype/public/$(NAME)
HOMESRCDIR = $(TEXMFHOMEROOT)/source/$(FORMAT)/$(NAME)
HOMEFNTSRCDIR = $(TEXMFHOMEROOT)/fonts/source/$(NAME)


# a default value
TEXMFROOT = `kpsewhich -var-value TEXMFLOCAL`
TEXMFHOMEROOT = `kpsewhich -var-value TEXMFHOME`

# installation rules
INSTALL_TEXFILES = @mkdir -p $(TEXDIR) && cp $(TEXFILES) $(TEXDIR)
INSTALL_DOCFILES = @mkdir -p $(DOCDIR) && cp $(DOCFILES) $(DOCDIR)
INSTALL_SRCFILES = @mkdir -p $(SRCDIR) && cp $(SRCFILES) $(SRCDIR)
INSTALL_TTFFILES = @mkdir -p $(TTFDIR) && cp $(TTFFILES) $(TTFDIR)
INSTALL_FNTSRCFILES = @mkdir -p $(FNTSRCDIR) && cp $(FNTSRCFILES) $(FNTSRCDIR)
# local $HOME installation rules
LOCAL_INSTALL_TEXFILES = @mkdir -p $(HOMETEXDIR) && cp $(TEXFILES) $(HOMETEXDIR)
LOCAL_INSTALL_DOCFILES = @mkdir -p $(HOMEDOCDIR) && cp $(DOCFILES) $(HOMEDOCDIR)
LOCAL_INSTALL_SRCFILES = @mkdir -p $(HOMESRCDIR) && cp $(SRCFILES) $(HOMESRCDIR)
LOCAL_INSTALL_TTFFILES = @mkdir -p $(HOMETTFDIR) && cp $(TTFFILES) $(HOMETTFDIR)
LOCAL_INSTALL_FNTSRCFILES = @mkdir -p $(HOMEFNTSRCDIR) && cp $(FNTSRCFILES) $(HOMEFNTSRCDIR)


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
	@mkdir -p $(TEXMFROOT)
	$(INSTALL_TEXFILES)
	$(INSTALL_DOCFILES)
	$(INSTALL_SRCFILES)
	$(INSTALL_TTFFILES)
	$(INSTALL_FNTSRCFILES)
	texhash

localinstall: $(ALLFILES)
	@echo "Installing in '$(TEXMFHOMEROOT)'."
	@mkdir -p $(TEXMFHOMEROOT)
	$(LOCAL_INSTALL_TEXFILES)
	$(LOCAL_INSTALL_DOCFILES)
	$(LOCAL_INSTALL_SRCFILES)
	$(LOCAL_INSTALL_TTFFILES)
	$(LOCAL_INSTALL_FNTSRCFILES)
	texhash

gregorio.ttf: squarize.py gregorio-base.sfd
	python2 squarize.py gregorio

parmesan.ttf: squarize.py parmesan-base.sfd
	python2 squarize.py parmesan
	
greciliae.ttf: squarize.py greciliae-base.sfd
	python2 squarize.py greciliae

all: gregorio.ttf parmesan.ttf greciliae.ttf

gregorio: gregorio.ttf

greciliae: greciliae.ttf

parmesan: parmesan.ttf

gregoria: Gregoria.otf Gregoria-Auctae.otf Gregoria-Deminutae.otf gregoria2gregorio.py
	python2 gregoria2gregorio.py

tds: $(TDS_ZIP)

clean:
	rm $(TDS_ZIP)
	
.DEFAULT_GOAL := all
