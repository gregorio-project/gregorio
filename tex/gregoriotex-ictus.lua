--GregorioTeX Lua file.
--
--Copyright (C) 2008-2010 The Gregorio Project (see CONTRIBUTORS.md)
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

-- this file contains lua functions for chironomy used by GregorioTeX
-- when called with LuaTeX.

if grechiro and grechiro.version then
 -- we simply don't load
else

grechiro = {}

grechiro.module = {
  name          = "gregoriotex-ictus",
  version       = 2.1,
  date          = "2010/09/27",
  description   = "GregorioTeX module for chironomy.",
  author        = "Elie Roux",
  copyright     = "Elie Roux",
  license       = "GPLv3"  
}

if luatextra and luatextra.provides_module then
  luatextra.provides_module(grechiro.module)
end

grechiro.version  = 2.1
grechiro.showlog  = grechiro.showlog or false

grechiro.currentLine = grechiro.currentLine or 1
grechiro.currentScore = grechiro.currentScore or 0
grechiro.list = grechiro.list or nil
grechiro.normalPen = grechiro.normalPen or "pencircle xscaled 1 yscaled 0.5 rotated 30"
grechiro.smallBarPen = grechiro.smallBarPen or "pencircle xscaled 0.5 yscaled 0.25 rotated 60"

local normalPen = grechiro.normalPen
local smallBarPen = grechiro.smallBarPen

local ia = 0
local it = 1

--[[

The list of ictus is like this:

chiro_list: scores(list)
score: lines(list)
line: begin, width, ictus(list)
ictus: type, pos

]]


-- we work in pt in this file

grechiro.atBeginScore = grechiro.atBeginScore or function()
  -- as we call this function at each score beginning, we don't rebuild the list each time
  if grechiro.list == nil then
    grechiro.createList()
  end
  grechiro.currentScore = grechiro.currentScore + 1
  grechiro.currentLine = 1
end

grechiro.createList = grechiro.createList or function ()
  -- the philosophy is to fill current* and then to append it to the good lists
  local f = io.open(tex.jobname .. '.gaux')
  local currentLine = nil
  local currentScore = nil
  local currentScoreWidth = 0
  local currentScoreBeginPos = 0
  local currentPos = 0
  if f == nil then
    return false
  end
  for line in f:lines() do
    key, pos = string.match(line, "(%w+):(%d+)")
    if key == nil then
      texio.write_nl("unable to find a corresponding line pattern in the aux file")
    else
      pos = pos/65536
      if key == 'ia' and currentLine ~= nil then
        if currentPos > pos then
          table.insert(currentScore.lines, currentLine)
          currentLine = {}
          currentLine.ictus = {}
          currentLine.begin = currentScoreBeginPos
          currentLine.width = currentScoreWidth
        end
        currentPos = pos
        table.insert(currentLine.ictus, {['type'] = ia, ['pos'] = pos})
      elseif key == 'it' and currentLine ~= nil then
        if currentPos > pos then
          table.insert(currentScore.lines, currentLine)
          currentLine = {}
          currentLine.ictus = {}
          currentLine.begin = currentScoreBeginPos
          currentLine.width = currentScoreWidth
        end
        currentPos = pos
        table.insert(currentLine.ictus, {['type'] = it, ['pos'] = pos})
      elseif key == 'begin' then
        if currentLine ~= nil and currentScore ~= nil then
          table.insert(currentScore.lines, currentLine)
        end
        if grechiro.list == nil then
          grechiro.list = {}
          grechiro.list.scores={}
        end
        currentScoreBeginPos = pos
        if currentScore ~= nil then
          table.insert(grechiro.list.scores, currentScore)
        end
        currentScore = {}
        currentScore.lines = {}
        currentScoreWidth = 0
        currentPos = 0
        currentLine = {}
        currentLine.ictus = {}
      elseif key == 'width' then
        currentScoreWidth = pos
        currentLine.begin = currentScoreBeginPos
        currentLine.width = currentScoreWidth
      end
    end
  end
  if currentScore ~= nil then
    table.insert(currentScore.lines, currentLine)
    table.insert(grechiro.list.scores, currentScore)
  end
  io.close(f)
  --printTable(grechiro.list, '')
  return true
end

local createList = grechiro.createList

-- function called in the TeX Code, calls ChiroPrintCLine with the good line
grechiro.printLine = grechiro.printLine or function ()
  if grechiro.list == nil or grechiro.currentScore > table.maxn(grechiro.list.scores) then
    return
  elseif grechiro.currentLine > table.maxn(grechiro.list.scores[grechiro.currentScore].lines) then
    -- if there are too many calls in a score
    return
  elseif table.maxn(grechiro.list.scores) < grechiro.currentScore  or grechiro.currentScore == 0 then
    -- a basic check
    return
  else
    --printTable(grechiro.list.scores[chiroCurrentScore].lines[chiroCurrentLine], '')
    grechiro.printCLine (grechiro.list.scores[grechiro.currentScore].lines[grechiro.currentLine])
    grechiro.currentLine = grechiro.currentLine + 1
    
  end
end

local printLine = grechiro.printLine

grechiro.printCLine = grechiro.printCLine or function (line)
  -- just to know if we print small bars or not
  printSmallBars = tex.count.printchirovbars
  if line == nil then
    return
  end
  local s = "\\mplibcode\nbeginfig(1);\npickup " .. normalPen .. ";\npath p,q;\n"
  local startPos = line.begin
  local endPos = line.begin + line.width
  local currentPos = startPos
  local previousLen = 0
  local nextLen = 0
  local path = nil
  local i = 1
  local firstShift = nil -- the kern we'll have to do before just printing the mplib
  local temp -- a stupid temporary value
  local first = 1 -- useful for a test (we can't test i because sometimes i == 2 the first time)
  local lastvpos = 3 -- here the default value is 3
  -- first we deal with the last point of the line:
  -- we add a point at min (lastpoint.pos + 20, endPos), except if it's the last line (TODO: check if it's the last line)
  table.insert(line.ictus, {['type'] = it, ['pos'] = math.min(line.ictus[table.maxn(line.ictus)].pos + 20, endPos)})
  -- then we set path to the good path section (see iait and friends for details path variable)
  -- we can't do a for .. in .. loop, because sometimes we have only one function for two or three ictus
  -- basically we draw the shape betwee line.ictus[i] and line.ictus[i+1] (or i+2 or 3)
  while line.ictus[i+1] do
    if line.ictus[i].type == it then
      if line.ictus[i+2] ~= nil then
        nextLen = line.ictus[i+2].pos  - line.ictus[i+1].pos
      else
        nextLen = 0
      end
      if line.ictus[i+1].type == ia then
        path, temp, vpos = grechiro.itia(line.ictus[i].pos, line.ictus[i+1].pos, previousLen, printSmallBars, lastvpos, nextLen)
      else
        path, temp, vpos = grechiro.itit(line.ictus[i].pos, line.ictus[i+1].pos, previousLen, printSmallBars, lastvpos, nextLen)
      end
      previousLen = 0
      i = i + 1
    else
      if line.ictus[i+1].type == it then
        if line.ictus[i+2] ~= nil then
          nextLen = line.ictus[i+2].pos  - line.ictus[i+1].pos
        else
          nextLen = 0
        end
        previousLen = (line.ictus[i+1].pos - line.ictus[i].pos)
        path, temp, vpos = grechiro.iait(line.ictus[i].pos, line.ictus[i+1].pos, 0, printSmallBars, lastvpos, nextLen)
        i = i + 1
      elseif line.ictus[i+2] ~= nil and line.ictus[i+2].type == it then
        if line.ictus[i+3] ~= nil then
          nextLen = line.ictus[i+3].pos  - line.ictus[i+2].pos
        else
          nextLen = 0
        end
        path, temp, vpos = grechiro.iaiait(line.ictus[i].pos, line.ictus[i+1].pos, line.ictus[i+2].pos, 0, printSmallBars, lastvpos, nextLen)
        previousLen = 0
        i = i + 2
      elseif line.ictus[i+2] ~= nil and line.ictus[i+3] ~= nil and line.ictus[i+2].type == ia then
        if line.ictus[i+3] ~= nil then
          nextLen = line.ictus[i+3].pos  - line.ictus[i+2].pos
        else
          nextLen = 0
        end
        path, temp, vpos = grechiro.iaiaiait(line.ictus[i].pos, line.ictus[i+1].pos, line.ictus[i+2].pos, line.ictus[i+3].pos, previousLen, printSmallBars, lastvpos, nextLen)
        previousLen = 0
        --path = iaiait
        i = i + 3
      end
    end
    lastvpos = vpos
    -- path contains something like p:= a .. path;
    -- and also something like draw the .. small .. path .. of .. the .. bar;
    if first == 1 then
      s = s .. path .. "q := p;\n"
      first = 0
    else
      s = s .. path .. "q := q & p;\n"
    end
    if firstShift == nil then
      -- we calculate the kern we'll have to make, in pt, and we do it
      -- temp is the difference between the point 0 of the metapost coordonate system and the effective beginning of the metapost figure (it can go in the negative corrdonates)
      -- line.ictus[1] is the position of the first ictus
      firstShift = line.ictus[1].pos - line.begin - temp
      temp = string.format("\\kern %fpt\n", firstShift)
      s = temp .. s
    end
  end
  s = s .. "draw q;\nendfig;\n\\endmplibcode\n"
  tex.print(s)
  -- texio.write_nl(s)
end

local printCLine = grechiro.printCLine

-- function that returns a string like "draw mypath;" where mypath is a small 
grechiro.printBar = grechiro.printBar or function (x,y)
  return string.format("draw (%.01f, %.01f){down} .. {down}(%.01f, %.01f) withpen " .. smallBarPen .. ";\n",
    x,
    y + 2,
    x,
    y - 2)
end

-- function that calculates the diameter of the first circle of ia (used in several functions)
grechiro.iaitfirstdiameter = grechiro.iaitfirstdiameter or function(ibegin, iend)
  return (10 + 0.35 * (iend - ibegin))
end

local iaitfirstdiameter = grechiro.iaitfirstdiameter

-- idem for the last angle
grechiro.iaitlastangle = grechiro.iaitlastangle or function (width)
  return (30 - 0.2 * (width))
end

local iaitlastangle = grechiro.iaitlastangle

grechiro.iait = grechiro.iait or function (ibegin, iend, first, printSmallBar, beginvpos, nextLen)
  local init_height
  if first == 1 then
    init_height = 0
  else
    init_height = 3
  end
  local path =  string.format("p := (%.01f, %.01f){left} .. {right}(%.01f, %.01f){right} .. {dir-%d}(%.01f,3);\n",
  ibegin,
  init_height,
  ibegin,
  init_height + iaitfirstdiameter(ibegin, iend),
  iaitlastangle (iend - ibegin), 
  iend)
  if printSmallBar == 1 then
    path = path .. grechiro.printBar(ibegin, 3)
  end
  -- we return path, and the left shift at the beginning (for the first of a line)
  return path, iaitfirstdiameter(ibegin, iend)/2
end

grechiro.iaiait = grechiro.iaiait or function (ibegin, imiddle, iend, first, printSmallBar, beginvpos, nextLen)
  local maxdiff-- a value we will use several times
  if imiddle - ibegin < iend - imiddle then
    maxdiff = (20 - (imiddle - ibegin))/2
  else
    maxdiff = (20 - (iend - imiddle))/2
  end
  -- the initial height
  local init_height
  if first == 1 then
    init_height = 0
  else
    init_height = 3
  end
  -- a variable we use several times
  local var1
  if imiddle - ibegin > 60 then
    var1 = 0
  else
    var1 = 20 - (imiddle - ibegin)/3
  end
  var1 = 0
  local path =  string.format("p := (%.01f, %.01f){left} .. {right}(%.01f, %.01f){right} .. {down}(%.01f, %.01f){down} .. {up}(%.01f, %.01f){up} .. {right}(%.01f,%.01f){right} .. {dir-%d}(%.01f,%.01f);\n",
  -- (%.01f, %.01f){left}
  ibegin,
  init_height,
  -- {right}(%.01f, %.01f){right}
  ibegin,
  24 + var1,
  -- {down}(%.01f, %.01f){down}
  imiddle+3,
  10 + maxdiff,
  -- {up}(%.01f, %.01f){up}
  imiddle-3,
  10 + maxdiff,
  -- {right}(%.01f,%.01f){right}
  imiddle + (iend - imiddle)/3,
  24 + var1,
  -- {dir-%d}(%.01f,%.01f)
  30,
  iend,
  3)
  if printSmallBar == 1 then
    path = path .. grechiro.printBar(ibegin, 3)
    path = path .. grechiro.printBar(imiddle, 7 + maxdiff)
  end
  return path, (24 + var1)/2
end

grechiro.iaiaiait = grechiro.iaiaiait or function (ibegin, imiddle1, imiddle2, iend, first, printSmallBar, beginvpos, nextLen)
  local maxdiff-- a value we will use several times
  maxdiff = math.max(imiddle1 - ibegin, imiddle2 - imiddle1, iend - imiddle2)
  maxdiff = 20 - maxdiff/2
  local init_height
  if first == 1 then
    init_height = 0
  else
    init_height = 3
  end
  local path =  string.format("p := (%.01f, %.01f){left} .. {right}(%.01f, %.01f){right} .. {down}(%.01f, %.01f){down} .. {up}(%.01f, %.01f){up} .. {right}(%.01f,%.01f){right} .. {down}(%.01f,%.01f){down} .. {up}(%.01f, %.01f){up} .. {right}(%.01f,%.01f){right} .. {dir-%d}(%.01f,%.01f);\n",
  -- (%.01f, %.01f){left}
  ibegin,
  init_height,
  -- {right}(%.01f, %.01f){right}
  ibegin,
  24 + (20 - (imiddle1 - ibegin))/3,
  -- {down}(%.01f, %.01f){down}
  imiddle1+3,
  10 + maxdiff,
  -- {up}(%.01f, %.01f){up}
  imiddle1-3,
  10 + maxdiff,
  -- {right}(%.01f,%.01f){right}
  imiddle1 + (imiddle2 - imiddle1)/3,
  24 + (20 - (imiddle1 - ibegin))/3,
  -- {down}(%.01f,%.01f){down}
  imiddle2+3,
  10 + maxdiff,
  -- {up}(%.01f, %.01f){up}
  imiddle2-3,
  10 + maxdiff,
  --{right}(%.01f,%.01f){right}
  imiddle2 + (iend - imiddle2)/3,
  24 + (20 - (imiddle2 - imiddle1))/3,
  -- {dir-%d}(%.01f,%.01f)
  30,
  iend,
  3)
  if printSmallBar == 1 then
    path = path .. grechiro.printBar(ibegin, 3)
    path = path .. grechiro.printBar(imiddle1, 7 + maxdiff)
    path = path .. grechiro.printBar(imiddle2, 7 + maxdiff)
  end
  return path, (24 + (20 - (imiddle1 - ibegin))/3)/2
end

grechiro.itia = grechiro.itia or function (ibegin, iend, previouslen, printSmallBar, beginvpos, nextLen)
  local path = string.format("p := (%.01f, 3){dir-%d} .. {dir30}(%.01f, 3);\n",
  ibegin,
  iaitlastangle (previouslen),
  iend)
  if printSmallBar == 1 then
    path = path .. grechiro.printBar(ibegin, 3)
  end
  return path, 0
end

grechiro.itit = grechiro.itit or function (ibegin, iend, previouslen, printSmallBar, beginvpos, nextLen)
  local path = string.format("p := (%.01f, 3){dir-%d} .. {dir-30}(%.01f, 3);\n",
  ibegin,
  iaitlastangle (previouslen),
  iend)
  if printSmallBar == 1 then
    path = path .. grechiro.printBar(ibegin, 3)
  end
  return path, 0
end

end
