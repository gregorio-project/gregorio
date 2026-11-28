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
-- the part of additional lyric line lev is part_lyric_line_base + lev
local part_lyric_line_base = gregoriotex.part_lyric_line_base

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

-- A syllable's main lyric line (level 1) is stored on the syllable table
-- itself, as it always was; its additional lines (levels 2 and below) in
-- cur.levels[lev], with the same field names: text (the line's box), raw_text,
-- dash and is_merged.  This lets spacing, hyphenation and rewriting handle
-- every level alike.

--- The table holding a given lyric line of a syllable, or nil if the
--- syllable has no such line.
--- @param cur table A syllable.
--- @param lev number The lyric line level.
--- @return table|nil
local function level(cur, lev)
  if lev == 1 then return cur end
  return cur.levels and cur.levels[lev]
end

--- Same as level, but creates the table if needed.
local function level_store(cur, lev)
  if lev == 1 then return cur end
  cur.levels = cur.levels or {}
  cur.levels[lev] = cur.levels[lev] or {}
  return cur.levels[lev]
end

--- The node whose head and width hold a lyric line's glyphs: the text box
--- itself for level 1, or the box nested in the zero-width box of levels 2+
--- (\hbox to 0pt{\kern...\hbox{...}\hss}).
--- @param cur table A syllable.
--- @param lev number The lyric line level.
--- @return node|nil
local function level_content_node(cur, lev)
  local box = (level(cur, lev) or {}).text
  if box == nil or lev == 1 then return box end
  for m in node.traverse(box.head) do
    if m.id == hlist then return m end
  end
  return nil
end

--- The deepest lyric line of a syllable (1 if it has no additional lines).
local function num_levels(cur)
  local n = 1
  if cur.levels ~= nil then
    for lev in pairs(cur.levels) do
      if lev > n then n = lev end
    end
  end
  return n
end

--- The deepest lyric line in the whole score.
local function max_level()
  local m = 1
  for _, cur in pairs(syllables) do
    m = math.max(m, num_levels(cur))
  end
  return m
end

--- Record the dash state of an additional lyric line of the current
--- syllable; called by \gre@typesetstackedlevel.  A forced hyphen wins over
--- an end of word, as for the main line.
--- @param lev number The lyric line level (2 for the first additional line).
--- @param end_of_word number 1 if this line ends a word here, else 0.
--- @param forced number 1 if this line has a forced hyphen, else 0.
local function set_lyric_line_dash(lev, end_of_word, forced)
  local dash = dash_maybedash
  if end_of_word == 1 then dash = dash_endofword end
  if forced == 1 then dash = dash_forced end
  level_store(current_syllable(), lev).dash = dash
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
  local part = tex.getattribute(part_attr)
  local lev
  if part == part_lyrics then
    lev = 1
  elseif part ~= nil and part > part_lyric_line_base + 1 then
    -- this is also called for the outer box of an additional lyric line,
    -- recognized by the inner box (which holds the text) it contains
    for m in node.traverse(head) do
      if m.id == hlist then return end
    end
    lev = part - part_lyric_line_base
  else
    return
  end
  local sid = tex.getattribute(syllable_id_attr)
  local cur = head
  while cur ~= nil and cur.id == temp do cur = cur.next end
  if syllables[sid] == nil then syllables[sid] = {} end
  level_store(syllables[sid], lev).raw_text = node.copy_list(cur)
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
    if syl.levels ~= nil then
      for _, cl in pairs(syl.levels) do
        node.flush_list(cl.raw_text)
      end
    end
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
        cl.text = nil
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
            level_store(syllables[sid], part - part_lyric_line_base).text = n
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

--- The horizontal gap between cur's and next's text at a given level, which
--- both must have.  The boxes of levels 2+ are zero-width, so the position
--- of the text inside them (level_edges) counts too.
--- @param cur table The current syllable.
--- @param lev number The lyric line level.
--- @param next table The next syllable.
--- @return number The gap, in sp.
local function level_gap(cur, lev, next)
  if lev == 1 then
    return node.dimensions(cur.text.next, cur.last.next) +
           node.dimensions(next.first, next.text)
  else
    local cur_box = cur.levels[lev].text
    local next_box = next.levels[lev].text
    local _, cur_right = level_edges(cur_box)
    local next_left = level_edges(next_box)
    return node.dimensions(cur_box.next, next_box) - cur_right + next_left
  end
end

--- Whether a syllable renders any text at a given level. Measured on the
--- box itself rather than on raw_text, which only note syllables save
--- (a bar's own text counts too).
--- @param cur table A syllable.
--- @param lev number The lyric line level.
--- @return boolean
local function level_has_text(cur, lev)
  local content = level_content_node(cur, lev)
  return content ~= nil and content.width ~= 0
end

--- The gap between cur's text at a given level and the next text it must
--- stay clear of, or nil if there is none. Normally that is the adjacent
--- syllable's text. But if cur's word continues at this level through note
--- syllables that are empty there (the connectors of a stacked word), their
--- boxes render nothing and can't mark a real boundary, so measure to the
--- text cur's word really runs into instead.
--- @param cur table The current syllable.
--- @param lev number The lyric line level.
--- @param next table The immediately following syllable.
--- @return number|nil The gap, in sp.
local function clearance_gap(cur, lev, next)
  local target = next
  local dash = level(cur, lev).dash
  if cur.settings.showlyrics
      and (dash == dash_maybedash or dash == dash_hasdash) then
    local candidate = next
    while candidate ~= nil and candidate.type == 'note'
        and not level_has_text(candidate, lev)
        and (level(candidate, lev) or {}).dash ~= dash_endofword do
      candidate = syllables[candidate.next_sid]
    end
    if candidate ~= nil and level_has_text(candidate, lev) then
      target = candidate
    end
  end
  if (level(target, lev) or {}).text == nil then return nil end
  if target ~= next and lev == 1 then
    -- level_gap's level-1 formula only adds up for an adjacent pair
    return node.dimensions(cur.text.next, target.text)
  end
  return level_gap(cur, lev, target)
end

--- Determine the width of a syllable's syllable-final skip, which is
--- the last skip before the start of the next syllable.
--- @param cur table The current syllable.
--- @param next table The next syllable.
local function adjust_syllablefinalskip(cur, next)
  local notes_distance = (
    node.dimensions(cur.last_note.next, cur.last.next) +
    node.dimensions(next.first, next.first_note)
  )
  debugmessage('syllablespacing', '  notes distance = %s', glue_to_string(notes_distance))
  local min_notes_distance = cur.min_notes_distance
  debugmessage('syllablespacing', '  min notes distance = %s', glue_to_string(min_notes_distance))
  local min_shift = glue_add(min_notes_distance, -notes_distance)
  debugmessage('syllablespacing', '  min notes shift = %s', glue_to_string(min_shift))

  -- nil if there is no text to keep clear of: then only the notes count
  local text_distance = clearance_gap(cur, 1, next)
  if text_distance ~= nil then
    debugmessage('syllablespacing', '  text distance = %s', glue_to_string(text_distance))
    local min_text_distance = cur.min_text_distance
    debugmessage('syllablespacing', '  min text distance = %s', glue_to_string(min_text_distance))
    local min_text_shift = glue_add(min_text_distance, -text_distance)
    debugmessage('syllablespacing', '  min text shift = %s', glue_to_string(min_text_shift))
    min_shift = glue_max(min_text_shift, min_shift)
  end

  -- Each additional lyric line has its own word boundaries, so its own
  -- minimum distance (interwordspacetext where it ends a word) applies.
  if cur.levels ~= nil then
    for lev = 2, num_levels(cur) do
      local cl = cur.levels[lev]
      if cl ~= nil and cl.text ~= nil then
        local level_distance = clearance_gap(cur, lev, next)
        if level_distance ~= nil then
          debugmessage('syllablespacing', '  lyric line %d distance = %s', lev, glue_to_string(level_distance))
          local min_level_distance = (cl.dash == dash_endofword) and cur.settings.interwordspacetext or {0, 0, 0}
          min_shift = glue_max(min_shift, glue_add(min_level_distance, -level_distance))
        end
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

--- Add a hyphen to the end of a syllable's text at a given lyric line.
--- Widening the main line requires adjusting its alignment with the notes;
--- the additional lines sit in zero-width boxes, so only their text grows.
--- @param cur table The current syllable.
--- @param lev number The lyric line level; defaults to 1.
local function add_hyphen(cur, lev)
  lev = lev or 1
  -- If the whole syllable has a style (\gre@fixedtextformat) then cur.font has this style too.
  local g = node.new(glyph)
  g.font = cur.font
  g.char = gregoriotex.hyphen

  if lev == 1 then
    -- Append hyphen to saved syllable text (needed if the syllable gets rewritten).
    add_to_raw_text(cur, g)

    -- Replace actual syllable text
    local old_width = cur.text.width
    node.flush_list(cur.text.head)
    cur.text.head = shaping(node.copy_list(cur.raw_text))
    local new_width = node.rangedimensions(cur.text, cur.text.head)
    cur.text.width = new_width
    local width_change = new_width - old_width

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
  else
    local inner = level_content_node(cur, lev)
    if inner == nil then return end
    -- as above, but g itself goes into the box, so raw_text gets a copy
    add_to_raw_text(level_store(cur, lev), node.copy(g))
    if inner.head == nil then
      inner.head = g
    else
      node.insert_after(inner.head, node.tail(inner.head), g)
    end
    inner.head = shaping(inner.head)
    inner.width = node.rangedimensions(inner, inner.head)
  end

  -- Mark text as having a hyphen
  level_store(cur, lev).dash = dash_hasdash
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

    -- Add the forced hyphens, on every lyric line that has one.
    if cur.settings.showlyrics then
      local forced_any = false
      for lev = 1, num_levels(cur) do
        local l = level(cur, lev)
        if l ~= nil and l.dash == dash_forced and l.text ~= nil then
          add_hyphen(cur, lev)
          forced_any = true
        end
      end
      if forced_any and cur.syllablefinalskip and next ~= nil
          and not next.barspacing1 then
        adjust_syllablefinalskip(cur, next)
      end
    end

    -- Add a hyphen to each lyric line whose word continues and whose text
    -- is too far from the next text at the same level.  A hyphen widens its
    -- line, which can change the spacing and so call for a hyphen on
    -- another line: repeat until no hyphen is added.
    if cur.settings.showlyrics and next ~= nil then
      local added_this_round = true
      while added_this_round do
        added_this_round = false
        for lev = 1, num_levels(cur) do
          -- (an empty syllable in the middle of a word gets no hyphen)
          if (level(cur, lev) or {}).dash == dash_maybedash
              and level_has_text(cur, lev) then
            local distance = clearance_gap(cur, lev, next)
            if distance ~= nil then
              debugmessage('hyphenation', 'syllable %d level %d distance %.5fpt', sid, lev, distance/2^16)
              if distance > cur.settings.maximumspacewithoutdash then
                debugmessage('hyphenation', 'adding hyphen to syllable %d level %d', sid, lev)
                add_hyphen(cur, lev)
                added_this_round = true
              end
            end
          end
        end
        if added_this_round and cur.syllablefinalskip and not next.barspacing1 then
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

--- Rewrite all syllable texts at a given lyric line that have no space in
--- between them, so that ligaturing and kerning can take place.  Each line
--- has its own word boundaries, so each is rewritten independently.
--- @param lev number The lyric line level to rewrite.
local function rewrite_level(lev)
  local start = 1
  local num_syllables = #syllables
  while start <= num_syllables do
    -- Find longest run of syllables, starting from start, that have
    -- zero distance between their text boxes at this level.
    -- Note: It's safe to assume that consecutive syllables are numbered consecutively,
    -- because we don't rewrite into or out of discretionaries. If this changes, then
    -- the code below must be updated accordingly.
    if not syllables[start].settings['syllablerewriting']
        or (level(syllables[start], lev) or {}).text == nil then
      start = start + 1
    else
      local stop = start
      while stop+1 <= num_syllables do
        local nxt = syllables[stop+1]
        -- There are several conditions that prevent syllable rewriting:
        -- if syllablerewriting is disabled
        if not nxt.settings.syllablerewriting then break end
        -- if either level's box is missing
        if (level(nxt, lev) or {}).text == nil then break end
        -- don't rewrite across a line break
        if gregoriotex.is_last_syllable_id_on_line(stop) then break end
        -- don't rewrite across a hyphen (at this level)
        if level(syllables[stop], lev).dash == dash_hasdash then break end
        -- if either syllable is a \GreBarSyllable
        if not (syllables[stop].type == 'note' and nxt.type == 'note') then break end
        -- don't rewrite across a nonzero space (at this level)
        if (lev == 1
              and node.dimensions(syllables[stop].text.next, nxt.text)
              or level_gap(syllables[stop], lev, nxt)) ~= 0 then
          break
        end
        stop = stop + 1
      end
      -- Concatenate this level's text boxes into one box.
      if start < stop then
        debugmessage('syllablerewriting', 'merge level %d syllables %d-%d', lev, start, stop)
        for sid = start+1, stop do
          -- Extend new text
          local store = level_store(syllables[sid], lev)
          local n = store.raw_text
          store.raw_text = nil
          add_to_raw_text(level_store(syllables[start], lev), n)
        end
        local head = shaping(node.copy_list(level_store(syllables[start], lev).raw_text))
        for sid = start, stop do
          -- Rewrite text, inserting kerns to preserve widths
          local content = level_content_node(syllables[sid], lev)
          local del = content.head
          content.head = nil
          node.flush_list(del)
          local kern = node.new(kern, 'userkern')
          kern.kern = content.width
          if sid == start then
            content.head = head
            kern.kern = kern.kern - node.dimensions(head)
            content.head = node.insert_after(head, tail, kern)
          else
            content.head = kern
            level_store(syllables[sid], lev).is_merged = true
          end
        end
      end
      start = stop + 1
    end
  end
end

--- Rewrite all syllable texts that have no space in between them, so that
--- ligaturing and kerning can take place.
local function syllable_rewriting()
  for lev = 1, max_level() do
    rewrite_level(lev)
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
gregoriotex.lyric_level = level
gregoriotex.num_levels = num_levels
