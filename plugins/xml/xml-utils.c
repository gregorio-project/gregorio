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
#include <stdio.h>
#include <gregorio/struct.h>
#include <gregorio/messages.h>

#include "xml.h"

const char *
xml_shape_to_str (char shape)
{
  const char *str;

  switch (shape)
    {
    case S_PUNCTUM:
      str = "punctum";
      break;
    case S_PUNCTUM_INCLINATUM:
      str = "punctum_inclinatum";
      break;
    case S_PUNCTUM_INCLINATUM_DEMINUTUS:
      str = "punctum_inclinatum_deminutus";
      break;
    case S_PUNCTUM_INCLINATUM_AUCTUS:
      str = "punctum_inclinatum_auctus";
      break;
    case S_VIRGA:
      str = "virga";
      break;
    case S_VIRGA_REVERSA:
      str = "virga-reversa";
      break;
    case S_ORISCUS:
      str = "oriscus";
      break;
    case S_ORISCUS_AUCTUS:
      str = "oriscus_auctus";
      break;
    case S_QUILISMA:
      str = "quilisma";
      break;
    case S_STROPHA:
      str = "stropha";
      break;
    case S_PUNCTUM_CAVUM:
      str = "punctum_cavum";
      break;
    case S_LINEA_PUNCTUM:
      str = "linea_punctum";
      break;
    case S_LINEA_PUNCTUM_CAVUM:
      str = "linea_punctum_cavum";
      break;
    case S_LINEA:
      str = "linea";
      break;
    default:
      str = "punctum";
      gregorio_message (_("unknown shape, `punctum' assumed"),
                        "xml_shape_to_str", WARNING, 0);
      break;
    }
  return str;
}

const char *
xml_signs_to_str (char signs)
{
  const char *str;

  switch (signs)
    {
    case _PUNCTUM_MORA:
      str = "<right>auctum</right>";
      break;
    case _AUCTUM_DUPLEX:
      str = "<right>auctum_duplex</right>";
      break;
    case _V_EPISEMUS:
      str = "<bottom>v_episemus</bottom>";
      break;
    case _V_EPISEMUS_PUNCTUM_MORA:
      str = "<right>auctum</right>\n<bottom>v_episemus</bottom>";
      break;
    case _V_EPISEMUS_AUCTUM_DUPLEX:
      str = "<right>auctum_duplex</right>\n<bottom>v_episemus</bottom>";
      break;
    case _ACCENTUS:
      str = "<above>accentus</above>";
      break;
    case _ACCENTUS_REVERSUS:
      str = "<above>reversed_accentus</above>";
      break;
    case _CIRCULUS:
      str = "<above>circulus</above>";
      break;
    case _SEMI_CIRCULUS:
      str = "<above>semi_circulus</above>";
      break;
    case _SEMI_CIRCULUS_REVERSUS:
      str = "<above>reversed_semi_circulus</above>";
      break;
    case _ICTUS_A:
      str = "<ictus-a/>";
      break;
    case _ICTUS_T:
      str = "<ictus-t/>";
      break;
    case _V_EPISEMUS_ICTUS_A:
      str = "<bottom>v_episemus</bottom><ictus-a/>";
      break;
    case _V_EPISEMUS_ICTUS_T:
      str = "<bottom>v_episemus</bottom><ictus-t/>";
      break;
    default:
      str = "";
      break;
    }
  return str;
}

void
xml_write_signs (FILE *f, char signs, unsigned char h_episemus_type,
                 char rare_sign)
{
  const char *str;
  if (signs != _NO_SIGN || rare_sign != _NO_SIGN
      || simple_htype (h_episemus_type == H_ALONE))
    {
      fprintf (f, "<signs>");
      if (simple_htype (h_episemus_type == H_ALONE))
        {
          fprintf (f, "<top>h_episemus</top>");
        }
      if (has_bottom (h_episemus_type))
        {
          fprintf (f, "<bottom>h_episemus</bottom>");
        }
      if (signs != _NO_SIGN)
        {
          str = xml_signs_to_str (signs);
          fprintf (f, "%s", str);
        }
      if (rare_sign != _NO_SIGN)
        {
          str = xml_signs_to_str (rare_sign);
          fprintf (f, "%s", str);
        }
      fprintf (f, "</signs>");
    }
  if (simple_htype (h_episemus_type) == H_MULTI_BEGINNING)
    {
      fprintf (f, "<multi-h-episemus position=\"beginning\" />");
    }
  if (simple_htype (h_episemus_type) == H_MULTI_MIDDLE)
    {
      fprintf (f, "<multi-h-episemus position=\"middle\" />");
    }
  if (simple_htype (h_episemus_type) == H_MULTI_END)
    {
      fprintf (f, "<multi-h-episemus position=\"end\" />");
    }
}

void
xml_write_pitch (FILE *f, char pitch, char clef)
{
  char step;
  int octave;
  gregorio_set_octave_and_step_from_pitch (&step, &octave, pitch, clef);
  fprintf (f, "<pitch><step>%c</step><octave>%d</octave></pitch>",
           step, octave);
}

void
xml_write_note (FILE *f, char signs, char step,
                int octave, char shape,
                unsigned char h_episemus_type, char alteration, char rare_sign,
                char *texverb)
{
  const char *shape_str = xml_shape_to_str (shape);

  fprintf (f, "<note><pitch><step>%c</step><octave>%d</octave>", step, octave);
  if (alteration == FLAT)
    {
      fprintf (f, "<flated />");
    }
  fprintf (f, "</pitch>");
  fprintf (f, "<shape>%s</shape>", shape_str);
  if (texverb)
    {
      fprintf (f, "<texverb>%s</texverb>", texverb);
    }
  xml_write_signs (f, signs, h_episemus_type, rare_sign);
  fprintf (f, "</note>");
}

const char *
xml_glyph_type_to_str (char name)
{
  const char *str;

  switch (name)
    {
    case G_PUNCTUM_INCLINATUM:
      str = "punctum-inclinatum";
      break;
    case G_2_PUNCTA_INCLINATA_DESCENDENS:
      str = "2-puncta-inclinata-descendens";
      break;
    case G_3_PUNCTA_INCLINATA_DESCENDENS:
      str = "3-puncta-inclinata-descendens";
      break;
    case G_4_PUNCTA_INCLINATA_DESCENDENS:
      str = "4-puncta-inclinata-descendens";
      break;
    case G_5_PUNCTA_INCLINATA_DESCENDENS:
      str = "5-puncta-inclinata-descendens";
      break;
    case G_2_PUNCTA_INCLINATA_ASCENDENS:
      str = "2-puncta-inclinata-ascendens";
      break;
    case G_3_PUNCTA_INCLINATA_ASCENDENS:
      str = "3-puncta-inclinata-ascendens";
      break;
    case G_4_PUNCTA_INCLINATA_ASCENDENS:
      str = "4-puncta-inclinata-ascendens";
      break;
    case G_5_PUNCTA_INCLINATA_ASCENDENS:
      str = "5-puncta-inclinata-ascendens";
      break;
    case G_TRIGONUS:
      str = "trigonus";
      break;
    case G_PUNCTA_INCLINATA:
      str = "puncta-inclinata";
      break;
    case G_VIRGA:
      str = "virga";
      break;
    case G_VIRGA_REVERSA:
      str = "virga-reversa";
      break;
    case G_STROPHA:
      str = "stropha";
      break;
    case G_PUNCTUM:
      str = "punctum";
      break;
    case G_PODATUS:
      str = "podatus";
      break;
    case G_FLEXA:
      str = "flexa";
      break;
    case G_TORCULUS:
      str = "torculus";
      break;
    case G_TORCULUS_RESUPINUS:
      str = "torculus-resupinus";
      break;
    case G_TORCULUS_RESUPINUS_FLEXUS:
      str = "torculus-resupinus-flexus";
      break;
    case G_PORRECTUS:
      str = "porrectus";
      break;
    case G_PORRECTUS_FLEXUS:
      str = "porrectus-flexus";
      break;
    case G_BIVIRGA:
      str = "bivirga";
      break;
    case G_TRIVIRGA:
      str = "trivirga";
      break;
    case G_DISTROPHA:
      str = "distropha";
      break;
    case G_TRISTROPHA:
      str = "tristropha";
      break;
    case G_SCANDICUS:
      str = "scandicus";
      break;
    case G_SALICUS:
      str = "salicus";
      break;
    case G_ANCUS:
      str = "ancus";
      break;
    default:
      str = "";
      break;
    }
  return str;
}

void
xml_set_pitch_from_octave_and_step (char step,
                                    int octave, char *pitch, int clef)
{
  *pitch = gregorio_det_pitch (clef, step, octave);
}

void
xml_write_liquescentia (FILE *f, char liquescentia)
{
  if (liquescentia == L_NO_LIQUESCENTIA)
    {
      return;
    }
  if (is_initio_debilis (liquescentia))
    {
      fprintf (f, "<initio_debilis />");
    }
  if (liquescentia == L_DEMINUTUS || liquescentia == L_DEMINUTUS_INITIO_DEBILIS)
    {
      fprintf (f, "<figura>deminutus</figura>");
    }
  if (liquescentia == L_AUCTUS_ASCENDENS
      || liquescentia == L_AUCTUS_ASCENDENS_INITIO_DEBILIS)
    {
      fprintf (f, "<figura>auctus-ascendens</figura>");
    }
  if (liquescentia == L_AUCTUS_DESCENDENS
      || liquescentia == L_AUCTUS_DESCENDENS_INITIO_DEBILIS)
    {
      fprintf (f, "<figura>auctus-descendens</figura>");
    }
  if (liquescentia == L_AUCTA || liquescentia == L_AUCTA_INITIO_DEBILIS)
    {
      fprintf (f, "<figura>auctus</figura>");
    }
}

void
xml_write_alteration (FILE *f, char type, char pitch, int clef, char *tab)
{
  char step;
  int octave;

  gregorio_set_octave_and_step_from_pitch (&step, &octave, pitch, clef);
  switch (type)
    {
    case GRE_FLAT:
      tab[pitch - 'a'] = FLAT;
      fprintf (f, "<flat><step>%c</step><octave>%d</octave></flat>",
               step, octave);
      break;
    case GRE_NATURAL:
      tab[pitch - 'a'] = NO_ALTERATION;
      fprintf (f,
               "<natural><step>%c</step><octave>%d</octave></natural>",
               step, octave);
      break;
    case GRE_SHARP:
      tab[pitch - 'a'] = NO_ALTERATION;
      fprintf (f,
               "<sharp><step>%c</step><octave>%d</octave></sharp>",
               step, octave);
      break;
    }
}

const char *
xml_bar_to_str (char type)
{
  const char *str;

  switch (type)
    {
    case B_VIRGULA:
      str = "virgula";
      break;
    case B_DIVISIO_MINIMA:
      str = "divisio-minima";
      break;
    case B_DIVISIO_MINOR:
      str = "divisio-minor";
      break;
    case B_DIVISIO_MAIOR:
      str = "divisio-maior";
      break;
    case B_DIVISIO_FINALIS:
      str = "divisio-finalis";
      break;
    case B_DIVISIO_MINOR_D1:
      str = "dominican-bar-1";
      break;
    case B_DIVISIO_MINOR_D2:
      str = "dominican-bar-2";
      break;
    case B_DIVISIO_MINOR_D3:
      str = "dominican-bar-3";
      break;
    case B_DIVISIO_MINOR_D4:
      str = "dominican-bar-4";
      break;
    case B_DIVISIO_MINOR_D5:
      str = "dominican-bar-5";
      break;
    case B_DIVISIO_MINOR_D6:
      str = "dominican-bar-6";
      break;
    default:
      str = "";
      gregorio_message (_("unknown bar type, nothing will be done"),
                        "xml_bar_to_str", ERROR, 0);
      break;
    }
  return str;
}
