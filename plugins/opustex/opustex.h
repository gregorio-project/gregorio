/* 
Gregorio OpusTeX headers.
Copyright (C) 2007 Elie Roux <elie.roux@telecom-bretagne.eu>.

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

#ifndef OPUSTEX_H
#define OPUSTEX_H

void write_score (FILE * f, gregorio_score * score);

void libgregorio_opustex_write_syllable (FILE * f,
					 gregorio_syllable * syllable,
					 char *first_syllable);

void libgregorio_opustex_write_text (FILE * f, gregorio_character *first_character,
				     char *first_syllable);

void libgregorio_opustex_write_element (FILE * f, gregorio_element * element);

void libgregorio_opustex_write_barline (FILE * f, char type);

void libgregorio_opustex_write_finis (FILE * f, char type);

void libgregorio_opustex_write_glyph (FILE * f, gregorio_glyph * glyph);

int libgregorio_opustex_first_letter (gregorio_score * score);

char libgregorio_opustex_is_vowel (int c);

char is_even (int c);

void libgregorio_opustex_print_note (FILE * f, char pitch);

void libgregorio_opustex_print_episem (FILE * f, char pitch, char length);

void libgregorio_opustex_print_episem_under (FILE * f, char pitch, char length);

const char *libgregorio_opustex_glyph_type_to_str (char name);

void
libgregorio_opustex_print_liquescentia (FILE * f, char liquescentia, char glyph);

void
libgregorio_opustex_print_augmentum_note (FILE * f, char pitch);

char
libgregorio_find_next_note (gregorio_element * current_element, gregorio_syllable * current_syllable);

char
libgregorio_opustex_is_out_of_neume (gregorio_syllable * syllable);

void libgregorio_otex_write_begin (FILE * f, unsigned char style);
void libgregorio_otex_write_end (FILE * f, unsigned char style);
void libgregorio_otex_write_special_char (FILE * f, grewchar * special_char);
void libgregorio_otex_write_verb (FILE * f, grewchar * verb_str);
void libgregorio_otex_print_char (FILE * f, grewchar to_print);

#endif
