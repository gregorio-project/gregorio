%{
/*
 * Gregorio is a program that translates gabc files to GregorioTeX
 * This file implements the score parser.
 *
 * Gregorio score determination in gabc input.
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

/*
 * 
 * This file is certainly not the most easy to understand, it is a bison file.
 * See the bison manual on gnu.org for further details.
 * 
 */

#include "config.h"
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include "bool.h"
#include "struct.h"
#include "unicode.h"
#include "messages.h"
#include "characters.h"
#include "support.h"
#include "sha1.h"
#include "plugins.h"
#include "gabc.h"

#define YYLLOC_DEFAULT(Current, Rhs, N) \
    if (N) { \
        (Current).first_line   = YYRHSLOC(Rhs, 1).first_line; \
        (Current).first_column = YYRHSLOC (Rhs, 1).first_column; \
        (Current).first_offset = YYRHSLOC (Rhs, 1).first_offset; \
        (Current).last_line    = YYRHSLOC (Rhs, N).last_line; \
        (Current).last_column  = YYRHSLOC (Rhs, N).last_column; \
        (Current).last_offset  = YYRHSLOC (Rhs, N).last_offset; \
    } else { \
        (Current).first_line   = (Current).last_line   = YYRHSLOC (Rhs, 0).last_line; \
        (Current).first_column = (Current).last_column = YYRHSLOC (Rhs, 0).last_column; \
        (Current).first_offset = (Current).last_offset = YYRHSLOC (Rhs, 0).last_offset; \
    }

#include "gabc-score-determination.h"
#include "gabc-score-determination-l.h"

/* uncomment it if you want to have an interactive shell to understand the
 * details on how bison works for a certain input */
/* int gabc_score_determination_debug=1; */

/*
 * 
 * We will need some variables and functions through the entire file, we
 * declare them there:
 * 
 */

/* the score that we will determine and return */
static gregorio_score *score;
/* an array of elements that we will use for each syllable */
static gregorio_element **elements;
gregorio_element *current_element;
/* a table containing the macros to use in gabc file */
static char *macros[10];
/* forward declaration of the flex/bison process function */
static int gabc_score_determination_parse(void);
/* other variables that we will have to use */
static gregorio_character *current_character;
static gregorio_character *first_text_character;
static gregorio_character *first_translation_character;
static gregorio_tr_centering translation_type;
static gregorio_nlba no_linebreak_area;
static gregorio_euouae euouae;
static gregorio_voice_info *current_voice_info;
static int number_of_voices;
static int voice;
/* see comments on text to understand this */
static gregorio_center_determination center_is_determined;
/* current_key is... the current key... updated by each notes determination
 * (for key changes) */
static int current_key;
static bool got_language = false;
static bool got_staff_lines = false;
static bool started_first_word = false;
static struct sha1_ctx digester;

static __inline void check_multiple(const char *name, bool exists) {
    if (exists) {
        gregorio_messagef("det_score", VERBOSITY_WARNING, 0,
                _("several %s definitions found, only the last will be taken "
                "into consideration"), name);
    }
}

static void gabc_score_determination_error(const char *error_str)
{
    gregorio_message(error_str, (const char *) "gabc_score_determination_parse",
            VERBOSITY_ERROR, 0);
}

static void fix_custos(gregorio_score *score_to_check)
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
    current_key = gregorio_calculate_new_key(
            score_to_check->first_voice_info->initial_clef);
    current_syllable = score_to_check->first_syllable;
    while (current_syllable) {
        current_element = (current_syllable->elements)[0];
        while (current_element) {
            if (current_element->type == GRE_CUSTOS) {
                custo_element = current_element;
                pitch = custo_element->u.misc.pitched.pitch;
                /* we look for the key */
                while (current_element) {
                    if (current_element->type == GRE_CLEF) {
                        pitch = gregorio_determine_next_pitch( current_syllable,
                                current_element, NULL);
                        newkey = gregorio_calculate_new_key(
                                current_element->u.misc.clef);
                        pitch_difference = (char) newkey - (char) current_key;
                        pitch -= pitch_difference;
                        current_key = newkey;
                    }
                    if (!custo_element->u.misc.pitched.force_pitch) {
                        while (pitch < LOWEST_PITCH) {
                            pitch += 7;
                        }
                        while (pitch > score_to_check->highest_pitch) {
                            pitch -= 7;
                        }
                        custo_element->u.misc.pitched.pitch = pitch;
                    }
                    assert(custo_element->u.misc.pitched.pitch >= LOWEST_PITCH 
                            && custo_element->u.misc.pitched.pitch
                            <= score_to_check->highest_pitch);
                    current_element = current_element->next;
                }
            }
            if (current_element) {
                if (current_element->type == GRE_CLEF) {
                    current_key = gregorio_calculate_new_key(
                            current_element->u.misc.clef);
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

static int check_score_integrity(gregorio_score *score_to_check)
{
    if (!score_to_check) {
        return 0;
    }
    return 1;
}

/*
 * Another function to be improved: this one checks the validity of the voice_infos.
 */

static int check_infos_integrity(gregorio_score *score_to_check)
{
    if (!score_to_check->name) {
        gregorio_message(_("no name specified, put `name:...;' at the "
                "beginning of the file, can be dangerous with some output "
                "formats"), "det_score", VERBOSITY_WARNING, 0);
    }
    return 1;
}

/*
 * The function that will initialize the variables. 
 */

static void initialize_variables(void)
{
    int i;
    /* build a brand new empty score */
    score = gregorio_new_score();
    /* initialization of the first voice info to an empty voice info */
    current_voice_info = NULL;
    gregorio_add_voice_info(&current_voice_info);
    score->first_voice_info = current_voice_info;
    /* other initializations */
    number_of_voices = 0;
    voice = 1;
    current_character = NULL;
    first_translation_character = NULL;
    first_text_character = NULL;
    translation_type = TR_NORMAL;
    no_linebreak_area = NLBA_NORMAL;
    euouae = EUOUAE_NORMAL;
    center_is_determined = CENTER_NOT_DETERMINED;
    current_key = gregorio_calculate_new_key(gregorio_default_clef);
    for (i = 0; i < 10; i++) {
        macros[i] = NULL;
    }
    got_language = false;
    got_staff_lines = false;
    started_first_word = false;
}

/*
 * function that frees the variables that need it, for when we have finished to 
 * determine the score 
 */

static void free_variables(void)
{
    int i;
    free(elements);
    for (i = 0; i < 10; i++) {
        free(macros[i]);
    }
}

/* see whether a voice_info is empty */
static int voice_info_is_not_empty(const gregorio_voice_info *voice_info)
{
    return (voice_info->initial_clef.line);
}

/*
 * a function called when we see "--\n" that end the infos for a certain voice 
 */
static void next_voice_info(void)
{
    /* we must do this test in the case where there would be a "--" before
     * first_declarations */
    if (voice_info_is_not_empty(current_voice_info)) {
        gregorio_add_voice_info(&current_voice_info);
        voice++;
    }
}

/*
 * Function that frees the voice_infos for voices > final_count. Useful if
 * there are too many voice_infos 
 */

static void reajust_voice_infos(gregorio_voice_info *voice_info,
        int final_count)
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
static void end_definitions(void)
{
    int i;

    if (!check_infos_integrity(score)) {
        gregorio_message(_("can't determine valid infos on the score"),
                "det_score", VERBOSITY_ERROR, 0);
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
            gregorio_messagef("det_score", VERBOSITY_WARNING, 0,
                    ngt_("not enough voice infos found: %d found, %d waited, "
                    "%d assumed", "not enough voice infos found: %d found, %d "
                    "waited, %d assumed", voice), voice,
                    number_of_voices, voice);
            score->number_of_voices = voice;
            number_of_voices = voice;
        } else {
            if (number_of_voices < voice) {
                gregorio_messagef("det_score", VERBOSITY_WARNING, 0,
                        ngt_("too many voice infos found: %d found, %d "
                        "waited, %d assumed", "not enough voice infos found: "
                        "%d found, %d waited, %d assumed",
                        number_of_voices), voice, number_of_voices,
                        number_of_voices);
            }
        }
    }
    /* voice is now voice-1, so that it can be the index of elements */
    voice = 0;
    elements = (gregorio_element **) gregorio_malloc(number_of_voices *
            sizeof(gregorio_element *));
    for (i = 0; i < number_of_voices; i++) {
        elements[i] = NULL;
    }

    if (!got_language) {
        static char latin[] = "Latin";
        gregorio_set_centering_language(latin);
    }
}

/*
 * Here starts the code for the determinations of the notes. The notes are not
 * precisely determined here, we separate the text describing the notes of each 
 * voice, and we call determine_elements_from_string to really determine them. 
 */
static char position = WORD_BEGINNING;
static gregorio_syllable *current_syllable = NULL;
static char *abovelinestext = NULL;

/*
 * Function called when we see a ")", it completes the gregorio_element array
 * of the syllable with NULL pointers. Usefull in the cases where for example
 * you have two voices, but a voice that is silent on a certain syllable. 
 */
static void complete_with_nulls(int last_voice)
{
    int i;
    for (i = last_voice + 1; i < number_of_voices; i++) {
        elements[i] = NULL;
    }
}

/*
 * Function called each time we find a space, it updates the current position. 
 */
static void update_position_with_space(void)
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
static void gregorio_set_translation_center_beginning(
        gregorio_syllable *current_syllable)
{
    gregorio_syllable *syllable = current_syllable->previous_syllable;
    while (syllable) {
        if (syllable->translation_type == TR_WITH_CENTER_END) {
            gregorio_message("encountering translation centering end but "
                    "cannot find translation centering beginning...",
                    "set_translation_center_beginning", VERBOSITY_ERROR, 0);
            current_syllable->translation_type = TR_NORMAL;
            return;
        }
        if (syllable->translation) {
            syllable->translation_type = TR_WITH_CENTER_BEGINNING;
            return;
        }
        syllable = syllable->previous_syllable;
    }
    /* we didn't find any beginning... */
    gregorio_message("encountering translation centering end but cannot find "
            "translation centering beginning...",
            "set_translation_center_beginning", VERBOSITY_ERROR, 0);
    current_syllable->translation_type = TR_NORMAL;
}

static void rebuild_characters(void)
{
    /* we rebuild the first syllable text if it is the first syllable, or if
     * it is the second when the first has no text.
     * it is a patch for cases like (c4) Al(ab)le(ab) */
    if ((!score->first_syllable && current_character)
            || (current_syllable && !current_syllable->previous_syllable
            && !current_syllable->text && current_character)) {
        /* leave the first syllable text untouched at this time */
        gregorio_go_to_first_character_c(&current_character);

        started_first_word = true;
    } else {
        gregorio_rebuild_characters(&current_character, center_is_determined,
                false);

        if (started_first_word) {
            gregorio_set_first_word(&current_character);
        }
    }
}

/*
 * Function to close a syllable and update the position. 
 */

static void close_syllable(YYLTYPE *loc)
{
    int i;
    gregorio_add_syllable(&current_syllable, number_of_voices, elements,
            first_text_character, first_translation_character, position,
            abovelinestext, translation_type, no_linebreak_area, euouae, loc,
            started_first_word);
    if (!score->first_syllable) {
        /* we rebuild the first syllable if we have to */
        score->first_syllable = current_syllable;
    }
    if (translation_type == TR_WITH_CENTER_END) {
        gregorio_set_translation_center_beginning(current_syllable);
    }
    /* we update the position */
    if (position == WORD_BEGINNING) {
        position = WORD_MIDDLE;
    }
    if (position == WORD_ONE_SYLLABLE || position == WORD_END) {
        position = WORD_BEGINNING;

        if (started_first_word) {
            started_first_word = false;
        }
    }
    center_is_determined = CENTER_NOT_DETERMINED;
    current_character = NULL;
    first_text_character = NULL;
    first_translation_character = NULL;
    translation_type = TR_NORMAL;
    no_linebreak_area = NLBA_NORMAL;
    euouae = EUOUAE_NORMAL;
    abovelinestext = NULL;
    for (i = 0; i < number_of_voices; i++) {
        elements[i] = NULL;
    }
    current_element = NULL;
}

/* a function called when we see a [, basically, all characters are added to
 * the translation pointer instead of the text pointer */
static void start_translation(unsigned char asked_translation_type)
{
    rebuild_characters();
    first_text_character = current_character;
    /* the middle letters of the translation have no sense */
    center_is_determined = CENTER_FULLY_DETERMINED;
    current_character = NULL;
    translation_type = asked_translation_type;
}

static void end_translation(void)
{
    rebuild_characters();
    first_translation_character = current_character;
}

/*
 * gregorio_gabc_add_text is the function called when lex returns a char *. In
 * this function we convert it into grewchar, and then we add the corresponding 
 * gregorio_characters in the list of gregorio_characters. 
 */

static void gregorio_gabc_add_text(char *mbcharacters)
{
    if (current_character) {
        current_character->next_character = gregorio_build_char_list_from_buf(
                mbcharacters);
        current_character->next_character->previous_character =
                current_character;
    } else {
        current_character = gregorio_build_char_list_from_buf(mbcharacters);
    }
    while (current_character && current_character->next_character) {
        current_character = current_character->next_character;
    }
    free(mbcharacters);
}

/*
 * 
 * The two functions called when lex returns a style, we simply add it. All the 
 * complex things will be done by the function after...
 * 
 */

static void gregorio_gabc_add_style(unsigned char style)
{
    gregorio_begin_style(&current_character, style);
}

static void gregorio_gabc_end_style(unsigned char style)
{
    gregorio_end_style(&current_character, style);
}

void gabc_digest(const void *const buf, const size_t size)
{
    sha1_process_bytes(buf, size, &digester);
}

static void determine_oriscus_orientation(gregorio_score *score) {
    gregorio_syllable *syllable;
    gregorio_element *element;
    gregorio_glyph *glyph;
    gregorio_note *note;
    gregorio_note *oriscus = NULL;

    for (syllable = score->first_syllable; syllable;
            syllable = syllable->next_syllable) {
        for (element = syllable->elements[0]; element;
                element = element->next) {
            if (element->type == GRE_ELEMENT) {
                for (glyph = element->u.first_glyph; glyph;
                        glyph = glyph->next) {
                    if (glyph->type == GRE_GLYPH) {
                        for (note = glyph->u.notes.first_note; note;
                                note = note->next) {
                            if (note->type == GRE_NOTE) {
                                if (oriscus) {
                                    if (note->u.note.pitch
                                            < oriscus->u.note.pitch) {
                                        switch(oriscus->u.note.shape) {
                                        case S_ORISCUS_UNDETERMINED:
                                            oriscus->u.note.shape =
                                                    S_ORISCUS_DESCENDENS;
                                            break;
                                        case S_ORISCUS_CAVUM_UNDETERMINED:
                                            oriscus->u.note.shape =
                                                    S_ORISCUS_CAVUM_DESCENDENS;
                                            break;
                                        default:
                                            gregorio_message(_("bad shape"),
                                                    "determine_oriscus_orientation",
                                                    VERBOSITY_ERROR, 0);
                                            break;
                                        }
                                    } else { /* ascending or the same */
                                        switch(oriscus->u.note.shape) {
                                        case S_ORISCUS_UNDETERMINED:
                                            oriscus->u.note.shape =
                                                    S_ORISCUS_ASCENDENS;
                                            break;
                                        case S_ORISCUS_CAVUM_UNDETERMINED:
                                            oriscus->u.note.shape =
                                                    S_ORISCUS_CAVUM_ASCENDENS;
                                            break;
                                        default:
                                            gregorio_message(_("bad shape"),
                                                    "determine_oriscus_orientation",
                                                    VERBOSITY_ERROR, 0);
                                            break;
                                        }
                                    }
                                    oriscus = NULL;
                                }

                                switch (note->u.note.shape) {
                                case S_ORISCUS_UNDETERMINED:
                                case S_ORISCUS_CAVUM_UNDETERMINED:
                                    oriscus = note;
                                    break;

                                default:
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if (oriscus) {
        /* oriscus at the end of the score */
        switch(oriscus->u.note.shape) {
        case S_ORISCUS_UNDETERMINED:
            oriscus->u.note.shape = S_ORISCUS_DESCENDENS;
            break;
        case S_ORISCUS_CAVUM_UNDETERMINED:
            oriscus->u.note.shape = S_ORISCUS_CAVUM_DESCENDENS;
            break;
        default:
            gregorio_message(_("bad shape"), "determine_oriscus_orientation",
                    VERBOSITY_ERROR, 0);
            break;
        }
    }
}

/*
 * The "main" function. It is the function that is called when we have to read
 * a gabc file. It takes a file descriptor, that is to say a file that is
 * aleady open. It returns a valid gregorio_score 
 */

gregorio_score *gabc_read_score(FILE *f_in)
{
    /* compute the SHA-1 digest while parsing, for I/O efficiency */
    sha1_init_ctx(&digester);
    /* digest GREGORIO_VERSION to get a different value when the version
    changes */
    sha1_process_bytes(GREGORIO_VERSION, strlen(GREGORIO_VERSION), &digester);
    /* the input file that flex will parse */
    gabc_score_determination_in = f_in;
    if (!f_in) {
        gregorio_message(_("can't read stream from argument, returning NULL "
                "pointer"), "det_score", VERBOSITY_ERROR, 0);
        return NULL;
    }
    initialize_variables();
    /* the flex/bison main call, it will build the score (that we have
     * initialized) */
    gabc_score_determination_parse();
    if (!score->legacy_oriscus_orientation) {
        determine_oriscus_orientation(score);
    }
    gregorio_fix_initial_keys(score, gregorio_default_clef);
    fix_custos(score);
    free_variables();
    /* the we check the validity and integrity of the score we have built. */
    if (!check_score_integrity(score)) {
        gregorio_free_score(score);
        score = NULL;
        gregorio_message(_("unable to determine a valid score from file"),
                "det_score", VERBOSITY_FATAL, 0);
    }
    sha1_finish_ctx(&digester, score->digest);
    return score;
}

unsigned char nabc_state = 0;
size_t nabc_lines = 0;

static void gabc_y_add_notes(char *notes, YYLTYPE loc) {
    gregorio_element *new_elements;
    gregorio_element *last_element;
    if (nabc_state == 0) {
        if (!elements[voice]) {
            elements[voice] = gabc_det_elements_from_string(notes,
                    &current_key, macros, &loc, score);
            current_element = elements[voice];
        } else {
            new_elements = gabc_det_elements_from_string(notes,
                    &current_key, macros, &loc, score);
            last_element = elements[voice];
            while(last_element->next) {
                last_element = last_element->next;
            }
            last_element->next = new_elements;
            new_elements->previous = last_element;
            current_element = new_elements;
        }
    } else {
        if (!elements[voice]) {
            gregorio_add_element(&elements[voice], NULL);
            current_element = elements[voice];
        }
        if (!current_element) {
            gregorio_message(_("current_element is null, this shouldn't "
                    "happen!"), "gabc_y_add_notes", VERBOSITY_FATAL, 0);
        }
        if (!current_element->nabc) {
            current_element->nabc = (char **) gregorio_calloc (nabc_lines,
                    sizeof (char *));
        }
        current_element->nabc[nabc_state-1] = gregorio_strdup(notes);
        current_element->nabc_lines = nabc_state;
    }
}
%}

%initial-action {
    @$.first_line = 1;
    @$.first_column = 0;
    @$.first_offset = 0;
    @$.last_line = 1;
    @$.last_column = 0;
    @$.last_offset = 0;
}

%token NAME AUTHOR GABC_COPYRIGHT SCORE_COPYRIGHT MANUSCRIPT_REFERENCE
%token NUMBER_OF_VOICES LANGUAGE STAFF_LINES ORISCUS_ORIENTATION
%token DEF_MACRO OTHER_HEADER
%token ANNOTATION MODE MODE_MODIFIER MODE_DIFFERENTIA
%token INITIAL_STYLE /* DEPRECATED by 4.1 */
%token VOICE_CUT VOICE_CHANGE END_OF_DEFINITIONS END_OF_FILE
%token COLON SEMICOLON SPACE CHARACTERS NOTES HYPHEN ATTRIBUTE
%token OPENING_BRACKET CLOSING_BRACKET CLOSING_BRACKET_WITH_SPACE
%token I_BEGINNING I_END
%token TT_BEGINNING TT_END
%token UL_BEGINNING UL_END
%token C_BEGINNING C_END
%token B_BEGINNING B_END
%token SC_BEGINNING SC_END
%token SP_BEGINNING SP_END
%token VERB_BEGINNING VERB VERB_END
%token CENTER_BEGINNING CENTER_END
%token TRANSLATION_BEGINNING TRANSLATION_END TRANSLATION_CENTER_END
%token ALT_BEGIN ALT_END
%token BNLBA ENLBA
%token EUOUAE_B EUOUAE_E
%token NABC_CUT NABC_LINES

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
    NUMBER_OF_VOICES attribute {
        gregorio_add_score_header(score, $1.text, $2.text);
        number_of_voices=atoi($2.text);
        if (number_of_voices > MAX_NUMBER_OF_VOICES) {
            gregorio_messagef("det_score", VERBOSITY_WARNING, 0,
                    _("can't define %d voices, maximum is %d"),
                    number_of_voices, MAX_NUMBER_OF_VOICES);
        }
        score->number_of_voices = number_of_voices;
    }
    | DEF_MACRO attribute {
        /* these definitions are not passed through */
        free(macros[$1.character - '0']);
        macros[$1.character - '0'] = $2.text;
    }
    | NAME attribute {
        if ($2.text == NULL) {
            gregorio_message("name can't be empty","det_score",
                    VERBOSITY_WARNING, 0);
        }
        check_multiple("name", score->name != NULL);
        gregorio_add_score_header(score, $1.text, $2.text);
        score->name = $2.text;
    }
    | LANGUAGE attribute {
        check_multiple("language", got_language);
        gregorio_add_score_header(score, $1.text, $2.text);
        gregorio_set_centering_language($2.text);
        got_language = true;
    }
    | GABC_COPYRIGHT attribute {
        check_multiple("gabc-copyright", score->gabc_copyright != NULL);
        gregorio_add_score_header(score, $1.text, $2.text);
        score->gabc_copyright = $2.text;
    }
    | SCORE_COPYRIGHT attribute {
        check_multiple("score_copyright", score->score_copyright != NULL);
        gregorio_add_score_header(score, $1.text, $2.text);
        score->score_copyright = $2.text;
    }
    | MODE attribute {
        check_multiple("mode", score->mode != 0);
        gregorio_add_score_header(score, $1.text, $2.text);
        score->mode = $2.text;
    }
    | MODE_MODIFIER attribute {
        check_multiple("mode-modifier", score->mode_modifier != NULL);
        gregorio_add_score_header(score, $1.text, $2.text);
        score->mode_modifier = $2.text;
    }
    | MODE_DIFFERENTIA attribute {
        check_multiple("mode-differentia", score->mode_differentia != NULL);
        gregorio_add_score_header(score, $1.text, $2.text);
        score->mode_differentia = $2.text;
    }
    | STAFF_LINES attribute {
        check_multiple("staff-lines", got_staff_lines);
        if ($2.text) {
            gregorio_add_score_header(score, $1.text, $2.text);
            gregorio_set_score_staff_lines(score, atoi($2.text));
            got_staff_lines = true;
        }
    }
    | NABC_LINES attribute {
        check_multiple("nabc lines", score->nabc_lines != 0);
        if ($2.text) {
            gregorio_add_score_header(score, $1.text, $2.text);
            nabc_lines=atoi($2.text);
            score->nabc_lines=nabc_lines;
        }
    }
    | INITIAL_STYLE attribute {
        if ($2.text) {
            /* DEPRECATED by 4.1 */
            gregorio_message("\"initial-style\" header is deprecated. Please "
            "use \\gresetinitiallines in TeX instead.",
            "gabc_score_determination_parse", VERBOSITY_DEPRECATION, 0);
            score->initial_style = atoi($2.text);
            free($2.text);
        }
    }
    | ANNOTATION attribute {
        if (score->annotation [MAX_ANNOTATIONS - 1]) {
            gregorio_messagef("det_score", VERBOSITY_WARNING, 0,
                    _("too many definitions of annotation found, only the "
                    "first %d will be taken"), MAX_ANNOTATIONS);
        }
        gregorio_add_score_header(score, $1.text, $2.text);
        gregorio_set_score_annotation(score, $2.text);
    }
    | AUTHOR attribute {
        check_multiple("author", score->author != NULL);
        gregorio_add_score_header(score, $1.text, $2.text);
        score->author = $2.text;
    }
    | MANUSCRIPT_REFERENCE attribute {
        check_multiple("manuscript-reference",
                score->manuscript_reference != NULL);
        gregorio_add_score_header(score, $1.text, $2.text);
        score->manuscript_reference = $2.text;
    }
    | ORISCUS_ORIENTATION attribute {
        gregorio_add_score_header(score, $1.text, $2.text);
        score->legacy_oriscus_orientation = (strcmp($2.text, "legacy") == 0);
    }
    | OTHER_HEADER attribute {
        gregorio_add_score_header(score, $1.text, $2.text);
    }
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
            gabc_y_add_notes($1.text, @1);
            free($1.text);
        }
        else {
            gregorio_messagef("det_score", VERBOSITY_ERROR, 0,
                    ngt_("too many voices in note : %d found, %d expected",
                    "too many voices in note : %d found, %d expected",
                    number_of_voices), voice+1, number_of_voices);
        }
        if (voice<number_of_voices-1) {
            gregorio_messagef("det_score", VERBOSITY_INFO, 0,
                    ngt_("not enough voices in note : %d found, %d expected, "
                    "completing with empty neume", "not enough voices in note "
                    ": %d found, %d expected, completing with empty neume",
                    voice+1), voice+1, number_of_voices);
            complete_with_nulls(voice);
        }
        voice=0;
        nabc_state=0;
    }
    | NOTES closing_bracket_with_space {
        if (voice<number_of_voices) {
            gabc_y_add_notes($1.text, @1);
            free($1.text);
        }
        else {
            gregorio_messagef("det_score", VERBOSITY_ERROR, 0,
                    ngt_("too many voices in note : %d found, %d expected",
                    "too many voices in note : %d found, %d expected",
                    number_of_voices), voice+1, number_of_voices);
        }
        if (voice<number_of_voices-1) {
            gregorio_messagef("det_score", VERBOSITY_INFO, 0,
                    ngt_("not enough voices in note : %d found, %d expected, "
                    "completing with empty neume", "not enough voices in note "
                    ": %d found, %d expected, completing with empty neume",
                    voice+1), voice+1, number_of_voices);
            complete_with_nulls(voice);
        }
        voice=0;
        nabc_state=0;
        update_position_with_space();
    }
    | NOTES VOICE_CUT {
        if (voice<number_of_voices) {
            gabc_y_add_notes($1.text, @1);
            free($1.text);
            voice++;
        }
        else {
            gregorio_messagef("det_score", VERBOSITY_ERROR, 0,
                    ngt_("too many voices in note : %d found, %d expected",
                    "too many voices in note : %d found, %d expected",
                    number_of_voices), voice+1, number_of_voices);
        }
    }
    | NOTES NABC_CUT {
        if (!nabc_lines) {
            gregorio_message(_("You used character \"|\" in gabc without "
                               "setting \"nabc-lines\" parameter. Please "
                               "set it in your gabc header."),
                             "det_score", VERBOSITY_FATAL, 0);
        }
        if (voice<number_of_voices) {
            gabc_y_add_notes($1.text, @1);
            free($1.text);
            nabc_state = (nabc_state + 1) % (nabc_lines+1);
        }
    }
    | CLOSING_BRACKET {
        elements[voice]=NULL;
        voice=0;
        nabc_state=0;
    }
    | closing_bracket_with_space {
        elements[voice]=NULL;
        voice=0;
        nabc_state=0;
        update_position_with_space();
    }
    ;

closing_bracket_with_space:
    CLOSING_BRACKET_WITH_SPACE
    | CLOSING_BRACKET_WITH_SPACE END_OF_FILE
    | CLOSING_BRACKET END_OF_FILE
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

euouae:
    EUOUAE_B {
        euouae = EUOUAE_BEGINNING;
    }
    | EUOUAE_E {
        euouae = EUOUAE_END;
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
    | euouae
    ;

text_hyphen:
    HYPHEN {
        gregorio_gabc_add_text(gregorio_strdup("-"));
    }
    | text_hyphen HYPHEN {
        gregorio_gabc_add_text(gregorio_strdup("-"));
    }
    ;

text:
    | text character
    | text text_hyphen character
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
        rebuild_characters();
        first_text_character = current_character;
        close_syllable(&@1);
    }
    | text HYPHEN OPENING_BRACKET notes {
        gregorio_gabc_add_style(ST_VERBATIM);
        gregorio_gabc_add_text(gregorio_strdup("\\GreForceHyphen"));
        gregorio_gabc_end_style(ST_VERBATIM);
        rebuild_characters();
        first_text_character = current_character;
        close_syllable(&@1);
    }
    | text translation OPENING_BRACKET notes {
        close_syllable(&@1);
    }
    | text HYPHEN translation OPENING_BRACKET notes {
        gregorio_gabc_add_style(ST_VERBATIM);
        gregorio_gabc_add_text(gregorio_strdup("\\GreForceHyphen"));
        gregorio_gabc_end_style(ST_VERBATIM);
        close_syllable(&@1);
    }
    ;

notes_without_word:
    OPENING_BRACKET notes {
        close_syllable(NULL);
    }
    | translation OPENING_BRACKET notes {
        close_syllable(NULL);
    }
    ;

syllable:
    syllable_with_notes
    | notes_without_word
    ;

syllables:
    | syllables syllable
    ;
