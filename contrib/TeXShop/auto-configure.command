#!/usr/bin/env bash

# This script is designed to automatically configure a TeXShop distribution.
# You should be able to direct it to run by double clicking on it.

#Copy the engine file from its instalation directory to the TeXShop Engines directory
ENGINEDIR="$HOME/Library/TeXShop/Engines"
if [ ! -d "$ENGINEDIR" ]; then
    mkdir -p "$ENGINEDIR"
fi
SOURCE="/Users/Shared/Gregorio/contrib/TeXShop/LuaLaTeX+se.engine"
if [ -e "$SOURCE" ]; then
    cp "$SOURCE" "$ENGINEDIR"
else
    echo "Cannot find LuaLaTeX+se.engine"
    echo "Please try running the Gregorio intaller again"
    exit 1
fi

#Add 'gabc' to the list of file extensions which TeXShop knows
TeXShopDir=`osascript -e 'POSIX path of (path to app "TeXShop")'`

defaults write "$TeXShopDir/Contents/Info.plist" CFBundleDocumentTypes -array-add '<dict>
<key>CFBundleTypeExtensions</key>
<array>
<string>gabc</string>
</array>
<key>CFBundleTypeName</key>
<string>gabc</string>
<key>CFBundleTypeOSTypes</key>
<array>
<string>GABC</string>
</array>
<key>CFBundleTypeRole</key>
<string>Editor</string>
<key>LSItemContentTypes</key>
<array>
<string>com.unknown.gabc</string>
</array>
<key>LSTypeIsPackage</key>
<false/>
<key>NSDocumentClass</key>
<string>TSDocument</string>
<key>NSPersistentStoreTypeKey</key>
<string>Binary</string>
</dict>'

#enable syntax coloring and the Typeset button for gabc files
defaults write TeXShop OtherTeXExtensions -array-add "gabc"

#Add gtex and gaux to the list of aux files deleted with Trash Aux Files
defaults write TeXShop OtherTrashExtensions -array-add "gtex"
defaults write TeXShop OtherTrashExtensions -array-add "gaux"
