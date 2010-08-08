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
--]]

kpse.set_program_name("luatex")

local texmflocal = kpse.expand_var("$TEXMFLOCAL")
texmflocal = texmflocal:gsub("/", "\\")
texmflocal = texmflocal..'\\'

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
    --  collectgarbage("step") -- sometimes makes a big difference in mem consumption
        local data = f:read('*all')
    --  garbagecollector.check(data)
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
end

local base_dirs = {
  texmflocal.."fonts",  texmflocal.."tex", texmflocal.."tex\\generic",  texmflocal.."tex\\latex", texmflocal.."fonts\\ofm",
  texmflocal.."fonts\\tfm", texmflocal.."fonts\\type1", texmflocal.."fonts\\ovp", texmflocal.."fonts\\ovf", texmflocal.."fonts\\map",
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
  os.exec("mktexlsr "..texmflocal)
end

create_dirs()
copy_files()
run_texcommands()
