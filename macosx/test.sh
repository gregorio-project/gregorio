#!/usr/bin/env bash

# Import the common material which locates the TeX tools and sets up the logfile
source common.sh

writelog 6 "Checking for TeX installation"

# We assume that if common.sh could not find the TeX tools, then no valid TeX
# installation exists
if [[ "$kpsewhichFound" = 0 ]]; then
    writelog 3 "Cannot find kpsewhich"
    writelog 3 "Installation Aborted!"
    exit 1
else
    writelog 6 "Found kpsewhich at $eachLocation"
    # We now look to make sure TEXMFLOCAL is set
    texmfLocal=`$KPSEWHICH -var-value TEXMFLOCAL`
    if [ -z "$texmfLocal" ]; then
        writelog 3 "no valid TEXMFLOCAL value"
        writelog 3 "Installation Aborted!"
        exit 1
    else
        writelog 6 "TEXMFLOCAL has value $texmfLocal"
    fi
fi
writelog 6 "Installtion Check Passed, proceeding to install files"
exit 0
