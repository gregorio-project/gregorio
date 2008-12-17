#!/bin/sh
#Script to move the Gregorio examples and such to a more 
#convenient place (in the user's home directory) and to -globally-
#install the fonts in the user's TeX distribution ... I don't know
#if this is actually a `good' place yet...

TEMPDIR="/private/tmp/gregorio"
GREUSERDIR="$HOME/Library/Gregorio"
GREFONTDIR="$GREUSERDIR/fonts"

mkdir -p $GREUSERDIR

mv $TEMPDIR/* $GREUSERDIR

cd $GREFONTDIR
python install.py

rm -dR $TEMPDIR