#!/usr/bin/python

#Python fontforge script to build a square notation font.
#Copyright (C) 2007 Elie Roux
#
#This program is free software; you can redistribute it and/or
#modify it under the terms of the GNU General Public License
#as published by the Free Software Foundation; either version 2
#of the License, or (at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, write to the Free Software
#Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#This script takes a very simple .sfd file with a few symbols and builds a|
#complete square notation font.
#
#This python script generates a fontforge native script (.pe). In the future, 
#python will also work (better that .pe) to control fontforge with scripts, but
#it is not yet implemented. the .pe script will build a new font, called 
#gregorio-final.sfd which will have all the glyphs of a square notation.
#
#To build you own font, look at gregorio-base.sfd, and build you own glyphs from
#it.
#
#Basic use :
# ./sqarize.py
# chmod +x squarize.pe
# ./squarize.pe
# the last step may take a few minutes

# the file we are going to write in
fout=open("squarize.pe", 'w')

# the base height is half the space between two lines plus half the heigth of a line
base_height=157.5

# some length, necessary to know where to draw lines, squares, etc.
line_length=22
base_length=164
length1=142
length2=120
length_debilis=88
length_deminutus=88
length_bfdeminutus=197
torculusresupinuslengths=(340,428,586,670,931)
porrectuslengths=(490,575,650,740,931)

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

toremove=['base2', 'base3', 'base4', 'base5', 'base6', 'base7', 'line2', 'line3', 'line4', 'line5', 'pesdeminutus', 'mdeminutus', 'auctusa1', 'auctusa2', 'auctusd1', 'auctusd2', 'queue', 'idebilis', 'deminutus', 'rdeminutus', 'obase', 'qbase', 'pbase', 'porrectus1', 'porrectus2', 'porrectus3', 'porrectus4', 'porrectus5', 'porrectusflexus1', 'porrectusflexus2', 'porrectusflexus3', 'porrectusflexus4', 'porrectusflexus5', 'vsbase', 'vbase', 'vlbase']

# in the police, all the free glyphs have the name NameMexxxx where xxxx is a number starting from 140 and increasing by one. For example each new glyph will be basically NameMecount, the next NameMecount+1, etc.
count=139

# initial glyphs are the names of the glyphs that are already in gregorio_base, mostly one-note glyphs.
initial_glyphs=[1,2,17,19,20,26,27,28,6,32,11,8,23,25,9,10,24,7,4,30,3,29,21,31,22,14,15,33]
def initialize_glyphs():
    global initial_glyphs
    for number in initial_glyphs:
	toto="_00%02d" % int(number)
	initial_glyphs.insert(0,toto)
	initial_glyphs.remove(number)
    initial_glyphs.append("_1025")

# we must cut the final font into small fonts of 255 characters, so each 255 characters we save the font into a new gregorio-x font, where x is an integer starting from 0
current_font_number=0
#current glyph will count the number of glyphs in the current small font. As the glyphs that are in gregorio-base will be kept only in gregorio-0, we initialize it with the number of these glyphs (in the main function)
current_glyph_number=0

# a function called at the beginning of the script, that opens the font

def headers():
    fout.write("#!/usr/local/bin/fontforge\n\nOpen(\"gregorio-base.sfd\");\n")

# the function that deletes the temporary glyphs and saves the modified font, called at the end

def footers():
    fout.write("Save(\"gregorio-%d.sfd\");\n" % current_font_number)
    fout.write("Quit(0);\n")

# function called when we are at the 255th glyph of a font, we start a new one.
def end_font():
    global current_glyph_number
    global current_font_number
    global count
    for glyph in toremove:
        fout.write("Select(\"%s\");\n" % glyph)
	fout.write("Clear();\n")
    if (current_font_number!=0):
	for glyph in initial_glyphs:
            fout.write("Select(\"%s\");\n" % glyph)
	    fout.write("Clear();\n")
    else:
	# we suppress empty glyphs
	for i in range(395-len(initial_glyphs),395):
	    fout.write("Select(\"NameMe.%d\");\n" % i)
	    fout.write("Clear();\n")	
    fout.write("Reencode(\"compacted\");\n")
    fout.write("Reencode(\"original\",1);\n")
    # 66537 is for generating an afm and a tfm file
    fout.write("Generate(\"gregorio-%d.pfb\",\"\",66537);\n" % current_font_number)
    #fout.write("Save(\"gregorio-%d.sfd\");\n" % current_font_number)
    fout.write("Close();\n")
    fout.write("Open(\"gregorio-base.sfd\");\n")
    current_glyph_number=0
    current_font_number=current_font_number+1
    count=139

# function called at the end of the modification of a glyph, it simplifies it and removes the overlap, so at the end we have the glyph that we want.

def end_glyph(glyphname):
    global current_glyph_number
    fout.write("Simplify();\n")
    fout.write("Simplify();\n")
    fout.write("RemoveOverlap();\n")
    fout.write("Simplify();\n")
    fout.write("CanonicalContours();\n")
    fout.write("CanonicalStart();\n")
    fout.write("%i\n" % current_glyph_number)
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

def main():
    global fout
    global current_glyph_number
    initialize_glyphs()
    current_glyph_number=len(initial_glyphs)
    headers()
    pes()
    pes_quadratum()
    porrectus()
    flexus()
    porrectusflexus()
    torculus()
    footers()
    fout.close()

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
    write_line(j, glyphname, length+length_bfdeminutus-line_length, (i-j+1)*base_height)
    if (tosimplify):
	simplify()
    paste_and_move("deminutus", glyphname, length+length_bfdeminutus-length_deminutus-line_length, (i-j)*base_height)

def pes():
    for i in range(1,6):
	write_pes(i, "pbase", 'pes')
#   with our glyphs, the quilisma pes with notes with only one ton of ambitus is ugly, we must draw it by hand
    for i in range(2,6):
	write_pes(i, "qbase", 'pesquilisma')
    for i in range(1,6):
	write_pes_deminutus(i, "pesdeminutus", 'pes', 'deminutus')
    for i in range(1,6):
	write_pes_debilis(i, 'pes', 'initiodebilis')

def write_pes(i, first_glyph, shape, liquescentia='nothing'):
    glyphname=name(0, 0, i, shape, liquescentia)
    begin_glyph(glyphname)
    simple_paste(first_glyph, glyphname)
    write_line(i, glyphname, length1, base_height)
    paste_and_move("base2", glyphname, 0, i*base_height)
    set_width(base_length)
    end_glyph(glyphname)    

def write_pes_debilis(i, shape, liquescentia='nothing'):
    glyphname=name(0, 0, i, shape, liquescentia)
    begin_glyph(glyphname)
    # with a deminutus it is much more beautiful than with a idebilis
    paste_and_move("deminutus", glyphname, length1-length_debilis, 0)
    write_line(i, glyphname, length1, base_height)
    simplify()
    paste_and_move("base2", glyphname, 0, i*base_height)
    set_width(base_length)
    end_glyph(glyphname) 

def write_pes_deminutus(i, first_glyph, shape, liquescentia='nothing'):
    glyphname=name(0, 0, i, shape, liquescentia)
    begin_glyph(glyphname)
    simple_paste(first_glyph, glyphname)
    write_line(i, glyphname, length1, base_height)
    paste_and_move("rdeminutus", glyphname, length1-length_deminutus, i*base_height)
    set_width(base_length)
    end_glyph(glyphname)

def pes_quadratum():
    for i in range(1,6):
	write_pes_quadratum(i, "base5", "vbase", 'pesquadratum')
    for i in range(1,6):
	write_pes_quadratum(i, "obase", "vbase", 'pesquassus')
    for i in range(1,6):
	write_pes_quadratum(i, "qbase", "vbase", 'pesquilismaquadratum')
    for i in range(1,6):
	write_pes_quadratum(i, "base5", "auctusa2", 'pesquadratum', 'auctusascendens')
    for i in range(1,6):
	write_pes_quadratum(i, "obase", "auctusa2", 'pesquassus', 'auctusascendens')
    for i in range(1,6):
	write_pes_quadratum(i, "qbase", "auctusa2", 'pesquilismaquadratum', 'auctusascendens')
    for i in range(1,6):
	write_pes_quadratum(i, "base5", "auctusd2", 'pesquadratum', 'auctusdescendens')
    for i in range(1,6):
	write_pes_quadratum(i, "obase", "auctusd2", 'pesquassus', 'auctusdescendens')
    for i in range(1,6):
	write_pes_quadratum(i, "qbase", "auctusd2", 'pesquilismaquadratum', 'auctusdescendens')

def write_pes_quadratum(i, first_glyph, last_glyph, shape, liquescentia='nothing'):
    glyphname=name(0, 0, i, shape, liquescentia)
    begin_glyph(glyphname)
    simple_paste(first_glyph, glyphname)
    if (i!=1):
	linename= "line%d" % i 
	paste_and_move(linename, glyphname, length1, base_height)
    paste_and_move(last_glyph, glyphname, length1, i*base_height)
    set_width(base_length+length1)
    end_glyph(glyphname)    

def flexus():
    for i in range(1,6):
	write_flexus(i, "base2", 'base7', 'flexus_nobar')
    for i in range(1,6):
	write_flexus(i, "vsbase", 'base7', 'flexus')
    for i in range(1,6):
	write_flexus(i, "vlbase", 'base7', 'flexus_longqueue')
    for i in range(1,6):
	write_flexus(i, "mdeminutus", 'base7', 'flexus', 'deminutus')
    for i in range(1,6):
	write_flexus(i, "base2", 'auctusa1', 'flexus_nobar', 'auctusascendens')
    for i in range(1,6):
	write_flexus(i, "vsbase", 'auctusa1', 'flexus', 'auctusascendens')
    for i in range(1,6):
	write_flexus(i, "vlbase", 'auctusa1', 'flexus_longqueue', 'auctusascendens')
    for i in range(1,6):
	write_flexus(i, "base2", 'auctusd1', 'flexus_nobar', 'auctusdescendens')
    for i in range(1,6):
	write_flexus(i, "vsbase", 'auctusd1', 'flexus', 'auctusdescendens')
    for i in range(1,6):
	write_flexus(i, "vlbase", 'auctusd1', 'flexus_longqueue', 'auctusdescendens')

def write_flexus(i, first_glyph, last_glyph, shape, liquescentia='nothing'):
    glyphname=name(0, 0, i, shape, liquescentia)
    begin_glyph(glyphname)
    # we add a queue if it is a deminutus
    if (first_glyph=="mdeminutus"):
	write_first_bar(i, glyphname)
	write_deminutus(0, i, glyphname, length=0, tosimplify=1)
	length=length_bfdeminutus
    else:
	simple_paste(first_glyph, glyphname)
	length=length1
	write_line(i, glyphname, length, (1-i)*base_height)
	paste_and_move(last_glyph, glyphname, length, (-i)*base_height)
	length=length1+base_length
    set_width(length)
    end_glyph(glyphname)

def porrectus():
    for i in range(1,6):
	for j in range(1,6):
	   write_porrectus(i,j, "base2", 0, 'porrectus')
    for i in range(1,6):
	for j in range(1,6):
	   write_porrectus(i,j, "rdeminutus", 0, 'porrectus', 'deminutus')
    for i in range(1,6):
	for j in range(1,6):
	   write_porrectus(i,j, "base2", 1, 'porrectus_nobar')
    for i in range(1,6):
	for j in range(1,6):
	   write_porrectus(i,j, "rdeminutus", 1, 'porrectus_nobar', 'deminutus')


def write_porrectus(i,j, last_glyph, with_bar, shape, liquescentia='nothing'):
    glyphname=name(0, i, j, shape, liquescentia)
    begin_glyph(glyphname)
    length=porrectuslengths[i-1]
    if (with_bar):
	write_first_bar(i, glyphname)
    first_glyph="porrectus%d" % i
    simple_paste(first_glyph, glyphname)
    write_line(j, glyphname, length-line_length, (-i+1)*base_height)
    if (with_bar):
	simplify()
    if (last_glyph=="rdeminutus"):
	paste_and_move(last_glyph, glyphname, (length-length_deminutus-line_length), (j-i)*base_height)
    else:
	paste_and_move(last_glyph, glyphname, (length-base_length), (j-i)*base_height)
    set_width(length)
    end_glyph(glyphname)

def porrectusflexus():
    for i in range(1,6):
	for j in range(1,6):
	    for k in range(1,6):
		write_porrectusflexus(i,j,k, "base7", 0, 'porrectusflexus_nobar')
    for i in range(1,6):
	for j in range(1,6):
	    for k in range(1,6):
		write_porrectusflexus(i,j,k, "auctusd1", 0, 'porrectusflexus_nobar', 'auctusdescendens')
    for i in range(1,6):
	for j in range(1,6):
	    for k in range(1,6):
		write_porrectusflexus(i,j,k, "auctusa1", 0, 'porrectusflexus_nobar', 'auctusascendens')
    for i in range(1,6):
	for j in range(1,6):
	    for k in range(1,6):
		write_porrectusflexus(i,j,k, "deminutus", 0, 'porrectusflexus_nobar', 'deminutus')
    for i in range(1,6):
	for j in range(1,6):
	    for k in range(1,6):
		write_porrectusflexus(i,j,k, "base7", 1, 'porrectusflexus')
    for i in range(1,6):
	for j in range(1,6):
	    for k in range(1,6):
		write_porrectusflexus(i,j,k, "auctusd1", 1, 'porrectusflexus_nobar', 'auctusdescendens')
    for i in range(1,6):
	for j in range(1,6):
	    for k in range(1,6):
		write_porrectusflexus(i,j,k, "auctusa1", 1, 'porrectusflexus', 'auctusascendens')
    for i in range(1,6):
	for j in range(1,6):
	    for k in range(1,6):
		write_porrectusflexus(i,j,k, "deminutus", 1, 'porrectusflexus', 'deminutus')

def write_porrectusflexus(i,j,k, last_glyph, with_bar, shape, liquescentia='nothing'):
    glyphname=name(i, j, k, shape, liquescentia)
    begin_glyph(glyphname)
    length=torculusresupinuslengths[i-1]
    first_glyph="porrectusflexus%d" % i
    if (with_bar):
	write_first_bar(i, glyphname)
    simple_paste(first_glyph, glyphname)
    write_line(j, glyphname, length-line_length, (-i+1)*base_height)
    if (last_glyph=="deminutus"):
	write_deminutus(j-i,k,glyphname, length-line_length,with_bar)
	length=length+length_bfdeminutus-line_length
    else:
	simplify()
	paste_and_move("base3", glyphname, (length-line_length), (j-i)*base_height)
	write_line(k, glyphname, length+length2, (j-i-k+1)*base_height)
	paste_and_move(last_glyph, glyphname, (length+length2), (j-i-k)*base_height)
	length=length+length2+base_length
    set_width(length)
    end_glyph(glyphname)

def torculus():
    for i in range(1,6):
	for j in range(1,6):
	    write_torculus(i,j, "base5", "base7", 'torculus')
    for i in range(1,6):
	for j in range(1,6):
	    write_torculus(i,j, "idebilis", "base7", 'torculus', 'initiodebilis')
    for i in range(1,6):
	for j in range(1,6):
	    write_torculus(i,j, "base5", "auctusd1", 'torculus', 'auctusdescendens')
    for i in range(1,6):
	for j in range(1,6):
	    write_torculus(i,j, "idebilis", "auctusd1", 'torculus', 'initiodebilisauctusdescendens')
    for i in range(1,6):
	for j in range(1,6):
	    write_torculus(i,j, "base5", "auctusa1", 'torculus', 'auctusascendens')
    for i in range(1,6):
	for j in range(1,6):
	    write_torculus(i,j, "idebilis", "auctusa1", 'torculus', 'initiodebilisauctusascendens')
    for i in range(1,6):
	for j in range(1,6):
	    write_torculus(i,j, "base5", "deminutus", 'torculus', 'deminutus')
    for i in range(1,6):
	for j in range(1,6):
	    write_torculus(i,j, "idebilis", "deminutus", 'torculus', 'initiodebilisdeminutus')

def write_torculus(i,j, first_glyph, last_glyph, shape, liquescentia='nothing'):
    glyphname=name(0, i, j, shape, liquescentia)
    begin_glyph(glyphname)
    length=length1
    if (first_glyph=="idebilis"):
	length=length_debilis
    simple_paste(first_glyph, glyphname)
    write_line(i, glyphname, length, base_height)
    if (last_glyph=="deminutus"):
	write_deminutus(i,j,glyphname, length)
	length=length+length_bfdeminutus
    else:
        paste_and_move("base3", glyphname, length, i*base_height)
	length=length+length1
	write_line(j, glyphname, length, (i-j+1)*base_height)
	paste_and_move(last_glyph, glyphname,  length, (i-j)*base_height)
        length=length+base_length
    set_width(length)
    end_glyph(glyphname)

main()
