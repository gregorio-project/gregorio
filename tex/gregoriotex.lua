--GregorioTeX Lua file.
--Copyright (C) 2008-2010 Elie Roux <elie.roux@telecom-bretagne.eu>
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

if gregoriotex and gregoriotex.version then
 -- we simply don't load
else

gregoriotex = {}

gregoriotex.module = {
    name          = "gregoriotex",
    version       = 2.1,
    date          = "2010/09/27",
    description   = "GregorioTeX module.",
    author        = "Elie Roux",
    copyright     = "Elie Roux",
    license       = "GPLv3",
}
if luatextra and luatextra.provides_module then
    luatextra.provides_module(gregoriotex.module)
    function gregoriotex.error(...)
        luatextra.module_error("GregorioTeX", string.format(...))
    end
    function gregoriotex.log(...)
        luatextra.module_log("GregorioTeX", string.format(...)) 
    end
    function gregoriotex.info(...)
        luatextra.module_info("GregorioTeX", string.format(...)) 
    end
elseif luatexbase and luatexbase.provides_module then
    luatexbase.provides_module(gregoriotex.module)
    function gregoriotex.error(...)
        luatexbase.module_error("GregorioTeX", string.format(...))
    end
    function gregoriotex.log(...)
        luatexbase.module_log("GregorioTeX", string.format(...)) 
    end
    function gregoriotex.info(...)
        luatexbase.module_info("GregorioTeX", string.format(...)) 
    end
else
    function gregoriotex.error(...)
        tex.sprint(string.format("\\immediate\\write16{}\\errmessage{GregorioTeX error: %s^^J^^J}\n", string.format(...)))
    end
    function gregoriotex.log(...)
        texio.write_nl('log', string.format("GregorioTeX: %s", string.format(...)))
    end
    function gregoriotex.info(...)
        texio.write_nl("GregorioTeX: "..string.format(...)) 
    end
end

gregoriotex.version  = 2.1
gregoriotex.showlog  = false

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

-- in each function we check if we really are inside a score, which we can see with the gregorioattr being set or not

function gregoriotex.addhyphenandremovedumblines (h, groupcode, glyphes)
    -- TODO: to be changed according to the font
    local hyphen = tex.defaulthyphenchar or 45 
    local lastseennode=nil
    local potentialdashvalue=1
    local nopotentialdashvalue=2
    local ictus=4
    local adddash=false
    local tempnode=node.new(glyph, 0)
    local dashnode
    tempnode.font=0
    tempnode.char = hyphen
    dashnode=node.hpack(tempnode)
    dashnode.shift=0
    -- we explore the lines
    for a in node.traverse_id(hlist, h) do
        if node.has_attribute(a.list, gregorioattr) then
            -- the next two lines are to remove the dumb lines
            if node.count(hlist, a.list) == 2 then
                node.remove(h, a)
            else
			    for b in node.traverse_id(hlist, a.list) do
		    		if node.has_attribute(b, gregorioattr, potentialdashvalue) then
			    		adddash=true
		    			lastseennode=b
		    			local font = 0
		    			-- we traverse the list, to detect the font to use,
		    			-- and also not to add an hyphen if there is already one
	    				for g in node.traverse_id(glyph, b.list) do
	    				    if font == 0 then
	    				        font = g.font
	    					end
	    					if g.char == hyphen or g.char == 45 then
	    					    adddash = false
	    					end
	    				end
	    				tempnode.font = font
		    			if dashnode.shift==0 then
		    				dashnode.shift = b.shift
		    			end
		    		-- if we encounter a text that doesn't need a dash, we acknowledge it
		    		elseif node.has_attribute(b, gregorioattr, nopotentialdashvalue) then
		    			adddash=false
		    		end
		    	end
		    	if adddash==true then
		    		local temp= node.copy(dashnode)
		    		node.insert_after(a.list, lastseennode, temp)
		    		addash=false
		    	end
		    end
            -- we reinitialize the shift value, because it may change according to the line
            dashnode.shift=0
        end
    end
    return true
end 

function gregoriotex.callback (h, groupcode, glyphes)
    gregoriotex.addhyphenandremovedumblines(h, groupcode, glyphes)
    return true
end

-- one day (when TeXLive 2007 will be really far away), proper callbacks should be created with luatexbase.

function gregoriotex.atScoreBeggining ()
    if callback.add then
      callback.add('post_linebreak_filter', gregoriotex.callback, 'gregoriotex.callback')
    elseif luatexbase then
      luatexbase.add_to_callback('post_linebreak_filter', gregoriotex.callback, 'gregoriotex.callback')
    else
      callback.register('post_linebreak_filter', gregoriotex.callback)
    end
    -- we call the optimize_gabc functions here
    if optimize_gabc_style then
        optimize_gabc_style.add_callback()
    end
end

function gregoriotex.atScoreEnd ()
    if callback.remove then
      callback.remove('post_linebreak_filter', 'gregoriotex.callback')
    elseif luatexbase then
      luatexbase.remove_from_callback('post_linebreak_filter', 'gregoriotex.callback')
    else
      callback.register('post_linebreak_filter', nil)
    end
    if optimize_gabc_style then
        optimize_gabc_style.remove_callback()
    end
end

-- a variable vith the value:
--- 1 if we can launch gregorio
--- 2 if we cannot
--- nil if we don't know (yet)
gregoriotex.shell_escape = nil

function gregoriotex.compile_gabc(gabc_file, tex_file)
    if not gregoriotex.shell_escape then
        local test = io.popen("gregorio -V")
        if test then
            local output = test:read("*a")
            test:close()
            if not output or output == "" then
                gregoriotex.shell_escape = 2
            else
                gregoriotex.shell_escape = 1
            end
        else
            gregoriotex.shell_escape = 2
        end
    end
    if gregoriotex.shell_escape == 2 then
        gregoriotex.error("unable to launch gregorio, shell-escape mode may not be activated. Try to compile with:\n    %s --shell-escape %s.tex\nSee the documentation of gregorio or your TeX distribution to automatize it.", tex.formatname, tex.jobname)
    else
        gregoriotex.info("compiling the score %s...", gabc_file)
        os.execute(string.format("gregorio -o %s %s", tex_file, gabc_file))
    end
end

function gregoriotex.include_gabc_score(gabc_file)
    if not lfs.isfile(gabc_file) then
        gregoriotex.error("the file %s does not exist.", gabc_file)
        return
    end
    local gabc_timestamp = lfs.attributes(gabc_file).modification
    local tex_file = gabc_file:gsub("%.gabc+$","-auto.tex")
    if lfs.isfile(tex_file) then
        local tex_timestamp = lfs.attributes(tex_file).modification
        if tex_timestamp < gabc_timestamp then
            gregoriotex.compile_gabc(gabc_file, tex_file)
        else
            gregoriotex.log("using the file %s without recompiling, as %s hasn't changed since last compilation.", tex_file, gabc_file)
        end
    else
        gregoriotex.compile_gabc(gabc_file, tex_file)
    end
    tex.print(string.format("\\input %s", tex_file))
end

end
