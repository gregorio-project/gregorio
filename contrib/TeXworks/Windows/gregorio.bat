@echo off
SETLOCAL ENABLEEXTENSIONS

echo Gregorio Engine for converting gabc files to gtex (Windows Version)
echo (C) 2014 R. Padraic Springuel. This work is licensed under a Creative Commons Attribution 4.0 International License.

set filename=%1
set texname=%2.gtex
"c:\Program Files\gregorio\gregorio.exe" -vW  "%filename%" -o "%texname%"
echo Produced %texname%
