/*
 * Gregorio dump output format headers. Copyright (C) 2007-2009 Elie Roux
 * <elie.roux@telecom-bretagne.eu>
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

#ifndef DUMP_H
#define DUMP_H

#include <struct.h>

void write_score(FILE *f, gregorio_score *score);

const char *dump_key_to_char(int key);

const char *dump_syllable_position(gregorio_word_position pos);

const char *dump_type(gregorio_type type);

const char *dump_bar_type(gregorio_bar element_type);

const char *dump_space_type(gregorio_space element_type);

const char *dump_liquescentia(gregorio_liquescentia liquescentia);

const char *dump_glyph_type(gregorio_glyph_type glyph_type);

const char *dump_shape(gregorio_shape shape);

const char *dump_signs(gregorio_sign signs);

const char *dump_special_sign(gregorio_sign rare_sign);

const char *dump_h_episemus_type(gregorio_h_episemus h_episemus_type);

void dump_write_characters(FILE *f, gregorio_character *current_character);

const char *dump_style_to_string(grestyle_style style);

const char *dump_translation_type_to_string(gregorio_tr_centering
                                            translation_type);

const char *dump_nlba_to_string(gregorio_nlba no_linebreak_area);

#endif
