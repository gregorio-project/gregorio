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
from os import access, F_OK, W_OK, makedirs, system, symlink
from os.path import join

TexliveDirs=['/usr/share/texmf/',
'/usr/local/texmf/',
'/sw/var/lib/texmf',
'/cygdrive/c/Program Files/texlive/texmf-local']

Fonts=['greciliae', 'gregorio', 'parmesan']

NumberOfFiles=5

def main():
    for basedir in TexliveDirs:
        if access(basedir, F_OK):
            if access(basedir, W_OK):
                print "installing gregorio fonts in %s" % basedir
                patch_cygwin()      
                install(basedir)
            else:
                print "error: can't write in %s" % basedir

def patch_cygwin():
    # just some symlinks for texlive 2008 to work fine under cygwin
    # test to know if it is a cygwin system
    if access('/cygdrive/c/Program Files/texlive/2008', F_OK):
        # we have to copy some files
        basename='/cygdrive/c/Program Files/texlive/2008'
        # we don't patch it two times, otherwise error occur
        if access('%s/bin/win32/a2ping' % basename, F_OK):
            return
        copy_cyg(basename, 'texmf/scripts/a2ping/a2ping.pl', 'a2ping')
        copy_cyg(basename, 'texmf-dist/scripts/context/stubs/unix/context', 'context')
        copy_cyg(basename, 'texmf-dist/scripts/dviasm/dviasm.py', 'dviasm')
        copy_cyg(basename, 'texmf/scripts/tetex/e2pall.pl', 'e2pall')
        copy_cyg(basename, 'texmf-dist/scripts/bengali/ebong.py', 'ebong')
        copy_cyg(basename, 'texmf-dist/scripts/epspdf/epspdf', 'epspdf')
        copy_cyg(basename, 'texmf-dist/scripts/epspdf/epspdftk', 'epspdftk')
        copy_cyg(basename, 'texmf/scripts/epstopdf/epstopdf.pl', 'epstopdf')
        copy_cyg(basename, 'texmf/scripts/texlive/getnonfreefonts.pl', 'getnonfreefonts')
        copy_cyg(basename, 'texmf-dist/scripts/tex4ht/ht.sh', 'ht')
        copy_cyg(basename, 'texmf-dist/scripts/tex4ht/htcontext.sh', 'htcontext')
        copy_cyg(basename, 'texmf-dist/scripts/tex4ht/htlatex.sh', 'htlatex')
        copy_cyg(basename, 'texmf-dist/scripts/tex4ht/htmex.sh', 'htmex')
        copy_cyg(basename, 'texmf-dist/scripts/tex4ht/httex.sh', 'httex')
        copy_cyg(basename, 'texmf-dist/scripts/tex4ht/httexi.sh', 'httexi')
        copy_cyg(basename, 'texmf-dist/scripts/tex4ht/htxelatex.sh', 'htxelatex')
        copy_cyg(basename, 'texmf-dist/scripts/tex4ht/htxetex.sh', 'htxetex')
        copy_cyg(basename, 'texmf-dist/scripts/glossaries/makeglossaries', 'makeglossaries')
        copy_cyg(basename, 'texmf-dist/scripts/tex4ht/mk4ht.pl', 'mk4ht')
        copy_cyg(basename, 'texmf-dist/scripts/mkjobtexmf/mkjobtexmf.pl', 'mkjobtexmf')
        copy_cyg(basename, 'texmf-dist/scripts/context/stubs/unix/mtxrun', 'mtxrun')
        copy_cyg(basename, 'texmf-dist/scripts/oberdiek/pdfatfi.pl', 'pdfatfi')
        copy_cyg(basename, 'texmf-dist/scripts/pdfcrop/pdfcrop.pl', 'pdfcrop')
        copy_cyg(basename, 'texmf-dist/scripts/ppower4/pdfthumb.texlua', 'pdfthumb.texlua')
        copy_cyg(basename, 'texmf-dist/scripts/perltex/perltex.pl', 'perltex')
        copy_cyg(basename, 'texmf/scripts/pkfix/pkfix.pl', 'pkfix')
        copy_cyg(basename, 'texmf-dist/scripts/ppower4/ppower4.texlua', 'ppower4')
        copy_cyg(basename, 'texmf/scripts/ps2eps/ps2eps.pl', 'ps2eps')
        copy_cyg(basename, 'texmf-dist/scripts/pst-pdf/ps4pdf', 'ps4pdf')
        copy_cyg(basename, 'texmf/scripts/texlive/rungs.tlu', 'rungs')
        copy_cyg(basename, 'texmf/scripts/simpdftex/simpdftex', 'simpdftex')
        copy_cyg(basename, 'texmf-dist/scripts/texcount/TeXcount.pl', 'texcount')
        copy_cyg(basename, 'texmf/scripts/texlive/texdoc.tlu', 'texdoc')
        copy_cyg(basename, 'texmf/scripts/tetex/texdoctk.pl', 'texdoctk')
        copy_cyg(basename, 'texmf/scripts/xindy/texindy.pl', 'texindy')
        copy_cyg(basename, 'texmf-dist/scripts/thumbpdf/thumbpdf.pl', 'thumbpdf')
        copy_cyg(basename, 'texmf/scripts/texlive/tlmgr.pl', 'tlmgr')
        copy_cyg(basename, 'texmf-dist/scripts/vpe/vpe.pl', 'vpe')
        copy_cyg(basename, 'texmf/scripts/xindy/xindy.pl', 'xindy')

def copy_cyg(basename, src, dst):
    symlink("%s/%s" %(basename, src), "%s/bin/win32/%s" %(basename, dst))

def install(basedir):
    makedir(basedir, 'fonts/tfm/public/gregoriotex')
    makedir(basedir, 'fonts/type1/public/gregoriotex')
    makedir(basedir, 'fonts/ovf/public/gregoriotex')
    makedir(basedir, 'fonts/ofm/public/gregoriotex')
    makedir(basedir, 'fonts/ovp/public/gregoriotex')
    makedir(basedir, 'fonts/maps/dvips/public/gregoriotex')
    makedir(basedir, 'tex/latex/gregoriotex')
    copy(basedir, '../tex/gregoriotex.sty', 'tex/latex/gregoriotex')
    makedir(basedir, 'tex/gregoriotex')
    copy(basedir, '../tex/gregoriotex.tex', 'tex/gregoriotex')
    copy(basedir, '../tex/gregoriotex-signs.tex', 'tex/gregoriotex')
    copy(basedir, '../tex/gregoriotex-spaces.tex', 'tex/gregoriotex')
    copy(basedir, '../tex/gregoriotex-syllable.tex', 'tex/gregoriotex')
    makedir(basedir, 'fonts/tfm/public/gregoriotex/gresym')
    copy(basedir, 'gresym.tfm', 'fonts/tfm/public/gregoriotex/gresym')
    makedir(basedir, 'fonts/type1/public/gregoriotex/gresym')
    copy(basedir, 'gresym.pfb', 'fonts/type1/public/gregoriotex/gresym')
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
    print ("copying %s in %s" % (filename, join(basedir, dirname)))
    shutil.copy(filename, join(basedir, dirname))

def endInstall(basedir):
    print ("running mktexlsr")
    system("mktexlsr")
    for fontname in Fonts:
        print ("running updmap-sys --enable MixedMap=%s" % join(basedir, 'fonts/map/dvips/public/gregoriotex/', "%s.map" % fontname))
        if access('/cygdrive', F_OK):
            system("updmap-sys.bat --enable MixedMap=%s" % join(basedir, 'fonts/map/dvips/public/gregoriotex/', "%s.map" % fontname))
        else:
            system("updmap-sys --enable MixedMap=%s" % join(basedir, 'fonts/map/dvips/public/gregoriotex/', "%s.map" % fontname))

if __name__ == "__main__":
    main()
