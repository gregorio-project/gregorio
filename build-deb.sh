#!/usr/bin/env bash
#
# This is a very simple and naive script to build the debian packages, in case
# it can be useful.

DEBFULLNAME='Gregorio Builder'
DEBEMAIL='gregorio-devel@gna.org'
DEBVERSION='UNRELEASED'

until [ -z "$1" ]; do
  case "$1" in
    --clean      ) CLEAN=TRUE    ;;
    --lint       ) LINT=TRUE    ;;
    --git        ) GIT=TRUE    ;;
    --source     ) SOURCE=TRUE    ;;
    --fullname=* ) DEBFULLNAME=`echo $1 | sed 's/--fullname=\(.*\)/\1/' ` ;;
    --version=*  ) DEBVERSION=`echo $1 | sed 's/--version=\(.*\)/\1/' ` ;;
    --email=*    ) DEBEMAIL=`echo $1 | sed 's/--email=\(.*\)/\1/' ` ;;
    *            ) echo "ERROR: invalid build.sh parameter: $1"; exit 1       ;;
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
  rm -f gregorio_$DEBIAN_VERSION*
  rm -f gregoriotex_$DEBIAN_VERSION*
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
    sed -i "s/UNRELEASED/$DEBVERSION/g" debian/changelog
    echo "gregorio ($DEBIAN_VERSION-1) $DEBVERSION; urgency=low

  * Auto build.
 -- $DEBFULLNAME <$DEBEMAIL>  $(date -R)

$(cat debian/changelog)" > debian/changelog
    if [ "$SOURCE" = "TRUE" ]
    then
      dpkg-buildpackage -S
    else
      dpkg-buildpackage
    fi
  fi
fi
