#!/usr/bin/perl -w
#
# gregorio-scribus, a script to use gregorio inside scribus.
# Copyright (C) 2009 Pierre Couderc <pierre@couderc.eu>.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use strict;

# $gregorio is the path of the gregorio executable. Do not forget to
# escape the \ (you must replace them by \\) for Windows paths.
# Under windows, if you want to use a native perl, you must put something
# like:
# my $gregorio = 'C:\\cygwinnew\\bin\\gregorio.exe';
# under Linux  or if you want to use the cygwin perl (which is advised as
# it is more simple), it can simply be:
my $gregorio = 'gregorio';

# $lualatex is the name of the LuaLaTeX executable in PDF mode.
# This variable is necessary because under TeXLive 2009, the formats
# have been changed and pdflualatex is replaced by lualatex, and
# lualatex has been replaced by dvilualatex. To sum up,
# under TeXLive 2008 use
# my $lualatex = "pdflualatex";
# and under TeXLive 2009 :
# my $lualatex = "lualatex";
my $lualatex = "lualatex";

my $path = $ARGV[0];
my $dir = $ARGV[1];
my @splitpath =split (m=[\\/]=,"$path");
my $file = $splitpath[$#splitpath];
if(defined($dir))
{
    chdir($dir);
}
open(INPUTFILE,"<","$path") || die("Cannot open file $path");
open(TEX,">", "$path.tex") || die("Cannot open file $path-main.tex");
open(GABC,">", "$path-score.gabc") || die("Cannot open file $path-score.gabc");
my $scheme = "lamed";
my $line;
foreach $line (<INPUTFILE>)
{
    if($line =~ /^\\/)
    {
        print TEX $line;
    }
    elsif($line =~ /^%%%/)
    {
        if($line =~ /^%%%%gregorio-scribus-scheme:lualatex/)
        {
            $scheme = "lualatex";
        }
    }
    elsif($line eq "\n")
    {
    }
    else
    {
        print GABC $line;
    }
}
print TEX <<EOF;
\\includescore{$file-score.tex}
\\end{document}
EOF
close TEX;
close GABC;
print "calling \'$gregorio $file-score.gabc\'\n";
unlink("$file-score.tex");
system("$gregorio $file-score.gabc");
if( -e "$file-score.tex")
{
  if($scheme eq "lualatex")
  {
    print "calling \'$lualatex --interaction nonstopmode $file.tex\'\n";
    system("$lualatex --interaction nonstopmode $file.tex");
  }
  else
  {
    print "calling \'lamed --interaction nonstopmode $file.tex\'\n";
    system("lamed --interaction nonstopmode $file.tex");
    print "calling \'dvipdfm $file.dvi\'\n";
    system("dvipdfm $file.dvi");
    unlink("$file.dvi");
  }
  unlink("$file-score.gabc");
  unlink("$file-score.tex");
  unlink("$file.tex");
  unlink("$file.aux");
}
else
{
  print "error: gregorio did not create \'$file-score.tex\'\n";
}
exit;
