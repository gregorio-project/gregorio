-- Script to build gregoriotex-fontmapping.tex
copyright = [[
% Copyright (C) 2015 The Gregorio Project (see CONTRIBUTORS.md)
%
% This file is part of Gregorio.
%
% Gregorio is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% Gregorio is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with Gregorio.  If not, see <http://www.gnu.org/licenses/>.
]]

local function capitalize(first, rest)
  return first:upper() .. rest
end

local function emit_font_mapping(font)
  local font_info = fontloader.open(font .. '.ttf')
  local i = 0
  while i < font_info.glyphmax do
    local glyph = font_info.glyphs[i]
    if glyph and glyph.unicode >= 0 then
      if glyph_names[glyph.unicode] == nil then
        file:write(string.format([[\chardef\grecp%s=%d\relax ]], glyph.name, glyph.unicode), '%\n')
        glyph_names[glyph.unicode] = glyph.name
      elseif glyph_names[glyph.unicode] ~= glyph.name then
        io.stderr:write(string.format('mismatched glyph %s:%s\n', font, glyph.name))
        os.exit(false)
      end
    end
    i = i + 1
  end
end

glyph_names = {}
file = io.open('gregoriotex-fontmapping.tex', 'w')

file:write('% Glyph mapping for GregorioTeX\n')
file:write('%\n')
file:write(copyright)
file:write('\n')
file:write([[\gre@declarefileversion{gregoriotex-fontmapping.tex}{3.0.0-rc2}]], '\n') -- GREGORIO_VERSION
file:write('\n')

emit_font_mapping('greciliae')
emit_font_mapping('gregorio')
emit_font_mapping('parmesan')

os.exit(true)
