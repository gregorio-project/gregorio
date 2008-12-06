/* 
Gregorio unicode character manipulation file.
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

#include "config.h"
#include <stdio.h>
#include "gettext.h"
#include <stdlib.h>
#include <gregorio/struct.h>
#include <gregorio/unicode.h>
#include <gregorio/messages.h>
#define _(str) gettext(str)
#define N_(str) str

/*

This file contains the definition of some functions that are different according
to the different cases of unicode systems in Gregorio. There are
two choices now, that are done at compilation time (with the
--enable-glib-utf8 option of configure):

The standard wchar_t system. It works fine with UTF-8 under Linux and MacOSX,
but under Windows the wchar_t is only 2 bytes wide, so it's unable to read UTF-8
correctly.

The glib system. It's not useful under Linux and MacOSX, but it's necessary
under Windows in order to enable Gregorio to read UTF-8.

As the policy is that gabc files are *only* in UTF-8, this option is *mandatory*
under Windows.

*/

#if GREGORIO_GLIB

gregorio_character *
gregorio_build_char_list_from_buf (char *buf)
{
  gregorio_character *current_character = NULL;
  if (buf == NULL || !g_utf8_validate(buf, -1, NULL))
    {
      return NULL;
    }
  while (buf && *buf != '\0') {
    gregorio_add_character (&current_character, g_utf8_get_char (buf));
    buf = g_utf8_find_next_char (buf, NULL);
    }
  gregorio_go_to_first_character(&current_character);
  return current_character;
}

void
gregorio_fprint_grewchar (FILE *f, grewchar gwc)
{

}

#else

gregorio_character *
gregorio_build_char_list_from_buf (char *buf)
{
  int i = 0;
  size_t len;
  grewchar *gwstring;
  gregorio_character *current_character = NULL;
  if (buf == NULL)
    {
      return NULL;
    }
  len = strlen (buf);	//to get the length of the syllable in ASCII
  gwstring = (grewchar *) malloc ((len + 1) * sizeof (grewchar));
  mbstowcs (gwstring, buf, (sizeof (grewchar) * (len + 1)));	//converting into wchar_t
  // then we get the real length of the syllable, in letters
  len = wcslen (gwstring);
  gwstring[len] = L'\0';
  // we add the corresponding characters in the list of gregorio_characters
  while (gwstring[i])
    {
      gregorio_add_character (&current_character, gwstring[i]);
      i++;
    }
  free (gwstring);
  gregorio_go_to_first_character(&current_character);
  return current_character;
}

void
gregorio_fprint_grewchar (FILE *f, grewchar gwc)
{

}

#endif
