/*
 * Copyright (C) 2007-2015 The Gregorio Project (see CONTRIBUTORS.md)
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

#include "config.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "struct.h"
#include "unicode.h"
#include "messages.h"

static const char *dump_translation_type_to_string(gregorio_tr_centering
                                            translation_type)
{
    switch (translation_type) {
    case TR_NORMAL:
        return "TR_NORMAL";
        break;
    case TR_WITH_CENTER_BEGINNING:
        return "TR_WITH_CENTER_BEGINNING";
        break;
    case TR_WITH_CENTER_END:
        return "TR_WITH_CENTER_END";
        break;
    default:
        return "";
        break;
    }
}

static const char *dump_nlba_to_string(gregorio_nlba no_linebreak_area)
{
    switch (no_linebreak_area) {
    case NLBA_NORMAL:
        return "NLBA_NORMAL";
        break;
    case NLBA_BEGINNING:
        return "NLBA_BEGINNING";
        break;
    case NLBA_END:
        return "NLBA_END";
        break;
    default:
        return "";
        break;
    }
}

static const char *dump_style_to_string(grestyle_style style)
{
    switch (style) {
    case ST_NO_STYLE:
        return "     ST_NO_STYLE";
        break;
    case ST_ITALIC:
        return "       ST_ITALIC";
        break;
    case ST_CENTER:
        return "       ST_CENTER";
        break;
    case ST_FORCED_CENTER:
        return " ST_FORCED_CENTER";
        break;
    case ST_INITIAL:
        return "      ST_INITIAL";
        break;
    case ST_BOLD:
        return "         ST_BOLD";
        break;
    case ST_TT:
        return "           ST_TT";
        break;
    case ST_UNDERLINED:
        return "   ST_UNDERLINED";
        break;
    case ST_COLORED:
        return "      ST_COLORED";
        break;
    case ST_SMALL_CAPS:
        return "   ST_SMALL_CAPS";
        break;
    case ST_SPECIAL_CHAR:
        return " ST_SPECIAL_CHAR";
        break;
    case ST_VERBATIM:
        return "     ST_VERBATIM";
        break;
    default:
        return "";
        break;
    }
}

static void dump_write_characters(FILE *f,
        gregorio_character *current_character)
{
    while (current_character) {
        fprintf(f,
                "---------------------------------------------------------------------\n");
        if (current_character->is_character) {
            fprintf(f, "     character                 ");
            gregorio_print_unichar(f, current_character->cos.character);
            fprintf(f, "\n");
        } else {
            if (current_character->cos.s.type == ST_T_BEGIN) {
                fprintf(f, "     beginning of style   %s\n",
                        dump_style_to_string(current_character->cos.s.style));
            } else {
                fprintf(f, "     end of style         %s\n",
                        dump_style_to_string(current_character->cos.s.style));
            }
        }
        current_character = current_character->next_character;
    }
}

static const char *dump_key_to_char(int key)
{
    const char *str;
    switch (key) {
    case -2:
        str = "f1";
        break;
    case 0:
        str = "f2";
        break;
    case 2:
        str = "f3";
        break;
    case 4:
        str = "f4";
        break;
    case 1:
        str = "c1";
        break;
    case 3:
        str = "c2";
        break;
    case 5:
        str = "c3";
        break;
    case 7:
        str = "c4";
        break;
    default:
        str = "no key defined";
        break;
    }
    return str;
}

static const char *dump_syllable_position(gregorio_word_position pos)
{
    const char *str;
    switch (pos) {
    case WORD_BEGINNING:
        str = "WORD_BEGINNING";
        break;
    case WORD_MIDDLE:
        str = "WORD_MIDDLE";
        break;
    case WORD_END:
        str = "WORD_END";
        break;
    case WORD_ONE_SYLLABLE:
        str = "WORD_ONE_SYLLABLE";
        break;
    default:
        str = "unknown";
        break;
    }
    return str;
}

static const char *dump_type(gregorio_type type)
{
    const char *str;
    switch (type) {
    case GRE_NOTE:
        str = "GRE_NOTE";
        break;
    case GRE_GLYPH:
        str = "GRE_GLYPH";
        break;
    case GRE_ELEMENT:
        str = "GRE_ELEMENT";
        break;
    case GRE_FLAT:
        str = "GRE_FLAT";
        break;
    case GRE_SHARP:
        str = "GRE_SHARP";
        break;
    case GRE_NATURAL:
        str = "GRE_NATURAL";
        break;
    case GRE_C_KEY_CHANGE:
        str = "GRE_C_KEY_CHANGE";
        break;
    case GRE_F_KEY_CHANGE:
        str = "GRE_F_KEY_CHANGE";
        break;
    case GRE_END_OF_LINE:
        str = "GRE_END_OF_LINE";
        break;
    case GRE_END_OF_PAR:
        str = "GRE_END_OF_PAR";
        break;
    case GRE_CUSTO:
        str = "GRE_CUSTO";
        break;
    case GRE_SPACE:
        str = "GRE_SPACE";
        break;
    case GRE_BAR:
        str = "GRE_BAR";
        break;
    case GRE_SYLLABLE:
        str = "GRE_SYLLABLE";
        break;
    case GRE_TEXVERB_GLYPH:
        str = "GRE_TEXVERB_GLYPH";
        break;
    case GRE_TEXVERB_ELEMENT:
        str = "GRE_TEXVERB_ELEMENT";
        break;
    case GRE_NLBA:
        str = "GRE_NLBA";
        break;
    case GRE_ALT:
        str = "GRE_ALT";
        break;
    case GRE_MANUAL_CUSTOS:
        str = "GRE_MANUAL_CUSTOS";
        break;
    default:
        str = "unknown";
        break;
    }
    return str;
}

static const char *dump_bar_type(gregorio_bar element_type)
{
    const char *str;
    switch (element_type) {
    case B_NO_BAR:
        str = "B_NO_BAR";
        break;
    case B_VIRGULA:
        str = "B_VIRGULA";
        break;
    case B_DIVISIO_MINIMA:
        str = "B_DIVISIO_MINIMA";
        break;
    case B_DIVISIO_MINOR:
        str = "B_DIVISIO_MINOR";
        break;
    case B_DIVISIO_MAIOR:
        str = "B_DIVISIO_MAIOR";
        break;
    case B_DIVISIO_FINALIS:
        str = "B_DIVISIO_FINALIS";
        break;
    case B_DIVISIO_MINOR_D1:
        str = "B_DIVISIO_MINOR_D1";
        break;
    case B_DIVISIO_MINOR_D2:
        str = "B_DIVISIO_MINOR_D2";
        break;
    case B_DIVISIO_MINOR_D3:
        str = "B_DIVISIO_MINOR_D3";
        break;
    case B_DIVISIO_MINOR_D4:
        str = "B_DIVISIO_MINOR_D4";
        break;
    case B_DIVISIO_MINOR_D5:
        str = "B_DIVISIO_MINOR_D5";
        break;
    case B_DIVISIO_MINOR_D6:
        str = "B_DIVISIO_MINOR_D6";
        break;
    default:
        str = "unknown";
        break;
    }
    return str;
}

static const char *dump_space_type(gregorio_space element_type)
{
    const char *str;
    switch (element_type) {
    case SP_DEFAULT:
        str = "SP_DEFAULT";
        break;
    case SP_NO_SPACE:
        str = "SP_NO_SPACE";
        break;
    case SP_ZERO_WIDTH:
        str = "SP_ZERO_WIDTH";
        break;
    case SP_NEUMATIC_CUT:
        str = "SP_NEUMATIC_CUT";
        break;
    case SP_LARGER_SPACE:
        str = "SP_LARGER_SPACE";
        break;
    case SP_GLYPH_SPACE:
        str = "SP_GLYPH_SPACE";
        break;
    case SP_GLYPH_SPACE_NB:
        str = "SP_GLYPH_SPACE_NB";
        break;
    case SP_LARGER_SPACE_NB:
        str = "SP_LARGER_SPACE_NB";
        break;
    case SP_NEUMATIC_CUT_NB:
        str = "SP_NEUMATIC_CUT_NB";
        break;
    default:
        str = "unknown";
        break;
    }
    return str;
}

static const char *dump_liquescentia(gregorio_liquescentia liquescentia)
{
    const char *str;
    switch (liquescentia) {
    case L_NO_LIQUESCENTIA:
        str = "L_NO_LIQUESCENTIA";
        break;
    case L_DEMINUTUS:
        str = "L_DEMINUTUS";
        break;
    case L_AUCTUS_ASCENDENS:
        str = "L_AUCTUS_ASCENDENS";
        break;
    case L_AUCTUS_DESCENDENS:
        str = "L_AUCTUS_DESCENDENS";
        break;
    case L_AUCTA:
        str = "L_AUCTA";
        break;
    case L_INITIO_DEBILIS:
        str = "L_INITIO_DEBILIS";
        break;
    case L_DEMINUTUS_INITIO_DEBILIS:
        str = "L_DEMINUTUS_INITIO_DEBILIS";
        break;
    case L_AUCTUS_ASCENDENS_INITIO_DEBILIS:
        str = "L_AUCTUS_ASCENDENS_INITIO_DEBILIS";
        break;
    case L_AUCTUS_DESCENDENS_INITIO_DEBILIS:
        str = "L_AUCTUS_DESCENDENS_INITIO_DEBILIS";
        break;
    case L_AUCTA_INITIO_DEBILIS:
        str = "L_AUCTA_INITIO_DEBILIS";
        break;
    default:
        str = "unknown";
        break;
    }
    return str;
}

static const char *dump_glyph_type(gregorio_glyph_type glyph_type)
{
    const char *str;
    switch (glyph_type) {
    case G_PUNCTUM_INCLINATUM:
        str = "G_PUNCTUM_INCLINATUM";
        break;
    case G_2_PUNCTA_INCLINATA_DESCENDENS:
        str = "G_2_PUNCTA_INCLINATA_DESCENDENS";
        break;
    case G_3_PUNCTA_INCLINATA_DESCENDENS:
        str = "G_3_PUNCTA_INCLINATA_DESCENDENS";
        break;
    case G_4_PUNCTA_INCLINATA_DESCENDENS:
        str = "G_4_PUNCTA_INCLINATA_DESCENDENS";
        break;
    case G_5_PUNCTA_INCLINATA_DESCENDENS:
        str = "G_5_PUNCTA_INCLINATA_DESCENDENS";
        break;
    case G_2_PUNCTA_INCLINATA_ASCENDENS:
        str = "G_2_PUNCTA_INCLINATA_ASCENDENS";
        break;
    case G_3_PUNCTA_INCLINATA_ASCENDENS:
        str = "G_3_PUNCTA_INCLINATA_ASCENDENS";
        break;
    case G_4_PUNCTA_INCLINATA_ASCENDENS:
        str = "G_4_PUNCTA_INCLINATA_ASCENDENS";
        break;
    case G_5_PUNCTA_INCLINATA_ASCENDENS:
        str = "G_5_PUNCTA_INCLINATA_ASCENDENS";
        break;
    case G_TRIGONUS:
        str = "G_TRIGONUS";
        break;
    case G_PUNCTA_INCLINATA:
        str = "G_PUNCTA_INCLINATA";
        break;
    case G_UNDETERMINED:
        str = "G_UNDETERMINED";
        break;
    case G_VIRGA:
        str = "G_VIRGA";
        break;
    case G_VIRGA_REVERSA:
        str = "G_VIRGA_REVERSA";
        break;
    case G_STROPHA:
        str = "G_STROPHA";
        break;
    case G_STROPHA_AUCTA:
        str = "G_STROPHA_AUCTA";
        break;
    case G_PUNCTUM:
        str = "G_PUNCTUM";
        break;
    case G_PODATUS:
        str = "G_PODATUS";
        break;
    case G_PES_QUADRATUM:
        str = "G_PES_QUADRATUM";
        break;
    case G_FLEXA:
        str = "G_FLEXA";
        break;
    case G_TORCULUS:
        str = "G_TORCULUS";
        break;
    case G_TORCULUS_RESUPINUS:
        str = "G_TORCULUS_RESUPINUS";
        break;
    case G_TORCULUS_RESUPINUS_FLEXUS:
        str = "G_TORCULUS_RESUPINUS_FLEXUS";
        break;
    case G_PORRECTUS:
        str = "G_PORRECTUS";
        break;
    case G_PORRECTUS_FLEXUS:
        str = "G_PORRECTUS_FLEXUS";
        break;
    case G_BIVIRGA:
        str = "G_BIVIRGA";
        break;
    case G_TRIVIRGA:
        str = "G_TRIVIRGA";
        break;
    case G_DISTROPHA:
        str = "G_DISTROPHA";
        break;
    case G_DISTROPHA_AUCTA:
        str = "G_DISTROPHA_AUCTA";
        break;
    case G_TRISTROPHA:
        str = "G_TRISTROPHA";
        break;
    case G_ANCUS:
        str = "G_ANCUS";
        break;
    case G_TRISTROPHA_AUCTA:
        str = "G_TRISTROPHA_AUCTA";
        break;
    case G_PES_QUADRATUM_FIRST_PART:
        str = "G_PES_QUADRATUM_FIRST_PART";
        break;
    case G_SCANDICUS:
        str = "G_SCANDICUS";
        break;
    case G_SALICUS:
        str = "G_SALICUS";
        break;
    case G_VIRGA_STRATA:
        str = "G_VIRGA_STRATA";
        break;
    case G_TORCULUS_LIQUESCENS:
        str = "G_TORCULUS_LIQUESCENS";
        break;
    default:
        str = "unknown";
        break;
    }
    return str;
}

static const char *dump_shape(gregorio_shape shape)
{
    const char *str;
    switch (shape) {
    case S_UNDETERMINED:
        str = "S_UNDETERMINED";
        break;
    case S_PUNCTUM:
        str = "S_PUNCTUM";
        break;
    case S_PUNCTUM_END_OF_GLYPH:
        str = "S_PUNCTUM_END_OF_GLYPH";
        break;
    case S_PUNCTUM_INCLINATUM:
        str = "S_PUNCTUM_INCLINATUM";
        break;
    case S_PUNCTUM_INCLINATUM_DEMINUTUS:
        str = "S_PUNCTUM_INCLINATUM_DEMINUTUS";
        break;
    case S_PUNCTUM_INCLINATUM_AUCTUS:
        str = "S_PUNCTUM_INCLINATUM_AUCTUS";
        break;
    case S_VIRGA:
        str = "S_VIRGA";
        break;
    case S_VIRGA_REVERSA:
        str = "S_VIRGA_REVERSA";
        break;
    case S_BIVIRGA:
        str = "S_BIVIRGA";
        break;
    case S_TRIVIRGA:
        str = "S_TRIVIRGA";
        break;
    case S_ORISCUS:
        str = "S_ORISCUS";
        break;
    case S_ORISCUS_AUCTUS:
        str = "S_ORISCUS_AUCTUS";
        break;
    case S_ORISCUS_DEMINUTUS:
        str = "S_ORISCUS_DEMINUTUS";
        break;
    case S_ORISCUS_SCAPUS:
        str = "S_ORISCUS_SCAPUS";
        break;
    case S_QUILISMA:
        str = "S_QUILISMA";
        break;
    case S_STROPHA:
        str = "S_STROPHA";
        break;
    case S_STROPHA_AUCTA:
        str = "S_STROPHA_AUCTA";
        break;
    case S_DISTROPHA:
        str = "S_DISTROPHA";
        break;
    case S_DISTROPHA_AUCTA:
        str = "S_DISTROPHA_AUCTA";
        break;
    case S_TRISTROPHA:
        str = "S_TRISTROPHA";
        break;
    case S_TRISTROPHA_AUCTA:
        str = "S_TRISTROPHA_AUCTA";
        break;
    case S_QUADRATUM:
        str = "S_QUADRATUM";
        break;
    case S_PUNCTUM_CAVUM:
        str = "S_PUNCTUM_CAVUM";
        break;
    case S_LINEA_PUNCTUM:
        str = "S_LINEA_PUNCTUM";
        break;
    case S_LINEA_PUNCTUM_CAVUM:
        str = "S_LINEA_PUNCTUM_CAVUM";
        break;
    case S_LINEA:
        str = "S_LINEA";
        break;
    default:
        str = "unknown";
        break;
    }
    return str;
}

static const char *dump_signs(gregorio_sign signs)
{
    const char *str;
    switch (signs) {
    case _NO_SIGN:
        str = "_NO_SIGN";
        break;
    case _PUNCTUM_MORA:
        str = "_PUNCTUM_MORA";
        break;
    case _AUCTUM_DUPLEX:
        str = "_AUCTUM_DUPLEX";
        break;
    case _V_EPISEMUS:
        str = "_V_EPISEMUS";
        break;
    case _V_EPISEMUS_PUNCTUM_MORA:
        str = "_V_EPISEMUS_PUNCTUM_MORA";
        break;
    case _V_EPISEMUS_AUCTUM_DUPLEX:
        str = "_V_EPISEMUS_AUCTUM_DUPLEX";
        break;
    default:
        str = "unknown";
        break;
    }
    return str;
}

// a function dumping special signs
static const char *dump_special_sign(gregorio_sign special_sign)
{
    const char *str;
    switch (special_sign) {
    case _ACCENTUS:
        str = "_ACCENTUS";
        break;
    case _ACCENTUS_REVERSUS:
        str = "_ACCENTUS_REVERSUS";
        break;
    case _CIRCULUS:
        str = "_CIRCULUS";
        break;
    case _SEMI_CIRCULUS:
        str = "_SEMI_CIRCULUS";
        break;
    case _SEMI_CIRCULUS_REVERSUS:
        str = "_SEMI_CIRCULUS_REVERSUS";
        break;
    case _V_EPISEMUS:
        str = "_V_EPISEMUS";
        break;
    case _V_EPISEMUS_BAR_H_EPISEMUS:
        str = "_V_EPISEMUS_BAR_H_EPISEMUS";
        break;
    case _BAR_H_EPISEMUS:
        str = "_BAR_H_EPISEMUS";
        break;
    default:
        str = "unknown";
        break;
    }
    return str;
}

static const char *dump_h_episemus_size(grehepisemus_size size)
{
    const char *str;
    switch (size) {
    case H_NORMAL:
        str = "H_NORMAL";
        break;
    case H_SMALL_LEFT:
        str = "H_SMALL_LEFT";
        break;
    case H_SMALL_CENTRE:
        str = "H_SMALL_CENTRE";
        break;
    case H_SMALL_RIGHT:
        str = "H_SMALL_RIGHT";
        break;
    default:
        str = "unknown";
        break;
    }
    return str;
}

static const char *dump_bool(bool value) {
    return value? "true" : "false";
}

void dump_write_score(FILE *f, gregorio_score *score)
{
    gregorio_voice_info *voice_info = score->first_voice_info;
    int i;
    int annotation_num;

    if (!f) {
        gregorio_message(_
                         ("call with NULL file"),
                         "gregoriotex_write_score", ERROR, 0);
        return;
    }
    fprintf(f,
            "=====================================================================\n"
            " SCORE INFOS\n"
            "=====================================================================\n");
    if (score->number_of_voices) {
        fprintf(f, "   number_of_voices          %d\n",
                score->number_of_voices);
    }
    if (score->name) {
        fprintf(f, "   name                      %s\n", score->name);
    }
    if (score->gabc_copyright) {
        fprintf(f, "   gabc_copyright            %s\n", score->gabc_copyright);
    }
    if (score->score_copyright) {
        fprintf(f, "   score_copyright           %s\n", score->score_copyright);
    }
    if (score->office_part) {
        fprintf(f, "   office_part               %s\n", score->office_part);
    }
    if (score->occasion) {
        fprintf(f, "   occasion                  %s\n", score->occasion);
    }
    if (score->meter) {
        fprintf(f, "   meter                     %s\n", score->meter);
    }
    if (score->commentary) {
        fprintf(f, "   commentary                %s\n", score->commentary);
    }
    if (score->arranger) {
        fprintf(f, "   arranger                  %s\n", score->arranger);
    }
    if (score->si.author) {
        fprintf(f, "   author                    %s\n", score->si.author);
    }
    if (score->si.date) {
        fprintf(f, "   date                      %s\n", score->si.date);
    }
    if (score->si.manuscript) {
        fprintf(f, "   manuscript                %s\n", score->si.manuscript);
    }
    if (score->si.manuscript_reference) {
        fprintf(f, "   manuscript_reference      %s\n",
                score->si.manuscript_reference);
    }
    if (score->si.manuscript_storage_place) {
        fprintf(f, "   manuscript_storage_place  %s\n",
                score->si.manuscript_storage_place);
    }
    if (score->si.book) {
        fprintf(f, "   book                      %s\n", score->si.book);
    }
    if (score->si.transcriber) {
        fprintf(f, "   transcriber               %s\n", score->si.transcriber);
    }
    if (score->si.transcription_date) {
        fprintf(f, "   transcription_date        %s\n",
                score->si.transcription_date);
    }
    if (score->lilypond_preamble) {
        fprintf(f, "   lilypond_preamble         %s\n",
                score->lilypond_preamble);
    }
    if (score->opustex_preamble) {
        fprintf(f, "   opustex_preamble          %s\n",
                score->opustex_preamble);
    }
    if (score->musixtex_preamble) {
        fprintf(f, "   musixtex_preamble         %s\n",
                score->musixtex_preamble);
    }
    if (score->gregoriotex_font) {
        fprintf(f, "   gregoriotex_font          %s\n",
                score->gregoriotex_font);
    }
    if (score->mode) {
        fprintf(f, "   mode                      %d\n", score->mode);
    }
    if (score->initial_style) {
        fprintf(f, "   initial_style             %d\n", score->initial_style);
    }
    if (score->nabc_lines) {
        fprintf (f, "   nabc_lines                %d\n", (int)score->nabc_lines);
    }
    if (score->user_notes) {
        fprintf(f, "   user_notes                %s\n", score->user_notes);
    }
    fprintf(f, "\n\n"
            "=====================================================================\n"
            " VOICES INFOS\n"
            "=====================================================================\n");
    for (i = 0; i < score->number_of_voices; i++) {
        fprintf(f, "  Voice %d\n", i + 1);
        if (voice_info->initial_key) {
            fprintf(f, "   initial_key               %d (%s)\n",
                    voice_info->initial_key,
                    dump_key_to_char(voice_info->initial_key));
            if (voice_info->flatted_key) {
                fprintf(f, "   flatted_key               true\n");
            }
        }
        for (annotation_num = 0; annotation_num < NUM_ANNOTATIONS;
             ++annotation_num) {
            if (voice_info->annotation[annotation_num]) {
                fprintf(f, "   annotation                %s\n",
                        voice_info->annotation[annotation_num]);
            }
        }
        if (voice_info->style) {
            fprintf(f, "   style                     %s\n", voice_info->style);
        }
        if (voice_info->virgula_position) {
            fprintf(f, "   virgula_position          %s\n",
                    voice_info->virgula_position);
        }
        voice_info = voice_info->next_voice_info;
    }
    fprintf(f, "\n\n"
            "=====================================================================\n"
            " SCORE\n"
            "=====================================================================\n");
    for (gregorio_syllable *syllable = score->first_syllable; syllable;
            syllable = syllable->next_syllable) {
        if (syllable->type) {
            fprintf(f, "   type                      %d (%s)\n",
                    syllable->type, dump_type(syllable->type));
        }
        if (syllable->position) {
            fprintf(f, "   position                  %d (%s)\n",
                    syllable->position,
                    dump_syllable_position(syllable->position));
        }
        if (syllable->special_sign) {
            fprintf(f, "   special sign                       %s\n",
                    dump_special_sign(syllable->special_sign));
        }
        if (syllable->no_linebreak_area != NLBA_NORMAL) {
            fprintf(f, "   no line break area        %s\n",
                    dump_nlba_to_string(syllable->no_linebreak_area));
        }
        if (syllable->text) {
            if (syllable->translation) {
                fprintf(f, "\n  Text\n");
            }
            dump_write_characters(f, syllable->text);
        }
        if ((syllable->translation
             && syllable->translation_type != TR_WITH_CENTER_END)
            || syllable->translation_type == TR_WITH_CENTER_END) {
            fprintf(f, "\n  Translation type             %s",
                    dump_translation_type_to_string
                    (syllable->translation_type));
            if (syllable->translation_type == TR_WITH_CENTER_END) {
                fprintf(f, "\n");
            }
        }
        if (syllable->translation) {
            fprintf(f, "\n  Translation\n");
            dump_write_characters(f, syllable->translation);
        }
        if (syllable->abovelinestext) {
            fprintf(f, "\n  Abovelinestext\n    %s", syllable->abovelinestext);
        }
        for (gregorio_element *element = *syllable->elements; element;
                element = element->next) {
            fprintf(f, "---------------------------------------------------------------------\n");
            if (element->type) {
                fprintf(f, "     type                    %d (%s)\n",
                        element->type, dump_type(element->type));
            }
            switch (element->type) {
            case GRE_CUSTO:
                if (element->u.misc.pitched.pitch) {
                    fprintf(f, "     pitch                   %c     \n",
                            element->u.misc.pitched.pitch);
                }
                break;
            case GRE_SPACE:
                if (element->u.misc.unpitched.info.space) {
                    fprintf(f, "     space                   %d (%s)\n",
                            element->u.misc.unpitched.info.space,
                            dump_space_type(element->u.misc.unpitched.info.
                                space));
                }
                break;
            case GRE_TEXVERB_ELEMENT:
                fprintf(f, "     TeX string              \"%s\"\n",
                        element->texverb);
                break;
            case GRE_NLBA:
                fprintf(f, "     nlba                    %d (%s)\n",
                        element->u.misc.unpitched.info.nlba,
                        dump_nlba_to_string(element->u.misc.unpitched.info.
                            nlba));
                break;
            case GRE_ALT:
                fprintf(f, "     Above lines text        \"%s\"\n",
                        element->texverb);
                break;
            case GRE_BAR:
                if (element->u.misc.unpitched.info.bar) {
                    fprintf(f, "     bar                     %d (%s)\n",
                            element->u.misc.unpitched.info.bar,
                            dump_bar_type(element->u.misc.unpitched.info.bar));
                    if (element->u.misc.unpitched.special_sign) {
                        fprintf(f, "     special sign            %d (%s)\n",
                                element->u.misc.unpitched.special_sign,
                                dump_special_sign(element->u.misc.unpitched.
                                                  special_sign));
                    }
                }
                break;
            case GRE_C_KEY_CHANGE:
                if (element->u.misc.pitched.pitch) {
                    fprintf(f, "     clef                    %d (c%d)\n",
                            element->u.misc.pitched.pitch,
                            element->u.misc.pitched.pitch - '0');
                    if (element->u.misc.pitched.flatted_key) {
                        fprintf(f, "     flatted_key             true\n");
                    }
                }
                break;
            case GRE_F_KEY_CHANGE:
                if (element->u.misc.pitched.pitch) {
                    fprintf(f, "     clef                    %d (f%d)\n",
                            element->u.misc.pitched.pitch,
                            element->u.misc.pitched.pitch - '0');
                    if (element->u.misc.pitched.flatted_key) {
                        fprintf(f, "     flatted_key             true\n");
                    }
                }
                break;
            case GRE_END_OF_LINE:
                if (element->u.misc.unpitched.info.sub_type) {
                    fprintf(f, "     sub_type                %d (%s)\n",
                            element->u.misc.unpitched.info.sub_type,
                            dump_type(element->u.misc.unpitched.info.sub_type));
                }
                break;
            case GRE_ELEMENT:
                for (gregorio_glyph *glyph = element->u.first_glyph;
                        glyph; glyph = glyph->next) {
                    fprintf(f, "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -\n");
                    if (glyph->type) {
                        fprintf(f, "       type                  %d (%s)\n",
                                glyph->type, dump_type(glyph->type));
                    }
                    switch (glyph->type) {
                    case GRE_TEXVERB_GLYPH:
                        fprintf(f, "       TeX string            \"%s\"\n",
                                glyph->texverb);
                        break;

                    case GRE_SPACE:
                        fprintf(f, "       space                 %d (%s)\n",
                                glyph->u.misc.unpitched.info.space,
                                dump_space_type(glyph->u.misc.unpitched.info.
                                                space));
                        break;

                    case GRE_BAR:
                        fprintf(f, "       glyph_type            %d (%s)\n",
                                glyph->u.misc.unpitched.info.bar,
                                dump_bar_type(glyph->u.misc.unpitched.info.
                                              bar));
                        if (glyph->u.misc.unpitched.special_sign) {
                            fprintf(f, "       special sign          %d (%s)\n",
                                    glyph->u.misc.unpitched.special_sign,
                                    dump_special_sign(glyph->u.misc.unpitched.
                                                      special_sign));
                        }
                        break;

                    case GRE_FLAT:
                    case GRE_NATURAL:
                    case GRE_SHARP:
                    case GRE_MANUAL_CUSTOS:
                        fprintf(f, "       pitch                 %c\n",
                                glyph->u.misc.pitched.pitch);
                        break;

                    case GRE_GLYPH:
                        fprintf(f, "       glyph_type            %d (%s)\n",
                                glyph->u.notes.glyph_type,
                                dump_glyph_type(glyph->u.notes.glyph_type));
                        if (glyph->u.notes.liquescentia) {
                            fprintf(f, "       liquescentia          %d (%s)\n",
                                    glyph->u.notes.liquescentia,
                                    dump_liquescentia(glyph->u.notes.
                                                      liquescentia));
                        }
                        break;

                    default:
                        fprintf(f, "       !!! UNKNOWN !!!       !!!\n");
                        break;
                    }
                    if (glyph->type == GRE_GLYPH) {
                        for (gregorio_note *note = glyph->u.notes.first_note;
                                note; note = note->next) {
                            fprintf(f, "-  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  \n");
                            if (note->type) {
                                fprintf(f, "         type                   %d (%s)\n",
                                        note->type, dump_type(note->type));
                            }
                            switch (note->type) {
                            case GRE_NOTE:
                                if (note->u.note.pitch) {
                                    fprintf(f, "         pitch                  %c\n",
                                            note->u.note.pitch);
                                }
                                if (note->u.note.shape) {
                                    fprintf(f, "         shape                  %d (%s)\n",
                                            note->u.note.shape,
                                            dump_shape(note->u.note.shape));
                                }
                                if (note->u.note.liquescentia) {
                                    fprintf(f, "         liquescentia           %d (%s)\n",
                                            note->u.note.liquescentia,
                                            dump_liquescentia(note->u.note.
                                                              liquescentia));
                                }
                                break;

                            default:
                                fprintf(f, "         !!! NOT ALLOWED !!!    !!!\n");
                                break;
                            }
                            if (note->texverb) {
                                fprintf(f, "         TeX string             \"%s\"\n",
                                        note->texverb);
                            }
                            if (note->choral_sign) {
                                fprintf(f, "         Choral Sign            \"%s\"\n",
                                        note->choral_sign);
                            }
                            if (note->signs) {
                                fprintf(f, "         signs                  %d (%s)\n",
                                        note->signs, dump_signs(note->signs));
                            }
                            if (note->signs & _V_EPISEMUS && note->v_episemus_height) {
                                if (note->v_episemus_height < note->u.note.pitch) {
                                    fprintf(f, "         v episemus forced      BELOW\n");
                                }
                                else {
                                    fprintf(f, "         v episemus forced      ABOVE\n");
                                }
                            }
                            if (note->special_sign) {
                                fprintf(f, "         special sign           %d (%s)\n",
                                        note->special_sign,
                                        dump_special_sign(note->special_sign));
                            }
                            if (note->h_episemus_above == HEPISEMUS_AUTO
                                    && note->h_episemus_below == HEPISEMUS_AUTO) {
                                fprintf(f, "         auto hepisemus size    %d (%s)\n",
                                        note->h_episemus_above_size,
                                        dump_h_episemus_size(note->h_episemus_above_size));
                                fprintf(f, "         auto hepisemus bridge  %s\n",
                                        dump_bool(note->h_episemus_above_connect));
                            }
                            else {
                                if (note->h_episemus_above == HEPISEMUS_FORCED) {
                                    fprintf(f, "         above hepisemus size   %d (%s)\n",
                                            note->h_episemus_above_size,
                                            dump_h_episemus_size(note->h_episemus_above_size));
                                    fprintf(f, "         above hepisemus bridge %s\n",
                                            dump_bool(note->h_episemus_above_connect));
                                }
                                if (note->h_episemus_below == HEPISEMUS_FORCED) {
                                    fprintf(f, "         below hepisemus size   %d (%s)\n",
                                            note->h_episemus_below_size,
                                            dump_h_episemus_size(note->h_episemus_below_size));
                                    fprintf(f, "         below hepisemus bridge %s\n",
                                            dump_bool(note->h_episemus_below_connect));
                                }
                            }
                        }
                    }
                }
                break;
            default:
                break;
            }
            if (element->nabc_lines) {
                fprintf(f, "     nabc_lines              %d\n",
                        (int)element->nabc_lines);
            }
            if (element->nabc_lines && element->nabc) {
                for (i = 0; i < (int)element->nabc_lines; i++) {
                    if (element->nabc[i]) {
                        fprintf(f, "     nabc_line %d             \"%s\"\n",
                                (int)(i+1), element->nabc[i]);
                    }
                }
            }
        }
        fprintf(f, "=====================================================================\n");
    }
}
