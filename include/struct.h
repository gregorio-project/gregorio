/* 
Gregorio structure manipulation headers.
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

typedef struct gregorio_note {
  char type;
  char pitch;
  char shape;
  char signs;
  char liquescentia;
  char h_episemus_type;
  char h_episemus_top_note;
  struct gregorio_note *previous_note;
  struct gregorio_note *next_note;
} gregorio_note;

typedef struct gregorio_glyph {
  char type;
  char glyph_type;
  char liquescentia;
  struct gregorio_note *first_note;
  struct gregorio_glyph *next_glyph;
  struct gregorio_glyph *previous_glyph;
} gregorio_glyph;

typedef struct gregorio_element {
  char type;
  char element_type;
  //char liquescentia;
  struct gregorio_glyph *first_glyph;
  struct gregorio_element *next_element;
  //struct gregorio_element *previous_element;
} gregorio_element;

typedef struct gregorio_syllable {
  char type;
  char position;
  char *syllable;
  struct gregorio_syllable *next_syllable;
  struct gregorio_element ** elements;
} gregorio_syllable;

typedef struct gregorio_score {
  struct gregorio_syllable *first_syllable;
  int number_of_voices;
  char *name;
  char *office_part;
  char *lilypond_preamble;
  char *opustex_preamble;
  char *musixtex_preamble;
  struct gregorio_voice_info *first_voice_info;
} gregorio_score;

typedef struct gregorio_voice_info {
  int initial_key;
  char *anotation;
  char *author;
  char *date;
  char *manuscript;
  char *reference;
  char *storage_place;
  char *translator;
  char *translation_date;
  char *style;
  char *virgula_position;
  struct gregorio_voice_info *next_voice_info;
} gregorio_voice_info;

gregorio_score * libgregorio_new_score ();

void libgregorio_set_score_number_of_voices (gregorio_score *score, int number_of_voices);
void libgregorio_set_score_office_part (gregorio_score *score, char *office_part);
void libgregorio_set_score_lilypond_preamble (gregorio_score *score, char *lilypond_preamble);
void libgregorio_set_score_opustex_preamble (gregorio_score *score, char *opustex_preamble);
void libgregorio_set_score_musixtex_preamble (gregorio_score *score, char *musixtex_preamble);


void
libgregorio_determine_h_episemus_type (gregorio_note * note);


void libgregorio_add_note(gregorio_note **current_note, char pitch, char shape, char signs, char liquescentia,char h_episemus);
void libgregorio_add_glyph (gregorio_glyph **current_glyph, char type, gregorio_note *first_note, char liquescentia);
void libgregorio_add_element (gregorio_element **current_element, char type, gregorio_glyph *first_glyph, char liquescentia);
void libgregorio_add_syllable (gregorio_syllable ** current_syllable, int number_of_voices, gregorio_element * elements[], char *syllable, char position);

void libgregorio_add_voice_info (gregorio_voice_info **current_voice_info);

void libgregorio_free_notes(gregorio_note **first_note);
void libgregorio_free_glyphs(gregorio_glyph **glyph);
void libgregorio_free_elements (gregorio_element ** element);
void libgregorio_free_syllables (gregorio_syllable ** syllable, int number_of_voices);
void libgregorio_free_score_infos (gregorio_score * score);
void libgregorio_free_voice_infos (gregorio_voice_info *voice_info);

void libgregorio_free_one_note(gregorio_note **note);
void libgregorio_free_one_glyph(gregorio_glyph **glyph);
void libgregorio_free_one_element(gregorio_element **element);
void libgregorio_free_one_syllable (gregorio_syllable **syllable, int number_of_voices);
void libgregorio_free_score(gregorio_score *score);

void libgregorio_add_special_as_glyph (gregorio_glyph **current_glyph, char type, char pitch);
void libgregorio_add_special_as_note (gregorio_note **current_note, char type, char pitch);
void libgregorio_add_special_as_element (gregorio_element **current_element, char type, char pitch);

void
libgregorio_set_score_name (gregorio_score * score, char *name);
void
libgregorio_set_score_office_part (gregorio_score * score, char *office_part);
void
libgregorio_set_score_number_of_voices (gregorio_score * score, int number_of_voices);
void
libgregorio_set_score_lilypond_preamble (gregorio_score * score,
				    char *lilypond_preamble);
void
libgregorio_set_score_opustex_preamble (gregorio_score * score, char *opustex_preamble);
void
libgregorio_set_score_musixtex_preamble (gregorio_score * score,
				    char *musixtex_preamble);
void
libgregorio_set_voice_initial_key (gregorio_voice_info * voice_info, int initial_key);
void
libgregorio_set_voice_anotation (gregorio_voice_info * voice_info, char *anotation);
void
libgregorio_set_voice_author (gregorio_voice_info * voice_info, char *author);
void
libgregorio_set_voice_date (gregorio_voice_info * voice_info, char *date);
void
libgregorio_set_voice_manuscript (gregorio_voice_info * voice_info, char *manuscript);
void
libgregorio_set_voice_reference (gregorio_voice_info * voice_info, char *reference);
void
libgregorio_set_voice_storage_place (gregorio_voice_info * voice_info, char *storage_place);
void
libgregorio_set_voice_translator (gregorio_voice_info * voice_info, char *translator);
void
libgregorio_set_voice_translation_date (gregorio_voice_info * voice_info, char *translation_date);
void
libgregorio_set_voice_style (gregorio_voice_info * voice_info, char *style);
void
libgregorio_set_voice_virgula_position (gregorio_voice_info * voice_info, char *virgula_position);

void
libgregorio_fix_initial_keys (gregorio_score * score, int default_key);

/*void
libgregorio_fix_positions (gregorio_score * score);*/

void libgregorio_go_to_first_note (gregorio_note **note);
void libgregorio_go_to_first_glyph (gregorio_glyph **glyph);

char libgregorio_add_note_to_a_glyph (char glyph, char current_pitch, char last_pitch, char shape, char *end_of_glyph);


void libgregorio_det_step_and_line_from_key (int key, char *step, int *line);

char libgregorio_is_only_special (gregorio_element *element);


int libgregorio_calculate_new_key(char step, int line);

char libgregorio_det_pitch (int key, char step, int octave);

void
libgregorio_set_octave_and_step_from_pitch (char *step,
					  int *octave, char pitch, int clef);

#define MAX_NUMBER_OF_VOICES 10

#define max(a, b) (a > b ? a : b)

#define is_alteration(type) type==GRE_FLAT||type==GRE_NATURAL

#define MAX_TEXT_LENGTH 200

#define GRE_NOTE 1
#define GRE_GLYPH 2
#define GRE_ELEMENT 3
#define GRE_FLAT 4
#define GRE_NATURAL 5
#define GRE_C_KEY_CHANGE 6
#define GRE_SYLLABLE 11
#define GRE_F_KEY_CHANGE 7
#define GRE_END_OF_LINE 8
#define GRE_SPACE 9
#define GRE_BAR 10

#define C_KEY 'c'
#define F_KEY 'f'
#define NO_KEY -5
#define DEFAULT_KEY 5


#define MONOPHONY 0



#define NO_ALTERATION USELESS_VALUE
#define FLAT GRE_FLAT
#define NATURAL GRE_NATURAL

#define WORD_BEGINNING 1
#define WORD_MIDDLE 2
#define WORD_END 3
#define WORD_ONE_SYLLABLE 4

#define USELESS_VALUE 0

#define _NO_SIGN 0
#define _PUNCTUM_MORA 1
#define _AUCTUM_DUPLEX 2
#define _V_EPISEMUS 5
#define _V_EPISEMUS_PUNCTUM_MORA 6
#define _V_EPISEMUS_AUCTUM_DUPLEX 7

#define is_multi(h_episemus) \
h_episemus>H_ALONE

#define H_NO_EPISEMUS 0
#define H_ONE 1
#define H_ALONE 2
#define H_MULTI 3
#define H_MULTI_BEGINNING 4
#define H_MULTI_MIDDLE 5
#define H_MULTI_END 6
#define H_UNDETERMINED 7

#define B_NO_BAR 0
#define B_VIRGULA 1
#define B_DIVISIO_MINIMA 2
#define B_DIVISIO_MINOR 3
#define B_DIVISIO_MAIOR 4
#define B_DIVISIO_FINALIS 5

#define S_UNDETERMINED 0
#define S_PUNCTUM 1
#define S_PUNCTUM_END_OF_GLYPH 2
#define S_PUNCTUM_INCLINATUM 3
#define S_VIRGA 4
#define S_BIVIRGA 5
#define S_TRIVIRGA 6
#define S_ORISCUS 7
#define S_ORISCUS_AUCTUS 8
#define S_QUILISMA 9
#define S_STROPHA 10
#define S_STROPHA_AUCTA 11
#define S_DISTROPHA 12
#define S_DISTROPHA_AUCTA 13
#define S_TRISTROPHA 14
#define S_TRISTROPHA_AUCTA 15
// special shapes that must not appear in the final form of the score : quadratum is the shape of the first note of a punctum quadratum and quilisma quadratum is the shape of the first note of a pes quislisma quadratum
#define S_QUADRATUM 16
#define S_QUILISMA_QUADRATUM 17

#define has_two_glyphs(type) type==ELT_TWO_GLYPH || type==ELT_PRAEPUNCTA_TWO_GLYPH ||type==ELT_TWO_GLYPH_SUBPUNCTA ||type==ELT_PRAEPUNCTA_TWO_GLYPH_SUBPUNCTA

#define ELT_NO_ELEMENT 0
#define ELT_PRAEPUNCTA 1
#define ELT_ONE_GLYPH 2
#define ELT_PRAEPUNCTA_ONE_GLYPH 3
#define ELT_TWO_GLYPH 4
#define ELT_PRAEPUNCTA_TWO_GLYPH 5
#define ELT_SUBPUNCTA ELT_ONE_GLYPH_SUBPUNCTA
#define ELT_ONE_GLYPH_SUBPUNCTA 6
#define ELT_PRAEPUNCTA_ONE_GLYPH_SUBPUNCTA 7
#define ELT_TWO_GLYPH_SUBPUNCTA 8
#define ELT_PRAEPUNCTA_TWO_GLYPH_SUBPUNCTA 9


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

#define G_PUNCTA_ASCENDENS 34
#define G_PUNCTA_DESCENDENS 35

#define is_puncta_inclinata(glyph) glyph<=G_5_PUNCTA_INCLINATA_ASCENDENS

#define SP_DEFAULT '1'
#define SP_NO_SPACE '2'
#define SP_ZERO_WIDTH '3'
#define SP_NEUMATIC_CUT '4'
#define SP_LARGER_SPACE '5'
#define SP_GLYPH_SPACE '6'

#define is_liquescentia(liquescentia) liquescentia==L_DEMINUTUS||liquescentia==L_AUCTUS_ASCENDENS||liquescentia==L_AUCTUS_DESCENDENS||liquescentia==L_AUCTA

#define is_initio_debilis(liquescentia) liquescentia>=L_INITIO_DEBILIS

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

