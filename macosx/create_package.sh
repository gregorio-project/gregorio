#!/bin/bash

# NOTE: This script assumes that it was invoked from the macosx directory and
# changes the working directory as needed accordingly.  Failure to invoke it
# from that directory will result in strange things happening.

# First we compile Gregorio and build all the necessary pacakge components.
BUILDDIR=`pwd`/build
cd ..
./build.sh --arch=x86_64 --enable-all-static --disable-shared --enable-static-ltdl
if [ ! $? -eq 0 ]; then
    exit $?
fi
make DESTDIR=$BUILDDIR install
./install-gtex.sh dir:$BUILDDIR/tmp
cd doc
make doc
cd ..
pandoc ./README.md -f markdown -t html -o $BUILDDIR/README.html
pandoc ./COPYING.md -f markdown -t html -o $BUILDDIR/COPYING.html
VERSION=`./VersionManager.py --get-current`
HTMLPREFIX="https://github.com/gregorio-project/gregorio/blob/v"$VERSION"/"
cd $BUILDDIR
sed -i.temp -E "s|(href=.)([A-Z]+.md.)|\1$HTMLPREFIX\2|g" README.html COPYING.html


# Now we build the packages
# Eventually we'd like to do this with the XCode tools themselves, but for now
# we do it using Packages: http://s.sudre.free.fr/Software/Packages/about.html
cd ..
packagesbuild Gregorio.pkgproj
packagesbuild Uninstall-Gregorio.pkgproj

# Having built the pacakges, we move them out of the build directory, attaching
# the version number to the filename in the process.
# The uninstall pacakge doesn't need the version number because it doesn't
# care about the version of gregorio.
VERSION=`echo $VERSION | sed s:[.]:_:g`
mv build/Gregorio.mpkg ../Gregorio-$VERSION.mpkg
mv build/Uninstall-Gregorio.pkg ../

# Now we clean up
#make distclean
#cd macosx
#rm -rf build/
