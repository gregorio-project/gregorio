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

#ifndef GABC_H
#define GABC_H

#define GABC_CURRENT_VERSION "0.9.3"

// functions to read gabc
gregorio_note *gabc_det_notes_from_string(char *str, char *macros[10]);
gregorio_element *gabc_det_elements_from_string(char *str, int *current_key,
        char *macros[10]);
gregorio_glyph *gabc_det_glyphs_from_notes(gregorio_note *current_note,
        int *current_key);
int gabc_score_determination_lex_destroy(void);
int gabc_notes_determination_lex_destroy(void);

// see comments on gregorio_add_note_to_a_glyph for meaning of these variables
typedef enum gabc_determination {
    DET_NO_END,
    DET_END_OF_CURRENT,
    DET_END_OF_PREVIOUS,
    DET_END_OF_BOTH,
} gabc_determination;

// defines the maximal interval between two notes of the same glyph
#define MAX_INTERVAL 5

#endif
