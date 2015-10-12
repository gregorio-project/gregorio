#!/bin/bash

# Script to uninstall the Gregorio Mac OS X distribution.

PREFIX="/usr/local"
BINDIR="$PREFIX/bin"
PKGCONFIGDIR="$PREFIX/lib/pkgconfig"
GREINCLUDEDIR="$PREFIX/include/gregorio"
GRETEXDIR=`kpsewhich gregoriotex.tex`
if [ -z "$GRETEXDIR" ]; then
    GRETEXDIR=`/usr/texbin/kpsewhich gregoriotex.tex`
fi
if [ -z "$GRETEXDIR" ]; then
GRETEXDIR=`/Library/TeX/texbin/kpsewhich gregoriotex.tex`
fi
GRETEXDIR="${GRETEXDIR%/gregoriotex.tex}"
TEXMFLOCAL="${GRETEXDIR%/tex/luatex/gregoriotex}"
GREFONTDIR="$TEXMFLOCAL/fonts/truetype/public/gregoriotex"
GREFONTSOURCE="$TEXMFLOCAL/source/gregoriotex"
GREDOCDIR="$TEXMFLOCAL/doc/luatex/gregoriotex"

rm $BINDIR/gregorio
rm $PKGCONFIGDIR/gregorio.pc
rm -rf $GREINCLUDEDIR
rm -rf $GRETEXDIR
rm -rf $GREFONTDIR
rm -rf $GREFONTSOURCE
rm -rf $GREDOCDIR
pkgutil --forget com.gregorio.pkg.Gregorio
