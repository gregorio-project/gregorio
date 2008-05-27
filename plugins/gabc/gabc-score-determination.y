%{
/*
Gregorio score determination in gabc input.
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

This file is certainly not the most easy to understand, it is a bison file. See the bison manual on gnu.org for further details.

*/

#include "config.h"
#include <stdio.h>
#include <stdlib.h>
#include <wchar.h>
#include "messages.h"
#include "struct.h"
#include "gabc.h"
#include "gabc-score-determination-l.h"
#include "gettext.h"
#define _(str) gettext(str)
#define N_(str) str
// request translation to the user native language for bison
#define YYENABLE_NLS 1
// don't know... to test..
//#define YYLTYPE_IS_TRIVIAL 0


/*

we declare the type of gabc_score_determination_lval (in the flex file) to be char *.

*/

#define YYSTYPE char *
#define YYSTYPE_IS_DECLARED 1

// uncomment it if you want to have an interactive shell to understand the details on  how bison works for a certain input
//int gabc_score_determination_debug=1;

/*

We will need some variables and functions through the entire file, we declare them there:

*/

/* to understand the det_style, you need to read the comments about text, where all is explained.
 */

typedef struct det_style
{
  unsigned char style;
  struct det_style *previous_style;
  struct det_style *next_style;
} det_style;


// the two functions to initialize and free the file variables
void initialize_variables ();
void free_variables ();
// the error string
char error[200];
// the score that we will determine and return
gregorio_score *score;
// an array of elements that we will use for each syllable
gregorio_element **elements;
// declaration of some functions, the first is the one initializing the flex/bison process
//int gabc_score_determination_parse ();
// other variables that we will have to use
gregorio_character *current_character;
gregorio_character *first_text_character;
gregorio_character *first_translation_character;
gregorio_voice_info *current_voice_info;
int number_of_voices;
int voice;
int clef;
det_style *first_style;
// a char that will take some useful values see comments on text to understand it
char center_is_determined;

#define FIRST_LETTER 1
#define SECOND_LETTER 2
#define THIRD_LETTER 3
char first_letter;

int check_score_integrity (gregorio_score * score);
void free_styles();
void next_voice_info ();
void set_clef (char *str);
void reajust_voice_infos (gregorio_voice_info * voice_info, int final_count);
void end_definitions ();
void suppress_useless_styles ();
void close_syllable ();
void push (unsigned char style);
void pop (det_style * element);
void add_text (char *mbcharacters);
void add_style(unsigned char style);
void end_style(unsigned char style);
void insert_style_before (unsigned char type, unsigned char style);
void insert_style_after (unsigned char type, unsigned char style);
void suppress_this_character (gregorio_character *to_suppress);
void end_style_determination ();
void complete_with_nulls (int voice);

void gabc_score_determination_error(char *error_str) {
libgregorio_message (error_str, (const char *)"gabc_score_determination_parse", ERROR, 0);
}


/* The "main" function. It is the function that is called when we have to read a gabc file. 
 * It takes a file descriptor, that is to say a file that is aleady open. 
 * It returns a valid gregorio_score
 */

gregorio_score *
read_score (FILE * f_in)
{
  // we initialize a file descriptor to /dev/null (see three lines below)
  FILE *f_out = fopen ("/dev/null", "w");
  // the input file that flex will parse
  gabc_score_determination_in = f_in;
  // the output file flex will write in (here /dev/null). We do not have to write in some file, we just have to build a score. Warnings and errors of flex are not written in this file, so they will appear anyway.
  gabc_score_determination_out = f_out;

  if (!f_in)
    {
      libgregorio_message (_
			   ("can't read stream from argument, returning NULL pointer"),
			   "libgregorio_det_score", ERROR, 0);
      return NULL;
    }
  initialize_variables ();
  // the flex/bison main call, it will build the score (that we have initialized)
  gabc_score_determination_parse ();
  fclose (f_out);
  free_variables ();
  // the we check the validity and integrity of the score we have built.
  libgregorio_fix_initial_keys (score, DEFAULT_KEY);
  if (!check_score_integrity (score))
    {
      libgregorio_free_score (score);
      score = NULL;
      libgregorio_message (_("unable to determine a valid score from file"),
			   "libgregorio_det_score", FATAL_ERROR, 0);
    }
  return score;
}

/* A function that checks to score integrity. For now it is... quite ridiculous... but it might be improved in the future.
 */

int
check_score_integrity (gregorio_score * score_to_check)
{
  if (!score_to_check)
    {
      return 0;
    }
  return 1;
}

/* 
 * Another function to be improved: this one checks the validity of the voice_infos.
 */

int
check_infos_integrity (gregorio_score * score_to_check)
{
  if (!score_to_check->name)
    {
      libgregorio_message (_
			   ("no name specified, put `name:...;' at the beginning of the file, can be dangerous with some output formats"),
			   "libgregorio_det_score", WARNING, 0);
    }
  return 1;
}

/* The function that will initialize the variables.
 */

void
initialize_variables ()
{
  // build a brand new empty score
  score = libgregorio_new_score ();
  // initialization of the first voice info to an empty voice info
  current_voice_info = NULL;
  libgregorio_add_voice_info (&current_voice_info);
  score->first_voice_info = current_voice_info;
  // other initializations
  number_of_voices = 0;
  voice = 1;
  current_character = NULL;
  first_style = NULL;
  center_is_determined=0;
  first_letter=FIRST_LETTER;
}


/* function that frees the variables that need it, for when we have finished to determine the score
 */

void
free_variables ()
{
  free (elements);
  free_styles();
}

// a macro to put inside a if to see if a voice_info is empty
#define voice_info_is_not_empty(voice_info)   voice_info->initial_key!=5 || voice_info->anotation || voice_info->author || voice_info->date || voice_info->manuscript || voice_info->reference || voice_info->storage_place || voice_info->translator || voice_info->translation_date || voice_info->style || voice_info->virgula_position


/* a function called when we see "--\n" that end the infos for a certain voice
 */
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

/* Function that updates the clef variable, intepreting the char *str argument
 */
void
set_clef (char *str)
{
  if (!str || !str[0] || !str[1])
    {
      libgregorio_message (_
			   ("unknown clef format in initial-key definition : format is `(c|f)[1-4]'"),
			   "libgregorio_det_score", ERROR, 0);
    }
  if (str[0] != 'c' && str[0] != 'f')
    {
      libgregorio_message (_
			   ("unknown clef format in initial-key definition : format is `(c|f)[1-4]'"),
			   "libgregorio_det_score", ERROR, 0);
      return;
    }
//here is something than could be changed : the format of the inital_key attribute
  if (str[1] != '1' && str[1] != '2' && str[1] != '3' && str[1] != '4')
    {
      libgregorio_message (_
			   ("unknown clef format in initial-key definition : format is `(c|f)[1-4]'"),
			   "libgregorio_det_score", ERROR, 0);
      return;
    }

  clef = libgregorio_calculate_new_key (str[0], str[1] - 48);
  if (str[2])
    {
      libgregorio_message (_
			   ("in initial_key definition, only two characters are needed : format is`(c|f)[1-4]'"),
			   "libgregorio_det_score", WARNING, 0);
    }
}

/* Function that frees the voice_infos for voices > final_count. Useful if there are too many voice_infos
 */

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

/* Function called when we have reached the end of the definitions, it tries to make the voice_infos coherent.
 */
void
end_definitions ()
{
  int i;

  if (!check_infos_integrity (score))
    {
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
	  snprintf (error, 62,
		    ngettext
		    ("not enough voice infos found: %d found, %d waited, %d assumed",
		     "not enough voice infos found: %d found, %d waited, %d assumed",
		     voice), voice, number_of_voices, voice);
	  libgregorio_message (error, "libgregorio_det_score", WARNING, 0);
	  score->number_of_voices = voice;
	  number_of_voices = voice;
	}
      else
	{
	  if (number_of_voices < voice)
	    {
	      snprintf (error, 62,
			ngettext
			("too many voice infos found: %d found, %d waited, %d assumed",
			 "not enough voice infos found: %d found, %d waited, %d assumed",
			 number_of_voices), voice, number_of_voices,
			number_of_voices);
	      libgregorio_message (error, "libgregorio_det_score", WARNING,
				   0);
	    }
	}
    }
  voice = 0;			// voice is now voice-1, so that it can be the index of elements 
  elements =
    (gregorio_element **) malloc (number_of_voices *
				  sizeof (gregorio_element *));
  for (i = 0; i < number_of_voices; i++)
    {
      elements[i] = NULL;
    }
}

/* Here starts the code for the determinations of the notes. The notes are not precisely determined here, we separate the text describing the notes of each voice, and we call determine_elements_from_string to really determine them.
 */
char *current_text = NULL; // TODO : not sure of the =NULL
char position = WORD_BEGINNING;
gregorio_syllable *current_syllable = NULL;


/* Function called when we see a ")", it completes the gregorio_element array of the syllable with NULL pointers. Usefull in the cases where for example you have two voices, but a voice that is silent on a certain syllable.
 */
void
complete_with_nulls (int last_voice)
{
  int i;
  for (i = last_voice + 1; i < number_of_voices; i++)
    {
      elements[i] = NULL;
    }
}

/* Function called each time we find a space, it updates the current position.
 */
void
update_position_with_space ()
{
  if (position == WORD_MIDDLE)
    {
      position = WORD_END;
    }
  if (position == WORD_BEGINNING)
    {
      position = WORD_ONE_SYLLABLE;
    }
}

/*

The three next defines are the possible values of center_is_determined.

HALF_DETERMINED means that lex has encountered a { but no }, and we will try to determine a middle starting after the {.
FULLY_DETERMINED means that lex has encountered a { and a }, so we won't determine the middle, it is considered done.
DETERMINING_MIDDLE is used internally in the big function to know where we are in the middle determination.

*/

#define NOT_DETERMINED 0
#define HALF_DETERMINED 1
#define FULLY_DETERMINED 2
#define DETERMINING_MIDDLE 3

/* Function to close a syllable and update the position.
 */

void
close_syllable ()
{
  libgregorio_add_syllable (&current_syllable, number_of_voices, elements,
			    first_text_character, first_translation_character, position);
  if (!score->first_syllable)
    {
      score->first_syllable = current_syllable;
    }
  //we update the position
  if (position == WORD_BEGINNING)
    {
      position = WORD_MIDDLE;
    }
  if (position == WORD_ONE_SYLLABLE || position == WORD_END)
    {
      position = WORD_BEGINNING;
    }
  center_is_determined=NOT_DETERMINED;
  first_letter=0;
  current_character = NULL;
  first_text_character=NULL;
  first_translation_character=NULL;
  //TODO : decide wether it will be freed all time or just at the end...
  free_styles();
}

// a function called when we see a [, basically, all characters are added to the translation pointer instead of the text pointer
void start_translation() {
  end_style_determination ();
  libgregorio_go_to_first_character(&current_character);
  first_text_character = current_character;
  center_is_determined=FULLY_DETERMINED; // the middle letters of the translation have no sense
  current_character=NULL;
}

void end_translation() {
  end_style_determination ();
  libgregorio_go_to_first_character(&current_character);
  first_translation_character=current_character;
}

void
test ()
{

}

/* Here starts the code of the interpretation of text and styles.

This part is not the easiest, in fact is is the most complicated. The reason is that I want to make something coherent in memory (easy to interprete), and to let the user type whatever he wants. 

Functionalities: For example if the user types tt<i>ttt<b>ttt</i>tt I want it to be represented as tt<i>ttt<b>ttt</b></i><b>tt</b>. The fabulous thing is that it is xml-compliant. This part also determines the middle, for example pot will be interpreted as p{o}t. When I did that I also thought about TeX styles that needed things like {p}{o}{t}, so when the user types <i>pot</i>, it is interpreted as <i>p</i>{<i>o</i>}<i>t</i>.

Internal structure: To do so we have a structure, det_style, that will help us : it is a stack (double chained list) of the styles that we have seen until now. When we encounter a <i>, we push the i style on the stack. If we encounter a </i> we suppress the i style from the stack. Let's take a more complex example: if we encounter <i><b></i>, the stack will be first null, then i then bi, and there we want to end i, but it is not the first style of the stack, so we close all the styles that we encounter before we encounter i (remember, this is for xml-compliance), so we insert a </b> before the </i>. But that's not all, we also write a <b> after the </i>, so that the b style continues. There our stack is just b. For center, we just close all the styles in the stack, insert a { and reopen all the styles in the stack.

The structure used for character, styles, etc. is described in include/struct.h

The functionment in this file is quite simple : we add all the characters that we see, even if they are incoherent, in the gregorio_character list, and then we call a very complex function that will build a stack of the style, determine the middle, make all xml-compliant, mow the lawn, etc.

*/

/*
The push function pushes a style in the stack, and updates first_style to this element.
*/

void
push (unsigned char style)
{
  det_style *element = (det_style *) malloc (sizeof (det_style));
  element->style = style;
  element->previous_style = NULL;
  element->next_style = first_style;
  if (first_style)
    {
      first_style->previous_style = element;
    }
  first_style = element;
}

/*
Pop deletes an style in the stack (the style to delete is the parameter)
*/

void
pop (det_style * element)
{
  if (!element)
    {
      return;
    }
  if (element->previous_style)
    {
      element->previous_style->next_style = element->next_style;
    }
  else
    {
      if (element->next_style)
	{
	  element->next_style->previous_style = element->previous_style;
	  first_style=element->next_style;
	}
      else
	{
	  first_style = NULL;
	}
    }
  free (element);
}

/*
free_styles just free the stack. You may notice that it will never be used in a normal functionment. But we never know...
*/

void
free_styles () {
  det_style *current_style=first_style;
  while (current_style) 
    {
      current_style=current_style->next_style;
      free(first_style);
      first_style=current_style;
    }
}

/*

add_text is the function called when lex returns a char *. In this function we convert it into wchar_t *, and then we add the corresponding gregorio_characters in the list of gregorio_characters.

*/

void
add_text (char *mbcharacters)
{
  int i = 0;
  size_t len;
  wchar_t *wtext;
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
      libgregorio_add_character (&current_character, wtext[i]);
      i++;
    }
  free (wtext);
}

/*

The two functions called when lex returns a style, we simply add it. All the complex things will be done by the function after...

*/

void add_style(unsigned char style) {
libgregorio_begin_style(&current_character, style);
}

void end_style(unsigned char style) {
libgregorio_end_style(&current_character, style);
}

/*

Then start the macros for the big function. the first one is the macro we call when we close a style. The magic thing is that is will prevent things like a<i></i>{<i>b</b>: when the user types a<i>b</i>, if the middle is between a and b (...), it will interpret it as a{<i>b</i>.

*/

#define close_style() if (!current_character->previous_character->is_character && current_character->previous_character->cos.s.style==current_style->style) {\
/* we suppose that there is a previous_character, because there is a current_style*/\
suppress_this_character(current_character->previous_character);\
}\
else {\
insert_style_before(ST_T_END, current_style->style);\
}

/*

next the macro called when we have determined that we must end the center here : it closes all styles, adds a } and then reopens all styles.

*/

#define end_center() while (current_style)\
	    {\
	      close_style ()\
	if (current_style->next_style) {\
	      current_style = current_style->next_style;\
	}\
	else {\
	break;\
	}\
	    }\
	  insert_style_before (ST_T_END, ST_CENTER);\
	  while (current_style)\
	    {\
	      insert_style_before (ST_T_BEGIN, current_style->style);\
	if (current_style->previous_style) {\
		current_style=current_style->previous_style;\
	}\
	else {\
	break;\
	}\
	    }

/*
about the same, but adding a {
*/

#define begin_center() while (current_style)\
	    {\
	      close_style ()\
	if (current_style->next_style) {\
	      current_style = current_style->next_style;\
	}\
	else {\
	break;\
	}\
	    }\
	  insert_style_before (ST_T_BEGIN, ST_CENTER);\
	  while (current_style)\
	    {\
	      insert_style_before (ST_T_BEGIN, current_style->style);\
	if (current_style->previous_style) {\
		current_style=current_style->previous_style;\
	}\
	else {\
	break;\
	}\
	    }


/*

the macro called when we have ended the determination of the current character. It makes current_character point to the last character, not to null at the end of the determination.

*/

#define end_c()	if (current_character->next_character) {\
	  current_character=current_character->next_character;\
	  continue;\
	}\
	else {\
	  break;\
	}

/*

basically the same except that we suppress the current_character

*/

#define suppress_char_and_end_c() 	if (current_character->next_character) {\
	current_character=current_character->next_character;\
	suppress_this_character (current_character->previous_character);\
	  continue;\
	}\
	else {\
	if (current_character->previous_character) {\
	current_character=current_character->previous_character;\
	suppress_this_character (current_character->next_character);\
	}\
	else {\
	suppress_this_character(current_character);\
	current_character=NULL;\
	}\
	  break;\
	}

/*

This is the macro that will determine the center, etc. for the first

*/

#define first_syllable()	  switch (first_letter) {\
case FIRST_LETTER:\
first_letter=SECOND_LETTER;\
break;\
case SECOND_LETTER:\
begin_center ()\
center_is_determined = DETERMINING_MIDDLE;\
first_letter=THIRD_LETTER;\
break;\
case THIRD_LETTER:\
end_center ()\
first_letter=0;\
center_is_determined = FULLY_DETERMINED;\
break;\
default:\
first_letter=0;\
break;\
}

/*

This function inserts a style before current_character, updating the double chained list.

*/

void insert_style_before (unsigned char type, unsigned char style) {
  gregorio_character *element =
    (gregorio_character *) malloc (sizeof (gregorio_character));
  element->is_character=0;
  element->cos.s.type=type;
  element->cos.s.style=style;
  element->next_character=current_character;
  if (current_character->previous_character) 
    {
      current_character->previous_character->next_character=element;
    }
  element->previous_character=current_character->previous_character;
  current_character->previous_character=element;
}

/*

This function puts a style after current_character, and updates current_character to the gregorio_character it created. It updates the double chained list. It does not touche to the det_styles list.

*/


void insert_style_after (unsigned char type, unsigned char style) {
  gregorio_character *element =
    (gregorio_character *) malloc (sizeof (gregorio_character));
  element->is_character=0;
  element->cos.s.type=type;
  element->cos.s.style=style;
  element->next_character=current_character->next_character;
  if (current_character->next_character) 
    {
      current_character->next_character->previous_character=element;
    }
  element->previous_character=current_character;
  current_character->next_character=element;
  current_character=element;
}

/*

This function suppresses the corresponding character, updates the double chained list, but does not touch to current_character.

*/

void suppress_this_character (gregorio_character *to_suppress) {
  if (to_suppress->previous_character) 
    {
        to_suppress->previous_character->next_character=to_suppress->next_character;
    }
  if (current_character->next_character) 
    {
	to_suppress->next_character->previous_character=to_suppress->previous_character;
    }
  free(to_suppress);
}


/*

THE big function. Very long, using a lot of long macros, etc. I hope you really want to understand it, 'cause it won't be easy.

*/

void
end_style_determination ()
{
  // a det_style, to walk through the list
  det_style *current_style = NULL;
  // a char that we will use in a very particular case
  unsigned char this_style;
  // a char that will be useful for the determination of iota and digamma
  unsigned char false_middle = 0;
  // so, here we start: we go to the first_character
  libgregorio_go_to_first_character(&current_character);
  // we loop until there isn't any character
  while (current_character)
    {
      // the first part of the function deals with real characters (not styles)
      if (current_character->is_character)
	{
      // the first case is when the user hasn't put { nor } (center_is_determined is 0), so we have to determine the center, and moreover it is the first_syllables. We call the good macro (see above).
	  if (center_is_determined!=FULLY_DETERMINED && center_is_determined!=HALF_DETERMINED && first_letter) 
	    {
	      first_syllable()
	      end_c ()
	    }
      // then, the second case is if the user has'nt determined the middle, and we have only seen vowels so far (else center_is_determined would be DETERMINING_MIDDLE). The current_character is the first vowel, so we start the center here.
	  if (!center_is_determined
	      && libgregorio_is_vowel (current_character->cos.character))
	    {
	      if (current_character->cos.character == L'i'
		  || current_character->cos.character == L'u')
		{
      // did you really think it would be that easy?... we have to deal with iota and digamma, that are not aligned the same way... So if the current character is i or u, we check if the next character is also a vowel or not. If it is the case we just pass, else we start the center there.
		  gregorio_character *temp = current_character->next_character;
		  while (temp)
		    {
		      if (temp->is_character)
			{
			 if (libgregorio_is_vowel (temp->cos.character))
			  {
			    false_middle = 1;
			    break;
			  }
			 else 
			  {
			    break;
			  }
			}
		      temp = temp->next_character;
		    }
		}
	      if (false_middle)
		{
	// the case of the iota or digamma
		  false_middle = 0;
		  // remember? this macro has a continue; in it
		  end_c ()
		}
	      begin_center ()
	      center_is_determined = DETERMINING_MIDDLE;
	      end_c ()
	    }
          // the case where the user has not determined the middle and we are in the middle section of the syllable, but there we encounter something that is not a vowel, so the center ends there.
	  if (center_is_determined == DETERMINING_MIDDLE
	      && !libgregorio_is_vowel (current_character->cos.character))
	    {
	      end_center ()
	      center_is_determined = FULLY_DETERMINED;
	    }
	  // in the case where it is just a normal character... we simply pass.
	  end_c ()
	}

// there starts the second part of the function that deals with the styles characters

      if (current_character->cos.s.type == ST_T_BEGIN
	  && current_character->cos.s.style != ST_CENTER)
	{
      // first, if it it the beginning of a style, which is not center. We check if the style is not already in the stack. If it is the case, we suppress the character and pass (with the good macro)
	  while (current_style
		 && current_style->style != current_character->cos.s.style)
	    {
	      current_style = current_style->next_style;
	    }
	  if (current_style)
	    {
	      current_style=first_style;
	      suppress_char_and_end_c ()
	    }
       // if it is something to add then we just push the style in the stack and continue.
	  push (current_character->cos.s.style);
	  current_style=first_style;
	  end_c ()
	}
      // if it is a beginning of a center, we call the good macro and end.
      if (current_character->cos.s.type == ST_T_BEGIN
	  && current_character->cos.s.style == ST_CENTER)
	{
	  if (center_is_determined)
	    {
	      end_c ()
	    }
	  //center_is_determined = DETERMINING_MIDDLE; // TODO: not really sure, but shouldn't be there
	  begin_center ()
	  end_c ()
	}
      if (current_character->cos.s.type == ST_T_END
	  && current_character->cos.s.style != ST_CENTER)
	{
	  // the case of the end of a style (the most complex). First, we have to see if the style is in the stack. If there is no stack, we just suppress and continue.
	  if (!current_style)
	    {
	      suppress_char_and_end_c ()
	    }
	  // so, we look if it is in the stack. If it is we put current_style to the style just before the style corresponding to the character that we are trating (still there ?)
	  if (current_style->style != current_character->cos.s.style)
	    {
	      while (current_style->next_style
		     && current_style->next_style->style !=
		     current_character->cos.s.style)
		{
		  current_style = current_style->next_style;
		}
	      if (current_style->next_style)
		{
		  current_style=first_style;
		  while (current_style)
		    {
		// if there are styles before in the stack, we close them
		      insert_style_before (ST_T_END, current_style->style);
		      current_style = current_style->previous_style;
		    }
		  current_style = first_style;
		  this_style = current_character->cos.s.style;
		// and then we reopen them
		  while (current_style && current_style->style != this_style)
		    {
		      insert_style_after (ST_T_BEGIN, current_style->style);
		      current_style = current_style->next_style;
		    }
		//we delete the style in the stack
		  pop(current_style);
		  current_style=first_style;
		}
	      else
		{
		  suppress_char_and_end_c ()
		}
	    }
	else {
	  pop (current_style);
	  current_style=first_style;
	  end_c ()
	}
	}
      else
	{// ST_T_END && ST_CENTER
	// a quite simple case, we just call the good macro.
	  if (!center_is_determined)
	    {
	      suppress_char_and_end_c ()
	    }
	}
      end_c ()
    }
  if (!current_character)
    {
      return;
    }
// we terminate all the styles that are still in the stack
  while (current_style)
    {
      insert_style_after (ST_T_END, current_style->style);
      current_style = current_style->next_style;
    }
// case where the syllable is composed of only one letter
  if (first_letter==SECOND_LETTER)
    {
      insert_style_after (ST_T_BEGIN, ST_CENTER);
      insert_style_after (ST_T_END, ST_CENTER);
      return;
    }
//current_character is at the end of the list now, so if we havn't closed the center, we do it at the end.
  if (center_is_determined != FULLY_DETERMINED)
    {
      insert_style_after (ST_T_END, ST_CENTER);
    }
// these last lines are for the case where the user didn't tell anything about the middle and there aren't any vowel in the syllable, so we begin the center before the first character (you can notice that there is no problem of style).
  if (!center_is_determined)
    {
      libgregorio_go_to_first_character (&current_character);
      insert_style_before (ST_T_BEGIN, ST_CENTER);
    }
// well.. you're quite brave if you reach this comment.
}



%}

%token ATTRIBUTE COLON SEMICOLON OFFICE_PART ANOTATION AUTHOR DATE MANUSCRIPT REFERENCE STORAGE_PLACE TRANSLATOR TRANSLATION_DATE STYLE VIRGULA_POSITION LILYPOND_PREAMBLE OPUSTEX_PREAMBLE MUSIXTEX_PREAMBLE MODE GREGORIOTEX_FONT SOFTWARE_USED NAME OPENING_BRACKET NOTES VOICE_CUT CLOSING_BRACKET NUMBER_OF_VOICES INITIAL_KEY VOICE_CHANGE END_OF_DEFINITIONS SPACE CHARACTERS I_BEGINNING I_END TT_BEGINNING TT_END B_BEGINNING B_END SC_BEGINNING SC_END SP_BEGINNING SP_END VERB_BEGINNING VERB VERB_END CENTER_BEGINNING CENTER_END CLOSING_BRACKET_WITH_SPACE TRANSLATION_BEGINNING TRANSLATION_END

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

gregoriotex_font_definition:
	GREGORIOTEX_FONT attribute {
	if (score->gregoriotex_font) {
	libgregorio_message(_("several GregorioTeX font definitions found, only the last will be taken into consideration"), "libgregorio_det_score",WARNING,0);
	}
	score->gregoriotex_font=$2;
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

mode_definition:
	MODE attribute {
	if (score->office_part) {
	libgregorio_message(_("several mode definitions found, only the last will be taken into consideration"), "libgregorio_det_score",WARNING,0);
	}
	if ($2)
	  {
	    score->mode=atoi($2);
	    free($2);
	  }
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
	mode_definition
	|
	gregoriotex_font_definition
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
	NOTES CLOSING_BRACKET_WITH_SPACE {
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
	update_position_with_space();
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

style_beginning:
	I_BEGINNING {
	add_style(ST_ITALIC);
	}
	|
	TT_BEGINNING {
	add_style(ST_TT);
	}
	|
	B_BEGINNING {
	add_style(ST_BOLD);
	}
	|
	SC_BEGINNING {
	add_style(ST_SMALL_CAPS);
	}
	|
	VERB_BEGINNING {
	add_style(ST_VERBATIM);
	}
	|
	SP_BEGINNING {
	add_style(ST_SPECIAL_CHAR);
	}
	|
	CENTER_BEGINNING {if (!center_is_determined) {
	add_style(ST_CENTER);
	center_is_determined=HALF_DETERMINED;
	}
	}
	;
	
style_end:
	I_END {
	end_style(ST_ITALIC);
	}
	|
	TT_END {
	end_style(ST_TT);
	}
	|
	B_END {
	end_style(ST_BOLD);
	}
	|
	SC_END {
	end_style(ST_SMALL_CAPS);
	}
	|
	VERB_END {
	end_style(ST_VERBATIM);
	}
	|
	SP_END {
	end_style(ST_SPECIAL_CHAR);
	}
	|
	CENTER_END {
	if (center_is_determined==HALF_DETERMINED) {
	  end_style(ST_CENTER);
	  center_is_determined=FULLY_DETERMINED;
	}
	}
	;

character:
	CHARACTERS {
	libgregorio_add_text($1, &current_character);
	}
	|
	style_beginning
	|
	style_end
	;
	
text:
	|text character
	;

translation_beginning:
    TRANSLATION_BEGINNING {
    start_translation();
    }
    ;

translation:
    translation_beginning text TRANSLATION_END {
    end_translation();
    }
    ;

syllable_with_notes:
	text OPENING_BRACKET notes {
	end_style_determination ();
    libgregorio_go_to_first_character(&current_character);
    first_text_character = current_character;
	close_syllable();
	}
	|
	text translation OPENING_BRACKET notes {
	close_syllable();
	}
	;

notes_without_word:
	OPENING_BRACKET notes {
	close_syllable();
	}
	|
	translation OPENING_BRACKET notes {
	close_syllable();
	}
	;

syllable:
	syllable_with_notes
	|
	notes_without_word
	;

syllables:
	|syllables syllable
	;
