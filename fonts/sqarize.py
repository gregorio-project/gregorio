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

#porrectus_lengths=[PORRECTUS_LENGTH_3-2*LINE_HEIGHT, PORRECTUS_LENGTH_2-2*LINE_HEIGHT, PORRECTUS_LENGTH_3-2*LINE_HEIGHT, PORRECTUS_LENGTH_4-2*LINE_HEIGHT, PORRECTUS_LENGTH_5-2*LINE_HEIGHT]

#mieux en fait : les glyphes s'emboitent bien, et on ajout n*le glyphe de queue. Haha mais attention ! il faut que l'intervalle soit celui de entre deux notes separees d'une demi-ligne !

#height symbols. Height symbols are more complicated we have a basic height, it is the height of a punctum.

#global BASE_HEIGHT=12 #height of a truc with truc
#global BASE_QUEUE_HEIGHT=12
#global BASE_INTERLINE=12

count=125

#base_height=78.75
base_height=157.5

def headers():
    print """#!/usr/local/bin/fontforge

Open("gregorio-test.sfd");"""

def footers():
    print """Save("gregorio-final.sfd");
Quit(0);"""

def torculus():
    for i in range(5):
	for j in range(5):
	    write_torculus(i+1,j+1)

def write_torculus(i,j):
    glyphname=name(16, 0, i, j)
    print base_height
    begin_glyph(glyphname)
    global length1
    global height1
    glyphname=name(16, 0, i, j)
    simple_paste("base5", glyphname)
    if (i!=1):
	linename= "line%d" % i 
	paste_and_move(linename, glyphname, length1, base_height)
    paste_and_move("base3", glyphname, length1, i*base_height)
    if (j!=1):
	linename = "line%d" % j
	paste_and_move(linename, glyphname, 2*length1, base_height)
    paste_and_move("base7", glyphname,  2*length1, (i-j)*base_height)
    set_width(2*length1+base_length)
    end_glyph(glyphname)

def end_glyph(glyphname):
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
    write_torculus(2,2)
    footers()

main()
