/*
 * Gregorio GregorioTeX output format headers. Copyright (C) 2006-2008 Elie
 * Roux <elie.roux@telecom-bretagne.eu>.
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option)
 * any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 * 
 * You should have received a copy of the GNU General Public License along with 
 * this program.  If not, see <http://www.gnu.org/licenses/>. 
 */

#ifndef GREGORIOTEX_H
#define GREGORIOTEX_H

#define GREGORIOTEX_API_VERSION 20130616

#define NO_FUSION 0
#define FUSION 1

#define GLYPH_NUMBERING_START 161

/*
 * Here are the different types, they must be the same as in squarize.py 
 */

// the first are the short ones (see squarize.py)
#define T_ONE_NOTE 1
#define T_PES 2
#define T_PESQUADRATUM 3
#define T_PESQUADRATUM_LONGQUEUE 4
#define T_PESQUILISMA 5
#define T_PESQUASSUS 6
#define T_PESQUASSUS_LONGQUEUE 7
#define T_PESQUILISMAQUADRATUM 8
#define T_PESQUILISMAQUADRATUM_LONGQUEUE 9
#define T_FLEXUS 10
#define T_FLEXUS_NOBAR 11
#define T_FLEXUS_LONGQUEUE 12
#define T_FLEXUS_ORISCUS 13
// the next are the long ones
#define T_PORRECTUSFLEXUS 14
#define T_PORRECTUSFLEXUS_NOBAR 18
#define T_PORRECTUS 22
#define T_PORRECTUS_NOBAR 26
#define T_TORCULUS 30
#define T_TORCULUS_RESUPINUS 34
#define T_TORCULUS_QUILISMA 38
// only deminutus are generated for the next two
#define T_SCANDICUS 42
#define T_ANCUS 44
#define T_ANCUS_LONGQUEUE 46
#define T_SALICUS_FIRST 48
#define T_SALICUS 50
#define T_SALICUS_LONGQUEUE 52
#define T_TORCULUS_LIQUESCENS 54
#define T_TORCULUS_LIQUESCENS_QUILISMA 58
// this is a special type for the first note of a torculus resupinus flexus
#define T_ONE_NOTE_TRF 72

// the liquescentia number of GregorioTeX (different because they have to be
// between 0 and 7)
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

// we define d to be short instead of long... may induce errors, but fixes some 
// 
// too
#define is_short(pitch, glyph, element) gregoriotex_is_long(pitch, glyph, element) == 0
#define is_on_a_line(pitch) (pitch=='b' || pitch=='d' ||pitch=='f'||pitch=='h'||pitch=='j'||pitch=='l')
#define is_between_lines(pitch) (pitch=='a' || pitch=='c' ||pitch=='e'||pitch=='g'||pitch=='i'||pitch=='k'||pitch=='m')

// Here we define a function that will determine the number of the liquescentia 
// 
// that we will add to the glyph number. There are several types as all glyphs
// can't have all liquescentiae. Let's first define the different types:

#define L_ALL 0                 /* for glyphs that accept all liquecentiae */
#define L_NO_INITIO 1           /* for glyphs that don't accept initio debilis */
#define L_UNDET_AUCTUS 2        /* for glyphs for which we don't know if the
                                 * auctus is ascendens or descendens */
#define L_NONE 3                /* for glyphs that don't accept liquescentia */
#define L_ONLY_DEMINUTUS 4
#define L_NO_DEMINUTUS 5
#define L_ONLY_AUCTUS 6

// the definitions of the type and liquescentia factors
#define TYPE_FACTOR 512
#define L_LIQ_FACTOR 256
#define S_LIQ_FACTOR 64

// additional glyph types, necessary for determination
#define G_PORRECTUS_NO_BAR 45
#define G_PORRECTUS_FLEXUS_NO_BAR 46
#define G_PES_QUILISMA 47

#define HEPISEMUS_FIRST_TWO 12

// very temporary types
#define TT_H_EPISEMUS 0
#define TT_V_EPISEMUS 1
#define TT_RARE 4
#define TT_BOTTOM 3
#define TT_TOP 2
#define TT_CHORAL_SIGN 5

// some bars, to know if they are inside a syllable or if they are a syllable
#define INSIDE_BAR 0
#define SYLLABLE_BAR 1

// a structure containing the status
typedef struct gregoriotex_status
{
  unsigned char bottom_line;    // 1 if the current_glyph will have an
  // additional line under or not (useful to
  // determine the length of the bar in case of a 
  // flexa starting at d
  unsigned char to_modify_h_episemus; // to link two hepisemus that are at the
  // same pitch
  gregorio_note *to_modify_note;
} gregoriotex_status;

// a structure containing the result of seekadditionalspaces

typedef struct gregorio_line
{
  // 0, 1, 2 or 3. it is the argument of grenewlinewithspaces in
  // gregoriotex.tex
  unsigned char additional_top_space;
  unsigned char additional_bottom_space;
  // O or 1, indicates if there is a translation on the line
  unsigned char translation;
  unsigned char ictus;          // idem
  unsigned char abovelinestext; // idem
} gregorio_line;

void write_score (FILE *f, gregorio_score *score);
void gregoriotex_write_voice_info (FILE *f, gregorio_voice_info *voice_info);
void gregoriotex_write_syllable (FILE *f, gregorio_syllable *syllable,
                                 char *first_syllable,
                                 unsigned char *line_number,
                                 unsigned char first_of_disc);
void gregoriotex_write_text (FILE *f, gregorio_character *first_character,
                             char *first_syllable);
unsigned char gregoriotex_fix_style (gregorio_character *first_character);
void gregoriotex_write_translation (FILE *f, gregorio_character *translation);
void gregoriotex_write_element (FILE *f, gregorio_syllable *syllable,
                                gregorio_element *element);
void gregoriotex_write_bar (FILE *f, char type, char signs, char inorsyllable);
void gregoriotex_write_glyph (FILE *f, gregorio_syllable *syllable,
                              gregorio_element *element, gregorio_glyph *glyph);
void gregoriotex_determine_number_and_type (gregorio_glyph *glyph,
                                            gregorio_element *element,
                                            int *type, char *gtype,
                                            unsigned int *glyph_number);

unsigned int gregoriotex_determine_interval (gregorio_glyph *glyph);
void gregoriotex_write_note (FILE *f, gregorio_note *note,
                             gregorio_glyph *glyph, gregorio_element *element,
                             char next_note_pitch);

void gtex_write_begin (FILE *f, unsigned char style);
void gtex_write_end (FILE *f, unsigned char style);
void gtex_write_special_char (FILE *f, grewchar *special_char);
void gtex_write_verb (FILE *f, grewchar *verb_str);
void gtex_print_char (FILE *f, grewchar to_print);

unsigned int gregoriotex_determine_liquescentia_number (unsigned int factor,
                                                        unsigned char type,
                                                        char liquescentia);
void gregoriotex_write_vepisemus (FILE *f, gregorio_glyph *current_glyph, int i,
                                  char type, gregorio_note *current_note);
void gregoriotex_write_choral_sign (FILE *f, gregorio_glyph *glyph, char type,
                                    int i, gregorio_note *current_note,
                                    char low);
void gregoriotex_write_hepisemus (FILE *f, gregorio_glyph *current_glyph,
                                  gregorio_element *current_element, int i,
                                  char type, gregorio_note *current_note);
char gregoriotex_find_next_hepisemus_height (gregorio_glyph *glyph,
                                             gregorio_note *note,
                                             gregorio_element *element,
                                             gregorio_note **final_note);
void gregoriotex_write_rare (FILE *f, gregorio_glyph *current_glyph, int i,
                             char type, gregorio_note *current_note, char rare);
void gregoriotex_write_signs (FILE *f, char type, gregorio_glyph *glyph,
                              gregorio_element *element,
                              gregorio_note *current_note);

void gregoriotex_write_next_first_text (FILE *f,
                                        gregorio_character *current_character);
int gregoriotex_syllable_first_type (gregorio_syllable *syllable);

void gregoriotex_determine_note_number_and_type (gregorio_note *note,
                                                 gregorio_glyph *glyph,
                                                 gregorio_element *element,
                                                 int *type,
                                                 unsigned int *glyph_number);

void gtex_write_end_for_two (FILE *f, unsigned char style);

void gregoriotex_write_punctum_mora (FILE *f, gregorio_glyph *glyph, char type,
                                     gregorio_note *current_note);
void gregoriotex_write_auctum_duplex (FILE *f, gregorio_note *current_note);

void gregoriotex_find_sign_number (gregorio_glyph *current_glyph, int i,
                                   char type, char sign_type,
                                   gregorio_note *current_note, char *number,
                                   char *height, char *bottom);
void gregoriotex_write_additional_line (FILE *f, gregorio_glyph *current_glyph,
                                        int i, char type, char bottom_or_top,
                                        gregorio_note *current_note);

void gregoriotex_getlineinfos (gregorio_syllable *syllable,
                               gregorio_line *line);

char gregoriotex_clef_flat_height (char step, int line);

unsigned char gregoriotex_is_long (char pitch, gregorio_glyph *glyph,
                                   gregorio_element *element);

void gregoriotex_write_bridge_hepisemus (FILE *f, gregorio_glyph *current_glyph,
                                         gregorio_element *current_element,
                                         gregorio_syllable *current_syllable,
                                         char height);

unsigned char gregoriotex_internal_style_to_gregoriotex (unsigned char style);

void gregoriotex_print_change_line_clef (FILE *f, gregorio_element *current_element);

gregorio_element *gregoriotex_syllable_is_clef_change (gregorio_syllable
                                                       *syllable);

// a global variable... could be good to remove it, but the structure of
// gregorio
// is really flawed, and there are many many things to fix before that!
unsigned char gregoriotex_ignore_style = 0;

#endif
