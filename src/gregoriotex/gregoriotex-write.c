/*
 * Copyright (C) 2008-2015 The Gregorio Project (see CONTRIBUTORS.md)
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
 * this program.  If not, see <http://www.gnu.org/licenses/>. */

/**
 * @file
 * @brief The plugin which writes a GregorioTeX score.
 */

#include "config.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <assert.h>
#include "struct.h"
#include "unicode.h"
#include "messages.h"
#include "characters.h"

#include "gregoriotex.h"

#define BUFSIZE 128

enum syllable { THIS_SYL, NEXT_SYL };

#define MAX_AMBITUS 5
static char *tex_ambitus[] = {
    NULL, "One", "Two", "Three", "Four", "Five"
};

// / the value indicating to GregorioTeX that there is no flat
#define NO_KEY_FLAT 'a'

// a helper macro for the following function
#define whileglyph(prevornext) \
        while(glyph)\
          {\
            if (glyph->type == GRE_GLYPH)\
              {\
                note = glyph->u.notes.first_note;\
                while (note)\
                  {\
                    if (note->u.note.pitch < 'c')\
                      {\
                        return 1;\
                      }\
                    note = note->next;\
                  }\
              }\
            glyph = glyph->prevornext;\
          }

// a function that determines if we must use a long queue or not (less easy
// that it might seem)

static unsigned char gregoriotex_is_long(char pitch,
        const gregorio_glyph *const current_glyph,
        const gregorio_element *const current_element)
{
    gregorio_note *note;
    gregorio_glyph *glyph = current_glyph->next;
    gregorio_element *element = current_element->next;
    switch (pitch) {
    case 'b':
    case 'f':
    case 'h':
    case 'j':
    case 'l':
        return 1;
    case 'd':
        // we first look forward to see if there is a note underneath c
        whileglyph(next);
        if (element && element->type == GRE_SPACE
                && (element->u.misc.unpitched.info.space == SP_NEUMATIC_CUT
                        || element->u.misc.unpitched.info.space ==
                        SP_LARGER_SPACE
                        || element->u.misc.unpitched.info.space ==
                        SP_NEUMATIC_CUT_NB
                        || element->u.misc.unpitched.info.space ==
                        SP_LARGER_SPACE_NB)) {
            element = element->next;
        }
        if (element && element->type == GRE_ELEMENT) {
            glyph = element->u.first_glyph;
            whileglyph(next);
        }
        // and now something completely different
        glyph = current_glyph->previous;
        element = current_element->previous;
        whileglyph(previous);
        if (element && element->type == GRE_SPACE
                && (element->u.misc.unpitched.info.space == SP_NEUMATIC_CUT
                        || element->u.misc.unpitched.info.space ==
                        SP_LARGER_SPACE
                        || element->u.misc.unpitched.info.space ==
                        SP_NEUMATIC_CUT_NB
                        || element->u.misc.unpitched.info.space ==
                        SP_LARGER_SPACE_NB)) {
            element = element->previous;
        }
        if (element && element->type == GRE_ELEMENT) {
            glyph = element->u.first_glyph;
            whileglyph(next);
        }
        return 0;
    default:
        return 0;
    }
}

// inline functions that we will use to determine if we need a short bar or not

// we define d to be short instead of long... may induce errors, but fixes
// some too
static inline bool is_short(const char pitch, const gregorio_glyph *const glyph,
        const gregorio_element *const element)
{
    return gregoriotex_is_long(pitch, glyph, element) == 0;
}

static gregoriotex_status *status = NULL;
static grestyle_style gregoriotex_ignore_style = ST_NO_STYLE;

static char *gregoriotex_determine_note_glyph_name(gregorio_note *note,
        gregorio_glyph *glyph, gregorio_element *element, gtex_alignment * type)
{
    if (!note) {
        gregorio_message(_
                ("called with NULL pointer"),
                "gregoriotex_determine_note_glyph_name", ERROR, 0);
        return "";
    }

    *type = AT_ONE_NOTE;
    switch (note->u.note.shape) {
    case S_PUNCTUM_INCLINATUM:
        *type = AT_PUNCTUM_INCLINATUM;
        return "PunctumInclinatum";
    case S_PUNCTUM_INCLINATUM_DEMINUTUS:
        return "PunctumInclinatumDeminutus";
    case S_PUNCTUM_INCLINATUM_AUCTUS:
        return "PunctumInclinatumAuctus";
    case S_PUNCTUM:
        return "Punctum";
    case S_PUNCTUM_AUCTUS_ASCENDENS:
        return "PunctumAscendens";
    case S_PUNCTUM_AUCTUS_DESCENDENS:
        return "PunctumDescendens";
    case S_PUNCTUM_DEMINUTUS:
        return "PunctumDeminutus";
    case S_PUNCTUM_CAVUM:
        return "PunctumCavum";
    case S_LINEA:
        return "Linea";
    case S_LINEA_PUNCTUM:
        return "LineaPunctum";
    case S_LINEA_PUNCTUM_CAVUM:
        return "LineaPunctumCavum";
    case S_VIRGA:
        if (is_short(note->u.note.pitch, glyph, element)) {
            return "Virga";
        } else {
            return "VirgaLongqueue";
        }
    case S_VIRGA_REVERSA:
        if (note->u.note.liquescentia == L_AUCTUS_DESCENDENS) {
            if (is_short(note->u.note.pitch, glyph, element)) {
                return "VirgaReversaDescendens";
            } else {
                return "VirgaReversaLongqueueDescendens";
            }
        } else {
            if (is_short(note->u.note.pitch, glyph, element)) {
                return "VirgaReversa";
            } else {
                return "VirgaReversaLongqueue";
            }
        }
    case S_ORISCUS:
        *type = AT_ORISCUS;
        return "Oriscus";
    case S_ORISCUS_AUCTUS:
        *type = AT_ORISCUS;
        return "OriscusReversus";
    case S_ORISCUS_DEMINUTUS:
        *type = AT_ORISCUS;
        return "OriscusDeminutus";
    case S_QUILISMA:
        *type = AT_QUILISMA;
        return "Quilisma";
    case S_ORISCUS_SCAPUS:
        if (is_short(note->u.note.pitch, glyph, element)) {
            return "OriscusScapus";
        } else {
            return "OriscusScapusLongqueue";
        }
    case S_STROPHA:
        *type = AT_STROPHA;
        if (glyph->u.notes.liquescentia == L_AUCTA) {
            return "StrophaAucta";
        } else {
            return "Stropha";
        }
    case S_STROPHA_AUCTA:
        *type = AT_STROPHA;
        return "StrophaAucta";
    default:
        gregorio_messagef("gregoriotex_determine_note_glyph_name", ERROR,
                0, _("called with unknown shape: %d"), note->u.note.shape);
        return "";
    }
}

/*
 * The different liquescentiae are:
 * 'Nothing'
 * 'InitioDebilis'
 * 'Deminutus
 * 'Ascendens'
 * 'Descendens'
 * 'InitioDebilisDeminutus'
 * 'InitioDebilisAscendens'
 * 'InitioDebilisDescendens'
 * 
 * If it is an auctus, which may be ascendens or descendens, by default we
 * consider it as an ascendens
 * 
 * They also are and must be the same as in squarize.py.
 */

static char *gregoriotex_determine_liquescentia(gtex_glyph_liquescentia type,
        gregorio_liquescentia liquescentia)
{
    switch (liquescentia) {
    case L_AUCTA:
        liquescentia = L_AUCTUS_ASCENDENS;
        break;
    case L_AUCTA_INITIO_DEBILIS:
        liquescentia = L_AUCTUS_ASCENDENS_INITIO_DEBILIS;
        break;
    }

    switch (type) {
    case LG_ALL:
        break;
    case LG_NO_INITIO:
        if (liquescentia >= L_INITIO_DEBILIS) {
            liquescentia = liquescentia - L_INITIO_DEBILIS;
        }
        break;
    case LG_ONLY_DEMINUTUS:
        if (liquescentia != L_DEMINUTUS
                && liquescentia != L_DEMINUTUS_INITIO_DEBILIS) {
            liquescentia = L_NO_LIQUESCENTIA;
        }
        break;
    case LG_ONLY_AUCTUS:
        if (liquescentia != L_AUCTUS_ASCENDENS
                && liquescentia != L_AUCTUS_DESCENDENS) {
            liquescentia = L_NO_LIQUESCENTIA;
        }
    case LG_UNDET_AUCTUS:
        if (liquescentia == L_AUCTUS_DESCENDENS) {
            liquescentia = L_AUCTUS_ASCENDENS;
        }
        if (liquescentia == L_AUCTUS_DESCENDENS_INITIO_DEBILIS) {
            liquescentia = L_AUCTUS_ASCENDENS_INITIO_DEBILIS;
        }
        break;
    default:
        liquescentia = L_NO_LIQUESCENTIA;
        break;
    }

    // now we convert liquescentia into the good GregorioTeX liquescentia
    // numbers

    switch (liquescentia) {
    case L_DEMINUTUS:
        return "Deminutus";
    case L_AUCTUS_ASCENDENS:
        return "Ascendens";
    case L_AUCTA:
    case L_AUCTUS_DESCENDENS:
        return "Descendens";
    case L_INITIO_DEBILIS:
        return "InitioDebilis";
    case L_DEMINUTUS_INITIO_DEBILIS:
        return "InitioDebilisDeminutus";
    case L_AUCTUS_ASCENDENS_INITIO_DEBILIS:
        return "InitioDebilisAscendens";
    case L_AUCTA_INITIO_DEBILIS:
    case L_AUCTUS_DESCENDENS_INITIO_DEBILIS:
        return "InitioDebilisDescendens";
    }

    return "Nothing";
}

static inline int compute_ambitus(const gregorio_note *const current_note)
{
    int first = current_note->u.note.pitch;
    int second = current_note->next->u.note.pitch;
    int ambitus;
    if (first < second) {
        ambitus = second - first;
    } else {
        ambitus = first - second;
    }
    if (ambitus < 1 || ambitus > MAX_AMBITUS) {
        gregorio_messagef("compute_ambitus", ERROR, 0,
                _("unsupported ambitus: %d"), ambitus);
        return 0;
    }
    return ambitus;
}

static char *compute_glyph_name(const gregorio_glyph *const glyph,
        char *const shape, const gtex_glyph_liquescentia ltype)
{
    static char buf[BUFSIZE];

    char *liquescentia = gregoriotex_determine_liquescentia(ltype,
            glyph->u.notes.liquescentia);
    gregorio_note *current_note;
    // then we start making our formula
    char first;
    char second;
    int ambitus1, ambitus2, ambitus3;
    if (!glyph) {
        gregorio_message(_("called with NULL pointer"),
                "compute_glyph_name", ERROR, 0);
        return "";
    }
    if (!glyph->u.notes.first_note) {
        gregorio_message(_("called with a glyph that have no note"),
                "compute_glyph_name", ERROR, 0);
        return "";
    }
    current_note = glyph->u.notes.first_note;
    if (!current_note->next) {
        gregorio_message(_("called with a multi-note glyph that has only "
                        "one note"), "compute_glyph_name", ERROR,
                0);
        return "";
    }
    if (!(ambitus1 = compute_ambitus(current_note))) {
        return "";
    }
    current_note = current_note->next;
    if (!current_note->next) {
        snprintf(buf, BUFSIZE, "%s%s%s", shape, tex_ambitus[ambitus1],
                liquescentia);
        return buf;
    }
    if (!(ambitus2 = compute_ambitus(current_note))) {
        return "";
    }
    current_note = current_note->next;
    if (!current_note->next) {
        snprintf(buf, BUFSIZE, "%s%s%s%s", shape, tex_ambitus[ambitus1],
                tex_ambitus[ambitus2], liquescentia);
        return buf;
    }
    if (!(ambitus3 = compute_ambitus(current_note))) {
        return "";
    }
    snprintf(buf, BUFSIZE, "%s%s%s%s%s", shape, tex_ambitus[ambitus1],
            tex_ambitus[ambitus2], tex_ambitus[ambitus3], liquescentia);
    return buf;
}

// the function that calculates the number of the glyph. It also
// calculates the type, used for determining the position of signs. Type is
// very basic, it is only the global dimensions : torculus, one_note, etc.

char *gregoriotex_determine_glyph_name(const gregorio_glyph *const glyph,
        const gregorio_element *const element, gtex_alignment *const  type,
        gtex_type *const gtype)
{
    char *shape = NULL;
    gtex_glyph_liquescentia ltype;
    char pitch = 0;
    if (!glyph) {
        gregorio_message(_("called with NULL pointer"),
                "gregoriotex_determine_glyph_name", ERROR, 0);
        return "";
    }
    if (!glyph->u.notes.first_note) {
        gregorio_message(_("called with a glyph that has no note"),
                "gregorio_tex_determine_glyph_name", ERROR, 0);
        return "";
    }
    *gtype = T_ONE_NOTE;
    switch (glyph->u.notes.glyph_type) {
    case G_PODATUS:
        pitch = glyph->u.notes.first_note->next->u.note.pitch;
        switch (glyph->u.notes.first_note->u.note.shape) {
        case S_QUILISMA:
            *type = AT_QUILISMA;
            // the next if is because we made the choice that AUCTUS shapes
            // look like pes quadratum.
            if (glyph->u.notes.liquescentia == L_AUCTUS_ASCENDENS
                    || glyph->u.notes.liquescentia == L_AUCTUS_DESCENDENS
                    || glyph->u.notes.liquescentia ==
                    L_AUCTUS_DESCENDENS_INITIO_DEBILIS
                    || glyph->u.notes.liquescentia ==
                    L_AUCTUS_ASCENDENS_INITIO_DEBILIS) {
                *gtype = T_PESQUILISMAQUADRATUM;
                shape = "PesQuilismaQuadratum";
            } else {
                *gtype = T_PESQUILISMA;
                shape = "PesQuilisma";
            }
            ltype = LG_NO_INITIO;
            break;
        case S_ORISCUS:
        case S_ORISCUS_SCAPUS:
            *type = AT_ORISCUS;
            // TODO: we could factorize this code
            if (glyph->u.notes.liquescentia == L_NO_LIQUESCENTIA
                    && gregoriotex_is_long(pitch, glyph, element) == 1) {
                *gtype = T_PESQUASSUS_LONGQUEUE;
                shape = "PesQuassusLongqueue";
            } else {
                *gtype = T_PESQUASSUS;
                shape = "PesQuassus";
            }
            ltype = LG_NO_INITIO;
            break;
        default:
            *type = AT_ONE_NOTE;
            if (glyph->u.notes.liquescentia == L_AUCTUS_ASCENDENS
                    || glyph->u.notes.liquescentia == L_AUCTUS_DESCENDENS
                    || glyph->u.notes.liquescentia ==
                    L_AUCTUS_DESCENDENS_INITIO_DEBILIS
                    || glyph->u.notes.liquescentia ==
                    L_AUCTUS_ASCENDENS_INITIO_DEBILIS) {
                *gtype = T_PESQUADRATUM;
                shape = "PesQuadratum";
            } else {
                *gtype = T_PES;
                shape = "Pes";
            }
            ltype = LG_ALL;
            break;
        }
        break;
    case G_PES_QUADRATUM:
        pitch = glyph->u.notes.first_note->next->u.note.pitch;
        switch (glyph->u.notes.first_note->u.note.shape) {
        case S_QUILISMA:
            *type = AT_QUILISMA;
            if (glyph->u.notes.liquescentia == L_NO_LIQUESCENTIA
                    && gregoriotex_is_long(pitch, glyph, element) == 1) {
                *gtype = T_PESQUILISMAQUADRATUM_LONGQUEUE;
                shape = "PesQuilismaQuadratumLongqueue";
            } else {
                *gtype = T_PESQUILISMAQUADRATUM;
                shape = "PesQuilismaQuadratum";
            }
            ltype = LG_NO_INITIO;
            break;
        case S_ORISCUS:
            *type = AT_ORISCUS;
            if (glyph->u.notes.liquescentia == L_NO_LIQUESCENTIA
                    && gregoriotex_is_long(pitch, glyph, element) == 1) {
                *gtype = T_PESQUASSUS_LONGQUEUE;
                shape = "PesQuadratumLongqueue";
            } else {
                *gtype = T_PESQUASSUS;
                shape = "PesQuassus";
            }
            ltype = LG_NO_INITIO;
            break;
        default:
            *type = AT_ONE_NOTE;
            if (glyph->u.notes.liquescentia == L_NO_LIQUESCENTIA
                    && gregoriotex_is_long(pitch, glyph, element) == 1) {
                *gtype = T_PESQUADRATUM_LONGQUEUE;
                shape = "PesQuadratumLongqueue";
            } else {
                *gtype = T_PESQUADRATUM;
                shape = "PesQuadratum";
            }
            ltype = LG_ALL;
            break;
        }
        break;
    case G_VIRGA_STRATA:
        pitch = glyph->u.notes.first_note->next->u.note.pitch;
        *type = AT_ONE_NOTE;
        *gtype = T_VIRGA_STRATA;
        shape = "VirgaStrata";
        ltype = LG_ALL;
        break;
    case G_FLEXA:
        pitch = glyph->u.notes.first_note->u.note.pitch;
        if (glyph->u.notes.liquescentia == L_DEMINUTUS) {
            *type = AT_FLEXUS_DEMINUTUS;
        } else {
            if (pitch - glyph->u.notes.first_note->next->u.note.pitch == 1) {
                *type = AT_FLEXUS_1;
            } else {
                *type = AT_FLEXUS;
            }
        }
        if (glyph->u.notes.first_note->u.note.shape == S_ORISCUS) {
            *gtype = T_FLEXUS_ORISCUS;
            shape = "FlexusOriscus";
            ltype = LG_NO_INITIO;
        } else if (glyph->u.notes.first_note->u.note.shape == S_ORISCUS_SCAPUS) {
            if (is_short(pitch, glyph, element)) {
                *gtype = T_FLEXUS_ORISCUS_SCAPUS;
                shape = "FlexusOriscusScapus";
            } else {
                *gtype = T_FLEXUS_ORISCUS_SCAPUS_LONGQUEUE;
                shape = "FlexusOriscusScapusLongqueue";
            }
            ltype = LG_NO_INITIO;
        } else {
            if (is_short(pitch, glyph, element)) {
                *gtype = T_FLEXUS;
                shape = "Flexus";
            } else {
                *gtype = T_FLEXUS_LONGQUEUE;
                shape = "FlexusLongqueue";
            }
            ltype = LG_NO_INITIO;
        }
        break;
    case G_TORCULUS:
        *gtype = T_TORCULUS;
        if (glyph->u.notes.first_note->u.note.shape == S_QUILISMA) {
            *type = AT_QUILISMA;
            shape = "TorculusQuilisma";
            ltype = LG_NO_INITIO;
        } else {
            *type = AT_ONE_NOTE;
            shape = "Torculus";
            ltype = LG_ALL;
        }
        break;
    case G_TORCULUS_LIQUESCENS:
        *gtype = T_TORCULUS_LIQUESCENS;
        if (glyph->u.notes.first_note->u.note.shape == S_QUILISMA) {
            *type = AT_QUILISMA;
            shape = "TorculusLiquescensQuilisma";
        } else {
            *type = AT_ONE_NOTE;
            shape = "TorculusLiquescens";
        }
        ltype = LG_ONLY_DEMINUTUS;
        break;
    case G_TORCULUS_RESUPINUS_FLEXUS:
        *type = AT_ONE_NOTE;
        *gtype = T_TORCULUS_RESUPINUS_FLEXUS;
        break;
    case G_PORRECTUS:
        *type = AT_PORRECTUS;
        *gtype = T_PORRECTUS;
        shape = "Porrectus";
        ltype = LG_NO_INITIO;
        break;
    case G_TORCULUS_RESUPINUS:
        *gtype = T_TORCULUS_RESUPINUS;
        if (glyph->u.notes.first_note->u.note.shape == S_QUILISMA) {
            *type = AT_QUILISMA;
            shape = "TorculusResupinusQuilisma";
        } else {
            *type = AT_ONE_NOTE;
            shape = "TorculusResupinus";
        }
        ltype = LG_ALL;
        break;
    case G_PORRECTUS_FLEXUS:
        *type = AT_PORRECTUS;
        *gtype = T_PORRECTUS_FLEXUS;
        shape = "PorrectusFlexus";
        ltype = LG_NO_INITIO;
        break;
    case G_PORRECTUS_NO_BAR:
        *type = AT_PORRECTUS;
        *gtype = T_TORCULUS_RESUPINUS;
        shape = "PorrectusNobar";
        ltype = LG_NO_INITIO;
        break;
    case G_PORRECTUS_FLEXUS_NO_BAR:
        *type = AT_PORRECTUS;
        *gtype = T_TORCULUS_RESUPINUS_FLEXUS;
        shape = "PorrectusFlexusNobar";
        ltype = LG_NO_INITIO;
        break;
    case G_ANCUS:
        if (glyph->u.notes.liquescentia == L_DEMINUTUS
                || glyph->u.notes.liquescentia == L_DEMINUTUS_INITIO_DEBILIS) {
            if (pitch - glyph->u.notes.first_note->next->u.note.pitch == 1) {
                *type = AT_FLEXUS_1;
            } else {
                *type = AT_FLEXUS;
            }
            if (is_short(pitch, glyph, element)) {
                *gtype = T_ANCUS;
                shape = "Ancus";
            } else {
                *gtype = T_ANCUS_LONGQUEUE;
                shape = "AncusLongqueue";
            }
            ltype = LG_ONLY_DEMINUTUS;
        } else {
            // TODO...
            *type = AT_ONE_NOTE;
        }
        break;
    case G_SCANDICUS:
        *type = AT_ONE_NOTE;
        *gtype = T_SCANDICUS;
        shape = "Scandicus";
        ltype = LG_NO_INITIO;
        break;
    case G_SALICUS:
        *type = AT_ONE_NOTE;
        pitch = glyph->u.notes.first_note->next->next->u.note.pitch;
        if (gregoriotex_is_long(pitch, glyph, element) == 1) {
            *gtype = T_SALICUS_LONGQUEUE;
            shape = "SalicusLongqueue";
        } else {
            *gtype = T_SALICUS;
            shape = "Salicus";
        }
        ltype = LG_NO_INITIO;
        break;
    case G_ONE_NOTE:
    case G_PUNCTUM_INCLINATUM:
    case G_TRIGONUS:
    case G_PUNCTA_INCLINATA:
    case G_2_PUNCTA_INCLINATA_DESCENDENS:
    case G_3_PUNCTA_INCLINATA_DESCENDENS:
    case G_4_PUNCTA_INCLINATA_DESCENDENS:
    case G_5_PUNCTA_INCLINATA_DESCENDENS:
    case G_2_PUNCTA_INCLINATA_ASCENDENS:
    case G_3_PUNCTA_INCLINATA_ASCENDENS:
    case G_4_PUNCTA_INCLINATA_ASCENDENS:
    case G_5_PUNCTA_INCLINATA_ASCENDENS:
    case G_PUNCTUM:
    case G_STROPHA:
    case G_VIRGA:
    case G_VIRGA_REVERSA:
    case G_STROPHA_AUCTA:
    case G_DISTROPHA:
    case G_DISTROPHA_AUCTA:
    case G_TRISTROPHA:
    case G_TRISTROPHA_AUCTA:
    case G_BIVIRGA:
    case G_TRIVIRGA:
        *type = AT_ONE_NOTE;
        break;
    default:
        gregorio_messagef("gregoriotex_determine_glyph_name", ERROR, 0,
                _("called with unknown glyph: %d"), glyph->u.notes.glyph_type);
        break;
    }
    if (shape) {
        shape = compute_glyph_name(glyph, shape, ltype);
    }
    // we fix *type with initio_debilis
    if (*type == AT_ONE_NOTE) {
        if (is_initio_debilis(glyph->u.notes.liquescentia)) {
            *type = AT_INITIO_DEBILIS;
        }
    }

    return shape;
}

/**
 * This now does nothing useful, since the manuscript_reference is
 * now part of the score info.  But we keep it here in case it may
 * be needed in future.
 */
void gregoriotex_write_voice_info(FILE *f, gregorio_voice_info *voice_info)
{
    if (!voice_info) {
        return;
    }
}

// this function indicates if the syllable is the last of the line. If it's the
// last of the score it returns false, as it's handled another way
static bool gregoriotex_is_last_of_line(gregorio_syllable *syllable)
{
    gregorio_element *current_element = NULL;
    if (!(syllable->next_syllable)) {
        return false;
    }
    if ((syllable->next_syllable->elements)[0]
            && (syllable->next_syllable->elements)[0]->type == GRE_END_OF_LINE) {
        // the next syllable start by an end of line
        return true;
    }
    current_element = (syllable->elements)[0];
    while (current_element) {
        if (current_element->type == GRE_END_OF_LINE) {
            // we return true only if the end of line is the last element
            if (!(current_element->next)) {
                return true;
            } else {
                return false;
            }
        } else {
            current_element = current_element->next;
        }
    }
    return false;
}

/*
 * A small helper for the following function 
 */

static inline bool is_clef(gregorio_type x)
{
    return x == GRE_C_KEY_CHANGE || x == GRE_F_KEY_CHANGE ||
            x == GRE_C_KEY_CHANGE_FLATED || x == GRE_F_KEY_CHANGE_FLATED;
}

/*
 * This function is used in write_syllable, it detects if the syllable is like
 * (c4), (::c4), (z0c4) or (z0::c4). It returns the gregorio_element of the
 * clef change. 
 */
static gregorio_element *gregoriotex_syllable_is_clef_change(gregorio_syllable
        *syllable)
{
    gregorio_element *element;
    if (!syllable || !syllable->elements || !syllable->elements[0]) {
        return NULL;
    }
    element = syllable->elements[0];
    // we just detect the foud cases
    if (element->type == GRE_CUSTO && element->next
            && (is_clef(element->next->type)) && !element->next->next) {
        return element->next;
    }
    if (element->type == GRE_BAR && element->next
            && (is_clef(element->next->type)) && !element->next->next) {
        return element->next;
    }
    if ((is_clef(element->type)) && !element->next) {
        return element;
    }
    if (element->type == GRE_CUSTO && element->next
            && element->next->type == GRE_BAR && element->next->next
            && (is_clef(element->next->next->type))
            && !element->next->next->next) {
        return element->next->next;
    }
    return NULL;
}

/*
 * ! @brief This is an arbitrary maximum of notes we consider to affect the
 * syllable's text. We automatically lower the textline if the chant notes are
 * below the staff, so that they do not overlap. However, after a certain point
 * (defined by this value), the notes extend far beyond the letters of the text,
 * and thus lowering the text does not need to be considered. Used by
 * gregoriotex_getlineinfos() 
 */
#define NUMBER_OF_NOTES 6

/*
 * ! @brief function filling the gregorio_line (see gregoriotex.h) struct with
 * the infos on the line following syllable 
 */
static void gregoriotex_getlineinfos(gregorio_syllable *syllable,
        gregorio_line *line)
{
    gregorio_element *element;
    gregorio_glyph *glyph;
    gregorio_note *note;
    unsigned char i;
    // a counter to know at which note we are in a syllable
    // the idea behind it is that after the 6th note (arbitrary number), we can
    // consider that the bottom notes won't be bothering the text, because
    // they won't be above it.

    if (line == NULL) {
        gregorio_message(_
                ("call with NULL pointer"),
                "gregoriotex_write_score", ERROR, 0);
        return;
    }
    /*
     * first we check if the syllable is only a end of line. If it is the case,
     * we don't print anything but a comment (to be able to read it if we read
     * GregorioTeX). The end of lines are treated separately in GregorioTeX, it
     * is buit inside the TeX structure. 
     */
    line->additional_top_space = 0;
    line->additional_bottom_space = 0;
    line->translation = 0;
    line->abovelinestext = 0;

    if (syllable == NULL) {
        // we allow the call with NULL syllable
        return;
    }

    while (syllable) {
        i = 0;
        if (syllable->translation) {
            line->translation = 1;
        }
        if (syllable->abovelinestext) {
            line->abovelinestext = 1;
        }
        element = *syllable->elements;
        while (element) {
            if (element->type == GRE_END_OF_LINE) {
                return;
            }
            if (element->type == GRE_ALT) {
                line->abovelinestext = 1;
            }
            if (element->type != GRE_ELEMENT) {
                element = element->next;
                continue;
            }
            glyph = element->u.first_glyph;
            while (glyph) {
                if (glyph->type != GRE_GLYPH) {
                    glyph = glyph->next;
                    continue;
                }
                note = glyph->u.notes.first_note;
                while (note) {
                    i = i + 1;
                    switch (note->u.note.pitch) {
                    case 'a':
                        if (line->additional_bottom_space < 3
                                && i < NUMBER_OF_NOTES) {
                            // the idea is to put an extra space when a low
                            // note
                            // has a vertical episemus
                            if (note->signs >= _V_EPISEMUS) {
                                line->additional_bottom_space = 4;
                            } else {
                                line->additional_bottom_space = 3;
                            }
                        }
                        break;
                    case 'b':
                        if (line->additional_bottom_space < 2
                                && i < NUMBER_OF_NOTES) {
                            if (note->signs >= _V_EPISEMUS) {
                                line->additional_bottom_space = 3;
                            } else {
                                line->additional_bottom_space = 2;
                            }
                        }
                        break;
                    case 'c':
                        if (line->additional_bottom_space < 1
                                && i < NUMBER_OF_NOTES) {
                            if (note->signs >= _V_EPISEMUS) {
                                line->additional_bottom_space = 2;
                            } else {
                                line->additional_bottom_space = 1;
                            }
                        }
                        break;
                    case 'm':
                        if (line->additional_top_space < 3) {
                            line->additional_top_space = 3;
                        }
                        break;
                    case 'l':
                        if (line->additional_top_space < 2) {
                            line->additional_top_space = 2;
                        }
                        break;
                    case 'k':
                        if (line->additional_top_space < 1) {
                            line->additional_top_space = 1;
                        }
                        break;
                    default:
                        break;
                    }
                    note = note->next;
                }
                glyph = glyph->next;
            }
            element = element->next;
        }
        syllable = syllable->next_syllable;
    }
}

/*
 * ! @brief Prints the beginning of each text style 
 */
static void gtex_write_begin(FILE *f, grestyle_style style)
{
    if (style == gregoriotex_ignore_style) {
        return;
    }
    switch (style) {
    case ST_ITALIC:
        fprintf(f, "\\greitalic{");
        break;
    case ST_SMALL_CAPS:
        fprintf(f, "\\gresmallcaps{");
        break;
    case ST_BOLD:
        fprintf(f, "\\greboldfont{");
        break;
    case ST_FORCED_CENTER:
    case ST_CENTER:
        fprintf(f, "}{");
        break;
    case ST_TT:
        fprintf(f, "\\grett{");
        break;
    case ST_UNDERLINED:
        fprintf(f, "\\greul{");
        break;
    case ST_COLORED:
        fprintf(f, "\\grecolored{");
        break;
    default:
        break;
    }
}

/**
 * @brief Ends each text style
 */
static void gtex_write_end(FILE *f, grestyle_style style)
{
    if (style == gregoriotex_ignore_style) {
        return;
    }
    switch (style) {
    case ST_FORCED_CENTER:
    case ST_CENTER:
        fprintf(f, "}{");
        break;
    case ST_INITIAL:
        break;
    default:
        fprintf(f, "}");
        break;
    }
}

// a specific function for writing ends of the two first parts of the text of 
// the next syllable
static void gtex_write_end_for_two(FILE *f, grestyle_style style)
{
    if (style != gregoriotex_ignore_style) {
        fprintf(f, "}");
    }
}

/*
 * ! @brief Writes GregorioTeX special characters. This function takes the
 * special characters as input (i.e. from gabc representation), and writes them 
 * * in GregorioTeX form. 
 */
static void gtex_write_special_char(FILE *f, grewchar *special_char)
{
    if (!gregorio_wcsbufcmp(special_char, "A/")) {
        fprintf(f, "\\Abar{}");
        return;
    }
    if (!gregorio_wcsbufcmp(special_char, "%")) {
        fprintf(f, "\\%%{}");
        return;
    }
    if (!gregorio_wcsbufcmp(special_char, "R/")) {
        fprintf(f, "\\Rbar{}");
        return;
    }
    if (!gregorio_wcsbufcmp(special_char, "V/")) {
        fprintf(f, "\\Vbar{}");
        return;
    }
    if (!gregorio_wcsbufcmp(special_char, "'æ")) {
        fprintf(f, "\\'\\ae{}");
        return;
    }
    if (!gregorio_wcsbufcmp(special_char, "'ae")) {
        fprintf(f, "\\'\\ae{}");
        return;
    }
    if (!gregorio_wcsbufcmp(special_char, "'œ")) {
        fprintf(f, "\\'\\oe{}");
        return;
    }
    if (!gregorio_wcsbufcmp(special_char, "'oe")) {
        fprintf(f, "\\'\\oe{}");
        return;
    }
    if (!gregorio_wcsbufcmp(special_char, "ae")) {
        fprintf(f, "\\ae{}");
        return;
    }
    if (!gregorio_wcsbufcmp(special_char, "oe")) {
        fprintf(f, "\\oe{}");
        return;
    }
    if (!gregorio_wcsbufcmp(special_char, "*")) {
        fprintf(f, "\\grestar{}");
        return;
    }
    if (!gregorio_wcsbufcmp(special_char, "+")) {
        fprintf(f, "\\gredagger{}");
        return;
    }
    if (!gregorio_wcsbufcmp(special_char, "-")) {
        fprintf(f, "\\grezerhyph{}");
        return;
    }
    if (!gregorio_wcsbufcmp(special_char, "\\")) {
        fprintf(f, "\\textbackslash{}");
        return;
    }
    if (!gregorio_wcsbufcmp(special_char, "&")) {
        fprintf(f, "\\&{}");
        return;
    }
    if (!gregorio_wcsbufcmp(special_char, "#")) {
        fprintf(f, "\\#{}");
        return;
    }
    if (!gregorio_wcsbufcmp(special_char, "_")) {
        fprintf(f, "\\_{}");
        return;
    }
    if (!gregorio_wcsbufcmp(special_char, "~")) {
        fprintf(f, "\\gretilde{}");
        return;
    }
}

static void gtex_write_verb(FILE *f, grewchar *first_char)
{
    gregorio_print_unistring(f, first_char);
}

static void gtex_print_char(FILE *f, grewchar to_print)
{
    switch (to_print) {
    case L'*':
        fprintf(f, "\\grestar{}");
        break;
    case L'%':
        fprintf(f, "\\%%{}");
        break;
    case L'\\':
        fprintf(f, "\\textbackslash{}");
        break;
    case L'&':
        fprintf(f, "\\&{}");
        break;
    case L'#':
        fprintf(f, "\\#{}");
        break;
    case L'+':
        fprintf(f, "\\gredagger{}");
        break;
    case L'_':
        fprintf(f, "\\_{}");
        break;
    case L'-':
        fprintf(f, "\\grehyph{}");
        break;
    default:
        gregorio_print_unichar(f, to_print);
        break;
    }
    return;
}

// a function to map the internal ST_* styles to gregoriotex styles as defined
// in gregoriotex-syllables.tex
static unsigned char gregoriotex_internal_style_to_gregoriotex(grestyle_style
        style)
{
    switch (style) {
    case ST_ITALIC:
        return 1;
        break;
    case ST_BOLD:
        return 2;
        break;
    case ST_SMALL_CAPS:
        return 3;
        break;
    case ST_TT:
        return 4;
        break;
    case ST_UNDERLINED:
        return 5;
        break;
    case ST_COLORED:
        return 6;
        break;
    default:
        return 0;
        break;
    }
}

/*
 * A quite hacky function: when we have only one style (typically italic) and
 * when this style is on all the parts, then we return this style.
 *
 */
static grestyle_style gregoriotex_fix_style(gregorio_character *first_character)
{
    grestyle_style possible_fixed_style = ST_NO_STYLE;
    unsigned char state = 0;
    /*
     * states are: - 0: we didn't meet any style yet, which means that if we
     * encounter: * a character -> we can return, nothing to do * a style -> we
     * go in state 1 * center or initial: stay in state 0 - 1: we encountered a
     * style, if we encounter * another style : we can return * something that
     * makes us change syllable part (like center or initial) -> go in state 2 *
     * a character : stay in state 1 - 2: if we encounter: * another style, then
     * return * a character, then return * the same style: go in state 1 
     */
    gregorio_character *current_char = first_character;
    while (current_char) {
        switch (state) {
        case 0:
            if (current_char->is_character)
                return 0;
            if (current_char->cos.s.style != ST_CENTER
                    && current_char->cos.s.style != ST_FORCED_CENTER
                    && current_char->cos.s.style != ST_SPECIAL_CHAR
                    && current_char->cos.s.style != ST_VERBATIM
                    && current_char->cos.s.style != ST_INITIAL) {
                possible_fixed_style = current_char->cos.s.style;
                state = 1;
            }
            break;
        case 1:
            if (!current_char->is_character) {
                if (!current_char->is_character
                        && current_char->cos.s.style != ST_CENTER
                        && current_char->cos.s.style != ST_FORCED_CENTER
                        && current_char->cos.s.style != ST_INITIAL) {
                    state = 2;
                } else if (current_char->cos.s.style != possible_fixed_style
                        && current_char->cos.s.style != ST_SPECIAL_CHAR
                        && current_char->cos.s.style != ST_VERBATIM)
                    return 0;
            }
            break;
        case 2:
            if (current_char->is_character)
                return 0;
            if (current_char->cos.s.style != ST_CENTER
                    && current_char->cos.s.style != ST_FORCED_CENTER
                    && current_char->cos.s.style != ST_SPECIAL_CHAR
                    && current_char->cos.s.style != ST_VERBATIM
                    && current_char->cos.s.style != ST_INITIAL) {
                if (current_char->cos.s.style != possible_fixed_style) {
                    return 0;
                } else {
                    state = 1;
                }
            }
            break;
        default:
            break;
        }
        current_char = current_char->next_character;
    }
    // if we reached here, this means that we there is only one style applied
    // to all the syllables
    return possible_fixed_style;
}

/*
 * @brief Writes the translation.
 *
 * There is no special handling of translation text; that is, we just print the
 * entire string of text under the normal text line, without considering any
 * special centering or linebreaks.
 */
static void gregoriotex_write_translation(FILE *f,
        gregorio_character *translation)
{
    if (translation == NULL) {
        return;
    }
    gregorio_write_text(false, translation, f,
            (&gtex_write_verb),
            (&gtex_print_char),
            (&gtex_write_begin), (&gtex_write_end), (&gtex_write_special_char));
}

// a function to compute the height of the flat of a key
// the flat is always on the line of the

static char gregoriotex_clef_flat_height(char step, int line)
{
    switch (step) {
    case C_KEY:
        switch (line) {
        case 1:
            return 'c';
            break;
        case 2:
            return 'e';
            break;
        case 3:
            return 'g';
            break;
        case 4:
            return 'i';
            break;
        default:
            gregorio_messagef("gregoriotex_clef_flat_height", ERROR, 0,
                    _("unknown line number: %d"), line);
            return 'g';
            break;
        }
        break;
    case F_KEY:
        switch (line) {
        case 1:
            return 'g';
            break;
        case 2:
            return 'i';
            break;
        case 3:
            return 'd';
            break;
        case 4:
            return 'f';
            break;
        default:
            gregorio_messagef("gregoriotex_clef_flat_height", ERROR, 0,
                    _("unknown line number: %d"), line);
            return 'g';
            break;
        }
        break;
    default:
        gregorio_messagef("gregoriotex_clef_flat_height", ERROR, 0,
                _("unknown clef type: %d"), step);
        return 'g';
        break;
    }
}

static void gregoriotex_write_bar(FILE *f, gregorio_bar type,
        gregorio_sign signs, bool is_inside_bar)
{
    // the type number of function vepisemusorrare
    char typenumber = 26;
    if (is_inside_bar) {
        fprintf(f, "\\grein");
    } else {
        fprintf(f, "\\gre");
    }
    switch (type) {
    case B_VIRGULA:
        fprintf(f, "virgula");
        typenumber = 26;
        break;
    case B_DIVISIO_MINIMA:
        fprintf(f, "divisiominima");
        typenumber = 25;
        break;
    case B_DIVISIO_MINOR:
        fprintf(f, "divisiominor");
        typenumber = 25;
        break;
    case B_DIVISIO_MAIOR:
        fprintf(f, "divisiomaior");
        typenumber = 25;
        break;
    case B_DIVISIO_FINALIS:
        fprintf(f, "divisiofinalis");
        typenumber = 27;
        break;
    case B_DIVISIO_MINOR_D1:
        fprintf(f, "dominica{1}");
        // TODO: a true typenumber
        typenumber = 25;
        break;
    case B_DIVISIO_MINOR_D2:
        fprintf(f, "dominica{2}");
        // TODO: a true typenumber
        typenumber = 25;
        break;
    case B_DIVISIO_MINOR_D3:
        fprintf(f, "dominica{3}");
        // TODO: a true typenumber
        typenumber = 25;
        break;
    case B_DIVISIO_MINOR_D4:
        fprintf(f, "dominica{4}");
        // TODO: a true typenumber
        typenumber = 25;
        break;
    case B_DIVISIO_MINOR_D5:
        fprintf(f, "dominica{5}");
        // TODO: a true typenumber
        typenumber = 25;
        break;
    case B_DIVISIO_MINOR_D6:
        fprintf(f, "dominica{6}");
        // TODO: a true typenumber
        typenumber = 25;
        break;
    default:
        gregorio_messagef("gregoriotex_write_bar", ERROR, 0,
                _("unknown bar type: %d"), type);
        break;
    }
    switch (signs) {
    case _V_EPISEMUS:
        fprintf(f, "{\\grebarvepisemus{%d}}%%\n", typenumber);
        break;
    case _BAR_H_EPISEMUS:
        fprintf(f, "{\\grebarbrace{%d}}%%\n", typenumber);
        break;
    case _V_EPISEMUS_BAR_H_EPISEMUS:
        fprintf(f, "{\\grebarbrace{%d}\\grebarvepisemus{%d}}%%\n", typenumber,
                typenumber);
        break;
    default:
        fprintf(f, "{}%%\n");
        break;
    }
}

/*
 * ! @brief Writes augmentum duplexes (double dots) We suppose we are on the
 * last note. \n The algorithm is the following: if there is a previous note,
 * we consider that the two puncta of the augumentum duplex must correspond to
 * the last note and the previous note. If we are adding to a single note
 * glyph, which would be weird but sure why not, we just typeset two puncta
 * spaced of 2. 
 */
static void gregoriotex_write_auctum_duplex(FILE *f,
        gregorio_note *current_note)
{
    char pitch = current_note->u.note.pitch;
    char previous_pitch = 0;
    // second_pitch is the second argument of the \augmentumduplex macro,
    // that's
    // what this function is all about.
    char second_pitch = 0;
    // this variable will be set to 1 if we are on the note before the last
    // note
    // of a podatus or a porrectus or a torculus resupinus
    unsigned char special_punctum = 0;
    if (current_note->previous) {
        if (current_note->previous->u.note.pitch - current_note->u.note.pitch ==
                -1
                || current_note->previous->u.note.pitch -
                current_note->u.note.pitch == 1) {
            special_punctum = 1;
        }
        second_pitch = current_note->previous->u.note.pitch;
        previous_pitch = second_pitch;
    }

    if (!previous_pitch || previous_pitch == pitch) {
        if (is_on_a_line(pitch)) {
            second_pitch = pitch;
            special_punctum = 1;
        } else {
            second_pitch = pitch + 1;
        }
    }
    // the first argument should always be the lowest one, that's what we do
    // here:
    if (pitch > second_pitch) {
        previous_pitch = pitch;
        pitch = second_pitch;
        second_pitch = previous_pitch;
    }
    // maybe the third argument should be changed
    fprintf(f, "\\greaugmentumduplex{%c}{%c}{%d}%%\n", pitch, second_pitch,
            special_punctum);
}

/**
 * @brief Adds a dot.
 *
 * Writes \c \\grepunctummora in the gtex file, with the appropriate arguments. You might think this function
 * more straightforward than it actually is...
 */
static void gregoriotex_write_punctum_mora(FILE *f, gregorio_glyph *glyph,
        gtex_type type, gregorio_note *current_note)
{
    // in this if we consider that the puncta are only on the last two notes
    // (maybe it would be useful to consider it more entirely, but it would be
    // really weird...)
    // the variable that will be set to true if we have to shift the punctum
    // inclinatum before the last note
    bool shift_before = false;
    // this variable will be set to 1 if we are on the note before the last
    // note of a podatus or a porrectus or a torculus resupinus
    unsigned char special_punctum = 0;
    // 0 if space is normal, 1 if there should be no space after a punctum
    unsigned char no_space = 0;
    // the pitch where to set the punctum
    char pitch = current_note->u.note.pitch;
    // a variable to know if we are on a punctum inclinatum or not
    unsigned char punctum_inclinatum = 0;
    // a temp variable
    gregorio_note *tmpnote;
    // TODO: ensure the first note of a T_ONE_NOTE_TRF is handled correctly
    // first: the very special case where type == T_ONE_NOTE_TRF, the punctum
    // is
    // at a strange place:
    //if (type == T_ONE_NOTE_TRF) {
    //    fprintf(f, "\\grepunctummora{%c}{1}{0}{0}%%\n",
    //            current_note->u.note.pitch);
    //}
    // we go into this switch only if it is the note before the last note
    if (current_note->next) {
        switch (glyph->u.notes.glyph_type) {
        case G_FLEXA:
        case G_TORCULUS:
        case G_TORCULUS_RESUPINUS_FLEXUS:
        case G_PORRECTUS_FLEXUS:
            if (glyph->u.notes.liquescentia != L_DEMINUTUS
                    && glyph->u.notes.liquescentia !=
                    L_DEMINUTUS_INITIO_DEBILIS) {
                shift_before = true;
            }
            break;
        case G_PODATUS:
            if ((current_note->u.note.shape != S_PUNCTUM
                            && current_note->u.note.shape != S_QUILISMA)
                    || glyph->u.notes.liquescentia == L_AUCTUS_DESCENDENS
                    || glyph->u.notes.liquescentia == L_AUCTUS_ASCENDENS
                    || glyph->u.notes.liquescentia ==
                    L_AUCTUS_ASCENDENS_INITIO_DEBILIS
                    || glyph->u.notes.liquescentia ==
                    L_AUCTUS_DESCENDENS_INITIO_DEBILIS) {
                shift_before = true;
                // fine tuning
                if (current_note->next->u.note.pitch -
                        current_note->u.note.pitch == 1) {
                    if (is_on_a_line(current_note->u.note.pitch)) {
                        special_punctum = 1;
                    } else {
                        pitch = current_note->u.note.pitch - 1;
                    }
                }
            } else {
                // case for f.g
                if (current_note->next->u.note.pitch -
                        current_note->u.note.pitch == 1) {
                    special_punctum = 1;
                }
            }
            break;
        case G_PES_QUADRATUM:
            shift_before = true;
            if (current_note->next->u.note.pitch - current_note->u.note.pitch ==
                    1) {
                if (is_on_a_line(current_note->u.note.pitch)) {
                    special_punctum = 1;
                } else {
                    pitch = current_note->u.note.pitch - 1;
                }
            }
            break;
        case G_PORRECTUS:
        case G_TORCULUS_RESUPINUS:
            // this case is only for the note before the previous note
            if ((current_note->next->u.note.pitch -
                            current_note->u.note.pitch == -1
                            || current_note->next->u.note.pitch -
                            current_note->u.note.pitch == 1)
                    && !(current_note->next->next))
                special_punctum = 1;
            break;
        default:
            break;
        }
    }
    // we enter here in any case
    switch (glyph->u.notes.glyph_type) {
    case G_TRIGONUS:
    case G_PUNCTA_INCLINATA:
    case G_2_PUNCTA_INCLINATA_DESCENDENS:
    case G_3_PUNCTA_INCLINATA_DESCENDENS:
    case G_4_PUNCTA_INCLINATA_DESCENDENS:
    case G_5_PUNCTA_INCLINATA_DESCENDENS:
        if (!current_note->next) {
            special_punctum = 1;
        }
        break;
    default:
        break;
    }
    if (current_note->u.note.shape == S_PUNCTUM_INCLINATUM) {
        punctum_inclinatum = 1;
    }
    if (current_note->u.note.shape == S_PUNCTUM_INCLINATUM_DEMINUTUS) {
        punctum_inclinatum = 1;
    }
    // when the punctum mora is on a note on a line, and the prior note is on
    // the space immediately above, the dot is placed on the space below the
    // line instead
    if (current_note->previous
            && (current_note->previous->u.note.pitch -
                    current_note->u.note.pitch == 1)
            && is_on_a_line(current_note->u.note.pitch)
            && (current_note->previous->signs == _PUNCTUM_MORA
                    || current_note->previous->signs == _V_EPISEMUS_PUNCTUM_MORA
                    || current_note->previous->choral_sign)) {
        special_punctum = 1;
    }

    if (shift_before) {
        if (current_note->next->u.note.pitch - current_note->u.note.pitch == -1
                || current_note->next->u.note.pitch -
                current_note->u.note.pitch == 1) {
            fprintf(f, "\\grepunctummora{%c}{3}{%d}{%d}%%\n", pitch,
                    special_punctum, punctum_inclinatum);
        } else {
            fprintf(f, "\\grepunctummora{%c}{2}{%d}{%d}%%\n", pitch,
                    special_punctum, punctum_inclinatum);
        }
        return;
    }
    // There are two special cases. The first: if the next glyph is a
    // ZERO_WIDTH_SPACE, and the current glyph is a PES, and the punctum mora
    // is
    // on the first note, and the first note of the next glyph is at least two
    // (or three depending on something) pitches higher than the current note.
    // You'll all have understood, this case is quite rare... but when it
    // appears, we pass 1 as a second argument of \punctummora so that it
    // removes the space introduced by the punctummora.
    if (glyph->u.notes.glyph_type == G_PODATUS && glyph->next
            && glyph->next->type == GRE_SPACE
            && current_note->next && glyph->next->next
            && glyph->next->next->type == GRE_GLYPH
            && glyph->next->next->u.notes.first_note
            && (glyph->next->next->u.notes.first_note->u.note.pitch -
                    current_note->u.note.pitch > 1)) {
        fprintf(f, "\\grepunctummora{%c}{1}{%d}{%d}%%\n", pitch,
                special_punctum, punctum_inclinatum);
        return;
    }
    // if there is a punctum or a auctum dumplex on a note after, we put a
    // zero-width punctum
    tmpnote = current_note->next;
    while (tmpnote) {
        if (tmpnote->signs == _PUNCTUM_MORA || tmpnote->signs == _AUCTUM_DUPLEX
                || tmpnote->signs == _V_EPISEMUS_PUNCTUM_MORA
                || tmpnote->signs == _V_EPISEMUS_AUCTUM_DUPLEX
                || tmpnote->choral_sign) {
            no_space = 1;
            break;
        }
        tmpnote = tmpnote->next;
    }

    // the normal operation
    fprintf(f, "\\grepunctummora{%c}{%d}{%d}{%d}%%\n", pitch, no_space,
            special_punctum, punctum_inclinatum);
}

static inline void write_single_hepisemus(FILE *const f, int hepisemus_case,
        const gregorio_note *const note, bool connect, const char height,
        const grehepisemus_size size, const int i,
        const int porrectus_long_episemus_index,
        bool (*const is_episemus_shown)(const gregorio_note *))
{
    char ambitus = 0;
    char size_arg;

    if (height) {
        switch (size) {
        case H_SMALL_LEFT:
            size_arg = 'l';
            connect = false;
            break;
        case H_SMALL_CENTRE:
            size_arg = 'c';
            connect = false;
            break;
        case H_SMALL_RIGHT:
            size_arg = 'r';
            break;
        default:
            size_arg = 'f';
            break;
        }

        if (i == porrectus_long_episemus_index && note->next
                && is_episemus_shown(note->next)) {
            ambitus = compute_ambitus(note);
        }

        if (i - 1 != porrectus_long_episemus_index || !note->previous
                || !is_episemus_shown(note->previous)) {
            if (connect && (!note->next
                    || note->next->u.note.shape == S_PUNCTUM_INCLINATUM
                    || note->next->u.note.shape == S_PUNCTUM_INCLINATUM_DEMINUTUS
                    || note->next->u.note.shape == S_PUNCTUM_INCLINATUM_AUCTUS)) {
                fprintf(f, "\\grehepisemusbridge{%c}{}{}%%\n", height);
            }
            fprintf(f, "\\grehepisemus{%c}{%d}{%d}{%d}{%c}{%c}%%\n",
                    height, note->gtex_offset_case, ambitus, hepisemus_case,
                    size_arg, height);
        }
    }
}

/**
 * @brief A function that writes the good \c \\hepisemus in GregorioTeX.
 * @param i The position of the note in the glyph.
 */
static void gregoriotex_write_hepisemus(FILE *const f,
        const gregorio_glyph *const glyph,
        const gregorio_note *const note, const int i, const gtex_type type)
{
    char ambitus;
    int porrectus_long_episemus_index = -1;

    if (!note) {
        return;
    }

    switch (type) {
    case T_PORRECTUS:
    case T_PORRECTUS_FLEXUS:
        porrectus_long_episemus_index = 1;
        break;
    case T_TORCULUS_RESUPINUS:
    case T_TORCULUS_RESUPINUS_FLEXUS:
        porrectus_long_episemus_index = 2;
        break;
    }

    write_single_hepisemus(f, 1, note, note->h_episemus_below_connect,
            note->h_episemus_below, note->h_episemus_below_size, i,
            porrectus_long_episemus_index, &gtex_is_h_episemus_below_shown);
    write_single_hepisemus(f, 0, note, note->h_episemus_above_connect,
            note->h_episemus_above, note->h_episemus_above_size, i,
            porrectus_long_episemus_index, &gtex_is_h_episemus_above_shown);
}

// a macro to write an additional line

static void gregoriotex_write_additional_line(FILE *f,
        gregorio_glyph *current_glyph, int i, gtex_type type, bool bottom,
        gregorio_note *current_note)
{
    char ambitus = 0;
    if (!current_note) {
        gregorio_message(_("called with no note"),
                "gregoriotex_write_additional_line", ERROR, 0);
        return;
    }
    // patch to get a line under the full glyph in the case of dbc (for
    // example)
    switch (type) {
    case T_PORRECTUS:
    case T_PORRECTUS_FLEXUS:
        if (i == 1) {
            i = HEPISEMUS_FIRST_TWO;
        }
        if (i == 2) {
            if (current_note->previous->u.note.pitch > 'b'
                    && current_note->previous->u.note.pitch < 'l') {
                i = HEPISEMUS_FIRST_TWO;
                // HEPISEMUS_FIRST_TWO works only for first note
                current_note = current_note->previous;
            } else {
                return;
            }
        }
        if (i == 3) {
            if (bottom || current_note->previous->u.note.pitch > 'k') {
                // we don't need to add twice the same line
                return;
            }
        }
        break;
    case T_TORCULUS_RESUPINUS:
    case T_TORCULUS_RESUPINUS_FLEXUS:
        if (i == 2) {
            i = HEPISEMUS_FIRST_TWO;
        }
        if (i == 3) {
            if (current_note->previous->u.note.pitch > 'b'
                    && current_note->previous->u.note.pitch < 'l') {
                i = HEPISEMUS_FIRST_TWO;
                // HEPISEMUS_FIRST_TWO works only for first note
                current_note = current_note->previous;
            } else {
                return;
            }
        }
        if (i == 4) {
            if (bottom || current_note->previous->u.note.pitch > 'k') {
                // we don't need to add twice the same line
                return;
            }
        }
        break;
    default:
        break;
    }

    if (i == HEPISEMUS_FIRST_TWO) {
        // here we must compare the first note of the big bar with the second
        // one
        // but it may be tricky sometimes, because of the previous patch
        if (current_note->previous &&
                current_note->previous->u.note.pitch >
                current_note->u.note.pitch) {
            ambitus =
                    current_note->previous->u.note.pitch -
                    current_note->u.note.pitch;
        } else {
            ambitus =
                    current_note->u.note.pitch -
                    current_note->next->u.note.pitch;
        }
    }
    fprintf(f, "\\greadditionalline{%d}{%d}{%d}%%\n",
            current_note->gtex_offset_case, ambitus, bottom ? 3 : 2);
}

/*
 * 
 * a function that writes the good value of \vepisemus in GregorioTeX. i is the 
 * position of the note in the glyph
 * 
 */

static void gregoriotex_write_vepisemus(FILE *f, gregorio_glyph *glyph, int i,
        gtex_type type, gregorio_note *note)
{

    char height = note->v_episemus_height;
    if (height < 'a') {
        height += 'z' - 'a' + 1;
    }

    fprintf(f, "\\grevepisemus{%c}{%d}%%\n", height, note->gtex_offset_case);
}

/*
 * a function that writes the rare signs in GregorioTeX. i is the position of
 * the note in the glyph */

static void gregoriotex_write_rare(FILE *f, gregorio_glyph *current_glyph,
        int i, gtex_type type, gregorio_note *current_note, gregorio_sign rare)
{
    switch (rare) {
    case _ACCENTUS:
        fprintf(f, "\\greaccentus{%c}{%d}%%\n", current_note->u.note.pitch,
                current_note->gtex_offset_case);
        break;
    case _ACCENTUS_REVERSUS:
        fprintf(f, "\\grereversedaccentus{%c}{%d}%%\n",
                current_note->u.note.pitch, current_note->gtex_offset_case);
        break;
    case _CIRCULUS:
        fprintf(f, "\\grecirculus{%c}{%d}%%\n", current_note->u.note.pitch,
                current_note->gtex_offset_case);
        break;
    case _SEMI_CIRCULUS:
        fprintf(f, "\\gresemicirculus{%c}{%d}%%\n", current_note->u.note.pitch,
                current_note->gtex_offset_case);
        break;
    case _SEMI_CIRCULUS_REVERSUS:
        fprintf(f, "\\grereversedsemicirculus{%c}{%d}%%\n",
                current_note->u.note.pitch, current_note->gtex_offset_case);
        break;
        // the cases of the bar signs are dealt in another function (write_bar)
    default:
        break;
    }
}

/*
 * function used when the glyph is only one note long
 */

static void gregoriotex_write_note(FILE *f, gregorio_note *note,
        gregorio_glyph *glyph, gregorio_element *element, char next_note_pitch)
{
    unsigned int initial_shape = note->u.note.shape;
    char temp;
    char *shape;
    // type in the sense of GregorioTeX alignment type
    gtex_alignment type = AT_ONE_NOTE;
    if (!note) {
        gregorio_message(_
                ("called with NULL pointer"),
                "gregoriotex_write_note", ERROR, 0);
        return;
    }
    if (note->u.note.shape == S_PUNCTUM
            && note->u.note.liquescentia != L_NO_LIQUESCENTIA) {
        switch (note->u.note.liquescentia) {
        case L_AUCTUS_ASCENDENS:
            note->u.note.shape = S_PUNCTUM_AUCTUS_ASCENDENS;
            break;
        case L_AUCTUS_DESCENDENS:
        case L_AUCTA:
            note->u.note.shape = S_PUNCTUM_AUCTUS_DESCENDENS;
            break;
        case L_DEMINUTUS:
        case L_INITIO_DEBILIS:
            note->u.note.shape = S_PUNCTUM_DEMINUTUS;
        default:
            break;
        }
    }
    shape = gregoriotex_determine_note_glyph_name(note, glyph, element, &type);
    note->u.note.shape = initial_shape;
    // special things for puncta inclinata
    if (note->u.note.shape == S_PUNCTUM_INCLINATUM) {
        if (note->previous) {
            // means that it is the first note of the puncta inclinata sequence
            temp = note->previous->u.note.pitch - note->u.note.pitch;
            // if (temp < -1 || temp > 1)
            switch (temp)       // we switch on the range of the inclinata
            {
                // this will look somewhat strange if temp is negative... to be
                // aligned then,
                // the second note should really shift differently
            case -2:
            case 2:
                fprintf(f, "\\greendofglyph{10}%%\n");
                break;
            case -3:
            case 3:
                fprintf(f, "\\greendofglyph{11}%%\n");
                break;
            case -4:
            case 4:            // not sure we ever need to consider a larger
                // ambitus here
                fprintf(f, "\\greendofglyph{11}%%\n");
                break;
            default:
                fprintf(f, "\\greendofglyph{3}%%\n");
                break;
            }
        }
    }
    if (note->u.note.shape == S_PUNCTUM_INCLINATUM_DEMINUTUS) {
        if (note->previous) {
            // means that it is the first note of the puncta inclinata sequence
            temp = note->previous->u.note.pitch - note->u.note.pitch;
            if (temp < -2 || temp > 2) {
                fprintf(f, "\\greendofglyph{11}%%\n");
            } else {
                if (note->previous
                        && note->previous->u.note.shape ==
                        S_PUNCTUM_INCLINATUM_DEMINUTUS) {
                    if (temp < -1 || temp > 1)
                        // really if the ambitus = 3rd at this point
                    {
                        fprintf(f, "\\greendofglyph{10}%%\n");
                    } else {
                        fprintf(f, "\\greendofglyph{8}%%\n");
                    }
                } else {
                    // puncta inclinatum followed by puncta inclinatum debilis
                    fprintf(f, "\\greendofglyph{7}%%\n");
                }
            }
        }
    }
    if (note->u.note.shape == S_PUNCTUM_INCLINATUM_AUCTUS) {
        if (note->previous) {
            // means that it is the first note of the puncta inclinata sequence
            temp = note->previous->u.note.pitch - note->u.note.pitch;
            if (temp < -1 || temp > 1) {
                fprintf(f, "\\greendofglyph{1}%%\n");
            } else {
                // we approximate that it is the same space
                fprintf(f, "\\greendofglyph{3}%%\n");
            }
        }
    }
    switch (note->u.note.shape) {
    case S_PUNCTUM_CAVUM:
        fprintf(f, "\\grepunctumcavum{%c}{%c}{%d}", note->u.note.pitch,
                next_note_pitch, type);
        break;
    case S_LINEA_PUNCTUM_CAVUM:
        fprintf(f, "\\grelineapunctumcavum{%c}{%c}{%d}", note->u.note.pitch,
                next_note_pitch, type);
        break;
    case S_LINEA:
        fprintf(f, "\\grelinea{%c}{%c}{%d}", note->u.note.pitch,
                next_note_pitch, type);
        break;
    default:
        fprintf(f, "\\greglyph{\\grecp%s}{%c}{%c}{%d}",
                shape, note->u.note.pitch, next_note_pitch, type);
        break;
    }
}

static int gregoriotex_syllable_first_type(gregorio_syllable *syllable)
{
    int result = 0;
    gtex_alignment type = AT_ONE_NOTE;
    gtex_type gtype = T_ONE_NOTE;
    // alteration says if there is a flat or a natural first in the next
    // syllable, see gregoriotex.tex for more details
    int alteration = 0;
    gregorio_glyph *glyph;
    gregorio_element *element;
    if (!syllable) {
        gregorio_message(_("called with a NULL argument"),
                "gregoriotex_syllable_first_type", ERROR, 0);
    }
    element = syllable->elements[0];
    while (element) {
        if (element->type == GRE_BAR) {
            switch (element->u.misc.unpitched.info.bar) {
            case B_NO_BAR:
            case B_VIRGULA:
                result = 10;
                break;
            case B_DIVISIO_MINIMA:
            case B_DIVISIO_MINOR:
            case B_DIVISIO_MAIOR:
            case B_DIVISIO_MINOR_D1:
            case B_DIVISIO_MINOR_D2:
            case B_DIVISIO_MINOR_D3:
            case B_DIVISIO_MINOR_D4:
            case B_DIVISIO_MINOR_D5:
            case B_DIVISIO_MINOR_D6:
                result = 11;
                break;
            case B_DIVISIO_FINALIS:
                result = 12;
                break;
            default:
                result = 0;
                break;
            }
            return result;
        }
        if (element->type == GRE_ELEMENT && element->u.first_glyph) {
            glyph = element->u.first_glyph;
            while (glyph) {
                if (alteration == 0) {
                    switch (glyph->type) {
                    case GRE_FLAT:
                        alteration = 20;
                        break;
                    case GRE_NATURAL:
                        alteration = 40;
                        break;
                    case GRE_SHARP:
                        alteration = 60;
                        break;
                    }
                }
                if (glyph->type == GRE_GLYPH && glyph->u.notes.first_note) {
                    switch (glyph->u.notes.glyph_type) {
                    case G_TRIGONUS:
                    case G_PUNCTA_INCLINATA:
                    case G_2_PUNCTA_INCLINATA_DESCENDENS:
                    case G_3_PUNCTA_INCLINATA_DESCENDENS:
                    case G_4_PUNCTA_INCLINATA_DESCENDENS:
                    case G_5_PUNCTA_INCLINATA_DESCENDENS:
                    case G_2_PUNCTA_INCLINATA_ASCENDENS:
                    case G_3_PUNCTA_INCLINATA_ASCENDENS:
                    case G_4_PUNCTA_INCLINATA_ASCENDENS:
                    case G_5_PUNCTA_INCLINATA_ASCENDENS:
                    case G_PUNCTUM:
                    case G_STROPHA:
                    case G_VIRGA:
                    case G_VIRGA_REVERSA:
                    case G_STROPHA_AUCTA:
                    case G_DISTROPHA:
                    case G_DISTROPHA_AUCTA:
                    case G_TRISTROPHA:
                    case G_TRISTROPHA_AUCTA:
                    case G_BIVIRGA:
                    case G_TRIVIRGA:
                        gregoriotex_determine_note_glyph_name
                                (glyph->u.notes.first_note, glyph, element,
                                &type);
                        break;
                    default:
                        gregoriotex_determine_glyph_name(glyph, element, &type,
                                &gtype);
                        break;
                    }
                    return type + alteration;
                }
                glyph = glyph->next;
            }
        }
        element = element->next;
    }
    return 0;
}

static void gregoriotex_write_choral_sign(FILE *f, gregorio_glyph *glyph,
        gtex_type type, int i, gregorio_note *current_note, bool low)
{
    bool kind_of_pes;
    // false in the normal case (sign above the note), true in the case of it's
    // next to the note (same height as a punctum)
    bool low_sign = choral_sign_here_is_low(glyph, current_note, &kind_of_pes);

    // the low choral signs must be typeset after the punctum, whereas the high
    // must be typeset before the h episemus
    if ((low_sign && !low) || (!low_sign && low)) {
        return;
    }

    if (low_sign) {
        // very approximative heuristic, some things may have to be adapted
        // here...
        if (is_on_a_line(current_note->u.note.pitch)) {
            if (kind_of_pes && current_note->u.note.pitch -
                    current_note->next->u.note.pitch == -1) {
                fprintf(f, "\\grelowchoralsign{%c}{%s}{1}%%\n",
                        current_note->u.note.pitch, current_note->choral_sign);
                return;
            }
            if (current_note->previous
                    && (current_note->previous->signs == _PUNCTUM_MORA
                            || current_note->previous->signs ==
                            _V_EPISEMUS_PUNCTUM_MORA)) {
                fprintf(f, "\\grelowchoralsign{%c}{%s}{1}%%\n",
                        current_note->u.note.pitch, current_note->choral_sign);
                return;
            }
        }

        fprintf(f, "\\grelowchoralsign{%c}{%s}{0}%%\n",
                current_note->u.note.pitch, current_note->choral_sign);
    } else {
        // let's cheat a little
        if (is_on_a_line(current_note->u.note.pitch)) {
            fprintf(f, "\\grehighchoralsign{%c}{%s}{%d}%%\n",
                    current_note->u.note.pitch, current_note->choral_sign,
                    current_note->gtex_offset_case);
        } else {
            fprintf(f, "\\grehighchoralsign{%c}{%s}{%d}%%\n",
                    current_note->u.note.pitch + 2, current_note->choral_sign,
                    current_note->gtex_offset_case);
        }
    }
}

/*
 * 
 * A function that write the signs of a glyph, which has the type type (T_*,
 * not G_*, which is in the glyph->glyph_type), and (important), we start only
 * at the note current_note. It is due to the way we call it : if type is
 * T_ONE_NOTE, we just do the signs on current_note, not all. This is the case
 * for example for the first note of the torculus resupinus, or the
 * G_*_PUNCTA_INCLINATA.
 * 
 */

// small helper
#define _found()\
	  if (!found)\
	    {\
	      found = true;\
	      fprintf (f, "%%\n");\
	    }

#define _end_loop()\
      if (type == T_ONE_NOTE)\
	{\
	  break;\
	}\
      else\
	{\
	  current_note = current_note->next;\
	  i++;\
	}

static void gregoriotex_write_signs(FILE *f, gtex_type type,
        gregorio_glyph *glyph, gregorio_element *element, gregorio_note *note)
{
    // i is the number of the note for which we are typesetting the sign.
    int i = 1;
    // a dumb char
    char block_hepisemus = 0;
    bool found = false;
    gregorio_note *current_note = note;
    while (current_note) {
        // we start by the additional lines
        if (current_note->u.note.pitch < 'c') {
            if (!found) {
                found = true;
                fprintf(f, "%%\n{%%\n");
            }
            gregoriotex_write_additional_line(f, glyph, i, type,
                    true, current_note);
            status->bottom_line = 1;
        }
        if (current_note->u.note.pitch > 'k') {
            if (!found) {
                found = true;
                fprintf(f, "%%\n{%%\n");
            }
            gregoriotex_write_additional_line(f, glyph, i, type,
                    false, current_note);
        }
        if (current_note->texverb) {
            if (!found) {
                found = true;
                fprintf(f, "%%\n{%%\n");
            }
            fprintf(f,
                    "%% verbatim text at note level:\n%s%%\n%% end of verbatim text\n",
                    current_note->texverb);
        }
        _end_loop();
    }
    if (!found) {
        fprintf(f, "{}{");
    } else {
        fprintf(f, "}{");
    }
    found = false;
    i = 1;
    current_note = note;
    // now a first loop for the choral signs, because high signs must be taken
    // into account before any hepisemus
    while (current_note) {
        if (current_note->choral_sign) {
            _found();
            gregoriotex_write_choral_sign(f, glyph, type, i, current_note,
                    false);
        }
        _end_loop();
    }
    // a loop for rare signs, vertical episemus, and horizontal episemus
    i = 1;
    current_note = note;
    while (current_note) {
        // we continue with the hepisemus
        if (current_note->h_episemus_above || current_note->h_episemus_below) {
            _found();
            gregoriotex_write_hepisemus(f, glyph, current_note, i, type);
        }
        // write_rare also writes the vepisemus
        if (current_note->special_sign) {
            _found();
            gregoriotex_write_rare(f, glyph, i, type,
                    current_note, current_note->special_sign);
        }
        if (current_note->signs != _NO_SIGN) {
            _found();
        }
        switch (current_note->signs) {
        case _V_EPISEMUS:
        case _V_EPISEMUS_PUNCTUM_MORA:
        case _V_EPISEMUS_AUCTUM_DUPLEX:
            gregoriotex_write_vepisemus(f, glyph, i, type, current_note);
            break;
        }
        // why is this if there?...
        if (!current_note->special_sign) {
            if (block_hepisemus == 2) {
                block_hepisemus = 0;
            }
            if (block_hepisemus == 1) {
                block_hepisemus = 2;
            }
        }
        _end_loop()
                // final loop for choral signs and punctum mora
    }
    i = 1;
    current_note = note;
    while (current_note) {
        switch (current_note->signs) {
        case _PUNCTUM_MORA:
        case _V_EPISEMUS_PUNCTUM_MORA:
            gregoriotex_write_punctum_mora(f, glyph, type, current_note);
            break;
        case _AUCTUM_DUPLEX:
        case _V_EPISEMUS_AUCTUM_DUPLEX:
            gregoriotex_write_auctum_duplex(f, current_note);
            break;
        default:
            break;
        }
        if (current_note->choral_sign) {
            _found();
            gregoriotex_write_choral_sign(f, glyph, type, i, current_note,
                    true);
        }
        _end_loop();
    }
    fprintf(f, "}%%\n");
}

static char *determine_leading_shape(gregorio_glyph *glyph)
{
    static char buf[BUFSIZE];
    int ambitus = compute_ambitus(glyph->u.notes.first_note);
    char *head, *head_liquescence;

    switch (glyph->u.notes.first_note->u.note.shape) {
    case S_QUILISMA:
        head = "Quilisma";
        break;
    case S_ORISCUS:
    case S_ORISCUS_SCAPUS:
        head = "Oriscus";
        break;
    default:
        head = "Punctum";
        break;
    }

    switch (glyph->u.notes.liquescentia) {
    case L_INITIO_DEBILIS:
    case L_DEMINUTUS_INITIO_DEBILIS:
    case L_AUCTUS_ASCENDENS_INITIO_DEBILIS:
    case L_AUCTUS_DESCENDENS_INITIO_DEBILIS:
    case L_AUCTA_INITIO_DEBILIS:
        head_liquescence = "InitioDebilis";
        break;
    default:
        head_liquescence = "";
        break;
    }

    snprintf(buf, BUFSIZE, "Leading%s%s%s", head, tex_ambitus[ambitus],
            head_liquescence);
    return buf;
}

static void gregoriotex_write_glyph(FILE *f, gregorio_syllable *syllable,
        gregorio_element *element, gregorio_glyph *glyph)
{
    // glyph number is the number of the glyph in the fonte, it is discussed in
    // later comments
    // type is the type of the glyph. Understand the type of the glyph for
    // gregoriotex, for the alignement between text and notes. (AT_ONE_NOTE,
    // etc.)
    gtex_alignment type = 0;
    // the type of the glyph, in the sense of the shape (T_PES, etc.)
    gtex_type gtype = 0;
    char next_note_pitch = 0;
    gregorio_note *current_note;
    char *leading_shape, *shape;
    if (!glyph) {
        gregorio_message(_("called with NULL pointer"),
                "gregoriotex_write_glyph", ERROR, 0);
        return;
    }
    if (glyph->type != GRE_GLYPH || !glyph->u.notes.first_note) {
        gregorio_message(_("called with glyph without note"),
                "gregoriotex_write_glyph", ERROR, 0);
        return;
    }
    next_note_pitch = gregorio_determine_next_pitch(syllable, element, glyph);
    current_note = glyph->u.notes.first_note;
    // first we check if it is really a unique glyph in gregoriotex... the
    // glyphs that are not a unique glyph are : trigonus and pucta inclinata
    // in general, and torculus resupinus and torculus resupinus flexus, so
    // we first divide the glyph into real gregoriotex glyphs
    switch (glyph->u.notes.glyph_type) {
    case G_TRIGONUS:
    case G_PUNCTA_INCLINATA:
    case G_2_PUNCTA_INCLINATA_DESCENDENS:
    case G_3_PUNCTA_INCLINATA_DESCENDENS:
    case G_4_PUNCTA_INCLINATA_DESCENDENS:
    case G_5_PUNCTA_INCLINATA_DESCENDENS:
    case G_2_PUNCTA_INCLINATA_ASCENDENS:
    case G_3_PUNCTA_INCLINATA_ASCENDENS:
    case G_4_PUNCTA_INCLINATA_ASCENDENS:
    case G_5_PUNCTA_INCLINATA_ASCENDENS:
        while (current_note) {
            gregoriotex_write_note(f, current_note, glyph, element,
                    next_note_pitch);
            gregoriotex_write_signs(f, T_ONE_NOTE, glyph, element,
                    current_note);
            current_note = current_note->next;
        }
        break;
    case G_SCANDICUS:
        if (glyph->u.notes.liquescentia == L_DEMINUTUS
                || glyph->u.notes.liquescentia == L_DEMINUTUS_INITIO_DEBILIS
                || glyph->u.notes.liquescentia == L_NO_LIQUESCENTIA) {
            shape = gregoriotex_determine_glyph_name(glyph, element, &type,
                    &gtype);
            fprintf(f, "\\greglyph{\\grecp%s}{%c}{%c}{%d}", shape,
                    glyph->u.notes.first_note->u.note.pitch, next_note_pitch,
                    type);
            gregoriotex_write_signs(f, gtype, glyph, element,
                    glyph->u.notes.first_note);
        } else {
            while (current_note) {
                gregoriotex_write_note(f, current_note, glyph, element,
                        next_note_pitch);
                gregoriotex_write_signs(f, T_ONE_NOTE, glyph, element,
                        current_note);
                current_note = current_note->next;
            }
        }
        break;
    case G_ANCUS:
        if (glyph->u.notes.liquescentia == L_DEMINUTUS
                || glyph->u.notes.liquescentia == L_DEMINUTUS_INITIO_DEBILIS) {
            shape = gregoriotex_determine_glyph_name(glyph, element, &type,
                    &gtype);
            fprintf(f, "\\greglyph{\\grecp%s}{%c}{%c}{%d}", shape,
                    glyph->u.notes.first_note->u.note.pitch, next_note_pitch,
                    type);
            gregoriotex_write_signs(f, gtype, glyph, element,
                    glyph->u.notes.first_note);
        } else {
            while (current_note) {
                gregoriotex_write_note(f, current_note, glyph, element,
                        next_note_pitch);
                gregoriotex_write_signs(f, T_ONE_NOTE, glyph, element,
                        current_note);
                current_note = current_note->next;
            }
        }
        break;
    case G_TORCULUS_RESUPINUS_FLEXUS:
        leading_shape = determine_leading_shape(glyph);
        // trick to have the good position for these glyphs
        glyph->u.notes.glyph_type = G_PORRECTUS_FLEXUS_NO_BAR;
        glyph->u.notes.first_note = current_note->next;
        shape = gregoriotex_determine_glyph_name(glyph, element, &type, &gtype);
        fprintf(f, "\\greglyph{\\grefusetwo{\\grecp%s}{\\grecp%s}}{%c}{%c}{%d}",
                leading_shape, shape,
                glyph->u.notes.first_note->u.note.pitch, next_note_pitch, type);
        glyph->u.notes.first_note = current_note;
        glyph->u.notes.glyph_type = G_TORCULUS_RESUPINUS_FLEXUS;
        gregoriotex_write_signs(f, gtype, glyph, element,
                glyph->u.notes.first_note);
        break;
    case G_BIVIRGA:
    case G_TRIVIRGA:
        while (current_note) {
            gregoriotex_write_note(f, current_note, glyph, element,
                    next_note_pitch);
            gregoriotex_write_signs(f, T_ONE_NOTE, glyph, element,
                    current_note);
            current_note = current_note->next;
            if (current_note) {
                fprintf(f, "\\greendofglyph{4}%%\n");
            }
        }
        break;
    case G_TRISTROPHA:
    case G_TRISTROPHA_AUCTA:
    case G_DISTROPHA:
    case G_DISTROPHA_AUCTA:
        while (current_note) {
            gregoriotex_write_note(f, current_note, glyph, element,
                    next_note_pitch);
            gregoriotex_write_signs(f, T_ONE_NOTE, glyph, element,
                    current_note);
            current_note = current_note->next;
            if (current_note) {
                fprintf(f, "\\greendofglyph{5}%%\n");
            }
        }
        break;
    case G_PUNCTUM:
        if (glyph->u.notes.first_note->u.note.shape != S_ORISCUS
                && glyph->u.notes.first_note->u.note.shape != S_ORISCUS_AUCTUS
                && glyph->u.notes.first_note->u.note.shape !=
                S_ORISCUS_DEMINUTUS
                && glyph->u.notes.first_note->u.note.shape !=
                S_ORISCUS_SCAPUS) {
            switch (glyph->u.notes.liquescentia) {
            case L_AUCTUS_ASCENDENS:
                glyph->u.notes.first_note->u.note.shape =
                        S_PUNCTUM_AUCTUS_ASCENDENS;
                break;
            case L_AUCTUS_DESCENDENS:
            case L_AUCTA:
                glyph->u.notes.first_note->u.note.shape =
                        S_PUNCTUM_AUCTUS_DESCENDENS;
                break;
            case L_DEMINUTUS:
            case L_INITIO_DEBILIS:
                glyph->u.notes.first_note->u.note.shape = S_PUNCTUM_DEMINUTUS;
            default:
                break;
            }
        }
        // else fall into the next case
    case G_PUNCTUM_INCLINATUM:
    case G_VIRGA:
    case G_VIRGA_REVERSA:
    case G_STROPHA:
    case G_STROPHA_AUCTA:
        gregoriotex_write_note(f, glyph->u.notes.first_note, glyph, element,
                next_note_pitch);
        gregoriotex_write_signs(f, T_ONE_NOTE, glyph, element, current_note);
        break;
    default:
        // special case of the torculus resupinus which first note is not a
        // punctum
        if (glyph->u.notes.glyph_type == G_TORCULUS_RESUPINUS
                && current_note->u.note.shape != S_PUNCTUM
                && current_note->u.note.shape != S_QUILISMA) {
            leading_shape = determine_leading_shape(glyph);
            // trick to have the good position for these glyphs
            glyph->u.notes.glyph_type = G_PORRECTUS_NO_BAR;
            glyph->u.notes.first_note = current_note->next;
            shape = gregoriotex_determine_glyph_name(glyph, element, &type,
                    &gtype);
            fprintf(f,
                    "\\greglyph{\\grefusetwo{\\grecp%s}{\\grecp%s}}{%c}{%c}{%d}",
                    leading_shape, shape,
                    glyph->u.notes.first_note->u.note.pitch, next_note_pitch,
                    type);
            glyph->u.notes.first_note = current_note;
            glyph->u.notes.glyph_type = G_TORCULUS_RESUPINUS;
            gregoriotex_write_signs(f, gtype, glyph, element,
                    glyph->u.notes.first_note);
            break;
        } else {
            shape = gregoriotex_determine_glyph_name(glyph, element, &type,
                    &gtype);
            fprintf(f, "\\greglyph{\\grecp%s}{%c}{%c}{%d}", shape,
                    glyph->u.notes.first_note->u.note.pitch, next_note_pitch,
                    type);
            gregoriotex_write_signs(f, gtype, glyph, element,
                    glyph->u.notes.first_note);
            break;
        }
    }
}

// here we absolutely need to pass the syllable as an argument, because we
// will need the next note, that may be contained in the next syllable

static void gregoriotex_write_element(FILE *f, gregorio_syllable *syllable,
        gregorio_element *element)
{
    if (element->type == GRE_ELEMENT) {
        for (gregorio_glyph *glyph = element->u.first_glyph; glyph;
                glyph = glyph->next) {
            switch (glyph->type) {
            case GRE_SPACE:
                // we assume here that it is a SP_ZERO_WIDTH, the only one a
                // glyph can be
                fprintf(f, "\\greendofglyph{1}%%\n");
                break;

            case GRE_TEXVERB_GLYPH:
                if (glyph->texverb) {
                    fprintf(f, "%% verbatim text at glyph level:\n%s%%\n"
                            "%% end of verbatim text\n", glyph->texverb);
                }
                break;

            case GRE_FLAT:
                fprintf(f, "\\greflat{%c}{0}%%\n", glyph->u.misc.pitched.pitch);
                break;

            case GRE_NATURAL:
                fprintf(f, "\\grenatural{%c}{0}%%\n",
                        glyph->u.misc.pitched.pitch);
                break;

            case GRE_SHARP:
                fprintf(f, "\\gresharp{%c}{0}%%\n",
                        glyph->u.misc.pitched.pitch);
                break;

            case GRE_MANUAL_CUSTOS:
                fprintf(f, "\\gremanualcusto{%c}%%\n",
                        glyph->u.misc.pitched.pitch);
                break;

            default:
                // at this point glyph->type is GRE_GLYPH
                assert(glyph->type == GRE_GLYPH);
                gregoriotex_write_glyph(f, syllable, element, glyph);
                if (glyph->next && glyph->next->type == GRE_GLYPH) {
                    if (is_puncta_inclinata(glyph->next->u.notes.glyph_type)
                            || glyph->next->u.notes.glyph_type ==
                            G_PUNCTA_INCLINATA) {
                        fprintf(f, "\\greendofglyph{9}%%\n");
                    } else {
                        fprintf(f, "\\greendofglyph{0}%%\n");
                    }
                }
                break;
            }
        }
    }
}

static void gregoriotex_write_text(FILE *f, gregorio_character *text,
        bool * first_syllable, int next_syl)
{
    if (text == NULL) {
        fprintf(f, "{}{}{}");
        return;
    }
    fprintf(f, "{");
    gregoriotex_ignore_style = gregoriotex_fix_style(text);
    if (gregoriotex_ignore_style != 0) {
        if (next_syl) {
            fprintf(f, "\\gresetfixednexttextformat{%d}",
                    gregoriotex_internal_style_to_gregoriotex
                    (gregoriotex_ignore_style));
        } else {
            fprintf(f, "\\gresetfixedtextformat{%d}",
                    gregoriotex_internal_style_to_gregoriotex
                    (gregoriotex_ignore_style));
        }
    }
    gregorio_write_text(first_syllable && *first_syllable, text, f,
            (&gtex_write_verb), (&gtex_print_char), (&gtex_write_begin),
            (&gtex_write_end), (&gtex_write_special_char));
    if (first_syllable) {
        *first_syllable = false;
    }
    gregoriotex_ignore_style = 0;
    fprintf(f, "}");
}

/*
 * Function printing the line clef change (only updating \localleftbox, not
 * printing the key). Useful for \grediscretionary.
 * TODO: I'm not sure about the third argument, but that's how it's called in
 * \grechangeclef.
 */
static void gregoriotex_print_change_line_clef(FILE *f,
        gregorio_element *current_element)
{
    if (current_element->type == GRE_C_KEY_CHANGE) {
        if (current_element->u.misc.pitched.flatted_key) {
            fprintf(f, "\\gresetlinesclef{c}{%d}{1}{%c}%%\n",
                    current_element->u.misc.pitched.pitch - '0',
                    gregoriotex_clef_flat_height('c',
                            current_element->u.misc.pitched.pitch - '0'));
        } else {
            fprintf(f, "\\gresetlinesclef{c}{%d}{1}{%c}%%\n",
                    current_element->u.misc.pitched.pitch - 48, NO_KEY_FLAT);
        }
    }
    if (current_element->type == GRE_F_KEY_CHANGE) {
        if (current_element->u.misc.pitched.flatted_key) {
            // the third argument is 0 or 1 according to the need for a
            // space before the clef
            fprintf(f, "\\gresetlinesclef{f}{%d}{1}{%c}%%\n",
                    current_element->u.misc.pitched.pitch - '0',
                    gregoriotex_clef_flat_height('f',
                            current_element->u.misc.pitched.pitch - '0'));
        } else {
            fprintf(f, "\\gresetlinesclef{f}{%d}{1}{%c}%%\n",
                    current_element->u.misc.pitched.pitch - '0', NO_KEY_FLAT);
        }
    }
}

static void handle_final_bar(FILE *f, char *type, gregorio_syllable *syllable)
{
    fprintf(f, "\\grefinal%s{%%\n", type);
    // first element will be the bar, which we just handled, so skip it
    for (gregorio_element *element = (*syllable->elements)->next; element;
            element = element->next) {
        switch (element->type) {
        case GRE_TEXVERB_ELEMENT:
            if (element->texverb) {
                fprintf(f, "%% verbatim text at element level:\n%s%%\n"
                        "%% end of verbatim text\n", element->texverb);
            }
            break;

        case GRE_ELEMENT:
            for (gregorio_glyph *glyph = element->u.first_glyph; glyph;
                    glyph = glyph->next) {
                switch (glyph->type) {
                case GRE_MANUAL_CUSTOS:
                    fprintf(f, "\\gremanualcusto{%c}%%\n",
                            glyph->u.misc.pitched.pitch);
                    break;
                }
            }
            break;
        }
    }
    fprintf(f, "}%%\n");
}

static inline bool is_manual_custos(gregorio_element *element)
{
    return element->type == GRE_ELEMENT
            && element->u.first_glyph
            && element->u.first_glyph->type == GRE_MANUAL_CUSTOS;
}

/*
 * Arguments are relatively obvious. The most obscure is certainly first_of_disc
 * which is 0 all the time, except in the case of a "clef change syllable". In
 * this case we make a \grediscretionary with two arguments: 
 *   1.what should be printed if the syllable is the last of its line (which
 *   basically means everything but clefs and custos), and 
 *   2. what should be printed if it's in a middle of a line (which means
 *   everything)
 * So the first_of_disc argument is:
 *   0 if we don't know (general case)
 *   1 in case of the first argument of a \grediscretionary
 *   2 if we are in the second argument (necessary in order to avoid infinite loops)
 */
static void gregoriotex_write_syllable(FILE *f, gregorio_syllable *syllable,
        bool * first_syllable, unsigned char *line_number,
        unsigned char first_of_disc)
{
    gregorio_line *line;
    gregorio_element *clef_change_element = NULL;
    if (!syllable) {
        return;
    }
    // Very first: before anything, if the syllable is the beginning of a
    // no-linebreak area:
    if (syllable->no_linebreak_area == NLBA_BEGINNING) {
        fprintf(f, "\\grebeginnlbarea{1}{0}%%\n");
    }
    if (syllable->euouae == EUOUAE_BEGINNING) {
        fprintf(f, "\\grebegineuouae{}%%\n");
    }
    /*
     * first we check if the syllable is only a end of line. If it is the case,
     * we don't print anything but a comment (to be able to read it if we read
     * GregorioTeX). The end of lines are treated separately in GregorioTeX, it
     * is buit inside the TeX structure. 
     */
    if (syllable->elements && *(syllable->elements)) {
        gregoriotex_compute_positioning(*(syllable->elements));

        if ((syllable->elements)[0]->type == GRE_END_OF_LINE) {
            line = (gregorio_line *) malloc(sizeof(gregorio_line));
            gregoriotex_getlineinfos(syllable->next_syllable, line);
            if (line->additional_bottom_space == 0
                    && line->additional_top_space == 0 && line->translation == 0
                    && line->abovelinestext == 0) {
                if ((syllable->elements)[0]->u.misc.unpitched.info.sub_type !=
                        GRE_END_OF_PAR) {
                    fprintf(f, "%%\n%%\n\\grenewline %%\n%%\n%%\n");
                } else {
                    fprintf(f, "%%\n%%\n\\grenewparline %%\n%%\n%%\n");
                }
            } else {
                if ((syllable->elements)[0]->u.misc.unpitched.info.sub_type !=
                        GRE_END_OF_PAR) {
                    fprintf(f,
                            "%%\n%%\n\\grenewlinewithspace{%u}{%u}{%u}{%u}%%\n%%\n%%\n",
                            line->additional_top_space,
                            line->additional_bottom_space, line->translation,
                            line->abovelinestext);
                } else {
                    fprintf(f,
                            "%%\n%%\n\\grenewparlinewithspace{%u}{%u}{%u}{%u}%%\n%%\n%%\n",
                            line->additional_top_space,
                            line->additional_bottom_space, line->translation,
                            line->abovelinestext);
                }

            }
            free(line);
            if (*line_number == 1) {
                fprintf(f, "\\greadjustthirdline %%\n");
                *line_number = 0;
            }
            return;
        }
        /*
         * This case is not simple: if the syllable contains a clef change,
         * whether it is (c4) or (::c4) or (z0::c4), we put it in a
         * discretionary. Warning: only these three cases will have the expected
         * effect. So first we detect it: 
         */
        if (first_of_disc == 0) {   /* to avoid infinite loops */
            clef_change_element = gregoriotex_syllable_is_clef_change(syllable);
            if (clef_change_element) {
                /*
                 * In this case, the first thing to do is to change the line clef 
                 */
                gregoriotex_print_change_line_clef(f, clef_change_element);
                fprintf(f, "\\grediscretionary{%%\n");
                gregoriotex_write_syllable(f, syllable, first_syllable,
                        line_number, 1);
                fprintf(f, "}{%%\n");
                gregoriotex_write_syllable(f, syllable, first_syllable,
                        line_number, 2);
                fprintf(f, "}%%\n");
                return;
            }
        }
        if ((syllable->elements)[0]->type == GRE_BAR) {
            if (!syllable->next_syllable && !syllable->text
                    && (syllable->elements)[0]->u.misc.unpitched.info.bar ==
                    B_DIVISIO_FINALIS) {
                handle_final_bar(f, "divisiofinalis", syllable);
                return;
            }
            if (!syllable->next_syllable && !syllable->text
                    && (syllable->elements)[0]->u.misc.unpitched.info.bar ==
                    B_DIVISIO_MAIOR) {
                handle_final_bar(f, "divisiomaior", syllable);
                return;
            } else {
                fprintf(f, "\\grebarsyllable");
            }
        } else {
            fprintf(f, "\\gresyllable");
        }
    } else {
        fprintf(f, "\\gresyllable");
    }
    gregoriotex_write_text(f, syllable->text, first_syllable, THIS_SYL);
    if (syllable->position == WORD_END
            || syllable->position == WORD_ONE_SYLLABLE || !syllable->text
            || !syllable->next_syllable
            || !syllable->next_syllable->type == GRE_END_OF_LINE
            || !syllable->next_syllable->type == GRE_END_OF_PAR) {
        fprintf(f, "{1}");
    } else {
        fprintf(f, "{0}");
    }
    if (syllable->next_syllable) {
        fprintf(f, "{\\gresetnextsyllable");
        gregoriotex_write_text(f, syllable->next_syllable->text, NULL,
                NEXT_SYL);
        fprintf(f, "}{}{%d}{",
                gregoriotex_syllable_first_type(syllable->next_syllable));
    } else {
        fprintf(f, "{\\gresetnextsyllable{}{}{}}{}{0}{");
    }
    if (syllable->translation) {
        if (syllable->translation_type == TR_WITH_CENTER_BEGINNING) {
            fprintf(f, "%%\n\\grewritetranslationwithcenterbeginning{");
        } else {
            fprintf(f, "%%\n\\grewritetranslation{");
        }
        gregoriotex_write_translation(f, syllable->translation);
        fprintf(f, "}%%\n");
    }
    if (syllable->translation_type) {
        if (syllable->translation_type == TR_WITH_CENTER_END)
            fprintf(f, "%%\n\\gretranslationcenterend %%\n");
    }
    if (syllable->abovelinestext) {
        fprintf(f, "%%\n\\gresettextabovelines{%s}%%\n",
                syllable->abovelinestext);
    }
    if (gregoriotex_is_last_of_line(syllable)) {
        fprintf(f, "%%\n\\grelastofline %%\n");
    }
    if (!syllable->next_syllable) {
        fprintf(f, "%%\n\\grelastofscore %%\n");
    }
    fprintf(f, "}{%%\n");

    for (gregorio_element *element = *syllable->elements; element;
            element = element->next) {
        if (element->nabc_lines && element->nabc) {
            size_t i;
            for (i = 0; i < element->nabc_lines; i++) {
                if (element->nabc[i]) {
                    fprintf(f, "\\nabcneumes{%d}{%s}%%\n", (int)(i+1),
                            element->nabc[i]);
                }
            }
        }
        switch (element->type) {
        case GRE_SPACE:
            switch (element->u.misc.unpitched.info.space) {
            case SP_ZERO_WIDTH:
                fprintf(f, "\\greendofelement{3}{1}%%\n");
                break;
            case SP_LARGER_SPACE:
                fprintf(f, "\\greendofelement{1}{0}%%\n");
                break;
            case SP_GLYPH_SPACE:
                fprintf(f, "\\greendofelement{2}{0}%%\n");
                break;
            case SP_GLYPH_SPACE_NB:
                fprintf(f, "\\greendofelement{2}{1}%%\n");
                break;
            case SP_LARGER_SPACE_NB:
                fprintf(f, "\\greendofelement{1}{1}%%\n");
                break;
            case SP_NEUMATIC_CUT_NB:
                fprintf(f, "\\greendofelement{0}{1}%%\n");
                break;
            default:
                break;
            }
            break;

        case GRE_TEXVERB_ELEMENT:
            if (element->texverb) {
                fprintf(f, "%% verbatim text at element level:\n%s%%\n"
                        "%% end of verbatim text\n", element->texverb);
            }
            break;

        case GRE_NLBA:
            if (element->u.misc.unpitched.info.nlba == NLBA_BEGINNING) {
                fprintf(f, "\\grebeginnlbarea{0}{0}%%\n");
            } else {
                fprintf(f, "\\greendnlbarea{0}{0}%%\n");
            }
            break;

        case GRE_ALT:
            if (element->texverb) {
                fprintf(f, "\\gresettextabovelines{%s}%%\n", element->texverb);
            }
            break;

        case GRE_C_KEY_CHANGE:
            if (first_of_disc != 1) {
                /*
                 * We don't print clef changes at the end of a line 
                 */
                if (element->previous && element->previous->type == GRE_BAR) {
                    if (element->u.misc.pitched.flatted_key) {
                        // the third argument is 0 or 1 according to the need for a
                        // space before the clef
                        fprintf(f, "\\grechangeclef{c}{%d}{0}{%c}%%\n",
                                element->u.misc.pitched.pitch - '0',
                                gregoriotex_clef_flat_height('c',
                                        element->u.misc.pitched.pitch - '0'));
                    } else {
                        fprintf(f, "\\grechangeclef{c}{%d}{0}{%c}%%\n",
                                element->u.misc.pitched.pitch - '0',
                                NO_KEY_FLAT);
                    }
                } else {
                    if (element->u.misc.pitched.flatted_key) {
                        // the third argument is 0 or 1 according to the need for a
                        // space before the clef
                        fprintf(f, "\\grechangeclef{c}{%d}{1}{%c}%%\n",
                                element->u.misc.pitched.pitch - '0',
                                gregoriotex_clef_flat_height('c',
                                        element->u.misc.pitched.pitch - '0'));
                    } else {
                        fprintf(f, "\\grechangeclef{c}{%d}{1}{%c}%%\n",
                                element->u.misc.pitched.pitch - '0',
                                NO_KEY_FLAT);
                    }
                }
            }
            break;

        case GRE_F_KEY_CHANGE:
            if (first_of_disc != 1) {
                /*
                 * We don't print clef changes at the end of a line 
                 */
                if (element->previous && element->previous->type == GRE_BAR) {
                    if (element->u.misc.pitched.flatted_key) {
                        // the third argument is 0 or 1 according to the need for a
                        // space before the clef
                        fprintf(f, "\\grechangeclef{f}{%d}{0}{%c}%%\n",
                                element->u.misc.pitched.pitch - '0',
                                gregoriotex_clef_flat_height('f',
                                        element->u.misc.pitched.pitch - '0'));
                    } else {
                        fprintf(f, "\\grechangeclef{f}{%d}{0}{%c}%%\n",
                                element->u.misc.pitched.pitch - '0',
                                NO_KEY_FLAT);
                    }
                } else {
                    if (element->u.misc.pitched.flatted_key) {
                        // the third argument is 0 or 1 according to the need for a
                        // space before the clef
                        fprintf(f, "\\grechangeclef{f}{%d}{1}{%c}%%\n",
                                element->u.misc.pitched.pitch - '0',
                                gregoriotex_clef_flat_height('f',
                                        element->u.misc.pitched.pitch - '0'));
                    } else {
                        fprintf(f, "\\grechangeclef{f}{%d}{1}{%c}%%\n",
                                element->u.misc.pitched.pitch - '0',
                                NO_KEY_FLAT);
                    }
                }
            }
            break;

        case GRE_CUSTO:
            if (first_of_disc != 1) {
                /*
                 * We don't print custos before a bar at the end of a line 
                 */
                // we also print an unbreakable larger space before the custo
                fprintf(f, "\\greendofelement{1}{1}%%\n\\grecusto{%c}%%\n",
                        element->u.misc.pitched.pitch);
            }
            break;

        case GRE_BAR:
            gregoriotex_write_bar(f,
                    element->u.misc.unpitched.info.bar,
                    element->u.misc.unpitched.special_sign,
                    element->next && !is_manual_custos(element->next));
            break;

        case GRE_END_OF_LINE:
            line = (gregorio_line *) malloc(sizeof(gregorio_line));
            // here we suppose we don't have two linebreaks in the same
            // syllable
            gregoriotex_getlineinfos(syllable->next_syllable, line);
            if (line->additional_bottom_space == 0
                    && line->additional_top_space == 0 && line->translation == 0
                    && line->abovelinestext == 0) {
                if (element->u.misc.unpitched.info.sub_type != GRE_END_OF_PAR) {
                    fprintf(f, "%%\n%%\n\\grenewline %%\n%%\n%%\n");
                } else {
                    fprintf(f, "%%\n%%\n\\grenewparline %%\n%%\n%%\n");
                }
            } else {
                if (element->u.misc.unpitched.info.sub_type != GRE_END_OF_PAR) {
                    fprintf(f, "%%\n%%\n\\grenewlinewithspace"
                            "{%u}{%u}{%u}{%u}%%\n%%\n%%\n",
                            line->additional_top_space,
                            line->additional_bottom_space, line->translation,
                            line->abovelinestext);
                } else {
                    fprintf(f, "%%\n%%\n\\grenewparlinewithspace"
                            "{%u}{%u}{%u}{%u}%%\n%%\n%%\n",
                            line->additional_top_space,
                            line->additional_bottom_space, line->translation,
                            line->abovelinestext);
                }
            }
            free(line);
            if (*line_number == 1) {
                fprintf(f, "\\greadjustthirdline %%\n");
                *line_number = 0;
            }
            break;

        default:
            // there current_element->type is GRE_ELEMENT
            assert(element->type == GRE_ELEMENT);
            gregoriotex_write_element(f, syllable, element);
            if (element->next && (element->next->type == GRE_ELEMENT
                            || (element->next->next
                                    && element->next->type == GRE_ALT
                                    && element->next->next->type ==
                                    GRE_ELEMENT))) {
                fprintf(f, "\\greendofelement{0}{0}%%\n");
            }
            break;
        }
    }
    fprintf(f, "}%%\n");
    if (syllable->position == WORD_END
            || syllable->position == WORD_ONE_SYLLABLE || !syllable->text) {
        fprintf(f, "%%\n");
    }
    // Very last, if the syllable is the end of a no-linebreak area:
    if (syllable->no_linebreak_area == NLBA_END) {
        fprintf(f, "\\greendnlbarea{1}{0}%%\n");
    }
    if (syllable->euouae == EUOUAE_END) {
        fprintf(f, "\\greendeuouae{}%%\n");
    }
}

void gregoriotex_write_score(FILE *f, gregorio_score *score)
{
    gregorio_character *first_text;
    // true if it is the first syllable and false if not.
    // It is for the initial.
    bool first_syllable = false;
    char clef_letter;
    int clef_line;
    char clef_flat = NO_KEY_FLAT;
    gregorio_syllable *current_syllable;
    // the current line (as far as we know), it is always 0, it can be 1 in the
    // case of the first line of a score with a two lines initial
    unsigned char line = 0;

    gregorio_line *first_line;
    status = malloc(sizeof(gregoriotex_status));
    status->bottom_line = 0;
    status->to_modify_note = NULL;

    if (!f) {
        gregorio_message(_
                ("call with NULL file"), "gregoriotex_write_score", ERROR, 0);
        return;
    }

    if (score->number_of_voices != 1) {
        gregorio_message(_
                ("gregoriotex only works in monophony (for the moment)"),
                "gregoriotex_write_score", ERROR, 0);
    }

    fprintf(f, "%% File generated by gregorio %s\n", GREGORIO_VERSION);
    fprintf(f, "\\gregoriotexapiversion{%s}%%\n", VERSION);

    if (score->name) {
        fprintf(f, "%% Name: %s\n", score->name);
    }
    if (score->si.author) {
        fprintf(f, "%% Author: %s\n", score->si.author);
    }
    if (score->gabc_copyright) {
        fprintf(f, "%% The copyright of this gabc is: %s\n",
                score->gabc_copyright);
    }
    if (score->score_copyright) {
        fprintf(f, "%% The copyright of the score is: %s\n",
                score->score_copyright);
    }

    fprintf(f, "\\begingregorioscore%%\n");
    if (score->nabc_lines) {
        fprintf(f, "\\scorenabclines{%d}", (int)score->nabc_lines);
    }
    // if necessary, we add some bottom space to the first line
    first_line = (gregorio_line *) malloc(sizeof(gregorio_line));
    gregoriotex_getlineinfos(score->first_syllable, first_line);
    if (first_line->additional_bottom_space != 0
            || first_line->translation != 0) {
        fprintf(f, "\\grefirstlinebottomspace{%u}{%u}%%\n",
                first_line->additional_bottom_space, first_line->translation);
    }
    free(first_line);
    // we select the good font
    if (score->gregoriotex_font) {
        if (!strcmp(score->gregoriotex_font, "gregorio")) {
            fprintf(f, "\\setgregoriofont{gregorio}%%\n");
        }
        if (!strcmp(score->gregoriotex_font, "parmesan")) {
            fprintf(f, "\\setgregoriofont{parmesan}%%\n");
        }
        if (!strcmp(score->gregoriotex_font, "greciliae")) {
            fprintf(f, "\\setgregoriofont{greciliae}%%\n");
        }
    }
    if (score->mode != 0) {
        fprintf(f, "\\gregorianmode{%d}%%\n", score->mode);
    }
    // first we draw the initial (first letter) and the initial key
    if (score->initial_style == NO_INITIAL) {
        fprintf(f, "\\grenoinitial %%\n");
    } else {
        if (score->initial_style == BIG_INITIAL) {
            fprintf(f, "\\gresetbiginitial %%\n");
            line = 1;
        }
        first_text = gregorio_first_text(score);
        if (first_text) {
            fprintf(f, "\\greinitial{");
            gregorio_write_initial(first_text, f,
                    (&gtex_write_verb),
                    (&gtex_print_char),
                    (&gtex_write_begin),
                    (&gtex_write_end), (&gtex_write_special_char));
            fprintf(f, "}%%\n");
            first_syllable = true;
        }
    }
    if (score->si.manuscript_reference) {
        fprintf(f, "\\grescorereference{%s}%%\n",
                score->si.manuscript_reference);
    }
    if (score->first_voice_info) {
        gregoriotex_write_voice_info(f, score->first_voice_info);
    }
    fprintf(f, "\\grebeginnotes %%\n");
    if (score->first_voice_info) {
        gregorio_det_step_and_line_from_key(score->
                first_voice_info->initial_key, &clef_letter, &clef_line);
        if (score->first_voice_info->flatted_key) {
            clef_flat = gregoriotex_clef_flat_height(clef_letter, clef_line);
        } else {
            clef_flat = NO_KEY_FLAT;
        }
    } else {
        clef_letter = 'c';
        clef_line = 3;
        clef_flat = NO_KEY_FLAT;
    }
    fprintf(f, "\\gresetinitialclef{%c}{%d}{%c}%%\n", clef_letter, clef_line,
            clef_flat);
    current_syllable = score->first_syllable;
    while (current_syllable) {
        gregoriotex_write_syllable(f, current_syllable, &first_syllable, &line,
                0);
        current_syllable = current_syllable->next_syllable;
    }
    fprintf(f, "\\endgregorioscore %%\n\\endinput %%\n");
    free(status);
}
