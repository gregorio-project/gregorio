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
#it is not yet implemented.


#here we define the basic shapes, that is to say shapes that we will combine to build all the glyphs, they are seven plus the special shapes for the porrectus

# 
# | |   = 1
# |_|
#

#  ______
# |      |
# |      |   = 2
# |____  |
#

#  ______
# |      |
# |      |   = 3
# |  __  |
#


#  ______
# |      |
# |      |   = 4
# |  ____|
#


#  ____
# |      |
# |      |   = 5
# |______|
#


#    __
# |      |
# |      |   = 6
# |______|
#

#    ____
# |      |
# |      |   = 7
# |______|
#


line_length=22
base_length=164
length1=142
length2=120
length_debilis=88
length_deminutus=88
length_bfdeminutus=197

count=140

#base_height=78.75
base_height=157.5

def headers():
    print """#!/usr/local/bin/fontforge

Open("gregorio-base.sfd");"""

def footers():
    print """Save("gregorio-final.sfd");
Quit(0);"""

def pes():
    for i in range(1,6):
	write_pes(i, "pbase", 1)
    for i in range(1,6):
	write_pes(i, "qbase", 2)
    for i in range(1,6):
	write_pes_debilis(i, "pesdebilis", 89)

def write_pes(i, first_glyph, glyph_number):
    glyphname=name(glyph_number, 0, 0, i)
    begin_glyph(glyphname)
    simple_paste(first_glyph, glyphname)
    if (i!=1):
	linename= "line%d" % i 
	paste_and_move(linename, glyphname, length1, base_height)
    paste_and_move("base2", glyphname, 0, i*base_height)
    set_width(base_length)
    end_glyph(glyphname)    

def write_pes_debilis(i, first_glyph, glyph_number):
    glyphname=name(glyph_number, 0, 0, i)
    begin_glyph(glyphname)
    simple_paste(first_glyph, glyphname)
    if (i!=1):
	linename= "line%d" % i 
	paste_and_move(linename, glyphname, length1, base_height)
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
        paste_and_move("queue", glyphname, 0, (-i+1)*base_height)
        if (i>1):
	    linename= "line%d" % i
	    paste_and_move(linename, glyphname, 0, (-i+1)*base_height)
	write_deminutus(0, i, glyphname, 0)
	length=length_bfdeminutus
    else:
	simple_paste(first_glyph, glyphname)
	length=length1
	if (i!=1):
	    linename= "line%d" % i 
	    paste_and_move(linename, glyphname, length, (1-i)*base_height)
	paste_and_move("base7", glyphname, length, (-i)*base_height)
	length=length1+base_length
    set_width(length)
    end_glyph(glyphname)

def write_deminutus(i, j, glyphname, length=0):
    paste_and_move("mdeminutus", glyphname, length, i*base_height)
    if (j>1):
	linename= "line%d" % j 
	paste_and_move(linename, glyphname, length+length_bfdeminutus-line_length, (i-j+1)*base_height)
    paste_and_move("deminutus", glyphname, length+length_bfdeminutus-length_deminutus-line_length, (i-j)*base_height)
    

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

porrectuslengths=(490,575,650,740,931)

def write_porrectus(i,j, glyphnumber, last_glyph, with_bar=0):
    glyphname=name(glyphnumber, 0, i, j)
    begin_glyph(glyphname)
    length=porrectuslengths[i-1]
    if (with_bar):
	paste_and_move("queue", glyphname, 0, (-i+1)*base_height)
	if (i>1):
	    linename= "line%d" % i
	    paste_and_move(linename, glyphname, 0, (-i+1)*base_height)
    first_glyph="porrectus%d" % i
    simple_paste(first_glyph, glyphname)
    if (j>1):
	linename= "line%d" % j 
	paste_and_move(linename, glyphname, length-line_length, (-i+1)*base_height)
    if (last_glyph=="rdeminutus"):
	paste_and_move(last_glyph, glyphname, (length-length_deminutus-line_length), (j-i)*base_height)
    else:
	paste_and_move(last_glyph, glyphname, (length-base_length), (j-i)*base_height)
    set_width(length)
    end_glyph(glyphname)

def torculusresupinus():
    for i in range(1,6):
	for j in range(1,6):
	    for k in range(1,6):
		write_torculusresupinus(i,j,k, 120, "base2", 0)

torculusresupinuslengths=(340,428,586,670,931)

def write_torculusresupinus(i,j,k, glyphnumber, last_glyph, with_bar=0):
    glyphname=name(glyphnumber, 0, i, j)
    begin_glyph(glyphname)
    length=torculusresupinuslengths[i-1]
    first_glyph="torculusresupinus%d" % i
    simple_paste(first_glyph, glyphname)
    if (j>1):
	linename= "line%d" % j 
	paste_and_move(linename, glyphname, length-line_length, (-i+1)*base_height)
    if (last_glyph=="rdeminutus"):
	paste_and_move(last_glyph, glyphname, (length-line_length), (j-i)*base_height)
    else:
	paste_and_move("base3", glyphname, (length-line_length), (j-i)*base_height)
    if (k>1):
	linename= "line%d" % k
	paste_and_move(linename, glyphname, (length+length2), (j-k-i+1)*base_height)
    if (last_glyph=="rdeminutus"):
	print "toto"
    else:
	paste_and_move("base7", glyphname, (length+length2), (j-i-k)*base_height)
    set_width(length+length2+base_length)
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
    if (i!=1):
	linename= "line%d" % i 
	paste_and_move(linename, glyphname, length, base_height)
    paste_and_move("base3", glyphname, length, i*base_height)
    if (j!=1):
	linename = "line%d" % j
	paste_and_move(linename, glyphname, length+length1, (i-j+1)*base_height)
    if (last_glyph=="deminutus"):
	last_length=line_length
	paste_and_move(last_glyph, glyphname,  length+length1-length_deminutus, (i-j)*base_height)
    else:
	last_length=base_length
	paste_and_move(last_glyph, glyphname,  length+length1, (i-j)*base_height)
    set_width(length+length1+last_length)
    end_glyph(glyphname)

def end_glyph(glyphname):
    print "Simplify();"
    print "Simplify();"
    print "RemoveOverlap();"
    print "Simplify();"

def begin_glyph(glyphname):
    global count
    print "Select(\"NameMe.%i\");" % count
    print "SetGlyphName(\"%s\");" % glyphname
    count=count+1

def set_width(width):
    print "SetWidth(%d);" % width

def name(glyphnum, i, j, k):
    return "%i%i%i%i" % (glyphnum, i, j, k)

def simple_paste(src, dst):
    print "Select(\"%s\");" % src
    print "Copy();"
    print "Select(\"%s\");" % dst
    print "PasteInto();" 

def paste_and_move(src, dst, horiz, vert):
    print "Select(\"%s\");" % src
    print "Copy();"
    print "Select(\"%s\");" % dst
    print "PasteWithOffset(%.2f, %.2f);" % (horiz, vert)

def main():
    headers()
    flexus()
    footers()

main()
