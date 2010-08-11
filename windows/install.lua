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
  type1 = texmflocal.."fonts\\type1\\"..suffix,
  tfm = texmflocal.."fonts\\tfm\\"..suffix,
  map = texmflocal.."fonts\\map\\"..suffix,
  ofm = texmflocal.."fonts\\ofm\\"..suffix,
  ovf = texmflocal.."fonts\\ovf\\"..suffix,
  ovp = texmflocal.."fonts\\ovp\\"..suffix,
  tex = texmflocal.."tex\\generic\\"..suffix,
  latex = texmflocal.."tex\\latex\\"..suffix,
  templatemain = texworksdir.."templates\\Gregorio Main File\\",
  templatescore = texworksdir.."templates\\Gregorio Score\\",
}

local fonts = {"greciliae", "parmesan", "gresym", "greextra", "gregorio"}

local fonts_files = {
  "greciliae-0", "greciliae-1", "greciliae-2", "greciliae-3", "greciliae-4", "greciliae-5", "greciliae-6", "greciliae-7", "greciliae-8",
  "gregorio-0", "gregorio-1", "gregorio-2", "gregorio-3", "gregorio-4", "gregorio-5", "gregorio-6", "gregorio-7", "gregorio-8",
  "parmesan-0", "parmesan-1", "parmesan-2", "parmesan-3", "parmesan-4", "parmesan-6", "parmesan-6", "parmesan-7", "parmesan-8",
}

local tex_files = {
  "optimize_gabc_style.lua",  "gregoriotex-ictus.lua", "gregoriotex.lua", "gregoriotex-signs.tex", "gregoriotex.tex", "gsp-default.tex", "gregoriotex-spaces.tex", "gregoriotex-syllable.tex", "gregoriotex-symbols.tex", "optimize_gabc.lua",
  }

local latex_files = {
    "optimize-gabc.sty", "gregoriosyms.sty", "gregoriotex.sty",
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
  print("copying files...")
  local texmfbin = kpse.expand_var("$TEXMFDIST")
  texmfbin = texmfbin:gsub("/", "\\").."\\..\\bin\\win32\\"
  copy_one_file("gregorio.exe", texmfbin)
  for _,f in ipairs(fonts_files) do
    copy_one_file('fonts\\'..f..'.pfb', dirs.type1)
    copy_one_file('fonts\\'..f..'.tfm', dirs.tfm)
  end
  for _,f in ipairs(fonts) do
    copy_one_file('fonts\\'..f..'.map', dirs.map)
    if f == 'greextra' or f == "gresym" then
      copy_one_file('fonts\\'..f..'.pfb', dirs.type1)
      copy_one_file('fonts\\'..f..'.tfm', dirs.tfm)
    else
      copy_one_file('fonts\\'..f..'.ofm', dirs.ofm)
      copy_one_file('fonts\\'..f..'.ovp', dirs.ovp)
      copy_one_file('fonts\\'..f..'.ovf', dirs.ovf)
    end
  end
  for _,f in ipairs(tex_files) do
    copy_one_file('tex\\'..f, dirs.tex)
  end
  for _,f in ipairs(latex_files) do
    copy_one_file('tex\\'..f, dirs.latex)
  end
  copy_one_file('examples\\main-lualatex.tex', dirs.templatemain)
  copy_one_file('examples\\PopulusSion.gabc', dirs.templatescore)
end

local base_dirs = {
  texmflocal.."fonts",  texmflocal.."tex", texmflocal.."tex\\generic",  texmflocal.."tex\\latex", texmflocal.."fonts\\ofm",
  texmflocal.."fonts\\tfm", texmflocal.."fonts\\type1", texmflocal.."fonts\\ovp", texmflocal.."fonts\\ovf", texmflocal.."fonts\\map",
  templatemain, templatescore,
}

function create_dirs()
  -- just in case
  for _,d in ipairs(base_dirs) do
	lfs.mkdir(d)
  end
  for _, d in pairs(dirs) do
    lfs.mkdir(d)
  end
end

function run_texcommands()
  print("running mktexlsr")
  local p = os.spawn("mktexlsr "..texmflocal)
  print("prout")
  for _,font in pairs(fonts) do
    print(string.format("updmap-sys.exe --enable MixedMap=%s.map", font))
    os.spawn(string.format("updmap-sys.exe --enable MixedMap=%s.map", font))
	print(string.format("updmap.exe --enable MixedMap=%s.map", font))
	os.spawn(string.format("updmap.exe --enable MixedMap=%s.map", font))
  end
end

function main_install()
	create_dirs()
	copy_files()
	run_texcommands()
end

function texworks_conf()
	local filesdir = texworksdir
	print("Modifying tools.ini ...")
	texworks_conf_tools(filesdir.."configuration\\tools.ini")
	print("Modifying TeXWorks.ini ...")
	texworks_conf_ini(filesdir.."TUG\\TeXWorks.ini")
	print("Modifying texworks-config.txt ...")
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

function texworks_conf_tools(filename)
   	-- let's remove the read-only attribute
	remove_read_only(filename)
	local f = io.open(filename, 'r')
	local toolstable = {}
	local current = 0
	local lualatexfound = 0
	local gregoriofound = 0
	for l in f:lines() do
	    local num = tonumber(l:match("(%d+)\]"))
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

if arg[1] == nil or arg[1] ~= '--conf' then
	main_install()
else
	texworks_conf()
end