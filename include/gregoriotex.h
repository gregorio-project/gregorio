/* 
Gregorio GregorioTeX output format headers.
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


#define NO_FUSION 0
#define FUSION 1


#define G_PORRECTUS_NO_BAR 35
#define G_PORRECTUS_FLEXUS_NO_BAR 36
#define G_PES_QUILISMA 37

// types for the beginning of the notes

#define T_ONE_NOTE 0
#define T_TWO_NOTES 1
#define T_PORRECTUS 2
#define T_INITIO_DEBILIS 3

void
libgregorio_gregoriotex_write_score (FILE * f, gregorio_score * score);

void
libgregorio_gregoriotex_write_voice_info (FILE * f,
					  gregorio_voice_info * voice_info);

void
libgregorio_gregoriotex_write_syllable (FILE * f,
					gregorio_syllable * syllable, char *first_syllable);

void
libgregorio_gregoriotex_write_text (FILE * f, gregorio_character *first_character, char *first_syllable);

void
libgregorio_gregoriotex_write_element (FILE * f, gregorio_syllable * syllable,
				       gregorio_element * element);

void
libgregorio_gregoriotex_write_bar (FILE * f, char type);

void
libgregorio_gregoriotex_write_glyph (FILE * f, gregorio_syllable * syllable,
				     gregorio_element * element,
				     gregorio_glyph * glyph);
void
libgregorio_gregoriotex_determine_number_and_type (gregorio_glyph *
						    glyph, int *type,
						    unsigned int
						    *glyph_number);

unsigned int
libgregorio_gregoriotex_determine_interval (gregorio_glyph * glyph);

void
libgregorio_gregoriotex_write_note (FILE * f, gregorio_note * note,
				    char next_note_pitch);

char
libgregorio_gregoriotex_determine_next_note (gregorio_syllable * syllable,
					     gregorio_element * element,
					     gregorio_glyph * glyph);

char
libgregorio_gregoriotex_syllable_first_note (gregorio_syllable * syllable);



void libgregorio_print_unicode_letters (FILE *f, wchar_t *wstr);


void libgregorio_gtex_write_begin (FILE * f, unsigned char style);
void libgregorio_gtex_write_end (FILE * f, unsigned char style);
void libgregorio_gtex_write_special_char (FILE * f, wchar_t * special_char);
void libgregorio_gtex_write_verb (FILE * f, wchar_t * verb_str);
void libgregorio_gtex_print_char (FILE * f, wchar_t to_print);
