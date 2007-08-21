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

#include "config.h"
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
  gregorio_character *first_text;
  // a char that will contain 1 if it is the first syllable and 0 if not. It is for the initial.
  char first_syllable = 0;
  char clef_letter;
  int clef_line;
  gregorio_syllable *current_syllable;

  if (score->number_of_voices != 1)
    {
      libgregorio_message (_
			   ("gregoriotex only works in monophony (for the moment)"),
			   "libgregorio_gregoriotex_write_score", ERROR, 0);
    }
  fprintf (f, "\\input gregoriotex.tex\n\n\\begingregorioscore%%\n");
// first we draw the initial (first letter) and the initial key
  first_text = libgregorio_first_text (score);
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
      first_syllable = SKIP_FIRST_LETTER;
    }
  if (score->mode != 0)
    {
      fprintf (f, "\\gregorianmode{%d}%%\n", score->mode);
    }
  if (score->first_voice_info)
    {
      libgregorio_gregoriotex_write_voice_info (f, score->first_voice_info);
    }
  fprintf (f, "\\beginscore%%\n");
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
  current_syllable = score->first_syllable;
  while (current_syllable)
    {
      libgregorio_gregoriotex_write_syllable (f, current_syllable,
					      &first_syllable);
      current_syllable = current_syllable->next_syllable;
    }
  fprintf (f, "\\endgregorioscore%%\n\\bye\n");
}



void
libgregorio_gregoriotex_write_voice_info (FILE * f,
					  gregorio_voice_info * voice_info)
{
  if (!voice_info)
    {
      return;
    }
  if (voice_info->reference)
    {
      fprintf (f, "\\scorereference{%s}%%\n", voice_info->reference);
    }
}

void
libgregorio_gregoriotex_write_syllable (FILE * f,
					gregorio_syllable * syllable,
					char *first_syllable)
{
  gregorio_element *current_element;

  if (!syllable)
    {
      return;
    }
  /* first we check if the syllable is only a end of line.
     If it is the case, we don't print anything but a comment (to be able to read it if we read GregorioTeX).
     The end of lines are treated separately in GregorioTeX, it is buit inside the TeX structure. */
  if ((syllable->elements)[0]->type == GRE_END_OF_LINE
      && !(syllable->elements)[0]->next_element)
    {
      fprintf (f, "%%gregorio::end_of_line\n");
      return;
    }
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
  current_element = (syllable->elements)[0];
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
  if (!wcscmp (special_char, L"'æ"))
    {
      fprintf (f, "\\'æ");
      return;
    }
  if (!wcscmp (special_char, L"'œ"))
    {
      fprintf (f, "\\'œ");
      return;
    }
  if (!wcscmp (special_char, L"ae"))
    {
      fprintf (f, "\\ae");
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
  if (to_print < 128)
    {
      fprintf (f, "%lc", to_print);
      return;
    }
  switch (to_print)
    {
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
  int i = 0;

  if (!wstr)
    {
      return;
    }
  while (wstr[i])
    {
      libgregorio_gtex_print_char (f, wstr[i]);
      i++;
    }
  return;
}

void
libgregorio_gregoriotex_write_text (FILE * f, gregorio_character * text,
				    char *first_syllable)
{
  if (text == NULL)
    {
      fprintf (f, "{}{}{}");
      return;
    }
  fprintf (f, "{");
  libgregorio_write_text (*first_syllable, text, f,
			  (&libgregorio_gtex_write_verb),
			  (&libgregorio_gtex_print_char),
			  (&libgregorio_gtex_write_begin),
			  (&libgregorio_gtex_write_end),
			  (&libgregorio_gtex_write_special_char));
  if (*first_syllable)
    {
      *first_syllable = 0;
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
  unsigned int glyph_number = 0;
// glyph number is the number of the glyph in the fonte, it is discussed in later comments
// type is the type of the glyph. Understand the type of the glyph for gregoriotex, for the alignement between text and notes.
  int type = 0;
  char next_note_pitch = 0;
  gregorio_note *current_note;

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
  next_note_pitch =
    libgregorio_gregoriotex_determine_next_note (syllable, element, glyph);
  current_note = glyph->first_note;
// first we check if it is really a unique glyph in gregoriotex... the glyphs that are not a unique glyph are : trigonus and pucta inclinata in general, and torculus resupinus and torculus resupinus flexus, so we first divide the glyph into real gregoriotex glyphs
  switch (glyph->glyph_type)
    {
    case G_TRIGONUS:
    case G_PUNCTA_INCLINATA:
    case G_SCANDICUS:
    case G_2_PUNCTA_INCLINATA_DESCENDENS:
    case G_3_PUNCTA_INCLINATA_DESCENDENS:
    case G_4_PUNCTA_INCLINATA_DESCENDENS:
    case G_5_PUNCTA_INCLINATA_DESCENDENS:
    case G_2_PUNCTA_INCLINATA_ASCENDENS:
    case G_3_PUNCTA_INCLINATA_ASCENDENS:
    case G_4_PUNCTA_INCLINATA_ASCENDENS:
    case G_5_PUNCTA_INCLINATA_ASCENDENS:
      while (current_note)
	{
	  libgregorio_gregoriotex_write_note (f, current_note,
					      next_note_pitch);
	  libgregorio_gregoriotex_write_signs (f, T_ONE_NOTE, glyph,
					       current_note);
	  current_note = current_note->next_note;
	}
      break;
    case G_TORCULUS_RESUPINUS:
      libgregorio_gregoriotex_write_note (f, current_note, next_note_pitch);
      libgregorio_gregoriotex_write_signs (f, T_ONE_NOTE, glyph,
					   glyph->first_note);
      // tricky to have the good position for these glyphs
      glyph->first_note = current_note->next_note;
      glyph->glyph_type = G_PORRECTUS_NO_BAR;
      libgregorio_gregoriotex_determine_number_and_type (glyph, &type,
							 &glyph_number);
      libgregorio_gregoriotex_write_signs (f, type, glyph, glyph->first_note);
      glyph->glyph_type = G_TORCULUS_RESUPINUS;
//TODO : fusion functions
      fprintf (f, "\\glyph{^^^^%04x}{%c}{%c}{%d}%%\n", glyph_number,
	       glyph->first_note->pitch, next_note_pitch, type);
      glyph->first_note = current_note;
      break;
    case G_TORCULUS_RESUPINUS_FLEXUS:
      libgregorio_gregoriotex_write_note (f, current_note, next_note_pitch);
      libgregorio_gregoriotex_write_signs (f, T_ONE_NOTE, glyph,
					   glyph->first_note);
      glyph->glyph_type = G_PORRECTUS_FLEXUS_NO_BAR;
      // tricky to have the good position for these glyphs
      glyph->first_note = current_note->next_note;
      libgregorio_gregoriotex_determine_number_and_type (glyph, &type,
							 &glyph_number);
      libgregorio_gregoriotex_write_signs (f, type, glyph, glyph->first_note);
      glyph->glyph_type = G_TORCULUS_RESUPINUS_FLEXUS;
//TODO : fusion functions
      fprintf (f, "\\glyph{^^^^%04x}{%c}{%c}{%d}%%\n", glyph_number,
	       glyph->first_note->pitch, next_note_pitch, type);
      glyph->first_note = current_note;
      break;
    case G_BIVIRGA:
    case G_DISTROPHA:
      while (current_note)
	{
	  libgregorio_gregoriotex_write_note (f, current_note,
					      next_note_pitch);
	  libgregorio_gregoriotex_write_signs (f, T_ONE_NOTE, glyph,
					       current_note);
	  current_note = current_note->next_note;
	  if (current_note)
	    {
	      fprintf (f, "\\endofglyph{4}%%\n");
	    }
	}
      break;
    case G_TRIVIRGA:
    case G_TRISTROPHA:
      while (current_note)
	{
	  libgregorio_gregoriotex_write_note (f, current_note,
					      next_note_pitch);
	  libgregorio_gregoriotex_write_signs (f, T_ONE_NOTE, glyph,
					       current_note);
	  current_note = current_note->next_note;
	  if (current_note)
	    {
	      fprintf (f, "\\endofglyph{5}%%\n");
	    }
	}
      break;
    case G_PUNCTUM_INCLINATUM:
    case G_VIRGA:
    case G_STROPHA:
    case G_STROPHA_AUCTA:
    case G_PUNCTUM:
      libgregorio_gregoriotex_write_note (f, glyph->first_note,
					  next_note_pitch);
      libgregorio_gregoriotex_write_signs (f, T_ONE_NOTE, glyph,
					   current_note);
      break;
    default:
      libgregorio_gregoriotex_determine_number_and_type (glyph, &type,
							 &glyph_number);
      fprintf (f, "\\glyph{^^^^%04x}{%c}{%c}{%d}%%\n", glyph_number,
	       glyph->first_note->pitch, next_note_pitch, type);
      libgregorio_gregoriotex_write_signs (f, type, glyph, glyph->first_note);
      break;
    }
}

/*

A function that write the signs of a glyph, which has the type type (T_*, not G_*, which is in the glyph->glyph_type), and (important), we start only at the note current_note. It is due to the way we call it : if type is T_ONE_NOTE, we just do the signs on current_note, not all. This is the case for example for the first note of the torculus resupinus, or the G_*_PUNCTA_INCLINATA.

*/

void
libgregorio_gregoriotex_write_signs (FILE * f, char type,
				     gregorio_glyph * glyph,
				     gregorio_note * current_note)
{
  // i is the number of the note for which we are typesetting the sign.
  int i = 1;
  while (current_note)
    {
      switch (current_note->signs)
	{
	case _PUNCTUM_MORA:
	  fprintf (f, "\\punctummora{%c}%%\n", current_note->pitch);
	  break;
	case _AUCTUM_DUPLEX:
	  fprintf (f, "\\augmentumduplex{%c}%%\n", current_note->pitch);
	  break;
	case _V_EPISEMUS:
	  libgregorio_gregoriotex_write_vepisemus (f, glyph, i, type,
						   current_note);
	  break;
	case _V_EPISEMUS_PUNCTUM_MORA:
	  libgregorio_gregoriotex_write_vepisemus (f, glyph, i, type,
						   current_note);
	  fprintf (f, "\\punctummora{%c}%%\n", current_note->pitch);
	  break;
	case _V_EPISEMUS_AUCTUM_DUPLEX:
	  libgregorio_gregoriotex_write_vepisemus (f, glyph, i, type,
						   current_note);
	  fprintf (f, "\\augmentumduplex{%c}%%\n", current_note->pitch);
	  break;
	default:
	  break;
	}
      if (current_note->h_episemus_type != H_NO_EPISEMUS
	  && current_note->h_episemus_top_note != 'm')
	{
// if it is a porrectus or a porrectus flexus, we check if the episemus is on the two first notes:
	  if ((type == T_PORRECTUS || type == T_PORRECTUSFLEXUS
	       || type == T_PORRECTUSFLEXUS_NOBAR
	       || type == T_PORRECTUS_NOBAR) && current_note->next_note
	      && current_note->next_note->h_episemus_type != H_NO_EPISEMUS)
	    {
	      libgregorio_gregoriotex_write_hepisemus (f, glyph,
						       HEPISEMUS_FIRST_TWO,
						       type, current_note);
	      i++;
	      current_note = current_note->next_note;
	    }
	  else
	    {
	      libgregorio_gregoriotex_write_hepisemus (f, glyph, i, type,
						       current_note);
	    }
	}
      // a bit dirty, depends on the way we call it
      if (type == T_ONE_NOTE)
	{
	  return;
	}
      else
	{
	  current_note = current_note->next_note;
	  i++;
	}
    }
}

// a function that writes the good \hepisemus un GregorioTeX. i is the position of the note in the glyph.

#define hepisemus_note_before_last_note() \
  if ((current_glyph->liquescentia == L_DEMINUTUS_INITIO_DEBILIS || current_glyph->liquescentia == L_DEMINUTUS) && current_note->next_note)\
    {\
	  fprintf (f, "\\hepisemus{%c}{3}{O}%%\n", current_note->h_episemus_top_note+1);\
    }\
  else \
    {\
      fprintf (f, "\\hepisemus{%c}{2}{O}%%\n", current_note->h_episemus_top_note+1);\
    }

#define hepisemus_last_note() \
  if (current_glyph->liquescentia == L_DEMINUTUS_INITIO_DEBILIS || current_glyph->liquescentia == L_DEMINUTUS)\
    {\
      /* may seem strange, but it is unlogical to typeset a small horizontal episemus at the end of a flexus deminutus */\
      fprintf (f, "\\hepisemus{%c}{3}{O}%%\n", current_note->h_episemus_top_note+1);\
    }\
  else \
    {\
      fprintf (f, "\\hepisemus{%c}{0}{O}%%\n", current_note->h_episemus_top_note+1);\
    }

void
libgregorio_gregoriotex_write_hepisemus (FILE * f,
					 gregorio_glyph * current_glyph,
					 int i, char type,
					 gregorio_note * current_note)
{
  if (!current_note || current_note->h_episemus_type == H_NO_EPISEMUS)
    {
      return;
    }
  switch (type)
    {
    case T_PES:
    case T_PESQUILISMA:
/* in the case of a pes, we put the episemus just under the bottom note */
      if (i == 1)
	{
	  if (current_glyph->liquescentia >= L_INITIO_DEBILIS)
	    {
	      fprintf (f, "\\hepisemus{%c}{1}{0}%%\n",
		       current_note->pitch - 2);
	    }
	  else
	    {
	      fprintf (f, "\\hepisemus{%c}{0}{0}%%\n",
		       current_note->pitch - 2);
	    }
	}
      else
	{			/* i=2 */
	  if (current_glyph->liquescentia >= L_INITIO_DEBILIS)
	    {
	      fprintf (f, "\\hepisemus{%c}{1}{0}%%\n",
		       current_note->h_episemus_top_note + 1);
	    }
	  else
	    {
	      fprintf (f, "\\hepisemus{%c}{0}{0}%%\n",
		       current_note->h_episemus_top_note + 1);
	    }
	}
      break;
    case T_PESQUADRATUM:
    case T_PESQUASSUS:
    case T_PESQUILISMAQUADRATUM:
      if (i == 1)
	{
	  if (current_glyph->liquescentia >= L_INITIO_DEBILIS)
	    {
	      fprintf (f, "\\hepisemus{%c}{7}{0}%%\n",
		       current_note->h_episemus_top_note + 1);
	    }
	  else
	    {
	      fprintf (f, "\\hepisemus{%c}{6}{0}%%\n",
		       current_note->h_episemus_top_note + 1);
	    }
	}
      else
	{			/* i=2 */
	  if (current_glyph->liquescentia == L_DEMINUTUS_INITIO_DEBILIS
	      || current_glyph->liquescentia == L_DEMINUTUS)
	    {
	      fprintf (f, "\\hepisemus{%c}{7}{0}%%\n",
		       current_note->h_episemus_top_note + 1);
	    }
	  else
	    {
	      fprintf (f, "\\hepisemus{%c}{6}{0}%%\n",
		       current_note->h_episemus_top_note + 1);
	    }
	}
      break;
    case T_FLEXUS:
    case T_FLEXUS_LONGQUEUE:
      switch (i)
	{
	case 1:
	  hepisemus_note_before_last_note ();
	  break;
	default:		/* i=2 */
	  hepisemus_last_note ();
	  break;
	}
      break;
    case T_PORRECTUSFLEXUS:
    case T_PORRECTUSFLEXUS_NOBAR:
      switch (i)
	{
	case HEPISEMUS_FIRST_TWO:
	  // special case, called when the horizontal episemus is on the fist two notes of a glyph. We consider current_note to be the first note.
	  if (!current_note->next_note)
	    {
	      return;
	    }
	  fprintf (f, "\\hepisemus{%c}{9}{%d}%%\n",
		   current_note->h_episemus_top_note + 1,
		   (current_note->pitch - current_note->next_note->pitch));
	case 1:
	  fprintf (f, "\\hepisemus{%c}{6}{0}%%\n",
		   current_note->h_episemus_top_note + 1);
	  break;
	case 2:
	  if (current_glyph->liquescentia == L_DEMINUTUS_INITIO_DEBILIS
	      || current_glyph->liquescentia == L_DEMINUTUS)
	    {
	      fprintf (f, "\\hepisemus{%c}{5}{0}%%\n",
		       current_note->h_episemus_top_note + 1);
	    }
	  else
	    {
	      fprintf (f, "\\hepisemus{%c}{4}{0}%%\n",
		       current_note->h_episemus_top_note + 1);
	    }
	  break;
	case 3:
	  hepisemus_note_before_last_note ();
	  break;
	default:
	  hepisemus_last_note ();
	  break;
	}
      break;
    case T_PORRECTUS:
    case T_PORRECTUS_NOBAR:
      switch (i)
	{
	case HEPISEMUS_FIRST_TWO:
	  // special case, called when the horizontal episemus is on the fist two notes of a glyph. We consider current_note to be the first note.
	  if (!current_note->next_note)
	    {
	      return;
	    }
	  fprintf (f, "\\hepisemus{%c}{8}{%d}%%\n",
		   current_note->h_episemus_top_note + 1,
		   (current_note->pitch - current_note->next_note->pitch));
	case 1:
	  fprintf (f, "\\hepisemus{%c}{6}{0}%%\n",
		   current_note->h_episemus_top_note + 1);
	  break;
	case 2:
	  hepisemus_note_before_last_note ();
	  break;
	default:
	  hepisemus_last_note ();
	  break;
	}
      break;
    case T_TORCULUS:
      switch (i)
	{
	case 1:
	  if (current_glyph->liquescentia >= L_INITIO_DEBILIS)
	    {
	      fprintf (f, "\\hepisemus{%c}{7}{0}%%\n",
		       current_note->h_episemus_top_note + 1);
	    }
	  else
	    {
	      fprintf (f, "\\hepisemus{%c}{6}{0}%%\n",
		       current_note->h_episemus_top_note + 1);
	    }
	  break;
	case 2:
	  hepisemus_note_before_last_note ();
	  break;
	default:
	  hepisemus_last_note ();
	  break;
	}
      break;
    default:			/* case T_ONE_NOTE */
      // we consider that oriscus and quilisma have the same width as punctum
      switch (current_note->shape)
	{
	case S_PUNCTUM_INCLINATUM:
	  if (current_glyph->liquescentia == L_DEMINUTUS_INITIO_DEBILIS
	      || current_glyph->liquescentia == L_DEMINUTUS)
	    {
	      fprintf (f, "\\hepisemus{%c}{11}{O}%%\n",
		       current_note->h_episemus_top_note + 1);
	    }
	  else
	    {
	      fprintf (f, "\\hepisemus{%c}{10}{O}%%\n",
		       current_note->h_episemus_top_note + 1);
	    }
	  break;
	case S_STROPHA:
	  fprintf (f, "\\hepisemus{%c}{12}{O}%%\n",
		   current_note->h_episemus_top_note + 1);
	  break;
	default:
	  fprintf (f, "\\hepisemus{%c}{0}{O}%%\n",
		   current_note->h_episemus_top_note + 1);
	  break;
	}
      break;
    }

}

/*

a function that writes the good value of \vepisemus in GregorioTeX. i is the position of the note in the glyph

*/

// two macros that write the final note and the note before the final note. In the cases where it is a flexus, it typesets the episemus before the two notes if there is enough place.

#define vepisemus_note_before_last_note() \
  if ((current_glyph->liquescentia == L_DEMINUTUS_INITIO_DEBILIS || current_glyph->liquescentia == L_DEMINUTUS) && current_note->next_note)\
    {\
      if ((current_note->pitch - current_note->next_note->pitch) < 4) \
	{\
	  fprintf (f, "\\vepisemus{%c}{3}%%\n", current_note->next_note->pitch-1);\
	}\
      else\
	{\
	  fprintf(f, "\\vepisemus{%c}{3}%%\n", current_note->pitch-1);\
	}\
    }\
  else \
    {\
      fprintf (f, "\\vepisemus{%c}{2}%%\n", current_note->pitch-1);\
    }

#define vepisemus_last_note() \
  if (current_glyph->liquescentia == L_DEMINUTUS_INITIO_DEBILIS || current_glyph->liquescentia == L_DEMINUTUS)\
    {\
      fprintf (f, "\\vepisemus{%c}{1}%%\n", current_note->pitch-1);\
    }\
  else \
    {\
      fprintf (f, "\\vepisemus{%c}{0}%%\n", current_note->pitch-1);\
    }


void
libgregorio_gregoriotex_write_vepisemus (FILE * f,
					 gregorio_glyph * current_glyph,
					 int i, char type,
					 gregorio_note * current_note)
{
  if (current_note->pitch == 'a')
    {
      return;
    }
  switch (type)
    {
    case T_PES:
    case T_PESQUILISMA:
/* in the case of a pes, we put the episemus just under the bottom note */
/* TODO: modify to typeset the episemus between the two notes if there is enough place */
      if (i == 1)
	{
	  if (current_glyph->liquescentia >= L_INITIO_DEBILIS)
	    {
	      fprintf (f, "\\vepisemus{%c}{1}%%\n", current_note->pitch - 1);
	    }
	  else
	    {
	      fprintf (f, "\\vepisemus{%c}{0}%%\n", current_note->pitch - 1);
	    }
	}
      else
	{			/* i=2 */
/* we don't print two episema */
	  if (!current_note->previous_note
	      || current_note->previous_note->signs >= _V_EPISEMUS)
	    {
	      break;
	    }
	  if (current_glyph->liquescentia >= L_INITIO_DEBILIS)
	    {
	      fprintf (f, "\\vepisemus{%c}{1}%%\n",
		       current_note->previous_note->pitch - 1);
	    }
	  else
	    {
	      fprintf (f, "\\vepisemus{%c}{0}%%\n",
		       current_note->previous_note->pitch - 1);
	    }
	}
      break;
    case T_PESQUADRATUM:
    case T_PESQUASSUS:
    case T_PESQUILISMAQUADRATUM:
      if (i == 1)
	{
	  if (current_glyph->liquescentia >= L_INITIO_DEBILIS)
	    {
	      fprintf (f, "\\vepisemus{%c}{7}%%\n", current_note->pitch - 1);
	    }
	  else
	    {
	      fprintf (f, "\\vepisemus{%c}{6}%%\n", current_note->pitch - 1);
	    }
	}
      else
	{			/* i=2 */
	  if (current_glyph->liquescentia == L_DEMINUTUS_INITIO_DEBILIS
	      || current_glyph->liquescentia == L_DEMINUTUS)
	    {
	      fprintf (f, "\\vepisemus{%c}{7}%%\n", current_note->pitch - 1);
	    }
	  else
	    {
	      fprintf (f, "\\vepisemus{%c}{6}%%\n", current_note->pitch - 1);
	    }
	}
      break;
    case T_FLEXUS:
    case T_FLEXUS_LONGQUEUE:
      switch (i)
	{
	case 1:
	  vepisemus_note_before_last_note ();
	  break;
	default:		/* i=2 */
	  vepisemus_last_note ();
	  break;
	}
      break;
    case T_PORRECTUSFLEXUS:
    case T_PORRECTUSFLEXUS_NOBAR:
      switch (i)
	{
	case 1:
	  fprintf (f, "\\vepisemus{%c}{8}%%\n", current_note->pitch - 1);
	  break;
	case 2:
	  if (current_glyph->liquescentia == L_DEMINUTUS_INITIO_DEBILIS
	      || current_glyph->liquescentia == L_DEMINUTUS)
	    {
	      fprintf (f, "\\vepisemus{%c}{5}%%\n", current_note->pitch - 1);
	    }
	  else
	    {
	      fprintf (f, "\\vepisemus{%c}{4}%%\n", current_note->pitch - 1);
	    }
	  break;
	case 3:
	  vepisemus_note_before_last_note ();
	  break;
	default:
	  vepisemus_last_note ();
	  break;
	}
      break;
    case T_PORRECTUS:
    case T_PORRECTUS_NOBAR:
      switch (i)
	{
	case 1:
	  fprintf (f, "\\vepisemus{%c}{8}%%\n", current_note->pitch - 1);
	  break;
	case 2:
	  vepisemus_note_before_last_note ();
	  break;
	default:
	  vepisemus_last_note ();
	  break;
	}
      break;
    case T_TORCULUS:
      switch (i)
	{
	case 1:
	  if (current_glyph->liquescentia >= L_INITIO_DEBILIS)
	    {
	      fprintf (f, "\\vepisemus{%c}{7}%%\n", current_note->pitch - 1);
	    }
	  else
	    {
	      fprintf (f, "\\vepisemus{%c}{6}%%\n", current_note->pitch - 1);
	    }
	  break;
	case 2:
	  vepisemus_note_before_last_note ();
	  break;
	default:
	  vepisemus_last_note ();
	  break;
	}
      break;
    default:			/* case T_ONE_NOTE */
      // we consider that oriscus and quilisma have the same width as punctum
      switch (current_note->shape)
	{
	case S_PUNCTUM_INCLINATUM:
	  if (current_glyph->liquescentia == L_DEMINUTUS_INITIO_DEBILIS
	      || current_glyph->liquescentia == L_DEMINUTUS)
	    {
	      fprintf (f, "\\vepisemus{%c}{10}%%\n",
		       current_note->pitch - 1);
	    }
	  else
	    {
	      fprintf (f, "\\vepisemus{%c}{9}%%\n",
		       current_note->pitch - 1);
	    }
	  break;
	case S_STROPHA:
	  fprintf (f, "\\vepisemus{%c}{11}%%\n",
		   current_note->pitch - 1);
	  break;
	default:
	  fprintf (f, "\\vepisemus{%c}{0}%%\n",
		   current_note->pitch - 1);
	  break;
	}
      break;
    }
}


/*

the different numbers of the liquescentiae are:
'nothing':0,
'initiodebilis':1,
'deminutus':2,
'auctusascendens':3,
'auctusdescendens':4,
'initiodebilisdeminutus':5,
'initiodebilisauctusascendens':6,
'initiodebilisauctusdescendens':7

if it is an auctus, which may be ascendens or descendens, by default we consider it as an ascendens

they also are and must be the same as in squarize.py.

to obtain the glyph number, we just do 2048 * glyphtype + 256 * liquescentia + x

where x is a number related to the differences between te heights of the notes:

if i is the difference between the two first notes, j between the second and the third and k the difference betweend the third and the fourth, x = i + 5 * j + 25 * k

*/

unsigned int
gregoriotex_determine_liquescentia_number (unsigned char type,
					   char liquescentia)
{
  if (liquescentia == L_AUCTA)
    {
      liquescentia = L_AUCTUS_ASCENDENS;
    }
  if (liquescentia == L_AUCTA_INITIO_DEBILIS)
    {
      liquescentia = L_AUCTUS_ASCENDENS_INITIO_DEBILIS;
    }
  switch (type)
    {
    case L_ALL:
      return LIQ_FACTOR * liquescentia;
      break;
    case L_NO_INITIO:
      if (liquescentia >= L_INITIO_DEBILIS)
	{
	  liquescentia = liquescentia - L_INITIO_DEBILIS;
	}
      break;
    case L_ONLY_DEMINUTUS:
      if (liquescentia != L_DEMINUTUS
	  && liquescentia != L_DEMINUTUS_INITIO_DEBILIS)
	{
	  liquescentia = L_NO_LIQUESCENTIA;
	}
    case L_UNDET_AUCTUS:
      if (liquescentia == L_AUCTUS_DESCENDENS)
	{
	  liquescentia = L_AUCTUS_ASCENDENS;
	}
      if (liquescentia == L_AUCTUS_DESCENDENS_INITIO_DEBILIS)
	{
	  liquescentia = L_AUCTUS_ASCENDENS_INITIO_DEBILIS;
	}
      break;
    default:
      return 0;
    }
  return LIQ_FACTOR * liquescentia;
}

// finaly the function that calculates the number of the glyph. It also calculates the type, used for determining the position of signs. Type is very basic, it is only the global dimensions : torculus, one_note, etc.

void
libgregorio_gregoriotex_determine_number_and_type (gregorio_glyph *
						   glyph, int *type,
						   unsigned int *glyph_number)
{
  unsigned int temp = 0;
  char pitch;
  char liquescentia;

  if (!glyph)
    {
      libgregorio_message (_
			   ("called with NULL pointer"),
			   "libgregorio_gregoriotex_determine_number_and_type",
			   ERROR, 0);
      return;
    }
  if (!glyph->first_note)
    {
      libgregorio_message (_
			   ("called with a glyph that have no note"),
			   "libgregorio_gregorio_tex_determine_number_and_type",
			   ERROR, 0);
      return;
    }
  liquescentia = glyph->liquescentia;
  /* commented, but must be there for the font gregoria (as there is no auctus descendens). TODO : having a variable telling the font
     if (liquescentia == L_AUCTUS_ASCENDENS)
     {
     glyph->liquescentia = L_AUCTUS_DESCENDENS;
     }
     if (liquescentia == L_AUCTUS_ASCENDENS_INITIO_DEBILIS)
     {
     glyph->liquescentia = L_AUCTUS_DESCENDENS_INITIO_DEBILIS;
     } */
  switch (glyph->glyph_type)
    {
    case G_PODATUS:
      switch (glyph->first_note->shape)
	{
	case S_QUILISMA:
	  *type = T_PESQUILISMA;
	  temp =
	    TYPE_FACTOR * T_PESQUILISMA +
	    gregoriotex_determine_liquescentia_number (L_ALL,
						       glyph->liquescentia);
	  break;
	case S_ORISCUS:
	  *type = T_PESQUASSUS;
	  temp =
	    TYPE_FACTOR * T_PESQUASSUS +
	    gregoriotex_determine_liquescentia_number (L_ALL,
						       glyph->liquescentia);
	  break;
	default:
	  *type = T_PES;
	  temp =
	    TYPE_FACTOR * T_PES +
	    gregoriotex_determine_liquescentia_number (L_ALL,
						       glyph->liquescentia);
	  break;
	}
      break;
    case G_PES_QUADRATUM:
      switch (glyph->first_note->shape)
	{
	case S_QUILISMA:
	  *type = T_PESQUILISMA;
	  temp =
	    TYPE_FACTOR * T_PESQUILISMA +
	    gregoriotex_determine_liquescentia_number (L_ALL,
						       glyph->liquescentia);
	  break;
	case S_ORISCUS:
	  *type = T_PESQUILISMAQUADRATUM;
	  temp =
	    TYPE_FACTOR * T_PESQUILISMAQUADRATUM +
	    gregoriotex_determine_liquescentia_number (L_ALL,
						       glyph->liquescentia);
	  break;
	default:
	  *type = T_PESQUADRATUM;
	  temp =
	    TYPE_FACTOR * T_PESQUADRATUM +
	    gregoriotex_determine_liquescentia_number (L_ALL,
						       glyph->liquescentia);
	  break;
	}
      break;
    case G_FLEXA:
      pitch = glyph->first_note->pitch;
      if (is_short (pitch))
	{
	  *type = T_FLEXUS;
	  temp =
	    TYPE_FACTOR * T_FLEXUS +
	    gregoriotex_determine_liquescentia_number (L_NO_INITIO,
						       glyph->liquescentia);
	}
      else
	{
	  *type = T_FLEXUS_LONGQUEUE;
	  temp =
	    TYPE_FACTOR * T_FLEXUS_LONGQUEUE +
	    gregoriotex_determine_liquescentia_number (L_NO_INITIO,
						       glyph->liquescentia);
	}
      break;
    case G_TORCULUS:
      *type = T_TORCULUS;
      temp =
	TYPE_FACTOR * T_TORCULUS +
	gregoriotex_determine_liquescentia_number (L_ALL,
						   glyph->liquescentia);
      break;
    case G_PORRECTUS:
      *type = T_PORRECTUS;
      temp =
	TYPE_FACTOR * T_PORRECTUS +
	gregoriotex_determine_liquescentia_number (L_ONLY_DEMINUTUS,
						   glyph->liquescentia);
      break;
    case G_PORRECTUS_FLEXUS:
      *type = T_PORRECTUSFLEXUS;
      temp =
	TYPE_FACTOR * T_PORRECTUSFLEXUS +
	gregoriotex_determine_liquescentia_number (L_NO_INITIO,
						   glyph->liquescentia);
      break;
    case G_PORRECTUS_NO_BAR:
      *type = T_PORRECTUS_NOBAR;
      temp =
	TYPE_FACTOR * T_PORRECTUS_NOBAR +
	gregoriotex_determine_liquescentia_number (L_ONLY_DEMINUTUS,
						   glyph->liquescentia);
      break;
    case G_PORRECTUS_FLEXUS_NO_BAR:
      *type = T_PORRECTUSFLEXUS_NOBAR;
      temp =
	TYPE_FACTOR * T_PORRECTUSFLEXUS_NOBAR +
	gregoriotex_determine_liquescentia_number (L_NO_INITIO,
						   glyph->liquescentia);
      break;
    case G_SCANDICUS:
//TODO ?
      *type = T_TORCULUS;
      break;
    default:
      libgregorio_message (_
			   ("called with unknown glyph"),
			   "libgregorio_gregorio_tex_determine_number_and_type",
			   ERROR, 0);
      break;
    }

  *glyph_number = libgregorio_gregoriotex_determine_interval (glyph);
  *glyph_number = temp + (*glyph_number);
  // we change to the original liquescentia
  glyph->liquescentia = liquescentia;
  // we fix *type with initio_debilis
  /* can't remember the meaning of this code...
     if (*type == T_ONE_NOTE)
     {
     if (is_initio_debilis (liquescentia))
     {
     *type = T_INITIO_DEBILIS;
     }
     }
   */
}



unsigned int
libgregorio_gregoriotex_determine_interval (gregorio_glyph * glyph)
{
  gregorio_note *current_note;
  unsigned int current;
// then we start making our formula
  char first;
  char second;

  if (!glyph)
    {
      libgregorio_message (_
			   ("called with NULL pointer"),
			   "libgregorio_gregoriotex_determine_interval",
			   ERROR, 0);
      return 0;
    }
  if (!glyph->first_note)
    {
      libgregorio_message (_
			   ("called with a glyph that have no note"),
			   "libgregorio_gregoriotex_determine_interval",
			   ERROR, 0);
      return 0;
    }
  current_note = glyph->first_note;
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
      current = 5 * (second - first) + current;
    }
  else
    {
      current = 5 * (first - second) + current;
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
      current = 25 * (second - first) + current;
    }
  else
    {
      current = 25 * (first - second) + current;
    }
  return current;
}

/* function used when the glyph is only one note long, the glyph number are simply the following:
* 01: c clef
* 02: f clef
* 05: flat (oriented to the top)
* 06: flat (oriented to the bottom)
* 07: natural
* 08: virgula
* 09: divisio minima
* 10: divisio minor
* 11: divisio maior
* 12: divisio finalis
* 13: punctum deminutum
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
* 31: punctum inclinatum auctum
* 32: punctum inclinatum deminutus
* 33: vertical episemus
* 34: punctum cavum
* 35: linea punctum
* 36: linea puctum cavum
* 37: circulus
* 38: semi-curculus
* 39: accentus

* 60: custo for bass notes (oriented to the top)
* 61: custo for bass notes (oriented to the top) with short bar
* 62: custo for bass notes (oriented to the top) with middle bar (for the lowest note)
* 63: custo for high notes (oriented to the bottom)
* 64: custo for high notes (oriented to the bottom) with short bar
* 65: custo for high notes (oriented to the bottom) with short bar (for the highest note)
* 66->71: idem for second type of custo
* 71->76: idem for third type

* 80: A with bar
* 81: R with bar
* 82: V with bar

*/

// and the different types of horizontal episemus:
//* 40: horizontal episemus, width of a punctum
#define H_PUNCTUM 40
//* 41: horizontal episemus, width of a flexus debilis
#define H_FLEXUS 41
//* 42: horizontal episemus, width of an initio debilis
#define H_INITIO 42
//* 43: horizontal episemus, width of a punctum inclinatum
#define H_INCLINATUM 43
//* 44: horizontal episemus, width of a punctum inclinatum deminutus
#define H_INCLINATUM_DEMINUTUS 44
//* 45: horizontal episemus, width of a stropha
#define H_STROPHA 45
//* 46: horizontal episemus, width of a porrectus with ambitus of 1
#define H_PORRECTUS1 46
//* 47: horizontal episemus, width of a porrectus with ambitus of 2
#define H_PORRECTUS2 47
//* 48: horizontal episemus, width of a porrectus with ambitus of 3
#define H_PORRECTUS3 48
//* 49: horizontal episemus, width of a porrectus with ambitus of 4
#define H_PORRECTUS4 49
//* 50: horizontal episemus, width of a porrectus with ambitus of 5
#define H_PORRECTUS5 50
//* 51: horizontal episemus, width of a porrectus flexus with ambitus of 1
#define H_PORRECTUS_FLEXUS1 51
//* 52: horizontal episemus, width of a porrectus flexus with ambitus of 2
#define H_PORRECTUS_FLEXUS2 52
//* 53: horizontal episemus, width of a porrectus flexus with ambitus of 3
#define H_PORRECTUS_FLEXUS3 53
//* 54: horizontal episemus, width of a porrectus flexus with ambitus of 4
#define H_PORRECTUS_FLEXUS4 54
//* 55: horizontal episemus, width of a porrectus flexus with ambitus of 5
#define H_PORRECTUS_FLEXUS5 55
// * 56: horizontal episemus, width of a quilisma
#define H_QUILISMA 56
// * 57: horizontal episemus, width of an oriscus
#define H_ORISCUS 57


void
libgregorio_gregoriotex_write_note (FILE * f, gregorio_note * note,
				    char next_note_pitch)
{
  int glyph_number;
  char temp;

  if (!note)
    {
      libgregorio_message (_
			   ("called with NULL pointer"),
			   "libgregorio_gregoriotex_write_note", ERROR, 0);
      return;
    }
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
  fprintf (f, "\\glyph{^^^^%04x}{%c}{%c}{0}%%\n", glyph_number,
	   note->pitch, next_note_pitch);
}


char
libgregorio_gregoriotex_determine_next_note (gregorio_syllable * syllable,
					     gregorio_element * element,
					     gregorio_glyph * glyph)
{
  char temp;

  if (!glyph || !element || !syllable)
    {
      libgregorio_message (_
			   ("called with a NULL argument"),
			   "libgregorio_gregoriotex_determine_next_note",
			   ERROR, 0);
      return 'g';
    }
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
  gregorio_glyph *glyph;
  gregorio_element *element;

  if (!syllable)
    {
      libgregorio_message (_
			   ("called with a NULL argument"),
			   "libgregorio_gregoriotex_determine_next_note",
			   ERROR, 0);
    }
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
