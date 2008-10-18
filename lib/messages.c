/* 
Gregorio messages.
Copyright (C) 2006 Elie Roux <elie.roux@enst-bretagne.fr>

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
#include "messages.h"
#define _(str) gettext(str)
#define N_(str) str

FILE *error_out;
char *file_name = NULL;
char verbosity_mode = 0;
char debug_messages = 0;


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

void
libgregorio_set_debug_messages (char new_mode)
{
  debug_messages = new_mode;
}

const char *
verbosity_to_str (char verbosity)
{
  const char *str;
  switch (verbosity)
    {
    case WARNING:
      str = _("warning:");
      break;
    case ERROR:
      str = _("error:");
      break;
    case FATAL_ERROR:
      str = _("fatal error:");
      break;
    default: //VERBOSE, for example
      str = " ";
      break;
    }
  return str;
}

void
libgregorio_message (const char *string, const char *function_name, char verbosity,
		int line_number)
{
  const char *verbosity_str;

  if (debug_messages == 0)
    {
      line_number=0;
      function_name=NULL;    
    }

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
  verbosity_str = verbosity_to_str (verbosity);
  if (line_number)
    {
      if (function_name)
	{
	  if (!file_name)
	    {
	      fprintf (error_out, "line %d: in function `%s': %s %s\n",
		       line_number, function_name, verbosity_str, string);
	      return;
	    }
	  else
	    {
	      fprintf (error_out, "%d: in function `%s':%s %s\n",
		       line_number, function_name, verbosity_str, string);
	    }
	}
      else
	{			//no function_name specified
	  if (!file_name)
	    {
	      fprintf (error_out, "line %d: %s %s\n", line_number,
		       verbosity_str, string);
	      return;
	    }
	  else
	    {
	      fprintf (error_out, "%d: %s %s\n", line_number,
		       verbosity_str, string);
	    }
	}
    }
  else
    {
      if (function_name)
	{
	  /*if (!file_name)
	    {
	      fprintf (error_out, "in function `%s':%s %s\n",
		       function_name, verbosity_str, string);
	      return;
	    }
	  else
	    {*/
	      fprintf (error_out, "in function `%s': %s %s\n",
		       function_name, verbosity_str, string);
	    //}
	}
      else
	{/*			//no function_name specified
	  if (!file_name)
	    {
	      fprintf (error_out, "%s %s\n", verbosity_str, string);
	      return;
	    }
	  else
	    {*/
	      fprintf (error_out, "%s %s\n",
		       verbosity_str, string);
	    //}
	}
    }
}
