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

TTFFILES = gregorio.ttf greciliae.ttf granapadano.ttf \
		   gregorio-op.ttf greciliae-op.ttf granapadano-op.ttf \
		   greextra.ttf gregall.ttf gresgmodern.ttf
SOURCEFILES = gregorio-base.sfd granapadano-base.sfd greciliae-base.sfd \
			  greextra.sfd gregall.sfd gresgmodern.sfd

EXTRA_DIST = $(TTFFILES) $(SOURCEFILES) squarize.py stemsschemas.py convertsfdtottf.py README.md simplify.py

FONTFORGE = fontforge
RM = rm

%.ttf: %-base.sfd squarize.py stemsschemas.py simplify.py %.json
	$(FONTFORGE) -script squarize.py $< -o $@ -c $*.json
	$(FONTFORGE) -script simplify.py $@

%-op.ttf: %-base.sfd squarize.py stemsschemas.py simplify.py %.json
	$(FONTFORGE) -script squarize.py $< -o $@ -s op -c $*.json
	$(FONTFORGE) -script simplify.py $@

%.ttf: convertsfdtottf.py %.sfd
	$(FONTFORGE) -script $< $*.sfd

fonts: $(TTFFILES)

%: %.ttf

MAINTAINERCLEANFILES = $(TTFFILES)

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

all: fonts
