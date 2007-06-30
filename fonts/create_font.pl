#!/usr/bin/perl -w

#Perl script to build a complete font for omega from afm and tfm files.
#Copyright (C) 2006 Elie Roux
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

use strict;


# static contains the beginning of the ovp file
my $static="(VTITLE gregorio)
(FAMILY UNSPECIFIED)
(FACE F MRR)
(CODINGSCHEME UNSPECIFIED)
(DESIGNSIZE R 10.0)
(COMMENT DESIGNSIZE IS IN POINTS)
(COMMENT OTHER SIZES ARE MULTIPLES OF DESIGNSIZE)
(CHECKSUM O 30643311733)
(SEVENBITSAFEFLAG TRUE)
(MAPFONT D 0
   (FONTNAME gregorio)
   (FONTAT R 1.0)
   (FONTDSIZE R 10.0)
   )";

# position will contain the names of the glyph as keys, and their position in their police as values
my %position;

# font will contain the name of the glyphs as key and the police he is in as a number (1 for gregorio-1.*, etc.)
my %font;

# name will contain the true number of the glyph (1 if the first trated, etc.) as key, and the glyph name as value
my @name;

# namex will contain keys of the form "x-y", where x is the number of the police (1 for gregorio-1.*, etc.) and y the position in the police. the values of namex are the names of the glyphs.
my %namex;

# order is a variable that will contain the number of glyphs that we have already treated
my $order=0;

# number_of_font is the number of 255 character fonts that will be used
my $number_of_font=6;

# first we read the afm files and we fill position, font, name and namex with the values
my $i;
for ($i=0;$i<$number_of_font;$i++) {
open IN,"<gregorio-$i.afm";
while (<IN>) {
if (m/C ([0-9]+) ; WX [0-9-]+ ; N _([0-9-]+) ;/) {
$position{$2}=$1; $font{$2}=$i; $namex{$i."-".$1}=$2; $name[$order]=$2; $order++;
}
}
close IN;
}

# then we open the pl files and we fill hash tables width, height and depth for every glyph

# height, width and depth will contain the names of the glyphs as keys, and 0 as values, they contain only the interesting keys (keys for which value is 0)
my %width;
my %height;
my %depth;
my $character;

for ($i=0;$i<$number_of_font;$i++) {
# there you must have the .pl files, they are generated from tfm by tftopl (in the tetex or texlive distribution)
open IN,"tftopl gregorio-$i.tfm |";
#open IN,"<gregorio-$i.pl";
while (<IN>) {
  if (m/\(CHARACTER O ([0-7]+)/) { 
    $character=oct($1);
    $width{$namex{$i."-".$character}}="0.0";
    $height{$namex{$i."-".$character}}="0.0";
    $depth{$namex{$i."-".$character}}="0.0";
  }
  elsif (m/\(CHARACTER D ([0-9]+)/) {
    $character=$1;
    $width{$namex{$i."-".$character}}="0.0";
    $height{$namex{$i."-".$character}}="0.0";
    $depth{$namex{$i."-".$character}}="0.0";
  }
  elsif (m/\(CHARACTER H ([0-9A-F]+)/) {
    $character=hex($1);
    $width{$namex{$i."-".$character}}="0.0";
    $height{$namex{$i."-".$character}}="0.0";
    $depth{$namex{$i."-".$character}}="0.0";
  }
  elsif (m/\(CHARACTER C ([A-Za-z0-9])/) {
    $character=ord($1);
    $width{$namex{$i."-".$character}}="0.0";
    $height{$namex{$i."-".$character}}="0.0";
    $depth{$namex{$i."-".$character}}="0.0";
  }
  elsif (m/\(CHARWD R ([0-9.-]+)/) {
    $width{$namex{$i."-".$character}}=$1;
  } 
  elsif (m/\(CHARHT R ([0-9.-]+)/) {
    $height{$namex{$i."-".$character}}=$1;
  } 
  elsif (m/\(CHARDP R ([0-9.-]+)/) {
    $depth{$namex{$i."-".$character}}=$1;
  } 
  }
close IN;
}

my $temp;

open OUT, ">gregorio.ovp";
print OUT $static."\n";
for ($i=0;$i<$order;$i++) { 
$temp=sprintf("%X",$name[$i]);
print OUT "(CHARACTER H ".$temp."
   (CHARWD R ".$width{$name[$i]}.")
   (CHARDP R ".$depth{$name[$i]}.")
   (CHARHT R ".$height{$name[$i]}.")
   (MAP
      (SELECTFONT D ".$font{$name[$i]}.")
      (SETCHAR D ".$position{$name[$i]}.")
      )
   )
";
}
close OUT;
