#!/usr/bin/env texlua
--[[
Gregorio gabc optimization script.
Copyright (C) 2010 Elie Roux <elie.roux@telecom-bretagne.eu>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

You must run this program with texlua, if possible under a TeXLive 2010.
This program installs gregorio under Windows.
--]]

kpse.set_program_name("luatex")

local texmflocal = kpse.expand_var("$TEXMFLOCAL"):gsub("/", "\\")..'\\'
local texworksdir = kpse.expand_var("$TEXMFCONFIG"):gsub("/", "\\")..'\\texworks\\'

local suffix = "gregoriotex\\"
local dirs = {
  templatemain = texworksdir.."templates\\Gregorio Main File\\",
  templatescore = texworksdir.."templates\\Gregorio Score\\",
}

function io.loaddata(filename,textmode)
    local f = io.open(filename,(textmode and 'r') or 'rb')
    if f then
        local data = f:read('*all')
        f:close()
        return data
    else
        return nil
    end
end

function io.savedata(filename,data,joiner)
    local f = io.open(filename,"wb")
    if f then
        f:write(data or "")
        f:close()
        return true
    else
        return false
    end
end

function copy_one_file(src, dest)
  local destfile = dest..src:gsub("^[^\\]+\\" ,"")
  io.savedata(destfile, io.loaddata(src))
end

function copy_files()
  if not lfs.isdir(texmflocal) then
    lfs.mkdir(texmflocal)
  end
  print("copying files...\n")
  local texmfbin = kpse.expand_var("$TEXMFDIST")
  texmfbin = texmfbin:gsub("/", "\\").."\\..\\bin\\win32\\"
  copy_one_file("gregorio.exe", texmfbin)
  print("unzipping TDS zip file...\n")
  os.spawn("unzip.exe -o gregoriotex.tds.zip -d "..texmflocal:gsub("\\", "/")) -- TeXLive provides unzip!
  copy_one_file('examples\\main-lualatex.tex', dirs.templatemain)
  copy_one_file('examples\\PopulusSion.gabc', dirs.templatescore)
end

function create_dirs()
  for _, d in pairs(dirs) do
    lfs.mkdir(d)
  end
end

function run_texcommands()
  print("running mktexlsr\n")
  local p = os.spawn("mktexlsr "..texmflocal)
end

local old_base_dirs = {
  texmflocal.."tex\\generic\\gregoriotex",
  texmflocal.."tex\\latex\\gregoriotex",
  texmflocal.."fonts\\ofm\\gregoriotex",
  texmflocal.."fonts\\tfm\\gregoriotex",
  texmflocal.."fonts\\type1\\gregoriotex",
  texmflocal.."fonts\\ovp\\gregoriotex",
  texmflocal.."fonts\\ovf\\gregoriotex", 
  texmflocal.."fonts\\map\\gregoriotex",
}

-- gregorio used to be installed in other directories which have precedence
-- over the new ones
function remove_possible_old_install()
  print("Removing possible old GregorioTeX files...\n")
  local old_install_was_present = false
  for _, d in pairs(old_base_dirs) do
    if lfs.isdir(d) then
      old_install_was_present = true
	  print("Removing directory "..d)
      lfs.rmdir(d)
    end
  end
  if old_install_was_present then
    os.spawn("updmap")
  end
end

function main_install()
	remove_possible_old_install()
	create_dirs()
	copy_files()
	run_texcommands()
end

-- lfs.isdir doesn't allow trailing slashes
function format_dirpath(p)
    return p:gsub("\\$", "")
end

function texworks_conf()
	local filesdir = texworksdir
	if not lfs.isdir(format_dirpath(texworksdir)) then
	   print("TeXWorks not found, skipping.\n"..texworksdir)
	   return
	end
	print("Modifying tools.ini...\n")
	texworks_conf_tools(filesdir.."configuration\\tools.ini")
	print("Modifying TeXWorks.ini...\n")
	texworks_conf_ini(filesdir.."TUG\\TeXWorks.ini")
	print("Modifying texworks-config.txt...\n")
	texworks_conf_config(filesdir.."configuration\\texworks-config.txt")
end

function remove_read_only(filename)
    os.spawn(string.format("attrib -r \"%s\"", filename))
end

function texworks_conf_config(filename)
    remove_read_only(filename)
	local data = ""
	local f = io.open(filename, 'r')
	for l in f:lines() do
		-- we consider that if someone has already modified it (or a previous intall of gregorio), we don't do anything
		local m = l:find("^file%-open%-filter")
	    if m then
		    return
		end
		data = data..l.."\n"
    end
	data = data..[[
file-open-filter:	TeX documents (*.tex)
file-open-filter:	Gabc score (*.gabc)
file-open-filter:	LaTeX documents (*.ltx)
file-open-filter:	BibTeX databases (*.bib)
file-open-filter:	Style files (*.sty)
file-open-filter:	Class files (*.cls)
file-open-filter:	Documented macros (*.dtx)
file-open-filter:	Auxiliary files (*.aux *.toc *.lot *.lof *.nav *.out *.snm *.ind *.idx *.bbl *.log)
file-open-filter:	Text files (*.txt)
file-open-filter:	PDF documents (*.pdf)
file-open-filter:	All files (*.* *)
]]
	io.savedata(filename, data)
end

function texworks_conf_ini(filename)
    remove_read_only(filename)
	local f = io.open(filename, 'r')
	local data = ""
	for l in f:lines() do
	    if l:match("defaultEngine") then
		    data = data.."defaultEngine=LuaLaTeX\n"
		else
			data = data..l.."\n"
		end
    end
	io.savedata(filename, data)
end

local full_tools_ini = [[[001]
name=LuaLaTeX
program=lualatex.exe
arguments=$synctexoption, $fullname
showPdf=true

[002]
name=Gregorio
program=gregorio.exe
arguments=$fullname
showPdf=false

[003]
name=pdfTeX
program=pdftex.exe
arguments=$synctexoption, $fullname
showPdf=true

[004]
name=pdfLaTeX
program=pdflatex.exe
arguments=$synctexoption, $fullname
showPdf=true

[005]
name=LuaTeX
program=luatex.exe
arguments=$synctexoption, $fullname
showPdf=true

[006]
name=XeTeX
program=xetex.exe
arguments=$synctexoption, $fullname
showPdf=true

[007]
name=XeLaTeX
program=xelatex.exe
arguments=$synctexoption, $fullname
showPdf=true

[008]
name=ConTeXt (LuaTeX)
program=context.exe
arguments=--synctex, $fullname
showPdf=true

[009]
name=ConTeXt (pdfTeX)
program=texexec.exe
arguments=--synctex, $fullname
showPdf=true

[010]
name=ConTeXt (XeTeX)
program=texexec.exe
arguments=--synctex, --xtx, $fullname
showPdf=true

[011]
name=BibTeX
program=bibtex.exe
arguments=$basename
showPdf=false

[012]
name=MakeIndex
program=makeindex.exe
arguments=$basename
showPdf=false]]

function texworks_conf_tools(filename)
	-- by default, there is no tools.ini in the recent versions of TeXWorks
	if not lfs.isfile(filename) then 
	  print(filename.." does not exist, creating it...\n")
	  io.savedata(filename, full_tools_ini)
	  return
	end
   	-- let's remove the read-only attribute
	remove_read_only(filename)
	local f = io.open(filename, 'r')
	local toolstable = {}
	local current = 0
	local lualatexfound = 0
	local gregoriofound = 0
	for l in f:lines() do
	    local num = tonumber(l:match("(%d+)%]"))
		if num then
		  current = num
		else
		  if l == "" then
		  elseif string.lower(l) == "name=lualatex" then
		    lualatexfound = 1
		  elseif string.lower(l) == "name=gregorio" then
		    gregoriofound = 1
		  elseif toolstable[current] == nil then
		    toolstable[current] = l
	      else
		    toolstable[current] = toolstable[current]..'\n'..l
		  end
		end
	end
	if lualatexfound == 0 then
		local tmp = toolstable[1]
		toolstable[1] = [[name=LuaLaTeX
program=lualatex
arguments=$synctexoption, $fullname
showPdf=true]]
		toolstable[current+1] = tmp
	end
	if gregoriofound == 0 then
		local tmp = toolstable[2]
		toolstable[2] = [[name=Gregorio
program=gregorio
arguments=$fullname
showPdf=false]]
		toolstable[current+2] = tmp
	end
	if gregoriofound == 1 and lualatexfound == 1 then
		return
	end
	local data = ""
	for i,s in ipairs(toolstable) do
	  data = data..string.format("[%03d]\n", i)..s..'\n\n'
	end
	io.savedata(filename, data)
end

function scribus_config()
	local f = io.open('contrib\\900_gregorio.xml', 'r')
	local data = ""
	for l in f:lines() do
	    if l:match("executable command") then
		    data = data..string.format("	<executable command='texlua \"%s\" \"%%file\" \"%%dir\"'/>\n", lfs.currentdir().."\\contrib\\gregorio-scribus.lua")
		else
			data = data..l.."\n"
		end
    end
	io.savedata('contrib\\900_gregorio.xml', data)
end

if arg[1] == nil or arg[1] ~= '--conf' then 	 
  main_install()
  scribus_config()
else 	 
  texworks_conf()
end
