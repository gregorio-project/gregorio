#!/bin/bash

# After installation we move the TeX files from their temporary location to
# the appropriate permanent location and then run texhash so that TeX is
# aware of the changes.


TEXMFLOCAL=`kpsewhich -var-value TEXMFLOCAL`
if [ -z "$TEXMFLOCAL" ]; then
    TEXMFLOCAL=`/usr/texbin/kpsewhich -var-value TEXMFLOCAL`
fi

TEXHASH=`which texhash`
if [ -z "$TEXHASH" ]; then
    TEXHASH="/usr/texbin/texhash"
fi

cp -r /tmp/gregorio/* $TEXMFLOCAL
rm -rf /tmp/gregorio

$TEXHASH
