--GregorioTeX Lua file.
--
--Copyright (C) 2008-2018 The Gregorio Project (see CONTRIBUTORS.md)
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

local internalversion = '5.1.1' -- GREGORIO_VERSION (comment used by VersionManager.py)

local err, warn, info, log = luatexbase.provides_module({
    name               = "gregoriotex",
    version            = '5.1.1', -- GREGORIO_VERSION
    greinternalversion = internalversion,
    date               = "2018/03/25", -- GREGORIO_DATE_LTX
    description        = "GregorioTeX module.",
    author             = "The Gregorio Project (see CONTRIBUTORS.md)",
    copyright          = "2008-2018 - The Gregorio Project",
    license            = "GPLv3+",
})

local real_gregorio_exe = nil

gregoriotex.module = { err = err, warn = warn, info = info, log = log }

local format = string.format

local hlist = node.id('hlist')
local vlist = node.id('vlist')
local glyph = node.id('glyph')
local glue = node.id('glue')
local whatsit = node.id('whatsit')

local hyphen = tex.defaulthyphenchar or 45

local dash_attr = luatexbase.attributes['gre@attr@dash']
local potentialdashvalue   = 1
local nopotentialdashvalue = 2

local center_attr = luatexbase.attributes['gre@attr@center']
local startcenter = 1
local endcenter   = 2

local glyph_id_attr = luatexbase.attributes['gre@attr@glyph@id']
local glyph_top_attr = luatexbase.attributes['gre@attr@glyph@top']
local glyph_bottom_attr = luatexbase.attributes['gre@attr@glyph@bottom']
local prev_line_id = nil

local syllable_id_attr = luatexbase.attributes['gre@attr@syllable@id']

local cur_score_id = nil
local score_inclusion = {}
local line_heights = nil
local new_line_heights = nil
local score_heights = nil
local new_score_heights = nil
local saved_positions = nil
local saved_lengths = nil
local new_saved_lengths = nil
local saved_newline_before_euouae = nil
local new_saved_newline_before_euouae = nil
local last_syllables = nil
local new_last_syllables = nil
local score_last_syllables = nil
local new_score_last_syllables = nil
local state_hashes = nil
local new_state_hashes = nil
local auxname = nil
local tmpname = nil
local test_snippet_filename = nil
local snippet_filename = nil
local snippet_logname = nil

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
local hashed_spaces = {}
local space_hash = ''

local per_line_dims = {}
local per_line_counts = {}
local saved_dims = {}
local saved_counts = {}

local catcode_at_letter = luatexbase.catcodetables['gre@atletter']

local user_defined_subtype = node.subtype('user_defined')
local create_marker = luatexbase.new_user_whatsit('marker', 'gregoriotex')
local marker_whatsit_id = luatexbase.get_user_whatsit_id('marker', 'gregoriotex')
local translation_mark = 1
local abovelinestext_mark = 2
log("marker whatsit id is %d", marker_whatsit_id)

local function get_prog_output(cmd, fmt)
  cmd = string.format(cmd, tmpname)
  local rc = os.execute(cmd)
  local content = nil
  if rc == 0 then
    local f = io.open(tmpname, 'r');
    if f then
      content = f:read(fmt)
      f:close()
    end
  end
  os.remove(tmpname)
  return content
end

local function gregorio_exe()
  if real_gregorio_exe == nil then
    local tmp_gabcfile = io.open(test_snippet_filename, 'w')
    tmp_gabcfile:write("name:test;\n%%\n(c4)(g)\n")
    tmp_gabcfile:close()

    local exe_version

    -- first look for one with the exact version
    real_gregorio_exe = 'gregorio-5_1_1' -- FILENAME_VERSION
    local cmd = string.format("%s -o %%s %s", real_gregorio_exe,
        test_snippet_filename)
    exe_version = get_prog_output(cmd, '*line')
    if not exe_version then
      -- look for suffix-less executable
      real_gregorio_exe = 'gregorio'
      cmd = string.format("%s -o %%s %s", real_gregorio_exe,
          test_snippet_filename)
      exe_version = get_prog_output(cmd, '*line')
    end
    if not exe_version or string.match(exe_version,"%d+%.%d+%.")
        ~= string.match(internalversion,"%d+%.%d+%.") then
      real_gregorio_exe = nil
      err("Unable to find gregorio executable.\n"..
          "shell-escape mode may not be activated. Try\n\n"..
          "%s --shell-escape %s.tex\n\n"..
          "See the documentation of Gregorio or your TeX\n"..
          "distribution to automatize it.",
          tex.formatname, tex.jobname)
    end

    os.remove(test_snippet_filename)
    log("will use %s", real_gregorio_exe)
  end

  return real_gregorio_exe
end

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

local function saved_computations_changed(tab1, tab2)
  local score_ids = {}
  local id,_
  for id,_ in pairs(tab1) do
    score_ids[id] = true
  end
  for id,_ in pairs(tab2) do
    score_ids[id] = true
  end
  for id,_ in pairs(score_ids) do
    local inner1 = tab1[id]
    local inner2 = tab2[id]
    if inner1 == nil or inner2 == nil then return true end
    local keys = {}
    local index
    for index,_ in pairs(inner1) do
      keys[index] = true
    end
    for index,_ in pairs(inner2) do
      keys[index] = true
    end
    for index,_ in pairs(keys) do
      if inner1[index] ~= inner2[index] then return true end
    end
  end
  return false
end

local function entries_changed(tab1, tab2)
  local k, v
  for k, v in pairs(tab1) do
    if tab2[k] ~= v then return true end
  end
  return false
end

local function is_greaux_write_needed()
  local id, tab
  if entries_changed(state_hashes, new_state_hashes) or
      entries_changed(new_state_hashes, state_hashes) then
    return true
  end
  for id, tab in pairs(new_line_heights) do
    if keys_changed(tab, line_heights[id]) then return true end
  end
  for id, tab in pairs(line_heights) do
    if keys_changed(tab, new_line_heights[id]) then return true end
  end
  for id, tab in pairs(new_last_syllables) do
    if keys_changed(tab, last_syllables[id]) then return true end
  end
  for id, tab in pairs(last_syllables) do
    if keys_changed(tab, new_last_syllables[id]) then return true end
  end
  if saved_computations_changed(saved_lengths, new_saved_lengths) then
    return true
  end
  if saved_computations_changed(saved_newline_before_euouae, new_saved_newline_before_euouae) then
    return true
  end
  return false
end

local function write_greaux()
  if is_greaux_write_needed() then
    -- only write this if heights change; since table ordering is not
    -- predictable, this ensures a steady state if the heights are unchanged.
    local aux = io.open(auxname, 'w')
    if aux then
      log("Writing %s", auxname)
      local id, tab, id2, line, value
      aux:write('return {\n ["line_heights"]={\n')
      for id, tab in pairs(new_line_heights) do
        aux:write(string.format('  ["%s"]={\n', id))
        for id2, line in pairs(tab) do
          if id2 == 'last' then
            aux:write(string.format('   ["%s"]=%d,\n', id2, line))
          else
            aux:write(string.format('   [%d]={%d,%d,%d,%d,%d},\n', id2, line[1],
                line[2], line[3], line[4], line[5]))
          end
        end
        aux:write('  },\n')
      end
      aux:write(' },\n ["last_syllables"]={\n')
      for id, tab in pairs(new_last_syllables) do
        aux:write(string.format('  ["%s"]={\n', id))
        for id2, value in pairs(tab) do
          if id2 == 'state' then
            aux:write(string.format('   state="%s",\n', value))
          else
            aux:write(string.format('   [%d]=%d,\n', id2, value))
          end
        end
        aux:write('  },\n')
      end
      aux:write(' },\n ["saved_lengths"]={\n')
      for id, tab in pairs(new_saved_lengths) do
        aux:write(string.format('  ["%s"]={\n', id))
        for id2, value in pairs(tab) do
          if value ~= nil then
            aux:write(string.format('   [%d]=%d,\n', id2, value))
          end
        end
        aux:write('  },\n')
      end
      aux:write(' },\n ["saved_newline_before_euouae"]={\n')
      for id, tab in pairs(new_saved_newline_before_euouae) do
        aux:write(string.format('  ["%s"]={\n', id))
        for id2, value in pairs(tab) do
          if value ~= nil then
            if value then
              aux:write(string.format('   [%d]=true,\n', id2))
            else
              aux:write(string.format('   [%d]=false,\n', id2))
            end
          end
        end
        aux:write('  },\n')
      end
      aux:write(' },\n ["state_hashes"]={\n')
      for id, value in pairs(new_state_hashes) do
        aux:write(string.format('  ["%s"]="%s",\n', id, value))
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
    tmpname = outputdir..'/'..tex.jobname..'.gtmp'
    test_snippet_filename = outputdir..'/'..tex.jobname..'.test.gsnippet'
    snippet_filename = outputdir..'/'..tex.jobname..'.gsnippet'
    snippet_logname = outputdir..'/'..tex.jobname..'.gsniplog'
  else
    auxname = tex.jobname..'.gaux'
    tmpname = tex.jobname..'.gtmp'
    test_snippet_filename = tex.jobname..'.test.gsnippet'
    snippet_filename = tex.jobname..'.gsnippet'
    snippet_logname = tex.jobname..'.gsniplog'
  end

  -- to get latexmk to realize the aux file is a dependency
  texio.write_nl('('..auxname..')')
  if lfs.isfile(auxname) then
    log("Reading %s", auxname)
    local score_info = dofile(auxname)
    line_heights = score_info.line_heights or {}
    last_syllables = score_info.last_syllables or {}
    state_hashes = score_info.state_hashes or {}
    saved_lengths = score_info.saved_lengths or {}
    saved_newline_before_euouae = score_info.saved_newline_before_euouae or {}
  else
    line_heights = {}
    last_syllables = {}
    state_hashes = {}
    saved_lengths = {}
    saved_newline_before_euouae = {}
  end

  if enable_height_computation then
    new_line_heights = {}
    new_last_syllables = {}
    new_state_hashes = {}

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
  saved_positions = {}
  new_saved_lengths = {}
  new_saved_newline_before_euouae = {}
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

-- helper function for center_translation()
local function get_first_node_by_id(id, head)
  for n in traverse_id(id, head) do
    return n
  end
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
  -- While normally we could use startnode.head.next.head.next.head
  -- to reach the translation (glyph node), packages such as LuaTeX-ja
  -- may have, for example, prepended a whatsit node to each list
  -- to store e.g. text direction, moving our translation glyph node to
  -- startnode.head.next.next.head.next.next.head.next instead.
  --
  -- To avoid unpleasant surprises, let's search for each desired node
  -- by its type:
  local vlistnode = get_first_node_by_id(vlist, startnode.head)
  local hlistnode = get_first_node_by_id(hlist, vlistnode.head)
  local glyphnode = get_first_node_by_id(glyph, hlistnode.head)
  -- hence translation width is:
  local trans_width = node.dimensions(glyphnode)
  -- now we must transform the kern 0pt into kern Xpt and kern -Xpt where X is:
  local X = (total_width - trans_width) / 2
  vlistnode.prev.kern = X
  vlistnode.next.kern = -X
end

local debug_types_activated = {['linesglues'] = false}

local function set_debug_string(debugstring)
  for debugtype in string.gmatch(debugstring, "[^,]+") do
    debug_types_activated[debugtype] = true
  end
end

local glue_sign_name = {[0] = 'normal', [1] = 'stretching', [2] = 'shrinking'}

local function debugmessage(type, ...)
  if (debug_types_activated[type] or debug_types_activated['all']) then
    texio.write_nl('GregorioTeX debug: ('..type..'): '..format(...))
  end
end

gregoriotex.module.debugmessage = debugmessage

-- in each function we check if we really are inside a score,
-- which we can see with the dash_attr being set or not
local function post_linebreak(h, groupcode, glyphes)
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
  local syl_id                  = nil
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
        debugmessage('linesglues', 'line %d: %s factor %d%%', linenum, glue_sign_name[line.glue_sign], line.glue_set*100)
        centerstartnode = nil
        line_id = nil
        line_top = nil
        line_bottom = nil
        line_has_translation = false
        line_has_abovelinestext = false
        for n in traverse_id(hlist, line.head) do
          syl_id = has_attribute(n, syllable_id_attr) or syl_id
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
          new_score_heights[prev_line_id] = { linenum, line_top, line_bottom,
              line_has_translation and 1 or 0,
              line_has_abovelinestext and 1 or 0 }
          new_score_heights['last'] = prev_line_id
          prev_line_id = line_id
        end
        if new_score_last_syllables and syl_id then
          new_score_last_syllables[syl_id] = syl_id
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

local function at_score_beginning(score_id, top_height, bottom_height,
    has_translation, has_above_lines_text, top_height_adj, bottom_height_adj,
    score_font_name)
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
  local text_font = unsafe_get_font_by_id(font.current())
  local score_font = unsafe_get_font_by_id(font.id('gre@font@music'))
  local state = md5.sumhexa(string.format('%s|%d|%s|%d|%s', text_font.name,
      text_font.size, score_font.name, score_font.size, space_hash))
  score_last_syllables = last_syllables[score_id]
  if score_last_syllables and state_hashes[score_id] ~= state then
    score_last_syllables = nil
  end
  if new_state_hashes then
    new_state_hashes[score_id] = state
  end
  if new_last_syllables then
    new_score_last_syllables = {}
    new_last_syllables[score_id] = new_score_last_syllables
  end

  luatexbase.add_to_callback('post_linebreak_filter', post_linebreak, 'gregoriotex.post_linebreak', 1)
  luatexbase.add_to_callback("hyphenate", disable_hyphenation, "gregoriotex.disable_hyphenation", 1)
end

local function at_score_end()
  luatexbase.remove_from_callback('post_linebreak_filter', 'gregoriotex.post_linebreak')
  luatexbase.remove_from_callback("hyphenate", "gregoriotex.disable_hyphenation")
  per_line_dims = {}
  per_line_counts = {}
  saved_dims = {}
  saved_counts = {}
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

local function compile_gabc(gabc_file, gtex_file, glog_file, allow_deprecated)
  info("compiling the score %s...", gabc_file)
  local extra_args = ''
  if tex.count['gre@generate@pointandclick'] == 1 then
    extra_args = extra_args..' -p'
  end
  if not allow_deprecated then
    extra_args = extra_args..' -D'
  end

  local cmd = string.format('%s %s -W -o %s -l %s "%s"', gregorio_exe(),
      extra_args, gtex_file, glog_file, gabc_file)
  res = os.execute(cmd)
  if res == nil then
    err("\nSomething went wrong when executing\n    '%s'.\n"
        .."shell-escape mode may not be activated. Try\n\n"
        .."%s --shell-escape %s.tex\n\n"
        .."See the documentation of Gregorio or your TeX\n"
        .."distribution to automatize it.",
        cmd, tex.formatname, tex.jobname)
  elseif res ~= 0 then
    local glog = io.open(glog_file, 'a+')
    if glog == nil then
      err("\n Unable to open %s", glog_file)
    else
      local size = glog:seek('end')
      if size > 0 then
        glog:seek('set')
        local line
        for line in glog:lines() do
          warn(line)
        end
      end
      glog:close()
    end
    err("\nAn error occured when compiling the score file\n"
        .."'%s' with %s.\nPlease check your score file.", gabc_file,
        gregorio_exe())
  else
    -- open the gtex file for writing so that LuaTeX records output to it
    -- when the -recorder option is used
    local gtex = io.open(gtex_file, 'a')
    if gtex == nil then
      err("\n Unable to open %s", gtex_file)
    else
      gtex:close()
    end
    local glog = io.open(glog_file, 'a+')
    if glog == nil then
      err("\n Unable to open %s", glog_file)
    else
      local size = glog:seek('end')
      if size > 0 then
        glog:seek('set')
        local line
        for line in glog:lines() do
          warn(line)
        end
        warn("*** end of warnings for %s ***", gabc_file)
      end
      glog:close()
    end
  end
end

local function include_score(input_file, force_gabccompile, allow_deprecated)
  if string.match(input_file, "[#%%]") then
    err("GABC filename contains invalid character(s): # %%\n"
        .."Rename the file and retry: %s", input_file)
  end
  local has_extention = false
  local file_dir,input_name
  local extensions = {['gabc']=true, ['gtex']=true, ['tex']=true}
  if extensions[string.match(input_file, "([^%.\\/]*)$")] then
    has_extention = true
  end
  if has_extention then
    file_dir,input_name = string.match(input_file, "(.-)([^\\/]-)%.?[^%.\\/]*$")
  else
    file_dir,input_name = string.match(input_file, "(.-)([^\\/]*)$")
  end

  local cleaned_filename = input_name:gsub("[%s%+%&%*%?$@:;!\"\'`]", "-")
  local gabc_file = string.format("%s%s.gabc", file_dir, input_name)
  local gtex_file = string.format("%s%s-%s.gtex", file_dir, cleaned_filename,
      internalversion:gsub("%.", "_"))
  local glog_file = string.format("%s%s-%s.glog", file_dir, cleaned_filename,
      internalversion:gsub("%.", "_"))
  if not lfs.isfile(gtex_file) then
    clean_old_gtex_files(file_dir..cleaned_filename)
    log("The file %s does not exist. Searching for a gabc file", gtex_file)
    if lfs.isfile(gabc_file) then
      local gabc = io.open(gabc_file, 'r')
      if gabc == nil then
        err("\n Unable to open %s", gabc_file)
        return
      else
        gabc:close()
      end
      compile_gabc(gabc_file, gtex_file, glog_file, allow_deprecated)
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
  tex.sprint(catcode_at_letter, string.format(
      [[\openin\gre@read@temp=%s\relax\closein\gre@read@temp]], gabc_file))
  local gabc = io.open(gabc_file, 'r')
  if gabc == nil then
    err("\n Unable to open %s", gabc_file)
  else
    gabc:close()
  end
  if gtex_timestamp < gabc_timestamp then
    log("%s has been modified and %s needs to be updated. Recompiling the gabc file.", gabc_file, gtex_file)
    compile_gabc(gabc_file, gtex_file, glog_file, allow_deprecated)
  elseif force_gabccompile then
    compile_gabc(gabc_file, gtex_file, glog_file, allow_deprecated)
  end
  tex.print(string.format([[\input %s\relax]], gtex_file))
  return
end

local function direct_gabc(gabc, header, allow_deprecated)
  info('Processing gabc snippet...')
  local deprecated
  if allow_deprecated then
    deprecated = ''
  else
    deprecated = '-D '
  end
  local f = io.open(snippet_filename, 'w')
  -- trims spaces on both ends (trim6 from http://lua-users.org/wiki/StringTrim)
  gabc = gabc:match('^()%s*$') and '' or gabc:match('^%s*(.*%S)')
  f:write('name:direct-gabc;\n'..(header or '')..'\n%%\n'..gabc:gsub('\\par ', '\n'))
  f:close()
  local cmd = string.format('%s -W %s-o %%s -l %s %s', gregorio_exe(),
      deprecated, snippet_logname, snippet_filename)
  local content = get_prog_output(cmd, '*a')
  if content == nil then
    err("\nSomething went wrong when executing\n    %s\n"
        .."shell-escape mode may not be activated. Try\n\n"
        .."%s --shell-escape %s.tex\n\n"
        .."See the documentation of Gregorio or your TeX\n"
        .."distribution to automatize it.", cmd, tex.formatname, tex.jobname)
  else
    tex.print(content:explode('\n'))
  end
  local glog = io.open(snippet_logname, 'a+')
  if glog == nil then
    err("\n Unable to open %s", snippet_logname)
  else
    local size = glog:seek('end')
    if size > 0 then
      glog:seek('set')
      local line
      for line in glog:lines() do
        warn(line)
      end
      warn("*** end of warnings/errors processing snippet ***")
    end
    glog:close()
  end
  os.remove(snippet_filename)
  os.remove(snippet_logname)
end

local function get_gregoriotexluaversion()
  return internalversion
end

local function check_one_font_version(name)
  local gregoriofont = get_font_by_name(name)
  if gregoriofont then
    local fontversion = gregoriofont.shared.rawdata.metadata.version
    if fontversion and string.match(fontversion, "%d+%.%d+%.%d+") ~= string.match(internalversion, "%d+%.%d+%.%d+") then
      local fontname = gregoriofont.shared.rawdata.metadata.fontname
      err("\nUncoherent file versions!\ngregoriotex.tex is version %s\nwhile %s.ttf is version %s\nplease reinstall one so that the\nversions match", string.match(internalversion, "%d+%.%d+%.%d+"), fontname, string.match(fontversion, "%d+%.%d+%.%d+"))
    end
  end
end

local function check_font_version()
  check_one_font_version('gre@font@music')
  check_one_font_version('gre@font@music@hollow')
  check_one_font_version('gre@font@music@hole')
end

local function map_font(name, prefix)
  log("Mapping font %s", name)
  local glyph, unicode
  for glyph, unicode in get_score_font_unicode_pairs(name) do
    if unicode >= 0 and not string.match(glyph, '%.') then
      debugmessage("mapfont", "Setting \\Gre%s%s to \\char%d", prefix, glyph, unicode)
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
        local _, name, factor
        _, _, name, factor = string.find(font_name, '^([^@]*)@(%d*)$')
        name = name or font_name
        factor = factor or '100000'
        local size = gre_factor * tonumber(factor)
        tex.print(catcode_at_letter, string.format(
            [[\global\font\%s = {name:%s} at %s sp\relax ]],
            font_csname, name, size))
        -- loaded_font_sizes will only be given a value if the font is for_score
        loaded_font_sizes[font_name] = {size = size, gre_factor = gre_factor}
        if font_factors[font_name] == nil then
          font_factors[font_name] = factor
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
  debugmessage('changeglyph', [[Setting \%s to \%s\char%d]], csname, font_csname, char)
  tex.print(catcode_at_letter, string.format(
      [[\edef\%s{{\noexpand\%s\char%d}}]], csname, font_csname, char))
end

local function set_common_score_glyph(csname, font_csname, char)
  -- font_csname is ignored
  debugmessage('changeglyph', [[Setting \%s to \char%d]], csname, char)
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

local function general_font_for(cavum)
  if cavum == 'Hollow' then
    return 'greciliae-hollow'
  elseif cavum == 'Hole' then
    return 'greciliae-hole'
  else
    return 'greciliae'
  end
end

local function change_single_score_glyph(glyph_name, cavum, font_name, replacement)
  if font_name == '*' then
    def_glyph('Gre'..cavum..'CP'..glyph_name, general_font_for(cavum),
        replacement, score_fonts, set_common_score_glyph)
  else
    def_glyph('Gre'..cavum..'CP'..glyph_name, font_name, replacement,
        score_fonts, set_score_glyph)
  end
end

local function change_score_glyph(glyph_name, font_name, replacement, cavum)
  cavum = cavum or ''
  if string.match(glyph_name, '%*') then
    glyph_name = '^'..glyph_name:gsub('%*', '.*')..'$'
    if replacement ~= '' and not string.match(replacement, '^%.') then
      err('If a wildcard is supplied for glyph name, replacement must be blank or start with a dot.')
    end
    local general_font = general_font_for(cavum)
    local other_font
    if font_name == '*' then
      other_font = get_score_font_resources(general_font).unicodes
    else
      other_font = get_score_font_resources(font_name).unicodes
    end
    local name, char
    for name, char in get_score_font_unicode_pairs(general_font) do
      if not string.match(name, '%.') and char >= 0 and string.match(name, glyph_name) then
        local matched_replacement = name..replacement
        if other_font[matched_replacement] ~= nil and other_font[matched_replacement] >= 0 then
          change_single_score_glyph(name, cavum, font_name, matched_replacement)
        end
      end
    end
  else
    if string.match(replacement, '^%.') then
      replacement = glyph_name..replacement
    end
    change_single_score_glyph(glyph_name, cavum, font_name, replacement)
  end
end

local function reset_score_glyph(glyph_name, cavum)
  cavum = cavum or ''
  local general_font = general_font_for(cavum)
  if string.match(glyph_name, '%*') then
    glyph_name = '^'..glyph_name:gsub('%*', '.*')..'$'
    local name, char
    for name, char in get_score_font_unicode_pairs(general_font) do
      if not string.match(name, '%.') and char >= 0 and string.match(name, glyph_name) then
        set_common_score_glyph('Gre'..cavum..'CP'..name, nil, char)
      end
    end
  else
    local char = get_score_font_resources(general_font).unicodes[glyph_name]
    if char == nil then
      err('\nGlyph %s was not found.', glyph_name)
    end
    set_common_score_glyph('Gre'..cavum..'CP'..glyph_name, nil, char)
  end
end

local function set_font_factor(font_name, font_factor)
  font_factors[font_name] = font_factor
end

local function scale_score_fonts(gre_factor)
  for font_name, font_csname in pairs(score_fonts) do
    if loaded_font_sizes[font_name] and font_factors[font_name] and loaded_font_sizes[font_name].size ~= gre_factor * font_factors[font_name] then
      local _, name
      _, _, name, _ = string.find(font_name, '^([^@]*)@(%d*)$')
      name = name or font_name
      local size = gre_factor * font_factors[font_name]
      log("%s : %s : rescaling %s to %s", font_name, font_csname, name, size)
      tex.print(catcode_at_letter, string.format(
          [[\global\font\%s = {name:%s} at %s sp\relax ]],
          font_csname, name, size))
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

local function adjust_line_height_internal(heights, inside_discretionary, for_next_line)
  local backup_dims = saved_dims
  local backup_counts = saved_counts
  -- restore saved dims
  local name, value
  for name, value in pairs(saved_dims) do
    tex.sprint(catcode_at_letter, string.format(
        [[\grechangedim{%s}{%s}{%s}]], name, value[1], value[2]))
  end
  for name, value in pairs(saved_counts) do
    tex.sprint(catcode_at_letter, string.format(
        [[\grechangecount{%s}{%s}]], name, value))
  end
  -- clear saved dims
  saved_dims = {}
  saved_counts = {}
  -- apply per-line dims
  local line_dims = per_line_dims[heights[1]]
  if line_dims ~= nil then
    for name, value in pairs(line_dims) do
      tex.sprint(catcode_at_letter, string.format(
          [[\gre@changedimforline{%s}{%s}{%s}]], name, value[1], value[2]))
    end
  end
  local line_counts = per_line_counts[heights[1]]
  if line_counts ~= nil then
    for name, value in pairs(line_counts) do
      tex.sprint(catcode_at_letter, string.format(
          [[\gre@changecountforline{%s}{%s}]], name, value))
    end
  end
  -- recalculate spaces
  tex.sprint(catcode_at_letter, string.format(
      [[\gre@calculate@additionalspaces{%d}{%d}{%d}{%d}]],
      heights[2], heights[3], heights[4], heights[5]))
  if inside_discretionary == 0 then
    tex.sprint(catcode_at_letter, [[\gre@updateleftbox ]])
  end
  if for_next_line then
    -- IS THIS GOOD ENOUGH???
    -- restore saved dims (from current line)
    local name, value
    for name, value in pairs(saved_dims) do
      tex.sprint(catcode_at_letter, string.format(
          [[\grechangedim{%s}{%s}{%s}]], name, value[1], value[2]))
    end
    for name, value in pairs(saved_counts) do
      tex.sprint(catcode_at_letter, string.format(
          [[\grechangecount{%s}{%s}]], name, value))
    end
    -- put previous saved dims back
    saved_dims = backup_dims
    saved_counts = backup_counts
  end
end

local function adjust_line_height(inside_discretionary, for_next_line)
  if score_heights then
    local heights = nil
    if for_next_line then
      local last = score_heights['last']
      if last then
        local target_id = tex.getattribute(glyph_id_attr) + 1
        while target_id <= last do
          heights = score_heights[target_id]
          if heights then break end
          target_id = target_id + 1
        end
      end
    else
      heights = score_heights[tex.getattribute(glyph_id_attr)]
    end
    if heights then
      adjust_line_height_internal(heights, inside_discretionary, for_next_line)
    end
  end
end

local function save_dim(name, value, modifier)
  saved_dims[name] = { value, modifier }
end

local function save_count(name, value)
  saved_counts[name] = value
end

local function change_next_score_line_dim(line_expr, name, value, modifier)
  local linenum_str
  for linenum_str in string.gmatch(line_expr, "%s*([^,]+)%s*") do
    local linenum = tonumber(linenum_str)
    local line_dims = per_line_dims[linenum]
    if line_dims == nil then
      line_dims = {}
      per_line_dims[linenum] = line_dims
    end
    line_dims[name] = { value, modifier }
  end
end

local function change_next_score_line_count(line_expr, name, value)
  local linenum_str
  for linenum_str in string.gmatch(line_expr, "([^,]+)") do
    local linenum = tonumber(linenum_str)
    local line_counts = per_line_counts[linenum]
    if line_counts == nil then
      line_counts = {}
      per_line_counts[linenum] = line_counts
    end
    line_counts[name] = value
  end
end

local function prep_save_position(index, fn)
  if saved_positions[cur_score_id] == nil then
    saved_positions[cur_score_id] = {}
  end
  saved_positions[cur_score_id][index] = { fn = fn }
end

local function save_position(index, which)
  tex.print(catcode_at_letter, string.format([[\luatexlatelua{gregoriotex.late_save_position('%s', %d, %d, \number\gre@lastxpos, \number\gre@lastypos)}]], cur_score_id, index, which))
end

local function late_save_position(score_id, index, which, xpos, ypos)
  info('saving %s, %d [%d] (%d,%d)', score_id, index, which, xpos, ypos)
  local pos = saved_positions[score_id][index]
  if pos == nil then
    err('Attempting to use unprepared position save slot %d', index)
    return
  end
  --[[
  if pos.fn == nil then
    err('Attempting to reuse position save slot %d', index)
    return
  end
  --]]
  pos['x'..which] = xpos
  pos['y'..which] = ypos
  if pos.x1 ~= nil and pos.y1 ~= nil and pos.x2 ~= nil and pos.y2 ~= nil then
    pos.fn(score_id, index, pos)
    --pos.fn = nil
  end
end

local function compute_saved_length(score_id, index, pos)
  if new_saved_lengths[score_id] == nil then
    new_saved_lengths[score_id] = {}
  end
  new_saved_lengths[score_id][index] = pos.x2 - pos.x1
  info('computed length for %s, %d: %d', score_id, index,
      new_saved_lengths[score_id][index])
end

local function save_length(index, which)
  if which == 1 then
    prep_save_position(index, compute_saved_length)
  end
  save_position(index, which)
end

local function compute_saved_newline_before_euouae(score_id, index, pos)
  if new_saved_newline_before_euouae[score_id] == nil then
    new_saved_newline_before_euouae[score_id] = {}
  end
  new_saved_newline_before_euouae[score_id][index] = pos.y2 ~= pos.y1
  info('computed euouae for %s, %d: %s', score_id, index,
      new_saved_newline_before_euouae[score_id][index])
end

local function save_euouae(index, which)
  if which == 1 then
    prep_save_position(index, compute_saved_newline_before_euouae)
  end
  tex.sprint(catcode_at_letter, [[\gre@savepos]])
  save_position(index, which)
end

local function var_brace_len(brace)
  if saved_lengths[cur_score_id] ~= nil then
    local length = saved_lengths[cur_score_id][brace]
    if saved_lengths[cur_score_id][brace] ~= nil then
      if length > 0 then
        tex.print(string.format('%dsp', length))
        return
      else
        warn('Dynamically sized signs spanning multiple lines unsupported, using length 2mm.')
      end
    end
  end
  tex.print('2mm')
end

-- this function is meant to be used from \ifcase; prints 0 for true and 1 for false
local function is_ypos_different(index)
  if saved_newline_before_euouae[cur_score_id] ~= nil then
    local newline_before_euouae =
        saved_newline_before_euouae[cur_score_id][index]
    if newline_before_euouae then
      tex.sprint([[\number0\relax ]])
      return
    end
  end
  tex.sprint([[\number1\relax ]])
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
  tex.setskip('gre@skip@temp@four',skip)
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

-- this function is meant to be used from \ifcase; prints 0 for true and 1 for false
local function is_last_syllable_on_line()
  if score_last_syllables then
    if score_last_syllables[tex.getattribute(syllable_id_attr)] then
      tex.print(0)
    else
      tex.print(1)
    end
  else
    -- if the last syllable is not computed, treat all syllables as the
    -- last on a line
    tex.print(0)
  end
end

local function hash_spaces(name, value)
  hashed_spaces[name] = value
  local k, _
  local keys = {}
  for k,_ in pairs(hashed_spaces) do
    table.insert(keys, k)
  end
  table.sort(keys)
  local mash = ''
  for _,k in ipairs(keys) do
    mash = string.format('%s%s:%s|', mash, k, hashed_spaces[k])
  end
  space_hash = md5.sumhexa(mash)
end

gregoriotex.number_to_letter             = number_to_letter
gregoriotex.init                         = init
gregoriotex.include_score                = include_score
gregoriotex.at_score_end                 = at_score_end
gregoriotex.at_score_beginning           = at_score_beginning
gregoriotex.check_font_version           = check_font_version
gregoriotex.get_gregoriotexluaversion    = get_gregoriotexluaversion
gregoriotex.map_font                     = map_font
gregoriotex.init_variant_font            = init_variant_font
gregoriotex.change_score_glyph           = change_score_glyph
gregoriotex.reset_score_glyph            = reset_score_glyph
gregoriotex.scale_score_fonts            = scale_score_fonts
gregoriotex.set_font_factor              = set_font_factor
gregoriotex.def_symbol                   = def_symbol
gregoriotex.font_size                    = font_size
gregoriotex.direct_gabc                  = direct_gabc
gregoriotex.adjust_line_height           = adjust_line_height
gregoriotex.var_brace_len                = var_brace_len
gregoriotex.save_length                  = save_length
gregoriotex.mark_translation             = mark_translation
gregoriotex.mark_abovelinestext          = mark_abovelinestext
gregoriotex.width_to_bp                  = width_to_bp
gregoriotex.hypotenuse                   = hypotenuse
gregoriotex.rotation                     = rotation
gregoriotex.scale_space                  = scale_space
gregoriotex.set_header_capture           = set_header_capture
gregoriotex.capture_header               = capture_header
gregoriotex.is_ypos_different            = is_ypos_different
gregoriotex.save_euouae                  = save_euouae
gregoriotex.mode_part                    = mode_part
gregoriotex.set_debug_string             = set_debug_string
gregoriotex.late_save_position           = late_save_position
gregoriotex.is_last_syllable_on_line     = is_last_syllable_on_line
gregoriotex.hash_spaces                  = hash_spaces
gregoriotex.save_dim                     = save_dim
gregoriotex.save_count                   = save_count
gregoriotex.change_next_score_line_dim   = change_next_score_line_dim
gregoriotex.change_next_score_line_count = change_next_score_line_count

dofile(kpse.find_file('gregoriotex-nabc.lua', 'lua'))
dofile(kpse.find_file('gregoriotex-signs.lua', 'lua'))
dofile(kpse.find_file('gregoriotex-symbols.lua', 'lua'))
