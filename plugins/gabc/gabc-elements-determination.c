/* 
Gregorio element determination in gabc input.
Copyright (C) 2006 Elie Roux-2009 Elie Roux <elie.roux@telecom-bretagne.eu>

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
#include <gregorio/struct.h>
#include <gregorio/messages.h>

#include "gabc.h"

/*

two macros that will be useful in the future: they are the tests to put in a if statement to determine if a glyph type is puncta incliata ascendens or descendens

*/

#define is_puncta_ascendens(glyph) glyph==G_2_PUNCTA_INCLINATA_ASCENDENS||glyph==G_3_PUNCTA_INCLINATA_ASCENDENS||glyph==G_4_PUNCTA_INCLINATA_ASCENDENS||glyph==G_5_PUNCTA_INCLINATA_ASCENDENS||glyph==G_PUNCTUM_INCLINATUM

#define is_puncta_descendens(glyph) glyph==G_2_PUNCTA_INCLINATA_DESCENDENS||glyph==G_3_PUNCTA_INCLINATA_DESCENDENS||glyph==G_4_PUNCTA_INCLINATA_DESCENDENS||glyph==G_5_PUNCTA_INCLINATA_DESCENDENS||glyph==G_PUNCTUM_INCLINATUM


/*

Two "hat" functions, they permit to have a good API. They amost don't do anything except calling the det_elements_from_glyphs.

All those functions change the current_key, according to the possible new values (with key changes)

*/

gregorio_element *
libgregorio_gabc_det_elements_from_string (char *str, int *current_key)
{
  gregorio_element *final;
  gregorio_note *tmp;
  tmp = libgregorio_gabc_det_notes_from_string (str);
  final = libgregorio_gabc_det_elements_from_notes (tmp, current_key);
  return final;
}

gregorio_element *
libgregorio_gabc_det_elements_from_notes (gregorio_note * current_note, int *current_key)
{
  gregorio_element *final = NULL;
  gregorio_glyph *tmp = libgregorio_gabc_det_glyphs_from_notes (current_note, current_key);
  final = libgregorio_gabc_det_elements_from_glyphs (tmp);
  return final;
}


/*

A function that will be called several times: it adds an element to the current element
current_element: the current_element in the determination, it will be updated to the element that we will add
first_glyph: the first_glyph of the element that we will add
current_glyph: the last glyph that will be in the element
 
*/

void
close_element (gregorio_element ** current_element,
	       gregorio_glyph * first_glyph)
{
  gregorio_add_element (current_element, first_glyph);
  if (first_glyph && first_glyph->previous_glyph)
    {
      first_glyph->previous_glyph->next_glyph = NULL;
      first_glyph->previous_glyph = NULL;
    }
}

/*

a macro that do automatically two or three things

*/

#define cut_before() if (first_glyph!=current_glyph) {\
close_element(&current_element,first_glyph);\
first_glyph =current_glyph;\
previous_glyph=current_glyph;\
}

/*

The big function of the file, but rather simple I think.

*/

gregorio_element *
libgregorio_gabc_det_elements_from_glyphs (gregorio_glyph * current_glyph)
{
// the last element we have successfully added to the list of elements
  gregorio_element *current_element = NULL;
// the first element, that we will return at the end. We have to consider it because the gregorio_element struct does not have previous_element element.
  gregorio_element *first_element = NULL;
// the first_glyph of the element that we are currently determining
  gregorio_glyph *first_glyph = current_glyph;
// the last real (GRE_GLYPH) that we have processed, often the same as first_glyph
  gregorio_glyph *previous_glyph = current_glyph;
// a char that is necessary to determine some cases
  char do_not_cut = 0;
// a char that is necesarry to determine the type of the current_glyph
  char current_glyph_type;

  if (!current_glyph)
    {
      return NULL;
    }
// first we go to the first glyph in the chained list of glyphs (maybe to suppress ?)
  gregorio_go_to_first_glyph (&current_glyph);


  while (current_glyph)
    {
      if (current_glyph->type != GRE_GLYPH)
	{
	  //we ignore flats and naturals, except if they are alone
	  if (current_glyph->type == GRE_NATURAL
	      || current_glyph->type == GRE_FLAT)
	    {
          if (current_glyph->next_glyph)
            {
              current_glyph = current_glyph->next_glyph;
	          continue;
            }
          else 
            {
              first_element = current_element;
              close_element (&current_element, first_glyph);
              current_glyph = current_glyph->next_glyph;
              continue;
            }
	    }
	  //we must not cut after a zero_width_space
	  if (current_glyph->type == GRE_SPACE
	      && current_glyph->glyph_type == SP_ZERO_WIDTH)
	    {
	      current_glyph = current_glyph->next_glyph;
	      do_not_cut = 1;
	      continue;
	    }
	    // clef change or space or end of line
	      cut_before();
	  //if statement to make neumatic cuts not appear in elements, as there is always one between elements  
	  if (current_glyph->type != GRE_SPACE
	      || current_glyph->glyph_type != SP_NEUMATIC_CUT)
	    //clef change or space other thant neumatic cut
	    {
	      if (!first_element)
		{
		  first_element = current_element;
		}
	      gregorio_add_special_as_element (&current_element,
						  current_glyph->type,
						  current_glyph->glyph_type, current_glyph->liquescentia);
	    }
	  else {
	
	}
	  first_glyph = current_glyph->next_glyph;
	  previous_glyph = current_glyph->next_glyph;
	  gregorio_free_one_glyph (&current_glyph);
	  continue;
	}

      if (is_puncta_ascendens(current_glyph->type))
	{
	  current_glyph_type = G_PUNCTA_ASCENDENS;
	}
      else
	{
	  if (is_puncta_descendens(current_glyph->type))
	    {
	      current_glyph_type = G_PUNCTA_DESCENDENS;
	    }
	  else
	    {
	      current_glyph_type = current_glyph->type;
	    }
	}
      switch (current_glyph_type)
	{
	case G_PUNCTA_ASCENDENS:
	  if (!do_not_cut)
	    {
	      cut_before ()
	      do_not_cut = 1;
	    }
	  else
	    {
	      previous_glyph = current_glyph;
	    }
	  break;
	case G_PUNCTA_DESCENDENS:
// we don't cut before, so we don't do anything
	  if (do_not_cut)
	    {
	      do_not_cut = 0;
	    }
	  break;
	case G_ONE_NOTE:
	  if (current_glyph->first_note
	      && (current_glyph->first_note->shape == S_STROPHA
		  || current_glyph->first_note->shape == S_VIRGA))
	    {
// we determine the last pitch
	      char last_pitch;
	      gregorio_note *tmp_note;
	      tmp_note = previous_glyph->first_note;
	      while (tmp_note->next_note)
		{
		  tmp_note = tmp_note->next_note;
		}
	      last_pitch = tmp_note->pitch;
	      if (current_glyph->first_note->pitch == last_pitch)
		{
		  previous_glyph = current_glyph;
		  break;
		}
	    }
//else we fall in the default case
	default:
	  if (do_not_cut)
	    {
	      do_not_cut = 0;
	    }
	  else
	    {
	      cut_before ()
	    }
	}

/* we must determine the first element, that we will return */
      if (!first_element && current_element)
	{
	  first_element = current_element;
	}
      if (!current_glyph->next_glyph)
	{
	  close_element (&current_element, first_glyph);
	}
      current_glyph = current_glyph->next_glyph;
    }				//end of while

/* we must determine the first element, that we will return */
  if (!first_element && current_element)
    {
      first_element = current_element;
    }
  return first_element;
}
