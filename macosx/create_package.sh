#!/bin/bash

# NOTE: This script assumes that it was invoked from the macosx directory and changes the working directory as needed accordingly.  Failure to invoke it from that directory will result in strange things happening.

# First we compile Gregorio and build all the necessary pacakge components.
BUILDDIR=`pwd`/build
cd ..
./build.sh --arch=x86_64 --enable-all-static --disable-shared --enable-static-ltdl
make DESTDIR=$BUILDDIR install
./install-gtex.sh dir:$BUILDDIR
cd doc
make doc
cd ..
pandoc ./README.md -f markdown -t html -o $HERE/README.html
pandoc ./COPYING.md -f markdown -t html -o $HERE/COPYING.html
VERSION=`./VersionManager.py --get-current`
HTMLPREFIX="https://github.com/gregorio-project/gregorio/blob/v"$VERSION"/"
cd $BUILDDIR
sed -i.temp -E "s|(href=.)([A-Z]+.md.)|\1$HTMLPREFIX\2|g" README.html COPYING.html


# Now we build the packages
cd ..
packagesbuild gregorio-contrib.pkgproj
packagesbuild gregorio-doc.pkgproj
packagesbuild gregorio-examples.pkgproj
packagesbuild Gregorio.pkgproj
packagesbuild Uninstall-Gregorio.pkgproj

VERSION=`echo $VERSION | sed s:[.]:_:g`
mv build/Gregorio.mpkg ../Gregorio-$VERSION.mpkg
mv build/Uninstall-Gregorio.pkg ../

# Now we clean up
cd ../doc
make clean
cd ..
make clean
cd macosx
rm -rf build/
