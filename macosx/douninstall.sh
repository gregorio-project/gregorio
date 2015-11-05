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
TEXMFLOCAL="${GRETEXDIR%/tex/luatex/gregoriotex}"
GREFONTDIR="$TEXMFLOCAL/fonts/truetype/public/gregoriotex"
GREFONTSOURCE="$TEXMFLOCAL/source/gregoriotex"
GREDOCDIR="$TEXMFLOCAL/doc/luatex/gregoriotex"

rm "$BINDIR/gregorio"
rm "$PKGCONFIGDIR/gregorio.pc"
rm -rf "$GREINCLUDEDIR"
rm -rf "$GRETEXDIR"
rm -rf "$GREFONTDIR"
rm -rf "$GREFONTSOURCE"
rm -rf "$GREDOCDIR"
pkgutil --forget com.gregorio.pkg.Gregorio
