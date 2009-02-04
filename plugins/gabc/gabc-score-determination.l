%{
/*
Gregorio score determination in gabc input.
Copyright (C) 2006 Elie Roux <elie.roux@enst-bretagne.fr>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "config.h"
#define YYSTYPE char *
#include "gettext.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <gregorio/struct.h>
#include <gregorio/messages.h>

#include "gabc.h"
#include "gabc-score-determination-y.h"
%}

%x attribute
%x score
%x notes
%x verb
%x special

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
%option prefix="gabc_score_determination_"
%option outfile="gabc-score-determination-l.c"
%option noyywrap



/* The expression for attribute below is rather messy because we allow
for (a) single-line values, ending with a semicolon at end of line or a
double semicolon, (b) multi-line values, which end at a double
semicolon. */

%%
<INITIAL>^(\xBB|\xEF|\xBF)* {
//BOM written by a lot of windows softwares when they write UTF-8
}
<INITIAL>:(\ )? {
	 BEGIN(attribute);
	 return COLON;
	}
<attribute>[^;\n\r]*(;[^;\n\r]+)*((\n|\r)[^;]*(;[^;]+)*)? {
	 gabc_score_determination_lval=strdup(gabc_score_determination_text);
         return ATTRIBUTE;
      }
<attribute>;(;|\n|\r)    {
	 BEGIN(INITIAL);
         return SEMICOLON;
      }
<INITIAL>number-of-voices {
         return NUMBER_OF_VOICES;
      }
<INITIAL>name {
         return NAME;
      }
<INITIAL>score-copyright {
         return SCORE_COPYRIGHT;
      }
<INITIAL>gabc-copyright {
         return GABC_COPYRIGHT;
      }
<INITIAL>office-part {
         return OFFICE_PART;
      }
<INITIAL>occasion {
         return OCCASION;
      }
<INITIAL>meter {
         return METER;
      }
<INITIAL>commentary {
         return COMMENTARY;
      }
<INITIAL>arranger {
         return ARRANGER;
      }
<INITIAL>gabc-version {
         return GABC_VERSION;
      }
<INITIAL>initial-style {
         return INITIAL_STYLE;
      }
<INITIAL>mode {
         return MODE;
      }
<INITIAL>annotation {
         return ANNOTATION;
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
<INITIAL>manuscript-reference {
         return MANUSCRIPT_REFERENCE;
      }
<INITIAL>manuscript-storage-place {
         return MANUSCRIPT_STORAGE_PLACE;
      }
<INITIAL>book {
         return BOOK;
      }
<INITIAL>transcriber {
         return TRANSCRIBER;
      }
<INITIAL>generated-by {
         return GENERATED_BY;
      }
<INITIAL>transcription-date {
         return TRANSCRIPTION_DATE;
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
<INITIAL>gregoriotex-font {
         return GREGORIOTEX_FONT;
      }
<INITIAL>user-notes {
         return USER_NOTES;
      }
<INITIAL>--(.*) {
	return VOICE_CHANGE;
	}
<INITIAL>%(%)*(\n|\r)+ {
	BEGIN(score);
	return END_OF_DEFINITIONS;
	 }
<INITIAL>. {
    char *dirtyvar = malloc(71*sizeof(char));
	snprintf(dirtyvar,70,gettext("unrecognized character: \"%c\" in definition part"),gabc_score_determination_text[0]);
	gregorio_message (dirtyvar,
		      "libgregorio_det_score", ERROR, 0);
	}
<score>[^\{\}\(\[\]<]+ {
	gabc_score_determination_lval=strdup(gabc_score_determination_text);
	return CHARACTERS;
	}
<score><i> {
	return I_BEGINNING;
	}
<score><\/i> {
	return I_END;
	}
<score><tt> {
	return TT_BEGINNING;
	}
<score><\/tt> {
	return TT_END;
	}
<score><ul> {
	return UL_BEGINNING;
	}
<score><\/ul> {
	return UL_END;
	}
<score><b> {
	return B_BEGINNING;
	}
<score><\/b> {
	return B_END;
	}
<score><sc> {
	return SC_BEGINNING;
	}
<score><\/sc> {
	return SC_END;
	}
<score><sp> {
    BEGIN(special);
	return SP_BEGINNING;
	}
<special>[^"<\/sp>"]+ {
	gabc_score_determination_lval=strdup(gabc_score_determination_text);
	return CHARACTERS;
	}
<special><\/sp> {
    BEGIN(score);
	return SP_END;
	}
<score><v> {
	BEGIN(verb);
	return VERB_BEGINNING;
	}
<verb>[^"<\/v>"]+ {
	gabc_score_determination_lval=strdup(gabc_score_determination_text);
	return CHARACTERS;
	}
<verb><\/v> {
	BEGIN(score);
	return VERB_END;
	}
<score>\{  {
	return CENTER_BEGINNING;
	}
<score>\}  {
	return CENTER_END;
	}
<score>\[  {
	return TRANSLATION_BEGINNING;
	}
<score>\]  {
	return TRANSLATION_END;
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
<notes>\)(\ |\t|\n|\r)+ {
	BEGIN(score);
	return CLOSING_BRACKET_WITH_SPACE;
	}
%%
