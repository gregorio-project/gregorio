# Copyright (C) 2006-2026 The Gregorio Project (see CONTRIBUTORS.md)
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

SUBDIRS = src examples tex contrib fonts doc macosx windows

ACLOCAL_AMFLAGS = -I m4

EXTRA_DIST = README.md CHANGELOG.md CONTRIBUTING.md CONTRIBUTORS.md \
			 UPGRADE.md COPYING.md .gregorio-version VersionManager.py \
			 build.sh install.sh install-gtex.sh

MOSTLYCLEANFILES = res.txt

CLEANFILES = gregoriotex.ctan.zip $(wildcard gregorio-*.zip) $(wildcard gregorio-*.tar.bz2)

export TOP_LEVEL_MAKE = true

gregorio:
	$(MAKE) -C src all

fonts: make-fonts
make-fonts:
	$(MAKE) -C fonts fonts

clean-fonts:
	$(MAKE) -C fonts clean-fonts

doc: pdf
clean-pdf: clean-doc
clean-doc:
	$(MAKE) -C doc clean-doc

gregoriotex.tds.zip: dist-zip install-gtex.sh
	./install-gtex.sh tds

ctan : gregoriotex.ctan.zip
gregoriotex.ctan.zip: doc dist-zip gregoriotex.tds.zip
	mkdir -p ctan/gregoriotex
	cp gregoriotex.tds.zip ctan/gregoriotex.tds.zip
	cp *.md ctan/gregoriotex/
	cp gregorio-$(VERSION).zip ctan/gregoriotex
	./install-gtex.sh dir:ctan/gregoriotex
	mv ctan/gregoriotex/doc/luatex/gregoriotex/* ctan/gregoriotex/doc
	rm -rf ctan/gregoriotex/doc/luatex
	mv ctan/gregoriotex/fonts/source/gregoriotex/* ctan/gregoriotex/fonts/source
	rm -rf ctan/gregoriotex/fonts/source/gregoriotex ctan/gregoriotex/fonts/source/granapadano-base.sfd ctan/gregoriotex/fonts/source/gregorio-base.sfd
	mv ctan/gregoriotex/fonts/truetype/public/gregoriotex/* ctan/gregoriotex/fonts/truetype
	rm -rf ctan/gregoriotex/fonts/truetype/public
	rm -rf ctan/gregoriotex/scripts
	mv ctan/gregoriotex/tex/lualatex/gregoriotex/* ctan/gregoriotex/tex/lualatex
	rm -rf ctan/gregoriotex/tex/lualatex/gregoriotex
	mv ctan/gregoriotex/tex/luatex/gregoriotex/* ctan/gregoriotex/tex/luatex
	rm -rf ctan/gregoriotex/tex/luatex/gregoriotex
	zip -r gregoriotex.ctan.zip ctan/
	rm -rf ctan/

if MACOSX
dist-macosx: gregorio doc fonts
	$(MAKE) -C macosx dist-macosx
else
dist-macosx:
	@echo "macOS packages can only be built on Mac systems."
	@false
endif

clean-macosx:
	$(MAKE) -C macosx clean-local

if !WINDOWS
dist-windows: gregorio doc fonts
	$(MAKE) -C windows dist-windows
	./configure
else
dist-windows:
	@echo "The dist-windows target is for cross-compiling from Linux/Mac to Windows,"
	@echo "not for building natively on Windows."
	@echo "If you're building natively on Windows, you should probably be using the"
	@echo "normal build targets."
	@false
endif

clean-windows:
	$(MAKE) -C windows clean-local

clean-local:
	rm -rf $(wildcard release-*)

release-$(FILENAME_VERSION):
	mkdir -p release-$(FILENAME_VERSION)

release: release-$(FILENAME_VERSION) dist dist-macosx dist-windows ctan
	$(MAKE) -C fonts supp-fonts-dist
	cp gregorio-$(VERSION).tar.bz2 release-$(FILENAME_VERSION)/
	cp fonts/supp_fonts-$(FILENAME_VERSION).zip release-$(FILENAME_VERSION)/
	cp macosx/Gregorio-$(FILENAME_VERSION).pkg release-$(FILENAME_VERSION)/
	cp macosx/Uninstall-Gregorio-$(FILENAME_VERSION).pkg release-$(FILENAME_VERSION)/
	cp windows/GregorioSetup-$(FILENAME_VERSION).exe release-$(FILENAME_VERSION)/
	cp doc/*.pdf release-$(FILENAME_VERSION)/
