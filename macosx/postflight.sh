#!/bin/bash

# After installation we move the TeX files from their temporary location to
# the appropriate permanent location and then run texhash so that TeX is
# aware of the changes.


TEXMFLOCAL=`/usr/texbin/kpsewhich -var-value TEXMFLOCAL`

cp -r /tmp/gregorio/* $TEXMFLOCAL
rm -rf /tmp/gregorio

/usr/texbin/texhash
