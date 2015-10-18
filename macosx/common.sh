#!/usr/bin/env bash

# Setup logging file
LOGDIR="/Users/Shared/Gregorio"
if [ ! -d "$LOGDIR" ]; then
    mkdir "$LOGDIR"
fi
LOGFILE="$LOGDIR/gregorio_install.log"
if [ ! -e "$LOGFILE" ]; then
    logger -s -t "Gregorio" -p "user.6" "Gregorio Installater Started" 2> $LOGFILE
fi

# Define a logging function
# Priority definitions:
# 0: Emergency (all terminals display message in addition to log)
# 1: Alert
# 2: Critical
# 3: Error
# 4: Warning
# 5: Notice
# 6: Info
# 7: Debug
# higher numbers wrap
writelog(){
    logger -s -t "Gregorio" -p "user.${1}" "$2" 2>> $LOGFILE
}

# Locate TeX Tools
kpsewhichFound=0
mktexlsrFound=0
possibleLocations=(
    '/usr/texbin'
    '/Library/TeX/texbin'
    '/opt/local/bin'
    '/usr/local/bin'
)
for eachLocation in "${possibleLocations[@]}"; do
    if [[ -e "${eachLocation}/kpsewhich" ]]; then
        (( kpsewhichFound++ ))
        KPSEWHICH="$eachLocation/kpsewhich"
    fi
    if [[ -e "${eachLocation}/mktexlsr" ]]; then
        (( mktexlsrFound++ ))
        MKTEXLSR="$eachLocation/mktexlsr"
    fi
    if [[ $kpsewhichFound -ne "0" && $mktexlsrFound -ne "0" ]]; then
        break
    fi
done
