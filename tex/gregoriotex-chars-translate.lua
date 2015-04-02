#!/usr/bin/env texlua
--GregorioTeX Lua file.
--
--Copyright (C) 2014-2015 The Gregorio Project (see CONTRIBUTORS.md)
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

infile = io.open("gregoriotex-chars.tex.in");
outfile = io.open("gregoriotex-chars.tex", 'w');

charrangestart = 161

for line in infile:lines() do
  newline = line
  if (string.sub(line,1,1)~='%') then
    newline = string.gsub(line, '([0-9]+)', function(match)
        return match+charrangestart
      end)
  end
  outfile:write(newline.."\n")
end

infile:close()
outfile:close()
