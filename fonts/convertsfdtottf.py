#!/usr/bin/python2
# coding=utf-8

from __future__ import print_function

import getopt, sys
import fontforge

def usage():
    print("""
Python script to confert a fontforge native file (.sfd) to a TrueType font
(.ttf).

Usage:
    convertsfdtottf fontname

with fontname=gresym or greextra for now.
""")

def main():
#    global font, font_name
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
    if args[0] == "gresym.sfd":
        font_name="gresym"
    elif args[0] == "greextra.sfd":
        font_name="greextra"
    else:
        usage()
        sys.exit(2)
    font = fontforge.open("%s.sfd" % font_name)
    font.generate("%s.ttf" % font_name)
    font.close()
    
if __name__ == "__main__":
    main()
