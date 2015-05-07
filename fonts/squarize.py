# This is a fontforge python script; use fontforge -lang=py -script to run it
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
import os.path

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
HEPISEMUS_ADDITIONAL_WIDTH=5
DEMINUTUS_VERTICAL_SHIFT=10
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
""")

def main():
    "Main function"
    global oldfont, newfont, font_name
    version_script_file = os.path.join(sys.path[0], '../VersionManager.py')
    proc = subprocess.Popen([version_script_file, '-c'], stdout=subprocess.PIPE, universal_newlines=True)
    version = proc.stdout.read().strip('\n')
    try:
        opts, args = getopt.gnu_getopt(sys.argv[1:], "o:h", ["outfile","help"])
    except getopt.GetoptError:
        # print help information and exit:
        usage()
        sys.exit(2)
    font_name = args[0]
    outfile = "%s.ttf" % font_name
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            usage()
            sys.exit()
        elif opt in ("-o", "--outfile"):
            outfile = arg
            print(outfile)
    if len(args) == 0:
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
    font_width = {}
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
    leading(font_width)
    # variants must be copied last!
    copy_variant_glyphs()
    newfont.generate(outfile)
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
    'VEpisemus.circumflexus',
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
    'VirgaReversaLongqueueDescendens',
    'PunctumSmall',
    'PunctumLineBR',
    'PunctumLineBL',
    'PunctumLineTL',
    'PunctumLineTR',
    'PunctumLineBLBR',
    'PunctumAuctusLineBL',
]

def glyph_exists(glyph_name, font):
    "returns if glyph named glyphName exists in font (boolean)"
    result = True
    try:
        font.selection.select(glyph_name)
    except:
        result = False
    return result

def copy_existing_glyph(glyph_name):
    "copies the named glyph, if it exists, and returns whether it was copied"
    global oldfont
    if glyph_exists(glyph_name, oldfont):
        complete_paste(glyph_name)
        set_glyph_name(glyph_name)
        return True
    else:
        return False

# This will be populated by initialize_glyphs
COMMON_DIRECT_VARIANTS = {}

def initialize_glyphs():
    "Builds the first glyphs."
    global newfont, oldfont, font_name
    # DIRECT_GLYPH_NAMES are the names of the glyphs that are already in
    # gregorio_base, mostly one-note glyphs.
    DIRECT_GLYPH_NAMES.sort()
    for name in DIRECT_GLYPH_NAMES:
        new_glyph()
        if glyph_exists(name, oldfont):
            oldfont.selection.select(name)
            oldfont.copy()
            newfont.paste()
            set_glyph_name(name)
            if name.find('.') > 0:
                COMMON_DIRECT_VARIANTS[name] = True
        else:
            print('Warning: glyph '+name+' missing from '+font_name)

def copy_variant_glyphs():
    "Copies the variant glyphs."
    global newfont, oldfont
    for glyph in oldfont.glyphs():
        name = glyph.glyphname
        if (glyph.isWorthOutputting() and name.find(".") > 0 and
                name not in COMMON_DIRECT_VARIANTS):
            new_glyph()
            oldfont.selection.select(glyph)
            oldfont.copy()
            newfont.paste()
            set_glyph_name(name)

def get_width(widths, glyphName):
    "Get length of glyph glyphName in the base font."
    global oldfont
    if glyphName not in widths:
        if glyph_exists(glyphName, oldfont):
            widths[glyphName] = oldfont[glyphName].width
        else:
            widths[glyphName] = 0
    return widths[glyphName]

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
S_TORCULUS_RESUPINUS_QUILISMA      = 'TorculusResupinusQuilisma'
S_SCANDICUS                        = 'Scandicus'
S_ANCUS                            = 'Ancus'
S_ANCUS_LONGQUEUE                  = 'AncusLongqueue'
S_VIRGA_STRATA                     = 'VirgaStrata'
S_SALICUS                          = 'Salicus'
S_SALICUS_LONGQUEUE                = 'SalicusLongqueue'
S_TORCULUS_LIQUESCENS              = 'TorculusLiquescens'
S_TORCULUS_LIQUESCENS_QUILISMA     = 'TorculusLiquescensQuilisma'
S_FLEXUS_ORISCUS_SCAPUS            = 'FlexusOriscusScapus'
S_FLEXUS_ORISCUS_SCAPUS_LONGQUEUE  = 'FlexusOriscusScapusLongqueue'
S_LEADING_ZERO_SPACER              = 'LeadingZeroSpacer'
S_LEADING_LINE_SPACER              = 'LeadingLineSpacer'
S_LEADING_PUNCTUM                  = 'LeadingPunctum'
S_LEADING_QUILISMA                 = 'LeadingQuilisma'
S_LEADING_ORISCUS                  = 'LeadingOriscus'

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
    "Copy and paste a glyph."
    global oldfont, newfont, glyphnumber
    oldfont.selection.select(src)
    oldfont.copy()
    newfont.selection.select('u%05x' % glyphnumber)
    newfont.pasteInto()

def complete_paste(src):
    "Copy and paste a glyph."
    global oldfont, newfont, glyphnumber
    oldfont.selection.select(src)
    oldfont.copy()
    newfont.selection.select('u%05x' % glyphnumber)
    newfont.paste()

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
    global oldfont
    first_glyph = 'mademinutus'
    if firstbar == 1:
        first_glyph = 'mdeminutus'
        if j == 1 and glyph_exists('mdeminutusam1', oldfont):
            first_glyph = 'mdeminutusam1'
    elif firstbar == 0:
        first_glyph = 'mnbdeminutus'
    paste_and_move(first_glyph, length, i*BASE_HEIGHT)
    write_line(j, length+get_width(widths, first_glyph)-get_width(widths, 'line2'),
               (i-j+1)*BASE_HEIGHT)
    if tosimplify:
        simplify()
    paste_and_move("deminutus",
                   length+get_width(widths, first_glyph)-get_width(widths, 'deminutus'),
                   (i-j)*BASE_HEIGHT)
    return get_width(widths, first_glyph)

def hepisemus(widths):
    "Creates horizontal episemae."
    global oldfont
    message("horizontal episemus")
    write_hepisemus(widths, get_width(widths, 'Punctum'), 'HEpisemusPunctum')
    write_hepisemus(widths, get_width(widths, 'mpdeminutus'), 'HEpisemusFlexusDeminutus')
    write_hepisemus(widths, get_width(widths, 'idebilis'), 'HEpisemusDebilis')
    write_hepisemus(widths, get_width(widths, 'PunctumInclinatum'), 'HEpisemusInclinatum')
    write_hepisemus(widths, get_width(widths, 'PunctumInclinatumDeminutus'), 'HEpisemusInclinatumDeminutus')
    write_hepisemus(widths, get_width(widths, 'Stropha'), 'HEpisemusStropha')
    write_hepisemus(widths, get_width(widths, 'Quilisma'), 'HEpisemusQuilisma')
    write_hepisemus(widths, get_width(widths, 'QuilismaLineTR'), 'HEpisemusQuilismaLineTR')
    write_hepisemus(widths, get_width(widths, 'PunctumSmall'), 'HEpisemusHighPes')
    write_hepisemus(widths, get_width(widths, 'Oriscus'), 'HEpisemusOriscus')
    write_hepisemus(widths, get_width(widths, 'OriscusLineTR'), 'HEpisemusOriscusLineTR')
    write_hepisemus(widths, get_width(widths, 'PunctumLineBR'), 'HEpisemusPunctumLineBR')
    write_hepisemus(widths, get_width(widths, 'PunctumLineBL'), 'HEpisemusPunctumLineBL')
    write_hepisemus(widths, get_width(widths, 'PunctumLineTL'), 'HEpisemusPunctumLineTL')
    write_hepisemus(widths, get_width(widths, 'PunctumLineTR'), 'HEpisemusPunctumLineTR')
    write_hepisemus(widths, get_width(widths, 'PunctumLineBLBR'), 'HEpisemusPunctumLineBLBR')
    write_hepisemus(widths, get_width(widths, 'PunctumAuctusLineBL'), 'HEpisemusPunctumAuctusLineBL')
    for i in range(1, MAX_INTERVAL+1):
        write_hepisemus(widths, get_width(widths, "porrectus%d"%i), 'HEpisemusPorrectus%s' % AMBITUS[i])
    for i in range(1, MAX_INTERVAL+1):
        if glyph_exists("porrectusam1%d"%i, oldfont):
            write_hepisemus(widths, get_width(widths, "porrectusam1%d"%i), 'HEpisemusPorrectusAmOne%s' % AMBITUS[i])
        else:
            write_hepisemus(widths, get_width(widths, "porrectus%d"%i), 'HEpisemusPorrectusAmOne%s' % AMBITUS[i])
    for i in range(1, MAX_INTERVAL+1):
        write_hepisemus(widths, get_width(widths, "porrectusflexus%d"%i), 'HEpisemusPorrectusFlexus%s' % AMBITUS[i])

def write_hepisemus(widths, shape_width, glyphname):
    "Writes the horizontal episemus glyphs."
    global HEPISEMUS_ADDITIONAL_WIDTH
    new_glyph()
    simple_paste("hepisemus_base")
    scale(shape_width + 2*HEPISEMUS_ADDITIONAL_WIDTH, 1)
    move(-HEPISEMUS_ADDITIONAL_WIDTH, 0)
    paste_and_move("hepisemusleft", -HEPISEMUS_ADDITIONAL_WIDTH, 0)
    paste_and_move("hepisemusright",
                   shape_width + HEPISEMUS_ADDITIONAL_WIDTH, 0)
    set_width(shape_width)
    end_glyph(glyphname)

def pes(widths):
    "Creates the pes."
    message("pes")
    precise_message("pes")
    for i in range(1, MAX_INTERVAL+1):
        write_pes(widths, i, "p2base", S_PES)
    precise_message("pes quilisma")
    for i in range(1, MAX_INTERVAL+1):
        write_pes(widths, i, "QuilismaLineTR", S_PES_QUILISMA)
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
    global oldfont
    new_glyph()
    glyph_name = '%s%s%s' % (shape, AMBITUS[i], lique)
    if copy_existing_glyph(glyph_name):
        return
    get_width(widths, 'QuilismaLineTR')
    temp_width = 0
    width_difference = get_width(widths, first_glyph)-get_width(widths, 'PunctumSmall')
    if width_difference < 0:
        paste_and_move(first_glyph, -width_difference, 0)
    else:
        simple_paste(first_glyph)
    temp_width = get_width(widths, first_glyph)-get_width(widths, 'line2')
    if width_difference < 0:
        temp_width = temp_width-width_difference
    write_line(i, temp_width, BASE_HEIGHT)
    if width_difference != 0:
        paste_and_move('PunctumSmall', width_difference, i*BASE_HEIGHT)
    else:
        paste_and_move('PunctumSmall', 0, i*BASE_HEIGHT)
    if width_difference < 0:
        set_width(get_width(widths, 'PunctumSmall'))
    else:
        set_width(get_width(widths, first_glyph))
    end_glyph(glyph_name)

def write_pes_debilis(widths, i, shape, lique=L_NOTHING):
    "Writes the pes debilis glyphs."
    new_glyph()
    glyph_name = '%s%s%s' % (shape, AMBITUS[i], lique)
    if copy_existing_glyph(glyph_name):
        return
    # with a deminutus it is much more beautiful than with a idebilis
    paste_and_move("deminutus", 0, 0)
    write_line(i, get_width(widths, 'deminutus')-get_width(widths, 'line2'), BASE_HEIGHT)
    simplify()
    paste_and_move("PunctumLineBL", get_width(widths, 'deminutus')-get_width(widths, 'line2'), i*BASE_HEIGHT)
    set_width(get_width(widths, 'deminutus')+get_width(widths, 'PunctumLineBL')-get_width(widths, 'line2'))
    end_glyph(glyph_name)

def write_pes_deminutus(widths, i, first_glyph, shape, lique=L_NOTHING):
    "Writes the pes deminutus glyphs."
    new_glyph()
    glyph_name = '%s%s%s' % (shape, AMBITUS[i], lique)
    if copy_existing_glyph(glyph_name):
        return
    simple_paste(first_glyph)
    temp_width = get_width(widths, first_glyph)-get_width(widths, 'line2')
    write_line(i, temp_width, BASE_HEIGHT)
    paste_and_move("rdeminutus",
                   get_width(widths, first_glyph)-get_width(widths, 'rdeminutus'),
                   i*BASE_HEIGHT)
    set_width(get_width(widths, first_glyph))
    end_glyph(glyph_name)

def write_pes_debilis_deminutus(widths, i, shape, lique=L_NOTHING):
    "Writes the pes debilis deminutus glyphs."
    new_glyph()
    glyph_name = '%s%s%s' % (shape, AMBITUS[i], lique)
    if copy_existing_glyph(glyph_name):
        return
    simple_paste("deminutus")
    write_line(i, get_width(widths, 'deminutus')-get_width(widths, 'line2'), BASE_HEIGHT)
    simplify()
    paste_and_move("rdeminutus", 0, i*BASE_HEIGHT)
    set_width(get_width(widths, 'deminutus'))
    end_glyph(glyph_name)

def pes_quadratum(widths):
    "Makes the pes quadratum."
    message("pes quadratum")
    precise_message("pes quadratum")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "PunctumLineTR", "rvsbase", S_PES_QUADRATUM)
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "PunctumLineTR", "rvlbase", S_PES_QUADRATUM_LONGQUEUE)
    precise_message("pes quassus")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "OriscusLineTR", "rvsbase", S_PES_QUASSUS)
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "OriscusLineTR", "rvlbase", S_PES_QUASSUS_LONGQUEUE)
    precise_message("pes quilisma quadratum")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "QuilismaLineTR", "rvsbase", S_PES_QUILISMA_QUADRATUM)
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "QuilismaLineTR",
                            "rvlbase", S_PES_QUILISMA_QUADRATUM_LONGQUEUE)
    precise_message("pes auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "PunctumLineTR",
                            "auctusa2", S_PES_QUADRATUM, L_ASCENDENS)
    precise_message("pes initio debilis auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "idebilis",
                            "auctusa2", S_PES_QUADRATUM,
                            L_INITIO_DEBILIS_ASCENDENS)
    precise_message("pes quassus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "OriscusLineTR",
                            "auctusa2", S_PES_QUASSUS, L_ASCENDENS)
    precise_message("pes quilisma auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "QuilismaLineTR",
                            "auctusa2", S_PES_QUILISMA_QUADRATUM,
                            L_ASCENDENS)
    precise_message("pes auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "PunctumLineTR",
                            "PunctumAuctusLineBL", S_PES_QUADRATUM, L_DESCENDENS)
    precise_message("pes initio debilis auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "idebilis",
                            "PunctumAuctusLineBL", S_PES_QUADRATUM,
                            L_INITIO_DEBILIS_DESCENDENS)
    precise_message("pes quassus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "OriscusLineTR",
                            "PunctumAuctusLineBL", S_PES_QUASSUS, L_DESCENDENS)
    precise_message("pes quilisma auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(widths, i, "QuilismaLineTR", "PunctumAuctusLineBL", S_PES_QUILISMA_QUADRATUM,
                            L_DESCENDENS)

def write_pes_quadratum(widths, i, first_glyph, last_glyph, shape, lique=L_NOTHING):
    "Writes the pes quadratum glyphs."
    new_glyph()
    glyph_name = '%s%s%s' % (shape, AMBITUS[i], lique)
    if copy_existing_glyph(glyph_name):
        return
    if first_glyph == "idebilis":
        first_width = get_width(widths, 'idebilis')-get_width(widths, 'line2')
    elif first_glyph == "PunctumLineTR":
        if i == 1:
            first_glyph = 'Punctum'
            if last_glyph == 'PunctumLineTL':
                last_glyph = 'Punctum'
            elif last_glyph == 'auctusa2':
                last_glyph = 'PunctumAscendens'
            elif last_glyph == 'PunctumAuctusLineBL':
                last_glyph = 'PunctumDescendens'
            elif last_glyph == 'rvsbase':
                last_glyph = 'Virga'
            elif last_glyph == 'rvlbase':
                last_glyph = 'VirgaLongqueue'
            first_width = get_width(widths, first_glyph)
        else:
            first_width = get_width(widths, first_glyph)-get_width(widths, 'line2')
    else:
        first_width = get_width(widths, first_glyph)-get_width(widths, 'line2')
    simple_paste(first_glyph)
    if i != 1:
        linename = "line%d" % i
        paste_and_move(linename, first_width, BASE_HEIGHT)
    paste_and_move(last_glyph, first_width, i*BASE_HEIGHT)
    set_width(first_width+get_width(widths, last_glyph))
    end_glyph(glyph_name)

def virga_strata(widths):
    "Creates the virga strata."
    precise_message("virga strata")
    for i in range(1, MAX_INTERVAL+1):
        write_virga_strata(widths, i, "PunctumLineTR", "obase4", S_VIRGA_STRATA)

def write_virga_strata(widths, i, first_glyph, last_glyph, shape, lique=L_NOTHING):
    "Writes the virga strata glyphs."
    new_glyph()
    glyph_name = '%s%s%s' % (shape, AMBITUS[i], lique)
    if copy_existing_glyph(glyph_name):
        return
    if i == 1:
        first_glyph = 'Punctum'
        first_width = get_width(widths, first_glyph)
        last_glyph = 'Oriscus'
    else:
        first_width = get_width(widths, first_glyph)-get_width(widths, 'line2')
    simple_paste(first_glyph)
    if i != 1:
        linename = "line%d" % i
        paste_and_move(linename, first_width, BASE_HEIGHT)
    paste_and_move(last_glyph, first_width, i*BASE_HEIGHT)
    set_width(first_width+get_width(widths, last_glyph))
    end_glyph(glyph_name)

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
    glyph_name = '%s%s%s%s' % (shape, AMBITUS[i], AMBITUS[j], lique)
    if copy_existing_glyph(glyph_name):
        return
    if j == 1:
        if last_glyph == 'rvsbase':
            last_glyph = 'Virga'
        elif last_glyph == 'rvlbase':
            last_glyph = 'VirgaLongqueue'
    if i == 1 and j == 1:
        first_glyph = 'Punctum'
        first_width = get_width(widths, first_glyph)
        middle_glyph = 'Oriscus'
        middle_width = get_width(widths, middle_glyph)
    elif i == 1:
        first_glyph = 'Punctum'
        first_width = get_width(widths, first_glyph)
        middle_glyph = 'OriscusLineTR'
        middle_width = get_width(widths, middle_glyph)-get_width(widths, 'line2')
    elif j == 1:
        first_glyph = 'PunctumLineTR'
        first_width = get_width(widths, first_glyph)-get_width(widths, 'line2')
        middle_glyph = 'obase4'
        middle_width = get_width(widths, middle_glyph)
    else:
        first_glyph = 'PunctumLineTR'
        first_width = get_width(widths, first_glyph)-get_width(widths, 'line2')
        middle_glyph = 'obase8'
        middle_width = get_width(widths, middle_glyph)-get_width(widths, 'line2')
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
    set_width(length+get_width(widths, last_glyph))
    end_glyph(glyph_name)

def flexus(widths):
    "Creates the flexus."
    message("flexus")
    precise_message("flexus")
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(widths, i, "PunctumLineBR", 'PunctumLineTL', S_FLEXUS_NOBAR)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(widths, i, "odbase", 'PunctumLineTL', S_FLEXUS_ORISCUS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(widths, i, "vbase"+str(i), 'PunctumLineTL', S_FLEXUS)
    write_flexus(widths, 1, "vlbase", 'PunctumLineTL', S_FLEXUS_LONGQUEUE)
    for i in range(2, MAX_INTERVAL+1):
        write_flexus(widths, i, "vbase"+str(i), 'PunctumLineTL', S_FLEXUS_LONGQUEUE)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(widths, i, "osbase"+str(i), 'PunctumLineTL', S_FLEXUS_ORISCUS_SCAPUS)
    write_flexus(widths, 1, "oslbase", 'PunctumLineTL', S_FLEXUS_ORISCUS_SCAPUS_LONGQUEUE)
    for i in range(2, MAX_INTERVAL+1):
        write_flexus(widths, i, "osbase"+str(i), 'PunctumLineTL',
                     S_FLEXUS_ORISCUS_SCAPUS_LONGQUEUE)
    precise_message("flexus deminutus")
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(widths, i, "mdeminutus", 'PunctumLineTL',
                     S_FLEXUS_NOBAR, L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(widths, i, "odbase", 'deminutus',
                     S_FLEXUS_ORISCUS, L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(widths, i, "mdeminutus", 'PunctumLineTL',
                     S_FLEXUS, L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(widths, i, "mdeminutus", 'PunctumLineTL',
                     S_FLEXUS_LONGQUEUE, L_DEMINUTUS)
    precise_message("flexus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(widths, i, "PunctumLineBR", 'auctusa1',
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
                 S_FLEXUS_ORISCUS_SCAPUS_LONGQUEUE, L_ASCENDENS)
    for i in range(2, MAX_INTERVAL+1):
        write_flexus(widths, i, "osbase"+str(i),
                     'auctusa1', S_FLEXUS_ORISCUS_SCAPUS_LONGQUEUE,
                     L_ASCENDENS)
    precise_message("flexus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(widths, i, "PunctumLineBR", 'auctusd1', S_FLEXUS_NOBAR,
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
                 S_FLEXUS_ORISCUS_SCAPUS_LONGQUEUE,
                 L_DESCENDENS)
    for i in range(2, MAX_INTERVAL+1):
        write_flexus(widths, i, "osbase"+str(i),
                     'auctusd1', S_FLEXUS_ORISCUS_SCAPUS_LONGQUEUE,
                     L_DESCENDENS)

def write_flexus(widths, i, first_glyph, last_glyph, shape, lique=L_NOTHING):
    # pylint: disable=too-many-statements
    "Writes the flexus glyphs."
    new_glyph()
    glyph_name = '%s%s%s' % (shape, AMBITUS[i], lique)
    if copy_existing_glyph(glyph_name):
        return
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
        length = get_width(widths, first_glyph)
    elif first_glyph == 'odbase' and last_glyph == 'deminutus':
        simple_paste(first_glyph)
        write_line(i, get_width(widths, first_glyph) - get_width(widths, 'line2'),
                   (1-i)*BASE_HEIGHT)
        simplify()
        paste_and_move("deminutus",
                       get_width(widths, first_glyph) -
                       get_width(widths, last_glyph), (-i)*BASE_HEIGHT)
        length = get_width(widths, first_glyph)
    else:
        if i == 1 and first_glyph != 'odbase':
            if last_glyph == 'PunctumLineTL':
                last_glyph = 'Punctum'
            elif last_glyph == 'auctusa1':
                last_glyph = 'PunctumAscendens'
            elif last_glyph == 'auctusd1':
                last_glyph = 'PunctumDescendens'
            if first_glyph == 'PunctumLineBR':
                first_glyph = 'Punctum'
            elif first_glyph == 'odbase':
                first_glyph = 'OriscusReversus'
            elif first_glyph == 'osbase':
                first_glyph = 'OriscusScapus'
            elif first_glyph == 'oslbase':
                first_glyph = 'OriscusScapusLongqueue'
            elif first_glyph == 'vsbase':
                first_glyph = 'VirgaReversa'
            elif first_glyph == 'vlbase':
                first_glyph = 'VirgaReversaLongqueue'
            length = get_width(widths, first_glyph)
        else:
            length = get_width(widths, first_glyph)-get_width(widths, 'line2')
        simple_paste(first_glyph)
        if i != 1:
            write_line(i, length, (1-i)*BASE_HEIGHT)
        paste_and_move(last_glyph, length, (-i)*BASE_HEIGHT)
        length = get_width(widths, first_glyph) + get_width(widths, last_glyph)
        if i != 1:
            length = length - get_width(widths, 'line2')
    set_width(length)
    end_glyph(glyph_name)

def porrectus(widths):
    "Creates the porrectus."
    message("porrectus")
    precise_message("porrectus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(widths, i, j, 'PunctumSmall', 1, S_PORRECTUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(widths, i, j, 'PunctumSmall', 0, S_PORRECTUS_NOBAR)
    precise_message("porrectus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(widths, i, j, "auctusa2", 1, S_PORRECTUS, L_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(widths, i, j, "auctusa2", 0, S_PORRECTUS_NOBAR, L_ASCENDENS)
    precise_message("porrectus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(widths, i, j, "PunctumAuctusLineBL", 1, S_PORRECTUS, L_DESCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(widths, i, j, "PunctumAuctusLineBL", 0, S_PORRECTUS_NOBAR, L_DESCENDENS)
    precise_message("porrectus deminutus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(widths, i, j, "rdeminutus", 1, S_PORRECTUS, L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(widths, i, j, "rdeminutus", 0, S_PORRECTUS_NOBAR, L_DEMINUTUS)
    precise_message("porrectus deminutus alt")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_alt_porrectus_deminutus(widths, i, j)

def write_porrectus(widths, i, j, last_glyph, with_bar, shape, lique=L_NOTHING):
    "Writes the porrectus glyphs."
    global oldfont
    new_glyph()
    glyph_name = '%s%s%s%s' % (shape, AMBITUS[i], AMBITUS[j], lique)
    if copy_existing_glyph(glyph_name):
        return
    first_glyph = "porrectus%d" % i
    if j == 1 and glyph_exists("porrectusam1%d" % i, oldfont):
        first_glyph = "porrectusam1%d" % i
    if last_glyph == 'auctusa2' or last_glyph == 'PunctumAuctusLineBL':
        first_glyph = "porrectusflexus%d" % i
    if not glyph_exists(first_glyph, oldfont):
        return
    if with_bar:
        write_first_bar(i)
    length = get_width(widths, first_glyph)
    simple_paste(first_glyph)
    write_line(j, length-get_width(widths, 'line2'), (-i+1)*BASE_HEIGHT)
    length = length-get_width(widths, 'line2')
    if with_bar:
        simplify()
    if last_glyph == "rdeminutus":
        length = length+get_width(widths, 'line2')
        paste_and_move(last_glyph, (length-get_width(widths, last_glyph)),
                       (j-i)*BASE_HEIGHT)
    elif last_glyph == 'auctusa2' or last_glyph == 'PunctumAuctusLineBL':
        paste_and_move(last_glyph, (length), (j-i)*BASE_HEIGHT)
        length = length + get_width(widths, last_glyph)
    else:
        paste_and_move(last_glyph,
                       (length-get_width(widths, last_glyph)+get_width(widths, 'line2')),
                       (j-i)*BASE_HEIGHT)
        length = length+get_width(widths, 'line2')
    set_width(length)
    end_glyph(glyph_name)

def write_alt_porrectus_deminutus(widths, i, j):
    "Writes the alternate porrectur deminutus glyphs."
    new_glyph()
    glyph_name = 'Porrectus%s%sDeminutus.alt' % (AMBITUS[i], AMBITUS[j])
    if copy_existing_glyph(glyph_name):
        return
    write_first_bar(i)
    if i == 1:
        first_glyph = 'PunctumLineBR'
    else:
        first_glyph = 'PunctumLineBLBR'
    simple_paste(first_glyph)
    write_line(i, get_width(widths, first_glyph)-get_width(widths, 'line2'), (-i+1)*BASE_HEIGHT)
    simplify()
    paste_and_move('mpdeminutus', (get_width(widths, first_glyph)-get_width(widths, 'line2')),
                   (-i)*BASE_HEIGHT)
    write_line(j,
               get_width(widths, first_glyph)+get_width(widths, 'mpdeminutus')-
               2*get_width(widths, 'line2'), (-i+1)*BASE_HEIGHT)
    paste_and_move('rdeminutus', (get_width(widths, first_glyph)
                                               + get_width(widths, 'mpdeminutus') -
                                               get_width(widths, 'line2') -
                                               get_width(widths, ('rdeminutus'))), (j-i)*BASE_HEIGHT)
    set_width(get_width(widths, first_glyph)+get_width(widths, 'mpdeminutus')-
              get_width(widths, 'line2'))
    end_glyph(glyph_name)


def porrectusflexus(widths):
    "Creates the porrectusflexus."
    message("porrectus flexus")
    precise_message("porrectus flexus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(widths, i, j, k, "PunctumLineTL", 0,
                                      S_PORRECTUS_FLEXUS_NOBAR)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(widths, i, j, k, "PunctumLineTL", 1,
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
    global oldfont
    new_glyph()
    glyph_name = '%s%s%s%s%s' % (shape, AMBITUS[i], AMBITUS[j], AMBITUS[k], lique)
    if copy_existing_glyph(glyph_name):
        return
    if j == 1:
        first_glyph = "porrectusflexusnb%d" % i
    else:
        first_glyph = "porrectusflexus%d" % i
    if not glyph_exists(first_glyph, oldfont):
        return
    if with_bar:
        write_first_bar(i)
    length = get_width(widths, first_glyph)
    simple_paste(first_glyph)
    write_line(j, length-get_width(widths, 'line2'), (-i+1)*BASE_HEIGHT)
    if last_glyph == "deminutus":
        width_dem = write_deminutus(widths, j-i, k, length-get_width(widths, 'line2'),
                        with_bar, firstbar=1)
        length = length+width_dem-get_width(widths, 'line2')
    else:
        simplify()
        middle_glyph = 'PunctumLineBLBR'
        if j == 1:
            if k == 1:
                middle_glyph = 'Punctum'
            else:
                middle_glyph = 'PunctumLineBR'
        else:
            length = length-get_width(widths, 'line2')
            if k == 1:
                middle_glyph = 'PunctumLineBL'
        paste_and_move(middle_glyph, length, (j-i)*BASE_HEIGHT)
        if k == 1:
            if last_glyph == 'PunctumLineTL':
                last_glyph = 'Punctum'
            elif last_glyph == 'auctusa1':
                last_glyph = 'PunctumAscendens'
            elif last_glyph == 'auctusd1':
                last_glyph = 'PunctumDescendens'
            length = length+get_width(widths, middle_glyph)
        else:
            write_line(k, length + get_width(widths, middle_glyph) - get_width(widths, 'line2'),
                       (j-i-k+1)*BASE_HEIGHT)
            length = length + get_width(widths, middle_glyph) - get_width(widths, 'line2')
        paste_and_move(last_glyph, length, (j-i-k)*BASE_HEIGHT)
        length = length+get_width(widths, last_glyph)
    set_width(length)
    end_glyph(glyph_name)

def torculus(widths):
    "Creates the torculus."
    message("torculus")
    precise_message("torculus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(widths, i, j, "PunctumLineTR", "PunctumLineTL", S_TORCULUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(widths, i, j, "QuilismaLineTR", "PunctumLineTL", S_TORCULUS_QUILISMA)
    precise_message("torculus initio debilis")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(widths, i, j, "idebilis", "PunctumLineTL", S_TORCULUS,
                           L_INITIO_DEBILIS)
    precise_message("torculus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(widths, i, j, "PunctumLineTR", "auctusd1", S_TORCULUS,
                           L_DESCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(widths, i, j, "QuilismaLineTR", "auctusd1", S_TORCULUS_QUILISMA,
                           L_DESCENDENS)
    precise_message("torculus initio debilis auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(widths, i, j, "idebilis", "auctusd1", S_TORCULUS,
                           L_INITIO_DEBILIS_DESCENDENS)
    precise_message("torculus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(widths, i, j, "PunctumLineTR", "auctusa1",
                           S_TORCULUS, L_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(widths, i, j, "QuilismaLineTR", "auctusa1", S_TORCULUS_QUILISMA,
                           L_ASCENDENS)
    precise_message("torculus initio debilis auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(widths, i, j, "idebilis", "auctusa1", S_TORCULUS,
                           L_INITIO_DEBILIS_ASCENDENS)
    precise_message("torculus deminutus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(widths, i, j, "PunctumLineTR", "deminutus", S_TORCULUS,
                           L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(widths, i, j, "QuilismaLineTR", "deminutus", S_TORCULUS_QUILISMA,
                           L_DEMINUTUS)
    precise_message("torculus initio debilis deminutus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(widths, i, j, "idebilis", "deminutus", S_TORCULUS,
                           L_INITIO_DEBILIS_DEMINUTUS)

def write_torculus(widths, i, j, first_glyph, last_glyph, shape, lique=L_NOTHING):
    "Writes the torculus glyphs."
    new_glyph()
    glyph_name = '%s%s%s%s' % (shape, AMBITUS[i], AMBITUS[j], lique)
    if copy_existing_glyph(glyph_name):
        return
    length = get_width(widths, first_glyph)-get_width(widths, 'line2')
    if first_glyph == "QuilismaLineTR":
        if i == 1:
            first_glyph = 'Quilisma'
            length = get_width(widths, first_glyph)
    elif i == 1 and first_glyph == 'PunctumLineTR':
        first_glyph = 'Punctum'
        length = length = get_width(widths, first_glyph)+0.1
    simple_paste(first_glyph)
    if i != 1:
        write_line(i, length, BASE_HEIGHT)
    if last_glyph == "deminutus":
        if i == 1:
            width_dem = write_deminutus(widths, i, j, length, firstbar=0)
        else:
            width_dem = write_deminutus(widths, i, j, length, firstbar=1)
        length = length+ width_dem
    else:
        if j == 1:
            if i == 1:
                second_glyph = 'Punctum'
            else:
                second_glyph = 'PunctumLineBL'
            paste_and_move(second_glyph, length, i*BASE_HEIGHT)
            length = length+get_width(widths, second_glyph)
            if last_glyph == 'PunctumLineTL':
                last_glyph = 'Punctum'
            elif last_glyph == 'auctusa1':
                last_glyph = 'PunctumAscendens'
            elif last_glyph == 'auctusd1':
                last_glyph = 'PunctumDescendens'
        else:
            if i == 1:
                second_glyph = 'PunctumLineBR'
            else:
                second_glyph = 'PunctumLineBLBR'
            paste_and_move(second_glyph, length, i*BASE_HEIGHT)
            length = length+get_width(widths, second_glyph)-get_width(widths, 'line2')
            write_line(j, length, (i-j+1)*BASE_HEIGHT)
        paste_and_move(last_glyph, length, (i-j)*BASE_HEIGHT)
        length = length+get_width(widths, last_glyph)
    set_width(length)
    end_glyph(glyph_name)

def torculus_liquescens(widths):
    "Creates the torculus liquescens."
    precise_message("torculus liquescens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculus_liquescens(widths, i, j, k, 'PunctumLineTR',
                                          S_TORCULUS_LIQUESCENS, L_DEMINUTUS)
    precise_message("torculus liquescens quilisma")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculus_liquescens(widths, i, j, k, 'QuilismaLineTR',
                                          S_TORCULUS_LIQUESCENS_QUILISMA, L_DEMINUTUS)

def write_torculus_liquescens(widths, i, j, k, first_glyph, shape,
                              lique='deminutus'):
    "Writes the torculus liquescens glyphs."
    new_glyph()
    glyph_name = '%s%s%s%s%s' % (shape, AMBITUS[i], AMBITUS[j], AMBITUS[k], lique)
    if copy_existing_glyph(glyph_name):
        return
    length = get_width(widths, first_glyph)-get_width(widths, 'line2')
    if first_glyph == "QuilismaLineTR":
        if i == 1:
            first_glyph = 'Quilisma'
            length = get_width(widths, first_glyph)
    elif i == 1:
        first_glyph = 'Punctum'
        length = get_width(widths, first_glyph)+0.1
    simple_paste(first_glyph)
    if i != 1:
        write_line(i, length, BASE_HEIGHT)
    flexus_firstbar = 2
    if j == 1:
        flexus_firstbar = 0
        if i == 1:
            second_glyph = 'Punctum'
        else:
            second_glyph = 'PunctumLineBL'
        paste_and_move(second_glyph, length, i*BASE_HEIGHT)
        length = length+get_width(widths, second_glyph)
    else:
        if i == 1:
            second_glyph = 'PunctumLineBR'
        else:
            second_glyph = 'PunctumLineBLBR'
        paste_and_move(second_glyph, length, i*BASE_HEIGHT)
        length = length+get_width(widths, second_glyph)-get_width(widths, 'line2')
        write_line(j, length, (i-j+1)*BASE_HEIGHT)
    width_dem = write_deminutus(widths, i-j, k, length, firstbar=flexus_firstbar)
    length = length+width_dem
    set_width(length)
    end_glyph(glyph_name)

def torculusresupinus(widths):
    "Creates the torculusresupinus."
    message("torculus resupinus")
    precise_message("torculus resupinus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(widths, i, j, k, 'PunctumLineTR', 'PunctumSmall',
                                        S_TORCULUS_RESUPINUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(widths, i, j, k, 'idebilis', 'PunctumSmall',
                                        S_TORCULUS_RESUPINUS, L_INITIO_DEBILIS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(widths, i, j, k, 'QuilismaLineTR', 'PunctumSmall',
                                        S_TORCULUS_RESUPINUS_QUILISMA)
    precise_message("torculus resupinus deminutus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(widths, i, j, k, 'PunctumLineTR', 'rdeminutus',
                                        S_TORCULUS_RESUPINUS, L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(widths, i, j, k, 'idebilis', 'rdeminutus',
                                        S_TORCULUS_RESUPINUS,
                                        L_INITIO_DEBILIS_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(widths, i, j, k, 'QuilismaLineTR', 'rdeminutus',
                                        S_TORCULUS_RESUPINUS_QUILISMA,
                                        L_DEMINUTUS)
    precise_message("torculus resupinus deminutus alt")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_alt_torculusresupinusdeminutus(widths, i, j, k, 'PunctumLineTR',
                                                     S_TORCULUS_RESUPINUS,
                                                     L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_alt_torculusresupinusdeminutus(widths, i, j, k, 'idebilis',
                                                     S_TORCULUS_RESUPINUS,
                                                     L_INITIO_DEBILIS_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_alt_torculusresupinusdeminutus(widths, i, j, k, 'QuilismaLineTR',
                                                     S_TORCULUS_RESUPINUS_QUILISMA,
                                                     L_DEMINUTUS)
    precise_message("torculus resupinus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(widths, i, j, k, 'PunctumLineTR', "auctusa2",
                                        S_TORCULUS_RESUPINUS, L_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(widths, i, j, k, 'idebilis', "auctusa2",
                                        S_TORCULUS_RESUPINUS,
                                        L_INITIO_DEBILIS_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(widths, i, j, k, 'QuilismaLineTR', "auctusa2",
                                        S_TORCULUS_RESUPINUS_QUILISMA,
                                        L_ASCENDENS)
    precise_message("torculus resupinus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(widths, i, j, k, 'PunctumLineTR', "PunctumAuctusLineBL",
                                        S_TORCULUS_RESUPINUS,
                                        L_DESCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(widths, i, j, k, 'idebilis', "PunctumAuctusLineBL",
                                        S_TORCULUS_RESUPINUS,
                                        L_INITIO_DEBILIS_DESCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(widths, i, j, k, 'QuilismaLineTR', "PunctumAuctusLineBL",
                                        S_TORCULUS_RESUPINUS_QUILISMA,
                                        L_DESCENDENS)

def write_torculusresupinus(widths, i, j, k, first_glyph, last_glyph, shape,
                            lique=L_NOTHING):
    "Writes the torculusresupinus glyphs."
    global oldfont
    new_glyph()
    glyph_name = '%s%s%s%s%s' % (shape, AMBITUS[i], AMBITUS[j], AMBITUS[k], lique)
    if copy_existing_glyph(glyph_name):
        return
    middle_glyph = "porrectus%d" % j
    if k == 1 and glyph_exists("porrectusam1%d" % j, oldfont):
        middle_glyph = "porrectusam1%d" % j
    if last_glyph == 'auctusa2' or last_glyph == 'PunctumAuctusLineBL':
        middle_glyph = "porrectusflexus%d" % j
    if not glyph_exists(middle_glyph, oldfont):
        return
    if i == 1 and first_glyph != 'idebilis':
        if first_glyph == 'PunctumLineTR':
            first_glyph = 'Punctum'
        elif first_glyph == 'QuilismaLineTR':
            first_glyph = 'Quilisma'
        length = get_width(widths, first_glyph)+0.1
    else:
        length = get_width(widths,first_glyph)-get_width(widths,'line2')
    simple_paste(first_glyph)
    if i != 1:
        write_line(i, length, BASE_HEIGHT)
    paste_and_move(middle_glyph, length, i*BASE_HEIGHT)
    length = length + get_width(widths, middle_glyph)
    if k != 1:
        write_line(k, length-get_width(widths, 'line2'), (i-j+1)*BASE_HEIGHT)
    simplify()
    if last_glyph == "rdeminutus":
        paste_and_move(last_glyph,
                       (length-get_width(widths, 'rdeminutus')),
                       (i-j+k)*BASE_HEIGHT)
    elif last_glyph == 'auctusa2' or last_glyph == 'PunctumAuctusLineBL':
        paste_and_move(last_glyph, (length-get_width(widths, 'line2')), (i-j+k)*BASE_HEIGHT)
        length = length - get_width(widths, 'line2') + get_width(widths, last_glyph)
    else:
        paste_and_move(last_glyph, (length-get_width(widths, last_glyph)),
                       (i-j+k)*BASE_HEIGHT)
    set_width(length)
    end_glyph(glyph_name)

def write_alt_torculusresupinusdeminutus(widths, i, j, k, first_glyph,
                                     shape, lique=L_NOTHING):
    # pylint: disable=invalid-name
    "Writes the torculusresupinusdeminutus glyphs."
    new_glyph()
    glyph_name = '%s%s%s%s%s.alt' % (shape, AMBITUS[i], AMBITUS[j], AMBITUS[k], lique)
    if copy_existing_glyph(glyph_name):
        return
    length = get_width(widths, first_glyph)-get_width(widths, 'line2')
    if i == 1:
        if first_glyph == 'PunctumLineTR':
            first_glyph = 'Punctum'
            length = get_width(widths, first_glyph)+0.1
        elif first_glyph == 'QuilismaLineTR':
            first_glyph = 'Quilisma'
            length = get_width(widths, first_glyph)+0.1
    simple_paste(first_glyph)
    if i != 1:
        write_line(i, length, BASE_HEIGHT)
    if j == 1 and i == 1:
        if first_glyph == "idebilis":
            second_glyph = 'PunctumLineBL'
            last_glyph = 'mnbpdeminutus'
        else:
            second_glyph = 'Punctum'
            last_glyph = 'mnbpdeminutus'
        paste_and_move(second_glyph, length, i*BASE_HEIGHT)
        length = length + get_width(widths, second_glyph)
    elif j == 1:
        second_glyph = 'PunctumLineBL'
        paste_and_move(second_glyph, length, i*BASE_HEIGHT)
        length = length + get_width(widths, second_glyph)
        last_glyph = 'mnbpdeminutus'
    elif i == 1 and first_glyph != "idebilis":
        second_glyph = 'PunctumLineBR'
        paste_and_move(second_glyph, length, i*BASE_HEIGHT)
        length = length + get_width(widths, second_glyph)-get_width(widths, 'line2')
        write_line(j, length, (i-j+1)*BASE_HEIGHT)
        last_glyph = 'mpdeminutus'
    else:
        second_glyph = 'PunctumLineBLBR'
        paste_and_move(second_glyph, length, i*BASE_HEIGHT)
        length = length + get_width(widths, second_glyph)-get_width(widths, 'line2')
        write_line(j, length, (i-j+1)*BASE_HEIGHT)
        last_glyph = 'mpdeminutus'
    paste_and_move(last_glyph, length, (i-j)*BASE_HEIGHT)
    length = length+get_width(widths, last_glyph)
    write_line(k, length-get_width(widths, 'line2'), (i-j+1)*BASE_HEIGHT)
    paste_and_move('rdeminutus',
                   length-get_width(widths, 'rdeminutus'), (i-j+k)*BASE_HEIGHT)
    set_width(length)
    end_glyph(glyph_name)

def scandicus(widths):
    "Creates the scandicus."
    message("scandicus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_scandicus(widths, i, j, 'PunctumSmall')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_scandicus(widths, i, j, 'rdeminutus', L_DEMINUTUS)

def write_scandicus(widths, i, j, last_glyph, lique=L_NOTHING):
    "Writes the scandicus glyphs."
    global oldfont
    new_glyph()
    final_vertical_shift = 0
    glyph_name = '%s%s%s%s' % (S_SCANDICUS, AMBITUS[i], AMBITUS[j], lique)
    if copy_existing_glyph(glyph_name):
        return
    # special case of i=j=1, we use glyph 1025 directly
    if i == 1 and j == 1 and lique == L_NOTHING:
        simple_paste('Punctum')
        second_glyph = 'PesOneNothing'
        paste_and_move(second_glyph, get_width(widths, 'Punctum'), BASE_HEIGHT)
        set_width(get_width(widths, 'PesOneNothing')+get_width(widths, 'Punctum'))
        end_glyph(glyph_name)
        return
    if i == 1:
        simple_paste('Punctum')
        length = get_width(widths, 'Punctum')
        second_glyph = 'p2base'
        if lique == L_DEMINUTUS:
            second_glyph = 'mnbpdeminutus'
        if j == 1:
            final_vertical_shift = DEMINUTUS_VERTICAL_SHIFT
    else:
        simple_paste('PunctumLineTR')
        length = get_width(widths, 'PunctumLineTR') - get_width(widths, 'line2')
        write_line(i, length, BASE_HEIGHT)
        second_glyph = 'msdeminutus'
        if j == 1 and glyph_exists('msdeminutusam1', oldfont):
            second_glyph = 'msdeminutusam1'
        if j == 1:
            final_vertical_shift = DEMINUTUS_VERTICAL_SHIFT
    paste_and_move(second_glyph, length, i*BASE_HEIGHT)
    if (i == 1) and lique == L_NOTHING:
        length = length + get_width(widths, 'Punctum')
    else:
        length = length + get_width(widths, second_glyph)
    if j != 1:
        write_line(j, length - get_width(widths, 'line2'), (i+1) * BASE_HEIGHT)
    if last_glyph == 'rdeminutus':
        paste_and_move('rdeminutus', length -
                       get_width(widths, 'rdeminutus'), (i+j)*BASE_HEIGHT+final_vertical_shift)
    else:
        paste_and_move(last_glyph, length - get_width(widths, last_glyph),
                       (i+j)*BASE_HEIGHT+final_vertical_shift)
    set_width(length)
    end_glyph(glyph_name)

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
    glyph_name = '%s%s%s%s' % (glyph_type, AMBITUS[i], AMBITUS[j], L_DEMINUTUS)
    if copy_existing_glyph(glyph_name):
        return
    if i == 1:
        second_glyph = 'mnbdeminutus'
        if first_glyph == 'vsbase':
            first_glyph = 'VirgaReversa'
        else:
            first_glyph = 'VirgaReversaLongqueue'
        length = get_width(widths, first_glyph)
    else:
        length = get_width(widths, first_glyph) - get_width(widths, 'line2')
        second_glyph = 'mademinutus'
    simple_paste(first_glyph)
    if i != 1:
        write_line(i, length, (-i+1)*BASE_HEIGHT)
    paste_and_move(second_glyph, length, -(i)*BASE_HEIGHT)
    length = length + get_width(widths, second_glyph)
    if j != 1:
        write_line(j, length - get_width(widths, 'line2'), (-i-j+1) * BASE_HEIGHT)
    paste_and_move('deminutus',
                   length - get_width(widths, 'deminutus'), (-i-j)*BASE_HEIGHT)
    set_width(length)
    end_glyph(glyph_name)

def leading(widths):
    "Creates the leading fusion glyphs."
    message("leading fusion glyphs")
    for i in range(1, MAX_INTERVAL+1):
        write_leading(widths, i, 'PunctumLineTR', S_LEADING_PUNCTUM)
    for i in range(1, MAX_INTERVAL+1):
        write_leading(widths, i, 'idebilis', S_LEADING_PUNCTUM, L_INITIO_DEBILIS)
    for i in range(1, MAX_INTERVAL+1):
        write_leading(widths, i, 'qbase', S_LEADING_QUILISMA)
    for i in range(1, MAX_INTERVAL+1):
        write_leading(widths, i, 'obase', S_LEADING_ORISCUS)

def write_leading_spacer(widths, glyph_name, width):
    "Writes the leading fusion spacer glyph."
    new_glyph()
    if copy_existing_glyph(glyph_name):
        return
    length = 0
    write_line(2, length, 0)
    set_width(width)
    end_glyph(glyph_name)

# lique has a slightly different meaning here
def write_leading(widths, i, first_glyph, glyph_type, lique=''):
    "Writes the leading fusion glyphs."
    new_glyph()
    glyph_name = '%s%s%s' % (glyph_type, AMBITUS[i], lique)
    if copy_existing_glyph(glyph_name):
        return
    length = -get_width(widths, 'line2')
    if i == 1 and first_glyph != 'idebilis':
        length = 0.1
        if first_glyph == 'PunctumLineTR':
            first_glyph = 'Punctum'
        elif first_glyph == 'qbase':
            first_glyph = 'Quilisma'
        elif first_glyph == 'obase':
            first_glyph = 'Oriscus'
    length = get_width(widths,first_glyph) + length
    paste_and_move(first_glyph, 0, -i * BASE_HEIGHT)
    if i != 1:
        write_line(i, length, -(i-1) * BASE_HEIGHT)
    simplify()
    set_width(length)
    end_glyph(glyph_name)

if __name__ == "__main__":
    main()
