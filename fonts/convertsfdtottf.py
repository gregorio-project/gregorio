#!/usr/bin/env python2
# coding=utf-8

"""
    Python fontforge script to convert from fontforge's native sfd
    to a TrueType font (ttf).

    Copyright (C) 2015 R. Padraic Springuel <rpspringuel@gmail.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    This script takes a .sfd file and converts it to a .ttf file.

    Basic use :
     ./convertsfdtottf.py fontname

"""


from __future__ import print_function

import getopt, sys
import fontforge


def usage():
    "Prints help message."
    print("""
Python script to confert a fontforge native file (.sfd) to a TrueType font
(.ttf).

Usage:
    convertsfdtottf fontname

where fontname is fontforge native file with extension sfd.
""")

def main():
    "Main function."
    try:
        opts, args = getopt.gnu_getopt(sys.argv[1:], "h", ["help"])
    except getopt.GetoptError:
        # print help information and exit:
        usage()
        sys.exit(2)
    outputfile = None
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            usage()
            sys.exit()
    if len(args) == 0:
        usage()
        sys.exit(2)
    if args[0][-3:] == "sfd":
        outputfile = "%s.ttf" % args[0][:-4]
        inputfile = args[0]
    else:
        usage()
        sys.exit(2)
    font = fontforge.open(inputfile)
    font.generate(outputfile)
    font.close()

if __name__ == "__main__":
    main()
