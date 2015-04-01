#!/bin/bash

# First we compile Gregorio and build all the necessary pacakge components.
HERE=`pwd`/build
cd ..
./build.sh --arch=x86_64 --enable-all-static --disable-shared --enable-static-ltdl
make DESTDIR=$HERE install
./install-gtex.sh dir:$HERE
cd doc
make doc
cd ..
pandoc ./README.md -f markdown -t html -o $HERE/README.html
pandoc ./COPYING.md -f markdown -t html -o $HERE/COPYING.html
VERSION=`./VersionManager.py --get-current`
HTMLPREFIX="https://github.com/gregorio-project/gregorio/blob/v"$VERSION"/"
cd $HERE
sed -i.temp -E "s|(href=.)([A-Z]+.md.)|\1$HTMLPREFIX\2|g" README.html COPYING.html
rm *.temp


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
