/*
 * Gregorio structure manipulation file. Copyright (C) 2008 Elie Roux
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

#ifndef CHARACTERS_H
#define CHARACTERS_H

/*
 * 
 * The three next defines are the possible values of center_is_determined.
 * 
 * CENTER_NOT_DETERMINED means that the plugin has encountered no { nor } (in
 * the gabc syntax). CENTER_HALF_DETERMINED means that the plugin has
 * encountered a { but no }, and we will try to determine a middle starting
 * after the {. CENTER_FULLY_DETERMINED means that lex has encountered a { and
 * a }, so we won't determine the middle, it is considered done.
 * CENTER_DETERMINING_MIDDLE is used internally in the big function to know
 * where we are in the middle determination.
 * 
 */

#define CENTER_NOT_DETERMINED 0
#define CENTER_HALF_DETERMINED 1
#define CENTER_FULLY_DETERMINED 2
#define CENTER_DETERMINING_MIDDLE 3

// two constants to know if we write old style TeX or modern utf TeX.
#define WRITE_OLD_TEX 1
#define WRITE_UTF_TEX 2

// this is a temporary structure that will be used for style determination

typedef struct det_style
{
  unsigned char style;
  struct det_style *previous_style;
  struct det_style *next_style;
} det_style;

grewchar gregorio_first_letter (gregorio_score *score);

gregorio_character *gregorio_first_text (gregorio_score *score);

int gregorio_is_vowel (grewchar letter);

void gregorio_write_text (char type, gregorio_character *current_character,
                          FILE *f, void (*printverb) (FILE *, grewchar *),
                          void (*printchar) (FILE *, grewchar),
                          void (*begin) (FILE *, unsigned char),
                          void (*end) (FILE *, unsigned char),
                          void (*printspchar) (FILE *, grewchar *));

void gregorio_write_initial (gregorio_character *current_character,
                             FILE *f, void (*printverb) (FILE *,
                                                         grewchar *),
                             void (*printchar) (FILE *, grewchar),
                             void (*begin) (FILE *, unsigned char),
                             void (*end) (FILE *, unsigned char),
                             void (*printspchar) (FILE *, grewchar *));

gregorio_character *gregorio_first_text (gregorio_score *score);

grewchar gregorio_first_letter (gregorio_score *score);

void gregorio_free_styles (det_style **first_style);

void
gregorio_insert_style_before (unsigned char type, unsigned char style,
                              gregorio_character *current_character);

void gregorio_insert_char_after (grewchar c,
                                 gregorio_character **current_character);

void gregorio_rebuild_characters (gregorio_character **param_character,
                                  char center_is_determined,
                                  unsigned char centering_scheme);

void gregorio_rebuild_first_syllable (gregorio_character **param_character);

void gregorio_write_one_tex_char_old (FILE *f, grewchar to_print);

void gregorio_write_one_tex_char (FILE *f, grewchar to_print);

void gregorio_write_one_tex_char_utf (FILE *f, grewchar to_print);

void gregorio_set_tex_write (unsigned char new);

#endif
