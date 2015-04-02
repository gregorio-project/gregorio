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

/**
 * @file
 * @brief This file contains a set of function to manipulate the gregorio
 * structure. 
 *
 * It starts by simple add/delete functions for almost all
 * structs, and ends with more complex functions for manipulating
 * horizontal episemus, keys, etc.
 *
 * The first functions are not commented, but they always act like
 * this : we give them a pointer to the pointer to the current element
 * (by element I mean a struct which can be gregorio_note,
 * gregorio_element, etc.), they add an element and the update the
 * pointer to the element so that it points to the new element (may
 * seem a bit strange).
 *
 * All the delete functions are recursive and free all memory.
 *
 */

#include "config.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "struct.h"
#include "unicode.h"
#include "messages.h"
#include "characters.h"

extern inline unsigned char simple_htype(unsigned char h);
extern inline bool has_bottom(unsigned char arg);
extern inline bool is_multi(unsigned char h_episemus);
extern inline bool is_puncta_inclinata(char glyph);
extern inline bool is_liquescentia(char liquescentia);
extern inline bool is_initio_debilis(char liquescentia);

static inline char max(char a, char b)
{
    return a > b ? a : b;
}

void
gregorio_add_note(gregorio_note **current_note, char pitch,
                  gregorio_shape shape, char signs, char liquescentia,
                  char h_episemus_type)
{

    gregorio_note *element = malloc(sizeof(gregorio_note));
    if (!element) {
        gregorio_message(_("error in memory allocation"),
                         "add_note", FATAL_ERROR, 0);
        return;
    }
    element->type = GRE_NOTE;
    element->pitch = pitch;
    element->shape = shape;
    element->signs = signs;
    element->rare_sign = _NO_SIGN;
    element->liquescentia = liquescentia;
    element->previous = *current_note;
    element->h_episemus_type = H_NO_EPISEMUS;
    element->h_episemus_top_note = 0;
    element->h_episemus_bottom_note = 0;
    element->next = NULL;
    element->texverb = NULL;
    element->choral_sign = NULL;
    if (*current_note) {
        (*current_note)->next = element;
    }
    *current_note = element;
    gregorio_mix_h_episemus(*current_note, h_episemus_type);
}

void
gregorio_add_special_as_note(gregorio_note **current_note, gregorio_type type,
                             char pitch)
{
    gregorio_note *element = malloc(sizeof(gregorio_note));
    if (!element) {
        gregorio_message(_("error in memory allocation"),
                         "add_special_as_note", FATAL_ERROR, 0);
        return;
    }
    element->type = type;
    element->pitch = pitch;
    element->signs = _NO_SIGN;
    element->previous = *current_note;
    element->next = NULL;
    element->texverb = NULL;
    element->h_episemus_type = H_NO_EPISEMUS;
    element->h_episemus_top_note = 0;
    element->h_episemus_bottom_note = 0;
    element->choral_sign = NULL;
    if (*current_note) {
        (*current_note)->next = element;
    }
    *current_note = element;
}

void
gregorio_add_texverb_as_note(gregorio_note **current_note, char *str,
                             gregorio_type type)
{
    gregorio_note *element;
    if (str == NULL) {
        return;
    }
    element = malloc(sizeof(gregorio_note));
    if (!element) {
        gregorio_message(_("error in memory allocation"),
                         "add_special_as_note", FATAL_ERROR, 0);
        return;
    }
    element->type = type;
    element->pitch = 0;
    element->signs = _NO_SIGN;
    element->previous = *current_note;
    element->h_episemus_type = H_NO_EPISEMUS;
    element->h_episemus_top_note = 0;
    element->h_episemus_bottom_note = 0;
    element->next = NULL;
    element->texverb = str;
    element->choral_sign = NULL;
    if (*current_note) {
        (*current_note)->next = element;
    }
    *current_note = element;
}

void gregorio_add_nlba_as_note(gregorio_note **current_note, char type)
{
    gregorio_note *element;
    element = malloc(sizeof(gregorio_note));
    if (!element) {
        gregorio_message(_("error in memory allocation"),
                         "add_special_as_note", FATAL_ERROR, 0);
        return;
    }
    element->type = GRE_NLBA;
    element->pitch = type;
    element->signs = _NO_SIGN;
    element->previous = *current_note;
    element->h_episemus_type = H_NO_EPISEMUS;
    element->h_episemus_top_note = 0;
    element->h_episemus_bottom_note = 0;
    element->next = NULL;
    element->texverb = NULL;
    element->choral_sign = NULL;
    if (*current_note) {
        (*current_note)->next = element;
    }
    *current_note = element;
}

void gregorio_add_texverb_to_note(gregorio_note **current_note, char *str)
{
    size_t len;
    char *res;
    unsigned int i;
    if (str == NULL) {
        return;
    }
    if (*current_note) {
        if ((*current_note)->texverb) {
            len = strlen((*current_note)->texverb) + strlen(str) + 1;
            res = malloc(len * sizeof(char));
            len = strlen((*current_note)->texverb);
            for (i = 0; i <= len; i++) {
                res[i] = ((*current_note)->texverb)[i];
            }
            strcat(res, str);
            free((*current_note)->texverb);
            (*current_note)->texverb = res;
        } else {
            (*current_note)->texverb = str;
        }
    }
}

void gregorio_add_cs_to_note(gregorio_note **current_note, char *str)
{
    if (*current_note) {
        (*current_note)->choral_sign = str;
    }
}

void gregorio_add_special_sign(gregorio_note *note, char sign)
{
    if (!note) {
        // error
        return;
    }
    note->rare_sign = sign;
}

void gregorio_set_signs(gregorio_note *note, char signs)
{
    if (!note) {
        // error
        return;
    }
    note->signs = signs;
}

void gregorio_change_shape(gregorio_note *note, gregorio_shape shape)
{
    if (!note || note->type != GRE_NOTE) {
        gregorio_message(_
                         ("trying to change the shape of something that is not a note"),
                         "change_shape", ERROR, 0);
        return;
    }
    note->shape = shape;
    if (note->shape == S_STROPHA || note->shape == S_DISTROPHA
        || note->shape == S_TRISTROPHA) {
        switch (note->liquescentia) {
        case L_AUCTUS_ASCENDENS:
        case L_AUCTUS_DESCENDENS:
            note->liquescentia = L_AUCTA;
            break;
        case L_AUCTUS_ASCENDENS_INITIO_DEBILIS:
        case L_AUCTUS_DESCENDENS_INITIO_DEBILIS:
            note->liquescentia = L_AUCTA_INITIO_DEBILIS;
            break;
        default:
            break;
        }
    }
    if (note->shape == S_ORISCUS) {
        switch (note->liquescentia) {
        case L_AUCTUS_ASCENDENS:
        case L_AUCTUS_DESCENDENS:
        case L_AUCTUS_ASCENDENS_INITIO_DEBILIS:
        case L_AUCTUS_DESCENDENS_INITIO_DEBILIS:
            note->shape = S_ORISCUS_AUCTUS;
            break;
        case L_DEMINUTUS:
        case L_DEMINUTUS_INITIO_DEBILIS:
            note->shape = S_ORISCUS_DEMINUTUS;
            break;
        default:
            break;
        }
    }
}

void gregorio_add_liquescentia(gregorio_note *note, char liq)
{
    if (!note || note->type != GRE_NOTE) {
        gregorio_message(_
                         ("trying to make a liquescence on something that is not a note"),
                         "add_liquescentia", ERROR, 0);
        return;
    }
    if (is_initio_debilis(liq)) {
        switch (liq) {
        case L_DEMINUTUS:
            note->liquescentia = L_DEMINUTUS_INITIO_DEBILIS;
            break;
        case L_AUCTUS_ASCENDENS:
            note->liquescentia = L_AUCTUS_ASCENDENS_INITIO_DEBILIS;
            break;
        case L_AUCTUS_DESCENDENS:
            note->liquescentia = L_AUCTUS_DESCENDENS_INITIO_DEBILIS;
            break;
        case L_AUCTA:
            note->liquescentia = L_AUCTA_INITIO_DEBILIS;
            break;
        }
    } else {
        note->liquescentia = liq;
    }
    if (note->shape == S_STROPHA || note->shape == S_DISTROPHA
        || note->shape == S_TRISTROPHA) {
        switch (note->liquescentia) {
        case L_AUCTUS_ASCENDENS:
        case L_AUCTUS_DESCENDENS:
            note->liquescentia = L_AUCTA;
            break;
        case L_AUCTUS_ASCENDENS_INITIO_DEBILIS:
        case L_AUCTUS_DESCENDENS_INITIO_DEBILIS:
            note->liquescentia = L_AUCTA_INITIO_DEBILIS;
            break;
        default:
            break;
        }
    }
    if (note->shape == S_ORISCUS) {
        switch (note->liquescentia) {
        case L_AUCTUS_ASCENDENS:
        case L_AUCTUS_DESCENDENS:
        case L_AUCTUS_ASCENDENS_INITIO_DEBILIS:
        case L_AUCTUS_DESCENDENS_INITIO_DEBILIS:
            note->shape = S_ORISCUS_AUCTUS;
            break;
        case L_DEMINUTUS:
        case L_DEMINUTUS_INITIO_DEBILIS:
            note->shape = S_ORISCUS_DEMINUTUS;
            break;
        default:
            break;
        }
    }
}

void
gregorio_add_h_episemus(gregorio_note *note, unsigned char type,
                        unsigned int *nbof_isolated_episemus)
{
    if (!note || (note->type != GRE_NOTE && note->type != GRE_BAR)) {
        gregorio_message(_
                         ("trying to add an horizontal episemus on something that is not a note"),
                         "add_h_episemus", ERROR, 0);
        return;
    }
    if (!nbof_isolated_episemus) {
        gregorio_message(_("NULL argument nbof_isolated_episemus"),
                         "add_h_episemus", FATAL_ERROR, 0);
        return;
    }
    if (type == H_BOTTOM) {
        note->h_episemus_type = note->h_episemus_type | H_BOTTOM;
        gregorio_determine_good_bottom_notes(note);
        return;
    }
    if (!note->h_episemus_top_note || *nbof_isolated_episemus == 0) {
        gregorio_mix_h_episemus(note, H_ONE);
        *nbof_isolated_episemus = 1;
    } else {
        gregorio_activate_isolated_h_episemus(note, *nbof_isolated_episemus);
        *nbof_isolated_episemus = *nbof_isolated_episemus + 1;
    }
}

// a helper function
void gregorio_set_h_episemus(gregorio_note *note, unsigned char type)
{
    if (!note || (note->type != GRE_NOTE && note->type != GRE_BAR)) {
        gregorio_message(_
                         ("trying to add an horizontal episemus on something that is not a note"),
                         "set_h_episemus", ERROR, 0);
        return;
    }
    if (type == H_BOTTOM) {
        note->h_episemus_type = (note->h_episemus_type) | H_BOTTOM;
    } else {
        note->h_episemus_type = (note->h_episemus_type & H_BOTTOM) | type;
    }
}

void gregorio_add_sign(gregorio_note *note, char sign)
{
    if (!note) {
        // error
        return;
    }
    switch (sign) {
    case _PUNCTUM_MORA:
        switch (note->signs) {
        case _NO_SIGN:
            note->signs = _PUNCTUM_MORA;
            break;
        case _V_EPISEMUS:
            note->signs = _V_EPISEMUS_PUNCTUM_MORA;
            break;
        case _PUNCTUM_MORA:
            note->signs = _AUCTUM_DUPLEX;
            break;
        case _V_EPISEMUS_PUNCTUM_MORA:
            note->signs = _V_EPISEMUS_AUCTUM_DUPLEX;
            break;
        default:
            break;
        }
        break;
    case _V_EPISEMUS:
        switch (note->signs) {
        case _NO_SIGN:
            note->signs = _V_EPISEMUS;
            break;
        case _PUNCTUM_MORA:
            note->signs = _V_EPISEMUS_PUNCTUM_MORA;
            break;
        case _AUCTUM_DUPLEX:
            note->signs = _V_EPISEMUS_AUCTUM_DUPLEX;
            break;
        default:
            break;
        }
    default:
        break;
    }
}

void gregorio_go_to_first_note(gregorio_note **note)
{
    gregorio_note *tmp;
    if (!*note) {
        return;
    }
    tmp = *note;
    while (tmp->previous) {
        tmp = tmp->previous;
    }
    *note = tmp;
}

void gregorio_free_one_note(gregorio_note **note)
{
    gregorio_note *next = NULL;
    free((*note)->texverb);
    free((*note)->choral_sign);
    if (!note || !*note) {
        return;
    }
    if ((*note)->next) {
        (*note)->next->previous = NULL;
        next = (*note)->next;
    }
    if ((*note)->previous) {
        (*note)->previous->next = NULL;
    }
    free(*note);
    *note = next;
}

void gregorio_free_notes(gregorio_note **note)
{
    gregorio_note *tmp;
    while (*note) {
        tmp = (*note)->next;
        free(*note);
        *note = tmp;
    }
}

void
gregorio_add_glyph(gregorio_glyph **current_glyph, char type,
                   gregorio_note *first_note, char liquescentia)
{
    gregorio_glyph *next_glyph = malloc(sizeof(gregorio_glyph));
    if (!next_glyph) {
        gregorio_message(_("error in memory allocation"),
                         "add_glyph", FATAL_ERROR, 0);
        return;
    }
    next_glyph->type = GRE_GLYPH;
    next_glyph->glyph_type = type;
    next_glyph->liquescentia = liquescentia;
    next_glyph->first_note = first_note;
    next_glyph->next = NULL;
    next_glyph->texverb = NULL;
    next_glyph->previous = *current_glyph;
    if (*current_glyph) {
        (*current_glyph)->next = next_glyph;
    }
    *current_glyph = next_glyph;
}

void
gregorio_add_special_as_glyph(gregorio_glyph **current_glyph,
                              gregorio_type type, char pitch,
                              char additional_infos, char *texverb)
{
    gregorio_glyph *next_glyph = malloc(sizeof(gregorio_glyph));
    if (!next_glyph) {
        gregorio_message(_("error in memory allocation"),
                         "add_special_as_glyph", FATAL_ERROR, 0);
        return;
    }
    next_glyph->type = type;
    next_glyph->glyph_type = pitch;
    next_glyph->liquescentia = additional_infos;
    next_glyph->first_note = NULL;
    next_glyph->next = NULL;
    next_glyph->texverb = texverb;
    next_glyph->previous = *current_glyph;
    if (*current_glyph) {
        (*current_glyph)->next = next_glyph;
    }
    *current_glyph = next_glyph;
}

void gregorio_go_to_first_glyph(gregorio_glyph **glyph)
{
    gregorio_glyph *tmp;
    if (!*glyph) {
        return;
    }
    tmp = *glyph;
    while (tmp->previous) {
        tmp = tmp->previous;
    }
    *glyph = tmp;
}

void gregorio_free_one_glyph(gregorio_glyph **glyph)
{
    gregorio_glyph *next = NULL;
    if (!glyph || !*glyph) {
        return;
    }
    if ((*glyph)->next) {
        (*glyph)->next->previous = NULL;
        next = (*glyph)->next;
    }
    if ((*glyph)->previous) {
        (*glyph)->previous->next = NULL;
    }
    free((*glyph)->texverb);
    gregorio_free_notes(&(*glyph)->first_note);
    free(*glyph);
    *glyph = next;
}

void gregorio_free_glyphs(gregorio_glyph **glyph)
{
    gregorio_glyph *next_glyph;
    if (!glyph || !*glyph) {
        return;
    }
    while (*glyph) {
        next_glyph = (*glyph)->next;
        gregorio_free_notes(&(*glyph)->first_note);
        free(*glyph);
        *glyph = next_glyph;
    }
}

void
gregorio_add_element(gregorio_element **current_element,
                     gregorio_glyph *first_glyph)
{
    gregorio_element *next = malloc(sizeof(gregorio_element));
    if (!next) {
        gregorio_message(_("error in memory allocation"),
                         "add_element", FATAL_ERROR, 0);
        return;
    }
    next->type = GRE_ELEMENT;
    next->element_type = 0;
    next->additional_infos = 0;
    next->first_glyph = first_glyph;
    next->previous = *current_element;
    next->next = NULL;
    next->texverb = NULL;
    if (*current_element) {
        (*current_element)->next = next;
    }
    *current_element = next;
}

void
gregorio_add_special_as_element(gregorio_element **current_element,
                                gregorio_type type, char pitch,
                                char additional_infos, char *texverb)
{
    gregorio_element *special = malloc(sizeof(gregorio_element));
    if (!special) {
        gregorio_message(_("error in memory allocation"),
                         "add_special_as_element", FATAL_ERROR, 0);
        return;
    }
    special->type = type;
    special->element_type = pitch;
    special->additional_infos = additional_infos;
    special->first_glyph = NULL;
    special->next = NULL;
    special->texverb = texverb;
    special->previous = *current_element;
    if (*current_element) {
        (*current_element)->next = special;
    }
    *current_element = special;
}

void gregorio_free_one_element(gregorio_element **element)
{
    gregorio_element *next;
    if (!element || !*element) {
        return;
    }
    free((*element)->texverb);
    next = (*element)->next;
    gregorio_free_glyphs(&(*element)->first_glyph);
    free(*element);
    *element = next;
}

void gregorio_free_elements(gregorio_element **element)
{
    gregorio_element *next;
    if (!element || !*element) {
        return;
    }
    while (*element) {
        next = (*element)->next;
        gregorio_free_glyphs(&(*element)->first_glyph);
        free(*element);
        *element = next;
    }
}

/*
 * 
 * This function converts a buffer of utf8 characters into a list of
 * gregorio_character and adds it to the current_character.
 * 
 */

void
gregorio_add_text(char *mbcharacters, gregorio_character **current_character)
{
    if (!current_character) {
        return;
    }
    if (*current_character) {
        (*current_character)->next_character =
            gregorio_build_char_list_from_buf(mbcharacters);
        (*current_character)->next_character->previous_character =
            (*current_character);
    } else {
        *current_character = gregorio_build_char_list_from_buf(mbcharacters);
    }
    while ((*current_character)->next_character) {
        (*current_character) = (*current_character)->next_character;
    }
}

void
gregorio_add_character(gregorio_character **current_character,
                       grewchar wcharacter)
{
    gregorio_character *element =
        (gregorio_character *) malloc(sizeof(gregorio_character));
    if (!element) {
        gregorio_message(_("error in memory allocation"),
                         "gregorio_add_character", FATAL_ERROR, 0);
        return;
    }
    element->is_character = 1;
    element->cos.character = wcharacter;
    element->next_character = NULL;
    element->previous_character = *current_character;
    if (*current_character) {
        (*current_character)->next_character = element;
    }
    *current_character = element;
}

void gregorio_free_one_character(gregorio_character *current_character)
{
    free(current_character);
}

void gregorio_free_characters(gregorio_character *current_character)
{
    gregorio_character *next_character;
    if (!current_character) {
        return;
    }
    while (current_character) {
        next_character = current_character->next_character;
        gregorio_free_one_character(current_character);
        current_character = next_character;
    }
}

void gregorio_go_to_first_character(gregorio_character **character)
{
    gregorio_character *tmp;
    if (!character || !*character) {
        return;
    }
    tmp = *character;
    while (tmp->previous_character) {
        tmp = tmp->previous_character;
    }
    *character = tmp;
}

void
gregorio_begin_style(gregorio_character **current_character,
                     grestyle_style style)
{
    gregorio_character *element =
        (gregorio_character *) malloc(sizeof(gregorio_character));
    if (!element) {
        gregorio_message(_("error in memory allocation"),
                         "add_note", FATAL_ERROR, 0);
        return;
    }
    element->is_character = 0;
    element->cos.s.type = ST_T_BEGIN;
    element->cos.s.style = style;
    element->previous_character = *current_character;
    element->next_character = NULL;
    if (*current_character) {
        (*current_character)->next_character = element;
    }
    *current_character = element;
}

void
gregorio_end_style(gregorio_character **current_character, grestyle_style style)
{
    gregorio_character *element =
        (gregorio_character *) malloc(sizeof(gregorio_character));
    if (!element) {
        gregorio_message(_("error in memory allocation"),
                         "add_note", FATAL_ERROR, 0);
        return;
    }
    element->is_character = 0;
    element->cos.s.type = ST_T_END;
    element->cos.s.style = style;
    element->next_character = NULL;
    element->previous_character = *current_character;
    if (*current_character) {
        (*current_character)->next_character = element;
    }
    *current_character = element;
}

void
gregorio_add_syllable(gregorio_syllable **current_syllable,
                      int number_of_voices, gregorio_element *elements[],
                      gregorio_character *first_character,
                      gregorio_character *first_translation_character,
                      gregorio_word_position position, char *abovelinestext,
                      gregorio_tr_centering translation_type,
                      gregorio_nlba no_linebreak_area)
{
    gregorio_syllable *next;
    gregorio_element **tab;
    int i;
    if (number_of_voices > MAX_NUMBER_OF_VOICES) {
        gregorio_message(_("too many voices"), "add_syllable", FATAL_ERROR, 0);
        return;
    }
    next = malloc(sizeof(gregorio_syllable));
    if (!next) {
        gregorio_message(_("error in memory allocation"),
                         "add_syllable", FATAL_ERROR, 0);
        return;
    }
    next->type = GRE_SYLLABLE;
    next->additional_infos = 0;
    next->position = position;
    next->no_linebreak_area = no_linebreak_area;
    next->text = first_character;
    next->translation = first_translation_character;
    next->translation_type = translation_type;
    next->abovelinestext = abovelinestext;
    next->next_syllable = NULL;
    next->previous_syllable = *current_syllable;
    tab = (gregorio_element **) malloc(number_of_voices *
                                       sizeof(gregorio_element *));
    if (elements) {
        for (i = 0; i < number_of_voices; i++) {
            tab[i] = elements[i];
        }
    } else {
        for (i = 0; i < number_of_voices; i++) {
            tab[i] = NULL;
        }
    }
    next->elements = tab;
    if (*current_syllable) {
        (*current_syllable)->next_syllable = next;
    }
    *current_syllable = next;
}

void
gregorio_free_one_syllable(gregorio_syllable **syllable, int number_of_voices)
{
    int i;
    gregorio_syllable *next;
    if (!syllable || !*syllable) {
        gregorio_message(_("function called with NULL argument"),
                         "free_one_syllable", WARNING, 0);
        return;
    }
    for (i = 0; i < number_of_voices; i++) {
        gregorio_free_elements((struct gregorio_element **)
                               &((*syllable)->elements[i]));
    }
    if ((*syllable)->text) {
        gregorio_free_characters((*syllable)->text);
    }
    if ((*syllable)->translation) {
        gregorio_free_characters((*syllable)->translation);
    }
    free((*syllable)->abovelinestext);
    next = (*syllable)->next_syllable;
    free((*syllable)->elements);
    free(*syllable);
    *syllable = next;
}

void gregorio_free_syllables(gregorio_syllable **syllable, int number_of_voices)
{
    if (!syllable || !*syllable) {
        gregorio_message(_("function called with NULL argument"),
                         "free_syllables", WARNING, 0);
        return;
    }
    while (*syllable) {
        gregorio_free_one_syllable(syllable, number_of_voices);
    }
}

gregorio_score *gregorio_new_score(void)
{
    gregorio_score *new_score = malloc(sizeof(gregorio_score));
    new_score->first_syllable = NULL;
    new_score->number_of_voices = 1;
    new_score->name = NULL;
    new_score->gabc_copyright = NULL;
    new_score->score_copyright = NULL;
    new_score->initial_style = NORMAL_INITIAL;
    new_score->office_part = NULL;
    new_score->occasion = NULL;
    new_score->meter = NULL;
    new_score->commentary = NULL;
    new_score->arranger = NULL;
    gregorio_source_info_init(&new_score->si);
    new_score->lilypond_preamble = NULL;
    new_score->opustex_preamble = NULL;
    new_score->musixtex_preamble = NULL;
    new_score->first_voice_info = NULL;
    new_score->mode = 0;
    new_score->gregoriotex_font = NULL;
    new_score->user_notes = NULL;
    return new_score;
}

void gregorio_source_info_init(source_info *si)
{
    si->author = NULL;
    si->date = NULL;
    si->manuscript = NULL;
    si->manuscript_reference = NULL;
    si->manuscript_storage_place = NULL;
    si->transcriber = NULL;
    si->transcription_date = NULL;
    si->book = NULL;
}

void gregorio_free_score(gregorio_score *score)
{
    if (!score) {
        gregorio_message(_("function called with NULL argument"),
                         "free_one_syllable", WARNING, 0);
        return;
    }
    gregorio_free_syllables(&(score->first_syllable), score->number_of_voices);
    gregorio_free_score_infos(score);
    free(score);
}

void gregorio_set_score_name(gregorio_score *score, char *name)
{
    if (!score) {
        gregorio_message(_("function called with NULL argument"),
                         "gregorio_set_score_name", WARNING, 0);
        return;
    }
    score->name = name;
}

void
gregorio_set_score_gabc_copyright(gregorio_score *score, char *gabc_copyright)
{
    if (!score) {
        gregorio_message(_("function called with NULL argument"),
                         "gregorio_set_score_gabc_copyright", WARNING, 0);
        return;
    }
    score->gabc_copyright = gabc_copyright;
}

void
gregorio_set_score_score_copyright(gregorio_score *score, char *score_copyright)
{
    if (!score) {
        gregorio_message(_("function called with NULL argument"),
                         "gregorio_set_score_score_copyright", WARNING, 0);
        return;
    }
    score->score_copyright = score_copyright;
}

void gregorio_set_score_office_part(gregorio_score *score, char *office_part)
{
    if (!score) {
        gregorio_message(_("function called with NULL argument"),
                         "gregorio_set_score_office_part", WARNING, 0);
        return;
    }
    score->office_part = office_part;
}

void gregorio_set_score_occasion(gregorio_score *score, char *occasion)
{
    if (!score) {
        gregorio_message(_("function called with NULL argument"),
                         "gregorio_set_score_occasion", WARNING, 0);
        return;
    }
    score->occasion = occasion;
}

void gregorio_set_score_meter(gregorio_score *score, char *meter)
{
    if (!score) {
        gregorio_message(_("function called with NULL argument"),
                         "gregorio_set_score_meter", WARNING, 0);
        return;
    }
    score->meter = meter;
}

void gregorio_set_score_commentary(gregorio_score *score, char *commentary)
{
    if (!score) {
        gregorio_message(_("function called with NULL argument"),
                         "gregorio_set_score_commentary", WARNING, 0);
        return;
    }
    score->commentary = commentary;
}

void gregorio_set_score_arranger(gregorio_score *score, char *arranger)
{
    if (!score) {
        gregorio_message(_("function called with NULL argument"),
                         "gregorio_set_score_arranger", WARNING, 0);
        return;
    }
    score->arranger = arranger;
}

void
gregorio_set_score_number_of_voices(gregorio_score *score, int number_of_voices)
{
    if (!score) {
        gregorio_message(_("function called with NULL argument"),
                         "gregorio_set_score_number_of_voices", WARNING, 0);
        return;
    }
    score->number_of_voices = number_of_voices;
}

void
gregorio_set_score_lilypond_preamble(gregorio_score *score,
                                     char *lilypond_preamble)
{
    if (!score) {
        gregorio_message(_("function called with NULL argument"),
                         "gregorio_set_score_lilypond_preamble", WARNING, 0);
        return;
    }
    score->lilypond_preamble = lilypond_preamble;
}

void
gregorio_set_score_opustex_preamble(gregorio_score *score,
                                    char *opustex_preamble)
{
    if (!score) {
        gregorio_message(_("function called with NULL argument"),
                         "gregorio_set_score_opustex_preamble", WARNING, 0);
        return;
    }
    score->opustex_preamble = opustex_preamble;
}

void
gregorio_set_score_musixtex_preamble(gregorio_score *score,
                                     char *musixtex_preamble)
{
    if (!score) {
        gregorio_message(_("function called with NULL argument"),
                         "gregorio_set_score_musixtex_preamble", WARNING, 0);
        return;
    }
    score->musixtex_preamble = musixtex_preamble;
}

void gregorio_set_score_user_notes(gregorio_score *score, char *user_notes)
{
    if (!score) {
        gregorio_message(_("function called with NULL argument"),
                         "gregorio_set_score_name", WARNING, 0);
        return;
    }
    score->user_notes = user_notes;
}

void gregorio_add_voice_info(gregorio_voice_info **current_voice_info)
{
    int annotation_num;
    gregorio_voice_info *next = malloc(sizeof(gregorio_voice_info));
    next->initial_key = NO_KEY;
    next->flatted_key = NO_FLAT_KEY;
    for (annotation_num = 0; annotation_num < NUM_ANNOTATIONS; ++annotation_num) {
        next->annotation[annotation_num] = NULL;
    }
    next->style = NULL;
    next->virgula_position = NULL;
    next->next_voice_info = NULL;
    if (*current_voice_info) {
        (*current_voice_info)->next_voice_info = next;
    }
    *current_voice_info = next;
}

void gregorio_free_score_infos(gregorio_score *score)
{
    if (!score) {
        gregorio_message(_("function called with NULL argument"),
                         "gregorio_free_score_infos", WARNING, 0);
        return;
    }
    if (score->name) {
        free(score->name);
    }
    if (score->office_part) {
        free(score->office_part);
    }
    if (score->occasion) {
        free(score->occasion);
    }
    if (score->meter) {
        free(score->meter);
    }
    if (score->commentary) {
        free(score->commentary);
    }
    if (score->arranger) {
        free(score->arranger);
    }
    if (score->lilypond_preamble) {
        free(score->lilypond_preamble);
    }
    if (score->opustex_preamble) {
        free(score->opustex_preamble);
    }
    if (score->musixtex_preamble) {
        free(score->musixtex_preamble);
    }
    if (score->user_notes) {
        free(score->user_notes);
    }
    gregorio_free_source_info(&score->si);
    if (score->first_voice_info) {
        gregorio_free_voice_infos(score->first_voice_info);
    }
}

void gregorio_free_source_info(source_info *si)
{
    if (si->date) {
        free(si->date);
    }
    if (si->author) {
        free(si->author);
    }
    if (si->manuscript) {
        free(si->manuscript);
    }
    if (si->manuscript_reference) {
        free(si->manuscript_reference);
    }
    if (si->manuscript_storage_place) {
        free(si->manuscript_storage_place);
    }
    if (si->transcriber) {
        free(si->transcriber);
    }
    if (si->transcription_date) {
        free(si->transcription_date);
    }
}

void gregorio_free_voice_infos(gregorio_voice_info *voice_info)
{
    int annotation_num;
    gregorio_voice_info *next;
    if (!voice_info) {
        gregorio_message(_("function called with NULL argument"),
                         "free_voice_info", WARNING, 0);
        return;
    }
    while (voice_info) {
        for (annotation_num = 0; annotation_num < NUM_ANNOTATIONS;
             ++annotation_num) {
            if (voice_info->annotation[annotation_num]) {
                free(voice_info->annotation[annotation_num]);
            }
        }
        if (voice_info->style) {
            free(voice_info->style);
        }
        if (voice_info->virgula_position) {
            free(voice_info->virgula_position);
        }
        next = voice_info->next_voice_info;
        free(voice_info);
        voice_info = next;
    }
}

/*
 * a set of quite useless function 
 */

void
gregorio_set_voice_annotation(gregorio_voice_info *voice_info, char *annotation)
{
    int annotation_num;
    if (!voice_info) {
        gregorio_message(_("function called with NULL argument"),
                         "gregorio_set_voice_annotation", WARNING, 0);
        return;
    }
    // save the annotation in the first spare place.
    for (annotation_num = 0; annotation_num < NUM_ANNOTATIONS; ++annotation_num) {
        if (voice_info->annotation[annotation_num] == NULL) {
            voice_info->annotation[annotation_num] = annotation;
            break;
        }
    }
}

void gregorio_set_score_author(gregorio_score *score, char *author)
{
    if (!score) {
        gregorio_message(_("function called with NULL argument"),
                         "gregorio_set_score_author", WARNING, 0);
        return;
    }
    score->si.author = author;
}

void gregorio_set_score_date(gregorio_score *score, char *date)
{
    if (!score) {
        gregorio_message(_("function called with NULL argument"),
                         "gregorio_set_score_date", WARNING, 0);
        return;
    }
    score->si.date = date;
}

void gregorio_set_score_manuscript(gregorio_score *score, char *manuscript)
{
    if (!score) {
        gregorio_message(_("function called with NULL argument"),
                         "gregorio_set_score_manuscript", WARNING, 0);
        return;
    }
    score->si.manuscript = manuscript;
}

void
gregorio_set_score_manuscript_reference(gregorio_score *score,
                                        char *manuscript_reference)
{
    if (!score) {
        gregorio_message(_("function called with NULL argument"),
                         "gregorio_set_score_reference", WARNING, 0);
        return;
    }
    score->si.manuscript_reference = manuscript_reference;
}

void
gregorio_set_score_manuscript_storage_place(gregorio_score *score,
                                            char *manuscript_storage_place)
{
    if (!score) {
        gregorio_message(_("function called with NULL argument"),
                         "gregorio_set_score_manuscript_storage_place", WARNING,
                         0);
        return;
    }
    score->si.manuscript_storage_place = manuscript_storage_place;
}

void gregorio_set_score_book(gregorio_score *score, char *book)
{
    if (!score) {
        gregorio_message(_("function called with NULL argument"),
                         "gregorio_set_score_book", WARNING, 0);
        return;
    }
    score->si.book = book;
}

void gregorio_set_score_transcriber(gregorio_score *score, char *transcriber)
{
    if (!score) {
        gregorio_message(_("function called with NULL argument"),
                         "gregorio_set_score_transcriber", WARNING, 0);
        return;
    }
    score->si.transcriber = transcriber;
}

void
gregorio_set_score_transcription_date(gregorio_score *score,
                                      char *transcription_date)
{
    if (!score) {
        gregorio_message(_("function called with NULL argument"),
                         "gregorio_set_score_transcription_date", WARNING, 0);
        return;
    }
    score->si.transcription_date = transcription_date;
}

void gregorio_set_voice_style(gregorio_voice_info *voice_info, char *style)
{
    if (!voice_info) {
        gregorio_message(_("function called with NULL argument"),
                         "gregorio_set_voice_style", WARNING, 0);
        return;
    }
    voice_info->style = style;
}

void
gregorio_set_voice_virgula_position(gregorio_voice_info *voice_info,
                                    char *virgula_position)
{
    if (!voice_info) {
        gregorio_message(_("function called with NULL argument"),
                         "gregorio_set_voice_virgula_position", WARNING, 0);
        return;
    }
    voice_info->virgula_position = virgula_position;
}

/**********************************
 *
 * Activate_isolated_h_episemus is used when we see an "isolated"
 * horizontal episemus: when we type ab__ lex see a then b then _ then _, so
 * we must put the _ on the a (kind of backward process), and say the
 * the episemus on the b is a multi episemus. Here n is the length of
 * the isolated episemus we found (can be up to 4).
 *
 *********************************/
void gregorio_activate_isolated_h_episemus(gregorio_note *current_note, int n)
{
    int i;
    gregorio_note *tmp = current_note;
    char top_note;
    if (!current_note) {
        gregorio_message(ngt_
                         ("isolated horizontal episemus at the beginning of a note sequence, ignored",
                          "isolated horizontal episemus at the beginning of a note sequence, ignored",
                          n), "activate_h_isolated_episemus", WARNING, 0);
        return;
    }
    if (current_note->type != GRE_NOTE) {
        gregorio_message(ngt_
                         ("isolated horizontal episemus after something that is not a note, ignored",
                          "isolated horizontal episemus after something that is not a note, ignored",
                          n), "activate_h_isolated_episemus", WARNING, 0);
        return;
    }
    /*
     * we make the first iteration by hand,in the case where something would be 
     * in highest_pitch 
     */
    top_note = current_note->pitch;
    tmp = tmp->previous;
    if (!tmp) {
        // case of b___
        gregorio_message(_
                         ("found more horizontal episemus than notes able to be under"),
                         "activate_h_isolated_episemus", WARNING, 0);
        return;
    }
    top_note = max(top_note, tmp->pitch);
    for (i = 0; i < n - 1; i++) {
        top_note = max(top_note, tmp->pitch);
        if (tmp->previous && tmp->previous->type == GRE_NOTE) {
            tmp = tmp->previous;
            top_note = max(top_note, tmp->pitch);
        } else {
            gregorio_message(_
                             ("found more horizontal episemus than notes able to be under"),
                             "activate_h_isolated_episemus", WARNING, 0);
            break;
        }
    }
    // improvement: we consider also the previous note (if it's a GRE_NOTE) for
    // the top note. TODO: we should consider also the next note, but we cannot
    // do it at this stage.
    if (tmp->previous && tmp->previous->type == GRE_NOTE) {
        top_note = max(top_note, tmp->previous->pitch);
    }
    while (tmp) {
        gregorio_set_h_episemus(tmp, H_MULTI);
        tmp->h_episemus_top_note = top_note;
        tmp = tmp->next;
    }

}

/**********************************
 *
 * Top notes are present in the score structure for the horizontal
 * episemus: if we type ab__ we must put the top notes of the two
 * notes to b, that's what is done with this function. It is a quite
 * complex process (see mix_h_episemus for details). This function
 * supposes that top notes of the previous notes of the episemus are
 * good. If the current_note is higher, it will set the previous
 * top-notes to this note, and if it is note it will set the top note
 * of the current note to the top note of the previous notes. Kind of
 * recursive process in fact.
 *
 *********************************/

void gregorio_determine_good_top_notes(gregorio_note *current_note)
{
    char top_note;
    gregorio_note *prev_note;
    if (!current_note) {
        gregorio_message(_
                         ("call with NULL argument"),
                         "gregorio_determine_good_top_notes", ERROR, 0);
        return;
    }
    prev_note = current_note->previous;
    if (!prev_note) {
        return;
    }
    if (current_note->h_episemus_top_note <= prev_note->h_episemus_top_note) {
        current_note->h_episemus_top_note = prev_note->h_episemus_top_note;
    } else {
        top_note = current_note->h_episemus_top_note;
        while (prev_note && simple_htype(prev_note->h_episemus_type) == H_MULTI) {
            prev_note->h_episemus_top_note = top_note;
            prev_note = prev_note->previous;
        }
    }
}

// same with bottom notes

void gregorio_determine_good_bottom_notes(gregorio_note *current_note)
{
    char bottom_note;
    gregorio_note *prev_note;
    if (!current_note) {
        gregorio_message(_
                         ("call with NULL argument"),
                         "gregorio_determine_good_bottom_notes", ERROR, 0);
        return;
    }
    prev_note = current_note->previous;
    current_note->h_episemus_bottom_note = current_note->pitch;
    if (!prev_note) {
        return;
    }
    if (prev_note->type == GRE_SPACE && prev_note->pitch == SP_ZERO_WIDTH
        && prev_note->previous) {
        prev_note = prev_note->previous;
        if (!prev_note || !has_bottom(prev_note->h_episemus_type)) {
            return;
        }
    }
    if (!has_bottom(prev_note->h_episemus_type)) {
        return;
    }
    if (current_note->h_episemus_bottom_note >=
        prev_note->h_episemus_bottom_note) {
        current_note->h_episemus_bottom_note =
            prev_note->h_episemus_bottom_note;
    } else {
        bottom_note = current_note->h_episemus_bottom_note;
        while (prev_note) {
            if (!has_bottom(prev_note->h_episemus_type)) {
                if (prev_note->type == GRE_SPACE
                    && prev_note->pitch == SP_ZERO_WIDTH
                    && prev_note->previous) {
                    prev_note = prev_note->previous;
                    continue;
                } else {
                    return;
                }
            }
            prev_note->h_episemus_bottom_note = bottom_note;
            prev_note = prev_note->previous;
        }
    }
}

/**********************************
 *
 * mix_h_episemus is quite uneasy to understand. The basis is that: we
 * have determined well the previous h episemus until the current note
 * (even the top notes !), now we have a h episemus (argument type)
 * and we would like to integrate it. That's what we do there.
 *
 *********************************/

void gregorio_mix_h_episemus(gregorio_note *current_note, unsigned char type)
{
    gregorio_note *prev_note = NULL;
    if (!current_note) {
        gregorio_message(_("function called with NULL argument"),
                         "gregorio_mix_h_episemus", WARNING, 0);
        return;
    }
    // case of the bar with a brace above it
    if (current_note->type != GRE_NOTE) {
        current_note->h_episemus_type = H_ALONE;
    }
    prev_note = current_note->previous;
    if (type == H_NO_EPISEMUS) {
        gregorio_set_h_episemus(current_note, H_NO_EPISEMUS);
        current_note->h_episemus_top_note = 0;
    } else {
        if (prev_note && prev_note->type == GRE_NOTE) {
            current_note->h_episemus_top_note =
                max(prev_note->pitch, current_note->pitch);
        } else {
            current_note->h_episemus_top_note = current_note->pitch;
        }
        if (!prev_note || prev_note->type != GRE_NOTE
            || simple_htype(prev_note->h_episemus_type) == H_NO_EPISEMUS) {
            gregorio_set_h_episemus(current_note, H_ALONE);
        } else {
            gregorio_set_h_episemus(current_note, H_MULTI);
            if (simple_htype(prev_note->h_episemus_type) != H_MULTI) {
                gregorio_set_h_episemus(prev_note, H_MULTI);
            }
            gregorio_determine_good_top_notes(current_note);
        }
    }
}

/**********************************
 *
 * There are still problems with the h episemus (for example if you
 * separate a multi h episemus into two different elements, this is a
 * patch function that makes it better, but it is quite ugly. What I
 * think would be better (TODO) is to determine h episemus in the
 * element determination part, so that it will be ok in the score
 * structure. But element determination part is not enough advanced
 * for that.
 *
 *********************************/

void gregorio_determine_h_episemus_type(gregorio_note *note)
{
    if (!note) {
        gregorio_message(_("function called with NULL argument"),
                         "determine_h_episemus_type", WARNING, 0);
        return;
    }
    if (simple_htype(note->h_episemus_type) == H_NO_EPISEMUS
        || simple_htype(note->h_episemus_type) == H_ALONE) {
        return;
    }
    // here h_episemus_type is H_MULTI
    if ((!note->next || note->next->type != GRE_NOTE)
        && (!note->previous || note->previous->type != GRE_NOTE)) {
        gregorio_set_h_episemus(note, H_ALONE);
        return;
    }

    if (note->next && note->next->type == GRE_NOTE) {
        if (is_multi(note->next->h_episemus_type)) {
            gregorio_set_h_episemus(note, H_MULTI_MIDDLE);
        } else {
            gregorio_set_h_episemus(note, H_MULTI_END);
        }
    } else {
        if (note->previous->h_episemus_type == H_NO_EPISEMUS) {
            gregorio_set_h_episemus(note, H_ALONE);
            return;
        } else {
            gregorio_set_h_episemus(note, H_MULTI_END);
        }
    }

    if (note->previous && note->previous->type == GRE_NOTE) {
        if (is_multi(note->previous->h_episemus_type)) {
            if (simple_htype(note->h_episemus_type) != H_MULTI_END) {
                gregorio_set_h_episemus(note, H_MULTI_MIDDLE);
            }
        } else {
            gregorio_set_h_episemus(note, H_MULTI_BEGINNING);
        }
    } else {
        if (simple_htype(note->next->h_episemus_type) == H_NO_EPISEMUS) {
            gregorio_set_h_episemus(note, H_ALONE);
        } else {
            gregorio_set_h_episemus(note, H_MULTI_BEGINNING);
        }
    }

}

/**********************************
 *
 * Very small function to determine if a punctum is a punctum
 * inclinatum or not.
 *
 *********************************/

gregorio_shape gregorio_det_shape(char pitch)
{
    if (pitch < 'a') {
        return S_PUNCTUM_INCLINATUM;
    } else {
        return S_PUNCTUM;
    }
}

/**********************************
 *
 * A function to build an integer from a key, very useful to represent
 * it in the structure.
 *
 *The representation is :
 *
 * * 1 for a C key on the first (bottom) line
 * * 3 for a C key on the second line
 * * 5 for a C key on the third line (default key)
 * * 7 for a C key on the fourth line
 *
 * * -2 for a F key on the first line
 * * 0 for a F key on the second line
 * * 2 for a F key on the third line
 * * 4 for a F key on the fourth line
 *
 *********************************/

int gregorio_calculate_new_key(char step, int line)
{
    switch (step) {
    case C_KEY:
        return (2 * line) - 1;
        break;
    case F_KEY:
        return (2 * line) - 4;
        break;
    default:
        gregorio_message(_("can't calculate key"),
                         "gregorio_calculate_new_key", ERROR, 0);
        return NO_KEY;
    }
}

/**********************************
 *
 * The reverse function of the preceeding : give step (c or f) and
 * line (1-4) from an integer representing the key.
 *
 *********************************/

void gregorio_det_step_and_line_from_key(int key, char *step, int *line)
{
    switch (key) {
    case -2:
        *step = 'f';
        *line = 1;
        break;
    case 0:
        *step = 'f';
        *line = 2;
        break;
    case 2:
        *step = 'f';
        *line = 3;
        break;
    case 4:
        *step = 'f';
        *line = 4;
        break;
    case 1:
        *step = 'c';
        *line = 1;
        break;
    case 3:
        *step = 'c';
        *line = 2;
        break;
    case 5:
        *step = 'c';
        *line = 3;
        break;
    case 7:
        *step = 'c';
        *line = 4;
        break;
    default:
        *step = '?';
        *line = 0;
        gregorio_message(_("can't determine step and line of the key"),
                         "gregorio_det_step_and_line_from_key", ERROR, 0);
        return;
    }
}

/**********************************
 *
 * You must be asking yourself why such numbers ? It is simple : it
 * are the magic numbers that make a correspondance between the height
 * (on the score) and the real pitch (depending on the key) of a note
 * !
 *
 * Demonstration : when you have a c key on the third line, it is
 * represented by 5. To have the height (on the score) of a note, you
 * simple add the key to the step ! for exemple you want to know the
 * letter by which an a will be represented : you do a + 5 = f !
 *
 * Of course you need to add or withdraw 7 depending on which octave
 * the note you want is in.
 *
 *********************************/

char gregorio_det_pitch(int key, char step, int octave)
{
    switch (octave) {
    case (2):
        return key + step;
        break;
    case (1):
        return key + step - 7;
        break;
    case (3):
        return key + step + 7;
        break;
    default:
        gregorio_message(_("unknown octave"),   // TODO : à améliorer
                         "gregorio_det_pitch", ERROR, 0);
        return 0;
        break;
    }
}

/**********************************
 *
 * The reverse function of the preceeding, it gives you the step and
 * the octave of a character representing a note, according to the
 * key.
 *
 *********************************/

void
gregorio_set_octave_and_step_from_pitch(char *step,
                                        int *octave, char pitch, int clef)
{
    if (pitch - clef < 97) {
        *step = pitch - clef + 7;
        *octave = 1;
        return;
    }
    if (pitch - clef > 103) {
        *step = pitch - clef - 7;
        *octave = 3;
        return;
    }
    // else :
    *step = pitch - clef;
    *octave = 2;
}

char
 gregorio_determine_next_pitch
    (gregorio_syllable *syllable, gregorio_element *element,
     gregorio_glyph *glyph) {
    char temp;
    if (!element || !syllable) {
        gregorio_message(_
                         ("called with a NULL argument"),
                         "gregorio_determine_next_pitch", ERROR, 0);
        return 'g';
    }
    // we first explore the next glyphs to find a note, if there is one
    if (glyph) {
        glyph = glyph->next;
        while (glyph) {
            if (glyph->type == GRE_GLYPH && glyph->first_note) {
                return glyph->first_note->pitch;
            }
            glyph = glyph->next;
        }
    }
    // then we do the same with the elements
    element = element->next;
    while (element) {
        if (element->type == GRE_ELEMENT && element->first_glyph) {
            glyph = element->first_glyph;
            while (glyph) {
                if (glyph->type == GRE_GLYPH && glyph->first_note) {
                    return glyph->first_note->pitch;
                }
                glyph = glyph->next;
            }
        }
        element = element->next;
    }

    // then we do the same with the syllables
    syllable = syllable->next_syllable;
    while (syllable) {
        // we call another function that will return the pitch of the first
        // note if syllable has a note, and 0 else
        temp = gregorio_syllable_first_note(syllable);
        if (temp) {
            return temp;
        }
        syllable = syllable->next_syllable;
    }
    // here it means that there is no next note, so we return a stupid value,
    // but it won' t be used
    return 'g';
}

gregorio_glyph *gregorio_first_glyph(gregorio_syllable *syllable)
{
    gregorio_glyph *glyph;
    gregorio_element *element;
    if (!syllable) {
        gregorio_message(_
                         ("called with a NULL argument"),
                         "gregorio_first_glyph", ERROR, 0);
    }
    element = syllable->elements[0];
    while (element) {
        if (element->type == GRE_ELEMENT && element->first_glyph) {
            glyph = element->first_glyph;
            while (glyph) {
                if (glyph->type == GRE_GLYPH && glyph->first_note) {
                    return glyph;
                }
                glyph = glyph->next;
            }
        }
        element = element->next;
    }
    return NULL;
}

char gregorio_syllable_first_note(gregorio_syllable *syllable)
{
    gregorio_glyph *glyph;
    glyph = gregorio_first_glyph(syllable);
    if (glyph == NULL) {
        return 0;
    } else {
        return glyph->first_note->pitch;
    }
}

/**********************************
 *
 * A function that may be useful (used in xml-write) : we have a
 * tabular of alterations (we must remember all alterations on all
 * notes all the time, they are reinitialized when a bar is found),
 * and we assign all of them to NO_ALTERATION.
 *
 *This function works in fact with a tabular of tabular, one per
 *voice, for polyphony.
 *
 *********************************/

void
gregorio_reinitialize_alterations(char alterations[][13], int number_of_voices)
{
    int i;
    int j;
    for (j = 0; j < number_of_voices; j++) {
        for (i = 0; i < 13; i++) {
            alterations[j][i] = NO_ALTERATION;
        }
    }
}

/**********************************
 *
 * The corresponding function for monophony.
 *
 *********************************/

void gregorio_reinitialize_one_voice_alterations(char alterations[13])
{
    int i;
    for (i = 0; i < 13; i++) {
        alterations[i] = NO_ALTERATION;
    }
}

/*
 * void gregorio_fix_positions (gregorio_score * score) { if (!score ||
 * !score->first_syllable) { //TODO : warning return; } gregorio_syllable
 * *syllable = score->first_syllable; while (syllable) { //TODO : here the case 
 * onesyllable(notes)*(:) anothersyllable(othernotes) is not trated if
 * (!syllable->next_syllable || syllable->next_syllable->position ==
 * WORD_BEGINNING) { if (syllable->position != WORD_BEGINNING) {
 * syllable->position = WORD_END; } } syllable = syllable->next_syllable; } } 
 */

/**********************************
 *
 * A function called after the entire score is determined : we check
 * if the first element is a key change, if it is the case we delete
 * it and we update the score->voice-info->initial_key. Works in
 * polyphony.
 *
 *********************************/

void gregorio_fix_initial_keys(gregorio_score *score, int default_key)
{
    char *error;
    int clef = 0;
    gregorio_element *element;
    gregorio_voice_info *voice_info;
    int i;
    char to_delete = 1;

    if (!score || !score->first_syllable || !score->first_voice_info) {
        gregorio_message(_("score is not available"),
                         "gregorio_fix_initial_keys", WARNING, 0);
        return;
    }
    error = malloc(100 * sizeof(char));
    voice_info = score->first_voice_info;
    for (i = 0; i < score->number_of_voices; i++) {
        element = score->first_syllable->elements[i];
        if (!element) {
            continue;
        }
        if (element->type == GRE_C_KEY_CHANGE) {
            clef =
                gregorio_calculate_new_key(C_KEY, element->element_type - 48);
            voice_info->initial_key = clef;
            if (element->additional_infos == FLAT_KEY) {
                voice_info->flatted_key = FLAT_KEY;
            }
            gregorio_free_one_element(&(score->first_syllable->elements[i]));
            voice_info = voice_info->next_voice_info;
            snprintf(error, 80,
                     _
                     ("in voice %d the first element is a key definition, considered as initial key"),
                     i + 1);
            gregorio_message(error, "gregorio_fix_initial_keys", VERBOSE, 0);

            continue;
        }
        if (element->type == GRE_F_KEY_CHANGE) {
            clef =
                gregorio_calculate_new_key(F_KEY, element->element_type - 48);
            voice_info->initial_key = clef;
            if (element->additional_infos == FLAT_KEY) {
                voice_info->flatted_key = FLAT_KEY;
            }
            gregorio_free_one_element(&(score->first_syllable->elements[i]));
            snprintf(error, 80,
                     _
                     ("in voice %d the first element is a key definition, considered as initial key"),
                     i + 1);
            gregorio_message(error, "gregorio_fix_initial_keys", VERBOSE, 0);
        }
        voice_info = voice_info->next_voice_info;
    }

    // then we suppress syllables that contain nothing anymore : case of (c2)
    // at beginning of files

    for (i = 0; i < score->number_of_voices; i++) {
        if (score->first_syllable->elements[i]) {
            to_delete = 0;
            break;
        }
    }

    if (to_delete) {
        gregorio_free_one_syllable(&(score->first_syllable),
                                   score->number_of_voices);
    }
    // finally we initialize voice infos that have no initial key to default
    // key

    voice_info = score->first_voice_info;

    for (i = 0; i < score->number_of_voices; i++) {
        if (voice_info->initial_key == NO_KEY) {
            voice_info->initial_key = default_key;
            snprintf(error, 75,
                     _
                     ("no initial key definition in voice %d, default key definition applied"),
                     i + 1);
            gregorio_message(error, "gregorio_fix_initial_keys", VERBOSE, 0);
        }
        voice_info = voice_info->next_voice_info;
    }
    free(error);
}

/**********************************
 *
 * A small function to determine if an element list contains only
 * special elements (bar, key-change, etc.), useful because the
 * representation (in xml for example) may vary according to it.
 *
 *********************************/

char gregorio_is_only_special(gregorio_element *element)
{
    if (!element) {
        return 0;
    }
    while (element) {
        if (element->type == GRE_ELEMENT) {
            return 0;
        }
        element = element->next;
    }
    return 1;
}
