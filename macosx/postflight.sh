#!/usr/bin/env bash

# Define a timestamp function
timestamp() {
    date +"%F %r %Z"
}

LOGDIR="/Users/Shared/Gregorio"
LOGFILE="$LOGDIR/gregorio_install.log"

echo "$(timestamp): Running Postflight Script" >> $LOGFILE

# Find the tools
possibleLocations=(
    '/usr/texbin'
    '/Library/TeX/texbin'
)
for eachLocation in "${possibleLocations[@]}"; do
    if [[ -e "${eachLocation}/texhash" ]]; then
        echo "$(timestamp): Found tools at $eachLocation" >> $LOGFILE
        TEXHASH="$eachLocation/texhash"
        KPSEWHICH="$eachLocation/kpsewhich"
        break
    fi
done


# After installation we move the TeX files from their temporary location to
# the appropriate permanent location

TEXMFLOCAL=`$KPSEWHICH -expand-path TEXMFLOCAL`
sep=`$KPSEWHICH -expand-path "{.,.}"`
sep="${sep#.}"
sep="${sep%.}"
TEXMFLOCAL="${TEXMFLOCAL%${sep}}"
if [ -z "$TEXMFLOCAL" ]; then
    TEXMFLOCAL=`$KPSEWHICH -var-value TEXMFLOCAL`
fi

echo "$(timestamp): Copying files to $TEXMFLOCAL" >> $LOGFILE
cp -r /tmp/gregorio/* $TEXMFLOCAL >> $LOGFILE 2>&1
echo "$(timestamp): Removing temporary files" >> $LOGFILE
rm -rf /tmp/gregorio >> $LOGFILE 2>&1


# run texhash so that TeX is aware of the new files
echo "$(timestamp): Running texhash" >> $LOGFILE
$TEXHASH >> $LOGFILE 2>&1
echo "$(timestamp): Installation Complete" >> $LOGFILE
