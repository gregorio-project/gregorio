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
#This script installs the fonts on a TeXLive system.

import getopt, sys, shutil
from os import access, F_OK, W_OK, makedirs, system, symlink, chmod, popen
from stat import S_IRUSR, S_IWUSR, S_IRGRP, S_IROTH
from os.path import join, basename

TexliveDirs=[
'/usr/local/texmf/',
'/sw/var/lib/texmf',
'/usr/local/texlive/texmf-local',
'/cygdrive',
'/usr/share/texmf/',
'/usr/local/texlive/2010basic/texmf-local']

Fonts=['greciliae', 'gregorio', 'parmesan']

def main():
    if access('gregoriao.ttf', F_OK):
        Fonts.append('gregoria')
    i=0
    for basedir in TexliveDirs:
        i=i+1
        if access(basedir, F_OK):
            if access(basedir, W_OK) or basedir == '/cygdrive':
                if basedir == '/cygdrive':
                    if access('/usr/bin/latex.exe', W_OK):
                        print "error: TeTeX installation of cygwin detected, aborting installation.\nYou must remove the TeX installation of cygwin before proceeding"
                        return
                    basedir = cyg_find_basedir()
                    if basedir == '':
                        print "error: can't locate latex.exe, aborting installation"
                        return
                    basedir = '%s/texmf-local' % basedir
                    install(basedir)
                else:
					print "installing gregorio fonts in %s" % basedir
					install(basedir)
            else:
                print "error: can't write in %s" % basedir
            return
        elif i==len(TexliveDirs) +1:
            print "error: unable to determine location of texmf directory"

def cyg_find_basedir():
	line = popen("which.exe latex.exe").readline()
	if line == "":
	    return ''
	splitpath = line.split('/')
	splitpath = splitpath[0:-3]
	return '/'.join(splitpath)
    
def install(basedir):
    makedir(basedir, 'fonts/truetype/public/gregoriotex')
    makedir(basedir, 'tex/latex/gregoriotex')
    copy(basedir, '../tex/gregoriotex.sty', 'tex/latex/gregoriotex')
    copy(basedir, '../tex/gregoriosyms.sty', 'tex/latex/gregoriotex')
    makedir(basedir, 'tex/gregoriotex')
    copy(basedir, '../tex/gregoriotex.tex', 'tex/gregoriotex')
    copy(basedir, '../tex/gsp-default.tex', 'tex/gregoriotex')
    copy(basedir, '../tex/gregoriotex-signs.tex', 'tex/gregoriotex')
    copy(basedir, '../tex/gregoriotex-spaces.tex', 'tex/gregoriotex')
    copy(basedir, '../tex/gregoriotex-syllable.tex', 'tex/gregoriotex')
    copy(basedir, '../tex/gregoriotex-symbols.tex', 'tex/gregoriotex')
    copy(basedir, '../tex/gregoriotex.lua', 'tex/gregoriotex')
    copy(basedir, '../tex/gregoriotex-ictus.lua', 'tex/gregoriotex')
    for fontname in Fonts:
        copy(basedir, '%s.ttf' % fontname, 'fonts/truetype/public/gregoriotex')
    endInstall(basedir)

def makedir(basedir, dirname):
    name = join(basedir, dirname)
    if access(name, F_OK):
        pass
    else:
        print ("creating directory %s" % name)
        makedirs(name)
        
def copy(basedir, filename, dirname):
    destdir=join(basedir, dirname)
    print ("copying %s in %s" % (filename, destdir))
    shutil.copy(filename, destdir)
    chmod(join(destdir, basename(filename)), S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH)
    

def endInstall(basedir):
    if access('/cygdrive', F_OK):
        print ("running mktexlsr")
        system("mktexlsr")
    else:
        print ("running mktexlsr %s" % basedir)
        system("mktexlsr %s" % basedir)

if __name__ == "__main__":
    main()
