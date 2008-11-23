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

#ifndef GREGORIOTEX_H
#define GREGORIOTEX_H

#define NO_FUSION 0
#define FUSION 1

/*
Here are the different types, they must be the same as in squarize.py
*/

// the first are the short ones (see squarize.py)
#define T_ONE_NOTE 1
#define T_PES 2
#define T_PESQUADRATUM 3
#define T_PESQUILISMA 4
#define T_PESQUASSUS 5
#define T_PESQUILISMAQUADRATUM 6
#define T_FLEXUS 7
#define T_FLEXUS_NOBAR 8
#define T_FLEXUS_LONGQUEUE 9
// the next are the long ones
#define T_PORRECTUSFLEXUS 12
#define T_PORRECTUSFLEXUS_NOBAR 16
#define T_PORRECTUS 20
#define T_PORRECTUS_NOBAR 24
#define T_TORCULUS 28
#define T_TORCULUS_RESUPINUS 32
#define T_TORCULUS_QUILISMA 36

// the liquescentia number of GregorioTeX (different because they have to be between 0 and 7)
#define GL_NO_LIQUESCENTIA 0
#define GL_INITIO_DEBILIS 1
#define GL_DEMINUTUS 2
#define GL_AUCTUS_ASCENDENS 3
#define GL_AUCTUS_DESCENDENS 4
#define GL_DEMINUTUS_INITIO_DEBILIS 5
#define GL_AUCTUS_ASCENDENS_INITIO_DEBILIS 6
#define GL_AUCTUS_DESCENDENS_INITIO_DEBILIS 7

// the different types for the alignment of the notes in GregorioTeX
#define AT_ONE_NOTE 0
#define AT_FLEXUS 1
#define AT_PORRECTUS 2
#define AT_INITIO_DEBILIS 3
#define AT_QUILISMA 4
#define AT_ORISCUS 5
#define AT_PUNCTUM_INCLINATUM 6
#define AT_STROPHA 7
#define AT_FLEXUS_1 8
#define AT_FLEXUS_DEMINUTUS 9

// the fonts
#define F_GREGORIO 1
#define F_PARMESAN 2
#define F_GREGORIA 3
#define F_GRECILIAE 4

// macro that we will use to determine if we need a short bar or not

#define is_short(pitch) pitch=='a'||pitch=='c'||pitch=='e'||pitch=='g'||pitch=='i'||pitch=='k'||pitch=='m'

// Here we define a function that will determine the number of the liquescentia that we will add to the glyph number. There are several types as all glyphs can't have all liquescentiae. Let's first define the different types:

#define L_ALL 0			/* for glyphs that accept all liquecentiae */
#define L_NO_INITIO 1		/* for glyphs that don't accept initio debilis */
#define L_UNDET_AUCTUS 2	/* for glyphs for which we don't know if the auctus is ascendens or descendens */
#define L_NONE 3		/* for glyphs that don't accept liquescentia */
#define L_ONLY_DEMINUTUS 4
#define L_NO_DEMINUTUS 5

// the definitions of the type and liquescentia factors
#define TYPE_FACTOR 512
#define L_LIQ_FACTOR 256
#define S_LIQ_FACTOR 64

// additional glyph types, necessary for determination
#define G_PORRECTUS_NO_BAR 40
#define G_PORRECTUS_FLEXUS_NO_BAR 41
#define G_PES_QUILISMA 42

#define HEPISEMUS_FIRST_TWO 0

// very temporary types
#define TT_H_EPISEMUS 0
#define TT_V_EPISEMUS 1
#define TT_BOTTOM 2
#define TT_TOP 1

// a structure containing the result of seekadditionalspaces

typedef struct gregorio_line {
unsigned char additional_top_space; // 0, 1, 2 or 3. it is the argument of
// grenewlinewithspaces in gregoriotex.tex
unsigned char additional_bottom_space;
unsigned char translation; // O or 1, indicates if there is a translation on
// the line
} gregorio_line;



void write_score (FILE * f, gregorio_score * score);
void libgregorio_gregoriotex_write_voice_info (FILE * f, gregorio_voice_info * voice_info);
void libgregorio_gregoriotex_write_syllable (FILE * f, gregorio_syllable * syllable, char *first_syllable, unsigned char *line_number);
void libgregorio_gregoriotex_write_text (FILE * f, gregorio_character *first_character, char *first_syllable);
void libgregorio_gregoriotex_write_translation (FILE *f, gregorio_character *translation);
void libgregorio_gregoriotex_write_element (FILE * f, gregorio_syllable * syllable, gregorio_element * element);
void libgregorio_gregoriotex_write_bar (FILE * f, char type);
void libgregorio_gregoriotex_write_glyph (FILE * f, gregorio_syllable * syllable, gregorio_element * element, gregorio_glyph * glyph);
void libgregorio_gregoriotex_determine_number_and_type (gregorio_glyph *glyph, int *type, char *gtype, unsigned int *glyph_number);

unsigned int libgregorio_gregoriotex_determine_interval (gregorio_glyph * glyph);
void libgregorio_gregoriotex_write_note (FILE * f, gregorio_note * note, char next_note_pitch);
char libgregorio_gregoriotex_determine_next_note (gregorio_syllable * syllable, gregorio_element * element, gregorio_glyph * glyph);

char libgregorio_gregoriotex_syllable_first_note (gregorio_syllable * syllable);
void libgregorio_print_unicode_letters (FILE *f, wchar_t *wstr);
void libgregorio_gtex_write_begin (FILE * f, unsigned char style);
void libgregorio_gtex_write_end (FILE * f, unsigned char style);
void libgregorio_gtex_write_special_char (FILE * f, wchar_t * special_char);
void libgregorio_gtex_write_verb (FILE * f, wchar_t * verb_str);
void libgregorio_gtex_print_char (FILE * f, wchar_t to_print);

unsigned int gregoriotex_determine_liquescentia_number (unsigned int factor, unsigned char type, char liquescentia);
void libgregorio_gregoriotex_write_vepisemus (FILE * f, gregorio_glyph * current_glyph, int i, char type, gregorio_note * current_note);
void libgregorio_gregoriotex_write_hepisemus (FILE * f, gregorio_glyph * current_glyph, int i, char type, gregorio_note * current_note);
void libgregorio_gregoriotex_write_signs (FILE * f, char type, gregorio_glyph * glyph, gregorio_note * current_note);

void libgregorio_gregoriotex_write_next_first_text (FILE * f, gregorio_character *current_character);
int libgregorio_gregoriotex_syllable_first_type (gregorio_syllable * syllable);
gregorio_glyph * libgregorio_gregoriotex_first_glyph (gregorio_syllable * syllable);

void libgregorio_gregoriotex_determine_note_number_and_type (gregorio_note * note, int *type, unsigned int *glyph_number);

void libgregorio_gtex_write_end_for_two (FILE * f, unsigned char style);

void libgregorio_gregoriotex_write_punctum_mora (FILE * f, gregorio_glyph * glyph, gregorio_note * current_note);
void libgregorio_gregoriotex_write_auctum_duplex (FILE * f, gregorio_glyph * glyph, gregorio_note * current_note);

void libgregorio_gregoriotex_find_sign_number (gregorio_glyph * current_glyph, int i, char type, char sign_type, gregorio_note * current_note, char *number, char *height);

void libgregorio_gregoriotex_write_additional_line (FILE * f, gregorio_glyph *current_glyph, int i, char type, char bottom_or_top, gregorio_note * current_note);

void libgregorio_gregoriotex_seeklinespaces (gregorio_syllable * syllable, gregorio_line * line);
#endif
