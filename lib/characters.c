/* 
Gregorio structure manipulation file.
Copyright (C) 2008 Elie Roux <elie.roux@telecom-bretagne.eu>

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

/**
 * @file
 * @brief This file contains almost all the gregorio_character manipulation things.
 *
 * @warning The code is very spaghetti, but I don't really think I can do it another way with the chosen representation of styles, and the fact that everything must be xml-compliant and tex-compliant...
 * So this file is basically very hard to maintain. Moreover, it has not been very well coded, so it is even harder to maintain...
 */

#include "config.h"
#include <stdio.h>
#include <stdlib.h>
#include <gregorio/struct.h>
#include <gregorio/unicode.h>
#include <gregorio/characters.h>
#include <gregorio/messages.h>

/*!
 * @brief Tests if a letter is a vowel or not. 
 * 
 * Necessary for determining proper centering, as we want the first neume centered over the vowel. Simple, we just compare \c letter to a list of vowels used in Latin, both accented and not.
 * \param letter The letter being tested
 * \return returns \c 1 if a vowel; otherwise returns \c 0
 */
int
gregorio_is_vowel (grewchar letter)
{
  grewchar vowels[] = { L'a', L'e', L'i', L'o', L'u', L'y', L'A', L'E',
    L'I', 'O', 'U', 'Y', L'œ', L'Œ', L'æ', L'Æ', L'ó', L'À', L'È',
    L'É', L'Ì', L'Í', L'Ý', L'Ò', L'Ó', L'è', L'é', L'ò', L'ú',
    L'ù', L'ý', L'á', L'à', L'ǽ', L'Ǽ', L'í', L'ë', L'*'
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

// a macro that will be used for verbatim and special-characters in the next function, it calls function with a grewchar * which is the verbatim or special-character. It places current_character to the character next to the end of the verbatim or special_char charachters.
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
		  text = (grewchar *) malloc ((i + 1) * sizeof (grewchar));\
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
		  text[i] = 0;\
		  function (f, text);\
		  free (text);



/**
 * This function is made to simplify the output modules : they just have to declare some simple functions (what to do when meeting a beginning of style, a character, etc.) and to call this function with pointer to these functions, and that will automatically write the good ouput. This function does not test at all the gregorio_character list, if it is wrong, then the ouput will be wrong. It is very simple to understand, even if it is a bit long.
 * type may be 0, or SKIP_FIRST_LETTER
 * 
 * @warning The difficulty comes when we have to write the first syllable text, without the first letter.
 * The behaviour can have some bugs is this case if the first syllable has some complex styles. It would be a bit stupid to do such a thing, but users are usually very creative when it comes to inventing twisted things...
 */
void
gregorio_write_text (char type, gregorio_character * current_character,
		     FILE * f, void (*printverb) (FILE *, grewchar *),
		     void (*printchar) (FILE *, grewchar),
		     void (*begin) (FILE *, unsigned char),
		     void (*end) (FILE *, unsigned char),
		     void (*printspchar) (FILE *, grewchar *))
{
  grewchar *text;
  int i, j;
  gregorio_character *begin_character;

  if (current_character == NULL)
    {
      return;
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
		  verb_or_sp (ST_VERBATIM, printverb);
		  break;
		case ST_SPECIAL_CHAR:
		  verb_or_sp (ST_SPECIAL_CHAR, printspchar);
		  break;
		case ST_INITIAL:
		  if (type == SKIP_FIRST_LETTER)
		    {
		      while (current_character)
			{
			  if (!current_character->is_character
			      && current_character->cos.s.type == ST_T_END
			      && current_character->cos.s.style == ST_INITIAL)
			    {
			      break;
			    }
			  current_character =
			    current_character->next_character;
			}
		    }
		  else
		    {
		      begin (f, ST_INITIAL);
		    }
		  break;
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


// the default behaviour is to write only the initial, that is to say things between the styles ST_INITIAL
void
gregorio_write_initial (gregorio_character * current_character,
			FILE * f, void (*printverb) (FILE *,
						     grewchar *),
			void (*printchar) (FILE *, grewchar),
			void (*begin) (FILE *, unsigned char),
			void (*end) (FILE *, unsigned char),
			void (*printspchar) (FILE *, grewchar *))
{
  int i, j;
  grewchar *text;
  gregorio_character *begin_character;
  // we loop until we see the beginning of the initial style
  gregorio_go_to_first_character (&current_character);
  while (current_character)
    {
      if (!current_character->is_character
	  && current_character->cos.s.type == ST_T_BEGIN
	  && current_character->cos.s.style == ST_INITIAL)
	{
	  current_character = current_character->next_character;
	  break;
	}

      current_character = current_character->next_character;
    }
  // then we loop until we see the end of the initial style, but we print
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
		  verb_or_sp (ST_VERBATIM, printverb);
		  break;
		case ST_SPECIAL_CHAR:
		  verb_or_sp (ST_SPECIAL_CHAR, printspchar);
		  break;
		default:
		  begin (f, current_character->cos.s.style);
		  break;
		}
	    }
	  else
	    {			// ST_T_END
	      if (current_character->cos.s.style == ST_INITIAL)
		{
		  return;
		}
	      else
		{
		  end (f, current_character->cos.s.style);
		}
	    }
	}
      current_character = current_character->next_character;
    }
}

/*

A very simple function that returns the first text of a score, or the null character if there is no such thing.

*/

gregorio_character *
gregorio_first_text (gregorio_score * score)
{
  gregorio_syllable *current_syllable;
  if (!score || !score->first_syllable)
    {
      gregorio_message (_("unable to find the first letter of the score"),
			"gregorio_first_text", ERROR, 0);
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
		    "gregorio_first_text", ERROR, 0);
  return NULL;
}

// gives the first letter of a score.

grewchar
gregorio_first_letter (gregorio_score * score)
{
  gregorio_syllable *current_syllable;
  gregorio_character *current_character;
  if (!score || !score->first_syllable)
    {
      gregorio_message (_("unable to find the first letter of the score"),
			"gregorio_first_letter", ERROR, 0);
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
		    "gregorio_first_letter", ERROR, 0);
  return L'\0';
}

/// the variable that will decide if we're writing old or modern style \n
/// It is set by gregorio_set_tex_write() and used in gregorio_write_one_tex_char()
unsigned char tex_write = WRITE_UTF_TEX;

void
gregorio_set_tex_write(unsigned char new)
{
    if (new == WRITE_OLD_TEX)
      {
        tex_write = WRITE_OLD_TEX;
      }
    else
      {
        tex_write = WRITE_UTF_TEX;
      }
}

/*!
 * A function to print one character in TeX. The reason of this function is that
 * sometimes you need gregorio to write \char 232 (because of some bugs) and
 *sometimes é, directly in utf8.
 *
 */
void
gregorio_write_one_tex_char (FILE * f, grewchar to_print)
{
    if (tex_write == WRITE_OLD_TEX) 
      {
        gregorio_write_one_tex_char_old (f, to_print);
      }
    else
      {
        gregorio_write_one_tex_char_utf (f, to_print);
      } 
}

// the function uses one of the following functions:

void
gregorio_write_one_tex_char_old (FILE * f, grewchar to_print)
{
      if (to_print < 128)
    {
      gregorio_print_unichar (f, to_print);
      return;
    }
    fprintf(f, "\\char %d", to_print);
}

void
gregorio_write_one_tex_char_utf (FILE * f, grewchar to_print)
{
    gregorio_print_unichar (f, to_print);
}

// this function sets the pointer

/* Here starts the code of the handling of text and styles.

This part is not the easiest, in fact is is the most complicated. The reason is that I want to make something coherent in memory (easy to interprete), and to let the user type whatever he wants. This part was originally written for gabc, that's why it's always talking about it. But it could as well be used by other read plugins, to put things in order.

Basically all the following lines of code are made for the last function, that will take a "user-written" gregorio_character list into a xml-compliant and tex-compliant list. It's more complicated than it seems...

Functionalities: For example if the user types tt<i>ttt<b>ttt</i>tt I want it to be represented as tt<i>ttt<b>ttt</b></i><b>tt</b>. The fabulous thing is that it is xml-compliant. This part also determines the middle, for example pot will be interpreted as p{o}t. When I did that I also thought about TeX styles that needed things like {p}{o}{t}, so when the user types <i>pot</i>, it is interpreted as <i>p</i>{<i>o</i>}<i>t</i>.

Internal structure: To do so we have a structure, det_style, that will help us : it is a stack (double chained list) of the styles that we have seen until now. When we encounter a <i>, we push the i style on the stack. If we encounter a </i> we suppress the i style from the stack. Let's take a more complex example: if we encounter <i><b></i>, the stack will be first null, then i then bi, and there we want to end i, but it is not the first style of the stack, so we close all the styles that we encounter before we encounter i (remember, this is for xml-compliance), so we insert a </b> before the </i>. But that's not all, we also write a <b> after the </i>, so that the b style continues. There our stack is just b. For center, we just close all the styles in the stack, insert a { and reopen all the styles in the stack.

The structure used for character, styles, etc. is described in include/struct.h

The functionment in this file is quite simple : we add all the characters that we see, even if they are incoherent, in the gregorio_character list, and then we call a very complex function that will build a stack of the style, determine the middle, make all xml-compliant, mow the lawn, etc.

This code is *really* spaghetti, but I think it's a necessary pain.

*/

/*
The push function pushes a style in the stack, and updates first_style to this element.
*/

void
gregorio_style_push (det_style ** current_style, unsigned char style)
{
  det_style *element;
  if (!current_style)
    {
      return;
    }
  element = (det_style *) malloc (sizeof (det_style));
  element->style = style;
  element->previous_style = NULL;
  element->next_style = (*current_style);
  if (*current_style)
    {
      (*current_style)->previous_style = element;
    }
  (*current_style) = element;
}

/*
Pop deletes an style in the stack (the style to delete is the parameter)
*/

void
gregorio_style_pop (det_style ** first_style, det_style * element)
{
  if (!element || !first_style || !*first_style)
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
	  (*first_style) = element->next_style;
	}
      else
	{
	  (*first_style) = NULL;
	}
    }
  free (element);
}

/*
free_styles just free the stack. You may notice that it will never be used in a normal functionment. But we never know...
*/

void
gregorio_free_styles (det_style ** first_style)
{
  det_style *current_style;
  if (!first_style)
    {
      return;
    }
  current_style = (*first_style);
  while (current_style)
    {
      current_style = current_style->next_style;
      free ((*first_style));
      (*first_style) = current_style;
    }
}



/*

Then start the macros for the big function. the first one is the macro we call when we close a style. The magic thing is that is will prevent things like a<i></i>{<i>b</b>: when the user types a<i>b</i>, if the middle is between a and b (...), it will interpret it as a{<i>b</i>.

*/

#define close_style() if (!current_character->previous_character->is_character && current_character->previous_character->cos.s.style==current_style->style) {\
/* we suppose that there is a previous_character, because there is a current_style*/\
gregorio_suppress_this_character(current_character->previous_character);\
}\
else {\
gregorio_insert_style_before(ST_T_END, current_style->style, current_character);\
}

/*

next the macro called when we have determined that we must end the center here : it closes all styles, adds a } and then reopens all styles.

*/

// type is ST_CENTER or ST_FORCED_CENTER
#define end_center(type) while (current_style)\
	    {\
	      close_style ()\
	if (current_style->next_style) {\
	      current_style = current_style->next_style;\
	}\
	else {\
	break;\
	}\
	    }\
	  gregorio_insert_style_before (ST_T_END, type, current_character);\
	  while (current_style)\
	    {\
	      gregorio_insert_style_before (ST_T_BEGIN, current_style->style, current_character);\
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

#define begin_center(type) while (current_style)\
	    {\
	      close_style ()\
	if (current_style->next_style) {\
	      current_style = current_style->next_style;\
	}\
	else {\
	break;\
	}\
	    }\
	  gregorio_insert_style_before (ST_T_BEGIN, type, current_character);\
	  while (current_style)\
	    {\
	      gregorio_insert_style_before (ST_T_BEGIN, current_style->style, current_character);\
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
	gregorio_suppress_this_character (current_character->previous_character);\
	  continue;\
	}\
	else {\
	if (current_character->previous_character) {\
	current_character=current_character->previous_character;\
	gregorio_suppress_this_character (current_character->next_character);\
	}\
	else {\
	gregorio_suppress_this_character(current_character);\
	current_character=NULL;\
	}\
	  break;\
	}

/*

This function inserts a style before current_character, updating the double chained list.

*/

void
gregorio_insert_style_before (unsigned char type, unsigned char style,
			      gregorio_character * current_character)
{
  gregorio_character *element =
    (gregorio_character *) malloc (sizeof (gregorio_character));
  element->is_character = 0;
  element->cos.s.type = type;
  element->cos.s.style = style;
  element->next_character = current_character;
  if (current_character->previous_character)
    {
      current_character->previous_character->next_character = element;
    }
  element->previous_character = current_character->previous_character;
  current_character->previous_character = element;
}

/*

This function puts a style after current_character, and updates current_character to the gregorio_character it created. It updates the double chained list. It does not touche to the det_styles list.

*/


void
gregorio_insert_style_after (unsigned char type, unsigned char style,
			     gregorio_character ** current_character)
{
  gregorio_character *element =
    (gregorio_character *) malloc (sizeof (gregorio_character));
  element->is_character = 0;
  element->cos.s.type = type;
  element->cos.s.style = style;
  element->next_character = (*current_character)->next_character;
  if ((*current_character)->next_character)
    {
      (*current_character)->next_character->previous_character = element;
    }
  element->previous_character = (*current_character);
  (*current_character)->next_character = element;
  (*current_character) = element;
}

void
gregorio_insert_char_after (grewchar c,
			     gregorio_character ** current_character)
{
  gregorio_character *element =
    (gregorio_character *) malloc (sizeof (gregorio_character));
  element->is_character = 1;
  element->cos.character = c;
  element->next_character = (*current_character)->next_character;
  if ((*current_character)->next_character)
    {
      (*current_character)->next_character->previous_character = element;
    }
  element->previous_character = (*current_character);
  (*current_character)->next_character = element;
  (*current_character) = element;
}

/*

This function suppresses the corresponding character, updates the double chained list, but does not touch to current_character.

*/

void
gregorio_suppress_this_character (gregorio_character * to_suppress)
{
  if (!to_suppress)
    {
      return;
    }
  if (to_suppress->previous_character)
    {
      to_suppress->previous_character->next_character =
	to_suppress->next_character;
    }
  if (to_suppress->next_character)
    {
      to_suppress->next_character->previous_character =
	to_suppress->previous_character;
    }
  free (to_suppress);
}

/*

This function suppresses the current character, updates the double chained list, and updates current_character to the character after, if there is one.

*/

void
gregorio_suppress_current_character (gregorio_character ** current_character)
{
  gregorio_character *thischaracter;
  if (!current_character || !*current_character)
    {
      return;
    }
  thischaracter = *current_character;
  if ((*current_character)->previous_character)
    {
      (*current_character)->previous_character->next_character =
	(*current_character)->next_character;
    }
  if ((*current_character)->next_character)
    {
      (*current_character)->next_character->previous_character =
	(*current_character)->previous_character;
    }
  (*current_character) = (*current_character)->next_character;
  free (thischaracter);
}

/*

THE big function. Very long, using a lot of long macros, etc. I hope you really want to understand it, 'cause it won't be easy.

current character is a pointer to a gregorio_character. The gregorio_character double-chained list it is in will be totally reorganized so that it is xml compliant, and the function will update it to the first character of this brand new list.

center_is_determined has the values present in characters.h.

Another difficulty is the fact that we must consider characters in verbatim and special character styles like only one block, we can't say the center is in the middle of a verbatim block.

29/11/10: there is now the possibility to choose between two centering schemes:
  - latine is the one used before
  - english is a new scheme where the whole syllable (except for forced centering) is centered

*/

void
gregorio_rebuild_characters (gregorio_character ** param_character,
			     char center_is_determined, unsigned char centering_scheme)
{
  // a det_style, to walk through the list
  det_style *current_style = NULL;
  // the current_character
  gregorio_character *current_character = *param_character;
  // a char that we will use in a very particular case
  unsigned char this_style;
  // a char that will be useful for the determination of iota and digamma
  unsigned char false_middle = 0;
  det_style *first_style = NULL;
  unsigned char center_type = 0;	// determining the type of centering (forced or not)
  // so, here we start: we go to the first_character
  gregorio_go_to_first_character (&current_character);
  // first we see if there is already a center determined
  if (center_is_determined == 0)
    {
      center_type = ST_CENTER;
    }
  else
    {
      center_type = ST_FORCED_CENTER;
    }
  // if there is no forced centering, we open the centering before the very first letter
  if (centering_scheme == SCHEME_ENGLISH && center_type == ST_CENTER)
    {
      gregorio_insert_style_before (ST_T_BEGIN, ST_CENTER, current_character);
      center_is_determined = CENTER_FULLY_DETERMINED;
    }
  // we loop until there isn't any character
  while (current_character)
    {
      // the first part of the function deals with real characters (not styles)
      if (current_character->is_character)
	{
	  // the firstcase is if the user has'nt determined the middle, and we have only seen vowels so far (else center_is_determined would be DETERMINING_MIDDLE). The current_character is the first vowel, so we start the center here.
	  if (!center_is_determined
	      && gregorio_is_vowel (current_character->cos.character))
	    {
	      if (current_character->cos.character == L'i'
		  || current_character->cos.character == L'I'
		  || current_character->cos.character == L'u')
		{
		  // did you really think it would be that easy?... we have to deal with iota and digamma, that are not aligned the same way... So if the current character is i or u, we check if the next character is also a vowel or not. If it is the case we just pass, else we start the center there.
		  gregorio_character *temp =
		    current_character->next_character;
		  while (temp)
		    {
		      if (temp->is_character)
			{
			  if (gregorio_is_vowel (temp->cos.character))
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
		  end_c ();
		}
	      begin_center (center_type);
	      center_is_determined = CENTER_DETERMINING_MIDDLE;
	      end_c ();
	    }
	  // the case where the user has not determined the middle and we are in the middle section of the syllable, but there we encounter something that is not a vowel, so the center ends there.
	  if (center_is_determined == CENTER_DETERMINING_MIDDLE
	      && !gregorio_is_vowel (current_character->cos.character))
	    {
	      end_center (center_type);
	      center_is_determined = CENTER_FULLY_DETERMINED;
	    }
	  // in the case where it is just a normal character... we simply pass.
	  end_c ();
	}
// there starts the second part of the function that deals with the styles characters
      if (current_character->cos.s.type == ST_T_BEGIN
	  && current_character->cos.s.style != ST_CENTER
	  && current_character->cos.s.style != ST_FORCED_CENTER)
	{
	  // first, if it it the beginning of a style, which is not center. We check if the style is not already in the stack. If it is the case, we suppress the character and pass (with the good macro)
	  while (current_style
		 && current_style->style != current_character->cos.s.style)
	    {
	      current_style = current_style->next_style;
	    }
	  if (current_style)
	    {
	      current_style = first_style;
	      suppress_char_and_end_c ();
	    }
	  // if we are determining the end of the middle and we have a VERBATIM or SPECIAL_CHAR style, we end the center determination
	  if ((current_character->cos.s.style == ST_VERBATIM
	      || current_character->cos.s.style == ST_SPECIAL_CHAR)
	      && center_is_determined == CENTER_DETERMINING_MIDDLE)
	    {
	      end_center (center_type);
	      center_is_determined = CENTER_FULLY_DETERMINED;
	    }
	  // if it is something to add then we just push the style in the stack and continue.
	  gregorio_style_push (&first_style, current_character->cos.s.style);
	  current_style = first_style;
	  // Here we pass all the characters after a verbatim (or special char) beginning, until we find a style (begin or end)
	  if (current_character->cos.s.style == ST_VERBATIM
	      || current_character->cos.s.style == ST_SPECIAL_CHAR)
	    {
	      if (current_character->next_character)
	        {
	          current_character = current_character->next_character;
	        }
	      while (current_character->next_character
		     && current_character->is_character)
		{
		  current_character = current_character->next_character;
		}
	    }
	  else
	    {
	      end_c ();
	    }
	}
      // if it is a beginning of a center, we call the good macro and end.
      if (current_character->cos.s.type == ST_T_BEGIN
	  && (current_character->cos.s.style == ST_CENTER
	      || current_character->cos.s.style == ST_FORCED_CENTER))
	{
	  if (current_character->cos.s.style == ST_CENTER)
	    {
	      center_type = ST_CENTER;
	    }
	  else
	    {
	      center_type = ST_FORCED_CENTER;
	    }
	  if (center_is_determined)
	    {
	      end_c ();
	    }
	  //center_is_determined = DETERMINING_MIDDLE; // TODO: not really sure, but shouldn't be there
	  begin_center (center_type) end_c ();
	}
      if (current_character->cos.s.type == ST_T_END
	  && current_character->cos.s.style != ST_CENTER
	  && current_character->cos.s.style != ST_FORCED_CENTER)
	{
	  // the case of the end of a style (the most complex). First, we have to see if the style is in the stack. If there is no stack, we just suppress and continue.
	  if (!current_style)
	    {
	      suppress_char_and_end_c ();
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
		  current_style = first_style;
		  while (current_style)
		    {
		      // if there are styles before in the stack, we close them
		      gregorio_insert_style_before (ST_T_END,
						    current_style->style,
						    current_character);
		      current_style = current_style->previous_style;
		    }
		  current_style = first_style;
		  this_style = current_character->cos.s.style;
		  // and then we reopen them
		  while (current_style && current_style->style != this_style)
		    {
		      gregorio_insert_style_after (ST_T_BEGIN,
						   current_style->style,
						   &current_character);
		      current_style = current_style->next_style;
		    }
		  //we delete the style in the stack
		  gregorio_style_pop (&first_style, current_style);
		  current_style = first_style;
		}
	      else
		{
		  suppress_char_and_end_c ();
		}
	    }
	  else
	    {
	      gregorio_style_pop (&first_style, current_style);
	      current_style = first_style;
	      end_c ();
	    }
	}
      else
	{			// ST_T_END && ST_CENTER
	  // a quite simple case, we just call the good macro.
	  if (!center_is_determined)
	    {
	      suppress_char_and_end_c ();
	    }
	}
      end_c ();
    }
  if (!current_character)
    {
      return;
    }
// we terminate all the styles that are still in the stack
  while (current_style)
    {
      gregorio_insert_style_after (ST_T_END, current_style->style,
				   &current_character);
      current_style = current_style->next_style;
    }
//current_character is at the end of the list now, so if we havn't closed the center, we do it at the end.
  if (center_is_determined != CENTER_FULLY_DETERMINED)
    {
      gregorio_insert_style_after (ST_T_END, center_type, &current_character);
    }
  // these three lines are for the case where the user didn't tell anything about the middle and there aren't any vowel in the syllable, so we begin the center before the first character (you can notice that there is no problem of style).
  if (!center_is_determined)
    {
      gregorio_go_to_first_character (&current_character);
      gregorio_insert_style_before (ST_T_BEGIN, ST_CENTER, current_character);
    }
  if (centering_scheme == SCHEME_ENGLISH && center_type == ST_CENTER)
    {
      gregorio_insert_style_after (ST_T_END, ST_CENTER, &current_character);
    }
  // well.. you're quite brave if you reach this comment.
  gregorio_go_to_first_character (&current_character);
  (*param_character) = current_character;
  gregorio_free_styles (&first_style);
}

/**
 * @brief This function will determine the behaviour of gregorio when it comes to the recognition of the initial. 
 * 
 * Basically it will take a gregorio_character list and return the same list, but with a style added : ST_INITIAL. This style will incidate the initial. The center will be placed at the second letter, unless there is a FORCED_CENTER somewhere. 
 * Finally all will be xml-compliant and tex-compliant when we call gregorio_rebuild_characters.
 *
 * If we note <> for the initial and {} for the center, here is what we want:
 *
 * @li \verbatim Po -> <P>{o} \endverbatim
 * @li \verbatim {A}b -> <>{A}b \endverbatim
 * @li \verbatim {}a -> <>{}a \endverbatim
 * @li \verbatim Glo -> <G>{l}o \endverbatim
 * @li \verbatim Gl{o} -> <G>l{o} \endverbatim
 *
 * @param param_character is a pointer to the (pointer to the) first character, it will be modified so that it points to the new first character.
 */
void
gregorio_rebuild_first_syllable (gregorio_character ** param_character)
{
  // the current_character
  gregorio_character *current_character = *param_character;
  unsigned char forced_center = 0;
  unsigned char letter = 0;	// the letter we are at
  // so, here we start: we go to the first_character
  gregorio_go_to_first_character (&current_character);
  // first we look at the styles, to see if there is a FORCED_CENTER somewhere
  if (!param_character)
    {
      return;
    }
  while (current_character)
    {
      if (!current_character->is_character)
	{
	  if (current_character->cos.s.style == ST_FORCED_CENTER)
	    {
	      forced_center = 1;
	      // we can break here, as there won't be forced center plus center
	      break;
	    }
	}
      current_character = current_character->next_character;
    }
  current_character = *param_character;
  gregorio_go_to_first_character (&current_character);
  // now we are going to place the two INITIAL styles (begin and end)
  while (current_character)
    {
      if (!current_character->is_character
	  && current_character->cos.s.style == ST_FORCED_CENTER
	  && letter == 0)
	{
	  // we don't touch anything after a FORCED_CENTER, so we put an empty INITIAL style just before
	  gregorio_insert_style_before (ST_T_BEGIN, ST_INITIAL,
					current_character);
	  current_character = current_character->previous_character;
	  gregorio_insert_style_after (ST_T_END, ST_INITIAL,
				       &current_character);
	  break;
	}
	// this if is a hack to make gregorio consider verbatim blocks and special chars like one block, not a sequence of letters
	  if (!current_character->is_character
	  && current_character->cos.s.type == ST_T_BEGIN
	  && (current_character->cos.s.style == ST_VERBATIM
	  || current_character->cos.s.style == ST_SPECIAL_CHAR))
	  
	{
          if (letter == 0)
	    {
	      letter = 1;
	      gregorio_insert_style_before (ST_T_BEGIN, ST_INITIAL,
					    current_character);
	      if (current_character->next_character)
		{
		  current_character = current_character->next_character;
		}
	      while(current_character->next_character && current_character->is_character)
		{
		  current_character = current_character->next_character;
		}
	      gregorio_insert_style_after (ST_T_END, ST_INITIAL,
					   &current_character);
	      break;
	    }
	}
      if (current_character->is_character && letter == 0)
	{
	  letter = 1;
	  gregorio_insert_style_before (ST_T_BEGIN, ST_INITIAL,
					current_character);
	  gregorio_insert_style_after (ST_T_END, ST_INITIAL,
				       &current_character);
	  break;
	}
      current_character = current_character->next_character;
    }
  current_character = *param_character;
  gregorio_go_to_first_character (&current_character);
  (*param_character) = current_character;
}
