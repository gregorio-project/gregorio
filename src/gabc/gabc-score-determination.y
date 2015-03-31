%{
/*
 * Gregorio score determination in gabc input. Copyright (C) 2006-2009 Elie
 * Roux <elie.roux@telecom-bretagne.eu>
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

/*
 * 
 * This file is certainly not the most easy to understand, it is a bison file.
 * See the bison manual on gnu.org for further details.
 * 
 */

#include "config.h"
#include <stdio.h>
#include <stdlib.h>
#include "struct.h"
#include "unicode.h"
#include "messages.h"
#include "characters.h"

#include "gabc.h"
#include "gabc-score-determination.h"
#include "gabc-score-determination-l.h"

// request translation to the user native language for bison
#define YYENABLE_NLS ENABLE_NLS

#define YYLEX_PARAM &yylval

// uncomment it if you want to have an interactive shell to understand the
// details on how bison works for a certain input
// int gabc_score_determination_debug=1;

/*
 * 
 * We will need some variables and functions through the entire file, we
 * declare them there:
 * 
 */

// the two functions to initialize and free the file variables
void initialize_variables();
void gabc_fix_custos(gregorio_score *score_to_check);
void free_variables();
// the error string
char error[200];
// the score that we will determine and return
gregorio_score *score;
// an array of elements that we will use for each syllable
gregorio_element **elements;
// a table containing the macros to use in gabc file
char *macros[10];
// declaration of some functions, the first is the one initializing the
// flex/bison process
int gabc_score_determination_parse();
// other variables that we will have to use
gregorio_character *current_character;
gregorio_character *first_text_character;
gregorio_character *first_translation_character;
unsigned char translation_type;
unsigned char no_linebreak_area;
gregorio_voice_info *current_voice_info;
int number_of_voices;
int voice;
// can't remember what it is...
int clef;
// a char that will take some useful values see comments on text to understand
// it
char center_is_determined;
// current_key is... the current key... updated by each notes determination
// (for key changes)
int current_key = DEFAULT_KEY;

int check_score_integrity(gregorio_score *score);
void next_voice_info();
void set_clef(char *str);
void reajust_voice_infos(gregorio_voice_info *voice_info, int final_count);
void end_definitions();
void suppress_useless_styles();
void rebuild_characters(gregorio_character **param_character,
                        char center_is_determined,
                        gregorio_lyric_centering centering_scheme);
void close_syllable();
void gregorio_gabc_add_text(char *mbcharacters);
void gregorio_gabc_add_style(unsigned char style);
void gregorio_gabc_end_style(unsigned char style);
void complete_with_nulls(int voice);
gregorio_lyric_centering centering_scheme;

void gabc_score_determination_error(char *error_str)
{
    gregorio_message(error_str, (const char *) "gabc_score_determination_parse",
                     ERROR, 0);
}

/*
 * The "main" function. It is the function that is called when we have to read
 * a gabc file. It takes a file descriptor, that is to say a file that is
 * aleady open. It returns a valid gregorio_score 
 */

gregorio_score *gabc_read_score(FILE *f_in)
{
    // the input file that flex will parse
    gabc_score_determination_in = f_in;
    if (!f_in) {
        gregorio_message(_
                         ("can't read stream from argument, returning NULL pointer"),
                         "det_score", ERROR, 0);
        return NULL;
    }
    initialize_variables();
    // the flex/bison main call, it will build the score (that we have
    // initialized)
    gabc_score_determination_parse();
    gregorio_fix_initial_keys(score, DEFAULT_KEY);
    gabc_fix_custos(score);
    free_variables();
    // the we check the validity and integrity of the score we have built.
    if (!check_score_integrity(score)) {
        gregorio_free_score(score);
        score = NULL;
        gregorio_message(_("unable to determine a valid score from file"),
                         "det_score", FATAL_ERROR, 0);
    }
    return score;
}

void gabc_fix_custos(gregorio_score *score_to_check)
{
    gregorio_syllable *current_syllable;
    gregorio_element *current_element;
    gregorio_element *custo_element;
    char pitch = 0;
    char pitch_difference = 0;
    int newkey;
    int current_key;
    if (!score_to_check || !score_to_check->first_syllable
        || !score_to_check->first_voice_info) {
        return;
    }
    current_key = score_to_check->first_voice_info->initial_key;
    current_syllable = score_to_check->first_syllable;
    while (current_syllable) {
        current_element = (current_syllable->elements)[0];
        while (current_element) {
            if (current_element->type == GRE_CUSTO) {
                custo_element = current_element;
                // we look for the key
                while (current_element) {
                    switch (current_element->type) {
                    case GRE_C_KEY_CHANGE:
                    case GRE_C_KEY_CHANGE_FLATED:
                        pitch =
                            gregorio_determine_next_pitch(current_syllable,
                                                          current_element,
                                                          NULL);
                        newkey =
                            gregorio_calculate_new_key(C_KEY,
                                                       current_element->element_type
                                                       - 48);
                        pitch_difference = (char) newkey - (char) current_key;
                        custo_element->element_type = pitch - pitch_difference;
                        current_key = newkey;
                        break;
                    case GRE_F_KEY_CHANGE:
                    case GRE_F_KEY_CHANGE_FLATED:
                        pitch =
                            gregorio_determine_next_pitch(current_syllable,
                                                          current_element,
                                                          NULL);
                        newkey =
                            gregorio_calculate_new_key(F_KEY,
                                                       current_element->element_type
                                                       - 48);
                        pitch_difference = (char) newkey - (char) current_key;
                        custo_element->element_type = pitch - pitch_difference;
                        current_key = newkey;
                        break;
                    default:
                        break;
                    }
                    /*
                     * in ASCII, 97 is a and 109 is m 
                     */
                    if (custo_element->element_type < 97
                        || custo_element->element_type > 109) {
                        gregorio_message(_("pitch difference too high to set "
                                           "automatic custo (z0), please "
                                           "check your score"),
                                         "gabc_fix_custos", ERROR, 0);
                        custo_element->element_type = 'g';
                    }
                    current_element = current_element->next;
                }
            }
            if (current_element) {
                if (current_element->type == GRE_C_KEY_CHANGE
                    || current_element->type == GRE_C_KEY_CHANGE_FLATED) {
                    current_key =
                        gregorio_calculate_new_key(C_KEY,
                                                   current_element->element_type
                                                   - 48);
                }
                if (current_element->type == GRE_F_KEY_CHANGE
                    || current_element->type == GRE_F_KEY_CHANGE_FLATED) {
                    current_key =
                        gregorio_calculate_new_key(F_KEY,
                                                   current_element->element_type
                                                   - 48);
                }
                current_element = current_element->next;
            }
        }
        current_syllable = current_syllable->next_syllable;
    }
}

/*
 * A function that checks to score integrity. For now it is... quite
 * ridiculous... but it might be improved in the future. 
 */

int check_score_integrity(gregorio_score *score_to_check)
{
    if (!score_to_check) {
        return 0;
    }
    return 1;
}

/*
 * Another function to be improved: this one checks the validity of the voice_infos.
 */

int check_infos_integrity(gregorio_score *score_to_check)
{
    if (!score_to_check->name) {
        gregorio_message(_("no name specified, put `name:...;' at the "
                           "beginning of the file, can be dangerous "
                           "with some output formats"),
                         "det_score", WARNING, 0);
    }
    return 1;
}

/*
 * The function that will initialize the variables. 
 */

void initialize_variables()
{
    int i;
    // build a brand new empty score
    score = gregorio_new_score();
    // initialization of the first voice info to an empty voice info
    current_voice_info = NULL;
    gregorio_add_voice_info(&current_voice_info);
    score->first_voice_info = current_voice_info;
    // other initializations
    number_of_voices = 0;
    voice = 1;
    current_character = NULL;
    first_translation_character = NULL;
    first_text_character = NULL;
    translation_type = TR_NORMAL;
    no_linebreak_area = NLBA_NORMAL;
    centering_scheme = SCHEME_DEFAULT;
    center_is_determined = 0;
    for (i = 0; i < 10; i++) {
        macros[i] = NULL;
    }
}

/*
 * function that frees the variables that need it, for when we have finished to 
 * determine the score 
 */

void free_variables()
{
    int i;
    free(elements);
    for (i = 0; i < 10; i++) {
        free(macros[i]);
    }
}

// see whether a voice_info is empty
int voice_info_is_not_empty(const gregorio_voice_info *voice_info)
{
    return (voice_info->initial_key != 5 ||
            voice_info->annotation[0] ||
            voice_info->annotation[1] ||
            voice_info->style || voice_info->virgula_position);
}

/*
 * a function called when we see "--\n" that end the infos for a certain voice 
 */
void next_voice_info()
{
    // we must do this test in the case where there would be a "--" before
    // first_declarations
    if (voice_info_is_not_empty(current_voice_info)) {
        gregorio_add_voice_info(&current_voice_info);
        voice++;
    }
}

/*
 * Function that updates the clef variable, intepreting the char *str argument 
 */
void set_clef(char *str)
{
    if (!str || !str[0] || !str[1]) {
        gregorio_message(_("unknown clef format in initial-key definition : "
                           "format is `(c|f)[1-4]'"), "det_score", ERROR, 0);
    }
    if (str[0] != 'c' && str[0] != 'f') {
        gregorio_message(_("unknown clef format in initial-key definition : "
                           "format is `(c|f)[1-4]'"), "det_score", ERROR, 0);
        return;
    }
    // here is something than could be changed : the format of the inital_key
    // attribute
    if (str[1] != '1' && str[1] != '2' && str[1] != '3' && str[1] != '4') {
        gregorio_message(_("unknown clef format in initial-key definition : "
                           "format is `(c|f)[1-4]'"), "det_score", ERROR, 0);
        return;
    }

    clef = gregorio_calculate_new_key(str[0], str[1] - 48);
    if (str[2]) {
        gregorio_message(_("in initial_key definition, only two characters are "
                           "needed : format is`(c|f)[1-4]'"),
                         "det_score", WARNING, 0);
    }
    current_key = clef;
}

/*
 * Function that frees the voice_infos for voices > final_count. Useful if
 * there are too many voice_infos 
 */

void reajust_voice_infos(gregorio_voice_info *voice_info, int final_count)
{
    int i = 1;
    while (voice_info && i <= final_count) {
        voice_info = voice_info->next_voice_info;
    }
    gregorio_free_voice_infos(voice_info);
}

/*
 * Function called when we have reached the end of the definitions, it tries to 
 * make the voice_infos coherent. 
 */
void end_definitions()
{
    int i;

    if (!check_infos_integrity(score)) {
        gregorio_message(_("can't determine valid infos on the score"),
                         "det_score", ERROR, 0);
    }
    if (!number_of_voices) {
        if (voice > MAX_NUMBER_OF_VOICES) {
            voice = MAX_NUMBER_OF_VOICES;
            reajust_voice_infos(score->first_voice_info, number_of_voices);
        }
        number_of_voices = voice;
        score->number_of_voices = voice;
    } else {
        if (number_of_voices > voice) {
            snprintf(error, 62,
                     ngt_
                     ("not enough voice infos found: %d found, %d waited, %d assumed",
                      "not enough voice infos found: %d found, %d waited, %d assumed",
                      voice), voice, number_of_voices, voice);
            gregorio_message(error, "det_score", WARNING, 0);
            score->number_of_voices = voice;
            number_of_voices = voice;
        } else {
            if (number_of_voices < voice) {
                snprintf(error, 62,
                         ngt_
                         ("too many voice infos found: %d found, %d waited, %d assumed",
                          "not enough voice infos found: %d found, %d waited, %d assumed",
                          number_of_voices), voice, number_of_voices,
                         number_of_voices);
                gregorio_message(error, "det_score", WARNING, 0);
            }
        }
    }
    voice = 0;                  // voice is now voice-1, so that it can be the
    // index of elements
    elements =
        (gregorio_element **) malloc(number_of_voices *
                                     sizeof(gregorio_element *));
    for (i = 0; i < number_of_voices; i++) {
        elements[i] = NULL;
    }
}

/*
 * Here starts the code for the determinations of the notes. The notes are not
 * precisely determined here, we separate the text describing the notes of each 
 * voice, and we call determine_elements_from_string to really determine them. 
 */
char position = WORD_BEGINNING;
gregorio_syllable *current_syllable = NULL;
char *abovelinestext = NULL;

/*
 * Function called when we see a ")", it completes the gregorio_element array
 * of the syllable with NULL pointers. Usefull in the cases where for example
 * you have two voices, but a voice that is silent on a certain syllable. 
 */
void complete_with_nulls(int last_voice)
{
    int i;
    for (i = last_voice + 1; i < number_of_voices; i++) {
        elements[i] = NULL;
    }
}

/*
 * Function called each time we find a space, it updates the current position. 
 */
void update_position_with_space()
{
    if (position == WORD_MIDDLE) {
        position = WORD_END;
    }
    if (position == WORD_BEGINNING) {
        position = WORD_ONE_SYLLABLE;
    }
}

/*
 * When we encounter a translation center ending, we call this function that
 * sets translation_type = TR_WITH_CENTER_BEGINNING on previous syllable with
 * translation 
 */
void
gregorio_set_translation_center_beginning(gregorio_syllable *current_syllable)
{
    gregorio_syllable *syllable = current_syllable->previous_syllable;
    while (syllable) {
        if (syllable->translation_type == TR_WITH_CENTER_END) {
            gregorio_message
                ("encountering translation centering end but cannot find "
                 "translation centering beginning...",
                 "set_translation_center_beginning", ERROR, 0);
            current_syllable->translation_type = TR_NORMAL;
            return;
        }
        if (syllable->translation) {
            syllable->translation_type = TR_WITH_CENTER_BEGINNING;
            return;
        }
        syllable = syllable->previous_syllable;
    }
    // we didn't find any beginning...
    gregorio_message
        ("encountering translation centering end but cannot find translation "
         "centering beginning...", "set_translation_center_beginning", ERROR, 0);
    current_syllable->translation_type = TR_NORMAL;
}

void rebuild_characters(gregorio_character **param_character,
                        char center_is_determined,
                        gregorio_lyric_centering centering_scheme)
{
    // we rebuild the first syllable text if it is the first syllable, or if
    // it is the second when the first has no text.
    // it is a patch for cases like (c4) Al(ab)le(ab)
    if ((!score->first_syllable && score->initial_style != NO_INITIAL
         && current_character)
        || (current_syllable && !current_syllable->previous_syllable
            && !current_syllable->text && current_character)) {
        gregorio_rebuild_first_syllable(&current_character);
    }

    gregorio_rebuild_characters(param_character, center_is_determined,
                                centering_scheme);
}

/*
 * Function to close a syllable and update the position. 
 */

void close_syllable()
{
    gregorio_add_syllable(&current_syllable, number_of_voices, elements,
                          first_text_character, first_translation_character,
                          position, abovelinestext, translation_type,
                          no_linebreak_area);
    if (!score->first_syllable) {
        // we rebuild the first syllable if we have to
        score->first_syllable = current_syllable;
    }
    if (translation_type == TR_WITH_CENTER_END) {
        gregorio_set_translation_center_beginning(current_syllable);
    }
    // we update the position
    if (position == WORD_BEGINNING) {
        position = WORD_MIDDLE;
    }
    if (position == WORD_ONE_SYLLABLE || position == WORD_END) {
        position = WORD_BEGINNING;
    }
    center_is_determined = CENTER_NOT_DETERMINED;
    current_character = NULL;
    first_text_character = NULL;
    first_translation_character = NULL;
    translation_type = TR_NORMAL;
    no_linebreak_area = NLBA_NORMAL;
    abovelinestext = NULL;
}

// a function called when we see a [, basically, all characters are added to
// the translation pointer instead of the text pointer
void start_translation(unsigned char asked_translation_type)
{
    rebuild_characters(&current_character, center_is_determined,
                       centering_scheme);
    first_text_character = current_character;
    center_is_determined = CENTER_FULLY_DETERMINED; // the middle letters of
    // the translation have no
    // sense
    current_character = NULL;
    translation_type = asked_translation_type;
}

void end_translation()
{
    rebuild_characters(&current_character, center_is_determined,
                       centering_scheme);
    first_translation_character = current_character;
}

/*
 * gregorio_gabc_add_text is the function called when lex returns a char *. In
 * this function we convert it into grewchar, and then we add the corresponding 
 * gregorio_characters in the list of gregorio_characters. 
 */

void gregorio_gabc_add_text(char *mbcharacters)
{
    if (current_character) {
        current_character->next_character =
            gregorio_build_char_list_from_buf(mbcharacters);
        current_character->next_character->previous_character =
            current_character;
    } else {
        current_character = gregorio_build_char_list_from_buf(mbcharacters);
    }
    while (current_character && current_character->next_character) {
        current_character = current_character->next_character;
    }
}

/*
 * the function called when centering_scheme is seen in gabc 
 */
void set_centering_scheme(char *sc)
{
    if (strncmp((const char *) sc, "latine", 6) == 0) {
        centering_scheme = SCHEME_LATINE;
        return;
    }
    if (strncmp((const char *) sc, "english", 6) == 0) {
        centering_scheme = SCHEME_ENGLISH;
        return;
    }
    gregorio_message
        ("centering-scheme unknown value: must be \"latine\" or \"english\"",
         "set_centering_scheme", WARNING, 0);
}

/*
 * 
 * The two functions called when lex returns a style, we simply add it. All the 
 * complex things will be done by the function after...
 * 
 */

void gregorio_gabc_add_style(unsigned char style)
{
    gregorio_begin_style(&current_character, style);
}

void gregorio_gabc_end_style(unsigned char style)
{
    gregorio_end_style(&current_character, style);
}
%}

%token ATTRIBUTE COLON SEMICOLON OFFICE_PART ANNOTATION AUTHOR DATE 
%token MANUSCRIPT MANUSCRIPT_REFERENCE MANUSCRIPT_STORAGE_PLACE TRANSCRIBER
%token TRANSCRIPTION_DATE BOOK STYLE VIRGULA_POSITION LILYPOND_PREAMBLE
%token OPUSTEX_PREAMBLE MUSIXTEX_PREAMBLE INITIAL_STYLE MODE GREGORIOTEX_FONT
%token GENERATED_BY NAME OPENING_BRACKET NOTES VOICE_CUT
%token CLOSING_BRACKET NUMBER_OF_VOICES VOICE_CHANGE END_OF_DEFINITIONS SPACE
%token CHARACTERS I_BEGINNING I_END TT_BEGINNING TT_END UL_BEGINNING UL_END
%token C_BEGINNING C_END B_BEGINNING B_END SC_BEGINNING SC_END SP_BEGINNING
%token SP_END VERB_BEGINNING VERB VERB_END CENTER_BEGINNING CENTER_END
%token CLOSING_BRACKET_WITH_SPACE TRANSLATION_BEGINNING TRANSLATION_END
%token GABC_COPYRIGHT SCORE_COPYRIGHT OCCASION METER COMMENTARY ARRANGER
%token GABC_VERSION USER_NOTES DEF_MACRO ALT_BEGIN ALT_END CENTERING_SCHEME
%token TRANSLATION_CENTER_END BNLBA ENLBA

%%

score:
    all_definitions syllables
    ;

all_definitions:
    definitions END_OF_DEFINITIONS {
        end_definitions();
    }
    ;

definitions:
    | definitions definition
    ;

number_of_voices_definition:
    NUMBER_OF_VOICES attribute {
        number_of_voices=atoi($2.text);
        if (number_of_voices > MAX_NUMBER_OF_VOICES) {
            snprintf(error, 40, _("can't define %d voices, maximum is %d"),
                     number_of_voices, MAX_NUMBER_OF_VOICES);
            gregorio_message(error,"det_score",WARNING,0);
        }
        gregorio_set_score_number_of_voices (score, number_of_voices);
    }
    ;

macro_definition:
    DEF_MACRO attribute {
        macros[$1.character - '0'] = $2.text;
    }
    ;

name_definition:
    NAME attribute {
        if ($2.text==NULL) {
            gregorio_message("name can't be empty","det_score", WARNING, 0);
        }
        if (score->name) {
            gregorio_message(_("several name definitions found, only the "
                               "last will be taken into consideration"),
                             "det_score",WARNING, 0);
        }
        gregorio_set_score_name (score, $2.text);
    }
    ;

lilypond_preamble_definition:
    LILYPOND_PREAMBLE attribute {
        if (score->lilypond_preamble) {
            gregorio_message(_("several lilypond preamble definitions found, "
                               "only the last will be taken into consideration"),
                             "det_score",WARNING,0);
        }
        gregorio_set_score_lilypond_preamble (score, $2.text);
    }
    ;
    
centering_scheme_definition:
    CENTERING_SCHEME attribute {
        set_centering_scheme($2.text);
    }
    ;

gabc_copyright_definition:
    GABC_COPYRIGHT attribute {
        if (score->gabc_copyright) {
            gregorio_message(_("several gabc-copyright fields found, only the "
                               "last will be taken into consideration"),
                             "det_score",WARNING,0);
        }
        gregorio_set_score_gabc_copyright (score, $2.text);
    }
    ;

score_copyright_definition:
    SCORE_COPYRIGHT attribute {
        if (score->score_copyright) {
            gregorio_message(_("several score_copyright fields found, only "
                               "the last will be taken into consideration"),
                             "det_score",WARNING,0);
        }
        gregorio_set_score_score_copyright (score, $2.text);
    }
    ;

opustex_preamble_definition:
    OPUSTEX_PREAMBLE attribute {
        if (score->opustex_preamble) {
            gregorio_message(_("several OpusTeX preamble definitions found, "
                               "only the last will be taken into consideration"),
                             "det_score",WARNING,0);
        }
        gregorio_set_score_opustex_preamble (score, $2.text);
    }
    ;

musixtex_preamble_definition:
    MUSIXTEX_PREAMBLE attribute {
        if (score->musixtex_preamble) {
            gregorio_message(_("several MusiXTeX preamble definitions found, "
                               "only the last will be taken into consideration"),
                             "det_score",WARNING,0);
        }
        gregorio_set_score_musixtex_preamble (score, $2.text);
    }
    ;

gregoriotex_font_definition:
    GREGORIOTEX_FONT attribute {
        if (score->gregoriotex_font) {
            gregorio_message(_("several GregorioTeX font definitions found, "
                               "only the last will be taken into consideration"),
                             "det_score",WARNING,0);
        }
        score->gregoriotex_font=$2.text;
    }
    ;

office_part_definition:
    OFFICE_PART attribute {
        if (score->office_part) {
            gregorio_message(_("several office part definitions found, only "
                               "the last will be taken into consideration"),
                             "det_score",WARNING,0);
        }
        gregorio_set_score_office_part (score, $2.text);
    }
    ;

occasion_definition:
    OCCASION attribute {
        if (score->occasion) {
            gregorio_message(_("several occasion definitions found, only the "
                               "last will be taken into consideration"),
                             "det_score",WARNING,0);
        }
        gregorio_set_score_occasion (score, $2.text);
    }
    ;

meter_definition:
    METER attribute {
        if (score->meter) {
            gregorio_message(_("several meter definitions found, only the "
                               "last will be taken into consideration"),
                             "det_score",WARNING,0);
        }
        gregorio_set_score_meter (score, $2.text);
    }
    ;

commentary_definition:
    COMMENTARY attribute {
        if (score->commentary) {
            gregorio_message(_("several commentary definitions found, only "
                               "the last will be taken into consideration"),
                             "det_score",WARNING,0);
        }
        gregorio_set_score_commentary (score, $2.text);
    }
    ;

arranger_definition:
    ARRANGER attribute {
        if (score->arranger) {
            gregorio_message(_("several arranger definitions found, only the "
                               "last will be taken into consideration"),
                             "det_score",WARNING,0);
        }
        gregorio_set_score_arranger (score, $2.text);
    }
    ;

gabc_version_definition:
    GABC_VERSION attribute {
        // So far this handling of the version is rudimentary.  When
        // we start supporting multiple input versions, it will become
        // more complex.  For the moment, just issue a warning.
        if (strcmp ($2.text, GABC_CURRENT_VERSION) != 0) {
            gregorio_message(_("gabc-version is not the current one "
                               GABC_CURRENT_VERSION " ; there may be problems"),
                             "det_score",WARNING,0);
        }
    }
    ;

mode_definition:
    MODE attribute {
        if (score->mode) {
            gregorio_message(_("several mode definitions found, only the last "
                               "will be taken into consideration"),
                             "det_score",WARNING,0);
        }
        if ($2.text) {
            score->mode=atoi($2.text);
            free($2.text);
        }
    }
    ;

initial_style_definition:
    INITIAL_STYLE attribute {
        if ($2.text) {
            score->initial_style=atoi($2.text);
            free($2.text);
        }
    }
    ;

annotation_definition:
    ANNOTATION attribute {
        if (current_voice_info->annotation [NUM_ANNOTATIONS - 1]) {
            snprintf(error,99,_("too many definitions of annotation found for "
                                "voice %d, only the first %d will be taken "
                                "into consideration"), voice, NUM_ANNOTATIONS);
            gregorio_message(error, "det_score",WARNING,0);
        }
        gregorio_set_voice_annotation (current_voice_info, $2.text);
    }
    ;

author_definition:
    AUTHOR attribute {
        if (score->si.author) {
            snprintf(error,99,_("several definitions of author found, only "
                                "the last will be taken into consideration"));
            gregorio_message(error, "det_score",WARNING,0);
        }
        gregorio_set_score_author (score, $2.text);
    }
    ;

date_definition:
    DATE attribute {
        if (score->si.date) {
            snprintf(error,99,_("several definitions of date found, only the "
                                "last will be taken into consideration"));
            gregorio_message(error, "det_score",WARNING,0);
        }
        gregorio_set_score_date (score, $2.text);
    }
    ;

manuscript_definition:
    MANUSCRIPT attribute {
        if (score->si.manuscript) {
            snprintf(error,99,_("several definitions of manuscript found, only "
                                "the last will be taken into consideration"));
            gregorio_message(error, "det_score",WARNING,0);
        }
        gregorio_set_score_manuscript (score, $2.text);
    }
    ;

manuscript_reference_definition:
    MANUSCRIPT_REFERENCE attribute {
        if (score->si.manuscript_reference) {
            snprintf(error,99,_("several definitions of manuscript-reference "
                                "found, only the last will be taken into "
                                "consideration"));
            gregorio_message(error, "det_score",WARNING,0);
        }
        gregorio_set_score_manuscript_reference (score, $2.text);
    }
    ;

manuscript_storage_place_definition:
    MANUSCRIPT_STORAGE_PLACE attribute {
        if (score->si.manuscript_storage_place) {
            snprintf(error,105,_("several definitions of "
                                 "manuscript-storage-place found, only the "
                                 "last will be taken into consideration"));
            gregorio_message(error, "det_score",WARNING,0);
        }
        gregorio_set_score_manuscript_storage_place (score, $2.text);
    }
    ;

book_definition:
    BOOK attribute {
        if (score->si.book) {
            snprintf(error,99,_("several definitions of book found, only the "
                                "last will be taken into consideration"));
            gregorio_message(error, "det_score",WARNING,0);
        }
        gregorio_set_score_book (score, $2.text);
    }
    ;

transcriber_definition:
    TRANSCRIBER attribute {
        if (score->si.transcriber) {
            snprintf(error,99,_("several definitions of transcriber found, only "
                                "the last will be taken into consideration"));
            gregorio_message(error, "det_score",WARNING,0);
        }
        gregorio_set_score_transcriber (score, $2.text);
        //free($2.text);
    }
    ;

transcription_date_definition:
    TRANSCRIPTION_DATE attribute {
        if (score->si.transcription_date) {
            snprintf(error,105,_("several definitions of transcription date "
                                 "found, only the last will be taken into "
                                 "consideration"));
            gregorio_message(error, "det_score",WARNING,0);
        }
        gregorio_set_score_transcription_date (score, $2.text);
    }
    ;

style_definition:
    STYLE attribute {
        if (current_voice_info->style) {
            snprintf(error,99,_("several definitions of style found for voice "
                                "%d, only the last will be taken into "
                                "consideration"), voice);
            gregorio_message(error, "det_score",WARNING,0);
        }
        gregorio_set_voice_style (current_voice_info, $2.text);
    }
    ;

virgula_position_definition:
    VIRGULA_POSITION attribute {
        if (current_voice_info->virgula_position) {
            snprintf(error,105,_("several definitions of virgula position "
                                 "found for voice %d, only the last will be "
                                 "taken into consideration"), voice);
            gregorio_message(error, "det_score",WARNING,0);
        }
        gregorio_set_voice_virgula_position (current_voice_info, $2.text);
    }
    ;


generated_by_definition:
    GENERATED_BY attribute {
        //set_voice_generated_by (current_voice_info, $2.text);
    }
    ;

user_notes_definition:
    USER_NOTES attribute {
        gregorio_set_score_user_notes (score, $2.text);
    }
    ;

attribute:
    COLON ATTRIBUTE SEMICOLON {
        $$.text = $2.text;
    }
    |
    COLON SEMICOLON {
        $$.text = NULL;
    }
    ;

definition:
    number_of_voices_definition
    | name_definition
    | macro_definition
    | gabc_copyright_definition
    | score_copyright_definition
    | generated_by_definition
    | musixtex_preamble_definition
    | opustex_preamble_definition
    | lilypond_preamble_definition
    | virgula_position_definition
    | style_definition
    | transcription_date_definition
    | transcriber_definition
    | manuscript_storage_place_definition
    | manuscript_reference_definition
    | manuscript_definition
    | book_definition
    | date_definition
    | author_definition
    | annotation_definition
    | office_part_definition
    | occasion_definition
    | meter_definition
    | commentary_definition
    | arranger_definition
    | gabc_version_definition
    | initial_style_definition
    | mode_definition
    | gregoriotex_font_definition
    | user_notes_definition
    | centering_scheme_definition
    | VOICE_CHANGE {
        next_voice_info();
    }
    ;

notes:
    | notes note
    ;

note:
    NOTES CLOSING_BRACKET {
        if (voice<number_of_voices) {
            elements[voice]=gabc_det_elements_from_string($1.text, &current_key, macros);
            free($1.text);
        }
        else {
            snprintf(error,105,ngt_("too many voices in note : %d foud, %d expected",
                                    "too many voices in note : %d foud, %d expected",
                                    number_of_voices), voice+1, number_of_voices);
            gregorio_message(error, "det_score",ERROR,0);
        }
        if (voice<number_of_voices-1) {
            snprintf(error,105,ngt_("not enough voices in note : %d foud, %d "
                                    "expected, completing with empty neume",
                                    "not enough voices in note : %d foud, "
                                    "%d expected, completing with empty neume",
                                    voice+1), voice+1, number_of_voices);
            gregorio_message(error, "det_score",VERBOSE,0);
            complete_with_nulls(voice);
        }
        voice=0;
    }
    | NOTES CLOSING_BRACKET_WITH_SPACE {
        if (voice<number_of_voices) {
            elements[voice]=gabc_det_elements_from_string($1.text, &current_key, macros);
            free($1.text);
        }
        else {
            snprintf(error,105,ngt_("too many voices in note : %d foud, %d expected",
                                    "too many voices in note : %d foud, %d expected",
                                    number_of_voices), voice+1, number_of_voices);
            gregorio_message(error, "det_score",ERROR,0);
        }
        if (voice<number_of_voices-1) {
            snprintf(error,105,ngt_("not enough voices in note : %d foud, %d "
                                    "expected, completing with empty neume",
                                    "not enough voices in note : %d foud, %d "
                                    "expected, completing with empty neume",
                                    voice+1), voice+1, number_of_voices);
            gregorio_message(error, "det_score",VERBOSE,0);
            complete_with_nulls(voice);
        }
        voice=0;
        update_position_with_space();
    }
    | NOTES VOICE_CUT {
        if (voice<number_of_voices) {
            elements[voice]=gabc_det_elements_from_string($1.text, &current_key, macros);
            free($1.text);
            voice++;
        }
        else {
            snprintf(error,105,ngt_("too many voices in note : %d found, %d expected",
                                    "too many voices in note : %d found, %d expected",
                                    number_of_voices), voice+1, number_of_voices);
            gregorio_message(error, "det_score",ERROR,0);
        }
    }
    | CLOSING_BRACKET {
        elements[voice]=NULL;
        voice=0;
    }
    | CLOSING_BRACKET_WITH_SPACE {
        elements[voice]=NULL;
        voice=0;
        update_position_with_space();
    }
    ;

style_beginning:
    I_BEGINNING {
        gregorio_gabc_add_style(ST_ITALIC);
    }
    | TT_BEGINNING {
        gregorio_gabc_add_style(ST_TT);
    }
    | UL_BEGINNING {
        gregorio_gabc_add_style(ST_UNDERLINED);
    }
    | C_BEGINNING {
        gregorio_gabc_add_style(ST_COLORED);
    }
    | B_BEGINNING {
        gregorio_gabc_add_style(ST_BOLD);
    }
    | SC_BEGINNING {
        gregorio_gabc_add_style(ST_SMALL_CAPS);
    }
    | VERB_BEGINNING {
        gregorio_gabc_add_style(ST_VERBATIM);
    }
    | SP_BEGINNING {
        gregorio_gabc_add_style(ST_SPECIAL_CHAR);
    }
    | CENTER_BEGINNING {
        if (!center_is_determined) {
            gregorio_gabc_add_style(ST_FORCED_CENTER);
            center_is_determined=CENTER_HALF_DETERMINED;
        }
    }
    ;

style_end:
    I_END {
        gregorio_gabc_end_style(ST_ITALIC);
    }
    | TT_END {
        gregorio_gabc_end_style(ST_TT);
    }
    | UL_END {
        gregorio_gabc_end_style(ST_UNDERLINED);
    }
    | C_END {
        gregorio_gabc_end_style(ST_COLORED);
    }
    | B_END {
        gregorio_gabc_end_style(ST_BOLD);
    }
    | SC_END {
        gregorio_gabc_end_style(ST_SMALL_CAPS);
    }
    | VERB_END {
        gregorio_gabc_end_style(ST_VERBATIM);
    }
    | SP_END {
        gregorio_gabc_end_style(ST_SPECIAL_CHAR);
    }
    | CENTER_END {
        if (center_is_determined==CENTER_HALF_DETERMINED) {
            gregorio_gabc_end_style(ST_FORCED_CENTER);
            center_is_determined=CENTER_FULLY_DETERMINED;
        }
    }
    ;

linebreak_area:
    BNLBA {
        no_linebreak_area = NLBA_BEGINNING;
    }
    | ENLBA {
        no_linebreak_area = NLBA_END;
    }
    ;

character:
    above_line_text
    | CHARACTERS {
        gregorio_gabc_add_text($1.text);
    }
    | style_beginning
    | style_end
    | linebreak_area
    ;

text:
    | text character
    ;

translation_beginning:
    TRANSLATION_BEGINNING {
        start_translation(TR_NORMAL);
    }
    ;

translation:
    translation_beginning text TRANSLATION_END {
        end_translation();
    }
    | TRANSLATION_CENTER_END {
        start_translation(TR_WITH_CENTER_END);
    }
    ;

above_line_text:
    ALT_BEGIN CHARACTERS ALT_END {
        abovelinestext = $2.text;
    }
    ;

syllable_with_notes:
    text OPENING_BRACKET notes {
        rebuild_characters (&current_character, center_is_determined, centering_scheme);
        first_text_character = current_character;
        close_syllable();
    }
    | text translation OPENING_BRACKET notes {
        close_syllable();
    }
    ;

notes_without_word:
    OPENING_BRACKET notes {
        close_syllable();
    }
    | translation OPENING_BRACKET notes {
        close_syllable();
    }
    ;

syllable:
    syllable_with_notes
    | notes_without_word
    ;

syllables:
    | syllables syllable
    ;
