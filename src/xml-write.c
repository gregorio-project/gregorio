/* 
Gregorio xml output format.
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
#include "gettext.h"
#define _(str) gettext(str)
#define N_(str) str
#include "messages.h"
#include "struct.h"
#include "xml.h"
#include <stdlib.h>
#define write_note(shape) libgregorio_xml_write_note(f, note->signs, step, octave, shape, note->h_episemus_type, alteration)

void
libgregorio_xml_write_gregorio_note (FILE * f, gregorio_note * note, int clef,
			  char alterations[])
{
  if (!note)
    {
      libgregorio_message (_("call with NULL argument"),
		      "libgregorio_xml_write_gregorio_note", ERROR, 0);
      return;
    }
  if (note->type != GRE_NOTE)
    {
      libgregorio_message (_("call with argument which type is not GRE_NOTE, wrote nothing"),
		      "libgregorio_xml_write_gregorio_note", ERROR, 0);
      return;
    }
  libgregorio_determine_h_episemus_type (note);
  char step;
  int octave;
  libgregorio_set_octave_and_step_from_pitch (&step, &octave, note->pitch,
					    clef);
  char alteration = alterations[(note->pitch) - 'a'];

  if (note->shape == S_BIVIRGA)
    {
      write_note (S_VIRGA);
      write_note (S_VIRGA);
      return;
    }
  if (note->shape == S_TRIVIRGA)
    {
      write_note (S_VIRGA);
      write_note (S_VIRGA);
      write_note (S_VIRGA);
      return;
    }
  if (note->shape == S_DISTROPHA)
    {
      write_note (S_STROPHA);
      write_note (S_STROPHA);
      return;
    }
  if (note->shape == S_TRISTROPHA)
    {
      write_note (S_STROPHA);
      write_note (S_STROPHA);
      write_note (S_STROPHA);
      return;
    }
  write_note (note->shape);
  return;
}

void
libgregorio_xml_write_gregorio_glyph (FILE * f, gregorio_glyph * glyph, int clef,
			   char alterations[])
{
  if (!glyph)
    {
      libgregorio_message (_("call with NULL argument"),
		      "libgregorio_xml_write_gregorio_glyph", ERROR, 0);
      return;
    }
  if (is_alteration (glyph->type))
    {
      libgregorio_xml_write_alteration (f, glyph->type, glyph->glyph_type, clef,
			    alterations);
      return;
    }
  if (glyph->type == GRE_SPACE && glyph->glyph_type==SP_ZERO_WIDTH) {
fprintf(f,"<zero-width-space />");
return;
}
  if (glyph->type != GRE_GLYPH)
    {
      libgregorio_message (_("call with an argument which type is unknown"),
		      "libgregorio_xml_write_gregorio_glyph", ERROR, 0);
      return;
    }
  char *type = libgregorio_xml_glyph_type_to_str (glyph->glyph_type);
  fprintf (f, "<glyph><type>%s</type>", type);
  libgregorio_xml_write_liquescentia (f, glyph->liquescentia);
  gregorio_note *current_note = glyph->first_note;
  while (current_note)
    {
      libgregorio_xml_write_gregorio_note (f, current_note, clef, alterations);
      current_note = current_note->next_note;
    }
  fprintf (f, "</glyph>");
}

void
libgregorio_xml_write_gregorio_element (FILE * f, gregorio_element * element, int *clef,
			     char alterations[])
{
  if (!element)
    {
      libgregorio_message (_("call with NULL argument"),
		      "libgregorio_xml_write_gregorio_element", ERROR, 0);
      return;
    }
  if (element->type == GRE_ELEMENT)
    {
      fprintf (f, "<element>");
      gregorio_glyph *current_glyph = element->first_glyph;
      while (current_glyph)
	{
	  libgregorio_xml_write_gregorio_glyph (f, current_glyph, *clef, alterations);
	  current_glyph = current_glyph->next_glyph;
	}
      fprintf (f, "</element>");
      return;
    }
  if (element->type == GRE_SPACE)
    {
      libgregorio_xml_write_space (f, element->element_type);
      return;
    }
  if (element->type == GRE_BAR)
    {
      libgregorio_reinitialize_one_voice_alterations (alterations);
      libgregorio_xml_write_neumatic_bar (f, element->element_type);
      return;
    }
  if (element->type == GRE_END_OF_LINE)
    {
      fprintf(f,"<end-of-line />");
      return;
    }
  if (element->type == GRE_C_KEY_CHANGE)
    {
      *clef = libgregorio_calculate_new_key (C_KEY, element->element_type - 48);
      libgregorio_xml_write_key_change (f, C_KEY, element->element_type - 48);
      return;
    }
  if (element->type == GRE_F_KEY_CHANGE)
    {
      *clef = libgregorio_calculate_new_key (F_KEY, element->element_type - 48);
      libgregorio_xml_write_key_change (f, F_KEY, element->element_type - 48);
      return;
    }

      libgregorio_message (_("call with an argument which type is unknown"),
		      "libgregorio_xml_write_gregorio_element", ERROR, 0);

}

void
libgregorio_xml_write_space (FILE * f, char type)
{
  switch (type)
    {
    case SP_LARGER_SPACE:
      fprintf (f, "<larger-neumatic-space />");
      break;
    case SP_GLYPH_SPACE:
      fprintf (f, "<glyph-space />");
      break;
    case SP_NEUMATIC_CUT:
	//we do not write neumatic cuts, they juste delimit elements
	break;
    default:
      libgregorio_message (_("space type is unknown"),
		      "libgregorio_xml_write_space", ERROR, 0);
      break;
    }
}



void
libgregorio_xml_write_neumatic_bar (FILE * f, char type)
{
  char *str;
  str = libgregorio_xml_bar_to_str (type);
  fprintf (f, "<neumatic-bar><type>%s</type></neumatic-bar>", str);
  free(str);
}

void
libgregorio_xml_write_key_change (FILE * f, char step, int line)
{
  fprintf (f,
	   "<clef-change><step>%c</step><line>%d</line></clef-change>",
	   step, line);
}

void
libgregorio_xml_write_key_change_in_polyphony (FILE * f, char step, int line,
					 int voice)
{
  fprintf (f,
	   "<clef-change voice=\"%d\"><step>%c</step><line>%d</line></clef-change>",
	   voice, step, line);
}

char in_text=0;

void
libgregorio_xml_write_begin (FILE * f, unsigned char style)
{
  if (in_text) 
    {
	fprintf(f, "</str>");
	in_text=0;
    }
  switch (style)
    {
    case ST_ITALIC:
      fprintf (f, "<italic>");
      break;
    case ST_SMALL_CAPS:
      fprintf (f, "<small-caps>");
      break;
    case ST_BOLD:
      fprintf (f, "<bold>");
      break;
    case ST_CENTER:
      fprintf (f, "<center>");
      break;
    case ST_TT:
      fprintf (f, "<tt>");
      break;
    default:
      break;
    }
}

void
libgregorio_xml_write_end (FILE * f, unsigned char style)
{
  if (in_text) 
    {
	fprintf(f, "</str>");
	in_text=0;
    }
  switch (style)
    {
    case ST_ITALIC:
      fprintf (f, "</italic>");
      break;
    case ST_SMALL_CAPS:
      fprintf (f, "</small-caps>");
      break;
    case ST_BOLD:
      fprintf (f, "</bold>");
      break;
    case ST_CENTER:
      fprintf (f, "</center>");
      break;
    case ST_TT:
      fprintf (f, "</tt>");
      break;
    default:
      break;
    }
}

void
libgregorio_xml_write_special_char (FILE * f, wchar_t * special_char)
{
  if (in_text) 
    {
	fprintf(f, "</str>");
	in_text=0;
    }
  fprintf (f, "<secial-char>%ls</special-char>", special_char);
}

void
libgregorio_xml_write_verb (FILE * f, wchar_t * verb_str)
{
  if (in_text) 
    {
	fprintf(f, "</str>");
	in_text=0;
    }
  fprintf (f, "<verbatim>%ls</verbatim>", verb_str);
}

void
libgregorio_xml_print_char (FILE * f, wchar_t to_print)
{
  if (!in_text) 
    {
	fprintf(f, "<str>");
	in_text=1;
    }
  fprintf (f, "%lc", to_print);
}

void
libgregorio_xml_print_text (FILE * f, gregorio_character *text, char position)
{
  char *position_str;
  switch (position)
    {
    case (WORD_BEGINNING):
      position_str = "beginning";
      break;
    case (WORD_MIDDLE):
      position_str = "middle";
      break;
    case (WORD_END):
      position_str = "end";
      break;
    case (WORD_ONE_SYLLABLE):
      position_str = "one-syllable";
      break;
    default:
      position_str = "";
      break;
    }
  if (!text) 
    {
	return;
    }
  fprintf (f, "<text position=\"%s\">", position_str);
      libgregorio_write_text (0, text, f,
			      (&libgregorio_xml_write_verb),
			      (&libgregorio_xml_print_char),
			      (&libgregorio_xml_write_begin),
			      (&libgregorio_xml_write_end),
			      (&libgregorio_xml_write_special_char));
  if (in_text) 
    {
	fprintf(f, "</str>");
	in_text=0;
    }
  fprintf(f, "</text>");
}


void
libgregorio_xml_write_syllable (FILE * f, gregorio_syllable * syllable,
			  int number_of_voices, int clefs[],
			  char alterations[][13])
{
  if (!syllable) {
      libgregorio_message (_("call with NULL argument"),
		      "libgregorio_xml_write_syllable", ERROR, 0);
  }
  int voice;
  int i;
  if (syllable->position == WORD_BEGINNING)
    {
      libgregorio_reinitialize_alterations (alterations, number_of_voices);
    }
  if (number_of_voices == 1)
    {
      voice = MONOPHONY;
    }
  else
    {
      voice = 1;
    }
  fprintf (f, "<syllable>");
  if (syllable->text)
    {
      libgregorio_xml_print_text (f, syllable->text, syllable->position);
    }
  for (i = 0; i < number_of_voices; i++)
  {
    if (!(syllable->elements[i]))
      {
      libgregorio_message (_("not_enough voices in syllable"),
		      "libgregorio_xml_write_syllable", VERBOSE, 0);
	voice++;
	continue;
      }
    if (libgregorio_is_only_special (syllable->elements[i]))
      {
	libgregorio_xml_write_specials_as_neumes (f, syllable->elements[i], voice,
					    &clefs[i]);
      }
    else
      {
	libgregorio_xml_write_neume (f, syllable->elements[i], voice, &clefs[i],
			       alterations[i]);
      }
    voice++;
  }


  fprintf (f, "</syllable>");
}

void
libgregorio_xml_write_neume (FILE * f, gregorio_element * element, int voice, int *clef,
		       char alterations[])
{
  if (!element)
    {
      return;
    }
  if (voice != MONOPHONY)
    {
      fprintf (f, "<neume voice=\"%d\">", voice);
    }
  else
    {
      fprintf (f, "<neume>");
    }
  while (element)
    {
      libgregorio_xml_write_gregorio_element (f, element, clef, alterations);
      element = element->next_element;
    }
  fprintf (f, "</neume>");
}

void
libgregorio_xml_write_specials_as_neumes (FILE * f, gregorio_element * element,
				    int voice, int *clef)
{
  char *str;
  while (element)
    {
      if (element->type == GRE_BAR)
	{
	  str = libgregorio_xml_bar_to_str (element->element_type);
	  if (voice == MONOPHONY)
	    {
	      fprintf (f, "<bar><type>%s</type></bar>", str);
	    }
	  else
	    {
	      fprintf (f, "<bar voice=\"%d\"><type>%s</type></bar>",
		       voice, str);
	    }
	}
      if (element->type == GRE_C_KEY_CHANGE)
	{
	  if (voice == MONOPHONY)
	    {
	      *clef =
		libgregorio_calculate_new_key (C_KEY, element->element_type - 48);
	      libgregorio_xml_write_key_change (f, C_KEY,
					  element->element_type - 48);
	    }
	  else
	    {
	      *clef =
		libgregorio_calculate_new_key (C_KEY, element->element_type - 48);
	      libgregorio_xml_write_key_change_in_polyphony (f, C_KEY,
						       element->element_type -
						       48, voice);
	    }
	}
      if (element->type == GRE_F_KEY_CHANGE)
	{
	  if (voice == MONOPHONY)
	    {
	      *clef =
		libgregorio_calculate_new_key (F_KEY, element->element_type - 48);
	      libgregorio_xml_write_key_change (f, F_KEY,
					  element->element_type - 48);
	    }
	  else
	    {
	      *clef =
		libgregorio_calculate_new_key (F_KEY, element->element_type - 48);
	      libgregorio_xml_write_key_change_in_polyphony (f, F_KEY,
						       element->element_type -
						       48, voice);
	    }
	}
      element = element->next_element;
    }
}

void
libgregorio_xml_write_score (FILE * f, gregorio_score * score)
{
  if (!score)
    {
      libgregorio_message (_("call with NULL argument"),
		      "libgregorio_xml_write_score", ERROR, 0);
      return;
    }

//we initialize the key array (that will maybe change, that's why we don't take the same)
  int i;
  int clefs[score->number_of_voices];
  gregorio_voice_info *voice_info = score->first_voice_info;
  for (i = 0; i < score->number_of_voices; i++)
    {
      if (!voice_info)
	{
	  libgregorio_message (_("score has more voice infos than voices (attribute number of voices)"),
		      "libgregorio_xml_write_syllable", ERROR, 0);
	  return;
	}
      clefs[i] = voice_info->initial_key;
      voice_info = voice_info->next_voice_info;
    }

// the clefs array is good, now let's take care of alterations
  char alterations[score->number_of_voices][13];
  libgregorio_reinitialize_alterations(alterations, score->number_of_voices);

  fprintf (f, "<score>");
  libgregorio_xml_write_score_attributes (f, score);
  gregorio_syllable *current_syllable = score->first_syllable;
  while (current_syllable)
    {
      libgregorio_xml_write_syllable (f, current_syllable, score->number_of_voices,
				clefs, alterations);
      current_syllable = current_syllable->next_syllable;
    }
  fprintf (f, "</score>\n");
}

void
libgregorio_xml_write_score_attributes (FILE * f, gregorio_score * score)
{
  if (!score)
    {
      libgregorio_message (_("call with NULL argument"),
		      "libgregorio_xml_write_score_attributes", ERROR, 0);
      return;
    }
//two variables for the key determination
  char step;
  int line;

  fprintf (f, "<score-attributes>");
  if (!score->name || score->name=="") {
      libgregorio_message (_("score has no name attribute, which is mandatory"),
		      "libgregorio_xml_write_score_attributes", ERROR, 0);
  fprintf (f, "<name></name>");
  }
  else {
  fprintf (f, "<name>%s</name>", score->name);
  }
  if (score->office_part)
    {
      fprintf (f, "<office-part>%s</office-part>", score->office_part);
    }

//then we consider the voice_info
  int voice=MONOPHONY;
  gregorio_voice_info *current_voice_info = score->first_voice_info;

  if (current_voice_info && !current_voice_info->next_voice_info)
    {
      voice = MONOPHONY;
    }
  else
    {
      voice = 1;
      fprintf (f, "<voice-list>");
    }
  while (current_voice_info)
    {
      if (voice != MONOPHONY)
	{
	  fprintf (f, "<voice-info id=\"%d\">", voice);
	}
      if (current_voice_info->anotation)
	{
	  fprintf (f,
		   "<anotation>%s</anotation>", current_voice_info-> anotation);
	}
      if (current_voice_info->author)
	{
	  fprintf (f, "<author>%s</author>", current_voice_info->author);
	}
      if (current_voice_info->date)
	{
	  fprintf (f, "<date>%s</date>", current_voice_info->date);
	}
      if (current_voice_info->manuscript)
	{
	  fprintf (f,
		   "<manuscript>%s</manuscript>", current_voice_info->manuscript);
	}
      if (current_voice_info->reference)
	{
	  fprintf (f,
		   "<reference>%s</reference>", current_voice_info->reference);
	}
      if (current_voice_info->storage_place)
	{
	  fprintf (f,
		   "<storage-place>%s</storage-place>",
		   current_voice_info->storage_place);
	}
      if (current_voice_info->translator)
	{
	  fprintf (f,
		   "<translator>%s</translator>", current_voice_info->		   translator);
	}
      if (current_voice_info->translation_date)
	{
	  fprintf (f,
		   "<translation-date>%s</translation-date>",
		   current_voice_info->translation_date);
	}

      if (current_voice_info->style)
	{
	  fprintf (f, "<style>%s</style>", current_voice_info->style);
	}
      libgregorio_det_step_and_line_from_key (current_voice_info->					 initial_key, &step, &line);
      fprintf (f, "<clef><step>%c</step><line>%d</line></clef>",
	       step, line);
      if (voice != MONOPHONY)
	{
	  fprintf (f, "</voice-info>");
      voice++;
	}

      current_voice_info = current_voice_info->next_voice_info;
    }// end of while for voice-lists
  if (voice != MONOPHONY)
    {
      fprintf (f, "</voice-list>");
    }
  fprintf (f, "</score-attributes>");
}
