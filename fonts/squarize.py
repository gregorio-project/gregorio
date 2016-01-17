# This is a fontforge python script; use fontforge -lang=py -script to run it
# coding=utf-8
# pylint: disable=too-many-branches, too-many-arguments, too-many-lines
# pylint: disable=import-error, no-member

"""
    Python fontforge script to build a square notation font.

    Copyright (C) 2013-2016 The Gregorio Project (see CONTRIBUTORS.md)

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
"""

from __future__ import print_function

import getopt, sys
import fontforge, psMat
import subprocess
import os
import argparse
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

GREGORIO_VERSION = '4.0.1'

# The unicode character at which we start our numbering:
# U+E000 is the start of the BMP Private Use Area
glyphnumber = 0xe000 - 1

# see defaults in get_parser()
BASE_HEIGHT = 0
HEPISEMA_ADDITIONAL_WIDTH=0
DEMINUTUS_VERTICAL_SHIFT=0
oldfont = None
newfont = None
font_name = None
subspecies = None
all_glyph_names = {}

def get_parser():
    "Return command line parser"
    parser = argparse.ArgumentParser(
        description="""Converts a small set of glyphs into a complete
gregorian square notation font. The initial glyphs have a name
convention, see gregorio-base.sfd.""")
    parser.add_argument('-b', '--base-height',
                        help='Half the vertical difference between two staff lines',
                        action='store', default=157.5, dest='BASE_HEIGHT')
    parser.add_argument('-a', '--hepisema-add',
                        help='Additional length added left and right of horizontal episema',
                        action='store', default=5, dest='HEPISEMA_ADDITIONAL_WIDTH')
    parser.add_argument('-d', '--deminutus-shift',
                        help='Vertical shifting of deminutus second note when ambitus is one',
                        action='store', default=10, dest='DEMINUTUS_VERTICAL_SHIFT')
    parser.add_argument('-o', '--outfile',
                        help='output ttf file name',
                        action='store', default=False, dest='outfile')
    parser.add_argument('-s', '--sub-species',
                        help='subspecies (can be \'op\')',
                        action='store', default=False, dest='subspecies')
    parser.add_argument('base_font', help="input sfd file name", action='store')
    return parser

def main():
    "Main function"
    global oldfont, newfont, font_name, subspecies, BASE_HEIGHT, HEPISEMA_ADDITIONAL_WIDTH, DEMINUTUS_VERTICAL_SHIFT
    parser = get_parser()
    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(1)
    args = parser.parse_args()
    subspecies = '_%s' % args.subspecies if args.subspecies else ''
    BASE_HEIGHT = int(args.BASE_HEIGHT)
    HEPISEMA_ADDITIONAL_WIDTH = int(args.HEPISEMA_ADDITIONAL_WIDTH)
    DEMINUTUS_VERTICAL_SHIFT = int(args.DEMINUTUS_VERTICAL_SHIFT)
    outfile = args.outfile
    inputfile = args.base_font
    if not outfile:
        pre, ext = os.path.splitext(inputfile)
        outfile = '%s.ttf' % pre
    oldfont = fontforge.open(inputfile)
    font_name = oldfont.fontname + subspecies
    newfont = fontforge.font()
    # newfont.encoding = "UnicodeFull"
    newfont.encoding = "ISO10646-1"
    newfont.fontname = oldfont.fontname
    newfont.fullname = oldfont.fullname
    newfont.familyname = oldfont.familyname
    newfont.version = GREGORIO_VERSION
    newfont.copyright = oldfont.copyright.replace('<<GPLV3>>', GPLV3)
    newfont.weight = "regular"
    initialize_glyphs()
    hepisema()
    measures()
    pes()
    pes_quadratum()
    virga_strata()
    flexus()
    scandicus()
    ancus()
    salicus()
    salicus_flexus()
    torculus()
    torculus_liquescens()
    porrectus()
    porrectusflexus()
    torculusresupinus()
    leading()
    fusion()
    fusion_pes()
    fusion_pes_quadratum()
    fusion_flexus()
    fusion_porrectus()
    # variants must be copied last!
    copy_variant_glyphs()
    newfont.generate(outfile)
    oldfont.close()
    newfont.close()
    print('last code point in', font_name, 'is', hex(glyphnumber))

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
    'StrophaAuctaLongtail',
    'VirgaLongqueue',
    'Virga',
    'VirgaReversaLongqueue',
    'VirgaReversa',
    'VirgaLineBR',
    'Quilisma',
    'QuilismaLineTR',
    'Oriscus',
    'OriscusLineBL',
    'OriscusLineTR',
    'OriscusReversus',
    'OriscusReversusLineTL',
    'OriscusScapusLongqueue',
    'OriscusScapus',
    'PunctumInclinatumAuctus',
    'PunctumInclinatumDeminutus',
    'VEpisema',
    'VEpisema.circumflexus',
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
    'RoundBraceDown',
    'OriscusDeminutus',
    'VirgaReversaAscendens',
    'VirgaReversaLongqueueAscendens',
    'VirgaReversaDescendens',
    'VirgaReversaLongqueueDescendens',
    'PunctumSmall',
    'PunctumLineBR',
    'PunctumLineBL',
    'PunctumLineTL',
    'PunctumLineTR',
    'PunctumLineBLBR',
    'PunctumAuctusLineBL',
    'SalicusOriscus',
    'PunctumCavumInclinatum',
    'PunctumCavumInclinatumHole',
    'PunctumCavumInclinatumAuctus',
    'PunctumCavumInclinatumAuctusHole',
    'OriscusCavum',
    'OriscusCavumHole',
    'OriscusCavumReversus',
    'OriscusCavumReversusHole',
    'OriscusCavumDeminutus',
    'OriscusCavumDeminutusHole',
]

GLYPH_EXISTS = {}

def glyph_exists(glyph_name):
    "returns if glyph named glyphName exists in font (boolean)"
    global GLYPH_EXISTS, oldfont
    if glyph_name in GLYPH_EXISTS:
        return GLYPH_EXISTS[glyph_name]
    result = True
    try:
        oldfont.selection.select(glyph_name)
    except:
        result = False
    GLYPH_EXISTS[glyph_name] = result
    return result

def subspecies_of(glyph_name):
    if subspecies and glyph_exists(glyph_name + subspecies):
        return glyph_name + subspecies
    else:
        return glyph_name

def copy_existing_glyph(glyph_name):
    "copies the named glyph, if it exists, and returns whether it was copied"
    if glyph_exists(glyph_name):
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
        if glyph_exists(name):
            oldfont.selection.select(subspecies_of(name))
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
                name.find("_") == -1 and name not in COMMON_DIRECT_VARIANTS):
            new_glyph()
            oldfont.selection.select(subspecies_of(name))
            oldfont.copy()
            newfont.paste()
            set_glyph_name(name)

# this will be populated by get_width
WIDTHS = {}

def get_width(glyphName):
    "Get length of glyph glyphName in the base font."
    global oldfont
    if glyphName not in WIDTHS:
        if glyph_exists(glyphName):
            WIDTHS[glyphName] = oldfont[subspecies_of(glyphName)].width
        else:
            WIDTHS[glyphName] = 0
    return WIDTHS[glyphName]

# Shapes
S_PES                              = 'Pes'
S_UPPER_PES                        = 'UpperPes'
S_LOWER_PES                        = 'LowerPes'
S_PES_QUADRATUM                    = 'PesQuadratum'
S_UPPER_PES_QUADRATUM              = 'UpperPesQuadratum'
S_LOWER_PES_QUADRATUM              = 'LowerPesQuadratum'
S_PES_QUADRATUM_LONGQUEUE          = 'PesQuadratumLongqueue'
S_UPPER_PES_QUADRATUM_LONGQUEUE    = 'UpperPesQuadratumLongqueue'
S_LOWER_PES_QUADRATUM_LONGQUEUE    = 'LowerPesQuadratumLongqueue'
S_PES_QUILISMA                     = 'PesQuilisma'
S_PES_QUASSUS                      = 'PesQuassus'
S_UPPER_PES_QUASSUS                = 'UpperPesQuassus'
S_LOWER_PES_QUASSUS                = 'LowerPesQuassus'
S_PES_QUASSUS_LONGQUEUE            = 'PesQuassusLongqueue'
S_UPPER_PES_QUASSUS_LONGQUEUE      = 'UpperPesQuassusLongqueue'
S_LOWER_PES_QUASSUS_LONGQUEUE      = 'LowerPesQuassusLongqueue'
S_PES_QUILISMA_QUADRATUM           = 'PesQuilismaQuadratum'
S_PES_QUILISMA_QUADRATUM_LONGQUEUE = 'PesQuilismaQuadratumLongqueue'
S_FLEXUS                           = 'Flexus'
S_UPPER_FLEXUS                     = 'UpperFlexus'
S_LOWER_FLEXUS                     = 'LowerFlexus'
S_FLEXUS_NOBAR                     = 'FlexusNobar'
S_FLEXUS_LONGQUEUE                 = 'FlexusLongqueue'
S_FLEXUS_ORISCUS                   = 'FlexusOriscus'
S_LOWER_FLEXUS_ORISCUS             = 'LowerFlexusOriscus'
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
S_SALICUS_FLEXUS                   = 'SalicusFlexus'
S_TORCULUS_LIQUESCENS              = 'TorculusLiquescens'
S_TORCULUS_LIQUESCENS_QUILISMA     = 'TorculusLiquescensQuilisma'
S_FLEXUS_ORISCUS_SCAPUS            = 'FlexusOriscusScapus'
S_FLEXUS_ORISCUS_SCAPUS_LONGQUEUE  = 'FlexusOriscusScapusLongqueue'
S_LEADING_PUNCTUM                  = 'LeadingPunctum'
S_LEADING_QUILISMA                 = 'LeadingQuilisma'
S_LEADING_ORISCUS                  = 'LeadingOriscus'
S_PUNCTUM                          = 'Punctum'
S_UPPER_PUNCTUM                    = 'UpperPunctum'
S_LOWER_PUNCTUM                    = 'LowerPunctum'
S_QUILISMA                         = 'Quilisma'
S_ORISCUS                          = 'Oriscus'
S_ORISCUS_SCAPUS                   = 'OriscusScapus'
S_ORISCUS_SCAPUS_LONGQUEUE         = 'OriscusScapusLongqueue'
S_UPPER_ORISCUS                    = 'UpperOriscus'
S_LOWER_ORISCUS                    = 'LowerOriscus'
S_VIRGA_REVERSA                    = 'VirgaReversa'
S_VIRGA_REVERSA_LONGQUEUE          = 'VirgaReversaLongqueue'

# Liquescentiae
L_NOTHING                   = 'Nothing'
L_INITIO_DEBILIS            = 'InitioDebilis'
L_DEMINUTUS                 = 'Deminutus'
L_ASCENDENS                 = 'Ascendens'
L_DESCENDENS                = 'Descendens'
L_UP                        = 'Up'
L_DOWN                      = 'Down'
L_INITIO_DEBILIS_DEMINUTUS  = 'InitioDebilisDeminutus'
L_INITIO_DEBILIS_ASCENDENS  = 'InitioDebilisAscendens'
L_INITIO_DEBILIS_DESCENDENS = 'InitioDebilisDescendens'
L_INITIO_DEBILIS_UP         = 'InitioDebilisUp'


def simple_paste(src):
    "Copy and paste a glyph."
    global oldfont, newfont, glyphnumber
    oldfont.selection.select(subspecies_of(src))
    oldfont.copy()
    newfont.selection.select('u%05x' % glyphnumber)
    newfont.pasteInto()

def complete_paste(src):
    "Copy and paste a glyph."
    global oldfont, newfont, glyphnumber
    oldfont.selection.select(subspecies_of(src))
    oldfont.copy()
    newfont.selection.select('u%05x' % glyphnumber)
    newfont.paste()

def simplify():
    "Simplify a glyph."
    global newfont, glyphnumber
    newfont[glyphnumber].simplify(0, ['mergelines'])
    newfont[glyphnumber].simplify()
    newfont[glyphnumber].removeOverlap()
    newfont[glyphnumber].simplify(0, ['mergelines'])
    newfont[glyphnumber].simplify()

def paste_and_move(src, xdimen, ydimen):
    "Pastes the src glyph into dst, and moves it with horiz and vert offsets."
    global oldfont, newfont, glyphnumber
    src = subspecies_of(src)
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
    newfont[glyphnumber].simplify(0, ['mergelines'])
    newfont[glyphnumber].simplify()
    newfont[glyphnumber].removeOverlap()
    newfont[glyphnumber].simplify(0, ['mergelines'])
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

def write_deminutus(i, j, length=0, tosimplify=0, firstbar=1):
    """As the glyph before a deminutus is not the same as a normal glyph,
    and always the same, we can call this function each
    time. Sometimes we have to simplify before building the last glyph
    (tosimplify=1), and length is the offset.
    """
    first_glyph_is_complete = False
    first_glyph = 'mademinutus' # firstbar == 2
    if firstbar == 1:
        first_glyph = 'mdeminutus'
    elif firstbar == 0:
        first_glyph = 'mnbdeminutus'
    if j == 1:
        if glyph_exists('%sam1flexus' % first_glyph):
            first_glyph = '%sam1flexus' % first_glyph
            first_glyph_is_complete = True
        elif glyph_exists('%sam1' % first_glyph):
            first_glyph = '%sam1flexus' % first_glyph
    paste_and_move(first_glyph, length, i*BASE_HEIGHT)
    if not first_glyph_is_complete:
        write_line(j, length+get_width(first_glyph)-get_width('line2'),
               (i-j+1)*BASE_HEIGHT)
    if tosimplify:
        simplify()
    if not first_glyph_is_complete:
        paste_and_move("deminutus",
                   length+get_width(first_glyph)-get_width('deminutus'),
                   (i-j)*BASE_HEIGHT)
    return get_width(first_glyph)

def measures():
    "Creates glyphs used only for measurement."
    message("glyphs for measurement")
    new_glyph()
    first_glyph = 'PunctumLineBLBR'
    second_glyph = 'PunctumLineTL'
    simple_paste(first_glyph)
    write_line(1, get_width(first_glyph) - get_width('line2'), -BASE_HEIGHT)
    paste_and_move(second_glyph, get_width(first_glyph) - get_width('line2'), -BASE_HEIGHT)
    set_width(get_width(first_glyph)+get_width(second_glyph)-get_width('line2'))
    end_glyph('FlexusLineBL')
    new_glyph()
    first_glyph = 'PunctumLineBL'
    second_glyph = 'Punctum'
    simple_paste(first_glyph)
    paste_and_move(second_glyph, get_width(first_glyph), -BASE_HEIGHT)
    set_width(get_width(first_glyph)+get_width(second_glyph))
    end_glyph('FlexusAmOneLineBL')

HEPISEMA_GLYPHS = {
    'HEpisemaPunctum': 'Punctum',
    'HEpisemaFlexusDeminutus': 'mpdeminutus',
    'HEpisemaDebilis': 'idebilis',
    'HEpisemaInclinatum': 'PunctumInclinatum',
    'HEpisemaInclinatumDeminutus': 'PunctumInclinatumDeminutus',
    'HEpisemaStropha': 'Stropha',
    'HEpisemaQuilisma': 'Quilisma',
    'HEpisemaQuilismaLineTR': 'QuilismaLineTR',
    'HEpisemaHighPes': 'PunctumSmall',
    'HEpisemaOriscus': 'Oriscus',
    'HEpisemaVirga': 'Virga',
    'HEpisemaVirgaLineBR': 'VirgaLineBR',
    'HEpisemaOriscusLineTR': 'OriscusLineTR',
    'HEpisemaPunctumLineBR': 'PunctumLineBR',
    'HEpisemaPunctumLineBL': 'PunctumLineBL',
    'HEpisemaPunctumLineTL': 'PunctumLineTL',
    'HEpisemaPunctumLineTR': 'PunctumLineTR',
    'HEpisemaPunctumLineBLBR': 'PunctumLineBLBR',
    'HEpisemaPunctumAuctusLineBL': 'PunctumAuctusLineBL',
    'HEpisemaSalicusOriscus': 'SalicusOriscus',
}

def hepisema():
    "Creates horizontal episemata."
    message("horizontal episema")
    for target, source in HEPISEMA_GLYPHS.items():
        write_hepisema(get_width(source), target)
        write_hepisema(get_width(source) * 2.0 / 3.0, target + "Reduced")
    reduction = get_width('PunctumSmall')
    for i in range(1, MAX_INTERVAL+1):
        write_hepisema(get_width("porrectus%d"%i),
                'HEpisemaPorrectus%s' % AMBITUS[i], reduction)
    for i in range(1, MAX_INTERVAL+1):
        if glyph_exists("porrectusam1%d"%i):
            write_hepisema(get_width("porrectusam1%d"%i),
                    'HEpisemaPorrectusAmOne%s' % AMBITUS[i], reduction)
        else:
            write_hepisema(get_width("porrectus%d"%i),
                    'HEpisemaPorrectusAmOne%s' % AMBITUS[i], reduction)
    # porrectus flexus does not get reduced because the note after is to the right
    for i in range(1, MAX_INTERVAL+1):
        write_hepisema(get_width("porrectusflexus%d"%i),
                'HEpisemaPorrectusFlexus%s' % AMBITUS[i])

def write_hepisema(shape_width, glyphname, reduction=0):
    "Writes the horizontal episema glyphs."
    global HEPISEMA_ADDITIONAL_WIDTH
    new_glyph()
    simple_paste("hepisema_base")
    drawn_width = shape_width - reduction
    scale(drawn_width + 2*HEPISEMA_ADDITIONAL_WIDTH, 1)
    move(-HEPISEMA_ADDITIONAL_WIDTH, 0)
    if glyph_exists('hepisemaleft'):
        paste_and_move("hepisemaleft", -HEPISEMA_ADDITIONAL_WIDTH, 0)
    if glyph_exists('hepisemaright'):
        paste_and_move("hepisemaright",
                   drawn_width + HEPISEMA_ADDITIONAL_WIDTH, 0)
    # use the original width for the glyph for the sake of ledger lines
    set_width(shape_width)
    end_glyph(glyphname)

def pes():
    "Creates the pes."
    message("pes")
    precise_message("pes")
    for i in range(1, MAX_INTERVAL+1):
        write_pes(i, "p2base", S_PES)
    precise_message("pes deminutus")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_deminutus(i, "pesdeminutus", S_PES, L_DEMINUTUS)
    precise_message("pes quilisma")
    for i in range(1, MAX_INTERVAL+1):
        write_pes(i, "QuilismaLineTR", S_PES_QUILISMA)
    precise_message("pes quilisma deminutus")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_deminutus(i, "QuilismaLineTR", S_PES_QUILISMA,
                L_DEMINUTUS)
    precise_message("pes quassus deminutus")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_deminutus(i, "OriscusLineTR", S_PES_QUASSUS,
                L_DEMINUTUS)
    precise_message("pes initio debilis")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_debilis(i, S_PES, L_INITIO_DEBILIS)
    precise_message("pes initio debilis deminutus")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_debilis_deminutus(i, S_PES,
                L_INITIO_DEBILIS_DEMINUTUS)

def fusion_pes():
    "Creates the fusion pes."
    message("fusion pes")
    precise_message("fusion pes")
    for i in range(1, MAX_INTERVAL+1):
        write_pes(i, "msdeminutus", S_UPPER_PES)
    precise_message("fusion pes deminutus")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_deminutus(i, "msdeminutus", S_UPPER_PES, L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        write_pes_deminutus(i, "mpdeminutus", S_LOWER_PES, L_DEMINUTUS)
    precise_message("fusion pes quassus deminutus")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_deminutus(i, "SalicusOriscus", S_UPPER_PES_QUASSUS,
                L_DEMINUTUS)

def write_pes(i, first_glyph, shape, lique=L_NOTHING):
    "Writes the pes glyphs."
    new_glyph()
    glyph_name = '%s%s%s' % (shape, AMBITUS[i], lique)
    if copy_existing_glyph(glyph_name):
        return
    get_width('QuilismaLineTR')
    temp_width = 0
    width_difference = get_width(first_glyph)-get_width('PunctumSmall')
    if width_difference < 0:
        paste_and_move(first_glyph, -width_difference, 0)
    else:
        simple_paste(first_glyph)
    temp_width = get_width(first_glyph)-get_width('line2')
    if width_difference < 0:
        temp_width = temp_width-width_difference
    write_line(i, temp_width, BASE_HEIGHT)
    if width_difference != 0:
        paste_and_move('PunctumSmall', width_difference, i*BASE_HEIGHT)
    else:
        paste_and_move('PunctumSmall', 0, i*BASE_HEIGHT)
    if width_difference < 0:
        set_width(get_width('PunctumSmall'))
    else:
        set_width(get_width(first_glyph))
    end_glyph(glyph_name)

def write_pes_debilis(i, shape, lique=L_NOTHING):
    "Writes the pes debilis glyphs."
    new_glyph()
    glyph_name = '%s%s%s' % (shape, AMBITUS[i], lique)
    if copy_existing_glyph(glyph_name):
        return
    # with a deminutus it is much more beautiful than with a idebilis
    simple_paste("deminutus")
    write_line(i, get_width('deminutus')-get_width('line2'), BASE_HEIGHT)
    simplify()
    paste_and_move("PunctumLineBL", get_width('deminutus')-get_width('line2'), i*BASE_HEIGHT)
    set_width(get_width('deminutus')+get_width('PunctumLineBL')-get_width('line2'))
    end_glyph(glyph_name)

def write_pes_deminutus(i, first_glyph, shape, lique=L_NOTHING):
    "Writes the pes deminutus glyphs."
    new_glyph()
    glyph_name = '%s%s%s' % (shape, AMBITUS[i], lique)
    if copy_existing_glyph(glyph_name):
        return
    simple_paste(first_glyph)
    temp_width = get_width(first_glyph)-get_width('line2')
    write_line(i, temp_width, BASE_HEIGHT)
    paste_and_move("rdeminutus",
                   get_width(first_glyph)-get_width('rdeminutus'),
                   i*BASE_HEIGHT)
    set_width(get_width(first_glyph))
    end_glyph(glyph_name)

def write_pes_debilis_deminutus(i, shape, lique=L_NOTHING):
    "Writes the pes debilis deminutus glyphs."
    new_glyph()
    glyph_name = '%s%s%s' % (shape, AMBITUS[i], lique)
    if copy_existing_glyph(glyph_name):
        return
    simple_paste("deminutus")
    write_line(i, get_width('deminutus')-get_width('line2'), BASE_HEIGHT)
    simplify()
    paste_and_move("rdeminutus", 0, i*BASE_HEIGHT)
    set_width(get_width('deminutus'))
    end_glyph(glyph_name)

def pes_quadratum():
    "Makes the pes quadratum."
    message("pes quadratum")
    precise_message("pes quadratum")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "PunctumLineTR", "rvsbase", S_PES_QUADRATUM)
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "PunctumLineTR", "rvlbase", S_PES_QUADRATUM_LONGQUEUE)
    precise_message("pes quassus")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "OriscusLineTR", "rvsbase", S_PES_QUASSUS)
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "OriscusLineTR", "rvlbase", S_PES_QUASSUS_LONGQUEUE)
    precise_message("pes quilisma quadratum")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "QuilismaLineTR", "rvsbase", S_PES_QUILISMA_QUADRATUM)
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "QuilismaLineTR",
                            "rvlbase", S_PES_QUILISMA_QUADRATUM_LONGQUEUE)
    precise_message("pes auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "PunctumLineTR",
                            "auctusa2", S_PES_QUADRATUM, L_ASCENDENS)
    precise_message("pes initio debilis auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "idebilis",
                            "auctusa2", S_PES_QUADRATUM,
                            L_INITIO_DEBILIS_ASCENDENS)
    precise_message("pes quassus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "OriscusLineTR",
                            "auctusa2", S_PES_QUASSUS, L_ASCENDENS)
    precise_message("pes quilisma auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "QuilismaLineTR",
                            "auctusa2", S_PES_QUILISMA_QUADRATUM,
                            L_ASCENDENS)
    precise_message("pes auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "PunctumLineTR",
                            "PunctumAuctusLineBL", S_PES_QUADRATUM, L_DESCENDENS)
    precise_message("pes initio debilis auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "idebilis",
                            "PunctumAuctusLineBL", S_PES_QUADRATUM,
                            L_INITIO_DEBILIS_DESCENDENS)
    precise_message("pes quassus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "OriscusLineTR",
                            "PunctumAuctusLineBL", S_PES_QUASSUS, L_DESCENDENS)
    precise_message("pes quilisma auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "QuilismaLineTR", "PunctumAuctusLineBL",
                            S_PES_QUILISMA_QUADRATUM, L_DESCENDENS)

def fusion_pes_quadratum():
    "Makes the fusion pes quadratum."
    message("fusion pes quadratum")
    precise_message("fusion pes quadratum")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "msdeminutus", "rvsbase",
                S_UPPER_PES_QUADRATUM)
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "base6", "rvsbase",
                S_LOWER_PES_QUADRATUM)
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "msdeminutus", "rvlbase",
                S_UPPER_PES_QUADRATUM_LONGQUEUE)
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "base6", "rvlbase",
                S_LOWER_PES_QUADRATUM_LONGQUEUE)
    precise_message("fusion pes quassus")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "SalicusOriscus", "rvsbase",
                S_UPPER_PES_QUASSUS)
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "SalicusOriscus", "rvlbase",
                S_UPPER_PES_QUASSUS_LONGQUEUE)
    precise_message("fusion pes auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "msdeminutus", "auctusa2",
                S_UPPER_PES_QUADRATUM, L_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "base6", "auctusa2",
                S_LOWER_PES_QUADRATUM, L_ASCENDENS)
    precise_message("fusion pes quassus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "SalicusOriscus", "auctusa2",
                S_UPPER_PES_QUASSUS, L_ASCENDENS)
    precise_message("fusion pes auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "msdeminutus", "PunctumAuctusLineBL",
                S_UPPER_PES_QUADRATUM, L_DESCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "base6", "PunctumAuctusLineBL",
                S_LOWER_PES_QUADRATUM, L_DESCENDENS)
    precise_message("fusion pes quassus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "SalicusOriscus", "PunctumAuctusLineBL",
                S_UPPER_PES_QUASSUS, L_DESCENDENS)

def write_pes_quadratum(i, first_glyph, last_glyph, shape, lique=L_NOTHING):
    "Writes the pes quadratum glyphs."
    new_glyph()
    glyph_name = '%s%s%s' % (shape, AMBITUS[i], lique)
    if copy_existing_glyph(glyph_name):
        return
    if first_glyph == "idebilis":
        first_width = get_width('idebilis')-get_width('line2')
    elif first_glyph == "PunctumLineTR" or first_glyph == "OriscusLineTR":
        if i == 1:
            if first_glyph == 'PunctumLineTR':
                first_glyph = 'Punctum'
            if first_glyph == 'msdeminutus':
                first_glyph = 'PunctumLineBL'
            if first_glyph == 'base6':
                first_glyph = 'PunctumLineTL'
            elif first_glyph == 'OriscusLineTR':
                first_glyph = 'Oriscus'
            elif first_glyph == 'SalicusOriscus':
                first_glyph = 'OriscusLineBL'

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

            first_width = get_width(first_glyph)
        else:
            first_width = get_width(first_glyph)-get_width('line2')
    else:
        first_width = get_width(first_glyph)-get_width('line2')
    simple_paste(first_glyph)
    if i != 1:
        linename = "line%d" % i
        paste_and_move(linename, first_width, BASE_HEIGHT)
    paste_and_move(last_glyph, first_width, i*BASE_HEIGHT)
    set_width(first_width+get_width(last_glyph))
    end_glyph(glyph_name)

def virga_strata():
    "Creates the virga strata."
    precise_message("virga strata")
    for i in range(1, MAX_INTERVAL+1):
        write_virga_strata(i, "PunctumLineTR", "OriscusLineBL",
                S_VIRGA_STRATA)

def write_virga_strata(i, first_glyph, last_glyph, shape, lique=L_NOTHING):
    "Writes the virga strata glyphs."
    new_glyph()
    glyph_name = '%s%s%s' % (shape, AMBITUS[i], lique)
    if copy_existing_glyph(glyph_name):
        return
    if i == 1:
        first_glyph = 'Punctum'
        first_width = get_width(first_glyph)
        last_glyph = 'Oriscus'
    else:
        first_width = get_width(first_glyph)-get_width('line2')
    simple_paste(first_glyph)
    if i != 1:
        linename = "line%d" % i
        paste_and_move(linename, first_width, BASE_HEIGHT)
    paste_and_move(last_glyph, first_width, i*BASE_HEIGHT)
    set_width(first_width+get_width(last_glyph))
    end_glyph(glyph_name)

def salicus():
    "Creates the salicus."
    message("salicus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_salicus(i, j, "rvsbase", S_SALICUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_salicus(i, j, "rvlbase", S_SALICUS_LONGQUEUE)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_salicus(i, j, "rdeminutus", S_SALICUS, L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_salicus(i, j, "auctusa2", S_SALICUS, L_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_salicus(i, j, "PunctumAuctusLineBL", S_SALICUS,
                    L_DESCENDENS)

def write_salicus(i, j, last_glyph, shape, lique=L_NOTHING):
    "Writes the salicus glyphs."
    new_glyph()
    glyph_name = '%s%s%s%s' % (shape, AMBITUS[i], AMBITUS[j], lique)
    if copy_existing_glyph(glyph_name):
        return
    length = draw_salicus(i, j, last_glyph)
    set_width(length)
    end_glyph(glyph_name)

def draw_salicus(i, j, last_glyph):
    not_deminutus = last_glyph != 'rdeminutus'
    if j == 1 and not_deminutus:
        if last_glyph == 'rvsbase':
            last_glyph = 'Virga'
        elif last_glyph == 'rvlbase':
            last_glyph = 'VirgaLongqueue'
    if i == 1 and j == 1 and not_deminutus:
        first_glyph = 'Punctum'
        first_width = get_width(first_glyph)
        middle_glyph = 'Oriscus'
        middle_width = get_width(middle_glyph)
    elif i == 1:
        first_glyph = 'Punctum'
        first_width = get_width(first_glyph)
        middle_glyph = 'OriscusLineTR'
        middle_width = get_width(middle_glyph)-get_width('line2')
    elif j == 1 and not_deminutus:
        first_glyph = 'PunctumLineTR'
        first_width = get_width(first_glyph)-get_width('line2')
        middle_glyph = 'OriscusLineBL'
        middle_width = get_width(middle_glyph)
    else:
        first_glyph = 'PunctumLineTR'
        first_width = get_width(first_glyph)-get_width('line2')
        middle_glyph = 'SalicusOriscus'
        middle_width = get_width(middle_glyph)-get_width('line2')
    simple_paste(first_glyph)
    if i != 1:
        linename = "line%d" % i
        paste_and_move(linename, first_width, BASE_HEIGHT)
    paste_and_move(middle_glyph, first_width, i*BASE_HEIGHT)
    length = first_width+middle_width
    if j != 1:
        linename = "line%d" % j
        paste_and_move(linename, length, (i+1)*BASE_HEIGHT)
    elif not_deminutus:
        length = length-0.01
        if last_glyph == 'auctusa2':
            last_glyph = 'PunctumAscendens'
        elif last_glyph == 'PunctumAuctusLineBL':
            last_glyph = 'PunctumDescendens'
        elif last_glyph == 'rvsbase':
            last_glyph = 'Virga'
        elif last_glyph == 'rvlbase':
            last_glyph = 'VirgaLongqueue'
        elif last_glyph == 'PunctumLineBLBR':
            last_glyph = 'PunctumLineBR'
        elif last_glyph == 'PunctumLineBL':
            last_glyph = 'Punctum'
    if not last_glyph:
        return length
    if not_deminutus:
        paste_and_move(last_glyph, length, (i+j)*BASE_HEIGHT)
        length = length + get_width(last_glyph)
    else:
        length = length+get_width('line2')
        paste_and_move(last_glyph, (length-get_width(last_glyph)),
                       (i+j)*BASE_HEIGHT)
    return length

def salicus_flexus():
    "Creates the salicus flexus."
    message("salicus flexus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_salicus_flexus(i, j, k, "PunctumLineTL")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_salicus_flexus(i, j, k, "deminutus", L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_salicus_flexus(i, j, k, "auctusa1", L_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_salicus_flexus(i, j, k, "auctusd1", L_DESCENDENS)

def write_salicus_flexus(i, j, k, last_glyph, lique=L_NOTHING):
    "Writes the salicus glyphs."
    new_glyph()
    glyph_name = '%s%s%s%s%s' % (S_SALICUS_FLEXUS, AMBITUS[i], AMBITUS[j],
            AMBITUS[k], lique)
    if copy_existing_glyph(glyph_name):
        return
    is_deminutus = last_glyph == 'deminutus'
    if is_deminutus:
        penult_glyph = None
    elif k == 1:
        penult_glyph = 'PunctumLineBL'
    else:
        penult_glyph = 'PunctumLineBLBR'
    length = draw_salicus(i, j, penult_glyph)
    if is_deminutus:
        width_dem = write_deminutus(j+i, k, length,
                        firstbar = 0 if j == 1 else 1)
        length = length + width_dem
    else:
        if k == 1 and not is_deminutus:
            length = length-0.01
            if last_glyph == 'PunctumLineTL':
                last_glyph = 'Punctum'
            elif last_glyph == 'auctusa1':
                last_glyph = 'PunctumAscendens'
            elif last_glyph == 'auctusd1':
                last_glyph = 'PunctumDescendens'
        if k != 1:
            length = length - get_width('line2')
            write_line(k, length, (1+i+j-k)*BASE_HEIGHT)
        paste_and_move(last_glyph, length, (i+j-k)*BASE_HEIGHT)
        length = length + get_width(last_glyph)
    set_width(length)
    end_glyph(glyph_name)

def flexus():
    "Creates the flexus."
    message("flexus")
    precise_message("flexus")
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "PunctumLineBR", 'PunctumLineTL', S_FLEXUS_NOBAR)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "odbase", 'PunctumLineTL', S_FLEXUS_ORISCUS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "vbase"+str(i), 'PunctumLineTL', S_FLEXUS)
    write_flexus(1, "vlbase", 'PunctumLineTL', S_FLEXUS_LONGQUEUE)
    for i in range(2, MAX_INTERVAL+1):
        write_flexus(i, "vbase"+str(i), 'PunctumLineTL', S_FLEXUS_LONGQUEUE)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "osbase"+str(i), 'PunctumLineTL',
                S_FLEXUS_ORISCUS_SCAPUS)
    write_flexus(1, "oslbase", 'PunctumLineTL',
            S_FLEXUS_ORISCUS_SCAPUS_LONGQUEUE)
    for i in range(2, MAX_INTERVAL+1):
        write_flexus(i, "osbase"+str(i), 'PunctumLineTL',
                     S_FLEXUS_ORISCUS_SCAPUS_LONGQUEUE)
    precise_message("flexus deminutus")
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "mdeminutus", 'PunctumLineTL',
                     S_FLEXUS_NOBAR, L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "odbase", 'deminutus',
                     S_FLEXUS_ORISCUS, L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "mdeminutus", 'PunctumLineTL',
                     S_FLEXUS, L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "mdeminutus", 'PunctumLineTL',
                     S_FLEXUS_LONGQUEUE, L_DEMINUTUS)
    precise_message("flexus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "PunctumLineBR", 'auctusa1',
                     S_FLEXUS_NOBAR, L_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "odbase", 'auctusa1',
                     S_FLEXUS_ORISCUS, L_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "vbase"+str(i),
                     'auctusa1', S_FLEXUS, L_ASCENDENS)
    write_flexus(1, "vlbase", 'auctusa1',
                 S_FLEXUS_LONGQUEUE, L_ASCENDENS)
    for i in range(2, MAX_INTERVAL+1):
        write_flexus(i, "vbase"+str(i),
                     'auctusa1', S_FLEXUS_LONGQUEUE, L_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "osbase"+str(i),
                     'auctusa1', S_FLEXUS_ORISCUS_SCAPUS,
                     L_ASCENDENS)
    write_flexus(1, "oslbase", 'auctusa1',
                 S_FLEXUS_ORISCUS_SCAPUS_LONGQUEUE, L_ASCENDENS)
    for i in range(2, MAX_INTERVAL+1):
        write_flexus(i, "osbase"+str(i),
                     'auctusa1', S_FLEXUS_ORISCUS_SCAPUS_LONGQUEUE,
                     L_ASCENDENS)
    precise_message("flexus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "PunctumLineBR", 'auctusd1', S_FLEXUS_NOBAR,
                     L_DESCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "odbase", 'auctusd1', S_FLEXUS_ORISCUS,
                     L_DESCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "vbase"+str(i), 'auctusd1', S_FLEXUS,
                     L_DESCENDENS)
    write_flexus(1, "vlbase", 'auctusd1', S_FLEXUS_LONGQUEUE,
                 L_DESCENDENS)
    for i in range(2, MAX_INTERVAL+1):
        write_flexus(i, "vbase"+str(i),
                     'auctusd1', S_FLEXUS_LONGQUEUE, L_DESCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "osbase"+str(i),
                     'auctusd1', S_FLEXUS_ORISCUS_SCAPUS,
                     L_DESCENDENS)
    write_flexus(1, "oslbase", 'auctusd1',
                 S_FLEXUS_ORISCUS_SCAPUS_LONGQUEUE,
                 L_DESCENDENS)
    for i in range(2, MAX_INTERVAL+1):
        write_flexus(i, "osbase"+str(i),
                     'auctusd1', S_FLEXUS_ORISCUS_SCAPUS_LONGQUEUE,
                     L_DESCENDENS)

def fusion_flexus():
    "Creates the fusion flexus."
    message("fusion flexus")
    precise_message("fusion flexus")
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "mademinutus", 'PunctumLineTL', S_LOWER_FLEXUS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "PunctumLineBLBR", 'PunctumLineTL',
                S_UPPER_FLEXUS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "OriscusReversusLineTLBR", 'PunctumLineTL',
                S_LOWER_FLEXUS_ORISCUS)
    precise_message("fusion flexus deminutus")
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "mademinutus", 'deminutus', S_LOWER_FLEXUS,
                L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "PunctumLineBLBR", 'deminutus', S_UPPER_FLEXUS,
                L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "OriscusReversusLineTLBR", 'deminutus',
                S_LOWER_FLEXUS_ORISCUS, L_DEMINUTUS)
    precise_message("fusion flexus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "mademinutus", 'auctusa1', S_LOWER_FLEXUS,
                L_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "PunctumLineBLBR", 'auctusa1', S_UPPER_FLEXUS,
                L_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "OriscusReversusLineTLBR", 'auctusa1',
                S_LOWER_FLEXUS_ORISCUS, L_ASCENDENS)
    precise_message("fusion flexus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "mademinutus", 'auctusd1', S_LOWER_FLEXUS,
                L_DESCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "PunctumLineBLBR", 'auctusd1', S_UPPER_FLEXUS,
                L_DESCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "OriscusReversusLineTLBR", 'auctusd1',
                S_LOWER_FLEXUS_ORISCUS, L_DESCENDENS)

def write_flexus(i, first_glyph, last_glyph, shape, lique=L_NOTHING):
    # pylint: disable=too-many-statements
    "Writes the flexus glyphs."
    new_glyph()
    glyph_name = '%s%s%s' % (shape, AMBITUS[i], lique)
    if copy_existing_glyph(glyph_name):
        return
    # we add a queue if it is a deminutus
    if first_glyph == "mdeminutus":
        if shape == S_FLEXUS_NOBAR:
            write_deminutus(0, i, length=0, tosimplify=1, firstbar=0)
        elif shape == S_FLEXUS:
            write_first_bar(1)
            write_deminutus(0, i, length=0, tosimplify=1, firstbar=1)
        else:
            write_first_bar(2)
            write_deminutus(0, i, length=0, tosimplify=1, firstbar=1)
        length = get_width(first_glyph)
    elif last_glyph == 'deminutus':
        simple_paste(first_glyph)
        write_line(i, get_width(first_glyph) - get_width('line2'),
                   (1-i)*BASE_HEIGHT)
        simplify()
        paste_and_move("deminutus",
                       get_width(first_glyph) -
                       get_width(last_glyph), (-i)*BASE_HEIGHT)
        length = get_width(first_glyph)
    else:
        if (i == 1 and first_glyph != 'odbase'
                and first_glyph != 'OriscusReversusLineTLBR'):
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
            elif first_glyph == 'VirgaLineBR':
                first_glyph = 'VirgaReversa'
            elif first_glyph == 'vlbase':
                first_glyph = 'VirgaReversaLongqueue'
            elif first_glyph == 'mademinutus':
                first_glyph = 'PunctumLineTL'
            elif first_glyph == 'PunctumLineBLBR':
                first_glyph = 'PunctumLineBL'

            length = get_width(first_glyph)
        else:
            length = get_width(first_glyph)-get_width('line2')
        simple_paste(first_glyph)
        if i != 1:
            write_line(i, length, (1-i)*BASE_HEIGHT)
        paste_and_move(last_glyph, length, (-i)*BASE_HEIGHT)
        length = get_width(first_glyph) + get_width(last_glyph)
        if i != 1:
            length = length - get_width('line2')
    set_width(length)
    end_glyph(glyph_name)

def porrectus():
    "Creates the porrectus."
    message("porrectus")
    precise_message("porrectus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(i, j, 'PunctumSmall', 1, S_PORRECTUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(i, j, 'PunctumSmall', 0, S_PORRECTUS_NOBAR)
    precise_message("porrectus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(i, j, "auctusa2", 1, S_PORRECTUS, L_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(i, j, "auctusa2", 0, S_PORRECTUS_NOBAR, L_ASCENDENS)
    precise_message("porrectus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(i, j, "PunctumAuctusLineBL", 1, S_PORRECTUS, L_DESCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(i, j, "PunctumAuctusLineBL", 0, S_PORRECTUS_NOBAR, L_DESCENDENS)
    precise_message("porrectus deminutus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(i, j, "rdeminutus", 1, S_PORRECTUS, L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(i, j, "rdeminutus", 0, S_PORRECTUS_NOBAR, L_DEMINUTUS)
    precise_message("porrectus deminutus alt")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_alt_porrectus_deminutus(i, j)

def fusion_porrectus():
    precise_message("porrectus-like fusion")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(i, j, '', 1, S_FLEXUS, L_UP)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(i, j, '', 0, S_FLEXUS_NOBAR, L_UP)

def write_porrectus(i, j, last_glyph, with_bar, shape, lique=L_NOTHING):
    "Writes the porrectus glyphs."
    new_glyph()
    glyph_name = '%s%s%s%s' % (shape, AMBITUS[i], AMBITUS[j], lique)
    if copy_existing_glyph(glyph_name):
        return
    first_glyph = "porrectus%d" % i
    if j == 1 and glyph_exists("porrectusam1%d" % i):
        first_glyph = "porrectusam1%d" % i
    if last_glyph == 'auctusa2' or last_glyph == 'PunctumAuctusLineBL' or last_glyph == '':
        if j == 1 and last_glyph == '':
            first_glyph = "porrectusflexusnb%d" % i
        else:
            first_glyph = "porrectusflexus%d" % i
    if not glyph_exists(first_glyph):
        return
    if with_bar:
        write_first_bar(i)
    length = get_width(first_glyph)
    simple_paste(first_glyph)
    write_line(j, length-get_width('line2'), (-i+1)*BASE_HEIGHT)
    length = length-get_width('line2')
    if with_bar:
        simplify()
    if last_glyph == 'rdeminutus':
        length = length+get_width('line2')
        paste_and_move(last_glyph, (length-get_width(last_glyph)),
                       (j-i)*BASE_HEIGHT)
    elif last_glyph == 'auctusa2' or last_glyph == 'PunctumAuctusLineBL':
        paste_and_move(last_glyph, (length), (j-i)*BASE_HEIGHT)
        length = length + get_width(last_glyph)
    elif last_glyph != '':
        paste_and_move(last_glyph,
                       (length-get_width(last_glyph)+get_width('line2')),
                       (j-i)*BASE_HEIGHT)
        length = length+get_width('line2')
    elif last_glyph == '' and j == 1:
        length = length+get_width('line2')
    set_width(length)
    end_glyph(glyph_name)

def write_alt_porrectus_deminutus(i, j):
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
    write_line(i, get_width(first_glyph)-get_width('line2'), (-i+1)*BASE_HEIGHT)
    simplify()
    paste_and_move('mpdeminutus', (get_width(first_glyph)-get_width('line2')),
                   (-i)*BASE_HEIGHT)
    write_line(j,
               get_width(first_glyph)+get_width('mpdeminutus')-
               2*get_width('line2'), (-i+1)*BASE_HEIGHT)
    paste_and_move('rdeminutus', (get_width(first_glyph)
                                               + get_width('mpdeminutus') -
                                               get_width('line2') -
                                               get_width(('rdeminutus'))), (j-i)*BASE_HEIGHT)
    set_width(get_width(first_glyph)+get_width('mpdeminutus')-
              get_width('line2'))
    end_glyph(glyph_name)


def porrectusflexus():
    "Creates the porrectusflexus."
    message("porrectus flexus")
    precise_message("porrectus flexus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(i, j, k, "PunctumLineTL", 0,
                                      S_PORRECTUS_FLEXUS_NOBAR)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(i, j, k, "PunctumLineTL", 1,
                                      S_PORRECTUS_FLEXUS)
    precise_message("porrectus flexus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(i, j, k,
                                      "auctusd1", 0,
                                      S_PORRECTUS_FLEXUS_NOBAR,
                                      L_DESCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(i, j, k,
                                      "auctusd1", 1,
                                      S_PORRECTUS_FLEXUS,
                                      L_DESCENDENS)
    precise_message("porrectus flexus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(i, j, k,
                                      "auctusa1", 0,
                                      S_PORRECTUS_FLEXUS_NOBAR,
                                      L_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(i, j, k,
                                      "auctusa1", 1,
                                      S_PORRECTUS_FLEXUS,
                                      L_ASCENDENS)
    precise_message("porrectus flexus deminutus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(i, j, k,
                                      "deminutus", 0,
                                      S_PORRECTUS_FLEXUS_NOBAR,
                                      L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(i, j, k,
                                      "deminutus", 1,
                                      S_PORRECTUS_FLEXUS, L_DEMINUTUS)

def write_porrectusflexus(i, j, k, last_glyph, with_bar,
                          shape, lique=L_NOTHING):
    "Writes the porrectusflexus glyphs."
    new_glyph()
    glyph_name = '%s%s%s%s%s' % (shape, AMBITUS[i], AMBITUS[j], AMBITUS[k], lique)
    if copy_existing_glyph(glyph_name):
        return
    if j == 1:
        first_glyph = "porrectusflexusnb%d" % i
    else:
        first_glyph = "porrectusflexus%d" % i
    if not glyph_exists(first_glyph):
        return
    if with_bar:
        write_first_bar(i)
    length = get_width(first_glyph)
    simple_paste(first_glyph)
    write_line(j, length-get_width('line2'), (-i+1)*BASE_HEIGHT)
    if last_glyph == "deminutus":
        width_dem = write_deminutus(j-i, k, length-get_width('line2'),
                        with_bar, firstbar=1)
        length = length+width_dem-get_width('line2')
    else:
        simplify()
        middle_glyph = 'PunctumLineBLBR'
        if j == 1:
            if k == 1:
                middle_glyph = 'Punctum'
            else:
                middle_glyph = 'PunctumLineBR'
        else:
            length = length-get_width('line2')
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
            length = length+get_width(middle_glyph)
        else:
            write_line(k, length + get_width(middle_glyph) - get_width('line2'),
                       (j-i-k+1)*BASE_HEIGHT)
            length = length + get_width(middle_glyph) - get_width('line2')
        paste_and_move(last_glyph, length, (j-i-k)*BASE_HEIGHT)
        length = length+get_width(last_glyph)
    set_width(length)
    end_glyph(glyph_name)

def torculus():
    "Creates the torculus."
    message("torculus")
    precise_message("torculus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(i, j, "PunctumLineTR", "PunctumLineTL", S_TORCULUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(i, j, "QuilismaLineTR", "PunctumLineTL", S_TORCULUS_QUILISMA)
    precise_message("torculus initio debilis")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(i, j, "idebilis", "PunctumLineTL", S_TORCULUS,
                           L_INITIO_DEBILIS)
    precise_message("torculus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(i, j, "PunctumLineTR", "auctusd1", S_TORCULUS,
                           L_DESCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(i, j, "QuilismaLineTR", "auctusd1", S_TORCULUS_QUILISMA,
                           L_DESCENDENS)
    precise_message("torculus initio debilis auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(i, j, "idebilis", "auctusd1", S_TORCULUS,
                           L_INITIO_DEBILIS_DESCENDENS)
    precise_message("torculus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(i, j, "PunctumLineTR", "auctusa1",
                           S_TORCULUS, L_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(i, j, "QuilismaLineTR", "auctusa1", S_TORCULUS_QUILISMA,
                           L_ASCENDENS)
    precise_message("torculus initio debilis auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(i, j, "idebilis", "auctusa1", S_TORCULUS,
                           L_INITIO_DEBILIS_ASCENDENS)
    precise_message("torculus deminutus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(i, j, "PunctumLineTR", "deminutus", S_TORCULUS,
                           L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(i, j, "QuilismaLineTR", "deminutus", S_TORCULUS_QUILISMA,
                           L_DEMINUTUS)
    precise_message("torculus initio debilis deminutus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_torculus(i, j, "idebilis", "deminutus", S_TORCULUS,
                           L_INITIO_DEBILIS_DEMINUTUS)

def write_torculus(i, j, first_glyph, last_glyph, shape, lique=L_NOTHING):
    "Writes the torculus glyphs."
    new_glyph()
    glyph_name = '%s%s%s%s' % (shape, AMBITUS[i], AMBITUS[j], lique)
    if copy_existing_glyph(glyph_name):
        return
    length = get_width(first_glyph)-get_width('line2')
    if first_glyph == "QuilismaLineTR":
        if i == 1:
            first_glyph = 'Quilisma'
            length = get_width(first_glyph)
    elif i == 1 and first_glyph == 'PunctumLineTR':
        first_glyph = 'Punctum'
        length = length = get_width(first_glyph)+0.1
    simple_paste(first_glyph)
    if i != 1:
        write_line(i, length, BASE_HEIGHT)
    if last_glyph == "deminutus":
        if i == 1:
            width_dem = write_deminutus(i, j, length, firstbar=0)
        else:
            width_dem = write_deminutus(i, j, length, firstbar=1)
        length = length+ width_dem
    else:
        if j == 1:
            if i == 1:
                second_glyph = 'Punctum'
            else:
                second_glyph = 'PunctumLineBL'
            paste_and_move(second_glyph, length, i*BASE_HEIGHT)
            length = length+get_width(second_glyph)
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
            length = length+get_width(second_glyph)-get_width('line2')
            write_line(j, length, (i-j+1)*BASE_HEIGHT)
        paste_and_move(last_glyph, length, (i-j)*BASE_HEIGHT)
        length = length+get_width(last_glyph)
    set_width(length)
    end_glyph(glyph_name)

def torculus_liquescens():
    "Creates the torculus liquescens."
    precise_message("torculus liquescens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculus_liquescens(i, j, k, 'PunctumLineTR',
                                          S_TORCULUS_LIQUESCENS, L_DEMINUTUS)
    precise_message("torculus liquescens quilisma")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculus_liquescens(i, j, k, 'QuilismaLineTR',
                                          S_TORCULUS_LIQUESCENS_QUILISMA, L_DEMINUTUS)

def write_torculus_liquescens(i, j, k, first_glyph, shape,
                              lique='deminutus'):
    "Writes the torculus liquescens glyphs."
    new_glyph()
    glyph_name = '%s%s%s%s%s' % (shape, AMBITUS[i], AMBITUS[j], AMBITUS[k], lique)
    if copy_existing_glyph(glyph_name):
        return
    length = get_width(first_glyph)-get_width('line2')
    if first_glyph == "QuilismaLineTR":
        if i == 1:
            first_glyph = 'Quilisma'
            length = get_width(first_glyph)
    elif i == 1:
        first_glyph = 'Punctum'
        length = get_width(first_glyph)+0.1
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
        length = length+get_width(second_glyph)
    else:
        if i == 1:
            second_glyph = 'PunctumLineBR'
        else:
            second_glyph = 'PunctumLineBLBR'
        paste_and_move(second_glyph, length, i*BASE_HEIGHT)
        length = length+get_width(second_glyph)-get_width('line2')
        write_line(j, length, (i-j+1)*BASE_HEIGHT)
    width_dem = write_deminutus(i-j, k, length, firstbar=flexus_firstbar)
    length = length+width_dem
    set_width(length)
    end_glyph(glyph_name)

def torculusresupinus():
    "Creates the torculusresupinus."
    message("torculus resupinus")
    precise_message("torculus resupinus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(i, j, k, 'PunctumLineTR', 'PunctumSmall',
                                        S_TORCULUS_RESUPINUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(i, j, k, 'idebilis', 'PunctumSmall',
                                        S_TORCULUS_RESUPINUS, L_INITIO_DEBILIS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(i, j, k, 'QuilismaLineTR', 'PunctumSmall',
                                        S_TORCULUS_RESUPINUS_QUILISMA)
    precise_message("torculus resupinus deminutus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(i, j, k, 'PunctumLineTR', 'rdeminutus',
                                        S_TORCULUS_RESUPINUS, L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(i, j, k, 'idebilis', 'rdeminutus',
                                        S_TORCULUS_RESUPINUS,
                                        L_INITIO_DEBILIS_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(i, j, k, 'QuilismaLineTR', 'rdeminutus',
                                        S_TORCULUS_RESUPINUS_QUILISMA,
                                        L_DEMINUTUS)
    precise_message("torculus resupinus deminutus alt")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_alt_torculusresupinusdeminutus(i, j, k, 'PunctumLineTR',
                                                     S_TORCULUS_RESUPINUS,
                                                     L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_alt_torculusresupinusdeminutus(i, j, k, 'idebilis',
                                                     S_TORCULUS_RESUPINUS,
                                                     L_INITIO_DEBILIS_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_alt_torculusresupinusdeminutus(i, j, k, 'QuilismaLineTR',
                                                     S_TORCULUS_RESUPINUS_QUILISMA,
                                                     L_DEMINUTUS)
    precise_message("torculus resupinus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(i, j, k, 'PunctumLineTR', "auctusa2",
                                        S_TORCULUS_RESUPINUS, L_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(i, j, k, 'idebilis', "auctusa2",
                                        S_TORCULUS_RESUPINUS,
                                        L_INITIO_DEBILIS_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(i, j, k, 'QuilismaLineTR', "auctusa2",
                                        S_TORCULUS_RESUPINUS_QUILISMA,
                                        L_ASCENDENS)
    precise_message("torculus resupinus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(i, j, k, 'PunctumLineTR', "PunctumAuctusLineBL",
                                        S_TORCULUS_RESUPINUS,
                                        L_DESCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(i, j, k, 'idebilis', "PunctumAuctusLineBL",
                                        S_TORCULUS_RESUPINUS,
                                        L_INITIO_DEBILIS_DESCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_torculusresupinus(i, j, k, 'QuilismaLineTR', "PunctumAuctusLineBL",
                                        S_TORCULUS_RESUPINUS_QUILISMA,
                                        L_DESCENDENS)

def write_torculusresupinus(i, j, k, first_glyph, last_glyph, shape,
                            lique=L_NOTHING):
    "Writes the torculusresupinus glyphs."
    new_glyph()
    glyph_name = '%s%s%s%s%s' % (shape, AMBITUS[i], AMBITUS[j], AMBITUS[k], lique)
    if copy_existing_glyph(glyph_name):
        return
    middle_glyph = "porrectus%d" % j
    if k == 1 and glyph_exists("porrectusam1%d" % j):
        middle_glyph = "porrectusam1%d" % j
    if last_glyph == 'auctusa2' or last_glyph == 'PunctumAuctusLineBL':
        middle_glyph = "porrectusflexus%d" % j
    if not glyph_exists(middle_glyph):
        return
    if i == 1 and first_glyph != 'idebilis':
        if first_glyph == 'PunctumLineTR':
            first_glyph = 'Punctum'
        elif first_glyph == 'QuilismaLineTR':
            first_glyph = 'Quilisma'
        length = get_width(first_glyph)+0.1
    else:
        length = get_width(first_glyph)-get_width('line2')
    simple_paste(first_glyph)
    if i != 1:
        write_line(i, length, BASE_HEIGHT)
    paste_and_move(middle_glyph, length, i*BASE_HEIGHT)
    length = length + get_width(middle_glyph)
    if k != 1:
        write_line(k, length-get_width('line2'), (i-j+1)*BASE_HEIGHT)
    simplify()
    if last_glyph == "rdeminutus":
        paste_and_move(last_glyph,
                       (length-get_width('rdeminutus')),
                       (i-j+k)*BASE_HEIGHT)
    elif last_glyph == 'auctusa2' or last_glyph == 'PunctumAuctusLineBL':
        paste_and_move(last_glyph, (length-get_width('line2')), (i-j+k)*BASE_HEIGHT)
        length = length - get_width('line2') + get_width(last_glyph)
    else:
        paste_and_move(last_glyph, (length-get_width(last_glyph)),
                       (i-j+k)*BASE_HEIGHT)
    set_width(length)
    end_glyph(glyph_name)

def write_alt_torculusresupinusdeminutus(i, j, k, first_glyph,
                                     shape, lique=L_NOTHING):
    # pylint: disable=invalid-name
    "Writes the torculusresupinusdeminutus glyphs."
    new_glyph()
    glyph_name = '%s%s%s%s%s.alt' % (shape, AMBITUS[i], AMBITUS[j], AMBITUS[k], lique)
    if copy_existing_glyph(glyph_name):
        return
    length = get_width(first_glyph)-get_width('line2')
    if i == 1:
        if first_glyph == 'PunctumLineTR':
            first_glyph = 'Punctum'
            length = get_width(first_glyph)+0.1
        elif first_glyph == 'QuilismaLineTR':
            first_glyph = 'Quilisma'
            length = get_width(first_glyph)+0.1
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
        length = length + get_width(second_glyph)
    elif j == 1:
        second_glyph = 'PunctumLineBL'
        paste_and_move(second_glyph, length, i*BASE_HEIGHT)
        length = length + get_width(second_glyph)
        last_glyph = 'mnbpdeminutus'
    elif i == 1 and first_glyph != "idebilis":
        second_glyph = 'PunctumLineBR'
        paste_and_move(second_glyph, length, i*BASE_HEIGHT)
        length = length + get_width(second_glyph)-get_width('line2')
        write_line(j, length, (i-j+1)*BASE_HEIGHT)
        last_glyph = 'mpdeminutus'
    else:
        second_glyph = 'PunctumLineBLBR'
        paste_and_move(second_glyph, length, i*BASE_HEIGHT)
        length = length + get_width(second_glyph)-get_width('line2')
        write_line(j, length, (i-j+1)*BASE_HEIGHT)
        last_glyph = 'mpdeminutus'
    paste_and_move(last_glyph, length, (i-j)*BASE_HEIGHT)
    length = length+get_width(last_glyph)
    write_line(k, length-get_width('line2'), (i-j+1)*BASE_HEIGHT)
    paste_and_move('rdeminutus',
                   length-get_width('rdeminutus'), (i-j+k)*BASE_HEIGHT)
    set_width(length)
    end_glyph(glyph_name)

def scandicus():
    "Creates the scandicus."
    message("scandicus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_scandicus(i, j, 'PunctumSmall')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_scandicus(i, j, 'rdeminutus', L_DEMINUTUS)

def write_scandicus(i, j, last_glyph, lique=L_NOTHING):
    "Writes the scandicus glyphs."
    new_glyph()
    final_vertical_shift = 0
    glyph_name = '%s%s%s%s' % (S_SCANDICUS, AMBITUS[i], AMBITUS[j], lique)
    if copy_existing_glyph(glyph_name):
        return
    # special case of i=j=1, we use glyph 1025 directly
    if i == 1 and j == 1 and lique == L_NOTHING:
        simple_paste('Punctum')
        second_glyph = 'PesOneNothing'
        paste_and_move(second_glyph, get_width('Punctum'), BASE_HEIGHT)
        set_width(get_width('PesOneNothing')+get_width('Punctum'))
        end_glyph(glyph_name)
        return
    if i == 1:
        simple_paste('Punctum')
        length = get_width('Punctum')
        second_glyph = 'p2base'
        if lique == L_DEMINUTUS:
            second_glyph = 'mnbpdeminutus'
        if j == 1:
            final_vertical_shift = DEMINUTUS_VERTICAL_SHIFT
    else:
        simple_paste('PunctumLineTR')
        length = get_width('PunctumLineTR') - get_width('line2')
        write_line(i, length, BASE_HEIGHT)
        second_glyph = 'msdeminutus'
        if j == 1 and glyph_exists('msdeminutusam1'):
            second_glyph = 'msdeminutusam1'
        if j == 1:
            final_vertical_shift = DEMINUTUS_VERTICAL_SHIFT
    if j == 1 and lique == L_NOTHING and glyph_exists('UpperPesOneNothing'):
        paste_and_move('UpperPesOneNothing', length, i * BASE_HEIGHT)
        set_width(length + get_width('UpperPesOneNothing'))
        end_glyph(glyph_name)
        return
    paste_and_move(second_glyph, length, i*BASE_HEIGHT)
    if (i == 1) and lique == L_NOTHING:
        length = length + get_width('Punctum')
    else:
        length = length + get_width(second_glyph)
    if j != 1:
        write_line(j, length - get_width('line2'), (i+1) * BASE_HEIGHT)
    if last_glyph == 'rdeminutus':
        paste_and_move('rdeminutus', length -
                       get_width('rdeminutus'), (i+j)*BASE_HEIGHT+final_vertical_shift)
    else:
        paste_and_move(last_glyph, length - get_width(last_glyph),
                       (i+j)*BASE_HEIGHT+final_vertical_shift)
    set_width(length)
    end_glyph(glyph_name)

def ancus():
    "Creates the ancus."
    message("ancus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_ancus(i, j, 'VirgaLineBR', S_ANCUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_ancus(i, j, 'vlbase', S_ANCUS_LONGQUEUE)

def write_ancus(i, j, first_glyph, glyph_type):
    "Writes the ancus glyphs."
    new_glyph()
    glyph_name = '%s%s%s%s' % (glyph_type, AMBITUS[i], AMBITUS[j], L_DEMINUTUS)
    if copy_existing_glyph(glyph_name):
        return
    if i == 1:
        second_glyph = 'mnbdeminutus'
        if first_glyph == 'VirgaLineBR':
            first_glyph = 'VirgaReversa'
        else:
            first_glyph = 'VirgaReversaLongqueue'
        length = get_width(first_glyph)
    else:
        length = get_width(first_glyph) - get_width('line2')
        second_glyph = 'mademinutus'
    simple_paste(first_glyph)
    if i != 1:
        write_line(i, length, (-i+1)*BASE_HEIGHT)
    paste_and_move(second_glyph, length, -(i)*BASE_HEIGHT)
    length = length + get_width(second_glyph)
    if j != 1:
        write_line(j, length - get_width('line2'), (-i-j+1) * BASE_HEIGHT)
    paste_and_move('deminutus',
                   length - get_width('deminutus'), (-i-j)*BASE_HEIGHT)
    set_width(length)
    end_glyph(glyph_name)

def leading():
    "Creates the leading fusion glyphs."
    message("leading fusion glyphs")
    for i in range(1, MAX_INTERVAL+1):
        write_leading(i, 'PunctumLineTR', S_LEADING_PUNCTUM)
    for i in range(1, MAX_INTERVAL+1):
        write_leading(i, 'idebilis', S_LEADING_PUNCTUM, L_INITIO_DEBILIS)
    for i in range(1, MAX_INTERVAL+1):
        write_leading(i, 'QuilismaLineTR', S_LEADING_QUILISMA)
    for i in range(1, MAX_INTERVAL+1):
        write_leading(i, 'OriscusLineTR', S_LEADING_ORISCUS)

# lique has a slightly different meaning here
def write_leading(i, first_glyph, glyph_type, lique=''):
    "Writes the leading fusion glyphs."
    new_glyph()
    glyph_name = '%s%s%s' % (glyph_type, AMBITUS[i], lique)
    if copy_existing_glyph(glyph_name):
        return
    length = -get_width('line2')
    if i == 1 and first_glyph != 'idebilis':
        length = 0.1
        if first_glyph == 'PunctumLineTR':
            first_glyph = 'Punctum'
        elif first_glyph == 'QuilismaLineTR':
            first_glyph = 'Quilisma'
        elif first_glyph == 'OriscusLineTR':
            first_glyph = 'Oriscus'
    length = get_width(first_glyph) + length
    paste_and_move(first_glyph, 0, -i * BASE_HEIGHT)
    if i != 1:
        write_line(i, length, -(i-1) * BASE_HEIGHT)
    simplify()
    set_width(length)
    end_glyph(glyph_name)

def fusion():
    "Creates the fusion glyphs."
    message("simple fusion glyphs")
    for i in range(1, MAX_INTERVAL+1):
        write_fusion_leading(i, 'PunctumLineTR', S_PUNCTUM, L_UP)
    for i in range(1, MAX_INTERVAL+1):
        write_fusion_leading(i, 'msdeminutus', S_UPPER_PUNCTUM, L_UP)
    for i in range(1, MAX_INTERVAL+1):
        write_fusion_leading(i, 'base6', S_LOWER_PUNCTUM, L_UP)
    for i in range(1, MAX_INTERVAL+1):
        write_fusion_leading(i, 'idebilis', S_PUNCTUM,
                L_INITIO_DEBILIS_UP)
    for i in range(1, MAX_INTERVAL+1):
        write_fusion_leading(i, 'QuilismaLineTR', S_QUILISMA, L_UP)
    for i in range(1, MAX_INTERVAL+1):
        write_fusion_leading(i, 'OriscusLineTR', S_ORISCUS, L_UP)
    for i in range(1, MAX_INTERVAL+1):
        write_fusion_leading(i, 'SalicusOriscus', S_UPPER_ORISCUS,
                L_UP)
    for i in range(1, MAX_INTERVAL+1):
        write_fusion_leading(i, 'OriscusScapusLineTR',
                S_ORISCUS_SCAPUS, L_UP)
    for i in range(1, MAX_INTERVAL+1):
        write_fusion_leading(i, 'OriscusScapusLongqueueLineTR',
                S_ORISCUS_SCAPUS_LONGQUEUE, L_UP)
    for i in range(1, MAX_INTERVAL+1):
        write_fusion_leading(i, 'odbase', S_ORISCUS, L_DOWN)
    for i in range(1, MAX_INTERVAL+1):
        write_fusion_leading(i, "osbase"+str(i), S_ORISCUS_SCAPUS, L_DOWN)
    write_fusion_leading(1, "oslbase", S_ORISCUS_SCAPUS_LONGQUEUE, L_DOWN)
    for i in range(2, MAX_INTERVAL+1):
        write_fusion_leading(i, "osbase"+str(i), S_ORISCUS_SCAPUS_LONGQUEUE, L_DOWN)
    for i in range(1, MAX_INTERVAL+1):
        write_fusion_leading(i, 'OriscusReversusLineTLBR', S_LOWER_ORISCUS,
                L_DOWN)
    for i in range(1, MAX_INTERVAL+1):
        write_fusion_leading(i, 'PunctumLineBR', S_PUNCTUM, L_DOWN)
    for i in range(1, MAX_INTERVAL+1):
        write_fusion_leading(i, 'PunctumLineBLBR', S_UPPER_PUNCTUM,
                L_DOWN)
    for i in range(1, MAX_INTERVAL+1):
        write_fusion_leading(i, 'mademinutus', S_LOWER_PUNCTUM, L_DOWN)
    for i in range(1, MAX_INTERVAL+1):
        write_fusion_leading(i, 'VirgaLineBR', S_VIRGA_REVERSA, L_DOWN)
    for i in range(1, MAX_INTERVAL+1):
        write_fusion_leading(i, 'vlbase', S_VIRGA_REVERSA_LONGQUEUE,
                L_DOWN)

# lique is only for initio debilis here
def write_fusion_leading(i, first_glyph, glyph_type, lique):
    "Writes the fusion glyphs."
    new_glyph()
    glyph_name = '%s%s%s' % (glyph_type, AMBITUS[i], lique)
    if copy_existing_glyph(glyph_name):
        return
    length = -get_width('line2')
    if (i == 1 and first_glyph != 'idebilis' and first_glyph != 'odbase'
            and first_glyph != 'OriscusReversusLineTLBR'
            and first_glyph != 'oslbase'
            and (not first_glyph.startswith('osbase'))):
        length = 0.1
        if first_glyph == 'PunctumLineTR' or first_glyph == 'PunctumLineBR':
            first_glyph = 'Punctum'
        elif first_glyph == 'QuilismaLineTR':
            first_glyph = 'Quilisma'
        elif first_glyph == 'OriscusLineTR':
            first_glyph = 'Oriscus'
        elif first_glyph == 'OriscusScapusLineTR':
            first_glyph = 'OriscusScapus'
        elif first_glyph == 'OriscusScapusLongqueueLineTR':
            first_glyph = 'OriscusScapusLongqueue'
        elif first_glyph == 'msdeminutus' or first_glyph == 'PunctumLineBLBR':
            first_glyph = 'PunctumLineBL'
        elif first_glyph == 'mademinutus' or first_glyph == 'base6':
            first_glyph = 'PunctumLineTL'
        elif first_glyph == 'SalicusOriscus':
            first_glyph = 'OriscusLineBL'
        elif first_glyph == 'VirgaLineBR':
            first_glyph = 'VirgaReversa'
        elif first_glyph == 'vlbase':
            first_glyph = 'VirgaReversaLongqueue'
    length = get_width(first_glyph) + length
    simple_paste(first_glyph)
    if i != 1:
        if lique == L_UP or lique == L_INITIO_DEBILIS_UP:
            write_line(i, length, BASE_HEIGHT)
        elif lique == L_DOWN:
            write_line(i, length, -(i - 1) * BASE_HEIGHT)
    simplify()
    set_width(length)
    end_glyph(glyph_name)

if __name__ == "__main__":
    main()
