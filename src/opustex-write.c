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
    int first_letter = libgregorio_opustex_first_letter (score);
    if (first_letter)
    {
        fprintf (f, "\\musicinitial{}{");
        libgregorio_opustex_print_char (f, first_letter);
        fprintf (f, "}%%\n");
        if (first_letter < 128)
        {
            first_syllable = 1;
        }
        else
        {
            first_syllable = 2;
        }
    }
    clef = score->first_voice_info->initial_key;
    gregorio_syllable *current_syllable = score->first_syllable;
    while (current_syllable)
    {
        libgregorio_opustex_write_syllable (f, current_syllable,
                                            first_syllable);
        current_syllable = current_syllable->next_syllable;
        first_syllable = 0;
    }
    fprintf (f, "\\bye\n");
}

int
libgregorio_opustex_first_letter (gregorio_score * score)
{
    if (!score || !score->first_syllable || !score->first_syllable->syllable)
    {
        libgregorio_message (_("unable to find the first letter of the score"),
                             "libgregorio_opustex_first_letter", ERROR, 0);
        return 0;
    }
    if (score->first_syllable->syllable[0] > 0)
    {
        return score->first_syllable->syllable[0];
    }
    else
    {
        if (score->first_syllable->syllable[0] > -63
            && score->first_syllable->syllable[0] < -32)
        {
            return score->first_syllable->syllable[1] +
                (score->first_syllable->syllable[0] + 66) * 64;
        }
        else
        {
            libgregorio_message (_
                                 ("unable to find the first letter of the score"),
                                 "libgregorio_opustex_first_letter", ERROR, 0);
            return 0;
        }
    }
}

char
libgregorio_opustex_is_out_of_neume (gregorio_syllable * syllable)
{
  if (!(syllable->syllable) && !(syllable->elements[1]) && syllable->elements[0]-> type != GRE_ELEMENT)
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
        libgregorio_opustex_write_text (f, syllable->syllable, nextposition,
                                        first_syllable);
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

char
libgregorio_opustex_is_vowel (int c)
{
    if (c == 65 || c == 69 || c == 73 || c == 79 || c == 85 || c == 89
        || c == 97 || c == 101 || c == 105 || c == 111 || c == 117 || c == 121
        || c == 192 || c == 193 || c == 194 || c == 195 || c == 196 || c == 197
        || c == 198 || c == 200 || c == 201 || c == 202 || c == 203 || c == 204
        || c == 205 || c == 206 || c == 207 || c == 210 || c == 211 || c == 212
        || c == 213 || c == 214 || c == 216 || c == 217 || c == 218 || c == 219
        || c == 220 || c == 221 || c == 224 || c == 225 || c == 226 || c == 227
        || c == 228 || c == 229 || c == 230 || c == 232 || c == 233 || c == 234
        || c == 235 || c == 236 || c == 237 || c == 238 || c == 239 || c == 242
        || c == 243 || c == 244 || c == 245 || c == 246 || c == 248 || c == 249
        || c == 250 || c == 251 || c == 252 || c == 253 || c == 255 || c == 256
        || c == 257 || c == 258 || c == 259 || c == 274 || c == 275 || c == 276
        || c == 277 || c == 278 || c == 279 || c == 280 || c == 281 || c == 282
        || c == 283 || c == 305 || c == 461 || c == 462 || c == 463 || c == 464
        || c == 465 || c == 466 || c == 467 || c == 468)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

void
libgregorio_opustex_write_text (FILE * f, char *syllable, char nextposition,
                                char first_syllable)
{
    size_t len = 0;
    if (syllable)
    {
        len = strlen (syllable);
    }
  char vowel = 0;
  char middle = 0;
  char centered_start = 0;
  char centered_stop = 0;
  char italic_start = 0;
  char italic_stop = 0;
  char special_char = 0;
  char mute_ending = 0;
  char gq = 0;
  char vowels = 0;
  for (i = first_syllable; i < len; i++)
    {
      int c=0;
      if (syllable[i] > 31)
	{
	  c = syllable[i];
	}
      if (syllable[i] > -63 && syllable[i] < -32)
	{
	  int subchar = syllable[i];
	  i++;
	  c = syllable[i] + (subchar + 66) * 64;
	}
      if (c == '{')
	{
	  centered_start++;
	}
      if (c == '}')
	{
	  centered_stop++;
	}
      if (c == '<')
	{
	  italic_start++;
	}
      if (c == '>')
	{
	  italic_stop++;
	}
      if (c == '\\')
	{
	  special_char++;
	}
      if (libgregorio_opustex_is_vowel (c) != 0)
	{
	  vowels++;
	}
    }
  if (centered_start == 1 && centered_stop == 1)
    {
      centered = 1;
    }
  if (italic_start == italic_stop)
    {
      italic = 1;
    }
  if (vowels == 0)
    {
      fprintf (f, "{}");
    }
  fprintf (f, "{");
  for (i = first_syllable; i < len; i++)
    {
        int c=0;
        if (syllable[i] > 31)
        {
            c = syllable[i];
        }
        if (syllable[i] > -63 && syllable[i] < -32)
        {
            int subchar = syllable[i];
            i++;
            c = syllable[i] + (subchar + 66) * 64;
        }
        if (centered == 1)
        {
            libgregorio_opustex_print_char (f, c);
            continue;
        }
        if (libgregorio_opustex_is_vowel (c) == 0)
        {
            if (vowel == 0 || middle == 1)
            {
                libgregorio_opustex_print_char (f, c);
            }
            else
            {
                if (italic == 2)
                {
                    fprintf (f, "}}{\\it{");
                }
                else
                {
                    fprintf (f, "}{");
                }
                libgregorio_opustex_print_char (f, c);
                vowel = 0;
                middle = 1;
            }
            if (c == 'g' || c == 'q' || c == 'G' || c == 'Q')
            {
                gq = 1;
            }
            else
            {
                gq = 0;
            }
        }
        else
        {
            if (vowel == 0)
            {
                if (c == 'u' && gq == 1)
                {
                    libgregorio_opustex_print_char (f, c);
                }
                else
                {
                    if (middle == 0)
                    {
                        if (italic == 2)
                        {
                            fprintf (f, "}}{\\it{");
                        }
                        else
                        {
                            fprintf (f, "}{");
                        }
                        libgregorio_opustex_print_char (f, c);
                        vowel = 1;
                    }
                    else
                    {
                        if (italic != 2)
                        {
                            fprintf (f, "\\it{");
                        }
                        libgregorio_opustex_print_char (f, c);
                        vowel = 1;
                        if (italic != 2)
                        {
                            mute_ending = 1;
                        }
                    }
                }
            }
            else
            {
                libgregorio_opustex_print_char (f, c);
                vowel = 1;
            }
            gq = 0;
        }
    }
    if (vowel == 1 && middle == 0)
    {
        fprintf (f, "}{");
    }
    if (mute_ending == 1)
    {
        fprintf (f, "}");
    }
    /*  if (nextposition
    && ((nextposition == WORD_BEGINNING)
    || (nextposition == WORD_ONE_SYLLABLE)))
    {
    }
    else
    {
    fprintf (f, "-");
    }*/
    fprintf (f, "}");
  if (vowels == 0)
    {
        fprintf (f, "{}");
    }
    centered = 0;
    italic = 0;
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

void
libgregorio_opustex_print_char (FILE * f, int c)
{
    int printed = 0;
    if (c < 128 && c != 35 && c != 36 && c != 37 && c != 38 && c != 60 && c != 62 && c != 95
        && c != 123 && c != 124 && c != 125 && c != 126)
    {
        fprintf (f, "%c", c);
        printed = 1;
    }
    if (c == 35)
    {
        fprintf (f, "\\#");
        printed = 1;
    }
    if (c == 36)
    {
        fprintf (f, "\\$");
        printed = 1;
    }
    if (c == 37)
    {
        fprintf (f, "\\%%");
        printed = 1;
    }
    if (c == 38)
    {
        fprintf (f, "\\&");
        printed = 1;
    }
    if (c == 60)
    {
        if (italic == 1)
        {
            fprintf (f, "\\it{");
            italic = 2;
        }
        else
        {
            fprintf (f, "\\textless");
        }
        printed = 1;
    }
    if (c == 62)
    {
        if (italic == 2)
        {
            fprintf (f, "}");
            italic = 1;
        }
        else
        {
            fprintf (f, "\\textgreater");
        }
        printed = 1;
    }
    if (c == 95)
    {
        fprintf (f, "\\_");
        printed = 1;
    }
    if (c == 123) // left brace - we don't print it because it breaks OpusTeX
    {
        if (centered == 1)
        {
            if (italic == 2)
            {
                fprintf (f, "}}{\\it{");
            }
            else
            {
                fprintf (f, "}{");
            }
        }
        printed = 1;
    }
    if (c == 124)
    {
        fprintf (f, "\\textbar");
        printed = 1;
    }
    if (c == 125) // right brace - we don't print it because it breaks OpusTeX
    {
        if (centered == 1)
        {
            if (italic == 2)
            {
                fprintf (f, "}}{\\it{");
            }
            else
            {
                fprintf (f, "}{");
            }
        }
        printed = 1;
    }
    if (c == 126)
    {
        fprintf (f, "$\\sim$");
        printed = 1;
    }
    if (c == 161)
    {
        fprintf (f, "!`");
        printed = 1;
    }
    if (c == 167)
    {
        fprintf (f, "\\S{}");
        printed = 1;
    }
    if (c == 168)
    {
        fprintf (f, "\\\"{}");
        printed = 1;
    }
    if (c == 169)
    {
        fprintf (f, "\\copyright{}");
        printed = 1;
    }
    if (c == 173)
    {
        fprintf (f, "\\-");
        printed = 1;
    }
    if (c == 175)
    {
        fprintf (f, "\\={}");
        printed = 1;
    }
    if (c == 176)
    {
        fprintf (f, "$^\\circ$");
        printed = 1;
    }
    if (c == 177)
    {
        fprintf (f, "$\\pm$");
        printed = 1;
    }
    if (c == 178)
    {
        fprintf (f, "$^2$");
        printed = 1;
    }
    if (c == 179)
    {
        fprintf (f, "$^3$");
        printed = 1;
    }
    if (c == 180)
    {
        fprintf (f, "\\'{}");
        printed = 1;
    }
    if (c == 181)
    {
        fprintf (f, "$\\mu$");
        printed = 1;
    }
    if (c == 182)
    {
        fprintf (f, "\\P{}");
        printed = 1;
    }
    if (c == 183)
    {
        fprintf (f, "$\\cdot$");
        printed = 1;
    }
    if (c == 184)
    {
        fprintf (f, "\\c{ }");
        printed = 1;
    }
    if (c == 185)
    {
        fprintf (f, "$^1$");
        printed = 1;
    }
    if (c == 191)
    {
        fprintf (f, "?`");
        printed = 1;
    }
    if (c == 192)
    {
        fprintf (f, "\\`A");
        printed = 1;
    }
    if (c == 193)
    {
        fprintf (f, "\\'A");
        printed = 1;
    }
    if (c == 194)
    {
        fprintf (f, "\\^A");
        printed = 1;
    }
    if (c == 195)
    {
        fprintf (f, "\\~A");
        printed = 1;
    }
    if (c == 196)
    {
        fprintf (f, "\\\"A");
        printed = 1;
    }
    if (c == 197)
    {
        fprintf (f, "\\r{A}");
        printed = 1;
    }
    if (c == 198)
    {
        fprintf (f, "{\\AE}");
        printed = 1;
    }
    if (c == 199)
    {
        fprintf (f, "\\c{C}");
        printed = 1;
    }
    if (c == 200)
    {
        fprintf (f, "\\`E");
        printed = 1;
    }
    if (c == 201)
    {
        fprintf (f, "\\'E");
        printed = 1;
    }
    if (c == 202)
    {
        fprintf (f, "\\^E");
        printed = 1;
    }
    if (c == 203)
    {
        fprintf (f, "\\\"E");
        printed = 1;
    }
    if (c == 204)
    {
        fprintf (f, "\\`I");
        printed = 1;
    }
    if (c == 205)
    {
        fprintf (f, "\\'I");
        printed = 1;
    }
    if (c == 206)
    {
        fprintf (f, "\\^I");
        printed = 1;
    }
    if (c == 207)
    {
        fprintf (f, "\\\"I");
        printed = 1;
    }
    if (c == 208)
    {
        fprintf (f, "{\\DH}");
        printed = 1;
    }
    if (c == 209)
    {
        fprintf (f, "\\~N");
        printed = 1;
    }
    if (c == 210)
    {
        fprintf (f, "\\`O");
        printed = 1;
    }
    if (c == 211)
    {
        fprintf (f, "\\'O");
        printed = 1;
    }
    if (c == 212)
    {
        fprintf (f, "\\^O");
        printed = 1;
    }
    if (c == 213)
    {
        fprintf (f, "\\~O");
        printed = 1;
    }
    if (c == 214)
    {
        fprintf (f, "\\\"O");
        printed = 1;
    }
    if (c == 215)
    {
        fprintf (f, "$\\times$");
        printed = 1;
    }
    if (c == 216)
    {
        fprintf (f, "{\\O}");
        printed = 1;
    }
    if (c == 217)
    {
        fprintf (f, "\\`U");
        printed = 1;
    }
    if (c == 218)
    {
        fprintf (f, "\\'U");
        printed = 1;
    }
    if (c == 219)
    {
        fprintf (f, "\\^U");
        printed = 1;
    }
    if (c == 220)
    {
        fprintf (f, "\\\"U");
        printed = 1;
    }
    if (c == 221)
    {
        fprintf (f, "\\'Y");
        printed = 1;
    }
    if (c == 222)
    {
        fprintf (f, "{\\TH}");
        printed = 1;
    }
    if (c == 223)
    {
        fprintf (f, "{\\ss}");
        printed = 1;
    }
    if (c == 224)
    {
        fprintf (f, "\\`a");
        printed = 1;
    }
    if (c == 225)
    {
        fprintf (f, "\\'a");
        printed = 1;
    }
    if (c == 226)
    {
        fprintf (f, "\\^a");
        printed = 1;
    }
    if (c == 227)
    {
        fprintf (f, "\\~a");
        printed = 1;
    }
    if (c == 228)
    {
        fprintf (f, "\\\"a");
        printed = 1;
    }
    if (c == 229)
    {
        fprintf (f, "\\r{a}");
        printed = 1;
    }
    if (c == 230)
    {
        fprintf (f, "{\\ae}");
        printed = 1;
    }
    if (c == 231)
    {
        fprintf (f, "\\c{c}");
        printed = 1;
    }
    if (c == 232)
    {
        fprintf (f, "\\`e");
        printed = 1;
    }
    if (c == 233)
    {
        fprintf (f, "\\'e");
        printed = 1;
    }
    if (c == 234)
    {
        fprintf (f, "\\^e");
        printed = 1;
    }
    if (c == 235)
    {
        fprintf (f, "\\\"e");
        printed = 1;
    }
    if (c == 236)
    {
        fprintf (f, "{\\`\\i}");
        printed = 1;
    }
    if (c == 237)
    {
        fprintf (f, "{\\'\\i}");
        printed = 1;
    }
    if (c == 238)
    {
        fprintf (f, "{\\^\\i}");
        printed = 1;
    }
    if (c == 239)
    {
        fprintf (f, "{\\\"\\i}");
        printed = 1;
    }
    if (c == 240)
    {
        fprintf (f, "{\\dh}");
        printed = 1;
    }
    if (c == 241)
    {
        fprintf (f, "\\~n");
        printed = 1;
    }
    if (c == 242)
    {
        fprintf (f, "\\`o");
        printed = 1;
    }
    if (c == 243)
    {
        fprintf (f, "\\'o");
        printed = 1;
    }
    if (c == 244)
    {
        fprintf (f, "\\^o");
        printed = 1;
    }
    if (c == 245)
    {
        fprintf (f, "\\~o");
        printed = 1;
    }
    if (c == 246)
    {
        fprintf (f, "\\\"o");
        printed = 1;
    }
    if (c == 247)
    {
        fprintf (f, "$\\div$");
        printed = 1;
    }
    if (c == 248)
    {
        fprintf (f, "{\\o}");
        printed = 1;
    }
    if (c == 249)
    {
        fprintf (f, "\\`u");
        printed = 1;
    }
    if (c == 250)
    {
        fprintf (f, "\\'u");
        printed = 1;
    }
    if (c == 251)
    {
        fprintf (f, "\\^u");
        printed = 1;
    }
    if (c == 252)
    {
        fprintf (f, "\\\"u");
        printed = 1;
    }
    if (c == 253)
    {
        fprintf (f, "\\'y");
        printed = 1;
    }
    if (c == 254)
    {
        fprintf (f, "{\\th}");
        printed = 1;
    }
    if (c == 255)
    {
        fprintf (f, "\\\"y");
        printed = 1;
    }
    if (c == 256)
    {
        fprintf (f, "\\=A");
        printed = 1;
    }
    if (c == 257)
    {
        fprintf (f, "\\=a");
        printed = 1;
    }
    if (c == 258)
    {
        fprintf (f, "\\u{A}");
        printed = 1;
    }
    if (c == 259)
    {
        fprintf (f, "\\u{a}");
        printed = 1;
    }
    if (c == 262)
    {
        fprintf (f, "\\'C");
        printed = 1;
    }
    if (c == 263)
    {
        fprintf (f, "\\'c");
        printed = 1;
    }
    if (c == 264)
    {
        fprintf (f, "\\^C");
        printed = 1;
    }
    if (c == 265)
    {
        fprintf (f, "\\^c");
        printed = 1;
    }
    if (c == 266)
    {
        fprintf (f, "\\.C");
        printed = 1;
    }
    if (c == 267)
    {
        fprintf (f, "\\.c");
        printed = 1;
    }
    if (c == 268)
    {
        fprintf (f, "\\v{C}");
        printed = 1;
    }
    if (c == 269)
    {
        fprintf (f, "\\v{c}");
        printed = 1;
    }
    if (c == 270)
    {
        fprintf (f, "\\v{D}");
        printed = 1;
    }
    if (c == 271)
    {
        fprintf (f, "\\v{d}");
        printed = 1;
    }
    if (c == 272)
    {
        fprintf (f, "{\\DJ}");
        printed = 1;
    }
    if (c == 273)
    {
        fprintf (f, "{\\dj}");
        printed = 1;
    }
    if (c == 274)
    {
        fprintf (f, "\\=E");
        printed = 1;
    }
    if (c == 275)
    {
        fprintf (f, "\\=e");
        printed = 1;
    }
    if (c == 276)
    {
        fprintf (f, "\\u{E}");
        printed = 1;
    }
    if (c == 277)
    {
        fprintf (f, "\\u{e}");
        printed = 1;
    }
    if (c == 278)
    {
        fprintf (f, "\\.E");
        printed = 1;
    }
    if (c == 279)
    {
        fprintf (f, "\\.e");
        printed = 1;
    }
    if (c == 282)
    {
        fprintf (f, "\\v{E}");
        printed = 1;
    }
    if (c == 283)
    {
        fprintf (f, "\\v{e}");
        printed = 1;
    }
    if (c == 284)
    {
        fprintf (f, "\\^G");
        printed = 1;
    }
    if (c == 285)
    {
        fprintf (f, "\\^g");
        printed = 1;
    }
    if (c == 286)
    {
        fprintf (f, "\\u{G}");
        printed = 1;
    }
    if (c == 287)
    {
        fprintf (f, "\\u{g}");
        printed = 1;
    }
    if (c == 288)
    {
        fprintf (f, "\\.G");
        printed = 1;
    }
    if (c == 289)
    {
        fprintf (f, "\\.g");
        printed = 1;
    }
    if (c == 290)
    {
        fprintf (f, "\\c{G}");
        printed = 1;
    }
    if (c == 291)
    {
        fprintf (f, "\\c{g}");
        printed = 1;
    }
    if (c == 292)
    {
        fprintf (f, "\\^H");
        printed = 1;
    }
    if (c == 293)
    {
        fprintf (f, "\\^h");
        printed = 1;
    }
    if (c == 305)
    {
        fprintf (f, "{\\i}");
        printed = 1;
    }
    if (c == 317)
    {
        fprintf (f, "\\v{L}");
        printed = 1;
    }
    if (c == 318)
    {
        fprintf (f, "\\v{l}");
        printed = 1;
    }
    if (c == 327)
    {
        fprintf (f, "\\v{N}");
        printed = 1;
    }
    if (c == 328)
    {
        fprintf (f, "\\v{n}");
        printed = 1;
    }
    if (c == 344)
    {
        fprintf (f, "\\v{R}");
        printed = 1;
    }
    if (c == 345)
    {
        fprintf (f, "\\v{r}");
        printed = 1;
    }
    if (c == 352)
    {
        fprintf (f, "\\v{S}");
        printed = 1;
    }
    if (c == 353)
    {
        fprintf (f, "\\v{s}");
        printed = 1;
    }
    if (c == 356)
    {
        fprintf (f, "\\v{T}");
        printed = 1;
    }
    if (c == 357)
    {
        fprintf (f, "\\v{t}");
        printed = 1;
    }
    if (c == 452)
    {
        fprintf (f, "D\\v{Z}");
        printed = 1;
    }
    if (c == 453)
    {
        fprintf (f, "D\\v{z}");
        printed = 1;
    }
    if (c == 454)
    {
        fprintf (f, "d\\v{z}");
        printed = 1;
    }
    if (c == 381)
    {
        fprintf (f, "\\v{Z}");
        printed = 1;
    }
    if (c == 382)
    {
        fprintf (f, "\\v{z}");
        printed = 1;
    }
    if (c == 461)
    {
        fprintf (f, "\\v{A}");
        printed = 1;
    }
    if (c == 462)
    {
        fprintf (f, "\\v{a}");
        printed = 1;
    }
    if (c == 463)
    {
        fprintf (f, "\\v{I}");
        printed = 1;
    }
    if (c == 464)
    {
        fprintf (f, "{\\v\\i}");
        printed = 1;
    }
    if (c == 465)
    {
        fprintf (f, "\\v{O}");
        printed = 1;
    }
    if (c == 466)
    {
        fprintf (f, "\\v{o}");
        printed = 1;
    }
    if (c == 467)
    {
        fprintf (f, "\\v{U}");
        printed = 1;
    }
    if (c == 468)
    {
        fprintf (f, "\\v{u}");
        printed = 1;
    }
    if (c == 486)
    {
        fprintf (f, "\\v{G}");
        printed = 1;
    }
    if (c == 487)
    {
        fprintf (f, "\\v{g}");
        printed = 1;
    }
    if (c == 488)
    {
        fprintf (f, "\\v{K}");
        printed = 1;
    }
    if (c == 489)
    {
        fprintf (f, "\\v{k}");
        printed = 1;
    }
    if (c == 542)
    {
        fprintf (f, "\\v{H}");
        printed = 1;
    }
    if (c == 543)
    {
        fprintf (f, "\\v{h}");
        printed = 1;
    }
    if (printed == 0)
    {
        fprintf (f, "?");
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
