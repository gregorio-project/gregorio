%{
/*
 * Copyright (C) 2015 The Gregorio Project (see CONTRIBUTORS.md)
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
#include <string.h>
#include "struct.h"
#include "messages.h"

#include "vowel-rules.h"
#include "vowel-rules-y.h"

#define YY_NO_INPUT
%}

%x chars

%option stack
%option pointer
%option nounput
%option noyy_push_state
%option noyy_pop_state
%option noyy_top_state
%option align
%option noread
%option nomain
%option noalways-interactive
%option nonever-interactive
%option prefix="gregorio_vowel_rulefile_"
%option noyywrap
%option 8bit

%%

<INITIAL>vowel  { BEGIN(chars); return VOWEL; }
<INITIAL>prefix { BEGIN(chars); return PREFIX; }
<INITIAL>suffix { BEGIN(chars); return SUFFIX; }
<chars>;        { BEGIN(INITIAL); return SEMICOLON; }
<*>[\ \t\n\r]   ;
<*>#[^\n\r]*    ;
<INITIAL>\xEF\xBB\xBF ;
<chars>[^;,# \t\n\r]+ {
                    gregorio_vowel_rulefile_lval =
                            strdup(gregorio_vowel_rulefile_text);
                    return CHARACTERS;
                }
<*>.            {
                    gregorio_messagef("gregorio_vowel_rulefile_lex",
                            VERBOSITY_WARNING, 0,
                            _("invalid character in vwl file: %c"),
                            *gregorio_vowel_rulefile_text);
                }

%%

