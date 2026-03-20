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
local hlist = node.id('hlist')
local glue = node.id('glue')
local kern = node.id('kern')
local temp = node.id('temp')
local disc = node.id('disc')
local glyph = node.id('glyph')
local whatsit = node.id('whatsit')
local penalty = node.id('penalty')
local local_par = node.id('local_par')

local syllable_id_attr = luatexbase.attributes['gre@attr@syllable@id']

local part_attr = luatexbase.attributes['gre@attr@part']
local part_lyrics = 4
local part_notes = 10
local part_penalty = 11

local alteration_type_attr = luatexbase.attributes['gre@attr@alteration@type']

local skip_type_attr = luatexbase.attributes['gre@attr@skip@type']
local skip_type_syllablefinal = 1
local skip_type_before_text = 2
local skip_type_text_notes = 3
local skip_type_after_notes = 4
local skip_type_clearsyllable = 5

--- Possible values of syllables[sid].dash
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

--- Insert one node list into another.
--- @param head node The head of the list to insert into.
--- @param where node The node after which newhead will be inserted.
--- @param newhead node The head of the list to insert.
--- @param newtail node The tail of the list to insert.
--- @return node The head of the new list.
--- @return node The new insertion point.
local function insert_list_after(head, where, newhead, newtail)
  if head == nil then
    return newhead, newtail
  elseif newhead == nil then
    return head, where
  else
    local rest = where.next
    where.next = newhead
    newhead.prev = where
    if rest ~= nil then
      newtail.next = rest
      rest.prev = newtail
    end
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

--- Return the data structure for the current syllable.
--- @return table The syllable.
local function current_syllable()
  local sid = tex.getattribute(syllable_id_attr)
  if syllables[sid] == nil then syllables[sid] = {} end
  return syllables[sid]
end

--- Save information about syllables that is impossible or
--- inconvenient to recover from node attributes.
--- @param type string Type of syllable ('bar' or 'note')
local function save_syllable_info(type)
  local sid = tex.getattribute(syllable_id_attr)
  if syllables[sid] == nil then syllables[sid] = {} end
  syllables[sid].sid = sid
  syllables[sid].type = type
  syllables[sid].font = font.current()
  settings = {}
  --- If these settings are changed mid-syllable, they do not affect the current syllable.
  settings.syllablerewriting = gregoriotex.get_if('gre@rewritesyllables')
  settings.showlyrics = gregoriotex.get_if('gre@showlyrics')
  settings.intersyllablespacestretchhyphen = string_to_glue(token.get_macro('gre@space@skip@intersyllablespacestretchhyphen'))
  settings.maximumspacewithoutdash = tex.sp(token.get_macro('gre@space@dimen@maximumspacewithoutdash'))
  syllables[sid].settings = settings
end

--- Save settings after expanding the text and notes of a syllable.
--- If these settings are changed mid-syllable, they do affect the current syllable.
local function save_post_syllable()
  local sid = tex.getattribute(syllable_id_attr)
  local settings = syllables[sid].settings
  settings.shiftaftermora = tex.count['gre@count@shiftaftermora']
  settings.moraadjustment = string_to_glue(token.get_macro('gre@space@skip@moraadjustment'))
  settings.moraadjustmentbar = string_to_glue(token.get_macro('gre@space@skip@moraadjustmentbar'))
end
  
--- Save syllable text before ligaturing and kerning happens. This
--- is needed later during syllable rewriting.
--- @param head node The syllable text.
local function save_syllable_texts(head)
  if tex.getattribute(part_attr) == part_lyrics then
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
local function save_min_distance(part, skip)
  local sid = tex.getattribute(syllable_id_attr)
  if syllables[sid] == nil then syllables[sid] = {} end
  local g = tex.skip[skip]
  if part == 'notes' then
    syllables[sid].min_notes_distance = {g.width, g.stretch, g.shrink}
  elseif part == 'text' then
    syllables[sid].min_text_distance = {g.width, g.stretch, g.shrink}
  elseif part == 'mora_shift' then
    syllables[sid].mora_shift = {g.width, g.stretch, g.shrink}
  end
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
  local custos_width, prev_sid
  local function visit(head)
    for n in node.traverse(head) do
      if n.id == disc then
        -- Recurse into all three parts of a discretionary node.
        local save_prev_sid = prev_sid
        visit(n.pre)
        visit(n.post)
        prev_sid = save_prev_sid
        visit(n.replace)
      elseif n.id == local_par then
        custos_width = n.box_right_width
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
            syllables[sid].custos_width = custos_width
            prev_sid = sid
          elseif part == part_notes then
            if syllables[sid].first_note == nil then
              syllables[sid].first_note = n
              syllables[sid].last_note_not_space = n
            end
            syllables[sid].last_note = n
            -- Sometimes we want the last note not including spaces.
            -- We ignore zero-width boxes because they are used during debugging.
            if n.id == hlist and n.width > 0 then
              syllables[sid].last_note_not_space = n
            end
          elseif skip_type == skip_type_before_text then
            syllables[sid].before_text_skip = n
          elseif skip_type == skip_type_text_notes then
            syllables[sid].text_notes_skip = n
          elseif skip_type == skip_type_after_notes then
            syllables[sid].after_notes_skip = n
          elseif skip_type == skip_type_syllablefinal then
            syllables[sid].syllablefinalskip = n
          elseif skip_type == skip_type_clearsyllable then
            syllables[sid].clearsyllable = n
          elseif n.id == penalty and n.penalty <= -10000 then
            -- Forced line break, which occurs within the notes
            syllables[sid].penalty = n
            syllables[sid].forced_line_break = true
          elseif part == part_penalty and not syllables[sid].forced_line_break then
            -- Ordinary end-of-syllable break
            syllables[sid].penalty = n
          end
        end
      end
    end
  end
  visit(head)
end

--- Determine the width of a \GreSyllable's syllable-final skip, which is
--- the last skip before the start of the next syllable.
--- @param cur table The current syllable.
--- @param next table The next syllable.
local function adjust_syllablefinalskip(cur, next)
  -- The distance from current text right edge to next text left edge.
  local text_distance = (
    node.dimensions(cur.text.next, cur.last.next) +
    node.dimensions(next.first, next.text)
  )
  debugmessage('syllablespacing', '  text distance = %s', glue_to_string(text_distance))
  local min_text_distance = cur.min_text_distance
  debugmessage('syllablespacing', '  min text distance = %s', glue_to_string(min_text_distance))
  local min_text_shift = glue_add(min_text_distance, -text_distance)
  debugmessage('syllablespacing', '  min text shift = %s', glue_to_string(min_text_shift))

  -- The distance from current notes right edge to next notes left edge.
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
  if cur.text and cur.dash == dash_hasdash then
    debugmessage('syllablespacing', '  adding stretch for hyphen: %s', glue_to_string(cur.settings.intersyllablespacestretchhyphen))
    syllablefinalskip = glue_add(syllablefinalskip, cur.settings.intersyllablespacestretchhyphen)
  end
  debugmessage('syllablespacing', '  syllable final skip = %s', glue_to_string(syllablefinalskip))
  node.setglue(cur.syllablefinalskip, table.unpack(syllablefinalskip))
end

--- Append material to the end of a syllable's raw_text.
--- @param cur table The current syllable.
--- @param head node The material to append.
local function add_to_raw_text(cur, head)
  -- Both cur.raw_text and head may be surrounded by markers (for
  -- point-and-click links). To allow ligaturing and kerning to
  -- occur, we need to discard head's markers and insert before
  -- cur.raw_text's closing marker.
  
  local last = cur.raw_text and node.tail(cur.raw_text)
  local tail = head and node.tail(head)
  if last ~= nil and last.id == whatsit then last = last.prev end
  if head ~= nil and head.id == whatsit then head = node.free(head) end
  if tail ~= nil and tail.id == whatsit then
    local del = tail
    tail = tail.prev
    node.free(del)
  end
  cur.raw_text = insert_list_after(cur.raw_text, last, head, tail)
end

--- Add a hyphen to the end of a syllable's text.
--- @param cur table The current syllable.
local function add_hyphen(cur)
  -- Append hyphen to saved syllable text (needed if the syllable gets rewritten).
  -- If the whole syllable has a style (\gre@fixedtextformat) then cur.font has this style too.
  local g = node.new(glyph)
  g.font = cur.font
  g.char = gregoriotex.hyphen
  
  add_to_raw_text(cur, g)
  
  -- Replace actual syllable text
  local old_width = cur.text.width
  node.flush_list(cur.text.head)
  cur.text.head = shaping(node.copy_list(cur.raw_text))
  local new_width = node.rangedimensions(cur.text, cur.text.head)
  cur.text.width = new_width
  local width_change = new_width - old_width

  -- Mark text as having a hyphen
  cur.dash = dash_hasdash

  -- To keep the text and notes aligned, update the kern between text and notes.
  cur.text_notes_skip.kern = cur.text_notes_skip.kern - width_change

  cur.hyphen_width = width_change

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

--- Determine the width of a \GreSyllable's horizontal spacing.
local function note_syllable_spacing(cur, next)
  debugmessage('syllablespacing', 'after syllable %d', cur.sid)
    
  -- If the next syllable is a clef change without a bar, there is still a
  -- syllablefinalskip in between. As far as the new bar spacing algorithm is concerned,
  -- this skip is part of both the text and notes of the current syllable (issue #1724).
  if (cur.type == 'note' and cur.syllablefinalskip ~= nil and next ~= nil) then
    adjust_syllablefinalskip(cur, next)
  end
  
  local needs_hyphen = false
  -- If there is too much space between text, add a hyphen
  if (cur.text ~= nil and cur.dash == dash_maybedash and
      next ~= nil and next.text ~= nil) then
    local text_distance = (
      node.dimensions(cur.text.next, cur.last.next) +
      node.dimensions(next.first, next.text)
    )

    -- Replicate bug #1734: if next syllable is a bar, assume it has
    -- the bar and text centered, with no extra space.
    if (next ~= nil and (next.type == 'bar' or next.type == 'clefchange') and gregoriotex.get_if('gre@newbarspacing')) then
      local end_diff = node.dimensions(cur.text.next, cur.last_note.next)
      local next_notes_width = 0
      -- further bug: should the below ignore space around bar too?
      if next.first_note then
        next_notes_width = node.dimensions(next.first_note, next.last_note.next)
      end
      local next_begin_diff = (next_notes_width - next.text.width)/2
      text_distance = end_diff - next_begin_diff
    end
    
    debugmessage('syllablespacing', 'space between text nodes: %.2fpt', text_distance/2^16)
    local max_distance = cur.settings.maximumspacewithoutdash
    debugmessage('syllablespacing', 'maximum space without dash: %.2fpt', max_distance/2^16)
    if text_distance > max_distance then needs_hyphen = true end
  end
  -- If hyphen was forced, add a hyphen
  if cur.text ~= nil and cur.dash == dash_forced then
    debugmessage('syllablespacing', 'forced hyphen')
    needs_hyphen = true
  end
  -- If lyrics are disabled, don't add a hyphen
  if not gregoriotex.get_if('gre@showlyrics') then needs_hyphen = false end

  if needs_hyphen then
    debugmessage('syllablespacing', 'text needs hyphen')
    add_hyphen(cur)
    -- Since adding the hyphen made cur wider, recompute syllablefinalskip
    if cur.syllablefinalskip and next ~= nil and next.type == 'note' then
      adjust_syllablefinalskip(cur, next)
    end
  end
end

--- Set the widths of all horizontal spaces in a \GreBarSyllable, using the new bar spacing algorithm.
--- @param prev node The previous syllable.
--- @param cur node The bar syllable.
--- @param next node The next syllable.
local function bar_syllable_spacing(prev, cur, next)
  debugmessage('barspacing', 'syllable %d', cur.sid)
  
  --[[ We want to satisfy the following constraints, from highest to lowest priority:
    (1) The offset between the current bar and text centers must not exceed a certain maximum.
    (2) The previous and next syllables must not overlap.
    (3) Minimize space between previous and next syllables.
    (4) Center the current bar between previous and next notes.
    (5) Center the current current text between previous and next text. ]]

  -- All positions are calculated relative to the beginning of the syllable.

  -- The end of the text and notes of the previous syllable.
  local prev_text_end, prev_notes_end
  if prev == nil then
    prev_text_end, prev_notes_end = 0, 0
  else
    prev_text_end = -node.dimensions(prev.text.next, prev.last.next)
    -- If previous text has a hyphen, ignore it.
    if prev.hyphen_width then
      prev_text_end = prev_text_end - prev.hyphen_width
    end
    prev_notes_end = -node.dimensions(prev.last_note.next, prev.last.next)
    -- Adjust if the previous note has a punctum mora.
    if cur.mora_shift[1] ~= 0 then
      prev_notes_end = prev_notes_end + cur.mora_shift[1]
      debugmessage('barspacing', 'punctum mora adjustment: %fpt', cur.mora_shift[1]/2^16)
    end
  end
  debugmessage('barspacing', 'previous text end: %fpt', prev_text_end/2^16)
  debugmessage('barspacing', 'previous notes end: %fpt', prev_notes_end/2^16)
  -- useful for comparison with previous version:
  debugmessage('barspacing', 'previous end difference: %fpt', (prev_notes_end-prev_text_end)/2^16)

  if prev and prev.syllablefinalskip then
    local width = prev.syllablefinalskip.width or prev.syllablefinalskip.kern
    prev_text_end = prev_text_end + width
    prev_notes_end = prev_notes_end + width
  end

  -- The current syllable.
  
  -- The space available to the text and notes depends on the next
  -- syllable's begin difference even if the next syllable is on the
  -- next line (bug #959).

  -- It is possible to have glue here: (1) if this is a clef change,
  -- the space before can be \gre@space@skip@interwordspacetext
  -- (possibly a bug); (2) if there are no notes, the space after can
  -- be \gre@space@skipinterwordspacenotes. We discard the stretch/shrink.

  local space_before_text, space_after_text
  if cur.text.width > 0 then
    space_before_text = prev and prev.min_text_distance[1] or 0
    space_after_text = cur.min_text_distance[1]
  else
    -- If there is no text, ignore prev.min_text_distance and split
    -- cur.min_text_distance evenly before and after.
    space_before_text = tex.round(cur.min_text_distance[1]/2)
    space_after_text = cur.min_text_distance[1] - space_before_text
  end
  debugmessage('barspacing', 'space before text: %fpt', space_before_text/2^16)
  debugmessage('barspacing', 'space after text: %fpt', space_after_text/2^16)
  -- text_req includes space before and after
  local text_req = space_before_text + cur.text.width + space_after_text
  debugmessage('barspacing', 'space required for text: %fpt', text_req/2^16)
  local text_center = node.dimensions(cur.first, cur.text) - space_before_text + tex.round(text_req/2)
  debugmessage('barspacing', 'text center: %fpt', text_center/2^16)

  -- If there are notes, then notes_width does include the space
  -- before and after. But if there are no notes, then notes_width is 0.
  local notes_width = node.dimensions(cur.first_note, cur.last_note.next)
  debugmessage('barspacing', 'width of notes: %fpt', notes_width/2^16)
  -- notes_req always includes the space before and after.
  local notes_req = notes_width + cur.min_notes_distance[1]
  debugmessage('barspacing', 'space required for notes: %fpt', notes_req/2^16)
  local space_after_notes = node.dimensions(cur.last_note_not_space.next, cur.last_note.next)
  debugmessage('barspacing', 'space after notes: %fpt', space_after_notes/2^16)
  local notes_center = node.dimensions(cur.first, cur.first_note) + tex.round(notes_width/2)
  debugmessage('barspacing', 'notes center: %fpt', notes_center/2^16)

  -- The end of the syllable, which is also the beginning of the next syllable.
  local cur_end = node.dimensions(cur.first, cur.last.next)
  debugmessage('barspacing', 'syllable width: %fpt', cur_end/2^16)

  -- The place near the end of the syllable where the line may be broken.
  local penalty_pos
  if cur.penalty ~= nil then
    penalty_pos = node.dimensions(cur.first, cur.penalty.next)
  else
    -- Inside a discretionary or at the end of the score, there is no penalty.
    -- Set this to the right edge of the syllable.
    penalty_pos = cur_end
  end
  debugmessage('barspacing', 'penalty position: %fpt', penalty_pos/2^16)

  -- The beginning of the text and notes of the next syllable.
  local next_text_begin, next_notes_begin
  if next == nil or cur.forced_line_break then
    next_text_begin, next_notes_begin = cur_end, cur_end
  else
    next_text_begin = cur_end + node.dimensions(next.first, next.text) 
    next_notes_begin = cur_end + node.dimensions(next.first, next.first_note)
    local n = next.first_note
    -- Skip over kerns and zero-width boxes (holes).
    while (n ~= nil and has_attribute(n, part_attr, part_attr_notes) and
           n.id ~= hlist or n.id == hlist and n.width == 0) do
      n = n.next
    end
    -- Replicate bug #1734: if next syllable is a bar, then ignore space before it
    if next.type == 'bar' or next.type == 'clefchange' then
      next_notes_begin = next_notes_begin + node.dimensions(next.first_note, n)
    end
    -- Adjust if the next note has an alteration.
    if cur.type == 'bar' then -- don't adjust if cur.type == 'clefchange'
      if has_attribute(n, alteration_type_attr) then
        local adj = tex.sp(token.get_macro('gre@space@dimen@alterationadjustmentbar'))
        next_notes_begin = next_notes_begin + adj
        debugmessage('barspacing', 'alteration adjustment: %fpt', adj/2^16)
      end
    end
  end
  debugmessage('barspacing', 'next text begin: %fpt', next_text_begin/2^16)
  debugmessage('barspacing', 'next notes begin: %fpt', next_notes_begin/2^16)
  -- useful for comparison with previous version:
  debugmessage('barspacing', 'next begin difference: %fpt', (next_text_begin-next_notes_begin)/2^16)
  
  -- Calculate space needed, assuming no offset limits.
  local end_shift = math.max(
    prev_notes_end + notes_req - next_notes_begin, -- notes touch prev and next notes
    prev_text_end + text_req - next_text_begin, -- text touches prev and next text
    prev_notes_end - next_text_begin, -- prev notes touch next text
    prev_text_end - next_notes_begin -- prev text touches next notes
  )
  debugmessage('barspacing', 'new syllable width: %fpt', (cur_end+end_shift)/2^16)
  
  -- Center notes and text in their respective spaces.
  local new_text_center = tex.round((prev_text_end + next_text_begin + end_shift)/2)
  local new_notes_center = tex.round((prev_notes_end + next_notes_begin + end_shift)/2)
  debugmessage('barspacing', 'new text center: %fpt', new_text_center/2^16)
  debugmessage('barspacing', 'new notes center: %fpt', new_notes_center/2^16)

  -- Don't let text offset exceed offset limits.
  if cur.text.width > 0 then
    local new_text_offset = new_text_center - new_notes_center
    debugmessage('barspacing', 'new text offset: %fpt', new_text_offset/2^16)
    
    local max_offset_left, max_offset_right
    if cur.clearsyllable ~= nil then
      -- Cleared syllable
      max_offset_left = 0
      max_offset_right = 0
    elseif cur.forced_line_break then
      -- Last syllable before forced break
      max_offset_left = tex.sp(token.get_macro('gre@space@dimen@maxbaroffsettextleft@eol'))
      max_offset_right = tex.sp(token.get_macro('gre@space@dimen@maxbaroffsettextright@eol'))
    elseif notes_width > 0 then
      -- The most common case
      max_offset_left = tex.sp(token.get_macro('gre@space@dimen@maxbaroffsettextleft'))
      max_offset_right = tex.sp(token.get_macro('gre@space@dimen@maxbaroffsettextright'))
    else
      -- A no-note syllable
      max_offset_left = tex.sp(token.get_macro('gre@space@dimen@maxbaroffsettextleft@nobar'))
      max_offset_right = tex.sp(token.get_macro('gre@space@dimen@maxbaroffsettextright@nobar'))
    end
    debugmessage('barspacing', 'maximum offset to left: %fpt', max_offset_left/2^16)
    debugmessage('barspacing', 'maximum offset to right: %fpt', max_offset_right/2^16)
  
    if new_text_offset > max_offset_right then
      -- Move text to the left
      new_text_center = new_notes_center + max_offset_right
      -- If text collides, move both text and notes to the right
      local overlap = prev_text_end - (new_text_center - tex.round(text_req/2))
      if overlap > 0 then
        new_text_center = new_text_center + overlap
        new_notes_center = new_notes_center + overlap
        -- If notes collide, increase space
        overlap = (new_notes_center + tex.round(notes_req/2)) - (next_notes_begin + end_shift)
        if overlap > 0 then
          end_shift = end_shift + overlap
        end
      end
    elseif new_text_offset < -max_offset_left then
      -- Move text to the right
      new_text_center = new_notes_center - max_offset_left
      -- If text collides, move both text and notes to the left
      local overlap = (new_text_center + tex.round(text_req/2)) - (next_text_begin + end_shift)
      if overlap > 0 then
        new_text_center = new_text_center - overlap
        new_notes_center = new_notes_center - overlap
        -- If notes collide, increase space
        overlap = prev_notes_end - (new_notes_center - tex.round(notes_req/2))
        if overlap > 0 then
          new_text_center = new_text_center + overlap
          new_notes_center = new_notes_center + overlap
          end_shift = end_shift + overlap
        end
      end
    end
    debugmessage('barspacing', 'new text center: %fpt', new_text_center/2^16)
    debugmessage('barspacing', 'new notes center: %fpt', new_notes_center/2^16)
    debugmessage('barspacing', 'new syllable width: %fpt', (cur_end + end_shift)/2^16)
  end

  -- Position of syllable-final penalty
  local new_penalty_pos
  if gregoriotex.get_if('gre@eolshiftsenabled') then
    debugmessage('barspacing', 'custos width: %fpt', cur.custos_width/2^16)
    new_penalty_pos = math.max(
      new_text_center + tex.round(text_req/2) - space_after_text - cur.custos_width,
      new_notes_center + tex.round(notes_req/2) - space_after_notes
    )
  else
    -- When eolshifts are disabled, the bar retains the space
    -- afterwards (possibly a bug).
    new_penalty_pos = math.max(
      new_text_center + tex.round(text_req/2) - space_after_text,
      new_notes_center + tex.round(notes_req/2)
    )
  end
  debugmessage('barspacing', 'new penalty position: %fpt', new_penalty_pos/2^16)
  
  -- Compute how much everything should shift by.
  local text_shift = new_text_center - text_center
  debugmessage('barspacing', 'shift text by: %fpt', text_shift/2^16)
  local notes_shift = new_notes_center - notes_center
  debugmessage('barspacing', 'shift notes by: %fpt', notes_shift/2^16)
  local penalty_shift = new_penalty_pos - penalty_pos
  debugmessage('barspacing', 'shift penalty by: %fpt', penalty_shift/2^16)

  -- Apply the shifts.
  cur.before_text_skip.kern = cur.before_text_skip.kern + text_shift
  cur.text_notes_skip.kern = cur.text_notes_skip.kern - text_shift + notes_shift
  cur.after_notes_skip.kern = cur.after_notes_skip.kern - notes_shift + penalty_shift
  if cur.syllablefinalskip ~= nil then
    if cur.syllablefinalskip.id == kern then -- possible inside discretionary
      cur.syllablefinalskip.kern = cur.syllablefinalskip.kern - penalty_shift + end_shift
    elseif cur.syllablefinalskip.id == glue then
      cur.syllablefinalskip.width = cur.syllablefinalskip.width - penalty_shift + end_shift
    end
  end
end

local function syllable_spacing()
  for sid, cur in pairs(syllables) do
    local prev = syllables[cur.prev_sid]
    local next = syllables[cur.next_sid]
    if cur.type == 'note' then
      note_syllable_spacing(cur, next)
    elseif cur.type == 'bar' or cur.type == 'clefchange' then
      if gregoriotex.get_if('gre@newbarspacing') then
        bar_syllable_spacing(prev, cur, next)
      else
        -- to do
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
        if prev.mora_shift then overlap = overlap + prev.mora_shift end
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
  local start = 1
  local num_syllables = #syllables
  while start <= num_syllables do
    -- Find longest run of syllables, starting from start, that have
    -- zero distance between their text boxes.
    -- Note: It's safe to assume that consecutive syllables are numbered consecutively,
    -- because we don't rewrite into or out of discretionaries. If this changes, then
    -- the code below must be updated accordingly.
    if not syllables[start].settings['syllablerewriting'] then
      start = start + 1
    else
      local stop = start
      while stop+1 <= num_syllables do
        -- There are several conditions that prevent syllable rewriting:
        -- if syllablerewriting is disabled
        if not syllables[stop+1].settings.syllablerewriting then break end
        -- if either text node is missing
        if syllables[stop+1].text == nil then break end
        -- don't rewrite across a line break
        if gregoriotex.is_last_syllable_id_on_line(stop) then break end
        -- don't rewrite across a hyphen
        if syllables[stop].dash == dash_hasdash then break end
        -- if either syllable is a \GreBarSyllable
        if not (syllables[stop].type == 'note' and syllables[stop+1].type == 'note') then break end
        -- don't rewrite across a nonzero space
        if node.dimensions(syllables[stop].text.next, syllables[stop+1].text) ~= 0 then break end
        stop = stop + 1
      end
      -- Concatenate syllable text boxes into one box.
      if start < stop then
        debugmessage('syllablerewriting', 'merge syllables %d-%d', start, stop)
        for sid = start+1, stop do
          -- Extend new text
          local n = syllables[sid].raw_text
          syllables[sid].raw_text = nil
          add_to_raw_text(syllables[start], n, node.tail(n))
        end
        local head = shaping(node.copy_list(syllables[start].raw_text))
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
            syllables[sid].text.head = node.insert_after(head, tail, kern)
          else
            syllables[sid].text.head = kern
            syllables[sid].is_merged = true
          end
        end
      end
      start = stop + 1
    end
  end
end

gregoriotex.save_syllable_info = save_syllable_info
gregoriotex.save_post_syllable = save_post_syllable
gregoriotex.save_syllable_texts = save_syllable_texts
gregoriotex.save_min_distance = save_min_distance
gregoriotex.current_syllable = current_syllable
gregoriotex.free_syllables = free_syllables
gregoriotex.scan_syllables = scan_syllables
gregoriotex.syllable_spacing = syllable_spacing
gregoriotex.syllable_clearing = syllable_clearing
gregoriotex.syllable_rewriting = syllable_rewriting
gregoriotex.add_hyphen = add_hyphen
