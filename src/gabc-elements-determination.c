/* 
Gregorio element determination in gabc input.
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
#include "struct.h"
#include "gabc.h"
#include "messages.h"



#define is_puncta_ascendens(glyph) glyph==G_2_PUNCTA_INCLINATA_ASCENDENS||glyph==G_3_PUNCTA_INCLINATA_ASCENDENS||glyph==G_4_PUNCTA_INCLINATA_ASCENDENS||glyph==G_5_PUNCTA_INCLINATA_ASCENDENS||glyph==G_PUNCTUM_INCLINATUM

#define is_puncta_descendens(glyph) glyph==G_2_PUNCTA_INCLINATA_DESCENDENS||glyph==G_3_PUNCTA_INCLINATA_DESCENDENS||glyph==G_4_PUNCTA_INCLINATA_DESCENDENS||glyph==G_5_PUNCTA_INCLINATA_DESCENDENS||glyph==G_PUNCTUM_INCLINATUM


//works only with the good values in the header file
#define mix_element_types(current_element,added_element) \
current_element+added_element

char
add_glyph_to_an_element (char element_type, char current_glyph_type,
			 char last_glyph_type, char last_pitch,
			 char next_pitch, char *end_of_element);

void
close_element (gregorio_element ** current_element, char element_type,
	       gregorio_glyph ** first_glyph, gregorio_glyph * current_glyph,
	       char liquescentia);

gregorio_element *
libgregorio_gabc_det_elements_from_string (char *str)
{
  gregorio_element *final;
  gregorio_note *tmp;
  tmp = libgregorio_gabc_det_notes_from_string (str);
  final = libgregorio_gabc_det_elements_from_notes (tmp);
  return final;
}

gregorio_element *
libgregorio_gabc_det_elements_from_notes (gregorio_note * current_note)
{
  gregorio_element *final = NULL;
  gregorio_glyph *tmp = libgregorio_gabc_det_glyphs_from_notes (current_note);
  final = libgregorio_gabc_det_elements_from_glyphs (tmp);
  return final;
}

/****************************
 * attention, commentaires qui tuent à placer ici...
 * 
 * 
 * 
****************************/

void
close_element (gregorio_element ** current_element, char element_type,
	       gregorio_glyph ** first_glyph, gregorio_glyph * current_glyph,
	       char liquescentia)
{
  libgregorio_add_element (current_element, element_type, *first_glyph,
			   liquescentia);
  if (current_glyph->next_glyph)
    {
      current_glyph->next_glyph->previous_glyph = NULL;
      *first_glyph = current_glyph->next_glyph;
      current_glyph->next_glyph = NULL;
    }
}

/****************************
 * attention, commentaires qui tuent à placer ici...
 * 
 * a bit diffucult to understant, I admit...
 * bien expliquer que le glyphe en cours est déjà incorporé à l'élément, pas comme dans glyph_determination
 * 
****************************/

gregorio_element *
libgregorio_gabc_det_elements_from_glyphs (gregorio_glyph * current_glyph)
{

  if (!current_glyph)
    {
//TODO warning
      return NULL;
    }
  libgregorio_go_to_first_glyph (&current_glyph);
  gregorio_element *current_element = NULL;
  gregorio_note *tmp_note;
  gregorio_element *first_element = NULL;
  gregorio_glyph *first_glyph = current_glyph;
  gregorio_glyph *next_glyph = NULL;
  char current_element_type = ELT_NO_ELEMENT;
  char liquescentia = L_NO_LIQUESCENTIA;
  char previous_glyph_type = G_UNDETERMINED;
  char next_element_type = ELT_NO_ELEMENT;
  char end_of_element;
  char last_pitch;
  char next_pitch;

  while (current_glyph)
    {
      next_glyph = current_glyph->next_glyph;

      if (current_glyph->type != GRE_GLYPH)
	{
	  //we ignore flats and naturals
	  if (current_glyph->type == GRE_NATURAL
	      || current_glyph->type == GRE_FLAT)
	    {
	      current_glyph = next_glyph;
	      continue;
	    }
	  //we pass zero-width-spaces, they will be treated later (in this function)
	  if (current_glyph->type == GRE_SPACE
	      && current_glyph->glyph_type == SP_ZERO_WIDTH)
	    {
	      current_glyph = next_glyph;
	      continue;
	    }
	  if (current_element_type != ELT_NO_ELEMENT)
	// clef change or space or end of line
	    {
	      close_element (&current_element, current_element_type,
			     &first_glyph,
			     current_glyph->previous_glyph, liquescentia);
	      current_element_type = ELT_NO_ELEMENT;
	      liquescentia = L_NO_LIQUESCENTIA;
	    }
	  //if statement to make neumatic cuts not appear in elements, as there is always one between elements  
	  if (current_glyph->type != GRE_SPACE
	      || current_glyph->type != SP_NEUMATIC_CUT)
	//clef change or space other thant neumatic cut
	    {
	      if (!first_element)
		{
		  first_element = current_element;
		}
	      libgregorio_add_special_as_element (&current_element,
						  current_glyph->type,
						  current_glyph->glyph_type);
	    }
	  /*if (current_glyph->type == GRE_SPACE && current_glyph->glyph_type == SP_NEUMATIC_CUT)
	{
	  close_element (&current_element, current_element_type,
			 &first_glyph, current_glyph->previous_glyph,
			 current_glyph->liquescentia);
	  current_element_type = next_element_type;
	  liquescentia = L_NO_LIQUESCENTIA;
	}*/
	  libgregorio_free_one_glyph (&current_glyph);
	  first_glyph = next_glyph;
	  current_glyph = next_glyph;
	  continue;
	}

/* we must determine the last pitch and the next pitch, because
 * the nature of the element depends on it : for example
 * cvba is a climacus
 * avba is something weird
*/
      if (current_element_type
	  && current_glyph->previous_glyph->type == GRE_GLYPH)
	{
	  tmp_note = current_glyph->previous_glyph->first_note;
	  while (tmp_note->next_note)
	    {
	      tmp_note = tmp_note->next_note;
	    }
	  last_pitch = tmp_note->pitch;
	}
      else
	{
	  last_pitch = 0;
	}
      next_pitch = current_glyph->first_note->pitch;

      /* first we do what we must about initio debilis */
      if (is_initio_debilis (current_glyph->liquescentia))
	{			/* meaning that the note is an initio debilis, maybe more */
	  if (current_element_type != ELT_NO_ELEMENT)
	    {
	      close_element (&current_element, current_element_type,
			     &first_glyph,
			     current_glyph->previous_glyph, liquescentia);
	      current_element_type = ELT_NO_ELEMENT;
	    }
	  liquescentia = L_INITIO_DEBILIS;
	}
      if (current_element_type != ELT_NO_ELEMENT)
	{
	  previous_glyph_type = current_glyph->previous_glyph->glyph_type;
	}
      else
	{
	  previous_glyph_type = G_NO_GLYPH;
	}
      next_element_type =
	add_glyph_to_an_element (current_element_type,
				 current_glyph->glyph_type,
				 previous_glyph_type, last_pitch,
				 next_pitch, &end_of_element);

/* now we take care of zero-width spaces, we can't cut an element on it */
      if (current_glyph->previous_glyph
	  && current_glyph->previous_glyph->type == GRE_SPACE)
	// if it is GRE_SPACE, it is SP_ZERO_WIDTH, as other types of spaces are now in gregorio_elements
	{
	  if (end_of_element == DET_END_OF_BOTH)
	    {
	      end_of_element = DET_END_OF_CURRENT;
	    }
	  if (end_of_element == DET_END_OF_PREVIOUS)
	    {
	      end_of_element = DET_NO_END;
	    }
	}
      if (current_glyph->next_glyph
	  && current_glyph->next_glyph->type == GRE_SPACE
	  && current_glyph->next_glyph->glyph_type == SP_ZERO_WIDTH)
	{
	  if (end_of_element == DET_END_OF_BOTH)
	    {
	      end_of_element = DET_END_OF_PREVIOUS;
	    }
	  if (end_of_element == DET_END_OF_CURRENT)
	    {
	      end_of_element = DET_NO_END;
	    }
	}


      switch (end_of_element)
	{
	case DET_NO_END:
	  current_element_type = next_element_type;
	  if (is_liquescentia (current_glyph->liquescentia))
	    {
	      liquescentia += current_glyph->liquescentia;	/* once again, only works with the good values in the header file */
	      close_element (&current_element, current_element_type,
			     &first_glyph, current_glyph, liquescentia);
	      current_element_type = ELT_NO_ELEMENT;
	      liquescentia = L_NO_LIQUESCENTIA;
	    }
	  break;
	case DET_END_OF_PREVIOUS:
	  close_element (&current_element, current_element_type,
			 &first_glyph, current_glyph->previous_glyph,
			 current_glyph->liquescentia);
	  current_element_type = next_element_type;
	  liquescentia = L_NO_LIQUESCENTIA;
	  if (is_liquescentia (current_glyph->liquescentia))
//not an initio debilis, because we considered it in the first part...
	    {
	      close_element (&current_element, current_element_type,
			     &first_glyph, current_glyph,
			     current_glyph->liquescentia);
	      current_element_type = ELT_NO_ELEMENT;
	    }
	  break;
	case DET_END_OF_CURRENT:
	  liquescentia += current_glyph->liquescentia;
	  close_element (&current_element, next_element_type,
			 &first_glyph, current_glyph, liquescentia);
	  current_element_type = ELT_NO_ELEMENT;
	  liquescentia = L_NO_LIQUESCENTIA;
	  break;
	default:		//case DET_END_OF_BOTH:
	  liquescentia += current_glyph->liquescentia;
	  close_element (&current_element, current_element_type,
			 &first_glyph, current_glyph, liquescentia);
	  liquescentia = L_NO_LIQUESCENTIA;
	  close_element (&current_element, next_element_type,
			 &first_glyph, current_glyph, liquescentia);
	  current_element_type = ELT_NO_ELEMENT;
	  break;
	}


/* we must determine the first element, that we will return */
      if (!first_element && current_element)
	{
	  first_element = current_element;
	}

      if (!next_glyph && current_element_type != ELT_NO_ELEMENT)
	{
	  close_element (&current_element, current_element_type,
			 &first_glyph, current_glyph, liquescentia);
	}

      current_glyph = next_glyph;
    }				//end of while

/* we must determine the first element, that we will return */
  if (!first_element && current_element)
    {
      first_element = current_element;
    }
  return first_element;
}

/****************************
 * attention, commentaires qui tuent à placer ici...
 * 
 * TODO : a lot of thing can be better... and more understandable
 * 
****************************/

char
add_glyph_to_an_element (char element_type, char current_glyph_type,
			 char last_glyph_type, char last_pitch,
			 char next_pitch, char *end_of_element)
{



  if (element_type == ELT_NO_ELEMENT || last_glyph_type == G_NO_GLYPH)
    {
      if (is_puncta_descendens (current_glyph_type)
	  || current_glyph_type == G_PUNCTA_INCLINATA)
	{
	  *end_of_element = DET_END_OF_CURRENT;
	}
      else
	{
	  *end_of_element = DET_NO_END;
	}
      if (is_puncta_ascendens (current_glyph_type))
	{
	  return ELT_PRAEPUNCTA;
	}
      else
	{
	  return ELT_ONE_GLYPH;
	}
    }

  if (is_puncta_ascendens (current_glyph_type))
    {
      *end_of_element = DET_END_OF_PREVIOUS;
      return ELT_PRAEPUNCTA;
    }



  if (is_puncta_descendens (current_glyph_type))
    {
      if (last_pitch <= next_pitch)
	{
	  *end_of_element = DET_END_OF_BOTH;
	  return ELT_SUBPUNCTA;
	}
      else
	{
	  *end_of_element = DET_END_OF_CURRENT;
	  element_type = mix_element_types (element_type, ELT_SUBPUNCTA);
	  return element_type;
	}
    }



  if (is_puncta_inclinata (current_glyph_type))
    {				// other cases of puncta_inclinata
      *end_of_element = DET_END_OF_BOTH;
      return ELT_SUBPUNCTA;
    }

  if (has_two_glyphs (element_type))
    {
      *end_of_element = DET_END_OF_CURRENT;
      return ELT_ONE_GLYPH;
    }

//We describe next every case where we put a second glyph. In this part, last_glyph is not a puncta inclinata glyph

  if (current_glyph_type == G_PUNCTUM && last_pitch == next_pitch)
    {
      *end_of_element = DET_NO_END;
      element_type = mix_element_types (element_type, ELT_ONE_GLYPH);
      return element_type;
    }


  //case of punctum preceding another glyph (quite often encoutered)
  if (last_glyph_type == G_PUNCTUM && last_pitch == next_pitch)
    {
      *end_of_element = DET_NO_END;
      element_type = mix_element_types (element_type, ELT_ONE_GLYPH);
      return element_type;
    }

  if (last_glyph_type == G_PUNCTUM)
    {
//TODO : we should chech here current_glyph_type, because it does not work for all of them
      *end_of_element = DET_NO_END;
      element_type = mix_element_types (element_type, ELT_ONE_GLYPH);
      return element_type;
    }


  if (last_glyph_type == G_PODATUS && current_glyph_type == G_PODATUS
      && last_pitch <= next_pitch)
    {
//TODO : we should chech here current_glyph_type, because it does not work for all of them
      *end_of_element = DET_NO_END;
      element_type = mix_element_types (element_type, ELT_ONE_GLYPH);
      return element_type;
    }

  if (last_glyph_type == G_PODATUS && current_glyph_type == G_FLEXA
      && last_pitch <= next_pitch)
    {
      *end_of_element = DET_NO_END;
      element_type = mix_element_types (element_type, ELT_ONE_GLYPH);
      return element_type;
    }


  else
    {				//"normal" types of glyphs, here we could make the behaviour better
      if (element_type == ELT_PRAEPUNCTA)
	{

	  *end_of_element = DET_NO_END;
	  return ELT_PRAEPUNCTA_ONE_GLYPH;
	}


    }
  //default behaviour
  *end_of_element = DET_END_OF_PREVIOUS;
  return ELT_ONE_GLYPH;
}
