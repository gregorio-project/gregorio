--Applescript
-- Tracy Llenos <tllenos@gmail.com>
-- a workaround macro for compiling Gregorio gabc files inside TeXShop

set fileName to #FILEPATH#
if fileName is equal to ""
activate
display dialog "Please save the file first" buttons {"OK"} default button "OK"
return
end if

-- finds proper filenames
-- from the Claus Gerhardt TeXShop macros
set fileName to #NAMEPATH#
set n to (number of characters of contents of fileName)
set fileNamequoted to quoted form of fileName
set baseName to do shell script "basename " & fileNamequoted
set m to (number of characters of contents of baseName)
set dirName to quoted form of (characters 1 thru (n - m - 1) of fileName as string)
set gabcName to baseName & ".gabc"

tell application "Terminal" 
activate
do script "cd " & dirName & "; " & "gregorio " & gabcName
delay 2
-- gives processes chance to terminate so user isn't prompted to kill them
close the front window
-- TODO: change behavior because number of windows spawned changes
-- should also consider letting Terminal quit
tell application "System Events"
tell process "Terminal"
keystroke "`" using {command down}
keystroke "w" using {command down}
end tell
end tell
end tell

tell application "TeXShop"
activate
end tell
-- we return to TeXShop