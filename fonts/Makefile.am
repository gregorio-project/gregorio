## This makefile is made to build to fonts from the sfd, it won't be useful for
## the average user.

TTFFILES = gregorio.ttf greciliae.ttf parmesan.ttf gresym.ttf greextra.ttf
SOURCEFILES = gregorio-base.sfd parmesan-base.sfd greciliae-base.sfd gresym.sfd greextra.sfd

EXTRA_DIST = $(TTFFILES) $(SOURCEFILES) squarize.py convertsfdtottf.py README.md gregoria2gregorio.py

PYTHON = python2
RM = rm

gregorio.ttf: squarize.py gregorio-base.sfd
	$(PYTHON) squarize.py gregorio

parmesan.ttf: squarize.py parmesan-base.sfd
	$(PYTHON) squarize.py parmesan
	
greciliae.ttf: squarize.py greciliae-base.sfd
	$(PYTHON) squarize.py greciliae

gresym.ttf: convertsfdtottf.py gresym.sfd
	$(PYTHON) convertsfdtottf.py gresym.sfd

greextra.ttf: convertsfdtottf.py greextra.sfd
	$(PYTHON) convertsfdtottf.py greextra.sfd

fonts: $(TTFFILES)

gregorio: gregorio.ttf

greciliae: greciliae.ttf

parmesan: parmesan.ttf

gregoria: Gregoria.otf Gregoria-Auctae.otf Gregoria-Deminutae.otf gregoria2gregorio.py
	$(PYTHON) gregoria2gregorio.py

gresym: gresym.ttf

greextra: greextra.ttf

MAINTAINERCLEANFILES = $(TTFFILES)

install:
	@$(TOP_LEVEL_MAKE) echo 'The Makefile in the fonts directory is no longer used for installing'
	@$(TOP_LEVEL_MAKE) echo 'GregorioTeX.  Please use install-gtex.sh from the parent directory'
	@$(TOP_LEVEL_MAKE) echo 'to install GregorioTeX.'
	@$(TOP_LEVEL_MAKE) echo
	@$(TOP_LEVEL_MAKE) echo 'If you were using "make install" before, now use'
	@$(TOP_LEVEL_MAKE) echo '    ./install-gtex.sh system'
	@$(TOP_LEVEL_MAKE) echo
	@$(TOP_LEVEL_MAKE) echo 'If you were using "make localinstall" before, now use'
	@$(TOP_LEVEL_MAKE) echo '    ./install-gtex.sh user'

all:
	@$(TOP_LEVEL_MAKE) echo 'Please use "make fonts" if you wish to build the GregorioTeX fonts'
