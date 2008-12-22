--GregorioTeX Lua file.
--Copyright (C) 2008 Elie Roux <elie.roux@telecom-bretagne.eu>
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

local hlist = node.id('hlist')
local vlist = node.id('vlist')
local glyph = node.id('glyph')

-- the algorithm here is simple: we look at the number of hlists in a line. If it is two, it means that it is a dumb line, and we remove it...
function removedumblines(h, groupcode, glyphes)
    for line in node.traverse_id(hlist, h) do
        if node.count(hlist, line.list) == 2 then
            node.remove(h, line)
        end
    end
    return true
end

function addhyphen(h, groupcode, glyphes)
    local lastseennode=nil
    local attributeid=987
    local potentialdashvalue=1
    local nopotentialdashvalue=2
    local adddash=false
    local tempnode=node.new(glyph, 0)
    local dashnode
    tempnode.font=0
    tempnode.char=tex.defaulthyphenchar
    dashnode=node.hpack(tempnode)
    dashnode.shift=0
    --% we explore the lines
    for a in node.traverse_id(hlist, h) do
        for b in node.traverse_id(hlist, a.list) do
            --if node.has_attribute(b, attributeid, 2) then
            --    texio.write_nl('prout')
            --end
            if node.has_attribute(b, attributeid, potentialdashvalue) then
                adddash=true
                lastseennode=b
                --attr = b.attr.next
                -- texio.write_nl('ATTR number = ' .. attr.number .. ' value = ' .. attr.value)
                -- here we set up the font number of the hyphen
                if (tempnode.font == 0) then
                    for g in node.traverse_id(glyph, b.list) do
                        tempnode.font = g.font
                        break
                    end
                end
                if dashnode.shift==0 then
                    dashnode.shift = b.shift
                end
            -- if we encounter a text that doesn't need a dash, we acknowledge it
            elseif node.has_attribute(b, attributeid, nopotentialdashvalue) then
                adddash=false
                --attr = b.attr.next
                -- texio.write_nl('ATTR number = ' .. attr.number .. ' value = ' .. attr.value)
            end
        end
        if adddash==true then
            local temp= node.copy(dashnode)
            addash=false
        end
        -- we reinitialize the shift value, because it may change according to the line
        dashnode.shift=0
    end
    return true
end 

function gregorioCallback(h, groupcode, glyphes)
    removedumblines(h, groupcode, glyphes)
    addhyphen(h, groupcode, glyphes)
    return true
end

function atScoreBeggining()
    callback.register('post_linebreak_filter', gregorioCallback)
end
