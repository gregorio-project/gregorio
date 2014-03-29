@echo off
SETLOCAL ENABLEEXTENSIONS EnableDelayedExpansion

echo Gregorio Engine for processing documents with included scores. (TeXWorks Windows Version)
echo (C) 2014 R. Padraic Springuel. This work is licensed under a Creative Commons Attribution 4.0 International License.

set filename=%1
:: scan the file for lines which add a gregorio score:
mtxrun -script grep -pattern="[\]includescore[{].*[}]" "%filename%" > tmpFile
mtxrun -script grep -pattern="[\]includetexscore[{].*[}]" "%filename%" >> tmpFile
mtxrun -script grep -pattern="[\]greincludetexscore[{].*[}]" "%filename%" >> tmpFile
::for each included score
for /f "tokens=3,4 delims={.}" %%a in (tmpFile) do (
	::first check for empty extensions and change to tex if present
	if "%%~b" == "" (
		set output=%%a.tex
	) else (
		set output=%%a.%%b
	)
	set gregname=%%a.gabc
	:: check to see if the score exists
	if not exist !gregname! (
		:: didn't find score, check to see if the included file exists
		if not exist !output! (
			echo Error: Neither !gregname! nor !output! exists!
			exit
		) else (
			echo Warning: Cannot update !output!.  !gregname! does not exist.
		)			
	) else (
		:: check to see if output exists
		if not exist !output! (
			:: Create the included file.
			"c:\Program Files\gregorio\gregorio.exe" -vW "!gregname!" -o "!output!"
			echo Produced !output!
		) else (
			:: check to see if gabc file is newer
			set temp1=!gregname:/=\!
			set temp2=!output:/=\!
			for /f "delims=" %%I in ('dir /b /OD !temp1! !temp2!') do set new=%%I
			if !gregname! == !new! (
				:: Update the included file.
				"c:\Program Files\gregorio\gregorio.exe" -vW "!gregname!" -o "!output!"
				echo Updated !output!
			) else (
				echo !gregname! has not changed.
			)
		)
	)
)
del tmpFile
:: compile the main project file
lualatex --shell-escape -file-line-error -synctex=1 "%filename%"
