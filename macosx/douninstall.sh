#!/usr/bin/env bash

# Script to uninstall the Gregorio Mac OS X distribution.

PREFIX="/usr/local"
BINDIR="$PREFIX/bin"
PKGCONFIGDIR="$PREFIX/lib/pkgconfig"
GREINCLUDEDIR="$PREFIX/include/gregorio"

# Find kpsewhich
source common.sh

writelog 6 "Uninstalling Gregorio Components"

GRETEXDIR=`$KPSEWHICH gregoriotex.tex`
GRETEXDIR="${GRETEXDIR%/gregoriotex.tex}"
GRELATEXDIR="${GRETEXDIR/luatex/lualatex}"
TEXMFLOCAL="${GRETEXDIR%/tex/luatex/gregoriotex}"
GREFONTDIR="$TEXMFLOCAL/fonts/truetype/public/gregoriotex"
GREFONTSOURCE="$TEXMFLOCAL/fonts/source/gregoriotex"
GREDOCDIR="$TEXMFLOCAL/doc/luatex/gregoriotex"

rm "$BINDIR/gregorio-6_1_0" # FILENAME_VERSION
rm "$PKGCONFIGDIR/gregorio.pc"
rm -rf "$GREINCLUDEDIR"
rm -rf "$GRETEXDIR"
rm -rf "$GRELATEXDIR"
rm -rf "$GREFONTDIR"
rm -rf "$GREFONTSOURCE"
rm -rf "$GREDOCDIR"
pkgutil --forget com.gregorio.pkg.Gregorio
