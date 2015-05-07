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

#define NO_FUSION 0
#define FUSION 1

/*
 * Here are the different types, they must be the same as in squarize.py 
 */

typedef enum gtex_type {
    T_ONE_NOTE = 1,
    // two note neumes
    T_PES,
    T_PESQUADRATUM,
    T_PESQUADRATUM_LONGQUEUE,
    T_PESQUILISMA,
    T_PESQUASSUS,
    T_PESQUASSUS_LONGQUEUE,
    T_PESQUILISMAQUADRATUM,
    T_PESQUILISMAQUADRATUM_LONGQUEUE,
    T_FLEXUS,
    T_FLEXUS_NOBAR,
    T_FLEXUS_LONGQUEUE,
    T_FLEXUS_ORISCUS,
    T_FLEXUS_ORISCUS_SCAPUS,
    T_FLEXUS_ORISCUS_SCAPUS_LONGQUEUE,
    T_VIRGA_STRATA,
    // three note neumes
    T_PORRECTUS,
    T_PORRECTUS_NOBAR,
    T_TORCULUS,
    T_TORCULUS_QUILISMA,
    T_SCANDICUS, // only deminutus
    T_ANCUS, // only deminutus
    T_ANCUS_LONGQUEUE, // only deminutus
    T_SALICUS,
    T_SALICUS_LONGQUEUE,
    // four note neumes
    T_PORRECTUSFLEXUS,
    T_PORRECTUSFLEXUS_NOBAR,
    T_TORCULUS_RESUPINUS,
    T_TORCULUS_RESUPINUS_QUILISMA,
    T_TORCULUS_LIQUESCENS,
    T_TORCULUS_LIQUESCENS_QUILISMA,
    // this is a special type for the first note of a torculus resupinus flexus
    T_ONE_NOTE_TRF,
} gtex_type;

// the different types for the alignment of the notes in GregorioTeX
// these values are numbers coded into GregorioTeX
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
    // 0 or 1, indicates if there is a translation on the line
    unsigned char translation;
    unsigned char abovelinestext;   // idem
} gregorio_line;

#endif
