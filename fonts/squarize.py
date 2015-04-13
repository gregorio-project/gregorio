#!/usr/bin/env python2
# coding=utf-8

"""
    Python fontforge script to build a square notation font.

    Copyright (C) 2013-2015 The Gregorio Project (see CONTRIBUTORS.md)

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

    This script takes a very simple .sfd file with a few symbols and
    builds a complete square notation font. See gregorio-base.sfd for
    naming conventions of these symbols.

    To build your own font, look at gregorio-base.sfd, and build your
    own glyphs from it.

    Basic use :
     ./squarize.py fontname

"""

from __future__ import print_function

import getopt, sys
import fontforge, psMat

#defines the maximal interval between two notes, the bigger this number is,
#the more glyphs you'll have to generate
MAX_INTERVAL = 5

# the numerotation of the glyphs are not the same between short and long
#types, here is the indicator
shortglyphs = 0

GPLV3 = """This program is free software: you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

As a special exception, if you create a document which uses this font,
and embed this font or unaltered portions of this font into the
document, this font does not by itself cause the resulting document to
be covered by the GNU General Public License. This exception does not
however invalidate any other reasons why the document might be covered
by the GNU General Public license. If you modify this font, you may
extend this exception to your version of the font, but you are not
obligated to do so. If you do not wish to do so, delete this exception
statement from your version."""

# Use the U+F0000 Supplemental Private Use Area-A.
UNICODE_CHAR_START = 0xf0000

oldfont = None
newfont = None
font_name = None
BASE_HEIGHT = None
LINE_WIDTH = None
WIDTH_PUNCTUM = None
width1 = None
width2 = None
WIDTH_DEBILIS = None
WIDTH_DEMINUTUS = None
WIDTH_INCLINATUM_DEMINUTUS = None
WIDTH_FLEXUSDEMINUTUS = None
PORRECTUSFLEXUSWIDTHS = None
PORRECTUSWIDTHS = None
WIDTH_INCLINATUM = None
WIDTH_STROPHA = None
HEPISEMUS_ADDITIONAL_WIDTH = None
WIDTH_ORISCUS = None
WIDTH_QUILISMA = None
WIDTH_HIGH_PES = None
WIDTH_ORISCUS_REV = None


def usage():
    "Prints the help message."
    print(""" Python script to convert a small set of glyphs into a complete
gregorian square notation font. The initial glyphs have a name
convention, see gregorio-base.sfd for this convention.

Usage:
        squarize.py fontname

with fontname=gregorio, parmesan or greciliae for now.""")

def main():
    "Main function"
    global oldfont, newfont, font_name, shortglyphs
    try:
        opts, args = getopt.gnu_getopt(sys.argv[1:], "h", ["help"])
    except getopt.GetoptError:
        # print help information and exit:
        usage()
        sys.exit(2)
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            usage()
            sys.exit()
    if len(args) == 0:
        usage()
        sys.exit(2)
    if args[0] == "gregorio":
        font_name = "gregorio"
    elif args[0] == "parmesan":
        font_name = "parmesan"
    elif args[0] == "greciliae":
        font_name = "greciliae"
    elif args[0] == "gregoria":
        font_name = "gregoria"
    else:
        usage()
        sys.exit(2)
    # the fonts
    oldfont = fontforge.open("%s-base.sfd" % font_name)
    newfont = fontforge.font()
    newfont.encoding = "UnicodeFull"
    newfont.fontname = "%s" % font_name
    newfont.fullname = "%s" % font_name
    newfont.fontlog = "See file FONTLOG you should have received with the software"
    newfont.familyname = "%s" % font_name
    if font_name == "greciliae":
        newfont.copyright = """Greciliae font, adapted with fontforge by Elie Roux
Copyright (C) 2007 Matthew Spencer
with Reserved Font Name Caeciliae

This Font Software is licensed under the SIL Open Font License, Version 1.1.
This license is also available with a FAQ at:
http://scripts.sil.org/OFL"""
    elif font_name == "gregorio":
        newfont.copyright = """gregorio font, created with FontForge.
Copyright (C) 2007 Elie Roux <elie.roux@telecom-bretagne.eu>

"""+GPLV3
    elif font_name == "parmesan":
        newfont.copyright = """LilyPond's pretty-but-neat music font.
Copyright (C) 2002--2006 Juergen Reuter <reuter@ipd.uka.de>

"""+GPLV3
    newfont.weight = "regular"
    initialize_glyphs()
    initialize_lengths()
    hepisemus()
    shortglyphs = 1
    pes()
    pes_quadratum()
    salicus_first()
    flexus()
    scandicus()
    ancus()
    salicus()
    shortglyphs = 0
    torculus()
    torculus_liquescens()
    porrectus()
    porrectusflexus()
    torculusresupinus()
    newfont.generate("%s.ttf" % font_name)
    oldfont.close()
    newfont.close()

def message(glyph_name):
    """Prints a message to stdout, so that the user gets less bored when
    building the font

    """
    print("generating", glyph_name, "for", font_name)

def precise_message(glyph_name):
    "Prints more information to entertain the user."
    print("  *", glyph_name)

# initial glyphs are the names of the glyphs that are already in
# gregorio_base, mostly one-note glyphs. see initialize_glyphs()
# for more details.
initial_glyphs = [1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 13, 14, 15, 16 , 17,
                  19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
                  32 , 33, 34, 35, 36, 37, 38, 39, 60, 61, 62, 63, 64,
                  65, 69, 70, 72, 73, 74, 77, 79, 81, 82, 83, 84, 85,
                  86, 87, 88, 89, 90, 91, 92, 93]


initialcount = None
count = None

def initialize_glyphs():
    global initialcount, count, newfont, oldfont
#    global initial_glyphs
    names = []
    unislots = []
    for number in initial_glyphs:
#        name = "_00%02d" % int(number)
#        initial_glyphs.insert(0, name)
#        initial_glyphs.remove(number)
        names.append("_00%02d" % int(number))
        unislots.append("u%05x" % (int(number)+UNICODE_CHAR_START))
#        unislots.append(int(number)+UNICODE_CHAR_START)
    if font_name == "gregorio":
        glyphs_to_append = (1025, 2561)
        initialcount = 192
    elif font_name == "parmesan":
        glyphs_to_append = (1025, 2561)
        initialcount = 192
    elif font_name == "greciliae":
        glyphs_to_append = (2561, 1025, 75, 76, 78, 80)
        initialcount = 199
    elif font_name == "gregoria":
        glyphs_to_append = (2561, 1025)
        initialcount = 178
    for glyphnumber in glyphs_to_append:
#        initial_glyphs.append(glyphnumber)
        names.append("_%04d" % int(glyphnumber))
        unislots.append("u%05x" % (int(glyphnumber)+UNICODE_CHAR_START))
#        unislots.append(int(number)+unicode_char_start)
    count = initialcount
#    print(unislots)
    for i in range(len(names)):
        oldfont.selection.select(("singletons",), names[i])
        oldfont.copy()
        #newfont.createMappedChar(unislots[i])
        newfont.selection.select(("singletons",), unislots[i])
        newfont.paste()

def initialize_lengths():
    "Initialize the lenghts, depending on the font"
    global BASE_HEIGHT, LINE_WIDTH, WIDTH_PUNCTUM, width1, width2
    global WIDTH_DEBILIS, WIDTH_DEMINUTUS, WIDTH_INCLINATUM_DEMINUTUS
    global WIDTH_FLEXUSDEMINUTUS, PORRECTUSFLEXUSWIDTHS, PORRECTUSWIDTHS
    global WIDTH_INCLINATUM, WIDTH_STROPHA, HEPISEMUS_ADDITIONAL_WIDTH
    global WIDTH_ORISCUS, WIDTH_QUILISMA, WIDTH_HIGH_PES, WIDTH_ORISCUS_REV
    if (font_name == "gregorio"):
        # the base heigth is half the space between two lines plus half the heigth of a line
        BASE_HEIGHT = 157.5
        # some width, necessary to know where to draw lines, squares, etc.
        # first the width of the lines that link notes, like in a pes for example
        LINE_WIDTH = 22
        # then the width of a punctum, we assume that it is the same width for
        # oriscus, quilisma, punctum auctum descendens and punctum auctum ascendens
        WIDTH_PUNCTUM = 164
        # WIDTH_ORISCUS is the width of an oriscus, idem for quilisma
        WIDTH_ORISCUS = 164
        WIDTH_QUILISMA = 164
        # WIDTH_ORISCUS_REV is the width of an oriscus reversus
        WIDTH_ORISCUS_REV = 164
        # the width of the first note of an initio debilis, and the one of the
        # last note of a deminutus. Warning, in GregorioTeX they must be the
        # same! you must (almost always) add the width of a line to have the real width.
        WIDTH_DEBILIS = 88
        WIDTH_DEMINUTUS = 88
        # width of a punctum inclinatum (we consider that the punctum
        # inclinatum auctus has the same width
        WIDTH_INCLINATUM = 164
        # width of a stropha (idem for the stropha aucta)
        WIDTH_STROPHA = 164
        # with of the second (highest) note of a pes
        WIDTH_HIGH_PES = 154
        # the width of the punctum inclinatum deminutus (no need to add the
        # width of a line)
        WIDTH_INCLINATUM_DEMINUTUS = 82
        # the width of the note which is just before a deminutus, in some
        # fonts it is not the same width as a punctum
        WIDTH_FLEXUSDEMINUTUS = 186
        # the widths of the torculus resupinus, there are five, one per note
        # difference between the two first notes (for example the first is the
        # width of the first two notes of baba
        PORRECTUSFLEXUSWIDTHS = (340, 428, 586, 670, 931)
        PORRECTUSWIDTHS = (490, 575, 650, 740, 931)
        # width that will be added to the standard width when we will build
        # horizontal episemus. for example, if a punctum has the length 164,
        # the episemus will have the width 244 and will be centered on the
        # center of the punctum
        HEPISEMUS_ADDITIONAL_WIDTH = 5
    elif (font_name == "parmesan"):
        BASE_HEIGHT = 157.5
        LINE_WIDTH = 22
        WIDTH_PUNCTUM = 161
        WIDTH_ORISCUS = 192
        WIDTH_ORISCUS_REV = 192
        WIDTH_QUILISMA = 161
        WIDTH_DEBILIS = 75
        WIDTH_DEMINUTUS = 75
        WIDTH_INCLINATUM = 178
        WIDTH_STROPHA = 169
        WIDTH_HIGH_PES = 151
        WIDTH_INCLINATUM_DEMINUTUS = 112
        WIDTH_FLEXUSDEMINUTUS = 161
        PORRECTUSFLEXUSWIDTHS = (340, 428, 586, 670, 931)
        PORRECTUSWIDTHS = (490, 575, 650, 740, 931)
        HEPISEMUS_ADDITIONAL_WIDTH = 5
    elif (font_name == "greciliae"):
        BASE_HEIGHT = 157.5
        LINE_WIDTH = 18
        WIDTH_PUNCTUM = 166
        WIDTH_ORISCUS = 166
        WIDTH_ORISCUS_REV = 168
        WIDTH_QUILISMA = 166
        WIDTH_DEBILIS = 65
        WIDTH_DEMINUTUS = 65
        WIDTH_INCLINATUM = 185
        WIDTH_STROPHA = 163
        WIDTH_HIGH_PES = 155
        WIDTH_INCLINATUM_DEMINUTUS = 139
        WIDTH_FLEXUSDEMINUTUS = 168
        PORRECTUSFLEXUSWIDTHS = (503, 629, 628, 628, 931)
        PORRECTUSWIDTHS = (503, 629, 628, 628, 931)
        HEPISEMUS_ADDITIONAL_WIDTH = 5
    if (font_name == "gregoria"):
        BASE_HEIGHT = 157.5
        LINE_WIDTH = 22
        WIDTH_PUNCTUM = 164
        WIDTH_ORISCUS = 164
        WIDTH_ORISCUS_REV = 164
        WIDTH_QUILISMA = 164
        WIDTH_DEBILIS = 88
        WIDTH_DEMINUTUS = 88
        WIDTH_INCLINATUM = 173
        WIDTH_STROPHA = 164
        WIDTH_HIGH_PES = 154
        WIDTH_INCLINATUM_DEMINUTUS = 128
        WIDTH_FLEXUSDEMINUTUS = 186
        PORRECTUSFLEXUSWIDTHS = (340, 428, 586, 670, 931)
        PORRECTUSWIDTHS = (490, 575, 650, 740, 931)
        HEPISEMUS_ADDITIONAL_WIDTH = 5

# the list of the number of the glyphs

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
    'flexus_oriscus':13,
    'porrectusflexus':14,
    'porrectusflexus_nobar':18,
    'porrectus':22,
    'porrectus_nobar':26,
    'torculus':30,
    'torculusresupinus':34,
    'torculusquilisma':38,
    'scandicus':42,
    'ancus':44,
    'ancus_longqueue':46,
    'salicus_first':48,
    'salicus':50,
    'salicus_longqueue':52,
    'torculus_liquescens': 54,
    'torculus_liquescens_quilisma': 58,
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

def gnumber(i, j, k, shape, liquescentia):
    """Get the number of the glyph, with the name of the general shape,
    and the name of the different ambitus.

    """
    if shortglyphs == 0:
        return i+(5*j)+(25*k)+(256*LIQUESCENTIAE[liquescentia])+(512*SHAPES[shape])+UNICODE_CHAR_START
    else:
        return i+(5*j)+(25*k)+(64*LIQUESCENTIAE[liquescentia])+(512*SHAPES[shape])+UNICODE_CHAR_START

def simple_paste(src, dstnum):
    "Copy and past a glyph."
    global oldfont, newfont
    oldfont.selection.select(("singletons",), src)
    oldfont.copy()
    newfont.selection.select(("singletons",), "u%05x" % int(dstnum))
    newfont.pasteInto()
    #newfont.paste()

def simplify(glyphnumber):
    "Simplify a glyph."
    newfont[glyphnumber].simplify()
    newfont[glyphnumber].removeOverlap()
    newfont[glyphnumber].simplify()

def paste_and_move(src, dst, xdimen, ydimen):
    "Pastes the src glyph into dst, and moves it with horiz and vert offsets."
    global oldfont, newfont
    oldfont[src].transform(psMat.translate(xdimen, ydimen))
    oldfont.selection.select(("singletons",), src)
    oldfont.copy()
    newfont.selection.select(("singletons",), "u%05x" % int(dst))
    newfont.pasteInto()
    oldfont[src].transform(psMat.translate(-xdimen, -ydimen))

def end_glyph(glyphnumber):
    global newfont
    newfont[glyphnumber].simplify()
    newfont[glyphnumber].simplify()
    newfont[glyphnumber].removeOverlap()
    newfont[glyphnumber].simplify()
    newfont[glyphnumber].canonicalContours()
    newfont[glyphnumber].canonicalStart()

def scale(glyphnumber, xdimen, ydimen):
    "Scales a glyph, horizontally by x and vertically by y"
    global newfont
    newfont[glyphnumber].transform(psMat.scale(xdimen, ydimen))

def move(glyphnumber, xdimen, ydimen):
    "moves a glyph, horizontally by x and vertically by y"
    global newfont
    newfont[glyphnumber].transform(psMat.translate(xdimen, ydimen))

def set_width(glyphnumber, width):
    "Set the width of a glyph"
    global newfont
    newfont[glyphnumber].width = width

def write_line(i, glyphnumber, length, height):
    "Writes a line in glyphnumber, with length and height offsets"
    if (i > 1):
        linename = "line%d" % i
        paste_and_move(linename, glyphnumber, length, height)

def write_first_bar(i, glyphnumber):
    """Write the first bar of a glyph. Used for porrectus flexus,
    porrectus and flexus.

    """
    paste_and_move("queue", glyphnumber, 0, (-i+1)*BASE_HEIGHT)
    write_line(i, glyphnumber, 0, (-i+1)*BASE_HEIGHT)

def write_deminutus(i, j, glyphnumber, length=0, tosimplify=0, firstbar=1):
    """As the glyph before a deminutus is not the same as a normal glyph,
    and always the same, we can call this function each
    time. Sometimes we have to simplify before building the last glyph
    (tosimplify=1), and length is the offset.

    """
    if firstbar == 1:
        paste_and_move("mdeminutus", glyphnumber, length, i*BASE_HEIGHT)
    elif firstbar == 0:
        paste_and_move("mnbdeminutus", glyphnumber, length, i*BASE_HEIGHT)
    else:
        paste_and_move("mademinutus", glyphnumber, length, i*BASE_HEIGHT)
    write_line(j, glyphnumber, length+WIDTH_FLEXUSDEMINUTUS-LINE_WIDTH, (i-j+1)*BASE_HEIGHT)
    if (tosimplify):
        simplify(glyphnumber)
    paste_and_move("deminutus", glyphnumber,
                   length+WIDTH_FLEXUSDEMINUTUS-WIDTH_DEMINUTUS-LINE_WIDTH, (i-j)*BASE_HEIGHT)

def hepisemus():
    "Creates horizontal episemae."
    message("horizontal episemus")
    write_hepisemus(WIDTH_PUNCTUM, 40)
    write_hepisemus(WIDTH_FLEXUSDEMINUTUS, 41)
    write_hepisemus(WIDTH_DEBILIS+LINE_WIDTH, 42)
    write_hepisemus(WIDTH_INCLINATUM, 43)
    write_hepisemus(WIDTH_INCLINATUM_DEMINUTUS, 44)
    write_hepisemus(WIDTH_STROPHA, 45)
    write_hepisemus(WIDTH_QUILISMA, 56)
    write_hepisemus(WIDTH_HIGH_PES, 58)
    write_hepisemus(WIDTH_ORISCUS, 57)
    for i in range(MAX_INTERVAL):
        write_hepisemus(PORRECTUSWIDTHS[i], int(46+i))
    for i in range(MAX_INTERVAL):
        write_hepisemus(PORRECTUSFLEXUSWIDTHS[i], int(51+i))

def write_hepisemus(shape_width, glyphnumber):
    "Makes the horizontal episemus."
    glyphnumber = glyphnumber + UNICODE_CHAR_START
    simple_paste("hepisemus_base", glyphnumber)
    scale(glyphnumber, shape_width + 2*HEPISEMUS_ADDITIONAL_WIDTH, 1)
    move(glyphnumber, -HEPISEMUS_ADDITIONAL_WIDTH, 0)
    paste_and_move("hepisemusleft", glyphnumber, -HEPISEMUS_ADDITIONAL_WIDTH, 0)
    paste_and_move("hepisemusright", glyphnumber, shape_width + HEPISEMUS_ADDITIONAL_WIDTH, 0)
    set_width(glyphnumber, shape_width)
    end_glyph(glyphnumber)

def pes():
    "Creates the pes."
    message("pes")
    precise_message("pes")
    standard_fonts = ["gregorio", "parmesan", "gregoria", "greciliae"]
    if font_name in standard_fonts:
    # we prefer drawing the pes with ambitus of one by hand, it is more beautiful
        for i in range(2, MAX_INTERVAL+1):
            write_pes(i, "p2base", 'pes')
    else:
        for i in range(1, MAX_INTERVAL+1):
            write_pes(i, "pbase", 'pes')
    # idem for the pes quilisma
    precise_message("pes quilisma")
    if font_name in standard_fonts:
        for i in range(2, MAX_INTERVAL+1):
            write_pes(i, "qbase", 'pesquilisma')
    else:
        for i in range(1, MAX_INTERVAL+1):
            write_pes(i, "qbase", 'pesquilisma')
    precise_message("pes deminutus")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_deminutus(i, "pesdeminutus", 'pes', 'deminutus')
    precise_message("pes initio debilis")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_debilis(i, 'pes', 'initiodebilis')
    precise_message("pes initio debilis deminutus")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_debilis_deminutus(i, 'pes', 'initiodebilisdeminutus')

def write_pes(i, first_glyph, shape, liquescentia='nothing'):
    glyphnumber = gnumber(i, 0, 0, shape, liquescentia)
    #begin_glyph(glyphnumber)
    # the difference of width of the two shapes, that will change a thing or two...
    if (first_glyph == "qbase"):
        width_difference = WIDTH_QUILISMA-WIDTH_HIGH_PES
    elif (first_glyph == "pbase" or first_glyph == "p2base"):
        width_difference = WIDTH_PUNCTUM-WIDTH_HIGH_PES
    else:
        width_difference = 0
    if (width_difference < 0):
        paste_and_move(first_glyph, glyphnumber, -width_difference, 0)
    else:
        simple_paste(first_glyph, glyphnumber)
    if (first_glyph == "qbase"):
        width1 = WIDTH_QUILISMA-LINE_WIDTH
    else:
        width1 = WIDTH_PUNCTUM-LINE_WIDTH
    if (width_difference < 0):
        width1 = width1-width_difference
    write_line(i, glyphnumber, width1, BASE_HEIGHT)
    if (width_difference != 0):
        paste_and_move('phigh', glyphnumber, width_difference, i*BASE_HEIGHT)
    else:
        paste_and_move('phigh', glyphnumber, 0, i*BASE_HEIGHT)
    if (width_difference < 0):
        set_width(glyphnumber, WIDTH_PUNCTUM)
    else:
        set_width(glyphnumber, WIDTH_QUILISMA)
    end_glyph(glyphnumber)

def write_pes_debilis(i, shape, liquescentia='nothing'):
    glyphnumber = gnumber(i, 0, 0, shape, liquescentia)
    # with a deminutus it is much more beautiful than with a idebilis
    paste_and_move("deminutus", glyphnumber, 0, 0)
    write_line(i, glyphnumber, WIDTH_DEBILIS, BASE_HEIGHT)
    simplify(glyphnumber)
    paste_and_move("base4", glyphnumber, WIDTH_DEBILIS, i*BASE_HEIGHT)
    set_width(glyphnumber, WIDTH_PUNCTUM+WIDTH_DEBILIS)
    end_glyph(glyphnumber)

def write_pes_deminutus(i, first_glyph, shape, liquescentia='nothing'):
    glyphnumber = gnumber(i, 0, 0, shape, liquescentia)
    simple_paste(first_glyph, glyphnumber)
    if (first_glyph == "qbase"):
        width1 = WIDTH_QUILISMA-LINE_WIDTH
    else:
        width1 = WIDTH_PUNCTUM-LINE_WIDTH
    write_line(i, glyphnumber, WIDTH_PUNCTUM-LINE_WIDTH, BASE_HEIGHT)
    paste_and_move("rdeminutus", glyphnumber, WIDTH_PUNCTUM-LINE_WIDTH-WIDTH_DEMINUTUS,
                   i*BASE_HEIGHT)
    set_width(glyphnumber, WIDTH_PUNCTUM)
    end_glyph(glyphnumber)

def write_pes_debilis_deminutus(i, shape, liquescentia='nothing'):
    glyphnumber = gnumber(i, 0, 0, shape, liquescentia)
    simple_paste("deminutus", glyphnumber)
    write_line(i, glyphnumber, WIDTH_DEBILIS, BASE_HEIGHT)
    simplify(glyphnumber)
    paste_and_move("rdeminutus", glyphnumber, 0, i*BASE_HEIGHT)
    set_width(glyphnumber, WIDTH_DEBILIS+LINE_WIDTH)
    end_glyph(glyphnumber)

def pes_quadratum():
    message("pes quadratum")
    precise_message("pes quadratum")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "base5", "rvsbase", 'pesquadratum')
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "base5", "rvlbase", 'pesquadratum_longqueue')
    precise_message("pes quassus")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "obase", "rvsbase", 'pesquassus')
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "obase", "rvlbase", 'pesquassus_longqueue')
    precise_message("pes quilisma quadratum")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "qbase", "rvsbase", 'pesquilismaquadratum')
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "qbase", "rvlbase", 'pesquilismaquadratum_longqueue')
    precise_message("pes auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "base5", "auctusa2", 'pesquadratum', 'auctusascendens')
    precise_message("pes initio debilis auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "idebilis", "auctusa2", 'pesquadratum',
                            'initiodebilisauctusascendens')
    precise_message("pes quassus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "obase", "auctusa2", 'pesquassus', 'auctusascendens')
    precise_message("pes quilisma auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "qbase", "auctusa2", 'pesquilismaquadratum', 'auctusascendens')
    precise_message("pes auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "base5", "auctusd2", 'pesquadratum', 'auctusdescendens')
    precise_message("pes initio debilis auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "idebilis", "auctusd2", 'pesquadratum',
                            'initiodebilisauctusdescendens')
    precise_message("pes quassus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "obase", "auctusd2", 'pesquassus', 'auctusdescendens')
    precise_message("pes quilisma auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "qbase", "auctusd2", 'pesquilismaquadratum', 'auctusdescendens')

def write_pes_quadratum(i, first_glyph, last_glyph, shape, liquescentia='nothing'):
    glyphnumber = gnumber(i, 0, 0, shape, liquescentia)
    if (first_glyph == "idebilis"):
        first_width = WIDTH_DEMINUTUS
    elif (first_glyph == "base5"):
        if i == 1:
            first_glyph = '_0017'
            if last_glyph == 'base7':
                last_glyph = '_0017'
            elif last_glyph == 'auctusa2':
                last_glyph = '_0072'
            elif last_glyph == 'auctusd2':
                last_glyph = '_0073'
            elif last_glyph == 'rvsbase':
                last_glyph = '_0023'
            elif last_glyph == 'rvlbase':
                last_glyph = '_0022'
            first_width = WIDTH_PUNCTUM
        else:
            first_width = WIDTH_PUNCTUM-LINE_WIDTH
    elif(first_glyph == "obase"):
        first_width = WIDTH_ORISCUS-LINE_WIDTH
    else:
        first_width = WIDTH_QUILISMA-LINE_WIDTH
    simple_paste(first_glyph, glyphnumber)
    if (i != 1):
        linename = "line%d" % i
        paste_and_move(linename, glyphnumber, first_width, BASE_HEIGHT)
    paste_and_move(last_glyph, glyphnumber, first_width, i*BASE_HEIGHT)
    set_width(glyphnumber, first_width+WIDTH_PUNCTUM)
    end_glyph(glyphnumber)

def salicus_first():
    precise_message("first part of salicus")
    for i in range(1, MAX_INTERVAL+1):
        write_salicus_first(i, "base5", "obase4", 'salicus_first')

def write_salicus_first(i, first_glyph, last_glyph, shape, liquescentia='nothing'):
    glyphnumber = gnumber(i, 0, 0, shape, liquescentia)
    if i == 1:
        first_glyph = '_0017'
        first_width = WIDTH_PUNCTUM
        last_glyph = '_0027'
    else:
        first_width = WIDTH_PUNCTUM-LINE_WIDTH
    simple_paste(first_glyph, glyphnumber)
    if (i != 1):
        linename = "line%d" % i
        paste_and_move(linename, glyphnumber, first_width, BASE_HEIGHT)
    paste_and_move(last_glyph, glyphnumber, first_width, i*BASE_HEIGHT)
    set_width(glyphnumber, first_width+WIDTH_ORISCUS)
    end_glyph(glyphnumber)

def salicus():
    message("salicus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_salicus(i, j, "rvsbase", 'salicus')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_salicus(i, j, "rvlbase", 'salicus_longqueue')

def write_salicus(i, j, last_glyph, shape, liquescentia='nothing'):
    glyphnumber = gnumber(i, j, 0, shape, liquescentia)
    if j == 1:
        if last_glyph == 'rvsbase':
            last_glyph = '_0023'
        elif last_glyph == 'rvlbase':
            last_glyph = '_0022'
    if i == 1 and j == 1:
        first_glyph = '_0017'
        first_width = WIDTH_PUNCTUM
        middle_glyph = '_0027'
        middle_width = WIDTH_ORISCUS
    elif i == 1:
        first_glyph = '_0017'
        first_width = WIDTH_PUNCTUM
        middle_glyph = 'obase'
        middle_width = WIDTH_ORISCUS-LINE_WIDTH
    elif j == 1:
        first_glyph = 'base5'
        first_width = WIDTH_PUNCTUM-LINE_WIDTH
        middle_glyph = 'obase4'
        middle_width = WIDTH_ORISCUS
    else:
        first_glyph = 'base5'
        first_width = WIDTH_PUNCTUM-LINE_WIDTH
        middle_glyph = 'obase8'
        middle_width = WIDTH_ORISCUS-LINE_WIDTH
    simple_paste(first_glyph, glyphnumber)
    if (i != 1):
        linename = "line%d" % i
        paste_and_move(linename, glyphnumber, first_width, BASE_HEIGHT)
    paste_and_move(middle_glyph, glyphnumber, first_width, i*BASE_HEIGHT)
    length = first_width+middle_width
    if (j != 1):
        linename = "line%d" % j
        paste_and_move(linename, glyphnumber, length, (i+1)*BASE_HEIGHT)
    else:
        length = length-0.01
    paste_and_move(last_glyph, glyphnumber, length, (i+j)*BASE_HEIGHT)
    set_width(glyphnumber, length+WIDTH_PUNCTUM)
    end_glyph(glyphnumber)

def flexus():
    message("flexus")
    precise_message("flexus")
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "base2", 'base7', 'flexus_nobar')
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "odbase", 'base7', 'flexus_oriscus')
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "vbase"+str(i), 'base7', 'flexus')
    write_flexus(1, "vlbase", 'base7', 'flexus_longqueue')
    for i in range(2, MAX_INTERVAL+1):
        write_flexus(i, "vbase"+str(i), 'base7', 'flexus_longqueue')
    precise_message("flexus deminutus")
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "mdeminutus", 'base7', 'flexus_nobar', 'deminutus')
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "odbase", 'deminutus', 'flexus_oriscus', 'deminutus')
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "mdeminutus", 'base7', 'flexus', 'deminutus')
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "mdeminutus", 'base7', 'flexus_longqueue', 'deminutus')
    precise_message("flexus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "base2", 'auctusa1', 'flexus_nobar', 'auctusascendens')
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "odbase", 'auctusa1', 'flexus_oriscus', 'auctusascendens')
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "vbase"+str(i), 'auctusa1', 'flexus', 'auctusascendens')
    write_flexus(1, "vlbase", 'auctusa1', 'flexus_longqueue', 'auctusascendens')
    for i in range(2, MAX_INTERVAL+1):
        write_flexus(i, "vbase"+str(i), 'auctusa1', 'flexus_longqueue', 'auctusascendens')
    precise_message("flexus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "base2", 'auctusd1', 'flexus_nobar', 'auctusdescendens')
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "odbase", 'auctusd1', 'flexus_oriscus', 'auctusdescendens')
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "vbase"+str(i), 'auctusd1', 'flexus', 'auctusdescendens')
    write_flexus(1, "vlbase", 'auctusd1', 'flexus_longqueue', 'auctusdescendens')
    for i in range(2, MAX_INTERVAL+1):
        write_flexus(i, "vbase"+str(i), 'auctusd1', 'flexus_longqueue', 'auctusdescendens')

def write_flexus(i, first_glyph, last_glyph, shape, liquescentia='nothing'):
    glyphnumber = gnumber(i, 0, 0, shape, liquescentia)
    # we add a queue if it is a deminutus
    if (first_glyph == "mdeminutus"):
        if shape == 'flexus_nobar':
            write_deminutus(0, i, glyphnumber, length=0, tosimplify=1, firstbar=0)
        elif shape == 'flexus':
            write_first_bar(1, glyphnumber)
            write_deminutus(0, i, glyphnumber, length=0, tosimplify=1, firstbar=1)
        else:
            write_first_bar(2, glyphnumber)
            write_deminutus(0, i, glyphnumber, length=0, tosimplify=1, firstbar=1)
        length = WIDTH_FLEXUSDEMINUTUS
    elif first_glyph == 'odbase' and last_glyph == 'deminutus':
        simple_paste(first_glyph, glyphnumber)
        write_line(i, glyphnumber, WIDTH_ORISCUS_REV - LINE_WIDTH, (1-i)*BASE_HEIGHT)
        simplify(glyphnumber)
        paste_and_move("deminutus", glyphnumber,
                       WIDTH_ORISCUS_REV - WIDTH_DEMINUTUS - LINE_WIDTH, (-i)*BASE_HEIGHT)
        length = WIDTH_ORISCUS_REV
    else:
        if i == 1:#we remove the bar aspect
            if last_glyph == 'base7':
                last_glyph = '_0017'
            elif last_glyph == 'auctusa1':
                last_glyph = '_0072'
            elif last_glyph == 'auctusd1':
                last_glyph = '_0073'
            if first_glyph == 'base2':
                first_glyph = '_0017'
            elif first_glyph == 'odbase':
                first_glyph = '_0028'
            elif first_glyph == 'vsbase':
                first_glyph = '_0025'
            elif first_glyph == 'vlbase':
                first_glyph = '_0024'
        simple_paste(first_glyph, glyphnumber)
        if first_glyph == 'odbase':
            length = WIDTH_ORISCUS_REV
        else:
            length = WIDTH_PUNCTUM
        if i != 1:
            length = length-LINE_WIDTH
            write_line(i, glyphnumber, length, (1-i)*BASE_HEIGHT)
        paste_and_move(last_glyph, glyphnumber, length, (-i)*BASE_HEIGHT)
        if first_glyph == 'odbase':
            length = WIDTH_ORISCUS_REV
        else:
            length = WIDTH_PUNCTUM
        if i == 1:
            length = 2 * length
        else:
            length = 2 * length - LINE_WIDTH
    set_width(glyphnumber, length)
    end_glyph(glyphnumber)

def porrectus():
    message("porrectus")
    precise_message("porrectus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(i, j, 'phigh', 1, 'porrectus')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(i, j, 'phigh', 0, 'porrectus_nobar')
    precise_message("porrectus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(i, j, "auctusa2", 1, 'porrectus', 'auctusascendens')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(i, j, "auctusa2", 0, 'porrectus_nobar', 'auctusascendens')
    precise_message("porrectus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(i, j, "auctusd2", 1, 'porrectus', 'auctusdescendens')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(i, j, "auctusd2", 0, 'porrectus_nobar', 'auctusdescendens')
    #precise_message("porrectus deminutus")
    #for i in range(1, MAX_INTERVAL+1):
    #    for j in range(1, MAX_INTERVAL+1):
    #        write_porrectus(i, j, "rdeminutus", 1, 'porrectus', 'deminutus')
    #for i in range(1, MAX_INTERVAL+1):
    #    for j in range(1, MAX_INTERVAL+1):
    #        write_porrectus(i, j, "rdeminutus", 0, 'porrectus_nobar', 'deminutus')
    precise_message("porrectus deminutus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_alternate_porrectus_deminutus(i, j)

def write_porrectus(i, j, last_glyph, with_bar, shape, liquescentia='nothing'):
    glyphnumber = gnumber(i, j, 0, shape, liquescentia)
    length = PORRECTUSWIDTHS[i-1]
    if (with_bar):
        write_first_bar(i, glyphnumber)
    first_glyph = "porrectus%d" % i
    if (last_glyph == 'auctusa2' or last_glyph == 'auctusd2'):
        length = PORRECTUSFLEXUSWIDTHS[i-1]
        if (j == 1):
            first_glyph = "porrectusflexusnb%d" % i
        else:
            first_glyph = "porrectusflexus%d" % i
    simple_paste(first_glyph, glyphnumber)
    if (j != 1 or (last_glyph != 'auctusa2' and last_glyph != 'auctusd2')):
        write_line(j, glyphnumber, length-LINE_WIDTH, (-i+1)*BASE_HEIGHT)
        length = length-LINE_WIDTH
    if (with_bar):
        simplify(glyphnumber)
    if (last_glyph == "rdeminutus"):
        paste_and_move(last_glyph, glyphnumber, (length-WIDTH_DEMINUTUS), (j-i)*BASE_HEIGHT)
    elif (last_glyph == 'auctusa2' or last_glyph == 'auctusd2'):
        if (last_glyph == 'auctusa2' and j == 1):
            last_glyph = '_0072'
        elif (last_glyph == 'auctusd2' and j == 1):
            last_glyph = '_0073'
        paste_and_move(last_glyph, glyphnumber, (length), (j-i)*BASE_HEIGHT)
        length = length + WIDTH_PUNCTUM
    else:
        paste_and_move(last_glyph, glyphnumber, (length-WIDTH_HIGH_PES+LINE_WIDTH),
                       (j-i)*BASE_HEIGHT)
        length = length+LINE_WIDTH
    set_width(glyphnumber, length)
    end_glyph(glyphnumber)

def write_alternate_porrectus_deminutus(i, j):
    glyphnumber = gnumber(i, j, 0, 'porrectus', 'deminutus')
    write_first_bar(i, glyphnumber)
    if i == 1:
        simple_paste('base2', glyphnumber)
    else:
        simple_paste('base3', glyphnumber)
    write_line(i, glyphnumber, WIDTH_PUNCTUM-LINE_WIDTH, (-i+1)*BASE_HEIGHT)
    simplify(glyphnumber)
    paste_and_move('mpdeminutus', glyphnumber, (WIDTH_PUNCTUM-LINE_WIDTH), (-i)*BASE_HEIGHT)
    write_line(j, glyphnumber, WIDTH_PUNCTUM+WIDTH_FLEXUSDEMINUTUS-2*LINE_WIDTH,
               (-i+1)*BASE_HEIGHT)
    paste_and_move('rdeminutus', glyphnumber,
                   (WIDTH_PUNCTUM+WIDTH_FLEXUSDEMINUTUS-2*LINE_WIDTH-WIDTH_DEMINUTUS),
                   (j-i)*BASE_HEIGHT)
    set_width(glyphnumber, WIDTH_PUNCTUM+WIDTH_FLEXUSDEMINUTUS-LINE_WIDTH)
    end_glyph(glyphnumber)


def porrectusflexus():
    message("porrectus flexus")
    precise_message("porrectus flexus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(i, j, k, "base7", 0, 'porrectusflexus_nobar')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(i, j, k, "base7", 1, 'porrectusflexus')
    precise_message("porrectus flexus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(i, j, k, "auctusd1", 0, 'porrectusflexus_nobar',
                                      'auctusdescendens')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(i, j, k, "auctusd1", 1, 'porrectusflexus',
                                      'auctusdescendens')
    precise_message("porrectus flexus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(i, j, k, "auctusa1", 0, 'porrectusflexus_nobar',
                                      'auctusascendens')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(i, j, k, "auctusa1", 1, 'porrectusflexus',
                                      'auctusascendens')
    precise_message("porrectus flexus deminutus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(i, j, k, "deminutus", 0, 'porrectusflexus_nobar',
                                      'deminutus')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(i, j, k, "deminutus", 1, 'porrectusflexus',
                                      'deminutus')

def write_porrectusflexus(i, j, k, last_glyph, with_bar, shape, liquescentia='nothing'):
    glyphnumber = gnumber(i, j, k, shape, liquescentia)
    length = PORRECTUSFLEXUSWIDTHS[i-1]
    if j == 1:
        first_glyph = "porrectusflexusnb%d" % i
    else:
        first_glyph = "porrectusflexus%d" % i
    if (with_bar):
        write_first_bar(i, glyphnumber)
    simple_paste(first_glyph, glyphnumber)
    write_line(j, glyphnumber, length-LINE_WIDTH, (-i+1)*BASE_HEIGHT)
    if (last_glyph == "deminutus"):
        if j == 1:
            write_deminutus(j-i, k, glyphnumber, length, with_bar, firstbar=0)
            length = length+WIDTH_FLEXUSDEMINUTUS
        else:
            write_deminutus(j-i, k, glyphnumber, length-LINE_WIDTH, with_bar, firstbar=1)
            length = length+WIDTH_FLEXUSDEMINUTUS-LINE_WIDTH
    else:
        simplify(glyphnumber)
        middle_glyph = 'base3'
        if j == 1:
            if k == 1:
                middle_glyph = '_0017'
            else:
                middle_glyph = 'base2'
        else:
            length = length-LINE_WIDTH
            if k == 1:
                middle_glyph = 'base4'
        paste_and_move(middle_glyph, glyphnumber, length, (j-i)*BASE_HEIGHT)
        if k == 1:
            if last_glyph == 'base7':
                last_glyph = '_0017'
            elif last_glyph == 'auctusa1':
                last_glyph = '_0072'
            elif last_glyph == 'auctusd1':
                last_glyph = '_0073'
            length = length+WIDTH_PUNCTUM
        else:
            write_line(k, glyphnumber, length + WIDTH_PUNCTUM - LINE_WIDTH, (j-i-k+1)*BASE_HEIGHT)
            length = length + WIDTH_PUNCTUM - LINE_WIDTH
        paste_and_move(last_glyph, glyphnumber, length, (j-i-k)*BASE_HEIGHT)
        length = length+ WIDTH_PUNCTUM
    set_width(glyphnumber, length)
    end_glyph(glyphnumber)

def torculus():
    message("torculus")
    precise_message("torculus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(i, j, "base5", "base7", 'torculus')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(i, j, "qbase", "base7", 'torculusquilisma')
    precise_message("torculus initio debilis")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(i, j, "idebilis", "base7", 'torculus', 'initiodebilis')
    precise_message("torculus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(i, j, "base5", "auctusd1", 'torculus', 'auctusdescendens')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(i, j, "qbase", "auctusd1", 'torculusquilisma',
                           'auctusdescendens')
    precise_message("torculus initio debilis auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(i, j, "idebilis", "auctusd1", 'torculus',
                           'initiodebilisauctusdescendens')
    precise_message("torculus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(i, j, "base5", "auctusa1", 'torculus', 'auctusascendens')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(i, j, "qbase", "auctusa1", 'torculusquilisma',
                           'auctusascendens')
    precise_message("torculus initio debilis auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(i, j, "idebilis", "auctusa1", 'torculus',
                           'initiodebilisauctusascendens')
    precise_message("torculus deminutus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(i, j, "base5", "deminutus", 'torculus', 'deminutus')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(i, j, "qbase", "deminutus", 'torculusquilisma',
                           'deminutus')
    precise_message("torculus initio debilis deminutus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(i, j, "idebilis", "deminutus", 'torculus',
                           'initiodebilisdeminutus')

def write_torculus(i, j, first_glyph, last_glyph, shape, liquescentia='nothing'):
    glyphnumber = gnumber(i, j, 0, shape, liquescentia)
    length = WIDTH_PUNCTUM-LINE_WIDTH
    if (first_glyph == "idebilis"):
        length = WIDTH_DEBILIS
    elif first_glyph == "qbase":
        length = WIDTH_QUILISMA-LINE_WIDTH
        if i == 1:
            first_glyph = '_0026'
            length = WIDTH_QUILISMA
    elif i == 1:
        first_glyph = '_0017'
        length = WIDTH_PUNCTUM+0.1
    simple_paste(first_glyph, glyphnumber)
    if i != 1:
        write_line(i, glyphnumber, length, BASE_HEIGHT)
    if (last_glyph == "deminutus"):
        if i == 1:
            write_deminutus(i, j, glyphnumber, length, firstbar=0)
        else:
            write_deminutus(i, j, glyphnumber, length, firstbar=1)
        length = length+WIDTH_FLEXUSDEMINUTUS
    else:
        if j == 1:
            if i == 1:
                paste_and_move("_0017", glyphnumber, length, i*BASE_HEIGHT)
            else:
                paste_and_move("base4", glyphnumber, length, i*BASE_HEIGHT)
            length = length+WIDTH_PUNCTUM
            if last_glyph == 'base7':
                last_glyph = '_0017'
            elif last_glyph == 'auctusa1':
                last_glyph = '_0072'
            elif last_glyph == 'auctusd1':
                last_glyph = '_0073'
        else:
            if i == 1:
                paste_and_move("base2", glyphnumber, length, i*BASE_HEIGHT)
            else:
                paste_and_move("base3", glyphnumber, length, i*BASE_HEIGHT)
            length = length+WIDTH_PUNCTUM-LINE_WIDTH
            write_line(j, glyphnumber, length, (i-j+1)*BASE_HEIGHT)
        paste_and_move(last_glyph, glyphnumber, length, (i-j)*BASE_HEIGHT)
        length = length+WIDTH_PUNCTUM
    set_width(glyphnumber, length)
    end_glyph(glyphnumber)

def torculus_liquescens():
    precise_message("torculus liquescens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculus_liquescens(i, j, k, 'base5',
                                          'torculus_liquescens', 'deminutus')
    precise_message("torculus liquescens quilisma")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculus_liquescens(i, j, k, 'qbase',
                                          'torculus_liquescens_quilisma', 'deminutus')

def write_torculus_liquescens(i, j, k, first_glyph, shape, liquescentia='deminutus'):
    glyphnumber = gnumber(i, j, k, shape, liquescentia)
    length = WIDTH_PUNCTUM-LINE_WIDTH
    if first_glyph == "qbase":
        length = WIDTH_QUILISMA-LINE_WIDTH
        if i == 1:
            first_glyph = '_0026'
            length = WIDTH_QUILISMA
    elif i == 1:
        first_glyph = '_0017'
        length = WIDTH_PUNCTUM+0.1
    simple_paste(first_glyph, glyphnumber)
    if i != 1:
        write_line(i, glyphnumber, length, BASE_HEIGHT)
    flexus_firstbar = 2
    if j == 1:
        flexus_firstbar = 0
        if i == 1:
            paste_and_move("_0017", glyphnumber, length, i*BASE_HEIGHT)
        else:
            paste_and_move("base4", glyphnumber, length, i*BASE_HEIGHT)
        length = length+WIDTH_PUNCTUM
    else:
        if i == 1:
            paste_and_move("base2", glyphnumber, length, i*BASE_HEIGHT)
        else:
            paste_and_move("base3", glyphnumber, length, i*BASE_HEIGHT)
        length = length+WIDTH_PUNCTUM-LINE_WIDTH
        write_line(j, glyphnumber, length, (i-j+1)*BASE_HEIGHT)
    write_deminutus(i-j, k, glyphnumber, length, firstbar=flexus_firstbar)
    length = length+WIDTH_FLEXUSDEMINUTUS
    set_width(glyphnumber, length)
    end_glyph(glyphnumber)

def torculusresupinus():
    message("torculus resupinus")
    precise_message("torculus resupinus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(i, j, k, 'base5', 'phigh',
                                        'torculusresupinus')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(i, j, k, 'idebilis', 'phigh',
                                        'torculusresupinus', 'initiodebilis')
    precise_message("torculus resupinus deminutus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinusdeminutus(i, j, k, 'base5',
                                                 'torculusresupinus', 'deminutus')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinusdeminutus(i, j, k, 'idebilis',
                                                 'torculusresupinus',
                                                 'initiodebilisdeminutus')
    precise_message("torculus resupinus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(i, j, k, 'base5', "auctusa2",
                                        'torculusresupinus', 'auctusascendens')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(i, j, k, 'idebilis', "auctusa2",
                                        'torculusresupinus',
                                        'initiodebilisauctusascendens')
    precise_message("torculus resupinus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(i, j, k, 'base5', "auctusd2",
                                        'torculusresupinus',
                                        'auctusdescendens')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(i, j, k, 'idebilis',
                                        "auctusd2",
                                        'torculusresupinus',
                                        'initiodebilisauctusdescendens')

def write_torculusresupinus(i, j, k, first_glyph, last_glyph, shape, liquescentia='nothing'):
    glyphnumber = gnumber(i, j, k, shape, liquescentia)
    if first_glyph == "idebilis":
        length = WIDTH_DEBILIS
    elif i == 1:
        if first_glyph == 'base5':
            first_glyph = '_0017'
            length = WIDTH_PUNCTUM+0.1
    else:
        if first_glyph == 'base5':
            length = WIDTH_PUNCTUM-LINE_WIDTH
    simple_paste(first_glyph, glyphnumber)
    if i != 1:
        write_line(i, glyphnumber, length, BASE_HEIGHT)
    middle_glyph = "porrectus%d" % j
    if (last_glyph == 'auctusa2' or last_glyph == 'auctusd2'):
        if (k == 1):
            middle_glyph = "porrectusflexusnb%d" % j
        else:
            middle_glyph = "porrectusflexus%d" % j
    paste_and_move(middle_glyph, glyphnumber, length, i*BASE_HEIGHT)
    if (last_glyph == 'auctusa2' or last_glyph == 'auctusd2'):
        length = length + PORRECTUSFLEXUSWIDTHS[j-1]
    else:
        length = length + PORRECTUSWIDTHS[j-1]
    if ((last_glyph != 'auctusa2' and last_glyph != 'auctusd2') or k != 1):
        write_line(k, glyphnumber, length-LINE_WIDTH, (i-j+1)*BASE_HEIGHT)
    simplify(glyphnumber)
    if (last_glyph == "rdeminutus"):
        paste_and_move(last_glyph, glyphnumber,
                       (length-WIDTH_DEMINUTUS-LINE_WIDTH), (i-j+k)*BASE_HEIGHT)
    elif (last_glyph == 'auctusa2' or last_glyph == 'auctusd2'):
        if (last_glyph == 'auctusa2' and k == 1):
            last_glyph = '_0072'
        elif (last_glyph == 'auctusd2' and k == 1):
            last_glyph = '_0073'
        if (k == 1):
            length = length+LINE_WIDTH
        paste_and_move(last_glyph, glyphnumber, (length-LINE_WIDTH), (i-j+k)*BASE_HEIGHT)
        length = length - LINE_WIDTH + WIDTH_PUNCTUM
    else:
        paste_and_move(last_glyph, glyphnumber, (length-WIDTH_HIGH_PES), (i-j+k)*BASE_HEIGHT)
    set_width(glyphnumber, length)
    end_glyph(glyphnumber)

def write_torculusresupinusdeminutus(i, j, k, first_glyph, shape, liquescentia='nothing'):
    glyphnumber = gnumber(i, j, k, shape, liquescentia)
    length = WIDTH_PUNCTUM-LINE_WIDTH
    if (first_glyph == "idebilis"):
        length = WIDTH_DEBILIS
    elif i == 1:
        first_glyph = '_0017'
        length = WIDTH_PUNCTUM+0.1
    simple_paste(first_glyph, glyphnumber)
    if i != 1:
        write_line(i, glyphnumber, length, BASE_HEIGHT)
    if j == 1 and i == 1:
        if first_glyph == "idebilis":
            paste_and_move("base4", glyphnumber, length, i*BASE_HEIGHT)
            length = length+WIDTH_PUNCTUM
            last_glyph = 'mnbpdeminutus'
        else:
            paste_and_move("_0017", glyphnumber, length, i*BASE_HEIGHT)
            length = length+WIDTH_PUNCTUM
            last_glyph = 'mnbpdeminutus'
    elif j == 1:
        paste_and_move("base4", glyphnumber, length, i*BASE_HEIGHT)
        length = length+WIDTH_PUNCTUM
        last_glyph = 'mnbpdeminutus'
    elif i == 1 and first_glyph != "idebilis":
        paste_and_move("base2", glyphnumber, length, i*BASE_HEIGHT)
        length = length+WIDTH_PUNCTUM-LINE_WIDTH
        write_line(j, glyphnumber, length, (i-j+1)*BASE_HEIGHT)
        last_glyph = 'mpdeminutus'
    else:
        paste_and_move("base3", glyphnumber, length, i*BASE_HEIGHT)
        length = length+WIDTH_PUNCTUM-LINE_WIDTH
        write_line(j, glyphnumber, length, (i-j+1)*BASE_HEIGHT)
        last_glyph = 'mpdeminutus'
    paste_and_move(last_glyph, glyphnumber, length, (i-j)*BASE_HEIGHT)
    length = length+WIDTH_FLEXUSDEMINUTUS
    write_line(k, glyphnumber, length-LINE_WIDTH, (i-j+1)*BASE_HEIGHT)
    paste_and_move('rdeminutus', glyphnumber,
                   length-WIDTH_DEMINUTUS-LINE_WIDTH, (i-j+k)*BASE_HEIGHT)
    set_width(glyphnumber, length)
    end_glyph(glyphnumber)

def scandicus():
    message("scandicus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_scandicus(i, j, 'phigh')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_scandicus(i, j, 'rdeminutus', 'deminutus')

def write_scandicus(i, j, last_glyph, liquescentia='nothing'):
    glyphnumber = gnumber(i, j, 0, 'scandicus', liquescentia)
    # special case of i=j=1, we use glyph 1025 directly
    if i == 1 and j == 1 and liquescentia == 'nothing':
        simple_paste('_0017', glyphnumber)
        second_glyph = '_1025'
        paste_and_move(second_glyph, glyphnumber, WIDTH_PUNCTUM, BASE_HEIGHT)
        set_width(glyphnumber, 2*WIDTH_PUNCTUM)
        end_glyph(glyphnumber)
        return
    if i == 1:
        simple_paste('_0017', glyphnumber)
        length = WIDTH_PUNCTUM
        second_glyph = 'p2base'
        if liquescentia == 'deminutus':
            second_glyph = 'mnbpdeminutus'
    else:
        simple_paste('base5', glyphnumber)
        length = WIDTH_PUNCTUM - LINE_WIDTH
        write_line(i, glyphnumber, length, BASE_HEIGHT)
        second_glyph = 'msdeminutus'
    paste_and_move(second_glyph, glyphnumber, length, i*BASE_HEIGHT)
    if (i == 1) and liquescentia == 'nothing':
        length = length + WIDTH_PUNCTUM
    else:
        length = length + WIDTH_FLEXUSDEMINUTUS
    if j != 1:
        write_line(j, glyphnumber, length - LINE_WIDTH, (i+1) * BASE_HEIGHT)
    if last_glyph == 'rdeminutus':
        paste_and_move('rdeminutus', glyphnumber,
                       length - WIDTH_DEMINUTUS - LINE_WIDTH, (i+j)*BASE_HEIGHT)
    else:
        paste_and_move(last_glyph, glyphnumber, length - WIDTH_HIGH_PES, (i+j)*BASE_HEIGHT)
    set_width(glyphnumber, length)
    end_glyph(glyphnumber)

def ancus():
    message("ancus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_ancus(i, j, 'vsbase', 'ancus')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_ancus(i, j, 'vlbase', 'ancus_longqueue')

def write_ancus(i, j, first_glyph, glyph_type):
    glyphnumber = gnumber(i, j, 0, glyph_type, 'deminutus')
    if i == 1:
        length = WIDTH_PUNCTUM
        second_glyph = 'mnbdeminutus'
        if first_glyph == 'vsbase':
            first_glyph = '_0025'
        else:
            first_glyph = '_0024'
    else:
        length = WIDTH_PUNCTUM - LINE_WIDTH
        second_glyph = 'mademinutus'
    simple_paste(first_glyph, glyphnumber)
    if i != 1:
        write_line(i, glyphnumber, length, (-i+1)*BASE_HEIGHT)
    paste_and_move(second_glyph, glyphnumber, length, -(i)*BASE_HEIGHT)
    length = length + WIDTH_FLEXUSDEMINUTUS
    if j != 1:
        write_line(j, glyphnumber, length - LINE_WIDTH, (-i-j+1) * BASE_HEIGHT)
    paste_and_move('deminutus', glyphnumber,
                   length - WIDTH_DEMINUTUS - LINE_WIDTH, (-i-j)*BASE_HEIGHT)
    set_width(glyphnumber, length)
    end_glyph(glyphnumber)

if __name__ == "__main__":
    main()
