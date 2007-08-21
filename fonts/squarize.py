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
#This script takes a very simple .sfd file with a few symbols and builds a|
#complete square notation font. See gregorio-base.sfd for naming conventions
#of these symbols.
#
#This python script generates a fontforge native script (.pe). In the future, 
#python will also work (better that .pe) to control fontforge with scripts, but
#it is not yet implemented. The .pe script will build foo-0.pfb (and also .tfm,
#.afm and .enc) to foo-5.pfb.
#
#To build you own font, look at gregorio-base.sfd, and build you own glyphs from
#it.
#
#Basic use :
# ./sqarize.py
# chmod +x squarize.pe
# ./squarize.pe
# the last step may take a few minutes

import getopt, sys

#defines the maximal interval between two notes, the bigger this number is, the more glyphs you'll have to generate
max_interval=5

# the list of the number of the glyphs

shapes={
'pes':2,
'pesquadratum':6,
'pesquilisma':4,
'pesquassus':5,
'pesquilismaquadratum':3,
'flexus':7,
'porrectusflexus':8,
'porrectusflexus_nobar':10,
'porrectus':11,
'porrectus_nobar':12,
'flexus_nobar':13,
'flexus_longqueue':15,
'torculus':14,
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

toremove=['base2', 'base3', 'base4', 'base5', 'base6', 'base7', 'line2', 'line3', 'line4', 'line5', 'pesdeminutus', 'mdeminutus', 'auctusa1', 'auctusa2', 'auctusd1', 'auctusd2', 'queue', 'idebilis', 'deminutus', 'rdeminutus', 'obase', 'qbase', 'pbase', 'porrectus1', 'porrectus2', 'porrectus3', 'porrectus4', 'porrectus5', 'porrectusflexus1', 'porrectusflexus2', 'porrectusflexus3', 'porrectusflexus4', 'porrectusflexus5', 'vsbase', 'vbase', 'vlbase', 'hepisemus_base','letterbar']

# in the police, all the free glyphs have the name NameMexxxx where xxxx is a number starting from 141 and increasing by one. For example each new glyph will be basically NameMecount, the next NameMecount+1, etc. They are initiated in initalize_glyphs()
initialcount=0
count=0

current_glyph_number=0
current_font_number=0

# initial glyphs are the names of the glyphs that are already in gregorio_base, mostly one-note glyphs. see initialize_glyphs() for more details
initial_glyphs=[1,2,17,19,20,26,27,28,6,32,11,8,23,25,9,10,24,7,4,3,21,31,22,14,15,33,13,62,65,39,69,70,38,37,60,61,63,64,16,34,35,36,66,67,68]

def usage():
    print """
Python script to convert a small set of glyphs into a complete
gregorian square notation font. The initial glyphs have a name convention,
see gregorio-base.sfd for this convention.

Usage:
	squarize.py fontname

with fontame=gregorio or parmesan for now. The script generates squarize-fontame.pe
which is a fontforge script.
"""

def main():
    global fout, font_name
    global current_glyph_number
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
    else:
        usage()
        sys.exit(2)
    # the file we are going to write in
    fout=open("squarize-%s.pe" % font_name, 'w')
    initialize_glyphs()
    initialize_lengths()
    current_glyph_number=len(initial_glyphs)
    headers()
    hepisemus()
    pes()
    pes_quadratum()
    flexus()
    torculus()
    porrectus()
    porrectusflexus()
    end_font()
    footers()
    fout.close()

def initialize_glyphs():
    global initial_glyphs, initialcount, count
    for number in initial_glyphs:
	toto="_00%02d" % int(number)
	initial_glyphs.insert(0,toto)
	initial_glyphs.remove(number)
    if font_name=="gregorio":
	glyphs_to_append=("_1025", "_4097")
    if font_name=="parmesan":
	glyphs_to_append=("_1025", "_4097")
    for glyphnumber in glyphs_to_append:
	initial_glyphs.append(glyphnumber)
    initialcount=159
    count=initialcount

#function in which we initialize the lenghts, depending on the font
def initialize_lengths():
    global base_height, line_width, width_punctum, width1, width2, width_debilis, width_deminutus, width_inclinatum_deminutus, width_flexusdeminutus, porrectusflexuswidths, porrectuswidths, width_inlinatum, width_stropha, hepisemus_additional_width, width_oriscus, width_quilisma
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
	# the width of the first note of an initio debilis, and the one of the last note of a deminutus. Warning, in GregorioTeX they must be the same! you must (almost always) add the width of a line to have the real width.
	width_debilis=88
	width_deminutus=88
	#width of a punctum inclinatum (we consider that the punctum inclinatum auctus has the same width
	width_inlinatum=164
	#width of a stropha (idem for the stropha aucta)
	width_stropha=164
	# the width of the punctum inclinatum deminutus (no need to add the width of a line)
	width_inclinatum_deminutus=82
	# the width of the note which is just before a deminutus, in some fonts it is not the same width as a punctum
	width_flexusdeminutus=197
	# the widths of the torculus resupinus, there are five, one per note difference between the two first notes (for example the first is the width of the first two notes of baba
	porrectusflexuswidths=(340,428,586,670,931)
	porrectuswidths=(490,575,650,740,931)
	# width that will be added to the standard width when we will build horizontal episemus. for example, if a punctum has the length 164, the episemus will have the width 244 and will be centered on the center of the punctum 
	hepisemus_additional_width=40
    if (font_name=="parmesan"):
	base_height=157.5
	line_width=22
	width_punctum=161
	width_oriscus=192
	width_quilisma=161
	width_debilis=75
	width_deminutus=75
	width_inlinatum=178
	width_stropha=169
	width_inclinatum_deminutus=112
	width_flexusdeminutus=161
	porrectusflexuswidths=(340,428,586,670,931)
	porrectuswidths=(490,575,650,740,931)
	hepisemus_additional_width=40

# a function called at the beginning of the script, that opens the font
def headers():
    fout.write("#!/usr/local/bin/fontforge\n\nPrint(\"Creating all square notation symbols for the %s font.\\nThis may take several minutes.\");\nOpen(\"%s-base.sfd\");\n" % (font_name, font_name))

# the function that deletes the temporary glyphs and saves the modified font, called at the end

def footers():
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
    fout.write("SetFontNames(\"%s-%d\");\n" % (font_name, current_font_number))
    # 66537 is for generating an afm and a tfm file
    fout.write("Generate(\"%s-%d.pfb\",\"\",66537);\n" % (font_name,current_font_number))
    # uncomment the next line if you want to generate sfd files (easier to debug)
    fout.write("Save(\"%s-%d.sfd\");\n" % (font_name, current_font_number))
    fout.write("Close();\n")
    fout.write("Open(\"%s-base.sfd\");\n" % font_name)
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
    glyphnumber=k+(5*j)+(25*i)+(256*liquescentiae[liquescentia])+(2048*shapes[shape])
    return "_%d" % (glyphnumber)

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
    if (i!=1):
	linename= "line%d" % i 
	paste_and_move(linename, glyphname, length, height)    

# a function to write the first bar of a glyph. Used for porrectus flexus, porrectus and flexus.

def write_first_bar(i, glyphname):
    paste_and_move("queue", glyphname, 0, (-i+1)*base_height)
    write_line(i, glyphname, 0, (-i+1)*base_height)

# as the glyph before a deminutus is not the same as a normal glyph, and always the same, we can call this function each time. Sometimes we have to simplify before building the last glyph (tosimplify=1), and length is the offset.

def write_deminutus(i, j, glyphname, length=0, tosimplify=0):
    paste_and_move("mdeminutus", glyphname, length, i*base_height)
    write_line(j, glyphname, length+width_flexusdeminutus-line_width, (i-j+1)*base_height)
    if (tosimplify):
	simplify()
    paste_and_move("deminutus", glyphname, length+width_flexusdeminutus-width_deminutus-line_width, (i-j)*base_height)

def hepisemus():
    message("horizontal episemus")
    write_hepisemus(width_punctum, "_0040")
    write_hepisemus(width_flexusdeminutus, "_0041")          
    write_hepisemus(width_debilis+line_width, "_0042")
    write_hepisemus(width_punctum, "_0043")
    write_hepisemus(width_inclinatum_deminutus, "_0044")
    write_hepisemus(width_punctum, "_0045")
    for i in range(max_interval):
	write_hepisemus(porrectuswidths[i], "_00%02d" % int(46+i))
    for i in range(max_interval):
	write_hepisemus(porrectusflexuswidths[i], "_00%02d" % int(51+i))
    
def write_hepisemus(shape_width, glyphname):
    begin_glyph(glyphname)
    simple_paste("hepisemus_base", glyphname)
    scale(shape_width + 2*hepisemus_additional_width, 1)
    move(-hepisemus_additional_width, 0)
    set_width(shape_width)
    end_glyph(glyphname)

def pes():
    message("pes")
    precise_message("pes")
    if (font_name=="gregorio" or font_name=="parmesan"):
    # we prefer drawing the pes with one ton of ambitus by hand, it is more beautiful
	for i in range(2,max_interval+1):
	    write_pes(i, "pbase", 'pes')
    else:
	for i in range(1,max_interval+1):
	    write_pes(i, "pbase", 'pes')
    # idem for the pes quilisma
    precise_message("pes quilisma")
    if (font_name=="gregorio" or font_name=="parmesan"):
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
    glyphname=name(0, 0, i, shape, liquescentia)
    begin_glyph(glyphname)
    # the difference of width of the two shapes, that will change a thing or two...
    if (first_glyph=="qbase"):
	width_difference=width_quilisma-width_punctum
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
    if (width_difference>0):
	paste_and_move("base2", glyphname, width_difference, 0)
    else:
	paste_and_move("base2", glyphname, 0, i*base_height)
    if (width_difference<0):
	set_width(width_punctum)
    else:
	set_width(width_quilisma)
    end_glyph(glyphname)    

def write_pes_debilis(i, shape, liquescentia='nothing'):
    glyphname=name(0, 0, i, shape, liquescentia)
    begin_glyph(glyphname)
    # with a deminutus it is much more beautiful than with a idebilis
    paste_and_move("deminutus", glyphname, width_punctum-line_width-width_debilis, 0)
    write_line(i, glyphname, width_punctum-line_width, base_height)
    simplify()
    paste_and_move("base2", glyphname, 0, i*base_height)
    set_width(width_punctum)
    end_glyph(glyphname) 

def write_pes_deminutus(i, first_glyph, shape, liquescentia='nothing'):
    glyphname=name(0, 0, i, shape, liquescentia)
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
    glyphname=name(0, 0, i, shape, liquescentia)
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
	write_pes_quadratum(i, "base5", "vbase", 'pesquadratum')
    precise_message("pes quassus")
    for i in range(1,max_interval+1):
	write_pes_quadratum(i, "obase", "vbase", 'pesquassus')
    precise_message("pes quilisma quadratum")
    for i in range(1,max_interval+1):
	write_pes_quadratum(i, "qbase", "vbase", 'pesquilismaquadratum')
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
    glyphname=name(0, 0, i, shape, liquescentia)
    begin_glyph(glyphname)
    simple_paste(first_glyph, glyphname)
    if (first_glyph=="idebilis"):
	first_width=width_deminutus
    elif (first_glyph=="base5"):
	first_width=width_punctum-line_width
    elif(first_glyph=="obase"):
	first_width=width_oriscus-line_width
    else:
	first_width=width_quilisma-line_width
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
	write_flexus(i, "vsbase", 'base7', 'flexus')
    for i in range(1,max_interval+1):
	write_flexus(i, "vlbase", 'base7', 'flexus_longqueue')
    precise_message("flexus deminutus")
    for i in range(1,max_interval+1):
	write_flexus(i, "mdeminutus", 'base7', 'flexus', 'deminutus')
    for i in range(1,max_interval+1):
	write_flexus(i, "mdeminutus", 'base7', 'flexus_longqueue', 'deminutus')
    precise_message("flexus auctus ascendens")
    for i in range(1,max_interval+1):
	write_flexus(i, "base2", 'auctusa1', 'flexus_nobar', 'auctusascendens')
    for i in range(1,max_interval+1):
	write_flexus(i, "vsbase", 'auctusa1', 'flexus', 'auctusascendens')
    for i in range(1,max_interval+1):
	write_flexus(i, "vlbase", 'auctusa1', 'flexus_longqueue', 'auctusascendens')
    precise_message("flexus auctus descendens")
    for i in range(1,max_interval+1):
	write_flexus(i, "base2", 'auctusd1', 'flexus_nobar', 'auctusdescendens')
    for i in range(1,max_interval+1):
	write_flexus(i, "vsbase", 'auctusd1', 'flexus', 'auctusdescendens')
    for i in range(1,max_interval+1):
	write_flexus(i, "vlbase", 'auctusd1', 'flexus_longqueue', 'auctusdescendens')

def write_flexus(i, first_glyph, last_glyph, shape, liquescentia='nothing'):
    glyphname=name(0, 0, i, shape, liquescentia)
    begin_glyph(glyphname)
    # we add a queue if it is a deminutus
    if (first_glyph=="mdeminutus"):
	write_first_bar(i, glyphname)
	write_deminutus(0, i, glyphname, length=0, tosimplify=1)
	length=width_flexusdeminutus
    else:
	simple_paste(first_glyph, glyphname)
	length=width_punctum-line_width
	write_line(i, glyphname, length, (1-i)*base_height)
	paste_and_move(last_glyph, glyphname, length, (-i)*base_height)
	length=2*width_punctum-line_width
    set_width(length)
    end_glyph(glyphname)

def porrectus():
    message("porrectus")
    precise_message("porrectus")
    for i in range(1,max_interval+1):
	for j in range(1,max_interval+1):
	   write_porrectus(i,j, "base2", 1, 'porrectus')
    for i in range(1,max_interval+1):
	for j in range(1,max_interval+1):
	   write_porrectus(i,j, "base2", 0, 'porrectus_nobar')
    precise_message("porrectus deminutus")
    for i in range(1,max_interval+1):
	for j in range(1,max_interval+1):
	   write_porrectus(i,j, "rdeminutus", 1, 'porrectus', 'deminutus')
    for i in range(1,max_interval+1):
	for j in range(1,max_interval+1):
	   write_porrectus(i,j, "rdeminutus", 0, 'porrectus_nobar', 'deminutus')


def write_porrectus(i,j, last_glyph, with_bar, shape, liquescentia='nothing'):
    glyphname=name(0, i, j, shape, liquescentia)
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
	paste_and_move(last_glyph, glyphname, (length-width_punctum), (j-i)*base_height)
    set_width(length)
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
    first_glyph="porrectusflexus%d" % i
    if (with_bar):
	write_first_bar(i, glyphname)
    simple_paste(first_glyph, glyphname)
    write_line(j, glyphname, length-line_width, (-i+1)*base_height)
    if (last_glyph=="deminutus"):
	write_deminutus(j-i,k,glyphname, length-line_width,with_bar)
	length=length+width_flexusdeminutus-line_width
    else:
	simplify()
	paste_and_move("base3", glyphname, (length-line_width), (j-i)*base_height)
	write_line(k, glyphname, length+width_punctum - 2*line_width, (j-i-k+1)*base_height)
	paste_and_move(last_glyph, glyphname, (length+width_punctum - 2*line_width), (j-i-k)*base_height)
	length=length+2*width_punctum - 2*line_width
    set_width(length)
    end_glyph(glyphname)

def torculus():
    message("torculus")
    precise_message("torculus")
    for i in range(1,max_interval+1):
	for j in range(1,max_interval+1):
	    write_torculus(i,j, "base5", "base7", 'torculus')
    precise_message("torculus initio debilis")
    for i in range(1,max_interval+1):
	for j in range(1,max_interval+1):
	    write_torculus(i,j, "idebilis", "base7", 'torculus', 'initiodebilis')
    precise_message("torculus auctus descendens")
    for i in range(1,max_interval+1):
	for j in range(1,max_interval+1):
	    write_torculus(i,j, "base5", "auctusd1", 'torculus', 'auctusdescendens')
    precise_message("torculus initio debilis auctus descendens")
    for i in range(1,max_interval+1):
	for j in range(1,max_interval+1):
	    write_torculus(i,j, "idebilis", "auctusd1", 'torculus', 'initiodebilisauctusdescendens')
    precise_message("torculus auctus ascendens")
    for i in range(1,max_interval+1):
	for j in range(1,max_interval+1):
	    write_torculus(i,j, "base5", "auctusa1", 'torculus', 'auctusascendens')
    precise_message("torculus initio debilis auctus ascendens")
    for i in range(1,max_interval+1):
	for j in range(1,max_interval+1):
	    write_torculus(i,j, "idebilis", "auctusa1", 'torculus', 'initiodebilisauctusascendens')
    precise_message("torculus deminutus")
    for i in range(1,max_interval+1):
	for j in range(1,max_interval+1):
	    write_torculus(i,j, "base5", "deminutus", 'torculus', 'deminutus')
    precise_message("torculus initio debilis deminutus")
    for i in range(1,max_interval+1):
	for j in range(1,max_interval+1):
	    write_torculus(i,j, "idebilis", "deminutus", 'torculus', 'initiodebilisdeminutus')

def write_torculus(i,j, first_glyph, last_glyph, shape, liquescentia='nothing'):
    glyphname=name(0, i, j, shape, liquescentia)
    begin_glyph(glyphname)
    length=width_punctum-line_width
    if (first_glyph=="idebilis"):
	length=width_debilis
    simple_paste(first_glyph, glyphname)
    write_line(i, glyphname, length, base_height)
    if (last_glyph=="deminutus"):
	write_deminutus(i,j,glyphname, length)
	length=length+width_flexusdeminutus
    else:
        paste_and_move("base3", glyphname, length, i*base_height)
	length=length+width_punctum-line_width
	write_line(j, glyphname, length, (i-j+1)*base_height)
	paste_and_move(last_glyph, glyphname,  length, (i-j)*base_height)
        length=length+width_punctum
    set_width(length)
    end_glyph(glyphname)

if __name__ == "__main__":
    main()
