#!/bin/bash
# Script to uninstall the gregorio Mac OS X distribution.
# Perhaps we should also uninstall the GregorioTeX stuff...
# But that is a problem for another day

PREFIX="/usr/local"
BINDIR="$PREFIX/bin"
#LIBDIR="$PREFIX/lib"
#GRELIBDIR="$LIBDIR/gregorio"
#GREINCLUDEDIR="$PREFIX/include/gregorio"
RECEIPTDIR="/Library/Receipts"

rm $BINDIR/gregorio
rm -dR $RECEIPTDIR/gregorio-2.0.pkg

echo "Gregorio uninstalled. You may now delete the Gregorio folder\ncontaining this script and \
the example files if you wish.\nThanks!"
