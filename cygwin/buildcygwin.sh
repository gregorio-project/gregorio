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
mkdir -p $DESTDIR/plugins
cp -R lib $DESTDIR
rm $DESTDIR/lib/*.c
rm $DESTDIR/lib/*.h
rm $DESTDIR/lib/Makefile*
cp -R src $DESTDIR/bin
rm $DESTDIR/bin/*.c
rm $DESTDIR/bin/Makefile*
cp -R plugins/dump $DESTDIR/plugins
rm $DESTDIR/plugins/dump/*.c
rm $DESTDIR/plugins/dump/*.h
rm $DESTDIR/plugins/dump/Makefile*
cp -R plugins/gabc $DESTDIR/plugins
rm $DESTDIR/plugins/gabc/*.c
rm $DESTDIR/plugins/gabc/*.l
rm $DESTDIR/plugins/gabc/*.y
rm $DESTDIR/plugins/gabc/*.h
rm $DESTDIR/plugins/gabc/Makefile*
cp -R plugins/gregoriotex $DESTDIR/plugins
rm $DESTDIR/plugins/gregoriotex/*.c
rm $DESTDIR/plugins/gregoriotex/*.h
rm $DESTDIR/plugins/gregoriotex/Makefile*
cp -R plugins/opustex $DESTDIR/plugins
rm $DESTDIR/plugins/opustex/*.c
rm $DESTDIR/plugins/opustex/*.h
rm $DESTDIR/plugins/opustex/Makefile*
cp -R plugins/xml $DESTDIR/plugins
rm $DESTDIR/plugins/xml/*.c
rm $DESTDIR/plugins/xml/*.h
rm $DESTDIR/plugins/xml/Makefile*
cp cygwin/doinstall.sh $DESTDIR
cp cygwin/README $DESTDIR
cp contrib/gprocess $DESTDIR
cp libtool $DESTDIR
xsltproc -o $DESTDIR/gregorio.1 -''-nonet /usr/share/docbook-xsl/manpages/docbook.xsl debian/manpage.xml 
cp -R fonts $DESTDIR
cp -R tex $DESTDIR
rm $DESTDIR/tex/Makefile*
cd cygwin
tar czf ../gregorio-cygwin.tgz gregorio-cygwin
cd ..
