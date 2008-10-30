#!/bin/sh
#Script to generate gregorio-cygwin.tgz with all the files necessary to create
#a gregorio cygwin distribution

PREFIX="/usr"
DESTDIR="cygwin/gregorio-cygwin"

cd ..
autoreconf -f -i
./configure --prefix=$PREFIX
make
mkdir -p $DESTDIR
cp src/gregorio.exe $DESTDIR
cp src/gregorio $DESTDIR
cp -R lib $DESTDIR
rm $DESTDIR/lib/*.c
rm $DESTDIR/lib/*.h
rm $DESTDIR/lib/Makefile*
cp -R src $DESTDIR/bin
rm $DESTDIR/bin/*.c
rm $DESTDIR/bin/Makefile*
cp -R plugins/dump $DESTDIR
rm $DESTDIR/dump/*.c
rm $DESTDIR/dump/*.h
rm $DESTDIR/dump/Makefile*
cp -R plugins/gabc $DESTDIR
rm $DESTDIR/gabc/*.c
rm $DESTDIR/gabc/*.l
rm $DESTDIR/gabc/*.y
rm $DESTDIR/gabc/*.h
rm $DESTDIR/gabc/Makefile*
cp -R plugins/gregoriotex $DESTDIR
rm $DESTDIR/gregoriotex/*.c
rm $DESTDIR/gregoriotex/*.h
rm $DESTDIR/gregoriotex/Makefile*
cp -R plugins/opustex $DESTDIR
rm $DESTDIR/opustex/*.c
rm $DESTDIR/opustex/*.h
rm $DESTDIR/opustex/Makefile*
cp -R plugins/xml $DESTDIR
rm $DESTDIR/xml/*.c
rm $DESTDIR/xml/*.h
rm $DESTDIR/xml/Makefile*
cp cygwin/doinstall.sh $DESTDIR
cp cygwin/README $DESTDIR
cp libtool $DESTDIR
xsltproc -o $DESTDIR/gregorio.1 -''-nonet /usr/share/docbook-xsl/manpages/docbook.xsl debian/manpage.xml 
cp -R fonts $DESTDIR
cp -R tex $DESTDIR
cd cygwin
tar czf ../gregorio-cygwin.tgz gregorio-cygwin
cd ..
