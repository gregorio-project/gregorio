/*
Gregorio structure manipulation headers.
Copyright (C) 2006-2010 Elie Roux <elie.roux@telecom-bretagne.eu>

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

/**
 * @file
 * The file starts by the definition of all the structures used in
 * gregorio. As it is certainly the most important file for
 * understanding, read it carefully.
 */

#include <gregorio/unicode.h>

#ifndef STRUCT_H
#define STRUCT_H

#ifdef __cplusplus
extern "C" {
#endif

/*!
 *
 * We start with the most precise structure, the note structure. The note
 * is always a real note (we'll see that glyphs and elements can be other
 * things).
 */
typedef struct gregorio_note {
// we have seen that notes are always real notes, that is to say
// GRE_NOTE. the type is always that in the final structure. But there
// is however this field in the structure because of the temporary
// states that can appear in the determination, where notes can be
// other things. This is the case for example in gabc reading.
  char type;
// then two pointer to other notes, to make a chained list.
  struct gregorio_note *previous;
  struct gregorio_note *next;
/// the pitch is the height of the note on the score, that is to say the letter it is represented by in gabc.
  char pitch;
// shape is the shape of the note... if you want to know the different
// possible shapes, see below.
  char shape;
// signs is the signs on the notes, see below for all possible values
  char signs;
// rare_sign is the sign we sometimes encounter on punctum cavum, like
// accentus, semi-circulus, etc. can also be the ictus
  char rare_sign;
// choral sign is a letter that appears next to a note in some choral scores
// we put it as char* because sometimes two letters appear
  char *choral_sign;
// liquescentia is the liquescence on the note, it is not really used
// in the final score, but it is, like type, used in the determination
// of glyphs.
  char liquescentia;
// h_episemus_type is the type of horizontal episemus, possible values
// are H_ALONE for an isolated horizontal episemus, H_MULTI_BEGINNING
// if the note is the first note of an episemus on several notes,
// H_MULTI_MIDDLE if it is inside an episemus on several notes. I let
// you guess what could be the use of H_MULTI_END. Other values are
// temporary values used in determination, they must not appear in the
// final structure.
  unsigned char h_episemus_type;
// h_episemus_top_note is the highest pitch of the notes that are
// under the same horizontal episemus of the note. If the note is not
// under an episemus, it is 0.
  char h_episemus_top_note;
// a string containing a possible TeX verbatim; necessary during
// structure generation.
  char *texverb;
} gregorio_note;
  
/*!
 * @brief The gregorio glyph structure
 *
 * Unlike gregorio_note, gregorio_glyph can be other things besides \c GRE_GLYPH: 
 * it can also be \c GRE_FLAT, \c GRE_NATURAL or \c GRE_SPACE
 */
typedef struct gregorio_glyph {
// type can have the values explained in the comment just above.
  char type;
// two pointer to make a chained list
  struct gregorio_glyph *previous;
  struct gregorio_glyph *next;
// in the case of a GRE_GLYPH, glyph_type is the type of the glyph
// (porrectus, pes, etc.), they are all listed below. If it is a
// GRE_FLAT or a GRE_NATURAL, it is the height of the flat or natural
// that will be represented. If it is GRE_SPACE, it is the kind of
// space it is (they are listed below). As a matter of fact, a
// GRE_SPACE in a gregorio_glyph can have only one value:
// SP_ZERO_WIDTH, as other spaces would break the glyphs into
// different elements.
  char glyph_type;
// liquescentia is really used, because that will determine the shape
// we will have to use.
// it may also contain additional informations (a bit hacky)
  char liquescentia;
// a pointer to a (chained list of) gregorio_notes, the first of the
// glyph.
  struct gregorio_note *first_note;
// a string containing a possible TeX verbatim; necessary during
// structure generation.
  char *texverb;
} gregorio_glyph;

typedef struct gregorio_element {
// type can have the values GRE_ELEMENT, GRE_BAR, GRE_C_KEY_CHANGE,
// GRE_F_KEY_CHANGE, GRE_END_OF_LINE or GRE_SPACE.
  char type;
// pointers to the next and previous elements.
  struct gregorio_element *previous;
  struct gregorio_element *next;
// in the case of a GRE_ELEMENT, element_type is the kind of element
// it is (but it is very blur.. don't watch this value). In the case
// of a GRE_BAR it is the type of bar (listed below). If it is
// GRE_*_KEY_CHANGE, it is 0. If it is GRE_SPACE, it is the kind of
// space (it can't be SP_ZERO_WIDTH).
  char element_type;
// contain additional informations, like for example bar signs, or if
// the key has a flat or not
  char additional_infos;
// a pointer to the first glyph of the element.
  struct gregorio_glyph *first_glyph;
// a string containing a possible TeX verbatim.
  char *texverb;
} gregorio_element;

/*

The we define the characters. First we define the different styles. You can notice that center is just a style like the others

*/

#define ST_NO_STYLE 0
#define ST_ITALIC 1
#define ST_CENTER 6
#define ST_FORCED_CENTER 8 // when the user types a {}, basically the same behaviour, except for the initial
#define ST_BOLD 2
#define ST_TT 3
#define ST_SMALL_CAPS 7
#define ST_SPECIAL_CHAR 4
#define ST_VERBATIM 5
#define ST_INITIAL 9 // a style used to determine the initial
#define ST_UNDERLINED 10

/*

Then the different types of styles. See the next comments for further readings.

*/

#define ST_T_NOTHING 0
#define ST_T_BEGIN 1
#define ST_T_END 2

/*

gregorio_characters are a bit specials. As there can be styles in the text, I had to find a structure mode adapted that just grewchar *. So basically a gregorio_character is a double-chained list of things that can be grewchar or gregorio_styles. For example if you type (in gabc) p<i>o</i>t, the corresponding gregorio_character list will be P->style(type: beginning, style italic) -> o -> style(type:end, style: italic). But for this list to be coherent, it is mandatory that it is xml-compliant, that is to say that a<b>c<i>d</b>e</i> will be interpreted as a<b>c<i>d</i></b><i>e</i>. This MUST be done when reading a file, so that the structure in memory is coherent. It makes input modules more comple, but output modules muche more simpler. The last particularity is that center must also be determined in the input modules, so that it is already defined in memory. But it is a bit more complex, because for TeX-like output modules, we need to close all styles before the center style: if the user types <i>pot</i> it must be represented as <i>p</i>{<i>o</i>}<i>t</i>.

Here is the declaration of the gregorio_style struct. It is simply two chars, one telling the type of style character it is (beginning for a character that marks the beginning of a style, and end for a character marking the end of a style). The other char simply is the style represented by the character (italic, etc.)

*/

typedef struct gregorio_style {
  unsigned char style;
  unsigned char type;
} gregorio_style;

/*

This union is quite ugly... but necessary for a gregorio_character to be able to be a grewchar or gregorio_style.

*/
typedef union character_or_style {
  grewchar character;
  struct gregorio_style s;
} character_or_style;

/*

Finally the gregorio_character structure in itself, It is first a char determining the type (character or gregorio_style).
This char is 0 when it is a style and something else when it is a character.
Then the two pointers to build the double chained list, and finally the union. So when you want to access to the style of a gregorio_character (when you know it is a character of style), you must access to mygregoriochar.cos.s.style, and for the character mygregoriochar.cos.character .

*/

typedef struct gregorio_character {
  unsigned char is_character;
  struct gregorio_character *next_character;
  struct gregorio_character *previous_character;
  union character_or_style cos;
} gregorio_character;

typedef struct gregorio_syllable {
// a syllable can be a GRE_SYLLABLE, a GRE_*_KEY_CHANGE or a
// GRE_BAR. It is useful when there is only that in a syllable.
  char type;
// position is WORD_BEGINNING for the beginning of a multi-syllable
// word, WORD_ONE_SYLLABLE for syllable that are alone in their word,
// and i let you gess what are WORD_MIDDLE and WORD_END.
  char position;
// again, an additional field to put some signs or other things...
  char additional_infos;
// pointer to a gregorio_text structure corresponding to the text.
  struct gregorio_character *text;
// pointer to a gregorio_text structure corresponding to the translation
  struct gregorio_character *translation;
// a string representing the text above the lines (raw TeX)
  char *abovelinestext;
// pointer to the next and previous syllable
  struct gregorio_syllable *next_syllable;
  struct gregorio_syllable *previous_syllable;
// and finally a pointer to the elements of the structure. Here we see
// that we point to an array of elements. In fact it is the array of
// the first elements of the different voices of the syllable, for the
// case of polyphonic score. In most scores (monophonic), the array
// has only one element.
  struct gregorio_element ** elements;
} gregorio_syllable;

  // The items in source_info used to be -- well, most of them -- in
  // gregorio_voice_info.  This is because the different `voices' may
  // in future be used for different variants of a melody:
  // e.g. notated in square notation, notated in some early neumatic
  // form from manuscript A, and another in manuscript B.  In that
  // case the different voices would naturally have different source
  // info.  However, this enhancement to gregorio is not yet planned,
  // and so this structure is made part of gregorio_score.
typedef struct source_info {
  char *author;
  char *date;
  char *manuscript;
  char *manuscript_reference; // was reference
  char *manuscript_storage_place; // was storage_place
  char *book;
  char *transcriber;
  char *transcription_date;
} source_info;

/*

Score is the top structure, the structure in which we will convert
everything, and from which we will construct XML

*/

typedef struct gregorio_score {
// the structure starts by a pointer to the first syllable of the
// score.
  struct gregorio_syllable *first_syllable;
// the number of voices is very important. In monophony it is one. If
// there are more voices thant number_of_voices, the additional voices
// won't be taken into consideration.
  int number_of_voices;
// then start some metadata:
  char *name;
  char *gabc_copyright;
  char *score_copyright;
  char *office_part;
  char *occasion;
  // the meter, numbers of syllables per line, as e.g. 8.8.8.8
  char *meter;
  char *commentary;
  char *arranger;
  struct source_info si;
// the mode of a song is between 1 and 8
  char mode;
// field giving informations on the initial (no initial, normal initial or two lines initial)
  char initial_style;
// these preambles will be added (in the future) as preamble in case
// of OpusTeX, MusiXTeX or Lilypond output.
  char *lilypond_preamble;
  char *opustex_preamble;
  char *musixtex_preamble;
// the font to use in gregoriotex
  char *gregoriotex_font;
  char *user_notes;
// the determination method (maximal ambitus, etc.)
  unsigned char det_method;
// then, as there are some metadata that are voice-specific, we add a
// pointer to the first voice_info. (see comments below)
  struct gregorio_voice_info *first_voice_info;
} gregorio_score;

/*

gregorio_voice info contains everything that is voice_specific, for
example the key, etc. that can be different from one voice to
another. The order of the voice_info (it is a chained list) is the
same as the order of the voices (from top to bottom in their
representation on the score).

*/

#define NUM_ANNOTATIONS 2

typedef struct gregorio_voice_info {
// the only thing that is worth a comment here is the key. We have a
// special representation for the key. See comments on
// src/struct-utils.c for further reading.
  int initial_key;
  char flatted_key;
  // There is one annotation for each line above the initial letter
  char *annotation[NUM_ANNOTATIONS];
  // See source_info above for comments about the move of author etc.
  char *style;
  char *virgula_position;
  struct gregorio_voice_info *next_voice_info;
} gregorio_voice_info;

gregorio_score *gregorio_new_score(void);
void gregorio_source_info_init (source_info *si);

void
gregorio_determine_h_episemus_type (gregorio_note * note);

void gregorio_activate_isolated_h_episemus (gregorio_note *current_note, int n);
void gregorio_mix_h_episemus (gregorio_note *current_note, unsigned char type);
char gregorio_det_shape (char pitch);

void gregorio_add_note(gregorio_note **current_note, char pitch, char shape, char signs, char liquescentia,char h_episemus);
void gregorio_add_glyph (gregorio_glyph **current_glyph, char type, gregorio_note *first_note, char liquescentia);
void gregorio_add_element (gregorio_element **current_element, gregorio_glyph *first_glyph);
void gregorio_add_syllable (gregorio_syllable ** current_syllable,
			  int number_of_voices, gregorio_element * elements[],
			  gregorio_character * first_character, gregorio_character *first_translation_character, char position, char *abovelinestext);

void gregorio_set_signs (gregorio_note *current_note, char signs);
void gregorio_add_special_sign (gregorio_note *current_note, char sign);
void gregorio_change_shape (gregorio_note *note, char shape);
void gregorio_add_h_episemus (gregorio_note *note, unsigned char type, unsigned int *nbof_isolated_episemus);
void gregorio_set_h_episemus(gregorio_note *note, unsigned char type);
void gregorio_add_sign (gregorio_note *note, char sign);
void gregorio_add_liquescentia (gregorio_note *note, char liquescentia);

void gregorio_add_voice_info (gregorio_voice_info **current_voice_info);

void gregorio_free_notes(gregorio_note **first_note);
void gregorio_free_glyphs(gregorio_glyph **glyph);
void gregorio_free_elements (gregorio_element ** element);
void gregorio_free_syllables (gregorio_syllable ** syllable, int number_of_voices);
void gregorio_free_score_infos (gregorio_score * score);
void gregorio_free_voice_infos (gregorio_voice_info *voice_info);
void gregorio_free_source_info (source_info *si);

void gregorio_free_one_note(gregorio_note **note);
void gregorio_free_one_glyph(gregorio_glyph **glyph);
void gregorio_free_one_element(gregorio_element **element);
void gregorio_free_one_syllable (gregorio_syllable **syllable, int number_of_voices);
void gregorio_free_score(gregorio_score *score);

void gregorio_go_to_first_character (gregorio_character ** character);
void gregorio_add_text (char *mbcharacters, gregorio_character **current_character);

void gregorio_add_special_as_glyph (gregorio_glyph **current_glyph, char type, char pitch, char additional_infos, char *texverb);
void gregorio_add_special_as_note (gregorio_note **current_note, char type, char pitch);
void gregorio_add_texverb_as_note (gregorio_note **current_note, char *str, char type);
void gregorio_add_texverb_to_note (gregorio_note **current_note, char *str);
void gregorio_add_cs_to_note (gregorio_note **current_note, char *str);
void gregorio_add_special_as_element (gregorio_element **current_element, char type, char pitch, char additional_infos, char *texverb);

void gregorio_determine_good_top_notes (gregorio_note * current_note);

void gregorio_reinitialize_alterations (char alterations[][13], int number_of_voices);

void gregorio_reinitialize_one_voice_alterations (char alterations[13]);

void
gregorio_set_score_name (gregorio_score * score, char *name);
void
gregorio_set_score_gabc_copyright (gregorio_score * score, char *gabc_copyright);
void
gregorio_set_score_score_copyright (gregorio_score * score, char *score_copyright);
void
gregorio_set_score_office_part (gregorio_score * score, char *office_part);
void
gregorio_set_score_occasion (gregorio_score * score, char *occasion);
void
gregorio_set_score_meter (gregorio_score * score, char *meter);
void
gregorio_set_score_commentary (gregorio_score * score, char *commentary);
void
gregorio_set_score_arranger (gregorio_score * score, char *arranger);
void
gregorio_set_score_gabc_version (gregorio_score * score, char *gabc_version);
void
gregorio_set_score_number_of_voices (gregorio_score * score, int number_of_voices);
void
gregorio_set_score_lilypond_preamble (gregorio_score * score,
				    char *lilypond_preamble);
void
gregorio_set_score_opustex_preamble (gregorio_score * score, char *opustex_preamble);
void
gregorio_set_score_musixtex_preamble (gregorio_score * score,
				    char *musixtex_preamble);
void
gregorio_set_voice_annotation (gregorio_voice_info * voice_info, char *annotation);
void
gregorio_set_score_author (gregorio_score * score, char *author);
void
gregorio_set_score_date (gregorio_score * score, char *date);
void
gregorio_set_score_manuscript (gregorio_score * score, char *manuscript);
void
gregorio_set_score_book (gregorio_score * score, char *book);
void
gregorio_set_score_manuscript_reference (gregorio_score * score, char *reference);
void
gregorio_set_score_manuscript_storage_place (gregorio_score * score, char *storage_place);
void
gregorio_set_score_transcriber (gregorio_score * score, char *transcriber);
void
gregorio_set_score_transcription_date (gregorio_score * score, char *transcription_date);
void
gregorio_set_score_user_notes (gregorio_score * score, char *user_notes);
void
gregorio_set_voice_style (gregorio_voice_info * voice_info, char *style);
void
gregorio_set_voice_virgula_position (gregorio_voice_info * voice_info, char *virgula_position);
void
gregorio_set_voice_annotation (gregorio_voice_info * voice_info, char *annotation);

void
gregorio_fix_initial_keys (gregorio_score * score, int default_key);

/*void
gregorio_fix_positions (gregorio_score * score);*/

void gregorio_go_to_first_note (gregorio_note **note);
void gregorio_go_to_first_glyph (gregorio_glyph **glyph);

char gregorio_add_note_to_a_glyph (char glyph, char current_pitch, char last_pitch, char shape, char *end_of_glyph);
void gregorio_det_step_and_line_from_key (int key, char *step, int *line);

char gregorio_is_only_special (gregorio_element *element);


int gregorio_calculate_new_key(char step, int line);

char gregorio_det_pitch (int key, char step, int octave);

void
gregorio_set_octave_and_step_from_pitch (char *step,
					  int *octave, char pitch, int clef);

// the maximum number of voices, more than this is total nonsense in
// gregorian chant.
#define MAX_NUMBER_OF_VOICES 10

#define max(a, b) (a > b ? a : b)

#define is_alteration(type) type==GRE_FLAT||type==GRE_NATURAL

#define MAX_TEXT_LENGTH 200

// all the different types of things a gregorio_* can be

#define GRE_NOTE 1
#define GRE_GLYPH 2
#define GRE_ELEMENT 3
#define GRE_FLAT 4
#define GRE_SHARP 19
#define GRE_NATURAL 5
#define GRE_C_KEY_CHANGE 6
#define GRE_C_KEY_CHANGE_FLATED 14
#define GRE_SYLLABLE 11
#define GRE_F_KEY_CHANGE 7
#define GRE_F_KEY_CHANGE_FLATED 15
#define GRE_END_OF_LINE 8
#define GRE_SPACE 9
#define GRE_BAR 10
#define GRE_END_OF_PAR 13
#define GRE_CUSTO 12
// I don't really know how I could use the a TEXVERB_NOTE in gregoriotex, as we don't write note by note...
//#define GRE_TEXVERB_NOTE 16
#define GRE_TEXVERB_GLYPH 17
#define GRE_TEXVERB_ELEMENT 18
// above lines text, quite the same as GRE_TEXVERB_ELEMENT, but counted differently for the spaces above the lines
#define GRE_ALT 20


#define C_KEY 'c'
#define F_KEY 'f'
#define NO_KEY -5
#define DEFAULT_KEY 5
#define FLAT_KEY 25
#define NO_FLAT_KEY 0


#define MONOPHONY 0

// the different initial styles

#define NO_INITIAL 0
#define NORMAL_INITIAL 1
#define BIG_INITIAL 2

#define NO_ALTERATION USELESS_VALUE
#define FLAT GRE_FLAT
#define NATURAL GRE_NATURAL

#define WORD_BEGINNING 1
#define WORD_MIDDLE 2
#define WORD_END 3
#define WORD_ONE_SYLLABLE 4

#define USELESS_VALUE 0

// definition of the signs. You can notice that the values are made so
// that if you wan to add a vertical episemus to a note, you juste
// make note->signs+=_V_EPISEMUS, so please don't change the value as
// this tricky is used.

#define _NO_SIGN 0
#define _PUNCTUM_MORA 1
#define _AUCTUM_DUPLEX 2
#define _V_EPISEMUS 5
#define _V_EPISEMUS_PUNCTUM_MORA 6
#define _V_EPISEMUS_AUCTUM_DUPLEX 7
// more rare signs, for now they can't be used with the others
#define _ACCENTUS 8
#define _ACCENTUS_REVERSUS 9
#define _CIRCULUS 10
#define _SEMI_CIRCULUS 11
#define _SEMI_CIRCULUS_REVERSUS 12
#define _ICTUS_A 13
#define _ICTUS_T 14
// signs of a bar
#define _V_EPISEMUS_ICTUS_A 15
#define _V_EPISEMUS_ICTUS_T 16
#define _V_EPISEMUS_H_EPISEMUS 17
#define _V_EPISEMUS_H_EPISEMUS_ICTUS_A 18
#define _V_EPISEMUS_H_EPISEMUS_ICTUS_T 19
#define _H_EPISEMUS_ICTUS_A 20
#define _H_EPISEMUS_ICTUS_T 21
#define _H_EPISEMUS 22

#define H_NO_EPISEMUS 0
#define H_ONE 1
#define H_ALONE 2
#define H_MULTI 3
#define H_MULTI_BEGINNING 4
#define H_MULTI_MIDDLE 5
#define H_MULTI_END 6
#define H_UNDETERMINED 7
// this H_EPISEMUS can be mixed with another one:
#define H_BOTTOM 16

#define simple_htype(h) ((h) & (255-H_BOTTOM))
#define has_bottom(arg)  (((arg) & H_BOTTOM) == H_BOTTOM)
#define is_multi(h_episemus) (simple_htype(h_episemus)) > H_ALONE

// the different kind of bars

#define B_NO_BAR 0
#define B_VIRGULA 1
#define B_DIVISIO_MINIMA 2
#define B_DIVISIO_MINOR 3
#define B_DIVISIO_MAIOR 4
#define B_DIVISIO_FINALIS 5
#define B_DIVISIO_MINOR_D1 6
#define B_DIVISIO_MINOR_D2 7
#define B_DIVISIO_MINOR_D3 8
#define B_DIVISIO_MINOR_D4 9
#define B_DIVISIO_MINOR_D5 10
#define B_DIVISIO_MINOR_D6 11

// the different shapes, only for notes

#define S_UNDETERMINED 0
#define S_PUNCTUM 1
#define S_PUNCTUM_END_OF_GLYPH 2
#define S_PUNCTUM_INCLINATUM 3
#define S_PUNCTUM_INCLINATUM_DEMINUTUS 20
#define S_PUNCTUM_INCLINATUM_AUCTUS 21
#define S_VIRGA 4
#define S_BIVIRGA 5
#define S_TRIVIRGA 6
#define S_ORISCUS 7
#define S_ORISCUS_AUCTUS 8
#define S_ORISCUS_DEMINUTUS 32
#define S_QUILISMA 9
#define S_STROPHA 10
#define S_STROPHA_AUCTA 11
#define S_DISTROPHA 12
#define S_DISTROPHA_AUCTA 13
#define S_TRISTROPHA 14
#define S_TRISTROPHA_AUCTA 15
#define S_PUNCTUM_CAVUM 28
#define S_LINEA_PUNCTUM 29
#define S_LINEA_PUNCTUM_CAVUM 30
// special shapes that must not appear in the final form of the score :
// quadratum is the shape of the first note of a punctum quadratum
// and quilisma quadratum is the shape of the first note of a pes
// quislisma quadratum
#define S_QUADRATUM 16
// those shapes are for now used only in gregoriotex
#define S_QUILISMA_QUADRATUM 17
#define S_PUNCTUM_AUCTUS_ASCENDENS 25
#define S_PUNCTUM_AUCTUS_DESCENDENS 26
#define S_PUNCTUM_DEMINUTUS 27
#define S_LINEA 31

// The different types of glyph

#define G_PUNCTUM_INCLINATUM 1
#define G_2_PUNCTA_INCLINATA_DESCENDENS 2
#define G_3_PUNCTA_INCLINATA_DESCENDENS 3
#define G_4_PUNCTA_INCLINATA_DESCENDENS 4
#define G_5_PUNCTA_INCLINATA_DESCENDENS 5
#define G_2_PUNCTA_INCLINATA_ASCENDENS 6
#define G_3_PUNCTA_INCLINATA_ASCENDENS 7
#define G_4_PUNCTA_INCLINATA_ASCENDENS 8
#define G_5_PUNCTA_INCLINATA_ASCENDENS 9
#define G_TRIGONUS 10
#define G_PUNCTA_INCLINATA 11
#define G_NO_GLYPH G_UNDETERMINED
#define G_UNDETERMINED 12
#define G_VIRGA 13
#define G_STROPHA 14
#define G_STROPHA_AUCTA 15
#define G_PUNCTUM 16
#define G_PES G_PODATUS
#define G_PODATUS 17
#define G_PES_QUADRATUM 18
#define G_FLEXA 19
#define G_FLEXUS G_FLEXA
#define G_TORCULUS 20
#define G_TORCULUS_RESUPINUS 21
#define G_TORCULUS_RESUPINUS_FLEXUS 22
#define G_PORRECTUS 23
#define G_PORRECTUS_FLEXUS 24
#define G_BIVIRGA 25
#define G_TRIVIRGA 26
#define G_DISTROPHA 27
#define G_DISTROPHA_AUCTA 28
#define G_TRISTROPHA 29
#define G_TRISTROPHA_AUCTA 30
#define G_PES_QUADRATUM_FIRST_PART 31
#define G_SCANDICUS 32
#define G_PES_QUILISMA_QUADRATUM_FIRST_PART 33
#define G_ANCUS 34

#define G_ONE_NOTE 36
#define G_PUNCTA_ASCENDENS 34
#define G_PUNCTA_DESCENDENS 35

#define is_puncta_inclinata(glyph) glyph<=G_5_PUNCTA_INCLINATA_ASCENDENS

// the different spaces

#define SP_DEFAULT '1'
#define SP_NO_SPACE '2'
#define SP_ZERO_WIDTH '3'
#define SP_NEUMATIC_CUT '4'
#define SP_LARGER_SPACE '5'
#define SP_GLYPH_SPACE '6'
#define SP_NEUMATIC_CUT_NB '7'
#define SP_LARGER_SPACE_NB '8'
#define SP_GLYPH_SPACE_NB '9'

#define is_liquescentia(liquescentia) liquescentia==L_DEMINUTUS||liquescentia==L_AUCTUS_ASCENDENS||liquescentia==L_AUCTUS_DESCENDENS||liquescentia==L_AUCTA

#define is_initio_debilis(liquescentia) liquescentia>=L_INITIO_DEBILIS

// the different liquescences, like for the signs, have special
// values: to say that something is initio_debilis, just do
// glyph->liquescentia+=L_INITIO_DEBILIS. So don't change the value,
// the tricky is much used

#define L_NO_LIQUESCENTIA 0
#define L_DEMINUTUS 1
#define L_AUCTUS_ASCENDENS 2
#define L_AUCTUS_DESCENDENS 3
#define L_AUCTA 4
#define L_INITIO_DEBILIS 5
#define L_DEMINUTUS_INITIO_DEBILIS 6
#define L_AUCTUS_ASCENDENS_INITIO_DEBILIS 7
#define L_AUCTUS_DESCENDENS_INITIO_DEBILIS 8
#define L_AUCTA_INITIO_DEBILIS 9

#define IS_INITIO_DEBILIS 5
#define NO_INITIO_DEBILIS 0

#define SKIP_FIRST_LETTER 1

// the centering schemes for gabc:
#define SCHEME_LATINE 1
#define SCHEME_ENGLISH 2
#define SCHEME_DEFAULT SCHEME_LATINE

void gregorio_add_character (gregorio_character **current_character, grewchar wcharacter);
void gregorio_begin_style (gregorio_character **current_character, unsigned char style);
void gregorio_end_style (gregorio_character **current_character, unsigned char style);

int gregorio_is_vowel (grewchar letter);

void gregorio_write_text (char type, gregorio_character * text, FILE *f, void (*printverb)(FILE *, grewchar *), void (*printchar)(FILE *, grewchar), void (*begin)(FILE *, unsigned char), void (*end)(FILE *, unsigned char), void (*printspchar)(FILE *, grewchar *));

void gregorio_write_first_letter (gregorio_character * current_character, FILE * f, void (*printverb) (FILE *, grewchar *), void (*printchar) (FILE *, grewchar), void (*begin) (FILE *, unsigned char), void (*end) (FILE *, unsigned char), void (*printspchar) (FILE *, grewchar *));
char gregorio_determine_next_pitch (gregorio_syllable * syllable, gregorio_element * element, gregorio_glyph * glyph);
gregorio_glyph * gregorio_first_glyph (gregorio_syllable * syllable);
char gregorio_syllable_first_note (gregorio_syllable * syllable);

void gregorio_free_characters (gregorio_character * current_character);
void gregorio_free_one_character (gregorio_character * current_character);
void gregorio_suppress_one_character (gregorio_character * current_character);

void gregorio_insert_character (gregorio_character * current_character, grewchar wcharacter, unsigned int style, unsigned int type);

#ifdef __cplusplus
}
#endif

#endif
