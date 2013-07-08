/*
 * Gregorio xml output format. Copyright (C) 2006-2009 Elie Roux
 * <elie.roux@telecom-bretagne.eu>
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
#include <stdlib.h>
#include <stdio.h>
#include <gregorio/struct.h>
#include <gregorio/unicode.h>
#include <gregorio/characters.h>
#include <gregorio/messages.h>
#if ALL_STATIC == 0
#include <gregorio/plugin.h>
#endif

#include "xml.h"

#if ALL_STATIC == 0
DECLARE_PLUGIN (xml)
{
  .id = "xml",.name = "GregorioXML",.description =
    "GregorioXML input/output plugin",.author =
    "Elie Roux <elie.roux@enst-bretagne.fr>",.file_extension = "xml",
#if ENABLE_XML == 1
    .type = GREGORIO_PLUGIN_BOTH,.read = read_score,
#else
    .type = GREGORIO_PLUGIN_OUTPUT,
#endif
.write = write_score};
#endif

#define write_note(shape) xml_write_note(f, note->signs, step, octave, shape, note->h_episemus_type, alteration, note->rare_sign, note->texverb)

void
xml_write_gregorio_note (FILE *f, gregorio_note *note, int clef,
                         char alterations[])
{
  char step;
  int octave;
  char alteration;

  if (!f)
    {
      gregorio_message (_
                        ("call with NULL file"),
                        "gregoriotex_write_score", ERROR, 0);
      return;
    }

  if (!note)
    {
      gregorio_message (_("call with NULL argument"),
                        "xml_write_gregorio_note", ERROR, 0);
      return;
    }
  if (note->type != GRE_NOTE)
    {
      gregorio_message (_
                        ("call with argument which type is not GRE_NOTE, wrote nothing"),
                        "xml_write_gregorio_note", ERROR, 0);
      return;
    }
  gregorio_determine_h_episemus_type (note);
  gregorio_set_octave_and_step_from_pitch (&step, &octave, note->pitch, clef);
  alteration = alterations[(note->pitch) - 'a'];

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
xml_write_gregorio_glyph (FILE *f, gregorio_glyph *glyph,
                          int clef, char alterations[])
{
  const char *type;
  gregorio_note *current_note;

  if (!glyph)
    {
      gregorio_message (_("call with NULL argument"),
                        "xml_write_gregorio_glyph", ERROR, 0);
      return;
    }
  if (is_alteration (glyph->type))
    {
      xml_write_alteration (f, glyph->type, glyph->glyph_type,
                            clef, alterations);
      return;
    }
  if (glyph->type == GRE_SPACE && glyph->glyph_type == SP_ZERO_WIDTH)
    {
      fprintf (f, "<zero-width-space />");
      return;
    }
  if (glyph->type == GRE_TEXVERB_GLYPH)
    {
      if (glyph->texverb)
        {
          fprintf (f, "<texverb-glyph>%s</texverb-glyph>", glyph->texverb);
        }
      return;
    }
  if (glyph->type != GRE_GLYPH)
    {
      gregorio_message (_("call with an argument which type is unknown"),
                        "xml_write_gregorio_glyph", ERROR, 0);
      return;
    }
  type = xml_glyph_type_to_str (glyph->glyph_type);
  fprintf (f, "<glyph><type>%s</type>", type);
  xml_write_liquescentia (f, glyph->liquescentia);
  current_note = glyph->first_note;
  while (current_note)
    {
      xml_write_gregorio_note (f, current_note, clef, alterations);
      current_note = current_note->next;
    }
  fprintf (f, "</glyph>");
}

void
xml_write_gregorio_element (FILE *f, gregorio_element *element,
                            int *clef, char alterations[])
{
  gregorio_glyph *current_glyph;

  if (!element)
    {
      gregorio_message (_("call with NULL argument"),
                        "xml_write_gregorio_element", ERROR, 0);
      return;
    }
  if (element->type == GRE_ELEMENT)
    {
      fprintf (f, "<element>");
      current_glyph = element->first_glyph;
      while (current_glyph)
        {
          xml_write_gregorio_glyph (f, current_glyph, *clef, alterations);
          current_glyph = current_glyph->next;
        }
      fprintf (f, "</element>");
      return;
    }
  if (element->type == GRE_SPACE)
    {
      xml_write_space (f, element->element_type);
      return;
    }
  if (element->type == GRE_TEXVERB_ELEMENT)
    {
      if (element->texverb)
        {
          fprintf (f, "<texverb-element>%s</texverb-element>",
                   element->texverb);
        }
      return;
    }
  if (element->type == GRE_BAR)
    {
      gregorio_reinitialize_one_voice_alterations (alterations);
      fprintf (f, "<neumatic-bar>");
      xml_write_bar (f, element->element_type, element->additional_infos);
      fprintf (f, "</neumatic-bar>");
      return;
    }
  if (element->type == GRE_CUSTO)
    {
      fprintf (f, "<custo>");
      xml_write_pitch (f, element->element_type, *clef);
      fprintf (f, "</custo>");
      return;
    }
  if (element->type == GRE_END_OF_LINE)
    {
      fprintf (f, "<end-of-line />");
      return;
    }
  if (element->type == GRE_C_KEY_CHANGE)
    {
      *clef = gregorio_calculate_new_key (C_KEY, element->element_type - 48);
      xml_write_key_change (f, C_KEY, element->element_type - 48);
      return;
    }
  if (element->type == GRE_F_KEY_CHANGE)
    {
      *clef = gregorio_calculate_new_key (F_KEY, element->element_type - 48);
      xml_write_key_change (f, F_KEY, element->element_type - 48);
      return;
    }

  gregorio_message (_("call with an argument which type is unknown"),
                    "xml_write_gregorio_element", ERROR, 0);

}

void
xml_write_space (FILE *f, char type)
{
  switch (type)
    {
    case SP_LARGER_SPACE:
      fprintf (f, "<larger-neumatic-space />");
      break;
    case SP_GLYPH_SPACE:
      fprintf (f, "<glyph-space />");
      break;
    case SP_GLYPH_SPACE_NB:
      fprintf (f, "<unbreakable-glyph-space />");
      break;
    case SP_LARGER_SPACE_NB:
      fprintf (f, "<unbreakable-larger-neumatic-space />");
      break;
    case SP_NEUMATIC_CUT_NB:
      fprintf (f, "<unbreakable-neumatic-cut />");
      break;
    case SP_NEUMATIC_CUT:
      // we do not write neumatic cuts, they juste delimit elements
      break;
    default:
      gregorio_message (_("space type is unknown"),
                        "xml_write_space", ERROR, 0);
      break;
    }
}

void
xml_write_bar (FILE *f, char type, char signs)
{
  const char *str;
  str = xml_bar_to_str (type);
  fprintf (f, "<type>%s</type>", str);
  switch (signs)
    {
    case _V_EPISEMUS:
      fprintf (f, "<signs>vertical-episemus</signs>");
      break;
    case _V_EPISEMUS_ICTUS_A:
      fprintf (f, "<signs>vertical-episemus-ictus-a</signs>");
      break;
    case _V_EPISEMUS_ICTUS_T:
      fprintf (f, "<signs>vertical-episemus-ictus-t</signs>");
      break;
    default:
      break;
    }
}

void
xml_write_key_change (FILE *f, char step, int line)
{
  fprintf (f,
           "<clef-change><step>%c</step><line>%d</line></clef-change>",
           step, line);
}

void
xml_write_key_change_in_polyphony (FILE *f, char step, int line, int voice)
{
  fprintf (f,
           "<clef-change voice=\"%d\"><step>%c</step><line>%d</line></clef-change>",
           voice, step, line);
}

char in_text = 0;

void
xml_write_begin (FILE *f, unsigned char style)
{
  if (in_text)
    {
      fprintf (f, "</str>");
      in_text = 0;
    }
  switch (style)
    {
    case ST_ITALIC:
      fprintf (f, "<italic>");
      break;
    case ST_SMALL_CAPS:
      fprintf (f, "<small-caps>");
      break;
    case ST_INITIAL:
      fprintf (f, "<initial>");
      break;
    case ST_BOLD:
      fprintf (f, "<bold>");
      break;
    case ST_FORCED_CENTER:
    case ST_CENTER:
      fprintf (f, "<center>");
      break;
    case ST_TT:
      fprintf (f, "<tt>");
      break;
    case ST_UNDERLINED:
      fprintf (f, "<ul>");
      break;
    default:
      break;
    }
}

void
xml_write_end (FILE *f, unsigned char style)
{
  if (in_text)
    {
      fprintf (f, "</str>");
      in_text = 0;
    }
  switch (style)
    {
    case ST_ITALIC:
      fprintf (f, "</italic>");
      break;
    case ST_SMALL_CAPS:
      fprintf (f, "</small-caps>");
      break;
    case ST_INITIAL:
      fprintf (f, "</initial>");
      break;
    case ST_BOLD:
      fprintf (f, "</bold>");
      break;
    case ST_FORCED_CENTER:
    case ST_CENTER:
      fprintf (f, "</center>");
      break;
    case ST_TT:
      fprintf (f, "</tt>");
      break;
    case ST_UNDERLINED:
      fprintf (f, "</ul>");
      break;
    default:
      break;
    }
}

void
xml_write_special_char (FILE *f, grewchar *first_char)
{
  if (in_text)
    {
      fprintf (f, "</str>");
      in_text = 0;
    }
  fprintf (f, "<special-char>");
  xml_print_unistring (f, first_char);
  fprintf (f, "</special-char>");
}

void
xml_write_verb (FILE *f, grewchar *first_char)
{
  if (in_text)
    {
      fprintf (f, "</str>");
      in_text = 0;
    }
  fprintf (f, "<verbatim>");
  xml_print_unistring (f, first_char);
  fprintf (f, "</verbatim>");
}

void
xml_print_unistring (FILE *f, grewchar *first_char)
{
  while (*first_char != 0)
    {
      xml_print_unichar (f, *first_char);
      first_char++;
    }
}

void
xml_print_unichar (FILE *f, grewchar to_print)
{
  switch (to_print)
    {
    case L'<':
      fprintf (f, "&lt;");
      break;
    case L'>':
      fprintf (f, "&gt;");
      break;
    case L'\'':
      fprintf (f, "&apos;");
      break;
    case L'&':
      fprintf (f, "&amp;");
      break;
    case L'"':
      fprintf (f, "\\\"");
      break;
    case L'\\':
      fprintf (f, "\\\\");
      break;
    default:
      gregorio_print_unichar (f, to_print);
      break;
    }
}

void
xml_print_char (FILE *f, grewchar to_print)
{
  if (!in_text)
    {
      fprintf (f, "<str>");
      in_text = 1;
    }
  xml_print_unichar (f, to_print);
}

void
xml_print_text (FILE *f, gregorio_character *text, char position)
{
  const char *position_str;
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
  gregorio_write_text (0, text, f,
                       (&xml_write_verb),
                       (&xml_print_char),
                       (&xml_write_begin),
                       (&xml_write_end), (&xml_write_special_char));
  if (in_text)
    {
      fprintf (f, "</str>");
      in_text = 0;
    }
  fprintf (f, "</text>");
}

void
xml_print_translation (FILE *f, gregorio_character *translation)
{
  if (!translation)
    {
      return;
    }
  fprintf (f, "<translation>");
  gregorio_write_text (0, translation, f,
                       (&xml_write_verb),
                       (&xml_print_char),
                       (&xml_write_begin),
                       (&xml_write_end), (&xml_write_special_char));
  if (in_text)
    {
      fprintf (f, "</str>");
      in_text = 0;
    }
  fprintf (f, "</translation>");
}

void
xml_write_syllable (FILE *f, gregorio_syllable *syllable,
                    int number_of_voices, int clefs[], char alterations[][13])
{
  int voice;
  int i;

  if (!syllable)
    {
      gregorio_message (_("call with NULL argument"),
                        "xml_write_syllable", ERROR, 0);
    }
  if (syllable->position == WORD_BEGINNING)
    {
      gregorio_reinitialize_alterations (alterations, number_of_voices);
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
      xml_print_text (f, syllable->text, syllable->position);
    }
  if (syllable->translation)
    {
      xml_print_translation (f, syllable->translation);
    }
  for (i = 0; i < number_of_voices; i++)
    {
      if (!(syllable->elements[i]))
        {
          gregorio_message (_("not_enough voices in syllable"),
                            "xml_write_syllable", VERBOSE, 0);
          voice++;
          continue;
        }
      if (gregorio_is_only_special (syllable->elements[i]))
        {
          xml_write_specials_as_neumes (f, syllable->elements[i],
                                        voice, &clefs[i]);
        }
      else
        {
          xml_write_neume (f, syllable->elements[i], voice,
                           &clefs[i], alterations[i]);
        }
      voice++;
    }

  fprintf (f, "</syllable>");
}

void
xml_write_neume (FILE *f, gregorio_element *element, int voice,
                 int *clef, char alterations[])
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
      xml_write_gregorio_element (f, element, clef, alterations);
      element = element->next;
    }
  fprintf (f, "</neume>");
}

void
xml_write_specials_as_neumes (FILE *f,
                              gregorio_element *element, int voice, int *clef)
{

  while (element)
    {
      if (element->type == GRE_BAR)
        {
          if (voice == MONOPHONY)
            {
              fprintf (f, "<bar>");
              xml_write_bar (f, element->element_type,
                             element->additional_infos);
              fprintf (f, "</bar>");
            }
          else
            {
              fprintf (f, "<bar voice=\"%d\">", voice);
              xml_write_bar (f, element->element_type,
                             element->additional_infos);
              fprintf (f, "</bar>");
            }
        }
      if (element->type == GRE_END_OF_LINE)
        {
          if (element->element_type == GRE_END_OF_PAR)
            {
              fprintf (f, "<end-of-paragraph/>");
            }
          else
            {
              fprintf (f, "<end-of-line/>");
            }
        }
      if (element->type == GRE_C_KEY_CHANGE)
        {
          if (voice == MONOPHONY)
            {
              *clef =
                gregorio_calculate_new_key (C_KEY, element->element_type - 48);
              xml_write_key_change (f, C_KEY, element->element_type - 48);
            }
          else
            {
              *clef =
                gregorio_calculate_new_key (C_KEY, element->element_type - 48);
              xml_write_key_change_in_polyphony (f, C_KEY,
                                                 element->element_type -
                                                 48, voice);
            }
        }
      if (element->type == GRE_F_KEY_CHANGE)
        {
          if (voice == MONOPHONY)
            {
              *clef =
                gregorio_calculate_new_key (F_KEY, element->element_type - 48);
              xml_write_key_change (f, F_KEY, element->element_type - 48);
            }
          else
            {
              *clef =
                gregorio_calculate_new_key (F_KEY, element->element_type - 48);
              xml_write_key_change_in_polyphony (f, F_KEY,
                                                 element->element_type -
                                                 48, voice);
            }
        }
      element = element->next;
    }
}

#if ALL_STATIC == 0
void
write_score (FILE *f, gregorio_score *score)
#else
void
xml_write_score (FILE *f, gregorio_score *score)
#endif
{
  int i;
  gregorio_voice_info *voice_info;
  gregorio_syllable *current_syllable;
  if (!score)
    {
      gregorio_message (_("call with NULL argument"),
                        "xml_write_score", ERROR, 0);
      return;
    }

  // we initialize the key array (that will maybe change, that's why we don't
  // take the same)
  int clefs[score->number_of_voices];
  voice_info = score->first_voice_info;
  for (i = 0; i < score->number_of_voices; i++)
    {
      if (!voice_info)
        {
          gregorio_message (_
                            ("score has more voice infos than voices (attribute number of voices)"),
                            "xml_write_syllable", ERROR, 0);
          return;
        }
      clefs[i] = voice_info->initial_key;
      voice_info = voice_info->next_voice_info;
    }

  // the clefs array is good, now let's take care of alterations
  char alterations[score->number_of_voices][13];
  gregorio_reinitialize_alterations (alterations, score->number_of_voices);
  fprintf (f,
           "<?xml version=\"1.0\"?>\n<!-- File generated by gregorio %s -->\n",
           VERSION);
  fprintf (f, "<score>");
  xml_write_score_attributes (f, score);
  current_syllable = score->first_syllable;
  while (current_syllable)
    {
      xml_write_syllable (f, current_syllable,
                          score->number_of_voices, clefs, alterations);
      current_syllable = current_syllable->next_syllable;
    }
  fprintf (f, "</score>\n");
}

void
xml_write_score_attributes (FILE *f, gregorio_score *score)
{
  // two variables for the key determination
  char step;
  int line;
  int voice = MONOPHONY;
  gregorio_voice_info *current_voice_info;
  int annotation_num;

  if (!score)
    {
      gregorio_message (_("call with NULL argument"),
                        "xml_write_score_attributes", ERROR, 0);
      return;
    }

  fprintf (f, "<score-attributes>");
  if (!score->name)
    {
      gregorio_message (_
                        ("score has no name attribute, which is mandatory"),
                        "xml_write_score_attributes", ERROR, 0);
      fprintf (f, "<name></name>");
    }
  else
    {
      fprintf (f, "<name>%s</name>", score->name);
    }
  if (score->gabc_copyright)
    {
      fprintf (f, "<gabc-copyright>%s</gabc-copyright>", score->gabc_copyright);
    }
  if (score->score_copyright)
    {
      fprintf (f, "<score-copyright>%s</score-copyright>",
               score->score_copyright);
    }
  if (score->office_part)
    {
      fprintf (f, "<office-part>%s</office-part>", score->office_part);
    }
  if (score->occasion)
    {
      fprintf (f, "<occasion>%s</occasion>", score->occasion);
    }
  if (score->meter)
    {
      fprintf (f, "<meter>%s</meter>", score->meter);
    }
  if (score->commentary)
    {
      fprintf (f, "<commentary>%s</commentary>", score->commentary);
    }
  if (score->arranger)
    {
      fprintf (f, "<arranger>%s</arranger>", score->arranger);
    }
  if (score->initial_style)
    {
      fprintf (f, "<initial-style>%d</initial-style>", score->initial_style);
    }
  if (score->mode)
    {
      fprintf (f, "<mode>%d</mode>", score->mode);
    }
  if (score->si.author)
    {
      fprintf (f, "<author>%s</author>", score->si.author);
    }
  if (score->si.date)
    {
      fprintf (f, "<date>%s</date>", score->si.date);
    }
  if (score->si.manuscript)
    {
      fprintf (f, "<manuscript>%s</manuscript>", score->si.manuscript);
    }
  if (score->si.manuscript_reference)
    {
      fprintf (f,
               "<manuscript-reference>%s</manuscript-reference>",
               score->si.manuscript_reference);
    }
  if (score->si.manuscript_storage_place)
    {
      fprintf (f,
               "<manuscript-storage-place>%s</manuscript-storage-place>",
               score->si.manuscript_storage_place);
    }
  if (score->si.book)
    {
      fprintf (f, "<book>%s</book>", score->si.book);
    }
  if (score->si.transcriber)
    {
      fprintf (f, "<transcriber>%s</transcriber>", score->si.transcriber);
    }
  if (score->si.transcription_date)
    {
      fprintf (f,
               "<transcription-date>%s</transcription-date>",
               score->si.transcription_date);
    }
  if (score->lilypond_preamble)
    {
      fprintf (f, "<lilypond-preamble>%s</lilypond-preamble>",
               score->lilypond_preamble);
    }
  if (score->opustex_preamble)
    {
      fprintf (f, "<opustex-preamble>%s</opustex-preamble>",
               score->opustex_preamble);
    }
  if (score->musixtex_preamble)
    {
      fprintf (f, "<musixtex-preamble>%s</musixtex-preamble>",
               score->musixtex_preamble);
    }
  if (score->gregoriotex_font)
    {
      fprintf (f, "<gregoriotex_font>%s</gregoriotex_font>",
               score->gregoriotex_font);
    }
  if (score->user_notes)
    {
      fprintf (f, "<user_notes>%s</user_notes>", score->user_notes);
    }

  // then we consider the voice_info
  current_voice_info = score->first_voice_info;

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
      for (annotation_num = 0; annotation_num < NUM_ANNOTATIONS;
           ++annotation_num)
        {
          if (current_voice_info->annotation[annotation_num])
            {
              fprintf (f,
                       "<annotation>%s</annotation>",
                       current_voice_info->annotation[annotation_num]);
            }
        }

      if (current_voice_info->style)
        {
          fprintf (f, "<style>%s</style>", current_voice_info->style);
        }
      gregorio_det_step_and_line_from_key (current_voice_info->initial_key,
                                           &step, &line);
      fprintf (f, "<clef><step>%c</step><line>%d</line></clef>", step, line);
      if (voice != MONOPHONY)
        {
          fprintf (f, "</voice-info>");
          voice++;
        }

      current_voice_info = current_voice_info->next_voice_info;
    }                           // end of while for voice-lists
  if (voice != MONOPHONY)
    {
      fprintf (f, "</voice-list>");
    }
  fprintf (f, "</score-attributes>");
}
