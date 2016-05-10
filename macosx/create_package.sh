#!/usr/bin/env bash

# NOTE: This script assumes that it was invoked from the macosx directory and
# changes the working directory as needed accordingly.  Failure to invoke it
# from that directory will result in strange things happening.

rcfile=create_package.rc
if [ -f $rcfile -a -r $rcfile ]; then
    source $rcfile
fi

case "$(echo $CLEAN | tr '[:upper:]' '[:lower:]')" in
    t|true|y|yes)
        clean=true
        ;;
    *)
        clean=false
        ;;
esac

while (( $# > 0 )); do
    unset OPTIND
    while getopts ":c" opt; do
        case $opt in
            c)
                if $clean; then
                    clean=false
                else
                    clean=true
                fi
                ;;
            \?)
                echo "Unknown option: -$OPTARG" >&2
                exit 2
                ;;
            esac
    done
    shift $((OPTIND - 1))
done


HERE=`pwd`
cd ..
VERSION=`./VersionManager.py --get-current`

# First we compile Gregorio and build all the necessary pacakge components.

# Command line tool and GregorioTeX
BUILDDIR=$HERE/build
if [ -d "$BUILDDIR" ]; then
    echo "Using existing build"
else
    cd $HERE/..
    ./build.sh --arch=x86_64
    # If the build process fails we halt this script here, since we can't build the
    # package without a properly compiled version of Gregorio.
    exit_code=$?
    if [ ! $exit_code -eq 0 ]; then
        exit $exit_code
    fi
    make DESTDIR=$BUILDDIR install
    ./install-gtex.sh dir:$BUILDDIR/tmp/gregorio
fi

# Documentation and other extras
EXTRASDIR=$BUILDDIR/Gregorio
if [ -d "$EXTRASDIR" ]; then
    echo "Using existing extras"
else
    mkdir $EXTRASDIR
    mkdir $EXTRASDIR/doc
    mkdir $EXTRASDIR/examples
    cd $HERE/../doc
    make doc
    cd ..
    cp doc/*.tex $EXTRASDIR/doc/
    cp doc/*-*.pdf $EXTRASDIR/doc/
    cp doc/*.md $EXTRASDIR/doc/
    cp doc/*.gabc $EXTRASDIR/doc/
    cp -r contrib/ $EXTRASDIR/contrib
    find $EXTRASDIR/contrib -name 'Makefile*' -delete
    cp examples/*.tex $EXTRASDIR/examples/
    cp examples/*.gabc $EXTRASDIR/examples/
    cp *.md $EXTRASDIR
fi

# Installer Resources
RESOURCEDIR=$HERE/Resources
if [ -d "$RESOURCEDIR" ]; then
    echo "Using existing installer resources"
else
    mkdir $RESOURCEDIR
    cd $HERE/..
    pandoc -s ./README.md -f markdown -t html -o $RESOURCEDIR/README.html
    pandoc -s ./COPYING.md -f markdown -t html -o $RESOURCEDIR/COPYING.html
    # We redirect the relative links in the above files to point to particular
    # file versions in the repository.
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
fi

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
if $clean; then
    cd ..
    make maintainer-clean
    cd $HERE
    rm -rf build/
    rm -rf Resources/
fi