--GregorioTeX Lua file.
--Copyright (C) 2008-2013 Elie Roux <elie.roux@telecom-bretagne.eu>
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU General Public License as published by
--the Free Software Foundation, either version 3 of the License, or
--(at your option) any later version.
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU General Public License for more details.
--
--You should have received a copy of the GNU General Public License
--along with this program.  If not, see <http://www.gnu.org/licenses/>.

-- this file contains lua functions used by GregorioTeX when called with LuaTeX.

local hpack, traverse_id, has_attribute, count, remove, insert_after, copy = node.hpack, node.traverse_id, node.has_attribute, node.count, node.remove, node.insert_after, node.copy

gregoriotex = gregoriotex or {}
local gregoriotex = gregoriotex

local err, warn, info, log = luatexbase.provides_module({
    name          = "gregoriotex",
    version       = 2.3,
    date          = "2013/05/21",
    description   = "GregorioTeX module.",
    author        = "Elie Roux",
    copyright     = "Elie Roux",
    license       = "GPLv3",
})

local hlist = node.id('hlist')
local vlist = node.id('vlist')
local glyph = node.id('glyph')
local gregorioattr = luatexbase.attributes['gregorioattr']

local hyphen = tex.defaulthyphenchar or 45 
local potentialdashvalue=1
local nopotentialdashvalue=2
local ictus=4

-- node factory
local tmpnode = node.new(glyph, 0)
tmpnode.font = 0
tmpnode.char = hyphen
local function gethyphennode()
  return copy(tmpnode)
end

local function getdashnnode()
  local hyphnode = gethyphennode()
  local dashnode = hpack(hyphnode)
  dashnode.shift = 0
  return dashnode,hyphnode
end

-- in each function we check if we really are inside a score, 
-- which we can see with the gregorioattr being set or not
local function process (h, groupcode, glyphes)
    -- TODO: to be changed according to the font
    local lastseennode=nil
    local adddash=false
    local currentfont = 0
    local currentshift = 0
    -- we explore the lines
    for a in traverse_id(hlist, h) do
        if has_attribute(a.list, gregorioattr) then
            -- the next two lines are to remove the dumb lines
            if count(hlist, a.list) == 2 then
                remove(h, a)
            else
			          for b in traverse_id(hlist, a.list) do
		          		if has_attribute(b, gregorioattr, potentialdashvalue) then
			          		adddash=true
		          			lastseennode=b
		          			currentfont = 0
		          			-- we traverse the list, to detect the font to use,
		          			-- and also not to add an hyphen if there is already one
	          				for g in node.traverse_id(glyph, b.list) do
	          				    if currentfont == 0 then
	          				        currentfont = g.font
	          					end
	          					if g.char == hyphen or g.char == 45 then
	          					    adddash = false
	          					end
	          				end
		          			if currentshift == 0 then
		          				currentshift = b.shift
		          			end
		          		-- if we encounter a text that doesn't need a dash, we acknowledge it
		          		elseif has_attribute(b, gregorioattr, nopotentialdashvalue) then
		          			adddash=false
		          		end
		          	end
		          	if adddash==true then
		          		local dashnode, hyphnode = getdashnnode()
		          		dashnode.shift = currentshift
		          		hyphnode.font = currentfont
		          		insert_after(a.list, lastseennode, dashnode)
		          		addash=false
		          	end
		        end
            -- we reinitialize the shift value, because it may change according to the line
            currentshift=0
        end
    end
    return true
end 

local function atScoreBeggining ()
    luatexbase.add_to_callback('post_linebreak_filter', process, 'gregoriotex.callback')
    -- we call the optimize_gabc functions here
    if optimize_gabc_style then
        optimize_gabc_style.add_callback()
    end
end

local function atScoreEnd ()
    luatexbase.remove_from_callback('post_linebreak_filter', 'gregoriotex.callback')
    if optimize_gabc_style then
        optimize_gabc_style.remove_callback()
    end
end

-- a variable vith the value:
--- 1 if we can launch gregorio
--- 2 if we cannot
--- nil if we don't know (yet)
local shell_escape = nil

local function compile_gabc(gabc_file, tex_file)
    if not shell_escape then
        local test = io.popen("gregorio -V")
        if test then
            local output = test:read("*a")
            test:close()
            if not output or output == "" then
                shell_escape = 2
            else
                shell_escape = 1
            end
        else
            shell_escape = 2
        end
    end
    if shell_escape == 2 then
        err("unable to launch gregorio, shell-escape mode may not be activated. Try to compile with:\n    %s --shell-escape %s.tex\nSee the documentation of gregorio or your TeX distribution to automatize it.", tex.formatname, tex.jobname)
    else
        info("compiling the score %s...", gabc_file)
        os.execute(string.format("gregorio -o %s %s", tex_file, gabc_file))
    end
end

local function include_gabc_score(gabc_file)
    if not lfs.isfile(gabc_file) then
        err("the file %s does not exist.", gabc_file)
        return
    end
    local gabc_timestamp = lfs.attributes(gabc_file).modification
    local tex_file = gabc_file:gsub("%.gabc+$","-auto.tex")
    if lfs.isfile(tex_file) then
        local tex_timestamp = lfs.attributes(tex_file).modification
        if tex_timestamp < gabc_timestamp then
            gregoriotex.compile_gabc(gabc_file, tex_file)
        else
            log("using the file %s without recompiling, as %s hasn't changed since last compilation.", tex_file, gabc_file)
        end
    else
        compile_gabc(gabc_file, tex_file)
    end
    tex.print(string.format("\\input %s", tex_file))
end

gregoriotex.include_gabc_score = include_gabc_score
gregoriotex.compile_gabc = compile_gabc
gregoriotex.atScoreEnd = atScoreEnd
gregoriotex.atScoreBeggining = atScoreBeggining
