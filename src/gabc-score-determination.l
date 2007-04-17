%{
/*
Gregorio score determination in gabc input.
Copyright (C) 2006 Elie Roux

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/
#define YYSTYPE char *
#include "struct.h"
#include "messages.h"
#include "gabc.h"
#include "gabc-score-determination-y.h"
#include <libintl.h>
#include <stdlib.h>
char *error;
%}

%x attribute
%x score
%x notes


%option nounput
%option noyywrap
%option noyy_push_state 
%option noyy_pop_state
%option noyy_top_state
%option noyyset_extra
%option noyyget_leng
%option noyyget_in
%option noyyset_in
%option noyyget_out
%option noyyset_out
%option noyyset_lval
%option noyyget_lval
%option noyyget_debug
%option noyyset_debug
%option align

%%
<INITIAL>: {
	BEGIN(attribute);
	return COLON;
	}
<attribute>;     {
	BEGIN(INITIAL);
         return SEMICOLON;
      }
<attribute>[^;]* {
	gabc_score_determination_lval=strdup(gabc_score_determination_text);
         return ATTRIBUTE;
      }
<INITIAL>number-of-voices {
         return NUMBER_OF_VOICES;
      }
<INITIAL>name {
         return NAME;
      }
<INITIAL>initial-key {
         return INITIAL_KEY;
      }
<INITIAL>office-part {
         return OFFICE_PART;
      }
<INITIAL>anotation {
         return ANOTATION;
      }
<INITIAL>author {
         return AUTHOR;
      }
<INITIAL>date {
         return DATE;
      }
<INITIAL>manuscript {
         return MANUSCRIPT;
      }
<INITIAL>reference {
         return REFERENCE;
      }
<INITIAL>storage-place {
         return STORAGE_PLACE;
      }
<INITIAL>translator {
         return TRANSLATOR;
      }
<INITIAL>software(\ |-)used {
         return SOFTWARE_USED;
      }
<INITIAL>translation-date {
         return TRANSLATION_DATE;
      }
<INITIAL>style {
         return STYLE;
      }
<INITIAL>virgula-position {
         return VIRGULA_POSITION;
      }
<INITIAL>lilypond-preamble {
         return LILYPOND_PREAMBLE;
      }
<INITIAL>opustex-preamble {
         return OPUSTEX_PREAMBLE;
      }
<INITIAL>musixtex-preamble {
         return MUSIXTEX_PREAMBLE;
      }
<INITIAL>--(.*) {
	return VOICE_CHANGE;
	}
<INITIAL>%(%)* {
	BEGIN(score);
	return END_OF_DEFINITIONS;
	 }
<INITIAL>. {
		snprintf(error,70,gettext("unrecognized character: %c in definition part"),gabc_score_determination_text[0]);
	libgregorio_message (error,
		      "libgregorio_det_score", ERROR, 0);
	}
<score>[^\(\ \t\n]* {
	gabc_score_determination_lval=strdup(gabc_score_determination_text);
	return SYLLABLE;
	}
<score>(\ |\t|\n)+ { 
	return SPACE;
	}
<score>\( {
	BEGIN(notes);
	return OPENING_BRACKET;
	}
<notes>[^&\)]* {
gabc_score_determination_lval=strdup(gabc_score_determination_text);
	return NOTES;
	}
<notes>& {
	return VOICE_CUT;
	}
<notes>\) {
	BEGIN(score);
	return CLOSING_BRACKET;
	}
%%
