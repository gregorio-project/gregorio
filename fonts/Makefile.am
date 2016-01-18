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

TTFFILES = gregorio.ttf greciliae.ttf parmesan.ttf \
		   gregorio-op.ttf greciliae-op.ttf parmesan-op.ttf \
		   greextra.ttf gregall.ttf gresgmodern.ttf
SOURCEFILES = gregorio-base.sfd parmesan-base.sfd greciliae-base.sfd \
			  greextra.sfd gregall.sfd gresgmodern.sfd

EXTRA_DIST = $(TTFFILES) $(SOURCEFILES) squarize.py convertsfdtottf.py README.md

FONTFORGE = fontforge
RM = rm

%.ttf: squarize.py %-base.sfd
	$(FONTFORGE) -script $^ -o $@

%-op.ttf: squarize.py %-base.sfd
	$(FONTFORGE) -script $^ -o $@ -s op

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
