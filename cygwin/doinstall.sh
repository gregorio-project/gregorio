#!/bin/sh
#Script to install the gregorio cygwin distribution.

PREFIX="/usr"
BINDIR="$PREFIX/bin"
LIBDIR="$PREFIX/lib"
GRELIBDIR="$LIBDIR/gregorio"
GREINCLUDEDIR="$PREFIX/include/gregorio"
MANDIR="$PREFIX/man/man1"

INSTALL="/usr/bin/install"

mkdir -p $BINDIR
mkdir -p $LIBDIR
mkdir -p $MANDIR
mkdir -p $GRELIBDIR
mkdir -p $GREINCLUDEDIR

cp gregorio.1 $MANDIR
cp gprocess $BINDIR

cd fonts
python install.py
cd ..

cp lib/* $LIBDIR
cp lib/gregorio/* $GRELIBDIR
cp bin/* $BINDIR
cp include/gregorio/* $GREINCLUDEDIR
