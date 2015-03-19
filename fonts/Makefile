## This makefile is made to build to fonts from the sfd, it won't be useful for
## the average user.

TTFFILES = gregorio.ttf greciliae.ttf parmesan.ttf gresym.ttf greextra.ttf

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

all: $(TTFFILES)

gregorio: gregorio.ttf

greciliae: greciliae.ttf

parmesan: parmesan.ttf

gregoria: Gregoria.otf Gregoria-Auctae.otf Gregoria-Deminutae.otf gregoria2gregorio.py
	$(PYTHON) gregoria2gregorio.py

gresym: gresym.ttf

greextra: greextra.ttf

clean:
	$(RM) $(TTFFILES)

.DEFAULT_GOAL := all
