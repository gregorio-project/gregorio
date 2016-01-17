#!/usr/bin/env bash

# This script is designed to automatically configure a TeXworks distribution on a Mac.
# You should be able to direct it to run by double clicking on it.


#This trap combination allows the window to linger long enough for the user to
#inspect the output, but still get closed when all is said and done.
function quit {
    read -n1 -r -p "Press any key to close window." key
    osascript -e 'tell application "Terminal" to close front window' > /dev/null 2>&1 &
}

trap quit EXIT

# Add the typesetting tool
TOOLS="$HOME/Library/TeXworks/configuration/tools.ini"
if [ ! -e "$TOOLS" ]; then
    echo "Cannot find TeXworks configuration"
    echo "Please open and close TeXworks and try running this script again"
    exit 1
fi
oldTOOLS="$TOOLS.old"
cp "$TOOLS" "$oldTOOLS"
last=`grep -E "^\[[0-9]+\]$" "$TOOLS" | tail -1`
last=${last:1:-1}
last=$(expr $last + 0)
(( last++ ))
last=`printf "%03d" $last`
last="[$last]"
echo "" >> "$TOOLS"
echo "$last" >> "$TOOLS"
echo "name=LuaLaTeX+se" >> "$TOOLS"
echo "program=lualatex" >> "$TOOLS"
echo "arguments=--shell-escape, \$synctexoption, \$fullname" >> "$TOOLS"
echo "showPdf=true" >> "$TOOLS"

# Add the file filter and cleanup patterns to the configuration
CONFIG="$HOME/Library/TeXworks/configuration/texworks-config.txt"
oldCONFIG="$CONFIG.old"
mv "$CONFIG" "$oldCONFIG"
cleanup=false
while read line; do
    if [[ $line == "# file-open-filter:"* ]]; then
        line=${line:2}
    fi
    if [[ $line == *"Auxiliary files"* ]]; then
        line="${line%?} *.gaux)"
    fi
    if [[ $line == *"All files"* ]]; then
        echo "file-open-filter:	Gabc score (*.gabc)" >> "$CONFIG"
    fi
    if [[ $line == "cleanup-patterns:"* ]]; then
        cleanup=true
    else
        if $cleanup; then
            echo "cleanup-patterns:	\$jobname.gaux *-*_*_*.gtex" >> "$CONFIG"
            cleanup=false
        fi
    fi
    echo "$line" >> "$CONFIG"
done < "$oldCONFIG"
