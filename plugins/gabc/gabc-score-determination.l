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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <gregorio/struct.h>
#include <gregorio/messages.h>

#include "gabc.h"
#include "gabc-score-determination-y.h"

unsigned char style_stack = 0;
%}

%x attribute
%x score
%x notes
%x style
%x verb
%x comments
%x inicomments
%x alt

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
%option bison-bridge
%option 8bit


/* The expression for attribute below is rather messy because we allow
for (a) single-line values, ending with a semicolon at end of line or a
double semicolon, (b) multi-line values, which end at a double
semicolon. */

%%
<INITIAL>^(\xBB|\xEF|\xBF)* {
//BOM written by a lot of windows softwares when they write UTF-8
}
<INITIAL>^[\n\r]+ {
// ignoring empty lines
}
<INITIAL>^[\%#]  {
	BEGIN(inicomments);
	}
<inicomments>(\n|\r)+  {
    BEGIN(INITIAL);
    }
<inicomments>[^\n\r]*  {
    //ignored
    }
<INITIAL>:(\ )? {
	 BEGIN(attribute);
	 return COLON;
	}
<attribute>[^;\n\r]*(;[^;\n\r]+)*([\n\r]+[^;]*(;[^;]+)*)? {
	 gabc_score_determination_lval = strdup(gabc_score_determination_text);
         return ATTRIBUTE;
      }
<attribute>;(;|[\n\r]+)    {
	 BEGIN(INITIAL);
         return SEMICOLON;
      }
<INITIAL>def-m[0-9] {
         gabc_score_determination_lval=gabc_score_determination_text[5];
         return DEF_MACRO;
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
<INITIAL>centering-scheme {
         return CENTERING_SCHEME;
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
	snprintf(dirtyvar,70,_("unrecognized character: \"%c\" in definition part"),gabc_score_determination_text[0]);
	gregorio_message (dirtyvar,
		      "det_score", ERROR, 0);
	}
<score>[^\{\}\(\[\]<%]+ {
	gabc_score_determination_lval=strdup(gabc_score_determination_text);
	return CHARACTERS;
	}
<score,style><i> {
	BEGIN(style);
    style_stack ++;
	return I_BEGINNING;
	}
<score,style><nlba> {
	return BNLBA;
	}
<score,style><\/nlba> {
	return ENLBA;
	}
<style><\/i> {
    style_stack --;
    if (style_stack == 0)
      {
        BEGIN(score);
      }
	return I_END;
	}
<score,style><tt> {
	BEGIN(style);
    style_stack ++;
	return TT_BEGINNING;
	}
<style><\/tt> {
    style_stack --;
    if (style_stack == 0)
      {
        BEGIN(score);
      }
	return TT_END;
	}
<score,style><ul> {
	BEGIN(style);
    style_stack ++;
	return UL_BEGINNING;
	}
<style><\/ul> {
    style_stack --;
    if (style_stack == 0)
      {
        BEGIN(score);
      }
	return UL_END;
	}
<score,style><c> {
	BEGIN(style);
    style_stack ++;
	return C_BEGINNING;
	}
<style><\/c> {
    style_stack --;
    if (style_stack == 0)
      {
        BEGIN(score);
      }
	return C_END;
	}
<score,style><b> {
	BEGIN(style);
    style_stack ++;
	return B_BEGINNING;
	}
<style><\/b> {
    style_stack --;
    if (style_stack == 0)
      {
        BEGIN(score);
      }
	return B_END;
	}
<score,style><sc> {
	BEGIN(style);
    style_stack ++;
	return SC_BEGINNING;
	}
<style><\/sc> {
    style_stack --;
    if (style_stack == 0)
      {
        BEGIN(score);
      }
	return SC_END;
	}
<score,style><sp> {
	BEGIN(style);
    style_stack ++;
	return SP_BEGINNING;
	}
<style><\/sp> {
    style_stack --;
    if (style_stack == 0)
      {
        BEGIN(score);
      }
	return SP_END;
	}
<style>[^<\{\}]* {
	gabc_score_determination_lval=strdup(gabc_score_determination_text);
	return CHARACTERS;
	}
<score>\%  {
	BEGIN(comments);
	}
<comments>(\n|\r)+  {
    BEGIN(score);
    }
<comments>[^\n\r]*  {
    //ignored
    }
<style,score><v> {
	BEGIN(verb);
	return VERB_BEGINNING;
	}
<verb><\/v> {
    if (style_stack == 0)
      {
        BEGIN(score);
      }
    else 
      {
        BEGIN(style);
      }
	return VERB_END;
	}
<verb>[^<]* {
	gabc_score_determination_lval=strdup(gabc_score_determination_text);
	return CHARACTERS;
	}
<verb,style,score,alt>< {
	gabc_score_determination_lval=strdup(gabc_score_determination_text);
	return CHARACTERS;
	}
<score,style>\{  {
	return CENTER_BEGINNING;
	}
<score,style>\}  {
	return CENTER_END;
	}
<score><alt>  {
  BEGIN(alt);
	return ALT_BEGIN;
	}
<alt>[^<]* {
	gabc_score_determination_lval=strdup(gabc_score_determination_text);
	return CHARACTERS;
	}
<alt><\/alt>  {
  BEGIN(score);
	return ALT_END;
	}
<score>\[\/]  {
	return TRANSLATION_CENTER_END;
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

