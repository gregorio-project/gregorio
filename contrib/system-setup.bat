@echo off
SETLOCAL ENABLEEXTENSIONS

set output="system-setup.log"

echo Gregorio Widows Setup Diagnostic Tool
echo (C) 2015 The Gregorio Project.
echo
echo Gregorio is free software: you can redistribute it and/or modify
echo it under the terms of the GNU General Public License as published by
echo the Free Software Foundation, either version 3 of the License, or
echo (at your option) any later version.
echo
echo This program is distributed in the hope that it will be useful,
echo but WITHOUT ANY WARRANTY; without even the implied warranty of
echo MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
echo GNU General Public License for more details.
echo 
echo You should have received a copy of the GNU General Public License
echo along with this program.  If not, see <http://www.gnu.org/licenses/>.
echo
echo Creating %output%...

echo Gregorio Windows Setup Results > %output%
echo Created: %date% >> %output%

echo Windows Version >> %output%

echo LuaTeX Version >> %output%
echo Location >> %output%

echo TeXLua Version >> %output%
echo Location >> %output%

echo TEXMFLOCAL >> %output%
kpsewhich --var-value TEXMFLOCAL >> %output%

echo Gregorio Version >> %output%
gregorio -v >> %output%
echo Location >> %output%

echo GregorioTeX Location >> %output%
kpsewhich gregoriotex.sty >> %output%

echo %output% created.  Please attach the file to an email to gregorio-users@gna.org
echo or create an issue at http://github.org/gregorio-project/gregorio/issues
echo
pause
