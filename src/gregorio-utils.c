/* 
Gregorio command line interface.
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
#include "struct.h"
#include "xml.h"
#include "gabc.h"
#include "messages.h"
#include <unistd.h>
#include <locale.h>
#include <stdlib.h>
#include "gregoriotex.h"
#include "opustex.h"
#include "dump.h"
#include <getopt.h>
#include <libgen.h>		/* for basename */
#include <string.h>		/* for strcmp */

#define PACKAGE "gregorio_utils"
#define LOCALEDIR "/home/elie/pougne/po/"
#include <locale.h>
#include <libintl.h>
#define _(str) gettext(str)
#define N_(str) str

#define GABC 1
#define XML 2
#define GTEX 3
#define OTEX 4
#define DUMP 5
#define GABC_STR "gabc"
#define XML_STR "xml"
#define GTEX_STR "gtex"
#define OTEX_STR "otex"
#define DUMP_STR "dump"

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


char *version = "0.0.4";
char *copyright = "copyright 2006 Elie Roux <elie.roux@enst-bretagne.fr>";

void
print_licence ()
{
  printf ("\n\
Tools for manipulation of gregorian chant files\n\
Copyright (C) 2006 Elie Roux <elie.roux@enst-bretagne.fr>\n\
\n\
This program is free software; you can redistribute it and/or\n\
modify it under the terms of the GNU General Public License\n\
as published by the Free Software Foundation; either version 2\n\
of the License, or (at your option) any later version.\n\
\n\
This program is distributed in the hope that it will be useful,\n\
but WITHOUT ANY WARRANTY; without even the implied warranty of\n\
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n\
GNU General Public License for more details.\n\
\n\
You should have received a copy of the GNU General Public License\n\
along with this program; if not, write to the Free Software\n\
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.\n\n");
}

void
print_usage (char *name)
{
  printf (_("\nUsage :\n%s [OPTION] {file}\n  where OPTION is :\n\
\t-o file    writes output to specified file\n\
\t-S         writes output to stdout\n\
\t-F format  specifies outpuf file format, default is xml\n\
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
\t gabc      gregorio-abc\n\
\t xml       gregorio-xml\n\
\t gtex      gregoriotex\n\
\t otex      opustex\n\
\t dump      simple text dump\n\
\n"), name, name);
}

int
main (int argc, char **argv)
{

  if (argc == 1)
    {
      print_usage (argv[0]);
      exit (0);
    }

  bindtextdomain (PACKAGE, LOCALEDIR);
  bind_textdomain_codeset (PACKAGE, "UTF-8");
  textdomain (PACKAGE);
  int c;

  char *input_file_name = NULL;
  char *output_file_name = NULL;
  char *error_file_name = NULL;
  FILE *input_file = NULL;
  FILE *output_file = NULL;
  FILE *error_file = NULL;
  char input_format = 0;
  char output_format = 0;
  char verb_mode = 0;
  char *current_directory = malloc (150 * sizeof (char));
  current_directory = getcwd (current_directory, 150);
  int number_of_options = 0;

  if (current_directory == NULL)
    {
      fprintf (stderr, _("can't determine current directory"));
      free (current_directory);
      exit (-1);
    }
  int option_index = 0;
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
	  if (!strcmp (optarg, XML_STR))
	    {
	      output_format = XML;
	      break;
	    }
	  if (!strcmp (optarg, GABC_STR))
	    {
	      output_format = GABC;
	      break;
	    }
	  if (!strcmp (optarg, GTEX_STR))
	    {
	      output_format = GTEX;
	      break;
	    }
	  if (!strcmp (optarg, OTEX_STR))
	    {
	      output_format = OTEX;
	      break;
	    }
          if (!strcmp (optarg, DUMP_STR))
            {
              output_format = DUMP;
              break;
            }
            else
	    {
	      fprintf (stderr, "error: unknown output format: %s\n", optarg);
	      exit (0);
	    }
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
	      libgregorio_set_error_out (error_file);
	      fprintf (stderr,
		       "warning: several output formats declared, first taken\n");
	      break;
	    }
	  if (!strcmp (optarg, GABC_STR))
	    {
	      input_format = GABC;
	break;
	    }
	  if (!strcmp (optarg, XML_STR))
	    {
	      input_format = XML;
	    }
	  else
	    {
	      fprintf (stderr, "error: unknown input format: %s\n", optarg);
	      exit (0);
	    }
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
	  printf ("%s version %s\n%s\n", argv[0], version, copyright);
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
      define_path (input_file_name, argv[optind]) if (input_file)
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

// then we act...
  if (!output_file_name && !output_file)
    {
      output_file = stdout;
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
      libgregorio_set_file_name (basename (input_file_name));
    }

  if (!error_file_name)
    {
      error_file = stderr;
      libgregorio_set_error_out (error_file);
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
      libgregorio_set_error_out (error_file);
    }

  if (!input_format)
    {
      input_format = GABC;
    }

  if (!output_format)
    {
      output_format = XML;
    }

  if (!verb_mode)
    {
      verb_mode = VERB_ERRORS;
    }

  libgregorio_set_verbosity_mode (verb_mode);

  gregorio_score *score = NULL;

  switch (input_format)
    {
    case GABC:
      score = libgregorio_gabc_read_file (input_file);
      break;
    case XML:
	score = libgregorio_xml_read_file (input_file_name);
	break;
    default:
      score = NULL;
      break;
    }

  fclose (input_file);

  if (score == NULL)
    {
      fprintf (stderr, "error in file parsing\n");
      exit (-1);
    }

  libgregorio_fix_initial_keys (score, DEFAULT_KEY);

	setlocale(LC_CTYPE, ""); //to work with an utf-8 encoding

  switch (output_format)
    {
    case XML:
      libgregorio_xml_write_score (output_file, score);
      break;
    case GABC:
      libgregorio_gabc_write_score (output_file, score);
	break;
    case GTEX:
	libgregorio_gregoriotex_write_score(output_file, score);
	break;
    case OTEX:
	libgregorio_opustex_write_score(output_file, score);
	break;
    case DUMP:
        libgregorio_dump_score(output_file, score);
        break;
      default:
      break;
    }

  fclose (output_file);

  libgregorio_free_score (score);
  free (current_directory);
  free (input_file_name);
  free (output_file_name);

  exit (0);

}
