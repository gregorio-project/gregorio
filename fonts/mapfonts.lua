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

tex_glyphs = {
  DivisioMaior = 'divisiomaior',
  Virgula = 'virgula',
  DivisioMinima = 'divisiominima',
  DivisioMinor = 'divisiominor',
  DivisioDominican = 'divisiodominican',
  DivisioDominicanAlt = 'divisiodominicanalt',
  PunctumCavum = 'punctumcavum',
  LineaPunctumCavum = 'lineapunctumcavum',
  PunctumCavumHole = 'punctumcavumhole',
  LineaPunctumCavumHole = 'lineapunctumcavumhole',
  PunctumCavumAlt = 'punctumcavumalt',
  LineaPunctumCavumAlt = 'lineapunctumcavumalt',
  PunctumCavumAltHole = 'punctumcavumholealt',
  LineaPunctumCavumAltHole = 'lineapunctumcavumholealt',
  PunctumDeminutus = 'smallpunctum',
  Punctum = 'punctum',
  PunctumInclinatum = 'punctuminclinatum',
  Stropha = 'stropha',
  StrophaAucta = 'strophaaucta',
  Quilisma = 'quilisma',
  Oriscus = 'oriscus',
  OriscusReversus = 'oriscusauctus',
  PunctumInclinatumAuctus = 'punctuminclinatumdem',
  LineaPunctum = 'lineapunctum',
  PunctumForMeasurement = 'peshigh',
  PesQuadratum_2_InitioDebilisDescendens = 'pesinitauctus',
  PesQuadratum_1_InitioDebilisDescendens = 'pesinitauctusone',
  PesQuadratumLongqueue_3_Nothing = 'flexus',
  PesQuadratumLongqueue_1_Nothing = 'flexusone',
  Flexus_2_Deminutus = 'flexusdeminutus',
  FlexusNobar_1_Nothing = 'flexusaltone',
  FlexusNobar_2_Nothing = 'flexusalt',
  Torculus_1_2_Nothing = 'torculus',
  Torculus_2_2_Deminutus = 'torculusdeminutus',
  Porrectus_1_1_Nothing = 'porrectus@one',
  Porrectus_2_1_Nothing = 'porrectus@two',
  Porrectus_3_1_Nothing = 'porrectus@three',
  Porrectus_4_1_Nothing = 'porrectus@four',
  Porrectus_5_1_Nothing = 'porrectus@five',
  CurlyBrace = 'curlybrace',
  BarBrace = 'barbrace',
  RoundBrace = 'brace',
  Linea = 'linea',
  VEpisemus = 'vepisemus',
  Accentus = 'accentus',
  Semicirculus = 'semicirculus',
  Circulus = 'circulus',
  AccentusReversus = 'reversedaccentus',
  SemicirculusReversus = 'reversedsemicirculus',
  HEpisemusPunctum = 'he@punctum',
  HEpisemusFlexusDeminutus = 'he@flexus',
  HEpisemusDebilis = 'he@initio',
  HEpisemusInclinatum = 'he@inclinatum',
  HEpisemusInclinatumDeminutus = 'he@inclinatumdem',
  HEpisemusStropha = 'he@stropha',
  HEpisemusPorrectus_1 = 'he@porrectus@one',
  HEpisemusPorrectus_2 = 'he@porrectus@two',
  HEpisemusPorrectus_3 = 'he@porrectus@three',
  HEpisemusPorrectus_4 = 'he@porrectus@four',
  HEpisemusPorrectus_5 = 'he@porrectus@five',
  HEpisemusPorrectusFlexus_1 = 'he@porrectusfl@one',
  HEpisemusPorrectusFlexus_2 = 'he@porrectusfl@two',
  HEpisemusPorrectusFlexus_3 = 'he@porrectusfl@three',
  HEpisemusPorrectusFlexus_4 = 'he@porrectusfl@four',
  HEpisemusPorrectusFlexus_5 = 'he@porrectusfl@five',
  HEpisemusQuilisma = 'he@quilisma',
  HEpisemusOriscus = 'he@oriscus',
  HEpisemusHighPes = 'he@smallpunctum',
  Flat = 'flat',
  FlatHole = 'flathole',
  Natural = 'natural',
  NaturalHole = 'naturalhole',
  Sharp = 'sharp',
  SharpHole = 'sharphole',
  CClef = 'cclef',
  FClef = 'fclef',
  CClefChange = 'incclef',
  FClefChange = 'infclef',
  AuctumMora = 'punctummora',
  CustosUpLong = 'custotoplong',
  CustosUpShort = 'custotopshort',
  CustosUpMedium = 'custotopmiddle',
  CustosDownLong = 'custobottomlong',
  CustosDownShort = 'custobottomshort',
  CustosDownMedium = 'custobottommiddle',
}

local function emit_font_mapping(font)
  local font_info = fontloader.open(font .. '.ttf')
  local i = 0
  while i < font_info.glyphmax do
    local glyph = font_info.glyphs[i]
    if glyph and glyph.unicode >= 0 then
      if glyph_names[glyph.unicode] == nil then
        local tex_glyph_name = tex_glyphs[glyph.name]
        if tex_glyph_name then
          texfile:write(string.format([[\chardef\gre@char@%s=%d\relax ]],
              tex_glyph_name, glyph.unicode), '%\n')
        end
        glyph_names[glyph.unicode] = glyph.name
      elseif glyph_names[glyph.unicode] ~= glyph.name then
        io.stderr:write(string.format('mismatched glyph %s:%s\n', font, glyph.name))
        os.exit(false)
      end
    end
    i = i + 1
  end
end

local function get(table, key)
  local tab = table[key]
  if not tab then
    tab = {}
    table[key] = tab
  end
  return tab
end

glyph_names = {}

texfile = io.open('gregoriotex-fontmapping.tex', 'w')
texfile:write('% Glyph mapping for GregorioTeX\n')
texfile:write('%\n')
texfile:write(copyright)
texfile:write('\n')
texfile:write([[\gre@declarefileversion{gregoriotex-fontmapping.tex}{3.0.0-rc2}]], '\n') -- GREGORIO_VERSION
texfile:write('\n')

emit_font_mapping('greciliae')
emit_font_mapping('gregorio')
emit_font_mapping('parmesan')

texfile:close()

c_copyright = copyright:gsub('%%', ' *')

cfile = io.open('gregoriotex-fontmapping.c', 'w')
cfile:write('/*\n')
cfile:write(' * Glyph mapping for GregorioTeX\n')
cfile:write(' *\n')
cfile:write(c_copyright)
cfile:write(' */\n')
cfile:write('\n')
cfile:write('#include "gregoriotex.h"\n')

hfile = io.open('gregoriotex-fontmapping.h', 'w')
hfile:write('/*\n')
hfile:write(' * Glyph mapping for GregorioTeX\n')
hfile:write(' *\n')
hfile:write(c_copyright)
hfile:write(' */\n')
hfile:write('\n')
hfile:write('#ifndef GREGORIOTEX_MAPPING_H\n')
hfile:write('#define GREGORIOTEX_MAPPING_H\n')
hfile:write('\n')
hfile:write('#include "gregoriotex.h"\n')
hfile:write('\n')

single = {}
two_note = {}
three_note = {}
four_note = {}

indices = { '1', '2', '3', '4', '5' }

for code_point, name in pairs(glyph_names) do
  local shape, amb1, amb2, amb3, liq
  shape, amb1, amb2, amb3, liq = name:match('^(%a+)_(%d)_(%d)_(%d)_(%a+)$')
  if shape then
    get(get(get(get(four_note, shape), liq), amb1), amb2)[amb3] = code_point
  else
    shape, amb1, amb2, liq = name:match('^(%a+)_(%d)_(%d)_(%a+)$')
    if shape then
      get(get(get(three_note, shape), liq), amb1)[amb2] = code_point
    else
      shape, amb1, liq = name:match('^(%a+)_(%d)_(%a+)$')
      if shape then
        get(get(two_note, shape), liq)[amb1] = code_point
      else
        single[name] = code_point
      end
    end
  end
end

for name, code_point in pairs(single) do
  hfile:write(string.format('#define CP_%s %d\n', name, code_point))
end
hfile:write('\n')

for shape, liqs in pairs(two_note) do
  hfile:write(string.format('const gtex_multinote_shape MNS_%s;\n', shape))

  cfile:write('\n')
  for liq, tab in pairs(liqs) do
    cfile:write(string.format(
        'static const int _%s_%s[MAX_AMBITUS] = { %d, %d, %d, %d, %d };\n',
        shape, liq, tab['1'], tab['2'], tab['3'], tab['4'], tab['5']))
  end
  cfile:write(string.format('static const struct gtex_multinote_shape _%s = {\n', shape));
  cfile:write('    .notes = 2,\n')
  cfile:write(string.format('    .name = "%s",\n', shape))
  for liq in pairs(liqs) do
    cfile:write(string.format('    .%s.two_note = _%s_%s,\n', liq, shape, liq))
  end
  cfile:write('};\n')
  cfile:write(string.format('const gtex_multinote_shape MNS_%s = &_%s;\n',
      shape, shape));
end

for shape, liqs in pairs(three_note) do
  hfile:write(string.format('const gtex_multinote_shape MNS_%s;\n', shape))

  cfile:write('\n')
  for liq, tab1 in pairs(liqs) do
    cfile:write(string.format('static const int _%s_%s[MAX_AMBITUS][MAX_AMBITUS] = {\n',
        shape, liq))
    for _, i in ipairs(indices) do
      tab = tab1[i]
      cfile:write(string.format('    { %d, %d, %d, %d, %d },\n',
          tab['1'], tab['2'], tab['3'], tab['4'], tab['5']))
    end
    cfile:write('};\n')
  end
  cfile:write(string.format('static const struct gtex_multinote_shape _%s = {\n', shape));
  cfile:write('    .notes = 3,\n')
  cfile:write(string.format('    .name = "%s",\n', shape))
  for liq in pairs(liqs) do
    cfile:write(string.format('    .%s.three_note = _%s_%s,\n', liq, shape, liq))
  end
  cfile:write('};\n')
  cfile:write(string.format('const gtex_multinote_shape MNS_%s = &_%s;\n',
      shape, shape));
end

for shape, liqs in pairs(four_note) do
  hfile:write(string.format('const gtex_multinote_shape MNS_%s;\n', shape))

  cfile:write('\n')
  for liq, tab1 in pairs(liqs) do
    cfile:write(string.format(
        'static const int _%s_%s[MAX_AMBITUS][MAX_AMBITUS][MAX_AMBITUS] = {\n',
        shape, liq))
    for _, i in ipairs(indices) do
      tab2 = tab1[i]
      cfile:write('   {\n')
      for _, j in ipairs(indices) do
        tab = tab2[j]
        cfile:write(string.format('        { %d, %d, %d, %d, %d },\n',
            tab['1'], tab['2'], tab['3'], tab['4'], tab['5']))
      end
      cfile:write('    },\n')
    end
    cfile:write('};\n')
  end
  cfile:write(string.format('static const struct gtex_multinote_shape _%s = {\n', shape));
  cfile:write('    .notes = 4,\n')
  cfile:write(string.format('    .name = "%s",\n', shape))
  for liq, tab1 in pairs(liqs) do
    cfile:write(string.format('    .%s.four_note = _%s_%s,\n', liq, shape, liq))
  end
  cfile:write('};\n')
  cfile:write(string.format('const gtex_multinote_shape MNS_%s = &_%s;\n',
      shape, shape));
end

hfile:write('\n')
hfile:write('#endif\n')
hfile:close()

cfile:close()

os.exit(true)
