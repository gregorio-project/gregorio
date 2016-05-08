--GregorioTeX Lua file.
--
--Copyright (C) 2008-2015 The Gregorio Project (see CONTRIBUTORS.md)
--
--This file is part of Gregorio.
--
--Gregorio is free software: you can redistribute it and/or modify
--it under the terms of the GNU General Public License as published by
--the Free Software Foundation, either version 3 of the License, or
--(at your option) any later version.
--
--Gregorio is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU General Public License for more details.
--
--You should have received a copy of the GNU General Public License
--along with Gregorio.  If not, see <http://www.gnu.org/licenses/>.

-- this file contains lua functions used by GregorioTeX when called with LuaTeX.

local hpack, traverse, traverse_id, has_attribute, count, remove, insert_after, copy = node.hpack, node.traverse, node.traverse_id, node.has_attribute, node.count, node.remove, node.insert_after, node.copy

gregoriotex = gregoriotex or {}
local gregoriotex = gregoriotex

local internalversion = '4.1.2' -- GREGORIO_VERSION (comment used by VersionManager.py)

local err, warn, info, log = luatexbase.provides_module({
    name               = "gregoriotex",
    version            = '4.1.2', -- GREGORIO_VERSION
    greinternalversion = internalversion,
    date               = "2016/05/08", -- GREGORIO_DATE_LTX
    description        = "GregorioTeX module.",
    author             = "The Gregorio Project (see CONTRIBUTORS.md)",
    copyright          = "2008-2015 - The Gregorio Project",
    license            = "GPLv3+",
})

gregoriotex.module = { err = err, warn = warn, info = info, log = log }

local format = string.format

local hlist = node.id('hlist')
local vlist = node.id('vlist')
local glyph = node.id('glyph')
local glue = node.id('glue')
local whatsit = node.id('whatsit')

local hyphen = tex.defaulthyphenchar or 45

local dash_attr         = luatexbase.attributes['gre@attr@dash']
local potentialdashvalue   = 1
local nopotentialdashvalue = 2

local center_attr = luatexbase.attributes['gre@attr@center']
local startcenter = 1
local endcenter   = 2

local glyph_id_attr = luatexbase.attributes['gre@attr@glyph@id']
local glyph_top_attr = luatexbase.attributes['gre@attr@glyph@top']
local glyph_bottom_attr = luatexbase.attributes['gre@attr@glyph@bottom']
local prev_line_id = nil

local cur_score_id = nil
local score_inclusion = {}
local line_heights = nil
local new_line_heights = nil
local score_heights = nil
local new_score_heights = nil
local var_brace_positions = nil
local new_var_brace_positions = nil
local pos_saves = nil
local new_pos_saves = nil
local auxname = nil

local space_below_staff = 5
local space_above_staff = 13

local score_fonts = {}
local symbol_fonts = {}
local loaded_font_sizes = {}
local font_factors = {}
local font_indexed = {}
local next_variant = 0
local variant_prefix = 'gre@font@variant@'
local number_to_letter = {
  ['0'] = 'A', ['1'] = 'B', ['2'] = 'C', ['3'] = 'D', ['4'] = 'E',
  ['5'] = 'F', ['6'] = 'G', ['7'] = 'H', ['8'] = 'I', ['9'] = 'J',
}

local capture_header_macro = {}

local catcode_at_letter = luatexbase.catcodetables['gre@atletter']

local user_defined_subtype = node.subtype('user_defined')
local create_marker = luatexbase.new_user_whatsit('marker', 'gregoriotex')
local marker_whatsit_id = luatexbase.get_user_whatsit_id('marker', 'gregoriotex')
local translation_mark = 1
local abovelinestext_mark = 2

log("marker whatsit id is %d", marker_whatsit_id)

local function mark(value)
  local marker = create_marker()
  marker.type = 100
  marker.value = value
  marker.attr = node.current_attr()
  node.write(marker)
end

local function mark_translation()
  mark(translation_mark)
end

local function mark_abovelinestext()
  mark(abovelinestext_mark)
end

local function is_mark(node, value)
  return node.id == whatsit and node.subtype == user_defined_subtype and
      node.user_id == marker_whatsit_id and node.value == value
end

local function keys_changed(tab1, tab2)
  if tab2 == nil then return true end
  local id,_
  for id,_ in pairs(tab1) do
    if tab2[id] == nil then return true end
  end
  for id,_ in pairs(tab2) do
    if tab1[id] == nil then return true end
  end
  return false
end

local function heights_changed()
  local id, tab
  for id, tab in pairs(new_line_heights) do
    if keys_changed(tab, line_heights[id]) then return true end
  end
  for id, tab in pairs(line_heights) do
    if keys_changed(tab, new_line_heights[id]) then return true end
  end
  for id, tab in pairs(new_var_brace_positions) do
    if keys_changed(tab, var_brace_positions[id]) then return true end
  end
  for id, tab in pairs(var_brace_positions) do
    if keys_changed(tab, new_var_brace_positions[id]) then return true end
  end
  for id, tab in pairs(new_pos_saves) do
    if keys_changed(tab, pos_saves[id]) then return true end
  end
  for id, tab in pairs(pos_saves) do
    if keys_changed(tab, new_pos_saves[id]) then return true end
  end
  return false
end

local function write_greaux()
  if heights_changed() then
    -- only write this if heights change; since table ordering is not
    -- predictable, this ensures a steady state if the heights are unchanged.
    local aux = io.open(auxname, 'w')
    if aux then
      log("Writing %s", auxname)
      aux:write('return {\n ["line_heights"]={\n')
      local id, tab, id2, line
      for id, tab in pairs(new_line_heights) do
        aux:write(string.format('  ["%s"]={\n', id))
        for id2, line in pairs(tab) do
          aux:write(string.format('   [%d]={%d,%d,%d,%d},\n', id2, line[1],
              line[2], line[3], line[4]))
        end
        aux:write('  },\n')
      end
      aux:write(' },\n ["var_brace_positions"]={\n')
      for id, tab in pairs(new_var_brace_positions) do
        aux:write(string.format('  ["%s"]={\n', id))
        for id2, line in pairs(tab) do
          if line[1] ~= nil and line[2] ~= nil then
            aux:write(string.format('   [%d]={%d,%d},\n', id2, line[1],
                line[2]))
          end
        end
        aux:write('  },\n')
      end
      aux:write(' },\n ["pos_saves"]={\n')
      for id, tab in pairs(new_pos_saves) do
        aux:write(string.format('  ["%s"]={\n', id))
        for id2, line in pairs(tab) do
          if line[1] ~= nil and line[2] ~= nil and line[3] ~= nil and
              line[4] ~= nil then
            aux:write(string.format('   [%d]={%d,%d,%d,%d},\n', id2, line[1],
                line[2], line[3], line[4]))
          end
        end
        aux:write('  },\n')
      end
      aux:write(' },\n}\n')
      aux:close()
    else
      err("\n Unable to open %s", auxname)
    end

    warn("Line heights or variable brace lengths may have changed. Rerun to fix.")
  end
end

local function init(arg, enable_height_computation)
  -- is there a better way to get the output directory?
  local outputdir = nil
  for k,v in pairs(arg) do
    if v:find('%-output%-directory') then
      if v:find('%-output%-directory=') then
        outputdir=string.explode(v, '=')[2]
      else
        outputdir=arg[tonumber(k)+1]
      end
    end
  end
  if outputdir and lfs.isdir(outputdir) then
    auxname = outputdir..'/'..tex.jobname..'.gaux'
  else
    auxname = tex.jobname..'.gaux'
  end

  -- to get latexmk to realize the aux file is a dependency
  texio.write_nl('('..auxname..')')
  if lfs.isfile(auxname) then
    log("Reading %s", auxname)
    local score_info = dofile(auxname)
    line_heights = score_info.line_heights or {}
    var_brace_positions = score_info.var_brace_positions or {}
    pos_saves = score_info.pos_saves or {}
  else
    line_heights = {}
    var_brace_positions = {}
    pos_saves = {}
  end

  if enable_height_computation then
    new_line_heights = {}

    local mcb_version = luatexbase.get_module_version and
        luatexbase.get_module_version('luatexbase-mcb') or 9999
    if mcb_version and mcb_version > 0.6 then
      luatexbase.add_to_callback('finish_pdffile', write_greaux,
          'gregoriotex.write_greaux')
    else
      -- The version of luatexbase in TeX Live 2014 does not support it, and
      -- luatexbase prevents a direct call to callback.register.  Because of
      -- this, we lose the LuaTeX statistics and "output written to" messages,
      -- but I know of no other workaround.

      luatexbase.add_to_callback('stop_run', write_greaux,
          'gregoriotex.write_greaux')
    end
  else
    warn('Height computation has been skipped.  Gregorio will use '..
        'previously computed values if available but will not recompute '..
        'line heights.  Remove or undefine \\greskipheightcomputation to '..
        'resume height computation.')
  end
  new_var_brace_positions = {}
  new_pos_saves = {}
end

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

-- a simple (for now) function to dump nodes for debugging
local function dump_nodes(head)
  local n, m
  for n in traverse(head) do
    if node.type(n.id) == 'penalty' then
      log("%s=%d {%d}", node.type(n.id), n.penalty, has_attribute(n, glyph_id_attr))
    elseif n.id == whatsit and n.subtype == user_defined_subtype and n.user_id == marker_whatsit_id then
      log("marker-whatsit %s", n.value)
    else
      log("node %s [%d] {%d}", node.type(n.id), n.subtype, has_attribute(n, glyph_id_attr))
    end
    if n.id == hlist then
      for m in traverse(n.head) do
        if node.type(m.id) == 'penalty' then
          log("..%s=%d {%d}", node.type(m.id), m.penalty, has_attribute(n, glyph_id_attr))
        elseif m.id == whatsit and m.subtype == user_defined_subtype and m.user_id == marker_whatsit_id then
          log("..marker-whatsit %s", m.value)
        else
          log("..node %s [%d] {%d}", node.type(m.id), m.subtype, has_attribute(n, glyph_id_attr))
        end
      end
    end
  end
  log('--end dump--')
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

local debug_types_activated = {['linesglues'] = false}

local function set_debug_string(debugstring)
  for debugtype in string.gmatch(debugstring, "[^,]+") do
    debug_types_activated[debugtype] = true
  end
end

local glue_sign_name = {[0] = 'normal', [1] = 'stretching', [2] = 'shrinking'}

local function debugmessage(type, message)
  if (debug_types_activated[type] or debug_types_activated['all']) then
    texio.write_nl('GregorioTeX debug: ('..type..'): '..message)
  end
end

-- in each function we check if we really are inside a score,
-- which we can see with the dash_attr being set or not
local function process (h, groupcode, glyphes)
  -- TODO: to be changed according to the font
  local lastseennode            = nil
  local adddash                 = false
  local currentfont             = 0
  local currentshift            = 0
  local centerstartnode         = nil
  local line_id                 = nil
  local line_top                = nil
  local line_bottom             = nil
  local line_has_translation    = false
  local line_has_abovelinestext = false
  local linenum                 = 0
  -- we explore the lines
  for line in traverse(h) do
    if line.id == glue then
      if line.next ~= nil and line.next.id == hlist
          and has_attribute(line.next, dash_attr)
          and count(hlist, line.next.head) <= 2 then
        --log("eating glue")
        h, line = remove(h, line)
      end
    elseif line.id == hlist and has_attribute(line, dash_attr) then
      -- the next two lines are to remove the dumb lines
      if count(hlist, line.head) <= 2 then
        --log("eating line")
        h, line = remove(h, line)
      else
        linenum = linenum + 1
        debugmessage('linesglues', format('line %d: %s factor %d%%', linenum, glue_sign_name[line.glue_sign], line.glue_set*100))
        centerstartnode = nil
        line_id = nil
        line_top = nil
        line_bottom = nil
        line_has_translation = false
        line_has_abovelinestext = false
        for n in traverse_id(hlist, line.head) do
          if has_attribute(n, center_attr, startcenter) then
            centerstartnode = n
          elseif has_attribute(n, center_attr, endcenter) then
            if not centerstartnode then
              warn("End of a translation centering area encountered on a\nline without translation centering beginning,\nskipping translation...")
            else
              center_translation(centerstartnode, n, line.glue_set, line.glue_sign, line.glue_order)
            end
          elseif has_attribute(n, dash_attr, potentialdashvalue) then
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
          elseif has_attribute(n, dash_attr, nopotentialdashvalue) then
            adddash=false
          end

          if new_score_heights then
            local glyph_id = has_attribute(n, glyph_id_attr)
            local glyph_top = has_attribute(n, glyph_top_attr) or 9 -- 'g'
            local glyph_bottom = has_attribute(n, glyph_bottom_attr) or 9 -- 'g'
            if glyph_id and glyph_id > prev_line_id then
              if not line_id or glyph_id > line_id then
                line_id = glyph_id
              end
              if not line_top or glyph_top > line_top then
                line_top = glyph_top
              end
              if not line_bottom or glyph_bottom < line_bottom then
                line_bottom = glyph_bottom
              end
            end
          end
        end
        -- look for marks
        if new_score_heights then
          for n in traverse_id(whatsit, line.head) do
            line_has_translation = line_has_translation or
                is_mark(n, translation_mark)
            line_has_abovelinestext = line_has_abovelinestext or
                is_mark(n, abovelinestext_mark)
          end
        end
        if adddash==true then
          local dashnode, hyphnode = getdashnnode()
          dashnode.shift = currentshift
          hyphnode.font = currentfont
          insert_after(line.head, lastseennode, dashnode)
          addash=false
        end
        if line_id then
          new_score_heights[prev_line_id] = { line_top, line_bottom,
              line_has_translation and 1 or 0,
              line_has_abovelinestext and 1 or 0 }
          prev_line_id = line_id
        end
      end
      -- we reinitialize the shift value, because it may change according to the line
      currentshift=0
    end
  end
  --dump_nodes(h)
  -- due to special cases, we don't return h here (see comments in bug #20974)
  return true
end

-- In gregoriotex, hyphenation is made by the process function, so TeX hyphenation
-- is just a waste of time. This function will be registered in the hyphenate
-- callback to skip this step and thus gain a little time.
local function disable_hyphenation()
  return false
end

local function atScoreBeginning (score_id, top_height, bottom_height,
    has_translation, has_above_lines_text, top_height_adj, bottom_height_adj)
  local inclusion = score_inclusion[score_id] or 1
  score_inclusion[score_id] = inclusion + 1
  score_id = score_id..'.'..inclusion
  cur_score_id = score_id
  if (top_height > top_height_adj or bottom_height < bottom_height_adj
      or has_translation ~= 0 or has_above_lines_text ~= 0)
      and tex.count['gre@variableheightexpansion'] == 1 then
    score_heights = line_heights[score_id] or {}
    if new_line_heights then
      new_score_heights = {}
      new_line_heights[score_id] = new_score_heights
    end
    prev_line_id = tex.getattribute(glyph_id_attr)
  else
    score_heights = nil
    new_score_heights = nil
  end

  luatexbase.add_to_callback('post_linebreak_filter', process, 'gregoriotex.callback', 1)
  luatexbase.add_to_callback("hyphenate", disable_hyphenation, "gregoriotex.disable_hyphenation", 1)
end

local function atScoreEnd ()
  luatexbase.remove_from_callback('post_linebreak_filter', 'gregoriotex.callback')
  luatexbase.remove_from_callback("hyphenate", "gregoriotex.disable_hyphenation")
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
    filename = "^"..file_withdir:match(".*/".."(.*)").."%-%d+_%d+_%d+[-%a%d]*%.gtex$"
    for a in lfs.dir(dirpath) do
      if a:match(filename) then
        os.remove(dirpath..sep..a)
      end
    end
  else
    filename = "^"..file_withdir.."%-%d+_%d+_%d+[-%a%d]*%.gtex$"
    for a in lfs.dir(lfs.currentdir()) do
      if a:match(filename) then os.remove(a) end
    end
  end
end

local function compile_gabc(gabc_file, gtex_file)
  info("compiling the score %s...", gabc_file)
  local extra_args = ''
  if tex.count['gre@generate@pointandclick'] == 1 then
    extra_args = ' -p'
  end

  res = os.execute(string.format("gregorio %s -o %s %s", extra_args, gtex_file, gabc_file))
  if res == nil then
    err("\nSomething went wrong when executing\n    'gregorio -o %s %s'.\n"
    .."shell-escape mode may not be activated. Try\n\n%s --shell-escape %s.tex\n\nSee the documentation of gregorio or your TeX\ndistribution to automatize it.", gtex_file, gabc_file, tex.formatname, tex.jobname)
  elseif res ~= 0 then
    err("\nAn error occured when compiling the score file\n'%s' with gregorio.\nPlease check your score file.", gabc_file)
  else
    -- open the gtex file for writing so that LuaTeX records output to it
    -- when the -recorder option is used
    local gtex = io.open(gtex_file, 'a')
    if gtex == nil then
      err("\n Unable to open %s", gtex_file)
    else
      gtex:close()
    end
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
  local gtex_file = file_root.."-"..internalversion:gsub("%.", "_")..".gtex"
  local gabc_file = file_root..".gabc"
  if not lfs.isfile(gtex_file) then
    clean_old_gtex_files(file_root)
    log("The file %s does not exist. Searching for a gabc file", gtex_file)
    if lfs.isfile(gabc_file) then
      local gabc = io.open(gabc_file, 'r')
      if gabc == nil then
        err("\n Unable to open %s", gabc_file)
        return
      else
        gabc:close()
      end
      compile_gabc(gabc_file, gtex_file)
      tex.print(string.format([[\input %s\relax]], gtex_file))
      return
    else
      err("The file %s does not exist.", gabc_file)
      return
    end
  end
  local gtex_timestamp = lfs.attributes(gtex_file).modification
  local gabc_timestamp = lfs.attributes(gabc_file).modification
  -- open the gabc file for reading so that LuaTeX records input from it
  -- when the -recorder option is used; do this here so that this happens
  -- on every run
  local gabc = io.open(gabc_file, 'r')
  if gabc == nil then
    err("\n Unable to open %s", gabc_file)
  else
    gabc:close()
  end
  if gtex_timestamp < gabc_timestamp then
    log("%s has been modified and %s needs to be updated. Recompiling the gabc file.", gabc_file, gtex_file)
    compile_gabc(gabc_file, gtex_file)
  elseif force_gabccompile then
    compile_gabc(gabc_file, gtex_file)
  end
  tex.print(string.format([[\input %s\relax]], gtex_file))
  return
end

local function direct_gabc(gabc, header)
  tmpname = os.tmpname()
  local f = io.open(tmpname, 'w')
  -- trims spaces on both ends (trim6 from http://lua-users.org/wiki/StringTrim)
  gabc = gabc:match('^()%s*$') and '' or gabc:match('^%s*(.*%S)')
  f:write('name:direct-gabc;\n'..(header or '')..'\n%%\n'..gabc:gsub('\\par ', '\n'))
  f:close()
  local p = io.popen('gregorio -S '..tmpname, 'r')
  if p == nil then
    err("\nSomething went wrong when executing\n    gregorio -S "..tmpname..".\n"
    .."shell-escape mode may not be activated. Try\n\n%s --shell-escape %s.tex\n\nSee the documentation of gregorio or your TeX\ndistribution to automatize it.", tex.formatname, tex.jobname)
  end
  tex.print(p:read("*a"):explode('\n'))
  p:close()
  os.remove(tmpname)
end

local function get_gregorioversion()
  return internalversion
end

local get_font_by_id = font.getfont --- cached, indexes fonts.hashes.identifiers
local font_id = font.id

-- an "unsafe" version of get_font_by_id that can see all fonts
-- LuaTeX can see, which is needed when we need the font size of
-- the user-selected current font
local function unsafe_get_font_by_id(id)
  return get_font_by_id(id) or font.fonts[id]
end

-- get_font_by_name(name) -- Look up a font identifier in the
-- ``score_fonts`` table. Returns the id of the font if found, -1
-- otherwise.
local function get_font_by_name(name)
  local id = font_id(name)
  return id >= 0 and get_font_by_id(id)
end

-- get_score_font_id(name) -- Look up a font identifier in the
-- ``score_fonts`` table. Returns the id of the font if found, -1
-- otherwise.
local function get_score_font_id(name)
  local sfnt = score_fonts[name]
  if sfnt then
    return font_id(sfnt)
  end
  return -1
end

local resource_dummy = { unicodes = { } }

-- get_font_resources(number) -- Retrieve the resource table
-- associated with a font id. Always returns a Lua table value whose
-- ``unicodes`` field is indexable.
local function get_font_resources(id)
  local fnt = get_font_by_id(id)
  if fnt then
    return fnt.resources or resource_dummy
  end
  return resource_dummy
end

-- get_score_font_resources(string) -- Retrieve the resource table
-- belonging to a font in the ``score_font`` table. Always returns
-- a table whose ``unicodes`` field is indexable.
local function get_score_font_resources(name)
  return get_font_resources(get_score_font_id(name))
end

local function get_score_font_unicode_pairs(name)
  local unicodes = get_score_font_resources(name).unicodes
  if not font_indexed[name] then
    -- The unicodes table may be lazy-loaded, so iterating it may not
    -- return everything.  Attempting to retrieve the code point of a
    -- glyph that has not already been loaded will trigger the __index
    -- method in the metatable (implemented by the fontloader) to load
    -- the table until the glyph is found.  When iterating the
    -- unicodes, we want the whole table to be filled, so we try to
    -- access a non-existing glyph in order to force load the entire
    -- table.
    local ignored = unicodes['_this_is_hopefully_a_nonexistent_glyph_']
    font_indexed[name] = true
  end
  return pairs(unicodes)
end

local function check_font_version()
  local gregoriofont = get_font_by_name('gre@font@music')
  if gregoriofont then
    local fontversion = gregoriofont.shared.rawdata.metadata.version
    if fontversion and string.match(fontversion, "%d+%.%d+%.%d+") ~= string.match(internalversion, "%d+%.%d+%.%d+") then
      local fontname = gregoriofont.shared.rawdata.metadata.fontname
      err("\nUncoherent file versions!\ngregoriotex.tex is version %s\nwhile %s.ttf is version %s\nplease reinstall one so that the\nversions match", string.match(internalversion, "%d+%.%d+%.%d+"), fontname, string.match(fontversion, "%d+%.%d+%.%d+"))
    end
  end
end

local function map_font(name, prefix)
  log("Mapping font %s", name)
  local glyph, unicode
  for glyph, unicode in get_score_font_unicode_pairs(name) do
    if unicode >= 0 and not string.match(glyph, '%.') then
      log("Setting \\Gre%s%s to \\char%d", prefix, glyph, unicode)
      tex.sprint(catcode_at_letter, string.format(
          [[\xdef\Gre%s%s{\char%d}]], prefix, glyph, unicode))
    end
  end
end

local function init_variant_font(font_name, for_score, gre_factor)
  if font_name ~= '*' then
    local font_table = for_score and score_fonts or symbol_fonts
    if font_table[font_name] == nil then
      local font_csname = variant_prefix..string.gsub(tostring(next_variant), '[0-9]', number_to_letter)
      font_table[font_name] = font_csname
      log("Registering variant font %s as %s.", font_name, font_csname)
      if for_score then
        tex.print(catcode_at_letter, string.format(
            [[\global\font\%s = {name:%s} at 10 sp\relax ]],
            font_csname, font_name))
        -- loaded_font_sizes will only be given a value if the font is for_score
        loaded_font_sizes[font_name] = {size = '10', gre_factor = gre_factor}
        if font_factors[font_name] == nil then
          font_factors[font_name] = '100000'
        end
      else
        -- is there a nice way to make this string readable?
        tex.print(catcode_at_letter, string.format(
            [[\gdef\%sSymReload#1{{\edef\localsize{#1}\ifx\localsize\%sSymSize\relax\relax\else\global\font\%s = {name:%s} at \localsize pt\relax\xdef\%sSymSize{\localsize}\fi}}\xdef\%sSymSize{0}\%sSymReload{\gre@symbolfontsize}]],
            font_csname, font_csname, font_csname, font_name, font_csname,
            font_csname, font_csname))
      end
      next_variant = next_variant + 1
    end
  end
end

local function set_score_glyph(csname, font_csname, char)
  log([[Setting \%s to \%s\char%d]], csname, font_csname, char)
  tex.print(catcode_at_letter, string.format(
      [[\edef\%s{{\noexpand\%s\char%d}}]], csname, font_csname, char))
end

local function set_common_score_glyph(csname, font_csname, char)
  -- font_csname is ignored
  log([[Setting \%s to \char%d]], csname, char)
  tex.print(catcode_at_letter, string.format(
      [[\edef\%s{{\char%d}}]], csname, char))
end

local function set_symbol_glyph(csname, font_csname, char)
  tex.print(catcode_at_letter, string.format(
      [[\def\%s{\%sSymReload{\gre@symbolfontsize}{\%s\char%d}\relax}]],
      csname, font_csname, font_csname, char))
end

local function set_sized_symbol_glyph(csname, font_csname, char)
  tex.print(catcode_at_letter, string.format(
      [[\gdef\%s#1{\%sSymReload{#1}{\%s\char%d}\relax}]],
      csname, font_csname, font_csname, char))
end

local function def_glyph(csname, font_name, glyph, font_table, setter)
  local font_csname = font_table[font_name]
  local char
  if string.match(glyph, '^%d+$') then
    char = tonumber(glyph)
  else
    local fid = font_id(font_csname)
    if fid < 0 then
      err('\nFont %s is not defined.', font_name)
    end
    char = get_font_resources(fid).unicodes[glyph]
    if char == nil then
      err('\nGlyph %s in font %s was not found.', glyph, font_name)
    end
  end
  setter(csname, font_csname, char)
end

local function change_single_score_glyph(glyph_name, font_name, replacement)
  if font_name == '*' then def_glyph('GreCP'..glyph_name, 'greciliae', replacement, score_fonts, set_common_score_glyph)
  else
    def_glyph('GreCP'..glyph_name, font_name, replacement, score_fonts,
        set_score_glyph)
  end
end

local function change_score_glyph(glyph_name, font_name, replacement)
  if string.match(glyph_name, '%*') then
    glyph_name = '^'..glyph_name:gsub('%*', '.*')..'$'
    if not string.match(replacement, '^%.') then
      err('If a wildcard is supplied for glyph name, replacement must start with a dot.')
    end
    local other_font
    if font_name == '*' then
      other_font = get_score_font_resources('greciliae').unicodes
    else
      other_font = get_score_font_resources(font_name).unicodes
    end
    local name, char
    for name, char in get_score_font_unicode_pairs('greciliae') do
      if not string.match(name, '%.') and char >= 0 and string.match(name, glyph_name) then
        local matched_replacement = name..replacement
        if other_font[matched_replacement] ~= nil and other_font[matched_replacement] >= 0 then
          change_single_score_glyph(name, font_name, matched_replacement)
        end
      end
    end
  else
    if string.match(replacement, '^%.') then
      replacement = glyph_name..replacement
    end
    change_single_score_glyph(glyph_name, font_name, replacement)
  end
end

local function reset_score_glyph(glyph_name)
  if string.match(glyph_name, '%*') then
    glyph_name = '^'..glyph_name:gsub('%*', '.*')..'$'
    local name, char
    for name, char in get_score_font_unicode_pairs('greciliae') do
      if not string.match(name, '%.') and char >= 0 and string.match(name, glyph_name) then
        set_common_score_glyph('GreCP'..name, nil, char)
      end
    end
  else
    local char = get_score_font_resources("greciliae").unicodes[glyph_name]
    if char == nil then
      err('\nGlyph %s was not found.', glyph_name)
    end
    set_common_score_glyph('GreCP'..glyph_name, nil, char)
  end
end

local function set_font_factor(font_name, font_factor)
  font_factors[font_name] = font_factor
end

local function scale_score_fonts(size, gre_factor)
  for font_name, font_csname in pairs(score_fonts) do
    if loaded_font_sizes[font_name] and font_factors[font_name] and loaded_font_sizes[font_name].size ~= gre_factor * font_factors[font_name] then
      tex.print(catcode_at_letter, string.format(
          [[\global\font\%s = {name:%s} at %s sp\relax ]],
          font_csname, font_name, gre_factor * font_factors[font_name]))
      loaded_font_sizes[font_name] = {size = size, gre_factor = gre_factor}
    end
  end
end

local function def_symbol(csname, font_name, glyph, sized)
  def_glyph(csname, font_name, glyph, symbol_fonts,
      sized and set_sized_symbol_glyph or set_symbol_glyph)
end

local function font_size()
  tex.print(string.format('%.2f', (unsafe_get_font_by_id(font.current()).size / 65536.0)))
end

local function adjust_line_height(inside_discretionary)
  if score_heights then
    local heights = score_heights[tex.getattribute(glyph_id_attr)]
    if heights then
      tex.sprint(catcode_at_letter, string.format(
          [[\gre@calculate@additionalspaces{%d}{%d}{%d}{%d}]],
          heights[1], heights[2], heights[3], heights[4]))
      if inside_discretionary == 0 then
        tex.sprint(catcode_at_letter, [[\gre@updateleftbox ]])
      end
    end
  end
end

local function var_brace_note_pos(brace, start_end)
  tex.print(catcode_at_letter, string.format([[\luatexlatelua{gregoriotex.late_brace_note_pos('%s', %d, %d, \number\gre@lastxpos)}]], cur_score_id, brace, start_end))
end

local function late_brace_note_pos(score_id, brace, start_end, pos)
  if new_var_brace_positions[score_id] == nil then
    new_var_brace_positions[score_id] = {}
  end
  if new_var_brace_positions[score_id][brace] == nil then
    new_var_brace_positions[score_id][brace] = {}
  end
  new_var_brace_positions[score_id][brace][start_end] = pos
end

local function var_brace_len(brace)
  if var_brace_positions[cur_score_id] ~= nil then
    if var_brace_positions[cur_score_id][brace] ~= nil then
      local posend = var_brace_positions[cur_score_id][brace][2]
      local posstart = var_brace_positions[cur_score_id][brace][1]
      if posend > posstart then
        tex.print(string.format('%dsp', posend - posstart))
      else
        warn('Dynamically sized braces spanning multiple lines unsupported, using length 2mm.')
        tex.print('2mm')
      end
      return
    end
  end
  tex.print('2mm')
end

local function save_pos(index, which)
  tex.print(catcode_at_letter, string.format([[\gre@savepos\luatexlatelua{gregoriotex.late_save_pos('%s', %d, %d, \number\gre@lastxpos, \number\gre@lastypos)}]], cur_score_id, index, which))
end

local function late_save_pos(score_id, index, which, xpos, ypos)
  if new_pos_saves[score_id] == nil then
    new_pos_saves[score_id] = {}
  end
  if new_pos_saves[score_id][index] == nil then
    new_pos_saves[score_id][index] = {}
  end
  new_pos_saves[score_id][index][(2 * which) - 1] = xpos
  new_pos_saves[score_id][index][2 * which] = ypos
end

-- this function is meant to be used from \ifcase; prints 0 for true and 1 for false
local function is_ypos_different(index)
  if pos_saves[cur_score_id] ~= nil then
    local saved_pos = pos_saves[cur_score_id][index]
    if saved_pos == nil or saved_pos[2] == saved_pos[4] then
      tex.sprint([[\number1\relax ]])
    else
      tex.sprint([[\number0\relax ]])
    end
  else
    tex.sprint([[\number1\relax ]])
  end
end

local function width_to_bp(width, value_if_star)
  if width == '*' then
    tex.print(value_if_star or '0')
  else
    tex.print(tex.sp(width) * 1.00375 / 65536)
  end
end

-- computes the hypotenuse given the width and height of the right triangle
local function hypotenuse(width, height)
  log("width %s height %s", width, height)
  local a = tex.sp(width)
  local b = tex.sp(height)
  tex.sprint(math.sqrt((a * a) + (b * b)) .. 'sp')
end

-- computes the rotation angle opposite the height of a right triangle
local function rotation(width, height)
  local a = tex.sp(width)
  local b = tex.sp(height)
  tex.sprint(math.deg(math.atan2(b, a)))
end

local function scale_space(factor)
  local skip = tex.getskip('gre@skip@temp@four')
  skip.width = skip.width * factor
  -- should skip.stretch and skip.shink also be scaled?
end

local function set_header_capture(header, macro_name, flags)
  if macro_name == '' then
    capture_header_macro[header] = nil
    log("no longer capturing header %s", header)
  else
    local macro = {}
    macro.name = macro_name
    flags:gsub("([^,]+)", function(flag)
      if flag == "string" then macro.takes_string = true
      elseif flag == "name" then macro.takes_header_name = true
      else err("unknown header capture flag: %s", flag)
      end
    end)
    capture_header_macro[header] = macro
    log("capturing header %s using %s, string=%s, name=%s", header, macro.name, macro.takes_string, macro.takes_header_name)
  end
end

local function capture_header(header, value)
  local macro = capture_header_macro[header]
  if macro ~= nil then
    tex.sprint(string.format([[\%s{]], macro.name))
    if macro.takes_header_name then
      tex.sprint(-2, header)
      tex.sprint('}{')
    end
    if macro.takes_string then
      tex.sprint(-2, value)
    else
      tex.sprint(value)
    end
    tex.print('}')
  end
end

local function mode_part(part)
  if part ~= '' then
    if not unicode.utf8.match(part, '^%p') then
      tex.sprint([[\thinspace]])
    end
    tex.print(part)
  end
end

gregoriotex.number_to_letter     = number_to_letter
gregoriotex.init                 = init
gregoriotex.include_score        = include_score
gregoriotex.atScoreEnd           = atScoreEnd
gregoriotex.atScoreBeginning     = atScoreBeginning
gregoriotex.check_font_version   = check_font_version
gregoriotex.get_gregorioversion  = get_gregorioversion
gregoriotex.map_font             = map_font
gregoriotex.init_variant_font    = init_variant_font
gregoriotex.change_score_glyph   = change_score_glyph
gregoriotex.reset_score_glyph    = reset_score_glyph
gregoriotex.scale_score_fonts    = scale_score_fonts
gregoriotex.set_font_factor      = set_font_factor
gregoriotex.def_symbol           = def_symbol
gregoriotex.font_size            = font_size
gregoriotex.direct_gabc          = direct_gabc
gregoriotex.adjust_line_height   = adjust_line_height
gregoriotex.var_brace_len        = var_brace_len
gregoriotex.var_brace_note_pos   = var_brace_note_pos
gregoriotex.late_brace_note_pos  = late_brace_note_pos
gregoriotex.mark_translation     = mark_translation
gregoriotex.mark_abovelinestext  = mark_abovelinestext
gregoriotex.width_to_bp          = width_to_bp
gregoriotex.hypotenuse           = hypotenuse
gregoriotex.rotation             = rotation
gregoriotex.scale_space          = scale_space
gregoriotex.set_header_capture   = set_header_capture
gregoriotex.capture_header       = capture_header
gregoriotex.save_pos             = save_pos
gregoriotex.late_save_pos        = late_save_pos
gregoriotex.is_ypos_different    = is_ypos_different
gregoriotex.mode_part            = mode_part
gregoriotex.set_debug_string     = set_debug_string

dofile(kpse.find_file('gregoriotex-nabc.lua', 'lua'))
dofile(kpse.find_file('gregoriotex-signs.lua', 'lua'))
dofile(kpse.find_file('gregoriotex-symbols.lua', 'lua'))
