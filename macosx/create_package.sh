#!/bin/bash

# NOTE: This script assumes that it was invoked from the macosx directory and
# changes the working directory as needed accordingly.  Failure to invoke it
# from that directory will result in strange things happening.

HERE=`pwd`

# First we compile Gregorio and build all the necessary pacakge components.

# Command line tool and GregorioTeX
BUILDDIR=$HERE/build
cd ..
./build.sh --arch=x86_64 --enable-all-static --disable-shared --enable-static-ltdl
# If the build process fails we halt this script here, since we can't build the
# package without a properly compiled version of Gregorio.
if [ ! $? -eq 0 ]; then
    exit $?
fi
make DESTDIR=$BUILDDIR install
./install-gtex.sh dir:$BUILDDIR/tmp/gregorio

# Documentation and other extras
EXTRASDIR=$BUILDDIR/Gregorio
mkdir $EXTRASDIR
mkdir $EXTRASDIR/doc
cd doc
make doc
cd ..
cp doc/*.tex $EXTRASDIR/doc/
cp doc/*.pdf $EXTRASDIR/doc/
cp doc/*.md $EXTRASDIR/doc/
cp -r contrib/ $EXTRASDIR/contrib
mv $EXTRASDIR/contrib/TeXworks/Mac\ OSX/* $EXTRASDIR/contrib/TeXworks
rm -rf $EXTRASDIR/contrib/TeXworks/Mac\ OSX
rm -rf $EXTRASDIR/contrib/TeXworks/Windows
rm -rf $EXTRASDIR/contrib/TeXworks/Linux
rm $EXTRASDIR/contrib/Makefile*
cp -r examples/ $EXTRASDIR/examples
rm $EXTRASDIR/examples/Makefile*
cp *.md $EXTRASDIR

# Installer Resources
RESOURCEDIR=$HERE/Resources
mkdir $RESOURCEDIR
pandoc -s ./README.md -f markdown -t html -o $RESOURCEDIR/README.html
pandoc -s ./COPYING.md -f markdown -t html -o $RESOURCEDIR/COPYING.html
# We redirect the relative links in the above files to point to particular
# file versions in the repository.
VERSION=`./VersionManager.py --get-current`
HTMLPREFIX="https://github.com/gregorio-project/gregorio/blob/v"$VERSION"/"
cd $RESOURCEDIR
sed -i.temp -E "s|(href=.)([A-Z]+.md.)|\1$HTMLPREFIX\2|g" README.html COPYING.html
# There are a few of characters that cause some problems, so we replace them
# with html character codes to tidy up the appearence of the documents.
sed -i.temp -E "s|\(C\)|\&copy;|g" README.html COPYING.html
sed -i.temp -E "s|©|\&copy;|g" README.html COPYING.html
sed -i.temp -E "s|--|\&#8212;|g" README.html COPYING.html
sed -i.temp -E "s|“|\&#8220;|g" README.html COPYING.html
sed -i.temp -E "s|”|\&#8221;|g" README.html COPYING.html


# Now we build the packages
# Eventually we'd like to do this with the XCode tools themselves, but for now
# we do it using Packages: http://s.sudre.free.fr/Software/Packages/about.html
cd $HERE
packagesbuild Gregorio.pkgproj
packagesbuild Uninstall-Gregorio.pkgproj

# Having built the pacakges, we move them out of the build directory, attaching
# the version number to the filename in the process.
# The uninstall pacakge doesn't need the version number because it doesn't
# care about the version of gregorio.
VERSION=`echo $VERSION | sed s:[.]:_:g`
mv $BUILDDIR/Gregorio.pkg ../Gregorio-$VERSION.pkg
mv $BUILDDIR/Uninstall-Gregorio.pkg ../

# Now we clean up
cd ..
make clean
make distclean
cd $HERE
rm -rf build/
rm -rf Resources/
