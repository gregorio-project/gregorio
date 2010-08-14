--[[
Gregorio gabc optimization style file.
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

module("optimize_gabc_style", package.seeall)

optimize_gabc_style.module = {
    name          = "optimize_gabc_style",
    version       = 1.0,
    date          = "2010/06/06",
    description   = "Gregorio gabc optimization style.",
    author        = "Elie Roux",
    copyright     = "Elie Roux",
    license       = "GPLv3"
}

if luatextra and luatextra.provides_module then
    luatextra.provides_module(optimize_gabc_style.module)
elseif luatexbase and luatexbase.provides_module then
    luatexbase.provides_module(optimize_gabc_style.module)
end

local hlist = node.id('hlist')
local vlist = node.id('vlist')
local glyph = node.id('glyph')
local gregorioattr
if tex.attributenumber and tex.attributenumber['gregorioattr'] then
  gregorioattr = tex.attributenumber['gregorioattr']
elseif luatexbase and luatexbase.attributes and luatexbase.attributes['gregorioattr'] then
  gregorioattr = luatexbase.attributes['gregorioattr']
else
  gregorioattr = 987 -- the number declared with gregorioattr
end

-- table containing the lines syllable number
local lines

local function count_syllables (h, groupcode, glyphes)
    local potentialdashvalue=1
    local nopotentialdashvalue=2
    local line = 0
    local syllable = 0
    local res = {}
    -- we explore the lines
    for a in node.traverse_id(hlist, h) do
        if node.has_attribute(a.list, gregorioattr) then
            line = line + 1
		    for b in node.traverse_id(hlist, a.list) do
		        local v = node.has_attribute(b, gregorioattr)
	    		if v == nopotentialdashvalue or v == potentialdashvalue then
	    		    syllable = syllable + 1
	    		end
	    	end
	    	if syllable ~= 0 then
	    	    res[line] = syllable
	    	end
	    end
    end
    if next(res) then
        lines = res
        io.savedata(".optimize_gabc.tmp", table.serialize(res, "return"))
    end
    return true
end 

-- these functions are automatically called by gregorio.
function add_callback()
    if callback.add then
      callback.add('post_linebreak_filter', count_syllables, 'count_syllables')
    elseif luatexbase then
      luatexbase.add_to_callback('post_linebreak_filter', count_syllables, 'count_syllables')
    else
      error("you need luatexbase to run this script")
    end
end

function remove_callback()
    if callback.remove then
      callback.remove('post_linebreak_filter', 'count_syllables')
    elseif luatexbase then
      luatexbase.remove_from_callback('post_linebreak_filter', 'count_syllables')
    else
      error("you need luatexbase to run this script")
    end
end

-- functions for position handling
-- we work in pt all the time

local res = {}
local pos = {}

function getpos(position)
    --texio.write_nl("position: "..position)
    table.insert(pos, position)
end

function forcedeol(position)
    --texio.write_nl("forced_eol position: "..position)
    table.insert(pos, -1)
end

function sethyphenwidth(width)
    width = tex.sp(width)
    --texio.write_nl("hyphenwidth: "..width)
    res.hyphenwidth = width
end

function setstaffwidth(width)
    width = tex.sp(width)
    --texio.write_nl("staffwidth: "..width)
    res.staffwidth = width
end

function setinitpos(position)
    --texio.write_nl("initpos: "..position)
    res.maxpos = position + res.staffwidth
    --texio.write_nl("maxpos: "..res.maxpos)
end

function settolerance(t)
    texio.write_nl("tolerance: "..t)
    res.tolerance = t
end

function write_file()
    --texio.write_nl("write_file")
    res.lines = lines
    res.endpos = pos
    --texio.write_nl(table.serialize(res))
    io.savedata(".optimize_gabc.tmp", table.serialize(res, "return"))
end
