/*
 * Copyright (C) 2006-2015 The Gregorio Project (see CONTRIBUTORS.md)
 *
 * This file is part of Gregorio.
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

#include <stdbool.h>
#include "struct.h"

#define GREGORIO_VERSION "3.0.0-rc2"

#define NO_FUSION 0
#define FUSION 1

/*
 * Here are the different types, they must be the same as in squarize.py 
 */

typedef enum gtex_type {
    // the first are the short ones (see squarize.py)
    T_ONE_NOTE = 1,
    T_PES = 2,
    T_PESQUADRATUM = 3,
    T_PESQUADRATUM_LONGQUEUE = 4,
    T_PESQUILISMA = 5,
    T_PESQUASSUS = 6,
    T_PESQUASSUS_LONGQUEUE = 7,
    T_PESQUILISMAQUADRATUM = 8,
    T_PESQUILISMAQUADRATUM_LONGQUEUE = 9,
    T_FLEXUS = 10,
    T_FLEXUS_NOBAR = 11,
    T_FLEXUS_LONGQUEUE = 12,
    T_FLEXUS_ORISCUS = 13,
    T_FLEXUS_ORISCUS_SCAPUS = 62,
    T_FLEXUS_ORISCUS_SCAPUS_LONGQUEUE = 63,
    // the next are the long ones
    T_PORRECTUSFLEXUS = 14,
    T_PORRECTUSFLEXUS_NOBAR = 18,
    T_PORRECTUS = 22,
    T_PORRECTUS_NOBAR = 26,
    T_TORCULUS = 30,
    T_TORCULUS_RESUPINUS = 34,
    T_TORCULUS_QUILISMA = 38,
    T_TORCULUS_LIQUESCENS = 54,
    T_TORCULUS_LIQUESCENS_QUILISMA = 58,
    // only deminutus are generated for the next two
    T_SCANDICUS = 42,
    T_ANCUS = 44,
    T_ANCUS_LONGQUEUE = 46,
    T_VIRGA_STRATA = 48,
    T_SALICUS = 50,
    T_SALICUS_LONGQUEUE = 52,
    // this is a special type for the first note of a torculus resupinus flexus
    T_ONE_NOTE_TRF = 72,
    // the next type value; don't use this directly, but keep it updated
    // as types are added to this enum
    T_NEXT_TYPE = 64,
} gtex_type;

// the different types for the alignment of the notes in GregorioTeX
typedef enum gtex_alignment {
    AT_ONE_NOTE = 0,
    AT_FLEXUS = 1,
    AT_PORRECTUS = 2,
    AT_INITIO_DEBILIS = 3,
    AT_QUILISMA = 4,
    AT_ORISCUS = 5,
    AT_PUNCTUM_INCLINATUM = 6,
    AT_STROPHA = 7,
    AT_FLEXUS_1 = 8,
    AT_FLEXUS_DEMINUTUS = 9,
} gtex_alignment;

// Here we define a function that will determine the number of the
// liquescentia that we will add to the glyph number. There are several types
// as all glyphs can't have all liquescentiae. Let's first define the
// different types:

typedef enum gtex_glyph_liquescentia {
    // for glyphs that accept all liquecentiae
    LG_ALL = 0,
    // for glyphs that don't accept initio debilis
    LG_NO_INITIO,
    // for glyphs for which we don't know if the auctus is ascendens or descendens
    LG_UNDET_AUCTUS,
    // for glyphs that don't accept liquescentia
    LG_NONE,
    LG_ONLY_DEMINUTUS,
    LG_NO_DEMINUTUS,
    LG_ONLY_AUCTUS,
} gtex_glyph_liquescentia;

typedef enum gtex_sign_type {
    ST_H_EPISEMUS = 0,
    ST_V_EPISEMUS = 1,
} gtex_sign_type;

#define HEPISEMUS_FIRST_TWO 12

// a structure containing the status
typedef struct gregoriotex_status {
    unsigned char bottom_line;  // 1 if the current_glyph will have an
    // additional line under or not (useful to
    // determine the length of the bar in case of a 
    // flexa starting at d
    unsigned char to_modify_h_episemus; // to link two hepisemus that are at
    // the
    // same pitch
    gregorio_note *to_modify_note;
} gregoriotex_status;

// a structure containing the result of seekadditionalspaces
typedef struct gregorio_line {
    // 0, 1, 2 or 3. it is the argument of grenewlinewithspaces in
    // gregoriotex.tex
    unsigned char additional_top_space;
    unsigned char additional_bottom_space;
    // O or 1, indicates if there is a translation on the line
    unsigned char translation;
    unsigned char ictus;        // idem
    unsigned char abovelinestext;   // idem
} gregorio_line;

// glyph structures

#define MAX_AMBITUS 5

typedef union gtex_glyph_table {
    const int (* const two_note);
    const int (* const three_note)[MAX_AMBITUS];
    const int (* const four_note)[MAX_AMBITUS][MAX_AMBITUS];
} gtex_glyph_table;

// Note: gtex_multinote_shape is a POINTER to struct gtex_multinote_shape
typedef struct gtex_multinote_shape {
    const int notes;
    const char * const name;
    const union gtex_glyph_table Nothing;
    const union gtex_glyph_table InitioDebilis;
    const union gtex_glyph_table Deminutus;
    const union gtex_glyph_table Ascendens;
    const union gtex_glyph_table Descendens;
    const union gtex_glyph_table InitioDebilisDeminutus;
    const union gtex_glyph_table InitioDebilisAscendens;
    const union gtex_glyph_table InitioDebilisDescendens;
} const *gtex_multinote_shape;

void write_score(FILE *f, gregorio_score *score);
void gregoriotex_write_voice_info(FILE *f, gregorio_voice_info *voice_info);
void gregoriotex_write_syllable(FILE *f, gregorio_syllable *syllable,
        char *first_syllable,
        unsigned char *line_number, unsigned char first_of_disc);
void gregoriotex_write_text(FILE *f, gregorio_character *first_character,
        char *first_syllable, int);
grestyle_style gregoriotex_fix_style(gregorio_character *first_character);
void gregoriotex_write_translation(FILE *f, gregorio_character *translation);
void gregoriotex_write_element(FILE *f, gregorio_syllable *syllable,
        gregorio_element *element);
void gregoriotex_write_bar(FILE *f, gregorio_bar type, gregorio_sign signs,
        bool is_inside_bar);
void gregoriotex_write_glyph(FILE *f, gregorio_syllable *syllable,
        gregorio_element *element, gregorio_glyph *glyph);

void gregoriotex_write_note(FILE *f, gregorio_note *note,
        gregorio_glyph *glyph, gregorio_element *element, char next_note_pitch);

void gtex_write_begin(FILE *f, grestyle_style style);
void gtex_write_end(FILE *f, grestyle_style style);
void gtex_write_special_char(FILE *f, grewchar *special_char);
void gtex_write_verb(FILE *f, grewchar *verb_str);
void gtex_print_char(FILE *f, grewchar to_print);

void gregoriotex_write_vepisemus(FILE *f, gregorio_glyph *current_glyph, int i,
        gtex_type type, gregorio_note *current_note);
void gregoriotex_write_choral_sign(FILE *f, gregorio_glyph *glyph,
        gtex_type type, int i, gregorio_note *current_note, char low);
void gregoriotex_write_hepisemus(FILE *f, gregorio_glyph *current_glyph,
        gregorio_element *current_element, int i, gtex_type type,
        gregorio_note *current_note);
char gregoriotex_find_next_hepisemus_height(gregorio_glyph *glyph,
        gregorio_note *note, gregorio_element *element,
        gregorio_note **final_note);
void gregoriotex_write_rare(FILE *f, gregorio_glyph *current_glyph, int i,
        gtex_type type, gregorio_note *current_note, gregorio_sign rare);
void gregoriotex_write_signs(FILE *f, gtex_type type, gregorio_glyph *glyph,
        gregorio_element *element, gregorio_note *current_note);
int gregoriotex_syllable_first_type(gregorio_syllable *syllable);

void gtex_write_end_for_two(FILE *f, grestyle_style style);

void gregoriotex_write_punctum_mora(FILE *f, gregorio_glyph *glyph,
        gtex_type type, gregorio_note *current_note);
void gregoriotex_write_auctum_duplex(FILE *f, gregorio_note *current_note);

void gregoriotex_find_sign_number(gregorio_glyph *current_glyph, int i,
        gtex_type type, gtex_sign_type sign_type, gregorio_note *current_note,
        char *number, char *height, bool *bottom);
void gregoriotex_write_additional_line(FILE *f, gregorio_glyph *current_glyph,
        int i, gtex_type type, bool bottom, gregorio_note *current_note);

void gregoriotex_getlineinfos(gregorio_syllable *syllable, gregorio_line *line);

char gregoriotex_clef_flat_height(char step, int line);

unsigned char gregoriotex_is_long(char pitch, gregorio_glyph *glyph,
        gregorio_element *element);

void gregoriotex_write_bridge_hepisemus(FILE *f, gregorio_glyph *current_glyph,
        gregorio_element *current_element,
        gregorio_syllable *current_syllable, char height);

unsigned char gregoriotex_internal_style_to_gregoriotex(grestyle_style style);

void gregoriotex_print_change_line_clef(FILE *f,
        gregorio_element *current_element);

gregorio_element *gregoriotex_syllable_is_clef_change(gregorio_syllable
        *syllable);

// a global variable... could be good to remove it, but the structure of
// gregorio is really flawed, and there are many many things to fix before
// that!
unsigned char gregoriotex_ignore_style;

#endif
