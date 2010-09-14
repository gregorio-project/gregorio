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
'/usr/share/texmf/']

Fonts=['greciliae', 'gregorio', 'parmesan']

NumberOfFiles=9

def main():
    if access('gregoria-0.pfb', F_OK):
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
                    #patch_cygwin(basedir)
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
	if splitpath[-1][0] == '2': # we test if the last directory is 2008 or 2009 or...
		splitpath = splitpath[0:-1]
	return '/'.join(splitpath)

def patch_cygwin(basedir):
    # just some symlinks for texlive 2008 to work fine under cygwin
    # test to know if it is a cygwin system
    # we have to copy some files
    if access('%s/2009' % basedir, F_OK):
        basename = '%s/2009' % basedir
    if access('%s/2010' % basedir, F_OK):
        basename = '%s/2010' % basedir
    elif access('%s/bin' % basedir, F_OK):
        basename = basedir
    else:
        # I don't know what to do for other cases
        return
    # we don't patch it two times, otherwise error occur
    print basename
    
def install(basedir):
    makedir(basedir, 'fonts/tfm/public/gregoriotex')
    makedir(basedir, 'fonts/type1/public/gregoriotex')
    makedir(basedir, 'fonts/ovf/public/gregoriotex')
    makedir(basedir, 'fonts/ofm/public/gregoriotex')
    makedir(basedir, 'fonts/ovp/public/gregoriotex')
    makedir(basedir, 'fonts/map/dvips/public/gregoriotex')
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
    copy(basedir, 'gresym.map', 'fonts/map/dvips/public/gregoriotex')
    copy(basedir, 'greextra.map', 'fonts/map/dvips/public/gregoriotex')
    makedir(basedir, 'fonts/tfm/public/gregoriotex/gresym')
    copy(basedir, 'gresym.tfm', 'fonts/tfm/public/gregoriotex/gresym')
    makedir(basedir, 'fonts/tfm/public/gregoriotex/greextra')
    copy(basedir, 'greextra.tfm', 'fonts/tfm/public/gregoriotex/greextra')
    makedir(basedir, 'fonts/type1/public/gregoriotex/gresym')
    copy(basedir, 'gresym.pfb', 'fonts/type1/public/gregoriotex/gresym')
    makedir(basedir, 'fonts/type1/public/gregoriotex/greextra')
    copy(basedir, 'greextra.pfb', 'fonts/type1/public/gregoriotex/greextra')
    for fontname in Fonts:
        makedir(basedir, 'fonts/tfm/public/gregoriotex/%s' % fontname)    
        for i in range(NumberOfFiles):
            copy(basedir, '%s-%d.tfm' % (fontname, i), 'fonts/tfm/public/gregoriotex/%s' % fontname)
        makedir(basedir, 'fonts/type1/public/gregoriotex/%s' % fontname)    
        for i in range(NumberOfFiles):
            copy(basedir, '%s-%d.pfb' % (fontname, i), 'fonts/type1/public/gregoriotex/%s' % fontname)
        makedir(basedir, 'fonts/map/dvips/public/gregoriotex')
        copy(basedir, '%s.map' % fontname, 'fonts/map/dvips/public/gregoriotex')
        makedir(basedir, 'fonts/ovf/public/gregoriotex/%s' % fontname)
        copy(basedir, '%s.ovf' % fontname, 'fonts/ovf/public/gregoriotex/%s' % fontname)
        makedir(basedir, 'fonts/ofm/public/gregoriotex/%s' % fontname)
        copy(basedir, '%s.ofm' % fontname, 'fonts/ofm/public/gregoriotex/%s' % fontname)
        makedir(basedir, 'fonts/ovp/public/gregoriotex/%s' % fontname)
        copy(basedir, '%s.ovp' % fontname, 'fonts/ovp/public/gregoriotex/%s' % fontname)
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
    Fonts.append("gresym")
    Fonts.append("greextra")
    # we detect here if it is a debian system
    if access('/etc/texmf/updmap.d', F_OK):
        print "filling /etc/texmf/updmap.d/20gregoriotex.cfg"
        fout=open("/etc/texmf/updmap.d/20gregoriotex.cfg", 'w')
        fout.write ("""# 20gregoriotex.cfg
# You can change/add entries to this file and changes will be preserved
# over upgrades, even if you have removed the main package prior
# (not if you purged it). You should leave the following pseudo comment
# present in the file!
# -_- DebPkgProvidedMaps -_-
# 
""")
        for fontname in Fonts:
            fout.write("MixedMap %s.map\n" % fontname)
        fout.close()
        print "running update-updmap"
        system("update-updmap")
        print "running updmap-sys"
        system("updmap-sys")
        print "running updmap"
        system("updmap")
    elif sys.platform == 'darwin':
        for fontname in Fonts:
            print ("running updmap-sys --nomkmap --enable MixedMap=%s.map" % fontname)
            system("updmap-sys --nomkmap --enable MixedMap=%s.map" % fontname)
        system("updmap-sys")
    else:
        for fontname in Fonts:
            print ("running updmap-sys --enable MixedMap=%s.map" % fontname)
            if access('/cygdrive', F_OK):
                system("updmap-sys.exe --enable MixedMap=%s.map" % fontname)
                print ("running updmap --enable MixedMap=%s.map" % fontname)
                system("updmap.exe --enable MixedMap=%s.map" % fontname)
            else:
                system("updmap-sys --enable MixedMap=%s.map" % fontname)

if __name__ == "__main__":
    main()
