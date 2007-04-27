/* 
Gregorio dump output format.
Copyright (C) 2007 Olivier Berten

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
#include "gettext.h"
#define _(str) gettext(str)
#define N_(str) str
#include "struct.h"
#include "dump.h"

void
libgregorio_dump_score (FILE * f, gregorio_score * score)
{
    fprintf (f,
             "=====================================================================\n SCORE INFOS\n=====================================================================\n");
    if (score->number_of_voices)
    {
        fprintf (f, "   number_of_voices          %d\n", score->number_of_voices);
    }
    if (score->name)
    {
        fprintf (f, "   name                      %s\n", score->name);
    }
    if (score->office_part)
    {
        fprintf (f, "   office_part               %s\n", score->office_part);
    }
    if (score->lilypond_preamble)
    {
        fprintf (f, "   lilypond_preamble         %s\n", score->lilypond_preamble);
    }
    if (score->opustex_preamble)
    {
        fprintf (f, "   opustex_preamble          %s\n", score->opustex_preamble);
    }
    if (score->musixtex_preamble)
    {
        fprintf (f, "   musixtex_preamble         %s\n", score->musixtex_preamble);
    }
    fprintf (f,
             "\n\n=====================================================================\n VOICES INFOS\n=====================================================================\n");
    gregorio_voice_info *voice_info = score->first_voice_info;
    int i;
    for (i = 0; i < score->number_of_voices; i++)
    {
        fprintf (f, "  Voice %d\n", i + 1);
        if (voice_info->initial_key)
        {
            fprintf (f, "   initial_key               %d (%s)\n", voice_info->initial_key,
                     libgregorio_dump_key_to_char (voice_info->initial_key));
        }
        if (voice_info->anotation)
        {
            fprintf (f, "   anotation                 %s\n", voice_info->anotation);
        }
        if (voice_info->author)
        {
            fprintf (f, "   author                    %s\n", voice_info->author);
        }
        if (voice_info->date)
        {
            fprintf (f, "   date                      %s\n", voice_info->date);
        }
        if (voice_info->manuscript)
        {
            fprintf (f, "   manuscript                %s\n", voice_info->manuscript);
        }
        if (voice_info->reference)
        {
            fprintf (f, "   reference                 %s\n", voice_info->reference);
        }
        if (voice_info->storage_place)
        {
            fprintf (f, "   storage_place             %s\n", voice_info->storage_place);
        }
        if (voice_info->translator)
        {
            fprintf (f, "   translator                %s\n", voice_info->translator);
        }
        if (voice_info->translation_date)
        {
            fprintf (f, "   translation_date          %s\n", voice_info->translation_date);
        }
        if (voice_info->style)
        {
            fprintf (f, "   style                     %s\n", voice_info->style);
        }
        if (voice_info->virgula_position)
        {
            fprintf (f, "   virgula_position          %s\n", voice_info->virgula_position);
        }
        voice_info = voice_info->next_voice_info;
    }
    fprintf (f,
             "\n\n=====================================================================\n SCORE\n=====================================================================\n");
    gregorio_syllable *syllable = score->first_syllable;
    while(syllable)
    {
        if (syllable->type)
        {
            fprintf (f, "   type                      %d (%s)\n", syllable->type,
                     libgregorio_dump_type (syllable->type));
        }
        if (syllable->position)
        {
            fprintf (f, "   position                  %d (%s)\n", syllable->position,
                     libgregorio_dump_syllable_position (syllable->position));
        }
        if (syllable->syllable)
        {
            fprintf (f, "   syllable                  %s\n", syllable->syllable);
        }
        gregorio_element *element = syllable->elements[0];
        while (element)
        {
            fprintf (f, "---------------------------------------------------------------------\n");
            if (element->type)
            {
                fprintf (f, "     type                    %d (%s)\n", element->type,
                         libgregorio_dump_type (element->type));
            }
            if (element->element_type && element->type==GRE_ELEMENT)
            {
                fprintf (f, "     element_type            %d (%s)\n", element->element_type,
                         libgregorio_dump_element_type (element->element_type));
            }
            if (element->element_type && element->type==GRE_SPACE)
            {
                fprintf (f, "     element_type            %d (%s)\n", element->element_type,
                         libgregorio_dump_space_type (element->element_type));
            }
            if (element->element_type && element->type==GRE_BAR)
            {
                fprintf (f, "     element_type            %d (%s)\n", element->element_type,
                         libgregorio_dump_bar_type (element->element_type));
            }
            if (element->element_type && element->type==GRE_C_KEY_CHANGE)
            {
                fprintf (f, "     element_type            %d (c%d)\n", element->element_type,
                         element->element_type - 48);
            }
            if (element->element_type && element->type==GRE_F_KEY_CHANGE)
            {
                fprintf (f, "     element_type            %d (f%d)\n", element->element_type,
                         element->element_type - 48);
            }
            if (element->liquescentia)
            {
                fprintf (f, "     liquescentia            %d (%s)\n", element->liquescentia,
                         libgregorio_dump_liquescentia (element->liquescentia));
            }
            gregorio_glyph *glyph = element->first_glyph;
            while (glyph)
            {
                fprintf (f, "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -\n");
                if (glyph->type)
                {
                    fprintf (f, "       type                  %d (%s)\n", glyph->type,
                             libgregorio_dump_type (glyph->type));
                }
                if (glyph->glyph_type)
                {
                  if (glyph->type == GRE_SPACE)
                  {
                    fprintf (f, "       glyph_type            %d (%s)\n", glyph->glyph_type,
                             libgregorio_dump_space_type (glyph->glyph_type));
                  }
                  if (glyph->type == GRE_BAR)
                  {
                    fprintf (f, "       glyph_type            %d (%s)\n", glyph->glyph_type,
                             libgregorio_dump_bar_type (glyph->glyph_type));
                  }
                  if ((glyph->type == GRE_FLAT)||(glyph->type == GRE_NATURAL))
                  {
                    fprintf (f, "       glyph_type            %d\n", glyph->glyph_type);
                  }
                  if ((glyph->type != GRE_SPACE)&&(glyph->type != GRE_BAR)&&(glyph->type != GRE_FLAT)&&(glyph->type != GRE_NATURAL))
                  {
                    fprintf (f, "       glyph_type            %d (%s)\n", glyph->glyph_type,
                             libgregorio_dump_glyph_type (glyph->glyph_type));
                  }
                }
                if (glyph->liquescentia)
                {
                    fprintf (f, "       liquescentia          %d (%s)\n", glyph->liquescentia,
                             libgregorio_dump_liquescentia (glyph->liquescentia));
                }
                gregorio_note *note = glyph->first_note;
                while (note)
                {
                    fprintf (f, "-  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  \n");
                    if (note->type)
                    {
                        fprintf (f, "         type                %d (%s)\n", note->type,
                                 libgregorio_dump_type (note->type));
                    }
                    if (note->pitch)
                    {
                        fprintf (f, "         pitch               %d\n", note->pitch);
                    }
                    if (note->shape)
                    {
                        fprintf (f, "         shape               %d (%s)\n", note->shape,
                                 libgregorio_dump_shape (note->shape));
                    }
                    if (note->signs)
                    {
                        fprintf (f, "         signs               %d (%s)\n", note->signs,
                                 libgregorio_dump_signs (note->signs));
                    }
                    if (note->liquescentia)
                    {
                        fprintf (f, "         liquescentia        %d (%s)\n", note->liquescentia,
                                 libgregorio_dump_liquescentia (note->liquescentia));
                    }
                    if (note->h_episemus_type)
                    {
                        fprintf (f, "         h_episemus_type     %d (%s)\n", note->h_episemus_type,
                                 libgregorio_dump_h_episemus_type (note->h_episemus_type));
                    }
                    if (note->h_episemus_top_note)
                    {
                        fprintf (f, "         h_episemus_top_note %d\n", note->h_episemus_top_note);
                    }
                    note = note->next_note;
                }
                glyph = glyph->next_glyph;
            }
            element = element->next_element;
        }
        fprintf (f, "=====================================================================\n");
        syllable = syllable->next_syllable;
    }
}

char *
libgregorio_dump_key_to_char (int key)
{
    char *str;
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


char *
libgregorio_dump_syllable_position (char pos)
{
    char *str;
    switch (pos)
    {
        case 1:
            str = "WORD_BEGINNING";
        break;
        case 2:
            str = "WORD_MIDDLE";
        break;
        case 3:
            str = "WORD_END";
        break;
        case 4:
            str = "WORD_ONE_SYLLABLE";
        break;
        default:
            str = "unknown";
        break;
    }
    return str;
}


char *
libgregorio_dump_type (char type)
{
    char *str;
    switch (type)
    {
        case 1:
            str = "GRE_NOTE";
        break;
        case 2:
            str = "GRE_GLYPH";
        break;
        case 3:
            str = "GRE_ELEMENT";
        break;
        case 4:
            str = "GRE_FLAT";
        break;
        case 5:
            str = "GRE_NATURAL";
        break;
        case 6:
            str = "GRE_C_KEY_CHANGE";
        break;
        case 7:
            str = "GRE_F_KEY_CHANGE";
        break;
        case 8:
            str = "GRE_END_OF_LINE";
        break;
        case 9:
            str = "GRE_SPACE";
        break;
        case 10:
            str = "GRE_BAR";
        break;
        case 11:
            str = "GRE_SYLLABLE";
        break;
        default:
            str = "unknown";
        break;
    }
    return str;
}


char *
libgregorio_dump_bar_type (char element_type)
{
    char *str;
    switch (element_type)
    {
        case 0:
            str = "B_NO_BAR";
        break;
        case 1:
            str = "B_VIRGULA";
        break;
        case 2:
            str = "B_DIVISIO_MINIMA";
        break;
        case 3:
            str = "B_DIVISIO_MINOR";
        break;
        case 4:
            str = "B_DIVISIO_MAIOR";
        break;
        case 5:
            str = "B_DIVISIO_FINALIS";
        break;
        default:
            str = "unknown";
        break;
    }
    return str;
}


char *
libgregorio_dump_space_type (char element_type)
{
    char *str;
    switch (element_type)
    {
        case '1':
            str = "SP_DEFAULT";
        break;
        case '2':
            str = "SP_NO_SPACE";
        break;
        case '3':
            str = "SP_ZERO_WIDTH";
        break;
        case '4':
            str = "SP_NEUMATIC_CUT";
        break;
        case '5':
            str = "SP_LARGER_SPACE";
        break;
        case '6':
            str = "SP_GLYPH_SPACE";
        break;
        default:
            str = "unknown";
        break;
    }
    return str;
}
char *
libgregorio_dump_element_type (char element_type)
{
    char *str;
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
char *
libgregorio_dump_liquescentia (char liquescentia)
{
    char *str;
    switch (liquescentia)
    {
        case 0:
            str = "L_NO_LIQUESCENTIA";
        break;
        case 1:
            str = "L_DEMINUTUS";
        break;
        case 2:
            str = "L_AUCTUS_ASCENDENS";
        break;
        case 3:
            str = "L_AUCTUS_DESCENDENS";
        break;
        case 4:
            str = "L_AUCTA";
        break;
        case 5:
            str = "L_INITIO_DEBILIS";
        break;
        case 6:
            str = "L_DEMINUTUS_INITIO_DEBILIS";
        break;
        case 7:
            str = "L_AUCTUS_ASCENDENS_INITIO_DEBILIS";
        break;
        case 8:
            str = "L_AUCTUS_DESCENDENS_INITIO_DEBILIS";
        break;
        case 9:
            str = "L_AUCTA_INITIO_DEBILIS";
        break;
        default:
            str = "unknown";
        break;
    }
    return str;
}
char *
libgregorio_dump_glyph_type (char glyph_type)
{
    char *str;
    switch (glyph_type)
    {
        case 1:
            str = "G_PUNCTUM_INCLINATUM";
        break;
        case 2:
            str = "G_2_PUNCTA_INCLINATA_DESCENDENS";
        break;
        case 3:
            str = "G_3_PUNCTA_INCLINATA_DESCENDENS";
        break;
        case 4:
            str = "G_4_PUNCTA_INCLINATA_DESCENDENS";
        break;
        case 5:
            str = "G_5_PUNCTA_INCLINATA_DESCENDENS";
        break;
        case 6:
            str = "G_2_PUNCTA_INCLINATA_ASCENDENS";
        break;
        case 7:
            str = "G_3_PUNCTA_INCLINATA_ASCENDENS";
        break;
        case 8:
            str = "G_4_PUNCTA_INCLINATA_ASCENDENS";
        break;
        case 9:
            str = "G_5_PUNCTA_INCLINATA_ASCENDENS";
        break;
        case 10:
            str = "G_TRIGONUS";
        break;
        case 11:
            str = "G_PUNCTA_INCLINATA";
        break;
        case 12:
            str = "G_UNDETERMINED";
        break;
        case 13:
            str = "G_VIRGA";
        break;
        case 14:
            str = "G_STROPHA";
        break;
        case 15:
            str = "G_STROPHA_AUCTA";
        break;
        case 16:
            str = "G_PUNCTUM";
        break;
        case 17:
            str = "G_PODATUS";
        break;
        case 18:
            str = "G_PES_QUADRATUM";
        break;
        case 19:
            str = "G_FLEXA";
        break;
        case 20:
            str = "G_TORCULUS";
        break;
        case 21:
            str = "G_TORCULUS_RESUPINUS";
        break;
        case 22:
            str = "G_TORCULUS_RESUPINUS_FLEXUS";
        break;
        case 23:
            str = "G_PORRECTUS";
        break;
        case 24:
            str = "G_PORRECTUS_FLEXUS";
        break;
        case 25:
            str = "G_BIVIRGA";
        break;
        case 26:
            str = "G_TRIVIRGA";
        break;
        case 27:
            str = "G_DISTROPHA";
        break;
        case 28:
            str = "G_DISTROPHA_AUCTA";
        break;
        case 29:
            str = "G_TRISTROPHA";
        break;
        case 30:
            str = "G_TRISTROPHA_AUCTA";
        break;
        case 31:
            str = "G_PES_QUADRATUM_FIRST_PART";
        break;
        case 32:
            str = "G_SCANDICUS";
        break;
        default:
            str = "unknown";
        break;
    }
    return str;
}

char *
libgregorio_dump_shape (char shape)
{
    char *str;
    switch (shape)
    {
        case 0:
            str = "S_UNDETERMINED";
        break;
        case 1:
            str = "S_PUNCTUM";
        break;
        case 2:
            str = "S_PUNCTUM_END_OF_GLYPH";
        break;
        case 3:
            str = "S_PUNCTUM_INCLINATUM";
        break;
        case 4:
            str = "S_VIRGA";
        break;
        case 5:
            str = "S_BIVIRGA";
        break;
        case 6:
            str = "S_TRIVIRGA";
        break;
        case 7:
            str = "S_ORISCUS";
        break;
        case 8:
            str = "S_ORISCUS_AUCTUS";
        break;
        case 9:
            str = "S_QUILISMA";
        break;
        case 10:
            str = "S_STROPHA";
        break;
        case 11:
            str = "S_STROPHA_AUCTA";
        break;
        case 12:
            str = "S_DISTROPHA";
        break;
        case 13:
            str = "S_DISTROPHA_AUCTA";
        break;
        case 14:
            str = "S_TRISTROPHA";
        break;
        case 15:
            str = "S_TRISTROPHA_AUCTA";
        break;
        case 16:
            str = "S_QUADRATUM";
        break;
        default:
            str = "unknown";
        break;
    }
    return str;
}

char *
libgregorio_dump_signs (char signs)
{
    char *str;
    switch (signs)
    {
        case 0:
            str = "_NO_SIGN";
        break;
        case 1:
            str = "_PUNCTUM_MORA";
        break;
        case 2:
            str = "_AUCTUM_DUPLEX";
        break;
        case 5:
            str = "_V_EPISEMUS";
        break;
        case 6:
            str = "_V_EPISEMUS_PUNCTUM_MORA";
        break;
        case 7:
            str = "_V_EPISEMUS_AUCTUM_DUPLEX";
        break;
        default:
            str = "unknown";
        break;
    }
    return str;
}

char *
libgregorio_dump_h_episemus_type (char h_episemus_type)
{
    char *str;
    switch (h_episemus_type)
    {
        case 0:
            str = "H_NO_EPISEMUS";
        break;
        case 1:
            str = "H_ONE";
        break;
        case 2:
            str = "H_ALONE";
        break;
        case 3:
            str = "H_MULTI";
        break;
        case 4:
            str = "H_MULTI_BEGINNING";
        break;
        case 5:
            str = "H_MULTI_MIDDLE";
        break;
        case 6:
            str = "H_MULTI_END";
        break;
        case 7:
            str = "H_UNDETERMINED";
        break;
        default:
            str = "unknown";
        break;
    }
    return str;
}
