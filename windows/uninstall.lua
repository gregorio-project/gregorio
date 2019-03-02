#!/usr/bin/env texlua
--[[
Gregorio Windows automatic installation script.
Copyright (C) 2010-2019 Gregorio Project authors

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
it uninstalls GregorioTeX under Windows.
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
local texmfdist = fixpath(kpse.expand_var("$TEXMFDIST"))..pathsep

function remove_tex_files()
  if string.find(string.lower(texmfdist),"texlive") then
    remove_texmf_install()
    print("Running mktexlsr\n")
    local p = os.spawn("mktexlsr "..texmflocal)
  elseif string.find(string.lower(texmfdist), "miktex") then
    print("Unregistering Gregorio's texmf tree with MiKTeX...")
    local appdir = lfs.currentdir()
    local target = fixpath(appdir.."/texmf/")
    os.spawn("initexmf --unregister-root=\""..target)
    print("Running initexmf...")
    os.spawn("initexmf -u")
    os.spawn("initexmf --mkmaps")
  else
    print("I don't recognize your TeX distribution.")
    print("You may need to remove files from your texmf tree manually.")
  end
end

local texmf_install_dirs = {
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
function rm_one(filename)
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

function remove_texmf_install()
  print("Looking for GregorioTeX files...")
  local install_was_present = false
  for _, d in pairs(texmf_install_dirs) do
    print("Looking for "..d.."...")
    if lfs.isdir(d) then
      install_was_present = true
      print("Found "..d..", removing...")
      rmdirrecursive(d)
    end
  end
  if install_was_present then
    --[[Since we removed some fonts, we need to rebuild the font databases.
    Since this function is only used when extracting files from a TeX Live
    texmf tree, we don't need to go through the distribution check.
    ]]--
    os.spawn("luaotfload-tool -u")
  end
end

function main_install()
  remove_tex_files()
  print("Uninstall script complete.")
  print("Press return to continue...")
  answer=io.read()
end

main_install()

