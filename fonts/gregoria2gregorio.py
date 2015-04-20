#!/usr/bin/env fontforge -script
# coding=utf-8
# pylint: disable=import-error, too-many-arguments, too-many-branches

"""
    Python fontforge script to convert Gregoria.otf to gregoriao.ttf

    Copyright (C) 2007-2015 The Gregorio Project (see CONTRIBUTORS.md)

    This file is part of Gregorio.

    Gregorio is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published
    by the Free Software Foundation, either version 3 of the License,
    or (at your option) any later version.

    Gregorio is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Gregorio.  If not, see <http://www.gnu.org/licenses/>.

"""

import fontforge, psMat


SHAPES = {
    'pes':2,
    'pesquadratum':3,
    'pesquadratum_longqueue':4,
    'pesquilisma':5,
    'pesquassus':6,
    'pesquassus_longqueue':7,
    'pesquilismaquadratum':8,
    'pesquilismaquadratum_longqueue':9,
    'flexus':10,
    'flexus_nobar':11,
    'flexus_longqueue':12,
    'porrectusflexus':14,
    'porrectusflexus_nobar':18,
    'porrectus':22,
    'porrectus_nobar':26,
    'torculus':30,
    'torculusresupinus':34,
    'torculusquilisma':38,
    'scandicus':42,
    'ancus':46,
}

LIQUESCENTIAE = {
    'nothing':0,
    'initiodebilis':1,
    'deminutus':2,
    'auctusascendens':3,
    'auctusdescendens':4,
    'initiodebilisdeminutus':5,
    'initiodebilisauctusascendens':6,
    'initiodebilisauctusdescendens':7,
}

PITCH_LETTERS = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k',
                 'l', 'm']

newfont = None
oldfont = None


def main():
    "Main function."
    global newfont, oldfont
    newfont = fontforge.font()
#    newfont.em = 2048
    oldfont = fontforge.open("Gregoria.otf")
    font_name = "gregoria"
    newfont.encoding = "ISO10646-1"
    newfont.fontname = "gregoriao"
    newfont.fullname = "gregoriao"
    newfont.familyname = "gregoriao"
    newfont.weight = oldfont.weight
    newfont.copyright = oldfont.copyright
    first_step(font_name)
    adjust_additional_glyphs()
    oldfont.close()
    oldfont = fontforge.open("Gregoria-Deminutae.otf")
    font_name = "gregoria-deminutae"
    first_step(font_name)
    adjust_additional_glyphs()
    oldfont.close()
    oldfont = fontforge.open("Gregoria-Auctae.otf")
    font_name = "gregoria-auctae"
    first_step(font_name)
    adjust_additional_glyphs()
    oldfont.close()
    newfont.em = 2048
    newfont.generate("gregoriao.ttf")
    newfont.close()


    # I don't know why, but Select does not seem to work with glyph
    # number, only with names, so we have to hardcode a correspondance
    # table between the glyphnumber and the name... happily only for
    # some value:
C_TABLE = {
    0:16759,
    255:17788,
    256:60,
    511:11285,
    512:7199,
    767:10,
    768:24,
    1023:15114,
    1024:15119,
    1279:6189,
    1280:6214,
    1535:9082,
    1536:9107,
    1791:8764,
    1792:8789,
    2047:16777,
    2048:16682,
    #the next one is not true, but it will make the algorithm work simply
    2303:17819,
    2133:17819}

def first_step(font_name):
    "First thing to do."
    adjust_two_notes_glyphs(font_name)
    adjust_three_notes_glyphs()
    adjust_four_notes_glyphs(font_name)
    rename_base_glyphs(font_name)


def give_liquescentia(font_name, debilis):
    "A simple function giving the liquescentia."
    if font_name == "gregoria":
        if debilis == 'initiodebilis':
            return "initiodebilis"
        else:
            return "nothing"
    elif font_name == "gregoria-auctae":
        if debilis == 'initiodebilis':
            return "initiodebilisauctusdescendens"
        else:
            return "auctusdescendens"
    elif font_name == "gregoria-deminutae":
        if debilis == 'initiodebilis':
            return "initiodebilisdeminutus"
        else:
            return "deminutus"

def adjust_two_notes_glyphs(font_name):
    "Adjust the height and renames two notes glyphs."
    # glyphs with the first note under the second
    # twoNotesGlyphs = ['flexa', 'flexus'] # there is a . in the name of the 3 and 4
    # case of pes
    for i in range(1, 5):
        name = glyph_num(i, 0, 0, 'pes', give_liquescentia(font_name, 'nothing'), 1)
        rename_glyph("pes%d" % i, name)
        adjust_glyph_height(name, i-1)
    # case of pesDebilis
    for i in range(1, 5):
        if font_name == "gregoria":
            name = glyph_num(i, 0, 0, 'pes', give_liquescentia(font_name, 'initiodebilis'), 1)
            rename_glyph("pesDebilis%d" % i, name)
            adjust_glyph_height(name, i-1)
    # case of pes.quadratum
    for i in range(1, 5):
        if font_name == "gregoria":
            name = glyph_num(i, 0, 0, 'pesquadratum', give_liquescentia(font_name, 'nothing'), 1)
            rename_glyph("pes.quadratum%d" % i, name)
            adjust_glyph_height(name, i-1)
            adjust_glyph_width(name, 329)
    # case of pes.quassus
    for i in range(1, 5):
        if font_name == "gregoria":
            name = glyph_num(i, 0, 0, 'pesquassus', give_liquescentia(font_name, 'nothing'), 1)
            rename_glyph("pes.quassus%d" % i, name)
            adjust_glyph_height(name, i-1)
    # case of flexus
    for i in range(1, 5):
        name = glyph_num(i, 0, 0, 'flexus_nobar', give_liquescentia(font_name, 'nothing'), 1)
        glyphname = "flexus%db" %i
        if i < 3:
            glyphname = "flexus%d.b" % i
        rename_glyph(glyphname, name)
        adjust_glyph_height(name, -1)
    # case of flexa
    for i in range(1, 5):
        name = glyph_num(i, 0, 0, 'flexus', give_liquescentia(font_name, 'nothing'), 1)
        glyphname = "flexa%d" % i
        if font_name == "gregoria":
            if i < 3:
                glyphname = "flexa%d.b" % i
            else:
                glyphname = "flexa%db" %i
        rename_glyph(glyphname, name)
        adjust_glyph_height(name, -1)

def adjust_three_notes_glyphs():
    "Adjust the height and renames three notes glyphs."
    #the glyph names in gregoria here is strange, so I just hardcode the names in a dictionary
    #correspondanceTable
    cTT = {
        '1':(1, 1),
        '2':(2, 2),
        '3':(3, 3),
        '4':(4, 4),
        '2a':(2, 1),
        '3a':(3, 1),
        '3b':(3, 2),
        '4a':(4, 1),
        '4b':(4, 2),
        '4c':(4, 3),
        '2a.':(1, 2),
        '3a.':(1, 3),
        '3b.':(2, 3),
        '4a.':(1, 4),
        '4b.':(2, 4),
        '4c.':(3, 4)}
    # the third number is the shift, it's useless but we never know...
    c_tp = {
        '1':(1, 1, 0),
        '2':(2, 2, 46),
        '3':(3, 3, 46),
        '4':(4, 4, 40),
        '2a':(2, 1, 46),
        '3a':(3, 1, 46),
        '3b':(3, 2, 0),
        '4a':(4, 3, 40),
        '4b':(4, 2, 40),
        '4c':(4, 1, 40),
        '2a.':(1, 2, 46),
        '3a.':(2, 3, 46),
        '3b.':(1, 3, 40),
        '4a.':(3, 4, 40),
        '4b.':(2, 4, 40),
        '4c.':(1, 4, 40)}
    #threeNotesGlyphs
    t_ng = {'torcDebilis':('torculus', 'initiodebilis'),
            'torculus':('torculus', 'nothing'),
            'porrectus':('porrectus', 'nothing'),
            'tor.resupinus':('porrectus_nobar', 'nothing')}
    for base in t_ng.keys():
        if t_ng[base][0] == 'torculus':
            for suffix in cTT.keys():
                adjust_three_notes_glyphs_aux("%s%s" % (base, suffix),
                                              cTT[suffix][0],
                                              cTT[suffix][1],
                                              t_ng[base][0],
                                              give_liquescentia(font_name, t_ng[base][1]))
        else:
            for suffix in c_tp.keys():
                adjust_three_notes_glyphs_aux("%s%s" % (base, suffix),
                                              c_tp[suffix][0],
                                              c_tp[suffix][1],
                                              t_ng[base][0],
                                              give_liquescentia(font_name, t_ng[base][1]))


def adjust_three_notes_glyphs_aux(oldname, i, j, glyph_type, liquescentia):
    "Make adjustments for three note glyphs."
    newname = glyph_num(i, j, 0, glyph_type, liquescentia, 0)
    rename_glyph(oldname, newname)
    # the constant thing is that the second note is on the good height
    if glyph_type == 'torculus':
        adjust_glyph_height(newname, i-1)
    else:
        adjust_glyph_height(newname, -i)
    center_glyph(newname)

def adjust_four_notes_glyphs(font_name):
    "Adjust the height and renames four notes glyphs."
    # the table is basically the same as before, the 4th number is the shift we have to apply
    c_table = {
        '1':(1, 1, 1, 1),
        '2':(2, 2, 2, 2),
        '2a':(2, 2, 1, 1),
        '2b':(2, 1, 1, 2),
        '2b.':(1, 2, 2, 1),
        '2c':(1, 1, 2, 1),
        '2d':(2, 1, 2, 2),
        '3':(3, 3, 3, 3),
        '3a':(3, 3, 2, 2),
        '3b':(2, 2, 3, 3),
        '3c':(1, 1, 3, 3),
        '3d':(3, 2, 1, 1),
        '3e':(3, 2, 2, 3),
        '3f':(2, 3, 3, 2),
        '3g':(3, 1, 1, 3),
        '3h':(1, 3, 3, 1),
        '3i':(2, 3, 2, 1),
        '3j':(3, 3, 1, 1),
        '3k':(2, 3, 1, 0),
        '3l':(1, 3, 1, -1),
        '3m':(1, 2, 3, 2),
        '4':(4, 4, 4, 3),
        '4a':(4, 4, 3, 2),
        '4b':(4, 4, 2, 1),
        '4c':(4, 4, 1, 0),
        '4d':(3, 3, 4, 3),
        '4e':(2, 2, 4, 3),
        '4f':(1, 1, 4, 3),
        '4g':(4, 3, 3, 3),
        '4h':(4, 2, 2, 3),
        '4i':(4, 1, 1, 3),
        '4j':(4, 3, 4, 4),
        '4k':(4, 2, 3, 4),
        '4l':(4, 1, 2, 4),
        '4m':(3, 4, 4, 2),
        '4n':(3, 4, 3, 1),
        '4o':(3, 4, 2, 0),
        '4p':(3, 4, 1, -1),
        '4q':(2, 4, 4, 1),
        '4r':(2, 4, 3, 0),
        '4s':(2, 4, 2, -1),
        '4t':(2, 4, 1, -2),
        '4u':(1, 4, 4, 0),
        '4v':(1, 4, 3, -1),
        '4w':(1, 4, 2, -2),
        '4x':(1, 4, 1, -3),
        '4y':(4, 3, 2, 2),
        '4z':(4, 3, 1, 1),
        '4a.':(4, 2, 1, 2),
        '4b.':(2, 3, 4, 2),
        '4c.':(1, 2, 4, 2),
        '4d.':(1, 3, 4, 2)}
    for suffix in c_table.keys():
        adjust_four_notes_glyphs_aux("por.flexus%s" % suffix,
                                     c_table[suffix][0], c_table[suffix][1],
                                     c_table[suffix][2], 'porrectusflexus',
                                     give_liquescentia(font_name, 'nothing'),
                                     c_table[suffix][3])
        if font_name != "gregoria-auctae":
            adjust_four_notes_glyphs_aux("por.flexus%s.001" % suffix,
                                         c_table[suffix][0], c_table[suffix][1],
                                         c_table[suffix][2],
                                         'porrectusflexus_nobar',
                                         give_liquescentia(font_name, 'nothing'),
                                         c_table[suffix][3])

def adjust_four_notes_glyphs_aux(oldname, i, j, k, glyph_type, liquescentia, shift):
    "Make adjustments for four note glyphs."
    newname = glyph_num(i, j, k, glyph_type, liquescentia, 0)
    # the constant thing is that the second note is on the good height
    rename_glyph(oldname, newname)
    adjust_glyph_height(newname, -shift)

def adjust_additional_glyphs():
    "Some small random adjustments of width, etc."
    adjust_glyph_width(19, 173)
    center_glyph(19)
    adjust_glyph_width(27, 164)
    center_glyph(27)

# glyphs appearing in every font, but we keep only one of each, the
# corresponding thing is their name in the gregorio name convention,
# when they are in Gregoria (not Gregoria-Auctae or Diminutae)
BASE_GLYPHS = ['Z.short', 'z.short', 'grave', 'o', 'v', 'x', 'y', 'circumflex',
               'quoteright', 'doH', 'faH', 'virga.alt', 'vir.inv', 'quilisma',
               'z', 'Z', 'pes.quil', 'oriscus']

# here we absolutely need to make an interation in a certain order (we
# must rename z.short before z), but python does not allow to iterate
# over a dictionary in the order in which it has been declared, so we
# must iterate over the list and look for the corresponding item in
# the dictionary.  the second element is the height adjustment
BASE_GLYPHS_NEW_NAMES = {
    'Z.short':(61, -1),
    'z.short':(64, -1),
    'grave':(8, -1),
    'o':(27, -1),
    'v':(23, -1),
    'x':(6, -1),
    'y':(5, -1),
    'circumflex':(16, -1),
    'quoteright':(33, -1),
    'doH':(1, 0),
    'faH':(2, 0),
    'virga.alt':(22, -1),
    'vir.inv':(25, -1),
    'quilisma':(26, -1),
    'z':(63, -1),
    'Z':(60, -1),
    'pes.quil':(2049, 0),
    'oriscus':(28, -1)}

def adjust_auctae_additional_glyphs():
    "we have to adapt some width because they are wrong in gregoria."
    correction_table = {
        11287:903,
        11286:657,
        11285:657}
    for (key, value) in correction_table.items():
        adjust_glyph_width(key, value)
        center_glyph(key)

def adjust_deminutae_additional_glyphs():
    # pylint: disable=invalid-name
    "The height of the porrectus without bar are messed up in gregoria-deminutae..."
    c_tp = {
        12818:1,
        12824:3,
        12807:-1,
        12811:-3,
        12817:-1,
        12813:-1,
        12816:-3,
        12823:1,
        12814:3,
        12822:-1,
        12809:2}
    for (key, value) in c_tp.items():
        adjust_glyph_height(key, value)

def rename_base_glyphs(font_name):
    "Renames the base glyphs."
    if font_name == "gregoria":
        for oldname in BASE_GLYPHS:
            number = BASE_GLYPHS_NEW_NAMES[oldname][0]
            rename_glyph(oldname, number)
            adjust_glyph_height(number, BASE_GLYPHS_NEW_NAMES[oldname][1])
        # here we adjust the vertical episemus and the circumflexus
        shift_glyph(16, 131)
        adjust_glyph_width(16, 99)
        adjust_glyph_precise_height(16, 100)
        shift_glyph(33, 89)
        adjust_glyph_width(33, 15)
        adjust_glyph_precise_height(33, 120)
        rename_glyph('inclinatum', 19)
        adjust_glyph_height(19, -1)
        rename_glyph('punctum', 17)
        adjust_glyph_height(17, -1)
        rename_glyph('s', 20)
        adjust_glyph_height(20, -1)
    elif font_name == "gregoria-auctae":
        rename_glyph('inclinatum', 31)
        adjust_glyph_height(31, -1)
        rename_glyph('punctum', 73)
        adjust_glyph_height(73, -1)
        rename_glyph('s', 21)
        adjust_glyph_height(21, -1)
    else:
        rename_glyph('inclinatum', 32)
        adjust_glyph_height(32, -1)

def rename_glyph(oldname, newnum):
    "Renames a glyph."
    global oldfont, newfont
    oldfont.selection.select(("singletons",), oldname)
    oldfont.copy()
    newfont.selection.select(("singletons",), "u%05x" % int(newnum))
    newfont.pasteInto()

def adjust_glyph_height(num, diff):
    "Add n (can be negative) to the height of a glyph. n is the difference of pitch."
    # we calculate the difference in the fontforge unity
    global newfont
    newfont[num].transform(psMat.translate(0, 157.5*diff))

def adjust_glyph_precise_height(num, offset):
    "Adjusts the glyph's heigth by offset."
    global newfont
    newfont[num].transform(psMat.translate(0, offset))

def adjust_glyph_width(num, width):
    "Adjusts the glyph width."
    global newfont
    newfont[num].width = width

def shift_glyph(num, offset):
    "Shifts glyph by offset."
    global newfont
    newfont[num].transform(psMat.translate(offset, 0))

def center_glyph(num):
    "Centers glyph."
    global newfont
    glyph = newfont[num]
    glyph.left_side_bearing = glyph.right_side_bearing = (glyph.left_side_bearing + glyph.right_side_bearing)/2

def glyph_num(i, j, k, shape, liquescentia, shortglyph):
    "Get the name, shape, and name of the different ambitus of a glyph."
    if shortglyph == 0:
        return i+(5*j)+(25*k)+(256*LIQUESCENTIAE[liquescentia])+(512*SHAPES[shape])
    else:
        return i+(5*j)+(25*k)+(64*LIQUESCENTIAE[liquescentia])+(512*SHAPES[shape])

if __name__ == "__main__":
    main()
