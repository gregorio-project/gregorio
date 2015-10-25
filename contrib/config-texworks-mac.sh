#!/usr/bin/env bash

# This script is designed to automatically configure a TeXworks distribution.

# Add the typesetting tool
TOOLS="$HOME/Library/TeXworks/configuration/tools.ini"
last=`grep -E "\[\d+\]" "$TOOLS" | tail -1`
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

# Add the file filter
CONFIG="$HOME/Library/TeXworks/configuration/texworks-config.txt"
echo "# file-open-filter: Gabc score (*.gabc)" >> "$CONFIG"
