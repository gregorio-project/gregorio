/* 
Gregorio messages headers.
Copyright (C) 2006-2009 Elie Roux <elie.roux@telecom-bretagne.eu>

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

#ifndef MESSAGES_H
#define MESSAGES_H

#ifndef ENABLE_NLS
#define ENABLE_NLS 0
#endif
#if ENABLE_NLS == 1
    #include "gettext.h"
    #define _(str) gettext(str)
    #define N_(str) str
    #define ngt_(str, strtwo, count) ngettext(str, strtwo, count)
#else
    #define _(str) str
    #define N_(str) str
    #define ngt_(str, strtwo, count) str
#endif

#ifdef __cplusplus
extern "C" {
#endif

void gregorio_message (const char *string, const char *function_name, char verbosity, int line_number);
void gregorio_set_verbosity_mode (char new_mode);
void gregorio_set_file_name (char *new_name);
void gregorio_set_error_out (FILE *f);

#define VERB_VERBOSE 1
#define VERB_WARNINGS 2
#define VERB_ERRORS 3
#define VERBOSE VERB_VERBOSE
#define WARNING VERB_WARNINGS
#define ERROR VERB_ERRORS
#define FATAL_ERROR 4

#ifdef __cplusplus
}
#endif

#endif
