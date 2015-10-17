#!/usr/bin/env bash

# Import the common material which locates the TeX tools and sets up the logfile
source common.sh

writelog 6 "Running Postflight Script"

# After installation we move the TeX files from their temporary location to
# the appropriate permanent location

texmfLocal=`$KPSEWHICH -expand-path TEXMFLOCAL`
sep=`$KPSEWHICH -expand-path "{.,.}"`
sep="${sep#.}"
sep="${sep%.}"
texmfLocal="${texmfLocal%${sep}}"
if [ -z "$texmfLocal" ]; then
    texmfLocal=`$KPSEWHICH -var-value TEXMFLOCAL`
fi

writelog 6 "Copying files to $texmfLocal"
cp -av /tmp/gregorio/ $texmfLocal >> $LOGFILE 2>&1
writelog 6 "Removing temporary files"
rm -rf /tmp/gregorio >> $LOGFILE 2>&1


# run texhash so that TeX is aware of the new files
writelog 6 "Running texhash"
$TEXHASH >> $LOGFILE 2>&1

# Change permisions on the installed supplemental files
cd /Users/Shared/Gregorio
writelog 6 "Setting Permissions for examples and doc"
chmod -R 777 examples/
chmod -R 777 doc/

writelog 6 "Installation Complete"
