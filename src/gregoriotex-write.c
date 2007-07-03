/* 
Gregorio GregorioTeX output format.
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

#include <stdio.h>
#include <stdlib.h>
#include "gettext.h"
#define _(str) gettext(str)
#define N_(str) str
#include "messages.h"
#include "struct.h"
#include <wchar.h>
#include <string.h>
#include "gregoriotex.h"

void
libgregorio_gregoriotex_write_score (FILE * f, gregorio_score * score)
{
  if (score->number_of_voices != 1)
    {
      libgregorio_message (_
			   ("gregoriotex only works in monophony (for the moment)"),
			   "libgregorio_gregoriotex_write_score", ERROR, 0);
    }


  fprintf (f, "\\input gregoriotex.tex\n\n\\begingregorioscore%%\n");
// first we draw the initial (first letter) and the initial key
    gregorio_character *first_text=libgregorio_first_text (score);
  // a char that will contain 1 if it is the first syllable and 0 if not. It is for the initial.
  char first_syllable = 0;
    if (first_text)
    {
        fprintf (f, "\\initial{");
        libgregorio_write_first_letter (first_text, f,
			      (&libgregorio_gtex_write_verb),
			      (&libgregorio_gtex_print_char),
			      (&libgregorio_gtex_write_begin),
			      (&libgregorio_gtex_write_end),
			      (&libgregorio_gtex_write_special_char));
        fprintf (f, "}%%\n");
        first_syllable=SKIP_FIRST_LETTER;
    }
  char clef_letter;
  int clef_line;
  if (score->first_voice_info)
    {
      libgregorio_det_step_and_line_from_key (score->first_voice_info->
					      initial_key, &clef_letter,
					      &clef_line);
    }
  else
    {
      clef_letter = 'c';
      clef_line = 3;
    }
  fprintf (f, "\\setinitialclef{%c}{%d}%%\n", clef_letter, clef_line);
  gregorio_syllable *current_syllable = score->first_syllable;
  while (current_syllable)
    {
      libgregorio_gregoriotex_write_syllable (f, current_syllable,
					      first_syllable);
      current_syllable = current_syllable->next_syllable;
    }
  fprintf (f, "\\endgregorioscore%%\n\\bye\n");
}



void
libgregorio_gregoriotex_write_voice_info (FILE * f,
					  gregorio_voice_info * voice_info)
{
}

void
libgregorio_gregoriotex_write_syllable (FILE * f,
					gregorio_syllable * syllable,
					char first_syllable)
{
  fprintf (f, "\\syllable");
  libgregorio_gregoriotex_write_text (f, syllable->text, first_syllable);
  if (syllable->position == WORD_END
      || syllable->position == WORD_ONE_SYLLABLE || !syllable->text)
    {
      fprintf (f, "{1}{%%\n");
    }
  else
    {
      fprintf (f, "{0}{%%\n");
    }
  gregorio_element *current_element = (syllable->elements)[0];
  while (current_element)
    {
      if (current_element->type == GRE_SPACE)
	{
	  if (current_element->element_type == SP_LARGER_SPACE)
	    {
	      fprintf (f, "\\endofelement{1}%%\n");
	    }
	  if (current_element->element_type == SP_LARGER_SPACE)
	    {
	      fprintf (f, "\\endofelement{2}%%\n");
	    }
	  current_element = current_element->next_element;
	  continue;
	}
      if (current_element->type == GRE_C_KEY_CHANGE)
	{
	  fprintf (f, "\\changeclef{1}{2}%%\n");	//TODO : change
	  current_element = current_element->next_element;
	  continue;
	}
      if (current_element->type == GRE_F_KEY_CHANGE)
	{
	  fprintf (f, "\\changeclef{1}{2}%%\n");	//TODO : change
	  current_element = current_element->next_element;
	  continue;
	}
      if (current_element->type == GRE_BAR)
	{
	  fprintf (f, "\\");
	  libgregorio_gregoriotex_write_bar (f,
					     current_element->element_type);
	  fprintf (f, "%%\n");
	  current_element = current_element->next_element;
	  continue;
	}
      if (current_element->type == GRE_END_OF_LINE)
	{
	  // for the moment, end_of_lines are treated separately, in the TeX structure
	  fprintf (f, "%%gregorio::end_of_line\n");
	  current_element = current_element->next_element;
	  continue;
	}
// there current_element->type is GRE_ELEMENT
      libgregorio_gregoriotex_write_element (f, syllable, current_element);
      if (current_element->next_element
	  && current_element->next_element->type == GRE_ELEMENT)
	{
	  fprintf (f, "\\endofelement{0}%%\n");
	}
      current_element = current_element->next_element;
    }
  fprintf (f, "}%%\n");
}

// we will need type for one thing for the moment : type=first_syllable=1 when it is the first syllable (for the initial).

void
libgregorio_gtex_write_begin (FILE * f, unsigned char style)
{
  switch (style)
    {
    case ST_SMALL_CAPS:
      fprintf (f, "{\\sc");
      break;
    case ST_BOLD:
      fprintf (f, "{\\bf");
      break;
    case ST_CENTER:
      fprintf (f, "}{");
      break;
    case ST_TT:
      fprintf (f, "{\\tt");
      break;
    default:
      break;
    }
}

void
libgregorio_gtex_write_end (FILE * f, unsigned char style)
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
libgregorio_gtex_write_special_char (FILE * f, wchar_t * special_char)
{
  if (!wcscmp(special_char, L"'æ"))
    {
	fprintf(f, "\\'æ");
	return;
    }
  if (!wcscmp(special_char, L"'œ"))
    {
	fprintf(f, "\\'œ");
	return;
    }
  if (!wcscmp(special_char, L"ae"))
    {
	fprintf(f, "\\ae");
	return;
    }
}

void
libgregorio_gtex_write_verb (FILE * f, wchar_t * verb_str)
{
  fprintf (f, "%ls", verb_str);
}

void
libgregorio_gtex_print_char (FILE * f, wchar_t to_print)
{
  switch (to_print) {
  case L'œ':
    fprintf (f, "\\oe ");
  break;
  case L'æ':
    fprintf (f, "\\ae ");
  break;
  default:
  fprintf (f, "^^^^%04x", to_print);
  break;
}
}

// a function that takes a wchar_t * and write it in omega style : every character is reprensented by ^^^^x where x is its hexadecimal representation on 4 letters (completed with 0)
void
libgregorio_print_unicode_letters (FILE * f, wchar_t * wstr)
{
  if (!wstr)
    {
      return;
    }
  int i = 0;
  while (wstr[i])
    {
      libgregorio_gtex_print_char(f, wstr[i]);
      i++;
    }
  return;
}

void
libgregorio_gregoriotex_write_text (FILE * f, gregorio_character * text, char first_syllable)
{
  if (text == NULL)
    {
      fprintf (f, "{}{}{}");
      return;
    }
  fprintf (f, "{");
      libgregorio_write_text (first_syllable, text, f,
			      (&libgregorio_gtex_write_verb),
			      (&libgregorio_gtex_print_char),
			      (&libgregorio_gtex_write_begin),
			      (&libgregorio_gtex_write_end),
			      (&libgregorio_gtex_write_special_char));
  if (first_syllable) {
    first_syllable=0;
  }
  fprintf (f, "}");
}

// here we absolutely need to pass the syllable as an argument, because we will need the next note, that may be contained in the next syllable

void
libgregorio_gregoriotex_write_element (FILE * f,
				       gregorio_syllable * syllable,
				       gregorio_element * element)
{
  gregorio_glyph *current_glyph = element->first_glyph;
  while (current_glyph)
    {
      if (current_glyph->type == GRE_SPACE)
	{
// we assume here that it is a SP_ZERO_WIDTH, the only one a glyph can be
	  fprintf (f, "\\endofglyph{1}%%\n");
	  current_glyph = current_glyph->next_glyph;
	  continue;
	}
      if (current_glyph->type == GRE_FLAT)
	{
	  fprintf (f, "\\flat{a}%%\n");	//TODO : change
	  current_glyph = current_glyph->next_glyph;
	  continue;
	}
      if (current_glyph->type == GRE_NATURAL)
	{
	  fprintf (f, "\\natural{a}%%\n ");	//TODO : change
	  current_glyph = current_glyph->next_glyph;
	  continue;
	}
      if (current_glyph->type == GRE_BAR)
	{
	  fprintf (f, "\\in");
	  libgregorio_gregoriotex_write_bar (f, current_glyph->glyph_type);
	  fprintf (f, "%%\n");
	  current_glyph = current_glyph->next_glyph;
	  continue;
	}
// at this point glyph->type is GRE_GLYPH
      libgregorio_gregoriotex_write_glyph (f, syllable, element,
					   current_glyph);
      if (current_glyph->next_glyph
	  && current_glyph->next_glyph->type == GRE_GLYPH)
	{
	  /* if (is_puncta_inclinata (current_glyph->next_glyph->glyph_type)
	     || current_glyph->next_glyph->glyph_type == G_TRIGONUS
	     || current_glyph->next_glyph->glyph_type == G_PUNCTA_INCLINATA)
	     {
	     fprintf (f, "\\endofglyph{3}%%\n");
	     }
	     else
	     { */
	  fprintf (f, "\\endofglyph{0}%%\n");
	  //}
	}
      current_glyph = current_glyph->next_glyph;
    }
}


void
libgregorio_gregoriotex_write_bar (FILE * f, char type)
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
			   "libgregorio_gregoriotex_write_bar", ERROR, 0);
      break;
    }
}

void
libgregorio_gregoriotex_write_glyph (FILE * f, gregorio_syllable * syllable,
				     gregorio_element * element,
				     gregorio_glyph * glyph)
{
  if (!glyph)
    {
      libgregorio_message (_
			   ("called with NULL pointer"),
			   "libgregorio_gregoriotex_write_glyph", ERROR, 0);
      return;
    }
  if (!glyph->first_note)
    {
      libgregorio_message (_
			   ("called with glyph without note"),
			   "libgregorio_gregoriotex_write_glyph", ERROR, 0);
      return;
    }
  unsigned int glyph_number;
// glyph number is the number of the glyph in the fonte, it is discussed in later comments
// type is the type of the glyph. Understand the type of the glyph for gregoriotex, for the alignement between text and notes.
  int type;
  char next_note_pitch = 0;
  next_note_pitch =
    libgregorio_gregoriotex_determine_next_note (syllable, element, glyph);
  gregorio_note *current_note = NULL;
// first we check if it is really a unique glyph in gregoriotex... the glyphs that are not a unique glyph are : trigonus and pucta inclinata in general, and torculus resupinus and torculus resupinus flexus, so we first divide the glyph into real gregoriotex glyphs
  if (is_puncta_inclinata (glyph->glyph_type)
      || glyph->glyph_type == G_TRIGONUS
      || glyph->glyph_type == G_PUNCTA_INCLINATA
      || glyph->glyph_type == G_SCANDICUS)
    {
      current_note = glyph->first_note;
      while (current_note)
	{
	  libgregorio_gregoriotex_write_note (f, current_note,
					      next_note_pitch);
	  current_note = current_note->next_note;
	}
      return;
    }
  if (glyph->glyph_type == G_VIRGA || glyph->glyph_type == G_STROPHA
      || glyph->glyph_type == G_STROPHA_AUCTA
      || glyph->glyph_type == G_PUNCTUM)
    {
      libgregorio_gregoriotex_write_note (f, glyph->first_note,
					  next_note_pitch);
      return;
    }
  if (glyph->glyph_type == G_TORCULUS_RESUPINUS)
    {
      current_note = glyph->first_note;
      libgregorio_gregoriotex_write_note (f, current_note, next_note_pitch);
      glyph->glyph_type = G_PORRECTUS_NO_BAR;
      libgregorio_gregoriotex_determine_number_and_type (glyph, &type,
							 &glyph_number);
      glyph->glyph_type = G_TORCULUS_RESUPINUS;
//TODO : fusion functions
      fprintf (f, "\\glyph{%d}{%d}{%d}{%d}%%\n", glyph_number,
	       glyph->first_note->pitch - 96, next_note_pitch - 96, type);
      return;
    }
  if (glyph->glyph_type == G_TORCULUS_RESUPINUS_FLEXUS)
    {
      current_note = glyph->first_note;
      libgregorio_gregoriotex_write_note (f, current_note, next_note_pitch);
      glyph->glyph_type = G_PORRECTUS_FLEXUS_NO_BAR;
      libgregorio_gregoriotex_determine_number_and_type (glyph, &type,
							 &glyph_number);
      glyph->glyph_type = G_TORCULUS_RESUPINUS_FLEXUS;
//TODO : fusion functions
      fprintf (f, "\\glyph{%d}{%d}{%d}{%d}%%\n", glyph_number,
	       glyph->first_note->pitch - 96, next_note_pitch - 96, type);
      return;
    }
  if (glyph->glyph_type == G_BIVIRGA || glyph->glyph_type == G_DISTROPHA)
    {
      current_note = glyph->first_note;
      while (current_note)
	{
	  libgregorio_gregoriotex_write_note (f, current_note,
					      next_note_pitch);
	  current_note = current_note->next_note;
	  if (current_note)
	    {
	      fprintf (f, "\\endofglyph{4}%%\n");
	    }
	}
      return;
    }

  if (glyph->glyph_type == G_TRIVIRGA || glyph->glyph_type == G_TRISTROPHA)
    {
      current_note = glyph->first_note;
      while (current_note)
	{
	  libgregorio_gregoriotex_write_note (f, current_note,
					      next_note_pitch);
	  current_note = current_note->next_note;
	  if (current_note)
	    {
	      fprintf (f, "\\endofglyph{5}%%\n");
	    }
	}
      return;
    }
  if (glyph->glyph_type == G_VIRGA
      || glyph->glyph_type == G_STROPHA || glyph->glyph_type ==
      G_STROPHA_AUCTA || glyph->glyph_type == G_PUNCTUM)
    {
      libgregorio_gregoriotex_write_note (f, glyph->first_note,
					  next_note_pitch);
    }
  libgregorio_gregoriotex_determine_number_and_type (glyph, &type,
						     &glyph_number);
  fprintf (f, "\\glyph{^^^^%04x}{%d}{%d}{%d}%%\n", glyph_number,
	   glyph->first_note->pitch - 96, next_note_pitch - 96, type);

}



/* here we determine the type... here are the different types : 
 * 1: symbols and one-note glyphs
 * 2: pes
 * 6: pes deminutus
 * 4: pes auctus ascendens
 * 5: pes auctus descendens
 * 3: pes initio debilis
 * 9: pes initio debilis deminutus
 * 7: pes initio debilisauctus ascendens
 * 8: pes initio debilisauctus descendens
 * 10: pes quadratus
 * 11: pes quassus
 * 12: pes quilisma
 * 13: flexa
 * 14: flexa deminutus
 * 15: flexa auctus ascendens
 * 16: flexa auctus descendens
 * small bar means that the first bar is shorter, it depends on the position of the first note
 * 17: flexa_short_bar
 * 18: flexa_short_bar deminutus
 * 19: flexa_short_bar auctus ascendens
 * 20: flexa_short_bar auctus descendens
 * 21: torculus
 * 22: torculus deminutus
 * 23: torculus auctus ascendens
 * 24: torculus auctus descendens
 * 25: torculus initio debilis
 * 26: torculus initio debilis deminutus 
 * 27: torculus auctus ascendens initio debilis
 * 28: torculus auctus descendens initio debilis 
 * 29: porrectus
 * 30: porrectus deminutus
 * 31: porrectus auctus ascendens
 * 32: porrectus auctus descendens
 * 33: porrectus flexus
 * 34: porrectus flexus deminutus
 * 35: porrectus flexus auctus ascendens
 * 36: porrectus flexus auctus descendens
 * 37: porrectus_short_bar
 * 38: porrectus_short_bar deminutus
 * 39: porrectus_short_bar auctus ascendens
 * 40: porrectus_short_bar auctus descendens
 * 41: porrectus_short_bar flexus
 * 42: porrectus_short_bar flexus deminutus
 * 43: porrectus_short_bar flexus auctus ascendens
 * 44: porrectus_short_bar flexus auctus descendens
 * 45: porrectus_no_bar
 * 46: porrectus_no_bar deminutus
 * 47: porrectus_no_bar auctus ascendens
 * 48: porrectus_no_bar auctus descendens
 * 49: porrectus_no_bar flexus
 * 50: porrectus_no_bar flexus deminutus
 * 51: porrectus_no_bar flexus auctus ascendens
 * 52: porrectus_no_bar flexus auctus descendens
 * 53: flexus
 * 54: flexus deminutus
 * 55: flexus auctus ascendens
 * 56: flexus auctus descendens
 * 57: scandicus deminutus

to obtain the glyph number, we multiply this type by 1000 and we add the differences between the notes with this algorith :
if we call (1) the difference between the first and the second note (and so on)
(1)+(2)*10+(3)*100
thus we have a number between 1 and 999
note that we assume we have no glyph of more than 4 notes
*/

// macro that we will use to determine if we need a short bar or not

#define is_short(pitch) pitch=='a'||pitch=='c'||pitch=='e'||pitch=='g'||pitch=='i'||pitch=='k'||pitch=='m'

void
libgregorio_gregoriotex_determine_number_and_type (gregorio_glyph *
						   glyph, int *type,
						   unsigned int *glyph_number)
{
  if (!glyph)
    {
      libgregorio_message (_
			   ("called with NULL pointer"),
			   "libgregorio_gregoriotex_determine_number_and_type",
			   ERROR, 0);
      return;
    }
  unsigned int temp = 0;
  char pitch;
  // for the moment there is no auctus ascendens in the police, so we replace them by auctus descendens
  char liquescentia = glyph->liquescentia;
  if (liquescentia == L_AUCTUS_ASCENDENS)
    {
      glyph->liquescentia = L_AUCTUS_DESCENDENS;
    }
  if (liquescentia == L_AUCTUS_ASCENDENS_INITIO_DEBILIS)
    {
      glyph->liquescentia = L_AUCTUS_DESCENDENS_INITIO_DEBILIS;
    }
  switch (glyph->glyph_type)
    {
    case G_PODATUS:
      if (glyph->first_note && glyph->first_note->shape == S_QUILISMA)
	{
	  temp = 12;
	}
      else
	{
	  temp = 2 + (unsigned int) glyph->liquescentia;
	}
      *type = T_ONE_NOTE;
      break;
    case G_PES_QUADRATUM:
      if (glyph->first_note && glyph->first_note->shape == S_ORISCUS)
	{
	  temp = 11;
	}
      else
	{
	  temp = 10;
	}
      *type = T_ONE_NOTE;
      break;
    case G_FLEXA:
      if (!glyph->first_note)
	{
	  libgregorio_message (_
			       ("called with a glyph that have no note"),
			       "libgregorio_gregorio_tex_determine_number_and_type",
			       ERROR, 0);
	  break;
	}
      pitch = glyph->first_note->pitch;
      if (is_short (pitch))
	{
	  temp = 17;
	}
      else
	{
	  temp = 13;
	}
      // we don't want initio_debilis
      if (is_initio_debilis (glyph->liquescentia))
	{
	  temp = temp + (unsigned int) glyph->liquescentia - L_INITIO_DEBILIS;
	}
      else
	{
	  temp = (unsigned int) temp + (unsigned int) glyph->liquescentia;
	}
      *type = T_TWO_NOTES;
      break;
    case G_TORCULUS:
      temp = 21 + (unsigned int) glyph->liquescentia;
      *type = T_ONE_NOTE;
      break;
    case G_PORRECTUS:
      if (!glyph->first_note)
	{
	  libgregorio_message (_
			       ("called with a glyph that have no note"),
			       "libgregorio_gregorio_tex_determine_number_and_type",
			       ERROR, 0);
	  break;
	}
      pitch = glyph->first_note->pitch;
/*
there is no short bar porrectus in gregoria for the moment, so we comment this part
      if (is_short (pitch))
	{
	  temp = 37;
	}
      else
	{*/
      temp = 29;
      //}
      // we don't want initio_debilis
      if (is_initio_debilis (glyph->liquescentia))
	{
	  temp = temp + (unsigned int) glyph->liquescentia - L_INITIO_DEBILIS;
	}
      else
	{
	  temp = (unsigned int) temp + (unsigned int) glyph->liquescentia;
	}
      *type = T_PORRECTUS;
      break;
    case G_PORRECTUS_FLEXUS:
      if (!glyph->first_note)
	{
	  libgregorio_message (_
			       ("called with a glyph that have no note"),
			       "libgregorio_gregorio_tex_determine_number_and_type",
			       ERROR, 0);
	  break;
	}
      pitch = glyph->first_note->pitch;
/*
there is no short bar porrectus flexus in gregoria for the moment, so we comment this part
      if (is_short (pitch))
	{
	  temp = 41;
	}
      else
	{*/
      temp = 33;
      //}
      // we don't want initio_debilis
      if (is_initio_debilis (glyph->liquescentia))
	{
	  temp = temp + (unsigned int) glyph->liquescentia - L_INITIO_DEBILIS;
	}
      else
	{
	  temp = (unsigned int) temp + (unsigned int) glyph->liquescentia;
	}
      *type = T_PORRECTUS;
      break;
    case G_PORRECTUS_NO_BAR:
      // we don't want initio_debilis
      if (is_initio_debilis (glyph->liquescentia))
	{
	  temp = 45 + (unsigned int) glyph->liquescentia - L_INITIO_DEBILIS;
	}
      else
	{
	  temp = 45 + (unsigned int) glyph->liquescentia;
	}
      *type = T_PORRECTUS;
      break;
    case G_PORRECTUS_FLEXUS_NO_BAR:
      // we don't want initio_debilis
      if (is_initio_debilis (glyph->liquescentia))
	{
	  temp = 49 + (unsigned int) glyph->liquescentia - L_INITIO_DEBILIS;
	}
      else
	{
	  temp = 49 + (unsigned int) glyph->liquescentia;
	}
      *type = T_PORRECTUS;
      break;
    case G_SCANDICUS:
//TODO ?
      *type = T_ONE_NOTE;
      break;
    default:
      libgregorio_message (_
			   ("called with unknown glyph"),
			   "libgregorio_gregorio_tex_determine_number_and_type",
			   ERROR, 0);
      break;
    }

  *glyph_number = libgregorio_gregoriotex_determine_interval (glyph);
  *glyph_number = (1000 * temp) + (*glyph_number);
  // we change to the original liquescentia
  glyph->liquescentia = liquescentia;
// we fix *type with initio_debilis
  if (*type == T_ONE_NOTE)
    {
      if (is_initio_debilis (liquescentia))
	{
	  *type = T_INITIO_DEBILIS;
	}
    }
}



unsigned int
libgregorio_gregoriotex_determine_interval (gregorio_glyph * glyph)
{
  if (!glyph)
    {
      libgregorio_message (_
			   ("called with NULL pointer"),
			   "libgregorio_gregoriotex_determine_interval",
			   ERROR, 0);
      return 0;
    }
  gregorio_note *current_note;
  if (!glyph->first_note)
    {
      libgregorio_message (_
			   ("called with a glyph that have no note"),
			   "libgregorio_gregoriotex_determine_interval",
			   ERROR, 0);
      return 0;
    }
  current_note = glyph->first_note;
  if (glyph->glyph_type == G_PORRECTUS_NO_BAR
      || glyph->glyph_type == G_PORRECTUS_FLEXUS_NO_BAR)
// if it is a no_bar glyph, we skip the first note, because it means that it is a torculus resupinus (flexus), and we split it into two : the first note and the second part. We've already taken care of the first note, so we skip it.
    {
      if (!current_note->next_note)
	{
	  libgregorio_message (_
			       ("called with a glyph that have no note"),
			       "libgregorio_gregoriotex_determine_interval",
			       ERROR, 0);
	  return 0;
	}
      current_note = current_note->next_note;
    }
  unsigned int current;
// then we start making our formula
  char first;
  char second;
  if (!current_note->next_note)
    {
      return 0;
    }
  first = current_note->pitch;
  second = current_note->next_note->pitch;
  if (first < second)
    {
      current = second - first;
    }
  else
    {
      current = first - second;
    }
  current_note = current_note->next_note;
  if (!current_note->next_note)
    {
      return current;
    }
  first = current_note->pitch;
  second = current_note->next_note->pitch;
  if (first < second)
    {
      current = 10 * (second - first) + current;
    }
  else
    {
      current = 10 * (first - second) + current;
    }
  current_note = current_note->next_note;
  if (!current_note->next_note)
    {
      return current;
    }
  first = current_note->pitch;
  second = current_note->next_note->pitch;
  if (first < second)
    {
      current = 100 * (second - first) + current;
    }
  else
    {
      current = 100 * (first - second) + current;
    }
  return current;
}

/* function used when the glyph is only one note long, the type is 1. Like before, we multiply this number by 1000 and we add something. Here the thing that will be added is this one : 

* 1: c clef
* 2: f clef
* 3: custo for bass notes (oriented to the top)
* 4: custo for high notes (oriented to the bottom)
* 5: flat (oriented to the top)
* 6: flat (oriented to the bottom)
* 7: natural
* 8: virgula
* 9: divisio minima
* 10: divisio minor
* 11: divisio maior
* 12: divisio finalis
* 13: vertical episemus
* 14: punctum mora
* 15: auctum duplex
* 16: circumflexus
* 17: punctum
* 18: punctum quadratum
* 19: punctum inclinatum
* 20: stropha
* 21: stropha aucta
* 22: virga
* 23: virga_short_bar
* 24: left virga
* 25: left virga_short_bar
* 26: quilisma
* 27: oriscus
* 28: oriscus auctus
* 29: custo for bass notes (oriented to the top) with short bar
* 30: custo for high notes (oriented to the bottom) with short bar
* 31: punctum inclinatum auctum
* 32: punctum inclinatum deminutus
* 33: vertical episemus
*/

void
libgregorio_gregoriotex_write_note (FILE * f, gregorio_note * note,
				    char next_note_pitch)
{
  int glyph_number;
  if (!note)
    {
      libgregorio_message (_
			   ("called with NULL pointer"),
			   "libgregorio_gregoriotex_write_note", ERROR, 0);
      return;
    }

  char temp;
  switch (note->shape)
    {
    case S_PUNCTUM_INCLINATUM:
// the most complex : we must determine first if it has a previous note, and if it has, we must compare the heights differences, if it is more than 2, we put a \zerowidthspace, else a \punctumincliatumshift
      glyph_number = 19;
      if (note->previous_note)
	{
//means that it is the first note of the puncta inclinata sequence
	  temp = note->previous_note->pitch - note->pitch;
	  if (temp < -2 || temp > 2)
	    {
	      fprintf (f, "\\endofglyph{1}%%\n");
	    }
	  else
	    {
	      fprintf (f, "\\endofglyph{3}%%\n");
	    }
	}
      break;
    case S_PUNCTUM:
      glyph_number = 17;
      break;
    case S_VIRGA:
      if (is_short (note->pitch))
	{
	  glyph_number = 23;
	}
      else
	{
	  glyph_number = 22;
	}
      break;
    case S_ORISCUS:
      glyph_number = 27;
      break;
    case S_ORISCUS_AUCTUS:
      glyph_number = 28;
      break;
    case S_QUILISMA:
      glyph_number = 26;
      break;
    case S_STROPHA:
      glyph_number = 20;
      break;
    case S_STROPHA_AUCTA:
      glyph_number = 21;
      break;
    default:
      libgregorio_message (_
			   ("called with unknown shape"),
			   "libgregorio_gregoriotex_write_note", ERROR, 0);
      return;
      break;
    }
  glyph_number = glyph_number + 1000;
  fprintf (f, "\\glyph{^^^^%04x}{%d}{%d}{0}%%\n", glyph_number,
	   note->pitch - 96, next_note_pitch - 96);
}


char
libgregorio_gregoriotex_determine_next_note (gregorio_syllable * syllable,
					     gregorio_element * element,
					     gregorio_glyph * glyph)
{
  if (!glyph || !element || !syllable)
    {
      libgregorio_message (_
			   ("called with a NULL argument"),
			   "libgregorio_gregoriotex_determine_next_note",
			   ERROR, 0);
      return 'g';
    }
  char temp;
// we first explore the next glyphs to find a note
  glyph = glyph->next_glyph;
  while (glyph)
    {
      if (glyph->type == GRE_GLYPH && glyph->first_note)
	{
	  return glyph->first_note->pitch;
	}
      glyph = glyph->next_glyph;
    }
// then we do the same with the elements
  element = element->next_element;
  while (element)
    {
      if (element->type == GRE_ELEMENT && element->first_glyph)
	{
	  glyph = element->first_glyph;
	  while (glyph)
	    {
	      if (glyph->type == GRE_GLYPH && glyph->first_note)
		{
		  return glyph->first_note->pitch;
		}
	      glyph = glyph->next_glyph;
	    }
	}
      element = element->next_element;
    }

// then we do the same with the syllables
  syllable = syllable->next_syllable;
  while (syllable)
    {
// we call another function that will return the pitch of the first note if syllable has a note, and 0 else
      temp = libgregorio_gregoriotex_syllable_first_note (syllable);
      if (temp)
	{
	  return temp;
	}
      syllable = syllable->next_syllable;
    }
// here it means that there is no next note, so we return a stupid value, but it won't be used
  return 'g';
}


char
libgregorio_gregoriotex_syllable_first_note (gregorio_syllable * syllable)
{
  if (!syllable)
    {
      libgregorio_message (_
			   ("called with a NULL argument"),
			   "libgregorio_gregoriotex_determine_next_note",
			   ERROR, 0);
    }
  gregorio_glyph *glyph;
  gregorio_element *element;
  element = syllable->elements[0];
  while (element)
    {
      if (element->type == GRE_ELEMENT && element->first_glyph)
	{
	  glyph = element->first_glyph;
	  while (glyph)
	    {
	      if (glyph->type == GRE_GLYPH && glyph->first_note)
		{
		  return glyph->first_note->pitch;
		}
	      glyph = glyph->next_glyph;
	    }
	}
      element = element->next_element;
    }
  return 0;
}
