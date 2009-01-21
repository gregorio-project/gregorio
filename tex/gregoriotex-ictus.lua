chiroCurrentLine = chiroCurrentLine or 1
chiroCurrentScore = chiroCurrentScore or 0
chiroList = chiroList or nil
local ia=0
local it=1

--dofile(table.lua)

--[[

The list of ictus is like this:

chiro_list: scores(list)
score: lines(list)
line: begin, width, ictus(list)
ictus: type, pos

]]


-- we work in pt in this file

function atBeginChiroScore()
  -- as we call this function at each score beginning, we don't rebuild the list each time
  if chiroList == nil then
    chiroCreateList()
  end
  chiroCurrentScore = chiroCurrentScore + 1
  chiroCurrentLine = 1
end

function chiroCreateList()
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
        if chiroList == nil then
          chiroList = {}
          chiroList.scores={}
        end
        currentScoreBeginPos = pos
        if currentScore ~= nil then
          table.insert(chiroList.scores, currentScore)
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
    table.insert(chiroList.scores, currentScore)
  end
  io.close(f)
  --printTable(chiroList, '')
  return true
end

-- function called in the TeX Code, calls ChiroPrintCLine with the good line
function chiroPrintLine()
  if chiroList == nil or chiroCurrentScore > table.maxn(chiroList.scores) then
    return
  elseif chiroCurrentLine > table.maxn(chiroList.scores[chiroCurrentScore].lines) then
    texio.write_nl('linea' .. chiroCurrentLine)
    texio.write_nl('lineg' .. chiroCurrentScore)
    texio.write_nl('scoreg' .. table.maxn(chiroList.scores[chiroCurrentScore].lines))
    -- if there are too many calls in a score
    return
  elseif table.maxn(chiroList.scores) < chiroCurrentScore  or chiroCurrentScore == 0 then
    texio.write_nl('lineb' .. chiroCurrentLine)
    -- a basic check
    return
  else
    --printTable(chiroList.scores[chiroCurrentScore].lines[chiroCurrentLine], '')
    texio.write_nl('linec' .. chiroCurrentLine)
    chiroPrintCLine (chiroList.scores[chiroCurrentScore].lines[chiroCurrentLine])
    chiroCurrentLine = chiroCurrentLine + 1
  end
end

function printTable(table, s)
  if table == {} or table == nil then
    return
  end
  for k,v in pairs(table) do
    texio.write_nl(s .. 'key : ' .. k)
    if type(v) == 'table' then
      texio.write_nl(s .. "table : ")
      printTable(v, s .. ' ')
    else
      texio.write_nl(s .. 'value : ' .. v)
    end
  end
end

function chiroPrintCLine (line)
  -- just to know if we print small bars or not
  printSmallBars = tex.count.printchirovbars
  --printTable(line, '')
  if line == nil then
    return
  end
  local s = "\\mplibcode\nbeginfig(1);\npickup pencircle xscaled 1 yscaled 0.5 rotated 30;\npath p,q;\n"
  local startPos = line.begin
  local endPos = line.begin + line.width
  local currentPos = startPos
  local previousLen = 0
  local path = nil
  local i = 1
  local firstShift = nil -- the kern we'll have to do before just printing the mplib
  local temp -- a stupid temporary value
  local first = 1 -- useful for a test (we can't test i because sometimes i == 2 the first time)
  -- first we deal with the last point of the line:
  -- we add a point at min (lastpoint.pos + 20, endPos), except if it's the last line (TODO: check if it's the last line)
  table.insert(line.ictus, {['type'] = it, ['pos'] = math.min(line.ictus[table.maxn(line.ictus)].pos + 20, endPos)})
  -- then we set path to the good path section (see iait and friends for details path variable
  -- we can't do a for in loop, because sometimes we have only one function for two or three ictus
  while line.ictus[i+1] do
    if line.ictus[i].type == it then
      if line.ictus[i+1].type == ia then
        path, temp = itia(line.ictus[i].pos, line.ictus[i+1].pos, previousLen, printSmallBars)
      else
        path, temp = itit(line.ictus[i].pos, line.ictus[i+1].pos, previousLen, printSmallBars)
      end
      previousLen = 0
      i = i + 1
    else
      if line.ictus[i+1].type == it then
        previousLen = (line.ictus[i+1].pos - line.ictus[i].pos)
        path, temp = iait(line.ictus[i].pos, line.ictus[i+1].pos, 0, printSmallBars)
        i = i + 1
      else
        path, temp = itit(line.ictus[i].pos, line.ictus[i+1].pos, previousLen, printSmallBars)
        previousLen = 0
        --path = iaiait
        i = i + 1
      end
    end
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
  texio.write_nl(s)
end

-- function that returns a string like "draw mypath;" where mypath is a small 
function chiroPrintBar (x,y)
  return string.format("draw (%d, %d){down} .. {down}(%d, %d);\n",
    x,
    y + 2,
    x,
    y - 2)
end

-- function that calculates the diameter of the first circle of ia (used in several functions)
function iaitfirstdiameter (ibegin, iend)
  return (10 + 0.35 * (iend - ibegin))
end

-- idem for the last angle
function iaitlastangle (width)
  return (30 - 0.2 * (width))
end

function iait (ibegin, iend, first, printSmallBar)
  local init_height
  if first == 1 then
    init_height = 0
  else
    init_height = 3
  end
  local path =  string.format("p := (%d, %d){left} .. {right}(%d, %d){right} .. {dir-%d}(%d,3);\n",
  ibegin,
  init_height,
  ibegin,
  init_height + iaitfirstdiameter(ibegin, iend),
  iaitlastangle (iend - ibegin), 
  iend)
  if printSmallBar == 1 then
    path = path .. chiroPrintBar(ibegin, 3)
  end
  -- we return path, and the left shift at the beginning (for the first of a line)
  return path, iaitfirstdiameter(ibegin, iend)/2
end

function iaiait (ibegin, imiddle, iend, first, printSmallBar)
  local maxdiff-- a value we will use several times
  if imiddle - ibegin < iend - imiddle then
    maxdiff = (20 - (imiddle - ibegin))/2
  else
    maxdiff = (20 - (iend - imiddle))/2
  end
  local init_height
  if first == 1 then
    init_height = 0
  else
    init_height = 3
  end
  local path =  string.format("p := (%d, %d){left} .. {right}(%d, %.01f){right} .. {down}(%d, %.01f){down} .. {up}(%d, %.01f){up} .. {right}(%d,%.01f){right} .. {dir-%d}(%d,%d);\n",
  ibegin,
  init_height,
  ibegin,
  27 + (20 - (imiddle - ibegin))/4,
  imiddle+3,
  13 + maxdiff,
  imiddle-3,
  13 + maxdiff,
  imiddle + (iend - imiddle)/3,
  27 + (20 - (imiddle - ibegin))/4,
  30,
  iend,
  3)
  if printSmallBar == 1 then
    path = path .. chiroPrintBar(ibegin, 3)
  end
  return path, 0
end

function itia (ibegin, iend, previouslen, printSmallBar)
  local path = string.format("p := (%d, 3){dir-%d} .. {dir30}(%d, 3);\n",
  ibegin,
  iaitlastangle (previouslen),
  iend)
  if printSmallBar == 1 then
    path = path .. chiroPrintBar(ibegin, 3)
  end
  return path, 0
end

function itit (ibegin, iend, previouslen, printSmallBar)
  local path = string.format("p := (%d, 3){dir-%d} .. {dir-30}(%d, 3);\n",
  ibegin,
  iaitlastangle (previouslen),
  iend)
  if printSmallBar == 1 then
    path = path .. chiroPrintBar(ibegin, 3)
  end
  return path, 0
end
