%{
/*
Gregorio notes determination in gabc input.
Copyright (C) 2006-2009 Elie Roux <elie.roux@telecom-bretagne.eu>

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

This file is quite huge but quite simple: it is just all the expressions you can find in gabc and the call to the right function. Lines are often enormous simply because we enable the user to put the signs in any order, for example av.'_ or a.v_', etc. for a virga with punctum mora, horizontal and vertical episemus.

*/

#include "config.h"
#include <stdio.h>
#include <ctype.h> /*for tolower*/
#include <gregorio/struct.h>
#include <gregorio/messages.h>

#include "gabc.h"

#define lex_add_note(i,shape,signs,liquescentia,h_episemus)\
	gregorio_add_note(&current_note, tolower(gabc_notes_determination_text[i]), shape, signs, liquescentia,h_episemus)

#define else_error_macro()\
      else\
      {\
        char *dirtyvar = malloc(71*sizeof(char));\
	      snprintf(dirtyvar,70,_("undefined macro used: m%d"),gabc_notes_determination_text[3]-48);\
	      gregorio_message (dirtyvar,\
		      "gabc_notes_determination", ERROR, 0);\
      }

gregorio_note *current_note;
unsigned int nbof_isolated_episemus;
char * macros[10];

%}

%option stack
%option pointer
%option nounput
%option noyy_push_state 
%option noyy_pop_state
%option noyy_top_state
%option full
%option noread
%option nomain
%option align
%option noyylineno
%option prefix="gabc_notes_determination_"
%option outfile="gabc-notes-determination-l.c"
%option noyywrap

%x texverbnote
%x texverbglyph
%x texverbelement
%x choralsign
%x comments

%%
<INITIAL>\%  {
	BEGIN(comments);
	}
<comments>(\n|\r)+  {
    BEGIN(INITIAL);
    }
<comments>[^\n\r]*  {
    //ignored
    }
<INITIAL>\[cs: {
    BEGIN(choralsign);
    }
<INITIAL>\[nm[1-9]\] {
    if (macros[gabc_notes_determination_text[3]-48])
      {
        gregorio_add_texverb_to_note(&current_note, strdup(macros[gabc_notes_determination_text[3]-48]));
      }
    else_error_macro();
    }
<INITIAL>\[gm[1-9]\] {
    if (macros[gabc_notes_determination_text[3]-48])
      {
        gregorio_add_texverb_as_note(&current_note, strdup(macros[gabc_notes_determination_text[3]-48]), GRE_TEXVERB_GLYPH);
      }
    else_error_macro();
    }
<INITIAL>\[em[1-9]\] {
    if (macros[gabc_notes_determination_text[3]-48])
      {
        gregorio_add_texverb_as_note(&current_note, strdup(macros[gabc_notes_determination_text[3]-48]), GRE_TEXVERB_ELEMENT);
      }
    else_error_macro();
    }
<INITIAL>\[nv: {
    BEGIN(texverbnote);
    }
<INITIAL>\[gv: {
    BEGIN(texverbglyph);
    }
<INITIAL>\[ev: {
    BEGIN(texverbelement);
    }
<choralsign>[^\]]+ {
	gregorio_add_cs_to_note(&current_note, strdup(gabc_notes_determination_text));
    }
<texverbnote>[^\]]+ {
	gregorio_add_texverb_to_note(&current_note, strdup(gabc_notes_determination_text));
    }
<texverbglyph>[^\]]+ {
	gregorio_add_texverb_as_note(&current_note, strdup(gabc_notes_determination_text), GRE_TEXVERB_GLYPH);
    }
<texverbelement>[^\]]+ {
	gregorio_add_texverb_as_note(&current_note, strdup(gabc_notes_determination_text), GRE_TEXVERB_ELEMENT);
    }
<texverbnote,texverbglyph,texverbelement,choralsign>\] {
	BEGIN(INITIAL);
    }
\{  {
	gregorio_add_texverb_as_note(&current_note, strdup("\\hbox to 0pt{"), GRE_TEXVERB_ELEMENT);
    }
\}  {
	gregorio_add_texverb_as_note(&current_note, strdup("\\hss%\n}%\n\\penalty 10001\\relax "), GRE_TEXVERB_ELEMENT);
    }
[\t\r\n]+      /* ignore ends of line and tabs */;
z {
	gregorio_add_special_as_note (&current_note, GRE_END_OF_LINE, GRE_END_OF_LINE);
	}
z0 {
	gregorio_add_special_as_note (&current_note, GRE_CUSTO, USELESS_VALUE);
	}
Z {
	gregorio_add_special_as_note (&current_note, GRE_END_OF_LINE, GRE_END_OF_PAR);
	}
(c|f)[1-4] {
	if (gabc_notes_determination_text[0]=='c') {
	gregorio_add_special_as_note (&current_note, GRE_C_KEY_CHANGE, gabc_notes_determination_text[1]);
	}
	else {
	gregorio_add_special_as_note (&current_note, GRE_F_KEY_CHANGE, gabc_notes_determination_text[1]);
	}
	}
(cb|fb)[1-4] {
	if (gabc_notes_determination_text[0]=='c') {
	gregorio_add_special_as_note (&current_note, GRE_C_KEY_CHANGE_FLATED, gabc_notes_determination_text[2]);
	}
	else {
	gregorio_add_special_as_note (&current_note, GRE_F_KEY_CHANGE_FLATED, gabc_notes_determination_text[2]);
	}
	}
`       {
	gregorio_add_special_as_note (&current_note, GRE_BAR, B_VIRGULA);
	}
`'       {
	gregorio_add_special_as_note (&current_note, GRE_BAR, B_VIRGULA);
	gregorio_set_signs (current_note, _V_EPISEMUS);
	}
,       {
	gregorio_add_special_as_note (&current_note, GRE_BAR, B_DIVISIO_MINIMA);
	}
,'       {
	gregorio_add_special_as_note (&current_note, GRE_BAR, B_DIVISIO_MINIMA);
	gregorio_set_signs (current_note, _V_EPISEMUS);
	}
;       {
	gregorio_add_special_as_note (&current_note, GRE_BAR, B_DIVISIO_MINOR);
	}
;1       {
	gregorio_add_special_as_note (&current_note, GRE_BAR, B_DIVISIO_MINOR_D1);
	}
;2       {
	gregorio_add_special_as_note (&current_note, GRE_BAR, B_DIVISIO_MINOR_D2);
	}
;3       {
	gregorio_add_special_as_note (&current_note, GRE_BAR, B_DIVISIO_MINOR_D3);
	}
;4       {
	gregorio_add_special_as_note (&current_note, GRE_BAR, B_DIVISIO_MINOR_D4);
	}
;5       {
	gregorio_add_special_as_note (&current_note, GRE_BAR, B_DIVISIO_MINOR_D5);
	}
;6       {
	gregorio_add_special_as_note (&current_note, GRE_BAR, B_DIVISIO_MINOR_D6);
	}
;1'       {
	gregorio_add_special_as_note (&current_note, GRE_BAR, B_DIVISIO_MINOR_D1);
	gregorio_set_signs (current_note, _V_EPISEMUS);
	}
;2'       {
	gregorio_add_special_as_note (&current_note, GRE_BAR, B_DIVISIO_MINOR_D2);
	gregorio_set_signs (current_note, _V_EPISEMUS);
	}
;3'       {
	gregorio_add_special_as_note (&current_note, GRE_BAR, B_DIVISIO_MINOR_D3);
	gregorio_set_signs (current_note, _V_EPISEMUS);
	}
;4'       {
	gregorio_add_special_as_note (&current_note, GRE_BAR, B_DIVISIO_MINOR_D4);
	gregorio_set_signs (current_note, _V_EPISEMUS);
	}
;5'       {
	gregorio_add_special_as_note (&current_note, GRE_BAR, B_DIVISIO_MINOR_D5);
	gregorio_set_signs (current_note, _V_EPISEMUS);
	}
;6'       {
	gregorio_add_special_as_note (&current_note, GRE_BAR, B_DIVISIO_MINOR_D6);
	gregorio_set_signs (current_note, _V_EPISEMUS);
	}
;'       {
	gregorio_add_special_as_note (&current_note, GRE_BAR, B_DIVISIO_MINOR);
	gregorio_set_signs (current_note, _V_EPISEMUS);
	}
:       {
	gregorio_add_special_as_note (&current_note, GRE_BAR, B_DIVISIO_MAIOR);
	}
:'       {
	gregorio_add_special_as_note (&current_note, GRE_BAR, B_DIVISIO_MAIOR);
	gregorio_set_signs (current_note, _V_EPISEMUS);
	}
::      {
	gregorio_add_special_as_note (&current_note, GRE_BAR, B_DIVISIO_FINALIS);
	}
::'      {
	gregorio_add_special_as_note (&current_note, GRE_BAR, B_DIVISIO_FINALIS);
	gregorio_set_signs (current_note, _V_EPISEMUS);
	}
U   {
    gregorio_add_special_sign (current_note, _ICTUS_A);
    }
u   {
    gregorio_add_special_sign (current_note, _ICTUS_T);
    }
r	{
    gregorio_change_shape (current_note, S_PUNCTUM_CAVUM);
    }
R	{
    gregorio_change_shape (current_note, S_LINEA_PUNCTUM);
    }
r0	{
    gregorio_change_shape (current_note, S_LINEA_PUNCTUM_CAVUM);
    }
r1	{
    gregorio_add_special_sign (current_note, _ACCENTUS);
    }
r2	{
    gregorio_add_special_sign (current_note, _ACCENTUS_REVERSUS);
    }
r3	{
    gregorio_add_special_sign (current_note, _CIRCULUS);
    }
r4	{
    gregorio_add_special_sign (current_note, _SEMI_CIRCULUS);
    }
r5	{
    gregorio_add_special_sign (current_note, _SEMI_CIRCULUS_REVERSUS);
    }
[a-mA-M]x       {
	gregorio_add_special_as_note (&current_note, GRE_FLAT, gabc_notes_determination_text[0]);
	}
[a-mA-M]#       {
	gregorio_add_special_as_note (&current_note, GRE_SHARP, gabc_notes_determination_text[0]);
	}
[a-mA-M]y       {
	gregorio_add_special_as_note (&current_note, GRE_NATURAL, gabc_notes_determination_text[0]);
	}
\/      {
	gregorio_add_special_as_note (&current_note, GRE_SPACE, SP_NEUMATIC_CUT);
	}
\/\/    {
	gregorio_add_special_as_note (&current_note, GRE_SPACE, SP_LARGER_SPACE);
	}
\       {
	gregorio_add_special_as_note (&current_note, GRE_SPACE, SP_GLYPH_SPACE);
	}
!\/      {
	gregorio_add_special_as_note (&current_note, GRE_SPACE, SP_NEUMATIC_CUT_NB);
	}
!\/\/    {
	gregorio_add_special_as_note (&current_note, GRE_SPACE, SP_LARGER_SPACE_NB);
	}
!\       {
	gregorio_add_special_as_note (&current_note, GRE_SPACE, SP_GLYPH_SPACE_NB);
	}
!/[^\/ ]       {
	gregorio_add_special_as_note (&current_note, GRE_SPACE, SP_ZERO_WIDTH);
	}
[a-mA-M]vv   {
	lex_add_note(0, S_BIVIRGA, _NO_SIGN, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M]vvv {
	lex_add_note(0, S_TRIVIRGA, _NO_SIGN, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M]VV   {
	lex_add_note(0, S_BIVIRGA, _NO_SIGN, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M]VVV {
	lex_add_note(0, S_TRIVIRGA, _NO_SIGN, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M]ss {
	lex_add_note(0, S_DISTROPHA, _NO_SIGN, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M]ss(\<|\>) {
	lex_add_note(0, S_DISTROPHA, _NO_SIGN, L_AUCTA,H_NO_EPISEMUS);
		}
[a-mA-M]sss {
	lex_add_note(0, S_TRISTROPHA, _NO_SIGN, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M]sss(\<|\>) {
	lex_add_note(0, S_TRISTROPHA, _NO_SIGN, L_AUCTA,H_NO_EPISEMUS);
		}
[a-mA-M]        {
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _NO_SIGN, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M] { 
	lex_add_note(1, gregorio_det_shape(gabc_notes_determination_text[1]), _NO_SIGN, L_INITIO_DEBILIS,H_NO_EPISEMUS);
		}
\'        {
    gregorio_add_sign(current_note, _V_EPISEMUS);
          }
_0        {
    gregorio_add_h_episemus(current_note, H_BOTTOM, &nbof_isolated_episemus);
          }
_         {
    gregorio_add_h_episemus(current_note, H_ONE, &nbof_isolated_episemus);
          }
\.        {
    gregorio_add_sign(current_note, _PUNCTUM_MORA);
          }
~         {
    gregorio_add_liquescentia(current_note, L_DEMINUTUS);
          }
>         {
    gregorio_add_liquescentia(current_note, L_AUCTUS_DESCENDENS);
          }
\<        {
    gregorio_add_liquescentia(current_note, L_AUCTUS_ASCENDENS);
          }
q         { 
	gregorio_change_shape(current_note, S_QUADRATUM);
          }
o         {
	gregorio_change_shape(current_note, S_ORISCUS);
		  }
w         {
	gregorio_change_shape(current_note, S_QUILISMA);
		  }
W         {
	gregorio_change_shape(current_note, S_QUILISMA_QUADRATUM);
		  }
(V|v)     {
	gregorio_change_shape(current_note, S_VIRGA);
		  }
s         {
	gregorio_change_shape(current_note, S_STROPHA);
		  }
.         {	
    char *dirtyvar = malloc(71*sizeof(char));
	snprintf(dirtyvar,70,_("unrecognized character: \"%c\""),gabc_notes_determination_text[0]);
	gregorio_message (dirtyvar,
		      "det_notes_from_string", ERROR, 0);
	      }

%%

void gabc_notes_determination_error(const char *str)
{
    char *dirtyvartwo = malloc(151*sizeof(char));
	  snprintf(dirtyvartwo,150,str);
    gregorio_message (dirtyvartwo, "det_notes_from_string", ERROR, 0);
}


gregorio_note *
gabc_det_notes_from_string (char *str, char *newmacros[10]) 
{
  int i;
  for (i=0;i<10;i++)
    {
      macros[i] = newmacros[i];
    }
  YY_BUFFER_STATE buf;
  current_note=NULL;
  buf=yy_scan_string(str);
  yylex();
  yy_flush_buffer(buf);
  yy_delete_buffer(buf);
  gregorio_go_to_first_note (&current_note);
  return current_note;
}

