%{
/*
Gregorio score determination in gabc input.
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

#include <stdio.h>
#include <stdlib.h>
#include "messages.h"
#include "struct.h"
#include "gabc.h"
#include "gabc-score-determination-l.h"
#include <libintl.h>
#define _(str) gettext(str)
#define N_(str) str



#define YYSTYPE char *
#define YYSTYPE_IS_DECLARED 1

void free_variables();
extern char *error;
gregorio_score *score;
gregorio_element **elements;
int gabc_score_determination_parse ();
void initialize_variables ();
int check_score_integrity (gregorio_score * score);

void
gabc_score_determination_error (const char *str)
{
  char *str2=strdup(str);
  libgregorio_message (str2, "libgregorio_det_score", ERROR, 0);
}

gregorio_score *
libgregorio_gabc_read_file (FILE * f_in)
{
  if (!f_in)
    {
      libgregorio_message (_
		      ("can't read stream from argument, returning NULL pointer"),
		      "libgregorio_det_score", ERROR, 0);
      return NULL;
    }
  FILE *f_out = fopen ("/dev/null", "w");
  initialize_variables ();
  gabc_score_determination_in = f_in;
  gabc_score_determination_out = f_out;
  gabc_score_determination_parse ();
  fclose (f_out);
  free_variables();
  libgregorio_fix_initial_keys (score,DEFAULT_KEY);
  if (!check_score_integrity (score))
    {
      libgregorio_free_score (score);
      score = NULL;
      libgregorio_message (_("unable to determine a valid score from file"),
		      "libgregorio_det_score", FATAL_ERROR, 0);
    }
  return score;
}

int check_score_integrity (gregorio_score *score) 
{
  if (!score)
    {
      return 0;
    }
return 1;
}

int
check_infos_integrity (gregorio_score * score)
{
  if (!score->name)
    {
      libgregorio_message (_
		      ("no name specified, put `name:...;' at the beginning of the file, can be dangerous with some output formats"),
		      "libgregorio_det_score", WARNING, 0);
    }
  return 1;
}

//int gabc_score_determination_debug=1;

gregorio_voice_info *current_voice_info;
int number_of_voices;
int voice;
int clef;


void
initialize_variables ()
{
  score = libgregorio_new_score ();
  current_voice_info = NULL;
  libgregorio_add_voice_info (&current_voice_info);
  score->first_voice_info = current_voice_info;
  number_of_voices = 0;
  voice = 1;
error=malloc(300 * sizeof(char));
}

void free_variables() {
  free (elements);
  free(error);
}

#define voice_info_is_not_empty(voice_info)   voice_info->initial_key!=5 || voice_info->anotation || voice_info->author || voice_info->date || voice_info->manuscript || voice_info->reference || voice_info->storage_place || voice_info->translator || voice_info->translation_date || voice_info->style || voice_info->virgula_position

void
next_voice_info ()
{
  //we must do this test in the case where there would be a "--" before first_declarations
  if (voice_info_is_not_empty (current_voice_info))
    {
      libgregorio_add_voice_info (&current_voice_info);
      voice++;
    }
}


void
set_clef (char *str)
{
  if (!str || !str[0] || !str[1])
    {
      libgregorio_message (_
		      ("unknown clef format in initial-key definition : format is `(c|f)[1-4]'"), "libgregorio_det_score",
		      ERROR,0);
    }
  if (str[0] != 'c' && str[0] != 'f')
    {
      libgregorio_message (_
		      ("unknown clef format in initial-key definition : format is `(c|f)[1-4]'"), "libgregorio_det_score",
		      ERROR,0);
      return;
    }
//here is something than could be changed : the format of the inital_key attribute
  if (str[1] != '1' && str[1] != '2' && str[1] != '3' && str[1] != '4')
    {
      libgregorio_message (_
		      ("unknown clef format in initial-key definition : format is `(c|f)[1-4]'"), "libgregorio_det_score",
		      ERROR,0);
      return;
    }

  clef = libgregorio_calculate_new_key (str[0], str[1]-48);
  if (str[2]) {
      libgregorio_message (_
		      ("in initial_key definition, only two characters are needed : format is`(c|f)[1-4]'"), "libgregorio_det_score",
		      WARNING,0);
  }
}

void
reajust_voice_infos (gregorio_voice_info * voice_info, int final_count)
{
  int i = 1;
  while (voice_info && i <= final_count)
    {
      voice_info = voice_info->next_voice_info;
    }
  libgregorio_free_voice_infos (voice_info);
}

void
end_definitions ()
{
  if (!check_infos_integrity(score)) {
      libgregorio_message (_("can't determine valid infos on the score"),
		      "libgregorio_det_score", ERROR, 0);
  }
  if (!number_of_voices)
    {
      if (voice > MAX_NUMBER_OF_VOICES)
	{
	  voice = MAX_NUMBER_OF_VOICES;
	  reajust_voice_infos (score->first_voice_info, number_of_voices);
	}
      number_of_voices = voice;
      score->number_of_voices = voice;
    }
  else
    {
      if (number_of_voices > voice)
	{
	snprintf(error, 62, ngettext("not enough voice infos found: %d found, %d waited, %d assumed","not enough voice infos found: %d found, %d waited, %d assumed",voice), voice, number_of_voices, voice);
	libgregorio_message(error,"libgregorio_det_score",WARNING,0);
	  score->number_of_voices = voice;
	  number_of_voices = voice;
	}
      else
	{
	  if (number_of_voices < voice)
	    {
	snprintf(error, 62, ngettext("too many voice infos found: %d found, %d waited, %d assumed","not enough voice infos found: %d found, %d waited, %d assumed",number_of_voices), voice, number_of_voices, number_of_voices);
	libgregorio_message(error,"libgregorio_det_score",WARNING,0);
	    }
	}
    }
  voice = 0;			// voice is now voice-1, so that it can be the index of elements 
  elements =
    (gregorio_element **) malloc (number_of_voices * sizeof (gregorio_element *));
  int i;
  for (i = 0; i < number_of_voices; i++)
    {
      elements[i] = NULL;
    }
}

//////////// here starts the code about the notes
char *current_text = "";
char position = WORD_BEGINNING;
gregorio_syllable *current_syllable = NULL;

void
complete_with_nulls (int voice)
{
  int i;
  for (i = voice + 1; i < number_of_voices; i++)
    {
      elements[i] = NULL;
    }
}


//function called each time we find a space
void
update_position_with_space ()
{
  if (position == WORD_MIDDLE)
    {
      position = WORD_BEGINNING;
    }
  if (current_syllable && current_syllable->position == WORD_MIDDLE)
    {
      current_syllable->position = WORD_END;
    }
}

void
close_syllable ()
{

  libgregorio_add_syllable (&current_syllable, number_of_voices, elements, current_text,
		position);
  if (!score->first_syllable)
    {
      score->first_syllable = current_syllable;
    }
//we update the position
  if (position == WORD_BEGINNING)
    {
      position = WORD_MIDDLE;
    }
}

void test () {

}

%}



%token ATTRIBUTE COLON SEMICOLON OFFICE_PART ANOTATION AUTHOR DATE MANUSCRIPT REFERENCE STORAGE_PLACE TRANSLATOR TRANSLATION_DATE STYLE VIRGULA_POSITION LILYPOND_PREAMBLE OPUSTEX_PREAMBLE MUSIXTEX_PREAMBLE SOFTWARE_USED NAME SYLLABLE OPENING_BRACKET NOTES VOICE_CUT CLOSING_BRACKET NUMBER_OF_VOICES INITIAL_KEY VOICE_CHANGE END_OF_DEFINITIONS SPACE

%%

score:
	all_definitions syllables
	;

all_definitions:
	definitions END_OF_DEFINITIONS {
	end_definitions();
	}
	;

definitions:
	| definitions definition
	;

number_of_voices_definition:
	NUMBER_OF_VOICES attribute {
	number_of_voices=atoi($2);
	if (number_of_voices > MAX_NUMBER_OF_VOICES) {
	snprintf(error, 40, _("can't define %d voices, maximum is %d"), number_of_voices, MAX_NUMBER_OF_VOICES);
	libgregorio_message(error,"libgregorio_det_score",WARNING,0);
	}
	libgregorio_set_score_number_of_voices (score, number_of_voices);
	}

name_definition:
	NAME attribute {
	if ($2==NULL) {
	libgregorio_message("name can't be empty","libgregorio_det_score",WARNING,0);
	}
	if (score->name) {
	libgregorio_message(_("several name definitions found, only the last will be taken into consideration"), "libgregorio_det_score",WARNING, 0);
	}
	libgregorio_set_score_name (score, $2);
	}
	;

lilypond_preamble_definition:
	LILYPOND_PREAMBLE attribute {
	if (score->lilypond_preamble) {
	libgregorio_message(_("several lilypond preamble definitions found, only the last will be taken into consideration"), "libgregorio_det_score",WARNING,0);
	}
	libgregorio_set_score_lilypond_preamble (score, $2);
	}
	;

opustex_preamble_definition:
	OPUSTEX_PREAMBLE attribute {
	if (score->opustex_preamble) {
	libgregorio_message(_("several OpusTeX preamble definitions found, only the last will be taken into consideration"), "libgregorio_det_score",WARNING,0);
	}
	libgregorio_set_score_opustex_preamble (score, $2);
	}
	;

musixtex_preamble_definition:
	MUSIXTEX_PREAMBLE attribute {
	if (score->musixtex_preamble) {
	libgregorio_message(_("several MusiXTeX preamble definitions found, only the last will be taken into consideration"), "libgregorio_det_score",WARNING,0);
	}
	libgregorio_set_score_musixtex_preamble (score, $2);
	}
	;

office_part_definition:
	OFFICE_PART attribute {
	if (score->office_part) {
	libgregorio_message(_("several office part definitions found, only the last will be taken into consideration"), "libgregorio_det_score",WARNING,0);
	}
	libgregorio_set_score_office_part (score, $2);
	}
	;

initial_key_definition:
	INITIAL_KEY attribute {
	if (current_voice_info->initial_key!=NO_KEY) {
	snprintf(error,99,_("several definitions of initial key found for voice %d, only the last will be taken into consideration"),voice);
	libgregorio_message(error, "libgregorio_det_score",WARNING,0);
	}
	set_clef($2);
	libgregorio_set_voice_initial_key (current_voice_info, clef);
	}
	;


anotation_definition:
	ANOTATION attribute {
	if (current_voice_info->anotation) {
	snprintf(error,99,_("several definitions of anotation found for voice %d, only the last will be taken into consideration"),voice);
	libgregorio_message(error, "libgregorio_det_score",WARNING,0);
	}
	libgregorio_set_voice_anotation (current_voice_info, $2);
	}
	;

author_definition:
	AUTHOR attribute {
	if (current_voice_info->author) {
	snprintf(error,99,_("several definitions of author found for voice %d, only the last will be taken into consideration"),voice);
	libgregorio_message(error, "libgregorio_det_score",WARNING,0);
	}
	libgregorio_set_voice_author (current_voice_info, $2);
	}
	;

date_definition:
	DATE attribute {
	if (current_voice_info->date) {
	snprintf(error,99,_("several definitions of date found for voice %d, only the last will be taken into consideration"),voice);
	libgregorio_message(error, "libgregorio_det_score",WARNING,0);
	}
	libgregorio_set_voice_date (current_voice_info, $2);
	}
	;

manuscript_definition:
	MANUSCRIPT attribute {
	if (current_voice_info->manuscript) {
	snprintf(error,99,_("several definitions of manuscript found for voice %d, only the last will be taken into consideration"),voice);
	libgregorio_message(error, "libgregorio_det_score",WARNING,0);
	}
	libgregorio_set_voice_manuscript (current_voice_info, $2);
	}
	;

reference_definition:
	REFERENCE attribute {
	if (current_voice_info->reference) {
	snprintf(error,99,_("several definitions of reference found for voice %d, only the last will be taken into consideration"),voice);
	libgregorio_message(error, "libgregorio_det_score",WARNING,0);
	}
	libgregorio_set_voice_reference (current_voice_info, $2);
	}
	;

storage_place_definition:
	STORAGE_PLACE attribute {
	if (current_voice_info->storage_place) {
	snprintf(error,105,_("several definitions of storage place found for voice %d, only the last will be taken into consideration"),voice);
	libgregorio_message(error, "libgregorio_det_score",WARNING,0);
	}
	libgregorio_set_voice_storage_place (current_voice_info, $2);
	}
	;

translator_definition:
	TRANSLATOR attribute {
	if (current_voice_info->translator) {
	snprintf(error,99,_("several definitions of translator found for voice %d, only the last will be taken into consideration"),voice);
	libgregorio_message(error, "libgregorio_det_score",WARNING,0);
	}
	libgregorio_set_voice_translator (current_voice_info, $2);
	//free($2);
	}
	;

translation_date_definition:
	TRANSLATION_DATE attribute {
	if (current_voice_info->translation_date) {
	snprintf(error,105,_("several definitions of translation date found for voice %d, only the last will be taken into consideration"),voice);
	libgregorio_message(error, "libgregorio_det_score",WARNING,0);
	}
	libgregorio_set_voice_translation_date (current_voice_info, $2);
	}
	;

style_definition:
	STYLE attribute {
	if (current_voice_info->style) {
	snprintf(error,99,_("several definitions of style found for voice %d, only the last will be taken into consideration"),voice);
	libgregorio_message(error, "libgregorio_det_score",WARNING,0);
	}
	libgregorio_set_voice_style (current_voice_info, $2);
	}
	;

virgula_position_definition:
	VIRGULA_POSITION attribute {
	if (current_voice_info->virgula_position) {
	snprintf(error,105,_("several definitions of virgula position found for voice %d, only the last will be taken into consideration"),voice);
	libgregorio_message(error, "libgregorio_det_score",WARNING,0);
	}
	libgregorio_set_voice_virgula_position (current_voice_info, $2);
	}
	;


sotfware_used_definition:
	SOFTWARE_USED attribute {
	//libgregorio_set_voice_sotfware_used (current_voice_info, $2);
	}
	;

attribute:
	COLON ATTRIBUTE SEMICOLON {
	$$=$2;
	}
	|
	COLON SEMICOLON {
	$$=NULL;
	}
	;

definition:
	number_of_voices_definition
	|
	name_definition
	|
	initial_key_definition
	|
	sotfware_used_definition
	|
	musixtex_preamble_definition
	|
	opustex_preamble_definition
	|
	lilypond_preamble_definition
	|
	virgula_position_definition
	|
	style_definition
	|
	translation_date_definition
	|
	translator_definition
	|
	storage_place_definition
	|
	reference_definition
	|
	manuscript_definition
	|
	date_definition
	|
	author_definition
	|
	anotation_definition
	|
	office_part_definition
	|
	VOICE_CHANGE {
	next_voice_info ();
	}
	;

notes:
	|notes note
	;

note:
	NOTES CLOSING_BRACKET {
	if (voice<number_of_voices) {
	elements[voice]=libgregorio_gabc_det_elements_from_string($1);
	free($1);
	}
	else {
	snprintf(error,105,ngettext("too many voices in note : %d foud, %d expected","too many voices in note : %d foud, %d expected",number_of_voices),voice+1, number_of_voices);
	libgregorio_message(error, "libgregorio_det_score",ERROR,0);
	}
	if (voice<number_of_voices-1) {
	snprintf(error,105,ngettext("not enough voices in note : %d foud, %d expected, completing with empty neume","not enough voices in note : %d foud, %d expected, completing with empty neume",voice+1),voice+1, number_of_voices);
	libgregorio_message(error, "libgregorio_det_score",VERBOSE,0);
	complete_with_nulls(voice);
	}
	voice=0;
	}
	|
	NOTES VOICE_CUT{
	if (voice<number_of_voices) {
	elements[voice]=libgregorio_gabc_det_elements_from_string($1);
	free($1);
	voice++;
	}
	else {
	snprintf(error,105,ngettext("too many voices in note : %d foud, %d expected","too many voices in note : %d foud, %d expected",number_of_voices),voice+1, number_of_voices);
	libgregorio_message(error, "libgregorio_det_score",ERROR,0);
	}
	}
	;
	
syllable_with_notes:
	SYLLABLE OPENING_BRACKET notes {
	current_text=$1;
	close_syllable();
	}
	;

notes_without_word:
	OPENING_BRACKET notes {
	current_text=NULL;
	close_syllable();
	}
	;

syllable:
	syllable_with_notes
	|
	notes_without_word
	|
	SPACE {
	update_position_with_space();
	}
	;

syllables:
	|syllables syllable
	;
