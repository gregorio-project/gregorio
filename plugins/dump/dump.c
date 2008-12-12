/* 
Gregorio dump output format.
Copyright (C) 2007 Elie Roux <elie.roux@enst-bretagne.fr>

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
#include <gregorio/struct.h>
#include <gregorio/unicode.h>
#include <gregorio/plugin.h>
#include <gregorio/messages.h>

#include "dump.h"

DECLARE_PLUGIN(dump)
{
  .id = "dump",
  .name = "dump",
  .description = "Raw dump plugin",
  .author = "Elie Roux <elie.roux@enst-bretagne.fr>",

  .type = GREGORIO_PLUGIN_OUTPUT,

  .file_extension = "dump",

  .write = write_score
};

void
write_score (FILE * f, gregorio_score * score)
{
  gregorio_syllable *syllable = score->first_syllable;
  gregorio_voice_info *voice_info = score->first_voice_info;
  int i;
  gregorio_element *element;
  gregorio_glyph *glyph;
  gregorio_note *note;

  if (!f) {
      gregorio_message (_
			   ("call with NULL file"),
			   "libgregorio_gregoriotex_write_score", ERROR, 0);
			   return;
  }

  fprintf (f,
	   "=====================================================================\n SCORE INFOS\n=====================================================================\n");
  if (score->number_of_voices)
    {
      fprintf (f, "   number_of_voices          %d\n",
	       score->number_of_voices);
    }
  if (score->name)
    {
      fprintf (f, "   name                      %s\n", score->name);
    }
  if (score->office_part)
    {
      fprintf (f, "   office_part               %s\n", score->office_part);
    }
  if (score->initial_style)
    {
      fprintf (f, "   initial_style             %d\n", score->initial_style);
    }
  if (score->mode)
    {
      fprintf (f, "   mode                      %d\n", score->mode);
    }
  if (score->lilypond_preamble)
    {
      fprintf (f, "   lilypond_preamble         %s\n",
	       score->lilypond_preamble);
    }
  if (score->opustex_preamble)
    {
      fprintf (f, "   opustex_preamble          %s\n",
	       score->opustex_preamble);
    }
  if (score->musixtex_preamble)
    {
      fprintf (f, "   musixtex_preamble         %s\n",
	       score->musixtex_preamble);
    }
  if (score->gregoriotex_font)
    {
      fprintf (f, "   gregoriotex_font          %s\n",
	       score->gregoriotex_font);
    }
  fprintf (f,
	   "\n\n=====================================================================\n VOICES INFOS\n=====================================================================\n");
  for (i = 0; i < score->number_of_voices; i++)
    {
      fprintf (f, "  Voice %d\n", i + 1);
      if (voice_info->initial_key)
	{
	  fprintf (f, "   initial_key               %d (%s)\n",
		   voice_info->initial_key,
		   libgregorio_dump_key_to_char (voice_info->initial_key));
	}
      if (voice_info->anotation)
	{
	  fprintf (f, "   anotation                 %s\n",
		   voice_info->anotation);
	}
      if (voice_info->author)
	{
	  fprintf (f, "   author                    %s\n",
		   voice_info->author);
	}
      if (voice_info->date)
	{
	  fprintf (f, "   date                      %s\n", voice_info->date);
	}
      if (voice_info->manuscript)
	{
	  fprintf (f, "   manuscript                %s\n",
		   voice_info->manuscript);
	}
      if (voice_info->reference)
	{
	  fprintf (f, "   reference                 %s\n",
		   voice_info->reference);
	}
      if (voice_info->storage_place)
	{
	  fprintf (f, "   storage_place             %s\n",
		   voice_info->storage_place);
	}
      if (voice_info->translator)
	{
	  fprintf (f, "   translator                %s\n",
		   voice_info->translator);
	}
      if (voice_info->translation_date)
	{
	  fprintf (f, "   translation_date          %s\n",
		   voice_info->translation_date);
	}
      if (voice_info->style)
	{
	  fprintf (f, "   style                     %s\n", voice_info->style);
	}
      if (voice_info->virgula_position)
	{
	  fprintf (f, "   virgula_position          %s\n",
		   voice_info->virgula_position);
	}
      voice_info = voice_info->next_voice_info;
    }
  fprintf (f,
	   "\n\n=====================================================================\n SCORE\n=====================================================================\n");
  while (syllable)
    {
      if (syllable->type)
	{
	  fprintf (f, "   type                      %d (%s)\n",
		   syllable->type, libgregorio_dump_type (syllable->type));
	}
      if (syllable->position)
	{
	  fprintf (f, "   position                  %d (%s)\n",
		   syllable->position,
		   libgregorio_dump_syllable_position (syllable->position));
	}
      if (syllable->text)
	{
	  if (syllable->translation)
	    {
	      fprintf (f, "\n  Text\n");
	    }
	  libgregorio_dump_write_characters (f, syllable->text);
	}
      if (syllable->translation)
	{
	  fprintf (f, "\n  Translation\n");
	  libgregorio_dump_write_characters (f, syllable->translation);
	}
      element = syllable->elements[0];
      while (element)
	{
	  fprintf (f,
		   "---------------------------------------------------------------------\n");
	  if (element->type)
	    {
	      fprintf (f, "     type                    %d (%s)\n",
		       element->type, libgregorio_dump_type (element->type));
	    }
	  if (element->element_type && element->type == GRE_ELEMENT)
	    {
	      fprintf (f, "     element_type            %d (%s)\n",
		       element->element_type,
		       libgregorio_dump_element_type (element->element_type));
	    }
	  if (element->element_type && element->type == GRE_SPACE)
	    {
	      fprintf (f, "     element_type            %d (%s)\n",
		       element->element_type,
		       libgregorio_dump_space_type (element->element_type));
	    }
	  if (element->element_type && element->type == GRE_BAR)
	    {
	      fprintf (f, "     element_type            %d (%s)\n",
		       element->element_type,
		       libgregorio_dump_bar_type (element->element_type));
	    }
	  if (element->element_type && element->type == GRE_C_KEY_CHANGE)
	    {
	      fprintf (f, "     element_type            %d (c%d)\n",
		       element->element_type, element->element_type - 48);
	    }
	  if (element->element_type && element->type == GRE_F_KEY_CHANGE)
	    {
	      fprintf (f, "     element_type            %d (f%d)\n",
		       element->element_type, element->element_type - 48);
	    }
	  glyph = element->first_glyph;
	  while (glyph)
	    {
	      fprintf (f,
		       "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -\n");
	      if (glyph->type)
		{
		  fprintf (f, "       type                  %d (%s)\n",
			   glyph->type, libgregorio_dump_type (glyph->type));
		}
	      if (glyph->glyph_type)
		{
		  if (glyph->type == GRE_SPACE)
		    {
		      fprintf (f, "       glyph_type            %d (%s)\n",
			       glyph->glyph_type,
			       libgregorio_dump_space_type (glyph->
							    glyph_type));
		    }
		  if (glyph->type == GRE_BAR)
		    {
		      fprintf (f, "       glyph_type            %d (%s)\n",
			       glyph->glyph_type,
			       libgregorio_dump_bar_type (glyph->glyph_type));
		    }
		  if ((glyph->type == GRE_FLAT)
		      || (glyph->type == GRE_NATURAL))
		    {
		      fprintf (f, "       glyph_type            %d\n",
			       glyph->glyph_type);
		    }
		  if ((glyph->type != GRE_SPACE) && (glyph->type != GRE_BAR)
		      && (glyph->type != GRE_FLAT)
		      && (glyph->type != GRE_NATURAL))
		    {
		      fprintf (f, "       glyph_type            %d (%s)\n",
			       glyph->glyph_type,
			       libgregorio_dump_glyph_type (glyph->
							    glyph_type));
		    }
		}
	      if (glyph->liquescentia)
		{
		  fprintf (f, "       liquescentia          %d (%s)\n",
			   glyph->liquescentia,
			   libgregorio_dump_liquescentia (glyph->
							  liquescentia));
		}
	      note = glyph->first_note;
	      while (note)
		{
		  fprintf (f,
			   "-  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  \n");
		  if (note->type)
		    {
		      fprintf (f, "         type                %d (%s)\n",
			       note->type,
			       libgregorio_dump_type (note->type));
		    }
		  if (note->pitch)
		    {
		      fprintf (f, "         pitch               %c\n",
			       note->pitch);
		    }
		  if (note->shape)
		    {
		      fprintf (f, "         shape               %d (%s)\n",
			       note->shape,
			       libgregorio_dump_shape (note->shape));
		    }
		  if (note->signs)
		    {
		      fprintf (f, "         signs               %d (%s)\n",
			       note->signs,
			       libgregorio_dump_signs (note->signs));
		    }
		  if (note->rare_sign)
		    {
		      fprintf (f, "         rare sign           %d (%s)\n",
			       note->rare_sign,
			       libgregorio_dump_rare_sign (note->rare_sign));
		    }
		  if (note->liquescentia)
		    {
		      fprintf (f, "         liquescentia        %d (%s)\n",
			       note->liquescentia,
			       libgregorio_dump_liquescentia (note->
							      liquescentia));
		    }
		  if (note->h_episemus_type)
		    {
		      fprintf (f, "         h_episemus_type     %d (%s)\n",
			       note->h_episemus_type,
			       libgregorio_dump_h_episemus_type (note->
								 h_episemus_type));
		    }
		  if (note->h_episemus_top_note)
		    {
		      fprintf (f, "         h_episemus_top_note %d\n",
			       note->h_episemus_top_note);
		    }
		  note = note->next_note;
		}
	      glyph = glyph->next_glyph;
	    }
	  element = element->next_element;
	}
      fprintf (f,
	       "=====================================================================\n");
      syllable = syllable->next_syllable;
    }
}

const char *
libgregorio_dump_style_to_string (unsigned char style)
{
  switch (style)
    {
    case ST_NO_STYLE:
      return "     ST_NO_STYLE";
      break;
    case ST_ITALIC:
      return "       ST_ITALIC";
      break;
    case ST_CENTER:
      return "       ST_CENTER";
      break;
    case ST_FORCED_CENTER:
      return " ST_FORCED_CENTER";
      break;
    case ST_INITIAL:
      return "      ST_INITIAL";
      break;
    case ST_BOLD:
      return "         ST_BOLD";
      break;
    case ST_TT:
      return "           ST_TT";
      break;
    case ST_SMALL_CAPS:
      return "   ST_SMALL_CAPS";
      break;
    case ST_SPECIAL_CHAR:
      return " ST_SPECIAL_CHAR";
      break;
    case ST_VERBATIM:
      return "     ST_VERBATIM";
      break;
    default:
      return "";
      break;
    }
}

void
libgregorio_dump_write_characters (FILE * f,
				   gregorio_character * current_character)
{
  while (current_character)
    {
      fprintf (f,
	       "---------------------------------------------------------------------\n");
      if (current_character->is_character)
	{
	  fprintf (f, "     character                 %lc\n",
		   current_character->cos.character);
	}
      else
	{
	  if (current_character->cos.s.type == ST_T_BEGIN)
	    {
	      fprintf (f, "     beginning of style   %s\n",
		       libgregorio_dump_style_to_string (current_character->
							 cos.s.style));
	    }
	  else
	    {
	      fprintf (f, "     end of style         %s\n",
		       libgregorio_dump_style_to_string (current_character->
							 cos.s.style));
	    }
	}
      current_character = current_character->next_character;
    }
}

const char *
libgregorio_dump_key_to_char (int key)
{
  const char *str;
  switch (key)
    {
    case -2:
      str = "f1";
      break;
    case 0:
      str = "f2";
      break;
    case 2:
      str = "f3";
      break;
    case 4:
      str = "f4";
      break;
    case 1:
      str = "c1";
      break;
    case 3:
      str = "c2";
      break;
    case 5:
      str = "c3";
      break;
    case 7:
      str = "c4";
      break;
    default:
      str = "no key defined";
      break;
    }
  return str;
}


const char *
libgregorio_dump_syllable_position (char pos)
{
  const char *str;
  switch (pos)
    {
    case WORD_BEGINNING:
      str = "WORD_BEGINNING";
      break;
    case WORD_MIDDLE:
      str = "WORD_MIDDLE";
      break;
    case WORD_END:
      str = "WORD_END";
      break;
    case WORD_ONE_SYLLABLE:
      str = "WORD_ONE_SYLLABLE";
      break;
    default:
      str = "unknown";
      break;
    }
  return str;
}


const char *
libgregorio_dump_type (char type)
{
  const char *str;
  switch (type)
    {
    case GRE_NOTE:
      str = "GRE_NOTE";
      break;
    case GRE_GLYPH:
      str = "GRE_GLYPH";
      break;
    case GRE_ELEMENT:
      str = "GRE_ELEMENT";
      break;
    case GRE_FLAT:
      str = "GRE_FLAT";
      break;
    case GRE_NATURAL:
      str = "GRE_NATURAL";
      break;
    case GRE_C_KEY_CHANGE:
      str = "GRE_C_KEY_CHANGE";
      break;
    case GRE_F_KEY_CHANGE:
      str = "GRE_F_KEY_CHANGE";
      break;
    case GRE_END_OF_LINE:
      str = "GRE_END_OF_LINE";
      break;
    case GRE_SPACE:
      str = "GRE_SPACE";
      break;
    case GRE_BAR:
      str = "GRE_BAR";
      break;
    case GRE_SYLLABLE:
      str = "GRE_SYLLABLE";
      break;
    default:
      str = "unknown";
      break;
    }
  return str;
}


const char *
libgregorio_dump_bar_type (char element_type)
{
  const char *str;
  switch (element_type)
    {
    case B_NO_BAR:
      str = "B_NO_BAR";
      break;
    case B_VIRGULA:
      str = "B_VIRGULA";
      break;
    case B_DIVISIO_MINIMA:
      str = "B_DIVISIO_MINIMA";
      break;
    case B_DIVISIO_MINOR:
      str = "B_DIVISIO_MINOR";
      break;
    case B_DIVISIO_MAIOR:
      str = "B_DIVISIO_MAIOR";
      break;
    case B_DIVISIO_FINALIS:
      str = "B_DIVISIO_FINALIS";
      break;
    default:
      str = "unknown";
      break;
    }
  return str;
}


const char *
libgregorio_dump_space_type (char element_type)
{
  const char *str;
  switch (element_type)
    {
    case SP_DEFAULT:
      str = "SP_DEFAULT";
      break;
    case SP_NO_SPACE:
      str = "SP_NO_SPACE";
      break;
    case SP_ZERO_WIDTH:
      str = "SP_ZERO_WIDTH";
      break;
    case SP_NEUMATIC_CUT:
      str = "SP_NEUMATIC_CUT";
      break;
    case SP_LARGER_SPACE:
      str = "SP_LARGER_SPACE";
      break;
    case SP_GLYPH_SPACE:
      str = "SP_GLYPH_SPACE";
      break;
    default:
      str = "unknown";
      break;
    }
  return str;
}


// not so sure it has still a meaning now...
const char *
libgregorio_dump_element_type (char element_type)
{
  const char *str;
  switch (element_type)
    {
    case 0:
      str = "ELT_NO_ELEMENT";
      break;
    case 1:
      str = "ELT_PRAEPUNCTA";
      break;
    case 2:
      str = "ELT_ONE_GLYPH";
      break;
    case 3:
      str = "ELT_PRAEPUNCTA_ONE_GLYPH";
      break;
    case 4:
      str = "ELT_TWO_GLYPH";
      break;
    case 5:
      str = "ELT_PRAEPUNCTA_TWO_GLYPH";
      break;
    case 6:
      str = "ELT_ONE_GLYPH_SUBPUNCTA";
      break;
    case 7:
      str = "ELT_PRAEPUNCTA_ONE_GLYPH_SUBPUNCTA";
      break;
    case 8:
      str = "ELT_TWO_GLYPH_SUBPUNCTA";
      break;
    case 9:
      str = "ELT_PRAEPUNCTA_TWO_GLYPH_SUBPUNCTA";
      break;
    default:
      str = "unknown";
      break;
    }
  return str;
}

const char *
libgregorio_dump_liquescentia (char liquescentia)
{
  const char *str;
  switch (liquescentia)
    {
    case L_NO_LIQUESCENTIA:
      str = "L_NO_LIQUESCENTIA";
      break;
    case L_DEMINUTUS:
      str = "L_DEMINUTUS";
      break;
    case L_AUCTUS_ASCENDENS:
      str = "L_AUCTUS_ASCENDENS";
      break;
    case L_AUCTUS_DESCENDENS:
      str = "L_AUCTUS_DESCENDENS";
      break;
    case L_AUCTA:
      str = "L_AUCTA";
      break;
    case L_INITIO_DEBILIS:
      str = "L_INITIO_DEBILIS";
      break;
    case L_DEMINUTUS_INITIO_DEBILIS:
      str = "L_DEMINUTUS_INITIO_DEBILIS";
      break;
    case L_AUCTUS_ASCENDENS_INITIO_DEBILIS:
      str = "L_AUCTUS_ASCENDENS_INITIO_DEBILIS";
      break;
    case L_AUCTUS_DESCENDENS_INITIO_DEBILIS:
      str = "L_AUCTUS_DESCENDENS_INITIO_DEBILIS";
      break;
    case L_AUCTA_INITIO_DEBILIS:
      str = "L_AUCTA_INITIO_DEBILIS";
      break;
    default:
      str = "unknown";
      break;
    }
  return str;
}
const char *
libgregorio_dump_glyph_type (char glyph_type)
{
  const char *str;
  switch (glyph_type)
    {
    case G_PUNCTUM_INCLINATUM:
      str = "G_PUNCTUM_INCLINATUM";
      break;
    case G_2_PUNCTA_INCLINATA_DESCENDENS:
      str = "G_2_PUNCTA_INCLINATA_DESCENDENS";
      break;
    case G_3_PUNCTA_INCLINATA_DESCENDENS:
      str = "G_3_PUNCTA_INCLINATA_DESCENDENS";
      break;
    case G_4_PUNCTA_INCLINATA_DESCENDENS:
      str = "G_4_PUNCTA_INCLINATA_DESCENDENS";
      break;
    case G_5_PUNCTA_INCLINATA_DESCENDENS:
      str = "G_5_PUNCTA_INCLINATA_DESCENDENS";
      break;
    case G_2_PUNCTA_INCLINATA_ASCENDENS:
      str = "G_2_PUNCTA_INCLINATA_ASCENDENS";
      break;
    case G_3_PUNCTA_INCLINATA_ASCENDENS:
      str = "G_3_PUNCTA_INCLINATA_ASCENDENS";
      break;
    case G_4_PUNCTA_INCLINATA_ASCENDENS:
      str = "G_4_PUNCTA_INCLINATA_ASCENDENS";
      break;
    case G_5_PUNCTA_INCLINATA_ASCENDENS:
      str = "G_5_PUNCTA_INCLINATA_ASCENDENS";
      break;
    case G_TRIGONUS:
      str = "G_TRIGONUS";
      break;
    case G_PUNCTA_INCLINATA:
      str = "G_PUNCTA_INCLINATA";
      break;
    case G_UNDETERMINED:
      str = "G_UNDETERMINED";
      break;
    case G_VIRGA:
      str = "G_VIRGA";
      break;
    case G_STROPHA:
      str = "G_STROPHA";
      break;
    case G_STROPHA_AUCTA:
      str = "G_STROPHA_AUCTA";
      break;
    case G_PUNCTUM:
      str = "G_PUNCTUM";
      break;
    case G_PODATUS:
      str = "G_PODATUS";
      break;
    case G_PES_QUADRATUM:
      str = "G_PES_QUADRATUM";
      break;
    case G_FLEXA:
      str = "G_FLEXA";
      break;
    case G_TORCULUS:
      str = "G_TORCULUS";
      break;
    case G_TORCULUS_RESUPINUS:
      str = "G_TORCULUS_RESUPINUS";
      break;
    case G_TORCULUS_RESUPINUS_FLEXUS:
      str = "G_TORCULUS_RESUPINUS_FLEXUS";
      break;
    case G_PORRECTUS:
      str = "G_PORRECTUS";
      break;
    case G_PORRECTUS_FLEXUS:
      str = "G_PORRECTUS_FLEXUS";
      break;
    case G_BIVIRGA:
      str = "G_BIVIRGA";
      break;
    case G_TRIVIRGA:
      str = "G_TRIVIRGA";
      break;
    case G_DISTROPHA:
      str = "G_DISTROPHA";
      break;
    case G_DISTROPHA_AUCTA:
      str = "G_DISTROPHA_AUCTA";
      break;
    case G_TRISTROPHA:
      str = "G_TRISTROPHA";
      break;
    case G_ANCUS:
      str = "G_ANCUS";
      break;
    case G_TRISTROPHA_AUCTA:
      str = "G_TRISTROPHA_AUCTA";
      break;
    case G_PES_QUADRATUM_FIRST_PART:
      str = "G_PES_QUADRATUM_FIRST_PART";
      break;
    case G_SCANDICUS:
      str = "G_SCANDICUS";
      break;
    default:
      str = "unknown";
      break;
    }
  return str;
}

const char *
libgregorio_dump_shape (char shape)
{
  const char *str;
  switch (shape)
    {
    case S_UNDETERMINED:
      str = "S_UNDETERMINED";
      break;
    case S_PUNCTUM:
      str = "S_PUNCTUM";
      break;
    case S_PUNCTUM_END_OF_GLYPH:
      str = "S_PUNCTUM_END_OF_GLYPH";
      break;
    case S_PUNCTUM_INCLINATUM:
      str = "S_PUNCTUM_INCLINATUM";
      break;
    case S_PUNCTUM_INCLINATUM_DEMINUTUS:
      str = "S_PUNCTUM_INCLINATUM_DEMINUTUS";
      break;
    case S_PUNCTUM_INCLINATUM_AUCTUS:
      str = "S_PUNCTUM_INCLINATUM_AUCTUS";
      break;
    case S_VIRGA:
      str = "S_VIRGA";
      break;
    case S_BIVIRGA:
      str = "S_BIVIRGA";
      break;
    case S_TRIVIRGA:
      str = "S_TRIVIRGA";
      break;
    case S_ORISCUS:
      str = "S_ORISCUS";
      break;
    case S_ORISCUS_AUCTUS:
      str = "S_ORISCUS_AUCTUS";
      break;
    case S_QUILISMA:
      str = "S_QUILISMA";
      break;
    case S_STROPHA:
      str = "S_STROPHA";
      break;
    case S_STROPHA_AUCTA:
      str = "S_STROPHA_AUCTA";
      break;
    case S_DISTROPHA:
      str = "S_DISTROPHA";
      break;
    case S_DISTROPHA_AUCTA:
      str = "S_DISTROPHA_AUCTA";
      break;
    case S_TRISTROPHA:
      str = "S_TRISTROPHA";
      break;
    case S_TRISTROPHA_AUCTA:
      str = "S_TRISTROPHA_AUCTA";
      break;
    case S_QUADRATUM:
      str = "S_QUADRATUM";
      break;
    case S_PUNCTUM_CAVUM:
      str = "S_PUNCTUM_CAVUM";
      break; 
    case S_LINEA_PUNCTUM:
      str = "S_LINEA_PUNCTUM";
      break;
    case S_LINEA_PUNCTUM_CAVUM:
      str = "S_LINEA_PUNCTUM_CAVUM";
      break;      
    default:
      str = "unknown";
      break;
    }
  return str;
}

const char *
libgregorio_dump_signs (char signs)
{
  const char *str;
  switch (signs)
    {
    case _NO_SIGN:
      str = "_NO_SIGN";
      break;
    case _PUNCTUM_MORA:
      str = "_PUNCTUM_MORA";
      break;
    case _AUCTUM_DUPLEX:
      str = "_AUCTUM_DUPLEX";
      break;
    case _V_EPISEMUS:
      str = "_V_EPISEMUS";
      break;
    case _V_EPISEMUS_PUNCTUM_MORA:
      str = "_V_EPISEMUS_PUNCTUM_MORA";
      break;
    case _V_EPISEMUS_AUCTUM_DUPLEX:
      str = "_V_EPISEMUS_AUCTUM_DUPLEX";
      break;
    default:
      str = "unknown";
      break;
    }
  return str;
}

const char *
libgregorio_dump_rare_sign (char rare_sign)
{
  const char *str;
  switch (rare_sign)
    {
    case _ACCENTUS:
      str = "_ACCENTUS";
      break;
    case _ACCENTUS_REVERSUS:
      str = "_ACCENTUS_REVERSUS";
      break;
    case _CIRCULUS:
      str = "_CIRCULUS";
      break;
    case _SEMI_CIRCULUS:
      str = "_SEMI_CIRCULUS";
      break;
    case _SEMI_CIRCULUS_REVERSUS:
      str = "_SEMI_CIRCULUS_REVERSUS";
      break;
    default:
      str = "unknown";
      break;
    }
  return str;
}

const char *
libgregorio_dump_h_episemus_type (char h_episemus_type)
{
  const char *str;
  switch (h_episemus_type)
    {
    case H_NO_EPISEMUS:
      str = "H_NO_EPISEMUS";
      break;
    case H_ONE:
      str = "H_ONE";
      break;
    case H_ALONE:
      str = "H_ALONE";
      break;
    case H_MULTI:
      str = "H_MULTI";
      break;
    case H_MULTI_BEGINNING:
      str = "H_MULTI_BEGINNING";
      break;
    case H_MULTI_MIDDLE:
      str = "H_MULTI_MIDDLE";
      break;
    case H_MULTI_END:
      str = "H_MULTI_END";
      break;
    case H_UNDETERMINED:
      str = "H_UNDETERMINED";
      break;
    default:
      str = "unknown";
      break;
    }
  return str;
}
