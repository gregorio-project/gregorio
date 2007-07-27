/* 
Gregorio gabc format headers.
Copyright (C) 2006 Elie Roux

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

#ifndef GABC_H
#define GABC_H

// functions to read gabc
gregorio_score * libgregorio_gabc_read_file (FILE * f);
void libgregorio_activate_isolated_h_episemus (gregorio_note *current_note, int n);
void libgregorio_mix_h_episemus (gregorio_note *current_note, char type);
char libgregorio_det_shape (char pitch);

gregorio_note *libgregorio_gabc_det_notes_from_string (char *str);
gregorio_glyph * libgregorio_gabc_det_glyphs_from_string (char *str);
gregorio_element *libgregorio_gabc_det_elements_from_string (char *str);

gregorio_element *libgregorio_gabc_det_elements_from_notes (gregorio_note *current_note);
gregorio_element *libgregorio_gabc_det_elements_from_glyphs (gregorio_glyph * current_glyph);
gregorio_glyph *libgregorio_gabc_det_glyphs_from_notes (gregorio_note *current_note);

// see comments on libgregorio_add_note_to_a_glyph for meaning of these variables
#define DET_NO_END 'A'
#define DET_END_OF_CURRENT 'B'
#define DET_END_OF_PREVIOUS 'C'
#define DET_END_OF_BOTH 'D'

// defines the maximal interval between two notes of the same glyph
#define MAX_INTERVAL 4

// functions to write gabc
void libgregorio_gabc_write_score (FILE * f, gregorio_score * score);
void libgregorio_gabc_write_voice_info (FILE * f, gregorio_voice_info * voice_info);
void libgregorio_gabc_write_gregorio_syllable (FILE * f, gregorio_syllable * syllable, int number_of_voices);
void libgregorio_gabc_write_gregorio_elements (FILE * f, gregorio_element * element);
void libgregorio_gabc_write_gregorio_element (FILE * f, gregorio_element * element);
void libgregorio_gabc_write_gregorio_glyph (FILE * f, gregorio_glyph * glyph);
void libgregorio_gabc_write_end_liquescentia (FILE * f, char liquescentia);
void libgregorio_gabc_write_key_change (FILE * f, char step, int line);
void libgregorio_gabc_write_space (FILE * f, char type);
void libgregorio_gabc_write_bar (FILE * f, char type);
void libgregorio_gabc_write_gregorio_note (FILE * f, gregorio_note * note, char glyph_type);
void libgregorio_gabc_write_begin (FILE * f, unsigned char style);
void libgregorio_gabc_write_end (FILE * f, unsigned char style);
void libgregorio_gabc_write_special_char (FILE * f, wchar_t * special_char);
void libgregorio_gabc_write_verb (FILE * f, wchar_t * verb_str);
void libgregorio_gabc_print_char (FILE * f, wchar_t to_print);

#endif
