/* 
Gregorio gabc output format.
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

#include <ctype.h>
#include <stdio.h>
#include <libintl.h>
#define _(str) gettext(str)
#define N_(str) str
#include "messages.h"
#include "struct.h"
#include "gabc.h"


void
libgregorio_gabc_write_score (FILE * f, gregorio_score * score)
{
if (score->name)
    {
  fprintf (f, "name: %s;\n", score->name);

    }
 else {
  fprintf (f, "name: unknown;\n");
      libgregorio_message (_("name is mandatory"),
			   "libgregorio_gabc_write_score", ERROR, 0);
}
  if (score->office_part)
    {
      fprintf (f, "office-part: %s;\n", score->office_part);
    }
  if (score->lilypond_preamble)
    {
      fprintf (f, "lilypond-preamble: %s;\n", score->lilypond_preamble);
    }
  if (score->opustex_preamble)
    {
      fprintf (f, "opustex-preamble: %s;\n", score->opustex_preamble);
    }
  if (score->musixtex_preamble)
    {
      fprintf (f, "musixtex-preamble: %s;\n", score->musixtex_preamble);
    }
  if (score->number_of_voices == 0)
    {
      libgregorio_message (_("gregorio_score seems to be empty"),
			   "libgregorio_gabc_write_score", ERROR, 0);
      return;
    }
  if (score->number_of_voices == 1)
    {
      libgregorio_gabc_write_voice_info (f, score->first_voice_info);
      fprintf (f, "%%%%\n");
    }
  else
    {
      gregorio_voice_info *voice_info = score->first_voice_info;
      while (voice_info)
	{
	  libgregorio_gabc_write_voice_info (f, voice_info);
	  if (voice_info->next_voice_info)
	    {
	      fprintf (f, "--\n");
	    }
	  else
	    {
	      fprintf (f, "%%%%\n");
	    }
	}
    }
  gregorio_syllable *syllable = score->first_syllable;
  while (syllable)
    {
      libgregorio_gabc_write_gregorio_syllable (f, syllable,
						score->number_of_voices);
      syllable = syllable->next_syllable;
    }
  fprintf (f, "\n");
}

void
libgregorio_gabc_write_voice_info (FILE * f, gregorio_voice_info * voice_info)
{
  if (!voice_info) {
      libgregorio_message (_("no voice info"),
			   "libgregorio_gabc_write_voice_info", WARNING, 0);
return;
}
  if (voice_info->anotation)
    {
      fprintf (f, "anotation: %s;\n", voice_info->anotation);
    }
  if (voice_info->author)
    {
      fprintf (f, "author: %s;\n", voice_info->author);
    }
  if (voice_info->date)
    {
      fprintf (f, "date: %s;\n", voice_info->date);
    }
  if (voice_info->manuscript)
    {
      fprintf (f, "manuscript: %s;\n", voice_info->manuscript);
    }
  if (voice_info->reference)
    {
      fprintf (f, "reference: %s;\n", voice_info->reference);
    }
  if (voice_info->storage_place)
    {
      fprintf (f, "storage-place: %s;\n", voice_info->storage_place);
    }
  if (voice_info->translator)
    {
      fprintf (f, "translator: %s;\n", voice_info->translator);
    }
  if (voice_info->translation_date)
    {
      fprintf (f, "translation-date: %s;\n", voice_info->translation_date);
    }
  if (voice_info->style)
    {
      fprintf (f, "style: %s;\n", voice_info->style);
    }
  if (voice_info->virgula_position)
    {
      fprintf (f, "virgula-position: %s;\n", voice_info->virgula_position);
    }
  char step;
  int line;
  libgregorio_det_step_and_line_from_key (voice_info->initial_key, &step,
					  &line);
  fprintf (f, "initial-key: %c%d;\n", step, line);
}

void
libgregorio_gabc_write_gregorio_syllable (FILE * f,
					  gregorio_syllable * syllable,
					  int number_of_voices)
{
  if (!syllable)
    {
      libgregorio_message (_("call with NULL argument"),
			   "libgregorio_gabc_write_syllable", ERROR, 0);
return;
    }
  int voice = 0;
  if (!syllable->syllable)
    {
      fprintf (f, "(");
    }
  else
    {
      fprintf (f, "%s(", syllable->syllable);
    }
  while (voice < number_of_voices - 1)
    {
      //we enter this loop only in polyphony
      libgregorio_gabc_write_gregorio_elements (f, syllable->elements[voice]);
      fprintf (f, "&");
      voice++;
    }
  libgregorio_gabc_write_gregorio_elements (f, syllable->elements[voice]);

  if (syllable->position == WORD_END
      || libgregorio_is_only_special (syllable->elements[0]))
    // we assume here that if the first voice is only special, all will be only specials too
    {
      fprintf (f, ") ");
    }
  else
    {
      fprintf (f, ")");
    }
}

void
libgregorio_gabc_write_gregorio_elements (FILE * f,
					  gregorio_element * element)
{
  while (element)
    {
      libgregorio_gabc_write_gregorio_element (f, element);
      // we don't want a bar after an end of line
      if (element->type != GRE_END_OF_LINE && element->next_element && element->next_element->type == GRE_ELEMENT)
	{
	  fprintf (f, "/");
	}
      element = element->next_element;
    }
}

void
libgregorio_gabc_write_gregorio_element (FILE * f, gregorio_element * element)
{
  if (!element)
    {
      libgregorio_message (_("call with NULL argument"),
			   "libgregorio_gabc_write_gregorio_element", ERROR,
			   0);
      return;
    }
  gregorio_glyph *current_glyph = element->first_glyph;
  switch (element->type)
    {
    case GRE_ELEMENT:
      while (current_glyph)
	{
	  libgregorio_gabc_write_gregorio_glyph (f, current_glyph);
	  current_glyph = current_glyph->next_glyph;
	}
      break;
    case GRE_SPACE:
      libgregorio_gabc_write_space (f, element->element_type);
      break;
    case GRE_BAR:
      libgregorio_gabc_write_bar (f, element->element_type);
      break;
    case GRE_C_KEY_CHANGE:
      libgregorio_gabc_write_key_change (f, C_KEY,
					 element->element_type - 48);
      break;
    case GRE_F_KEY_CHANGE:
      libgregorio_gabc_write_key_change (f, F_KEY,
					 element->element_type - 48);
      break;
    case GRE_END_OF_LINE:
      fprintf(f,"z");
      break;
    default:
      libgregorio_message (_("call with an argument which type is unknown"),
			   "libgregorio_gabc_write_gregorio_element", ERROR,
			   0);
      break;
    }
}


void
libgregorio_gabc_write_gregorio_glyph (FILE * f, gregorio_glyph * glyph)
{
  if (!glyph)
    {
      libgregorio_message (_("call with NULL argument"),
			   "libgregorio_gabc_write_gregorio_glyph", ERROR, 0);
      return;
    }
  switch (glyph->type)
    {
    case GRE_FLAT:
      fprintf (f, "x%c", glyph->glyph_type);
      break;
    case GRE_NATURAL:
      fprintf (f, "y%c", glyph->glyph_type);
      break;
	case GRE_SPACE:
	if (glyph->glyph_type==SP_ZERO_WIDTH && glyph->next_glyph) {
	fprintf(f,"!");
	}
	else {
	      libgregorio_message (_("bad space"),
			   "libgregorio_gabc_write_gregorio_glyph", ERROR, 0);
	}
	break;
    case GRE_GLYPH:
      if (is_initio_debilis (glyph->liquescentia))
	{
	  fprintf (f, "-");
	}

      gregorio_note *current_note = glyph->first_note;
      while (current_note)
	{
	  libgregorio_gabc_write_gregorio_note (f, current_note,
						glyph->glyph_type);
//third argument necessary for the special shape pes quadratum
	  current_note = current_note->next_note;
	}
      libgregorio_gabc_write_end_liquescentia (f, glyph->liquescentia);
      break;
    default:

      libgregorio_message (_("call with an argument which type is unknown"),
			   "libgregorio_gabc_write_gregorio_glyph", ERROR, 0);
      break;
    }
}

void
libgregorio_gabc_write_end_liquescentia (FILE * f, char liquescentia)
{
  if (liquescentia == L_NO_LIQUESCENTIA)
    {
      return;
    }
  if (liquescentia == L_DEMINUTUS
      || liquescentia == L_DEMINUTUS_INITIO_DEBILIS)
    {
      fprintf (f, "~");
    }
  if (liquescentia == L_AUCTUS_ASCENDENS
      || liquescentia == L_AUCTUS_ASCENDENS_INITIO_DEBILIS)
    {
      fprintf (f, "<");
    }
  if (liquescentia == L_AUCTUS_DESCENDENS
      || liquescentia == L_AUCTUS_DESCENDENS_INITIO_DEBILIS)
    {
      fprintf (f, ">");
    }
  if (liquescentia == L_AUCTA || liquescentia == L_AUCTA_INITIO_DEBILIS)
    {
      fprintf (f, "<");
    }
}

void
libgregorio_gabc_write_key_change (FILE * f, char step, int line)
{
  fprintf (f, "%c%d", step, line);
}

void
libgregorio_gabc_write_space (FILE * f, char type)
{
  switch (type)
    {
    case SP_LARGER_SPACE:
      fprintf (f, "//");
      break;
    case SP_GLYPH_SPACE:
      fprintf (f, " ");
      break;
    case SP_NEUMATIC_CUT:
      // neumatic cuts are automatically added between elements
      break;
    default:
      libgregorio_message (_("space type is unknown"),
			   "libgregorio_gabc_write_space", ERROR, 0);
      break;
    }
}

void
libgregorio_gabc_write_bar (FILE * f, char type)
{
  switch (type)
    {
    case B_VIRGULA:
      fprintf (f, "`");
      break;
    case B_DIVISIO_MINIMA:
      fprintf (f, ",");
      break;
    case B_DIVISIO_MINOR:
      fprintf (f, ";");
      break;
    case B_DIVISIO_MAIOR:
      fprintf (f, ":");
      break;
    case B_DIVISIO_FINALIS:
      fprintf (f, "::");
      break;
    default:
      libgregorio_message (_("unknown bar type, nothing will be done"),
			   "libgregorio_gabc_bar_to_str", ERROR, 0);
      break;
    }
}

void
libgregorio_gabc_write_gregorio_note (FILE * f, gregorio_note * note,
				      char glyph_type)
{
  if (!note)
    {
      libgregorio_message (_("call with NULL argument"),
			   "libgregorio_gabc_write_gregorio_note", ERROR, 0);
      return;
    }
  if (note->type != GRE_NOTE)
    {
      libgregorio_message (_
			   ("call with argument which type is not GRE_NOTE, wrote nothing"),
			   "libgregorio_gabc_write_gregorio_note", ERROR, 0);
      return;
    }
  char shape;
  if (glyph_type == G_PES_QUADRATUM)
    {
      shape = S_QUADRATUM;
    }
  else
    {
      shape = note->shape;
    }
  note->pitch = tolower (note->pitch);
  switch (shape)
    {
    case S_PUNCTUM:
      fprintf (f, "%c", note->pitch);
      break;
    case S_PUNCTUM_INCLINATUM:
      fprintf (f, "%c", toupper (note->pitch));
      break;
    case S_VIRGA:
      fprintf (f, "%cv", note->pitch);
      break;
    case S_BIVIRGA:
      fprintf (f, "%cvv", note->pitch);
      break;
    case S_TRIVIRGA:
      fprintf (f, "%cvvv", note->pitch);
      break;
    case S_ORISCUS:
      fprintf (f, "%co", note->pitch);
      break;
    case S_ORISCUS_AUCTUS:
      fprintf (f, "%co", note->pitch);	//we consider that the AUCTUS is also in the liquescentia
      break;
    case S_QUILISMA:
      fprintf (f, "%cw", note->pitch);
      break;
    case S_STROPHA:
      fprintf (f, "%cs", note->pitch);
      break;
    case S_STROPHA_AUCTA:
      fprintf (f, "%cs", note->pitch);
      break;
    case S_DISTROPHA:
      fprintf (f, "%css", note->pitch);
      break;
    case S_DISTROPHA_AUCTA:
      fprintf (f, "%css", note->pitch);
      break;
    case S_TRISTROPHA:
      fprintf (f, "%csss", note->pitch);
      break;
    case S_TRISTROPHA_AUCTA:
      fprintf (f, "%csss", note->pitch);
      break;
    case S_QUADRATUM:
      fprintf (f, "%cq", note->pitch);
      break;
    default:
      fprintf (f, "%c", note->pitch);
      break;
    }
  switch (note->signs)
    {
    case _PUNCTUM_MORA:
      fprintf (f, ".");
      break;
    case _AUCTUM_DUPLEX:
      fprintf (f, "..");
      break;
    case _V_EPISEMUS:
      fprintf (f, "'");
      break;
    case _V_EPISEMUS_PUNCTUM_MORA:
      fprintf (f, "'.");
      break;
    case _V_EPISEMUS_AUCTUM_DUPLEX:
      fprintf (f, "'..");
      break;
    default:
      break;
    }
  if (note->h_episemus_type != H_NO_EPISEMUS)
    {
      fprintf (f, "_");
    }
}
