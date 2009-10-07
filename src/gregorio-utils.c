/* 
Gregorio command line interface.
Copyright (C) 2006-2009 Elie Roux <elie.roux@telecom-bretagne.eu>

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
#include <unistd.h>
#include <stdlib.h>
#include <getopt.h>
#include <libgen.h>		/* for basename */
#include <string.h>		/* for strcmp */
#include <gregorio/struct.h>
#include <gregorio/plugin_loader.h>
#include <gregorio/messages.h>

#include <locale.h>
#include "gettext.h"
#define _(str) gettext(str)
#define N_(str) str

#ifndef MODULE_PATH_ENV
#  define MODULE_PATH_ENV        "MODULE_PATH"
#endif

#define DEFAULT_INPUT_FORMAT    "gabc"
#define DEFAULT_OUTPUT_FORMAT   "gtex"

#define define_path(file_name,string) \
		/*we first test if path is absolute */\
		if (string[0]=='/') {\
		/*path is absolute*/\
		file_name=string;\
		}\
		else {/*path is relative*/\
		file_name=malloc(150*sizeof(char));\
		snprintf(file_name,150,"%s/%s", current_directory, string);\
		}


// function that returns the filename without the extension
static char *
get_base_filename (char *fbasename)
{
  char *p;
  int l;
  char *ret;
  p = strrchr (fbasename, '.');
  if (!p)
    {
      return NULL;
    }
  l = strlen (fbasename) - strlen (p);
  ret = (char *) malloc ((l + 1) * sizeof (char));
  snprintf (ret, l + 1, "%s", fbasename);
  ret[l] = '\0';
  return ret;
}


// function that adds the good extension to a basename (without extension)
static char *
get_output_filename (char *fbasename, char *extension)
{
  char *output_filename = NULL;
  output_filename =
    (char *) malloc (sizeof (char) *
		     (strlen (extension) + strlen (fbasename) + 2));
  output_filename = strcpy (output_filename, fbasename);
  output_filename = strcat (output_filename, ".");
  output_filename = strcat (output_filename, extension);
  return output_filename;
}


/* the type definitions of the function to read a score from a file, and to write a score
to a file. Necessary for the libtool stuff... */

static void
print_licence ()
{
  printf ("\n\
Tools for manipulation of gregorian chant files\n\
Copyright (C) 2006-2008 Elie Roux <elie.roux@telecom-bretagne.eu>\n\
\n\
This program is free software: you can redistribute it and/or modify\n\
it under the terms of the GNU General Public License as published by\n\
the Free Software Foundation, either version 3 of the License, or\n\
(at your option) any later version.\n\
\n\
This program is distributed in the hope that it will be useful,\n\
but WITHOUT ANY WARRANTY; without even the implied warranty of\n\
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n\
GNU General Public License for more details.\n\
\n\
You should have received a copy of the GNU General Public License\n\
along with this program.  If not, see <http://www.gnu.org/licenses/>.\n\n");
}

static void
print_usage (char *name)
{
  printf (_("\nUsage :\n%s [OPTION] {file}\n  where OPTION is :\n\
\t-o file    writes output to specified file\n\
\t-S         writes output to stdout\n\
\t-F format  specifies output file format, default is gtex\n\
\t-l file    writes messages output to specified file (default stderr)\n\
\t-f format  specifies input file format, default is gabc\n\
\t-s         reads input from stdin\n\
\t-h         displays this message\n\
\t-V         displays %s version\n\
\t-L         displays licence\n\
\t-v         verbose mode\n\
\t-W         displays all warnings\n\
\n\
available formats are:\n\
\t gabc      gabc\n\
\t xml       GregorioXML\n\
\t gtex      GregorioTeX\n\
\t otex      OpusTeX\n\
\t dump      simple text dump\n\
\n"), name, name);
}

int
main (int argc, char **argv)
{
  const char *copyright =
    "Copyright (C) 2006-2008 Elie Roux <elie.roux@telecom-bretagne.eu>";
  int c;

  char *input_file_name = NULL;
  char *output_file_name = NULL;
  char *output_basename = NULL;
  char *error_file_name = NULL;
  FILE *input_file = NULL;
  FILE *output_file = NULL;
  FILE *error_file = NULL;
  char *input_format = NULL;
  char *output_format = NULL;
  char verb_mode = 0;
  char *current_directory = malloc (150 * sizeof (char));
  int number_of_options = 0;
  int option_index = 0;
  int error = 0;
  gregorio_plugin *input_plugin = NULL;
  gregorio_plugin_info *input_plugin_info = NULL;
  gregorio_plugin *output_plugin = NULL;
  gregorio_plugin_info *output_plugin_info = NULL;
  static struct option long_options[] = {
    {"output-file", 1, 0, 'o'},
    {"stdout", 0, 0, 'S'},
    {"output-format", 1, 0, 'F'},
    {"messages-file", 1, 0, 'l'},
    {"input-format", 1, 0, 'f'},
    {"stdin", 0, 0, 's'},
    {"help", 0, 0, 'h'},
    {"version", 0, 0, 'V'},
    {"licence", 0, 0, 'L'},
    {"verbose", 0, 0, 'v'},
    {"all-warnings", 0, 0, 'W'}
  };
  gregorio_score *score = NULL;

  if (argc == 1)
    {
      print_usage (argv[0]);
      exit (0);
    }
  current_directory = getcwd (current_directory, 150);

  bindtextdomain (PACKAGE, LOCALEDIR);
  bind_textdomain_codeset (PACKAGE, "UTF-8");
  textdomain (PACKAGE);

  if (current_directory == NULL)
    {
      fprintf (stderr, _("can't determine current directory"));
      free (current_directory);
      exit (-1);
    }

  error = gregorio_plugin_loader_init ();
  if (error)
    {
      fprintf (stderr, _("can't initalize libtool"));
      free (current_directory);
      exit (-1);
    }

  while (1)
    {
      c = getopt_long (argc, argv, "o:SF:l:f:shLVvW",
		       long_options, &option_index);
      if (c == -1)
	break;
      switch (c)
	{
	case 'o':
	  if (output_file_name)
	    {
	      fprintf (stderr,
		       "warning: several output files declared, %s taken\n",
		       output_file_name);
	      break;
	    }
	  if (output_file)
	    {			//means that stdout is defined
	      fprintf (stderr,
		       "warning: can't write to file and stdout, writing on stdout\n");
	      break;
	    }
	  define_path (output_file_name, optarg) break;
	case 'S':
	  if (output_file_name)
	    {
	      fprintf (stderr,
		       "warning: can't write to file and stdout, writing on %s\n",
		       output_file_name);
	      break;
	    }
	  if (output_file)
	    {			//means that stdout is defined
	      fprintf (stderr, "warning: option used two times: %c\n", c);
	      break;
	    }
	  output_file = stdout;
	  break;
	case 'F':
	  if (output_format)
	    {
	      fprintf (stderr,
		       "warning: several output formats declared, first taken\n");
	      break;
	    }
          output_format = optarg;
	  break;
	case 'l':
	  if (error_file_name)
	    {
	      fprintf (stderr,
		       "warning: several error files declared, %s taken\n",
		       error_file_name);
	      break;
	    }
	  define_path (error_file_name, optarg) break;
	case 'f':
	  if (input_format)
	    {
	      gregorio_set_error_out (error_file);
	      fprintf (stderr,
		       "warning: several output formats declared, first taken\n");
	      break;
	    }
          input_format = optarg;
	  break;
	case 's':
	  if (input_file_name)
	    {
	      fprintf (stderr,
		       "warning: can't read from file and stdin, writing on %s\n",
		       input_file_name);
	      break;
	    }
	  if (input_file)
	    {			//means that stdin is defined
	      fprintf (stderr, "warning: option used two times: %c\n", c);
	      break;
	    }
	  input_file = stdin;
	  break;
	case 'h':
	  print_usage (argv[0]);
	  exit (0);
	  break;
	case 'V':
	  printf ("%s version %s\n%s\n", argv[0], VERSION, copyright);
	  exit (0);
	  break;
	case 'v':
	  if (verb_mode && verb_mode != VERB_WARNINGS)
	    {
	      fprintf (stderr, "warning: verbose option passed two times\n");
	      break;
	    }
	  verb_mode = VERB_VERBOSE;
	  break;
	case 'W':
	  if (verb_mode == VERB_WARNINGS)
	    {
	      fprintf (stderr,
		       "warning: all-warnings option passed two times\n");
	      break;
	    }
	  if (verb_mode != VERB_VERBOSE)
	    {
	      verb_mode = VERB_WARNINGS;
	    }
	  break;
	case 'L':
	  print_licence ();
	  exit (0);
	  break;
	case '?':
	  break;
	default:
	  fprintf (stderr, "unknown option: %c\n", c);
	  print_usage (argv[0]);
	  exit (0);
	  break;
	}
      number_of_options++;
    }				//end of while
  if (optind == argc)
    {
      if (!input_file)
	{			//input not undefined (could be stdin)
	  fprintf (stderr, "error: no input file specified\n");
	  print_usage (argv[0]);
	  exit (-1);
	}
    }
  else
    {
      define_path (input_file_name, argv[optind]);
      output_basename = get_base_filename (input_file_name);
      if (input_file)
	{
	  fprintf (stderr,
		   "warning: can't read from stdin and a file, reading from file %s\n",
		   input_file_name);
	  input_file = NULL;
	}
    }
  optind++;
  if (optind < argc)
    {
      printf ("ignored arguments: ");
      while (number_of_options < argc)
	printf ("%s ", argv[number_of_options++]);
      printf ("\n");
    }

  if (!input_format)
    {
      input_format = DEFAULT_INPUT_FORMAT;
    }

  if (!output_format)
    {
      output_format = DEFAULT_OUTPUT_FORMAT;
    }

// then we act...

  /* Load plugins */
  output_plugin = gregorio_plugin_load(PLUGINDIR, output_format);
  if (output_plugin == NULL)
    {
      fprintf (stderr, "error: invalid output plugin %s\n", output_format);
      free (current_directory);
      exit (1);
    }
  output_plugin_info = gregorio_plugin_get_info(output_plugin);
  if ((output_plugin_info->type & GREGORIO_PLUGIN_OUTPUT) == 0)
    {
      gregorio_plugin_unload (output_plugin);
      fprintf (stderr, "error: invalid output plugin %s\n", output_format);
      free (current_directory);
      exit (1);
    }
  input_plugin = gregorio_plugin_load(PLUGINDIR, input_format);
  if (input_plugin == NULL)
    {
      gregorio_plugin_unload (output_plugin);
      fprintf (stderr, "error: invalid input plugin %s\n", input_format);
      free (current_directory);
      exit (1);
    }
  input_plugin_info = gregorio_plugin_get_info(input_plugin);
  if ((input_plugin_info->type & GREGORIO_PLUGIN_INPUT) == 0)
    {
      gregorio_plugin_unload (output_plugin);
      gregorio_plugin_unload (input_plugin);
      fprintf (stderr, "error: invalid input plugin %s\n", input_format);
      free (current_directory);
      exit (1);
    }

  if (!output_file_name && !output_file)
    {
      if (!output_basename)
	{
	  output_file = stdout;
	}
      else
	{
	  if (input_format != output_format)
	    {
	      output_file_name =
		get_output_filename (output_basename,
                                     output_plugin_info->file_extension);
	    }
	  output_file = fopen (output_file_name, "w");
	  if (!output_file)
	    {
	      fprintf (stderr, "error: can't write in file %s",
		       output_file_name);
	    }
	  free (output_basename);
	}
    }
  else
    {
      if (!output_file)
	{
	  output_file = fopen (output_file_name, "w");
	  if (!output_file)
	    {
	      fprintf (stderr, "error: can't write in file %s",
		       output_file_name);
	    }
	}
    }

//we always have input_file or input_file_name
  if (!input_file)
    {
      input_file = fopen (input_file_name, "r");
      if (!input_file)
	{
	  fprintf (stderr, "error: can't open file %s for reading\n",
		   input_file_name);
	  exit (-1);
	}
      gregorio_set_file_name (basename (input_file_name));
    }

  if (!error_file_name)
    {
      error_file = stderr;
      gregorio_set_error_out (error_file);
    }
  else
    {
      error_file = fopen (error_file_name, "w");
      if (!error_file)
	{
	  fprintf (stderr, "error: can't open file %s for writing\n",
		   error_file_name);
	  exit (-1);
	}
      gregorio_set_error_out (error_file);
    }

  free (current_directory);
  free (input_file_name);
  free (output_file_name);

  if (!verb_mode)
    {
      verb_mode = VERB_ERRORS;
    }

  gregorio_set_verbosity_mode (verb_mode);
  setlocale (LC_CTYPE, "");	//to work with an utf-8 encoding

  score = (input_plugin_info->read) (input_file);
  gregorio_plugin_unload (input_plugin);

  fclose (input_file);
  if (score == NULL)
    {
      gregorio_plugin_unload (output_plugin);
      fprintf (stderr, "error in file parsing\n");
      exit (-1);
    }

  gregorio_fix_initial_keys (score, DEFAULT_KEY);

  (output_plugin_info->write) (output_file, score);
  gregorio_plugin_unload (output_plugin);
  fclose (output_file);
  gregorio_free_score (score);

  gregorio_plugin_loader_exit();
  exit (0);
}
