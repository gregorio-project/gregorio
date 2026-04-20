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

CLEANFILES = $(wildcard GregorioSetup-*.exe)

dist-windows : GregorioSetup-$(FILENAME_VERSION).exe

../src/gregorio-$(FILENAME_VERSION).exe :
	$(top_srcdir)/build.sh --mingw

GregorioSetup-$(FILENAME_VERSION).exe : ../src/gregorio-$(FILENAME_VERSION).exe
	wine 'C:\\Program Files (x86)\Inno Setup 6\ISCC.exe' gregorio.iss
	mv Output/mysetup.exe GregorioSetup-$(FILENAME_VERSION).exe
	rm -rf Output/

clean-local :
	rm -rf Output/
