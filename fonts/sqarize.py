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


#global OUTPUT=sys.stdout
#here we define the basic shapes, that is to say shapes that we will combine to build all the glyphs, they are seven plus the special shapes for the porrectus

#global QUEUE=1

# 
# | |   = 1
# |_|
#

#global B_R=2 # for bottom right (the place of the hole(s))

#  ______
# |      |
# |      |   = 2
# |____  |
#

#global B_RL=3

#  ______
# |      |
# |      |   = 3
# |  __  |
#

#global B_L=4

#  ______
# |      |
# |      |   = 4
# |  ____|
#

#global T_R=R

#  ____
# |      |
# |      |   = 5
# |______|
#

#global T_RL=6

#    __
# |      |
# |      |   = 6
# |______|
#

#global T_L=7

#    ____
# |      |
# |      |   = 7
# |______|
#


#global ORISCUS=8
#global PORR=9
#global PORR_1=10
#global PORR_2=11
#global PORR_3=12
#global PORR_4=13
#global PORR_5=14

#length symbols
#global LINE_LENGTH 22
#global BASE_LENGTH=164
#global PORRECTUS_LENGTH_1=x
#global PORRECTUS_LENGTH_2=y
#global PORRECTUS_LENGTH_3=z
#global PORRECTUS_LENGTH_4=a
#global PORRECTUS_LENGTH_5=b


base_length=164
length1=142
length2=120
length_debilis=88

count=125

#base_height=78.75
base_height=157.5

def headers():
    print """#!/usr/local/bin/fontforge

Open("gregorio-test.sfd");"""

def footers():
    print """Save("gregorio-final.sfd");
Quit(0);"""

def pes():
    for i in range(5):
	write_pes(i+1, "pbase", 1)
    for i in range(5):
	write_pes(i+1, "qbase", 2)

def write_pes(i, first_glyph, glyph_number):
    glyphname=name(glyph_number, 0, 0, i)
    begin_glyph(glyphname)
    global length1
    global height1
    simple_paste(first_glyph, glyphname)
    if (i!=1):
	linename= "line%d" % i 
	paste_and_move(linename, glyphname, length1, base_height)
    paste_and_move("base2", glyphname, 0, i*base_height)
    set_width(base_length)
    end_glyph(glyphname)    

def pes_quadratum():
    for i in range(5):
	write_pes_quadratum(i+1, "base5", 3)
    for i in range(5):
	write_pes_quadratum(i+1, "obase", 4)

def write_pes_quadratum(i, first_glyph, glyph_number):
    glyphname=name(glyph_number, 0, 0, i)
    begin_glyph(glyphname)
    global length1
    global height1
    simple_paste(first_glyph, glyphname)
    if (i!=1):
	linename= "line%d" % i 
	paste_and_move(linename, glyphname, length1, base_height)
    paste_and_move("vbase", glyphname, length1, i*base_height)
    set_width(base_length)
    end_glyph(glyphname)    

def flexus():
    for i in range(5):
	write_flexus(i+1, "base2", 17)
    for i in range(5):
	write_flexus(i+1, "vsbase", 18)
    for i in range(5):
	write_flexus(i+1, "vlbase", 19)

def write_flexus(i, first_glyph, glyph_number):
    glyphname=name(glyph_number, 0, 0, i)
    begin_glyph(glyphname)
    global length1
    global height1
    simple_paste(first_glyph, glyphname)
    if (i!=1):
	linename= "line%d" % i 
	paste_and_move(linename, glyphname, length1, (1-i)*base_height)
    paste_and_move("base5", glyphname, length1, (-i)*base_height)
    set_width(length1+base_length)
    end_glyph(glyphname)

def torculus():
    for i in range(5):
	for j in range(5):
	    write_torculus(i+1,j+1, "base5", "base7", 16)
    for i in range(5):
	for j in range(5):
	    write_torculus(i+1,j+1, "idebilis", "base7", 16)

def write_torculus(i,j, first_glyph, last_glyph, glyph_number):
    glyphname=name(glyph_number, 0, i, j)
    begin_glyph(glyphname)
    global length1
    global height1
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
    paste_and_move(last_glyph, glyphname,  length+length1, (i-j)*base_height)
    set_width(length+length1+base_length)
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
    torculus()
    footers()

main()
