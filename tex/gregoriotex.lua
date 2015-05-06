--GregorioTeX Lua file.
--
--Copyright (C) 2008-2015 The Gregorio Project (see CONTRIBUTORS.md)
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

-- this file contains lua functions used by GregorioTeX when called with LuaTeX.

local hpack, traverse_id, has_attribute, count, remove, insert_after, copy = node.hpack, node.traverse_id, node.has_attribute, node.count, node.remove, node.insert_after, node.copy

gregoriotex = gregoriotex or {}
local gregoriotex = gregoriotex

local internalversion = '3.0.0-rc2' -- GREGORIO_VERSION (comment used by VersionManager.py)

local err, warn, info, log = luatexbase.provides_module({
    name               = "gregoriotex",
    version            = '3.0.0-rc2', -- GREGORIO_VERSION
    greinternalversion = internalversion,
    date               = "2015/05/04", -- GREGORIO_DATE_LTX
    description        = "GregorioTeX module.",
    author             = "The Gregorio Project (see CONTRIBUTORS.md)",
    copyright          = "2008-2015 - The Gregorio Project",
    license            = "GPLv3+",
})

local hlist = node.id('hlist')
local vlist = node.id('vlist')
local glyph = node.id('glyph')

local hyphen = tex.defaulthyphenchar or 45 

local gregorioattr         = luatexbase.attributes['gregorioattr']
local potentialdashvalue   = 1
local nopotentialdashvalue = 2

local gregoriocenterattr = luatexbase.attributes['gregoriocenterattr']
local startcenter = 1
local endcenter   = 2

local score_fonts = {}
local symbol_fonts = {}
local loaded_font_sizes = {}
local next_variant = 0
local variant_prefix = 'greVariantFont'
local number_to_letter = {
    ['0'] = 'A', ['1'] = 'B', ['2'] = 'C', ['3'] = 'D', ['4'] = 'E',
    ['5'] = 'F', ['6'] = 'G', ['7'] = 'H', ['8'] = 'I', ['9'] = 'J',
}

-- node factory
local tmpnode = node.new(glyph, 0)
tmpnode.font = 0
tmpnode.char = hyphen
local function gethyphennode()
  return copy(tmpnode)
end

local function getdashnnode()
  local hyphnode = gethyphennode()
  local dashnode = hpack(hyphnode)
  dashnode.shift = 0
  return dashnode,hyphnode
end

local function center_translation(startnode, endnode, ratio, sign, order)
  -- total width between beginning the two centering points
  local total_width = node.dimensions(ratio, sign, order, startnode, endnode)
  -- definition of translation with a beginning is:
  --  \hbox to 0pt{
  --    \kern 0pt
  --    \vbox to 0pt{
  --      \vss\hbox to 0pt{
  --        translation\hss
  --      }
  --    }
  --    \kern 0pt
  --  }
  -- 
  -- hence translation width is:
  local trans_width = node.dimensions(startnode.head.next.head.next.head)
  -- now we must transform the kern 0pt into kern Xpt and kern -Xpt where X is:
  local X = (total_width - trans_width) / 2
  startnode.head.kern = X
  startnode.head.next.next.kern = -X
end

-- in each function we check if we really are inside a score, 
-- which we can see with the gregorioattr being set or not
local function process (h, groupcode, glyphes)
  -- TODO: to be changed according to the font
  local lastseennode    = nil
  local adddash         = false
  local currentfont     = 0
  local currentshift    = 0
  local centerstartnode = nil
  -- we explore the lines
  for line in traverse_id(hlist, h) do
    if has_attribute(line, gregorioattr) then
      -- the next two lines are to remove the dumb lines
      if count(hlist, line.head) <= 2 then
	h, line = remove(h, line)
      else
	centerstartnode = nil
	for n in traverse_id(hlist, line.head) do
	  if has_attribute(n, gregoriocenterattr, startcenter) then
	    centerstartnode = n
	  elseif has_attribute(n, gregoriocenterattr, endcenter) then
	    if not centerstartnode then
	      warn("End of a translation centering area encountered on a\nline without translation centering beginning,\nskipping translation...")
	    else
	      center_translation(centerstartnode, n, line.glue_set, line.glue_sign, line.glue_order)
	    end
	  elseif has_attribute(n, gregorioattr, potentialdashvalue) then
	    adddash=true
	    lastseennode=n
	    currentfont = 0
	    -- we traverse the list, to detect the font to use,
	    -- and also not to add an hyphen if there is already one
	    for g in node.traverse_id(glyph, n.head) do
	      if currentfont == 0 then
		currentfont = g.font
	      end
	      if g.char == hyphen or g.char == 45 then
		adddash = false
	      end
	    end
	    if currentshift == 0 then
	      currentshift = n.shift
	    end
	    -- if we encounter a text that doesn't need a dash, we acknowledge it
	  elseif has_attribute(n, gregorioattr, nopotentialdashvalue) then
	    adddash=false
	  end
	end
	if adddash==true then
	  local dashnode, hyphnode = getdashnnode()
	  dashnode.shift = currentshift
	  hyphnode.font = currentfont
	  insert_after(line.head, lastseennode, dashnode)
	  addash=false
	end
      end
      -- we reinitialize the shift value, because it may change according to the line
      currentshift=0
    end
  end
  -- due to special cases, we don't return h here (see comments in bug #20974)
  return true
end 

-- In gregoriotex, hyphenation is made by the process function, so TeX hyphenation
-- is just a waste of time. This function will be registered in the hyphenate
-- callback to skip this step and thus gain a little time.
local function disable_hyphenation()
  return false
end

local function atScoreBeggining ()
  luatexbase.add_to_callback('post_linebreak_filter', process, 'gregoriotex.callback', 1)
  luatexbase.add_to_callback("hyphenate", disable_hyphenation, "gregoriotex.disable_hyphenation", 1)
end

local function atScoreEnd ()
  luatexbase.remove_from_callback('post_linebreak_filter', 'gregoriotex.callback')
  luatexbase.remove_from_callback("hyphenate", "gregoriotex.disable_hyphenation")
end

local function clean_old_gtex_files(file_withdir)
  local filename = ""
  local dirpath = ""
  local sep = ""
  local onwindows = os.type == "windows" or
    string.find(os.getenv("PATH"),";",1,true)
  if onwindows then
    sep = "\\"
    dirpath = string.match(file_withdir, "(.*)"..sep)
  else
    sep = "/"
    dirpath = string.match(file_withdir, "(.*)"..sep)
  end
  if dirpath then -- dirpath is nil if current directory
    filename = "^"..file_withdir:match(".*/".."(.*)").."%-%d+_%d+_%d+[-%a%d]*%.gtex$"
    for a in lfs.dir(dirpath) do
      if a:match(filename) then
	os.remove(dirpath..sep..a)
      end
    end
  else
    filename = "^"..file_withdir.."%-%d+_%d+_%d+[-%a%d]*%.gtex$"
    for a in lfs.dir(lfs.currentdir()) do
      if a:match(filename) then os.remove(a) end
    end
  end
end

local function compile_gabc(gabc_file, gtex_file)
  info("compiling the score %s...", gabc_file)
  res = os.execute(string.format("gregorio -o %s %s", gtex_file, gabc_file))
  if res == nil then
    err("\nSomething went wrong when executing\n    'gregorio -o %s %s'.\n"
    .."shell-escape mode may not be activated. Try\n\n%s --shell-escape %s.tex\n\nSee the documentation of gregorio or your TeX\ndistribution to automatize it.", gtex_file, gabc_file, tex.formatname, tex.jobname)
  elseif res ~= 0 then
    err("\nAn error occured when compiling the score file\n'%s' with gregorio.\nPlease check your score file.", gabc_file)
  else
    -- open the gtex file for writing so that LuaTeX records output to it
    -- when the -recorder option is used
    local gtex = io.open(gtex_file, 'a')
    if gtex == nil then
      err("\n Unable to open %s", gtex_file)
    else
      gtex:close()
    end
  end
end

local function include_score(input_file, force_gabccompile)
  local file_root
  if string.match(input_file:sub(-5), '%.gtex') then
    file_root = input_file:sub(1,-6)
  elseif string.match(input_file:sub(-4), '%.tex') then
    file_root = input_file:sub(1,-5)
  elseif string.match(input_file:sub(-5), '%.gabc') then
    file_root = input_file:sub(1,-6)
  elseif not file_root then
    file_root = input_file
  end
  local gtex_file = file_root.."-"..internalversion:gsub("%.", "_")..".gtex"
  local gabc_file = file_root..".gabc"
  if not lfs.isfile(gtex_file) then
    clean_old_gtex_files(file_root)
    log("The file %s does not exist. Searching for a gabc file", gtex_file)
    if lfs.isfile(gabc_file) then
      local gabc = io.open(gabc_file, 'r')
      if gabc == nil then
        err("\n Unable to open %s", gabc_file)
        return
      else
        gabc:close()
      end
      compile_gabc(gabc_file, gtex_file)
      tex.print(string.format("\\input %s", gtex_file))
      return
    else
      err("The file %s does not exist.", gabc_file)
      return
    end
  end
  local gtex_timestamp = lfs.attributes(gtex_file).modification
  local gabc_timestamp = lfs.attributes(gabc_file).modification
  -- open the gabc file for reading so that LuaTeX records input from it
  -- when the -recorder option is used; do this here so that this happens
  -- on every run
  local gabc = io.open(gabc_file, 'r')
  if gabc == nil then
    err("\n Unable to open %s", gabc_file)
  else
    gabc:close()
  end
  if gtex_timestamp < gabc_timestamp then
    log("%s has been modified and %s needs to be updated. Recompiling the gabc file.", gabc_file, gtex_file)
    compile_gabc(gabc_file, gtex_file)
  elseif force_gabccompile then
    compile_gabc(gabc_file, gtex_file)
  end
  tex.print(string.format("\\input %s", gtex_file))
  return
end

local function direct_gabc(gabc, header)
  tmpname = os.tmpname()
  local p = io.popen('gregorio -s -o '..tmpname, 'w')
  if p == nil then
    err("\nSomething went wrong when executing\n    gregorio -s -o "..tmpname..".\n"
    .."shell-escape mode may not be activated. Try\n\n%s --shell-escape %s.tex\n\nSee the documentation of gregorio or your TeX\ndistribution to automatize it.", tex.formatname, tex.jobname)
  end
  p:write('name:direct-gabc;\n'..(header or '')..'\n%%%%\n'..gabc)
  p:close()
  f = io.open(tmpname)
  tex.print(f:read("*a"):explode('\n'))
  f:close()
  os.remove(tmpname)
end

local function check_font_version()
  local gregoriofont = font.getfont(font.id('gregoriofont'))
  local fontversion = gregoriofont.shared.rawdata.metadata.version
  if fontversion ~= internalversion then
    fontname = gregoriofont.shared.rawdata.metadata.fontname
    fontfile = gregoriofont.shared.rawdata.metadata.origname
    err("\nUncoherent file versions!\ngregoriotex.tex is version %s\nwhile %s.ttf is version %s\nplease update file\n%s", internalversion, fontname, fontversion, fontfile)
  end
end

local function get_gregorioversion()
  return internalversion
end

local function map_font(name, prefix)
  log("Mapping font %s", name)
  local glyph, unicode
  for glyph, unicode in pairs(font.fonts[font.id(score_fonts[name])].resources.unicodes) do
    if unicode >= 0 and not string.match(glyph, '%.') then
      tex.sprint(string.format([[\xdef\gre%s%s{\char%d}]], prefix, glyph, unicode))
    end
  end
end

local function init_variant_font(font_name, for_score)
  if font_name ~= '*' then
    local font_table = for_score and score_fonts or symbol_fonts
    if font_table[font_name] == nil then
      local font_csname = variant_prefix..string.gsub(tostring(next_variant), '[0-9]', number_to_letter)
      font_table[font_name] = font_csname
      log("Registering variant font %s as %s.", font_name, font_csname)
      if for_score then
        tex.print(string.format([[\global\font\%s = {name:%s} at 10 sp\relax ]], font_csname, font_name))
        -- loaded_font_sizes will only be given a value if the font is for_score
        loaded_font_sizes[font_name] = '10'
      else
        -- is there a nice way to make this string readable?
        tex.print(string.format(
            [[\gdef\%sSymReload#1{{\edef\localsize{#1}\ifx\localsize\%sSymSize\relax\relax\else\global\font\%s = {name:%s} at \localsize pt\relax\xdef\%sSymSize{\localsize}\fi}}\xdef\%sSymSize{0}\%sSymReload{\gresymbolfontsize}]],
            font_csname, font_csname, font_csname, font_name, font_csname,
            font_csname, font_csname))
      end
      next_variant = next_variant + 1
    end
  end
end

local function set_score_glyph(csname, font_csname, char)
  log([[Setting \%s to \%s\char%d]], csname, font_csname, char)
  tex.print(string.format([[\edef\%s{{\noexpand\%s\char%d}}]], csname, font_csname, char))
end

local function set_common_score_glyph(csname, font_csname, char)
  -- font_csname is ignored
  log([[Setting \%s to \char%d]], csname, char)
  tex.print(string.format([[\edef\%s{{\char%d}}]], csname, char))
end

local function set_symbol_glyph(csname, font_csname, char)
  tex.print(string.format([[\def\%s{\%sSymReload{\gresymbolfontsize}{\%s\char%d}\relax}]],
      csname, font_csname, font_csname, char))
end

local function set_sized_symbol_glyph(csname, font_csname, char)
  tex.print(string.format([[\gdef\%s#1{\%sSymReload{#1}{\%s\char%d}\relax}]],
      csname, font_csname, font_csname, char))
end

local function def_glyph(csname, font_name, glyph, font_table, setter)
  local font_csname = font_table[font_name]
  local char
  if string.match(glyph, '^%d+$') then
    char = tonumber(glyph)
  else
    local font_id = font.id(font_csname)
    if font_id < 0 then
      err('\nFont %s is not defined.', font_name)
    end
    char = font.fonts[font_id].resources.unicodes[glyph]
    if char == nil then
      err('\nGlyph %s in font %s was not found.', glyph, font_name)
    end
  end
  setter(csname, font_csname, char)
end

local function change_single_score_glyph(glyph_name, font_name, replacement)
  if font_name == '*' then
    def_glyph('grecp'..glyph_name, 'greciliae', replacement, score_fonts,
        set_common_score_glyph)
  else
    def_glyph('grecp'..glyph_name, font_name, replacement, score_fonts,
        set_score_glyph)
  end
end

local function change_score_glyph(glyph_name, font_name, replacement)
  if string.match(glyph_name, '%*') then
    glyph_name = '^'..glyph_name:gsub('%*', '.*')..'$'
    if not string.match(replacement, '^%.') then
      err('If a wildcard is supplied for glyph name, replacement must start with a dot.')
    end
    local greciliae = font.fonts[font.id(score_fonts['greciliae'])].resources.unicodes
    local other_font
    if font_name == '*' then
      other_font = greciliae
    else
      other_font = font.fonts[font.id(score_fonts[font_name])].resources.unicodes
    end
    local name, char
    for name, char in pairs(greciliae) do
      if not string.match(name, '%.') and char >= 0 and string.match(name, glyph_name) then
        local matched_replacement = name..replacement
        if other_font[matched_replacement] ~= nil and other_font[matched_replacement] >= 0 then
          change_single_score_glyph(name, font_name, matched_replacement)
        end
      end
    end
  else
    if string.match(replacement, '^%.') then
      replacement = glyph_name..replacement
    end
    change_single_score_glyph(glyph_name, font_name, replacement)
  end
end

local function reset_score_glyph(glyph_name)
  if string.match(glyph_name, '%*') then
    glyph_name = '^'..glyph_name:gsub('%*', '.*')..'$'
    local name, char
    for name, char in pairs(font.fonts[font.id(score_fonts['greciliae'])].resources.unicodes) do
      if not string.match(name, '%.') and char >= 0 and string.match(name, glyph_name) then
        set_common_score_glyph('grecp'..name, nil, char)
      end
    end
  else
    local font_csname = score_fonts['greciliae']
    local char = font.fonts[font.id(font_csname)].resources.unicodes[glyph_name]
    if char == nil then
      err('\nGlyph %s was not found.', glyph_name)
    end
    set_common_score_glyph('grecp'..glyph_name, nil, char)
  end
end

local function scale_score_fonts(size)
  for font_name, font_csname in pairs(score_fonts) do
    if loaded_font_sizes[font_name] and loaded_font_sizes[font_name] ~= size then
      tex.print(string.format([[\global\font\%s = {name:%s} at %s sp\relax ]],
          font_csname, font_name, size))
      loaded_font_sizes[font_name] = size
    end
  end
end

local function def_symbol(csname, font_name, glyph, sized)
  def_glyph(csname, font_name, glyph, symbol_fonts,
      sized and set_sized_symbol_glyph or set_symbol_glyph)
end

local function font_size()
  tex.print(string.format('%.2f', (font.fonts[font.current()].size / 65536.0)))
end

gregoriotex.include_score        = include_score
gregoriotex.compile_gabc         = compile_gabc
gregoriotex.atScoreEnd           = atScoreEnd
gregoriotex.atScoreBeggining     = atScoreBeggining
gregoriotex.check_font_version   = check_font_version
gregoriotex.get_gregorioversion  = get_gregorioversion
gregoriotex.map_font             = map_font
gregoriotex.init_variant_font    = init_variant_font
gregoriotex.change_score_glyph   = change_score_glyph
gregoriotex.reset_score_glyph    = reset_score_glyph
gregoriotex.scale_score_fonts    = scale_score_fonts
gregoriotex.def_symbol           = def_symbol
gregoriotex.font_size            = font_size
gregoriotex.direct_gabc          = direct_gabc
