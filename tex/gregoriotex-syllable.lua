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

local syllable_id_attr = luatexbase.attributes['gre@attr@syllable@id']

local part_attr = luatexbase.attributes['gre@attr@part']
local part_lyrics = 4

local dash_attr = luatexbase.attributes['gre@attr@dash']
local dash_hasdash = 2
local dash_barsyllable = 4

local saved_syllable_texts = {}
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
    saved_syllable_texts[sid] = node.copy_list(cur)
  end
end

local function free_saved_syllable_texts()
  for sid, head in pairs(saved_syllable_texts) do
    node.flush_list(head)
    saved_syllable_texts[sid] = nil
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

local function syllable_rewriting(head)
  --gregoriotex.dump_nodes(head)
  if not gregoriotex.get_if('gre@rewritesyllables') then return head end

  local syllables = {}
  local last_sid = nil
  for n in node.traverse(head) do
    -- This skips over discretionary nodes, which can't participate in syllable rewriting
    local sid, part = has_attribute(n, syllable_id_attr), has_attribute(n, part_attr)
    if sid ~= nil and part == part_lyrics then
      if syllables[sid] ~= nil then
        err('syllable %d has more than one text node', sid)
      end
      debugmessage('syllablerewriting', 'syllable %d has text node', sid)
      syllables[sid] = {}
      syllables[sid].text_node = n
      last_sid = sid
    end
  end

  if last_sid == nil then return head end

  local start = 1
  while start <= last_sid do
    -- Find longest run of syllables, starting from start, that have
    -- zero distance between their text boxes.
    if syllables[start] == nil or syllables[start].text_node == nil then
      debugmessage('syllablerewriting', 'syllable %d has no text node', start)
      start = start + 1
    else
      local stop = start
      while stop+1 <= last_sid do
        -- There are several conditions that prevent syllable rewriting:
        -- if either text node is missing
        if syllables[stop+1] == nil or syllables[stop+1].text_node == nil then break end
        -- don't rewrite across a line break
        if gregoriotex.is_last_syllable_id_on_line(stop) then break end
        -- don't rewrite across a hyphen
        if has_attribute(syllables[stop].text_node, dash_attr, dash_hasdash) then break end
        -- if either syllable is a \GreBarSyllable
        if has_attribute(syllables[stop].text_node, dash_attr, dash_barsyllable) or
          has_attribute(syllables[stop+1].text_node, dash_attr, dash_barsyllable) then break end
        -- don't rewrite across a nonzero space
        if node.dimensions(syllables[stop].text_node.next, syllables[stop+1].text_node) ~= 0 then break end
        stop = stop + 1
      end
      -- Concatenate syllable text boxes into one box.
      if start < stop then
        debugmessage('syllablerewriting', 'merge syllables %d-%d', start, stop)
        local head, tail
        for sid = start, stop do
          -- Extend new text
          local n = saved_syllable_texts[sid]
          saved_syllable_texts[sid] = nil
          head, tail = concat_list(head, tail, n, node.tail(n))
        end
        head = shaping(head)
        for sid = start, stop do
          -- Rewrite text, inserting kerns to preserve widths
          local del = syllables[sid].text_node.head
          syllables[sid].text_node.head = nil
          node.flush_list(del)
          local kern = node.new(kern, 'userkern')
          kern.kern = syllables[sid].text_node.width
          if sid == start then
            syllables[sid].text_node.head = head
            kern.kern = kern.kern - node.dimensions(head)
            concat_list(head, tail, kern)
          else
            syllables[sid].text_node.head = kern
          end
        end
      end
      start = stop + 1
    end
  end
  --gregoriotex.dump_nodes(head)
  return head
end

gregoriotex.save_syllable_texts = save_syllable_texts
gregoriotex.free_saved_syllable_texts = free_saved_syllable_texts
gregoriotex.syllable_rewriting = syllable_rewriting
