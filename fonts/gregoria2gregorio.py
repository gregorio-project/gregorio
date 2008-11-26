#!/usr/bin/python
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

import os

shapes={
'pes':2,
'pesquadratum':3,
'pesquilisma':4,
'pesquassus':5,
'pesquilismaquadratum':6,
'flexus':7,
'flexus_nobar':8,
'flexus_longqueue':9,
'porrectusflexus':12,
'porrectusflexus_nobar':16,
'porrectus':20,
'porrectus_nobar':24,
'torculus':28,
'torculusresupinus':32,
'torculusquilisma':36,
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

fout=open("create-gregoria.pe", 'w')

# the current font name
fontName=""

# a big list in which we put all the glyph numbers that have been created
bigList=[]

# a function called at the beginning of the script, that opens the font
def header():
    fout.write("#!/usr/local/bin/fontforge\n\nPrint(\"Adapting the gregoria font for gregorio.\\nThis may take several minutes.\");\n")
    

def openFont(fontName):
    fout.write("Open(\"%s\");\n" % fontName)

# the function that deletes the temporary glyphs and saves the modified font, called at the end

def footer():
    fout.write("Quit(0);\n")
    
# function called when we are at the 255th glyph of a font, we start a new one.
def save_font(fontName):
    fout.write("Reencode(\"compacted\");\n")
    fout.write("Reencode(\"original\",1);\n")
    fout.write("SetFontNames(\"%s\");\n" % (fontName))
    # 66537 is for generating an afm and a tfm file
    #fout.write("Generate(\"%s.pfb\",\"\",66537);\n" % (fontName))
    # uncomment the next line if you want to generate sfd files (easier to debug)
    fout.write("Save(\"%s.sfd\");\n" % (fontName))
    fout.write("Close();\n")

def main():
    global fontName, fout
    header()
    # first let's "clean" gregoria of all these
    openFont("Gregoria.otf")
    fontName="gregoria"
    first_step()
    adjustAdditionalGlyphs()
    save_font("gregoria")
    openFont("Gregoria-Auctae.otf")
    fontName="gregoria-auctae"
    first_step()
    adjustAuctaeAdditionalGlyphs()
    save_font("gregoria-auctae")
    openFont("Gregoria-Deminutae.otf")
    fontName="gregoria-deminutae"
    first_step()
    adjustDeminutaeAdditionalGlyphs()
    save_font("gregoria-deminutae")
    # now we have our gregorio fonts with (only) the glyphs we want in it, and a table with all those glyphs
    # let's merge the fonts in one big gregoria.sfd
    mergeFonts("gregoria", "gregoria-auctae", "gregoria")
    mergeFonts("gregoria", "gregoria-deminutae", "gregoria")
    for i in range(9):
        mergeFonts("gregoria", "gregoria-%d" % i, "gregoria")
    footer()
    fout.close()
    os.popen("python squarize.py gregoria")
    print "Generating gregorio glyphs for gregoria.\nThis step can be extremely long (10 minutes)."
    #os.popen("fontforge -script gregoria.pe")
    os.popen("fontforge -script create-gregoria.pe")
    for i in range(1, 12):
        os.popen("fontforge -script merge-gregoria-%d.pe" % i)
    fout=open("cut-gregoria.pe", 'w')
    cutGregoria()
    fout.close()
    os.popen("fontforge -script cut-gregoria.pe")

    # I don't know why, but Select does not seem to work with glyph number, only with names, so we have to hardcode a correspondance table between the glyphnumber and the name... happily only for some value:
cT={
    0:60,
    255:11285,
    256:7199,
    511:10,
    512:53,
    767:15128,
    768:15133,
    1023:6259,
    1024:6284,
    1279:9032,
    1280:9057,
    1535:8858,
    1536:8739,
    1791:16727,
    1792:16752,
    2047:17781,
    2048:17806,
    #the next one is not true, but it will make the algorithm work simply
    2303:17819,
    2133:17819}

# a function to call the big gregoria font in 256 character fonts, and generate pfb and tfm
def cutGregoria():
    fout.write("#!/usr/local/bin/fontforge\n\n")
    fout.write("Open(\"gregoria.sfd\");\n")
    deleteGlyph(".notdef")
    for i in range(9):
        # for each range, we select and delete the previous glyphs, and the next ones
        if i != 0:
            removeRange(cT[256*(i-1)], cT[256*i - 1])
        if i != 8:
            removeRange(cT[256*(i+1)], cT[256*i])
        generateFont(i)
    fout.write("Quit(0);\n")
        
def removeRange(begin, end):
    fout.write("Select(\"_%04d\", \"_%04d\");\n" % (begin, end))
    fout.write("Clear();\n")

def generateFont(i):
    fout.write("Reencode(\"compacted\");\n")
    fout.write("Reencode(\"original\",1);\n")
    fout.write("SetFontNames(\"gregoria-%d\");\n" % i)
    fout.write("Generate(\"gregoria-%d.pfb\",\"\",66537);\n" % i)
    fout.write("Close();\n")
    fout.write("Open(\"gregoria.sfd\");\n")

scriptNum=1

# fontforge segfaults when merging too many fonts in the same script, so we create one script per merging
def mergeFonts(firstFont, secondFont, result):
    global scriptNum
    fscript=open("merge-gregoria-%d.pe" % scriptNum, 'w')
    fscript.write("#!/usr/local/bin/fontforge\n\n")
    fscript.write("Open(\"%s.sfd\");\n" % firstFont)
    fscript.write("MergeFonts(\"%s.sfd\");\n" % secondFont)
    fscript.write("Reencode(\"compacted\");\n")
    fscript.write("Reencode(\"original\",1);\n")
    fscript.write("Save(\"%s.sfd\");\n" % result)
    fscript.write("Close();\n")
    fscript.write("Quit(0);\n")
    scriptNum = scriptNum +1
    fscript.close()

def first_step():
    deleteUselessGlyphs()
    adjustTwoNotesGlyphs()
    adjustThreeNotesGlyphs()
    adjustFourNotesGlyphs()
    renameBaseGlyphs()
    
def deleteGlyph(GlyphName):
    fout.write("Select(\"%s\");\n" % GlyphName)
    fout.write("Clear();\n") 

def deleteUselessGlyphs():
    # first some random glyphs
    randomGlyphs=['.notdef', '.null', 'CR', 'space', 'exclam', 'numbersign', 'quotesingle', 'plus', 'comma', 'hyphen', 'period', 'slash', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'colon', 'semicolon', 'question', 'V', 'W', 'X', 'Y', 'q', 'w', 'nbspace', 'asciicircum', 'underscore', 'apostrophe', 'N', 'O', 'n', 'virga.alt.001', 'virga', 'doF.alt', 'doH.alt', 'doJ.alt', 'faH.alt', 'faJ.alt', 'apostropha', 'quilisma.001', 'S', 'doF', 'doJ', 'faJ']
    for glyph in randomGlyphs:
        deleteGlyph(glyph)
    combinationLetters=['x', 'y', 'o', 'v', 'w', 's']
    #
    # type eo
    #
    for letter in combinationLetters:
        for pitch in pitchLetters:
          if letter=='y' and pitch == 'b': # TODO: bugreport
              deleteGlyph("b_y")
          else:
              deleteGlyph("%c%c" % (pitch, letter)) 
    # various things
    for pitch in pitchLetters:
        deleteGlyph("%cv.alt" % pitch)
        deleteGlyph("%cs.alt" % pitch)
        deleteGlyph("%cV" % pitch.upper())
        deleteGlyph("%c.alt.001" % pitch)
        deleteGlyph("%c.alt" % pitch)
        deleteGlyph("%c.alt" % pitch.upper())
    #          
    # type g and G
    #
    for pitch in pitchLetters:
        deleteGlyph("%c" % pitch)
        deleteGlyph("%c" % pitch.upper())
    #
    # type spaceXXX
    #    
    spaceTypes=['205', '246', '328', '410', '492', '574', '656', '738', '820', '902', '984']
    for space in spaceTypes:
        deleteGlyph("SP%s" % space)
    deleteGlyph("SP246.001")
    deleteGlyph("SPdiv2")
    #
    # type pmoraA1
    #
    Types=["", '1', '2', '3', '4']
    for pmora in Types:
        for letter in pitchLetters:
            deleteGlyph("pmora%c%s" % (letter.upper(), pmora))
    for i in range(1,5):
        deleteGlyph("pmora%d" % i)
    #
    # type episema2wA1
    #
    episemaPrefix=["", "2w", "3w"]
    for episema in Types:
        for prefix in episemaPrefix:
            if episema != "" and prefix != "":
                deleteGlyph("episema%s%s" % (prefix, episema))
            for letter in pitchLetters:
                deleteGlyph("episema%s%c%s" % (prefix, letter.upper(), episema))
    for i in range(1, 5):
        deleteGlyph("episema%d" % i)
    deleteGlyph("episema2w")
    deleteGlyph("episema3w")
    #
    # type episVertA1
    #
    for epis in Types:
        for letter in pitchLetters:
            deleteGlyph("episVert%c%s" % (letter.upper(), epis))
            deleteGlyph("episVert%c%s.alt" % (letter.upper(), epis))
    for i in range(1, 5):
        deleteGlyph("episVert%d" % i)
        deleteGlyph("episVert%d.alt" % i)
    #
    # type enddownA (custos)
    #    
    for letter in pitchLetters:
        deleteGlyph("enddown%c" % letter.upper())
        deleteGlyph("endup%c" % letter.upper())
        deleteGlyph("endup%c.norm" % letter.upper())
        deleteGlyph("enddown%c.norm" % letter.upper())
    #
    # various types of simple glyphs
    # 
    twoNoteGlyphs=["pes", "pes.quadratum", "flexa", "pes.quassus", "flexus", "pesDebilis"]
    for glyph in twoNoteGlyphs:
        for i in range(1, 43):
            deleteGlyph("%s%02d" % (glyph, i))
    for i in range(1, 43):
        deleteGlyph("flexa%02d.alt" % i)
    for i in range(1, 14):
        deleteGlyph("stratus%d" % i)
    for i in range(1, 13):
        deleteGlyph("pes.quil%02d" % i)
    for i in range(1, 5):
        for j in range(1, 14-i):
            deleteGlyph("bar%d.%02d" % (i, j))
    for i in range(1,5):
        deleteGlyph("bar%d" % i)
    if fontName=="gregoria":
        for i in range(1, 5):
            deleteGlyph("flexa%d" % i)
    else:
        deleteGlyph("flexa1.b")
        deleteGlyph("flexa2.b")
        deleteGlyph("flexa3b")
        deleteGlyph("flexa4b")
    supressThreeNotesGlyph("torcDebilis")
    supressThreeNotesGlyph("porrectus")
    supressThreeNotesGlyph("torculus")
    supressThreeNotesGlyph("tor.resupinus")
    supressFourNotesGlyph("por.resupinus")
    supressFourNotesGlyph("por.flex")
    
def supressThreeNotesGlyph(name):
    for i in range(1, 13):
        deleteGlyph("%s1.%d" % (name, i))
    for i in range(1, 34):
        deleteGlyph("%s2.%d" % (name, i))
    for i in range(1, 51):
        deleteGlyph("%s3.%d" % (name, i))
    for i in range(1, 64):
        deleteGlyph("%s4.%d" % (name, i))


def supressFourNotesGlyph(name):
    for i in range(1, 13):
        deleteGlyph("%s1.%d" % (name, i))
    for i in range(1, 66):
        deleteGlyph("%s2.%d" % (name, i))
    for i in range(1, 141):
        deleteGlyph("%s3.%d" % (name, i))
    for i in range(1, 277):
        deleteGlyph("%s4.%02d" % (name, i))

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
        name=glyphName(i, 0, 0, 'pes', giveLiquescentia('nothing'), 1)
        adjustGlyphHeight("pes%d" % i, i-1)
        renameGlyph("pes%d" % i, name)
    # case of pesDebilis
    for i in range(1,5):
        if fontName=="gregoria":
            name=glyphName(i, 0, 0, 'pes', giveLiquescentia('initiodebilis'), 1)
            adjustGlyphHeight("pesDebilis%d" % i, i-1)
            renameGlyph("pesDebilis%d" % i, name)
        else:
            deleteGlyph("pesDebilis%d" % i)
    # case of pes.quadratum
    for i in range(1,5):
        if fontName == "gregoria":
            name=glyphName(i, 0, 0, 'pesquadratum', giveLiquescentia('nothing'), 1)
            adjustGlyphHeight("pes.quadratum%d" % i, i-1)
            renameGlyph("pes.quadratum%d" % i, name)
            adjustGlyphWidth(name, 329)
        else:
            deleteGlyph("pes.quadratum%d" % i)
    # case of pes.quassus
    for i in range(1,5):
        if fontName == "gregoria":
            name=glyphName(i, 0, 0, 'pesquassus', giveLiquescentia('nothing'), 1)
            adjustGlyphHeight("pes.quassus%d" % i, i-1)
            renameGlyph("pes.quassus%d" % i, name)
        else:
            deleteGlyph("pes.quassus%d" % i)
    # case of flexus
    for i in range(1,5):
        name=glyphName(i, 0, 0, 'flexus_nobar', giveLiquescentia('nothing'), 1)
        if i<3:
            glyphname="flexus%d.b" % i
        else:
            glyphname="flexus%db" %i
        adjustGlyphHeight(glyphname, -1)
        renameGlyph(glyphname, name)
    # case of flexa
    for i in range(1,5):
        name=glyphName(i, 0, 0, 'flexus', giveLiquescentia('nothing'), 1)
        if fontName=="gregoria":
            if i<3:
                glyphname="flexa%d.b" % i
            else:
                glyphname="flexa%db" %i
        else:
            glyphname="flexa%d" % i
        adjustGlyphHeight(glyphname, -1)
        renameGlyph(glyphname, name)

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
        if base == "torcDebilis" and fontName == "gregoria-auctae":
            for suffix in cTT.keys():
                deleteGlyph("%s%s" % (base, suffix))
        else:
            for suffix in cTP.keys():
                adjustThreeNotesGlyphsAux("%s%s" % (base, suffix), cTP[suffix][0], cTP[suffix][1], tNG[base][0], giveLiquescentia(tNG[base][1]))


def adjustThreeNotesGlyphsAux(oldname, i, j, glyphType, liquescentia):
    newname=glyphName(i, j, 0, glyphType, liquescentia, 0)
    # the constant thing is that the second note is on the good height
    if glyphType == 'torculus':
        adjustGlyphHeight(oldname, i-1)
    else:
        adjustGlyphHeight(oldname, -i)
    centerGlyph(oldname)
    renameGlyph(oldname, newname)

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
        if fontName == "gregoria-auctae":
            deleteGlyph("por.flexus%s.001" % suffix)
        else:
            adjustFourNotesGlyphsAux("por.flexus%s.001" % suffix, cT[suffix][0], cT[suffix][1], cT[suffix][2], 'porrectusflexus_nobar', giveLiquescentia('nothing'), cT[suffix][3])
            
def adjustFourNotesGlyphsAux(oldname, i, j, k, glyphType, liquescentia, shift):
    newname=glyphName(i, j, k, glyphType, liquescentia, 0)
    # the constant thing is that the second note is on the good height
    adjustGlyphHeight(oldname, -shift)
    renameGlyph(oldname, newname)

# some small random adjustments of width, etc.
def adjustAdditionalGlyphs():
    adjustGlyphWidth('_0019',173)
    centerGlyph('_0019')
    adjustGlyphWidth('_0027',164)
    centerGlyph('_0027')

# glyphs appearing in every font, but we keep only one of each, the corresponding thing is their name in the gregorio name convention, when they are in Gregoria (not Gregoria-Auctae or Diminutae)
baseGlyphs=['Z.short', 'z.short', 'grave', 'o', 'v', 'x', 'y', 'circumflex', 'quoteright', 'doH', 'faH', 'virga.alt',  'vir.inv', 'quilisma', 'z', 'Z', 'pes.quil', 'oriscus']

# here we absolutely need to make an interation in a certain order (we must rename z.short before z), but python does not allow to iterate over a dictionary in the order in which it has been declared, so we must iterate over the list and look for the corresponding item in the dictionary.
baseGlyphsNewNames={
    'Z.short':61,
    'z.short':64,
    'grave':8,
    'o':27,
    'v':23,
    'x':6,
    'y':5,
    'circumflex':16,
    'quoteright':33,
    'doH':1,
    'faH':2,
    'virga.alt':22,
    'vir.inv':25,
    'quilisma':26,
    'z':63,
    'Z':60,
    'pes.quil':2049,
    'oriscus':28}
          
def adjustAuctaeAdditionalGlyphs():
    for l in pitchLetters:
        deleteGlyph("%c.quad" % l)
    deleteGlyph("_0073.quad")
    for g in baseGlyphs:
        deleteGlyph(g)
    # we have to adapt some width because they are wrong in gregoria
    correctionTable={
    '_11287':903,
    '_11286':657,
    '_11285':657}
    for (k,v) in correctionTable.items():
        adjustGlyphWidth(k, v)
        centerGlyph(k)
    
        
def adjustDeminutaeAdditionalGlyphs():
    for l in pitchLetters:
        deleteGlyph("%c.quad" % l)
    deleteGlyph("punctum.quad")
    for g in baseGlyphs:
        deleteGlyph(g)
    for i in range(1, 50):
        deleteGlyph("scandicus%02d" % i)
    deleteGlyph("scandicus1")
    deleteGlyph("scandicus2")
    deleteGlyph("scandicus1a")
    deleteGlyph("scandicus1b")
    deleteGlyph("scandicus2a")
    deleteGlyph("SPdiv2.001")
    # for an unknown reason, the height of the porrectus without bar are messed up in gregoria-deminutae...
    cTP={
    '_12818':1,
    '_12824':3,
    '_12807':-1,
    '_12811':-3,
    '_12817':-1,
    '_12813':-1,
    '_12816':-3,
    '_12823':1,
    '_12814':3,
    '_12822':-1,
    '_12809':2}
    for (k,v) in cTP.items():
        adjustGlyphHeight(k,v)

def renameBaseGlyphs():
    if fontName=="gregoria":
        for oldname in baseGlyphs:
            number = baseGlyphsNewNames[oldname]
            adjustGlyphHeight(oldname, -1)
            renameGlyph(oldname, "_%04d" % number)
        renameGlyph('inclinatum', '_0019')
        adjustGlyphHeight('_0019', -1)
        renameGlyph('punctum', '_0017')
        adjustGlyphHeight('_0017', -1)
        renameGlyph('s', '_0020')
        adjustGlyphHeight('_0020', -1)
    elif fontName=="gregoria-auctae":
        renameGlyph('inclinatum', '_0031')
        adjustGlyphHeight('_0031', -1)
        renameGlyph('punctum', '_0073')
        adjustGlyphHeight('_0073', -1)
        renameGlyph('s', '_0021')
        adjustGlyphHeight('_0021', -1)
    else:
        renameGlyph('inclinatum', '_0032')
        adjustGlyphHeight('_0032', -1)
        deleteGlyph('s')
        deleteGlyph('punctum')

# function to rename a glyph
def renameGlyph(oldname, newname):
    fout.write("Select(\"%s\");\n" % oldname)
    fout.write("SetGlyphName(\"%s\");\n" % newname)    
    bigList.append(newname)

# function to add n (can be negative) to the height of a glyph. n is the difference of pitch.
def adjustGlyphHeight(name, n):
    fout.write("Select(\"%s\");\n" % name)
    # we calculate the difference in the fontforge unity
    y=n*157.5
    fout.write("Move(0,%d);\n" % y)

def adjustGlyphWidth(name, width):
    fout.write("Select(\"%s\");\n" % name)
    fout.write("SetWidth(%d);\n" % width)
    
def shiftGlyph(name, shift):
    fout.write("Select(\"%s\");\n" % name)
    fout.write("Move(%d,0);\n" % shift)

def centerGlyph(name):
    fout.write("Select(\"%s\");\n" % name)
    fout.write("CenterInWidth();\n")

# function to get the name of the glyph, with the name of the general shape, and the name of the different ambitus
def glyphName(i, j, k, shape, liquescentia, shortglyph):
    if shortglyph==0:
        glyphnumber=i+(5*j)+(25*k)+(256*liquescentiae[liquescentia])+(512*shapes[shape])
    else :
        glyphnumber=i+(5*j)+(25*k)+(64*liquescentiae[liquescentia])+(512*shapes[shape])
    return "_%04d" % (glyphnumber)
    
if __name__ == "__main__":
    main()
