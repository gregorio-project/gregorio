/* 
Gregorio xml output format headers.
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

// Functions to write GregorioXML

#ifndef XML_H
#define XML_H

void
libgregorio_xml_write_score_attributes (FILE * f, gregorio_score * score);
void
libgregorio_xml_write_score (FILE * f, gregorio_score * score);
void
libgregorio_xml_write_specials_as_neumes (FILE * f, gregorio_element * element,
				    int voice, int *clef);

void
libgregorio_xml_write_neume (FILE * f, gregorio_element * element, int voice, int *clef,
		       char alterations[]);
void
libgregorio_xml_write_syllable (FILE * f, gregorio_syllable * syllable,
			  int number_of_voices, int clef[],
			  char alterations[][13]);
void
libgregorio_xml_print_text (FILE * f, gregorio_character *text, char position);
void
libgregorio_xml_write_key_change_in_polyphony (FILE * f, char step, int line,
					 int voice);

const char *libgregorio_xml_shape_to_str (char shape);
const char *libgregorio_xml_signs_to_str (char signs);
void libgregorio_xml_write_signs (FILE *f, char signs, char multi_h_episemus_type);
void libgregorio_xml_write_note (FILE *f, char signs, char step, int octave, char shape, char multi_h_episemus_type, char alteration);
const char *libgregorio_xml_glyph_type_to_str(char name);

void libgregorio_xml_write_liquescentia (FILE *f, char liquescentia);

void determine_h_episemus_type (gregorio_note *note);


void libgregorio_xml_write_gregorio_glyph (FILE *f, gregorio_glyph *glyph, int clef, char alterations[]);
void libgregorio_xml_write_gregorio_note (FILE *f, gregorio_note *note, int clef, char alterations[]);

void libgregorio_xml_write_alteration (FILE *f, char type, char pitch, int clef, char *tab);

void
libgregorio_xml_write_gregorio_element (FILE * f, gregorio_element * element, int *clef,
			   char alterations[]);

const char * libgregorio_xml_bar_to_str(char type);
void libgregorio_xml_write_neumatic_bar (FILE * f, char type);
void libgregorio_xml_write_space (FILE * f, char type);

void libgregorio_xml_write_key_change (FILE *f, char step, int line);

void libgregorio_xml_write_begin (FILE * f, unsigned char style);
void libgregorio_xml_write_end (FILE * f, unsigned char style);
void libgregorio_xml_write_special_char (FILE * f, wchar_t * special_char);
void libgregorio_xml_write_verb (FILE * f, wchar_t * verb_str);
void libgregorio_xml_print_char (FILE * f, wchar_t to_print);

void libgregorio_xml_set_pitch_from_octave_and_step (char step, int octave, char *pitch, int clef);

// Functions to read GregorioXML

#include <libxml/xmlmemory.h>
#include <libxml/parser.h>

gregorio_score * libgregorio_xml_read_file (char *filename);
void libgregorio_xml_read_score_attributes (xmlNodePtr current_node, xmlDocPtr doc, gregorio_score * score);
void libgregorio_xml_read_multi_voice_info (xmlNodePtr current_node, xmlDocPtr doc, gregorio_score * score);

void libgregorio_xml_read_mono_voice_info (xmlNodePtr current_node, xmlDocPtr doc, gregorio_score * score);

void libgregorio_xml_read_voice_info (xmlNodePtr current_node, xmlDocPtr doc, gregorio_voice_info * voice_info);

int
libgregorio_xml_read_initial_key (xmlNodePtr current_node, xmlDocPtr doc);

void
libgregorio_xml_read_key (xmlNodePtr current_node, xmlDocPtr doc, char *step,
			  int *line);

void
libgregorio_xml_read_syllable (xmlNodePtr current_node, xmlDocPtr doc,
			       gregorio_syllable ** current_syllable,
			       int number_of_voices, char alterations[][13],
			       int clefs[]);

char
libgregorio_xml_read_signs (xmlNodePtr current_node, xmlDocPtr doc,
			    char * h_episemus);

char
libgregorio_xml_read_shape (char *type);

void
libgregorio_xml_read_h_episemus (xmlNodePtr current_node, char *h_episemus);

char
libgregorio_xml_read_pitch (xmlNodePtr current_node, xmlDocPtr doc, int key);

void
  libgregorio_xml_read_note
  (xmlNodePtr
   current_node, xmlDocPtr doc, gregorio_note ** current_note, int key);

char
libgregorio_xml_read_glyph_type (char *type);

char
libgregorio_xml_read_alteration (xmlNodePtr current_node, xmlDocPtr doc,
				 int key);

void
libgregorio_xml_read_glyph (xmlNodePtr current_node, xmlDocPtr doc,
			    gregorio_glyph ** current_glyph,
			    int key);

void
libgregorio_xml_read_glyphs (xmlNodePtr current_node, xmlDocPtr doc,
			     gregorio_element * element, char alterations[13],
			     int key);

void
libgregorio_xml_read_element (xmlNodePtr current_node, xmlDocPtr doc,
			      gregorio_element ** current_element,
			      char alterations[13], int *key);

void
libgregorio_xml_read_elements (xmlNodePtr current_node, xmlDocPtr doc,
			       gregorio_element ** first_element,
			       char alterations[13], int *key);

void
libgregorio_xml_read_multi_neumes (xmlNodePtr current_node, xmlDocPtr doc,
				   gregorio_syllable * syllable,
				   int number_of_voices, char alterations[][13],
				   int clefs[]);

void
libgregorio_xml_read_mono_neumes (xmlNodePtr current_node, xmlDocPtr doc,
				  gregorio_syllable * syllable,
				  char alterations[][13], int clefs[]);

void
libgregorio_xml_read_text (xmlNodePtr current_node, xmlDocPtr doc,
			   gregorio_syllable * syllable);


char
libgregorio_xml_read_figura (char *liquescentia);

char libgregorio_xml_read_bar (xmlNodePtr current_node, xmlDocPtr doc);
char libgregorio_xml_read_position (char *position);

#endif
