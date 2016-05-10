# This is a fontforge python script; use fontforge -lang=py -script to run it
# coding=utf-8
# pylint: disable=too-many-branches, too-many-arguments, too-many-lines
# pylint: disable=import-error, no-member, C0326

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

import sys
import os
import os.path
import json
import argparse
import fontforge
import psMat
import stemsschemas

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

GREGORIO_VERSION = '4.1.2'

# The unicode character at which we start our numbering:
# U+E000 is the start of the BMP Private Use Area
glyphnumber = 0xe000 - 1

# see defaults in get_parser()
FONT_CONFIG = None
STEM_SCHEMA = None
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
    parser.add_argument('-o', '--outfile',
                        help='output ttf file name',
                        action='store', default=False, dest='outfile')
    parser.add_argument('-s', '--sub-species',
                        help='subspecies (can be \'op\')',
                        action='store', default=False, dest='subspecies')
    parser.add_argument('-c', '--config-font',
                        help='font-specific configuration',
                        action='store', dest='config_file')
    parser.add_argument('-n', '--name',
                        help='name of the font, should match output file name to be found by luaotfload',
                        action='store', default=False, dest='font_name')
    parser.add_argument('-sc', '--stems-schema',
                        help='stem length schema, can be \'default\' or \'solesmes\'',
                        action='store', default='default', dest='stems_schema')
    parser.add_argument('base_font', help="input sfd file name", action='store')
    return parser

def main():
    "Main function"
    global oldfont, newfont, font_name, subspecies, FONT_CONFIG, STEM_SCHEMA
    parser = get_parser()
    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(1)
    args = parser.parse_args()
    with open(args.config_file, 'r') as stream:
        font_config = json.load(stream)
    subspecies = '_%s' % args.subspecies if args.subspecies else ''
    if 'base height' not in font_config:
        font_config['base height'] = 157.5
    if 'hepisema additional width' not in font_config:
        font_config['hepisema additional width'] = 5
    if 'deminutus vertical shift' not in font_config:
        font_config['deminutus vertical shift'] = 10
    if 'additional upper queue height' not in font_config:
        font_config['additional upper queue height'] = 10
    FONT_CONFIG = font_config
    STEM_SCHEMA = stemsschemas.get_stem_schema(args.stems_schema, font_config)
    outfile = args.outfile
    inputfile = args.base_font
    if not outfile:
        pre = os.path.splitext(inputfile)
        outfile = '%s.ttf' % pre
    oldfont = fontforge.open(inputfile)
    if args.font_name:
        font_name = args.font_name
    else:
        font_name = oldfont.fontname
    if args.subspecies:
        font_name = '%s-%s' % (font_name, args.subspecies)
    newfont = fontforge.font()
    # newfont.encoding = "UnicodeFull"
    newfont.encoding = "ISO10646-1"
    newfont.fontname = font_name
    newfont.fullname = font_name
    newfont.familyname = font_name
    newfont.version = GREGORIO_VERSION
    newfont.copyright = oldfont.copyright.replace('<<GPLV3>>', GPLV3)
    newfont.weight = "regular"
    initialize_glyphs()
    hepisema()
    measures()
    virga()
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
    """ Create a new glyph and select it.
    """
    global newfont, glyphnumber
    glyphnumber += 1
    if glyphnumber > 0xf8ff:
        print("WARNING: exceeded private use area")
    newfont.selection.select('u%05x' % glyphnumber)

def set_glyph_name(name):
    """ Sets the name of current glyph.
    """
    global all_glyph_names, newfont, glyphnumber
    if name in all_glyph_names:
        print("ERROR: duplicate glyph name [%s]" % name, file=sys.stderr)
        sys.exit(1)
    else:
        all_glyph_names[name] = True
    newfont[glyphnumber].glyphname = name

def message(glyph_name):
    """Prints a message to stdout, so that the user gets less bored when
    building the font.
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
    'VirgaBaseLineBL',
    'Quilisma',
    'QuilismaLineTR',
    'Oriscus',
    'OriscusLineBL',
    'OriscusLineTR',
    'OriscusReversus',
    'OriscusReversusLineTL',
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
    subglyph_name = subspecies_of(glyph_name)
    if subglyph_name != glyph_name and glyph_exists(subglyph_name):
        complete_paste(subglyph_name)
        set_glyph_name(glyph_name)
        return True
    elif glyph_exists(glyph_name):
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
S_PES_QUADRATUM_OPENQUEUE          = 'PesQuadratumOpenqueue'
S_UPPER_PES_QUADRATUM_OPENQUEUE    = 'UpperPesQuadratumOpenqueue'
S_LOWER_PES_QUADRATUM_OPENQUEUE    = 'LowerPesQuadratumOpenqueue'
S_PES_QUILISMA                     = 'PesQuilisma'
S_PES_QUASSUS                      = 'PesQuassus'
S_UPPER_PES_QUASSUS                = 'UpperPesQuassus'
S_LOWER_PES_QUASSUS                = 'LowerPesQuassus'
S_PES_QUASSUS_LONGQUEUE            = 'PesQuassusLongqueue'
S_UPPER_PES_QUASSUS_LONGQUEUE      = 'UpperPesQuassusLongqueue'
S_LOWER_PES_QUASSUS_LONGQUEUE      = 'LowerPesQuassusLongqueue'
S_PES_QUASSUS_OPENQUEUE            = 'PesQuassusOpenqueue'
S_UPPER_PES_QUASSUS_OPENQUEUE      = 'UpperPesQuassusOpenqueue'
S_LOWER_PES_QUASSUS_OPENQUEUE      = 'LowerPesQuassusOpenqueue'
S_PES_QUILISMA_QUADRATUM           = 'PesQuilismaQuadratum'
S_PES_QUILISMA_QUADRATUM_LONGQUEUE = 'PesQuilismaQuadratumLongqueue'
S_PES_QUILISMA_QUADRATUM_OPENQUEUE = 'PesQuilismaQuadratumOpenqueue'
S_FLEXUS                           = 'Flexus'
S_UPPER_FLEXUS                     = 'UpperFlexus'
S_LOWER_FLEXUS                     = 'LowerFlexus'
S_FLEXUS_NOBAR                     = 'FlexusNobar'
S_FLEXUS_LONGQUEUE                 = 'FlexusLongqueue'
S_FLEXUS_OPENQUEUE                 = 'FlexusOpenqueue'
S_FLEXUS_ORISCUS                   = 'FlexusOriscus'
S_LOWER_FLEXUS_ORISCUS             = 'LowerFlexusOriscus'
S_PORRECTUS_FLEXUS                 = 'PorrectusFlexus'
S_PORRECTUS_FLEXUS_LONGQUEUE       = 'PorrectusFlexusLongqueue'
S_PORRECTUS_FLEXUS_NOBAR           = 'PorrectusFlexusNobar'
S_PORRECTUS                        = 'Porrectus'
S_PORRECTUS_LONGQUEUE              = 'PorrectusLongqueue'
S_PORRECTUS_NOBAR                  = 'PorrectusNobar'
# for stem length determination only:
S_PORRECTUS_DEMINUTUS_ALT          = 'PorrectusDeminutus.alt'
S_TORCULUS                         = 'Torculus'
S_TORCULUS_RESUPINUS               = 'TorculusResupinus'
S_TORCULUS_QUILISMA                = 'TorculusQuilisma'
S_TORCULUS_RESUPINUS_QUILISMA      = 'TorculusResupinusQuilisma'
S_SCANDICUS                        = 'Scandicus'
S_ANCUS                            = 'Ancus'
S_ANCUS_LONGQUEUE                  = 'AncusLongqueue'
S_ANCUS_OPENQUEUE                  = 'AncusOpenqueue'
S_VIRGA_STRATA                     = 'VirgaStrata'
S_SALICUS                          = 'Salicus'
S_SALICUS_LONGQUEUE                = 'SalicusLongqueue'
S_SALICUS_OPENQUEUE                = 'SalicusOpenqueue'
S_SALICUS_FLEXUS                   = 'SalicusFlexus'
S_TORCULUS_LIQUESCENS              = 'TorculusLiquescens'
S_TORCULUS_LIQUESCENS_QUILISMA     = 'TorculusLiquescensQuilisma'
S_FLEXUS_ORISCUS_SCAPUS            = 'FlexusOriscusScapus'
S_FLEXUS_ORISCUS_SCAPUS_LONGQUEUE  = 'FlexusOriscusScapusLongqueue'
S_FLEXUS_ORISCUS_SCAPUS_OPENQUEUE  = 'FlexusOriscusScapusOpenqueue'
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
S_ORISCUS_SCAPUS_OPENQUEUE         = 'OriscusScapusOpenqueue'
S_ORISCUS_REVERSUS_SCAPUS          = 'OriscusScapusReversus'
S_ORISCUS_REVERSUS_SCAPUS_LONGQUEUE= 'OriscusScapusReversusLongqueue'
S_ORISCUS_REVERSUS_SCAPUS_OPENQUEUE= 'OriscusScapusReversusOpenqueue'
S_UPPER_ORISCUS                    = 'UpperOriscus'
S_LOWER_ORISCUS                    = 'LowerOriscus'
S_VIRGA                            = 'Virga'
S_VIRGA_LONGQUEUE                  = 'VirgaLongqueue'
S_VIRGA_OPENQUEUE                  = 'VirgaOpenqueue'
S_VIRGA_REVERSA                    = 'VirgaReversa'
S_VIRGA_REVERSA_LONGQUEUE          = 'VirgaReversaLongqueue'
S_VIRGA_REVERSA_OPENQUEUE          = 'VirgaReversaOpenqueue'

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
# A very special case for stem length: when the queue of ancus must go to the
# bottom of the second note (which is the first note of a deminutus), we use
# this.
L_DEMINUTUS_FIRST           = "DeminutusFirst"

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
    """ Simplify a glyph. Does nothing in current version of fontforge (seems to
     be a bug).
     """
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
    if xdimen != 0 or ydimen != 0:
        oldfont[src].transform(psMat.translate(xdimen, ydimen))
    oldfont.selection.select(src)
    oldfont.copy()
    newfont.selection.select('u%05x' % glyphnumber)
    newfont.pasteInto()
    if xdimen != 0 or ydimen != 0:
        oldfont[src].transform(psMat.translate(-xdimen, -ydimen))

def end_glyph(name):
    "Final function to call when building a glyph."
    global newfont, glyphnumber
    set_glyph_name(name)
    newfont[glyphnumber].simplify(0, ['mergelines'])
    newfont[glyphnumber].simplify(0)
    newfont[glyphnumber].removeOverlap()
    newfont[glyphnumber].simplify(0, ['mergelines'])
    newfont[glyphnumber].simplify(0)
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

def get_queue_glyph(height, rev = False):
    "Creates the asked line glyph in tmpglyph"
    global oldfont, STEM_SCHEMA
    oldfont.selection.select('queuebase')
    oldfont.copy()
    oldfont.selection.select('tmpglyph')
    oldfont.paste()
    # Mind height sign here, transform doesn't like negative values
    oldfont['tmpglyph'].transform(psMat.scale(1,-height+FONT_CONFIG['stem bottom']+
                                              FONT_CONFIG['additional upper queue height']))
    oldfont['tmpglyph'].transform(psMat.translate(0,height-FONT_CONFIG['stem bottom']))
    queueglyphname = 'queue' if not rev else 'rqueue'
    oldfont.selection.select(queueglyphname)
    oldfont[queueglyphname].transform(psMat.translate(0, height-FONT_CONFIG['stem bottom']))
    oldfont.copy()
    oldfont.selection.select('tmpglyph')
    oldfont.pasteInto()
    oldfont[queueglyphname].transform(psMat.translate(0, -height+FONT_CONFIG['stem bottom']))
    oldfont['tmpglyph'].removeOverlap()
    oldfont['tmpglyph'].simplify(0)
    oldfont['tmpglyph'].simplify(0, ['mergelines'])
    return 'tmpglyph'

def write_line(i, length, height):
    "Writes a line in currently selected glyph, with length and height offsets"
    if i > 1:
        linename = "line%d" % i
        paste_and_move(linename, length, height)

STEM_LIQ_FALLBACKS = {
    L_DESCENDENS : L_ASCENDENS,
    L_ASCENDENS : L_NOTHING,
    L_DEMINUTUS : L_NOTHING,
    L_INITIO_DEBILIS: L_DEMINUTUS,
    L_INITIO_DEBILIS_DEMINUTUS: L_DEMINUTUS,
    L_INITIO_DEBILIS_ASCENDENS: L_ASCENDENS,
    L_INITIO_DEBILIS_DESCENDENS: L_DESCENDENS,
    L_UP: L_NOTHING,
    L_DOWN: L_NOTHING,
    L_DEMINUTUS_FIRST: L_NOTHING
}

STEM_SHAPE_FALLBACKS = {
    S_VIRGA_REVERSA : S_VIRGA,
    S_ORISCUS_SCAPUS : S_VIRGA,
    S_ORISCUS_REVERSUS_SCAPUS: S_VIRGA,
    S_FLEXUS_ORISCUS_SCAPUS: S_FLEXUS,
    S_PES_QUADRATUM: S_FLEXUS,
    S_PES_QUASSUS: S_PES_QUADRATUM,
    S_PES_QUILISMA_QUADRATUM: S_PES_QUADRATUM,
    S_UPPER_PES_QUADRATUM: S_PES_QUADRATUM,
    S_LOWER_PES_QUADRATUM: S_PES_QUADRATUM,
    S_UPPER_PES_QUASSUS: S_PES_QUASSUS,
    S_LOWER_PES_QUASSUS: S_PES_QUASSUS,
    S_PORRECTUS: S_FLEXUS,
    S_PORRECTUS_FLEXUS: S_PORRECTUS,
    S_PORRECTUS_DEMINUTUS_ALT: S_FLEXUS,
    # 3 notes glyphs are handled in a different way, see get_default_shift
    #S_ANCUS: S_FLEXUS,
    #S_SALICUS: S_PES_QUASSUS,
}

def get_shift(qtype, shape, liq, i, j):
    """Returns the shift corresponding to the arguments in the queue length
       schema or False
    """
    global STEM_SCHEMA
    #print('get shift %s %s %s %d %d' % (qtype, shape, liq, i, j))
    i = str(i)
    j = str(j)
    if shape not in STEM_SCHEMA:
        return False
    if liq not in STEM_SCHEMA[shape]:
        return False
    if i=='0':
        return STEM_SCHEMA[shape][liq].get(qtype, False)
    elif i not in STEM_SCHEMA[shape][liq]:
        return False
    elif j=='0':
        return STEM_SCHEMA[shape][liq][i].get(qtype, False)
    else:
        if j in STEM_SCHEMA[shape][liq][i] and qtype in STEM_SCHEMA[shape][liq][i][j]:
            return STEM_SCHEMA[shape][liq][i][j][qtype]
        else:
            return False
    return False # Shouldn't happen

def get_default_shift(qtype, shape, liq, i, j, side):
    """Returns the default shift associated with the schema. This
       function should be used for ancus or salicus only. The idea
       is to take i+j when reasonable, i otherwise.
    """
    global STEM_SCHEMA
    if i==0:
        print('fatal error, this should not happen!')
        exit()
    if shape == S_ANCUS:
        if j==0 or STEM_SCHEMA['ignore j']:
            return get_shift(qtype, S_FLEXUS, L_DEMINUTUS_FIRST, i, 0)
        else:
            if MAX_INTERVAL < (i+j):
                return get_shift(qtype, S_FLEXUS, L_DEMINUTUS_FIRST, i, 0)
            else:
                return get_shift(qtype, S_FLEXUS, L_DEMINUTUS, i+j, 0)
    elif shape == S_SALICUS:
        # for this shape, i is the second ambitus j is the first one
        # so that it's just a mirror of ancus
        if j==0 or STEM_SCHEMA['ignore j']:
            return get_queue_shift(qtype, S_PES_QUASSUS, L_NOTHING, i, 'right', 0)
        else:
            if MAX_INTERVAL < (i+j):
                return get_queue_shift(qtype, S_PES_QUASSUS, L_NOTHING, i, 'right', 0)
            else:
                return get_queue_shift(qtype, S_PES_QUADRATUM, L_NOTHING, i+j, 'right', 0)
    else:
        print('calling get_default_shift with shape %s, this should not happen!' % shape)
        exit()

def get_queue_shift(qtype, shape, liq, i=0, side='left', j=0):
    """ Returns the queue shift associated with the arguments in the queue
        length schema, applying all fallbacks.
    """
    global STEM_SCHEMA
    queueshape = shape
    shift = False
    # kind of do-while loop...
    while not shift:
        shift = get_shift(qtype, queueshape, liq, i, j)
        #print(shift)
        queueliq = liq
        while not shift and queueliq in STEM_LIQ_FALLBACKS:
            queueliq = STEM_LIQ_FALLBACKS[queueliq]
            shift = get_shift(qtype, queueshape, queueliq, i, j)
            #print(shift)
        if queueshape in STEM_SHAPE_FALLBACKS:
            queueshape = STEM_SHAPE_FALLBACKS[queueshape]
        else:
            break
    if not shift:
        shift = get_default_shift(qtype, shape, liq, i, j, side)
        #print(shift)
    return shift

def write_left_queue(i, qtype, stemshape, liq = L_NOTHING, j=0, length=0, shift=0):
    """ Write the left queue of a glyph. Non-obvious args:
         - i: the ambitus between the first and second note
         - j: ambitus between the second and third note in case of an ancus
         - length: horizontal shift to apply to the queue
         - shift: the vertical shift to apply to the queue
    """
    qshift = get_queue_shift(qtype, stemshape, liq, i, 'left', j)
    queue_glyph = get_queue_glyph(qshift, False)
    paste_and_move(queue_glyph, length, shift)

def write_right_queue(i, length, qtype, stemshape, liq = L_NOTHING, j=0, shift=0):
    """ Write the right queue of a glyph. Same arguments as write_length_queue
    """
    qshift = get_queue_shift(qtype, stemshape, liq, i, 'right', j)
    queue_glyph = get_queue_glyph(qshift, True)
    paste_and_move(queue_glyph, length, shift)

def write_virga_in(right_queue, firstglyph, qtype, liq, stemshape=S_VIRGA, i=0):
    "Draws a virga at height i."
    if not right_queue:
        write_left_queue(i, qtype, stemshape, liq)
    paste_and_move(firstglyph, 0, (i)*FONT_CONFIG['base height'])
    first_width = get_width(firstglyph)
    if right_queue:
        write_right_queue(i, first_width-get_width('line2'), qtype, stemshape)
    return first_width

def write_virga(shape, lique=L_NOTHING, right_queue=False, firstglyph='rvirgabase',
                qtype='short', stemshape=S_VIRGA):
    "Writes the virga glyphs."
    new_glyph()
    if lique == L_NOTHING:
        glyph_name = shape
    else:
        glyph_name = '%s%s' % (shape, lique)
    if copy_existing_glyph(glyph_name):
        return
    thislen = write_virga_in(right_queue, firstglyph, qtype, lique, stemshape)
    set_width(thislen)
    end_glyph(glyph_name)

def virga():
    "Creates virgas"
    message("virgas")
    write_virga(S_VIRGA, L_NOTHING, True,
                'virgabase', 'short', S_VIRGA)
    write_virga(S_VIRGA_LONGQUEUE, L_NOTHING, True,
                'virgabase', 'long', S_VIRGA)
    write_virga(S_VIRGA_OPENQUEUE, L_NOTHING, True,
                'virgabase', 'open', S_VIRGA)
    write_virga(S_VIRGA_REVERSA, L_NOTHING, False,
                'rvirgabase', 'short', S_VIRGA_REVERSA)
    write_virga(S_VIRGA_REVERSA_LONGQUEUE, L_NOTHING, False,
                'rvirgabase', 'long', S_VIRGA_REVERSA)
    write_virga(S_VIRGA_REVERSA_OPENQUEUE, L_NOTHING, False,
                'rvirgabase', 'open', S_VIRGA_REVERSA)
    write_virga(S_VIRGA_REVERSA, L_DESCENDENS, False,
                'PunctumAuctusLineBL', 'short', S_VIRGA)
    write_virga(S_VIRGA_REVERSA_LONGQUEUE, L_DESCENDENS, False,
                'PunctumAuctusLineBL', 'long', S_VIRGA)
    write_virga(S_VIRGA_REVERSA_OPENQUEUE, L_DESCENDENS, False,
                'PunctumAuctusLineBL', 'open', S_VIRGA)
    write_virga(S_VIRGA_REVERSA, L_ASCENDENS, False,
                'auctusa2', 'short', S_VIRGA)
    write_virga(S_VIRGA_REVERSA_LONGQUEUE, L_ASCENDENS, False,
                'auctusa2', 'long', S_VIRGA)
    write_virga(S_VIRGA_REVERSA_OPENQUEUE, L_ASCENDENS, False,
                'auctusa2', 'open', S_VIRGA)
    write_virga(S_ORISCUS_SCAPUS, L_NOTHING, False,
                'OriscusLineBL', 'short', S_ORISCUS_SCAPUS)
    write_virga(S_ORISCUS_SCAPUS_LONGQUEUE, L_NOTHING, False,
                'OriscusLineBL', 'long', S_ORISCUS_SCAPUS)
    write_virga(S_ORISCUS_SCAPUS_OPENQUEUE, L_NOTHING, False,
                'OriscusLineBL', 'open', S_ORISCUS_SCAPUS)
    write_virga(S_ORISCUS_REVERSUS_SCAPUS, L_NOTHING, False,
                'OriscusReversusLineBL', 'short', S_ORISCUS_REVERSUS_SCAPUS)
    write_virga(S_ORISCUS_REVERSUS_SCAPUS_LONGQUEUE, L_NOTHING, False,
                'OriscusReversusLineBL', 'long', S_ORISCUS_REVERSUS_SCAPUS)
    write_virga(S_ORISCUS_REVERSUS_SCAPUS_OPENQUEUE, L_NOTHING, False,
                'OriscusReversusLineBL', 'open', S_ORISCUS_REVERSUS_SCAPUS)

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
    paste_and_move(first_glyph, length, i*FONT_CONFIG['base height'])
    if not first_glyph_is_complete:
        write_line(j, length+get_width(first_glyph)-get_width('line2'),
                   (i-j+1)*FONT_CONFIG['base height'])
    if tosimplify:
        simplify()
    if not first_glyph_is_complete:
        paste_and_move("deminutus",
                       length+get_width(first_glyph)-get_width('deminutus'),
                       (i-j)*FONT_CONFIG['base height'])
    return get_width(first_glyph)

def measures():
    "Creates glyphs used only for measurement."
    message("glyphs for measurement")
    new_glyph()
    first_glyph = 'PunctumLineBLBR'
    second_glyph = 'PunctumLineTL'
    simple_paste(first_glyph)
    write_line(1, get_width(first_glyph) - get_width('line2'), -FONT_CONFIG['base height'])
    paste_and_move(second_glyph, get_width(first_glyph) - get_width('line2'),
                   -FONT_CONFIG['base height'])
    set_width(get_width(first_glyph)+get_width(second_glyph)-get_width('line2'))
    end_glyph('FlexusLineBL')
    new_glyph()
    first_glyph = 'PunctumLineBL'
    second_glyph = 'Punctum'
    simple_paste(first_glyph)
    paste_and_move(second_glyph, get_width(first_glyph), -FONT_CONFIG['base height'])
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
    'HEpisemaVirga': 'rvirgabase',
    'HEpisemaVirgaBaseLineBL': 'VirgaBaseLineBL',
    'HEpisemaOriscusLineTR': 'OriscusLineTR',
    'HEpisemaPunctumLineBR': 'PunctumLineBR',
    'HEpisemaPunctumLineBL': 'PunctumLineBL',
    'HEpisemaPunctumLineTL': 'PunctumLineTL',
    'HEpisemaPunctumLineTR': 'PunctumLineTR',
    'HEpisemaPunctumLineBLBR': 'PunctumLineBLBR',
    'HEpisemaPunctumAuctusLineBL': 'PunctumAuctusLineBL',
    'HEpisemaSalicusOriscus': 'SalicusOriscus',
    'HEpisemaFlat': 'Flat',
    'HEpisemaSharp': 'Sharp',
    'HEpisemaNatural': 'Natural',
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
    global FONT_CONFIG
    new_glyph()
    simple_paste("hepisema_base")
    drawn_width = shape_width - reduction
    scale(drawn_width + 2*FONT_CONFIG['hepisema additional width'], 1)
    move(-FONT_CONFIG['hepisema additional width'], 0)
    if glyph_exists('hepisemaleft'):
        paste_and_move("hepisemaleft", -FONT_CONFIG['hepisema additional width'], 0)
    if glyph_exists('hepisemaright'):
        paste_and_move("hepisemaright",
                       drawn_width + FONT_CONFIG['hepisema additional width'], 0)
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
    write_line(i, temp_width, FONT_CONFIG['base height'])
    if width_difference != 0:
        paste_and_move('PunctumSmall', width_difference, i*FONT_CONFIG['base height'])
    else:
        paste_and_move('PunctumSmall', 0, i*FONT_CONFIG['base height'])
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
    write_line(i, get_width('deminutus')-get_width('line2'), FONT_CONFIG['base height'])
    simplify()
    paste_and_move("PunctumLineBL", get_width('deminutus')-get_width('line2'),
                   i*FONT_CONFIG['base height'])
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
    write_line(i, temp_width, FONT_CONFIG['base height'])
    paste_and_move("rdeminutus",
                   get_width(first_glyph)-get_width('rdeminutus'),
                   i*FONT_CONFIG['base height'])
    set_width(get_width(first_glyph))
    end_glyph(glyph_name)

def write_pes_debilis_deminutus(i, shape, lique=L_NOTHING):
    "Writes the pes debilis deminutus glyphs."
    new_glyph()
    glyph_name = '%s%s%s' % (shape, AMBITUS[i], lique)
    if copy_existing_glyph(glyph_name):
        return
    simple_paste("deminutus")
    write_line(i, get_width('deminutus')-get_width('line2'), FONT_CONFIG['base height'])
    simplify()
    paste_and_move("rdeminutus", 0, i*FONT_CONFIG['base height'])
    set_width(get_width('deminutus'))
    end_glyph(glyph_name)

def pes_quadratum():
    "Makes the pes quadratum."
    message("pes quadratum")
    precise_message("pes quadratum")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "PunctumLineTR", "VirgaBaseLineBL",
                            S_PES_QUADRATUM,
                            stemshape=S_PES_QUADRATUM, qtype='short')
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "PunctumLineTR", "VirgaBaseLineBL",
                            S_PES_QUADRATUM_LONGQUEUE,
                            stemshape=S_PES_QUADRATUM, qtype='long')
    write_pes_quadratum(1, "PunctumLineTR", "VirgaBaseLineBL",
                        S_PES_QUADRATUM_OPENQUEUE,
                        stemshape=S_PES_QUADRATUM, qtype='open')
    precise_message("pes quassus")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "OriscusLineTR", "VirgaBaseLineBL",
                            S_PES_QUASSUS,
                            stemshape=S_PES_QUASSUS, qtype='short')
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "OriscusLineTR", "VirgaBaseLineBL",
                            S_PES_QUASSUS_LONGQUEUE,
                            stemshape=S_PES_QUASSUS, qtype='long')
    write_pes_quadratum(1, "OriscusLineTR", "VirgaBaseLineBL", S_PES_QUASSUS_OPENQUEUE,
                        stemshape=S_PES_QUASSUS, qtype='open')
    precise_message("pes quilisma quadratum")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "QuilismaLineTR", "VirgaBaseLineBL",
                            S_PES_QUILISMA_QUADRATUM,
                            stemshape=S_PES_QUILISMA_QUADRATUM, qtype='short')
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "QuilismaLineTR",
                            "VirgaBaseLineBL", S_PES_QUILISMA_QUADRATUM_LONGQUEUE,
                            stemshape=S_PES_QUILISMA_QUADRATUM, qtype='long')
    write_pes_quadratum(1, "QuilismaLineTR",
                        "VirgaBaseLineBL", S_PES_QUILISMA_QUADRATUM_OPENQUEUE,
                        stemshape=S_PES_QUILISMA_QUADRATUM, qtype='open')
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
        write_pes_quadratum(i, "msdeminutus", "VirgaBaseLineBL",
                            S_UPPER_PES_QUADRATUM,
                            stemshape=S_UPPER_PES_QUADRATUM, qtype='short')
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "base6", "VirgaBaseLineBL",
                            S_LOWER_PES_QUADRATUM,
                            stemshape=S_LOWER_PES_QUADRATUM, qtype='short')
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "msdeminutus", "VirgaBaseLineBL",
                            S_UPPER_PES_QUADRATUM_LONGQUEUE,
                            stemshape=S_UPPER_PES_QUADRATUM, qtype='long')
    write_pes_quadratum(1, "msdeminutus", "VirgaBaseLineBL",
                        S_UPPER_PES_QUADRATUM_OPENQUEUE,
                        stemshape=S_UPPER_PES_QUADRATUM, qtype='open')
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "base6", "VirgaBaseLineBL",
                            S_LOWER_PES_QUADRATUM_LONGQUEUE,
                            stemshape=S_LOWER_PES_QUADRATUM, qtype='long')
    write_pes_quadratum(1, "base6", "VirgaBaseLineBL",
                        S_LOWER_PES_QUADRATUM_OPENQUEUE,
                        stemshape=S_LOWER_PES_QUADRATUM, qtype='open')
    precise_message("fusion pes quassus")
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "SalicusOriscus", "VirgaBaseLineBL",
                            S_UPPER_PES_QUASSUS,
                            stemshape=S_UPPER_PES_QUASSUS, qtype='short')
    for i in range(1, MAX_INTERVAL+1):
        write_pes_quadratum(i, "SalicusOriscus", "VirgaBaseLineBL",
                            S_UPPER_PES_QUASSUS_LONGQUEUE,
                            stemshape=S_UPPER_PES_QUASSUS, qtype='long')
    write_pes_quadratum(1, "SalicusOriscus", "VirgaBaseLineBL",
                        S_UPPER_PES_QUASSUS_OPENQUEUE,
                        stemshape=S_UPPER_PES_QUASSUS, qtype='open')
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

def write_pes_quadratum(i, first_glyph, last_glyph, shape, lique=L_NOTHING,
                        stemshape=None, qtype=None):
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
            elif last_glyph == 'VirgaBaseLineBL':
                last_glyph = 'virgabase'

            first_width = get_width(first_glyph)
        else:
            first_width = get_width(first_glyph)-get_width('line2')
    else:
        first_width = get_width(first_glyph)-get_width('line2')
    simple_paste(first_glyph)
    if i != 1:
        linename = "line%d" % i
        paste_and_move(linename, first_width, FONT_CONFIG['base height'])
    paste_and_move(last_glyph, first_width, i*FONT_CONFIG['base height'])
    width = first_width+get_width(last_glyph)
    if qtype:
        write_right_queue(i, width-get_width('line2'), qtype, stemshape, lique,
                          shift=i*FONT_CONFIG['base height'])
    set_width(width)
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
        paste_and_move(linename, first_width, FONT_CONFIG['base height'])
    paste_and_move(last_glyph, first_width, i*FONT_CONFIG['base height'])
    set_width(first_width+get_width(last_glyph))
    end_glyph(glyph_name)

def salicus():
    "Creates the salicus."
    message("salicus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_salicus(i, j, "VirgaBaseLineBL", S_SALICUS, qtype='short')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_salicus(i, j, "VirgaBaseLineBL", S_SALICUS_LONGQUEUE, qtype='long')
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

def write_salicus(i, j, last_glyph, shape, lique=L_NOTHING, qtype=None):
    "Writes the salicus glyphs."
    new_glyph()
    glyph_name = '%s%s%s%s' % (shape, AMBITUS[i], AMBITUS[j], lique)
    if copy_existing_glyph(glyph_name):
        return
    length = draw_salicus(i, j, last_glyph, lique, qtype)
    set_width(length)
    end_glyph(glyph_name)

def draw_salicus(i, j, last_glyph, lique=L_NOTHING, qtype=None):
    """ Draw a salicus in current glyph.
    """
    deminutus = last_glyph == 'rdeminutus'
    no_third_glyph = False
    if j == 1 and not deminutus and last_glyph == 'VirgaBaseLineBL':
        last_glyph = 'virgabase'
    if i == 1 and j == 1 and not deminutus:
        first_glyph = 'Punctum'
        first_width = get_width(first_glyph)
        middle_glyph = 'Oriscus'
        middle_width = get_width(middle_glyph)
    elif i == 1 and (not deminutus or not glyph_exists('PesQuassusOneDeminutus')):
        first_glyph = 'Punctum'
        first_width = get_width(first_glyph)
        middle_glyph = 'OriscusLineTR'
        middle_width = get_width(middle_glyph)-get_width('line2')
    elif j == 1 and not deminutus:
        first_glyph = 'PunctumLineTR'
        first_width = get_width(first_glyph)-get_width('line2')
        middle_glyph = 'OriscusLineBL'
        middle_width = get_width(middle_glyph)
    elif (j == 1 and deminutus and glyph_exists('PesQuassusOneDeminutus') and
          glyph_exists('UpperPesQuassusOneDeminutus')):
        if i == 1:
            first_glyph = 'Punctum'
            first_width = get_width(first_glyph)
            middle_glyph = 'PesQuassusOneDeminutus'
            middle_width = get_width(middle_glyph)
        else:
            first_glyph = 'PunctumLineTR'
            first_width = get_width(first_glyph)-get_width('line2')
            middle_glyph = 'UpperPesQuassusOneDeminutus'
            middle_width = get_width(middle_glyph)
        no_third_glyph = True
    else:
        first_glyph = 'PunctumLineTR'
        first_width = get_width(first_glyph)-get_width('line2')
        middle_glyph = 'SalicusOriscus'
        middle_width = get_width(middle_glyph)-get_width('line2')
    simple_paste(first_glyph)
    if i != 1:
        linename = "line%d" % i
        paste_and_move(linename, first_width, FONT_CONFIG['base height'])
    paste_and_move(middle_glyph, first_width, i*FONT_CONFIG['base height'])
    length = first_width+middle_width
    if not no_third_glyph:
        if j != 1:
            linename = "line%d" % j
            paste_and_move(linename, length, (i+1)*FONT_CONFIG['base height'])
        elif not deminutus:
            length = length-0.01
            if last_glyph == 'auctusa2':
                last_glyph = 'PunctumAscendens'
            elif last_glyph == 'PunctumAuctusLineBL':
                last_glyph = 'PunctumDescendens'
            elif last_glyph == 'VirgaBaseLineBL':
                last_glyph = 'virgabase'
            elif last_glyph == 'PunctumLineBLBR':
                last_glyph = 'PunctumLineBR'
            elif last_glyph == 'PunctumLineBL':
                last_glyph = 'Punctum'
        if not last_glyph:
            return length
        if not deminutus:
            paste_and_move(last_glyph, length, (i+j)*FONT_CONFIG['base height'])
            length = length + get_width(last_glyph)
            if qtype:
                write_right_queue(j, length-get_width('line2'), qtype, S_SALICUS,
                                  lique, i, (i+j)*FONT_CONFIG['base height'])
        else:
            length = length+get_width('line2')
            paste_and_move(last_glyph, (length-get_width(last_glyph)),
                           (i+j)*FONT_CONFIG['base height'])
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
            write_line(k, length, (1+i+j-k)*FONT_CONFIG['base height'])
        paste_and_move(last_glyph, length, (i+j-k)*FONT_CONFIG['base height'])
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
        write_flexus(i, "rvbase", 'PunctumLineTL', S_FLEXUS, qtype='short')
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "rvbase", 'PunctumLineTL', S_FLEXUS_LONGQUEUE, qtype='long')
    write_flexus(1, "rvbase", 'PunctumLineTL', S_FLEXUS_OPENQUEUE, qtype='open')
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "osbase", 'PunctumLineTL',
                     S_FLEXUS_ORISCUS_SCAPUS, stemshape=S_FLEXUS_ORISCUS_SCAPUS, qtype='short')
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "osbase", 'PunctumLineTL',
                     S_FLEXUS_ORISCUS_SCAPUS_LONGQUEUE,
                     stemshape=S_FLEXUS_ORISCUS_SCAPUS, qtype='long')
    write_flexus(1, "osbase", 'PunctumLineTL', S_FLEXUS_ORISCUS_SCAPUS_OPENQUEUE,
                 stemshape=S_FLEXUS_ORISCUS_SCAPUS, qtype='open')
    precise_message("flexus deminutus")
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "mdeminutus", 'PunctumLineTL',
                     S_FLEXUS_NOBAR, L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "odbase", 'deminutus',
                     S_FLEXUS_ORISCUS, L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "mdeminutus", 'PunctumLineTL',
                     S_FLEXUS, L_DEMINUTUS, qtype='short')
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "mdeminutus", 'PunctumLineTL',
                     S_FLEXUS_LONGQUEUE, L_DEMINUTUS, qtype='long')
    write_flexus(1, "mdeminutus", 'PunctumLineTL',
                 S_FLEXUS_OPENQUEUE, L_DEMINUTUS, qtype='open')
    precise_message("flexus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "PunctumLineBR", 'auctusa1',
                     S_FLEXUS_NOBAR, L_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "odbase", 'auctusa1',
                     S_FLEXUS_ORISCUS, L_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "rvbase",
                     'auctusa1', S_FLEXUS, L_ASCENDENS, qtype='short')
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "rvbase",
                     'auctusa1', S_FLEXUS_LONGQUEUE, L_ASCENDENS, qtype='long')
    write_flexus(1, "rvbase",
                 'auctusa1', S_FLEXUS_OPENQUEUE, L_ASCENDENS, qtype='open')
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "osbase",
                     'auctusa1', S_FLEXUS_ORISCUS_SCAPUS,
                     L_ASCENDENS, stemshape = S_FLEXUS_ORISCUS_SCAPUS, qtype='short')
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "osbase",
                     'auctusa1', S_FLEXUS_ORISCUS_SCAPUS_LONGQUEUE,
                     L_ASCENDENS, stemshape = S_FLEXUS_ORISCUS_SCAPUS, qtype='long')
    write_flexus(1, "osbase",
                 'auctusa1', S_FLEXUS_ORISCUS_SCAPUS_OPENQUEUE, L_ASCENDENS,
                 stemshape = S_FLEXUS_ORISCUS_SCAPUS, qtype='open')
    precise_message("flexus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "PunctumLineBR", 'auctusd1', S_FLEXUS_NOBAR,
                     L_DESCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "odbase", 'auctusd1', S_FLEXUS_ORISCUS,
                     L_DESCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "rvbase", 'auctusd1', S_FLEXUS,
                     L_DESCENDENS, qtype='short')
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "rvbase",
                     'auctusd1', S_FLEXUS_LONGQUEUE, L_DESCENDENS, qtype='long')
    write_flexus(1, "rvbase",
                 'auctusd1', S_FLEXUS_OPENQUEUE, L_DESCENDENS, qtype='open')
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "osbase",
                     'auctusd1', S_FLEXUS_ORISCUS_SCAPUS,
                     L_DESCENDENS, S_FLEXUS_ORISCUS_SCAPUS,
                     stemshape=S_FLEXUS_ORISCUS_SCAPUS, qtype='short')
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "osbase",
                     'auctusd1', S_FLEXUS_ORISCUS_SCAPUS_LONGQUEUE,
                     L_DESCENDENS, S_FLEXUS_ORISCUS_SCAPUS,
                     stemshape=S_FLEXUS_ORISCUS_SCAPUS, qtype='long')
    write_flexus(1, "osbase",
                 'auctusd1', S_FLEXUS_ORISCUS_SCAPUS_OPENQUEUE, L_DESCENDENS,
                 S_FLEXUS_ORISCUS_SCAPUS,
                 stemshape=S_FLEXUS_ORISCUS_SCAPUS,qtype='open')

def fusion_flexus():
    "Creates the fusion flexus."
    message("fusion flexus")
    precise_message("fusion flexus")
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "mademinutus", 'PunctumLineTL', S_LOWER_FLEXUS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "rvbase", 'PunctumLineTL',
                     S_UPPER_FLEXUS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "OriscusReversusLineTLBR", 'PunctumLineTL',
                     S_LOWER_FLEXUS_ORISCUS)
    precise_message("fusion flexus deminutus")
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "mademinutus", 'deminutus', S_LOWER_FLEXUS,
                     L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "mdeminutus", 'deminutus', S_UPPER_FLEXUS,
                     L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "OriscusReversusLineTLBR", 'deminutus',
                     S_LOWER_FLEXUS_ORISCUS, L_DEMINUTUS)
    precise_message("fusion flexus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "mademinutus", 'auctusa1', S_LOWER_FLEXUS,
                     L_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "rvbase", 'auctusa1', S_UPPER_FLEXUS,
                     L_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "OriscusReversusLineTLBR", 'auctusa1',
                     S_LOWER_FLEXUS_ORISCUS, L_ASCENDENS)
    precise_message("fusion flexus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "mademinutus", 'auctusd1', S_LOWER_FLEXUS,
                     L_DESCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "rvbase", 'auctusd1', S_UPPER_FLEXUS,
                     L_DESCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        write_flexus(i, "OriscusReversusLineTLBR", 'auctusd1',
                     S_LOWER_FLEXUS_ORISCUS, L_DESCENDENS)

def write_flexus(i, first_glyph, last_glyph, shape, lique=L_NOTHING,
                 firstglyph_amone=None, lastglyph_amone=None, stemshape=S_FLEXUS, qtype=None):
    # pylint: disable=too-many-statements
    "Writes the flexus glyphs."
    new_glyph()
    glyph_name = '%s%s%s' % (shape, AMBITUS[i], lique)
    if copy_existing_glyph(glyph_name):
        return
    # we add a queue if it is a deminutus
    if first_glyph == "mdeminutus" and shape != S_UPPER_FLEXUS:
        if shape == S_FLEXUS_NOBAR:
            length = write_deminutus(0, i, length=0, tosimplify=1, firstbar=0)
        else:
            write_left_queue(i, qtype, stemshape, lique)
            length = write_deminutus(0, i, length=0, tosimplify=1, firstbar=1)
    elif last_glyph == 'deminutus' and (shape == S_UPPER_FLEXUS or shape == S_LOWER_FLEXUS):
        firstbar = 1 if first_glyph == 'mdeminutus' else 2
        length = write_deminutus(0, i, length=0, tosimplify=1, firstbar=firstbar)
    elif last_glyph == 'deminutus':
        simple_paste(first_glyph)
        write_line(i, get_width(first_glyph) - get_width('line2'),
                   (1-i)*FONT_CONFIG['base height'])
        simplify()
        paste_and_move("deminutus",
                       get_width(first_glyph) -
                       get_width(last_glyph), (-i)*FONT_CONFIG['base height'])
        length = get_width(first_glyph)
    else:
        if qtype:
            write_left_queue(i, qtype, stemshape, lique)
        if i == 1 and first_glyph != 'OriscusReversusLineTLBR':
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
                first_glyph = 'OriscusLineBL'
            elif first_glyph == 'VirgaLineBR':
                first_glyph = 'VirgaReversa'
            elif first_glyph == 'rvbase':
                first_glyph = 'rvirgabase'
            elif first_glyph == 'mademinutus':
                first_glyph = 'PunctumLineTL'
            elif first_glyph == 'PunctumLineBLBR':
                first_glyph = 'PunctumLineBL'

            length = get_width(first_glyph)
        else:
            length = get_width(first_glyph)-get_width('line2')
        simple_paste(first_glyph)
        if i != 1:
            write_line(i, length, (1-i)*FONT_CONFIG['base height'])
        paste_and_move(last_glyph, length, (-i)*FONT_CONFIG['base height'])
        length = length + get_width(last_glyph)
    set_width(length)
    end_glyph(glyph_name)

def porrectus():
    "Creates the porrectus."
    message("porrectus")
    precise_message("porrectus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(i, j, 'PunctumSmall', S_PORRECTUS, qtype='short')
    for j in range(1, MAX_INTERVAL+1):
        write_porrectus(1, j, 'PunctumSmall', S_PORRECTUS_LONGQUEUE, qtype='long')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(i, j, 'PunctumSmall', S_PORRECTUS_NOBAR)
    precise_message("porrectus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(i, j, "auctusa2", S_PORRECTUS, L_ASCENDENS, qtype='short')
    for j in range(1, MAX_INTERVAL+1):
        write_porrectus(1, j, "auctusa2", S_PORRECTUS_LONGQUEUE, L_ASCENDENS, qtype='long')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(i, j, "auctusa2", S_PORRECTUS_NOBAR, L_ASCENDENS)
    precise_message("porrectus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(i, j, "PunctumAuctusLineBL", S_PORRECTUS, L_DESCENDENS, qtype='short')
    for j in range(1, MAX_INTERVAL+1):
        write_porrectus(1, j, "PunctumAuctusLineBL", S_PORRECTUS_LONGQUEUE,
                        L_DESCENDENS, qtype='long')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(i, j, "PunctumAuctusLineBL", S_PORRECTUS_NOBAR, L_DESCENDENS)
    precise_message("porrectus deminutus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(i, j, "rdeminutus", S_PORRECTUS, L_DEMINUTUS, qtype='short')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(i, j, "rdeminutus", S_PORRECTUS_LONGQUEUE, L_DEMINUTUS, qtype='long')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(i, j, "rdeminutus", S_PORRECTUS_NOBAR, L_DEMINUTUS)
    precise_message("porrectus deminutus alt")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_alt_porrectus_deminutus(i, j)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_alt_porrectus_deminutus(i, j, qtype='long')

def fusion_porrectus():
    "Write fusion porrectus."
    precise_message("porrectus-like fusion")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(i, j, '', S_FLEXUS, L_UP, qtype='short')
    for j in range(1, MAX_INTERVAL+1):
        write_porrectus(1, j, '', S_FLEXUS_LONGQUEUE, L_UP, qtype='long')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_porrectus(i, j, '', S_FLEXUS_NOBAR, L_UP)

def write_porrectus(i, j, last_glyph, shape, lique=L_NOTHING, qtype=None):
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
    if qtype:
        write_left_queue(i, qtype, S_PORRECTUS, L_NOTHING)
    length = get_width(first_glyph)
    simple_paste(first_glyph)
    write_line(j, length-get_width('line2'), (-i+1)*FONT_CONFIG['base height'])
    length = length-get_width('line2')
    if qtype:
        simplify()
    if last_glyph == 'rdeminutus':
        length = length+get_width('line2')
        paste_and_move(last_glyph, (length-get_width(last_glyph)),
                       (j-i)*FONT_CONFIG['base height'])
    elif last_glyph == 'auctusa2' or last_glyph == 'PunctumAuctusLineBL':
        paste_and_move(last_glyph, (length), (j-i)*FONT_CONFIG['base height'])
        length = length + get_width(last_glyph)
    elif last_glyph != '':
        paste_and_move(last_glyph,
                       (length-get_width(last_glyph)+get_width('line2')),
                       (j-i)*FONT_CONFIG['base height'])
        length = length+get_width('line2')
    elif last_glyph == '' and j == 1:
        length = length+get_width('line2')
    set_width(length)
    end_glyph(glyph_name)

def write_alt_porrectus_deminutus(i, j, qtype='short'):
    "Writes the alternate porrectur deminutus glyphs."
    new_glyph()
    if qtype=='long':
        glyph_name = 'PorrectusLongqueue%s%sDeminutus.alt' % (AMBITUS[i], AMBITUS[j])
    else:
        glyph_name = 'Porrectus%s%sDeminutus.alt' % (AMBITUS[i], AMBITUS[j])
    if copy_existing_glyph(glyph_name):
        return
    write_left_queue(i, qtype, S_PORRECTUS_DEMINUTUS_ALT, L_NOTHING)
    if i == 1:
        first_glyph = 'PunctumLineBR'
    else:
        first_glyph = 'PunctumLineBLBR'
    simple_paste(first_glyph)
    write_line(i, get_width(first_glyph)-get_width('line2'), (-i+1)*FONT_CONFIG['base height'])
    simplify()
    paste_and_move('mpdeminutus', (get_width(first_glyph)-get_width('line2')),
                   (-i)*FONT_CONFIG['base height'])
    write_line(j,
               get_width(first_glyph)+get_width('mpdeminutus')-
               2*get_width('line2'), (-i+1)*FONT_CONFIG['base height'])
    paste_and_move('rdeminutus', (get_width(first_glyph)
                                  + get_width('mpdeminutus') -
                                  get_width('line2') -
                                  get_width(('rdeminutus'))),
                   (j-i)*FONT_CONFIG['base height'])
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
                write_porrectusflexus(i, j, k, "PunctumLineTL",
                                      S_PORRECTUS_FLEXUS_NOBAR)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(i, j, k, "PunctumLineTL",
                                      S_PORRECTUS_FLEXUS, qtype='short')
    for j in range(1, MAX_INTERVAL+1):
        for k in range(1, MAX_INTERVAL+1):
            write_porrectusflexus(1, j, k, "PunctumLineTL",
                                  S_PORRECTUS_FLEXUS_LONGQUEUE, qtype='long')
    precise_message("porrectus flexus auctus descendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(i, j, k,
                                      "auctusd1",
                                      S_PORRECTUS_FLEXUS_NOBAR,
                                      L_DESCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(i, j, k,
                                      "auctusd1",
                                      S_PORRECTUS_FLEXUS,
                                      L_DESCENDENS, qtype='short')
    for j in range(1, MAX_INTERVAL+1):
        for k in range(1, MAX_INTERVAL+1):
            write_porrectusflexus(1, j, k,
                                  "auctusd1",
                                  S_PORRECTUS_FLEXUS_LONGQUEUE,
                                  L_DESCENDENS, qtype='long')
    precise_message("porrectus flexus auctus ascendens")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(i, j, k,
                                      "auctusa1",
                                      S_PORRECTUS_FLEXUS_NOBAR,
                                      L_ASCENDENS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(i, j, k,
                                      "auctusa1",
                                      S_PORRECTUS_FLEXUS,
                                      L_ASCENDENS, qtype='short')
    for j in range(1, MAX_INTERVAL+1):
        for k in range(1, MAX_INTERVAL+1):
            write_porrectusflexus(1, j, k,
                                  "auctusa1",
                                  S_PORRECTUS_FLEXUS_LONGQUEUE,
                                  L_ASCENDENS, qtype='long')
    precise_message("porrectus flexus deminutus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(i, j, k,
                                      "deminutus",
                                      S_PORRECTUS_FLEXUS_NOBAR,
                                      L_DEMINUTUS)
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            for k in range(1, MAX_INTERVAL+1):
                write_porrectusflexus(i, j, k,
                                      "deminutus",
                                      S_PORRECTUS_FLEXUS, L_DEMINUTUS,
                                      qtype='short')
    for j in range(1, MAX_INTERVAL+1):
        for k in range(1, MAX_INTERVAL+1):
            write_porrectusflexus(1, j, k,
                                  "deminutus",
                                  S_PORRECTUS_FLEXUS_LONGQUEUE,
                                  L_DEMINUTUS, qtype='long')

def write_porrectusflexus(i, j, k, last_glyph,
                          shape, lique=L_NOTHING, qtype=None):
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
    if qtype:
        write_left_queue(i, qtype, S_PORRECTUS_FLEXUS, L_NOTHING)
    length = get_width(first_glyph)
    simple_paste(first_glyph)
    write_line(j, length-get_width('line2'), (-i+1)*FONT_CONFIG['base height'])
    if last_glyph == "deminutus":
        width_dem = write_deminutus(j-i, k, length-get_width('line2'),
                                    qtype != None, firstbar=1)
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
        paste_and_move(middle_glyph, length, (j-i)*FONT_CONFIG['base height'])
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
                       (j-i-k+1)*FONT_CONFIG['base height'])
            length = length + get_width(middle_glyph) - get_width('line2')
        paste_and_move(last_glyph, length, (j-i-k)*FONT_CONFIG['base height'])
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
        write_line(i, length, FONT_CONFIG['base height'])
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
            paste_and_move(second_glyph, length, i*FONT_CONFIG['base height'])
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
            paste_and_move(second_glyph, length, i*FONT_CONFIG['base height'])
            length = length+get_width(second_glyph)-get_width('line2')
            write_line(j, length, (i-j+1)*FONT_CONFIG['base height'])
        paste_and_move(last_glyph, length, (i-j)*FONT_CONFIG['base height'])
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
        write_line(i, length, FONT_CONFIG['base height'])
    flexus_firstbar = 2
    if j == 1:
        flexus_firstbar = 0
        if i == 1:
            second_glyph = 'Punctum'
        else:
            second_glyph = 'PunctumLineBL'
        paste_and_move(second_glyph, length, i*FONT_CONFIG['base height'])
        length = length+get_width(second_glyph)
    else:
        if i == 1:
            second_glyph = 'PunctumLineBR'
        else:
            second_glyph = 'PunctumLineBLBR'
        paste_and_move(second_glyph, length, i*FONT_CONFIG['base height'])
        length = length+get_width(second_glyph)-get_width('line2')
        write_line(j, length, (i-j+1)*FONT_CONFIG['base height'])
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
        write_line(i, length, FONT_CONFIG['base height'])
    paste_and_move(middle_glyph, length, i*FONT_CONFIG['base height'])
    length = length + get_width(middle_glyph)
    if k != 1:
        write_line(k, length-get_width('line2'), (i-j+1)*FONT_CONFIG['base height'])
    simplify()
    if last_glyph == "rdeminutus":
        paste_and_move(last_glyph,
                       (length-get_width('rdeminutus')),
                       (i-j+k)*FONT_CONFIG['base height'])
    elif last_glyph == 'auctusa2' or last_glyph == 'PunctumAuctusLineBL':
        paste_and_move(last_glyph, (length-get_width('line2')), (i-j+k)*FONT_CONFIG['base height'])
        length = length - get_width('line2') + get_width(last_glyph)
    else:
        paste_and_move(last_glyph, (length-get_width(last_glyph)),
                       (i-j+k)*FONT_CONFIG['base height'])
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
        write_line(i, length, FONT_CONFIG['base height'])
    if j == 1 and i == 1:
        if first_glyph == "idebilis":
            second_glyph = 'PunctumLineBL'
            last_glyph = 'mnbpdeminutus'
        else:
            second_glyph = 'Punctum'
            last_glyph = 'mnbpdeminutus'
        paste_and_move(second_glyph, length, i*FONT_CONFIG['base height'])
        length = length + get_width(second_glyph)
    elif j == 1:
        second_glyph = 'PunctumLineBL'
        paste_and_move(second_glyph, length, i*FONT_CONFIG['base height'])
        length = length + get_width(second_glyph)
        last_glyph = 'mnbpdeminutus'
    elif i == 1 and first_glyph != "idebilis":
        second_glyph = 'PunctumLineBR'
        paste_and_move(second_glyph, length, i*FONT_CONFIG['base height'])
        length = length + get_width(second_glyph)-get_width('line2')
        write_line(j, length, (i-j+1)*FONT_CONFIG['base height'])
        last_glyph = 'mpdeminutus'
    else:
        second_glyph = 'PunctumLineBLBR'
        paste_and_move(second_glyph, length, i*FONT_CONFIG['base height'])
        length = length + get_width(second_glyph)-get_width('line2')
        write_line(j, length, (i-j+1)*FONT_CONFIG['base height'])
        last_glyph = 'mpdeminutus'
    paste_and_move(last_glyph, length, (i-j)*FONT_CONFIG['base height'])
    length = length+get_width(last_glyph)
    write_line(k, length-get_width('line2'), (i-j+1)*FONT_CONFIG['base height'])
    paste_and_move('rdeminutus',
                   length-get_width('rdeminutus'), (i-j+k)*FONT_CONFIG['base height'])
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
        paste_and_move(second_glyph, get_width('Punctum'), FONT_CONFIG['base height'])
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
            final_vertical_shift = FONT_CONFIG['deminutus vertical shift']
    else:
        simple_paste('PunctumLineTR')
        length = get_width('PunctumLineTR') - get_width('line2')
        write_line(i, length, FONT_CONFIG['base height'])
        second_glyph = 'msdeminutus'
        if j == 1 and glyph_exists('msdeminutusam1'):
            second_glyph = 'msdeminutusam1'
        if j == 1:
            final_vertical_shift = FONT_CONFIG['deminutus vertical shift']
    if j == 1 and lique == L_NOTHING and glyph_exists('UpperPesOneNothing'):
        paste_and_move('UpperPesOneNothing', length, i * FONT_CONFIG['base height'])
        set_width(length + get_width('UpperPesOneNothing'))
        end_glyph(glyph_name)
        return
    paste_and_move(second_glyph, length, i*FONT_CONFIG['base height'])
    if (i == 1) and lique == L_NOTHING:
        length = length + get_width('Punctum')
    else:
        length = length + get_width(second_glyph)
    if j != 1:
        write_line(j, length - get_width('line2'), (i+1) * FONT_CONFIG['base height'])
    if last_glyph == 'rdeminutus':
        paste_and_move('rdeminutus', length -
                       get_width('rdeminutus'), (i+j)*FONT_CONFIG['base height']+
                       final_vertical_shift)
    else:
        paste_and_move(last_glyph, length - get_width(last_glyph),
                       (i+j)*FONT_CONFIG['base height']+final_vertical_shift)
    set_width(length)
    end_glyph(glyph_name)

def ancus():
    "Creates the ancus."
    message("ancus")
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_ancus(i, j, 'rvbase', S_ANCUS, 'short')
    for i in range(1, MAX_INTERVAL+1):
        for j in range(1, MAX_INTERVAL+1):
            write_ancus(i, j, 'rvbase', S_ANCUS_LONGQUEUE, 'long')

def write_ancus(i, j, first_glyph, glyph_type, qtype):
    "Writes the ancus glyphs."
    new_glyph()
    glyph_name = '%s%s%s%s' % (glyph_type, AMBITUS[i], AMBITUS[j], L_DEMINUTUS)
    if copy_existing_glyph(glyph_name):
        return
    write_left_queue(i, qtype, S_ANCUS, L_NOTHING, j)
    if i == 1:
        first_glyph = 'rvirgabase'
        length = get_width(first_glyph)
    else:
        length = get_width(first_glyph) - get_width('line2')
    simple_paste(first_glyph)
    if i != 1:
        write_line(i, length, (-i+1)*FONT_CONFIG['base height'])
    width_dem = write_deminutus(-i, j, length,
                                firstbar = 0 if i == 1 else 2)
    set_width(length+width_dem)
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
    paste_and_move(first_glyph, 0, -i * FONT_CONFIG['base height'])
    if i != 1:
        write_line(i, length, -(i-1) * FONT_CONFIG['base height'])
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
        write_fusion_leading(i, 'SalicusOriscus',
                             S_ORISCUS_SCAPUS, L_UP, qtype='short',
                             stemshape=S_FLEXUS_ORISCUS_SCAPUS)
    for i in range(1, MAX_INTERVAL+1):
        write_fusion_leading(i, 'SalicusOriscus',
                             S_ORISCUS_SCAPUS_LONGQUEUE, L_UP, qtype='long',
                             stemshape=S_FLEXUS_ORISCUS_SCAPUS)
    write_fusion_leading(1, 'SalicusOriscus',
                         S_ORISCUS_SCAPUS_OPENQUEUE, L_UP, qtype='open',
                         stemshape=S_FLEXUS_ORISCUS_SCAPUS)
    for i in range(1, MAX_INTERVAL+1):
        write_fusion_leading(i, 'odbase', S_ORISCUS, L_DOWN)
    for i in range(1, MAX_INTERVAL+1):
        write_fusion_leading(i, "osbase", S_ORISCUS_SCAPUS, L_DOWN,
                             qtype='short', stemshape=S_FLEXUS_ORISCUS_SCAPUS)
    for i in range(1, MAX_INTERVAL+1):
        write_fusion_leading(i, "osbase", S_ORISCUS_SCAPUS_LONGQUEUE, L_DOWN,
                             qtype='long', stemshape=S_FLEXUS_ORISCUS_SCAPUS)
    write_fusion_leading(1, "osbase", S_ORISCUS_SCAPUS_OPENQUEUE, L_DOWN,
                         qtype='open', stemshape=S_FLEXUS_ORISCUS_SCAPUS)
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
        write_fusion_leading(i, 'VirgaBaseLineBL', S_VIRGA_REVERSA, L_DOWN,
                             qtype='short', stemshape=S_FLEXUS)
    for i in range(1, MAX_INTERVAL+1):
        write_fusion_leading(i, 'VirgaBaseLineBL', S_VIRGA_REVERSA_LONGQUEUE,
                             L_DOWN, qtype='long', stemshape=S_FLEXUS)
    write_fusion_leading(1, 'VirgaBaseLineBL', S_VIRGA_REVERSA_OPENQUEUE,
                         L_DOWN, qtype='open', stemshape=S_FLEXUS)

# lique is only for initio debilis here
def write_fusion_leading(i, first_glyph, glyph_type, lique, qtype = None, stemshape = None):
    "Writes the fusion glyphs."
    new_glyph()
    glyph_name = '%s%s%s' % (glyph_type, AMBITUS[i], lique)
    if copy_existing_glyph(glyph_name):
        return
    length = -get_width('line2')
    if (i == 1 and first_glyph != 'idebilis' and first_glyph != 'odbase'
            and first_glyph != 'OriscusReversusLineTLBR'
            and first_glyph != 'osbase'):
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
        elif first_glyph == 'VirgaBaseLineBL':
            first_glyph = 'rvirgabase'
    length = get_width(first_glyph) + length
    if qtype:
        write_left_queue(i, qtype, stemshape, lique)
    simple_paste(first_glyph)
    if i != 1:
        if lique == L_UP or lique == L_INITIO_DEBILIS_UP:
            write_line(i, length, FONT_CONFIG['base height'])
        elif lique == L_DOWN:
            write_line(i, length, -(i - 1) * FONT_CONFIG['base height'])
    simplify()
    set_width(length)
    end_glyph(glyph_name)

if __name__ == "__main__":
    main()
