/*
 * Copyright (C) 2009-2015 The Gregorio Project (see CONTRIBUTORS.md)
 *
 * This file is part of Gregorio.
 *
 * Gregorio is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Gregorio is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Gregorio.  If not, see <http://www.gnu.org/licenses/>.
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

void gregorio_message(const char *string, const char *function_name,
        char verbosity, int line_number);
void gregorio_messagef(const char *function_name, char verbosity,
        int line_number, const char *format, ...)
        __attribute__ ((__format__ (__printf__, 4, 5)));
void gregorio_set_verbosity_mode(char new_mode);
void gregorio_set_file_name(char *new_name);
void gregorio_set_error_out(FILE *f);
int gregorio_get_return_value(void);

#define VERB_VERBOSE 1
#define VERB_WARNINGS 2
#define VERB_ERRORS 3
#define VERBOSE VERB_VERBOSE
#define WARNING VERB_WARNINGS
#define ERROR VERB_ERRORS
#define FATAL_ERROR 4

#endif
