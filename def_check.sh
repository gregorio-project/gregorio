#! /usr/bin/env bash

# This script is used make sure that all macros which gregoriotex-write.c
# might write to a gtex file are defined in the TeX code.
# It does this by creating two lists: one of all the \Gre macros defined in the TeX
# code, and one of all the macros which might be printed by gregoriotex-write.c.
# It then compares these two lists and outputs res.tex which contains a list of
# undefined macros (preceded by >) and macros which are defined but cannot be
# produced by gregoriotex-write.c

# It is not perfect, and especially has trouble with macros whose names
# gregoriotex-write.c builds a piece at a time.

HERE=`pwd`

TEXFILE=$HERE/tex.txt
CFILE=$HERE/c.txt
DIFFFILE=$HERE/diff.txt
RESFILE=$HERE/res.txt

#Extraction from TeX code
cd tex

grep -hE '\\[gex]?def\\Gre' *.tex *.sty > $TEXFILE
grep -hE '\\let\\Gre.*' *.tex *.sty >> $TEXFILE
grep -h '\\gredefsymbol{Gre.*' *.tex *.sty >> $TEXFILE

#remove deprecated code
sed -i.temp '/.*OBSOLETE.*/d' $TEXFILE
sed -i.temp '/.*DEPRECATED.*/d' $TEXFILE

#Isolate function names
sed -i.temp 's:Gre:\
Gre:g' $TEXFILE
sed -i.temp '/Gre/!d' $TEXFILE
sed -i.temp 's:\(Gre[a-zA-Z]*\).*:\1:' $TEXFILE

#remove bar lines (these names are assembled piecemeal, not whole)
sed -i.temp '/^GreDivisioFinalis$/d' $TEXFILE
sed -i.temp '/^GreDivisioMaior$/d' $TEXFILE
sed -i.temp '/^GreDivisioMaiorDotted$/d' $TEXFILE
sed -i.temp '/^GreDivisioMinima$/d' $TEXFILE
sed -i.temp '/^GreDivisioMinimaHigh$/d' $TEXFILE
sed -i.temp '/^GreDivisioMinimaParen$/d' $TEXFILE
sed -i.temp '/^GreDivisioMinimaParenHigh$/d' $TEXFILE
sed -i.temp '/^GreDivisioMinimis$/d' $TEXFILE
sed -i.temp '/^GreDivisioMinimisHigh$/d' $TEXFILE
sed -i.temp '/^GreDivisioMinor$/d ' $TEXFILE
sed -i.temp '/^GreDominica$/d' $TEXFILE
sed -i.temp '/^GreVirgula$/d' $TEXFILE
sed -i.temp '/^GreVirgulaHigh$/d' $TEXFILE
sed -i.temp '/^GreVirgulaParen$/d' $TEXFILE
sed -i.temp '/^GreVirgulaParenHigh$/d' $TEXFILE
sed -i.temp '/^GreFinalDivisioFinalis$/d' $TEXFILE
sed -i.temp '/^GreFinalDivisioMaior$/d' $TEXFILE
sed -i.temp '/^GreInDivisioFinalis$/d' $TEXFILE
sed -i.temp '/^GreInDivisioMaior$/d' $TEXFILE
sed -i.temp '/^GreInDivisioMaiorDotted$/d' $TEXFILE
sed -i.temp '/^GreInDivisioMinima$/d' $TEXFILE
sed -i.temp '/^GreInDivisioMinimaHigh$/d' $TEXFILE
sed -i.temp '/^GreInDivisioMinimaParen$/d' $TEXFILE
sed -i.temp '/^GreInDivisioMinimaParenHigh$/d' $TEXFILE
sed -i.temp '/^GreInDivisioMinimis$/d' $TEXFILE
sed -i.temp '/^GreInDivisioMinimisHigh$/d' $TEXFILE
sed -i.temp '/^GreInDivisioMinor$/d' $TEXFILE
sed -i.temp '/^GreInDominica$/d' $TEXFILE
sed -i.temp '/^GreInVirgula$/d' $TEXFILE
sed -i.temp '/^GreInVirgulaHigh$/d' $TEXFILE
sed -i.temp '/^GreInVirgulaParen$/d' $TEXFILE
sed -i.temp '/^GreInVirgulaParenHigh$/d' $TEXFILE

#remove alterations (these names are assembled piecemeal, not whole)
sed -i.temp '/^GreFlat$/d' $TEXFILE
sed -i.temp '/^GreFlatParen$/d' $TEXFILE
sed -i.temp '/^GreFlatSoft$/d' $TEXFILE
sed -i.temp '/^GreNatural$/d' $TEXFILE
sed -i.temp '/^GreNaturalParen$/d' $TEXFILE
sed -i.temp '/^GreNaturalSoft$/d' $TEXFILE
sed -i.temp '/^GreSharp$/d' $TEXFILE
sed -i.temp '/^GreSharpParen$/d' $TEXFILE
sed -i.temp '/^GreSharpSoft$/d' $TEXFILE

#label file
echo "00 GreMacros Defined in TeX" >> $TEXFILE

#alphabetize and remove duplicates
sort -u -o$TEXFILE $TEXFILE


#Extraction from c code
cd ../src/gregoriotex
grep -hE '\\\\Gre.*' gregoriotex-write.c > $CFILE

cd ../gabc
grep -hE '\\\\Gre.*' gabc-notes-determination.l >> $CFILE
grep -hE '\\\\Gre.*' gabc-score-determination.y >> $CFILE

#remove deprecated code
sed -i.temp '/.*OBSOLETE.*/d' $CFILE
sed -i.temp '/.*DEPRECATED.*/d' $CFILE

#Isolate function names
sed -i.temp 's:Gre:\
Gre:g' $CFILE
sed -i.temp '/Gre/!d' $CFILE
sed -i.temp 's:\(Gre[a-zA-Z]*\).*:\1:' $CFILE

#remove prefixes of assembled function names
sed -i.temp '/^Gre$/d' $CFILE
sed -i.temp '/^GreCP$/d' $CFILE
sed -i.temp '/^GreFinal$/d' $CFILE
sed -i.temp '/^GreIn$/d' $CFILE
sed -i.temp '/^GreOCase$/d' $CFILE

#label file
echo "00 Macros Written by C" >> $CFILE

#alphabetize and remove duplicates
sort -u -o$CFILE $CFILE

#find differences
diff -B $CFILE $TEXFILE > $DIFFFILE

grep -h '[<>]' $DIFFFILE > $RESFILE

sort -u -o$RESFILE $RESFILE

#cleanup
rm $CFILE.temp
rm $CFILE
rm $TEXFILE.temp
rm $TEXFILE
rm $DIFFFILE

#open result
open $RESFILE
