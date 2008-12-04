%{
/*
Gregorio notes determination in gabc input.
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

This file is quite huge but quite simple: it is just all the expressions you can find in gabc and the call to the right function. Lines are often enormous simply because we enable the user to put the signs in any order, for example av.'_ or a.v_', etc. for a virga with punctum mora, horizontal and vertical episemus.

Update (three years later): This file is a HUGE CRAP... Hardcoding everything was definitely not the right thing to do. What should be done is the following: if we encounter a sign or a letter changing the shape, we just change the current note. Why the **** did I write this file like this...
*/

#include "config.h"
#include <stdio.h>
#include <ctype.h> /*for tolower*/
#include "gettext.h"
#include <gregorio/struct.h>
#include <gregorio/messages.h>

#include "gabc.h"

#define lex_add_note(i,shape,signs,liquescentia,h_episemus)\
	gregorio_add_note(&current_note, tolower(gabc_notes_determination_text[i]), shape, signs, liquescentia,h_episemus)

gregorio_note *current_note;
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


%%
[\t\r\n]+      /* ignore ends of line and tabs */;
z {
	gregorio_add_special_as_note (&current_note, GRE_END_OF_LINE, GRE_END_OF_LINE);
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
`       {
	gregorio_add_special_as_note (&current_note, GRE_BAR, B_VIRGULA);
	}
,       {
	gregorio_add_special_as_note (&current_note, GRE_BAR, B_DIVISIO_MINIMA);
	}
;       {
	gregorio_add_special_as_note (&current_note, GRE_BAR, B_DIVISIO_MINOR);
	}
:       {
	gregorio_add_special_as_note (&current_note, GRE_BAR, B_DIVISIO_MAIOR);
	}
::      {
	gregorio_add_special_as_note (&current_note, GRE_BAR, B_DIVISIO_FINALIS);
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
[a-mA-M]y       {
	gregorio_add_special_as_note (&current_note, GRE_NATURAL, gabc_notes_determination_text[0]);
	}
!       {
	gregorio_add_special_as_note (&current_note, GRE_SPACE, SP_ZERO_WIDTH);
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
[a-mA-M]vv   {
	lex_add_note(0, S_BIVIRGA, _NO_SIGN, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M]vvv {
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
_ 	{
	gregorio_activate_isolated_h_episemus (current_note, 1);
	}
__ 	{
	gregorio_activate_isolated_h_episemus (current_note, 2);
	}
___ 	{
	gregorio_activate_isolated_h_episemus (current_note, 3);
	}
____ 	{
	gregorio_activate_isolated_h_episemus (current_note, 4);
	}
[a-mA-M]        {
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _NO_SIGN, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M]'       {
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _V_EPISEMUS, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M]\.\.    {
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M]\.      {
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](\.'|'\.)  {
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _V_EPISEMUS_PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](\.\.'|'\.\.) {
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _V_EPISEMUS_AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M]_       {
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _NO_SIGN, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](\.\._|_\.\.) {
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](\._|_\.) { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M]('_|_') { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _V_EPISEMUS, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](_\.'|_'\.|\._'|'_\.|\.'_|'\._)  { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _V_EPISEMUS_PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](_\.\.'|_'\.\.|\.\._'|'_\.\.|\.\.'_|'\.\._) { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _V_EPISEMUS_AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M]~         { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]),_NO_SIGN, L_DEMINUTUS,H_NO_EPISEMUS);
		}
[a-mA-M]('~|~') { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _V_EPISEMUS, L_DEMINUTUS,H_NO_EPISEMUS);
		}
[a-mA-M](\.\.~|~\.\.) { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _AUCTUM_DUPLEX, L_DEMINUTUS,H_NO_EPISEMUS);
		}
[a-mA-M](\.~|~\.) { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _PUNCTUM_MORA, L_DEMINUTUS,H_NO_EPISEMUS);
		}
[a-mA-M](~\.'|~'\.|\.~'|'~\.|\.'~|'\.~) { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _V_EPISEMUS_PUNCTUM_MORA, L_DEMINUTUS,H_NO_EPISEMUS);
		}
[a-mA-M](~\.\.'|~'\.\.|\.\.~'|'~\.\.|\.\.'~|'\.\.~) { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _V_EPISEMUS_AUCTUM_DUPLEX, L_DEMINUTUS,H_NO_EPISEMUS);
		}
[a-mA-M]_~         { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _NO_SIGN, L_DEMINUTUS,H_ONE);
		}
[a-mA-M](~'_|~_'|'~_|_~'|'_~|_'~) {
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _V_EPISEMUS, L_DEMINUTUS,H_ONE);
		}
[a-mA-M](~\.\._|~_\.\.|\.\.~_|_~\.\.|\.\._~|_\.\.~) { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _AUCTUM_DUPLEX, L_DEMINUTUS,H_ONE);
		}
[a-mA-M](~\._|~_\.|\.~_|_~\.|\._~|_\.~) { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _PUNCTUM_MORA, L_DEMINUTUS,H_ONE);
		}
[a-mA-M](~_\.'|~_'\.|~\._'|~'_\.|~\.'_|~'\._|_~\.'|_~'\.|\.~_'|'~_\.|\.~'_|'~\._|_\.~'|_'~\.|\._~'|'_~\.|\.'~_|'\.~_|_\.'~|_'\.~|\._'~|'_\.~|\.'_~|'\._~)  { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]),_V_EPISEMUS_PUNCTUM_MORA, L_DEMINUTUS,H_ONE);
		}
[a-mA-M](~_\.\.'|~_'\.\.|~\.\._'|~'_\.\.|~\.\.'_|~'\.\._|_~\.\.'|_~'\.\.|\.\.~_'|'~_\.\.|\.\.~'_|'~\.\._|_\.\.~'|_'~\.\.|\.\._~'|'_~\.\.|\.\.'~_|'\.\.~_|_\.\.'~|_'\.\.~|\.\._'~|'_\.\.~|\.\.'_~|'\.\._~) { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _V_EPISEMUS_AUCTUM_DUPLEX, L_DEMINUTUS,H_ONE);
		}
[a-mA-M]\>         { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _NO_SIGN, L_AUCTUS_DESCENDENS,H_NO_EPISEMUS);
		}
[a-mA-M]('\>|\>') { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]),_V_EPISEMUS, L_AUCTUS_DESCENDENS,H_NO_EPISEMUS);
		}
[a-mA-M](\.\.\>|\>\.\.) { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _AUCTUM_DUPLEX, L_AUCTUS_DESCENDENS,H_NO_EPISEMUS);
		}
[a-mA-M](\.\>|\>\.) { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _PUNCTUM_MORA, L_AUCTUS_DESCENDENS,H_NO_EPISEMUS);
		}
[a-mA-M](\>\.'|\>'\.|\.\>'|'\>\.|\.'\>|'\.\>) { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]),_V_EPISEMUS_PUNCTUM_MORA, L_AUCTUS_DESCENDENS,H_NO_EPISEMUS);
		}
[a-mA-M](\>\.\.'|\>'\.\.|\.\.\>'|'\>\.\.|\.\.'\>|'\.\.\>) { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]),_V_EPISEMUS_AUCTUM_DUPLEX, L_AUCTUS_DESCENDENS,H_NO_EPISEMUS);
		}
[a-mA-M](_\>|\>_)         { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _NO_SIGN, L_AUCTUS_DESCENDENS,H_ONE);
		}
[a-mA-M](\>'_|\>_'|'\>_|_\>'|'_\>|_'\>) { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _V_EPISEMUS, L_AUCTUS_DESCENDENS,H_ONE);
		}
[a-mA-M](\>\.\._|\>_\.\.|\.\.\>_|_\>\.\.|\.\._\>|_\.\.\>) { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _AUCTUM_DUPLEX, L_AUCTUS_DESCENDENS,H_ONE);
		}
[a-mA-M](\>\._|\>_\.|\.\>_|_\>\.|\._\>|_\.\>) { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _PUNCTUM_MORA, L_AUCTUS_DESCENDENS,H_ONE);
		}
[a-mA-M](\>_\.'|\>_'\.|\>\._'|\>'_\.|\>\.'_|\>'\._|_\>\.'|_\>'\.|\.\>_'|'\>_\.|\.\>'_|'\>\._|_\.\>'|_'\>\.|\._\>'|'_\>\.|\.'\>_|'\.\>_|_\.'\>|_'\.\>|\._'\>|'_\.\>|\.'_\>|'\._\>)  { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _V_EPISEMUS_PUNCTUM_MORA, L_AUCTUS_DESCENDENS,H_ONE);
		}
[a-mA-M](\>_\.\.'|\>_'\.\.|\>\.\._'|\>'_\.\.|\>\.\.'_|\>'\.\._|_\>\.\.'|_\>'\.\.|\.\.\>_'|'\>_\.\.|\.\.\>'_|'\>\.\._|_\.\.\>'|_'\>\.\.|\.\._\>'|'_\>\.\.|\.\.'\>_|'\.\.\>_|_\.\.'\>|_'\.\.\>|\.\._'\>|'_\.\.\>|\.\.'_\>|'\.\._\>) { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _V_EPISEMUS_AUCTUM_DUPLEX, L_AUCTUS_DESCENDENS,H_ONE);
		}
[a-mA-M]\< { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _NO_SIGN, L_AUCTUS_ASCENDENS,H_NO_EPISEMUS);
		}
[a-mA-M]('\<|\<') { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _V_EPISEMUS, L_AUCTUS_ASCENDENS,H_NO_EPISEMUS);
		}
[a-mA-M](\.\.\<|\<\.\.) { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _AUCTUM_DUPLEX, L_AUCTUS_ASCENDENS,H_NO_EPISEMUS);
		}
[a-mA-M](\.\<|\<\.) { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _PUNCTUM_MORA, L_AUCTUS_ASCENDENS,H_NO_EPISEMUS);
		}
[a-mA-M](\<\.'|\<'\.|\.\<'|'\<\.|\.'\<|'\.\<) { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _V_EPISEMUS_PUNCTUM_MORA, L_AUCTUS_ASCENDENS,H_NO_EPISEMUS);
		}
[a-mA-M](\<\.\.'|\<'\.\.|\.\.\<'|'\<\.\.|\.\.'\<|'\.\.\<) { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _V_EPISEMUS_AUCTUM_DUPLEX, L_AUCTUS_ASCENDENS,H_NO_EPISEMUS);
		}
[a-mA-M](_\<|\<_) { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _NO_SIGN, L_AUCTUS_ASCENDENS,H_ONE);
		}
[a-mA-M](\<\.\._|\<_\.\.|\.\.\<_|_\<\.\.|\.\._\<|_\.\.\<) { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _AUCTUM_DUPLEX, L_AUCTUS_ASCENDENS,H_ONE);
		}
[a-mA-M](\<'_|\<_'|'\<_|_\<'|'_\<|_'\<) { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _V_EPISEMUS, L_AUCTUS_ASCENDENS,H_ONE);
		}
[a-mA-M](\<\._|\<_\.|\.\<_|_\<\.|\._\<|_\.\<) { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _PUNCTUM_MORA, L_AUCTUS_ASCENDENS,H_ONE);
		}
[a-mA-M](\<_\.'|\<_'\.|\<\._'|\<'_\.|\<\.'_|\<'\._|_\<\.'|_\<'\.|\.\<_'|'\<_\.|\.\<'_|'\<\._|_\.\<'|_'\<\.|\._\<'|'_\<\.|\.'\<_|'\.\<_|_\.'\<|_'\.\<|\._'\<|'_\.\<|\.'_\<|'\._\<)  { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _V_EPISEMUS_PUNCTUM_MORA, L_AUCTUS_ASCENDENS,H_ONE);
		}
[a-mA-M](\<_\.\.'|\<_'\.\.|\<\.\._'|\<'_\.\.|\<\.\.'_|\<'\.\._|_\<\.\.'|_\<'\.\.|\.\.\<_'|'\<_\.\.|\.\.\<'_|'\<\.\._|_\.\.\<'|_'\<\.\.|\.\._\<'|'_\<\.\.|\.\.'\<_|'\.\.\<_|_\.\.'\<|_'\.\.\<|\.\._'\<|'_\.\.\<|\.\.'_\<|'\.\._\<) { 
	lex_add_note(0, gregorio_det_shape(gabc_notes_determination_text[0]), _V_EPISEMUS_AUCTUM_DUPLEX, L_AUCTUS_ASCENDENS,H_ONE);
		}
-[a-mA-M] { 
	lex_add_note(1, gregorio_det_shape(gabc_notes_determination_text[1]), _NO_SIGN, L_INITIO_DEBILIS,H_NO_EPISEMUS);
		}
-[a-mA-M]' { 
	lex_add_note(1, gregorio_det_shape(gabc_notes_determination_text[1]), _V_EPISEMUS, L_INITIO_DEBILIS,H_NO_EPISEMUS);
		}
-[a-mA-M]\.\. { 
	lex_add_note(1, gregorio_det_shape(gabc_notes_determination_text[1]), _AUCTUM_DUPLEX, L_INITIO_DEBILIS,H_NO_EPISEMUS);
		}
-[a-mA-M]\. { 
	lex_add_note(1, gregorio_det_shape(gabc_notes_determination_text[1]), _PUNCTUM_MORA, L_INITIO_DEBILIS,H_NO_EPISEMUS);
		}
-[a-mA-M](\.'|'\.) { 
	lex_add_note(1, gregorio_det_shape(gabc_notes_determination_text[1]), _V_EPISEMUS_PUNCTUM_MORA, L_INITIO_DEBILIS,H_NO_EPISEMUS);;
		}
-[a-mA-M](\.\.'|'\.\.) { 
	lex_add_note(1, gregorio_det_shape(gabc_notes_determination_text[1]), _V_EPISEMUS_AUCTUM_DUPLEX, L_INITIO_DEBILIS,H_NO_EPISEMUS);
		}
-[a-mA-M]_ { 
	lex_add_note(1, gregorio_det_shape(gabc_notes_determination_text[1]), _NO_SIGN, L_INITIO_DEBILIS,H_ONE);
		}
-[a-mA-M]('_|_') { 
	lex_add_note(1, gregorio_det_shape(gabc_notes_determination_text[1]),_V_EPISEMUS, L_INITIO_DEBILIS,H_ONE);
		}
-[a-mA-M](\.\._|_\.\.) { 
	lex_add_note(1, gregorio_det_shape(gabc_notes_determination_text[1]),_AUCTUM_DUPLEX, L_INITIO_DEBILIS,H_ONE);
		}
-[a-mA-M](\._|_\.) { 
	lex_add_note(1, gregorio_det_shape(gabc_notes_determination_text[1]), _PUNCTUM_MORA, L_INITIO_DEBILIS,H_ONE);
		}
-[a-mA-M](_\.'|_'\.|\._'|'_\.|\.'_|'\._) { 
	lex_add_note(1, gregorio_det_shape(gabc_notes_determination_text[1]), _V_EPISEMUS_PUNCTUM_MORA, L_INITIO_DEBILIS,H_ONE);
		}
-[a-mA-M](_\.\.'|_'\.\.|\.\._'|'_\.\.|\.\.'_|'\.\._) { 
	lex_add_note(1, gregorio_det_shape(gabc_notes_determination_text[1]), _V_EPISEMUS_AUCTUM_DUPLEX, L_INITIO_DEBILIS,H_ONE);
		}
[a-mA-M]q         { 
	lex_add_note(0, S_QUADRATUM, _NO_SIGN, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M]('q|q') { 
	lex_add_note(0, S_QUADRATUM, _V_EPISEMUS, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](\.\.q|q\.\.) { 
	lex_add_note(0, S_QUADRATUM, _AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](\.q|q\.) { 
	lex_add_note(0, S_QUADRATUM, _PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](q\.'|q'\.|\.q'|'q\.|\.'q|'\.q) { 
	lex_add_note(0, S_QUADRATUM, _V_EPISEMUS_PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](q\.\.'|q'\.\.|\.\.q'|'q\.\.|\.\.'q|'\.\.q) { 
	lex_add_note(0, S_QUADRATUM, _V_EPISEMUS_AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](_q|q_)      { 
	lex_add_note(0, S_QUADRATUM, _NO_SIGN, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](q'_|q_'|'q_|_q'|'_q|_'q) { 
	lex_add_note(0, S_QUADRATUM, _V_EPISEMUS, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](q\.\._|q_\.\.|\.\.q_|_q\.\.|\.\._q|_\.\.q) { 
	lex_add_note(0, S_QUADRATUM, _AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](q\._|q_\.|\.q_|_q\.|\._q|_\.q) { 
	lex_add_note(0, S_QUADRATUM, _PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](q_\.'|q_'\.|q\._'|q'_\.|q\.'_|q'\._|_q\.'|_q'\.|\.q_'|'q_\.|\.q'_|'q\._|_\.q'|_'q\.|\._q'|'_q\.|\.'q_|'\.q_|_\.'q|_'\.q|\._'q|'_\.q|\.'_q|'\._q)  { 
	lex_add_note(0, S_QUADRATUM, _V_EPISEMUS_PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](q_\.\.'|q_'\.\.|q\.\._'|q'_\.\.|q\.\.'_|q'\.\._|_q\.\.'|_q'\.\.|\.\.q_'|'q_\.\.|\.\.q'_|'q\.\._|_\.\.q'|_'q\.\.|\.\._q'|'_q\.\.|\.\.'q_|'\.\.q_|_\.\.'q|_'\.\.q|\.\._'q|'_\.\.q|\.\.'_q|'\.\._q) { 
	lex_add_note(0, S_QUADRATUM, _V_EPISEMUS_AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M]q         { 
	lex_add_note(1, gregorio_det_shape(gabc_notes_determination_text[1]), _NO_SIGN, L_INITIO_DEBILIS,H_NO_EPISEMUS);
		}
-[a-mA-M]('q|q') {
	lex_add_note(1, gregorio_det_shape(gabc_notes_determination_text[1]), _V_EPISEMUS, L_INITIO_DEBILIS,H_NO_EPISEMUS);
		}
-[a-mA-M](\.\.q|q\.\.) {
	lex_add_note(1, gregorio_det_shape(gabc_notes_determination_text[1]), _AUCTUM_DUPLEX, L_INITIO_DEBILIS,H_NO_EPISEMUS);
		}
-[a-mA-M](\.q|q\.) {
	lex_add_note(1, gregorio_det_shape(gabc_notes_determination_text[1]), _PUNCTUM_MORA, L_INITIO_DEBILIS,H_NO_EPISEMUS);
		}
-[a-mA-M](q\.'|q'\.|\.q'|'q\.|\.'q|'\.q) {
	lex_add_note(1, gregorio_det_shape(gabc_notes_determination_text[1]), _V_EPISEMUS_PUNCTUM_MORA, L_INITIO_DEBILIS,H_NO_EPISEMUS);
		}
-[a-mA-M](q\.\.'|q'\.\.|\.\.q'|'q\.\.|\.\.'q|'\.\.q) {
	lex_add_note(1, gregorio_det_shape(gabc_notes_determination_text[1]), _V_EPISEMUS_AUCTUM_DUPLEX, L_INITIO_DEBILIS,H_NO_EPISEMUS);
		}
-[a-mA-M](_q|q_)         { 
	lex_add_note(1, gregorio_det_shape(gabc_notes_determination_text[1]), _NO_SIGN, L_INITIO_DEBILIS,H_ONE);
		}
-[a-mA-M](q'_|q_'|'q_|_q'|'_q|_'q) {
	lex_add_note(1, gregorio_det_shape(gabc_notes_determination_text[1]), _V_EPISEMUS, L_INITIO_DEBILIS,H_ONE);
		}
-[a-mA-M](q\.\._|q_\.\.|\.\.q_|_q\.\.|\.\._q|_\.\.q) {
	lex_add_note(1, gregorio_det_shape(gabc_notes_determination_text[1]), _AUCTUM_DUPLEX, L_INITIO_DEBILIS,H_ONE);
		}
-[a-mA-M](q\._|q_\.|\.q_|_q\.|\._q|_\.q) {
	lex_add_note(1, gregorio_det_shape(gabc_notes_determination_text[1]), _PUNCTUM_MORA, L_INITIO_DEBILIS,H_ONE);
		}
-[a-mA-M](q_\.'|q_'\.|q\._'|q'_\.|q\.'_|q'\._|_q\.'|_q'\.|\.q_'|'q_\.|\.q'_|'q\._|_\.q'|_'q\.|\._q'|'_q\.|\.'q_|'\.q_|_\.'q|_'\.q|\._'q|'_\.q|\.'_q|'\._q)  {
	lex_add_note(1, gregorio_det_shape(gabc_notes_determination_text[1]), _V_EPISEMUS_PUNCTUM_MORA, L_INITIO_DEBILIS,H_ONE);
		}
-[a-mA-M](q_\.\.'|q_'\.\.|q\.\._'|q'_\.\.|q\.\.'_|q'\.\._|_q\.\.'|_q'\.\.|\.\.q_'|'q_\.\.|\.\.q'_|'q\.\._|_\.\.q'|_'q\.\.|\.\._q'|'_q\.\.|\.\.'q_|'\.\.q_|_\.\.'q|_'\.\.q|\.\._'q|'_\.\.q|\.\.'_q|'\.\._q) {
	lex_add_note(1, gregorio_det_shape(gabc_notes_determination_text[1]), _V_EPISEMUS_AUCTUM_DUPLEX, L_INITIO_DEBILIS,H_ONE);
		}
[a-mA-M]o         {
	lex_add_note(0, S_ORISCUS, _NO_SIGN, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M]('o|o') {
	lex_add_note(0, S_ORISCUS, _V_EPISEMUS, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](\.\.o|o\.\.) {
	lex_add_note(0, S_ORISCUS, _AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](\.o|o\.) {
	lex_add_note(0, S_ORISCUS, _PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](o\.'|o'\.|\.o'|'o\.|\.'o|'\.o) {
	lex_add_note(0, S_ORISCUS, _V_EPISEMUS_PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](o\.\.'|o'\.\.|\.\.o'|'o\.\.|\.\.'o|'\.\.o) {
	lex_add_note(0, S_ORISCUS, _V_EPISEMUS_AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](_o|o_)         {
	lex_add_note(0, S_ORISCUS, _NO_SIGN, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](o'_|o_'|'o_|_o'|'_o|_'o) {
	lex_add_note(0, S_ORISCUS, _V_EPISEMUS, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](o\.\._|o_\.\.|\.\.o_|_o\.\.|\.\._o|_\.\.o) {
	lex_add_note(0, S_ORISCUS, _AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](o\._|o_\.|\.o_|_o\.|\._o|_\.o) {
	lex_add_note(0, S_ORISCUS, _PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](o_\.'|o_'\.|o\._'|o'_\.|o\.'_|o'\._|_o\.'|_o'\.|\.o_'|'o_\.|\.o'_|'o\._|_\.o'|_'o\.|\._o'|'_o\.|\.'o_|'\.o_|_\.'o|_'\.o|\._'o|'_\.o|\.'_o|'\._o)  {
	lex_add_note(0, S_ORISCUS, _V_EPISEMUS_PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](o_\.\.'|o_'\.\.|o\.\._'|o'_\.\.|o\.\.'_|o'\.\._|_o\.\.'|_o'\.\.|\.\.o_'|'o_\.\.|\.\.o'_|'o\.\._|_\.\.o'|_'o\.\.|\.\._o'|'_o\.\.|\.\.'o_|'\.\.o_|_\.\.'o|_'\.\.o|\.\._'o|'_\.\.o|\.\.'_o|'\.\._o) {
	lex_add_note(0, S_ORISCUS, _V_EPISEMUS_AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M]o         {
	lex_add_note(1, S_ORISCUS, _NO_SIGN, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M]('o|o') {
	lex_add_note(1, S_ORISCUS, _V_EPISEMUS, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M](\.\.o|o\.\.) {
	lex_add_note(1, S_ORISCUS, _AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M](\.o|o\.) {
	lex_add_note(1, S_ORISCUS, _PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M](o\.'|o'\.|\.o'|'o\.|\.'o|'\.o) {
	lex_add_note(1, S_ORISCUS, _V_EPISEMUS_PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M](o\.\.'|o'\.\.|\.\.o'|'o\.\.|\.\.'o|'\.\.o) {
	lex_add_note(1, S_ORISCUS, _V_EPISEMUS_AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M](_o|o_)         {
	lex_add_note(1, S_ORISCUS, _NO_SIGN, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M](o'_|o_'|'o_|_o'|'_o|_'o) {
	lex_add_note(1, S_ORISCUS, _V_EPISEMUS, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M](o\.\._|o_\.\.|\.\.o_|_o\.\.|\.\._o|_\.\.o) {
	lex_add_note(1, S_ORISCUS, _AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M](o\._|o_\.|\.o_|_o\.|\._o|_\.o) {
	lex_add_note(1, S_ORISCUS, _PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M](o_\.'|o_'\.|o\._'|o'_\.|o\.'_|o'\._|_o\.'|_o'\.|\.o_'|'o_\.|\.o'_|'o\._|_\.o'|_'o\.|\._o'|'_o\.|\.'o_|'\.o_|_\.'o|_'\.o|\._'o|'_\.o|\.'_o|'\._o)  {
	lex_add_note(1, S_ORISCUS, _V_EPISEMUS_PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M](o_\.\.'|o_'\.\.|o\.\._'|o'_\.\.|o\.\.'_|o'\.\._|_o\.\.'|_o'\.\.|\.\.o_'|'o_\.\.|\.\.o'_|'o\.\._|_\.\.o'|_'o\.\.|\.\._o'|'_o\.\.|\.\.'o_|'\.\.o_|_\.\.'o|_'\.\.o|\.\._'o|'_\.\.o|\.\.'_o|'\.\._o) {
	lex_add_note(1, S_ORISCUS, _V_EPISEMUS_AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M]((\<|\>)o|o(\<|\>))        {
	lex_add_note(0, S_ORISCUS_AUCTUS, _NO_SIGN, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](o'(\<|\>)|o(\<|\>)'|'o(\<|\>)|(\<|\>)o'|'(\<|\>)o|(\<|\>)'o) {
	lex_add_note(0, S_ORISCUS_AUCTUS, _V_EPISEMUS, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](o\.\.(\<|\>)|o(\<|\>)\.\.|\.\.o(\<|\>)|(\<|\>)o\.\.|\.\.(\<|\>)o|(\<|\>)\.\.o) {
	lex_add_note(0, S_ORISCUS_AUCTUS, _AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](o\.(\<|\>)|o(\<|\>)\.|\.o(\<|\>)|(\<|\>)o\.|\.(\<|\>)o|(\<|\>)\.o) {
	lex_add_note(0, S_ORISCUS_AUCTUS, _PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](o(\<|\>)\.'|o(\<|\>)'\.|o\.(\<|\>)'|o'(\<|\>)\.|o\.'(\<|\>)|o'\.(\<|\>)|(\<|\>)o\.'|(\<|\>)o'\.|\.o(\<|\>)'|'o(\<|\>)\.|\.o'(\<|\>)|'o\.(\<|\>)|(\<|\>)\.o'|(\<|\>)'o\.|\.(\<|\>)o'|'(\<|\>)o\.|\.'o(\<|\>)|'\.o(\<|\>)|(\<|\>)\.'o|(\<|\>)'\.o|\.(\<|\>)'o|'(\<|\>)\.o|\.'(\<|\>)o|'\.(\<|\>)o) {
	lex_add_note(0, S_ORISCUS_AUCTUS,_V_EPISEMUS_PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](o(\<|\>)\.\.'|o(\<|\>)'\.\.|o\.\.(\<|\>)'|o'(\<|\>)\.\.|o\.\.'(\<|\>)|o'\.\.(\<|\>)|(\<|\>)o\.\.'|(\<|\>)o'\.\.|\.\.o(\<|\>)'|'o(\<|\>)\.\.|\.\.o'(\<|\>)|'o\.\.(\<|\>)|(\<|\>)\.\.o'|(\<|\>)'o\.\.|\.\.(\<|\>)o'|'(\<|\>)o\.\.|\.\.'o(\<|\>)|'\.\.o(\<|\>)|(\<|\>)\.\.'o|(\<|\>)'\.\.o|\.\.(\<|\>)'o|'(\<|\>)\.\.o|\.\.'(\<|\>)o|'\.\.(\<|\>)o) {
	lex_add_note(0, S_ORISCUS_AUCTUS, _V_EPISEMUS_AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](o_(\<|\>)|o(\<|\>)_|_o(\<|\>)|(\<|\>)o_|_(\<|\>)o|(\<|\>)_o)        {
	lex_add_note(0, S_ORISCUS_AUCTUS, _NO_SIGN, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](o(\<|\>)_'|o(\<|\>)'_|o_(\<|\>)'|o'(\<|\>)_|o_'(\<|\>)|o'_(\<|\>)|(\<|\>)o_'|(\<|\>)o'_|_o(\<|\>)'|'o(\<|\>)_|_o'(\<|\>)|'o_(\<|\>)|(\<|\>)_o'|(\<|\>)'o_|_(\<|\>)o'|'(\<|\>)o_|_'o(\<|\>)|'_o(\<|\>)|(\<|\>)_'o|(\<|\>)'_o|_(\<|\>)'o|'(\<|\>)_o|_'(\<|\>)o|'_(\<|\>)o) {
	lex_add_note(0, S_ORISCUS_AUCTUS,_V_EPISEMUS, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](o(\<|\>)\.\._|o(\<|\>)_\.\.|o\.\.(\<|\>)_|o_(\<|\>)\.\.|o\.\._(\<|\>)|o_\.\.(\<|\>)|(\<|\>)o\.\._|(\<|\>)o_\.\.|\.\.o(\<|\>)_|_o(\<|\>)\.\.|\.\.o_(\<|\>)|_o\.\.(\<|\>)|(\<|\>)\.\.o_|(\<|\>)_o\.\.|\.\.(\<|\>)o_|_(\<|\>)o\.\.|\.\._o(\<|\>)|_\.\.o(\<|\>)|(\<|\>)\.\._o|(\<|\>)_\.\.o|\.\.(\<|\>)_o|_(\<|\>)\.\.o|\.\._(\<|\>)o|_\.\.(\<|\>)o) {
	lex_add_note(0, S_ORISCUS_AUCTUS, _AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](o(\<|\>)\._|o(\<|\>)_\.|o\.(\<|\>)_|o_(\<|\>)\.|o\._(\<|\>)|o_\.(\<|\>)|(\<|\>)o\._|(\<|\>)o_\.|\.o(\<|\>)_|_o(\<|\>)\.|\.o_(\<|\>)|_o\.(\<|\>)|(\<|\>)\.o_|(\<|\>)_o\.|\.(\<|\>)o_|_(\<|\>)o\.|\._o(\<|\>)|_\.o(\<|\>)|(\<|\>)\._o|(\<|\>)_\.o|\.(\<|\>)_o|_(\<|\>)\.o|\._(\<|\>)o|_\.(\<|\>)o) {
	lex_add_note(0, S_ORISCUS_AUCTUS, _PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](o(\<|\>)_\.'|o(\<|\>)_'\.|o(\<|\>)\._'|o(\<|\>)'_\.|o(\<|\>)\.'_|o(\<|\>)'\._|o_(\<|\>)\.'|o_(\<|\>)'\.|o\.(\<|\>)_'|o'(\<|\>)_\.|o\.(\<|\>)'_|o'(\<|\>)\._|o_\.(\<|\>)'|o_'(\<|\>)\.|o\._(\<|\>)'|o'_(\<|\>)\.|o\.'(\<|\>)_|o'\.(\<|\>)_|o_\.'(\<|\>)|o_'\.(\<|\>)|o\._'(\<|\>)|o'_\.(\<|\>)|o\.'_(\<|\>)|o'\._(\<|\>)|(\<|\>)o_\.'|(\<|\>)o_'\.|(\<|\>)o\._'|(\<|\>)o'_\.|(\<|\>)o\.'_|(\<|\>)o'\._|_o(\<|\>)\.'|_o(\<|\>)'\.|\.o(\<|\>)_'|'o(\<|\>)_\.|\.o(\<|\>)'_|'o(\<|\>)\._|_o\.(\<|\>)'|_'o(\<|\>)\.|\._o(\<|\>)'|'_o(\<|\>)\.|\.'o(\<|\>)_|'\.o(\<|\>)_|_\.o'(\<|\>)|_'o\.(\<|\>)|\._o'(\<|\>)|'_o\.(\<|\>)|\.'o_(\<|\>)|'\.o_(\<|\>)|(\<|\>)_\.o'|(\<|\>)_o'\.|(\<|\>)\.o_'|(\<|\>)'o_\.|(\<|\>)\.o'_|(\<|\>)'o\._|_(\<|\>)o\.'|_(\<|\>)o'\.|\.(\<|\>)o_'|'(\<|\>)o_\.|\.(\<|\>)o'_|'(\<|\>)o\._|_\.o(\<|\>)'|_'o(\<|\>)\.|\._o(\<|\>)'|'_o(\<|\>)\.|\.'o(\<|\>)_|'\.o(\<|\>)_|_\.o'(\<|\>)|_'o\.(\<|\>)|\._o'(\<|\>)|'_o\.(\<|\>)|\.'o_(\<|\>)|'\.o_(\<|\>)|(\<|\>)_\.o'|(\<|\>)_'o\.|(\<|\>)\._o'|(\<|\>)'_o\.|(\<|\>)\.'o_|(\<|\>)'\.o_|_(\<|\>)\.o'|_(\<|\>)'o\.|\.(\<|\>)_o'|'(\<|\>)_o\.|\.(\<|\>)'o_|'(\<|\>)\.o_|_\.(\<|\>)o'|_'(\<|\>)o\.|\._(\<|\>)o'|'_(\<|\>)o\.|\.'(\<|\>)o_|'\.(\<|\>)o_|_\.'o(\<|\>)|_'\.o(\<|\>)|\._'o(\<|\>)|'_\.o(\<|\>)|\.'_o(\<|\>)|'\._o(\<|\>)|(\<|\>)_\.'o|(\<|\>)_'\.o|(\<|\>)\._'o|(\<|\>)'_\.o|(\<|\>)\.'_o|(\<|\>)'\._o|_(\<|\>)\.'o|_(\<|\>)'\.o|\.(\<|\>)_'o|'(\<|\>)_\.o|\.(\<|\>)'_o|'(\<|\>)\._o|_\.(\<|\>)'o|_'(\<|\>)\.o|\._(\<|\>)'o|'_(\<|\>)\.o|\.'(\<|\>)_o|'\.(\<|\>)_o|_\.'(\<|\>)o|_'\.(\<|\>)o|\._'(\<|\>)o|'_\.(\<|\>)o|\.'_(\<|\>)o|'\._(\<|\>)o)  {
	lex_add_note(0, S_ORISCUS_AUCTUS, _V_EPISEMUS_PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](o(\<|\>)_\.\.'|o(\<|\>)_'\.\.|o(\<|\>)\.\._'|o(\<|\>)'_\.\.|o(\<|\>)\.\.'_|o(\<|\>)'\.\._|o_(\<|\>)\.\.'|o_(\<|\>)'\.\.|o\.\.(\<|\>)_'|o'(\<|\>)_\.\.|o\.\.(\<|\>)'_|o'(\<|\>)\.\._|o_\.\.(\<|\>)'|o_'(\<|\>)\.\.|o\.\._(\<|\>)'|o'_(\<|\>)\.\.|o\.\.'(\<|\>)_|o'\.\.(\<|\>)_|o_\.\.'(\<|\>)|o_'\.\.(\<|\>)|o\.\._'(\<|\>)|o'_\.\.(\<|\>)|o\.\.'_(\<|\>)|o'\.\._(\<|\>)|(\<|\>)o_\.\.'|(\<|\>)o_'\.\.|(\<|\>)o\.\._'|(\<|\>)o'_\.\.|(\<|\>)o\.\.'_|(\<|\>)o'\.\._|_o(\<|\>)\.\.'|_o(\<|\>)'\.\.|\.\.o(\<|\>)_'|'o(\<|\>)_\.\.|\.\.o(\<|\>)'_|'o(\<|\>)\.\._|_o\.\.(\<|\>)'|_'o(\<|\>)\.\.|\.\._o(\<|\>)'|'_o(\<|\>)\.\.|\.\.'o(\<|\>)_|'\.\.o(\<|\>)_|_\.\.o'(\<|\>)|_'o\.\.(\<|\>)|\.\._o'(\<|\>)|'_o\.\.(\<|\>)|\.\.'o_(\<|\>)|'\.\.o_(\<|\>)|(\<|\>)_\.\.o'|(\<|\>)_o'\.\.|(\<|\>)\.\.o_'|(\<|\>)'o_\.\.|(\<|\>)\.\.o'_|(\<|\>)'o\.\._|_(\<|\>)o\.\.'|_(\<|\>)o'\.\.|\.\.(\<|\>)o_'|'(\<|\>)o_\.\.|\.\.(\<|\>)o'_|'(\<|\>)o\.\._|_\.\.o(\<|\>)'|_'o(\<|\>)\.\.|\.\._o(\<|\>)'|'_o(\<|\>)\.\.|\.\.'o(\<|\>)_|'\.\.o(\<|\>)_|_\.\.o'(\<|\>)|_'o\.\.(\<|\>)|\.\._o'(\<|\>)|'_o\.\.(\<|\>)|\.\.'o_(\<|\>)|'\.\.o_(\<|\>)|(\<|\>)_\.\.o'|(\<|\>)_'o\.\.|(\<|\>)\.\._o'|(\<|\>)'_o\.\.|(\<|\>)\.\.'o_|(\<|\>)'\.\.o_|_(\<|\>)\.\.o'|_(\<|\>)'o\.\.|\.\.(\<|\>)_o'|'(\<|\>)_o\.\.|\.\.(\<|\>)'o_|'(\<|\>)\.\.o_|_\.\.(\<|\>)o'|_'(\<|\>)o\.\.|\.\._(\<|\>)o'|'_(\<|\>)o\.\.|\.\.'(\<|\>)o_|'\.\.(\<|\>)o_|_\.\.'o(\<|\>)|_'\.\.o(\<|\>)|\.\._'o(\<|\>)|'_\.\.o(\<|\>)|\.\.'_o(\<|\>)|'\.\._o(\<|\>)|(\<|\>)_\.\.'o|(\<|\>)_'\.\.o|(\<|\>)\.\._'o|(\<|\>)'_\.\.o|(\<|\>)\.\.'_o|(\<|\>)'\.\._o|_(\<|\>)\.\.'o|_(\<|\>)'\.\.o|\.\.(\<|\>)_'o|'(\<|\>)_\.\.o|\.\.(\<|\>)'_o|'(\<|\>)\.\._o|_\.\.(\<|\>)'o|_'(\<|\>)\.\.o|\.\._(\<|\>)'o|'_(\<|\>)\.\.o|\.\.'(\<|\>)_o|'\.\.(\<|\>)_o|_\.\.'(\<|\>)o|_'\.\.(\<|\>)o|\.\._'(\<|\>)o|'_\.\.(\<|\>)o|\.\.'_(\<|\>)o|'\.\._(\<|\>)o) {
	lex_add_note(0, S_ORISCUS_AUCTUS, _V_EPISEMUS_AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M]w         {
	lex_add_note(0, S_QUILISMA, _NO_SIGN, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M]('w|w') {
	lex_add_note(0, S_QUILISMA, _V_EPISEMUS, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](\.\.w|w\.\.) {
	lex_add_note(0, S_QUILISMA, _AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](\.w|w\.) {
	lex_add_note(0, S_QUILISMA, _PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](w\.'|w'\.|\.w'|'w\.|\.'w|'\.w) {
	lex_add_note(0, S_QUILISMA, _V_EPISEMUS_PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](w\.\.'|w'\.\.|\.\.w'|'w\.\.|\.\.'w|'\.\.w) {
	lex_add_note(0, S_QUILISMA, _V_EPISEMUS_AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](_w|w_)         {
	lex_add_note(0, S_QUILISMA, _NO_SIGN, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](w'_|w_'|'w_|_w'|'_w|_'w) {
	lex_add_note(0, S_QUILISMA, _V_EPISEMUS , L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](w\.\._|w_\.\.|\.\.w_|_w\.\.|\.\._w|_\.\.w) {
	lex_add_note(0, S_QUILISMA, _AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](w\._|w_\.|\.w_|_w\.|\._w|_\.w) {
	lex_add_note(0, S_QUILISMA, _PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](w_\.'|w_'\.|w\._'|w'_\.|w\.'_|w'\._|_w\.'|_w'\.|\.w_'|'w_\.|\.w'_|'w\._|_\.w'|_'w\.|\._w'|'_w\.|\.'w_|'\.w_|_\.'w|_'\.w|\._'w|'_\.w|\.'_w|'\._w)  {
	lex_add_note(0, S_QUILISMA, _V_EPISEMUS_PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](w_\.\.'|w_'\.\.|w\.\._'|w'_\.\.|w\.\.'_|w'\.\._|_w\.\.'|_w'\.\.|\.\.w_'|'w_\.\.|\.\.w'_|'w\.\._|_\.\.w'|_'w\.\.|\.\._w'|'_w\.\.|\.\.'w_|'\.\.w_|_\.\.'w|_'\.\.w|\.\._'w|'_\.\.w|\.\.'_w|'\.\._w) {
	lex_add_note(0, S_QUILISMA, _V_EPISEMUS_AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M]w         {
	lex_add_note(1, S_QUILISMA, _NO_SIGN, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M]('w|w') {
	lex_add_note(1, S_QUILISMA, _V_EPISEMUS, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M](\.\.w|w\.\.) {
	lex_add_note(1, S_QUILISMA, _AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M](\.w|w\.) {
	lex_add_note(1, S_QUILISMA, _PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M](w\.'|w'\.|\.w'|'w\.|\.'w|'\.w) {
	lex_add_note(1, S_QUILISMA, _V_EPISEMUS_PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M](w\.\.'|w'\.\.|\.\.w'|'w\.\.|\.\.'w|'\.\.w) {
	lex_add_note(1, S_QUILISMA,_V_EPISEMUS_AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M](_w|w_)         {
	lex_add_note(1, S_QUILISMA, _NO_SIGN, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M](w'_|w_'|'w_|_w'|'_w|_'w) {
	lex_add_note(1, S_QUILISMA, _V_EPISEMUS, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M](w\.\._|w_\.\.|\.\.w_|_w\.\.|\.\._w|_\.\.w) {
	lex_add_note(1, S_QUILISMA, _AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M](w\._|w_\.|\.w_|_w\.|\._w|_\.w) {
	lex_add_note(1, S_QUILISMA, _PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M](w_\.'|w_'\.|w\._'|w'_\.|w\.'_|w'\._|_w\.'|_w'\.|\.w_'|'w_\.|\.w'_|'w\._|_\.w'|_'w\.|\._w'|'_w\.|\.'w_|'\.w_|_\.'w|_'\.w|\._'w|'_\.w|\.'_w|'\._w)  {
	lex_add_note(1, S_QUILISMA, _V_EPISEMUS_PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M](w_\.\.'|w_'\.\.|w\.\._'|w'_\.\.|w\.\.'_|w'\.\._|_w\.\.'|_w'\.\.|\.\.w_'|'w_\.\.|\.\.w'_|'w\.\._|_\.\.w'|_'w\.\.|\.\._w'|'_w\.\.|\.\.'w_|'\.\.w_|_\.\.'w|_'\.\.w|\.\._'w|'_\.\.w|\.\.'_w|'\.\._w) {
	lex_add_note(1, S_QUILISMA, _V_EPISEMUS_AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M]W         {
	lex_add_note(0, S_QUILISMA_QUADRATUM, _NO_SIGN, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M]('W|W') {
	lex_add_note(0, S_QUILISMA_QUADRATUM, _V_EPISEMUS, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](\.\.W|W\.\.) {
	lex_add_note(0, S_QUILISMA_QUADRATUM, _AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](\.W|W\.) {
	lex_add_note(0, S_QUILISMA_QUADRATUM, _PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](W\.'|W'\.|\.W'|'W\.|\.'W|'\.W) {
	lex_add_note(0, S_QUILISMA_QUADRATUM, _V_EPISEMUS_PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](W\.\.'|W'\.\.|\.\.W'|'W\.\.|\.\.'W|'\.\.W) {
	lex_add_note(0, S_QUILISMA_QUADRATUM, _V_EPISEMUS_AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](_W|W_)         {
	lex_add_note(0, S_QUILISMA_QUADRATUM, _NO_SIGN, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](W'_|W_'|'W_|_W'|'_W|_'W) {
	lex_add_note(0, S_QUILISMA_QUADRATUM, _V_EPISEMUS , L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](W\.\._|W_\.\.|\.\.W_|_W\.\.|\.\._W|_\.\.W) {
	lex_add_note(0, S_QUILISMA_QUADRATUM, _AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](W\._|W_\.|\.W_|_W\.|\._W|_\.W) {
	lex_add_note(0, S_QUILISMA_QUADRATUM, _PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](W_\.'|W_'\.|W\._'|W'_\.|W\.'_|W'\._|_W\.'|_W'\.|\.W_'|'W_\.|\.W'_|'W\._|_\.W'|_'W\.|\._W'|'_W\.|\.'W_|'\.W_|_\.'W|_'\.W|\._'W|'_\.W|\.'_W|'\._W)  {
	lex_add_note(0, S_QUILISMA_QUADRATUM, _V_EPISEMUS_PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](W_\.\.'|W_'\.\.|W\.\._'|W'_\.\.|W\.\.'_|W'\.\._|_W\.\.'|_W'\.\.|\.\.W_'|'W_\.\.|\.\.W'_|'W\.\._|_\.\.W'|_'W\.\.|\.\._W'|'_W\.\.|\.\.'W_|'\.\.W_|_\.\.'W|_'\.\.W|\.\._'W|'_\.\.W|\.\.'_W|'\.\._W) {
	lex_add_note(0, S_QUILISMA_QUADRATUM, _V_EPISEMUS_AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M]W         {
	lex_add_note(1, S_QUILISMA_QUADRATUM, _NO_SIGN, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M]('W|W') {
	lex_add_note(1, S_QUILISMA_QUADRATUM, _V_EPISEMUS, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M](\.\.W|W\.\.) {
	lex_add_note(1, S_QUILISMA_QUADRATUM, _AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M](\.W|W\.) {
	lex_add_note(1, S_QUILISMA_QUADRATUM, _PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M](W\.'|W'\.|\.W'|'W\.|\.'W|'\.W) {
	lex_add_note(1, S_QUILISMA_QUADRATUM, _V_EPISEMUS_PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M](W\.\.'|W'\.\.|\.\.W'|'W\.\.|\.\.'W|'\.\.W) {
	lex_add_note(1, S_QUILISMA_QUADRATUM,_V_EPISEMUS_AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M](_W|W_)         {
	lex_add_note(1, S_QUILISMA_QUADRATUM, _NO_SIGN, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M](W'_|W_'|'W_|_W'|'_W|_'W) {
	lex_add_note(1, S_QUILISMA_QUADRATUM, _V_EPISEMUS, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M](W\.\._|W_\.\.|\.\.W_|_W\.\.|\.\._W|_\.\.W) {
	lex_add_note(1, S_QUILISMA_QUADRATUM, _AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M](W\._|W_\.|\.W_|_W\.|\._W|_\.W) {
	lex_add_note(1, S_QUILISMA_QUADRATUM, _PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M](W_\.'|W_'\.|W\._'|W'_\.|W\.'_|W'\._|_W\.'|_W'\.|\.W_'|'W_\.|\.W'_|'W\._|_\.W'|_'W\.|\._W'|'_W\.|\.'W_|'\.W_|_\.'W|_'\.W|\._'W|'_\.W|\.'_W|'\._W)  {
	lex_add_note(1, S_QUILISMA_QUADRATUM, _V_EPISEMUS_PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M](W_\.\.'|W_'\.\.|W\.\._'|W'_\.\.|W\.\.'_|W'\.\._|_W\.\.'|_W'\.\.|\.\.W_'|'W_\.\.|\.\.W'_|'W\.\._|_\.\.W'|_'W\.\.|\.\._W'|'_W\.\.|\.\.'W_|'\.\.W_|_\.\.'W|_'\.\.W|\.\._'W|'_\.\.W|\.\.'_W|'\.\._W) {
	lex_add_note(1, S_QUILISMA_QUADRATUM, _V_EPISEMUS_AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](V|v)         {
	lex_add_note(0, S_VIRGA, _NO_SIGN, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M]('(V|v)|(V|v)') {
	lex_add_note(0, S_VIRGA, _V_EPISEMUS, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](\.\.(V|v)|(V|v)\.\.) {
	lex_add_note(0, S_VIRGA, _AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](\.(V|v)|(V|v)\.) {
	lex_add_note(0, S_VIRGA, _PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M]((V|v)\.'|(V|v)'\.|\.(V|v)'|'(V|v)\.|\.'(V|v)|'\.(V|v)) {
	lex_add_note(0, S_VIRGA, _V_EPISEMUS_PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M]((V|v)\.\.'|(V|v)'\.\.|\.\.(V|v)'|'(V|v)\.\.|\.\.'(V|v)|'\.\.(V|v)) {
	lex_add_note(0, S_VIRGA, _V_EPISEMUS_AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](_(V|v)|(V|v)_)         {
	lex_add_note(0, S_VIRGA, _NO_SIGN, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M]((V|v)'_|(V|v)_'|'(V|v)_|_(V|v)'|'_(V|v)|_'(V|v)) {
	lex_add_note(0, S_VIRGA, _V_EPISEMUS, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M]((V|v)\.\._|(V|v)_\.\.|\.\.(V|v)_|_(V|v)\.\.|\.\._(V|v)|_\.\.(V|v)) {
	lex_add_note(0, S_VIRGA, _AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M]((V|v)\._|(V|v)_\.|\.(V|v)_|_(V|v)\.|\._(V|v)|_\.(V|v)) {
	lex_add_note(0, S_VIRGA,_PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M]((V|v)_\.'|(V|v)_'\.|(V|v)\._'|(V|v)'_\.|(V|v)\.'_|(V|v)'\._|_(V|v)\.'|_(V|v)'\.|\.(V|v)_'|'(V|v)_\.|\.(V|v)'_|'(V|v)\._|_\.(V|v)'|_'(V|v)\.|\._(V|v)'|'_(V|v)\.|\.'(V|v)_|'\.(V|v)_|_\.'(V|v)|_'\.(V|v)|\._'(V|v)|'_\.(V|v)|\.'_(V|v)|'\._(V|v))  {
	lex_add_note(0, S_VIRGA, _V_EPISEMUS_PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M]((V|v)_\.\.'|(V|v)_'\.\.|(V|v)\.\._'|(V|v)'_\.\.|(V|v)\.\.'_|(V|v)'\.\._|_(V|v)\.\.'|_(V|v)'\.\.|\.\.(V|v)_'|'(V|v)_\.\.|\.\.(V|v)'_|'(V|v)\.\._|_\.\.(V|v)'|_'(V|v)\.\.|\.\._(V|v)'|'_(V|v)\.\.|\.\.'(V|v)_|'\.\.(V|v)_|_\.\.'(V|v)|_'\.\.(V|v)|\.\._'(V|v)|'_\.\.(V|v)|\.\.'_(V|v)|'\.\._(V|v)) {
	lex_add_note(0, S_VIRGA, _V_EPISEMUS_AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M](V|v)         {
	lex_add_note(1, S_VIRGA, _NO_SIGN, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M]('(V|v)|(V|v)') {
	lex_add_note(1, S_VIRGA, _V_EPISEMUS, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M](\.\.(V|v)|(V|v)\.\.) {
	lex_add_note(1, S_VIRGA, _AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M](\.(V|v)|(V|v)\.) {
	lex_add_note(1, S_VIRGA, _PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M]((V|v)\.'|(V|v)'\.|\.(V|v)'|'(V|v)\.|\.'(V|v)|'\.(V|v)) {
	lex_add_note(1, S_VIRGA, _V_EPISEMUS_PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M]((V|v)\.\.'|(V|v)'\.\.|\.\.(V|v)'|'(V|v)\.\.|\.\.'(V|v)|'\.\.(V|v)) {
	lex_add_note(1, S_VIRGA, _V_EPISEMUS_AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M](_(V|v)|(V|v)_)         {
	lex_add_note(1, S_VIRGA, _NO_SIGN, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M]((V|v)'_|(V|v)_'|'(V|v)_|_(V|v)'|'_(V|v)|_'(V|v)) {
	lex_add_note(1, S_VIRGA, _V_EPISEMUS, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M]((V|v)\.\._|(V|v)_\.\.|\.\.(V|v)_|_(V|v)\.\.|\.\._(V|v)|_\.\.(V|v)) {
	lex_add_note(1, S_VIRGA, _AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M]((V|v)\._|(V|v)_\.|\.(V|v)_|_(V|v)\.|\._(V|v)|_\.(V|v)) {
	lex_add_note(1, S_VIRGA, _PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M]((V|v)_\.'|(V|v)_'\.|(V|v)\._'|(V|v)'_\.|(V|v)\.'_|(V|v)'\._|_(V|v)\.'|_(V|v)'\.|\.(V|v)_'|'(V|v)_\.|\.(V|v)'_|'(V|v)\._|_\.(V|v)'|_'(V|v)\.|\._(V|v)'|'_(V|v)\.|\.'(V|v)_|'\.(V|v)_|_\.'(V|v)|_'\.(V|v)|\._'(V|v)|'_\.(V|v)|\.'_(V|v)|'\._(V|v))  {
	lex_add_note(1, S_VIRGA, _V_EPISEMUS_PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M]((V|v)_\.\.'|(V|v)_'\.\.|(V|v)\.\._'|(V|v)'_\.\.|(V|v)\.\.'_|(V|v)'\.\._|_(V|v)\.\.'|_(V|v)'\.\.|\.\.(V|v)_'|'(V|v)_\.\.|\.\.(V|v)'_|'(V|v)\.\._|_\.\.(V|v)'|_'(V|v)\.\.|\.\._(V|v)'|'_(V|v)\.\.|\.\.'(V|v)_|'\.\.(V|v)_|_\.\.'(V|v)|_'\.\.(V|v)|\.\._'(V|v)|'_\.\.(V|v)|\.\.'_(V|v)|'\.\._(V|v)) {
	lex_add_note(1, S_VIRGA, _V_EPISEMUS_AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M]s         {
	lex_add_note(0, S_STROPHA, _NO_SIGN, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M]('s|s') {
	lex_add_note(0, S_STROPHA, _V_EPISEMUS, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](\.\.s|s\.\.) {
	lex_add_note(0, S_STROPHA, _AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](\.s|s\.) {
	lex_add_note(0, S_STROPHA, _PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](s\.'|s'\.|\.s'|'s\.|\.'s|'\.s) {
	lex_add_note(0, S_STROPHA, _V_EPISEMUS_PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](s\.\.'|s'\.\.|\.\.s'|'s\.\.|\.\.'s|'\.\.s) {
	lex_add_note(0, S_STROPHA, _V_EPISEMUS_AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
[a-mA-M](_s|s_)         {
	lex_add_note(0, S_STROPHA, _NO_SIGN, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](s'_|s_'|'s_|_s'|'_s|_'s) {
	lex_add_note(0, S_STROPHA, _V_EPISEMUS, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](s\.\._|s_\.\.|\.\.s_|_s\.\.|\.\._s|_\.\.s) {
	lex_add_note(0, S_STROPHA, _AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](s\._|s_\.|\.s_|_s\.|\._s|_\.s) {
	lex_add_note(0, S_STROPHA, _PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](s_\.'|s_'\.|s\._'|s'_\.|s\.'_|s'\._|_s\.'|_s'\.|\.s_'|'s_\.|\.s'_|'s\._|_\.s'|_'s\.|\._s'|'_s\.|\.'s_|'\.s_|_\.'s|_'\.s|\._'s|'_\.s|\.'_s|'\._s)  {
	lex_add_note(0, S_STROPHA, _V_EPISEMUS_PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M](s_\.\.'|s_'\.\.|s\.\._'|s'_\.\.|s\.\.'_|s'\.\._|_s\.\.'|_s'\.\.|\.\.s_'|'s_\.\.|\.\.s'_|'s\.\._|_\.\.s'|_'s\.\.|\.\._s'|'_s\.\.|\.\.'s_|'\.\.s_|_\.\.'s|_'\.\.s|\.\._'s|'_\.\.s|\.\.'_s|'\.\._s) {
	lex_add_note(0, S_STROPHA, _V_EPISEMUS_AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M]s         {
	lex_add_note(1, S_STROPHA, _NO_SIGN, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M]('s|s') {
	lex_add_note(1, S_STROPHA, _V_EPISEMUS, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M](\.\.s|s\.\.) {
	lex_add_note(1, S_STROPHA, _AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M](\.s|s\.) {
	lex_add_note(1, S_STROPHA, _PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M](s\.'|s'\.|\.s'|'s\.|\.'s|'\.s) {
	lex_add_note(1, S_STROPHA, _V_EPISEMUS_PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M](s\.\.'|s'\.\.|\.\.s'|'s\.\.|\.\.'s|'\.\.s) {
	lex_add_note(1, S_STROPHA, _V_EPISEMUS_AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_NO_EPISEMUS);
		}
-[a-mA-M](_s|s_)         {
	lex_add_note(1, S_STROPHA, _NO_SIGN, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M](s'_|s_'|'s_|_s'|'_s|_'s) {
	lex_add_note(1, S_STROPHA, _V_EPISEMUS, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M](s\.\._|s_\.\.|\.\.s_|_s\.\.|\.\._s|_\.\.s) {
	lex_add_note(1, S_STROPHA, _AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M](s\._|s_\.|\.s_|_s\.|\._s|_\.s) {
	lex_add_note(1, S_STROPHA, _PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M](s_\.'|s_'\.|s\._'|s'_\.|s\.'_|s'\._|_s\.'|_s'\.|\.s_'|'s_\.|\.s'_|'s\._|_\.s'|_'s\.|\._s'|'_s\.|\.'s_|'\.s_|_\.'s|_'\.s|\._'s|'_\.s|\.'_s|'\._s)  {
	lex_add_note(1, S_STROPHA, _V_EPISEMUS_PUNCTUM_MORA, L_NO_LIQUESCENTIA,H_ONE);
		}
-[a-mA-M](s_\.\.'|s_'\.\.|s\.\._'|s'_\.\.|s\.\.'_|s'\.\._|_s\.\.'|_s'\.\.|\.\.s_'|'s_\.\.|\.\.s'_|'s\.\._|_\.\.s'|_'s\.\.|\.\._s'|'_s\.\.|\.\.'s_|'\.\.s_|_\.\.'s|_'\.\.s|\.\._'s|'_\.\.s|\.\.'_s|'\.\._s) {
	lex_add_note(1, S_STROPHA, _V_EPISEMUS_AUCTUM_DUPLEX, L_NO_LIQUESCENTIA,H_ONE);
		}
[a-mA-M]((\<|\>)s|s(\<|\>))        {
	lex_add_note(0, S_STROPHA, _NO_SIGN, L_AUCTA,H_NO_EPISEMUS);
		}
[a-mA-M](s'(\<|\>)|s(\<|\>)'|'s(\<|\>)|(\<|\>)s'|'(\<|\>)s|(\<|\>)'s) {
	lex_add_note(0, S_STROPHA, _V_EPISEMUS, L_AUCTA,H_NO_EPISEMUS);
		}
[a-mA-M](s\.\.(\<|\>)|s(\<|\>)\.\.|\.\.s(\<|\>)|(\<|\>)s\.\.|\.\.(\<|\>)s|(\<|\>)\.\.s) {
	lex_add_note(0, S_STROPHA, _AUCTUM_DUPLEX, L_AUCTA,H_NO_EPISEMUS);
		}
[a-mA-M](s\.(\<|\>)|s(\<|\>)\.|\.s(\<|\>)|(\<|\>)s\.|\.(\<|\>)s|(\<|\>)\.s) {
	lex_add_note(0, S_STROPHA, _PUNCTUM_MORA, L_AUCTA,H_NO_EPISEMUS);
		}
[a-mA-M](s(\<|\>)\.'|s(\<|\>)'\.|s\.(\<|\>)'|s'(\<|\>)\.|s\.'(\<|\>)|s'\.(\<|\>)|(\<|\>)s\.'|(\<|\>)s'\.|\.s(\<|\>)'|'s(\<|\>)\.|\.s'(\<|\>)|'s\.(\<|\>)|(\<|\>)\.s'|(\<|\>)'s\.|\.(\<|\>)s'|'(\<|\>)s\.|\.'s(\<|\>)|'\.s(\<|\>)|(\<|\>)\.'s|(\<|\>)'\.s|\.(\<|\>)'s|'(\<|\>)\.s|\.'(\<|\>)s|'\.(\<|\>)s) {
	lex_add_note(0, S_STROPHA, _V_EPISEMUS_PUNCTUM_MORA, L_AUCTA,H_NO_EPISEMUS);
		}
[a-mA-M](s(\<|\>)\.\.'|s(\<|\>)'\.\.|s\.\.(\<|\>)'|s'(\<|\>)\.\.|s\.\.'(\<|\>)|s'\.\.(\<|\>)|(\<|\>)s\.\.'|(\<|\>)s'\.\.|\.\.s(\<|\>)'|'s(\<|\>)\.\.|\.\.s'(\<|\>)|'s\.\.(\<|\>)|(\<|\>)\.\.s'|(\<|\>)'s\.\.|\.\.(\<|\>)s'|'(\<|\>)s\.\.|\.\.'s(\<|\>)|'\.\.s(\<|\>)|(\<|\>)\.\.'s|(\<|\>)'\.\.s|\.\.(\<|\>)'s|'(\<|\>)\.\.s|\.\.'(\<|\>)s|'\.\.(\<|\>)s) {
	lex_add_note(0, S_STROPHA, _V_EPISEMUS_AUCTUM_DUPLEX, L_AUCTA,H_NO_EPISEMUS);
		}
[a-mA-M](s_(\<|\>)|s(\<|\>)_|_s(\<|\>)|(\<|\>)s_|_(\<|\>)s|(\<|\>)_s)        {
	lex_add_note(0, S_STROPHA, _NO_SIGN, L_AUCTA,H_ONE);
		}
[a-mA-M](s(\<|\>)_'|s(\<|\>)'_|s_(\<|\>)'|s'(\<|\>)_|s_'(\<|\>)|s'_(\<|\>)|(\<|\>)s_'|(\<|\>)s'_|_s(\<|\>)'|'s(\<|\>)_|_s'(\<|\>)|'s_(\<|\>)|(\<|\>)_s'|(\<|\>)'s_|_(\<|\>)s'|'(\<|\>)s_|_'s(\<|\>)|'_s(\<|\>)|(\<|\>)_'s|(\<|\>)'_s|_(\<|\>)'s|'(\<|\>)_s|_'(\<|\>)s|'_(\<|\>)s) {
	lex_add_note(0, S_STROPHA, _V_EPISEMUS, L_AUCTA,H_ONE);
		}
[a-mA-M](s(\<|\>)\.\._|s(\<|\>)_\.\.|s\.\.(\<|\>)_|s_(\<|\>)\.\.|s\.\._(\<|\>)|s_\.\.(\<|\>)|(\<|\>)s\.\._|(\<|\>)s_\.\.|\.\.s(\<|\>)_|_s(\<|\>)\.\.|\.\.s_(\<|\>)|_s\.\.(\<|\>)|(\<|\>)\.\.s_|(\<|\>)_s\.\.|\.\.(\<|\>)s_|_(\<|\>)s\.\.|\.\._s(\<|\>)|_\.\.s(\<|\>)|(\<|\>)\.\._s|(\<|\>)_\.\.s|\.\.(\<|\>)_s|_(\<|\>)\.\.s|\.\._(\<|\>)s|_\.\.(\<|\>)s) {
	lex_add_note(0, S_STROPHA, _AUCTUM_DUPLEX, L_AUCTA,H_ONE);
		}
[a-mA-M](s(\<|\>)\._|s(\<|\>)_\.|s\.(\<|\>)_|s_(\<|\>)\.|s\._(\<|\>)|s_\.(\<|\>)|(\<|\>)s\._|(\<|\>)s_\.|\.s(\<|\>)_|_s(\<|\>)\.|\.s_(\<|\>)|_s\.(\<|\>)|(\<|\>)\.s_|(\<|\>)_s\.|\.(\<|\>)s_|_(\<|\>)s\.|\._s(\<|\>)|_\.s(\<|\>)|(\<|\>)\._s|(\<|\>)_\.s|\.(\<|\>)_s|_(\<|\>)\.s|\._(\<|\>)s|_\.(\<|\>)s) {
	lex_add_note(0, S_STROPHA, _PUNCTUM_MORA, L_AUCTA,H_ONE);
		}
[a-mA-M](s(\<|\>)_\.'|s(\<|\>)_'\.|s(\<|\>)\._'|s(\<|\>)'_\.|s(\<|\>)\.'_|s(\<|\>)'\._|s_(\<|\>)\.'|s_(\<|\>)'\.|s\.(\<|\>)_'|s'(\<|\>)_\.|s\.(\<|\>)'_|s'(\<|\>)\._|s_\.(\<|\>)'|s_'(\<|\>)\.|s\._(\<|\>)'|s'_(\<|\>)\.|s\.'(\<|\>)_|s'\.(\<|\>)_|s_\.'(\<|\>)|s_'\.(\<|\>)|s\._'(\<|\>)|s'_\.(\<|\>)|s\.'_(\<|\>)|s'\._(\<|\>)|(\<|\>)s_\.'|(\<|\>)s_'\.|(\<|\>)s\._'|(\<|\>)s'_\.|(\<|\>)s\.'_|(\<|\>)s'\._|_s(\<|\>)\.'|_s(\<|\>)'\.|\.s(\<|\>)_'|'s(\<|\>)_\.|\.s(\<|\>)'_|'s(\<|\>)\._|_s\.(\<|\>)'|_'s(\<|\>)\.|\._s(\<|\>)'|'_s(\<|\>)\.|\.'s(\<|\>)_|'\.s(\<|\>)_|_\.s'(\<|\>)|_'s\.(\<|\>)|\._s'(\<|\>)|'_s\.(\<|\>)|\.'s_(\<|\>)|'\.s_(\<|\>)|(\<|\>)_\.s'|(\<|\>)_s'\.|(\<|\>)\.s_'|(\<|\>)'s_\.|(\<|\>)\.s'_|(\<|\>)'s\._|_(\<|\>)s\.'|_(\<|\>)s'\.|\.(\<|\>)s_'|'(\<|\>)s_\.|\.(\<|\>)s'_|'(\<|\>)s\._|_\.s(\<|\>)'|_'s(\<|\>)\.|\._s(\<|\>)'|'_s(\<|\>)\.|\.'s(\<|\>)_|'\.s(\<|\>)_|_\.s'(\<|\>)|_'s\.(\<|\>)|\._s'(\<|\>)|'_s\.(\<|\>)|\.'s_(\<|\>)|'\.s_(\<|\>)|(\<|\>)_\.s'|(\<|\>)_'s\.|(\<|\>)\._s'|(\<|\>)'_s\.|(\<|\>)\.'s_|(\<|\>)'\.s_|_(\<|\>)\.s'|_(\<|\>)'s\.|\.(\<|\>)_s'|'(\<|\>)_s\.|\.(\<|\>)'s_|'(\<|\>)\.s_|_\.(\<|\>)s'|_'(\<|\>)s\.|\._(\<|\>)s'|'_(\<|\>)s\.|\.'(\<|\>)s_|'\.(\<|\>)s_|_\.'s(\<|\>)|_'\.s(\<|\>)|\._'s(\<|\>)|'_\.s(\<|\>)|\.'_s(\<|\>)|'\._s(\<|\>)|(\<|\>)_\.'s|(\<|\>)_'\.s|(\<|\>)\._'s|(\<|\>)'_\.s|(\<|\>)\.'_s|(\<|\>)'\._s|_(\<|\>)\.'s|_(\<|\>)'\.s|\.(\<|\>)_'s|'(\<|\>)_\.s|\.(\<|\>)'_s|'(\<|\>)\._s|_\.(\<|\>)'s|_'(\<|\>)\.s|\._(\<|\>)'s|'_(\<|\>)\.s|\.'(\<|\>)_s|'\.(\<|\>)_s|_\.'(\<|\>)s|_'\.(\<|\>)s|\._'(\<|\>)s|'_\.(\<|\>)s|\.'_(\<|\>)s|'\._(\<|\>)s)  {
	lex_add_note(0, S_STROPHA, _V_EPISEMUS_PUNCTUM_MORA, L_AUCTA,H_ONE);
		}
[a-mA-M](s(\<|\>)_\.\.'|s(\<|\>)_'\.\.|s(\<|\>)\.\._'|s(\<|\>)'_\.\.|s(\<|\>)\.\.'_|s(\<|\>)'\.\._|s_(\<|\>)\.\.'|s_(\<|\>)'\.\.|s\.\.(\<|\>)_'|s'(\<|\>)_\.\.|s\.\.(\<|\>)'_|s'(\<|\>)\.\._|s_\.\.(\<|\>)'|s_'(\<|\>)\.\.|s\.\._(\<|\>)'|s'_(\<|\>)\.\.|s\.\.'(\<|\>)_|s'\.\.(\<|\>)_|s_\.\.'(\<|\>)|s_'\.\.(\<|\>)|s\.\._'(\<|\>)|s'_\.\.(\<|\>)|s\.\.'_(\<|\>)|s'\.\._(\<|\>)|(\<|\>)s_\.\.'|(\<|\>)s_'\.\.|(\<|\>)s\.\._'|(\<|\>)s'_\.\.|(\<|\>)s\.\.'_|(\<|\>)s'\.\._|_s(\<|\>)\.\.'|_s(\<|\>)'\.\.|\.\.s(\<|\>)_'|'s(\<|\>)_\.\.|\.\.s(\<|\>)'_|'s(\<|\>)\.\._|_s\.\.(\<|\>)'|_'s(\<|\>)\.\.|\.\._s(\<|\>)'|'_s(\<|\>)\.\.|\.\.'s(\<|\>)_|'\.\.s(\<|\>)_|_\.\.s'(\<|\>)|_'s\.\.(\<|\>)|\.\._s'(\<|\>)|'_s\.\.(\<|\>)|\.\.'s_(\<|\>)|'\.\.s_(\<|\>)|(\<|\>)_\.\.s'|(\<|\>)_s'\.\.|(\<|\>)\.\.s_'|(\<|\>)'s_\.\.|(\<|\>)\.\.s'_|(\<|\>)'s\.\._|_(\<|\>)s\.\.'|_(\<|\>)s'\.\.|\.\.(\<|\>)s_'|'(\<|\>)s_\.\.|\.\.(\<|\>)s'_|'(\<|\>)s\.\._|_\.\.s(\<|\>)'|_'s(\<|\>)\.\.|\.\._s(\<|\>)'|'_s(\<|\>)\.\.|\.\.'s(\<|\>)_|'\.\.s(\<|\>)_|_\.\.s'(\<|\>)|_'s\.\.(\<|\>)|\.\._s'(\<|\>)|'_s\.\.(\<|\>)|\.\.'s_(\<|\>)|'\.\.s_(\<|\>)|(\<|\>)_\.\.s'|(\<|\>)_'s\.\.|(\<|\>)\.\._s'|(\<|\>)'_s\.\.|(\<|\>)\.\.'s_|(\<|\>)'\.\.s_|_(\<|\>)\.\.s'|_(\<|\>)'s\.\.|\.\.(\<|\>)_s'|'(\<|\>)_s\.\.|\.\.(\<|\>)'s_|'(\<|\>)\.\.s_|_\.\.(\<|\>)s'|_'(\<|\>)s\.\.|\.\._(\<|\>)s'|'_(\<|\>)s\.\.|\.\.'(\<|\>)s_|'\.\.(\<|\>)s_|_\.\.'s(\<|\>)|_'\.\.s(\<|\>)|\.\._'s(\<|\>)|'_\.\.s(\<|\>)|\.\.'_s(\<|\>)|'\.\._s(\<|\>)|(\<|\>)_\.\.'s|(\<|\>)_'\.\.s|(\<|\>)\.\._'s|(\<|\>)'_\.\.s|(\<|\>)\.\.'_s|(\<|\>)'\.\._s|_(\<|\>)\.\.'s|_(\<|\>)'\.\.s|\.\.(\<|\>)_'s|'(\<|\>)_\.\.s|\.\.(\<|\>)'_s|'(\<|\>)\.\._s|_\.\.(\<|\>)'s|_'(\<|\>)\.\.s|\.\._(\<|\>)'s|'_(\<|\>)\.\.s|\.\.'(\<|\>)_s|'\.\.(\<|\>)_s|_\.\.'(\<|\>)s|_'\.\.(\<|\>)s|\.\._'(\<|\>)s|'_\.\.(\<|\>)s|\.\.'_(\<|\>)s|'\.\._(\<|\>)s) {
	lex_add_note(0, S_STROPHA, _V_EPISEMUS_AUCTUM_DUPLEX, L_AUCTA,H_ONE);
		}
.       {	
    char *dirtyvar = malloc(71*sizeof(char));
	snprintf(dirtyvar,70,gettext("unrecognized character: \"%c\""),gabc_notes_determination_text[0]);
	gregorio_message (dirtyvar,
		      "libgregorio_det_notes_from_string", ERROR, 0);
	}

%%

void gabc_notes_determination_error(const char *str)
{
    char *dirtyvartwo = malloc(151*sizeof(char));
	snprintf(dirtyvartwo,150,str);
      gregorio_message (dirtyvartwo,
		      "libgregorio_det_notes_from_string", ERROR, 0);
}


gregorio_note *libgregorio_gabc_det_notes_from_string (char *str) {
current_note=NULL;
YY_BUFFER_STATE buf;
buf=yy_scan_string(str);
yylex();
yy_flush_buffer(buf);
yy_delete_buffer(buf);
gregorio_go_to_first_note (&current_note);
return current_note;
}
