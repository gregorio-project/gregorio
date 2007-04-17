/* 
Gregorio dump output format headers.
Copyright (C) 2007 Olivier Berten.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/


void
libgregorio_dump_score (FILE * f, gregorio_score * score);

char *
libgregorio_dump_key_to_char(int key);

char *
libgregorio_dump_syllable_position (char pos);

char *
libgregorio_dump_type (char type);

char *
libgregorio_dump_bar_type (char element_type);

char *
libgregorio_dump_space_type (char element_type);

char *
libgregorio_dump_element_type (char element_type);

char *
libgregorio_dump_liquescentia (char liquescentia);

char *
libgregorio_dump_glyph_type (char glyph_type);

char *
libgregorio_dump_shape (char shape);

char *
libgregorio_dump_signs (char signs);

char *
libgregorio_dump_h_episemus_type (char h_episemus_type);

