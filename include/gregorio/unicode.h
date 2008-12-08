/* 
Gregorio unicode headers.
Copyright (C) 2008 Elie Roux <elie.roux@telecom-bretagne.eu>.

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

#ifndef GREGORIO_GLIB
#define GREGORIO_GLIB 0
#endif

#ifndef UNICODE_H_FIRST_PART
#define UNICODE_H_FIRST_PART
#define UNICODE_H

#if GREGORIO_GLIB

#include <glib.h>

#define grewchar gunichar

#else

#include <wchar.h>

#define grewchar wchar_t

#endif

#endif

// we enter the second part only if struct.h has already been included, because
// we need gregorio_character

#ifdef STRUCT_H

#ifndef UNICODE_H_SECOND_PART
#define UNICODE_H_SECOND_PART

gregorio_character * gregorio_build_char_list_from_buf (char *buf);

#endif

#endif
