/* 
Gregorio OpusTeX output format.
Copyright (C) 2007 Olivier Berten

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

#include <stdio.h>
#include <stdlib.h>
#include "gettext.h"
#define _(str) gettext(str)
#define N_(str) str
#include "messages.h"
#include "struct.h"
#include <wchar.h>
#include <string.h>
#include "opustex.h"

int i;
int clef;
char loff = 0;
char centered = 0;
char italic = 0;
char key_change = 0;
char new_line = 0;

void
libgregorio_opustex_write_score (FILE * f, gregorio_score * score)
{
    if (score->number_of_voices != 1)
    {
        libgregorio_message (_
                             ("opustex only works in monophony (for the moment)"),
                             "libgregorio_opustex_write_score", ERROR, 0);
    }
    
    
    fprintf (f,
             "\\input opustex\n\\input opusgre\n\\input opuscho\n\n\\setgregorian1\n");
    // first we draw the initial (first letter) and the initial key
    char first_syllable = 0;
    char clef_letter;
    int clef_line;
    if (score->first_voice_info)
    {
        libgregorio_det_step_and_line_from_key (score->first_voice_info->
                                                initial_key, &clef_letter,
                                                &clef_line);
        if (clef_letter=='f')
        {
            fprintf (f, "\\setclefsymbol1\\gregorianFclef\n\\setclef1%d\n",
                     clef_line + 2);
        }
        else
        {
            fprintf (f, "\\setclef1%d\n", clef_line);
        }
    }
    else
    {
        fprintf (f, "\\setclef13\n");
    }
    // a char that will contain 1 if it is the first syllable and 0 if not. It is for the initial.
    fprintf (f,
             "\\musicindent10mm\n\\raisesong3\\Internote\n\\initiumgregorianum\n");
	gregorio_character *first_text=libgregorio_first_text (score);
    if (first_text)
    {
        fprintf (f, "\\musicinitial{}{");
        libgregorio_write_first_letter (first_text, f,
			      (&libgregorio_otex_write_verb),
			      (&libgregorio_otex_print_char),
			      (&libgregorio_otex_write_begin),
			      (&libgregorio_otex_write_end),
			      (&libgregorio_otex_write_special_char));
        fprintf (f, "}%%\n");
        first_syllable=SKIP_FIRST_LETTER;
    }

    clef = score->first_voice_info->initial_key;
    gregorio_syllable *current_syllable = score->first_syllable;
    while (current_syllable)
    {
        libgregorio_opustex_write_syllable (f, current_syllable,
                                            first_syllable);
        current_syllable = current_syllable->next_syllable;
    }
    fprintf (f, "\\bye\n");
}


char
libgregorio_opustex_is_out_of_neume (gregorio_syllable * syllable)
{
  if (!(syllable->text) && !(syllable->elements[1]) && syllable->elements[0]-> type != GRE_ELEMENT)
    {
      return 1;
    }
  return 0;
}

char
is_even (int c)
{
    if (c % 2 == 0)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

void
libgregorio_opustex_write_syllable (FILE * f, gregorio_syllable * syllable,
                                    char first_syllable)
{
    char finis = 0;
    gregorio_element *current_element = syllable->elements[0];
    if (libgregorio_opustex_is_out_of_neume (syllable))
    {
        if (current_element->type == GRE_BAR)
        {
            if (syllable->next_syllable)
            {
                fprintf (f, "\\");
                libgregorio_opustex_write_barline (f,
                                                   current_element->
                                                   element_type);
                fprintf (f, "\n\\spatium\n");
                current_element = current_element->next_element;
            }
            else
            {
                fprintf (f, "\\");
                libgregorio_opustex_write_finis (f,
                                                 current_element->element_type);
                fprintf (f, "\n");
                finis = 1;
            }
            key_change = 0;
            new_line = 0;
            return;
        }
        if (current_element->type == GRE_SPACE)
        {
            switch (current_element->element_type)
            {
                case SP_NO_SPACE:
                    fprintf (f, "\\nonspatium\n");
                break;
                case SP_ZERO_WIDTH:
                    fprintf (f, "\\Nonspatium\n");
                break;
                case SP_NEUMATIC_CUT:
                    fprintf (f, "\\spatiumparvum\n");
                break;
                case SP_LARGER_SPACE:
                    fprintf (f, " \\spatiumparvum\n");
                break;
                case SP_GLYPH_SPACE:
                    break;
                default:
                    fprintf (f, "\\spatium\n");
                break;
            }
            key_change = 0;
            new_line = 0;
            return;
        }
        char next_note = libgregorio_find_next_note (current_element, syllable);
        if  (syllable->next_syllable && syllable->next_syllable->elements[0] &&  syllable->next_syllable->elements[0]->type == GRE_END_OF_LINE)
        {
            new_line = 1;
        }
        if (current_element->type == GRE_C_KEY_CHANGE)
        {
            if (next_note != 0)
            {
                clef =
                    libgregorio_calculate_new_key (C_KEY,
                                                   current_element->element_type -
                                                   48);
                if (new_line == 1)
                {
                    fprintf (f, "\\loff{\\custos ");
                }
                else
                {
                    fprintf (f, "\\CUSTOS ");
                }
                libgregorio_opustex_print_note (f, next_note);
                if (new_line == 1)
                {
                    fprintf (f, "}\n");
                }
                fprintf (f,
                         "\\setclefsymbol1\\gregorianCclef\n\\setclef1%d\n",
                         current_element->element_type - 48);
                if (new_line == 1)
                {
                    fprintf (f, "\\lineaproxima\n");
                }
                else
                {
                    fprintf (f, "\\changeclefs\n");
                }
            }
            key_change = 1;
            new_line = 0;
            return;
        }
        if (current_element->type == GRE_F_KEY_CHANGE)
        {
            if (next_note != 0)
            {
                clef =
                    libgregorio_calculate_new_key (F_KEY,
                                                   current_element->element_type -
                                                   48);
                if (new_line == 1)
                {
                    fprintf (f, "\\loff{\\custos ");
                }
                else
                {
                    fprintf (f, "\\CUSTOS ");
                }
                libgregorio_opustex_print_note (f, next_note);
                if (new_line == 1)
                {
                    fprintf (f, "}\n");
                }
                fprintf (f,
                         "\\setclefsymbol1\\gregorianFclef\n\\setclef1%d\n",
                         current_element->element_type - 46);
                if (new_line == 1)
                {
                    fprintf (f, "\\lineaproxima\n");
                }
                else
                {
                    fprintf (f, "\\changeclefs\n");
                }
            }
            key_change = 1;
            new_line = 0;
            return;
        }
        if (current_element->type == GRE_END_OF_LINE)
        {
            if (next_note == 0 || (syllable->next_syllable && syllable->next_syllable->elements[0] &&  (syllable->next_syllable->elements[0]->type == GRE_C_KEY_CHANGE || syllable->next_syllable->elements[0]->type == GRE_F_KEY_CHANGE)) || key_change == 1)
            {
            }
            else
            {
                fprintf (f, "\\custos ");
                libgregorio_opustex_print_note (f, next_note);
                fprintf (f, "\n\\lineaproxima\n");
            }
            key_change = 0;
            new_line = 1;
            return;
        }
    }
    else
    {
        int nextposition=0;
        if (syllable->next_syllable)
        {
            nextposition = syllable->next_syllable->position;
        }
        fprintf (f, "\\sgn ");
        libgregorio_opustex_write_text (f, syllable->text, first_syllable);
        while (current_element)
        {
            if (current_element->type == GRE_SPACE)
            {
                switch (current_element->element_type)
                {
                    case SP_NO_SPACE:
                        fprintf (f, "\\nonspatium");
                    break;
                    case SP_ZERO_WIDTH:
                        fprintf (f, "\\Nonspatium");
                    break;
                    case SP_NEUMATIC_CUT:
                        fprintf (f, "\\spatiumparvum");
                    break;
                    case SP_LARGER_SPACE:
                        fprintf (f, " \\spatiumparvum");
                    break;
                    case SP_GLYPH_SPACE:
                        break;
                    default:
                        fprintf (f, "\\spatium");
                    break;
                }
                current_element = current_element->next_element;
                key_change = 0;
                new_line = 0;
                continue;
            }
            if (current_element->type == GRE_BAR)
            {
                fprintf (f, "\\");
                libgregorio_opustex_write_barline (f,
                                                   current_element->
                                                   element_type);
                fprintf (f, "\\spatium");	// OpusTeX: inside a neume, divisio needs to be followed by a spatium
                current_element = current_element->next_element;
                key_change = 0;
                new_line = 0;
                continue;
            }
            if (current_element->type == GRE_C_KEY_CHANGE
                || current_element->type == GRE_F_KEY_CHANGE)
            {
                libgregorio_message (_
                                     ("clef change inside of a syllable doesn't work in OpusTeX"),
                                     "libgregorio_opustex_write syllable",
                                     ERROR, 0);
                current_element = current_element->next_element;
                continue;
            }
            if (current_element->type == GRE_END_OF_LINE)
            {
                if (current_element->next_element && current_element->next_element->type == GRE_BAR)
                {
                    libgregorio_message (_
                                         ("line break cannot be placed before a divisio in OpusTeX"),
                                         "libgregorio_opustex_write syllable",
                                         ERROR, 0);
                }
                else
                {
                    char next_note = libgregorio_find_next_note (current_element, syllable);
                    if (next_note == 0 || (!(current_element->next_element) && (syllable->next_syllable && syllable->next_syllable->elements[0] && (syllable->next_syllable->elements[0]->type == GRE_C_KEY_CHANGE || syllable->next_syllable->elements[0]->type == GRE_F_KEY_CHANGE))) || key_change == 1)
                    {
                    }
                    else
                    {
                        fprintf (f, "\\custos ");
                        libgregorio_opustex_print_note (f, next_note);
                        fprintf (f, "\\lineaproxima");
                    }
                }
                current_element = current_element->next_element;
                key_change = 0;
                new_line = 1;
                continue;
            }
            libgregorio_opustex_write_element (f, syllable, current_element);
            current_element = current_element->next_element;
            key_change = 0;
            new_line = 0;
            continue;
        }
        if (loff >= 1)
        {
            fprintf (f, "}");
        }
        loff = 0;
        fprintf (f, "\\egn\n");
        if (nextposition
            && ((nextposition == WORD_BEGINNING)
                || (nextposition == WORD_ONE_SYLLABLE)))
        {
            fprintf (f, "\\spatium\n");
        }
    }
    if (!(syllable->next_syllable) && finis == 0)
    {
        fprintf (f, "\\Finisgregoriana\n");
    }
}


void
libgregorio_otex_write_begin (FILE * f, unsigned char style)
{
  switch (style)
    {
    case ST_ITALIC:
      fprintf (f, "{\\it ");
      break;
    case ST_SMALL_CAPS:
      fprintf (f, "{\\sc ");
      break;
    case ST_BOLD:
      fprintf (f, "{\\bf ");
      break;
    case ST_CENTER:
      fprintf (f, "}{");
      break;
    case ST_TT:
      fprintf (f, "{\\tt ");
      break;
    default:
      break;
    }
}

void
libgregorio_otex_write_end (FILE * f, unsigned char style)
{
  switch (style)
    {
    case ST_CENTER:
      fprintf (f, "}{");
      break;
    default:
      fprintf (f, "}");
      break;
    }
}

void
libgregorio_otex_write_special_char (FILE * f, wchar_t * special_char)
{
  if (!wcscmp(special_char, L"'æ"))
    {
	fprintf(f, "\\'ae");
	return;
    }
  if (!wcscmp(special_char, L"'œ"))
    {
	fprintf(f, "\\'oe");
	return;
    }
  if (!wcscmp(special_char, L"ae"))
    {
	fprintf(f, "\\ae");
	return;
    }
  if (!wcscmp(special_char, L"R/"))
    {
	fprintf(f, "\\s R");
	return;
    }
  if (!wcscmp(special_char, L"A/"))
    {
	fprintf(f, "\\s A");
	return;
    }
  if (!wcscmp(special_char, L"V/"))
    {
	fprintf(f, "\\s V");
	return;
    }
}

void
libgregorio_otex_write_verb (FILE * f, wchar_t * verb_str)
{
  fprintf (f, "%ls", verb_str);
}

void
libgregorio_otex_print_char (FILE * f, wchar_t to_print)
{
  switch (to_print) {
  case L'œ':
    fprintf (f, "\\oe ");
  break;
  case L'æ':
    fprintf (f, "\\ae ");
  break;
  case L'é':
    fprintf (f, "\\'e ");
  break;
  case L'è':
    fprintf (f, "\\`e ");
  break;
  case L'à':
    fprintf (f, "\\`a ");
  break;
  case L'ô':
    fprintf (f, "\\^o ");
  break;
  case L'î':
    fprintf (f, "\\^i ");
  break;
  case L'û':
    fprintf (f, "\\^u ");
  break;
  case L'ê':
    fprintf (f, "\\^e ");
  break;
  case L'ó':
    fprintf (f, "\\'o ");
  break;
  default:
  fprintf (f, "%lc", to_print);
  break;
}
}

void
libgregorio_opustex_write_text (FILE * f, gregorio_character * text, char first_syllable)
{
  if (text == NULL)
    {
      fprintf (f, "{}{}{}");
      return;
    }
  fprintf (f, "{");
      libgregorio_write_text (first_syllable, text, f,
			      (&libgregorio_otex_write_verb),
			      (&libgregorio_otex_print_char),
			      (&libgregorio_otex_write_begin),
			      (&libgregorio_otex_write_end),
			      (&libgregorio_otex_write_special_char));
  if (first_syllable) {
  first_syllable=0;
  }
  fprintf (f, "}");
}


void
libgregorio_opustex_write_element (FILE * f, gregorio_syllable * syllable,
                                   gregorio_element * element)
{
    gregorio_glyph *current_glyph = element->first_glyph;
    while (current_glyph)
    {
        if (current_glyph->type == GRE_SPACE)
        {
            // we assume here that it is a SP_ZERO_WIDTH, the only one a glyph can be
            if (loff != 1)
            {
                fprintf (f, "\\Nonspatium");
            }
            current_glyph = current_glyph->next_glyph;
            continue;
        }
        if (current_glyph->type == GRE_FLAT)
        {
            fprintf (f, "\\bmolle ");
            libgregorio_opustex_print_note (f, current_glyph->glyph_type);
            current_glyph = current_glyph->next_glyph;
            continue;
        }
        if (current_glyph->type == GRE_NATURAL)
        {
            fprintf (f, "\\bdurum ");
            libgregorio_opustex_print_note (f, current_glyph->glyph_type);
            current_glyph = current_glyph->next_glyph;
            continue;
        }
        if (current_glyph->type == GRE_BAR)
        {
            fprintf (f, "\\");
            libgregorio_opustex_write_barline (f, current_glyph->glyph_type);
            fprintf (f, "\n\\spatium\n");
            current_glyph = current_glyph->next_glyph;
            continue;
        }
        // at this point glyph->type is GRE_GLYPH
        libgregorio_opustex_write_glyph (f, syllable, element, current_glyph);
        current_glyph = current_glyph->next_glyph;
    }
}

void
libgregorio_opustex_write_barline (FILE * f, char type)
{
    switch (type)
    {
        case B_VIRGULA:
            fprintf (f, "virgula");
        break;
        case B_DIVISIO_MINIMA:
            fprintf (f, "divisiominima");
        break;
        case B_DIVISIO_MINOR:
            fprintf (f, "divisiominor");
        break;
        case B_DIVISIO_MAIOR:
            fprintf (f, "divisiomaior");
        break;
        case B_DIVISIO_FINALIS:
            fprintf (f, "divisiofinalis");
        break;
        default:
            libgregorio_message (_("unknown bar type"),
                                 "libgregorio_opustex_write_barline", ERROR, 0);
        break;
    }
}

void
libgregorio_opustex_write_finis (FILE * f, char type)
{
    switch (type)
    {
        case B_DIVISIO_MAIOR:
            fprintf (f, "finisgregoriana");
        break;
        default:
            fprintf (f, "Finisgregoriana");
        break;
    }
}

void
libgregorio_opustex_write_glyph (FILE * f, gregorio_syllable * syllable,
                                 gregorio_element * element,
                                 gregorio_glyph * glyph)
{
    if (!glyph)
    {
        libgregorio_message (_
                             ("called with NULL pointer"),
                             "libgregorio_opustex_write_glyph", ERROR, 0);
        return;
    }
    if (!glyph->first_note)
    {
        libgregorio_message (_
                             ("called with glyph without note"),
                             "libgregorio_opustex_write_glyph", ERROR, 0);
        return;
    }
    gregorio_note *current_note = NULL;
    if (loff == 1)
    {
        fprintf (f, "\\loff{");
        loff++;
    }
    current_note = glyph->first_note;
    while (current_note)
    {
        if (current_note->signs >= _V_EPISEMUS)
        {
            fprintf (f, "\\ictus ");
            libgregorio_opustex_print_note (f, current_note->pitch);
        }
        current_note = current_note->next_note;
    }
    current_note = glyph->first_note;
    int h_length = 0;
    int h_pitch = 0;
    // divide puncta_inclinata into single glyphs
    if (is_puncta_inclinata (glyph->glyph_type)
        || glyph->glyph_type == G_PUNCTA_INCLINATA)
    {
        if (glyph->first_note->signs >= _V_EPISEMUS)
        {
            fprintf (f, "\\ictus ");
            libgregorio_opustex_print_note (f, glyph->first_note->pitch);
        }
        fprintf (f, "\\punctuminclinatum ");
        libgregorio_opustex_print_note (f, glyph->first_note->pitch);
        current_note = glyph->first_note->next_note;
        while (current_note)
        {
            fprintf (f, "\\nonspatium");
            if (current_note->h_episemus_type == H_ALONE)
            {
                libgregorio_opustex_print_episem (f, current_note->pitch, 1);
            }
            if (current_note->signs >= _V_EPISEMUS)
            {
                fprintf (f, "\\ictus ");
                libgregorio_opustex_print_note (f, current_note->pitch);
            }
            fprintf (f, "\\punctuminclinatum ");
            libgregorio_opustex_print_note (f, current_note->pitch);
            current_note = current_note->next_note;
        }
        return;
    }
    else
    {
        if (glyph->glyph_type != G_PES)
        {
            while (current_note)
            {
                if (current_note->h_episemus_type == H_ALONE)
                {
                    libgregorio_opustex_print_episem (f, current_note->pitch, 1);
                }
                if (current_note->h_episemus_type == H_MULTI)
                {
                    h_length++;
                    h_pitch = current_note->h_episemus_top_note;
                }
                current_note = current_note->next_note;
            }
            if (h_length > 0)
            {
                libgregorio_opustex_print_episem (f, h_pitch, h_length);
            }
        }
        else
        {
            if (glyph->first_note->h_episemus_type > H_NO_EPISEMUS)
            {
                libgregorio_opustex_print_episem_under (f, glyph->first_note->pitch,
                                                        1);
            }
            if (glyph->first_note->next_note->h_episemus_type > H_NO_EPISEMUS)
            {
                libgregorio_opustex_print_episem (f,
                                                  glyph->first_note->next_note->
                                                  pitch, 1);
            }
        }
        
    }
    // special shapes
    if (glyph->glyph_type == G_DISTROPHA_AUCTA)
    {
        fprintf (f, "\\strophaaucta ");
        libgregorio_opustex_print_note (f, glyph->first_note->pitch);
        fprintf (f, "\\spatiumparvum\\strophaaucta ");
        libgregorio_opustex_print_note (f, glyph->first_note->pitch);
        return;
    }
    if (glyph->glyph_type == G_TRISTROPHA_AUCTA)
    {
        fprintf (f, "\\strophaaucta ");
        libgregorio_opustex_print_note (f, glyph->first_note->pitch);
        fprintf (f, "\\spatiumparvum\\strophaaucta ");
        libgregorio_opustex_print_note (f, glyph->first_note->pitch);
        fprintf (f, "\\spatiumparvum\\strophaaucta ");
        libgregorio_opustex_print_note (f, glyph->first_note->pitch);
        return;
    }
    if (glyph->glyph_type == G_PUNCTUM && glyph->first_note->shape == S_ORISCUS)
    {
        fprintf (f, "\\oriscus ");
        libgregorio_opustex_print_note (f, glyph->first_note->pitch);
        return;
    }
    if (glyph->glyph_type == G_PUNCTUM
        && glyph->first_note->shape == S_ORISCUS_AUCTUS)
    {
        fprintf (f, "\\oriscusreversus ");
        libgregorio_opustex_print_note (f, glyph->first_note->pitch);
        return;
    }
    if (glyph->glyph_type == G_PUNCTUM
        && glyph->first_note->shape == S_QUILISMA)
    {
        fprintf (f, "\\quilisma ");
        libgregorio_opustex_print_note (f, glyph->first_note->pitch);
        return;
    }
    // pes quassus
        if (glyph->glyph_type == G_PES && glyph->first_note->shape == S_ORISCUS)
    {
        fprintf (f, "\\pesquassus ");
    }
    else
    {
        // quilisma
            char *quilisma = "";
        if (glyph->first_note->shape == S_QUILISMA
            && (glyph->glyph_type == G_PES || glyph->glyph_type == G_TORCULUS))
        {
            quilisma = "quilisma";
        }
        if (glyph->first_note->shape == S_QUILISMA
            && glyph->glyph_type == G_PES_QUADRATUM)
        {
            quilisma = "Quilisma";
        }
        //print glyph name
            fprintf (f, "\\%s%s", quilisma,
                     libgregorio_opustex_glyph_type_to_str (glyph->glyph_type));
    }
    if (glyph->liquescentia)
    {
        libgregorio_opustex_print_liquescentia (f, glyph->liquescentia,
                                                glyph->glyph_type);
    }
    fprintf (f, " ");
    //print the notes of the glyph
        current_note = glyph->first_note;
    while (current_note)
    {
        libgregorio_opustex_print_note (f, current_note->pitch);
        current_note = current_note->next_note;
    }
    char augmentum;
    current_note = glyph->first_note;
    while (current_note)
    {
        if (current_note->signs == _PUNCTUM_MORA
            || current_note->signs == _V_EPISEMUS_PUNCTUM_MORA)
        {
            fprintf (f, "\\augmentum ");
            libgregorio_opustex_print_augmentum_note (f, current_note->pitch);
            augmentum = 1;
        }
        if (current_note->signs == _AUCTUM_DUPLEX
            || current_note->signs == _V_EPISEMUS_AUCTUM_DUPLEX)
        {
            fprintf (f, "\\augmentumduplex ");
            libgregorio_opustex_print_augmentum_note (f, current_note->pitch);
            libgregorio_opustex_print_augmentum_note (f,
                                                      current_note->
                                                      previous_note->pitch);
            augmentum = 1;
        }
        current_note = current_note->next_note;
    }
    if (augmentum == 1 && glyph->next_glyph
        && glyph->next_glyph->type == GRE_SPACE
        && glyph->next_glyph->glyph_type == SP_ZERO_WIDTH)
        loff++;
}

void
libgregorio_opustex_print_note (FILE * f, char pitch)
{
    if (is_even (clef))
    {
        if (pitch - clef < 104)
        {
            fprintf (f, "%c", pitch - clef - 25);
        }
        else
        {
            fprintf (f, "%c", pitch - clef - 7);
        }
    }
    else
    {
        if (pitch - clef < 97)
        {
            fprintf (f, "%c", pitch - clef - 18);
        }
        else
        {
            fprintf (f, "%c", pitch - clef);
        }
    }
}

void
libgregorio_opustex_print_episem (FILE * f, char pitch, char length)
{
    int realpitch;
    if (is_even (clef))
    {
        if (pitch - clef < 104)
        {
            realpitch = pitch - clef - 25;
        }
        else
        {
            realpitch = pitch - clef - 7;
        }
    }
    else
    {
        if (pitch - clef < 97)
        {
            realpitch = pitch - clef - 18;
        }
        else
        {
            realpitch = pitch - clef;
        }
    }
    if (!is_even(pitch) && pitch < 'k') // if the note is between staff lines
    {
        fprintf (f, "\\episem %c%d", realpitch + 2, length);
    }
    else
    {
        fprintf (f, "\\episem %c%d", realpitch + 1, length);
    }
}

void
libgregorio_opustex_print_episem_under (FILE * f, char pitch, char length)
{
    int realpitch;
    if (is_even (clef))
    {
        if (pitch - clef < 104)
        {
            realpitch = pitch - clef - 25;
        }
        else
        {
            realpitch = pitch - clef - 7;
        }
    }
    else
    {
        if (pitch - clef < 97)
        {
            realpitch = pitch - clef - 18;
        }
        else
        {
            realpitch = pitch - clef;
        }
    }
    if (!is_even(pitch) && pitch > 'c') // if the note is between staff lines
    {
        fprintf (f, "\\episem %c%d", realpitch - 2, length);
    }
    else
    {
        fprintf (f, "\\episem %c%d", realpitch - 1, length);
    }
}


void
libgregorio_opustex_print_augmentum_note (FILE * f, char pitch)
{
    int realpitch;
    if (is_even (clef))
    {
        if (pitch - clef < 104)
        {
            realpitch = pitch - clef - 25;
        }
        else
        {
            realpitch = pitch - clef - 7;
        }
    }
    else
    {
        if (pitch - clef < 97)
        {
            realpitch = pitch - clef - 18;
        }
        else
        {
            realpitch = pitch - clef;
        }
    }
    if (is_even (realpitch))
    {
        fprintf (f, "%c", realpitch);
    }
    else
    {
        fprintf (f, "%c", realpitch + 1);
    }
}
char *
libgregorio_opustex_glyph_type_to_str (char name)
{
    char *str="";
    switch (name)
    {
        case G_PUNCTUM_INCLINATUM:
            str = "punctuminclinatum";
        break;
        case G_TRIGONUS:
            str = "trigonus";
        break;
        case G_VIRGA:
            str = "virga";
        break;
        case G_STROPHA:
            str = "stropha";
        break;
        case G_PUNCTUM:
            str = "punctum";
        break;
        case G_PES:
            str = "pes";
        break;
        case G_PES_QUADRATUM:	//doesn't exist in OpusTeX
            str = "pes";
        libgregorio_message (_("pes quadratum doesn't exist in OpusTeX"),
                             "libgregorio_opustex_glyph_type_to_str", ERROR, 0);
        break;
        case G_FLEXA:
            str = "clivis";
        break;
        case G_TORCULUS:
            str = "torculus";
        break;
        case G_TORCULUS_RESUPINUS:
            str = "torculusresupinus";
        break;
        case G_TORCULUS_RESUPINUS_FLEXUS:
            libgregorio_message (_
                                 ("torculus_resupinus_flexus doesn't exist in OpusTeX"),
                                 "libgregorio_opustex_glyph_type_to_str", ERROR, 0);
        break;
        case G_PORRECTUS:
            str = "porrectus";
        break;
        case G_PORRECTUS_FLEXUS:
            str = "porrectusflexus";
        break;
        case G_BIVIRGA:
            str = "varbivirga";
        break;
        case G_TRIVIRGA:
            str = "vartrivirga";
        break;
        case G_DISTROPHA:
            str = "distropha";
        break;
        case G_TRISTROPHA:
            str = "tristropha";
        break;
        case G_SCANDICUS:
            str = "scandicus";
        break;
        default:
        break;
    }
    return str;
}

void
libgregorio_opustex_print_liquescentia (FILE * f, char liquescentia,
                                        char glyph)
{
    char *suffix = "us";
    if (glyph == G_FLEXA || glyph == G_STROPHA)
    {
        suffix = "a";
    }
    if (glyph <= G_PUNCTUM_INCLINATUM)
    {
        suffix = "um";
    }
    switch (liquescentia)
    {
        case L_DEMINUTUS:
            if (glyph == G_TORCULUS || glyph == G_PORRECTUS
                || glyph == G_TORCULUS_RESUPINUS)
        {
            fprintf (f, "deminutus");
        }
        else
        {
            libgregorio_message (_("that glyph cannot be deminutus in OpusTeX"),
                                 "libgregorio_opustex_print_liquescentia",
                                 ERROR, 0);
        }
        break;
        case L_AUCTUS_ASCENDENS:
            if (glyph == G_PUNCTUM || glyph == G_PES || glyph == G_FLEXA)
        {
            fprintf (f, "auct%sascendens", suffix);
        }
        else
        {
            libgregorio_message (_
                                 ("that glyph cannot be auctus ascendens in OpusTeX"),
                                 "libgregorio_opustex_print_liquescentia",
                                 ERROR, 0);
        }
        break;
        case L_AUCTUS_DESCENDENS:
            if (glyph == G_PUNCTUM || glyph == G_PES || glyph == G_FLEXA
                || glyph == G_TORCULUS || glyph == G_PORRECTUS)
        {
            fprintf (f, "auct%sdescendens", suffix);
        }
        else
        {
            libgregorio_message (_
                                 ("that glyph cannot be auctus descendens in OpusTeX"),
                                 "libgregorio_opustex_print_liquescentia",
                                 ERROR, 0);
        }
        break;
        case L_AUCTA:
            if (glyph == G_PUNCTUM_INCLINATUM || glyph == G_STROPHA)
        {
            fprintf (f, "auct%s", suffix);
        }
        else
        {
            libgregorio_message (_("that glyph cannot be auctus in OpusTeX"),
                                 "libgregorio_opustex_print_liquescentia",
                                 ERROR, 0);
        }
        break;
        case L_INITIO_DEBILIS:
            if (glyph == G_PES || glyph == G_TORCULUS || glyph == G_PORRECTUS)
        {
            fprintf (f, "initiodebilis");
        }
        else
        {
            libgregorio_message (_
                                 ("that glyph cannot have initio debilis in OpusTeX"),
                                 "libgregorio_opustex_print_liquescentia",
                                 ERROR, 0);
        }
        break;
        case L_DEMINUTUS_INITIO_DEBILIS:
            if (glyph == G_TORCULUS)
        {
            fprintf (f, "deminitusinitiodebilis");
        }
        else
        {
            libgregorio_message (_
                                 ("that glyph cannot be deminutus initio debilis in OpusTeX"),
                                 "libgregorio_opustex_print_liquescentia",
                                 ERROR, 0);
        }
        break;
        case L_AUCTUS_ASCENDENS_INITIO_DEBILIS:
            libgregorio_message (_
                                 ("there's no auctus ascendens initio debilis in OpusTeX"),
                                 "libgregorio_opustex_print_liquescentia", ERROR,
                                 0);
        break;
        case L_AUCTUS_DESCENDENS_INITIO_DEBILIS:
            if (glyph == G_PES || glyph == G_TORCULUS)
        {
            fprintf (f, "auctus descendens initiodebilis");
        }
        else
        {
            libgregorio_message (_
                                 ("that glyph cannot be auctus descendens initio debilis in OpusTeX"),
                                 "libgregorio_opustex_print_liquescentia",
                                 ERROR, 0);
        }
        break;
        case L_AUCTA_INITIO_DEBILIS:
            libgregorio_message (_("there's no aucta initio debilis in OpusTeX"),
                                 "libgregorio_opustex_print_liquescentia", ERROR,
                                 0);
        break;
    }
}

char
libgregorio_find_next_note (gregorio_element * current_element, gregorio_syllable * current_syllable)
{
    gregorio_element * next_element = current_element->next_element;
    gregorio_element * element_element = NULL;
    char stop = 0;
    while (stop == 0)
    {
        if (next_element)
        {
            if (next_element->type == GRE_ELEMENT)
            {
                element_element = next_element;
                stop = 1;
            }
            else
            {
                next_element = next_element->next_element;
            }
        }
        else
        {
            if (current_syllable->next_syllable)
            {
                current_syllable = current_syllable->next_syllable;
                next_element = current_syllable->elements[0];
            }
            else
            {
                stop = 1;
            }
        }
    }
    gregorio_glyph * next_glyph = NULL;
    if (element_element)
    {
        next_glyph = element_element->first_glyph;
        while (next_glyph->type != GRE_GLYPH)
        {
            next_glyph = next_glyph->next_glyph;
        }
    }
    if (next_glyph)
    {
        return next_glyph->first_note->pitch;
    }
    return 0;
}
