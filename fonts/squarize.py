#!./fontforge_python.sh
# coding=utf-8
# pylint: disable=too-many-branches, too-many-arguments, too-many-lines
# pylint: disable=import-error, no-member

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
import subprocess
import os

os.chdir(sys.path[0])


GPLV3 = """Gregorio is free software: you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

Gregorio is distributed in the hope that it will be useful, but
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

# defines the maximal interval between two notes, the bigger this number is,
# the more glyphs you'll have to generate
MAX_INTERVAL = 5

# this dictionary must have a value for 1 up to MAX_INTERVAL
AMBITUS = {
    1: 'One',
    2: 'Two',
    3: 'Three',
    4: 'Four',
    5: 'Five',
}

# The unicode character at which we start our numbering:
# U+E000 is the start of the BMP Private Use Area
glyphnumber = 0xe000 - 1

BASE_HEIGHT = 157.5
oldfont = None
newfont = None
font_name = None
all_glyph_names = {}

def usage():
    "Prints the help message."
    print(""" Python script to convert a small set of glyphs into a complete
gregorian square notation font. The initial glyphs have a name
convention, see gregorio-base.sfd for this convention.

Usage:
        squarize.py fontname

with fontname=gregorio, parmesan or greciliae.""")

def main():
    "Main function"
    global oldfont, newfont, font_name
    proc = subprocess.Popen(['../VersionManager.py', '-c'], stdout=subprocess.PIPE)
    version = proc.stdout.read().strip('\n')
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
    else:
        usage()
        sys.exit(2)
    # the fonts
    oldfont = fontforge.open("%s-base.sfd" % font_name)
    newfont = fontforge.font()
    # newfont.encoding = "UnicodeFull"
    newfont.encoding = "ISO10646-1"
    newfont.fontname = "%s" % font_name
    newfont.fullname = "%s" % font_name
    newfont.familyname = "%s" % font_name
    newfont.version = version
    if font_name == "greciliae":
        newfont.copyright = """Greciliae font
Copyright (C) 2007 Matthew Spencer with Reserved Font Name "Caeciliae",
Copyright (C) 2007-2015 The Gregorio Project (see CONTRIBUTORS.md)
with Reserved Font Name "Greciliae".

This Font Software is licensed under the SIL Open Font License, Version 1.1.
This license is also available with a FAQ at:
http://scripts.sil.org/OFL"""
    elif font_name == "gregorio":
        newfont.copyright = """Font named "gregorio"
Copyright (C) 2007-2015 The Gregorio Project (see CONTRIBUTORS.md)
This file is part of Gregorio.

"""+GPLV3
    elif font_name == "parmesan":
        newfont.copyright = """LilyPond's pretty-but-neat music font, adapted to the Gregorio Project.
Copyright (C) 2002-2006 Juergen Reuter <reuter@ipd.uka.de>
Copyright (C) 2007-2015 The Gregorio Project (see CONTRIBUTORS.md)
This file is part of Gregorio.

"""+GPLV3
    newfont.weight = "regular"
    initialize_glyphs()
    font_width = get_lengths(font_name)
    hepisemus(font_width)
    pes(font_width)
    pes_quadratum(font_width)
    virga_strata(font_width)
    flexus(font_width)
    scandicus(font_width)
    ancus(font_width)
    salicus(font_width)
    torculus(font_width)
    torculus_liquescens(font_width)
    porrectus(font_width)
    porrectusflexus(font_width)
    torculusresupinus(font_width)
    # variants must be copied last!
    copy_variant_glyphs()
    newfont.generate("%s.ttf" % font_name)
    oldfont.close()
    newfont.close()

def new_glyph():
    global newfont, glyphnumber
    glyphnumber += 1
    if glyphnumber > 0xf8ff:
        print("WARNING: exceeded private use area")

    newfont.selection.select('u%05x' % glyphnumber)

def set_glyph_name(name):
    global all_glyph_names, newfont, glyphnumber
    if name in all_glyph_names:
        print("ERROR: duplicate glyph name [%s]" % name, file=sys.stderr)
        sys.exit(1)
    else:
        all_glyph_names[name] = True
    newfont[glyphnumber].glyphname = name

def message(glyph_name):
    """Prints a message to stdout, so that the user gets less bored when
    building the font

    """
    print("generating", glyph_name, "for", font_name)

def precise_message(glyph_name):
    "Prints more information to entertain the user."
    print("  *", glyph_name)

# These names must consist wholly of ASCII letters
DIRECT_GLYPH_NAMES = [
    'CClef',
    'FClef',
    'CClefChange',
    'FClefChange',
    'Flat',
    'Natural',
    'Virgula',
    'DivisioMinima',
    'DivisioMinor',
    'DivisioMaior',
    'PunctumDeminutus',
    'AuctumMora',
    'AuctumDuplex',
    'Circumflexus',
    'Punctum',
    'PunctumInclinatum',
    'Stropha',
    'StrophaAucta',
    'VirgaLongqueue',
    'Virga',
    'VirgaReversaLongqueue',
    'VirgaReversa',
    'Quilisma',
    'Oriscus',
    'OriscusReversus',
    'OriscusScapusLongqueue',
    'OriscusScapus',
    'PunctumInclinatumAuctus',
    'PunctumInclinatumDeminutus',
    'VEpisemus',
    'PunctumCavum',
    'LineaPunctum',
    'LineaPunctumCavum',
    'Circulus',
    'Semicirculus',
    'Accentus',
    'CustosUpLong',
    'CustosUpShort',
    'CustosUpMedium',
    'CustosDownLong',
    'CustosDownShort',
    'CustosDownMedium',
    'AccentusReversus',
    'SemicirculusReversus',
    'PunctumAscendens',
    'PunctumDescendens',
    'PunctumForMeasurement',
    'PunctumCavumHole',
    'LineaPunctumCavumHole',
    'FlatHole',
    'NaturalHole',
    'DivisioDominican',
    'DivisioDominicanAlt',
    'Sharp',
    'SharpHole',
    'Linea',
    'RoundBrace',
    'CurlyBrace',
    'BarBrace',
    'OriscusDeminutus',
    'VirgaReversaDescendens',
    'VirgaReversaDescendensLongqueue',
    'PesOneNothing',
    'PesQuilismaOneNothing',
]

def initialize_glyphs():
    "Builds the first glyphs."
    global newfont, oldfont, font_name
    # DIRECT_GLYPH_NAMES are the names of the glyphs that are already in
    # gregorio_base, mostly one-note glyphs.
    DIRECT_GLYPH_NAMES.sort()

    for name in DIRECT_GLYPH_NAMES:
        new_glyph()
        oldfont.selection.select(name)
        oldfont.copy()
        newfont.paste()
        set_glyph_name(name)

def copy_variant_glyphs():
    "Copies the variant glyphs."
    global newfont, oldfont
    for glyph in oldfont.glyphs():
        if glyph.isWorthOutputting() and glyph.glyphname.find(".") > 0:
            new_glyph()
            oldfont.selection.select(glyph)
            oldfont.copy()
            newfont.paste()
            set_glyph_name(glyph.glyphname)

def get_lengths(fontname):
    "Initialize widths depending on the font."
    lengths = {}
    if fontname == "gregorio":
        lengths = dict(line_width=22, # some width, necessary to know
                       # where to draw lines, squares, etc. first the
                       # width of the lines that link notes, like in a
                       # pes for example
                       #
                       # then the width of a punctum, we assume that
                       # it is the same width for oriscus, quilisma,
                       # punctum auctum descendens and punctum auctum
                       # ascendens
                       width_punctum=164,
                       # width_oriscus is the width of an oriscus,
                       # idem for quilisma
                       width_oriscus=164,
                       width_quilisma=164,
                       # width_oriscus_rev is the width of an oriscus
                       # reversus
                       width_oriscus_rev=164,
                       # the width of the first note of an initio
                       # debilis, and the one of the last note of a
                       # deminutus. Warning, in GregorioTeX they must
                       # be the same! you must (almost always) add the
                       # width of a line to have the real width.
                       width_debilis=88,
                       width_deminutus=88,
                       # width of a punctum inclinatum (we consider
                       # that the punctum inclinatum auctus has the
                       # same width
                       width_inclinatum=164,
                       # width of a stropha (idem for the stropha aucta)
                       width_stropha=164,
                       # width of the second (highest) note of a pes
                       width_high_pes=154,
                       # width of the punctum inclinatum deminutus (no
                       # need to add the width of a line)
                       width_inclinatum_deminutus=82,
                       # width of the note which is just before a
                       # deminutus, in some fonts it is not the same
                       # width as a punctum
                       width_flexusdeminutus=186,
                       # the width of the torculus resupinus, five in
                       # total, one per note difference between the
                       # two first notes (for example the first is the
                       # width of the first two notes of baba
                       porrectusflexuswidths=(340, 428, 586, 670, 931),
                       porrectuswidths=(490, 575, 650, 740, 931),
                       # width that will be added to the standard
                       # width when we will build horizontal
                       # episemus. for example, if a punctum has the
                       # length 164, the episemus will have the width
                       # 244 and will be centered on the center of the
                       # punctum
                       hepisemus_additional_width=5)
    elif fontname == "parmesan":
        lengths = dict(line_width=22,
                       width_punctum=161,
                       width_oriscus=192,
                       width_oriscus_rev=192,
                       width_quilisma=161,
                       width_debilis=75,
                       width_deminutus=75,
                       width_inclinatum=178,
                       width_stropha=169,
                       width_high_pes=151,
                       width_inclinatum_deminutus=112,
                       width_flexusdeminutus=161,
                       porrectusflexuswidths=(340, 428, 586, 670, 931),
                       porrectuswidths=(490, 575, 650, 740, 931),
                       hepisemus_additional_width=5)
    elif fontname == "greciliae":
        lengths = dict(line_width=18,
                       width_punctum=166,
                       width_oriscus=166,
                       width_oriscus_rev=168,
                       width_quilisma=166,
                       width_debilis=65,
                       width_deminutus=65,
                       width_inclinatum=185,
                       width_stropha=163,
                       width_high_pes=155,
                       width_inclinatum_deminutus=139,
                       width_flexusdeminutus=168,
                       porrectusflexuswidths=(503, 629, 628, 628, 931),
                       porrectuswidths=(503, 629, 628, 628, 931),
                       hepisemus_additional_width=5)
    return lengths

# Shapes
S_PES                              = 'Pes'
S_PES_QUADRATUM                    = 'PesQuadratum'
S_PES_QUADRATUM_LONGQUEUE          = 'PesQuadratumLongqueue'
S_PES_QUILISMA                     = 'PesQuilisma'
S_PES_QUASSUS                      = 'PesQuassus'
S_PES_QUASSUS_LONGQUEUE            = 'PesQuassusLongqueue'
S_PES_QUILISMA_QUADRATUM           = 'PesQuilismaQuadratum'
S_PES_QUILISMA_QUADRATUM_LONGQUEUE = 'PesQuilismaQuadratumLongqueue'
S_FLEXUS                           = 'Flexus'
S_FLEXUS_NOBAR                     = 'FlexusNobar'
S_FLEXUS_LONGQUEUE                 = 'FlexusLongqueue'
S_FLEXUS_ORISCUS                   = 'FlexusOriscus'
S_PORRECTUS_FLEXUS                 = 'PorrectusFlexus'
S_PORRECTUS_FLEXUS_NOBAR           = 'PorrectusFlexusNobar'
S_PORRECTUS                        = 'Porrectus'
S_PORRECTUS_NOBAR                  = 'PorrectusNobar'
S_TORCULUS                         = 'Torculus'
S_TORCULUS_RESUPINUS               = 'TorculusResupinus'
S_TORCULUS_QUILISMA                = 'TorculusQuilisma'
S_SCANDICUS                        = 'Scandicus'
S_ANCUS                            = 'Ancus'
S_ANCUS_LONGQUEUE                  = 'AncusLongqueue'
S_VIRGA_STRATA                     = 'VirgaStrata'
S_SALICUS                          = 'Salicus'
S_SALICUS_LONGQUEUE                = 'SalicusLongqueue'
S_TORCULUS_LIQUESCENS              = 'TorculusLiquescens'
S_TORCULUS_LIQUESCENS_QUILISMA     = 'TorculusLiquescensQuilisma'
S_FLEXUS_ORISCUS_SCAPUS            = 'FlexusOriscusScapus'
S_FLEXUS_ORISCUS_SCAPIS_LONGQUEUE  = 'FlexusOriscusScapusLongqueue'

# Liquescentiae
L_NOTHING                   = 'Nothing'
L_INITIO_DEBILIS            = 'InitioDebilis'
L_DEMINUTUS                 = 'Deminutus'
L_ASCENDENS                 = 'Ascendens'
L_DESCENDENS                = 'Descendens'
L_INITIO_DEBILIS_DEMINUTUS  = 'InitioDebilisDeminutus'
L_INITIO_DEBILIS_ASCENDENS  = 'InitioDebilisAscendens'
L_INITIO_DEBILIS_DESCENDENS = 'InitioDebilisDescendens'

def simple_paste(src):
    "Copy and past a glyph."
    global oldfont, newfont, glyphnumber
    oldfont.selection.select(src)
    oldfont.copy()
    newfont.selection.select('u%05x' % glyphnumber)
    newfont.pasteInto()
    #newfont.paste()

def simplify():
    "Simplify a glyph."
    global newfont, glyphnumber
    newfont[glyphnumber].simplify()
    newfont[glyphnumber].removeOverlap()
    newfont[glyphnumber].simplify()

def paste_and_move(src, xdimen, ydimen):
    "Pastes the src glyph into dst, and moves it with horiz and vert offsets."
    global oldfont, newfont, glyphnumber
    oldfont[src].transform(psMat.translate(xdimen, ydimen))
    oldfont.selection.select(src)
    oldfont.copy()
    newfont.selection.select('u%05x' % glyphnumber)
    newfont.pasteInto()
    oldfont[src].transform(psMat.translate(-xdimen, -ydimen))

def end_glyph(name):
    "Final function to call when building a glyph."
    global newfont, glyphnumber
    set_glyph_name(name)
    newfont[glyphnumber].simplify()
    newfont[glyphnumber].simplify()
    newfont[glyphnumber].removeOverlap()
    newfont[glyphnumber].simplify()
    newfont[glyphnumber].canonicalContours()
    newfont[glyphnumber].canonicalStart()

def scale(xdimen, ydimen):
    "Scales a glyph, horizontally by x and vertically by y"
    global newfont, glyphnumber
    newfont[glyphnumber].transform(psMat.scale(xdimen, ydimen))

def move(xdimen, ydimen):
    "moves a glyph, horizontally by x and vertically by y"
    global newfont, glyphnumber
    newfont[glyphnumber].transform(psMat.translate(xdimen, ydimen))

def set_width(width):
    "Set the width of a glyph"
    global newfont, glyphnumber
    newfont[glyphnumber].width = width

def write_line(i, length, height):
    "Writes a line in currently selected glyph, with length and height offsets"
    if i > 1:
        linename = "line%d" % i
        paste_and_move(linename, length, height)

def write_first_bar(i):
    """Write the first bar of a glyph. Used for porrectus flexus,
    porrectus and flexus.

    """
    paste_and_move("queue", 0, (-i+1)*BASE_HEIGHT)
    write_line(i, 0, (-i+1)*BASE_HEIGHT)

def write_deminutus(widths, i, j, length=0, tosimplify=0, firstbar=1):
    """As the glyph before a deminutus is not the same as a normal glyph,
    and always the same, we can call this function each
    time. Sometimes we have to simplify before building the last glyph
    (tosimplify=1), and length is the offset.

    """
    if firstbar == 1:
        paste_and_move("mdeminutus", length, i*BASE_HEIGHT)
    elif firstbar == 0:
        paste_and_move("mnbdeminutus", length, i*BASE_HEIGHT)
    else:
        paste_and_move("mademinutus", length, i*BASE_HEIGHT)
    write_line(j, length+widths['width_flexusdeminutus']-widths['line_width'],
               (i-j+1)*BASE_HEIGHT)
    if tosimplify:
        simplify()
    paste_and_move("deminutus",
                   length+widths['width_flexusdeminutus']-widths['width_deminutus']-
                   widths['line_width'], (i-j)*BASE_HEIGHT)

def hepisemus(widths):
    "Creates horizontal episemae."
    message("horizontal episemus")
    write_hepisemus(widths, widths['width_punctum'], 'HEpisemusPunctum')
    write_hepisemus(widths, widths['width_flexusdeminutus'], 'HEpisemusFlexusDeminutus')
    write_hepisemus(widths, widths['width_debilis']+widths['line_width'], 'HEpisemusDebilis')
    write_hepisemus(widths, widths['width_inclinatum'], 'HEpisemusInclinatum')
    write_hepisemus(widths, widths['width_inclinatum_deminutus'], 'HEpisemusInclinatumDeminutus')
    write_hepisemus(widths, widths['width_stropha'], 'HEpisemusStropha')
    write_hepisemus(widths, widths['width_quilisma'], 'HEpisemusQuilisma')
    write_hepisemus(widths, widths['width_high_pes'], 'HEpisemusHighPes')
    write_hepisemus(widths, widths['width_oriscus'], 'HEpisemusOriscus')
    for i in range(MAX_INTERVAL):
        write_hepisemus(widths, widths['porrectuswidths'][i], 'HEpisemusPorrectus%s' % AMBITUS[i + 1])
    for i in range(MAX_INTERVAL):
        write_hepisemus(widths, widths['porrectusflexuswidths'][i], 'HEpisemusPorrectusFlexus%s' % AMBITUS[i + 1])

def write_hepisemus(widths, shape_width, glyphname):
    "Writes the horizontal episemus glyphs."
    new_glyph()
    simple_paste("hepisemus_base")
    scale(shape_width + 2*widths['hepisemus_additional_width'], 1)
    move(-widths['hepisemus_additional_width'], 0)
    paste_and_move("hepisemusleft", -widths['hepisemus_additional_width'], 0)
    paste_and_move("hepisemusright",
                   shape_width + widths['hepisemus_additional_width'], 0)
    set_width(shape_width)
    end_glyph(glyphname)

def pes(widths):
    "Creates the pes."
    message("pes")
    precise_message("pes")
    # we prefer drawing the pes with ambitus of one by hand, it is more beautiful
    for i in range(2, MAX_INTERVAL+1):
        write_pes(widths, i, "p2base", S_PES)
    precise_message("pes quilisma")
    # idem for the pes quilisma
    for i in range(2, MAX_INTERVAL+1):
        write_pes(widths, i, "qbase", S_PES_QUILISMA)
    precise_message("pes deminutus")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_deminutus(widths, i, "pesdeminutus", S_PES, L_DEMINUTUS)
    precise_message("pes initio debilis")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_debilis(widths, i, S_PES, L_INITIO_DEBILIS)
    precise_message("pes initio debilis deminutus")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_debilis_deminutus(widths, i, S_PES, L_INITIO_DEBILIS_DEMINUTUS)

def write_pes(widths, i, first_glyph, shape, lique=L_NOTHING):
    "Writes the pes glyphs."
    new_glyph()
    temp_width = 0
    # the difference of width of the two shapes, that will change a thing or two...
    if first_glyph == "qbase":
        width_difference = widths['width_quilisma']-widths['width_high_pes']
    elif first_glyph == "pbase" or first_glyph == "p2base":
        width_difference = widths['width_punctum']-widths['width_high_pes']
    else:
        width_difference = 0
    if width_difference < 0:
        paste_and_move(first_glyph, -width_difference, 0)
    else:
        simple_paste(first_glyph)
    if first_glyph == "qbase":
        temp_width = widths['width_quilisma']-widths['line_width']
    else:
        temp_width = widths['width_punctum']-widths['line_width']
    if width_difference < 0:
        temp_width = temp_width-width_difference
    write_line(i, temp_width, BASE_HEIGHT)
    if width_difference != 0:
        paste_and_move('phigh', width_difference, i*BASE_HEIGHT)
    else:
        paste_and_move('phigh', 0, i*BASE_HEIGHT)
    if width_difference < 0:
        set_width(widths['width_punctum'])
    else:
        set_width(widths['width_quilisma'])
    end_glyph('%s%s%s' % (shape, AMBITUS[i], lique))

def write_pes_debilis(widths, i, shape, lique=L_NOTHING):
    "Writes the pes debilis glyphs."
    new_glyph()
    # with a deminutus it is much more beautiful than with a idebilis
    paste_and_move("deminutus", 0, 0)
    write_line(i, widths['width_debilis'], BASE_HEIGHT)
    simplify()
    paste_and_move("base4", widths['width_debilis'], i*BASE_HEIGHT)
    set_width(widths['width_punctum']+widths['width_debilis'])
    end_glyph('%s%s%s' % (shape, AMBITUS[i], lique))

def write_pes_deminutus(widths, i, first_glyph, shape, lique=L_NOTHING):
    "Writes the pes deminutus glyphs."
    new_glyph()
    temp_width = 0
    simple_paste(first_glyph)
    if first_glyph == "qbase":
        temp_width = widths['width_quilisma']-widths['line_width']
    else:
        temp_width = widths['width_punctum']-widths['line_width']
    write_line(i, temp_width, BASE_HEIGHT)
    paste_and_move("rdeminutus",
                   widths['width_punctum']-widths['line_width']-widths['width_deminutus'],
                   i*BASE_HEIGHT)
    set_width(widths['width_punctum'])
    end_glyph('%s%s%s' % (shape, AMBITUS[i], lique))

def write_pes_debilis_deminutus(widths, i, shape, lique=L_NOTHING):
    "Writes the pes debilis deminutus glyphs."
    new_glyph()
    simple_paste("deminutus")
    write_line(i, widths['width_debilis'], BASE_HEIGHT)
    simplify()
    paste_and_move("rdeminutus", 0, i*BASE_HEIGHT)
    set_width(widths['width_debilis']+widths['line_width'])
    end_glyph('%s%s%s' % (shape, AMBITUS[i], lique))

def pes_quadratum(widths):
    "Makes the pes quadratum."
    message("pes quadratum")
    precise_message("pes quadratum")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "base5", "rvsbase", S_PES_QUADRATUM)
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "base5", "rvlbase", S_PES_QUADRATUM_LONGQUEUE)
    precise_message("pes quassus")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "obase", "rvsbase", S_PES_QUASSUS)
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "obase", "rvlbase", S_PES_QUASSUS_LONGQUEUE)
    precise_message("pes quilisma quadratum")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "qbase", "rvsbase", S_PES_QUILISMA_QUADRATUM)
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "qbase",
                            "rvlbase", S_PES_QUILISMA_QUADRATUM_LONGQUEUE)
    precise_message("pes auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "base5",
                            "auctusa2", S_PES_QUADRATUM, L_ASCENDENS)
    precise_message("pes initio debilis auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "idebilis",
                            "auctusa2", S_PES_QUADRATUM,
                            L_INITIO_DEBILIS_ASCENDENS)
    precise_message("pes quassus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "obase",
                            "auctusa2", S_PES_QUASSUS, L_ASCENDENS)
    precise_message("pes quilisma auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "qbase",
                            "auctusa2", S_PES_QUILISMA_QUADRATUM,
                            L_ASCENDENS)
    precise_message("pes auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "base5",
                            "auctusd2", S_PES_QUADRATUM, L_DESCENDENS)
    precise_message("pes initio debilis auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "idebilis",
                            "auctusd2", S_PES_QUADRATUM,
                            L_INITIO_DEBILIS_DESCENDENS)
    precise_message("pes quassus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "obase",
                            "auctusd2", S_PES_QUASSUS, L_DESCENDENS)
    precise_message("pes quilisma auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "qbase", "auctusd2", S_PES_QUILISMA_QUADRATUM,
                            L_DESCENDENS)

def write_pes_quadratum(widths, i, first_glyph, last_glyph, shape, lique=L_NOTHING):
    "Writes the pes quadratum glyphs."
    new_glyph()
    if first_glyph == "idebilis":
        first_width = widths['width_deminutus']
    elif first_glyph == "base5":
        if i == 1:
            first_glyph = 'Punctum'
            if last_glyph == 'base7':
                last_glyph = 'Punctum'
            elif last_glyph == 'auctusa2':
                last_glyph = 'PunctumAscendens'
            elif last_glyph == 'auctusd2':
                last_glyph = 'PunctumDescendens'
            elif last_glyph == 'rvsbase':
                last_glyph = 'Virga'
            elif last_glyph == 'rvlbase':
                last_glyph = 'VirgaLongqueue'
            first_width = widths['width_punctum']
        else:
            first_width = widths['width_punctum']-widths['line_width']
    elif first_glyph == "obase":
        first_width = widths['width_oriscus']-widths['line_width']
    else:
        first_width = widths['width_quilisma']-widths['line_width']
    simple_paste(first_glyph)
    if i != 1:
        linename = "line%d" % i
        paste_and_move(linename, first_width, BASE_HEIGHT)
    paste_and_move(last_glyph, first_width, i*BASE_HEIGHT)
    set_width(first_width+widths['width_punctum'])
    end_glyph('%s%s%s' % (shape, AMBITUS[i], lique))

def virga_strata(widths):
    "Creates the virga strata."
    precise_message("virga strata")
    for i in range(1, MAX_INTERVAL+1):
        write_virga_strata(widths, i, "base5", "obase4", S_VIRGA_STRATA)

def write_virga_strata(widths, i, first_glyph, last_glyph, shape, lique=L_NOTHING):
    "Writes the virga strata glyphs."
    new_glyph()
    if i == 1:
        first_glyph = 'Punctum'
        first_width = widths['width_punctum']
        last_glyph = 'Oriscus'
    else:
        first_width = widths['width_punctum']-widths['line_width']
    simple_paste(first_glyph)
    if i != 1:
        linename = "line%d" % i
        paste_and_move(linename, first_width, BASE_HEIGHT)
    paste_and_move(last_glyph, first_width, i*BASE_HEIGHT)
    set_width(first_width+widths['width_oriscus'])
    end_glyph('%s%s%s' % (shape, AMBITUS[i], lique))

def salicus(widths):
    "Creates the salicus."
    message("salicus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_salicus(widths, i, j, "rvsbase", S_SALICUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_salicus(widths, i, j, "rvlbase", S_SALICUS_LONGQUEUE)

def write_salicus(widths, i, j, last_glyph, shape, lique=L_NOTHING):
    "Writes the salicus glyphs."
    new_glyph()
    if j == 1:
        if last_glyph == 'rvsbase':
            last_glyph = 'Virga'
        elif last_glyph == 'rvlbase':
            last_glyph = 'VirgaLongqueue'
    if i == 1 and j == 1:
        first_glyph = 'Punctum'
        first_width = widths['width_punctum']
        middle_glyph = 'Oriscus'
        middle_width = widths['width_oriscus']
    elif i == 1:
        first_glyph = 'Punctum'
        first_width = widths['width_punctum']
        middle_glyph = 'obase'
        middle_width = widths['width_oriscus']-widths['line_width']
    elif j == 1:
        first_glyph = 'base5'
        first_width = widths['width_punctum']-widths['line_width']
        middle_glyph = 'obase4'
        middle_width = widths['width_oriscus']
    else:
        first_glyph = 'base5'
        first_width = widths['width_punctum']-widths['line_width']
        middle_glyph = 'obase8'
        middle_width = widths['width_oriscus']-widths['line_width']
    simple_paste(first_glyph)
    if i != 1:
        linename = "line%d" % i
        paste_and_move(linename, first_width, BASE_HEIGHT)
    paste_and_move(middle_glyph, first_width, i*BASE_HEIGHT)
    length = first_width+middle_width
    if j != 1:
        linename = "line%d" % j
        paste_and_move(linename, length, (i+1)*BASE_HEIGHT)
    else:
        length = length-0.01
    paste_and_move(last_glyph, length, (i+j)*BASE_HEIGHT)
    set_width(length+widths['width_punctum'])
    end_glyph('%s%s%s%s' % (shape, AMBITUS[i], AMBITUS[j], lique))

def flexus(widths):
    "Creates the flexus."
    message("flexus")
    precise_message("flexus")
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(widths, i, "base2", 'base7', S_FLEXUS_NOBAR)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(widths, i, "odbase", 'base7', S_FLEXUS_ORISCUS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(widths, i, "vbase"+str(i), 'base7', S_FLEXUS)
    write_flexus(widths, 1, "vlbase", 'base7', S_FLEXUS_LONGQUEUE)
    for i in range(2, MAX_INTERVAL+1):
        write_flexus(widths, i, "vbase"+str(i), 'base7', S_FLEXUS_LONGQUEUE)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(widths, i, "osbase"+str(i), 'base7', S_FLEXUS_ORISCUS_SCAPUS)
    write_flexus(widths, 1, "oslbase", 'base7', S_FLEXUS_ORISCUS_SCAPIS_LONGQUEUE)
    for i in range(2, MAX_INTERVAL+1):
        write_flexus(widths, i, "osbase"+str(i), 'base7',
                     S_FLEXUS_ORISCUS_SCAPIS_LONGQUEUE)
    precise_message("flexus deminutus")
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(widths, i, "mdeminutus", 'base7',
                     S_FLEXUS_NOBAR, L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(widths, i, "odbase", 'deminutus',
                     S_FLEXUS_ORISCUS, L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(widths, i, "mdeminutus", 'base7',
                     S_FLEXUS, L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(widths, i, "mdeminutus", 'base7',
                     S_FLEXUS_LONGQUEUE, L_DEMINUTUS)
    precise_message("flexus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(widths, i, "base2", 'auctusa1',
                     S_FLEXUS_NOBAR, L_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(widths, i, "odbase", 'auctusa1',
                     S_FLEXUS_ORISCUS, L_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(widths, i, "vbase"+str(i),
                     'auctusa1', S_FLEXUS, L_ASCENDENS)
    write_flexus(widths, 1, "vlbase", 'auctusa1',
                 S_FLEXUS_LONGQUEUE, L_ASCENDENS)
    for i in range(2, MAX_INTERVAL+1):
        write_flexus(widths, i, "vbase"+str(i),
                     'auctusa1', S_FLEXUS_LONGQUEUE, L_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(widths, i, "osbase"+str(i),
                     'auctusa1', S_FLEXUS_ORISCUS_SCAPUS,
                     L_ASCENDENS)
    write_flexus(widths, 1, "oslbase", 'auctusa1',
                 S_FLEXUS_ORISCUS_SCAPIS_LONGQUEUE, L_ASCENDENS)
    for i in range(2, MAX_INTERVAL+1):
        write_flexus(widths, i, "osbase"+str(i),
                     'auctusa1', S_FLEXUS_ORISCUS_SCAPIS_LONGQUEUE,
                     L_ASCENDENS)
    precise_message("flexus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(widths, i, "base2", 'auctusd1', S_FLEXUS_NOBAR,
                     L_DESCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(widths, i, "odbase", 'auctusd1', S_FLEXUS_ORISCUS,
                     L_DESCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(widths, i, "vbase"+str(i), 'auctusd1', S_FLEXUS,
                     L_DESCENDENS)
    write_flexus(widths, 1, "vlbase", 'auctusd1', S_FLEXUS_LONGQUEUE,
                 L_DESCENDENS)
    for i in range(2, MAX_INTERVAL+1):
        write_flexus(widths, i, "vbase"+str(i),
                     'auctusd1', S_FLEXUS_LONGQUEUE, L_DESCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(widths, i, "osbase"+str(i),
                     'auctusd1', S_FLEXUS_ORISCUS_SCAPUS,
                     L_DESCENDENS)
    write_flexus(widths, 1, "oslbase", 'auctusd1',
                 S_FLEXUS_ORISCUS_SCAPIS_LONGQUEUE,
                 L_DESCENDENS)
    for i in range(2, MAX_INTERVAL+1):
        write_flexus(widths, i, "osbase"+str(i),
                     'auctusd1', S_FLEXUS_ORISCUS_SCAPIS_LONGQUEUE,
                     L_DESCENDENS)

def write_flexus(widths, i, first_glyph, last_glyph, shape, lique=L_NOTHING):
    # pylint: disable=too-many-statements
    "Writes the flexus glyphs."
    new_glyph()
    # we add a queue if it is a deminutus
    if first_glyph == "mdeminutus":
        if shape == S_FLEXUS_NOBAR:
            write_deminutus(widths, 0, i, length=0, tosimplify=1, firstbar=0)
        elif shape == S_FLEXUS:
            write_first_bar(1)
            write_deminutus(widths, 0, i, length=0, tosimplify=1, firstbar=1)
        else:
            write_first_bar(2)
            write_deminutus(widths, 0, i, length=0, tosimplify=1, firstbar=1)
        length = widths['width_flexusdeminutus']
    elif first_glyph == 'odbase' and last_glyph == 'deminutus':
        simple_paste(first_glyph)
        write_line(i, widths['width_oriscus_rev'] - widths['line_width'],
                   (1-i)*BASE_HEIGHT)
        simplify()
        paste_and_move("deminutus",
                       widths['width_oriscus_rev'] -
                       widths['width_deminutus'] -
                       widths['line_width'], (-i)*BASE_HEIGHT)
        length = widths['width_oriscus_rev']
    else:
        if i == 1: #we remove the bar aspect
            if last_glyph == 'base7':
                last_glyph = 'Punctum'
            elif last_glyph == 'auctusa1':
                last_glyph = 'PunctumAscendens'
            elif last_glyph == 'auctusd1':
                last_glyph = 'PunctumDescendens'
            if first_glyph == 'base2':
                first_glyph = 'Punctum'
            elif first_glyph == 'odbase':
                first_glyph = 'OriscusReversus'
            elif first_glyph == 'vsbase':
                first_glyph = 'VirgaReversa'
            elif first_glyph == 'vlbase':
                first_glyph = 'VirgaReversaLongqueue'
            elif first_glyph == 'oslbase':
                first_glyph = 'OriscusScapusLongqueue'
        simple_paste(first_glyph)
        if first_glyph == 'odbase':
            length = widths['width_oriscus_rev']
        elif first_glyph == 'OriscusScapusLongqueue' or first_glyph.startswith('osbase'):
            length = widths['width_oriscus']
        else:
            length = widths['width_punctum']
        if i != 1:
            length = length-widths['line_width']
            write_line(i, length, (1-i)*BASE_HEIGHT)
        paste_and_move(last_glyph, length, (-i)*BASE_HEIGHT)
        if first_glyph == 'odbase':
            length = widths['width_oriscus_rev']
        elif first_glyph == 'OriscusScapusLongqueue' or first_glyph.startswith('osbase'):
            length = widths['width_oriscus']
        else:
            length = widths['width_punctum']
        if i == 1:
            length = 2 * length
        else:
            length = 2 * length - widths['line_width']
    set_width(length)
    end_glyph('%s%s%s' % (shape, AMBITUS[i], lique))

def porrectus(widths):
    "Creates the porrectus."
    message("porrectus")
    precise_message("porrectus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(widths, i, j, 'phigh', 1, S_PORRECTUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(widths, i, j, 'phigh', 0, S_PORRECTUS_NOBAR)
    precise_message("porrectus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(widths, i, j, "auctusa2", 1, S_PORRECTUS,
                            L_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(widths, i, j, "auctusa2", 0, S_PORRECTUS_NOBAR,
                            L_ASCENDENS)
    precise_message("porrectus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(widths, i, j, "auctusd2", 1, S_PORRECTUS,
                            L_DESCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(widths, i, j, "auctusd2", 0, S_PORRECTUS_NOBAR,
                            L_DESCENDENS)
    #precise_message("porrectus deminutus")
    #for i in range(1, MAX_INTERVAL+1):
    #    for j in range(1, MAX_INTERVAL+1):
    #        write_porrectus(widths, i, j, "rdeminutus", 1, S_PORRECTUS, L_DEMINUTUS)
    #for i in range(1, MAX_INTERVAL+1):
    #    for j in range(1, MAX_INTERVAL+1):
    #        write_porrectus(widths, i, j, "rdeminutus", 0,
    #                        S_PORRECTUS_NOBAR, L_DEMINUTUS)
    precise_message("porrectus deminutus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_alt_porrectus_deminutus(widths, i, j)

def write_porrectus(widths, i, j, last_glyph, with_bar, shape, lique=L_NOTHING):
    "Writes the porrectus glyphs."
    new_glyph()
    length = widths['porrectuswidths'][i-1]
    if with_bar:
        write_first_bar(i)
    first_glyph = "porrectus%d" % i
    if last_glyph == 'auctusa2' or last_glyph == 'auctusd2':
        length = widths['porrectusflexuswidths'][i-1]
        if j == 1:
            first_glyph = "porrectusflexusnb%d" % i
        else:
            first_glyph = "porrectusflexus%d" % i
    simple_paste(first_glyph)
    if j != 1 or (last_glyph != 'auctusa2' and last_glyph != 'auctusd2'):
        write_line(j, length-widths['line_width'], (-i+1)*BASE_HEIGHT)
        length = length-widths['line_width']
    if with_bar:
        simplify()
    if last_glyph == "rdeminutus":
        paste_and_move(last_glyph, (length-widths['width_deminutus']),
                       (j-i)*BASE_HEIGHT)
    elif last_glyph == 'auctusa2' or last_glyph == 'auctusd2':
        if last_glyph == 'auctusa2' and j == 1:
            last_glyph = 'PunctumAscendens'
        elif last_glyph == 'auctusd2' and j == 1:
            last_glyph = 'PunctumDescendens'
        paste_and_move(last_glyph, (length), (j-i)*BASE_HEIGHT)
        length = length + widths['width_punctum']
    else:
        paste_and_move(last_glyph,
                       (length-widths['width_high_pes']+widths['line_width']),
                       (j-i)*BASE_HEIGHT)
        length = length+widths['line_width']
    set_width(length)
    end_glyph('%s%s%s%s' % (shape, AMBITUS[i], AMBITUS[j], lique))

def write_alt_porrectus_deminutus(widths, i, j):
    "Writes the alternate porrectur deminutus glyphs."
    new_glyph()
    write_first_bar(i)
    if i == 1:
        simple_paste('base2')
    else:
        simple_paste('base3')
    write_line(i, widths['width_punctum']-widths['line_width'], (-i+1)*BASE_HEIGHT)
    simplify()
    paste_and_move('mpdeminutus', (widths['width_punctum']-widths['line_width']),
                   (-i)*BASE_HEIGHT)
    write_line(j,
               widths['width_punctum']+widths['width_flexusdeminutus']-
               2*widths['line_width'], (-i+1)*BASE_HEIGHT)
    paste_and_move('rdeminutus', (widths['width_punctum']
                                               + widths['width_flexusdeminutus'] -
                                               2*widths['line_width'] -
                                               widths['width_deminutus']), (j-i)*BASE_HEIGHT)
    set_width(widths['width_punctum']+widths['width_flexusdeminutus']-
              widths['line_width'])
    end_glyph('Porrectus%s%sDeminutus' % (AMBITUS[i], AMBITUS[j]))


def porrectusflexus(widths):
    "Creates the porrectusflexus."
    message("porrectus flexus")
    precise_message("porrectus flexus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(widths, i, j, k, "base7", 0,
                                      S_PORRECTUS_FLEXUS_NOBAR)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(widths, i, j, k, "base7", 1,
                                      S_PORRECTUS_FLEXUS)
    precise_message("porrectus flexus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(widths, i, j, k,
                                      "auctusd1", 0,
                                      S_PORRECTUS_FLEXUS_NOBAR,
                                      L_DESCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(widths, i, j, k,
                                      "auctusd1", 1,
                                      S_PORRECTUS_FLEXUS,
                                      L_DESCENDENS)
    precise_message("porrectus flexus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(widths, i, j, k,
                                      "auctusa1", 0,
                                      S_PORRECTUS_FLEXUS_NOBAR,
                                      L_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(widths, i, j, k,
                                      "auctusa1", 1,
                                      S_PORRECTUS_FLEXUS,
                                      L_ASCENDENS)
    precise_message("porrectus flexus deminutus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(widths, i, j, k,
                                      "deminutus", 0,
                                      S_PORRECTUS_FLEXUS_NOBAR,
                                      L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(widths, i, j, k,
                                      "deminutus", 1,
                                      S_PORRECTUS_FLEXUS, L_DEMINUTUS)

def write_porrectusflexus(widths, i, j, k, last_glyph, with_bar,
                          shape, lique=L_NOTHING):
    "Writes the porrectusflexus glyphs."
    new_glyph()
    length = widths['porrectusflexuswidths'][i-1]
    if j == 1:
        first_glyph = "porrectusflexusnb%d" % i
    else:
        first_glyph = "porrectusflexus%d" % i
    if with_bar:
        write_first_bar(i)
    simple_paste(first_glyph)
    write_line(j, length-widths['line_width'], (-i+1)*BASE_HEIGHT)
    if last_glyph == "deminutus":
        if j == 1:
            write_deminutus(widths, j-i, k, length, with_bar, firstbar=0)
            length = length+widths['width_flexusdeminutus']
        else:
            write_deminutus(widths, j-i, k, length-widths['line_width'],
                            with_bar, firstbar=1)
            length = length+widths['width_flexusdeminutus']-widths['line_width']
    else:
        simplify()
        middle_glyph = 'base3'
        if j == 1:
            if k == 1:
                middle_glyph = 'Punctum'
            else:
                middle_glyph = 'base2'
        else:
            length = length-widths['line_width']
            if k == 1:
                middle_glyph = 'base4'
        paste_and_move(middle_glyph, length, (j-i)*BASE_HEIGHT)
        if k == 1:
            if last_glyph == 'base7':
                last_glyph = 'Punctum'
            elif last_glyph == 'auctusa1':
                last_glyph = 'PunctumAscendens'
            elif last_glyph == 'auctusd1':
                last_glyph = 'PunctumDescendens'
            length = length+widths['width_punctum']
        else:
            write_line(k, length + widths['width_punctum'] - widths['line_width'],
                       (j-i-k+1)*BASE_HEIGHT)
            length = length + widths['width_punctum'] - widths['line_width']
        paste_and_move(last_glyph, length, (j-i-k)*BASE_HEIGHT)
        length = length+ widths['width_punctum']
    set_width(length)
    end_glyph('%s%s%s%s%s' % (shape, AMBITUS[i], AMBITUS[j], AMBITUS[k], lique))

def torculus(widths):
    "Creates the torculus."
    message("torculus")
    precise_message("torculus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(widths, i, j, "base5", "base7", S_TORCULUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(widths, i, j, "qbase", "base7", S_TORCULUS_QUILISMA)
    precise_message("torculus initio debilis")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(widths, i, j, "idebilis", "base7", S_TORCULUS,
                           L_INITIO_DEBILIS)
    precise_message("torculus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(widths, i, j, "base5", "auctusd1", S_TORCULUS,
                           L_DESCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(widths, i, j, "qbase", "auctusd1", S_TORCULUS_QUILISMA,
                           L_DESCENDENS)
    precise_message("torculus initio debilis auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(widths, i, j, "idebilis", "auctusd1", S_TORCULUS,
                           L_INITIO_DEBILIS_DESCENDENS)
    precise_message("torculus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(widths, i, j, "base5", "auctusa1",
                           S_TORCULUS, L_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(widths, i, j, "qbase", "auctusa1", S_TORCULUS_QUILISMA,
                           L_ASCENDENS)
    precise_message("torculus initio debilis auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(widths, i, j, "idebilis", "auctusa1", S_TORCULUS,
                           L_INITIO_DEBILIS_ASCENDENS)
    precise_message("torculus deminutus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(widths, i, j, "base5", "deminutus", S_TORCULUS,
                           L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(widths, i, j, "qbase", "deminutus", S_TORCULUS_QUILISMA,
                           L_DEMINUTUS)
    precise_message("torculus initio debilis deminutus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(widths, i, j, "idebilis", "deminutus", S_TORCULUS,
                           L_INITIO_DEBILIS_DEMINUTUS)

def write_torculus(widths, i, j, first_glyph, last_glyph, shape, lique=L_NOTHING):
    "Writes the torculus glyphs."
    new_glyph()
    length = widths['width_punctum']-widths['line_width']
    if first_glyph == "idebilis":
        length = widths['width_debilis']
    elif first_glyph == "qbase":
        length = widths['width_quilisma']-widths['line_width']
        if i == 1:
            first_glyph = 'Quilisma'
            length = widths['width_quilisma']
    elif i == 1:
        first_glyph = 'Punctum'
        length = widths['width_punctum']+0.1
    simple_paste(first_glyph)
    if i != 1:
        write_line(i, length, BASE_HEIGHT)
    if last_glyph == "deminutus":
        if i == 1:
            write_deminutus(widths, i, j, length, firstbar=0)
        else:
            write_deminutus(widths, i, j, length, firstbar=1)
        length = length+widths['width_flexusdeminutus']
    else:
        if j == 1:
            if i == 1:
                paste_and_move("Punctum", length, i*BASE_HEIGHT)
            else:
                paste_and_move("base4", length, i*BASE_HEIGHT)
            length = length+widths['width_punctum']
            if last_glyph == 'base7':
                last_glyph = 'Punctum'
            elif last_glyph == 'auctusa1':
                last_glyph = 'PunctumAscendens'
            elif last_glyph == 'auctusd1':
                last_glyph = 'PunctumDescendens'
        else:
            if i == 1:
                paste_and_move("base2", length, i*BASE_HEIGHT)
            else:
                paste_and_move("base3", length, i*BASE_HEIGHT)
            length = length+widths['width_punctum']-widths['line_width']
            write_line(j, length, (i-j+1)*BASE_HEIGHT)
        paste_and_move(last_glyph, length, (i-j)*BASE_HEIGHT)
        length = length+widths['width_punctum']
    set_width(length)
    end_glyph('%s%s%s%s' % (shape, AMBITUS[i], AMBITUS[j], lique))

def torculus_liquescens(widths):
    "Creates the torculus liquescens."
    precise_message("torculus liquescens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculus_liquescens(widths, i, j, k, 'base5',
                                          S_TORCULUS_LIQUESCENS, L_DEMINUTUS)
    precise_message("torculus liquescens quilisma")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculus_liquescens(widths, i, j, k, 'qbase',
                                          S_TORCULUS_LIQUESCENS_QUILISMA, L_DEMINUTUS)

def write_torculus_liquescens(widths, i, j, k, first_glyph, shape,
                              lique='deminutus'):
    "Writes the torculus liquescens glyphs."
    new_glyph()
    length = widths['width_punctum']-widths['line_width']
    if first_glyph == "qbase":
        length = widths['width_quilisma']-widths['line_width']
        if i == 1:
            first_glyph = 'Quilisma'
            length = widths['width_quilisma']
    elif i == 1:
        first_glyph = 'Punctum'
        length = widths['width_punctum']+0.1
    simple_paste(first_glyph)
    if i != 1:
        write_line(i, length, BASE_HEIGHT)
    flexus_firstbar = 2
    if j == 1:
        flexus_firstbar = 0
        if i == 1:
            paste_and_move("Punctum", length, i*BASE_HEIGHT)
        else:
            paste_and_move("base4", length, i*BASE_HEIGHT)
        length = length+widths['width_punctum']
    else:
        if i == 1:
            paste_and_move("base2", length, i*BASE_HEIGHT)
        else:
            paste_and_move("base3", length, i*BASE_HEIGHT)
        length = length+widths['width_punctum']-widths['line_width']
        write_line(j, length, (i-j+1)*BASE_HEIGHT)
    write_deminutus(widths, i-j, k, length, firstbar=flexus_firstbar)
    length = length+widths['width_flexusdeminutus']
    set_width(length)
    end_glyph('%s%s%s%s%s' % (shape, AMBITUS[i], AMBITUS[j], AMBITUS[k], lique))

def torculusresupinus(widths):
    "Creates the torculusresupinus."
    message("torculus resupinus")
    precise_message("torculus resupinus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(widths, i, j, k, 'base5', 'phigh',
                                        S_TORCULUS_RESUPINUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(widths, i, j, k, 'idebilis', 'phigh',
                                        S_TORCULUS_RESUPINUS, L_INITIO_DEBILIS)
    precise_message("torculus resupinus deminutus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinusdeminutus(widths, i, j, k, 'base5',
                                                 S_TORCULUS_RESUPINUS, L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinusdeminutus(widths, i, j, k, 'idebilis',
                                                 S_TORCULUS_RESUPINUS,
                                                 L_INITIO_DEBILIS_DEMINUTUS)
    precise_message("torculus resupinus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(widths, i, j, k, 'base5', "auctusa2",
                                        S_TORCULUS_RESUPINUS, L_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(widths, i, j, k, 'idebilis', "auctusa2",
                                        S_TORCULUS_RESUPINUS,
                                        L_INITIO_DEBILIS_ASCENDENS)
    precise_message("torculus resupinus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(widths, i, j, k, 'base5', "auctusd2",
                                        S_TORCULUS_RESUPINUS,
                                        L_DESCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(widths, i, j, k, 'idebilis',
                                        "auctusd2",
                                        S_TORCULUS_RESUPINUS,
                                        L_INITIO_DEBILIS_DESCENDENS)

def write_torculusresupinus(widths, i, j, k, first_glyph, last_glyph, shape,
                            lique=L_NOTHING):
    "Writes the torculusresupinus glyphs."
    new_glyph()
    if first_glyph == "idebilis":
        length = widths['width_debilis']
    elif i == 1:
        if first_glyph == 'base5':
            first_glyph = 'Punctum'
            length = widths['width_punctum']+0.1
    else:
        if first_glyph == 'base5':
            length = widths['width_punctum']-widths['line_width']
    simple_paste(first_glyph)
    if i != 1:
        write_line(i, length, BASE_HEIGHT)
    middle_glyph = "porrectus%d" % j
    if last_glyph == 'auctusa2' or last_glyph == 'auctusd2':
        if k == 1:
            middle_glyph = "porrectusflexusnb%d" % j
        else:
            middle_glyph = "porrectusflexus%d" % j
    paste_and_move(middle_glyph, length, i*BASE_HEIGHT)
    if last_glyph == 'auctusa2' or last_glyph == 'auctusd2':
        length = length + widths['porrectusflexuswidths'][j-1]
    else:
        length = length + widths['porrectuswidths'][j-1]
    if (last_glyph != 'auctusa2' and last_glyph != 'auctusd2') or k != 1:
        write_line(k, length-widths['line_width'], (i-j+1)*BASE_HEIGHT)
    simplify()
    if last_glyph == "rdeminutus":
        paste_and_move(last_glyph,
                       (length-widths['width_deminutus']-widths['line_width']),
                       (i-j+k)*BASE_HEIGHT)
    elif last_glyph == 'auctusa2' or last_glyph == 'auctusd2':
        if last_glyph == 'auctusa2' and k == 1:
            last_glyph = 'PunctumAscendens'
        elif last_glyph == 'auctusd2' and k == 1:
            last_glyph = 'PunctumDescendens'
        if k == 1:
            length = length+widths['line_width']
        paste_and_move(last_glyph, (length-widths['line_width']), (i-j+k)*BASE_HEIGHT)
        length = length - widths['line_width'] + widths['width_punctum']
    else:
        paste_and_move(last_glyph, (length-widths['width_high_pes']),
                       (i-j+k)*BASE_HEIGHT)
    set_width(length)
    end_glyph('%s%s%s%s%s' % (shape, AMBITUS[i], AMBITUS[j], AMBITUS[k], lique))

def write_torculusresupinusdeminutus(widths, i, j, k, first_glyph,
                                     shape, lique=L_NOTHING):
    # pylint: disable=invalid-name
    "Writes the torculusresupinusdeminutus glyphs."
    new_glyph()
    length = widths['width_punctum']-widths['line_width']
    if first_glyph == "idebilis":
        length = widths['width_debilis']
    elif i == 1:
        first_glyph = 'Punctum'
        length = widths['width_punctum']+0.1
    simple_paste(first_glyph)
    if i != 1:
        write_line(i, length, BASE_HEIGHT)
    if j == 1 and i == 1:
        if first_glyph == "idebilis":
            paste_and_move("base4", length, i*BASE_HEIGHT)
            length = length+widths['width_punctum']
            last_glyph = 'mnbpdeminutus'
        else:
            paste_and_move("Punctum", length, i*BASE_HEIGHT)
            length = length+widths['width_punctum']
            last_glyph = 'mnbpdeminutus'
    elif j == 1:
        paste_and_move("base4", length, i*BASE_HEIGHT)
        length = length+widths['width_punctum']
        last_glyph = 'mnbpdeminutus'
    elif i == 1 and first_glyph != "idebilis":
        paste_and_move("base2", length, i*BASE_HEIGHT)
        length = length+widths['width_punctum']-widths['line_width']
        write_line(j, length, (i-j+1)*BASE_HEIGHT)
        last_glyph = 'mpdeminutus'
    else:
        paste_and_move("base3", length, i*BASE_HEIGHT)
        length = length+widths['width_punctum']-widths['line_width']
        write_line(j, length, (i-j+1)*BASE_HEIGHT)
        last_glyph = 'mpdeminutus'
    paste_and_move(last_glyph, length, (i-j)*BASE_HEIGHT)
    length = length+widths['width_flexusdeminutus']
    write_line(k, length-widths['line_width'], (i-j+1)*BASE_HEIGHT)
    paste_and_move('rdeminutus',
                   length-widths['width_deminutus']-widths['line_width'], (i-j+k)*BASE_HEIGHT)
    set_width(length)
    end_glyph('%s%s%s%s%s' % (shape, AMBITUS[i], AMBITUS[j], AMBITUS[k], lique))

def scandicus(widths):
    "Creates the scandicus."
    message("scandicus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_scandicus(widths, i, j, 'phigh')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_scandicus(widths, i, j, 'rdeminutus', L_DEMINUTUS)

def write_scandicus(widths, i, j, last_glyph, lique=L_NOTHING):
    "Writes the scandicus glyphs."
    new_glyph()
    # special case of i=j=1, we use glyph 1025 directly
    if i == 1 and j == 1 and lique == L_NOTHING:
        simple_paste('Punctum')
        second_glyph = 'PesOneNothing'
        paste_and_move(second_glyph, widths['width_punctum'], BASE_HEIGHT)
        set_width(2*widths['width_punctum'])
        end_glyph('%s%s%s%s' % (S_SCANDICUS, AMBITUS[i], AMBITUS[j], lique))
        return
    if i == 1:
        simple_paste('Punctum')
        length = widths['width_punctum']
        second_glyph = 'p2base'
        if lique == L_DEMINUTUS:
            second_glyph = 'mnbpdeminutus'
    else:
        simple_paste('base5')
        length = widths['width_punctum'] - widths['line_width']
        write_line(i, length, BASE_HEIGHT)
        second_glyph = 'msdeminutus'
    paste_and_move(second_glyph, length, i*BASE_HEIGHT)
    if (i == 1) and lique == L_NOTHING:
        length = length + widths['width_punctum']
    else:
        length = length + widths['width_flexusdeminutus']
    if j != 1:
        write_line(j, length - widths['line_width'], (i+1) * BASE_HEIGHT)
    if last_glyph == 'rdeminutus':
        paste_and_move('rdeminutus', length -
                       widths['width_deminutus'] -
                       widths['line_width'], (i+j)*BASE_HEIGHT)
    else:
        paste_and_move(last_glyph, length - widths['width_high_pes'],
                       (i+j)*BASE_HEIGHT)
    set_width(length)
    end_glyph('%s%s%s%s' % (S_SCANDICUS, AMBITUS[i], AMBITUS[j], lique))

def ancus(widths):
    "Creates the ancus."
    message("ancus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_ancus(widths, i, j, 'vsbase', S_ANCUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_ancus(widths, i, j, 'vlbase', S_ANCUS_LONGQUEUE)

def write_ancus(widths, i, j, first_glyph, glyph_type):
    "Writes the ancus glyphs."
    new_glyph()
    if i == 1:
        length = widths['width_punctum']
        second_glyph = 'mnbdeminutus'
        if first_glyph == 'vsbase':
            first_glyph = 'VirgaReversa'
        else:
            first_glyph = 'VirgaReversaLongqueue'
    else:
        length = widths['width_punctum'] - widths['line_width']
        second_glyph = 'mademinutus'
    simple_paste(first_glyph)
    if i != 1:
        write_line(i, length, (-i+1)*BASE_HEIGHT)
    paste_and_move(second_glyph, length, -(i)*BASE_HEIGHT)
    length = length + widths['width_flexusdeminutus']
    if j != 1:
        write_line(j, length - widths['line_width'], (-i-j+1) * BASE_HEIGHT)
    paste_and_move('deminutus',
                   length - widths['width_deminutus'] - widths['line_width'], (-i-j)*BASE_HEIGHT)
    set_width(length)
    end_glyph('%s%s%s%s' % (glyph_type, AMBITUS[i], AMBITUS[j], L_DEMINUTUS))

if __name__ == "__main__":
    main()
