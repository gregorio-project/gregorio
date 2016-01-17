#!/usr/bin/env bash

# This script is designed to automatically configure a TeXworks distribution.
# You should be able to direct it to run by double clicking on it.


#This trap combination allows the window to linger long enough for the user to
#inspect the output, but still get closed when all is said and done.
function quit {
    read -n1 -r -p "Press any key to close window." key
    if $mac; then
        osascript -e 'tell application "Terminal" to close front window' > /dev/null 2>&1 &
    else
        exit
    fi
}

trap quit EXIT

case "$(uname -s)" in
    Darwin)
        echo 'Mac OS X detected'
        mac=true
        ToolsDir="$HOME/Library/TeXworks"
        ;;
    Linux)
        echo 'Linux detected'
        mac=false
        ToolsDir="$HOME/.TeXworks"
        ;;
    *)
        echo 'Unsupported OS detected'
        echo "Please configure TeXworks manually"
        exit 1
        ;;
esac

# Add the typesetting tool
TOOLS="$ToolsDir/configuration/tools.ini"
if [ ! -e "$TOOLS" ]; then
    echo "Cannot find TeXworks configuration"
    echo "Please open and close TeXworks and try running this script again"
    exit 1
fi
echo "Adding LuaLaTeX+se Typesetting tool"
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
CONFIG="$ToolsDir/configuration/texworks-config.txt"
oldCONFIG="$CONFIG.old"
mv "$CONFIG" "$oldCONFIG"
cleanup=false
echo "Adding Gregorio files to Open dialog and Trash Aux Files list"
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

echo "Configuration Complete"
exit 0
