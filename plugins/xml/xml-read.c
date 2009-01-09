/* 
Gregorio xml input.
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
#include <string.h>
#include <stdlib.h>
#include <libxml/xmlmemory.h>
#include <libxml/parser.h>
#include "gettext.h"
#define _(str) gettext(str)
#define N_(str) str
#include <gregorio/struct.h>
#include <gregorio/unicode.h>
#include <gregorio/messages.h>

#include "xml.h"

gregorio_score *
read_score (FILE *f)
{

  xmlDocPtr doc;
  xmlNodePtr current_node;
  gregorio_score *score;
  int i;
  gregorio_syllable *current_syllable = NULL;

  //doc = xmlParseFile (filename);
  doc=xmlReadFd(fileno(f), (const char *)"", NULL, 0);

  if (doc == NULL)
    {
      gregorio_message (_("file not parsed successfully"),
			   "libgregorio_xml_read_file", ERROR, 0);
      return NULL;
    }

  current_node = xmlDocGetRootElement (doc);

  if (current_node == NULL)
    {
      gregorio_message (_("empty file"),
			   "libgregorio_xml_read_file", WARNING, 0);
      xmlFreeDoc (doc);
      return NULL;
    }

  if (xmlStrcmp (current_node->name, (const xmlChar *) "score"))
    {
      gregorio_message (_("root element is not score"),
			   "libgregorio_xml_read_file", ERROR, 0);
      xmlFreeDoc (doc);
      return NULL;
    }

  score = gregorio_new_score ();

  current_node = current_node->xmlChildrenNode;

  if (xmlStrcmp (current_node->name, (const xmlChar *) "score-attributes"))
    {
      gregorio_message (_("score-attributes expected, not found"),
			   "libgregorio_xml_read_file", WARNING, 0);
    }
  else
    {
      libgregorio_xml_read_score_attributes (current_node->xmlChildrenNode,
					     doc, score);
    }
  current_node = current_node->next;
  // we are now at the first syllable markup

  gregorio_voice_info *voice_info = score->first_voice_info;

  int clefs[score->number_of_voices];
  if (voice_info)
    {
      for (i = 0; i < score->number_of_voices; i++)
	{
	  clefs[i] = voice_info->initial_key;
	  voice_info = voice_info->next_voice_info;
	}
    }
  else
    {
      for (i = 0; i < score->number_of_voices; i++)
	{
	  clefs[i] = DEFAULT_KEY;
	}
    }
  char alterations[score->number_of_voices][13];
  gregorio_reinitialize_alterations (alterations, score->number_of_voices);

//we have to do one iteration, to have the first_syllable
  if (xmlStrcmp (current_node->name, (const xmlChar *) "syllable"))
    {
      gregorio_message (_
			   ("unknown markup, syllable expected"),
			   "libgregorio_xml_read_file", WARNING, 0);
    }
  else
    {
      libgregorio_xml_read_syllable (current_node->xmlChildrenNode, doc,
				     (&current_syllable),
				     score->number_of_voices, alterations,
				     clefs);
    }
  score->first_syllable = current_syllable;
  current_node = current_node->next;
  while (current_node)
    {
      if (xmlStrcmp (current_node->name, (const xmlChar *) "syllable"))
	{
	  gregorio_message (_
			       ("unknown markup, syllable expected"),
			       "libgregorio_xml_read_file", WARNING, 0);
	}
      else
	{
	  libgregorio_xml_read_syllable (current_node->xmlChildrenNode, doc,
					 &(current_syllable),
					 score->number_of_voices, alterations,
					 clefs);
	}
      current_node = current_node->next;
    }
  xmlFreeDoc (doc);
  return score;
}

void
libgregorio_xml_read_score_attributes (xmlNodePtr current_node, xmlDocPtr doc,
				       gregorio_score * score)
{
  while (current_node)
    {
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "name"))
	{
	  score->name = (char *) xmlNodeListGetString
	    (doc, current_node->xmlChildrenNode, 1);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "license"))
	{
	  score->license = (char *) xmlNodeListGetString
	    (doc, current_node->xmlChildrenNode, 1);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "office-part"))
	{
	  score->office_part = (char *) xmlNodeListGetString
	    (doc, current_node->xmlChildrenNode, 1);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp
	  (current_node->name, (const xmlChar *) "lilypond-preamble"))
	{
	  score->lilypond_preamble = (char *) xmlNodeListGetString
	    (doc, current_node->xmlChildrenNode, 1);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp
	  (current_node->name, (const xmlChar *) "opustex-preamble"))
	{
	  score->opustex_preamble = (char *) xmlNodeListGetString
	    (doc, current_node->xmlChildrenNode, 1);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp
	  (current_node->name, (const xmlChar *) "musixtex-preamble"))
	{
	  score->musixtex_preamble = (char *) xmlNodeListGetString
	    (doc, current_node->xmlChildrenNode, 1);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp
	  (current_node->name, (const xmlChar *) "gregoriotex_font"))
	{
	  score->gregoriotex_font = (char *) xmlNodeListGetString
	    (doc, current_node->xmlChildrenNode, 1);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "initial-style"))
	{
	  score->initial_style = atoi ((char *) xmlNodeListGetString
			      (doc, current_node->xmlChildrenNode, 1));
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "mode"))
	{
	  score->mode = atoi ((char *) xmlNodeListGetString
			      (doc, current_node->xmlChildrenNode, 1));
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "voice-list"))
	{
	  libgregorio_xml_read_multi_voice_info (current_node->
						 xmlChildrenNode, doc, score);
	  break;
	}
      else
	{
	  score->number_of_voices = 1;
	  libgregorio_xml_read_mono_voice_info (current_node, doc, score);
	  break;

	}

    }

}

void
libgregorio_xml_read_multi_voice_info (xmlNodePtr current_node, xmlDocPtr doc,
				       gregorio_score * score)
{

  int number_of_voices = 0;
  gregorio_voice_info *voice_info;
  gregorio_add_voice_info (&score->first_voice_info);
  voice_info = score->first_voice_info;
  while (current_node)
    {
// todo : check if the voices are in order

      libgregorio_xml_read_voice_info (current_node->xmlChildrenNode, doc,
				       voice_info);
      gregorio_add_voice_info (&voice_info);
      number_of_voices++;
    }
  score->number_of_voices = number_of_voices;

}

void
libgregorio_xml_read_mono_voice_info (xmlNodePtr current_node, xmlDocPtr doc,
				      gregorio_score * score)
{

  gregorio_add_voice_info (&(score->first_voice_info));
  libgregorio_xml_read_voice_info (current_node, doc,
				   score->first_voice_info);
}

void
libgregorio_xml_read_voice_info (xmlNodePtr current_node, xmlDocPtr doc,
				 gregorio_voice_info * voice_info)
{

  while (current_node)
    {

      if (!xmlStrcmp (current_node->name, (const xmlChar *) "anotation"))
	{
	  voice_info->anotation = (char *) xmlNodeListGetString
	    (doc, current_node->xmlChildrenNode, 1);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "author"))
	{
	  voice_info->author = (char *) xmlNodeListGetString
	    (doc, current_node->xmlChildrenNode, 1);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "date"))
	{
	  voice_info->date = (char *) xmlNodeListGetString
	    (doc, current_node->xmlChildrenNode, 1);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "manuscript"))
	{
	  voice_info->manuscript = (char *) xmlNodeListGetString
	    (doc, current_node->xmlChildrenNode, 1);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "reference"))
	{
	  voice_info->reference = (char *) xmlNodeListGetString
	    (doc, current_node->xmlChildrenNode, 1);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "storage-place"))
	{
	  voice_info->storage_place = (char *) xmlNodeListGetString
	    (doc, current_node->xmlChildrenNode, 1);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "translator"))
	{
	  voice_info->translator = (char *) xmlNodeListGetString
	    (doc, current_node->xmlChildrenNode, 1);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp
	  (current_node->name, (const xmlChar *) "translation-date"))
	{
	  voice_info->translation_date = (char *) xmlNodeListGetString
	    (doc, current_node->xmlChildrenNode, 1);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "style"))
	{
	  voice_info->style = (char *) xmlNodeListGetString
	    (doc, current_node->xmlChildrenNode, 1);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp
	  (current_node->name, (const xmlChar *) "virgula-position"))
	{
	  voice_info->virgula_position = (char *) xmlNodeListGetString
	    (doc, current_node->xmlChildrenNode, 1);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "clef"))
	{
	  voice_info->initial_key =
	    libgregorio_xml_read_initial_key (current_node->xmlChildrenNode,
					      doc);
	}
      else
	{
	  gregorio_message (_
			       ("unknown markup, in attributes markup"),
			       "libgregorio_xml_read_file", WARNING, 0);
	}
      current_node = current_node->next;
    }

}

char
libgregorio_xml_read_bar (xmlNodePtr current_node, xmlDocPtr doc)
{
  if (xmlStrcmp (current_node->name, (const xmlChar *) "type"))
    {
      gregorio_message (_
			   ("unknown markup, in attributes markup"),
			   "libgregorio_xml_read_file", WARNING, 0);
      return 0;
    }
  current_node = current_node->xmlChildrenNode;
  if (!xmlStrcmp
      (xmlNodeListGetString (doc, current_node, 1),
       (const xmlChar *) "virgula"))
    {
      return B_VIRGULA;
    }
  if (!xmlStrcmp
      (xmlNodeListGetString (doc, current_node, 1),
       (const xmlChar *) "divisio-minima"))
    {
      return B_DIVISIO_MINIMA;
    }
  if (!xmlStrcmp
      (xmlNodeListGetString (doc, current_node, 1),
       (const xmlChar *) "divisio-minor"))
    {
      return B_DIVISIO_MINOR;
    }
  if (!xmlStrcmp
      (xmlNodeListGetString (doc, current_node, 1),
       (const xmlChar *) "divisio-maior"))
    {
      return B_DIVISIO_MAIOR;
    }
  if (!xmlStrcmp
      (xmlNodeListGetString (doc, current_node, 1),
       (const xmlChar *) "divisio-finalis"))
    {
      return B_DIVISIO_FINALIS;
    }
  return B_NO_BAR;
}

int
libgregorio_xml_read_initial_key (xmlNodePtr current_node, xmlDocPtr doc)
{
  char step = 0;
  int line = 0;
  libgregorio_xml_read_key (current_node, doc, &step, &line);
  return gregorio_calculate_new_key (step, line);
}

void
libgregorio_xml_read_key (xmlNodePtr current_node, xmlDocPtr doc, char *step,
			  int *line)
{
  xmlChar *step_temp;
  xmlChar *temp;

  while (current_node)
    {
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "step"))
	{
	  step_temp = xmlNodeListGetString
	    (doc, current_node->xmlChildrenNode, 1);
	  *step = ((char *) step_temp)[0];
	  if (((char *) step_temp)[1])
	    {
	      gregorio_message (_
				   ("too long step declaration"),
				   "libgregorio_xml_read_file", WARNING, 0);
	    }
	  xmlFree (step_temp);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "line"))
	{
	  temp = xmlNodeListGetString (doc, current_node->xmlChildrenNode, 1);
	  *line = atoi ((char *) temp);
	  xmlFree (temp);
	  current_node = current_node->next;
	  continue;
	}
      else
	{
	  gregorio_message (_
			       ("unknown markup, step or line expected"),
			       "libgregorio_xml_read_file", WARNING, 0);
	}
      current_node = current_node->next;
    }
  if (*step == 0 || !(*line))
    {
      gregorio_message (_
			   ("step or line markup missing in key declaration"),
			   "libgregorio_xml_read_file", WARNING, 0);
    }

}

void
libgregorio_xml_read_syllable (xmlNodePtr current_node, xmlDocPtr doc,
			       gregorio_syllable ** current_syllable,
			       int number_of_voices, char alterations[][13],
			       int clefs[])
{
  char step;
  int line;
  gregorio_element *current_element = NULL;

  gregorio_add_syllable (current_syllable, number_of_voices, NULL, NULL, NULL,
			    0);
  if (!xmlStrcmp (current_node->name, (const xmlChar *) "text"))
    {
// it is possible (and even often the case) that we don't have text
      libgregorio_xml_read_text (current_node, doc, *current_syllable);
      current_node = current_node->next;
    }

  if (!xmlStrcmp (current_node->name, (const xmlChar *) "translation"))
    {
// it is possible (and even often the case) that we don't have text
      libgregorio_xml_read_translation (current_node, doc, *current_syllable);
      current_node = current_node->next;
    }

//warning : we cannot do something like <syllable><bar>..</bar><neume>..
//TODO : implement it (not very difficult)
  if (xmlStrcmp (current_node->name, (const xmlChar *) "neume"))
    {
// or for every voice... I don't know if it really has a sense in polyphony
      while (current_node)
	{
	  if (!xmlStrcmp (current_node->name, (const xmlChar *) "bar"))
	    {
	      step =
		libgregorio_xml_read_bar (current_node->xmlChildrenNode, doc);
	      //here we use step, but it is juste to verify if we can really read the bar
	      if (step != 0)
		{

		  gregorio_add_special_as_element ((&current_element),
						      GRE_BAR, step, 0);
		  if (!((*current_syllable)->elements[0]))
		    {
// we need this to find the first element
		      (*current_syllable)->elements[0] = current_element;
		    }
		  gregorio_reinitialize_alterations (alterations,
							number_of_voices);
		}
	      current_node = current_node->next;
	      continue;
	    }
	  if (!xmlStrcmp
	      (current_node->name, (const xmlChar *) "clef-change"))
	    {
	      libgregorio_xml_read_key (current_node->xmlChildrenNode, doc,
					(&step), &(line));
	      if (step == 'c')
		{
		  gregorio_add_special_as_element ((&current_element),
						      GRE_C_KEY_CHANGE,
						      line + 48, 0);
		  if (!((*current_syllable)->elements[0]))
		    {
// we need this to find the first element
		      (*current_syllable)->elements[0] = current_element;
		    }
		  gregorio_reinitialize_alterations (alterations,
							number_of_voices);
		  clefs[0] = gregorio_calculate_new_key (step, line);
		}
	      if (step == 'f')
		{
		  gregorio_add_special_as_element ((&current_element),
						      GRE_F_KEY_CHANGE,
						      line + 48, 0);
		  if (!((*current_syllable)->elements[0]))
		    {
// we need this to find the first element
		      (*current_syllable)->elements[0] = current_element;
		    }
		  gregorio_reinitialize_alterations (alterations,
							number_of_voices);
		  clefs[0] = gregorio_calculate_new_key (step, line);
		}
	      else
		{
		  gregorio_message (_
				       ("unknown clef-change"),
				       "libgregorio_xml_read_syllable",
				       WARNING, 0);
		}
	      current_node = current_node->next;
	      continue;
	    }
	  gregorio_message (_
			       ("unknown markup in syllable"),
			       "libgregorio_xml_read_syllable", WARNING, 0);
	  current_node = current_node->next;
	  continue;
	}

      return;
    }

  if (number_of_voices == 1)
    {
      libgregorio_xml_read_mono_neumes (current_node, doc, *current_syllable,
					alterations, clefs);
    }
  else
    {
      libgregorio_xml_read_multi_neumes (current_node, doc, *current_syllable,
					 number_of_voices, alterations,
					 clefs);
    }
}

char
libgregorio_xml_read_position (char *position)
{
  if (!strcmp (position, "beginning"))
    {
      return WORD_BEGINNING;
    }
  if (!strcmp (position, "one-syllable"))
    {
      return WORD_ONE_SYLLABLE;
    }
  if (!strcmp (position, "middle"))
    {
      return WORD_MIDDLE;
    }
  if (!strcmp (position, "end"))
    {
      return WORD_END;
    }
  else
    {
      gregorio_message (_
			   ("text position unrecognized"),
			   "libgregorio_xml_read_text", WARNING, 0);
      return WORD_ONE_SYLLABLE;
    }
}

void libgregorio_xml_read_styled_text (xmlNodePtr current_node, xmlDocPtr doc,
				       gregorio_character **
				       current_character);

void
libgregorio_xml_read_text (xmlNodePtr current_node, xmlDocPtr doc,
			   gregorio_syllable * syllable)
{

  char *temp;
  gregorio_character *current_character = NULL;

  temp = (char *) xmlGetProp (current_node, (const xmlChar *) "position");
  if (!temp)
    {
      gregorio_message (_
			   ("position attribute missing, assuming beginning"),
			   "libgregorio_xml_read_syllable", WARNING, 0);
      syllable->position = WORD_ONE_SYLLABLE;	//TODO: better gestion of word position
      return;
    }
  syllable->position = libgregorio_xml_read_position (temp);
  free (temp);
  libgregorio_xml_read_styled_text (current_node->xmlChildrenNode, doc,
				    &current_character);
  gregorio_go_to_first_character (&current_character);
  syllable->text = current_character;
}

void
libgregorio_xml_read_translation (xmlNodePtr current_node, xmlDocPtr doc,
			   gregorio_syllable * syllable)
{
  gregorio_character *current_character = NULL;

  libgregorio_xml_read_styled_text (current_node->xmlChildrenNode, doc,
				    &current_character);
  gregorio_go_to_first_character (&current_character);
  syllable->translation = current_character;
}

void
libgregorio_xml_read_styled_text (xmlNodePtr current_node, xmlDocPtr doc,
				  gregorio_character ** current_character)
{

  while (current_node)
    {
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "str"))
	{
	  gregorio_add_text ((char *) xmlNodeListGetString
				(doc, current_node->xmlChildrenNode, 1),
				current_character);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "center"))
	{
	  gregorio_begin_style (current_character, ST_CENTER);
	  libgregorio_xml_read_styled_text (current_node->xmlChildrenNode,
					    doc, current_character);
	  gregorio_end_style (current_character, ST_CENTER);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "italic"))
	{
	  gregorio_begin_style (current_character, ST_ITALIC);
	  libgregorio_xml_read_styled_text (current_node->xmlChildrenNode,
					    doc, current_character);
	  gregorio_end_style (current_character, ST_ITALIC);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "bold"))
	{
	  gregorio_begin_style (current_character, ST_BOLD);
	  libgregorio_xml_read_styled_text (current_node->xmlChildrenNode,
					    doc, current_character);
	  gregorio_end_style (current_character, ST_BOLD);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "tt"))
	{
	  gregorio_begin_style (current_character, ST_TT);
	  libgregorio_xml_read_styled_text (current_node->xmlChildrenNode,
					    doc, current_character);
	  gregorio_end_style (current_character, ST_TT);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "small-capitals"))
	{
	  gregorio_begin_style (current_character, ST_SMALL_CAPS);
	  libgregorio_xml_read_styled_text (current_node->xmlChildrenNode,
					    doc, current_character);
	  gregorio_end_style (current_character, ST_SMALL_CAPS);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp
	  (current_node->name, (const xmlChar *) "special-character"))
	{
	  gregorio_begin_style (current_character, ST_SPECIAL_CHAR);
	  libgregorio_xml_read_styled_text (current_node->xmlChildrenNode,
					    doc, current_character);
	  gregorio_end_style (current_character, ST_SPECIAL_CHAR);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "verbatim"))
	{
	  gregorio_begin_style (current_character, ST_VERBATIM);
	  libgregorio_xml_read_styled_text (current_node->xmlChildrenNode,
					    doc, current_character);
	  gregorio_end_style (current_character, ST_VERBATIM);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "initial"))
	{
	  gregorio_begin_style (current_character, ST_INITIAL);
	  libgregorio_xml_read_styled_text (current_node->xmlChildrenNode,
					    doc, current_character);
	  gregorio_end_style (current_character, ST_INITIAL);
	  current_node = current_node->next;
	  continue;
	}
      else
	{
	  current_node = current_node->next;
	}
    }
}


void
libgregorio_xml_read_mono_neumes (xmlNodePtr current_node, xmlDocPtr doc,
				  gregorio_syllable * syllable,
				  char alterations[][13], int clefs[])
{
  if (xmlStrcmp (current_node->name, (const xmlChar *) "neume"))
    {
      gregorio_message (_
			   ("unknown markup, expecting neume"),
			   "libgregorio_xml_read_syllable", WARNING, 0);
      return;
    }
  libgregorio_xml_read_elements (current_node->xmlChildrenNode, doc,
				 syllable->elements, alterations[0], clefs);
}

void
libgregorio_xml_read_multi_neumes (xmlNodePtr current_node, xmlDocPtr doc,
				   gregorio_syllable * syllable,
				   int number_of_voices,
				   char alterations[][13], int clefs[])
{
  int i;
  if (xmlStrcmp (current_node->name, (const xmlChar *) "neume"))
    {
      gregorio_message (_
			   ("unknown markup, expecting neume"),
			   "libgregorio_xml_read_syllable", WARNING, 0);
      return;
    }
//TODO : check the order of the voices
  for (i = 0; i < number_of_voices; i++)
    {
      libgregorio_xml_read_elements (current_node->xmlChildrenNode, doc,
				     syllable->elements + i, alterations[i],
				     clefs + i);
      current_node = current_node->next;
    }
}

void
libgregorio_xml_read_elements (xmlNodePtr current_node, xmlDocPtr doc,
			       gregorio_element ** first_element,
			       char alterations[13], int *key)
{
  gregorio_element *current_element = NULL;

  libgregorio_xml_read_element (current_node, doc, &(current_element),
				alterations, key);
  (*first_element) = current_element;
  current_node = current_node->next;
  while (current_node)
    {
      libgregorio_xml_read_element (current_node, doc, &(current_element),
				    alterations, key);
      current_node = current_node->next;
    }
}

void
libgregorio_xml_read_element (xmlNodePtr current_node, xmlDocPtr doc,
			      gregorio_element ** current_element,
			      char alterations[13], int *key)
{
  char step;
  int line;

  if (!xmlStrcmp (current_node->name, (const xmlChar *) "neumatic-bar"))
    {
      step = libgregorio_xml_read_bar (current_node->xmlChildrenNode, doc);
      //here we use step, but it is juste to verify if we can really read the bar
      if (step != 0)
	{

	  gregorio_add_special_as_element (current_element, GRE_BAR, step, 0);
	  gregorio_reinitialize_one_voice_alterations (alterations);
	}
      return;
    }
	  if (!xmlStrcmp (current_node->name, (const xmlChar *) "custo"))
	    {
	  step =
	    libgregorio_xml_read_pitch
	    (current_node->xmlChildrenNode->xmlChildrenNode, doc, *key);
		  gregorio_add_special_as_element (current_element,
						      GRE_CUSTO, step, 0);
	    }
  if (!xmlStrcmp (current_node->name, (const xmlChar *) "clef-change"))
    {
      libgregorio_xml_read_key (current_node->xmlChildrenNode, doc,
				(&step), &(line));
      if (step == 'c')
	{
	  gregorio_add_special_as_element (current_element,
					      GRE_C_KEY_CHANGE, line + 48, 0);
	  gregorio_reinitialize_one_voice_alterations (alterations);
	  *key = gregorio_calculate_new_key (step, line);
	}
      if (step == 'f')
	{
	  gregorio_add_special_as_element (current_element,
					      GRE_F_KEY_CHANGE, line + 48, 0);
	  gregorio_reinitialize_one_voice_alterations (alterations);
	  *key = gregorio_calculate_new_key (step, line);
	}
      else
	{
	  gregorio_message (_
			       ("unknown clef-change"),
			       "libgregorio_xml_read_element", WARNING, 0);
	}
      return;
    }
  if (!xmlStrcmp
      (current_node->name, (const xmlChar *) "larger-neumatic-space"))
    {
      gregorio_add_special_as_element (current_element,
					  GRE_SPACE, SP_LARGER_SPACE, 0);
      return;
    }
  if (!xmlStrcmp (current_node->name, (const xmlChar *) "end-of-line"))
    {
      gregorio_add_special_as_element (current_element,
					  GRE_END_OF_LINE, USELESS_VALUE, 0);
      return;
    }
  if (!xmlStrcmp (current_node->name, (const xmlChar *) "glyph-space"))
    {
      gregorio_add_special_as_element (current_element,
					  GRE_SPACE, SP_GLYPH_SPACE, 0);
      return;
    }

  if (!xmlStrcmp (current_node->name, (const xmlChar *) "element"))
    {
      gregorio_add_element (current_element, NULL);
      libgregorio_xml_read_glyphs (current_node->xmlChildrenNode, doc,
				   (*current_element), alterations, *key);
      return;
    }
  gregorio_message (_
		       ("unknown markup"),
		       "libgregorio_xml_read_element", WARNING, 0);

}

void
libgregorio_xml_read_glyphs (xmlNodePtr current_node, xmlDocPtr doc,
			     gregorio_element * element, char alterations[13],
			     int key)
{
  gregorio_glyph *current_glyph = NULL;
  char step;

  while (current_node)
    {
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "flat"))
	{
	  step =
	    libgregorio_xml_read_alteration (current_node->xmlChildrenNode,
					     doc, key);
	  gregorio_add_special_as_glyph (&current_glyph, GRE_FLAT, step, 0);
	  alterations[(int) step - 48] = FLAT;
	  current_node = current_node->next;
	  continue;
	}

      if (!xmlStrcmp (current_node->name, (const xmlChar *) "natural"))
	{
	  step =
	    libgregorio_xml_read_alteration (current_node->xmlChildrenNode,
					     doc, key);
	  gregorio_add_special_as_glyph (&current_glyph, GRE_NATURAL,
					    step, 0);
	  alterations[(int) step - 48] = NO_ALTERATION;
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp
	  (current_node->name, (const xmlChar *) "zero-width-space"))
	{
	  gregorio_add_special_as_glyph (&current_glyph, GRE_SPACE,
					    SP_ZERO_WIDTH, 0);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "glyph"))
	{
	  libgregorio_xml_read_glyph (current_node->xmlChildrenNode, doc,
				      (&current_glyph), key);
	  current_node = current_node->next;
	  continue;
	}
      gregorio_message (_
			   ("unknown markup"),
			   "libgregorio_xml_read_glyphs", WARNING, 0);

      current_node = current_node->next;
    }
  gregorio_go_to_first_glyph (&current_glyph);
  element->first_glyph = current_glyph;
}

// TODO : verify that il handles flats well

void
libgregorio_xml_read_glyph (xmlNodePtr current_node, xmlDocPtr doc,
			    gregorio_glyph ** current_glyph, int key)
{
  char liquescentia = L_NO_LIQUESCENTIA;
  xmlChar *temp;
  gregorio_note *current_note = NULL;

  gregorio_add_glyph (current_glyph, G_UNDETERMINED,
			 NULL, L_NO_LIQUESCENTIA);
  if (!xmlStrcmp (current_node->name, (const xmlChar *) "type"))
    {
      temp = xmlNodeListGetString (doc, current_node->xmlChildrenNode, 1);
      (*current_glyph)->glyph_type =
	libgregorio_xml_read_glyph_type ((char *) temp);
      xmlFree (temp);
      current_node = current_node->next;
    }
  else
    {
      gregorio_message (_
			   ("type missing in glyph markup"),
			   "libgregorio_xml_read_glyph", ERROR, 0);
//TODO : mechanism to determine the glyph ?
      return;
    }

  while (current_node)
    {
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "note"))
	{
	  libgregorio_xml_read_note (current_node->xmlChildrenNode, doc,
				     (&current_note), key);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "figura"))
	{
	  liquescentia = liquescentia +
	    libgregorio_xml_read_figura ((char *)
					 xmlNodeListGetString (doc,
							       current_node->
							       xmlChildrenNode,
							       1));
//bug if two <figura>, but wrong anyway

	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "initio-debilis"))
	{
	  liquescentia = liquescentia + L_INITIO_DEBILIS;
//bug if two <figura>, but wrong anyway

	  current_node = current_node->next;
	  continue;
	}

      gregorio_message (_
			   ("unknown markup, expecting note"),
			   "libgregorio_xml_read_glyph", ERROR, 0);

      current_node = current_node->next;
    }
  gregorio_go_to_first_note (&(current_note));
  (*current_glyph)->first_note = current_note;
  (*current_glyph)->liquescentia = liquescentia;
}

char
libgregorio_xml_read_alteration (xmlNodePtr current_node, xmlDocPtr doc,
				 int key)
{
  char *step_temp;
  char step = 0;
  int octave = 0;

  while (current_node)
    {
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "step"))
	{
	  step_temp = (char *) xmlNodeListGetString
	    (doc, current_node->xmlChildrenNode, 1);
	  step = step_temp[0];
	  if (step_temp[1])
	    {
	      gregorio_message (_
				   ("too long step declaration"),
				   "libgregorio_xml_read_alteration", WARNING,
				   0);
	    }
	  free (step_temp);
	  current_node = current_node->next;
	  continue;
	}

      if (!xmlStrcmp (current_node->name, (const xmlChar *) "octave"))
	{
	  step_temp = (char *) xmlNodeListGetString
	    (doc, current_node->xmlChildrenNode, 1);
	  octave = atoi (step_temp);
	  free (step_temp);
	  current_node = current_node->next;
	  continue;
	}
      gregorio_message (_
			   ("unknown markup"),
			   "libgregorio_xml_read_alteration", WARNING, 0);
      current_node = current_node->next;
    }
  if (step == 0 || !octave)
    {
      gregorio_message (_
			   ("step or line markup missing in alteration declaration"),
			   "libgregorio_xml_read_alteration", WARNING, 0);
      return 0;
    }

  return gregorio_det_pitch (key, step, octave);

}

char
libgregorio_xml_read_glyph_type (char *type)
{
  if (!type)
    {
      gregorio_message
	(_("empty glyph type markup"), "libgregorio_xml_read_glyph_type",
	 ERROR, 0);
      return G_NO_GLYPH;
    }
  if (!strcmp (type, "punctum-inclinatum"))
    {
      return G_PUNCTUM_INCLINATUM;
    }
  if (!strcmp (type, "2-puncta-inclinata-descendens"))
    {
      return G_2_PUNCTA_INCLINATA_DESCENDENS;
    }
  if (!strcmp (type, "3-puncta-inclinata-descendens"))
    {
      return G_3_PUNCTA_INCLINATA_DESCENDENS;
    }
  if (!strcmp (type, "4-puncta-inclinata-descendens"))
    {
      return G_4_PUNCTA_INCLINATA_DESCENDENS;
    }
  if (!strcmp (type, "5-puncta-inclinata-descendens"))
    {
      return G_5_PUNCTA_INCLINATA_DESCENDENS;
    }
  if (!strcmp (type, "2-puncta-inclinata-ascendens"))
    {
      return G_2_PUNCTA_INCLINATA_ASCENDENS;
    }
  if (!strcmp (type, "3-puncta-inclinata-ascendens"))
    {
      return G_3_PUNCTA_INCLINATA_ASCENDENS;
    }
  if (!strcmp (type, "4-puncta-inclinata-ascendens"))
    {
      return G_4_PUNCTA_INCLINATA_ASCENDENS;
    }
  if (!strcmp (type, "5-puncta-inclinata-ascendens"))
    {
      return G_5_PUNCTA_INCLINATA_ASCENDENS;
    }
  if (!strcmp (type, "trigonus"))
    {
      return G_TRIGONUS;
    }
  if (!strcmp (type, "puncta-inclinata"))
    {
      return G_PUNCTA_INCLINATA;
    }
  if (!strcmp (type, "virga"))
    {
      return G_VIRGA;
    }
  if (!strcmp (type, "stropha"))
    {
      return G_STROPHA;
    }
  if (!strcmp (type, "punctum"))
    {
      return G_PUNCTUM;
    }
  if (!strcmp (type, "podatus"))
    {
      return G_PODATUS;
    }
  if (!strcmp (type, "flexa"))
    {
      return G_FLEXA;
    }
  if (!strcmp (type, "torculus"))
    {
      return G_TORCULUS;
    }
  if (!strcmp (type, "torculus-resupinus"))
    {
      return G_TORCULUS_RESUPINUS;
    }
  if (!strcmp (type, "torculus-resupinus-flexus"))
    {
      return G_TORCULUS_RESUPINUS_FLEXUS;
    }
  if (!strcmp (type, "porrectus"))
    {
      return G_PORRECTUS;
    }
  if (!strcmp (type, "porrectus-flexus"))
    {
      return G_PORRECTUS_FLEXUS;
    }
  if (!strcmp (type, "bivirga"))
    {
      return G_BIVIRGA;
    }
  if (!strcmp (type, "trivirga"))
    {
      return G_TRIVIRGA;
    }
  if (!strcmp (type, "distropha"))
    {
      return G_DISTROPHA;
    }
  if (!strcmp (type, "tristropha"))
    {
      return G_TRISTROPHA;
    }
  if (!strcmp (type, "scandicus"))
    {
      return G_SCANDICUS;
    }
  if (!strcmp (type, "ancus"))
    {
      return G_ANCUS;
    }
  gregorio_message
    (_("unknown glyph type"), "libgregorio_xml_read_glyph_type", ERROR, 0);
  return G_NO_GLYPH;
}


char
libgregorio_xml_read_figura (char *liquescentia)
{
  if (!strcmp (liquescentia, "deminutus"))
    {
      return L_DEMINUTUS;
    }
  if (!strcmp (liquescentia, "auctus-descendens"))
    {
      return L_AUCTUS_DESCENDENS;
    }
  if (!strcmp (liquescentia, "auctus-ascendens"))
    {
      return L_AUCTUS_ASCENDENS;
    }
  if (!strcmp (liquescentia, "auctus"))
    {
      return L_AUCTA;
    }
  gregorio_message
    (_("unknown liquescentia"), "libgregorio_xml_read_liquescentia", WARNING,
     0);
  return L_NO_LIQUESCENTIA;
}

void
  libgregorio_xml_read_note
  (xmlNodePtr
   current_node, xmlDocPtr doc, gregorio_note ** current_note, int key)
{
  char pitch = 0;
  char liquescentia = L_NO_LIQUESCENTIA;
  char shape = S_UNDETERMINED;
  char signs = _NO_SIGN;
  char h_episemus = H_NO_EPISEMUS;
  char rare_sign=_NO_SIGN;
  xmlChar *temp;

  while (current_node)
    {
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "pitch"))
	{
	  pitch =
	    libgregorio_xml_read_pitch
	    (current_node->xmlChildrenNode, doc, key);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "shape"))
	{
	  temp = xmlNodeListGetString (doc, current_node->xmlChildrenNode, 1);
	  shape = libgregorio_xml_read_shape ((char *) temp);
	  xmlFree (temp);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "signs"))
	{
	  signs =
	    libgregorio_xml_read_signs
	    (current_node->xmlChildrenNode, doc, &h_episemus, &rare_sign);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp
	  (current_node->name, (const xmlChar *) "multi-h-episemus"))
	{
	  libgregorio_xml_read_h_episemus (current_node, (&h_episemus));
	  current_node = current_node->next;
	  continue;
	}
      gregorio_message
	(_("unknown markup, ignored"), "libgregorio_read_note", WARNING, 0);
      current_node = current_node->next;
      continue;
    }
  if (pitch == 0 || shape == S_UNDETERMINED)
    {
      gregorio_message
	(_("missing pitch or shape in note"), "libgregorio_read_note",
	 WARNING, 0);

    }
  else
    {
//TODO : better understanding of liquescentia
      gregorio_add_note (current_note, pitch, shape, signs, liquescentia,
			    h_episemus);
      gregorio_add_special_sign (*current_note, rare_sign);
    }

}

char
libgregorio_xml_read_pitch (xmlNodePtr current_node, xmlDocPtr doc, int key)
{
  char *step_temp;
  char step = 0;
  int octave = 0;

  while (current_node)
    {
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "step"))
	{
	  step_temp = (char *) xmlNodeListGetString
	    (doc, current_node->xmlChildrenNode, 1);
	  step = step_temp[0];
	  if (step_temp[1])
	    {
	      gregorio_message (_
				   ("too long step declaration"),
				   "libgregorio_xml_read_alteration", WARNING,
				   0);
	    }
	  free (step_temp);
	  current_node = current_node->next;
	  continue;
	}

      if (!xmlStrcmp (current_node->name, (const xmlChar *) "octave"))
	{
	  step_temp = (char *) xmlNodeListGetString
	    (doc, current_node->xmlChildrenNode, 1);
	  octave = atoi (step_temp);
	  free (step_temp);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "flated"))
	{
	  //TODO : add the flat glyph before the current_glyph
	  current_node = current_node->next;
	  continue;
	}
      gregorio_message (_
			   ("unknown markup"),
			   "libgregorio_xml_read_alteration", WARNING, 0);
      current_node = current_node->next;
    }
  if (step == 0 || !octave)
    {
      gregorio_message (_
			   ("step or line markup missing in alteration declaration"),
			   "libgregorio_xml_read_alteration", WARNING, 0);
      return 0;
    }

  return gregorio_det_pitch (key, step, octave);

}

void
libgregorio_xml_read_h_episemus (xmlNodePtr current_node, char *h_episemus)
{
  char *position =
    (char *) xmlGetProp (current_node, (const xmlChar *) "position");
  if (strcmp (position, "beginning"))
    {
      *h_episemus = H_MULTI_BEGINNING;
      free (position);
      return;
    }
  if (strcmp (position, "middle"))
    {
      *h_episemus = H_MULTI_MIDDLE;
      free (position);
      return;
    }
  if (strcmp (position, "end"))
    {
      *h_episemus = H_MULTI_END;
      free (position);
      return;
    }
  if (!position)
    {
      gregorio_message
	(_("position attribute missing in multi-h-episemus"),
	 "libgregorio_xml_read_h_episemus", WARNING, 0);
      return;
    }
  gregorio_message
    (_("unknown position attribute in multi-h-episemus"),
     "libgregorio_xml_read_h_episemus", WARNING, 0);
  free (position);
}

char
libgregorio_xml_read_shape (char *type)
{
  if (!strcmp (type, "punctum"))
    {
      return S_PUNCTUM;
    }
  if (!strcmp (type, "punctum_inclinatum"))
    {
      return S_PUNCTUM_INCLINATUM;
    }
  if (!strcmp (type, "punctum_inclinatum_deminutus"))
    {
      return S_PUNCTUM_INCLINATUM_DEMINUTUS;
    }
  if (!strcmp (type, "punctum_inclinatum_auctus"))
    {
      return S_PUNCTUM_INCLINATUM_AUCTUS;
    }
  if (!strcmp (type, "virga"))
    {
      return S_VIRGA;
    }
  if (!strcmp (type, "oriscus"))
    {
      return S_ORISCUS;
    }
  if (!strcmp (type, "oriscus_auctus"))
    {
      return S_ORISCUS_AUCTUS;
    }
  if (!strcmp (type, "quilisma"))
    {
      return S_QUILISMA;
    }
  if (!strcmp (type, "stropha"))
    {
      return S_STROPHA;
    }
  if (!strcmp (type, "punctum_cavum"))
    {
      return S_PUNCTUM_CAVUM;
    }
  if (!strcmp (type, "linea_punctum"))
    {
      return S_LINEA_PUNCTUM;
    }
  if (!strcmp (type, "linea_punctum_cavum"))
    {
      return S_LINEA_PUNCTUM_CAVUM;
    }
  gregorio_message
    (_
     ("unknown shape, punctum assumed"),
     "libgregorio_read_shape", WARNING, 0);
  return S_PUNCTUM;
}

// returns signs
// sets rare_sign
char
libgregorio_xml_read_signs (xmlNodePtr current_node, xmlDocPtr doc,
			    char *h_episemus, char *rare_sign)
{
  xmlChar *temp;
  char signs = _NO_SIGN;

  while (current_node)
    {
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "right"))
	{
	  temp = xmlNodeListGetString (doc, current_node->xmlChildrenNode, 1);
	  if (!xmlStrcmp (temp, (const xmlChar *) "auctum"))
	    {
	      signs = signs + _PUNCTUM_MORA;
//TODO : bug if two times <right>, but it would be bad XML anyway...
	      current_node = current_node->next;
	      xmlFree (temp);
	      continue;
	    }
	  if (!xmlStrcmp (temp, (const xmlChar *) "auctum-duplex"))
	    {
	      signs = signs + _AUCTUM_DUPLEX;
	      current_node = current_node->next;
	      xmlFree (temp);
	      continue;
	    }
	  gregorio_message
	    (_
	     ("unknown right sign"),
	     "libgregorio_xml_read_signs", WARNING, 0);
	  xmlFree (temp);
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "top"))
	{
	  if (*h_episemus == H_NO_EPISEMUS)
	    {
	      *h_episemus = H_ALONE;
//TODO : better understanding of h_episemus
	    }
	  current_node = current_node->next;
	  continue;
	}
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "bottom"))
	{
	  signs = signs + _V_EPISEMUS;
	  current_node = current_node->next;
	  continue;
	}
	// rare signs (accentus, etc.)
      if (!xmlStrcmp (current_node->name, (const xmlChar *) "above"))
	{
	  temp = xmlNodeListGetString (doc, current_node->xmlChildrenNode, 1);
	  if (!xmlStrcmp (temp, (const xmlChar *) "accentus"))
	    {
	      *rare_sign = _ACCENTUS;
	      current_node = current_node->next;
	      xmlFree (temp);
	      continue;
	    }
	  if (!xmlStrcmp (temp, (const xmlChar *) "reversed_accentus"))
	    {
	      *rare_sign = _ACCENTUS_REVERSUS;
	      current_node = current_node->next;
	      xmlFree (temp);
	      continue;
	    }
	  if (!xmlStrcmp (temp, (const xmlChar *) "circulus"))
	    {
	      *rare_sign = _CIRCULUS;
	      current_node = current_node->next;
	      xmlFree (temp);
	      continue;
	    }
	  if (!xmlStrcmp (temp, (const xmlChar *) "semi_circulus"))
	    {
	      *rare_sign = _SEMI_CIRCULUS;
	      current_node = current_node->next;
	      xmlFree (temp);
	      continue;
	    }
	  if (!xmlStrcmp (temp, (const xmlChar *) "reversed_semi_circulus"))
	    {
	      *rare_sign = _SEMI_CIRCULUS_REVERSUS;
	      current_node = current_node->next;
	      xmlFree (temp);
	      continue;
	    }
	  gregorio_message
	    (_
	     ("unknown above sign"),
	     "libgregorio_xml_read_signs", WARNING, 0);
	  xmlFree (temp);
	  current_node = current_node->next;
	  continue;
	}
      gregorio_message
	(_
	 ("unknown sign"),
	 "libgregorio_xml_read_signs", WARNING, 0);
      current_node = current_node->next;
    }
  return signs;
}

#include <gregorio/plugin.h>

DECLARE_PLUGIN(xml)
{
    .id = "xml",
    .name = "GregorioXML",
    .description = "GregorioXML input/output plugin",
    .author = "Elie Roux <elie.roux@enst-bretagne.fr>",

    .file_extension = "xml",

    .type = GREGORIO_PLUGIN_BOTH,

    .read = read_score,
    .write = write_score
};

