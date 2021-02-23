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

if sed --version 2&> /dev/null; then
  SED=sed
elif gsed --version 2&> /dev/null; then
  SED=gsed
else
  echo "I can't find GNU sed."
  echo "Please install it and try again."
  return 1
fi


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
$SED -i.temp 's:.*OBSOLETE.*::' $TEXFILE
$SED -i.temp 's:.*DEPRECATED.*::' $TEXFILE

#Isolate function names
$SED -i.temp 's:Gre:\
Gre:g' $TEXFILE
$SED -i.temp '/Gre/!d' $TEXFILE
$SED -i.temp 's:\(Gre[a-zA-Z]*\).*:\1:' $TEXFILE

#remove bar lines (these names are assembled piecemeal, not whole)
$SED -i.temp 's:^GreDivisioFinalis$::' $TEXFILE
$SED -i.temp 's:^GreDivisioMaior$::' $TEXFILE
$SED -i.temp 's:^GreDivisioMinima$::' $TEXFILE
$SED -i.temp 's:^GreDivisioMinor$::' $TEXFILE
$SED -i.temp 's:^GreDominica$::' $TEXFILE
$SED -i.temp 's:^GreVirgula$::' $TEXFILE
$SED -i.temp 's:^GreFinalDivisioFinalis$::' $TEXFILE
$SED -i.temp 's:^GreFinalDivisioMaior$::' $TEXFILE
$SED -i.temp 's:^GreInDivisioFinalis$::' $TEXFILE
$SED -i.temp 's:^GreInDivisioMaior$::' $TEXFILE
$SED -i.temp 's:^GreInDivisioMinima$::' $TEXFILE
$SED -i.temp 's:^GreInDivisioMinor$::' $TEXFILE
$SED -i.temp 's:^GreInDominica$::' $TEXFILE
$SED -i.temp 's:^GreInVirgula$::' $TEXFILE


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
$SED -i.temp 's:.*OBSOLETE.*::' $CFILE
$SED -i.temp 's:.*DEPRECATED.*::' $CFILE

#Isolate function names
$SED -i.temp 's:Gre:\
Gre:g' $CFILE
$SED -i.temp '/Gre/!d' $CFILE
$SED -i.temp 's:\(Gre[a-zA-Z]*\).*:\1:' $CFILE

#remove prefixes of assembled function names
$SED -i.temp 's:^Gre$::' $CFILE
$SED -i.temp 's:^GreCP$::' $CFILE
$SED -i.temp 's:^GreFinal$::' $CFILE
$SED -i.temp 's:^GreIn$::' $CFILE

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
