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
#
#This script takes a very simple .sfd file with a few symbols and builds a
#complete square notation font. See gregorio-base.sfd for naming conventions
#of these symbols.
#
#This python script generates a fontforge native script (.pe). In the future, 
#python will also work (better than .pe) to control fontforge with scripts, but
#it is not yet implemented. The .pe script will build foo-0.pfb (and also .tfm,
#.afm and .enc) to foo-8.pfb.
#
#To build your own font, look at gregorio-base.sfd, and build your own glyphs from
#it.
#
#Basic use :
# ./squarize.py fontname
# chmod +x fontname.pe
# ./fontname.pe
#where fontname = gregorio, parmesan, or greciliae 
# the last step may take a few minutes

import getopt, sys

#defines the maximal interval between two notes, the bigger this number is, the more glyphs you'll have to generate
max_interval=5

# the list of the number of the glyphs

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
'flexus_oriscus':13,
'porrectusflexus':14,
'porrectusflexus_nobar':18,
'porrectus':22,
'porrectus_nobar':26,
'torculus':30,
'torculusresupinus':34,
'torculusquilisma':38,
# if one day we are running out of namespace, we may consider these two next as specials, because only the deminutus are generated
'scandicus':42,
'ancus':46,
'ancus_longqueue':50,
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

# a list of temporary glyphs, that must be removed from the finame font

toremove=['base2', 'base3', 'base4', 'base5', 'base6', 'base7', 'line2', 'line3', 'line4', 'line5', 'pesdeminutus', 'mdeminutus', 'auctusa1', 'auctusa2', 'auctusd1', 'auctusd2', 'queue', 'idebilis', 'deminutus', 'rdeminutus', 'obase', 'qbase', 'pbase', 'p2base', 'porrectus1', 'porrectus2', 'porrectus3', 'porrectus4', 'porrectus5', 'porrectusflexus1', 'porrectusflexus2', 'porrectusflexus3', 'porrectusflexus4', 'porrectusflexus5', 'vsbase', 'rvsbase', 'rvlbase', 'vlbase', 'hepisemus_base','phigh', 'hepisemusleft', 'hepisemusright', 'mpdeminutus', 'mnbdeminutus', 'mnbpdeminutus', 'porrectusflexusnb1', 'porrectusflexusnb2', 'porrectusflexusnb3', 'porrectusflexusnb4', 'porrectusflexusnb5', 'msdeminutus', 'mademinutus','odbase']

# in the police, all the free glyphs have the name NameMexxxx where xxxx is a number starting from 141 and increasing by one. For example each new glyph will be basically NameMecount, the next NameMecount+1, etc. They are initiated in initalize_glyphs()
initialcount=0
count=0

current_glyph_number=0
current_font_number=0

# the numerotation of the glyphs are not the same between short and long types, here is the indicator
shortglyphs=0

# initial glyphs are the names of the glyphs that are already in gregorio_base, mostly one-note glyphs. see initialize_glyphs() for more details
initial_glyphs=[1,2,17,19,20,26,27,28,6,32,11,8,23,25,9,10,24,7,4,3,21,31,22,14,15,33,13,62,65,39,69,70,38,37,60,61,63,64,16,34,35,36,72,73,74,77,79,81,82]

def usage():
    print """
Python script to convert a small set of glyphs into a complete
gregorian square notation font. The initial glyphs have a name convention,
see gregorio-base.sfd for this convention.

Usage:
        squarize.py fontname

with fontname=gregorio, parmesan or greciliae for now. The script generates
fontname.pe which is a fontforge script.
"""

def main():
    global fout, font_name
    global current_glyph_number, shortglyphs
    try:
        opts, args = getopt.gnu_getopt(sys.argv[1:], "h", ["help"])
    except getopt.GetoptError:
        # print help information and exit:
        usage()
        sys.exit(2)
    output = None
    verbose = False
    for o, a in opts:
        if o in ("-h", "--help"):
            usage()
            sys.exit()
    if len(args)==0:
        usage()
        sys.exit(2)
    if args[0] == "gregorio":
        font_name="gregorio"
    elif args[0] == "parmesan":
        font_name="parmesan"
    elif args[0] == "greciliae":
        font_name="greciliae"
    elif args[0] == "gregoria":
        font_name="gregoria"
    else:
        usage()
        sys.exit(2)
    # the file we are going to write in
    fout=open("%s.pe" % font_name, 'w')
    initialize_glyphs()
    initialize_lengths()
    current_glyph_number=len(initial_glyphs)
    header()
    hepisemus()
    shortglyphs=1
    pes()
    pes_quadratum()
    flexus()
    shortglyphs=0
    scandicus()
    ancus()
    torculus()
    porrectus()
    porrectusflexus()
    torculusresupinus()
    end_font()
    footer()
    fout.close()

def initialize_glyphs():
    global initial_glyphs, initialcount, count
    for number in initial_glyphs:
        toto="_00%02d" % int(number)
        initial_glyphs.insert(0,toto)
        initial_glyphs.remove(number)
    if font_name=="gregorio":
        glyphs_to_append=("_1025", "_2561")
        initialcount=183
    elif font_name=="parmesan":
        glyphs_to_append=("_1025", "_2561")
        initialcount=183
    elif font_name=="greciliae":
        glyphs_to_append=("_2561", "_1025", "_0075", "_0076", "_0078", "_0080")
        initialcount=190
    elif font_name=="gregoria":
        glyphs_to_append=("_2561", "_1025")
        initialcount=178
    for glyphnumber in glyphs_to_append:
        initial_glyphs.append(glyphnumber)
    count=initialcount

#function in which we initialize the lenghts, depending on the font
def initialize_lengths():
    global base_height, line_width, width_punctum, width1, width2, width_debilis, width_deminutus, width_inclinatum_deminutus, width_flexusdeminutus, porrectusflexuswidths, porrectuswidths, width_inclinatum, width_stropha, hepisemus_additional_width, width_oriscus, width_quilisma, width_high_pes, width_oriscus_rev
    if (font_name=="gregorio"):
        # the base heigth is half the space between two lines plus half the heigth of a line
        base_height=157.5
        # some width, necessary to know where to draw lines, squares, etc.
        # first the width of the lines that link notes, like in a pes for example
        line_width=22
        # then the width of a punctum, we assume that it is the same width for oriscus, quilisma, punctum auctum descendens and punctum auctum ascendens 
        width_punctum=164
        # width_oriscus is the width of an oriscus, idem for quilisma
        width_oriscus=164
        width_quilisma=164
        # width_oriscus_rev is the width of an oriscus reversus
        width_oriscus_rev=164
        # the width of the first note of an initio debilis, and the one of the last note of a deminutus. Warning, in GregorioTeX they must be the same! you must (almost always) add the width of a line to have the real width.
        width_debilis=88
        width_deminutus=88
        #width of a punctum inclinatum (we consider that the punctum inclinatum auctus has the same width
        width_inclinatum=164
        #width of a stropha (idem for the stropha aucta)
        width_stropha=164
        #with of the second (highest) note of a pes
        width_high_pes=154
        # the width of the punctum inclinatum deminutus (no need to add the width of a line)
        width_inclinatum_deminutus=82
        # the width of the note which is just before a deminutus, in some fonts it is not the same width as a punctum
        width_flexusdeminutus=186
        # the widths of the torculus resupinus, there are five, one per note difference between the two first notes (for example the first is the width of the first two notes of baba
        porrectusflexuswidths=(340,428,586,670,931)
        porrectuswidths=(490,575,650,740,931)
        # width that will be added to the standard width when we will build horizontal episemus. for example, if a punctum has the length 164, the episemus will have the width 244 and will be centered on the center of the punctum 
        hepisemus_additional_width=30
    elif (font_name=="parmesan"):
        base_height=157.5
        line_width=22
        width_punctum=161
        width_oriscus=192
        width_oriscus_rev=192
        width_quilisma=161
        width_debilis=75
        width_deminutus=75
        width_inclinatum=178
        width_stropha=169
        width_high_pes=151
        width_inclinatum_deminutus=112
        width_flexusdeminutus=161
        porrectusflexuswidths=(340,428,586,670,931)
        porrectuswidths=(490,575,650,740,931)
        hepisemus_additional_width=30
    elif (font_name=="greciliae"):
        base_height=157.5
        line_width=18
        width_punctum=166
        width_oriscus=166
        width_oriscus_rev=168
        width_quilisma=166
        width_debilis=65
        width_deminutus=65
        width_inclinatum=155
        width_stropha=163
        width_high_pes=155
        width_inclinatum_deminutus=112
        width_flexusdeminutus=168
        porrectusflexuswidths=(503,629,628,628,931)
        porrectuswidths=(503,629,628,628,931)
        hepisemus_additional_width=30
    if (font_name=="gregoria"):
        base_height=157.5
        line_width=22
        width_punctum=164
        width_oriscus=164
        width_oriscus_rev=164
        width_quilisma=164
        width_debilis=88
        width_deminutus=88
        width_inclinatum=173
        width_stropha=164
        width_high_pes=154
        width_inclinatum_deminutus=128
        width_flexusdeminutus=186
        porrectusflexuswidths=(340,428,586,670,931)
        porrectuswidths=(490,575,650,740,931)
        hepisemus_additional_width=30

# a function called at the beginning of the script, that opens the font
def header():
    fout.write("#!/usr/local/bin/fontforge\n\nPrint(\"Creating all square notation symbols for the %s font.\\nThis may take several minutes.\");\n" % font_name)
    open_base_font(font_name)

def open_base_font(font_name):
    if font_name=="gregoria":
        fout.write("Open(\"gregorio-base.sfd\");\n")
    else:
        fout.write("Open(\"%s-base.sfd\");\n" % font_name)

# the function that deletes the temporary glyphs and saves the modified font, called at the end
def footer():
    fout.write("Close();\n")
    fout.write("Quit(0);\n")

# a function that prints a message to stdout, so that the user gets less bored when building the font
def message(glyph_name):
    fout.write("Print(\"generating %s for %s...\");\n" % (glyph_name, font_name))

def precise_message(glyph_name):
    fout.write("Print(\"  * %s\");\n" % glyph_name)

# function called when we are at the 255th glyph of a font, we start a new one.
def end_font():
    global current_glyph_number
    global current_font_number
    global count, initialcount
    for glyph in toremove:
        fout.write("Select(\"%s\");\n" % glyph)
        fout.write("Clear();\n")
    if (current_font_number!=0):
        for glyph in initial_glyphs:
            fout.write("Select(\"%s\");\n" % glyph)
            fout.write("Clear();\n")
    if (count != initialcount+255):
        # we suppress empty glyphs
        for i in range(count, initialcount+256):
            fout.write("Select(\"NameMe.%d\");\n" % i)
            fout.write("Clear();\n")        
    fout.write("Reencode(\"compacted\");\n")
    fout.write("Reencode(\"original\",1);\n")
    fout.write("Reencode(\"compacted\");\n")
    fout.write("SetFontNames(\"%s-%d\");\n" % (font_name, current_font_number))
    #for gregoria font, we generate the sfd, not the pfb
    if font_name=="gregoria":
        fout.write("Save(\"%s-%d.sfd\");\n" % (font_name, current_font_number))
    else:
        # 66537 is for generating an afm and a tfm file
        fout.write("Generate(\"%s-%d.pfb\",\"\",66537);\n" % (font_name,current_font_number))
        # uncomment the next line if you want to generate sfd files (easier to debug)
        #fout.write("Save(\"%s-%d.sfd\");\n" % (font_name, current_font_number))
    fout.write("Close();\n")
    open_base_font(font_name)
    current_glyph_number=0
    current_font_number=current_font_number+1
    count=initialcount

# function called at the end of the modification of a glyph, it simplifies it and removes the overlap, so at the end we have the glyph that we want.

def end_glyph(glyphname):
    global current_glyph_number
    fout.write("Simplify();\n")
    fout.write("Simplify();\n")
    fout.write("RemoveOverlap();\n")
    fout.write("Simplify();\n")
    fout.write("CanonicalContours();\n")
    fout.write("CanonicalStart();\n")
    if (current_glyph_number==255):
        end_font()
    else:
        current_glyph_number=current_glyph_number+1

# function called to initialize a glyph for modification

def begin_glyph(glyphname):
    global count
    fout.write("Select(\"NameMe.%i\");\n" % count)
    fout.write("SetGlyphName(\"%s\");\n" % glyphname)
    count=count+1

# function to set the width of a glyph

def set_width(width):
    fout.write("SetWidth(%d);\n" % width)

# function to get the name of the glyph, with the name of the general shape, and the name of the different ambitus

def name(i, j, k, shape, liquescentia):
    if shortglyphs==0:
        glyphnumber=i+(5*j)+(25*k)+(256*liquescentiae[liquescentia])+(512*shapes[shape])
    else :
        glyphnumber=i+(5*j)+(25*k)+(64*liquescentiae[liquescentia])+(512*shapes[shape])
    return "_%04d" % (glyphnumber)

# function that simply pastes the src glyph into dst glyph, without moving it

def simple_paste(src, dst):
    fout.write("Select(\"%s\");\n" % src)
    fout.write("Copy();\n")
    fout.write("Select(\"%s\");\n" % dst)
    fout.write("PasteInto();\n")

# function that pastes the src glyph into dst, and moves it with horiz and vert offsets

def paste_and_move(src, dst, horiz, vert):
    fout.write("Select(\"%s\");\n" % src)
    fout.write("Copy();\n")
    fout.write("Select(\"%s\");\n" % dst)
    fout.write("PasteWithOffset(%.2f, %.2f);\n" % (horiz, vert))

# the simplify function of fontforge is quite strange, and sometimes doesn't work well if we call it at the end of a glyph modification, so in some case we have to call this function in the middle of a determination.

def simplify():
    fout.write("Simplify();\n")
    fout.write("RemoveOverlap();\n")
    fout.write("Simplify();\n")

# a function that scales a glyph, horizontally by x and vertically by y
def scale(x, y):
    fout.write("Transform(%d00, 0, 0, %d00, 0, 0);\n" % (x,y))


# a function that moves a glyph, horizontally by x and vertically by y
def move(x, y):
    fout.write("Move(%d,%d);\n" % (x,y))

# a function that writes a line in glyphname, with length and height offsets

def write_line(i, glyphname, length, height):
    if (i>1):
        linename= "line%d" % i 
        paste_and_move(linename, glyphname, length, height)    

# a function to write the first bar of a glyph. Used for porrectus flexus, porrectus and flexus.

def write_first_bar(i, glyphname):
    paste_and_move("queue", glyphname, 0, (-i+1)*base_height)
    write_line(i, glyphname, 0, (-i+1)*base_height)

# as the glyph before a deminutus is not the same as a normal glyph, and always the same, we can call this function each time. Sometimes we have to simplify before building the last glyph (tosimplify=1), and length is the offset.

def write_deminutus(i, j, glyphname, length=0, tosimplify=0, firstbar=1):
    if firstbar!=0:
        paste_and_move("mdeminutus", glyphname, length, i*base_height)
    else:
        paste_and_move("mnbdeminutus", glyphname, length, i*base_height)
    write_line(j, glyphname, length+width_flexusdeminutus-line_width, (i-j+1)*base_height)
    if (tosimplify):
        simplify()
    paste_and_move("deminutus", glyphname, length+width_flexusdeminutus-width_deminutus-line_width, (i-j)*base_height)

def hepisemus():
    message("horizontal episemus")
    write_hepisemus(width_punctum, "_0040")
    write_hepisemus(width_flexusdeminutus, "_0041")          
    write_hepisemus(width_debilis+line_width, "_0042")
    write_hepisemus(width_inclinatum, "_0043")
    write_hepisemus(width_inclinatum_deminutus, "_0044")
    write_hepisemus(width_stropha, "_0045")
    write_hepisemus(width_quilisma, "_0056")
    write_hepisemus(width_high_pes, "_0058")
    write_hepisemus(width_oriscus, "_0057")
    for i in range(max_interval):
        write_hepisemus(porrectuswidths[i], "_00%02d" % int(46+i))
    for i in range(max_interval):
        write_hepisemus(porrectusflexuswidths[i], "_00%02d" % int(51+i))
    
def write_hepisemus(shape_width, glyphname):
    begin_glyph(glyphname)
    simple_paste("hepisemus_base", glyphname)
    scale(shape_width + 2*hepisemus_additional_width, 1)
    move(-hepisemus_additional_width, 0)
    paste_and_move("hepisemusleft", glyphname, -hepisemus_additional_width, 0)
    paste_and_move("hepisemusright", glyphname, shape_width + hepisemus_additional_width, 0)
    set_width(shape_width)
    end_glyph(glyphname)

def pes():
    message("pes")
    precise_message("pes")
    if (font_name=="gregorio" or font_name=="parmesan" or font_name=="gregoria" or font_name=="greciliae"):
    # we prefer drawing the pes with one ton of ambitus by hand, it is more beautiful
        for i in range(2,max_interval+1):
            write_pes(i, "p2base", 'pes')
    else:
        for i in range(1,max_interval+1):
            write_pes(i, "pbase", 'pes')
    # idem for the pes quilisma
    precise_message("pes quilisma")
    if (font_name=="gregorio" or font_name=="parmesan" or font_name=="greciliae" or font_name=="gregoria"):
        for i in range(2,max_interval+1):
            write_pes(i, "qbase", 'pesquilisma')
    else:
        for i in range(1,max_interval+1):
            write_pes(i, "qbase", 'pesquilisma')
    precise_message("pes deminutus")
    for i in range(1,max_interval+1):
        write_pes_deminutus(i, "pesdeminutus", 'pes', 'deminutus')
    precise_message("pes initio debilis")
    for i in range(1,max_interval+1):
        write_pes_debilis(i, 'pes', 'initiodebilis')
    precise_message("pes initio debilis deminutus")
    for i in range(1,max_interval+1):
        write_pes_debilis_deminutus(i, 'pes', 'initiodebilisdeminutus')

def write_pes(i, first_glyph, shape, liquescentia='nothing'):
    glyphname=name(i, 0, 0, shape, liquescentia)
    begin_glyph(glyphname)
    # the difference of width of the two shapes, that will change a thing or two...
    if (first_glyph=="qbase"):
        width_difference=width_quilisma-width_high_pes
    elif (first_glyph=="pbase" or first_glyph == "p2base"):
        width_difference=width_punctum-width_high_pes
    else:
        width_difference=0
    if (width_difference<0):
        paste_and_move(first_glyph, glyphname, -width_difference, 0)
    else:
        simple_paste(first_glyph, glyphname)
    if (first_glyph=="qbase"):
        width1=width_quilisma-line_width
    else:
        width1=width_punctum-line_width
    if (width_difference<0):
        width1=width1-width_difference
    write_line(i, glyphname, width1, base_height)
    if (width_difference != 0):
        paste_and_move("phigh", glyphname, width_difference, i*base_height)
    else:
        paste_and_move("phigh", glyphname, 0, i*base_height)
    if (width_difference<0):
        set_width(width_punctum)
    else:
        set_width(width_quilisma)
    end_glyph(glyphname)    

def write_pes_debilis(i, shape, liquescentia='nothing'):
    glyphname=name(i, 0, 0, shape, liquescentia)
    begin_glyph(glyphname)
    # with a deminutus it is much more beautiful than with a idebilis
    paste_and_move("deminutus", glyphname, width_high_pes-line_width-width_debilis, 0)
    write_line(i, glyphname, width_high_pes-line_width, base_height)
    simplify()
    paste_and_move("phigh", glyphname, 0, i*base_height)
    set_width(width_high_pes)
    end_glyph(glyphname) 

def write_pes_deminutus(i, first_glyph, shape, liquescentia='nothing'):
    glyphname=name(i, 0, 0, shape, liquescentia)
    begin_glyph(glyphname)
    simple_paste(first_glyph, glyphname)
    if (first_glyph=="qbase"):
        width1=width_quilisma-line_width
    else:
        width1=width_punctum-line_width
    write_line(i, glyphname, width_punctum-line_width, base_height)
    paste_and_move("rdeminutus", glyphname, width_punctum-line_width-width_deminutus, i*base_height)
    set_width(width_punctum)
    end_glyph(glyphname)

def write_pes_debilis_deminutus(i, shape, liquescentia='nothing'):
    glyphname=name(i, 0, 0, shape, liquescentia)
    begin_glyph(glyphname)
    simple_paste("deminutus", glyphname)
    write_line(i, glyphname, width_debilis, base_height)
    simplify()
    paste_and_move("rdeminutus", glyphname, 0, i*base_height)
    set_width(width_debilis+line_width)
    end_glyph(glyphname)

def pes_quadratum():
    message("pes quadratum")
    precise_message("pes quadratum")
    for i in range(1,max_interval+1):
        write_pes_quadratum(i, "base5", "rvsbase", 'pesquadratum')
    for i in range(1,max_interval+1):
        write_pes_quadratum(i, "base5", "rvlbase", 'pesquadratum_longqueue')
    precise_message("pes quassus")
    for i in range(1,max_interval+1):
        write_pes_quadratum(i, "obase", "rvsbase", 'pesquassus')
    for i in range(1,max_interval+1):
        write_pes_quadratum(i, "obase", "rvlbase", 'pesquassus_longqueue')
    precise_message("pes quilisma quadratum")
    for i in range(1,max_interval+1):
        write_pes_quadratum(i, "qbase", "rvsbase", 'pesquilismaquadratum')
    for i in range(1,max_interval+1):
        write_pes_quadratum(i, "qbase", "rvlbase", 'pesquilismaquadratum_longqueue')
    precise_message("pes auctus ascendens")
    for i in range(1,max_interval+1):
        write_pes_quadratum(i, "base5", "auctusa2", 'pesquadratum', 'auctusascendens')
    precise_message("pes initio debilis auctus ascendens")
    for i in range(1,max_interval+1):
        write_pes_quadratum(i, "idebilis", "auctusa2", 'pesquadratum', 'initiodebilisauctusascendens')
    precise_message("pes quassus auctus ascendens")
    for i in range(1,max_interval+1):
        write_pes_quadratum(i, "obase", "auctusa2", 'pesquassus', 'auctusascendens')
    precise_message("pes quilisma auctus ascendens")
    for i in range(1,max_interval+1):
        write_pes_quadratum(i, "qbase", "auctusa2", 'pesquilismaquadratum', 'auctusascendens')
    precise_message("pes auctus descendens")
    for i in range(1,max_interval+1):
        write_pes_quadratum(i, "base5", "auctusd2", 'pesquadratum', 'auctusdescendens')
    precise_message("pes initio debilis auctus descendens")
    for i in range(1,max_interval+1):
        write_pes_quadratum(i, "idebilis", "auctusd2", 'pesquadratum', 'initiodebilisauctusdescendens')
    precise_message("pes quassus auctus descendens")
    for i in range(1,max_interval+1):
        write_pes_quadratum(i, "obase", "auctusd2", 'pesquassus', 'auctusdescendens')
    precise_message("pes quilisma auctus descendens")
    for i in range(1,max_interval+1):
        write_pes_quadratum(i, "qbase", "auctusd2", 'pesquilismaquadratum', 'auctusdescendens')

def write_pes_quadratum(i, first_glyph, last_glyph, shape, liquescentia='nothing'):
    glyphname=name(i, 0, 0, shape, liquescentia)
    begin_glyph(glyphname)
    if (first_glyph=="idebilis"):
        first_width=width_deminutus
    elif (first_glyph=="base5"):
        if i==1:
            first_glyph='_0017'
            if last_glyph=='base7':
                last_glyph='_0017'
            elif last_glyph=='auctusa2':
                last_glyph='_0072'
            elif last_glyph=='auctusd2':
                last_glyph='_0073'
            elif last_glyph=='rvsbase':
                last_glyph='_0023'
            elif last_glyph=='rvlbase':
                last_glyph='_0022'
            first_width=width_punctum
        else:
            first_width=width_punctum-line_width
    elif(first_glyph=="obase"):
        first_width=width_oriscus-line_width
    else:
        first_width=width_quilisma-line_width
    simple_paste(first_glyph, glyphname)
    if (i!=1):
        linename= "line%d" % i 
        paste_and_move(linename, glyphname, first_width, base_height)
    paste_and_move(last_glyph, glyphname, first_width, i*base_height)
    set_width(first_width+width_punctum)
    end_glyph(glyphname)    

def flexus():
    message("flexus")
    precise_message("flexus")
    for i in range(1,max_interval+1):
        write_flexus(i, "base2", 'base7', 'flexus_nobar')
    for i in range(1,max_interval+1):
        write_flexus(i, "odbase", 'base7', 'flexus_oriscus')
    for i in range(1,max_interval+1):
        write_flexus(i, "vsbase", 'base7', 'flexus')
    for i in range(1,max_interval+1):
        write_flexus(i, "vlbase", 'base7', 'flexus_longqueue')
    precise_message("flexus deminutus")
    for i in range(1,max_interval+1):
        write_flexus(i, "mdeminutus", 'base7', 'flexus_nobar', 'deminutus')
    for i in range(1,max_interval+1):
        write_flexus(i, "mdeminutus", 'base7', 'flexus', 'deminutus')
    for i in range(1,max_interval+1):
        write_flexus(i, "mdeminutus", 'base7', 'flexus_longqueue', 'deminutus')
    precise_message("flexus auctus ascendens")
    for i in range(1,max_interval+1):
        write_flexus(i, "base2", 'auctusa1', 'flexus_nobar', 'auctusascendens')
    for i in range(1,max_interval+1):
        write_flexus(i, "odbase", 'auctusa1', 'flexus_oriscus', 'auctusascendens')
    for i in range(1,max_interval+1):
        write_flexus(i, "vsbase", 'auctusa1', 'flexus', 'auctusascendens')
    for i in range(1,max_interval+1):
        write_flexus(i, "vlbase", 'auctusa1', 'flexus_longqueue', 'auctusascendens')
    precise_message("flexus auctus descendens")
    for i in range(1,max_interval+1):
        write_flexus(i, "base2", 'auctusd1', 'flexus_nobar', 'auctusdescendens')
    for i in range(1,max_interval+1):
        write_flexus(i, "odbase", 'auctusd1', 'flexus_oriscus', 'auctusdescendens')
    for i in range(1,max_interval+1):
        write_flexus(i, "vsbase", 'auctusd1', 'flexus', 'auctusdescendens')
    for i in range(1,max_interval+1):
        write_flexus(i, "vlbase", 'auctusd1', 'flexus_longqueue', 'auctusdescendens')

def write_flexus(i, first_glyph, last_glyph, shape, liquescentia='nothing'):
    glyphname=name(i, 0, 0, shape, liquescentia)
    begin_glyph(glyphname)
    # we add a queue if it is a deminutus
    if (first_glyph=="mdeminutus"):
        if shape=='flexus_nobar':
            write_deminutus(0, i, glyphname, length=0, tosimplify=1, firstbar=0)
        elif shape=='flexus':
            write_first_bar(1, glyphname)
            write_deminutus(0, i, glyphname, length=0, tosimplify=1, firstbar=1)
        else:
            write_first_bar(2, glyphname)
            write_deminutus(0, i, glyphname, length=0, tosimplify=1, firstbar=1)
        length=width_flexusdeminutus
    else:
        if i==1:#we remove the bar aspect
            if last_glyph=='base7':
                last_glyph='_0017'
            elif last_glyph=='auctusa1':
                last_glyph='_0072'
            elif last_glyph=='auctusd1':
                last_glyph='_0073' 
            if first_glyph=='base2':
                first_glyph='_0017'
            if first_glyph=='odbase':
                first_glyph='_0028'
            elif first_glyph=='vsbase':
                first_glyph='_0025'
            elif first_glyph=='vlbase':
                first_glyph='_0024'
        simple_paste(first_glyph, glyphname)
        if first_glyph=='odbase':
            length = width_oriscus_rev
        else:
            length=width_punctum
        if i!=1:
            length=length-line_width
            write_line(i, glyphname, length, (1-i)*base_height)
        paste_and_move(last_glyph, glyphname, length, (-i)*base_height)
        if first_glyph=='odbase':
            length = width_oriscus_rev
        else:
            length = width_punctum
        if i==1:
            length = 2 * length
        else:
            length = 2 * length - line_width
    set_width(length)
    end_glyph(glyphname)

def porrectus():
    message("porrectus")
    precise_message("porrectus")
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            write_porrectus(i,j, "phigh", 1, 'porrectus')
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            write_porrectus(i,j, "phigh", 0, 'porrectus_nobar')
    #precise_message("porrectus deminutus")
    #for i in range(1,max_interval+1):
    #    for j in range(1,max_interval+1):
    #        write_porrectus(i,j, "rdeminutus", 1, 'porrectus', 'deminutus')
    #for i in range(1,max_interval+1):
    #    for j in range(1,max_interval+1):
    #        write_porrectus(i,j, "rdeminutus", 0, 'porrectus_nobar', 'deminutus')
    precise_message("porrectus deminutus")
    for i in range(1, max_interval+1):
        for j in range(1, max_interval+1):
            write_alternate_porrectus_deminutus(i,j)

def write_porrectus(i,j, last_glyph, with_bar, shape, liquescentia='nothing'):
    glyphname=name(i, j, 0, shape, liquescentia)
    begin_glyph(glyphname)
    length=porrectuswidths[i-1]
    if (with_bar):
        write_first_bar(i, glyphname)
    first_glyph="porrectus%d" % i
    simple_paste(first_glyph, glyphname)
    write_line(j, glyphname, length-line_width, (-i+1)*base_height)
    if (with_bar):
        simplify()
    if (last_glyph=="rdeminutus"):
        paste_and_move(last_glyph, glyphname, (length-width_deminutus-line_width), (j-i)*base_height)
    else:
        paste_and_move(last_glyph, glyphname, (length-width_high_pes), (j-i)*base_height)
    set_width(length)
    end_glyph(glyphname)

def write_alternate_porrectus_deminutus(i,j):
    glyphname=name(i, j, 0, 'porrectus', 'deminutus')
    begin_glyph(glyphname)
    write_first_bar(i, glyphname)
    if i == 1:
        simple_paste('base2', glyphname)
    else:
        simple_paste('base3', glyphname)
    write_line(i, glyphname, width_punctum-line_width, (-i+1)*base_height)
    simplify()
    paste_and_move('mpdeminutus', glyphname, (width_punctum-line_width), (-i)*base_height)
    write_line(j, glyphname, width_punctum+width_flexusdeminutus-2*line_width, (-i+1)*base_height)
    paste_and_move('rdeminutus', glyphname, (width_punctum+width_flexusdeminutus-2*line_width-width_deminutus), (j-i)*base_height)
    set_width(width_punctum+width_flexusdeminutus-line_width)
    end_glyph(glyphname)


def porrectusflexus():
    message("porrectus flexus")
    precise_message("porrectus flexus")
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            for k in range(1,max_interval+1):
                write_porrectusflexus(i,j,k, "base7", 0, 'porrectusflexus_nobar')
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            for k in range(1,max_interval+1):
                write_porrectusflexus(i,j,k, "base7", 1, 'porrectusflexus')
    precise_message("porrectus flexus auctus descendens")
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            for k in range(1,max_interval+1):
                write_porrectusflexus(i,j,k, "auctusd1", 0, 'porrectusflexus_nobar', 'auctusdescendens')
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            for k in range(1,max_interval+1):
                write_porrectusflexus(i,j,k, "auctusd1", 1, 'porrectusflexus', 'auctusdescendens')
    precise_message("porrectus flexus auctus ascendens")
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            for k in range(1,max_interval+1):
                write_porrectusflexus(i,j,k, "auctusa1", 0, 'porrectusflexus_nobar', 'auctusascendens')
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            for k in range(1,max_interval+1):
                write_porrectusflexus(i,j,k, "auctusa1", 1, 'porrectusflexus', 'auctusascendens')
    precise_message("porrectus flexus deminutus")
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            for k in range(1,max_interval+1):
                write_porrectusflexus(i,j,k, "deminutus", 0, 'porrectusflexus_nobar', 'deminutus')
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            for k in range(1,max_interval+1):
                write_porrectusflexus(i,j,k, "deminutus", 1, 'porrectusflexus', 'deminutus')

def write_porrectusflexus(i,j,k, last_glyph, with_bar, shape, liquescentia='nothing'):
    glyphname=name(i, j, k, shape, liquescentia)
    begin_glyph(glyphname)
    length=porrectusflexuswidths[i-1]
    if j==1:
        first_glyph="porrectusflexusnb%d" % i
    else:
        first_glyph="porrectusflexus%d" % i
    if (with_bar):
        write_first_bar(i, glyphname)
    simple_paste(first_glyph, glyphname)
    write_line(j, glyphname, length-line_width, (-i+1)*base_height)
    if (last_glyph=="deminutus"):
        if j==1:
            write_deminutus(j-i,k,glyphname, length-line_width,with_bar,firstbar=0)
            length=length+width_flexusdeminutus
        else:
            write_deminutus(j-i,k,glyphname, length-line_width,with_bar,firstbar=1)
            length=length+width_flexusdeminutus-line_width
    else:
        simplify()
        middle_glyph='base3'
        if j==1:
            if k==1:
                middle_glyph='_0017'
            else:
                middle_glyph='base2'
        else:
            length=length-line_width
            if k==1:
                middle_glyph='base4'
        paste_and_move(middle_glyph, glyphname, length, (j-i)*base_height)
        if k==1:
            if last_glyph=='base7':
                last_glyph='_0017'
            elif last_glyph=='auctusa1':
                last_glyph='_0072'
            elif last_glyph=='auctusd1':
                last_glyph='_0073'
            length=length+width_punctum
        else:
            write_line(k, glyphname, length + width_punctum - line_width, (j-i-k+1)*base_height)
            length=length + width_punctum - line_width
        paste_and_move(last_glyph, glyphname, length, (j-i-k)*base_height)
        length=length+ width_punctum
    set_width(length)
    end_glyph(glyphname)

def torculus():
    message("torculus")
    precise_message("torculus")
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            write_torculus(i,j, "base5", "base7", 'torculus')
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            write_torculus(i,j, "qbase", "base7", 'torculusquilisma')
    precise_message("torculus initio debilis")
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            write_torculus(i,j, "idebilis", "base7", 'torculus', 'initiodebilis')
    precise_message("torculus auctus descendens")
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            write_torculus(i,j, "base5", "auctusd1", 'torculus', 'auctusdescendens')
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            write_torculus(i,j, "qbase", "auctusd1", 'torculusquilisma', 'auctusdescendens')
    precise_message("torculus initio debilis auctus descendens")
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            write_torculus(i,j, "idebilis", "auctusd1", 'torculus', 'initiodebilisauctusdescendens')
    precise_message("torculus auctus ascendens")
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            write_torculus(i,j, "base5", "auctusa1", 'torculus', 'auctusascendens')
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            write_torculus(i,j, "qbase", "auctusa1", 'torculusquilisma', 'auctusascendens')
    precise_message("torculus initio debilis auctus ascendens")
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            write_torculus(i,j, "idebilis", "auctusa1", 'torculus', 'initiodebilisauctusascendens')
    precise_message("torculus deminutus")
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            write_torculus(i,j, "base5", "deminutus", 'torculus', 'deminutus')
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            write_torculus(i,j, "qbase", "deminutus", 'torculusquilisma', 'deminutus')
    precise_message("torculus initio debilis deminutus")
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            write_torculus(i,j, "idebilis", "deminutus", 'torculus', 'initiodebilisdeminutus')

def write_torculus(i,j, first_glyph, last_glyph, shape, liquescentia='nothing'):
    glyphname=name(i, j, 0, shape, liquescentia)
    begin_glyph(glyphname)
    length=width_punctum-line_width
    if (first_glyph=="idebilis"):
        length=width_debilis
    elif first_glyph=="qbase":
        length=width_quilisma-line_width
        if i==1:
            first_glyph='_0026'
            length=width_quilisma
    elif i==1:
        first_glyph='_0017'
        length=width_punctum
    simple_paste(first_glyph, glyphname)
    if i!=1:
        write_line(i, glyphname, length, base_height)
    if (last_glyph=="deminutus"):
        if i==1:
            write_deminutus(i,j,glyphname, length, firstbar=0)
        else:
            write_deminutus(i,j,glyphname, length, firstbar=1)
        length=length+width_flexusdeminutus
    else:
        if j==1:
            if i==1:
                paste_and_move("_0017", glyphname, length, i*base_height)
            else:
                paste_and_move("base4", glyphname, length, i*base_height)
            length=length+width_punctum
            if last_glyph=='base7':
                last_glyph='_0017'
            elif last_glyph=='auctusa1':
                last_glyph='_0072'
            elif last_glyph=='auctusd1':
                last_glyph='_0073'   
        else:
            if i==1:
                paste_and_move("base2", glyphname, length, i*base_height)
            else:
                paste_and_move("base3", glyphname, length, i*base_height)
            length=length+width_punctum-line_width
            write_line(j, glyphname, length, (i-j+1)*base_height)
        paste_and_move(last_glyph, glyphname,  length, (i-j)*base_height)
        length=length+width_punctum
    set_width(length)
    end_glyph(glyphname)

def torculusresupinus():
    message("torculus resupinus")
    precise_message("torculus resupinus")
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            for k in range(1,max_interval+1):
                write_torculusresupinus(i,j,k, 'base5', "phigh", 'torculusresupinus')
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            for k in range(1,max_interval+1):
                write_torculusresupinus(i,j,k, 'idebilis', "phigh", 'torculusresupinus', 'initiodebilis')
    precise_message("torculus resupinus deminutus")
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            for k in range(1,max_interval+1):
                write_torculusresupinusdeminutus(i,j,k, 'base5', 'torculusresupinus', 'deminutus')
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            for k in range(1,max_interval+1):
                write_torculusresupinusdeminutus(i,j,k, 'idebilis', 'torculusresupinus', 'initiodebilisdeminutus')
                

def write_torculusresupinus(i,j,k, first_glyph, last_glyph, shape, liquescentia='nothing'):
    glyphname=name(i, j, k, shape, liquescentia)
    begin_glyph(glyphname)
    if first_glyph=="idebilis":
        length=width_debilis
    elif i==1:
        if first_glyph=='base5':
            first_glyph='_0017'
            length=width_punctum
    else:
        if first_glyph=='base5':
            length=width_punctum-line_width
    simple_paste(first_glyph, glyphname)
    if i!=1:
        write_line(i, glyphname, length, base_height)
    middle_glyph="porrectus%d" % j
    paste_and_move(middle_glyph, glyphname, length, i*base_height)
    length=length + porrectuswidths[j-1]
    write_line(k, glyphname, length-line_width, (i-j+1)*base_height)
    simplify()
    if (last_glyph=="rdeminutus"):
        paste_and_move(last_glyph, glyphname, (length-width_deminutus-line_width), (i-j+k)*base_height)
    else:
        paste_and_move(last_glyph, glyphname, (length-width_high_pes), (i-j+k)*base_height)
    set_width(length)
    end_glyph(glyphname)

def write_torculusresupinusdeminutus(i,j,k, first_glyph, shape, liquescentia='nothing'):
    glyphname=name(i, j, k, shape, liquescentia)
    begin_glyph(glyphname)
    length=width_punctum-line_width
    if (first_glyph=="idebilis"):
        length=width_debilis
    elif i==1:
        first_glyph='_0017'
        length=width_punctum
    simple_paste(first_glyph, glyphname)
    if i!=1:
        write_line(i, glyphname, length, base_height)
    if j==1 and i==1:
        if first_glyph=="idebilis":
            paste_and_move("base4", glyphname, length, i*base_height)
            length=length+width_punctum
            last_glyph='mnbpdeminutus'
        else:
            paste_and_move("_0017", glyphname, length, i*base_height)
            length=length+width_punctum
            last_glyph='mnbpdeminutus'
    elif j==1:
        paste_and_move("base4", glyphname, length, i*base_height)
        length=length+width_punctum
        last_glyph='mnbpdeminutus'
    elif i==1 and first_glyph != "idebilis":
        paste_and_move("base2", glyphname, length, i*base_height)
        length=length+width_punctum-line_width
        write_line(j, glyphname, length, (i-j+1)*base_height)
        last_glyph='mpdeminutus'
    else:
        paste_and_move("base3", glyphname, length, i*base_height)
        length=length+width_punctum-line_width
        write_line(j, glyphname, length, (i-j+1)*base_height)
        last_glyph='mpdeminutus'
    paste_and_move(last_glyph, glyphname, length, (i-j)*base_height)
    length=length+width_flexusdeminutus
    write_line(k, glyphname, length-line_width, (i-j+1)*base_height)
    paste_and_move('rdeminutus', glyphname, length-width_deminutus-line_width, (i-j+k)*base_height)
    set_width(length)
    end_glyph(glyphname)

def scandicus():
    message("scandicus")
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            write_scandicus(i,j)
            
def write_scandicus(i,j):
    glyphname=name(i, j, 0, 'scandicus', 'deminutus')
    begin_glyph(glyphname)
    if i == 1:
        simple_paste('_0017', glyphname)
        length = width_punctum
        second_glyph = 'mnbpdeminutus'
    else:
        simple_paste('base5', glyphname)
        length = width_punctum - line_width
        write_line(i, glyphname, length, base_height)
        second_glyph = 'msdeminutus'
    paste_and_move(second_glyph, glyphname, length, i*base_height)
    length = length + width_flexusdeminutus
    if j != 1:
        write_line(j, glyphname, length - line_width, (i+1) * base_height)
    paste_and_move('rdeminutus', glyphname, length - width_deminutus - line_width, (i+j)*base_height)
    set_width(length)
    end_glyph(glyphname)
        
def ancus():
    message("ancus")
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            write_ancus(i,j, 'vsbase', 'ancus')
    for i in range(1,max_interval+1):
        for j in range(1,max_interval+1):
            write_ancus(i,j, 'vlbase', 'ancus_longqueue')
            
def write_ancus(i,j, first_glyph, glyph_type):
    glyphname=name(i, j, 0, glyph_type, 'deminutus')
    begin_glyph(glyphname)
    if i == 1:
        length = width_punctum
        second_glyph = 'mnbdeminutus'
        if first_glyph == 'vsbase':
            first_glyph = '_0025'
        else:
            first_glyph = '_0024'
    else:
        length = width_punctum - line_width
        second_glyph = 'mademinutus'
    simple_paste(first_glyph, glyphname)
    if i != 1:
        write_line(i, glyphname, length, (-i+1)*base_height)
    paste_and_move(second_glyph, glyphname, length, -(i)*base_height)
    length = length + width_flexusdeminutus
    if j != 1:
        write_line(j, glyphname, length - line_width, (-i-j+1) * base_height)
    paste_and_move('deminutus', glyphname, length - width_deminutus - line_width, (-i-j)*base_height)
    set_width(length)
    end_glyph(glyphname)
    
    
if __name__ == "__main__":
    main()
