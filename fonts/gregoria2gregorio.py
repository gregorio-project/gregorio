#!/usr/bin/env python2
# coding=utf-8

#Python fontforge script to build a square notation font.
#Copyright (C) 2007 Elie Roux <elie.roux@enst-bretagne.fr>
#
#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.

from os import system
import fontforge, psMat

shapes={
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

liquescentiae={
'nothing':0,
'initiodebilis':1,
'deminutus':2,
'auctusascendens':3,
'auctusdescendens':4,
'initiodebilisdeminutus':5,
'initiodebilisauctusascendens':6,
'initiodebilisauctusdescendens':7,
}

pitchLetters=['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm']

# a big list in which we put all the glyph numbers that have been created
bigList=[]

def main():
    global newfont, oldfont, fontName
    newfont = fontforge.font()
#    newfont.em = 2048
    oldfont = fontforge.open("Gregoria.otf")
    fontName = "gregoria"
    newfont.encoding="ISO10646-1"
    newfont.fontname="gregoriao"
    newfont.fullname="gregoriao"
    newfont.familyname="gregoriao"
    newfont.weight=oldfont.weight
    newfont.copyright=oldfont.copyright
    first_step()
    adjustAdditionalGlyphs()
    oldfont.close()
    oldfont = fontforge.open("Gregoria-Deminutae.otf")
    fontName="gregoria-deminutae"
    first_step()
    adjustAdditionalGlyphs()
    oldfont.close()
    oldfont = fontforge.open("Gregoria-Auctae.otf")
    fontName="gregoria-auctae"
    first_step()
    adjustAdditionalGlyphs()
    oldfont.close()
    newfont.em = 2048
    newfont.generate("gregoriao.ttf")
    newfont.close()
    

    # I don't know why, but Select does not seem to work with glyph number, only with names, so we have to hardcode a correspondance table between the glyphnumber and the name... happily only for some value:
cT={
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

def first_step():
    adjustTwoNotesGlyphs()
    adjustThreeNotesGlyphs()
    adjustFourNotesGlyphs()
    renameBaseGlyphs()

# a simple function giving the liquescentia
def giveLiquescentia(debilis):
    if fontName=="gregoria":
        if debilis=='initiodebilis':
            return "initiodebilis"
        else:
            return "nothing"
    elif fontName=="gregoria-auctae":
        if debilis=='initiodebilis':
            return "initiodebilisauctusdescendens"
        else:
            return "auctusdescendens"
    elif fontName=="gregoria-deminutae":
        if debilis=='initiodebilis':
            return "initiodebilisdeminutus"
        else:
            return "deminutus"

# adjust the height and renames two notes glyphs
def adjustTwoNotesGlyphs():
    # glyphs with the first note under the second
    twoNotesGlyphs=['flexa', 'flexus'] # there is a . in the name of the 3 and 4
    # case of pes
    for i in range(1,5):
        name=glyphNum(i, 0, 0, 'pes', giveLiquescentia('nothing'), 1)
        renameGlyph("pes%d" % i, name)
        adjustGlyphHeight(name, i-1)
    # case of pesDebilis
    for i in range(1,5):
        if fontName=="gregoria":
            name=glyphNum(i, 0, 0, 'pes', giveLiquescentia('initiodebilis'), 1)
            renameGlyph("pesDebilis%d" % i, name)
            adjustGlyphHeight(name, i-1)
    # case of pes.quadratum
    for i in range(1,5):
        if fontName == "gregoria":
            name=glyphNum(i, 0, 0, 'pesquadratum', giveLiquescentia('nothing'), 1)
            renameGlyph("pes.quadratum%d" % i, name)
            adjustGlyphHeight(name, i-1)
            adjustGlyphWidth(name, 329)
    # case of pes.quassus
    for i in range(1,5):
        if fontName == "gregoria":
            name=glyphNum(i, 0, 0, 'pesquassus', giveLiquescentia('nothing'), 1)
            renameGlyph("pes.quassus%d" % i, name)
            adjustGlyphHeight(name, i-1)
    # case of flexus
    for i in range(1,5):
        name=glyphNum(i, 0, 0, 'flexus_nobar', giveLiquescentia('nothing'), 1)
        glyphname="flexus%db" %i
        if i<3:
            glyphname="flexus%d.b" % i
        renameGlyph(glyphname, name)
        adjustGlyphHeight(name, -1)
    # case of flexa
    for i in range(1,5):
        name=glyphNum(i, 0, 0, 'flexus', giveLiquescentia('nothing'), 1)
        glyphname = "flexa%d" % i
        if fontName=="gregoria":
            if i<3:
                glyphname="flexa%d.b" % i
            else:
                glyphname="flexa%db" %i
        renameGlyph(glyphname, name)
        adjustGlyphHeight(name, -1)

# adjust the height and renames three notes glyphs
def adjustThreeNotesGlyphs():
    #the glyph names in gregoria here is strange, so I just hardcode the names in a dictionary
    #correspondanceTable
    cTT={
    '1':(1,1),
    '2':(2,2),
    '3':(3,3),
    '4':(4,4),
    '2a':(2,1),
    '3a':(3,1),
    '3b':(3,2),
    '4a':(4,1),
    '4b':(4,2),
    '4c':(4,3),
    '2a.':(1,2),
    '3a.':(1,3),
    '3b.':(2,3),
    '4a.':(1,4),
    '4b.':(2,4),
    '4c.':(3,4)}
    # the third number is the shift, it's useless but we never know...
    cTP={
    '1':(1,1,0),
    '2':(2,2,46),
    '3':(3,3,46),
    '4':(4,4,40),
    '2a':(2,1,46),
    '3a':(3,1,46),
    '3b':(3,2,0),
    '4a':(4,3,40),
    '4b':(4,2,40),
    '4c':(4,1,40),
    '2a.':(1,2,46),
    '3a.':(2,3,46),
    '3b.':(1,3,40),
    '4a.':(3,4,40),
    '4b.':(2,4,40),
    '4c.':(1,4,40)}
    #threeNotesGlyphs
    tNG={'torcDebilis':('torculus', 'initiodebilis'),
    'torculus':('torculus', 'nothing'),
    'porrectus':('porrectus', 'nothing'),
    'tor.resupinus':('porrectus_nobar', 'nothing')}
    for base in tNG.keys():
        if tNG[base][0]=='torculus':
            for suffix in cTT.keys():
                adjustThreeNotesGlyphsAux("%s%s" % (base, suffix), cTT[suffix][0], cTT[suffix][1], tNG[base][0], giveLiquescentia(tNG[base][1]))
        else:
            for suffix in cTP.keys():
                adjustThreeNotesGlyphsAux("%s%s" % (base, suffix), cTP[suffix][0], cTP[suffix][1], tNG[base][0], giveLiquescentia(tNG[base][1]))


def adjustThreeNotesGlyphsAux(oldname, i, j, glyphType, liquescentia):
    newname=glyphNum(i, j, 0, glyphType, liquescentia, 0)
    renameGlyph(oldname, newname)
    # the constant thing is that the second note is on the good height
    if glyphType == 'torculus':
        adjustGlyphHeight(newname, i-1)
    else:
        adjustGlyphHeight(newname, -i)
    centerGlyph(newname)

# adjust the height and renames four notes glyphs
def adjustFourNotesGlyphs():
    # the table is basically the same as before, the 4th number is the shift we have to apply
    cT={
    '1':(1,1,1,1),
    '2':(2,2,2,2),
    '2a':(2,2,1,1),
    '2b':(2,1,1,2),
    '2b.':(1,2,2,1),
    '2c':(1,1,2,1),
    '2d':(2,1,2,2),
    '3':(3,3,3,3),
    '3a':(3,3,2,2),
    '3b':(2,2,3,3),
    '3c':(1,1,3,3),
    '3d':(3,2,1,1),
    '3e':(3,2,2,3),
    '3f':(2,3,3,2),
    '3g':(3,1,1,3),
    '3h':(1,3,3,1),
    '3i':(2,3,2,1),
    '3j':(3,3,1,1),
    '3k':(2,3,1,0),
    '3l':(1,3,1,-1),
    '3m':(1,2,3,2),
    '4':(4,4,4,3),
    '4a':(4,4,3,2),
    '4b':(4,4,2,1),
    '4c':(4,4,1,0),
    '4d':(3,3,4,3),
    '4e':(2,2,4,3),
    '4f':(1,1,4,3),
    '4g':(4,3,3,3),
    '4h':(4,2,2,3),
    '4i':(4,1,1,3),
    '4j':(4,3,4,4),
    '4k':(4,2,3,4),
    '4l':(4,1,2,4),
    '4m':(3,4,4,2),
    '4n':(3,4,3,1),
    '4o':(3,4,2,0),
    '4p':(3,4,1,-1),
    '4q':(2,4,4,1),
    '4r':(2,4,3,0),
    '4s':(2,4,2,-1),
    '4t':(2,4,1,-2),
    '4u':(1,4,4,0),
    '4v':(1,4,3,-1),
    '4w':(1,4,2,-2),
    '4x':(1,4,1,-3),
    '4y':(4,3,2,2),
    '4z':(4,3,1,1),
    '4a.':(4,2,1,2),
    '4b.':(2,3,4,2),
    '4c.':(1,2,4,2),
    '4d.':(1,3,4,2)}
    for suffix in cT.keys():
        adjustFourNotesGlyphsAux("por.flexus%s" % suffix, cT[suffix][0], cT[suffix][1], cT[suffix][2], 'porrectusflexus', giveLiquescentia('nothing'), cT[suffix][3])
        if fontName != "gregoria-auctae":
            adjustFourNotesGlyphsAux("por.flexus%s.001" % suffix, cT[suffix][0], cT[suffix][1], cT[suffix][2], 'porrectusflexus_nobar', giveLiquescentia('nothing'), cT[suffix][3])
            
def adjustFourNotesGlyphsAux(oldname, i, j, k, glyphType, liquescentia, shift):
    newname=glyphNum(i, j, k, glyphType, liquescentia, 0)
    # the constant thing is that the second note is on the good height
    renameGlyph(oldname, newname)
    adjustGlyphHeight(newname, -shift)

# some small random adjustments of width, etc.
def adjustAdditionalGlyphs():
    adjustGlyphWidth(19,173)
    centerGlyph(19)
    adjustGlyphWidth(27,164)
    centerGlyph(27)

# glyphs appearing in every font, but we keep only one of each, the corresponding thing is their name in the gregorio name convention, when they are in Gregoria (not Gregoria-Auctae or Diminutae)
baseGlyphs=['Z.short', 'z.short', 'grave', 'o', 'v', 'x', 'y', 'circumflex', 'quoteright', 'doH', 'faH', 'virga.alt',  'vir.inv', 'quilisma', 'z', 'Z', 'pes.quil', 'oriscus']

# here we absolutely need to make an interation in a certain order (we must rename z.short before z), but python does not allow to iterate over a dictionary in the order in which it has been declared, so we must iterate over the list and look for the corresponding item in the dictionary.
# the second element is the height adjustment
baseGlyphsNewNames={
    'Z.short':(61,-1),
    'z.short':(64,-1),
    'grave':(8,-1),
    'o':(27,-1),
    'v':(23,-1),
    'x':(6,-1),
    'y':(5,-1),
    'circumflex':(16,-1),
    'quoteright':(33,-1),
    'doH':(1,0),
    'faH':(2,0),
    'virga.alt':(22,-1),
    'vir.inv':(25,-1),
    'quilisma':(26,-1),
    'z':(63,-1),
    'Z':(60,-1),
    'pes.quil':(2049,0),
    'oriscus':(28,-1)}
          
def adjustAuctaeAdditionalGlyphs():
    # we have to adapt some width because they are wrong in gregoria
    correctionTable={
    11287:903,
    11286:657,
    11285:657}
    for (k,v) in correctionTable.items():
        adjustGlyphWidth(k, v)
        centerGlyph(k)
    
        
def adjustDeminutaeAdditionalGlyphs():
    # for an unknown reason, the height of the porrectus without bar are messed up in gregoria-deminutae...
    cTP={
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
    for (k,v) in cTP.items():
        adjustGlyphHeight(k,v)

def renameBaseGlyphs():
    if fontName=="gregoria":
        for oldname in baseGlyphs:
            number = baseGlyphsNewNames[oldname][0]
            renameGlyph(oldname, number)
            adjustGlyphHeight(number, baseGlyphsNewNames[oldname][1])
        # here we adjust the vertical episemus and the circumflexus
        shiftGlyph(16,131)
        adjustGlyphWidth(16,99)
        adjustGlyphPreciseHeight(16,100)
        shiftGlyph(33,89)
        adjustGlyphWidth(33,15)
        adjustGlyphPreciseHeight(33,120)
        renameGlyph('inclinatum', 19)
        adjustGlyphHeight(19, -1)
        renameGlyph('punctum', 17)
        adjustGlyphHeight(17, -1)
        renameGlyph('s', 20)
        adjustGlyphHeight(20, -1)
    elif fontName=="gregoria-auctae":
        renameGlyph('inclinatum', 31)
        adjustGlyphHeight(31, -1)
        renameGlyph('punctum', 73)
        adjustGlyphHeight(73, -1)
        renameGlyph('s', 21)
        adjustGlyphHeight(21, -1)
    else:
        renameGlyph('inclinatum', 32)
        adjustGlyphHeight(32, -1)

# function to rename a glyph
def renameGlyph(oldname, newnum):
    global oldfont, newfont
    oldfont.selection.select(("singletons",), oldname)
    oldfont.copy()
    newfont.selection.select(("singletons",), "u%05x" % int(newnum))
    newfont.pasteInto()

# function to add n (can be negative) to the height of a glyph. n is the difference of pitch.
def adjustGlyphHeight(num, n):
    # we calculate the difference in the fontforge unity
    global newfont
    newfont[num].transform(psMat.translate(0,157.5*n))

def adjustGlyphPreciseHeight(num, y):
    global newfont
    newfont[num].transform(psMat.translate(0,y))

def adjustGlyphWidth(num, width):
    global newfont
    newfont[num].width = width

def shiftGlyph(num, shift):
    global newfont
    newfont[num].transform(psMat.translate(shift,0))

def centerGlyph(num):
    global newfont
    g = newfont[num]
    g.left_side_bearing = g.right_side_bearing = (g.left_side_bearing + g.right_side_bearing)/2 

# function to get the name of the glyph, with the name of the general shape, and the name of the different ambitus
def glyphNum(i, j, k, shape, liquescentia, shortglyph):
    if shortglyph==0:
        return i+(5*j)+(25*k)+(256*liquescentiae[liquescentia])+(512*shapes[shape])
    else :
        return i+(5*j)+(25*k)+(64*liquescentiae[liquescentia])+(512*shapes[shape])
    
if __name__ == "__main__":
    main()
