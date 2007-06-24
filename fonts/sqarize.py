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

numbers={'pes':2,
'pesdeminutus':6,
'pesauctusascendens':4,
'pesauctusdescendens':5,
'pesinitiodebilis':3,
'pesinitiodebilisauctusascendens':7,
'pesinitiodebilisauctusdescendens':8,
'pesquadratum':10,
'pesquassus':11,
'pesquilisma':12,
#'':,
}

# a list of temporary glyphs, that must be removed from the finame font

toremove=['base2', 'base3', 'base4', 'base5', 'base6', 'base7', 'line2', 'line3', 'line4', 'line5', 'pesdebilis', 'mdeminutus', 'auctusa1', 'auctusa2', 'auctusd1', 'auctusd2', 'queue', 'idebilis', 'deminutus', 'rdeminutus', 'obase', 'qbase', 'pbase', 'porrectus1', 'porrectus2', 'porrectus3', 'porrectus4', 'porrectus5', 'porrectusflexus1', 'porrectusflexus2', 'porrectusflexus3', 'porrectusflexus4', 'porrectusflexus5', 'vsbase', 'vbase', 'vlbase']

# in the police, all the free glyphs have the name NameMexxxx where xxxx is a number starting from 140 and increasing by one. For example each new glyph will be basically NameMecount, the next NameMecount+1, etc.
count=140

# a function called at the beginning of the script, that opens the font

def headers():
    print """#!/usr/local/bin/fontforge

Open("gregorio-base.sfd");"""

# the function that deletes the temporary glyphs and saves the modified font, called at the end

def footers():
    for glyph in toremove:
        print "Select(\"%s\");" % glyph
	print "Clear();"
    print """Save("gregorio-final.sfd");
Quit(0);"""

# function called at the end of the modification of a glyph, it simplifies it and removes the overlap, so at the end we have the glyph that we want.

def end_glyph(glyphname):
    print "Simplify();"
    print "Simplify();"
    print "RemoveOverlap();"
    print "Simplify();"

# function called to initialize a glyph for modification

def begin_glyph(glyphname):
    global count
    print "Select(\"NameMe.%i\");" % count
    print "SetGlyphName(\"%s\");" % glyphname
    count=count+1

# function to set the width of a glyph

def set_width(width):
    print "SetWidth(%d);" % width

# function to get the name of the glyph, with the name of the general shape, and the name of the different ambitus

def name(glyphnum, i, j, k):
    return "%i%i%i%i" % (glyphnum, i, j, k)

# function that simply pastes the src glyph into dst glyph, without moving it

def simple_paste(src, dst):
    print "Select(\"%s\");" % src
    print "Copy();"
    print "Select(\"%s\");" % dst
    print "PasteInto();" 

# function that pastes the src glyph into dst, and moves it with horiz and vert offsets

def paste_and_move(src, dst, horiz, vert):
    print "Select(\"%s\");" % src
    print "Copy();"
    print "Select(\"%s\");" % dst
    print "PasteWithOffset(%.2f, %.2f);" % (horiz, vert)

# the simplify function of fontforge is quite strange, and sometimes doesn't work well if we call it at the end of a glyph modification, so in some case we have to call this function in the middle of a determination.

def simplify():
    print "Simplify();"
    print "RemoveOverlap();"
    print "Simplify();"

def main():
    headers()
    pes()
    footers()

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
	write_pes(i, "pbase", 1)
#   with our glyphs, the quilisma pes with notes with only one ton of ambitus is ugly, we must draw it by hand
    for i in range(2,6):
	write_pes(i, "qbase", 2)
    for i in range(1,6):
	write_pes_deminutus(i, "pesdebilis", 89)
    for i in range(1,6):
	write_pes_debilis(i, 89)

def write_pes(i, first_glyph, glyph_number):
    glyphname=name(glyph_number, 0, 0, i)
    begin_glyph(glyphname)
    simple_paste(first_glyph, glyphname)
    write_line(i, glyphname, length1, base_height)
    paste_and_move("base2", glyphname, 0, i*base_height)
    set_width(base_length)
    end_glyph(glyphname)    

def write_pes_debilis(i, glyph_number):
    glyphname=name(glyph_number, 0, 0, i)
    begin_glyph(glyphname)
    # with a deminutus it is much more beautiful than with a idebilis
    paste_and_move("deminutus", glyphname, length1-length_debilis, 0)
    write_line(i, glyphname, length1, base_height)
    simplify()
    paste_and_move("base2", glyphname, 0, i*base_height)
    set_width(base_length)
    end_glyph(glyphname) 

def write_pes_deminutus(i, first_glyph, glyph_number):
    glyphname=name(glyph_number, 0, 0, i)
    begin_glyph(glyphname)
    simple_paste(first_glyph, glyphname)
    write_line(i, glyphname, length1, base_height)
    paste_and_move("rdeminutus", glyphname, length1-length_deminutus, i*base_height)
    set_width(base_length)
    end_glyph(glyphname)

def pes_quadratum():
    for i in range(1,6):
	write_pes_quadratum(i, "base5", "vbase", 3)
    for i in range(1,6):
	write_pes_quadratum(i, "obase", "vbase", 4)
    for i in range(1,6):
	write_pes_quadratum(i, "qbase", "vbase", 78)
    for i in range(1,6):
	write_pes_quadratum(i, "base5", "auctusa2", 79)
    for i in range(1,6):
	write_pes_quadratum(i, "obase", "auctusa2", 80)
    for i in range(1,6):
	write_pes_quadratum(i, "qbase", "auctusa2", 81)
    for i in range(1,6):
	write_pes_quadratum(i, "base5", "auctusd2", 82)
    for i in range(1,6):
	write_pes_quadratum(i, "obase", "auctusd2", 83)
    for i in range(1,6):
	write_pes_quadratum(i, "qbase", "auctusd2", 83)

def write_pes_quadratum(i, first_glyph, last_glyph, glyph_number):
    glyphname=name(glyph_number, 0, 0, i)
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
	write_flexus(i, "base2", 17)
    for i in range(1,6):
	write_flexus(i, "vsbase", 18)
    for i in range(1,6):
	write_flexus(i, "vlbase", 19)
    for i in range(1,6):
	write_flexus(i, "mdeminutus", 520)

def write_flexus(i, first_glyph, glyph_number):
    glyphname=name(glyph_number, 0, 0, i)
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
	paste_and_move("base7", glyphname, length, (-i)*base_height)
	length=length1+base_length
    set_width(length)
    end_glyph(glyphname)

def porrectus():
#    for i in range(1,6):
#	for j in range(1,6):
#	   write_porrectus(i,j, 105, "base2", 0)
#    for i in range(1,6):
#	for j in range(1,6):
#	   write_porrectus(i,j, 106, "rdeminutus", 0)
    for i in range(1,6):
	for j in range(1,6):
	   write_porrectus(i,j, 107, "base2", 1)
#    for i in range(1,6):
#	for j in range(1,6):
#	   write_porrectus(i,j, 108, "rdeminutus", 1)


def write_porrectus(i,j, glyphnumber, last_glyph, with_bar=0):
    glyphname=name(glyphnumber, 0, i, j)
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
#    for i in range(1,6):
#	for j in range(1,6):
#	    for k in range(1,6):
#		write_porrectusflexus(i,j,k, 120, "base2", 0)
#    for i in range(1,6):
#	for j in range(1,6):
#	    for k in range(1,6):
#		write_porrectusflexus(i,j,k, 120, "auctusd1", 0)
#    for i in range(1,6):
#	for j in range(1,6):
#	    for k in range(1,6):
#		write_porrectusflexus(i,j,k, 120, "auctusa1", 0)
#    for i in range(1,6):
#	for j in range(1,6):
#	    for k in range(1,6):
#		write_porrectusflexus(i,j,k, 120, "deminutus", 0)
#    for i in range(1,6):
#	for j in range(1,6):
#	    for k in range(1,6):
#		write_porrectusflexus(i,j,k, 120, "base2", 1)
#    for i in range(1,6):
#	for j in range(1,6):
#	    for k in range(1,6):
#		write_porrectusflexus(i,j,k, 120, "auctusd1", 1)
    for i in range(1,6):
	for j in range(1,6):
	    for k in range(1,6):
		write_porrectusflexus(i,j,k, 120, "auctusa1", 1)
#    for i in range(1,6):
#	for j in range(1,6):
#	    for k in range(1,6):
#		write_porrectusflexus(i,j,k, 120, "deminutus", 1)

def write_porrectusflexus(i,j,k, glyphnumber, last_glyph, with_bar=0):
    glyphname=name(glyphnumber, 0, i, j)
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
	    write_torculus(i,j, "base5", "base7", 16)
    for i in range(1,6):
	for j in range(1,6):
	    write_torculus(i,j, "idebilis", "base7", 58)
    for i in range(1,6):
	for j in range(1,6):
	    write_torculus(i,j, "base5", "auctusd1", 59)
    for i in range(1,6):
	for j in range(1,6):
	    write_torculus(i,j, "idebilis", "auctusd1", 60)
    for i in range(1,6):
	for j in range(1,6):
	    write_torculus(i,j, "base5", "auctusa1", 60)
    for i in range(1,6):
	for j in range(1,6):
	    write_torculus(i,j, "idebilis", "auctusa1", 62)
    for i in range(1,6):
	for j in range(1,6):
	    write_torculus(i,j, "base5", "deminutus", 63)
    for i in range(1,6):
	for j in range(1,6):
	    write_torculus(i,j, "idebilis", "deminutus", 64)

def write_torculus(i,j, first_glyph, last_glyph, glyph_number):
    glyphname=name(glyph_number, 0, i, j)
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
