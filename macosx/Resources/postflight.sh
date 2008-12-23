#!/bin/sh
#Script to move the Gregorio examples and such to a more 
#convenient place (in the user's home directory) and to -globally-
#install the fonts in the user's TeX distribution

TEMPDIR="/private/tmp/gregorio"
GREUSERDIR="$HOME/Documents/Gregorio"
GREFONTDIR="$GREUSERDIR/fonts"

mkdir -p $GREUSERDIR

mv $TEMPDIR/* $GREUSERDIR

cd $GREFONTDIR
python install.py

rm -dR $TEMPDIR