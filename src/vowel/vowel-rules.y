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

// uncomment it if you want to have an interactive shell to understand the
// details on how bison works for a certain input
//int gregorio_vowel_rulefile_debug=1;

static void gregorio_vowel_rulefile_error(const char *const error_str)
{
    gregorio_message(error_str, (const char *) "gregorio_vowel_rulefile_parse",
            VERBOSITY_ERROR, 0);
}

%}

%name-prefix "gregorio_vowel_rulefile_"

%token VOWEL PREFIX SUFFIX SEMICOLON CHARACTERS

%%

rules
    :
    | rules rule
    ;

rule
    : VOWEL vowels SEMICOLON
    | PREFIX prefixes SEMICOLON
    | SUFFIX suffixes SEMICOLON
    ;

vowels
    :
    | vowels CHARACTERS     { gregorio_vowel_table_add($2); free($2); }
    ;

prefixes
    :
    | prefixes CHARACTERS   { gregorio_prefix_table_add($2); free($2); }
    ;

suffixes
    :
    | suffixes CHARACTERS   { gregorio_suffix_table_add($2); free($2); }
    ;
