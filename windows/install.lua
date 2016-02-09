#!/usr/bin/env texlua
--[[
Gregorio Windows automatic installation script.
Copyright (C) 2010-2015 Gregorio Project authors

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
it configures Gregorio under windows to work with TeXLive or MiKTeX.
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
    print("Distribution is TeXLive")
    local texmfbin = fixpath(texmfdist.."/../bin/win32/")
    print("Executable into bin...")
    copy_one_file("gregorio.exe", texmfbin)
    print("GregorioTeX files...")
    os.spawn("xcopy texmf "..texmflocal.." /e /f /y")
  elseif string.find(string.lower(texmfdist), "miktex") then
    print("Distribution is MiKTeX")
    --[[ MiKTeX uses slightly different paths for the location of it's bin
    directory for 32 and 64 bit versions.  Since the copy command will fail
    silently if the destination directory doesn't exist, the simplest way to deal
    with this is to simply try copying to both locations.
    --]]
    local texmfbin_32 = fixpath(texmfdist.."/miktex/bin/")
    local texmfbin_64 = fixpath(texmfdist.."/miktex/bin/x64/")
    print("Executable into bin...")
    copy_one_file("gregorio.exe", texmfbin_32)
    copy_one_file("gregorio.exe", texmfbin_64)
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
    print("Running mktexlsr\n")
    os.spawn("mktexlsr "..texmflocal)
  elseif string.find(string.lower(texmfdist), "miktex") then
    print("Running initexmf...")
    os.spawn("initexmf --update-fndb=\""..target)
  else
    print("I don't recognize your TeX distribution.")
    print("You may need to rebuild your texmf indecies manually.")
  end
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
  os.spawn("rmdir "..dir)
end

-- gregorio used to be installed in other directories which have precedence
-- over the new ones
function remove_possible_old_install()
  print("Looking for old GregorioTeX files...\n")
  local old_install_was_present = false
  for _, d in pairs(old_base_dirs) do
    print("Looking for "..d.."...")
    if lfs.isdir(d) then
      old_install_was_present = true
      print("Found "..d..", removing...")
      rmdirrecursive(d)
    end
  end
  if old_install_was_present then
    if string.find(string.lower(texmfdist),"texlive") then
      os.spawn("updmap-sys")
    elseif string.find(string.lower(texmfdist), "miktex") then
      os.spawn("initexmf --mkmaps")
    else
      print("I don't recognize your TeX distribution.")
      print("You may need to rebuild your font maps manually.")
    end
  end
end

function main_install()
  remove_possible_old_install()
  copy_files()
  run_texcommands()
  print("Post-install script complete.")
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

