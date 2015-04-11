## This makefile is made to build to fonts from the sfd, it won't be useful for
## the average user.

# Copyright (C) 2006-2015 The Gregorio Project (see CONTRIBUTORS.md)
#
# This file is part of Gregorio.
#
# Gregorio is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Gregorio is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Gregorio.  If not, see <http://www.gnu.org/licenses/>.

TTFFILES = gregorio.ttf greciliae.ttf parmesan.ttf gresym.ttf greextra.ttf
SOURCEFILES = gregorio-base.sfd parmesan-base.sfd greciliae-base.sfd gresym.sfd greextra.sfd

EXTRA_DIST = $(TTFFILES) $(SOURCEFILES) squarize.py convertsfdtottf.py README.md gregoria2gregorio.py

FONTFORGE = fontforge
RM = rm

gregorio.ttf: squarize.py gregorio-base.sfd
	$(FONTFORGE) -script squarize.py gregorio

parmesan.ttf: squarize.py parmesan-base.sfd
	$(FONTFORGE) -script squarize.py parmesan
	
greciliae.ttf: squarize.py greciliae-base.sfd
	$(FONTFORGE) -script squarize.py greciliae

gresym.ttf: convertsfdtottf.py gresym.sfd
	$(FONTFORGE) -script convertsfdtottf.py gresym.sfd

greextra.ttf: convertsfdtottf.py greextra.sfd
	$(FONTFORGE) -script convertsfdtottf.py greextra.sfd

fonts: $(TTFFILES)

gregorio: gregorio.ttf

greciliae: greciliae.ttf

parmesan: parmesan.ttf

gregoria: Gregoria.otf Gregoria-Auctae.otf Gregoria-Deminutae.otf gregoria2gregorio.py
	$(FONTFORGE) -script gregoria2gregorio.py

gresym: gresym.ttf

greextra: greextra.ttf

clean-local:
	@$(TOP_LEVEL_MAKE) $(RM) -f $(TTFFILES)

install-data-local:
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
