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
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.	If not, see <http://www.gnu.org/licenses/>.

You must run this program with texlua, if possible under a TeXLive 2010.
This program installs gregorio under Windows.
--]]

require("lfs")

kpse.set_program_name("luatex")

local pathsep = '/'
local function fixpath(path)
	return path
end
local function remove_trailing_slash(path)
	return path:gsub("/$" ,"")
end
local function basename(path)
	return path:gsub("^[^/]+/" ,"")
end
if os_type == "windows" or os_type == "msdos" then
	pathsep = '\\'
	fixpath = function(path)
		return path:gsub("/", "\\")
	end
	remove_trailing_slash = function(path)
		return path:gsub("\\$" ,"")
	end
	basename = function(path)
		return path:gsub("^[^\\]+\\" ,"")
	end
end

local texmflocal = fixpath(kpse.expand_var("$TEXMFLOCAL"))..pathsep
local texworksdir = fixpath(kpse.expand_var("$TEXMFCONFIG"))..pathsep..'texworks'..pathsep

local suffix = "gregoriotex"..pathsep
local dirs = {
	templatemain = texworksdir.."templates"..pathsep.."Gregorio Main File"..pathsep,
	templatescore = texworksdir.."templates"..pathsep.."Gregorio Score"..pathsep,
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
	local destfile = dest..basename(src)
	io.savedata(destfile, io.loaddata(src))
end

function copy_files()
	if not lfs.isdir(texmflocal) then
		lfs.mkdir(texmflocal)
	end
	print("copying files...\n")
	local texmfbin = kpse.expand_var("$TEXMFDIST")
	texmfbin = fixpath(texmfbin.."/../bin/win32/")
	copy_one_file("gregorio.exe", texmfbin)
	print("unzipping TDS zip file...\n")
	os.spawn("unzip.exe -o gregoriotex.tds.zip -d "..texmflocal:gsub("\\", "/")) -- TeXLive provides unzip!
	copy_one_file(fixpath('examples/main-lualatex.tex'), dirs.templatemain)
	copy_one_file(fixpath('examples/PopulusSion.gabc'), dirs.templatescore)
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
	fixpath(texmflocal.."tex/generic/gregoriotex"),
	fixpath(texmflocal.."tex/latex/gregoriotex"),
	fixpath(texmflocal.."fonts/ofm/gregoriotex"),
	fixpath(texmflocal.."fonts/tfm/gregoriotex"),
	fixpath(texmflocal.."fonts/type1/gregoriotex"),
	fixpath(texmflocal.."fonts/ovp/gregoriotex"),
	fixpath(texmflocal.."fonts/ovf/gregoriotex"), 
	fixpath(texmflocal.."fonts/map/gregoriotex"),
}

-- should remove the Read-Only flag on files under Windows, but doesn't work, no idea why... even the attrib command in cmd.exe doesn't work...
-- Windows doesn't seem to be a very reliable OS, it should be avoided...
function remove_read_only(filename)
	if os.name == "windows" or os.name == "msdos" then
		os.spawn(string.format("attrib -r \"%s\" /s /d", filename))
	end
end

-- a function removing one file
local function rm_one(filename)
	print("removing "..filename)
	remove_read_only(filename)
	local b, err = os.remove(filename)
	if not b then
		if err then
			print("error: "..err)
		else
			print("error when trying to remove "..filename)
		end
	end
end

-- a function removing a directory with all included files, using the previous one
-- does not work with subdirectories (we shouldn't have any here)
local function rmdirrecursive(dir)
	print("Removing directory "..dir)
	for filename in lfs.dir(dir) do
		if filename ~= "." and filename ~= ".." then
			rm_one(dir..pathsep..filename)
	end
	end
	rm_one(dir)
end

-- gregorio used to be installed in other directories which have precedence
-- over the new ones
function remove_possible_old_install()
	print("Removing possible old GregorioTeX files...\n")
	local old_install_was_present = false
	for _, d in pairs(old_base_dirs) do
		if lfs.isdir(d) then
			old_install_was_present = true
			rmdirrecursive(d)
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

function texworks_conf(install_dir)
	local filesdir = texworksdir
	if not lfs.isdir(remove_trailing_slash(texworksdir)) then
		 print("TeXWorks not found, skipping.\n"..texworksdir)
		 return
	end
	print("Modifying tools.ini...\n")
	texworks_conf_tools(filesdir.."configuration"..pathsep.."tools.ini", install_dir)
	print("Modifying TeXWorks.ini...\n")
	texworks_conf_ini(filesdir.."TUG"..pathsep.."TeXWorks.ini")
	print("Modifying texworks-config.txt...\n")
	texworks_conf_config(filesdir.."configuration"..pathsep.."texworks-config.txt")
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
file-open-filter: TeX documents (*.tex)
file-open-filter: Gabc score (*.gabc)
file-open-filter: LaTeX documents (*.ltx)
file-open-filter: BibTeX databases (*.bib)
file-open-filter: Style files (*.sty)
file-open-filter: Class files (*.cls)
file-open-filter: Documented macros (*.dtx)
file-open-filter: Auxiliary files (*.aux *.toc *.lot *.lof *.nav *.out *.snm *.ind *.idx *.bbl *.log)
file-open-filter: Text files (*.txt)
file-open-filter: PDF documents (*.pdf)
file-open-filter: All files (*.* *)
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

local full_tools_ini = {[[name=pdfTeX
program=pdftex.exe
arguments=$synctexoption, $fullname
showPdf=true]]}

full_tools_ini[2] = [[name=pdfLaTeX
program=pdflatex.exe
arguments=$synctexoption, $fullname
showPdf=true]]

full_tools_ini[3] = [[name=LuaTeX
program=luatex.exe
arguments=$synctexoption, $fullname
showPdf=true]]

full_tools_ini[4] = [[name=LuaLaTeX
program=lualatex.exe
arguments=$synctexoption, $fullname
showPdf=true]]

full_tools_ini[5] = [[name=XeTeX
program=xetex.exe
arguments=$synctexoption, $fullname
showPdf=true]]

full_tools_ini[6] = [[name=XeLaTeX
program=xelatex.exe
arguments=$synctexoption, $fullname
showPdf=true]]

full_tools_ini[7] = [[name=ConTeXt (LuaTeX)
program=context.exe
arguments=--synctex, $fullname
showPdf=true]]

full_tools_ini[8] = [[name=ConTeXt (pdfTeX)
program=texexec.exe
arguments=--synctex, $fullname
showPdf=true]]

full_tools_ini[9] = [[name=ConTeXt (XeTeX)
program=texexec.exe
arguments=--synctex, --xtx, $fullname
showPdf=true]]

full_tools_ini[10] = [[name=BibTeX
program=bibtex.exe
arguments=$basename
showPdf=false]]

full_tools_ini[11] = [[name=MakeIndex
program=makeindex.exe
arguments=$basename
showPdf=false]]

function texworks_conf_tools(filename, install_dir)
	local lualatexfound = 0
	local gregoriofound = 0
	local gregbookfound = 0
	-- by default, there is no tools.ini in the recent versions of TeXWorks
	if not lfs.isfile(filename) then 
		print(filename.." does not exist, creating it...\n")
		local toolstable = full_tools_ini
		current = 11
	else
		-- let's remove the read-only attribute
        remove_read_only(filename)
        local f = io.open(filename, 'r')
        local toolstable = {}
        local current = 0
        for l in f:lines() do
           local num = tonumber(l:match("%[(%d+)%]"))
           if num then
               current = num
           elseif l ~= "" then
               if string.lower(l) == "name=lualatex" then
                   lualatexfound = 1
               elseif string.lower(l) == "name=gregorio" then
                   gregoriofound = 1
               elseif string.lower(l) == "name=greg-book" then
                   gregbookfound = 1
               end
               if toolstable[current] == nil then
                   toolstable[current] = l
               else
                   toolstable[current] = toolstable[current]..'\n'..l
               end
           end
        end
    end
	if lualatexfound == 0 then
		current = current + 1
		toolstable[current] = "name=LuaLaTeX"
        toolstable[current] = toolstable[current]..'\n'..'program=lualatex'
        toolstable[current] = toolstable[current]..'\n'..'arguments=$synctexoption, $fullname'
        toolstable[current] = toolstable[current]..'\n'..'showPdf=true'
	end
	if gregoriofound == 0 then
		current = current + 1
		toolstable[current] = "name=gregorio"
        toolstable[current] = toolstable[current]..'\n'..'program='..install_dir..'/contrib/TeXworks/gregorio.bat'
        toolstable[current] = toolstable[current]..'\n'..'arguments=$fullname, $basename'
        toolstable[current] = toolstable[current]..'\n'..'showPdf=false'
	end
	if gregbookfound == 0 then
		current = current + 1
		toolstable[current] = 'name=greg-book'
        toolstable[current] = toolstable[current]..'\n'..'program='..install_dir..'/contrib/TeXworks/greg-book.bat'
        toolstable[current] = toolstable[current]..'\n'..'arguments=$fullname'
        toolstable[current] = toolstable[current]..'\n'..'showPdf=true'
	end
	if gregbookfound == 1 and gregoriofound == 1 and lualatexfound == 1 then
		return
	end
	local data = ""
	for i,s in ipairs(toolstable) do
		data = data..string.format("[%03d]\n", i)..s..'\n\n'
	end
	io.savedata(filename, data)
end

function scribus_config()
	local f = io.open('contrib'..pathsep..'900_gregorio.xml', 'r')
	local data = ""
	for l in f:lines() do
			if l:match("executable command") then
				data = data..string.format("	<executable command='texlua \"%s\" \"%%file\" \"%%dir\"'/>\n", lfs.currentdir()..pathsep.."contrib"..pathsep.."gregorio-scribus.lua")
		else
			data = data..l.."\n"
		end
		end
	io.savedata('contrib'..pathsep..'900_gregorio.xml', data)
end

if arg[1] == nil or arg[1] ~= '--conf' then		 
	main_install()
	scribus_config()
else
    --even though windows uses \ as the path seperator, TeXworks uses / so we
    --need to change that in the installation directory name we've been passed
    install_dir = arg[2]:gsub("\\","/")
	texworks_conf(install_dir)
end
