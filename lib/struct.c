/* 
Gregorio structure manipulation file.
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

/*
 * This file contains a set of function to manipulate the gregorio
 * structure. It starts by simple add/delete functions for almost all
 * structs, and ends with more complex functions for manipulating
 * horizontal episemus, keys, etc.
 *
 * The first functions are not commented, but they always act like
 * this : we give them a pointer to the pointer to the current element
 * (by element I mean a struct which can be gregorio_note,
 * gregorio_element, etc.), they add an element and the update the
 * pointer to the element so that it points to the new element (may
 * seem a bit strange).
 *
 * All the delete functions are recursive and free all memory.
 * 
*/

#include "config.h"
#include <stdio.h>
#include <wchar.h>
#include "gettext.h"
#include <stdlib.h>
#include "messages.h"
#include "struct.h"
#include "gabc/gabc.h"
#define _(str) gettext(str)
#define N_(str) str


void
libgregorio_add_note (gregorio_note ** current_note, char pitch, char shape,
		      char signs, char liquescentia, char h_episemus_type)
{

  gregorio_note *element = malloc (sizeof (gregorio_note));
  if (!element)
    {
      gregorio_message (_("error in memory allocation"),
			   "add_note", FATAL_ERROR, 0);
      return;
    }
  element->type = GRE_NOTE;
  element->pitch = pitch;
  element->shape = shape;
  element->signs = signs;
  element->rare_sign = _NO_SIGN;
  element->liquescentia = liquescentia;
  element->previous_note = *current_note;
  element->next_note = NULL;
  if (*current_note)
    {
      (*current_note)->next_note = element;
    }
  *current_note = element;
  libgregorio_mix_h_episemus (*current_note, h_episemus_type);
}


void
libgregorio_add_special_as_note (gregorio_note ** current_note, char type,
				 char pitch)
{
  gregorio_note *element = malloc (sizeof (gregorio_note));
  if (!element)
    {
      gregorio_message (_("error in memory allocation"),
			   "add_special_as_note", FATAL_ERROR, 0);
      return;
    }
  element->type = type;
  element->pitch = pitch;
  //element->shape = NULL;
  //element->signs = NULL;
  //element->liquescentia=NULL;
  element->previous_note = *current_note;
  element->next_note = NULL;
  if (*current_note)
    {
      (*current_note)->next_note = element;
    }
  *current_note = element;
}

void
libgregorio_add_special_sign (gregorio_note *note, char sign)
{
    note->rare_sign=sign;
}

void
libgregorio_change_shape (gregorio_note *note, char shape)
{
    note->shape=shape;
}

void
libgregorio_go_to_first_note (gregorio_note ** note)
{
  gregorio_note *tmp;
  if (!*note)
    {
      return;
    }
  tmp = *note;
  while (tmp->previous_note)
    {
      tmp = tmp->previous_note;
    }
  *note = tmp;
}

void
libgregorio_free_one_note (gregorio_note ** note)
{
  gregorio_note *next = NULL;
  if (!note || !*note)
    {
      return;
    }
  if ((*note)->next_note)
    {
      (*note)->next_note->previous_note = NULL;
      next = (*note)->next_note;
    }
  if ((*note)->previous_note)
    {
      (*note)->previous_note->next_note = NULL;
    }
  free (*note);
  *note = next;
}

void
libgregorio_free_notes (gregorio_note ** note)
{
  gregorio_note *tmp;
  while (*note)
    {
      tmp = (*note)->next_note;
      free (*note);
      *note = tmp;
    }
}


void
libgregorio_add_glyph (gregorio_glyph ** current_glyph, char type,
		       gregorio_note * first_note, char liquescentia)
{
  gregorio_glyph *next_glyph = malloc (sizeof (gregorio_glyph));
  if (!next_glyph)
    {
      gregorio_message (_("error in memory allocation"),
			   "add_glyph", FATAL_ERROR, 0);
      return;
    }
  next_glyph->type = GRE_GLYPH;
  next_glyph->glyph_type = type;
  next_glyph->liquescentia = liquescentia;
  next_glyph->first_note = first_note;
  next_glyph->next_glyph = NULL;
  next_glyph->previous_glyph = *current_glyph;
  if (*current_glyph)
    {
      (*current_glyph)->next_glyph = next_glyph;
    }
  *current_glyph = next_glyph;
}


void
libgregorio_add_special_as_glyph (gregorio_glyph ** current_glyph, char type,
				  char pitch)
{
  gregorio_glyph *next_glyph = malloc (sizeof (gregorio_glyph));
  if (!next_glyph)
    {
      gregorio_message (_("error in memory allocation"),
			   "add_special_as_glyph", FATAL_ERROR, 0);
      return;
    }
  next_glyph->type = type;
  next_glyph->glyph_type = pitch;
  //next_glyph->liquescentia = 0;
  next_glyph->first_note = NULL;
  next_glyph->next_glyph = NULL;
  next_glyph->previous_glyph = *current_glyph;
  if (*current_glyph)
    {
      (*current_glyph)->next_glyph = next_glyph;
    }
  *current_glyph = next_glyph;
}


void
libgregorio_go_to_first_glyph (gregorio_glyph ** glyph)
{
  gregorio_glyph *tmp;
  if (!*glyph)
    {
      return;
    }
  tmp = *glyph;
  while (tmp->previous_glyph)
    {
      tmp = tmp->previous_glyph;
    }
  *glyph = tmp;
}


void
libgregorio_free_one_glyph (gregorio_glyph ** glyph)
{
  gregorio_glyph *next = NULL;
  if (!glyph || !*glyph)
    {
      return;
    }
  if ((*glyph)->next_glyph)
    {
      (*glyph)->next_glyph->previous_glyph = NULL;
      next = (*glyph)->next_glyph;
    }
  if ((*glyph)->previous_glyph)
    {
      (*glyph)->previous_glyph->next_glyph = NULL;
    }
  libgregorio_free_notes (&(*glyph)->first_note);
  free (*glyph);
  *glyph = next;
}


void
libgregorio_free_glyphs (gregorio_glyph ** glyph)
{
  gregorio_glyph *next_glyph;
  if (!glyph || !*glyph)
    {
      return;
    }
  while (*glyph)
    {
      next_glyph = (*glyph)->next_glyph;
      libgregorio_free_notes (&(*glyph)->first_note);
      free (*glyph);
      *glyph = next_glyph;
    }
}


void
libgregorio_add_element (gregorio_element ** current_element,
			 gregorio_glyph * first_glyph)
{
  gregorio_element *next = malloc (sizeof (gregorio_element));
  if (!next)
    {
      gregorio_message (_("error in memory allocation"),
			   "add_element", FATAL_ERROR, 0);
      return;
    }
  next->type = GRE_ELEMENT;
  //next->element_type = 0;
  next->first_glyph = first_glyph;
  next->next_element = NULL;
  if (*current_element)
    {
      (*current_element)->next_element = next;
    }
  *current_element = next;
}


void
libgregorio_add_special_as_element (gregorio_element ** current_element,
				    char type, char pitch)
{
  gregorio_element *special = malloc (sizeof (gregorio_element));
  if (!special)
    {
      gregorio_message (_("error in memory allocation"),
			   "add_special_as_element", FATAL_ERROR, 0);
      return;
    }
  special->type = type;
  special->element_type = pitch;
  special->first_glyph = NULL;
  special->next_element = NULL;
  if (*current_element)
    {
      (*current_element)->next_element = special;
    }
  *current_element = special;
}


void
libgregorio_free_one_element (gregorio_element ** element)
{
  gregorio_element *next;
  if (!element || !*element)
    {
      return;
    }
  next = (*element)->next_element;
  libgregorio_free_glyphs (&(*element)->first_glyph);
  free (*element);
  *element = next;
}


void
libgregorio_free_elements (gregorio_element ** element)
{
  gregorio_element *next;
  if (!element || !*element)
    {
      return;
    }
  while (*element)
    {
      next = (*element)->next_element;
      libgregorio_free_glyphs (&(*element)->first_glyph);
      free (*element);
      *element = next;
    }
}

void
libgregorio_add_text (char *mbcharacters,
		      gregorio_character ** current_character)
{
  size_t len;
  wchar_t *wtext;
  int i = 0;
  if (mbcharacters == NULL)
    {
      return;
    }
  len = strlen (mbcharacters);	//to get the length of the syllable in ASCII
  wtext = (wchar_t *) malloc ((len + 1) * sizeof (wchar_t));
  mbstowcs (wtext, mbcharacters, (sizeof (wchar_t) * (len + 1)));	//converting into wchar_t
  // then we get the real length of the syllable, in letters
  len = wcslen (wtext);
  wtext[len] = L'\0';
  // we add the corresponding characters in the list of gregorio_characters
  while (wtext[i])
    {
      libgregorio_add_character (current_character, wtext[i]);
      i++;
    }
  free (wtext);
}

void
libgregorio_add_character (gregorio_character ** current_character,
			   wchar_t wcharacter)
{
  gregorio_character *element =
    (gregorio_character *) malloc (sizeof (gregorio_character));
  if (!element)
    {
      gregorio_message (_("error in memory allocation"),
			   "libgregorio_add_character", FATAL_ERROR, 0);
      return;
    }
  element->is_character = 1;
  element->cos.character = wcharacter;
  element->next_character = NULL;
  element->previous_character = *current_character;
  if (*current_character)
    {
      (*current_character)->next_character = element;
    }
  *current_character = element;
}


void
libgregorio_free_one_character (gregorio_character * current_character)
{
  free (current_character);
}

void
libgregorio_free_characters (gregorio_character * current_character)
{
  gregorio_character *next_character;
  if (!current_character)
    {
      return;
    }
  while (current_character)
    {
      next_character = current_character->next_character;
      libgregorio_free_one_character (current_character);
      current_character = next_character;
    }
}

void
libgregorio_go_to_first_character (gregorio_character ** character)
{
  gregorio_character *tmp;
  if (!character || !*character)
    {
      return;
    }
  tmp = *character;
  while (tmp->previous_character)
    {
      tmp = tmp->previous_character;
    }
  *character = tmp;
}

void
libgregorio_begin_style (gregorio_character ** current_character,
			 unsigned char style)
{
  gregorio_character *element =
    (gregorio_character *) malloc (sizeof (gregorio_character));
  if (!element)
    {
      gregorio_message (_("error in memory allocation"),
			   "add_note", FATAL_ERROR, 0);
      return;
    }
  element->is_character = 0;
  element->cos.s.type = ST_T_BEGIN;
  element->cos.s.style = style;
  element->previous_character = *current_character;
  element->next_character = NULL;
  if (*current_character)
    {
      (*current_character)->next_character = element;
    }
  *current_character = element;
}

void
libgregorio_end_style (gregorio_character ** current_character,
		       unsigned char style)
{
  gregorio_character *element =
    (gregorio_character *) malloc (sizeof (gregorio_character));
  if (!element)
    {
      gregorio_message (_("error in memory allocation"),
			   "add_note", FATAL_ERROR, 0);
      return;
    }
  element->is_character = 0;
  element->cos.s.type = ST_T_END;
  element->cos.s.style = style;
  element->next_character = NULL;
  element->previous_character = *current_character;
  if (*current_character)
    {
      (*current_character)->next_character = element;
    }
  *current_character = element;
}

void
libgregorio_add_syllable (gregorio_syllable ** current_syllable,
			  int number_of_voices, gregorio_element * elements[],
			  gregorio_character * first_character, gregorio_character *first_translation_character, char position)
{
  gregorio_syllable *next;
  gregorio_element **tab;
  int i;
  if (number_of_voices > MAX_NUMBER_OF_VOICES)
    {
      gregorio_message (_("too many voices"),
			   "add_syllable", FATAL_ERROR, 0);
      return;
    }
  next = malloc (sizeof (gregorio_syllable));
  if (!next)
    {
      gregorio_message (_("error in memory allocation"),
			   "add_syllable", FATAL_ERROR, 0);
      return;
    }
  next->type = GRE_SYLLABLE;
  next->position = position;
  next->text = first_character;
  next->translation = first_translation_character;
  next->next_syllable = NULL;
  tab = (gregorio_element **) malloc (number_of_voices *
				  sizeof (gregorio_element *));
  if (elements)
    {
      for (i = 0; i < number_of_voices; i++)
	{
	  tab[i] = elements[i];
	}
    }
  else
    {
      for (i = 0; i < number_of_voices; i++)
	{
	  tab[i] = NULL;
	}
    }
  next->elements = tab;
  if (*current_syllable)
    {
      (*current_syllable)->next_syllable = next;
    }
  *current_syllable = next;
}


void
libgregorio_free_one_syllable (gregorio_syllable ** syllable,
			       int number_of_voices)
{
  int i;
  gregorio_syllable *next;
  if (!syllable || !*syllable)
    {
      gregorio_message (_("function called with NULL argument"),
			   "free_one_syllable", WARNING, 0);
      return;
    }
  for (i = 0; i < number_of_voices; i++)
    {
      libgregorio_free_elements ((struct gregorio_element **)
				 &((*syllable)->elements[i]));
    }
  if ((*syllable)->text)
    {
      libgregorio_free_characters ((*syllable)->text);
    }
  if ((*syllable)->translation)
    {
      libgregorio_free_characters ((*syllable)->translation);
    }
  next = (*syllable)->next_syllable;
  free ((*syllable)->elements);
  free (*syllable);
  *syllable = next;
}


void
libgregorio_free_syllables (gregorio_syllable ** syllable,
			    int number_of_voices)
{
  if (!syllable || !*syllable)
    {
      gregorio_message (_("function called with NULL argument"),
			   "free_syllables", WARNING, 0);
      return;
    }
  while (*syllable)
    {
      libgregorio_free_one_syllable (syllable, number_of_voices);
    }
}

gregorio_score *
libgregorio_new_score ()
{
  gregorio_score *new_score = malloc (sizeof (gregorio_score));
  new_score->first_syllable = NULL;
  new_score->number_of_voices = 1;
  new_score->name = NULL;
  new_score->initial_style = NORMAL_INITIAL;
  new_score->office_part = NULL;
  new_score->lilypond_preamble = NULL;
  new_score->opustex_preamble = NULL;
  new_score->musixtex_preamble = NULL;
  new_score->first_voice_info = NULL;
  new_score->mode=0;
  new_score->gregoriotex_font = NULL;
  return new_score;
}

void
libgregorio_free_score (gregorio_score * score)
{
  if (!score)
    {
      gregorio_message (_("function called with NULL argument"),
			   "free_one_syllable", WARNING, 0);
      return;
    }
  libgregorio_free_syllables (&(score->first_syllable),
			      score->number_of_voices);
  libgregorio_free_score_infos (score);
  free (score);
}

void
libgregorio_set_score_name (gregorio_score * score, char *name)
{
  if (!score)
    {
      gregorio_message (_("function called with NULL argument"),
			   "libgregorio_set_score_name", WARNING, 0);
      return;
    }
  score->name = name;
}

void
libgregorio_set_score_office_part (gregorio_score * score, char *office_part)
{
  if (!score)
    {
      gregorio_message (_("function called with NULL argument"),
			   "libgregorio_set_score_office_part", WARNING, 0);
      return;
    }
  score->office_part = office_part;
}

void
libgregorio_set_score_number_of_voices (gregorio_score * score,
					int number_of_voices)
{
  if (!score)
    {
      gregorio_message (_("function called with NULL argument"),
			   "libgregorio_set_score_number_of_voices", WARNING,
			   0);
      return;
    }
  score->number_of_voices = number_of_voices;
}

void
libgregorio_set_score_lilypond_preamble (gregorio_score * score,
					 char *lilypond_preamble)
{
  if (!score)
    {
      gregorio_message (_("function called with NULL argument"),
			   "libgregorio_set_score_lilypond_preamble", WARNING,
			   0);
      return;
    }
  score->lilypond_preamble = lilypond_preamble;
}

void
libgregorio_set_score_opustex_preamble (gregorio_score * score,
					char *opustex_preamble)
{
  if (!score)
    {
      gregorio_message (_("function called with NULL argument"),
			   "libgregorio_set_score_opustex_preamble", WARNING,
			   0);
      return;
    }
  score->opustex_preamble = opustex_preamble;
}

void
libgregorio_set_score_musixtex_preamble (gregorio_score * score,
					 char *musixtex_preamble)
{
  if (!score)
    {
      gregorio_message (_("function called with NULL argument"),
			   "libgregorio_set_score_musixtex_preamble", WARNING,
			   0);
      return;
    }
  score->musixtex_preamble = musixtex_preamble;
}

void
libgregorio_add_voice_info (gregorio_voice_info ** current_voice_info)
{
  gregorio_voice_info *next = malloc (sizeof (gregorio_voice_info));
  next->initial_key = NO_KEY;
  next->anotation = NULL;
  next->author = NULL;
  next->date = NULL;
  next->manuscript = NULL;
  next->reference = NULL;
  next->storage_place = NULL;
  next->translator = NULL;
  next->translation_date = NULL;
  next->style = NULL;
  next->virgula_position = NULL;
  next->next_voice_info = NULL;
  if (*current_voice_info)
    {
      (*current_voice_info)->next_voice_info = next;
    }
  *current_voice_info = next;
}

void
libgregorio_free_score_infos (gregorio_score * score)
{
  if (!score)
    {
      gregorio_message (_("function called with NULL argument"),
			   "libgregorio_free_score_infos", WARNING, 0);
      return;
    }
  if (score->name)
    {
      free (score->name);
    }
  if (score->office_part)
    {
      free (score->office_part);
    }
  if (score->lilypond_preamble)
    {
      free (score->lilypond_preamble);
    }
  if (score->opustex_preamble)
    {
      free (score->opustex_preamble);
    }
  if (score->musixtex_preamble)
    {
      free (score->musixtex_preamble);
    }
  if (score->first_voice_info)
    {
      libgregorio_free_voice_infos (score->first_voice_info);
    }
}

void
libgregorio_free_voice_infos (gregorio_voice_info * voice_info)
{
  gregorio_voice_info *next;
  if (!voice_info)
    {
      gregorio_message (_("function called with NULL argument"),
			   "free_voice_info", WARNING, 0);
      return;
    }
  while (voice_info)
    {
      if (voice_info->anotation)
	{
	  free (voice_info->anotation);
	}
      if (voice_info->date)
	{
	  free (voice_info->date);
	}
      if (voice_info->author)
	{
	  free (voice_info->author);
	}
      if (voice_info->manuscript)
	{
	  free (voice_info->manuscript);
	}
      if (voice_info->reference)
	{
	  free (voice_info->reference);
	}
      if (voice_info->storage_place)
	{
	  free (voice_info->storage_place);
	}
      if (voice_info->translator)
	{
	  free (voice_info->translator);
	}
      if (voice_info->translation_date)
	{
	  free (voice_info->translation_date);
	}
      if (voice_info->style)
	{
	  free (voice_info->style);
	}
      if (voice_info->virgula_position)
	{
	  free (voice_info->virgula_position);
	}
      next = voice_info->next_voice_info;
      free (voice_info);
      voice_info = next;
    }
}

/* a set of quite useless function */

void
libgregorio_set_voice_initial_key (gregorio_voice_info * voice_info,
				   int initial_key)
{
  if (!voice_info)
    {
      gregorio_message (_("function called with NULL argument"),
			   "libgregorio_set_voice_initial_key", WARNING, 0);
      return;
    }
  voice_info->initial_key = initial_key;
}



void
libgregorio_set_voice_anotation (gregorio_voice_info * voice_info,
				 char *anotation)
{
  if (!voice_info)
    {
      gregorio_message (_("function called with NULL argument"),
			   "libgregorio_set_voice_anotation", WARNING, 0);
      return;
    }
  voice_info->anotation = anotation;
}

void
libgregorio_set_voice_author (gregorio_voice_info * voice_info, char *author)
{
  if (!voice_info)
    {
      gregorio_message (_("function called with NULL argument"),
			   "libgregorio_set_voice_author", WARNING, 0);
      return;
    }
  voice_info->author = author;
}

void
libgregorio_set_voice_date (gregorio_voice_info * voice_info, char *date)
{
  if (!voice_info)
    {
      gregorio_message (_("function called with NULL argument"),
			   "libgregorio_set_voice_date", WARNING, 0);
      return;
    }
  voice_info->date = date;
}

void
libgregorio_set_voice_manuscript (gregorio_voice_info * voice_info,
				  char *manuscript)
{
  if (!voice_info)
    {
      gregorio_message (_("function called with NULL argument"),
			   "libgregorio_set_voice_manuscript", WARNING, 0);
      return;
    }
  voice_info->manuscript = manuscript;
}

void
libgregorio_set_voice_reference (gregorio_voice_info * voice_info,
				 char *reference)
{
  if (!voice_info)
    {
      gregorio_message (_("function called with NULL argument"),
			   "libgregorio_set_voice_reference", WARNING, 0);
      return;
    }
  voice_info->reference = reference;
}

void
libgregorio_set_voice_storage_place (gregorio_voice_info * voice_info,
				     char *storage_place)
{
  if (!voice_info)
    {
      gregorio_message (_("function called with NULL argument"),
			   "libgregorio_set_voice_storage_place", WARNING, 0);
      return;
    }
  voice_info->storage_place = storage_place;
}

void
libgregorio_set_voice_translator (gregorio_voice_info * voice_info,
				  char *translator)
{
  if (!voice_info)
    {
      gregorio_message (_("function called with NULL argument"),
			   "libgregorio_set_voice_translator", WARNING, 0);
      return;
    }
  voice_info->translator = translator;
}

void
libgregorio_set_voice_translation_date (gregorio_voice_info * voice_info,
					char *translation_date)
{
  if (!voice_info)
    {
      gregorio_message (_("function called with NULL argument"),
			   "libgregorio_set_voice_translation_date", WARNING,
			   0);
      return;
    }
  voice_info->translation_date = translation_date;
}

void
libgregorio_set_voice_style (gregorio_voice_info * voice_info, char *style)
{
  if (!voice_info)
    {
      gregorio_message (_("function called with NULL argument"),
			   "libgregorio_set_voice_style", WARNING, 0);
      return;
    }
  voice_info->style = style;
}

void
libgregorio_set_voice_virgula_position (gregorio_voice_info * voice_info,
					char *virgula_position)
{
  if (!voice_info)
    {
      gregorio_message (_("function called with NULL argument"),
			   "libgregorio_set_voice_virgula_position", WARNING,
			   0);
      return;
    }
  voice_info->virgula_position = virgula_position;
}



/**********************************
 * 
 * Activate_isolated_h_episemus is used when we see an "isolated"
 * horizontal episemus: when we type ab__ lex see a then b_ then _, so
 * we must put the _ on the a (kind of backward process), and say the
 * the episemus on the b is a multi episemus. Here n is the length of
 * the isolated episemus we found (can be up to 4).
 * 
 *********************************/
void
libgregorio_activate_isolated_h_episemus (gregorio_note * current_note, int n)
{
  int i;
  gregorio_note *tmp = current_note;
  char top_note;
  if (!current_note)
    {
      gregorio_message (ngettext
			   ("isolated horizontal episemus at the beginning of a note sequence, ignored",
			    "isolated horizontal episemus at the beginning of a note sequence, ignored",
			    n), "activate_h_isolated_episemus", WARNING, 0);
      return;
    }
  if (current_note->type != GRE_NOTE)
    {
      gregorio_message (ngettext
			   ("isolated horizontal episemus after something that is not a note, ignored",
			    "isolated horizontal episemus after something that is not a note, ignored",
			    n), "activate_h_isolated_episemus", WARNING, 0);
      return;
    }
  /* we make the first iteration by hand,in the case where something would be in highest_pitch */
  top_note = current_note->pitch;
  tmp = tmp->previous_note;
  if (!tmp)
    {
      // case of b___
      gregorio_message (_
			   ("found more horizontal episemus than notes able to be under"),
			   "activate_h_isolated_episemus", WARNING, 0);
      return;
    }
  for (i = 0; i < n; i++)
    {
      top_note = max (top_note, tmp->pitch);
      if (tmp->previous_note && tmp->previous_note->type == GRE_NOTE)
	{
	  tmp = tmp->previous_note;
	}
      else
	{
	  gregorio_message (_
			       ("found more horizontal episemus than notes able to be under"),
			       "activate_h_isolated_episemus", WARNING, 0);
	  break;
	}
    }
  while (tmp)
    {
      tmp->h_episemus_type = H_MULTI;
      tmp->h_episemus_top_note = top_note;
      tmp = tmp->next_note;
    }

}

/**********************************
 * 
 * Top notes are present in the score structure for the horizontal
 * episemus: if we type ab__ we must put the top notes of the two
 * notes to b, that's what is done with this function. It is a quite
 * complex process (see mix_h_episemus for details). This function
 * supposes that top notes of the previous notes of the episemus are
 * good. If the current_note is higher, it will set the previous
 * top-notes to this note, and if it is note it will set the top note
 * of the current note to the top note of the previous notes. Kind of
 * recursive process in fact.
 * 
 *********************************/

void
libgregorio_determine_good_top_notes (gregorio_note * current_note)
{
  char top_note;
  gregorio_note *prev_note;
  if (!current_note)
    {
      gregorio_message (_
			   ("call with NULL argument"),
			   "activate_h_isolated_episemus", ERROR, 0);
      return;
    }
  prev_note = current_note->previous_note;
  if (!prev_note)
    {
      return;
    }
  if (current_note->h_episemus_top_note < prev_note->h_episemus_top_note)
    {
      current_note->h_episemus_top_note = prev_note->h_episemus_top_note;
    }
  else
    {
      top_note = current_note->h_episemus_top_note;
      while (prev_note && prev_note->h_episemus_type == H_MULTI)
	{
	  prev_note->h_episemus_top_note = top_note;
	  prev_note = prev_note->previous_note;
	}
    }
}

/**********************************
 * 
 * mix_h_episemus is quite uneasy to understand. The basis is that: we
 * have determined well the previous h episemus until the current note
 * (even the top notes !), now we have a h episemus (argument type)
 * and we would like to integrate it. That's what we do there.
 * 
 *********************************/

void
libgregorio_mix_h_episemus (gregorio_note * current_note, char type)
{
  gregorio_note *prev_note = NULL;
  if (current_note)
    {
      prev_note = current_note->previous_note;
    }
  if (type == H_NO_EPISEMUS)
    {
      current_note->h_episemus_type = H_NO_EPISEMUS;
    }
  else
    {
      current_note->h_episemus_top_note = current_note->pitch;
      if (!prev_note || prev_note->type != GRE_NOTE
	  || prev_note->h_episemus_type == H_NO_EPISEMUS)
	{
	  current_note->h_episemus_type = H_ALONE;
	}
      else
	{
	  current_note->h_episemus_type = H_MULTI;
	  if (prev_note->h_episemus_type != H_MULTI)
	    {
	      prev_note->h_episemus_type = H_MULTI;
	    }
	  libgregorio_determine_good_top_notes (current_note);
	}
    }
}


/**********************************
 * 
 * There are still problems with the h episemus (for example if you
 * separate a multi h episemus into two different elements, this is a
 * patch function that makes it better, but it is quite ugly. What I
 * think would be better (TODO) is to determine h episemus in the
 * element determination part, so that it will be ok in the score
 * structure. But element determination part is not enough advanced
 * for that.
 * 
 *********************************/

void
libgregorio_determine_h_episemus_type (gregorio_note * note)
{
  if (!note)
    {
      gregorio_message (_("function called with NULL argument"),
			   "determine_h_episemus_type", WARNING, 0);
      return;
    }
  if (note->h_episemus_type == H_NO_EPISEMUS
      || note->h_episemus_type == H_ALONE)
    {
      return;
    }
  //here h_episemus_type is H_MULTI
  if (!note->next_note && !note->previous_note)
    {
      note->h_episemus_type = H_ALONE;
      return;
    }

  if (note->next_note)
    {
      if (is_multi (note->next_note->h_episemus_type))
	{
	  note->h_episemus_type = H_MULTI_MIDDLE;
	}
      else
	{
	  note->h_episemus_type = H_MULTI_END;
	}
    }
  else
    {
      if (note->previous_note->h_episemus_type == H_NO_EPISEMUS)
	{
	  note->h_episemus_type = H_ALONE;
	  return;
	}
      else
	{
	  note->h_episemus_type = H_MULTI_END;
	}
    }

  if (note->previous_note)
    {
      if (is_multi (note->previous_note->h_episemus_type))
	{
	  if (note->h_episemus_type != H_MULTI_END)
	    {
	      note->h_episemus_type = H_MULTI_MIDDLE;
	    }
	}
      else
	{
	  note->h_episemus_type = H_MULTI_BEGINNING;
	}
    }
  else
    {
      if (note->next_note->h_episemus_type == H_NO_EPISEMUS)
	{
	  note->h_episemus_type = H_ALONE;
	}
      else
	{
	  note->h_episemus_type = H_MULTI_BEGINNING;
	}
    }

}

/**********************************
 * 
 * Very small function to determine if a punctum is a punctum
 * inclinatum or not.
 * 
 *********************************/

char
libgregorio_det_shape (char pitch)
{
  if (pitch < 'a')
    {
      return S_PUNCTUM_INCLINATUM;
    }
  else
    {
      return S_PUNCTUM;
    }
}

/**********************************
 * 
 * A function to build an integer from a key, very useful to represent
 * it in the structure.
 *
 *The representation is : 
 *
 * * 1 for a C key on the first (bottom) line
 * * 3 for a C key on the second line
 * * 5 for a C key on the third line (default key)
 * * 7 for a C key on the fourth line
 * 
 * * -2 for a F key on the first line
 * * 0 for a F key on the second line
 * * 2 for a F key on the third line
 * * 4 for a F key on the fourth line
 * 
 *********************************/

int
libgregorio_calculate_new_key (char step, int line)
{
  switch (step)
    {
    case C_KEY:
      return (2 * line) - 1;
      break;
    case F_KEY:
      return (2 * line) - 4;
      break;
    default:
      gregorio_message (_("can't calculate key"),
			   "libgregorio_calculate_new_key", ERROR, 0);
      return NO_KEY;
    }
}

/**********************************
 * 
 * The reverse function of the preceeding : give step (c or f) and
 * line (1-4) from an integer representing the key.
 * 
 *********************************/

void
libgregorio_det_step_and_line_from_key (int key, char *step, int *line)
{
  switch (key)
    {
    case -2:
      *step = 'f';
      *line = 1;
      break;
    case 0:
      *step = 'f';
      *line = 2;
      break;
    case 2:
      *step = 'f';
      *line = 3;
      break;
    case 4:
      *step = 'f';
      *line = 4;
      break;
    case 1:
      *step = 'c';
      *line = 1;
      break;
    case 3:
      *step = 'c';
      *line = 2;
      break;
    case 5:
      *step = 'c';
      *line = 3;
      break;
    case 7:
      *step = 'c';
      *line = 4;
      break;
    default:
      *step = 0;
      *line = 0;
      gregorio_message (_("can't determine step and line of the key"),
			   "libgregorio_det_step_and_line_from_key", ERROR,
			   0);
      return;
    }
}

/**********************************
 * 
 * You must be asking yourself why such numbers ? It is simple : it
 * are the magic numbers that make a correspondance between the height
 * (on the score) and the real pitch (depending on the key) of a note
 * !
 *
 * Demonstration : when you have a c key on the third line, it is
 * represented by 5. To have the height (on the score) of a note, you
 * simple add the key to the step ! for exemple you want to know the
 * letter by which an a will be represented : you do a + 5 = f !
 *
 * Of course you need to add or withdraw 7 depending on which octave
 * the note you want is in.
 * 
 *********************************/

char
libgregorio_det_pitch (int key, char step, int octave)
{
  switch (octave)
    {
    case (2):
      return key + step;
      break;
    case (1):
      return key + step - 7;
      break;
    case (3):
      return key + step + 7;
      break;
    default:
      gregorio_message (_("unknown octave"),	//TODO : à améliorer
			   "libgregorio_det_pitch", ERROR, 0);
      return 0;
      break;
    }
}

/**********************************
 * 
 * The reverse function of the preceeding, it gives you the step and
 * the octave of a character representing a note, according to the
 * key.
 * 
 *********************************/

void
libgregorio_set_octave_and_step_from_pitch (char *step,
					    int *octave, char pitch, int clef)
{
  if (pitch - clef < 97)
    {
      *step = pitch - clef + 7;
      *octave = 1;
      return;
    }
  if (pitch - clef > 103)
    {
      *step = pitch - clef - 7;
      *octave = 3;
      return;
    }
//else : 
  *step = pitch - clef;
  *octave = 2;
}

/**********************************
 * 
 * A function that may be useful (used in xml-write) : we have a
 * tabular of alterations (we must remember all alterations on all
 * notes all the time, they are reinitialized when a bar is found),
 * and we assign all of them to NO_ALTERATION.
 *
 *This function works in fact with a tabular of tabular, one per
 *voice, for polyphony.
 * 
 *********************************/

void
libgregorio_reinitialize_alterations (char alterations[][13],
				      int number_of_voices)
{
  int i;
  int j;
  for (j = 0; j < number_of_voices; j++)
    {
      for (i = 0; i < 13; i++)
	{
	  alterations[j][i] = NO_ALTERATION;
	}
    }
}

/**********************************
 * 
 * The corresponding function for monophony.
 * 
 *********************************/

void
libgregorio_reinitialize_one_voice_alterations (char alterations[13])
{
  int i;
  for (i = 0; i < 13; i++)
    {
      alterations[i] = NO_ALTERATION;
    }
}

/*
void
libgregorio_fix_positions (gregorio_score * score)
{
  if (!score || !score->first_syllable)
    {
//TODO : warning
      return;
    }
  gregorio_syllable *syllable = score->first_syllable;
  while (syllable)
    {
//TODO : here the case onesyllable(notes)*(:) anothersyllable(othernotes) is not trated
      if (!syllable->next_syllable
	  || syllable->next_syllable->position == WORD_BEGINNING)
	{
	  if (syllable->position != WORD_BEGINNING)
	    {
	      syllable->position = WORD_END;
	    }
	}
      syllable = syllable->next_syllable;
    }
}
*/

/**********************************
 * 
 * A function called after the entire score is determined : we check
 * if the first element is a key change, if it is the case we delete
 * it and we update the score->voice-info->initial_key. Works in
 * polyphony.
 * 
 *********************************/

void
libgregorio_fix_initial_keys (gregorio_score * score, int default_key)
{
  char *error;
  int clef = 0;
  gregorio_element *element;
  gregorio_voice_info *voice_info;
  int i;
  char to_delete = 1;

  if (!score || !score->first_syllable || !score->first_voice_info)
    {
      gregorio_message (_("score is not available"),
			   "libgregorio_fix_initial_keys", WARNING, 0);
      return;
    }
  error = malloc (100 * sizeof (char));
  voice_info = score->first_voice_info;
  for (i = 0; i < score->number_of_voices; i++)
    {
      element = score->first_syllable->elements[i];
      if (!element)
	{
	  continue;
	}
      if (element->type == GRE_C_KEY_CHANGE)
	{
	  clef =
	    libgregorio_calculate_new_key (C_KEY, element->element_type - 48);
	  voice_info->initial_key = clef;
	  libgregorio_free_one_element (&
					(score->first_syllable->elements[i]));
	  voice_info = voice_info->next_voice_info;
	  snprintf (error, 80,
		    _
		    ("in voice %d the first element is a key definition, considered as initial key"),
		    i + 1);
	  gregorio_message (error, "libgregorio_fix_initial_keys", VERBOSE,
			       0);

	  continue;
	}
      if (element->type == GRE_F_KEY_CHANGE)
	{
	  clef =
	    libgregorio_calculate_new_key (F_KEY, element->element_type - 48);
	  voice_info->initial_key = clef;
	  libgregorio_free_one_element (&
					(score->first_syllable->elements[i]));
	  snprintf (error, 80,
		    _
		    ("in voice %d the first element is a key definition, considered as initial key"),
		    i + 1);
	  gregorio_message (error, "libgregorio_fix_initial_keys", VERBOSE,
			       0);
	}
      voice_info = voice_info->next_voice_info;
    }

// then we suppress syllables that contain nothing anymore : case of (c2) at beginning of files

  for (i = 0; i < score->number_of_voices; i++)
    {
      if (score->first_syllable->elements[i])
	{
	  to_delete = 0;
	  break;
	}
    }

  if (to_delete)
    {
      libgregorio_free_one_syllable (&(score->first_syllable),
				     score->number_of_voices);
    }

// finally we initialize voice infos that have no initial key to default key

  voice_info = score->first_voice_info;

  for (i = 0; i < score->number_of_voices; i++)
    {



      if (voice_info->initial_key == NO_KEY)
	{
	  voice_info->initial_key = default_key;
	  snprintf (error, 75,
		    _
		    ("no initial key definition in voice %d, default key definition applied"),
		    i + 1);
	  gregorio_message (error, "libgregorio_fix_initial_keys", VERBOSE,
			       0);
	}
      voice_info = voice_info->next_voice_info;
    }
  free (error);
}

/**********************************
 * 
 * A small function to determine if an element list contains only
 * special elements (bar, key-change, etc.), useful because the
 * representation (in xml for example) may vary according to it.
 * 
 *********************************/

char
libgregorio_is_only_special (gregorio_element * element)
{
  if (!element)
    {
      return 0;
    }
  while (element)
    {
      if (element->type == GRE_ELEMENT)
	{
	  return 0;
	}
      element = element->next_element;
    }
  return 1;
}


/**********************************
 * 
 * Here are functions that deal with characters and styles.
 * 
 *********************************/

/* Here is a function that tests if a letter is a vowel or not */

int
libgregorio_is_vowel (wchar_t letter)
{
  wchar_t vowels[] = { L'a', L'e', L'i', L'o', L'u', L'y', L'A', L'E',
    L'I', 'O', 'U', 'Y', L'œ', L'Œ', L'æ', L'Æ', L'ó', L'À', L'È',
    L'É', L'Ì', L'Í', L'Ý', L'Ò', L'Ó', L'è', L'é', L'ò', L'ú',
    L'ù', L'ý', L'á', L'à', L'ǽ', L'Ǽ', L'í', L'*'
  };
  int i;
  for (i = 0; i < 37; i++)
    {
      if (letter == vowels[i])
	{
	  return 1;
	}
    }
  return 0;
}

// a macro that will be used for verbatim and special-characters in the next function, it calls function with a wchar_t * which is the verbatim or special-character. It places current_character to the character next to the end of the verbatim or special_char charachters.

#define verb_or_sp(ST_TYPE, function) \
		  i = 0;\
		  j = 0;\
		  current_character = current_character->next_character;\
		  begin_character = current_character;\
		  while (current_character)\
		    {\
		      if (current_character->cos.s.type == ST_T_END\
			  && current_character->cos.s.style == ST_TYPE)\
			{\
			  break;\
			}\
		      else\
			{\
			  if (current_character->is_character)\
			    {\
			      i++;\
			    }\
			  current_character =\
			    current_character->next_character;\
			}\
		    }\
		  if (i == 0)\
		    {\
		      break;\
		    }\
		  text = (wchar_t *) malloc ((i + 1) * sizeof (wchar_t));\
		  current_character = begin_character;\
		  while (j < i)\
		    {\
		      if (current_character->is_character)\
			{\
			  text[j] = current_character->cos.character;\
			  current_character =\
			    current_character->next_character;\
			  j++;\
			}\
		      else\
			{\
			  current_character =\
			    current_character->next_character;\
			}\
		    }\
		  text[i] = L'\0';\
		  function (f, text);\
		  free (text);



/*

This function is made to simplify the output modules : they just have to declare some simple functions (what to do when meeting a beginning of style, a character, etc.) and to call this function with pointer to these functions, and that will automatically write the good ouput. This function does not test at all the gregorio_character list, if it is wrong, then the ouput will be wrong. It is very simple to understand, even if it is a bit long.

type may be 0, or SKIP_FIRST_SYLLABLE

*/

void
libgregorio_write_text (char type, gregorio_character * current_character,
			FILE * f, void (*printverb) (FILE *, wchar_t *),
			void (*printchar) (FILE *, wchar_t),
			void (*begin) (FILE *, unsigned char),
			void (*end) (FILE *, unsigned char),
			void (*printspchar) (FILE *, wchar_t *))
{
  wchar_t *text;
  int i, j;
  gregorio_character *begin_character;

  if (current_character == NULL)
    {
      return;
    }
  if (type == SKIP_FIRST_LETTER)
    {
      while (current_character)
	{
	  if (!current_character->is_character
	      && current_character->cos.s.style == ST_CENTER)
	    {
	      break;
	    }
	  current_character = current_character->next_character;
	}
    }
  while (current_character)
    {
      if (current_character->is_character)
	{
	  printchar (f, current_character->cos.character);
	}
      else
	{
	  if (current_character->cos.s.type == ST_T_BEGIN)
	    {
	      switch (current_character->cos.s.style)
		{
		case ST_VERBATIM:
		  verb_or_sp (ST_VERBATIM, printverb) break;
		case ST_SPECIAL_CHAR:
		  verb_or_sp (ST_SPECIAL_CHAR, printspchar) break;
		default:
		  begin (f, current_character->cos.s.style);
		  break;
		}
	    }
	  else
	    {			// ST_T_END
	      end (f, current_character->cos.s.style);
	    }
	}

      current_character = current_character->next_character;
    }
}

void
libgregorio_write_first_letter (gregorio_character * current_character,
				FILE * f, void (*printverb) (FILE *,
							     wchar_t *),
				void (*printchar) (FILE *, wchar_t),
				void (*begin) (FILE *, unsigned char),
				void (*end) (FILE *, unsigned char),
				void (*printspchar) (FILE *, wchar_t *))
{
  int i, j;
  wchar_t *text;
  gregorio_character *begin_character;
  while (current_character)
    {
      if (current_character->is_character)
	{
	  printchar (f, current_character->cos.character);
	}
      else
	{
	  if (current_character->cos.s.type == ST_T_BEGIN)
	    {
	      switch (current_character->cos.s.style)
		{
		case ST_CENTER:		  
		  return;
		  break;
		case ST_VERBATIM:
		  verb_or_sp (ST_VERBATIM, printverb) break;
		case ST_SPECIAL_CHAR:
		  verb_or_sp (ST_SPECIAL_CHAR, printspchar) break;
		default:
		  begin (f, current_character->cos.s.style);
		  break;
		}
	    }
	  else
	    {			// ST_T_END
	      end (f, current_character->cos.s.style);
	    }
	}

      current_character = current_character->next_character;
    }
}

/*

A very simple function that returns the first text of a score, or the null character if there is no such thing.

*/

gregorio_character *
libgregorio_first_text (gregorio_score * score)
{
  gregorio_syllable *current_syllable;
  if (!score || !score->first_syllable)
    {
      gregorio_message (_("unable to find the first letter of the score"),
			   "libgregorio_first_text", ERROR, 0);
      return NULL;
    }
  current_syllable = score->first_syllable;
  while (current_syllable)
    {
      if (current_syllable->text)
	{
	  return current_syllable->text;
	}
      current_syllable = current_syllable->next_syllable;
    }

  gregorio_message (_("unable to find the first letter of the score"),
		       "libgregorio_first_text", ERROR, 0);
  return NULL;
}

wchar_t
libgregorio_first_letter (gregorio_score * score)
{
  gregorio_syllable *current_syllable;
  gregorio_character *current_character;
  if (!score || !score->first_syllable)
    {
      gregorio_message (_("unable to find the first letter of the score"),
			   "libgregorio_first_letter", ERROR, 0);
      return L'\0';
    }
  current_syllable = score->first_syllable;
  current_character = score->first_syllable->text;
  while (current_syllable)
    {
      while (current_character)
	{
	  if (current_character->is_character)
	    {
	      return current_character->cos.character;
	    }
	  current_character = current_character->next_character;
	}
      current_syllable = current_syllable->next_syllable;
    }

  gregorio_message (_("unable to find the first letter of the score"),
		       "libgregorio_first_letter", ERROR, 0);
  return L'\0';
}
