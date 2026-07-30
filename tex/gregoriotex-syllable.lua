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
local whatsit = node.id('whatsit')
local hlist = node.id('hlist')

local syllable_id_attr = luatexbase.attributes['gre@attr@syllable@id']

local part_attr = luatexbase.attributes['gre@attr@part']
local part_lyrics = 4
local part_notes = 10
-- additional lyric lines (stacked lyrics, level 2+) use
-- part_lyric_line_base + level, so they sort after every fixed part
local part_lyric_line_base = 9

local skip_type_attr = luatexbase.attributes['gre@attr@skip@type']
local skip_type_syllablefinal = 1
local skip_type_before_text = 2
local skip_type_text_notes = 3
local skip_type_after_notes = 4
local skip_type_clearsyllable = 5

--- Possible values of syllables[sid].dash
local dash_maybedash = 1
local dash_hasdash = 2
local dash_endofword = 3
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

--- Record whether an additional lyric line (level 2+) ends a word here,
--- called from \GreWriteLyricLine for each line of the current syllable.
--- @param level number The lyric line level (2 for the first additional line).
--- @param end_of_word number 1 if this level ends a word here, else 0.
local function set_lyric_line_dash(level, end_of_word)
  local cur = current_syllable()
  if cur.levels == nil then cur.levels = {} end
  if cur.levels[level] == nil then cur.levels[level] = {} end
  cur.levels[level].dash = (end_of_word == 1) and dash_endofword or dash_maybedash
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
  settings.syllablerewriting = gregoriotex.get_if('gre@rewritesyllables')
  settings.showlyrics = gregoriotex.get_if('gre@showlyrics')
  settings.intersyllablespacestretchhyphen = string_to_glue(token.get_macro('gre@space@skip@intersyllablespacestretchhyphen'))
  settings.maximumspacewithoutdash = tex.sp(token.get_macro('gre@space@dimen@maximumspacewithoutdash'))
  settings.interwordspacetext = string_to_glue(token.get_macro('gre@space@skip@interwordspacetext'))
  syllables[sid].settings = settings
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
    if cur.levels ~= nil then
      for _, cl in pairs(cur.levels) do
        cl.box = nil
      end
    end
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
          elseif part ~= nil and part >= part_lyric_line_base + 2 then
            local lev = part - part_lyric_line_base
            if syllables[sid].levels == nil then syllables[sid].levels = {} end
            if syllables[sid].levels[lev] == nil then syllables[sid].levels[lev] = {} end
            syllables[sid].levels[lev].box = n
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
          end
        end
      end
    end
  end
  visit(head)
end

--- Find the left and right edges of an additional lyric line's text,
--- relative to its zero-width outer box: a centering kern followed by the
--- inner text hbox.
--- @param box node The outer hbox of the lyric line.
--- @return number The left edge, in sp.
--- @return number The right edge, in sp.
local function level_edges(box)
  local left = 0
  for m in node.traverse(box.head) do
    if m.id == kern then
      left = left + m.kern
    elseif m.id == hlist then
      return left, left + m.width
    end
  end
  return left, left
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
  
  local min_shift = glue_max(min_text_shift, min_notes_shift)

  -- Each additional lyric line has its own word position, independent of
  -- the main line, so its own minimum distance (interwordspacetext where
  -- it ends a word here, otherwise none) must be enforced separately.
  if cur.levels ~= nil and next.levels ~= nil then
    for lev, cl in pairs(cur.levels) do
      local nl = next.levels[lev]
      if cl.box ~= nil and nl ~= nil and nl.box ~= nil then
        local _, cur_right = level_edges(cl.box)
        local next_left = level_edges(nl.box)
        local level_distance = node.dimensions(cl.box.next, nl.box) - cur_right + next_left
        debugmessage('syllablespacing', '  lyric line %d distance = %s', lev, glue_to_string(level_distance))
        local min_level_distance = (cl.dash == dash_endofword) and cur.settings.interwordspacetext or {0, 0, 0}
        min_shift = glue_max(min_shift, glue_add(min_level_distance, -level_distance))
      end
    end
  end

  local syllablefinalskip = {cur.syllablefinalskip.width, cur.syllablefinalskip.stretch, cur.syllablefinalskip.shrink}
  -- Ensure that min text shift, min notes shift, and every lyric line's own
  -- min shift are satisfied.
  syllablefinalskip = glue_add(syllablefinalskip, min_shift)
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

--- Add a hyphen to the end of one additional lyric line of a syllable.
--- The outer box has zero width, so only the inner text hbox needs to
--- grow; adjust_syllablefinalskip fixes up the horizontal spacing.
--- @param cur table The current syllable.
--- @param lev number The lyric line level (2 for the first additional line).
local function add_level_hyphen(cur, lev)
  local box = cur.levels[lev] and cur.levels[lev].box
  if box == nil then return end
  local inner
  for m in node.traverse(box.head) do
    if m.id == hlist then
      inner = m
      break
    end
  end
  if inner == nil then return end
  local g = node.new(glyph)
  g.font = cur.font
  g.char = gregoriotex.hyphen
  if inner.head == nil then
    inner.head = g
  else
    node.insert_after(inner.head, node.tail(inner.head), g)
  end
  inner.head = shaping(inner.head)
  inner.width = node.rangedimensions(inner, inner.head)
  cur.levels[lev].dash = dash_hasdash
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
    if (cur.text ~= nil and cur.dash == dash_maybedash and
        next ~= nil and next.text ~= nil) then
      local text_distance = (
        node.dimensions(cur.text.next, cur.last.next) +
        node.dimensions(next.first, next.text)
      )
      local max_distance = cur.settings.maximumspacewithoutdash
      if text_distance > max_distance then needs_hyphen = true end
    end
    -- If hyphen was forced, add a hyphen
    if cur.text ~= nil and cur.dash == dash_forced then
      needs_hyphen = true
    end
    -- If lyrics are disabled, don't add a hyphen
    if not cur.settings.showlyrics then needs_hyphen = false end

    if needs_hyphen then
      add_hyphen(cur)
      -- Since adding the hyphen made cur wider, recompute syllablefinalskip
      if cur.syllablefinalskip and next ~= nil and not next.barspacing1 then
        adjust_syllablefinalskip(cur, next)
      end
    end

    -- Hyphens for the additional lyric lines, with the same distance rule
    -- as the level-1 text above. Adding a hyphen widens a line, which can
    -- change what adjust_syllablefinalskip computes and so require another
    -- line to be hyphenated too; iterate to a fixed point. Each round
    -- either adds at least one hyphen or stops, so this terminates.
    if cur.levels ~= nil and cur.settings.showlyrics then
      local added_this_round = true
      while added_this_round do
        added_this_round = false
        if (cur.text ~= nil and cur.dash == dash_maybedash and
            next ~= nil and next.text ~= nil) then
          local text_distance = (
            node.dimensions(cur.text.next, cur.last.next) +
            node.dimensions(next.first, next.text)
          )
          if text_distance > cur.settings.maximumspacewithoutdash then
            debugmessage('hyphenation', 'adding hyphen to syllable %d', sid)
            add_hyphen(cur)
            added_this_round = true
          end
        end
        for lev, cl in pairs(cur.levels) do
          if cl.box ~= nil and cl.dash == dash_maybedash
              and next ~= nil and next.levels ~= nil
              and next.levels[lev] ~= nil and next.levels[lev].box ~= nil then
            local _, cur_right = level_edges(cl.box)
            local next_left = level_edges(next.levels[lev].box)
            local level_distance = node.dimensions(cl.box.next, next.levels[lev].box) - cur_right + next_left
            debugmessage('hyphenation', 'syllable %d lyric line %d distance %.5fpt', sid, lev, level_distance/2^16)
            if level_distance > cur.settings.maximumspacewithoutdash then
              debugmessage('hyphenation', 'adding hyphen to lyric line %d of syllable %d', lev, sid)
              add_level_hyphen(cur, lev)
              added_this_round = true
            end
          end
        end
        if added_this_round and cur.syllablefinalskip and next ~= nil and not next.barspacing1 then
          adjust_syllablefinalskip(cur, next)
        end
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
gregoriotex.set_lyric_line_dash = set_lyric_line_dash
gregoriotex.save_syllable_texts = save_syllable_texts
gregoriotex.save_min_distances = save_min_distances
gregoriotex.current_syllable = current_syllable
gregoriotex.free_syllables = free_syllables
gregoriotex.scan_syllables = scan_syllables
gregoriotex.syllable_spacing = syllable_spacing
gregoriotex.syllable_clearing = syllable_clearing
gregoriotex.syllable_rewriting = syllable_rewriting
gregoriotex.add_hyphen = add_hyphen
gregoriotex.add_level_hyphen = add_level_hyphen
