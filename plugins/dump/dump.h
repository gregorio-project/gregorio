/* 
Gregorio dump output format headers.
Copyright (C) 2007 Elie Roux <elie.roux@enst-bretagne.fr>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef DUMP_H
#define DUMP_H

void
write_score (FILE * f, gregorio_score * score);

const char *
libgregorio_dump_key_to_char(int key);

const char *
libgregorio_dump_syllable_position (char pos);

const char *
libgregorio_dump_type (char type);

const char *
libgregorio_dump_bar_type (char element_type);

const char *
libgregorio_dump_space_type (char element_type);

const char *
libgregorio_dump_element_type (char element_type);

const char *
libgregorio_dump_liquescentia (char liquescentia);

const char *
libgregorio_dump_glyph_type (char glyph_type);

const char *
libgregorio_dump_shape (char shape);

const char *
libgregorio_dump_signs (char signs);

const char *
libgregorio_dump_rare_sign (char rare_sign);

const char *
libgregorio_dump_h_episemus_type (char h_episemus_type);

void
libgregorio_dump_write_characters (FILE * f, gregorio_character * current_character);

const char *
libgregorio_dump_style_to_string (unsigned char style);

#endif
