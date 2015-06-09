%{
/*
 * Copyright (C) 2015 The Gregorio Project (see CONTRIBUTORS.md)
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
#include <assert.h>
#include "struct.h"
#include "unicode.h"
#include "messages.h"

#include "vowel.h"

#include "vowel-rules.h"
#include "vowel-rules-l.h"

#if ! defined lint || defined __GNUC__
# define IGNORE(e) ((void) (e))
#else
# define IGNORE(e) /* empty */
#endif

// uncomment it if you want to have an interactive shell to understand the
// details on how bison works for a certain input
//int gregorio_vowel_rulefile_debug=1;

static void gregorio_vowel_rulefile_error(const char *const filename,
        const char *const language, bool *const found,
        const char *const error_str)
{
    IGNORE(language);
    IGNORE(found);
    gregorio_messagef("gregorio_vowel_rulefile_parse", VERBOSITY_ERROR, 0,
            _("%s: %s"), filename, error_str);
}

static inline void initialize(const char *language, bool *const found)
{
    assert(language);
    *found = false;
}

// this returns false until the language *after* the desired language
static inline bool match_language(const char *language, bool *found,
        const char *const name)
{
    if (*found) {
        return true;
    }

    *found = strcmp(language, name) == 0;
    return false;
}

static inline void add(const bool *const found, void (*const fn)(const char *),
        const char *const value)
{
    if (*found) {
        fn(value);
    }
}

%}

%name-prefix "gregorio_vowel_rulefile_"
%parse-param { const char *const filename }
%parse-param { const char *const language }
%parse-param { bool *const found }
%initial-action { initialize(language, found); }

%token LANGUAGE VOWEL PREFIX SUFFIX SEMICOLON NAME CHARACTERS INVALID

%%

rules
    :
    | rules rule
    ;

rule
    : LANGUAGE NAME SEMICOLON {
                                    if (match_language(language, found, $3)) {
                                        YYACCEPT;
                                    }
                                }
    | VOWEL vowels SEMICOLON
    | PREFIX prefixes SEMICOLON
    | SUFFIX suffixes SEMICOLON
    ;

vowels
    :
    | vowels CHARACTERS         { add(found, gregorio_vowel_table_add, $2); }
    ;

prefixes
    :
    | prefixes CHARACTERS       { add(found, gregorio_prefix_table_add, $2); }
    ;

suffixes
    :
    | suffixes CHARACTERS       { add(found, gregorio_suffix_table_add, $2); }
    ;
