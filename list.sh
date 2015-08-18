#! /usr/bin/env bash

# This script is used to compare the code base to the documentation and make
# sure that the two match up.
# It does this by creating two lists: one of all the macros defined in the TeX
# code, and one of all the macros documented in the documentation (plus all the
# macros in the code which are marked as deprecated or obsolete, and thus don't
# need documentation.  It then compares these two lists and outputs res.tex
# which contains a list of undocumented macros (preceded by >) and macros which
# are documented but which no longer appear in the code (preceded by <).


HERE=`pwd`

CODEFILE=$HERE/code.txt
DOCFILE=$HERE/doc.txt
DIFFFILE=$HERE/diff.txt
RESFILE=$HERE/res.txt

#Extraction from code
cd tex

#find definitions
grep -h '\\new[a-z]*\\.*' *.tex *.sty > $CODEFILE
grep -hE '\\[gex]?def\\.*' *.tex *.sty >> $CODEFILE
grep -hE '\\let\\.*' *.tex *.sty >> $CODEFILE

#remove trailing comments
gsed -i.temp 's/%.*$//' $CODEFILE

#remove whitespace
gsed -i.temp 's/^[ \t]*//;s/[ \t]*$//' $CODEFILE

#remove new and trailing code
sed -i.temp 's:.*\\new[a-z]*{*\(\\*[a-zA-Z@]*\)[\\}]*.*:\1:' $CODEFILE

#remove def and definition
sed -i.temp -E 's:.*\\[gex]?def[a-z]*(\\[a-zA-Z@]*)[#{[].*:\1:' $CODEFILE

#remove let and definition
sed -i.temp 's:.*\\let[a-z]*\(\\[a-zA-Z@]*\)\\.*:\1:' $CODEFILE

#unwrap csname
sed -i.temp 's:.*\(\\csname.*\\endcsname\).*:\1:' $CODEFILE

#colors
grep -hE '\\definecolor.*' *.sty >> $CODEFILE
sed -i.temp 's:\\definecolor{\([a-zA-Z]*\)}.*:\1:' $CODEFILE

#distances
grep -h '\\grecreatedim{.*' gsp-default.tex >> $CODEFILE
sed -i.temp 's:\\grecreatedim{\([a-z@]*\)}.*:\1:' $CODEFILE

#boxes
grep -hE '\\setbox.*' *.tex *.sty >> $CODEFILE
sed -i.temp 's:\\setbox\(\\[a-z@]*\):\1:' $CODEFILE

#alphabetize and remove duplicates
sort -u -o$CODEFILE $CODEFILE


#Extraction from documentation
cd $HERE/doc

grep -h '\\macroname.*' *.tex > $DOCFILE

#remove all but name
sed -i.temp 's:\\macroname{\([^}]*\)}.*:\1:' $DOCFILE

#replace TeX code with backslash
sed -i.temp 's:\\textbackslash :\\:' $DOCFILE

#deprecated and obsolete functions (not in documentation because they don't need to be)
cd $HERE/tex

grep -h '\\gre@deprecated.*' *.tex >> $DOCFILE
grep -h '\\gre@obsolete.*' *.tex >> $DOCFILE

sed -i.temp 's:^\s*\\gre@deprecated{\protect\([^}]*\)}.*:\1:' $DOCFILE
sed -i.temp 's:^\s*\\gre@obsolete{\protect\([^}]*\)}.*:\1:' $DOCFILE

#alphabetize and remove duplicates
sort -u -o$DOCFILE $DOCFILE


#find differences
diff -B $DOCFILE $CODEFILE > $DIFFFILE

grep -h '[<>]' $DIFFFILE > $RESFILE

sort -u -o$RESFILE $RESFILE

#cleanup
rm $DOCFILE.temp
rm $DOCFILE
rm $CODEFILE.temp
rm $CODEFILE
rm $DIFFFILE
