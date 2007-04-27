/* 
Gregorio messages.
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
#include "gettext.h"
#include "messages.h"
#define _(str) gettext(str)
#define N_(str) str

FILE *error_out;
char *file_name = NULL;
char verbosity_mode = 0;


void
libgregorio_set_error_out (FILE * f)
{
  error_out = f;
}

void
libgregorio_set_file_name (char *new_name)
{
  file_name = new_name;
}

void
libgregorio_set_verbosity_mode (char new_mode)
{
  verbosity_mode = new_mode;
}

const char *
verbosity_to_str (char verbosity)
{
  const char *str;
  switch (verbosity)
    {
    case WARNING:
      str = _(" warning:");
      break;
    case ERROR:
      str = _(" error:");
      break;
    case FATAL_ERROR:
      str = _(" fatal error:");
      break;
    default: //VERBOSE, for example
      str = " ";
      break;
    }
  return str;
}

void
libgregorio_message (const char *string, char *function_name, char verbosity,
		int line_number)
{
  if (!error_out)
    {
      fprintf (stderr,
	       _
	       ("warning: error_out not set in libgregorio_messages, assumed stderr\n"));
      error_out = stderr;
    }
  if (!verbosity_mode)
    {
      fprintf (stderr,
	       _
	       ("warning: verbosity mode not set in libgregorio_messages, assumed warnings\n"));
      verbosity_mode = VERB_WARNINGS;
    }
  if (verbosity < verbosity_mode)
    {
      return;
    }
  const char *verbosity_str = verbosity_to_str (verbosity);
  if (line_number)
    {
      if (function_name)
	{
	  if (!file_name)
	    {
	      fprintf (error_out, "line %d: in function `%s':%s %s\n",
		       line_number, function_name, verbosity_str, string);
	      return;
	    }
	  else
	    {
	      fprintf (error_out, "%s:%d: in function `%s':%s %s\n", file_name,
		       line_number, function_name, verbosity_str, string);
	    }
	}
      else
	{			//no function_name specified
	  if (!file_name)
	    {
	      fprintf (error_out, "line %d:%s %s\n", line_number,
		       verbosity_str, string);
	      return;
	    }
	  else
	    {
	      fprintf (error_out, "%s:%d:%s %s\n", file_name, line_number,
		       verbosity_str, string);
	    }
	}
    }
  else
    {
      if (function_name)
	{
	  if (!file_name)
	    {
	      fprintf (error_out, "in function `%s':%s %s\n",
		       function_name, verbosity_str, string);
	      return;
	    }
	  else
	    {
	      fprintf (error_out, "%s: in function `%s':%s %s\n", file_name,
		       function_name, verbosity_str, string);
	    }
	}
      else
	{			//no function_name specified
	  if (!file_name)
	    {
	      fprintf (error_out, "%s %s\n", verbosity_str, string);
	      return;
	    }
	  else
	    {
	      fprintf (error_out, "%s:%s %s\n", file_name,
		       verbosity_str, string);
	    }
	}
    }
}
