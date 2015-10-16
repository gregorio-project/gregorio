#!/usr/bin/env bash

# Define a timestamp function
timestamp() {
    date +"%F %r %Z"
}

LOGDIR="/Users/Shared/Gregorio"
if [ ! -d "$LOGDIR" ]; then
    mkdir "$LOGDIR"
fi
LOGFILE="$LOGDIR/gregorio_install.log"

echo "$(timestamp): Gregorio Installation Started" > $LOGFILE
echo "$(timestamp): Checking for TeX installation" >> $LOGFILE

# Test to see if we have a valid TeX installation (by looking for kpsewhich)
kpsewhichFound=0
possibleLocations=(
    '/usr/texbin'
    '/Library/TeX/texbin'
)
for eachLocation in "${possibleLocations[@]}"; do
    if [[ -e "${eachLocation}/kpsewhich" ]]; then
        (( kpsewhichFound++ ))
        echo "$(timestamp): Found kpsewhich at $eachLocation" >> $LOGFILE
        texBinLocation="$eachLocation"
        break
    fi
done
if [[ "$kpsewhichFound" = 0 ]]; then
    echo "$(timestamp): Cannot find kpsewhich" >> $LOGFILE
    echo "$(timestamp): Installation Aborted!" >> $LOGFILE
    exit 1
else
    TEXMFLOCAL=`$texBinLocation/kpsewhich -var-value TEXMFLOCAL`
    if [ -z "$TEXMFLOCAL" ]; then
        echo "$(timestamp): no valid TEXMFLOCAL value" >> $LOGFILE
        ehco "$(timestamp): Installation Aborted!" >> $LOGFILE
        exit 1
    fi
fi
echo "$(timestamp): Installtion Check Passed, proceeding to install files" >> $LOGFILE
exit 0
