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
#include <string.h>
#include <gregorio/struct.h>
#include <gregorio/unicode.h>
#include <gregorio/plugin.h>
#include <gregorio/messages.h>
#include <gregorio/characters.h>

#include "gregoriotex.h"

DECLARE_PLUGIN (gregoriotex)
{
.id = "gtex",.name = "gregoriotex",.description =
    "GregorioTeX output plugin",.author =
    "Elie Roux <elie.roux@enst-bretagne.fr>",.file_extension = "tex",.type =
    GREGORIO_PLUGIN_OUTPUT,.write = write_score};

void
write_score (FILE * f, gregorio_score * score)
{
  gregorio_character *first_text;
  // a char that will contain 1 if it is the first syllable and 0 if not. It is for the initial.
  char first_syllable = 0;
  char clef_letter;
  int clef_line;
  gregorio_syllable *current_syllable;
  // the current line (as far as we know), it is always 0, it can be 1 in the case of the first line of a score with a two lines initial
  unsigned char line = 0;
  gregorio_line *first_line;

  if (!f)
    {
      gregorio_message (_
			("call with NULL file"),
			"libgregorio_gregoriotex_write_score", ERROR, 0);
      return;
    }

  if (score->number_of_voices != 1)
    {
      gregorio_message (_
			("gregoriotex only works in monophony (for the moment)"),
			"libgregorio_gregoriotex_write_score", ERROR, 0);
    }
  fprintf (f, "\\begingregorioscore%%\n");
  // if necessary, we add some bottom space to the first line
  first_line = (gregorio_line *) malloc (sizeof (gregorio_line));
  libgregorio_gregoriotex_seeklinespaces (score->first_syllable, first_line);
  if (first_line->additional_bottom_space != 0
      || first_line->translation != 0)
    {
      fprintf (f, "\\firstlinebottomspace{%u}{%u}%%\n",
	       first_line->additional_bottom_space, first_line->translation);
    }
  free (first_line);
  // we select the good font
  if (score->gregoriotex_font)
    {
      if (!strcmp (score->gregoriotex_font, "gregorio"))
	{
	  fprintf (f, "\\setgregorianfont{gregorio}%%\n");
	}
      if (!strcmp (score->gregoriotex_font, "parmesan"))
	{
	  fprintf (f, "\\setgregorianfont{parmesan}%%\n");
	}
      if (!strcmp (score->gregoriotex_font, "greciliae"))
	{
	  fprintf (f, "\\setgregorianfont{greciliae}%%\n");
	}
      if (!strcmp (score->gregoriotex_font, "gregoria"))
	{
	  fprintf (f, "\\setgregorianfont{gregoria}%%\n");
	}
    }
// first we draw the initial (first letter) and the initial key
  if (score->initial_style == NO_INITIAL)
    {
      fprintf (f, "\\grenoinitial %%\n");
    }
  else
    {
      if (score->initial_style == BIG_INITIAL)
	{
	  fprintf (f, "\\setbiginitial %%\n");
	  line = 1;
	}
      first_text = gregorio_first_text (score);
      if (first_text)
	{
	  fprintf (f, "\\greinitial{");
	  gregorio_write_initial (first_text, f,
				  (&libgregorio_gtex_write_verb),
				  (&libgregorio_gtex_print_char),
				  (&libgregorio_gtex_write_begin),
				  (&libgregorio_gtex_write_end),
				  (&libgregorio_gtex_write_special_char));
	  fprintf (f, "}%%\n");
	  first_syllable = SKIP_FIRST_LETTER;
	}
    }
  if (score->mode != 0)
    {
      fprintf (f, "\\gregorianmode{%d}%%\n", score->mode);
    }
  if (score->first_voice_info)
    {
      libgregorio_gregoriotex_write_voice_info (f, score->first_voice_info);
    }
  fprintf (f, "\\beginscore %%\n");
  if (score->first_voice_info)
    {
      gregorio_det_step_and_line_from_key (score->
					   first_voice_info->initial_key,
					   &clef_letter, &clef_line);
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
					      &first_syllable, &line);
      current_syllable = current_syllable->next_syllable;
    }
  fprintf (f, "\\endgregorioscore %%\n");
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
					char *first_syllable,
					unsigned char *line_number)
{
  gregorio_element *current_element;
  gregorio_line *line;

  if (!syllable)
    {
      return;
    }
  /* first we check if the syllable is only a end of line.
     If it is the case, we don't print anything but a comment (to be able to read it if we read GregorioTeX).
     The end of lines are treated separately in GregorioTeX, it is buit inside the TeX structure. */
  if ((syllable->elements) && (syllable->elements)[0])
    {

      if ((syllable->elements)[0]->type == GRE_END_OF_LINE)
	{
	  line = (gregorio_line *) malloc (sizeof (gregorio_line));
	  libgregorio_gregoriotex_seeklinespaces (syllable->next_syllable,
						  line);
	  if (line->additional_bottom_space == 0
	      && line->additional_top_space == 0 && line->translation == 0)
	    {
	      if ((syllable->elements)[0]->element_type != GRE_END_OF_PAR)
		{
		  fprintf (f, "%%\n%%\n\\grenewline %%\n%%\n%%\n");
		}
	      else
		{
		  fprintf (f, "%%\n%%\n\\grenewparline %%\n%%\n%%\n");
		}
	    }
	  else
	    {
	      if ((syllable->elements)[0]->element_type != GRE_END_OF_PAR)
		{
		  fprintf (f,
			   "%%\n%%\n\\grenewlinewithspace{%u}{%u}{%u}%%\n%%\n%%\n",
			   line->additional_top_space,
			   line->additional_bottom_space, line->translation);
		}
	      else
		{
		  fprintf (f,
			   "%%\n%%\n\\grenewparlinewithspace{%u}{%u}{%u}%%\n%%\n%%\n",
			   line->additional_top_space,
			   line->additional_bottom_space, line->translation);
		}

	    }
	  free (line);
	  if (*line_number == 1)
	    {
	      fprintf (f, "\\adjustthirdline %%\n");
	      *line_number = 0;
	    }
	  return;
	}
      if ((syllable->elements)[0]->type == GRE_BAR)
	{
	  if (!syllable->next_syllable && !syllable->text
	      && (syllable->elements)[0]->element_type == B_DIVISIO_FINALIS)
	    {
	      fprintf (f, "\\finaldivisiofinalis{0}%%\n");
	      return;
	    }
	  else
	    {
	      fprintf (f, "\\barsyllable");
	    }
	}
      else
	{
	  fprintf (f, "\\syllable");
	}
    }
  else
    {
      fprintf (f, "\\syllable");
    }
  libgregorio_gregoriotex_write_text (f, syllable->text, first_syllable);
  if (syllable->position == WORD_END
      || syllable->position == WORD_ONE_SYLLABLE || !syllable->text)
    {
      fprintf (f, "{1}");
    }
  else
    {
      fprintf (f, "{0}");
    }
  if (syllable->next_syllable)
    {
      libgregorio_gregoriotex_write_next_first_text (f,
						     syllable->
						     next_syllable->text);
      fprintf (f, "{%d}{",
	       libgregorio_gregoriotex_syllable_first_type
	       (syllable->next_syllable));
    }
  else
    {
      fprintf (f, "{}{}{0}{");
    }

  if (syllable->translation)
    {
      fprintf (f, "%%\n\\writetranslation{");
      libgregorio_gregoriotex_write_translation (f, syllable->translation);
      fprintf (f, "}%%\n");
    }
  if (syllable->next_syllable && (syllable->next_syllable->elements)[0]
      && (syllable->next_syllable->elements)[0]->type == GRE_END_OF_LINE)
    {
      fprintf (f, "%%\n\\lastofline %%\n");
    }

  fprintf (f, "}{%%\n");

  current_element = (syllable->elements)[0];
  while (current_element)
    {
      if (current_element->type == GRE_SPACE)
	{
	  if (current_element->element_type == SP_LARGER_SPACE)
	    {
	      fprintf (f, "\\endofelement{1}%%\n");
	    }
	  if (current_element->element_type == SP_GLYPH_SPACE)
	    {
	      fprintf (f, "\\endofelement{2}%%\n");
	    }
	  current_element = current_element->next_element;
	  continue;
	}
      if (current_element->type == GRE_C_KEY_CHANGE)
	{
	  fprintf (f, "\\changeclef{c}{%d}%%\n",
		   current_element->element_type - 48);
	  current_element = current_element->next_element;
	  continue;
	}
      if (current_element->type == GRE_F_KEY_CHANGE)
	{
	  fprintf (f, "\\changeclef{f}{%d}%%\n",
		   current_element->element_type - 48);
	  current_element = current_element->next_element;
	  continue;
	}
      if (current_element->type == GRE_BAR)
	{
	  if (current_element->next_element)
	    {
	      fprintf (f, "\\in");
	    }
	  else
	    {
	      fprintf (f, "\\");
	    }
	  libgregorio_gregoriotex_write_bar (f,
					     current_element->element_type);
	  fprintf (f, "%%\n");
	  current_element = current_element->next_element;
	  continue;
	}
      if (current_element->type == GRE_END_OF_LINE)
	{
	  line = (gregorio_line *) malloc (sizeof (gregorio_line));
	  // here we suppose we don't have two linebreaks in the same syllable
	  libgregorio_gregoriotex_seeklinespaces (syllable->next_syllable,
						  line);
	  if (line->additional_bottom_space == 0
	      && line->additional_top_space == 0 && line->translation == 0)
	    {
	      if (current_element->element_type != GRE_END_OF_PAR)
		{
		  fprintf (f, "%%\n%%\n\\grenewline %%\n%%\n%%\n");
		}
	      else
		{
		  fprintf (f, "%%\n%%\n\\grenewparline %%\n%%\n%%\n");
		}
	    }
	  else
	    {
	      if (current_element->element_type != GRE_END_OF_PAR)
		{
		  fprintf (f,
			   "%%\n%%\n\\grenewlinewithspace{%u}{%u}{%u}%%\n%%\n%%\n",
			   line->additional_top_space,
			   line->additional_bottom_space, line->translation);
		}
	      else
		{
		  fprintf (f,
			   "%%\n%%\n\\grenewparlinewithspace{%u}{%u}{%u}%%\n%%\n%%\n",
			   line->additional_top_space,
			   line->additional_bottom_space, line->translation);
		}

	    }
	  free (line);
	  if (*line_number == 1)
	    {
	      fprintf (f, "\\adjustthirdline %%\n");
	      *line_number = 0;
	    }
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
  if (syllable->position == WORD_END
      || syllable->position == WORD_ONE_SYLLABLE || !syllable->text)
    {
      fprintf (f, "%%\n");
    }
}


void
libgregorio_gregoriotex_seeklinespaces (gregorio_syllable * syllable,
					gregorio_line * line)
{
  gregorio_element *element;
  gregorio_glyph *glyph;
  gregorio_note *note;

  if (line == NULL || syllable == NULL)
    {
      gregorio_message (_
			("call with NULL pointer"),
			"libgregorio_gregoriotex_write_score", ERROR, 0);
      return;
    }

  line->additional_top_space = 0;
  line->additional_bottom_space = 0;
  line->translation = 0;

  while (syllable)
    {
      if (syllable->translation)
	{
	  line->translation = 1;
	}
      element = (syllable->elements)[0];
      while (element)
	{
	  if (element->type == GRE_END_OF_LINE)
	    {
	      return;
	    }
	  if (element->type != GRE_ELEMENT)
	    {
	      element = element->next_element;
	      continue;
	    }
	  glyph = element->first_glyph;
	  while (glyph)
	    {
	      if (glyph->type != GRE_GLYPH)
		{
		  glyph = glyph->next_glyph;
		  continue;
		}
	      note = glyph->first_note;
	      while (note)
		{
		  switch (note->pitch)
		    {
		    case 'a':
		      if (line->additional_bottom_space < 3)
			{
			  line->additional_bottom_space = 3;
			}
		      break;
		    case 'b':
		      if (line->additional_bottom_space < 2)
			{
			  line->additional_bottom_space = 2;
			}
		      break;
		    case 'c':
		      if (line->additional_bottom_space < 1)
			{
			  line->additional_bottom_space = 1;
			}
		      break;
		    case 'm':
		      if (line->additional_top_space < 3)
			{
			  line->additional_top_space = 3;
			}
		      break;
		    case 'l':
		      if (line->additional_top_space < 2)
			{
			  line->additional_top_space = 2;
			}
		      break;
		    case 'k':
		      if (line->additional_top_space < 1)
			{
			  line->additional_top_space = 1;
			}
		      break;
		    default:
		      break;
		    }
		  note = note->next_note;
		}
	      glyph = glyph->next_glyph;
	    }
	  element = element->next_element;
	}
      syllable = syllable->next_syllable;
    }
}

// we will need type for one thing for the moment : type=first_syllable=1 when it is the first syllable (for the initial).

void
libgregorio_gtex_write_begin (FILE * f, unsigned char style)
{
  switch (style)
    {
    case ST_ITALIC:
      fprintf (f, "\\greitalic{");
      break;
    case ST_SMALL_CAPS:
      fprintf (f, "\\gresmallcaps{");
      break;
    case ST_BOLD:
      fprintf (f, "\\greboldfont{");
      break;
    case ST_FORCED_CENTER:
    case ST_CENTER:
      fprintf (f, "}{");
      break;
    case ST_TT:
      fprintf (f, "\\grett{");
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
    case ST_FORCED_CENTER:
    case ST_CENTER:
      fprintf (f, "}{");
      break;
    default:
      fprintf (f, "}");
      break;
    }
}

// a specific function for writing ends of the two first parts of the text of the next syllable
void
libgregorio_gtex_write_end_for_two (FILE * f, unsigned char style)
{
  fprintf (f, "}");
}

void
libgregorio_gtex_write_special_char (FILE * f, grewchar * special_char)
{
  if (!wcscmp (special_char, L"A/"))
    {
      fprintf (f, "\\Abar");
      return;
    }
  if (!wcscmp (special_char, L"R/"))
    {
      fprintf (f, "\\Rbar");
      return;
    }
  if (!wcscmp (special_char, L"V/"))
    {
      fprintf (f, "\\Vbar");
      return;
    }
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
  if (!wcscmp (special_char, L"*"))
    {
      fprintf (f, "\\grestar ");
      return;
    }
  if (!wcscmp (special_char, L"+"))
    {
      fprintf (f, "\\gredagger ");
      return;
    }
}

void
libgregorio_gtex_write_verb (FILE * f, grewchar * verb_str)
{
  fprintf (f, "%ls", verb_str);
}

void
libgregorio_gtex_print_char (FILE * f, grewchar to_print)
{
// special case for the star, as it is < 128
  if (to_print == L'*')
    {
      fprintf (f, "\\grestar ");
      return;
    }
  if (to_print == L'+')
    {
      fprintf (f, "\\gredagger ");
      return;
    }
  if (to_print == L'_')
    {
      fprintf (f, "\\_ ");
      return;
    }
  if (to_print == L'~')
    {
      fprintf (f, "\\ensuremath{\\sim}");
      return;
    }
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
      fprintf (f, "\\char %d", to_print);
      break;
    }
}

// a function that takes a grewchar * and write it in omega style : every character is reprensented by ^^^^x where x is its hexadecimal representation on 4 letters (completed with 0)
void
libgregorio_print_unicode_letters (FILE * f, grewchar * wstr)
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
  gregorio_write_text (*first_syllable, text, f,
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

// the function to write the translation
void
libgregorio_gregoriotex_write_translation (FILE * f,
					   gregorio_character * translation)
{
  if (translation == NULL)
    {
      return;
    }
  gregorio_write_text (0, translation, f,
		       (&libgregorio_gtex_write_verb),
		       (&libgregorio_gtex_print_char),
		       (&libgregorio_gtex_write_begin),
		       (&libgregorio_gtex_write_end),
		       (&libgregorio_gtex_write_special_char));
}

// a function to write only the two first syllables of the next syllables
void
libgregorio_gregoriotex_write_next_first_text (FILE * f,
					       gregorio_character *
					       current_character)
{
  if (current_character == NULL)
    {
      fprintf (f, "{}{}");
      return;
    }
  gregorio_character *first_character = current_character;
  gregorio_character *next_character;
  // big dirty hack to have only the first two syllables printed : we cut the thing just after the ST_CENTER closing
  while (current_character)
    {
      if (current_character->is_character == 0
	  && (current_character->cos.s.style == ST_CENTER
	      || current_character->cos.s.style == ST_FORCED_CENTER)
	  && current_character->cos.s.type == ST_T_END)
	{
	  next_character = current_character->next_character;
	  current_character->next_character = NULL;

	  fprintf (f, "{");
	  gregorio_write_text (0, first_character, f,
			       (&libgregorio_gtex_write_verb),
			       (&libgregorio_gtex_print_char),
			       (&libgregorio_gtex_write_begin),
			       (&libgregorio_gtex_write_end_for_two),
			       (&libgregorio_gtex_write_special_char));
	  current_character->next_character = next_character;
	  return;
	}
      else
	{
	  current_character = current_character->next_character;
	}
    }
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
	  fprintf (f, "\\flat{%c}{0}%%\n", current_glyph->glyph_type);
	  current_glyph = current_glyph->next_glyph;
	  continue;
	}
      if (current_glyph->type == GRE_NATURAL)
	{
	  fprintf (f, "\\natural{%c}{0}%%\n", current_glyph->glyph_type);
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
	  if (is_puncta_inclinata (current_glyph->next_glyph->glyph_type)
	      || current_glyph->next_glyph->glyph_type == G_PUNCTA_INCLINATA)
	    {
	      fprintf (f, "\\endofglyph{9}%%\n");
	    }
	  else
	    {
	      fprintf (f, "\\endofglyph{0}%%\n");
	    }
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
      gregorio_message (_("unknown bar type"),
			"libgregorio_gregoriotex_write_bar", ERROR, 0);
      break;
    }
}

void
libgregorio_gregoriotex_write_glyph (FILE * f,
				     gregorio_syllable * syllable,
				     gregorio_element * element,
				     gregorio_glyph * glyph)
{
  unsigned int glyph_number = 0;
// glyph number is the number of the glyph in the fonte, it is discussed in later comments
// type is the type of the glyph. Understand the type of the glyph for gregoriotex, for the alignement between text and notes. (AT_ONE_NOTE, etc.)
  int type = 0;
  // the type of the glyph, in the sense of the shape (T_PES, etc.)
  char gtype = 0;
  char next_note_pitch = 0;
  gregorio_note *current_note;

  if (!glyph)
    {
      gregorio_message (_
			("called with NULL pointer"),
			"libgregorio_gregoriotex_write_glyph", ERROR, 0);
      return;
    }
  if (!glyph->first_note)
    {
      gregorio_message (_
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
    case G_SCANDICUS:
    case G_ANCUS:
      if (glyph->liquescentia == L_DEMINUTUS
	  || glyph->liquescentia == L_DEMINUTUS_INITIO_DEBILIS)
	{
	  libgregorio_gregoriotex_determine_number_and_type (glyph, &type,
							     &gtype,
							     &glyph_number);
	  fprintf (f, "\\glyph{\\char %d}{%c}{%c}{%d}%%\n", glyph_number,
		   glyph->first_note->pitch, next_note_pitch, type);
	  libgregorio_gregoriotex_write_signs (f, gtype, glyph,
					       glyph->first_note);
	}
      else
	{
	  while (current_note)
	    {
	      libgregorio_gregoriotex_write_note (f, current_note,
						  next_note_pitch);
	      libgregorio_gregoriotex_write_signs (f, T_ONE_NOTE, glyph,
						   current_note);
	      current_note = current_note->next_note;
	    }
	}
      break;
    case G_TORCULUS_RESUPINUS_FLEXUS:
      libgregorio_gregoriotex_write_note (f, current_note, next_note_pitch);
      libgregorio_gregoriotex_write_signs (f, T_ONE_NOTE, glyph,
					   glyph->first_note);
      glyph->glyph_type = G_PORRECTUS_FLEXUS_NO_BAR;
      // tricky to have the good position for these glyphs
      glyph->first_note = current_note->next_note;
      libgregorio_gregoriotex_determine_number_and_type (glyph, &type,
							 &gtype,
							 &glyph_number);
      libgregorio_gregoriotex_write_signs (f, gtype, glyph,
					   glyph->first_note);
      glyph->glyph_type = G_TORCULUS_RESUPINUS_FLEXUS;
//TODO : fusion functions
      fprintf (f, "\\glyph{\\char %d}{%c}{%c}{%d}%%\n", glyph_number,
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
    case G_PUNCTUM:
      switch (glyph->liquescentia)
	{
	case L_AUCTUS_ASCENDENS:
	  glyph->first_note->shape = S_PUNCTUM_AUCTUS_ASCENDENS;
	  break;
	case L_AUCTUS_DESCENDENS:
	case L_AUCTA:
	  glyph->first_note->shape = S_PUNCTUM_AUCTUS_DESCENDENS;
	  break;
	case L_DEMINUTUS:
	case L_INITIO_DEBILIS:
	  glyph->first_note->shape = S_PUNCTUM_DEMINUTUS;
	default:
	  break;
	}
    case G_PUNCTUM_INCLINATUM:
    case G_VIRGA:
    case G_STROPHA:
    case G_STROPHA_AUCTA:
      libgregorio_gregoriotex_write_note (f, glyph->first_note,
					  next_note_pitch);
      libgregorio_gregoriotex_write_signs (f, T_ONE_NOTE, glyph,
					   current_note);
      break;
    default:
      // special case of the torculus resupinus which first note is not a punctum
      if (glyph->glyph_type == G_TORCULUS_RESUPINUS
	  && current_note->shape != S_PUNCTUM)
	{
	  libgregorio_gregoriotex_write_note (f, current_note,
					      next_note_pitch);
	  libgregorio_gregoriotex_write_signs (f, T_ONE_NOTE, glyph,
					       glyph->first_note);
	  // tricky to have the good position for these glyphs
	  glyph->first_note = current_note->next_note;
	  glyph->glyph_type = G_PORRECTUS_NO_BAR;
	  libgregorio_gregoriotex_determine_number_and_type (glyph, &type,
							     &gtype,
							     &glyph_number);
	  libgregorio_gregoriotex_write_signs (f, gtype, glyph,
					       glyph->first_note);
	  glyph->glyph_type = G_TORCULUS_RESUPINUS;
//TODO : fusion functions
	  fprintf (f, "\\glyph{\\char %d}{%c}{%c}{%d}%%\n", glyph_number,
		   glyph->first_note->pitch, next_note_pitch, type);
	  glyph->first_note = current_note;
	}
      else
	{
	  libgregorio_gregoriotex_determine_number_and_type (glyph, &type,
							     &gtype,
							     &glyph_number);
	  fprintf (f, "\\glyph{\\char %d}{%c}{%c}{%d}%%\n", glyph_number,
		   glyph->first_note->pitch, next_note_pitch, type);
	  libgregorio_gregoriotex_write_signs (f, gtype, glyph,
					       glyph->first_note);
	  break;
	}
    }
}

/*

A function that write the signs of a glyph, which has the type type (T_*, not G_*, which is in the glyph->glyph_type), and (important), we start only at the note current_note. It is due to the way we call it : if type is T_ONE_NOTE, we just do the signs on current_note, not all. This is the case for example for the first note of the torculus resupinus, or the G_*_PUNCTA_INCLINATA.

*/

// a macro checking if an additional line is needed and, if it is the case,
// calling the additional line function. It must be called after the vepisemus
// but before the punctum mora

#define additional_line()\
    	      if (current_note->pitch < 'c')\
	{\
	  libgregorio_gregoriotex_write_additional_line (f, glyph, i, type,\
							 TT_BOTTOM,\
							 current_note);\
	}\
      if (current_note->pitch > 'k')\
	{\
	  libgregorio_gregoriotex_write_additional_line (f, glyph, i, type,\
							 TT_TOP,\
							 current_note);\
	}

void
libgregorio_gregoriotex_write_signs (FILE * f, char type,
				     gregorio_glyph * glyph,
				     gregorio_note * current_note)
{
  // i is the number of the note for which we are typesetting the sign.
  int i = 1;
  // a dumb char
  char block_hepisemus = 0;
  while (current_note)
    {
      // we start by the hepisemus
      if (current_note->h_episemus_type != H_NO_EPISEMUS
	  && current_note->h_episemus_top_note != 'm' && block_hepisemus == 0)
	{
// if it is a porrectus or a porrectus flexus, we check if the episemus is on the two first notes:
	  if ((type == T_PORRECTUS || type == T_PORRECTUSFLEXUS
	       || type == T_PORRECTUSFLEXUS_NOBAR
	       || type == T_PORRECTUS_NOBAR) && current_note->next_note
	      && current_note->next_note->h_episemus_type != H_NO_EPISEMUS
	      && i == 1)
	    {
	      libgregorio_gregoriotex_write_hepisemus (f, glyph,
						       HEPISEMUS_FIRST_TWO,
						       type, current_note);
	      block_hepisemus = 1;
	    }
	  else
	    {
	      if (type == T_TORCULUS_RESUPINUS && current_note->next_note
		  && current_note->next_note->h_episemus_type != H_NO_EPISEMUS
		  && i == 2)
		{
		  libgregorio_gregoriotex_write_hepisemus (f, glyph,
							   HEPISEMUS_FIRST_TWO,
							   type,
							   current_note);
		  block_hepisemus = 1;
		}
	      else
		{
		  libgregorio_gregoriotex_write_hepisemus (f, glyph, i, type,
							   current_note);
		}
	    }
	}
      switch (current_note->signs)
	{
	case _PUNCTUM_MORA:
	  additional_line ();
	  libgregorio_gregoriotex_write_punctum_mora (f, glyph, current_note);
	  break;
	case _AUCTUM_DUPLEX:
	  additional_line ();
	  libgregorio_gregoriotex_write_auctum_duplex (f, glyph,
						       current_note);

	  break;
	case _V_EPISEMUS:
	  libgregorio_gregoriotex_write_vepisemus (f, glyph, i, type,
						   current_note);
	  additional_line ();
	  break;
	case _V_EPISEMUS_PUNCTUM_MORA:
	  libgregorio_gregoriotex_write_vepisemus (f, glyph, i, type,
						   current_note);
	  additional_line ();
	  libgregorio_gregoriotex_write_punctum_mora (f, glyph, current_note);
	  break;
	case _V_EPISEMUS_AUCTUM_DUPLEX:
	  libgregorio_gregoriotex_write_vepisemus (f, glyph, i, type,
						   current_note);
	  additional_line ();
	  libgregorio_gregoriotex_write_auctum_duplex (f, glyph,
						       current_note);
	  break;
	default:
	  additional_line ();
	  break;
	}
      if (current_note->rare_sign)
	{
	  libgregorio_gregoriotex_write_rare (f, glyph, i, type,
					      current_note,
					      current_note->rare_sign);
	}
      else
	{
	  if (block_hepisemus == 1)
	    {
	      block_hepisemus = 0;
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


void
libgregorio_gregoriotex_write_auctum_duplex (FILE * f,
					     gregorio_glyph * glyph,
					     gregorio_note * current_note)
{
// we suppose we are on the last note... I don't really understand what it would mean otherwise...
// the algorith is the following : if there is a previous note, we consider that the two puncta of the augumentum duplex must correspond to the last note and the previous note, if there is no such thing, we just typeset two puncta spaced of 2.
  char pitch = current_note->pitch;
  char previous_pitch = 0;
// second_pitch is the second argument of the \augmentumduplex macro, that's what this function is all about.
  char second_pitch = 0;

  if (current_note->previous_note)
    {
      previous_pitch = current_note->previous_note->pitch;
    }

  // the behaviour (try to make some examples to understand) is to draw a puctum for each note, but they must be separated of at least two
  if (previous_pitch && previous_pitch < pitch)
    {
      if (pitch - previous_pitch > 1 || is_on_a_line (pitch))
	{
	  second_pitch = previous_pitch;
	}
      else
	{
	  second_pitch = previous_pitch - 1;	// for the fg.. to look differently, try pitch + 1 instead
	}
    }

  if (previous_pitch && previous_pitch > pitch)
    {
      if (previous_pitch - pitch > 1 || is_between_lines (pitch))
	{
	  second_pitch = previous_pitch;
	}
      else
	{
	  second_pitch = pitch - 1;	// for the gf.. to look differently, try previous_pitch + 1 instead
	}
    }

  if (!previous_pitch || previous_pitch == pitch)
    {
      if (is_on_a_line (pitch))
	{
	  second_pitch = pitch - 1;
	}
      else
	{
	  second_pitch = pitch + 1;
	}
    }

  fprintf (f, "\\augmentumduplex{%c}{%c}%%\n", pitch, second_pitch);

}


void
libgregorio_gregoriotex_write_punctum_mora (FILE * f,
					    gregorio_glyph * glyph,
					    gregorio_note * current_note)
{
// there is a case in which we do something special : if the next glyph is a ZERO_WIDTH_SPACE, and the current glyph is a PES, and the punctum mora is on the first note, and the glyph after is a pes and the first note of the next pes is at least two (or three depending on something) pitchs higher than the current note. You'll all have understood, this case is quite rare... but when it appears, we pass 1 as a second argument of \punctummora so that it removes the space introduced by the punctummora.
  if (glyph->glyph_type == G_PODATUS && glyph->next_glyph
      && glyph->next_glyph->type == GRE_SPACE
      && glyph->next_glyph->glyph_type == SP_ZERO_WIDTH
      && current_note->next_note && glyph->next_glyph->next_glyph
      && glyph->next_glyph->next_glyph->type == GRE_GLYPH
      && glyph->next_glyph->next_glyph->glyph_type == G_PODATUS
      && glyph->next_glyph->next_glyph->first_note
      && (glyph->next_glyph->next_glyph->first_note->pitch -
	  current_note->pitch > 1))
    {
      fprintf (f, "\\punctummora{%c}{1}%%\n", current_note->pitch);
    }
  else
    {
      fprintf (f, "\\punctummora{%c}{0}%%\n", current_note->pitch);
    }
}

// a function that writes the good \hepisemus un GregorioTeX. i is the position of the note in the glyph.

void
libgregorio_gregoriotex_write_hepisemus (FILE * f,
					 gregorio_glyph *
					 current_glyph,
					 int i, char type,
					 gregorio_note * current_note)
{

  char height = 0;
  char number = 0;
  char ambitus = 0;
  char bottom = 0;

  if (!current_note || current_note->h_episemus_type == H_NO_EPISEMUS)
    {
      return;
    }
  libgregorio_gregoriotex_find_sign_number (current_glyph, i,
					    type, TT_H_EPISEMUS, current_note,
					    &number, &height, &bottom);

  if (i == HEPISEMUS_FIRST_TWO)
    {
      ambitus = current_note->pitch - current_note->next_note->pitch;
    }
  if (bottom == 1)
    {
      fprintf (f, "\\hepisemusbottom{%c}{%d}{%d}%%\n", height, number,
	       ambitus);
    }
  else
    {
      fprintf (f, "\\hepisemus{%c}{%d}{%d}%%\n", height, number, ambitus);
    }
}

// a macro to write an additional line bottom_or_top is bottom, or top...

void
libgregorio_gregoriotex_write_additional_line (FILE * f,
					       gregorio_glyph *
					       current_glyph,
					       int i, char type,
					       char bottom_or_top,
					       gregorio_note * current_note)
{

  char height = 0;
  char number = 0;
  char ambitus = 0;

  if (!current_note)
    {
      return;
    }
  libgregorio_gregoriotex_find_sign_number (current_glyph, i,
					    type, TT_H_EPISEMUS, current_note,
					    &number, &height, NULL);

  if (i == HEPISEMUS_FIRST_TWO)
    {
      ambitus = current_note->pitch - current_note->next_note->pitch;
    }
  fprintf (f, "\\additionalline{%d}{%d}{%d}%%\n", number, ambitus,
	   bottom_or_top);
}


/*

a function that writes the good value of \vepisemus in GregorioTeX. i is the position of the note in the glyph

*/


void
libgregorio_gregoriotex_write_vepisemus (FILE * f,
					 gregorio_glyph *
					 current_glyph,
					 int i, char type,
					 gregorio_note * current_note)
{

  char height = 0;
  char number = 0;

  if (current_note->pitch == 'a')
    {
      return;
    }

  libgregorio_gregoriotex_find_sign_number (current_glyph, i,
					    type, TT_V_EPISEMUS, current_note,
					    &number, &height, NULL);
  fprintf (f, "\\vepisemus{%c}{%d}%%\n", height, number);
}


/*
a function that writes the rare signs in GregorioTeX. i is the position of the note in the glyph
*/

void
libgregorio_gregoriotex_write_rare (FILE * f,
				    gregorio_glyph *
				    current_glyph,
				    int i, char type,
				    gregorio_note * current_note, char rare)
{

  char height = 0;
  char number = 0;

  libgregorio_gregoriotex_find_sign_number (current_glyph, i,
					    type, TT_RARE, current_note,
					    &number, &height, NULL);

  switch (rare)
    {
    case _ACCENTUS:
      fprintf (f, "\\accentus{%d}%%\n", number);
      break;
    case _ACCENTUS_REVERSUS:
      fprintf (f, "\\reversedaccentus{%d}%%\n", number);
      break;
    case _CIRCULUS:
      fprintf (f, "\\circulus{%d}%%\n", number);
      break;
    case _SEMI_CIRCULUS:
      fprintf (f, "\\semicirculus{%d}%%\n", number);
      break;
    case _SEMI_CIRCULUS_REVERSUS:
      fprintf (f, "\\reversedsemicirculus{%d}%%\n", number);
      break;
    default:
      break;
    }
}

#define number_note_before_last_note() \
  if ((current_glyph->liquescentia == L_DEMINUTUS_INITIO_DEBILIS || current_glyph->liquescentia == L_DEMINUTUS) && current_note->next_note)\
    {\
      *number = 3;\
    }\
  else \
      {\
      if ((current_note->pitch - current_note->next_note->pitch) == 1 || (current_note->pitch - current_note->next_note->pitch) == -1)\
    {\
      *number = 17;\
    }\
    else \
    {\
      *number = 2;\
    }\
    }

// num can be 0 or 18 according if the last note is a standard punctum or a smaller punctum (for pes, porrectus and torculus resupinus
#define number_last_note(num) \
  if (current_glyph->liquescentia == L_DEMINUTUS_INITIO_DEBILIS || current_glyph->liquescentia == L_DEMINUTUS)\
    {\
      /* may seem strange, but it is unlogical to typeset a small horizontal episemus at the end of a flexus deminutus */\
      *number = 1;\
    }\
  else \
    {\
      *number = num;\
    }

#define normal_height() \
  if (sign_type == TT_H_EPISEMUS) {\
  *height=current_note->h_episemus_top_note+1;\
  }\
  else {\
  *height=current_note->pitch -1;\
  }

//same as before, but for one note and then another one higher, when the sign is on the last
#define normal_height_top()\
  if (sign_type == TT_H_EPISEMUS) {\
  *height=current_note->h_episemus_top_note+1;\
  }\
  else {\
  *height=current_note->pitch +2;\
  }

// case of one note and then one lower, when the sign is on the first
#define height_layered_notes()\
  if (sign_type == TT_H_EPISEMUS)\
    {\
      *height=current_note->h_episemus_top_note+1;\
    }\
  else\
    {\
      if ((current_note->pitch - current_note->next_note->pitch) == 1 || (current_note->pitch - current_note->next_note->pitch) == -1)\
      {\
        *height=current_note->pitch + 2;\
      }\
      else\
      {\
        *height=current_note->pitch -1;\
      }\
    }

// case of one note and then one higher, on the same vertical axis,
// when the sign is on the first
#define normal_height_bottom()\
  if (sign_type == TT_H_EPISEMUS) \
    {\
  /* we check if the previous or the next note has an horizontal episemus\
  // if it is the case, we use this height. If not, we put the episemus under the note*/\
      if ((!current_note->previous_note || !current_note->previous_note -> h_episemus_type)\
          && (!current_note->next_note || !current_note->next_note->h_episemus_type))\
        {\
          *height=current_note->pitch - 1;\
           if (bottom){\
             *bottom=1;\
           }\
        }\
      else \
        {\
          *height=current_note->h_episemus_top_note+1;\
        }\
    }\
  else\
    {\
      *height=current_note->pitch -1;\
    }

// a function that finds the good sign (additional line, vepisemus or hepisemus) number, according to the gregoriotex convention (described in gregoriotex.tex)
// this function is REALLY a pain in the ass, but it is sadly necessary
void
libgregorio_gregoriotex_find_sign_number (gregorio_glyph * current_glyph,
					  int i, char type, char sign_type,
					  gregorio_note * current_note,
					  char *number, char *height,
					  char *bottom)
{
  switch (type)
    {
    case T_PES:
    case T_PESQUILISMA:
/* in the case of a pes, we put the episemus just under the bottom note */
      if (i == 1)
	{
	  if (current_glyph->liquescentia >= L_INITIO_DEBILIS)
	    {
	      *number = 1;
	    }
	  else
	    {
	      if (current_note->shape == S_QUILISMA)
		{
		  *number = 15;
		}
	      else
		{
		  *number = 0;
		}
	    }
	  normal_height_bottom ();
	}
      else
	{			/* i=2 */
	  if (current_glyph->liquescentia == L_DEMINUTUS_INITIO_DEBILIS
	      || current_glyph->liquescentia == L_DEMINUTUS)
	    {
	      *number = 1;
	    }
	  else
	    {
	      *number = 18;
	    }
	  normal_height_top ();
	}
      break;
    case T_PESQUADRATUM:
    case T_PESQUASSUS:
    case T_PESQUILISMAQUADRATUM:
      if (i == 1)
	{
	  if (current_glyph->liquescentia >= L_INITIO_DEBILIS)
	    {
	      *number = 7;
	    }
	  else
	    {
	      if (current_note->shape == S_ORISCUS)
		{
		  *number = 19;
		}
	      if (current_note->shape == S_QUILISMA)
		{
		  *number = 20;
		}
	      else
		{
		  *number = 6;
		}
	    }
	}
      else
	{			/* i=2 */
	  if (current_glyph->liquescentia == L_DEMINUTUS_INITIO_DEBILIS
	      || current_glyph->liquescentia == L_DEMINUTUS)
	    {
	      *number = 7;
	    }
	  else
	    {
	      *number = 0;
	    }
	}
      normal_height ();
      break;
    case T_FLEXUS:
    case T_FLEXUS_LONGQUEUE:
      switch (i)
	{
	case 1:
	  number_note_before_last_note ();
	  if (current_glyph->liquescentia == L_DEMINUTUS_INITIO_DEBILIS
	      || current_glyph->liquescentia == L_DEMINUTUS)
	    {
	      height_layered_notes ();
	    }
	  else
	    {
	      normal_height ();
	    }
	  break;
	default:		/* i=2 */
	  number_last_note (0);
	  normal_height ();
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
	      *number = 0;
	    }
	  *number = 10;
	  break;
	case 1:
	  *number = 6;
	  normal_height ();
	  break;
	case 2:
	  if (current_glyph->liquescentia == L_DEMINUTUS_INITIO_DEBILIS
	      || current_glyph->liquescentia == L_DEMINUTUS)
	    {
	      *number = 5;
	    }
	  else
	    {
	      *number = 4;
	    }
	  normal_height_bottom ();
	  break;
	case 3:
	  if (current_note->pitch - current_note->next_note->pitch != 1)
	    {
	      number_note_before_last_note ();
	    }
	  if ((current_glyph->liquescentia == L_DEMINUTUS_INITIO_DEBILIS
	       || current_glyph->liquescentia == L_DEMINUTUS)
	      && current_note->next_note)
	    {
	      *number = 3;
	    }
	  else
	    {
	      *number = 2;
	    }
	  if (current_glyph->liquescentia == L_DEMINUTUS_INITIO_DEBILIS
	      || current_glyph->liquescentia == L_DEMINUTUS)
	    {
	      height_layered_notes ();
	    }
	  else
	    {
	      normal_height ();
	    }
	  break;
	default:
	  number_last_note (0);
	  normal_height ();
	  break;
	}
      break;
    case T_TORCULUS_RESUPINUS:
      switch (i)
	{
	case HEPISEMUS_FIRST_TWO:
	  // special case, called when the horizontal episemus is on the fist two notes of a glyph. We consider current_note to be the second note. in the case of the toruculus resupinus, it are the notes two and three. Warning, this MUST NOT be called if the porrectus is deminutus.
	  if (!current_note->next_note)
	    {
	      return;
	    }
	  *number = 11;
	  normal_height ();
	  break;
	case 1:
	  if (current_glyph->liquescentia >= L_INITIO_DEBILIS)
	    {
	      *number = 7;
	    }
	  else
	    {
	      *number = 6;
	    }
	  normal_height ();
	  break;
	case 2:
	  if (current_glyph->liquescentia >= L_INITIO_DEBILIS)
	    {
	      *number = 23;
	    }
	  else
	    {
	      if (current_note->pitch - current_note->previous_note->pitch ==
		  1)
		{
		  *number = 21;
		}
	      else
		{
		  *number = 22;
		}
	    }
	  normal_height ();
	case 3:
	  number_note_before_last_note ();
	  if (current_glyph->liquescentia == L_DEMINUTUS_INITIO_DEBILIS
	      || current_glyph->liquescentia == L_DEMINUTUS)
	    {
	      height_layered_notes ();
	    }
	  else
	    {
	      normal_height_bottom ();
	    }
	  break;
	default:
	  number_last_note (18);
	  normal_height ();
	  break;
	}
      break;
    case T_PORRECTUS:
    case T_PORRECTUS_NOBAR:
      switch (i)
	{
	case HEPISEMUS_FIRST_TWO:
	  // special case, called when the horizontal episemus is on the fist two notes of a glyph. We consider current_note to be the first note. Warning, this MUST NOT be called if the porrectus is deminutus.
	  if (!current_note->next_note)
	    {
	      *number = 0;
	    }
	  *number = 9;
	  normal_height ()break;
	case 1:
	  *number = 6;
	  normal_height ();
	  break;
	case 2:
	  if ((current_glyph->liquescentia ==
	       L_DEMINUTUS_INITIO_DEBILIS
	       || current_glyph->liquescentia == L_DEMINUTUS)
	      && current_note->next_note)
	    {
	      *number = 3;
	    }
	  else
	    {
	      *number = 0;
	    }
	  normal_height_bottom ();
	  break;
	default:
	  number_last_note (1);
	  normal_height_top ();
	  break;
	}
      break;
    case T_SCANDICUS:
      switch (i)
	{
	case 1:
	  if (current_glyph->liquescentia >= L_INITIO_DEBILIS)
	    {
	      *number = 7;
	    }
	  else
	    {
		  *number = 6;
	    }
	  normal_height ();
	  break;
	case 2:
	  number_note_before_last_note ();
      normal_height ();
	  break;
	default:
	  number_last_note (0);
	  normal_height_top ();
	  break;
	}
	break;
	case T_ANCUS:
	case T_ANCUS_LONGQUEUE:
      switch (i)
	{
	case 1:
	  *number = 6;
	  normal_height ();
	  break;
	case 2:
	  number_note_before_last_note ();
      height_layered_notes ();
	  break;
	default:
	  number_last_note (0);
	  normal_height ();
	  break;
	}
	break;
    case T_TORCULUS:
    case T_TORCULUS_QUILISMA:
      switch (i)
	{
	case 1:
	  if (current_glyph->liquescentia >= L_INITIO_DEBILIS)
	    {
	      *number = 7;
	    }
	  else
	    {
	      if (type == T_TORCULUS_QUILISMA)
		{
		  *number = 20;
		}
	      else
		{
		  *number = 6;
		}
	    }
	  normal_height ();
	  break;
	case 2:
	  number_note_before_last_note ();
	  if (current_glyph->liquescentia == L_DEMINUTUS_INITIO_DEBILIS
	      || current_glyph->liquescentia == L_DEMINUTUS)
	    {
	      height_layered_notes ();
	    }
	  else
	    {
	      normal_height ();
	    }
	  break;
	default:
	  number_last_note (0);
	  normal_height ();
	  break;
	}
      break;
    default:			/* case T_ONE_NOTE */
      normal_height ();
      switch (current_note->shape)
	{
	case S_PUNCTUM_INCLINATUM_DEMINUTUS:
	  *number = 13;
	  break;
	case S_PUNCTUM_INCLINATUM_AUCTUS:
	case S_PUNCTUM_INCLINATUM:
	  *number = 12;
	  break;
	case S_STROPHA:
	  *number = 14;
	  break;
	case S_QUILISMA:
	  *number = 15;
	  break;
	case S_ORISCUS:
	  *number = 16;
	  break;
	default:
	  number_last_note (0);
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

to obtain the glyph number, we just do 512 * glyphtype + liq_factor * liquescentia + x

where liq_factor is 64 for short types (pes and flexus) and 256 for long types

where x is a number related to the differences between te heights of the notes:

if i is the difference between the two first notes, j between the second and the third and k the difference betweend the third and the fourth, x = i + 5 * j + 25 * k

*/

unsigned int
gregoriotex_determine_liquescentia_number (unsigned int
					   factor,
					   unsigned char
					   type, char liquescentia)
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

  //now we convert liquescentia into the good GregorioTeX liquescentia numbers

  switch (liquescentia)
    {
    case L_NO_LIQUESCENTIA:
      liquescentia = GL_NO_LIQUESCENTIA;
      break;
    case L_DEMINUTUS:
      liquescentia = GL_DEMINUTUS;
      break;
    case L_AUCTUS_ASCENDENS:
      liquescentia = GL_AUCTUS_ASCENDENS;
      break;
    case L_AUCTA:
    case L_AUCTUS_DESCENDENS:
      liquescentia = GL_AUCTUS_DESCENDENS;
      break;
    case L_INITIO_DEBILIS:
      liquescentia = GL_INITIO_DEBILIS;
      break;
    case L_DEMINUTUS_INITIO_DEBILIS:
      liquescentia = GL_DEMINUTUS_INITIO_DEBILIS;
      break;
    case L_AUCTUS_ASCENDENS_INITIO_DEBILIS:
      liquescentia = GL_AUCTUS_ASCENDENS_INITIO_DEBILIS;
      break;
    case L_AUCTA_INITIO_DEBILIS:
    case L_AUCTUS_DESCENDENS_INITIO_DEBILIS:
      liquescentia = GL_AUCTUS_DESCENDENS_INITIO_DEBILIS;
      break;
    default:
      liquescentia = GL_NO_LIQUESCENTIA;
      break;
    }

  return factor * liquescentia;
}

// finaly the function that calculates the number of the glyph. It also calculates the type, used for determining the position of signs. Type is very basic, it is only the global dimensions : torculus, one_note, etc.

void
  libgregorio_gregoriotex_determine_number_and_type
  (gregorio_glyph * glyph, int *type, char *gtype, unsigned int *glyph_number)
{
  unsigned int temp = 0;
  char pitch = 0;
  char liquescentia;
  if (!glyph)
    {
      gregorio_message (_
			("called with NULL pointer"),
			"libgregorio_gregoriotex_determine_number_and_type",
			ERROR, 0);
      return;
    }
  if (!glyph->first_note)
    {
      gregorio_message (_
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
      pitch = glyph->first_note->next_note->pitch;
      switch (glyph->first_note->shape)
	{
	case S_QUILISMA:
	  *type = AT_QUILISMA;
	  *gtype = T_PESQUILISMA;
	  temp =
	    TYPE_FACTOR * T_PESQUILISMA +
	    gregoriotex_determine_liquescentia_number (S_LIQ_FACTOR,
						       L_NO_INITIO,
						       glyph->liquescentia);
	  break;
	case S_ORISCUS:
	  *type = AT_ORISCUS;
	  // TODO: we could factorize this code
	  if (glyph->liquescentia == L_NO_LIQUESCENTIA && is_long (pitch))
	    {
	      *gtype = T_PESQUASSUS_LONGQUEUE;
	    }
	  else
	    {
	      *gtype = T_PESQUASSUS;
	    }
	  temp =
	    TYPE_FACTOR * (*gtype) +
	    gregoriotex_determine_liquescentia_number (S_LIQ_FACTOR,
						       L_NO_INITIO,
						       glyph->liquescentia);
	  break;
	default:
	  *type = AT_ONE_NOTE;
	  *gtype = T_PES;
	  temp =
	    TYPE_FACTOR * T_PES +
	    gregoriotex_determine_liquescentia_number (S_LIQ_FACTOR,
						       L_ALL,
						       glyph->liquescentia);
	  break;
	}
      break;
    case G_PES_QUADRATUM:
      pitch = glyph->first_note->next_note->pitch;
      switch (glyph->first_note->shape)
	{
	case S_QUILISMA:
	  *type = AT_QUILISMA;
	  if (glyph->liquescentia == L_NO_LIQUESCENTIA && is_long (pitch))
	    {
	      *gtype = T_PESQUILISMAQUADRATUM_LONGQUEUE;
	    }
	  else
	    {
	      *gtype = T_PESQUILISMAQUADRATUM;
	    }
	  temp =
	    TYPE_FACTOR * (*gtype) +
	    gregoriotex_determine_liquescentia_number (S_LIQ_FACTOR,
						       L_NO_INITIO,
						       glyph->liquescentia);
	  break;
	case S_ORISCUS:
	  *type = AT_ORISCUS;
	  if (glyph->liquescentia == L_NO_LIQUESCENTIA && is_long (pitch))
	    {
	      *gtype = T_PESQUASSUS_LONGQUEUE;
	    }
	  else
	    {
	      *gtype = T_PESQUASSUS;
	    }
	  temp =
	    TYPE_FACTOR * (*gtype) +
	    gregoriotex_determine_liquescentia_number (S_LIQ_FACTOR,
						       L_NO_INITIO,
						       glyph->liquescentia);
	  break;
	default:
	  *type = AT_ONE_NOTE;
	  if (glyph->liquescentia == L_NO_LIQUESCENTIA && is_long (pitch))
	    {
	      *gtype = T_PESQUADRATUM_LONGQUEUE;
	    }
	  else
	    {
	      *gtype = T_PESQUADRATUM;
	    }
	  temp =
	    TYPE_FACTOR * (*gtype) +
	    gregoriotex_determine_liquescentia_number (S_LIQ_FACTOR,
						       L_ALL,
						       glyph->liquescentia);
	  break;
	}
      break;
    case G_FLEXA:
      pitch = glyph->first_note->pitch;
      if (glyph->liquescentia == L_DEMINUTUS)
	{
	  *type = AT_FLEXUS_DEMINUTUS;
	}
      else
	{
	  if (pitch - glyph->first_note->next_note->pitch == 1)
	    {
	      *type = AT_FLEXUS_1;
	    }
	  else
	    {
	      *type = AT_FLEXUS;
	    }
	}
      if (is_short (pitch))
	{
	  *gtype = T_FLEXUS;
	  temp =
	    TYPE_FACTOR * T_FLEXUS +
	    gregoriotex_determine_liquescentia_number (S_LIQ_FACTOR,
						       L_NO_INITIO,
						       glyph->liquescentia);
	}
      else
	{
	  *gtype = T_FLEXUS_LONGQUEUE;
	  temp =
	    TYPE_FACTOR * T_FLEXUS_LONGQUEUE +
	    gregoriotex_determine_liquescentia_number (S_LIQ_FACTOR,
						       L_NO_INITIO,
						       glyph->liquescentia);
	}
      break;
    case G_TORCULUS:
      if (glyph->first_note->shape == S_QUILISMA)
	{
	  *type = AT_QUILISMA;
	  *gtype = T_TORCULUS_QUILISMA;
	  temp =
	    TYPE_FACTOR * T_TORCULUS_QUILISMA +
	    gregoriotex_determine_liquescentia_number (L_LIQ_FACTOR,
						       L_NO_INITIO,
						       glyph->liquescentia);
	}
      else
	{
	  *type = AT_ONE_NOTE;
	  *gtype = T_TORCULUS;
	  temp =
	    TYPE_FACTOR * T_TORCULUS +
	    gregoriotex_determine_liquescentia_number (L_LIQ_FACTOR, L_ALL,
						       glyph->liquescentia);
	}
      break;
    case G_PORRECTUS:
      *type = AT_PORRECTUS;
      *gtype = T_PORRECTUS;
      temp =
	TYPE_FACTOR * T_PORRECTUS +
	gregoriotex_determine_liquescentia_number (L_LIQ_FACTOR,
						   L_ONLY_DEMINUTUS,
						   glyph->liquescentia);
      break;
    case G_TORCULUS_RESUPINUS:
      *type = AT_ONE_NOTE;
      *gtype = T_TORCULUS_RESUPINUS;
      temp =
	TYPE_FACTOR * T_TORCULUS_RESUPINUS +
	gregoriotex_determine_liquescentia_number (L_LIQ_FACTOR,
						   L_ONLY_DEMINUTUS,
						   glyph->liquescentia);
      break;
    case G_PORRECTUS_FLEXUS:
      *type = AT_PORRECTUS;
      *gtype = T_PORRECTUSFLEXUS;
      temp =
	TYPE_FACTOR * T_PORRECTUSFLEXUS +
	gregoriotex_determine_liquescentia_number (L_LIQ_FACTOR,
						   L_NO_INITIO,
						   glyph->liquescentia);
      break;
    case G_PORRECTUS_NO_BAR:
      *type = AT_PORRECTUS;
      *gtype = T_PORRECTUS_NOBAR;
      temp =
	TYPE_FACTOR * T_PORRECTUS_NOBAR +
	gregoriotex_determine_liquescentia_number (L_LIQ_FACTOR,
						   L_ONLY_DEMINUTUS,
						   glyph->liquescentia);
      break;
    case G_PORRECTUS_FLEXUS_NO_BAR:
      *type = AT_PORRECTUS;
      *gtype = T_PORRECTUSFLEXUS_NOBAR;
      temp =
	TYPE_FACTOR * T_PORRECTUSFLEXUS_NOBAR +
	gregoriotex_determine_liquescentia_number (L_LIQ_FACTOR,
						   L_NO_INITIO,
						   glyph->liquescentia);
      break;
    case G_ANCUS:
      if (glyph->liquescentia == L_DEMINUTUS
	  || glyph->liquescentia == L_DEMINUTUS_INITIO_DEBILIS)
	{
		  if (pitch - glyph->first_note->next_note->pitch == 1)
	    {
	      *type = AT_FLEXUS_1;
	    }
	  else
	    {
	      *type = AT_FLEXUS;
	    }
	  if (is_short (pitch))
	    {
	      *gtype = T_ANCUS;
	      temp = TYPE_FACTOR * T_ANCUS + 
	           gregoriotex_determine_liquescentia_number (L_LIQ_FACTOR,
						   L_ONLY_DEMINUTUS,
						   glyph->liquescentia);
	    }
	  else
	    {
	      *gtype = T_ANCUS_LONGQUEUE;
	      temp = TYPE_FACTOR * T_ANCUS_LONGQUEUE + 
	           gregoriotex_determine_liquescentia_number (L_LIQ_FACTOR,
						   L_ONLY_DEMINUTUS,
						   glyph->liquescentia);
	    }
	}
      else
	{
	  //TODO...
	  *type = AT_ONE_NOTE;
	}
      break;
    case G_SCANDICUS:
      if (glyph->liquescentia == L_DEMINUTUS
	  || glyph->liquescentia == L_DEMINUTUS_INITIO_DEBILIS)
	{
	  *type = AT_ONE_NOTE;
	  *gtype = T_SCANDICUS;
	  temp = TYPE_FACTOR * T_SCANDICUS + 	  
	           gregoriotex_determine_liquescentia_number (L_LIQ_FACTOR,
						   L_ONLY_DEMINUTUS,
						   glyph->liquescentia);;
	}
      else
	{
	  // TODO: do it really...
	  *type = AT_ONE_NOTE;
	}
      break;
    default:
      gregorio_message (_
			("called with unknown glyph"),
			"libgregorio_gregoriotex_determine_number_and_type",
			ERROR, 0);
      break;
    }

  *glyph_number = libgregorio_gregoriotex_determine_interval (glyph);
  *glyph_number = temp + (*glyph_number);
  // we change to the original liquescentia
  glyph->liquescentia = liquescentia;
  // we fix *type with initio_debilis
  if (*type == AT_ONE_NOTE)
    {
      if (is_initio_debilis (liquescentia))
	{
	  *type = AT_INITIO_DEBILIS;
	}
    }

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
      gregorio_message (_
			("called with NULL pointer"),
			"libgregorio_gregoriotex_determine_interval",
			ERROR, 0);
      return 0;
    }
  if (!glyph->first_note)
    {
      gregorio_message (_
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
* 03: c clef for key changes
* 04: f clef for key changes
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
* 69: reversed accentus
* 70: reversed semi-circulus
* 72: punctum auctus ascendens
* 73: punctum auctus descendens
* 74: smaller punctum for pes, porrectus and torculus resupinus (theorically never used alone, but necessary for some measures

* 60: custo for bass notes (oriented to the top)
* 61: custo for bass notes (oriented to the top) with short bar
* 62: custo for bass notes (oriented to the top) with middle bar (for the lowest note)
* 63: custo for high notes (oriented to the bottom)
* 64: custo for high notes (oriented to the bottom) with short bar
* 65: custo for high notes (oriented to the bottom) with middle bar (for the highest note)

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
// * 58: horizontal episemus width of a small punctum for pes, porrectus and torculus resupinus
#define H_SMALL_PUNCTUM 58

void
libgregorio_gregoriotex_write_note (FILE * f,
				    gregorio_note * note,
				    char next_note_pitch)
{
  unsigned int glyph_number;
  char temp;
  // type in the sense of GregorioTeX alignment type
  int type = AT_ONE_NOTE;
  if (!note)
    {
      gregorio_message (_
			("called with NULL pointer"),
			"libgregorio_gregoriotex_write_note", ERROR, 0);
      return;
    }

  libgregorio_gregoriotex_determine_note_number_and_type
    (note, &type, &glyph_number);
// special things for puncta inclinata
  if (note->shape == S_PUNCTUM_INCLINATUM)
    {
      if (note->previous_note)
	{
//means that it is the first note of the puncta inclinata sequence
	  temp = note->previous_note->pitch - note->pitch;
	  if (temp < -1 || temp > 1)
	    {
	      fprintf (f, "\\endofglyph{1}%%\n");
	    }
	  else
	    {
	      fprintf (f, "\\endofglyph{3}%%\n");
	    }
	}
    }
  if (note->shape == S_PUNCTUM_INCLINATUM_DEMINUTUS)
    {
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
	      if (note->previous_note
		  && note->previous_note->shape ==
		  S_PUNCTUM_INCLINATUM_DEMINUTUS)
		{
		  fprintf (f, "\\endofglyph{8}%%\n");
		}
	      else
		{
		  fprintf (f, "\\endofglyph{7}%%\n");
		}
	    }
	}
    }
  if (note->shape == S_PUNCTUM_INCLINATUM_AUCTUS)
    {
      if (note->previous_note)
	{
//means that it is the first note of the puncta inclinata sequence
	  temp = note->previous_note->pitch - note->pitch;
	  if (temp < -1 || temp > 1)
	    {
	      fprintf (f, "\\endofglyph{1}%%\n");
	    }
	  else
	    {
	      // we approximate that it is the same space
	      fprintf (f, "\\endofglyph{3}%%\n");
	    }
	}
    }

  fprintf (f, "\\glyph{\\char %d}{%c}{%c}{%d}%%\n",
	   glyph_number, note->pitch, next_note_pitch, type);
}

void
  libgregorio_gregoriotex_determine_note_number_and_type
  (gregorio_note * note, int *type, unsigned int *glyph_number)
{
  if (!note)
    {
      gregorio_message (_
			("called with NULL pointer"),
			"libgregorio_gregoriotex_write_note", ERROR, 0);
      return;
    }

  *type = AT_ONE_NOTE;
  switch (note->shape)
    {
    case S_PUNCTUM_INCLINATUM:
      *glyph_number = 19;
      *type = AT_PUNCTUM_INCLINATUM;
      break;
    case S_PUNCTUM_INCLINATUM_DEMINUTUS:
      *glyph_number = 32;
      break;
    case S_PUNCTUM_INCLINATUM_AUCTUS:
      *glyph_number = 31;
      break;
    case S_PUNCTUM:
      *glyph_number = 17;
      break;
    case S_PUNCTUM_AUCTUS_ASCENDENS:
      *glyph_number = 72;
      break;
    case S_PUNCTUM_AUCTUS_DESCENDENS:
      *glyph_number = 73;
      break;
    case S_PUNCTUM_DEMINUTUS:
      *glyph_number = 13;
      break;
    case S_PUNCTUM_CAVUM:
      *glyph_number = 34;
      break;
    case S_LINEA_PUNCTUM:
      *glyph_number = 35;
      break;
    case S_LINEA_PUNCTUM_CAVUM:
      *glyph_number = 36;
      break;
    case S_VIRGA:
      if (is_short (note->pitch))
	{
	  *glyph_number = 23;
	}
      else
	{
	  *glyph_number = 22;
	}
      break;
    case S_ORISCUS:
      *type = AT_ORISCUS;
      *glyph_number = 27;
      break;
    case S_ORISCUS_AUCTUS:
      *type = AT_ORISCUS;
      *glyph_number = 28;
      break;
    case S_QUILISMA:
      *type = AT_QUILISMA;
      *glyph_number = 26;
      break;
    case S_STROPHA:
      *type = AT_STROPHA;
      *glyph_number = 20;
      break;
    case S_STROPHA_AUCTA:
      *type = AT_STROPHA;
      *glyph_number = 21;
      break;
    default:
      gregorio_message (_
			("called with unknown shape"),
			"libgregorio_gregoriotex_write_note", ERROR, 0);
      return;
      break;
    }

}

char
  libgregorio_gregoriotex_determine_next_note
  (gregorio_syllable * syllable, gregorio_element * element,
   gregorio_glyph * glyph)
{
  char temp;
  if (!glyph || !element || !syllable)
    {
      gregorio_message (_
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
// here it means that there is no next note, so we return a stupid value, but it won' t be used
  return 'g';
}

// the second argument says if we want to also look for a sign element or not

gregorio_glyph *
libgregorio_gregoriotex_first_glyph (gregorio_syllable * syllable)
{
  gregorio_glyph *glyph;
  gregorio_element *element;
  if (!syllable)
    {
      gregorio_message (_
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
		  return glyph;
		}
	      glyph = glyph->next_glyph;
	    }
	}
      element = element->next_element;
    }
  return NULL;
}

char
libgregorio_gregoriotex_syllable_first_note (gregorio_syllable * syllable)
{
  gregorio_glyph *glyph;
  glyph = libgregorio_gregoriotex_first_glyph (syllable);
  if (glyph == NULL)
    {
      return 0;
    }
  else
    {
      return glyph->first_note->pitch;
    }
}

// a function to determine the 7th argument of syllable

int
libgregorio_gregoriotex_syllable_first_type (gregorio_syllable * syllable)
{
  int type = 0;
  char gtype = 0;
  unsigned int number = 0;
  // alteration says if there is a flat or a natural first in the next syllable, see gregoriotex.tex for more details
  int alteration = 0;
  gregorio_glyph *glyph;
  gregorio_element *element;
  if (!syllable)
    {
      gregorio_message (_
			("called with a NULL argument"),
			"libgregorio_gregoriotex_determine_next_note",
			ERROR, 0);
    }
  element = syllable->elements[0];
  while (element)
    {
      if (element->type == GRE_BAR)
	{
	  switch (element->element_type)
	    {
	    case B_NO_BAR:
	    case B_VIRGULA:
	      type = 10;
	      break;
	    case B_DIVISIO_MINIMA:
	    case B_DIVISIO_MINOR:
	    case B_DIVISIO_MAIOR:
	      type = 11;
	      break;
	    case B_DIVISIO_FINALIS:
	      type = 12;
	      break;
	    default:
	      type = 0;
	      break;
	    }
	  return type;
	}
      if (element->type == GRE_ELEMENT && element->first_glyph)
	{
	  glyph = element->first_glyph;
	  while (glyph)
	    {
	      if (glyph->type == GRE_FLAT && alteration == 0)
		{
		  alteration = 20;
		}
	      if (glyph->type == GRE_NATURAL && alteration == 0)
		{
		  alteration = 40;
		}
	      if (glyph->type == GRE_GLYPH && glyph->first_note)
		{
		  switch (glyph->glyph_type)
		    {
		    case G_TRIGONUS:
		    case G_PUNCTA_INCLINATA:
		    case G_2_PUNCTA_INCLINATA_DESCENDENS:
		    case G_3_PUNCTA_INCLINATA_DESCENDENS:
		    case G_4_PUNCTA_INCLINATA_DESCENDENS:
		    case G_5_PUNCTA_INCLINATA_DESCENDENS:
		    case G_2_PUNCTA_INCLINATA_ASCENDENS:
		    case G_3_PUNCTA_INCLINATA_ASCENDENS:
		    case G_4_PUNCTA_INCLINATA_ASCENDENS:
		    case G_5_PUNCTA_INCLINATA_ASCENDENS:
		    case G_PUNCTUM:
		    case G_STROPHA:
		    case G_VIRGA:
		    case G_STROPHA_AUCTA:
		      libgregorio_gregoriotex_determine_note_number_and_type
			(glyph->first_note, &type, &number);
		      break;
		    default:
		      libgregorio_gregoriotex_determine_number_and_type
			(glyph, &type, &gtype, &number);
		      break;
		    }
		  return type + alteration;
		}
	      glyph = glyph->next_glyph;
	    }
	}
      element = element->next_element;
    }
  return 0;
}
