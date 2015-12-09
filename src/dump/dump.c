/*
 * Gregorio is a program that translates gabc files to GregorioTeX.
 * This file provides functions to dump out Gregorio structures.
 *
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
#include "bool.h"
#include "struct.h"
#include "unicode.h"
#include "messages.h"
#include "plugins.h"
#include "support.h"

static const char *dump_style_to_string(grestyle_style style)
{
    static char buf[50];

    gregorio_snprintf(buf, sizeof buf, "%16s", grestyle_style_to_string(style));
    return buf;
}

void dump_write_characters(FILE *const f,
        const gregorio_character * current_character)
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

static const char *dump_key_to_char(const int key)
{
    switch (key) {
    case -2:
        return "f1";
    case 0:
        return "f2";
    case 2:
        return "f3";
    case 4:
        return "f4";
    case 1:
        return "c1";
    case 3:
        return "c2";
    case 5:
        return "c3";
    case 7:
        return "c4";
    }
    return "no key defined";
}

static const char *dump_bool(bool value) {
    return value? "true" : "false";
}

static const char *dump_pitch(const char height) {
    static char buf[20];
    if (height >= LOWEST_PITCH && height <= HIGHEST_PITCH) {
        gregorio_snprintf(buf, 20, "%c", height + 'a' - LOWEST_PITCH);
    } else {
        gregorio_snprintf(buf, 20, "?%d", height);
    }
    return buf;
}

void dump_write_score(FILE *f, gregorio_score *score)
{
    gregorio_voice_info *voice_info = score->first_voice_info;
    int i;
    int annotation_num;
    gregorio_syllable *syllable;

    if (!f) {
        gregorio_message(_("call with NULL file"), "gregoriotex_write_score",
                VERBOSITY_ERROR, 0);
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
    if (score->language) {
        fprintf(f, "   language                  %s\n", score->language);
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
    if (score->mode) {
        fprintf(f, "   mode                      %d\n", score->mode);
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
        for (annotation_num = 0; annotation_num < MAX_ANNOTATIONS;
             ++annotation_num) {
            if (score->annotation[annotation_num]) {
                fprintf(f, "   annotation                %s\n",
                        score->annotation[annotation_num]);
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
    for (syllable = score->first_syllable; syllable;
            syllable = syllable->next_syllable) {
        gregorio_element *element;
        if (syllable->type) {
            fprintf(f, "   type                      %d (%s)\n",
                    syllable->type, gregorio_type_to_string(syllable->type));
        }
        if (syllable->position) {
            fprintf(f, "   position                  %d (%s)\n",
                    syllable->position,
                    gregorio_word_position_to_string(syllable->position));
        }
        if (syllable->special_sign) {
            fprintf(f, "   special sign                       %s\n",
                    gregorio_sign_to_string(syllable->special_sign));
        }
        if (syllable->no_linebreak_area != NLBA_NORMAL) {
            fprintf(f, "   no line break area        %s\n",
                    gregorio_nlba_to_string(syllable->no_linebreak_area));
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
                    gregorio_tr_centering_to_string
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
        for (element = *syllable->elements; element; element = element->next) {
            gregorio_glyph *glyph;
            fprintf(f, "---------------------------------------------------------------------\n");
            if (element->type) {
                fprintf(f, "     type                    %d (%s)\n",
                        element->type, gregorio_type_to_string(element->type));
            }
            switch (element->type) {
            case GRE_CUSTOS:
                if (element->u.misc.pitched.pitch) {
                    fprintf(f, "     pitch                   %s\n",
                            dump_pitch(element->u.misc.pitched.pitch));
                }
                if (element->u.misc.pitched.force_pitch) {
                    fprintf(f, "     force_pitch             true\n");
                }
                break;
            case GRE_SPACE:
                if (element->u.misc.unpitched.info.space) {
                    fprintf(f, "     space                   %d (%s)\n",
                            element->u.misc.unpitched.info.space,
                            gregorio_space_to_string(element->u.misc.unpitched.
                                                     info.space));
                }
                break;
            case GRE_TEXVERB_ELEMENT:
                fprintf(f, "     TeX string              \"%s\"\n",
                        element->texverb);
                break;
            case GRE_NLBA:
                fprintf(f, "     nlba                    %d (%s)\n",
                        element->u.misc.unpitched.info.nlba,
                        gregorio_nlba_to_string(element->u.misc.unpitched.info.
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
                            gregorio_bar_to_string(element->u.misc.unpitched.
                                                   info.bar));
                    if (element->u.misc.unpitched.special_sign) {
                        fprintf(f, "     special sign            %d (%s)\n",
                                element->u.misc.unpitched.special_sign,
                                gregorio_sign_to_string(element->
                                        u.misc.unpitched.special_sign));
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
                            gregorio_type_to_string(element->u.misc.unpitched.
                                                    info.sub_type));
                }
                break;
            case GRE_ELEMENT:
                for (glyph = element->u.first_glyph; glyph;
                        glyph = glyph->next) {
                    gregorio_note *note;
                    fprintf(f, "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -\n");
                    if (glyph->type) {
                        fprintf(f, "       type                  %d (%s)\n",
                                glyph->type, gregorio_type_to_string(glyph->
                                                                     type));
                    }
                    switch (glyph->type) {
                    case GRE_TEXVERB_GLYPH:
                        fprintf(f, "       TeX string            \"%s\"\n",
                                glyph->texverb);
                        break;

                    case GRE_SPACE:
                        fprintf(f, "       space                 %d (%s)\n",
                                glyph->u.misc.unpitched.info.space,
                                gregorio_space_to_string(glyph->u.misc.
                                                         unpitched.info.space));
                        break;

                    case GRE_BAR:
                        fprintf(f, "       glyph_type            %d (%s)\n",
                                glyph->u.misc.unpitched.info.bar,
                                gregorio_bar_to_string(glyph->u.misc.unpitched.
                                                       info.bar));
                        if (glyph->u.misc.unpitched.special_sign) {
                            fprintf(f, "       special sign          %d (%s)\n",
                                    glyph->u.misc.unpitched.special_sign,
                                    gregorio_sign_to_string(glyph->
                                            u.misc.unpitched.special_sign));
                        }
                        break;

                    case GRE_FLAT:
                    case GRE_NATURAL:
                    case GRE_SHARP:
                        fprintf(f, "       pitch                 %s\n",
                                dump_pitch(glyph->u.misc.pitched.pitch));
                        break;

                    case GRE_GLYPH:
                        fprintf(f, "       glyph_type            %d (%s)\n",
                                glyph->u.notes.glyph_type,
                                gregorio_glyph_type_to_string(glyph->u.notes.
                                                              glyph_type));
                        if (glyph->u.notes.liquescentia) {
                            fprintf(f, "       liquescentia          %d (%s)\n",
                                    glyph->u.notes.liquescentia,
                                    gregorio_liquescentia_to_string(
                                            glyph->u.notes.liquescentia));
                        }
                        break;

                    default:
                        fprintf(f, "       !!! UNKNOWN !!!       !!!\n");
                        break;
                    }
                    if (glyph->type == GRE_GLYPH) {
                        for (note = glyph->u.notes.first_note; note;
                                note = note->next) {
                            fprintf(f, "-  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  \n");
                            if (note->type) {
                                fprintf(f, "         type                   %d (%s)\n",
                                        note->type,
                                        gregorio_type_to_string(note->type));
                            }
                            switch (note->type) {
                            case GRE_NOTE:
                                if (note->u.note.pitch) {
                                    fprintf(f, "         pitch                  %s\n",
                                            dump_pitch(note->u.note.pitch));
                                }
                                if (note->u.note.shape) {
                                    fprintf(f, "         shape                  %d (%s)\n",
                                            note->u.note.shape,
                                            gregorio_shape_to_string(
                                                    note->u.note.shape));
                                }
                                if (note->u.note.liquescentia) {
                                    fprintf(f, "         liquescentia           %d (%s)\n",
                                            note->u.note.liquescentia,
                                            gregorio_liquescentia_to_string(
                                                    note->u.note.liquescentia));
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
                                        note->signs,
                                        gregorio_sign_to_string(note->signs));
                            }
                            if (note->signs & _V_EPISEMA && note->v_episema_height) {
                                if (note->v_episema_height < note->u.note.pitch) {
                                    fprintf(f, "         v episema forced       BELOW\n");
                                }
                                else {
                                    fprintf(f, "         v episema forced       ABOVE\n");
                                }
                            }
                            if ((note->signs == _PUNCTUM_MORA
                                        || note->signs == _V_EPISEMA_PUNCTUM_MORA)
                                    && note->mora_vposition) {
                                fprintf(f, "         mora vposition         %s\n",
                                        gregorio_vposition_to_string(note->
                                                mora_vposition));
                            }
                            if (note->special_sign) {
                                fprintf(f, "         special sign           %d (%s)\n",
                                        note->special_sign,
                                        gregorio_sign_to_string(
                                                note->special_sign));
                            }
                            if (note->h_episema_above == HEPISEMA_AUTO
                                    && note->h_episema_below == HEPISEMA_AUTO) {
                                fprintf(f, "         auto hepisema size     %d (%s)\n",
                                        note->h_episema_above_size,
                                        grehepisema_size_to_string(note->
                                                h_episema_above_size));
                                fprintf(f, "         auto hepisema bridge   %s\n",
                                        dump_bool(note->h_episema_above_connect));
                            }
                            else {
                                if (note->h_episema_above == HEPISEMA_FORCED) {
                                    fprintf(f, "         above hepisema size    %d (%s)\n",
                                            note->h_episema_above_size,
                                            grehepisema_size_to_string(note->
                                                    h_episema_above_size));
                                    fprintf(f, "         above hepisema bridge  %s\n",
                                            dump_bool(note->h_episema_above_connect));
                                }
                                if (note->h_episema_below == HEPISEMA_FORCED) {
                                    fprintf(f, "         below hepisema size    %d (%s)\n",
                                            note->h_episema_below_size,
                                            grehepisema_size_to_string(note->
                                                    h_episema_below_size));
                                    fprintf(f, "         below hepisema bridge  %s\n",
                                            dump_bool(note->h_episema_below_connect));
                                }
                            }
                        }
                    }
                }
                break;

            default:
                /* do nothing */
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
