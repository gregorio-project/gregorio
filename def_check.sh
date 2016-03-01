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
sed -i.temp 's:.*OBSOLETE.*::' $TEXFILE
sed -i.temp 's:.*DEPRECATED.*::' $TEXFILE

#Isolate function names
sed -i.temp 's:Gre:\
Gre:g' $TEXFILE
sed -i.temp '/Gre/!d' $TEXFILE
sed -i.temp 's:\(Gre[a-zA-Z]*\).*:\1:' $TEXFILE

#label file
echo "00 GreMacros Defined in TeX" >> $TEXFILE

#alphabetize and remove duplicates
sort -u -o$TEXFILE $TEXFILE


#Extraction from c code
cd ../src/gregoriotex

grep -hE '\\\\Gre.*' gregoriotex-write.c > $CFILE

#remove deprecated code
sed -i.temp 's:.*OBSOLETE.*::' $CFILE
sed -i.temp 's:.*DEPRECATED.*::' $CFILE

#Isolate function names
sed -i.temp 's:Gre:\
Gre:g' $CFILE
sed -i.temp '/Gre/!d' $CFILE
sed -i.temp 's:\(Gre[a-zA-Z]*\).*:\1:' $CFILE

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
