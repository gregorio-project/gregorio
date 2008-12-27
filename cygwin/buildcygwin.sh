#!/bin/sh
#Script to generate gregorio-cygwin.tgz with all the files necessary to create
#a gregorio cygwin distribution

PREFIX="/usr"
DESTDIR="cygwin/gregorio-0.9.2"
CURDIR=`cd .. && pwd`

cd ..
autoreconf -f -i
./configure --prefix=$PREFIX --enable-glib-utf8
make
make DESTDIR=$CURDIR/$DESTDIR install
xsltproc -o $DESTDIR/gregorio.1 -''-nonet /usr/share/docbook-xsl/manpages/docbook.xsl debian/manpage.xml 
cp -R fonts $DESTDIR
cp -R tex $DESTDIR
rm $DESTDIR/tex/Makefile*
cp -R examples $DESTDIR
rm $DESTDIR/examples/Makefile*
cp contrib/gprocess $DESTDIR
cp cygwin/doinstall.sh $DESTDIR
mv $DESTDIR/usr/* $DESTDIR
rm -rf $DESTDIR/usr
rm -rf $DESTDIR/share
