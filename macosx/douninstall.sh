#!/bin/sh
#Script to uninstall the gregorio Mac OS X distribution.

PREFIX="/usr/local"
BINDIR="$PREFIX/bin"
LIBDIR="$PREFIX/lib"
GRELIBDIR="$LIBDIR/gregorio"
GREINCLUDEDIR="$PREFIX/include/gregorio"
MANDIR="$PREFIX/man/man1"
RECEIPTDIR="/Library/Receipts"

rm $BINDIR/gregorio
rm -dR $GRELIBDIR
rm $LIBDIR/pkgconfig/gregorio.pc
rm $LIBDIR/libgregorio*.dylib
rm $LIBDIR/libgregorio*.la
rm -dR $GREINCLUDEDIR
rm $MANDIR/gregorio.1
rm -dR $RECEIPTDIR/Gregorio.pkg

echo "Gregorio uninstalled. You may now delete the Gregorio folder\ncontaining this script and \
the example files if you wish.\nThanks!"