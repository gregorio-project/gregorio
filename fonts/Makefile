## This makefile is made to build to fonts from the sfd, it won't be useful for
## the average user.

gregorio.ttf: squarize.py gregorio-base.sfd
	python squarize.py gregorio

parmesan.ttf: squarize.py parmesan-base.sfd
	python squarize.py parmesan
	
greciliae.ttf: squarize.py greciliae-base.sfd
	python squarize.py greciliae

all: gregorio.ttf parmesan.ttf greciliae.ttf

clean:
	rm $(CLEANFILES)

install:
	python install.py
	
.DEFAULT_GOAL := all
