--GregorioTeX Syllable Lua support file.
--
--Copyright (C) 2015-2026 The Gregorio Project (see CONTRIBUTORS.md)
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

-- this file contains lua functions to support signs used by GregorioTeX.

-- GREGORIO_VERSION 6.1.0

local err = gregoriotex.module.err
local warn = gregoriotex.module.warn
local info = gregoriotex.module.info
local log = gregoriotex.module.log
local debugmessage = gregoriotex.module.debugmessage

local has_attribute = node.has_attribute
local kern = node.id('kern')
local temp = node.id('temp')
local disc = node.id('disc')

local syllable_id_attr = luatexbase.attributes['gre@attr@syllable@id']

local part_attr = luatexbase.attributes['gre@attr@part']
local part_lyrics = 4
local part_notes = 10

local skip_type_attr = luatexbase.attributes['gre@attr@skip@type']
local skip_type_syllablefinal = 1
local skip_type_barspacing1 = 2
local skip_type_clearsyllable = 5

local dash_attr = luatexbase.attributes['gre@attr@dash']
local dash_hasdash = 2
local dash_barsyllable = 4

-- Functions for manipulating glue, which we just store as a 3-tuple
-- {width, stretch, shrink} in sp.

local function glue_to_string(g)
  if g == nil then
    return 'nil'
  elseif type(g) == 'number' then
    return string.format('%.5fpt', g/2^16)
  else
    if type(g) == 'userdata' then -- glue or glue_spec node
      g = {g.width, g.stretch, g.shrink}
    end
    local s = string.format('%.5fpt', g[1]/2^16)
    if g[2] ~= 0 then s = s .. string.format(' plus %.5fpt', g[2]/2^16) end
    if g[3] ~= 0 then s = s .. string.format(' minus %.5fpt', g[3]/2^16) end
    return s
  end
end

local function string_to_glue(s)
  local stretch = 0
  local shrink = 0
  local i, j
  i, j = string.find(s, 'minus', 1, true)
  if i ~= nil then
    shrink = tex.sp(s:sub(j+1))
    s = s:sub(1, i-1)
  end
  i, j = string.find(s, 'plus', 1, true)
  if i ~= nil then
    stretch = tex.sp(s:sub(j+1))
    s = s:sub(1, i-1)
  end
  local width = tex.sp(s)
  return {width, stretch, shrink}
end

local function dimen_to_glue(dimen)
  return {dimen, 0, 0}
end

local function glue_max(a, b)
  -- If the natural widths are equal, return a.
  if type(a) == 'number' then a = dimen_to_glue(a) end
  if type(b) == 'number' then b = dimen_to_glue(b) end
  if a[1] > b[1] then return a else return b end
end

local function glue_add(a, b)
  if type(a) == 'number' then a = dimen_to_glue(a) end
  if type(b) == 'number' then b = dimen_to_glue(b) end
  return {a[1]+b[1], a[2]+b[2], a[3]+b[3]}
end

-- Table for storing information about syllables that is impossible or
-- inconvenient to recover from node attributes.
local saved_syllables = {}

local function save_syllable_texts(head)
  -- Save syllable texts before ligaturing and kerning happens. This
  -- is needed later during syllable rewriting.
  -- Because syllable_id_attr is set even for material not in the
  -- syllable text, it's better to use dash_attr to detect whether
  -- this box is really syllable text.
  if tex.getattribute(dash_attr) > 0 then
    local sid = tex.getattribute(syllable_id_attr)
    local cur = head
    while cur ~= nil and cur.id == temp do cur = cur.next end
    if saved_syllables[sid] == nil then saved_syllables[sid] = {} end
    saved_syllables[sid].text = node.copy_list(cur)
  end
end

local function save_min_distances()
  local sid = tex.getattribute(syllable_id_attr)
  if saved_syllables[sid] == nil then saved_syllables[sid] = {} end
  local g = tex.skip['gre@skip@minTextDistance']
  saved_syllables[sid].min_text_distance = {g.width, g.stretch, g.shrink}
  g = tex.skip['gre@skip@minNotesDistance']
  saved_syllables[sid].min_notes_distance = {g.width, g.stretch, g.shrink}
end

local function free_saved_syllables()
  for sid, syl in pairs(saved_syllables) do
    node.flush_list(syl.text)
    saved_syllables[sid] = nil
  end
end

local function concat_list(head, tail, newhead, newtail)
  if head == nil then
    return newhead, newtail
  elseif newhead == nil then
    return head, tail
  else
    tail.next = newhead
    newhead.prev = tail
    return head, newtail
  end
end

local function shaping(head)
  head = node.ligaturing(head)
  head = node.kerning(head)
  -- Under luaotfload, ligaturing and kerning are done inside the following
  if nodes ~= nil and nodes.simple_font_handler ~= nil then
    head = nodes.simple_font_handler(head)
  end
  return head
end

local function scan_syllables(head)
  -- Find nodes corresponding to various parts of syllables and store them in a
  -- data structure more convenient for downstream processing.
  local syllables = {}
  local prev_sid = 0
  local function visit(head)
    for n in node.traverse(head) do
      -- to do: The two syllables in a discretionary are numbered
      -- differently, meaning that in the output, the syllables are
      -- not necessarily numbered consecutively.
      if n.id == disc then
        visit(n.pre)
        visit(n.post)
        visit(n.replace)
      else
        local sid = has_attribute(n, syllable_id_attr)
        local part = has_attribute(n, part_attr)
        local skip_type = has_attribute(n, skip_type_attr)
        if sid ~= nil then
          while prev_sid < sid do
            prev_sid = prev_sid+1
            syllables[prev_sid] = {}
            if saved_syllables[prev_sid] == nil then saved_syllables[prev_sid] = {} end
          end
          if part == part_lyrics then
            if syllables[sid].text ~= nil then
              err(' syllable %d has more than one text node', sid)
            end
            syllables[sid].text = n
          elseif part == part_notes then
            if syllables[sid].first_note == nil then
              syllables[sid].first_note = n
            end
            syllables[sid].last_note = n
          elseif skip_type == skip_type_syllablefinal then
            syllables[sid].syllablefinalskip = n
          elseif skip_type == skip_type_barspacing1 then
            syllables[sid].barspacing1 = n
          elseif skip_type == skip_type_clearsyllable then
            syllables[sid].clearsyllable = n
          end
        end
      end
    end
  end
  visit(head)
  return syllables
end

local function syllable_spacing(syllables)

  for sid, cur in pairs(syllables) do
    -- If the next syllable is a bar syllable, then this syllable
    -- shouldn't have syllablefinalskip. But (due to a bug, #1724)
    -- if the next syllable is a clef change, it is a bar syllable
    -- and this syllable does have syllablefinalskip; we ignore it.
    debugmessage('syllablespacing', 'after syllable %d', sid)
    local next = syllables[sid+1]
    if cur.syllablefinalskip and next ~= nil and not next.barspacing1 then
      local text_distance = node.dimensions(cur.text.next, next.text)
      debugmessage('syllablespacing', '  text distance = %s', glue_to_string(new_text_distance))
      local min_text_distance = saved_syllables[sid].min_text_distance
      debugmessage('syllablespacing', '  min text distance = %s', glue_to_string(min_text_distance))
      local min_text_shift = glue_add(min_text_distance, -text_distance)
      debugmessage('syllablespacing', '  min text shift = %s', glue_to_string(min_text_shift))
      
      local notes_distance = node.dimensions(cur.last_note.next, next.first_note)
      local min_notes_distance = saved_syllables[sid].min_notes_distance
      debugmessage('syllablespacing', '  min notes distance = %s', glue_to_string(min_notes_distance))
      local min_notes_shift = glue_add(min_notes_distance, -notes_distance)
      debugmessage('syllablespacing', '  min notes shift = %s', glue_to_string(min_notes_shift))

      local syllablefinalskip = {cur.syllablefinalskip.width, cur.syllablefinalskip.stretch, cur.syllablefinalskip.shrink}
      -- Ensure that min text shift and min notes shift are satisfied.
      syllablefinalskip = glue_add(syllablefinalskip, glue_max(min_text_shift, min_notes_shift))
      -- If this syllable has a hyphen, add some additional stretch.
      -- Note: This happens even if there is no text (\gresetlyrics{invisible}).
      if cur.text and has_attribute(cur.text, dash_attr, dash_hasdash) then
        debugmessage('syllablespacing', '  adding stretch for hyphen')
        syllablefinalskip = glue_add(syllablefinalskip, string_to_glue(token.get_macro('gre@space@skip@intersyllablespacestretchhyphen')))
      end
      debugmessage('syllablespacing', '  syllable final skip = %s', glue_to_string(syllablefinalskip))
      node.setglue(cur.syllablefinalskip, table.unpack(syllablefinalskip))
    else
      debugmessage('syllablespacing', '  no syllable final skip, not adjusting')
    end
  end
end

local function syllable_clearing(syllables)
  for sid, cur in pairs(syllables) do
    local prev = syllables[sid-1]
    if cur.clearsyllable and prev then
      debugmessage('clear', 'syllable %d', sid)
      local kern = 0
      -- current text must begin at or after prev notes' end
      if prev.last_note and cur.text then
        local overlap = -node.dimensions(prev.last_note.next, cur.text)
        debugmessage('clear', ' text-note overlap %fpt', overlap/2^16)
        kern = math.max(kern, overlap)
      end
      -- current notes must begin at or after prev text's end
      if prev.text and cur.first_note then
        local overlap = -node.dimensions(prev.text.next, cur.first_note)
        debugmessage('clear', ' note-text overlap %fpt', overlap/2^16)
        kern = math.max(kern, overlap)
      end
      debugmessage('clear', ' kern %fpt', kern/2^16)
      cur.clearsyllable.kern = kern
    end
  end
end

local function syllable_rewriting(syllables)
  if not gregoriotex.get_if('gre@rewritesyllables') then return end

  local start = 1
  local num_syllables = #syllables
  while start <= num_syllables do
    -- Find longest run of syllables, starting from start, that have
    -- zero distance between their text boxes.
    if syllables[start].text == nil then
      debugmessage('syllablerewriting', 'syllable %d has no text node', start)
      start = start + 1
    else
      local stop = start
      while stop+1 <= num_syllables do
        -- There are several conditions that prevent syllable rewriting:
        -- if either text node is missing
        if syllables[stop+1].text == nil then break end
        -- don't rewrite across a line break
        if gregoriotex.is_last_syllable_id_on_line(stop) then break end
        -- don't rewrite across a hyphen
        if has_attribute(syllables[stop].text, dash_attr, dash_hasdash) then break end
        -- if either syllable is a \GreBarSyllable
        if has_attribute(syllables[stop].text, dash_attr, dash_barsyllable) or
          has_attribute(syllables[stop+1].text, dash_attr, dash_barsyllable) then break end
        -- don't rewrite across a nonzero space
        if node.dimensions(syllables[stop].text.next, syllables[stop+1].text) ~= 0 then break end
        stop = stop + 1
      end
      -- Concatenate syllable text boxes into one box.
      if start < stop then
        debugmessage('syllablerewriting', 'merge syllables %d-%d', start, stop)
        local head, tail
        for sid = start, stop do
          -- Extend new text
          local n = saved_syllables[sid].text
          saved_syllables[sid].text = nil
          head, tail = concat_list(head, tail, n, node.tail(n))
        end
        head = shaping(head)
        for sid = start, stop do
          -- Rewrite text, inserting kerns to preserve widths
          local del = syllables[sid].text.head
          syllables[sid].text.head = nil
          node.flush_list(del)
          local kern = node.new(kern, 'userkern')
          kern.kern = syllables[sid].text.width
          if sid == start then
            syllables[sid].text.head = head
            kern.kern = kern.kern - node.dimensions(head)
            concat_list(head, tail, kern)
          else
            syllables[sid].text.head = kern
          end
        end
      end
      start = stop + 1
    end
  end
end

gregoriotex.save_syllable_texts = save_syllable_texts
gregoriotex.save_min_distances = save_min_distances
gregoriotex.free_saved_syllables = free_saved_syllables
gregoriotex.scan_syllables = scan_syllables
gregoriotex.syllable_spacing = syllable_spacing
gregoriotex.syllable_clearing = syllable_clearing
gregoriotex.syllable_rewriting = syllable_rewriting
