#!/bin/bash
# Postflight script to move the Gregorio examples and such to 
# a more convenient place (~/Library/Gregorio)
# Better would be to adapt install.lua to OS X

PATH=$PATH:/usr/texbin

PREFIX="/usr/local"
TEMPDIR="/private/tmp/gregorio"
GREUSERDIR="$HOME/Library/Gregorio"
GREFONTDIR="$GREUSERDIR/fonts"
GRECONTRIBDIR="$GREUSERDIR/contrib"
OLDGREUSERDIR="$HOME/Documents/Gregorio"
TEXSHOPDIR="$HOME/Library/TeXShop"

mkdir -p $GREUSERDIR
cp -f -R $TEMPDIR/* $GREUSERDIR

chown -R $USER $GREUSERDIR

# cleanup from older package installation, if it exists
# we leave most of the old directory alone, just in case
if [[ -f $OLDGREUSERDIR/douninstall.sh ]]; then
	chown -R $USER $OLDGREUSERDIR
	cd $OLDGREUSERDIR
	rm -dR $PREFIX/lib/gregorio
	rm $PREFIX/lib/pkgconfig/gregorio.pc
	rm $PREFIX/lib/libgregorio*.dylib
	rm $PREFIX/lib/libgregorio*.la
	rm -dR $PREFIX/include/gregorio
	rm -dR /Library/Receipts/gregorio-1.0.pkg
	rm $OLDGREUSERDIR/douninstall.sh
fi

# TeXShop support
if [[ -d $TEXSHOPDIR ]]; then
	cp -f $GRECONTRIBDIR/gregorio.engine $TEXSHOPDIR/Engines
#	ok, this doesn't work
#	/usr/bin/defaults write TeXShop OtherTeXExtensions -array-add "\"gabc\""
	cp -f $GREUSERDIR/examples/main-lualatex.tex $TEXSHOPDIR/Templates
#	cp -f $GREUSERDIR/examples/PopulusSion.gabc $TEXSHOPDIR/Templates
fi

# install fonts; have to be in font dir for install.py to work
cd $GREFONTDIR
python ./install.py

# this should be variable, but anyways.. run updmap for the user if he has
# personal map files generated
if [[ -f $HOME/Library/texlive/2010/texmf-var/fonts/map/pdftex/updmap/pdftex.map ]]; then
	updmap
fi

rm -dR $TEMPDIR
#  something went wrong?, look here: /var/log
