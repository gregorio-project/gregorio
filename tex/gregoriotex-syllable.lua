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

local note_type_attr = luatexbase.attributes['gre@attr@note@type']
local note_type_mora = 1
local note_type_bar = 2
local note_type_custos = 3

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

--- Test whether a node is a note.
--- @param n node The node to test.
--- @return bool Whether it is a note.
local function node_is_note(n)
  return (n ~= nil and
          has_attribute(n, part_attr, part_attr_notes) and
          n.id == hlist and n.width > 0)
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
--- @param end_of_word int Whether the syllable ends a word (1) or not (0)
local function save_syllable_info(type, end_of_word)
  local sid = tex.getattribute(syllable_id_attr)
  if syllables[sid] == nil then syllables[sid] = {} end
  syllables[sid].sid = sid
  syllables[sid].type = type
  syllables[sid].font = font.current()
  syllables[sid].in_disc = tonumber(token.get_macro('gre@insidediscretionary')) > 0
  syllables[sid].in_euouae = gregoriotex.get_if('gre@in@euouae')
  syllables[sid].end_of_word = end_of_word > 0
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
          local cur = syllables[sid]
          -- Record first and last node
          if part ~= nil or skip_type ~= nil then
            if cur.first == nil then
              cur.first = n
            end
          end
          cur.last = n
          if part == part_lyrics then
            if cur.text ~= nil then
              err(' syllable %d has more than one text node', sid)
            end
            cur.text = n
            -- Since every syllable is guaranteed to have exactly one text node,
            -- do some other bookkeeping here
            cur.prev_sid = prev_sid
            if prev_sid ~= nil then syllables[prev_sid].next_sid = sid end
            cur.custos_width = custos_width
            prev_sid = sid
          elseif part == part_notes then
            if cur.first_note == nil then
              cur.first_note = n
            end
            cur.last_note = n
          elseif skip_type == skip_type_before_text then
            cur.before_text_skip = n
          elseif skip_type == skip_type_text_notes then
            cur.text_notes_skip = n
          elseif skip_type == skip_type_after_notes then
            cur.after_notes_skip = n
          elseif skip_type == skip_type_syllablefinal then
            cur.syllablefinalskip = n
          elseif skip_type == skip_type_clearsyllable then
            cur.clearsyllable = n
          elseif n.id == penalty and n.penalty <= -10000 then
            -- Forced line break, which occurs within the notes
            cur.penalty = n
            cur.forced_line_break = true
          elseif part == part_penalty and not cur.forced_line_break then
            -- Ordinary end-of-syllable break
            cur.penalty = n
          end
        
          -- Sometimes we want the first or last note not including
          -- spaces or any zero-width material, e.g., the zero-width
          -- boxes used in debugging. If there are no such notes, let
          -- both be the first node.
          local n = cur.last_note
          while n ~= cur.first_note and (n.id ~= hlist or n.width == 0) do
            n = n.prev
          end
          cur.last_note_not_space = n
          local n = cur.first_note
          while n ~= cur.last_note_not_space and (n.id ~= hlist or n.width == 0) do
            n = n.next
          end
          cur.first_note_not_space = n
        end
      end
    end
  end
  visit(head)
end

--- Calculate how much the beginning of a syllable's notes should be
--- effectively moved right by when it starts with an alteration.
--- @param cur node The syllable to compute the shift for.
local function calculate_alteration_shift(cur)
  -- Skip over kerns and zero-width boxes (which are used both for debugging and for holes).
  local n = cur.first_note_not_space
  if has_attribute(n, alteration_type_attr) then
    -- Now look for a note, because a lone accidental doesn't get the alteration shift
    while n ~= cur.last_note.next and (not node_is_note(n) or has_attribute(n, alteration_type_attr)) do
      n = n.next
    end
    if n ~= cur.last_note.next then
      local adj = tex.sp(token.get_macro('gre@space@dimen@alterationadjustmentbar'))
      debugmessage('syllablespacing', 'alteration adjustment for syllable %d: %fpt', cur.sid, adj/2^16)
      cur.alteration_shift = adj
    end
  end
end

--- Calculate how much the end of a syllable's notes should be effectively moved left by
--- when it ends with a punctum mora.
--- @param cur node The syllable to compute the shift for.
--- @param next node The next syllable.
local function calculate_punctum_mora_shift(cur, next)
  debugmessage('syllablespacing', 'calculating punctum mora shift for syllable %d', cur.sid)
  -- Skip various things at the end of the notes. Zero-width boxes are used during debugging.
  local n = cur.last_note_not_space
  -- Look for final punctum mora and measure it (including preceding spacebeforesigns).
  local has_mora = false
  while n.next ~= cur.first_note and has_attribute(n, note_type_attr, note_type_mora) do
    n = n.prev
    has_mora = true
  end
  if has_mora then
    local mora_shift = dimen_to_glue(0)
    local mora_width = node.dimensions(n.next, cur.last_note.next)
    debugmessage('syllablespacing', 'mora width: %fpt', mora_width/2^16)
    local code = cur.settings.shiftaftermora
    if next ~= nil and next.type == 'bar' then
      if (code == 2 and next.text.width == 0 -- barsnotextonly
          or code == 3 -- barsonly
          or code == 5 -- always
      ) then
        mora_shift = glue_add(-mora_width, cur.settings.moraadjustmentbar)
        debugmessage('syllablespacing', 'mora adjustment before bar: %fpt', cur.settings.moraadjustmentbar[1]/2^16)
      end
    elseif next ~= nil and next.type == 'note' then
      if code > 3 then
        mora_shift = glue_add(-mora_width, cur.settings.moraadjustment)
        debugmessage('syllablespacing', 'mora adjustment: %fpt', cur.settings.moraadjustment[1]/2^16)
      end
    end
    debugmessage('syllablespacing', 'punctum mora shift: %fpt', mora_shift[1]/2^16)
    cur.mora_shift = mora_shift
  end
end

--- Determine the width of a \GreSyllable's syllable-final skip, which is
--- the last skip before the start of the next syllable.
--- @param cur table The current syllable.
--- @param next table The next syllable.
local function adjust_syllablefinalskip(cur, next)

  -- Several decisions depend on whether the next syllable starts with
  -- a bar or not.

  local next_is_bar = false

  if next ~= nil and next.type == 'bar' and not next.in_disc then
    -- In general, if next is a \GreBarSyllable, then it recomputes
    -- the space between cur and next, so cur doesn't need
    -- syllablefinalskip. This includes no-note syllables, but
    -- excludes clef changes (discretionaries), which are handled
    -- below.
    next_is_bar = true

  elseif next ~= nil then
    -- Otherwise, we check if next really starts with a bar (possibly
    -- preceded by a custos).
    
    -- If next is a clef change without a bar, it is a
    -- \GreBarSyllable, but we set next_is_bar to false, so there is
    -- still a syllablefinalskip in between. As far as the new bar
    -- spacing algorithm is concerned, this skip is part of both the
    -- text and notes of the current syllable (issue #1724).
    
    -- If next is a clef change with a bar, we set next_is_bar to
    -- true, even if a custos comes first (g+:c3).
    
    -- If next is a bar preceded by a custos (g+:), it is a
    -- \GreSyllable, but we set next_is_bar to true, which means there
    -- is no space in between (possibly a bug).
    
    local n = next.first_note_not_space
    -- Skip over non-notes and custoses
    while n ~= next.last_note.next and (not node_is_note(n) or has_attribute(n, note_type_attr, note_type_custos)) do
      n = n.next
    end
    if n ~= next.last_note.next and has_attribute(n, note_type_attr, note_type_bar) then
      next_is_bar = true
    end
  end
  debugmessage('syllablespacing', 'next_is_bar = %s', next_is_bar)
  
  local next_is_alteration = next ~= nil and next.alteration_shift ~= nil

  -- Just before the syllablefinalskip comes a penalty, which we adjust here.
  -- If the next syllable is a bar or clef change, don't allow a line break
  if next ~= nil and next.type == 'bar' then
    cur.penalty.penalty = tex.count['gre@space@count@nobreakpenalty']
  end

  -- In a few situations, we just zero out the syllablefinalskip and
  -- return. There is one more case below, after computing min_text_distance.
  if (next == nil or
      (next_is_bar and not gregoriotex.get_if('gre@newbarspacing') and
       (cur.forced_line_break or next.text.width == 0)))
  then
    debugmessage('syllablespacing', '  syllable final skip = 0pt')
    node.setglue(cur.syllablefinalskip, 0, 0, 0)
    return
  end

  --- Compute minimum desired distances

  -- The minimum distance from text right edge to next text left edge.
  local min_text_distance
  if cur.end_of_word then
    if cur.in_euouae then
      if gregoriotex.get_if('gre@newbarspacing') and next_is_bar then
        min_text_distance = dimen_to_glue(tex.sp(token.get_macro('gre@space@dimen@interwordspacetext@bars@euouae')))
      else
        min_text_distance = string_to_glue(token.get_macro('gre@space@skip@interwordspacetext@euouae'))
      end
    else -- not in euouae
      if gregoriotex.get_if('gre@newbarspacing') and next_is_bar then
        min_text_distance = dimen_to_glue(tex.sp(token.get_macro('gre@space@dimen@interwordspacetext@bars')))
      else
        min_text_distance = string_to_glue(token.get_macro('gre@space@skip@interwordspacetext'))
      end
    end
  else -- middle of word
    min_text_distance = dimen_to_glue(0)
  end
  cur.min_text_distance = min_text_distance -- needed by bar_syllable_spacing
  debugmessage('syllablespacing', '  min text distance = %s', glue_to_string(min_text_distance))
  
  -- One more case where there is no syllablefinalskip.
  -- The reason we do this here is that bar_syllable_spacing still needs cur.min_text_distance.
  if next_is_bar and gregoriotex.get_if('gre@newbarspacing') then
    debugmessage('syllablespacing', '  syllable final skip = 0pt')
    node.setglue(cur.syllablefinalskip, 0, 0, 0)
    return
  end

  -- The minimum distance from notes right edge to next notes left edge.
  local min_notes_distance
  if not next_is_bar and not next_is_alteration then -- next note is ordinary
    if cur.end_of_word then
      if cur.in_euouae then
        min_notes_distance = string_to_glue(token.get_macro('gre@space@skip@interwordspacenotes@euouae'))
      else
        min_notes_distance = string_to_glue(token.get_macro('gre@space@skip@interwordspacenotes'))
      end
    else
      min_notes_distance = dimen_to_glue(tex.sp(token.get_macro('gre@space@dimen@intersyllablespacenotes')))
    end
    if cur.mora_shift ~= nil then
      min_notes_distance = glue_add(min_notes_distance, cur.mora_shift)
    end

  elseif not next_is_alteration then -- next note is bar
    if gregoriotex.get_if('gre@newbarspacing') then
      min_notes_distance = 0
    else
      min_notes_distance = string_to_glue(token.get_macro('gre@space@skip@notebarspace'))
    end
    
  else -- next note is alteration
    if cur.end_of_word then
      min_notes_distance = string_to_glue(token.get_macro('gre@space@skip@interwordspacenotes@alteration'))
    else
      min_notes_distance = dimen_to_glue(tex.sp(token.get_macro('gre@space@dimen@intersyllablespacenotes@alteration')))
    end
  end

  debugmessage('syllablespacing', '  min notes distance = %s', glue_to_string(min_notes_distance))

  --- Compute how much to adjust the skip by.
  
  -- The distance from current text right edge to next text left edge.
  local text_distance = (
    node.dimensions(cur.text.next, cur.last.next) +
    node.dimensions(next.first, next.text)
  )
  debugmessage('syllablespacing', '  text distance = %s', glue_to_string(text_distance))
  
  local min_text_shift = glue_add(min_text_distance, -text_distance)
  debugmessage('syllablespacing', '  min text shift = %s', glue_to_string(min_text_shift))

  -- The distance from current notes right edge to next notes left edge.
  local notes_distance = (
    node.dimensions(cur.last_note.next, cur.last.next) +
    node.dimensions(next.first, next.first_note)
  )
  debugmessage('syllablespacing', '  notes distance = %s', glue_to_string(notes_distance))
  
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
    
  adjust_syllablefinalskip(cur, next)
  
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
    if (next ~= nil and next.type == 'bar' and gregoriotex.get_if('gre@newbarspacing')) then
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

--- Get the ends of the text and notes of the previous syllable, relative to the beginning of the current syllable.
--- @param prev node The previous syllable.
--- @param cur node The current syllable.
--- @return int The end of the text, in sp.
--- @return int The end of the notes, in sp.
--- @return int The end of the syllable, in sp (with punctum mora adjustment; used in old bar spacing only).
local function get_prev_ends(prev, cur)
  local prev_text_end, prev_notes_end
  local prev_end = 0
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
    if prev.mora_shift ~= nil then
      local save = math.max(prev_text_end, prev_notes_end)
      prev_notes_end = prev_notes_end + prev.mora_shift[1]
      -- Recompute end of previous syllable as if the punctum mora were not there, but the syllablefinalskip (if any) is
      prev_end = math.max(prev_text_end, prev_notes_end) - save
      debugmessage('barspacing', 'punctum mora adjustment: %fpt', prev.mora_shift[1]/2^16)
    end
  end
  debugmessage('barspacing', 'previous text end: %fpt', prev_text_end/2^16)
  debugmessage('barspacing', 'previous notes end: %fpt', prev_notes_end/2^16)
  -- useful for comparison with previous version:
  debugmessage('barspacing', 'previous end difference: %fpt', (prev_notes_end-prev_text_end)/2^16)
  debugmessage('barspacing', 'previous syllable end: %fpt', prev_end/2^16)
  return prev_text_end, prev_notes_end, prev_end
end

--- Get the position of the penalty (that is, where a line break may occur).
--- @param cur node The current syllable.
local function get_penalty(cur)
  local penalty_pos
  if cur.penalty ~= nil then
    penalty_pos = node.dimensions(cur.first, cur.penalty.next)
  else
    -- Inside a discretionary or at the end of the score, there is no penalty.
    -- Set this to the right edge of the syllable.
    penalty_pos = node.dimensions(cur.first, cur.last.next)
  end
  debugmessage('barspacing', 'penalty position: %fpt', penalty_pos/2^16)
  return penalty_pos
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
  local prev_text_end, prev_notes_end = get_prev_ends(prev, cur)

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

  local space_before_text = 0
  local space_after_text = 0
  if cur.text.width > 0 then
    space_before_text = prev and prev.min_text_distance and prev.min_text_distance[1] or 0
    if cur.end_of_word then
      if cur.in_euouae then
        space_after_text = tex.sp(token.get_macro('gre@space@dimen@interwordspacetext@bars@euouae'))
      else
        space_after_text = tex.sp(token.get_macro('gre@space@dimen@interwordspacetext@bars'))
      end
    end
  else
    -- If there is no text, ignore prev.min_text_distance and split
    -- current min_text_distance evenly before and after.
    local space_for_text
    if cur.end_of_word then
      if cur.in_euouae then
        space_for_text = tex.sp(token.get_macro('gre@space@dimen@interwordspacetext@bars@notext@euouae'))
      else
        space_for_text = tex.sp(token.get_macro('gre@space@dimen@interwordspacetext@bars@notext'))
      end
    end
    space_before_text = tex.round(space_for_text/2)
    space_after_text = tex.round(space_for_text/2)
  end
  cur.min_text_distance = dimen_to_glue(space_after_text)
  debugmessage('barspacing', 'space before text: %fpt', space_before_text/2^16)
  debugmessage('barspacing', 'space after text: %fpt', space_after_text/2^16)
  -- text_req includes space before and after
  local text_req = space_before_text + cur.text.width + space_after_text
  debugmessage('barspacing', 'space required for text: %fpt', text_req/2^16)
  local text_center = node.dimensions(cur.first, cur.text) - space_before_text + tex.round(text_req/2)
  debugmessage('barspacing', 'text center: %fpt', text_center/2^16)

  -- If there are notes, then notes_width does include the space
  -- before and after, and we don't add extra space. But if there are
  -- no notes, then notes_width is 0, and we add some extra space.
  local notes_width = node.dimensions(cur.first_note, cur.last_note.next)
  debugmessage('barspacing', 'width of notes: %fpt', notes_width/2^16)
  -- notes_req always includes the space before and after.
  local notes_req = notes_width
  if notes_width == 0 then
    notes_req = notes_req + string_to_glue(token.get_macro('gre@space@skip@interwordspacenotes'))[1]
  end
  debugmessage('barspacing', 'space required for notes: %fpt', notes_req/2^16)
  local space_after_notes = node.dimensions(cur.last_note_not_space.next, cur.last_note.next)
  debugmessage('barspacing', 'space after notes: %fpt', space_after_notes/2^16)
  local notes_center = node.dimensions(cur.first, cur.first_note) + tex.round(notes_width/2)
  debugmessage('barspacing', 'notes center: %fpt', notes_center/2^16)

  -- The end of the syllable, which is also the beginning of the next syllable.
  local cur_end = node.dimensions(cur.first, cur.last.next)
  debugmessage('barspacing', 'syllable width: %fpt', cur_end/2^16)

  local penalty_pos = get_penalty(cur)

  -- The beginning of the text and notes of the next syllable.
  local next_text_begin, next_notes_begin
  if next == nil or cur.forced_line_break then
    next_text_begin, next_notes_begin = cur_end, cur_end
  else
    next_text_begin = cur_end + node.dimensions(next.first, next.text) 
    next_notes_begin = cur_end + node.dimensions(next.first, next.first_note)
    -- Replicate bug #1734: if next syllable is a bar, then ignore space before it
    if next.type == 'bar' then
      next_notes_begin = next_notes_begin + node.dimensions(next.first_note, next.first_note_not_space)
    end
    -- Adjust if the next note has an alteration.
    if cur.type == 'bar' and next.alteration_shift ~= nil and not cur.in_disc then
      debugmessage('barspacing', 'alteration shift: %fpt', next.alteration_shift/2^16)
      next_notes_begin = next_notes_begin + next.alteration_shift
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
  debugmessage('barspacing', 'shift end by: %fpt', end_shift/2^16)

  -- Apply the shifts.
  cur.before_text_skip.kern = cur.before_text_skip.kern + text_shift
  cur.text_notes_skip.kern = cur.text_notes_skip.kern - text_shift + notes_shift
  cur.after_notes_skip.kern = cur.after_notes_skip.kern - notes_shift + penalty_shift
  if cur.syllablefinalskip ~= nil and not (next == nil or cur.forced_line_break) then
    if cur.syllablefinalskip.id == kern then -- possible inside discretionary
      cur.syllablefinalskip.kern = cur.syllablefinalskip.kern - penalty_shift + end_shift
    elseif cur.syllablefinalskip.id == glue then
      local skip = table.pack(node.getglue(cur.syllablefinalskip))
      skip = glue_add(skip, - penalty_shift + end_shift)
      skip = glue_add(skip, string_to_glue(token.get_macro('gre@space@skip@bar@rubber')))
      node.setglue(cur.syllablefinalskip, table.unpack(skip))
    end
  end
end

--- Set the widths of all horizontal spaces in a \GreBarSyllable, using the old bar spacing algorithm.
--- @param prev node The previous syllable.
--- @param cur node The bar syllable.
--- @param next node The next syllable.
local function old_bar_syllable_spacing(prev, cur, next)
  debugmessage('barspacing', 'syllable %d', cur.sid)
  
  -- The end of the text and notes of the previous syllable.
  local prev_text_end, prev_notes_end, prev_end = get_prev_ends(prev, cur)

  local text_begin = node.dimensions(cur.first, cur.text)
  local text_end = text_begin + cur.text.width
  
  -- Width of notes including built-in space
  local notes_begin = node.dimensions(cur.first, cur.first_note)
  local notes_width = node.dimensions(cur.first_note, cur.last_note.next)
  local notes_end = notes_begin + notes_width
  debugmessage('barspacing', 'notes begin: %fpt', notes_begin/2^16)
  debugmessage('barspacing', 'notes width: %fpt', notes_width/2^16)

  local penalty_pos = get_penalty(cur)

  -- The end of the syllable, which is also the beginning of the next syllable.
  local cur_end = node.dimensions(cur.first, cur.last.next)
  debugmessage('barspacing', 'syllable width: %fpt', cur_end/2^16)
  
  -- The beginning of the text and notes of the next syllable.
  local next_text_begin, next_notes_begin
  if next == nil or cur.forced_line_break then
    next_text_begin, next_notes_begin = cur_end, cur_end
  else
    next_text_begin = cur_end + node.dimensions(next.first, next.text) 
    next_notes_begin = cur_end + node.dimensions(next.first, next.first_note)
  end  
  debugmessage('barspacing', 'next text begin: %fpt', next_text_begin/2^16)
  debugmessage('barspacing', 'next notes begin: %fpt', next_notes_begin/2^16)
  -- useful for comparison with previous version:
  debugmessage('barspacing', 'next begin difference: %fpt', (next_text_begin-next_notes_begin)/2^16)
  
  local new_text_begin, new_notes_begin, end_shift
  local end_glue = dimen_to_glue(0)
  if cur.text.width == 0 then
    debugmessage('barspacing', 'bar has no text')
    -- The notes should have at least notebarspace around the notes on either side
    local notes_req = notes_width + 2*string_to_glue(token.get_macro('gre@space@skip@notebarspace'))[1]
    debugmessage('barspacing', 'minimum space for notes: %fpt', notes_req/2^16)
    -- Minimum distance between the previous and next syllable
    local syllable_req
    if prev_notes_end < prev_text_end then
      syllable_req = string_to_glue(token.get_macro('gre@space@skip@interwordspacetext'))[1]
    else
      syllable_req = string_to_glue(token.get_macro('gre@space@skip@interwordspacenotes'))[1]
    end
    debugmessage('barspacing', 'minimum space for syllable: %fpt', syllable_req/2^16)
    end_shift = math.max(prev_notes_end + notes_req - next_notes_begin, prev_end + syllable_req - cur_end)
    debugmessage('barspacing', 'shift end by: %fpt', end_shift/2^16)
    -- Move the (empty) text as far right as possible so as not to interfere with hyphenation
    new_text_begin = next_text_begin
    -- Center notes between previous and next notes
    new_notes_begin = tex.round((prev_notes_end + next_notes_begin + end_shift - notes_width)/2)
    debugmessage('barspacing', 'new notes begin: %fpt', new_notes_begin/2^16)
    -- If notes end earlier than previous text, move notes right (but don't move end of syllable)
    new_notes_begin = math.max(new_notes_begin, prev_text_end - notes_width)
    debugmessage('barspacing', 'new notes begin: %fpt', new_notes_begin/2^16)
    -- If notes begin later than next text, move end of syllable right (rather than move notes left)
    end_shift = math.max(end_shift, new_notes_begin - next_text_begin)
    -- The penalty is at the end of the notes (even if the text is longer, probably a bug)
    new_penalty_pos = new_notes_begin + notes_width
  else
    debugmessage('barspacing', 'bar has text')
    -- The text begins at the beginning of the syllable.
    -- Bug: If the bar is wider than the notes, it could overlap the preceding notes.
    new_text_begin = prev_end
    new_notes_begin = prev_end - text_begin + notes_begin
    new_penalty_pos = math.max(new_notes_begin + notes_width, prev_end + cur.text.width)
    local final_skip
    if text_end < notes_end then
      if next_notes_begin < next_text_begin then
        final_skip = string_to_glue(token.get_macro('gre@space@skip@notebarspace'))
      else
        final_skip = string_to_glue(token.get_macro('gre@space@skip@textbartextspace'))
      end
    else
      if next_text_begin < next_notes_begin then
        final_skip = string_to_glue(token.get_macro('gre@space@skip@textbartextspace'))
      else
        final_skip = string_to_glue(token.get_macro('gre@space@skip@interwordspacetext'))
      end
    end
    end_shift = glue_add(new_penalty_pos, final_skip)[1] - cur_end
    end_glue[2], end_glue[3] = final_skip[2], final_skip[3]
  end
  
  -- Compute how much everything should shift by.
  local text_shift = new_text_begin - text_begin
  debugmessage('barspacing', 'shift text by: %fpt', text_shift/2^16)
  local notes_shift = new_notes_begin - notes_begin
  debugmessage('barspacing', 'shift notes by: %fpt', notes_shift/2^16)
  local penalty_shift = new_penalty_pos - penalty_pos
  debugmessage('barspacing', 'shift penalty by: %fpt', penalty_shift/2^16)
  debugmessage('barspacing', 'shift end by: %fpt', end_shift/2^16)

  -- Apply the shifts.
  cur.before_text_skip.kern = cur.before_text_skip.kern + text_shift
  cur.text_notes_skip.kern = cur.text_notes_skip.kern - text_shift + notes_shift
  cur.after_notes_skip.kern = cur.after_notes_skip.kern - notes_shift + penalty_shift
  if cur.syllablefinalskip ~= nil and not (next == nil or cur.forced_line_break) then
    if cur.syllablefinalskip.id == kern then -- possible inside discretionary
      cur.syllablefinalskip.kern = cur.syllablefinalskip.kern - penalty_shift + end_shift
    elseif cur.syllablefinalskip.id == glue then
      cur.syllablefinalskip.width = cur.syllablefinalskip.width - penalty_shift + end_shift
      cur.syllablefinalskip.stretch, cur.syllablefinalskip.shrink = end_glue[2], end_glue[3]
    end
  end
end

local function syllable_spacing()
  for sid, cur in pairs(syllables) do
    local prev = syllables[cur.prev_sid]
    local next = syllables[cur.next_sid]
    if next ~= nil then calculate_alteration_shift(next) end
    calculate_punctum_mora_shift(cur, next)
    if cur.type == 'note' then
      note_syllable_spacing(cur, next)
    elseif cur.type == 'bar' then
      if gregoriotex.get_if('gre@newbarspacing') then
        bar_syllable_spacing(prev, cur, next)
      else
        old_bar_syllable_spacing(prev, cur, next)
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
        if cur.type == 'bar' and prev.mora_shift then
          overlap = overlap + prev.mora_shift[1]
        end
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
gregoriotex.current_syllable = current_syllable
gregoriotex.free_syllables = free_syllables
gregoriotex.scan_syllables = scan_syllables
gregoriotex.syllable_spacing = syllable_spacing
gregoriotex.syllable_clearing = syllable_clearing
gregoriotex.syllable_rewriting = syllable_rewriting
gregoriotex.add_hyphen = add_hyphen
