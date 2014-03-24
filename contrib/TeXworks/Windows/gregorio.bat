SETLOCAL ENABLEEXTENSIONS

set filename=%1
set texname=%2.gtex
"c:\Program Files\gregorio\gregorio.exe" -vW  "%filename%" -o "%texname%"
echo "produced %texname%"
