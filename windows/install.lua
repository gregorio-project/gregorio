#!/usr/bin/env texlua
--[[
Gregorio Windows automatic installation script.
Copyright (C) 2010-2025 Gregorio Project authors

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

This texlua script is called in Windows automatic installer (see gregorio.iss),
it configures Gregorio under windows to work with TeX Live or MiKTeX.
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

if os.type == "windows" or os.type == "msdos" then
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
local texmfdist = kpse.expand_var("$TEXMFDIST")

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
  print(src.." -> "..destfile)
  io.savedata(destfile, io.loaddata(src))
end

function copy_files()
  if not lfs.isdir(texmflocal) then
    lfs.mkdir(texmflocal)
  end
  print("Copying files into texmf tree...")
  if string.find(string.lower(texmfdist), "texlive") then
    print("Distribution is TeX Live")
    print("GregorioTeX files...")
    os.spawn("xcopy texmf "..texmflocal.." /e /f /y")
  elseif string.find(string.lower(texmfdist), "miktex") then
    print("Distribution is MiKTeX")
    print("Registering Gregorio's texmf tree with MiKTeX...")
    appdir = lfs.currentdir()
    target = fixpath(appdir.."/texmf/")
    os.spawn("initexmf --register-root=\""..target)
  else
    print("I don't recognize your TeX distribution.")
    print("You may need to add files to your texmf tree manually.")
  end
end

function run_texcommands()
  if string.find(string.lower(texmfdist),"texlive") then
    print("Running mktexlsr...")
    os.spawn("mktexlsr "..texmflocal)
  elseif string.find(string.lower(texmfdist), "miktex") then
    print("Running initexmf...")
    os.spawn("initexmf --update-fndb=\""..target)
  else
    print("I don't recognize your TeX distribution.")
    print("You may need to rebuild your texmf indecies manually.")
  end
  os.spawn("luaotfload-tool -u")
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
  fixpath(texmflocal.."tex/luatex/gregoriotex"),
  fixpath(texmflocal.."tex/lualatex/gregoriotex"),
  fixpath(texmflocal.."fonts/truetype/public/gregoriotex"),
  fixpath(texmflocal.."fonts/source/gregoriotex"),
  fixpath(texmflocal.."doc/luatex/gregoriotex/examples"),
  fixpath(texmflocal.."doc/luatex/gregoriotex"),
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
  os.execute("rmdir "..dir)
end

-- gregorio used to be installed in other directories which have precedence
-- over the new ones
function remove_possible_old_install()
  print("Looking for old GregorioTeX files...")
  local old_install_was_present = false
  for _, d in pairs(old_base_dirs) do
    print("Looking for "..d.."...")
    if lfs.isdir(d) then
      if string.find(string.lower(d),"fonts") then
        --We're removing fonts so we'll need to update the fonts maps later
        old_install_was_present = true
      end
      print("Found "..d..", removing...")
      rmdirrecursive(d)
    end
  end
  if old_install_was_present then
    if string.find(string.lower(texmfdist),"texlive") or string.find(string.lower(texmfdist), "miktex") then
      os.spawn("luaotfload-tool -u")
    else
      print("I don't recognize your TeX distribution.")
      print("You may need to rebuild your font maps manually.")
    end
  end
  --[[ Prior to 4.1 we used to copy the executable into the TeX path to make it
  available. Therefore we need to remove it from said location to make sure we
  don't have any version conflicts when upgrading from 4.0 or earlier.
  ]]--
  if string.find(string.lower(texmfdist), "texlive") then
    local texmfbin = fixpath(texmfdist.."/../bin/win32/")
    --[[ In TL2016, gregorio 4.1 is included by default, so we need to preserve
    that executable.  To make things easier, we simply assume that 4.0
    or earlier has not been installed over TL2016 or later.
    ]]--
    if not string.find(string.lower(texmfdist), "2016") then
      print("Removing old executable in bin...")
      rm_one(texmfbin.."gregorio.exe")
    end
  elseif string.find(string.lower(texmfdist), "miktex") then
    --[[ MiKTeX uses slightly different paths for the location of it's bin
    directory for 32 and 64 bit versions.  Since we used to copy to both of
    these locations, we now need to remove from both locations.
    --]]
    local texmfbin_32 = fixpath(texmfdist.."/miktex/bin/")
    local texmfbin_64 = fixpath(texmfdist.."/miktex/bin/x64/")
    print("Removing executable from bins...")
    rm_one(texmfbin_32.."gregorio.exe")
    rm_one(texmfbin_64.."gregorio.exe")
  else
    print("I don't recognize your TeX distribution.")
    print("You may need to remove old executable files manually.")
  end
end

function main_install()
  remove_possible_old_install()
  print("\n")
  copy_files()
  print("\n")
  run_texcommands()
  print("\nPost-install script complete.")
  print("Press return to continue...")
  local answer=io.read()
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

main_install()
scribus_config()

