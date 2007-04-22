# Gregorio Makefile.
# Copyright (C) 2006 Elie Roux
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

CC=gcc
CCFLAGS=-g -Wall -I/usr/include/libxml2 -lxml2 -lz
LEX=flex
BISON=bison
FILES=src/gabc-notes-determination.c src/gabc-score-determination-l.c src/gabc-score-determination-y.c src/struct-utils.c src/xml-write.c src/xml-read.c src/xml-utils.c src/gabc-glyphs-determination.c src/gabc-elements-determination.c src/gregorio-utils.c src/messages.c src/gabc-write.c src/gregoriotex-write.c src/opustex-write.c src/dump.c

all: flex bison c

flex:
	$(LEX) -o src/gabc-notes-determination.c --prefix="gabc_notes_determination_" src/gabc-notes-determination.l 
	$(LEX) -o src/gabc-score-determination-l.c -C --header-file="src/gabc-score-determination-l.h" --prefix="gabc_score_determination_" src/gabc-score-determination.l

c:
	$(CC) $(CCFLAGS) $(FILES) -o gregorio
	chmod +x gregorio-utils

bison:
	bison --defines="src/gabc-score-determination-y.h" -p "gabc_score_determination_" -o src/gabc-score-determination-y.c src/gabc-score-determination.y

translation-template:
	xgettext --language=C src/*.c src/*y --keyword="_" --keyword="N_" --output="po/messages.po"
translation-fr:
	msgfmt --output-file="../po/fr_FR/LC_MESSAGES/gregorio-utils.mo" ../po/fr.po 
