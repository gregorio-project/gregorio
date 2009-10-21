#!/usr/bin/perl -w
#
# gregorio-scribus, a script to use gregorio inside scribus.
# Copyright (C) 2009 Pierre Couderc <pierre@couderc.eu>.
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;

my $dir = $ARGV[0];
my $file = $ARGV[1];
open(INPUTFILE,"<","$file") || die("Cannot open file $file");
my @raw_data=<INPUTFILE>; 
open(TEX,">gregorio-scribus-tmp.tex") || die("Cannot open file gregorio-scribus-tmp.tex");
open(GABC,">gregorio-scribus-tmp-score.gabc") || die("Cannot open file gregorio-scribus-tmp-score.gabc");
foreach my $lineo (@raw_data)
{
        if(defined($lineo))
	{
		my $line = $lineo;
		if(substr($lineo,0,1) eq "\\")
		{
			print TEX $line;
		}
		else
		{
			print GABC $line;
		}
	}
}
print TEX <<EOF;
\\includescore{gregorio-scribus-tmp-score.tex}
\\end{document}
EOF
close TEX;
close GABC;
print 'calling \'gregorio gregorio-scribus-tmp-score.gabc\'\n';
unlink('gregorio-scribus-tmp-score.tex');
system('gregorio gregorio-scribus-tmp-score.gabc');
if( -e 'gregorio-scribus-tmp-score.tex')
{
  system('lamed gregorio-scribus-tmp.tex');
  print 'calling \'lamed gregorio-scribus-tmp.tex\'\n';
  system("dvipdfm $dir/gregorio-scribus-tmp.dvi");
  print 'calling \'dvipdfm $dir/gregorio-scribus-tmp.dvi\'\n';
  system("mv gregorio-scribus-tmp.pdf $file.pdf");
  unlink('gregorio-scribus-tmp-score.gabc');
  unlink('gregorio-scribus-tmp-score.tex');
  unlink('gregorio-scribus-tmp.tex');
  unlink('gregorio-scribus-tmp.dvi');
}
exit;
