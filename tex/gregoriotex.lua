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

local internalversion = 20150311

local err, warn, info, log = luatexbase.provides_module({
    name               = "gregoriotex",
    version            = 2.4,
    greinternalversion = internalversion,
    date               = "2013/12/29",
    description        = "GregorioTeX module.",
    author             = "Elie Roux",
    copyright          = "Elie Roux",
    license            = "GPLv3",
})

local hlist = node.id('hlist')
local vlist = node.id('vlist')
local glyph = node.id('glyph')

local hyphen = tex.defaulthyphenchar or 45 

local gregorioattr         = luatexbase.attributes['gregorioattr']
local potentialdashvalue   = 1
local nopotentialdashvalue = 2
local ictus                = 4

local gregoriocenterattr = luatexbase.attributes['gregoriocenterattr']
local startcenter = 1
local endcenter   = 2

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

local function center_translation(startnode, endnode, ratio, sign, order)
    -- total width between beginning the two centering points
    local total_width = node.dimensions(ratio, sign, order, startnode, endnode)
    -- definition of translation with a beginning is:
    --  \hbox to 0pt{
    --    \kern 0pt
    --    \vbox to 0pt{
    --      \vss\hbox to 0pt{
    --        translation\hss
    --      }
    --    }
    --    \kern 0pt
    --  }
    -- 
    -- hence translation width is:
    local trans_width = node.dimensions(startnode.head.next.head.next.head)
    -- now we must transform the kern 0pt into kern Xpt and kern -Xpt where X is:
    local X = (total_width - trans_width) / 2
    startnode.head.kern = X
    startnode.head.next.next.kern = -X
end

-- in each function we check if we really are inside a score, 
-- which we can see with the gregorioattr being set or not
local function process (h, groupcode, glyphes)
    -- TODO: to be changed according to the font
    local lastseennode    = nil
    local adddash         = false
    local currentfont     = 0
    local currentshift    = 0
    local centerstartnode = nil
    -- we explore the lines
    for line in traverse_id(hlist, h) do
        if has_attribute(line, gregorioattr) then
            -- the next two lines are to remove the dumb lines
            if count(hlist, line.head) <= 2 then
                h, line = remove(h, line)
            else
                centerstartnode = nil
                for n in traverse_id(hlist, line.head) do
                  if has_attribute(n, gregoriocenterattr, startcenter) then
                    centerstartnode = n
                  elseif has_attribute(n, gregoriocenterattr, endcenter) then
                    if not centerstartnode then
                      warn("End of a translation centering area encountered on a\nline without translation centering beginning,\nskipping translation...")
                    else
                      center_translation(centerstartnode, n, line.glue_set, line.glue_sign, line.glue_order)
                    end
                  elseif has_attribute(n, gregorioattr, potentialdashvalue) then
                    adddash=true
                    lastseennode=n
                    currentfont = 0
                    -- we traverse the list, to detect the font to use,
                    -- and also not to add an hyphen if there is already one
                    for g in node.traverse_id(glyph, n.head) do
                        if currentfont == 0 then
                            currentfont = g.font
                      end
                      if g.char == hyphen or g.char == 45 then
                          adddash = false
                      end
                    end
                    if currentshift == 0 then
                      currentshift = n.shift
                    end
                  -- if we encounter a text that doesn't need a dash, we acknowledge it
                  elseif has_attribute(n, gregorioattr, nopotentialdashvalue) then
                    adddash=false
                  end
                end
                if adddash==true then
                  local dashnode, hyphnode = getdashnnode()
                  dashnode.shift = currentshift
                  hyphnode.font = currentfont
                  insert_after(line.head, lastseennode, dashnode)
                  addash=false
                end
            end
            -- we reinitialize the shift value, because it may change according to the line
            currentshift=0
        end
    end
    -- due to special cases, we don't return h here (see comments in bug #20974)
    return true
end 

-- In gregoriotex, hyphenation is made by the process function, so TeX hyphenation
-- is just a waste of time. This function will be registered in the hyphenate
-- callback to skip this step and thus gain a little time.
local function disable_hyphenation()
    return false
end

local function atScoreBeggining ()
    luatexbase.add_to_callback('post_linebreak_filter', process, 'gregoriotex.callback', 1)
    luatexbase.add_to_callback("hyphenate", disable_hyphenation, "gregoriotex.disable_hyphenation", 1)
    -- we call the optimize_gabc functions here
    if optimize_gabc_style then
        optimize_gabc_style.add_callback()
    end
end

local function atScoreEnd ()
    luatexbase.remove_from_callback('post_linebreak_filter', 'gregoriotex.callback')
    luatexbase.remove_from_callback("hyphenate", "gregoriotex.disable_hyphenation")
    if optimize_gabc_style then
        optimize_gabc_style.remove_callback()
    end
end

local function clean_old_gtex_files(file_withdir)
    local filename = ""
    local dirpath = ""
    local sep = ""
    local onwindows = os.type == "windows" or
	string.find(os.getenv("PATH"),";",1,true)
    if onwindows then
	sep = "\\"
	dirpath = string.match(file_withdir, "(.*)"..sep)
    else
	sep = "/"
	dirpath = string.match(file_withdir, "(.*)"..sep)
    end
    if dirpath then -- dirpath is nil if current directory
	filename = "^"..file_withdir:match(".*/".."(.*)").."%-[0-9].*%.gtex$"
	for a in lfs.dir(dirpath) do
	    if a:match(filename) then
		os.remove(dirpath..sep..a)
	    end
	end
    else
	filename = "^"..file_withdir.."%-[0-9].*%.gtex$"
	for a in lfs.dir(lfs.currentdir()) do
	    if a:match(filename) then os.remove(a) end
	end
    end
end

local function compile_gabc(gabc_file, gtex_file)
    info("compiling the score %s...", gabc_file)
    res = os.execute(string.format("gregorio -o %s %s", gtex_file, gabc_file))
    if res == nil then
        err("\nSomething went wrong when executing\n    'gregorio -o %s %s'.\n"
        .."shell-escape mode may not be activated. Try\n    '%s --shell-escape %s.tex'\nSee the documentation of gregorio or your TeX\ndistribution to automatize it.", gtex_file, gabc_file, tex.formatname, tex.jobname)
    elseif res ~= 0 then
        err("\nAn error occured when compiling the score file\n'%s' with gregorio.\nPlease check your score file.", gabc_file)
    end
end

local function include_score(input_file, force_gabccompile)
    local file_root
    if string.match(input_file:sub(-5), '%.gtex') then
	file_root = input_file:sub(1,-6)
    elseif string.match(input_file:sub(-4), '%.tex') then
	file_root = input_file:sub(1,-5)
    elseif string.match(input_file:sub(-5), '%.gabc') then
	file_root = input_file:sub(1,-6)
    elseif not file_root then
	file_root = input_file
    end
    local gtex_file = file_root.."-"..internalversion..".gtex"
    local gabc_file = file_root..".gabc"
    if not lfs.isfile(gtex_file) then
	clean_old_gtex_files(file_root)
	log("The file %s does not exist. Searching for a gabc file", gtex_file)
	if lfs.isfile(gabc_file) then
	    compile_gabc(gabc_file, gtex_file)
	    tex.print(string.format("\\input %s", gtex_file))
	    return
	else
	    err("The file %s does not exist.", gabc_file)
	    return
	end
    end
    local gtex_timestamp = lfs.attributes(gtex_file).modification
    local gabc_timestamp = lfs.attributes(gabc_file).modification
    if gtex_timestamp < gabc_timestamp then
	log("%s has been modified and %s needs to be updated. Recompiling the gabc file.", gabc_file, gtex_file)
	compile_gabc(gabc_file, gtex_file)
    elseif force_gabccompile then
	compile_gabc(gabc_file, gtex_file)
    end
    tex.print(string.format("\\input %s", gtex_file))
    return
end

local function check_version(greinternalversion)
    if greinternalversion ~= internalversion then
        err("uncoherent file versions: gregoriotex.tex is version %i while gregoriotex.lua is version "..internalversion, greinternalversion)
    end
end

local function get_greapiversion()
    return internalversion
end

gregoriotex.include_score      = include_score
gregoriotex.compile_gabc       = compile_gabc
gregoriotex.atScoreEnd         = atScoreEnd
gregoriotex.atScoreBeggining   = atScoreBeggining
gregoriotex.check_version      = check_version
gregoriotex.get_greapiversion  = get_greapiversion
