#!/bin/bash
# Script to uninstall the gregorio Mac OS X distribution.

PREFIX="/usr/local"
BINDIR="$PREFIX/bin"
PKGCONFIGDIR="$PREFIX/lib/pkgconfig"
GREINCLUDEDIR="$PREFIX/include/gregorio"
TEXMFLOCAL="$PREFIX/texlive/texmf-local"
GRETEXDIR="$TEXMFLOCAL/tex/luatex/gregoriotex"
GREFONTDIR="$TEXMFLOCAL/fonts/truetype/public/gregoriotex"
GREFONTSOURCE="$TEXMFLOCAL/source/gregoriotex"
GREDOCDIR="$TEXMFLOCAL/doc/luatex/gregoriotex"
RECEIPTDIR="/Library/Receipts"

rm $BINDIR/gregorio
rm $PKGCONFIGDIR/gregorio.pc
rm -rf $GREINCLUDEDIR
rm -rf $GRETEXDIR
rm -rf $GREFONTDIR
rm -rf $GREFONTSOURCE
rm -rf $GREDOCDIR

