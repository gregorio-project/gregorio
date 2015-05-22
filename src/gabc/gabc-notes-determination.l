%{
/*
 * Copyright (C) 2006-2015 The Gregorio Project (see CONTRIBUTORS.md)
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
#include <stdbool.h>
#include <ctype.h>              /* for tolower */
#include "struct.h"
#include "messages.h"

#include "gabc.h"

#define YY_NO_INPUT

static gregorio_note *current_note;
static char char_for_brace;
static unsigned int nbof_isolated_episemus;
static char *notesmacros[10];
static char *tempstr = NULL;

static inline char pitch_letter_to_height(const char pitch) {
    return pitch - 'a' + LOWEST_PITCH;
}

gregorio_shape punctum(const char pitch)
{
    if (pitch < 'a') {
        return S_PUNCTUM_INCLINATUM;
    } else {
        return S_PUNCTUM;
    }
}

static inline void lex_add_note(int i, gregorio_shape shape, char signs,
        char liquescentia)
{
    nbof_isolated_episemus = 0;
    gregorio_add_note(&current_note,
            pitch_letter_to_height(tolower(gabc_notes_determination_text[i])),
            shape, signs, liquescentia, NULL);
}

static inline void add_bar_as_note(gregorio_bar bar)
{
    nbof_isolated_episemus = 0;
    gregorio_add_bar_as_note(&current_note, bar);
}

static inline void error(void)
{
    gregorio_messagef("gabc_notes_determination", ERROR, 0,
            _("undefined macro used: m%d"),
            gabc_notes_determination_text[3] - '0');
}

static void add_h_episemus(void) {
    grehepisemus_size size = H_NORMAL;
    gregorio_vposition vposition = VPOS_AUTO;
    bool disable_bridge = false;

    char *ptr = gabc_notes_determination_text;
    char current;
    // first character is the underscore
    while ((current = *(++ptr))) {
        switch(current) {
        case '0':
            vposition = VPOS_BELOW;
            break;
        case '1':
            vposition = VPOS_ABOVE;
            break;
        case '2':
            disable_bridge = true;
            break;
        case '3':
            size = H_SMALL_LEFT;
            break;
        case '4':
            size = H_SMALL_CENTRE;
            break;
        case '5':
            size = H_SMALL_RIGHT;
            break;
        default:
            gregorio_messagef("gabc_notes_determination", ERROR, 0,
                    _("unrecognized horizontal episemus modifier: %c"),
                    current);
            break;
        };
    }

    gregorio_add_h_episemus(current_note, size, vposition, disable_bridge,
                &nbof_isolated_episemus);
}

static void add_sign(gregorio_sign sign) {
    gregorio_vposition vposition = VPOS_AUTO;
    switch(gabc_notes_determination_text[1]) {
    case '0':
        vposition = VPOS_BELOW;
        break;
    case '1':
        vposition = VPOS_ABOVE;
        break;
    }
    gregorio_add_sign(current_note, sign, vposition);
}

static inline void add_alteration(const gregorio_type type) {
    gregorio_add_alteration_as_note(&current_note, type,
            pitch_letter_to_height(gabc_notes_determination_text[0]));
}

%}

%option stack
%option 8bit
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
%option noyywrap

%x texverbnote
%x texverbglyph
%x texverbelement
%x choralsign
%x alt
%x comments
%x overbrace
%x underbrace
%x overcurlybrace
%x overcurlyaccentusbrace

%%
<INITIAL>\% {
        BEGIN(comments);
    }
<comments>(\n|\r)+ {
        BEGIN(INITIAL);
    }
<comments>[^\n\r]* {
        //ignored
    }
<INITIAL>\[cs: {
        BEGIN(choralsign);
    }
<INITIAL>\[ob:[01]; {
        char_for_brace = gabc_notes_determination_text[4]-'0';
        BEGIN(overbrace);
    }
<INITIAL>\[ub:[01]; {
        char_for_brace = gabc_notes_determination_text[4]-'0';
        BEGIN(underbrace);
    }
<INITIAL>\[ocb:[01]; {
        char_for_brace = gabc_notes_determination_text[5]-'0';
        BEGIN(overcurlybrace);
    }
<INITIAL>\[ocba:[01]; {
        char_for_brace = gabc_notes_determination_text[6]-'0';
        BEGIN(overcurlyaccentusbrace);
    }
<INITIAL>\[nm[1-9]\] {
        if (notesmacros[gabc_notes_determination_text[3]-'0']) {
            gregorio_add_texverb_to_note(&current_note,
            strdup(notesmacros[gabc_notes_determination_text[3]-'0']));
        } else error();
    }
<INITIAL>\[gm[1-9]\] {
        if (notesmacros[gabc_notes_determination_text[3]-'0']) {
            gregorio_add_texverb_as_note(&current_note,
            strdup(notesmacros[gabc_notes_determination_text[3]-'0']),
            GRE_TEXVERB_GLYPH);
        } else error();
    }
<INITIAL>\[em[1-9]\] {
        if (notesmacros[gabc_notes_determination_text[3]-'0']) {
            gregorio_add_texverb_as_note(&current_note,
            strdup(notesmacros[gabc_notes_determination_text[3]-'0']),
            GRE_TEXVERB_ELEMENT);
        } else error();
    }
<INITIAL>\[altm[1-9]\] {
        if (notesmacros[gabc_notes_determination_text[5]-'0']) {
            gregorio_add_texverb_as_note(&current_note,
            strdup(notesmacros[gabc_notes_determination_text[5]-'0']),
            GRE_TEXVERB_ELEMENT);
        } else error();
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
<INITIAL>\[alt: {
        BEGIN(alt);
    }
<INITIAL><nlba> {
        gregorio_add_nlba_as_note(&current_note, NLBA_BEGINNING);
    }
<INITIAL><\/nlba> {
        gregorio_add_nlba_as_note(&current_note, NLBA_END);
    }
<overbrace>[^\]]+ {
        snprintf(tempstr, 70, "\\greoverbrace{%s}{0pt}{0pt}{%d}",
                gabc_notes_determination_text, char_for_brace);
        gregorio_add_texverb_to_note(&current_note, strdup(tempstr));
    }
<underbrace>[^\]]+ {
        snprintf(tempstr, 70, "\\greunderbrace{%s}{0pt}{0pt}{%d}",
                gabc_notes_determination_text, char_for_brace);
        gregorio_add_texverb_to_note(&current_note, strdup(tempstr));
    }
<overcurlybrace>[^\]]+ {
        snprintf(tempstr, 70, "\\greovercurlybrace{%s}{0pt}{0pt}{%d}{0}",
                gabc_notes_determination_text, char_for_brace);
        gregorio_add_texverb_to_note(&current_note, strdup(tempstr));
    }
<overcurlyaccentusbrace>[^\]]+ {
        snprintf(tempstr, 70, "\\greovercurlybrace{%s}{0pt}{0pt}{%d}{1}",
                gabc_notes_determination_text, char_for_brace);
        gregorio_add_texverb_to_note(&current_note, strdup(tempstr));
    }
<choralsign>[^\]]+ {
        gregorio_add_cs_to_note(&current_note,
                strdup(gabc_notes_determination_text));
    }
<texverbnote>[^\]]+ {
        gregorio_add_texverb_to_note(&current_note,
                strdup(gabc_notes_determination_text));
    }
<texverbglyph>[^\]]+ {
        gregorio_add_texverb_as_note(&current_note,
                strdup(gabc_notes_determination_text), GRE_TEXVERB_GLYPH);
    }
<texverbelement>[^\]]+ {
        gregorio_add_texverb_as_note(&current_note,
                strdup(gabc_notes_determination_text), GRE_TEXVERB_ELEMENT);
    }
<alt>[^\]]+ {
        gregorio_add_texverb_as_note(&current_note,
                strdup(gabc_notes_determination_text), GRE_ALT);
    }
<texverbnote,texverbglyph,texverbelement,choralsign,alt,overcurlyaccentusbrace,overcurlybrace,overbrace,underbrace>\] {
        BEGIN(INITIAL);
    }
\{  {
        gregorio_add_texverb_as_note(&current_note, strdup("\\hbox to 0pt{"),
                GRE_TEXVERB_ELEMENT);
    }
\}  {
        gregorio_add_texverb_as_note(&current_note,
                strdup("\\hss%\n}%\n\\grenobreak\\relax "),
                GRE_TEXVERB_ELEMENT);
    }
[a-m]\+ {
        gregorio_add_manual_custos_as_note(&current_note,
                pitch_letter_to_height(gabc_notes_determination_text[0]));
    }
[\t\r\n]+ /* ignore ends of line and tabs */;
z   {
        gregorio_add_end_of_line_as_note(&current_note, GRE_END_OF_LINE);
    }
z0  {
        gregorio_add_custo_as_note(&current_note);
    }
Z   {
        gregorio_add_end_of_line_as_note(&current_note, GRE_END_OF_PAR);
    }
(c|f)[1-4] {
        if (gabc_notes_determination_text[0]=='c') {
            gregorio_add_clef_change_as_note(&current_note, GRE_C_KEY_CHANGE,
                    gabc_notes_determination_text[1]);
        } else {
            gregorio_add_clef_change_as_note(&current_note, GRE_F_KEY_CHANGE,
                    gabc_notes_determination_text[1]);
        }
    }
(cb|fb)[1-4] {
        if (gabc_notes_determination_text[0]=='c') {
            gregorio_add_clef_change_as_note(&current_note, GRE_C_KEY_CHANGE_FLATED,
                                             gabc_notes_determination_text[2]);
        } else {
            gregorio_add_clef_change_as_note(&current_note, GRE_F_KEY_CHANGE_FLATED,
                                             gabc_notes_determination_text[2]);
        }
    }
`   {
        add_bar_as_note(B_VIRGULA);
    }
,   {
        add_bar_as_note(B_DIVISIO_MINIMA);
    }
,1  {
        add_bar_as_note(B_DIVISIO_MINOR_D1);
    }
,2  {
        add_bar_as_note(B_DIVISIO_MINOR_D2);
    }
,3  {
        add_bar_as_note(B_DIVISIO_MINOR_D3);
    }
,4  {
        add_bar_as_note(B_DIVISIO_MINOR_D4);
    }
,5  {
        add_bar_as_note(B_DIVISIO_MINOR_D5);
    }
,6  {
        add_bar_as_note(B_DIVISIO_MINOR_D6);
    }
;   {
        add_bar_as_note(B_DIVISIO_MINOR);
    }
;1  {
        add_bar_as_note(B_DIVISIO_MINOR_D1);
    }
;2  {
        add_bar_as_note(B_DIVISIO_MINOR_D2);
    }
;3  {
        add_bar_as_note(B_DIVISIO_MINOR_D3);
    }
;4  {
        add_bar_as_note(B_DIVISIO_MINOR_D4);
    }
;5  {
        add_bar_as_note(B_DIVISIO_MINOR_D5);
    }
;6  {
        add_bar_as_note(B_DIVISIO_MINOR_D6);
    }
:   {
        add_bar_as_note(B_DIVISIO_MAIOR);
    }
::  {
        add_bar_as_note(B_DIVISIO_FINALIS);
    }
r   {
        gregorio_change_shape(current_note, S_PUNCTUM_CAVUM);
    }
R   {
        gregorio_change_shape(current_note, S_LINEA_PUNCTUM);
    }
r0  {
        gregorio_change_shape(current_note, S_LINEA_PUNCTUM_CAVUM);
    }
r1  {
        gregorio_add_special_sign(current_note, _ACCENTUS);
    }
r2  {
        gregorio_add_special_sign(current_note, _ACCENTUS_REVERSUS);
    }
r3  {
        gregorio_add_special_sign(current_note, _CIRCULUS);
    }
r4  {
        gregorio_add_special_sign(current_note, _SEMI_CIRCULUS);
    }
r5  {
        gregorio_add_special_sign(current_note, _SEMI_CIRCULUS_REVERSUS);
    }
[a-mA-M]x {
        add_alteration(GRE_FLAT);
    }
[a-mA-M]# {
        add_alteration(GRE_SHARP);
    }
[a-mA-M]y {
        add_alteration(GRE_NATURAL);
    }
\/  {
        gregorio_add_space_as_note(&current_note, SP_NEUMATIC_CUT);
    }
\/\/ {
        gregorio_add_space_as_note(&current_note, SP_LARGER_SPACE);
    }
\   {
        gregorio_add_space_as_note(&current_note, SP_GLYPH_SPACE);
    }
!\/ {
        gregorio_add_space_as_note(&current_note, SP_NEUMATIC_CUT_NB);
    }
!\/\/ {
        gregorio_add_space_as_note(&current_note, SP_LARGER_SPACE_NB);
    }
!\  {
        gregorio_add_space_as_note(&current_note, SP_GLYPH_SPACE_NB);
    }
!/[^\/ ] {
        gregorio_add_space_as_note(&current_note, SP_ZERO_WIDTH);
    }
=   {
        gregorio_change_shape(current_note, S_LINEA);
    }
[a-mA-M]vv {
        lex_add_note(0, S_BIVIRGA, _NO_SIGN, L_NO_LIQUESCENTIA);
    }
[a-mA-M]vvv {
        lex_add_note(0, S_TRIVIRGA, _NO_SIGN, L_NO_LIQUESCENTIA);
    }
[a-mA-M]VV {
        lex_add_note(0, S_BIVIRGA, _NO_SIGN, L_NO_LIQUESCENTIA);
    }
[a-mA-M]VVV {
        lex_add_note(0, S_TRIVIRGA, _NO_SIGN, L_NO_LIQUESCENTIA);
    }
[a-mA-M]ss {
        lex_add_note(0, S_DISTROPHA, _NO_SIGN, L_NO_LIQUESCENTIA);
    }
[a-mA-M]ss(\<|\>) {
        lex_add_note(0, S_DISTROPHA, _NO_SIGN, L_AUCTA);
    }
[a-mA-M]sss {
        lex_add_note(0, S_TRISTROPHA, _NO_SIGN, L_NO_LIQUESCENTIA);
    }
[a-mA-M]sss(\<|\>) {
        lex_add_note(0, S_TRISTROPHA, _NO_SIGN, L_AUCTA);
    }
[a-mA-M] {
        lex_add_note(0, punctum(gabc_notes_determination_text[0]), _NO_SIGN,
                L_NO_LIQUESCENTIA);
    }
-[a-mA-M] { 
        lex_add_note(1, punctum(gabc_notes_determination_text[1]), _NO_SIGN,
                L_INITIO_DEBILIS);
    }
\'[01]? {
        add_sign(_V_EPISEMUS);
    }
_[0-5]* {
        add_h_episemus();
    }
\.[01]? {
        add_sign(_PUNCTUM_MORA);
    }
~   {
        gregorio_add_liquescentia(current_note, L_DEMINUTUS);
    }
>   {
        gregorio_add_liquescentia(current_note, L_AUCTUS_DESCENDENS);
    }
\<  {
        gregorio_add_liquescentia(current_note, L_AUCTUS_ASCENDENS);
    }
q   { 
        gregorio_change_shape(current_note, S_QUADRATUM);
    }
o   {
        gregorio_change_shape(current_note, S_ORISCUS);
    }
O   {
        gregorio_change_shape(current_note, S_ORISCUS_SCAPUS);
    }
w   {
        gregorio_change_shape(current_note, S_QUILISMA);
    }
W   {
        gregorio_change_shape(current_note, S_QUILISMA_QUADRATUM);
    }
v   {
        gregorio_change_shape(current_note, S_VIRGA);
    }
V   {
        gregorio_change_shape(current_note, S_VIRGA_REVERSA);
    }
s   {
        gregorio_change_shape(current_note, S_STROPHA);
    }
.   {        
        snprintf(tempstr, 70, _("unrecognized character: \"%c\""),
                gabc_notes_determination_text[0]);
        gregorio_message (tempstr, "det_notes_from_string", ERROR, 0);
    }

%%

gregorio_note *gabc_det_notes_from_string(char *str, char *newmacros[10])
{
    int i;
    YY_BUFFER_STATE buf;
    // a small optimization could uccur here: we could do it only once at the
    // beginning of the score, not at each syllable
    for (i = 0; i < 10; i++) {
        notesmacros[i] = newmacros[i];
    }
    tempstr = malloc(71 * sizeof(char));
    nbof_isolated_episemus = 0;
    current_note = NULL;
    buf = yy_scan_string(str);
    yylex();
    yy_flush_buffer(buf);
    yy_delete_buffer(buf);
    gregorio_go_to_first_note(&current_note);
    free(tempstr);
    return current_note;
}
