@echo off
SETLOCAL ENABLEEXTENSIONS

set output="c:\system-setup.log"

echo Gregorio Widows Setup Diagnostic Tool
echo (C) 2015 The Gregorio Project.
echo.
echo Gregorio is free software: you can redistribute it and/or modify
echo it under the terms of the GNU General Public License as published by
echo the Free Software Foundation, either version 3 of the License, or
echo (at your option) any later version.
echo.
echo This program is distributed in the hope that it will be useful,
echo but WITHOUT ANY WARRANTY; without even the implied warranty of
echo MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
echo GNU General Public License for more details.
echo.
echo You should have received a copy of the GNU General Public License
echo along with this program.  If not, see http://www.gnu.org/licenses/.
echo.
echo Creating %output%...

echo 	Gregorio Windows Setup Results > %output%
echo 	Created: %date% >> %output%
echo ----------------------------------------------------------------------------- >> %output%
echo. >> %output%
echo. >> %output%

echo 	Windows Version >> %output%
ver >> %output%
echo ----------------------------------------------------------------------------- >> %output%
echo. >> %output%
echo. >> %output%

echo 	LuaTeX Version >> %output%
echo. >> %output%
luatex -v >> %output% 2>&1
echo 	LuaTeX Location >> %output%
echo. >> %output%
@for %%e in (%PATHEXT%) do @for %%i in (luatex%%e) do @if NOT "%%~$PATH:i"=="" echo %%~$PATH:i >> %output% 2>&1
echo ----------------------------------------------------------------------------- >> %output%
echo. >> %output%
echo. >> %output%

echo 	TEXMFLOCAL >> %output%
echo. >> %output%
kpsewhich --var-value TEXMFLOCAL >> %output% 2>&1
echo ----------------------------------------------------------------------------- >> %output%
echo. >> %output%
echo. >> %output%

echo 	Gregorio Version >> %output%
echo. >> %output%
gregorio -V >> %output% 2>&1
echo. >> %output%
echo 	Gregorio Location >> %output%
echo. >> %output%
@for %%e in (%PATHEXT%) do @for %%i in (gregorio%%e) do @if NOT "%%~$PATH:i"=="" echo %%~$PATH:i >> %output% 2>&1
echo ----------------------------------------------------------------------------- >> %output%
echo. >> %output%
echo. >> %output%

echo 	GregorioTeX Location >> %output%
echo. >> %output%
kpsewhich gregoriotex.sty >> %output% 2>&1
echo ----------------------------------------------------------------------------- >> %output%
echo. >> %output%
echo. >> %output%

echo %output% created.  Please attach the file to an email to 
echo gregorio-users@gna.org or create an issue at 
echo http://github.org/gregorio-project/gregorio/issues
echo. 
pause
