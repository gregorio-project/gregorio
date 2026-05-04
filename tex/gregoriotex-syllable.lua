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

-- This file contains Lua functions to support spacing of syllables.

-- GREGORIO_VERSION 6.2.0

local err = gregoriotex.module.err
local warn = gregoriotex.module.warn
local info = gregoriotex.module.info
local log = gregoriotex.module.log
local debugmessage = gregoriotex.module.debugmessage

local has_attribute = node.has_attribute
local kern = node.id('kern')
local temp = node.id('temp')
local disc = node.id('disc')
local glyph = node.id('glyph')

local syllable_id_attr = luatexbase.attributes['gre@attr@syllable@id']

local part_attr = luatexbase.attributes['gre@attr@part']
local part_lyrics = 4
local part_notes = 10

local skip_type_attr = luatexbase.attributes['gre@attr@skip@type']
local skip_type_syllablefinal = 1
local skip_type_before_text = 2
local skip_type_text_notes = 3
local skip_type_after_notes = 4
local skip_type_clearsyllable = 5

local dash_attr = luatexbase.attributes['gre@attr@dash']
local dash_maybedash = 1
local dash_hasdash = 2
local dash_forced = 5

-- Functions for manipulating glue, which we just store as a 3-tuple
-- {width, stretch, shrink} in sp.

--- Convert glue to a string.
--- @param g table The glue to be converted
--- @return string Human-readable string representation of g.
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

--- Convert a string to glue.
--- @param s string The string to be converted, e.g., "1pt plus 2pt minus 3pt"
--- @return table The glue represented by s.
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

--- Convert a dimen to glue.
--- @param dimen number A dimension, in sp.
--- @return table The glue equivalent to dimen, with no stretch or shrink.
local function dimen_to_glue(dimen)
  return {dimen, 0, 0}
end

--- Find the maximum of two glues.
--- @param a table A glue.
--- @param b table Another glue.
--- @return table The greater of a and b. If the natural widths are equal, return a.
local function glue_max(a, b)
  if type(a) == 'number' then a = dimen_to_glue(a) end
  if type(b) == 'number' then b = dimen_to_glue(b) end
  if a[1] > b[1] then return a else return b end
end

--- Find the sum of two glues.
--- @param a table A glue.
--- @param b table Another glue.
--- @return table The sum of a and b.
local function glue_add(a, b)
  if type(a) == 'number' then a = dimen_to_glue(a) end
  if type(b) == 'number' then b = dimen_to_glue(b) end
  return {a[1]+b[1], a[2]+b[2], a[3]+b[3]}
end

-- Miscellaneous helper functions

--- Concatenate two node lists.
--- @param head node The head of the first list.
--- @param tail node The tail of the first list.
--- @param newhead node The head of the second list.
--- @param newtail node The tail of the second list.
--- @return node The head of the concatenated list.
--- @return node The tail of the concatenated list.
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

--- Apply ligaturing and kerning to a node list.
--- @param head node The head of the list to be processed.
--- @return node The head of the processed list.
local function shaping(head)
  head = node.ligaturing(head)
  head = node.kerning(head)
  -- Under luaotfload, ligaturing and kerning are done inside the following
  if nodes ~= nil and nodes.simple_font_handler ~= nil then
    head = nodes.simple_font_handler(head)
  end
  return head
end

-- Table for storing information about syllables that is impossible or
-- inconvenient to recover from node attributes.
local syllables = {}
gregoriotex.syllables = syllables

--- Save information about syllables that is impossible or
--- inconvenient to recover from node attributes.
local function save_syllable_info(type)
  local sid = tex.getattribute(syllable_id_attr)
  if syllables[sid] == nil then syllables[sid] = {} end
  syllables[sid].sid = sid
  syllables[sid].type = type
  syllables[sid].font = font.current()
end

--- Save syllable text before ligaturing and kerning happens. This
--- is needed later during syllable rewriting.
--- @param head node The syllable text.
local function save_syllable_texts(head)
  -- Because syllable_id_attr is set even for material not in the
  -- syllable text, it's better to use dash_attr to detect whether
  -- this box is really syllable text.
  if tex.getattribute(dash_attr) > 0 then
    local sid = tex.getattribute(syllable_id_attr)
    local cur = head
    while cur ~= nil and cur.id == temp do cur = cur.next end
    if syllables[sid] == nil then syllables[sid] = {} end
    syllables[sid].raw_text = node.copy_list(cur)
  end
end

--- Save the minimum distance between text/notes of a \GreSyllable and
--- the following syllable, or before and after the text/notes of a
--- \GreBarSyllable.
local function save_min_distances()
  local sid = tex.getattribute(syllable_id_attr)
  if syllables[sid] == nil then syllables[sid] = {} end
  local g = tex.skip['gre@skip@minTextDistance']
  syllables[sid].min_text_distance = {g.width, g.stretch, g.shrink}
  g = tex.skip['gre@skip@minNotesDistance']
  syllables[sid].min_notes_distance = {g.width, g.stretch, g.shrink}
end

--- Free all information saved about syllables.
local function free_syllables()
  for sid, syl in pairs(syllables) do
    node.flush_list(syl.raw_text)
    syllables[sid] = nil
  end
end

--- Find nodes corresponding to various parts of syllables and store them in a
--- data structure more convenient for downstream processing.
--- @param head node The head of the list to be processed.
--- @return node The head of the processed list.
local function scan_syllables(head)
  for _, cur in pairs(syllables) do
    cur.first_note = nil
  end
  local prev_sid
  local function visit(head)
    for n in node.traverse(head) do
      if n.id == disc then
        -- Recurse into all three parts of a discretionary node.
        local save_prev_sid = prev_sid
        visit(n.pre)
        visit(n.post)
        prev_sid = save_prev_sid
        visit(n.replace)
      else
        local sid = has_attribute(n, syllable_id_attr)
        local part = has_attribute(n, part_attr)
        local skip_type = has_attribute(n, skip_type_attr)
        if sid ~= nil and syllables[sid] ~= nil then
          -- Record first and last node
          if part ~= nil or skip_type ~= nil then
            if syllables[sid].first == nil then
              syllables[sid].first = n
            end
          end
          syllables[sid].last = n
          if part == part_lyrics then
            if syllables[sid].text ~= nil then
              err(' syllable %d has more than one text node', sid)
            end
            syllables[sid].text = n
            -- Since every syllable is guaranteed to have exactly one text node,
            -- do some other bookkeeping here
            syllables[sid].prev_sid = prev_sid
            if prev_sid ~= nil then syllables[prev_sid].next_sid = sid end
            prev_sid = sid
          elseif part == part_notes then
            if syllables[sid].first_note == nil then
              syllables[sid].first_note = n
            end
            syllables[sid].last_note = n
          elseif skip_type == skip_type_before_test then
            syllables[sid].before_text_skip = n
          elseif skip_type == skip_type_text_notes then
            syllables[sid].text_notes_skip = n
          elseif skip_type == skip_type_after_notes then
            syllables[sid].after_notes_skip = n
          elseif skip_type == skip_type_syllablefinal then
            syllables[sid].syllablefinalskip = n
          elseif skip_type == skip_type_clearsyllable then
            syllables[sid].clearsyllable = n
          end
        end
      end
    end
  end
  visit(head)
end

--- Determine the width of a syllable's syllable-final skip, which is
--- the last skip before the start of the next syllable.
--- @param cur table The current syllable.
--- @param next table The next syllable.
local function adjust_syllablefinalskip(cur, next)
  local text_distance = (
    node.dimensions(cur.text.next, cur.last.next) +
    node.dimensions(next.first, next.text)
  )
  debugmessage('syllablespacing', '  text distance = %s', glue_to_string(text_distance))
  local min_text_distance = cur.min_text_distance
  debugmessage('syllablespacing', '  min text distance = %s', glue_to_string(min_text_distance))
  local min_text_shift = glue_add(min_text_distance, -text_distance)
  debugmessage('syllablespacing', '  min text shift = %s', glue_to_string(min_text_shift))
  
  local notes_distance = (
    node.dimensions(cur.last_note.next, cur.last.next) +
    node.dimensions(next.first, next.first_note)
  )
  debugmessage('syllablespacing', '  notes distance = %s', glue_to_string(notes_distance))
  local min_notes_distance = cur.min_notes_distance
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
end

--- Add a hyphen to the end of a syllable's text.
--- @param cur table The current syllable.
local function add_hyphen(cur)
  -- Append hyphen to saved syllable text (needed if the syllable gets rewritten)
  local g = node.new(glyph)
  g.font = cur.font
  g.char = gregoriotex.hyphen
  -- Find last glyph (because the last node may be a marker)
  local last = node.tail(cur.raw_text)
  while last ~= nil and last.id ~= glyph do last = last.prev end
  cur.raw_text = node.insert_after(cur.raw_text, last, g)
  
  -- Replace actual syllable text
  local old_width = cur.text.width
  node.flush_list(cur.text.head)
  cur.text.head = shaping(node.copy_list(cur.raw_text))
  local new_width = node.rangedimensions(cur.text, cur.text.head)
  cur.text.width = new_width
  local width_change = new_width - old_width

  -- Mark text as having a hyphen
  node.set_attribute(cur.text, dash_attr, dash_hasdash)

  -- To keep the text and notes aligned, update the kern between text and notes.
  cur.text_notes_skip.kern = cur.text_notes_skip.kern - width_change

  -- We also need to adjust the kern after the notes that moves
  -- to the right edge of the syllable. If this syllable ends up
  -- as the last of the line, \gre@calculateeolshift has already
  -- allocated space for the hyphen, and this adjustment is not
  -- necessary. So we want the adjustment to go after the
  -- endofsyllablepenalty, where it will disappear in case of a
  -- line break. But syllablefinalskip goes after the
  -- endofsyllablepenalty, so we can just let
  -- adjust_syllablefinalskip do all the work.

  -- Bug: if this syllable gets a hyphen and the next syllable is a
  -- bar, then the bar will have the wrong previousenddifference.
end

--- Determine the width of all syllables' horizontal spacing.
local function syllable_spacing()
  for sid, cur in pairs(syllables) do
    debugmessage('syllablespacing', 'after syllable %d', sid)
    local next = syllables[cur.next_sid]

    -- If the next syllable is a clef change without a bar, there is still a
    -- syllablefinalskip in between. As far as the new bar spacing algorithm is concerned,
    -- this skip is part of both the text and notes of the current syllable (issue #1724).
    if (cur.type == 'note' and cur.syllablefinalskip ~= nil and next ~= nil) then
      adjust_syllablefinalskip(cur, next)
    end

    local needs_hyphen = false
    -- If there is too much space between text, add a hyphen
    if (cur.text ~= nil and has_attribute(cur.text, dash_attr, dash_maybedash) and
        next ~= nil and next.text ~= nil) then
      local text_distance = (
        node.dimensions(cur.text.next, cur.last.next) +
        node.dimensions(next.first, next.text)
      )
      local max_distance = tex.sp(token.get_macro('gre@space@dimen@maximumspacewithoutdash'))
      if text_distance > max_distance then needs_hyphen = true end
    end
    -- If hyphen was forced, add a hyphen
    if cur.text ~= nil and has_attribute(cur.text, dash_attr, dash_forced) then
      needs_hyphen = true
    end
    -- If lyrics are disabled, don't add a hyphen
    if not gregoriotex.get_if('gre@showlyrics') then needs_hyphen = false end

    if needs_hyphen then
      add_hyphen(cur)
      -- Since adding the hyphen made cur wider, recompute syllablefinalskip
      if cur.syllablefinalskip and next ~= nil and not next.barspacing1 then
        adjust_syllablefinalskip(cur, next)
      end
    end
  end
end

--- Clear all syllables that are marked for clearing.
local function syllable_clearing()
  for sid, cur in pairs(syllables) do
    local prev = syllables[cur.prev_sid]
    if cur.clearsyllable and prev then
      debugmessage('clear', 'syllable %d', sid)
      local kern = 0
      -- current text must begin at or after prev notes' end
      if prev.last_note and cur.text then
        local overlap = -(node.dimensions(prev.last_note.next, prev.last.next) +
                          node.dimensions(cur.first, cur.text))
        debugmessage('clear', ' text-note overlap %fpt', overlap/2^16)
        kern = math.max(kern, overlap)
      end
      -- current notes must begin at or after prev text's end
      if prev.text and cur.first_note then
        local overlap = -(node.dimensions(prev.text.next, prev.last.next) +
                          node.dimensions(cur.first, cur.first_note))
        debugmessage('clear', ' note-text overlap %fpt', overlap/2^16)
        kern = math.max(kern, overlap)
      end
      debugmessage('clear', ' kern %fpt', kern/2^16)
      cur.clearsyllable.kern = kern
    end
  end
end

--- Rewrite all syllable texts that have no space in between them, so that
--- ligaturing and kerning can take place.
local function syllable_rewriting()
  if not gregoriotex.get_if('gre@rewritesyllables') then return end

  local start = 1
  local num_syllables = #syllables
  while start <= num_syllables do
    -- Find longest run of syllables, starting from start, that have
    -- zero distance between their text boxes.
    -- Note: It's safe to assume that consecutive syllables are numbered consecutively,
    -- because we don't rewrite into or out of discretionaries. If this changes, then
    -- the code below must be updated accordingly.
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
        if not (syllables[stop].type == 'note' and syllables[stop+1].type == 'note') then break end
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
          local n = syllables[sid].raw_text
          syllables[sid].raw_text = nil
          head, tail = concat_list(head, tail, n, node.tail(n))
        end
        syllables[start].raw_text = node.copy_list(head) -- in case it needs a hyphen
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

gregoriotex.save_syllable_info = save_syllable_info
gregoriotex.save_syllable_texts = save_syllable_texts
gregoriotex.save_min_distances = save_min_distances
gregoriotex.free_syllables = free_syllables
gregoriotex.scan_syllables = scan_syllables
gregoriotex.syllable_spacing = syllable_spacing
gregoriotex.syllable_clearing = syllable_clearing
gregoriotex.syllable_rewriting = syllable_rewriting
gregoriotex.add_hyphen = add_hyphen
