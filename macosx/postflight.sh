#!/bin/bash

# After installation we move the TeX files from their temporary location to
# the appropriate permanent location and then run texhash so that TeX is
# aware of the changes.


TEXHASH=${TEXHASH:-texhash}
TEXMFLOCAL=`kpsewhich -var-value TEXMFLOCAL`

mv /tmp/greogorio/* $TEXMFLOCAL
rm -rf /tmp/gregorio

${TEXHASH}
