#!/bin/sh
#Script to uninstall the gregorio Mac OS X distribution.

PREFIX="/usr/local"
BINDIR="$PREFIX/bin"
LIBDIR="$PREFIX/lib"
GRELIBDIR="$LIBDIR/gregorio"
GREINCLUDEDIR="$PREFIX/include/gregorio"
RECEIPTDIR="/Library/Receipts"

rm $BINDIR/gregorio
rm -dR $GRELIBDIR
rm $LIBDIR/pkgconfig/gregorio.pc
rm $LIBDIR/libgregorio*.dylib
rm $LIBDIR/libgregorio*.la
rm -dR $GREINCLUDEDIR
rm -dR $RECEIPTDIR/gregorio-1.0.pkg

echo "Gregorio uninstalled. You may now delete the Gregorio folder\ncontaining this script and \
the example files if you wish.\nThanks!"
