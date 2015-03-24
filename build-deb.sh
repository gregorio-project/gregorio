#!/usr/bin/env bash
#
# This is a very simple and naive script to build the debian packages, in case
# it can be useful.


until [ -z "$1" ]; do
  case "$1" in
    --clean     ) CLEAN=TRUE    ;;
    --lint      ) LINT=TRUE    ;;
    --git       ) GIT=TRUE    ;;
    *           ) echo "ERROR: invalid build.sh parameter: $1"; exit 1       ;;
  esac
  shift
done

VERSION=`./VersionManager.py --get-current`
if [ "$GIT" = "TRUE" ]
then
  DEBIAN_VERSION=`./VersionManager.py --get-debian-git`
else
  DEBIAN_VERSION=`./VersionManager.py --get-debian-stable`
fi

if [ "$CLEAN" = "TRUE" ]
then
  rm gregorio_$DEBIAN_VERSION*
  rm gregoriotex_$DEBIAN_VERSION*
  rm -rf gregorio-$VERSION
else
  if [ "$LINT" = "TRUE" ]
  then
    lintian gregorio_$DEBIAN_VERSION*.changes
  else
    autoreconf -f -i
    ./configure
    make dist
    tar xzf gregorio-$VERSION.tar.gz
    mv gregorio-$VERSION.tar.gz gregorio_$DEBIAN_VERSION.orig.tar.gz
    cd gregorio-$VERSION
    ./configure
    cp -R ../debian .
    dpkg-buildpackage
  fi
fi
