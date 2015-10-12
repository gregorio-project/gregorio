#!/bin/bash

# After installation we move the TeX files from their temporary location to
# the appropriate permanent location and then run texhash so that TeX is
# aware of the changes.


TEXMFLOCAL=`kpsewhich -expand-path \$TEXMFLOCAL`
sep=`kpsewhich -expand-path "{.,.}"`
if [ -z "$TEXMFLOCAL" ]; then
    TEXMFLOCAL=`kpsewhich -var-value TEXMFLOCAL`
fi
if [ -z "$TEXMFLOCAL" ]; then
    TEXMFLOCAL=`/usr/texbin/kpsewhich -expand-path $TEXMFLOCAL`
    sep=`/usr/texbin/kpsewhich -expand-path "{.,.}"`
fi
if [ -z "$TEXMFLOCAL" ]; then
    TEXMFLOCAL=`/usr/texbin/kpsewhich -var-value TEXMFLOCAL`
fi
if [ -z "$TEXMFLOCAL" ]; then
    TEXMFLOCAL=`/Library/TeX/texbin/kpsewhich -expand-path $TEXMFLOCAL`
    sep=`/usr/texbin/kpsewhich -expand-path "{.,.}"`
fi
if [ -z "$TEXMFLOCAL" ]; then
    TEXMFLOCAL=`/Library/TeX/texbin/kpsewhich -var-value TEXMFLOCAL`
fi

TEXHASH=`which texhash`
if [ -z "$TEXHASH" ]; then
    TEXHASH="/usr/texbin/texhash"
fi

sep="${sep#.}"
sep="${sep%.}"
TEXMFLOCAL="${TEXMFLOCAL%${sep}}"

cp -r /tmp/gregorio/* $TEXMFLOCAL
rm -rf /tmp/gregorio

$TEXHASH
