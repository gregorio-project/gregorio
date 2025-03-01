#! /usr/bin/env bash

# Copyright (C) 2016-2025 The Gregorio Project (see CONTRIBUTORS.md)
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

######################################################################
# Script to be executed by make ctan

VERSION=`head -1 .gregorio-version`
FILEVERSION=`echo $VERSION | sed 's/\./_/g'`

rm -rf ctan
mkdir -p ctan/gregoriotex/
mv gregoriotex.tds.zip ctan/gregoriotex.tds.zip
cp gregorio-$VERSION.zip ctan/gregoriotex/
cp *.md ctan/gregoriotex
cd ctan/gregoriotex
unzip gregorio-$VERSION.zip
cd gregorio-$VERSION
cp -r doc/ ../
cp -r tex/ ../
cp -r fonts/ ../
cp -r examples/ ../doc/
rm -rf windows
cd ..
rm doc/Makefile*
rm doc/examples/Makefile*
rm tex/Makefile*
mkdir tex/lualatex
mkdir tex/luatex
mv tex/*.sty tex/lualatex
mv tex/*.* tex/luatex
rm fonts/Makefile*
mkdir fonts/sources/
mkdir fonts/truetype/
mv fonts/*.ttf fonts/truetype
mv fonts/*.* fonts/sources
rm -rf gregorio-$VERSION
cd ..
zip -r ../gregoriotex.ctan.zip gregoriotex gregoriotex.tds.zip --exclude=*.DS_Store*
cd ..
rm -rf ctan
