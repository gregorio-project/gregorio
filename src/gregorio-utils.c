/*
 * Gregorio command line interface. Copyright (C) 2006-2015 Gregorio project
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
#include <unistd.h>
#include <stdlib.h>
#include <getopt.h>
#include <libgen.h>             /* for basename */
#include <string.h>             /* for strcmp */
#include <locale.h>
#include <limits.h>
#include "struct.h"
#include "plugins.h"
#include "messages.h"
#include "characters.h"

#ifndef MODULE_PATH_ENV
#define MODULE_PATH_ENV        "MODULE_PATH"
#endif

#define GABC 1
#define GTEX 3
#define DUMP 5
#define GABC_STR "gabc"
#define GTEX_STR "gtex"
#define DUMP_STR "dump"
#define DEFAULT_INPUT_FORMAT    GABC
#define DEFAULT_OUTPUT_FORMAT   GTEX

// realpath is not in mingw32
#ifdef __MINGW32__
#ifndef PATH_MAX
#define PATH_MAX _MAX_PATH
#endif
#define realpath(path,resolved_path) _fullpath(resolved_path, path, PATH_MAX)
#endif

static char *define_path(char *current_directory, char *string)
{
    int length;
    char *file_name;
    char temp_name[PATH_MAX];
    char *base_name;
#ifdef __MINGW32__
    char *last_backslash;
#endif

    // case 1: file exists
    file_name = realpath(string, NULL);
    if (file_name) {
        return file_name;
    }
    // case 2: file doesn't exist
    file_name = malloc(PATH_MAX * sizeof(char));

    strcpy(temp_name, string);
    base_name = strrchr(temp_name, '/');
#ifdef __MINGW32__
    last_backslash = strrchr(temp_name, '\\');
    if (last_backslash > base_name) {
        base_name = last_backslash;
    }
#endif
    if (base_name) {
        // some path was supplied

        *base_name = '\0';
        base_name++;

        // try to resolve it
        if (!realpath(temp_name, file_name)) {
            fprintf(stderr, "the directory %s for %s does not exist\n",
                    file_name, base_name);
            exit(-1);
        }
    } else {
        // no path was supplied
        base_name = string;
        strcpy(file_name, current_directory);
    }

    // make sure we're not bigger than PATH_MAX
    length = strlen(file_name);
    if (length + strlen(base_name) + 1 >= PATH_MAX) {
        fprintf(stderr, "filename too long: %s/%s\n", file_name, base_name);
        exit(-1);
    }
    // build the file name
    file_name[length] = '/';
    strcpy(file_name + length + 1, base_name);

    return file_name;
}

// function that returns the filename without the extension
static char *get_base_filename(char *fbasename)
{
    char *p;
    int l;
    char *ret;
    p = strrchr(fbasename, '.');
    if (!p) {
        return NULL;
    }
    l = strlen(fbasename) - strlen(p);
    ret = (char *) malloc((l + 1) * sizeof(char));
    snprintf(ret, l + 1, "%s", fbasename);
    ret[l] = '\0';
    return ret;
}

// function that adds the good extension to a basename (without extension)
static char *get_output_filename(char *fbasename, char *extension)
{
    char *output_filename = NULL;
    output_filename =
        (char *) malloc(sizeof(char) *
                        (strlen(extension) + strlen(fbasename) + 2));
    output_filename = strcpy(output_filename, fbasename);
    output_filename = strcat(output_filename, ".");
    output_filename = strcat(output_filename, extension);
    return output_filename;
}

/*
 * the type definitions of the function to read a score from a file, and to
 * write a score to a file. Necessary for the libtool stuff... 
 */

static void print_licence()
{
    printf("\n\
Tools for manipulation of gregorian chant files\n\
Copyright (C) 2006-2015 Gregorio project authors (see CONTRIBUTORS.md)\n\
\n\
This program is free software: you can redistribute it and/or modify\n\
it under the terms of the GNU General Public License as published by\n\
the Free Software Foundation, either version 3 of the License, or\n\
(at your option) any later version.\n\
\n");
    printf("This program is distributed in the hope that it will be useful,\n\
but WITHOUT ANY WARRANTY; without even the implied warranty of\n\
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n\
GNU General Public License for more details.\n\
\n\
You should have received a copy of the GNU General Public License\n\
along with this program.  If not, see <http://www.gnu.org/licenses/>.\n\n");
}

static void print_usage(char *name)
{
    printf(_("\nUsage :\n%s [OPTION] {file}\n  where OPTION is :\n\
\t-o file    writes output to specified file\n\
\t-S         writes output to stdout\n\
\t-F format  specifies output file format (default: gtex)\n\
\t-O         write two-bytes characters as \\char %%d instead of utf8 in TeX (deprecated)\n\
\t-l file    writes messages output to specified file (default: stderr)\n\
\t-f format  specifies input file format (default: gabc)\n\
\t-s         reads input from stdin\n\
\t-h         displays this message\n\
\t-V         displays %s version\n"), name, name);
    printf(_("\t-L         displays licence\n\
\t-v         verbose mode\n\
\t-W         displays all warnings\n\
\n\
available formats are:\n\
\t gabc      gabc\n\
\t gtex      GregorioTeX\n\
\t dump      simple text dump (for debugging purpose)\n\
\n"));
}

void check_input_clobber(char *input_file_name, char *output_file_name)
{
    if (input_file_name && output_file_name &&
        strcmp(input_file_name, output_file_name) == 0) {
        fprintf(stderr, "error: refusing to overwrite the input file\n");
        exit(-1);
    }
}

int main(int argc, char **argv)
{
    const char *copyright =
        "Copyright (C) 2006-2015 Gregorio project authors (see CONTRIBUTORS.md)";
    int c;

    char *input_file_name = NULL;
    char *output_file_name = NULL;
    char *output_basename = NULL;
    char *error_file_name = NULL;
    FILE *input_file = NULL;
    FILE *output_file = NULL;
    FILE *error_file = NULL;
    unsigned char input_format = 0;
    unsigned char output_format = 0;
    char verb_mode = 0;
    char *current_directory = malloc(PATH_MAX * sizeof(char));
    int number_of_options = 0;
    int option_index = 0;
    static struct option long_options[] = {
        {"output-file", 1, 0, 'o'},
        {"stdout", 0, 0, 'S'},
        {"output-format", 1, 0, 'F'},
        {"messages-file", 1, 0, 'l'},
        {"input-format", 1, 0, 'f'},
        {"stdin", 0, 0, 's'},
        {"old-style-tex", 0, 0, 'O'},
        {"help", 0, 0, 'h'},
        {"version", 0, 0, 'V'},
        {"licence", 0, 0, 'L'},
        {"verbose", 0, 0, 'v'},
        {"all-warnings", 0, 0, 'W'}
    };
    gregorio_score *score = NULL;

    if (argc == 1) {
        print_usage(argv[0]);
        exit(0);
    }
    setlocale(LC_CTYPE, "C");
    current_directory = getcwd(current_directory, PATH_MAX);

#if ENABLE_NLS == 1
    bindtextdomain(PACKAGE, LOCALEDIR);
    bind_textdomain_codeset(PACKAGE, "UTF-8");
    textdomain(PACKAGE);
#endif

    if (current_directory == NULL) {
        fprintf(stderr, _("can't determine current directory"));
        free(current_directory);
        exit(-1);
    }

    while (1) {
        c = getopt_long(argc, argv, "o:SF:l:f:shOLVvW",
                        long_options, &option_index);
        if (c == -1)
            break;
        switch (c) {
        case 'o':
            if (output_file_name) {
                fprintf(stderr,
                        "warning: several output files declared, %s taken\n",
                        output_file_name);
                break;
            }
            if (output_file) {  // means that stdout is defined
                fprintf(stderr,
                        "warning: can't write to file and stdout, writing on stdout\n");
                break;
            }
            output_file_name = define_path(current_directory, optarg);
            break;
        case 'S':
            if (output_file_name) {
                fprintf(stderr,
                        "warning: can't write to file and stdout, writing on %s\n",
                        output_file_name);
                break;
            }
            if (output_file) {  // means that stdout is defined
                fprintf(stderr, "warning: option used two times: %c\n", c);
                break;
            }
            output_file = stdout;
            break;
        case 'O':
            fprintf(stderr,
                    "Warning: -O option is deprecated, it will be removed in next release.\nIf you use it, please tell the mailing list.\n");
            gregorio_set_tex_write(WRITE_OLD_TEX);
            break;
        case 'F':
            if (output_format) {
                fprintf(stderr,
                        "warning: several output formats declared, first taken\n");
                break;
            }
            if (!strcmp(optarg, GABC_STR)) {
                output_format = GABC;
                break;
            }
            if (!strcmp(optarg, GTEX_STR)) {
                output_format = GTEX;
                break;
            }
            if (!strcmp(optarg, DUMP_STR)) {
                output_format = DUMP;
                break;
            } else {
                fprintf(stderr, "error: unknown output format: %s\n", optarg);
                exit(0);
            }
            break;
        case 'l':
            if (error_file_name) {
                fprintf(stderr,
                        "warning: several error files declared, %s taken\n",
                        error_file_name);
                break;
            }
            error_file_name = define_path(current_directory, optarg);
            break;
        case 'f':
            if (input_format) {
                gregorio_set_error_out(error_file);
                fprintf(stderr,
                        "warning: several output formats declared, first taken\n");
                break;
            }
            if (!strcmp(optarg, GABC_STR)) {
                input_format = GABC;
                break;
            } else {
                fprintf(stderr, "error: unknown input format: %s\n", optarg);
                exit(0);
            }
            break;
        case 's':
            if (input_file_name) {
                fprintf(stderr,
                        "warning: can't read from file and stdin, writing on %s\n",
                        input_file_name);
                break;
            }
            if (input_file) {   // means that stdin is defined
                fprintf(stderr, "warning: option used two times: %c\n", c);
                break;
            }
            input_file = stdin;
            break;
        case 'h':
            print_usage(argv[0]);
            exit(0);
            break;
        case 'V':
            printf("Gregorio version %s.\n%s\n", VERSION, copyright);
            exit(0);
            break;
        case 'v':
            if (verb_mode && verb_mode != VERB_WARNINGS) {
                fprintf(stderr, "warning: verbose option passed two times\n");
                break;
            }
            verb_mode = VERB_VERBOSE;
            break;
        case 'W':
            if (verb_mode == VERB_WARNINGS) {
                fprintf(stderr,
                        "warning: all-warnings option passed two times\n");
                break;
            }
            if (verb_mode != VERB_VERBOSE) {
                verb_mode = VERB_WARNINGS;
            }
            break;
        case 'L':
            print_licence();
            exit(0);
            break;
        case '?':
            break;
        default:
            fprintf(stderr, "unknown option: %c\n", c);
            print_usage(argv[0]);
            exit(0);
            break;
        }
        number_of_options++;
    }                           // end of while
    if (optind == argc) {
        if (!input_file) {      // input not undefined (could be stdin)
            fprintf(stderr, "error: no input file specified\n");
            print_usage(argv[0]);
            exit(-1);
        }
    } else {
        input_file_name = define_path(current_directory, argv[optind]);
        output_basename = get_base_filename(input_file_name);
        if (input_file) {
            fprintf(stderr,
                    "warning: can't read from stdin and a file, reading from file %s\n",
                    input_file_name);
            input_file = NULL;
        }
    }
    optind++;
    if (optind < argc) {
        printf("ignored arguments: ");
        while (number_of_options < argc)
            printf("%s ", argv[number_of_options++]);
        printf("\n");
    }

    if (!input_format) {
        input_format = DEFAULT_INPUT_FORMAT;
    }

    if (!output_format) {
        output_format = DEFAULT_OUTPUT_FORMAT;
    }
    // then we act...

    if (!output_file_name && !output_file) {
        if (!output_basename) {
            output_file = stdout;
        } else {
            if (input_format != output_format) {
                switch (output_format) {
                case GABC:
                    output_file_name =
                        get_output_filename(output_basename, "gabc");
                    break;
                case GTEX:
                    output_file_name =
                        get_output_filename(output_basename, "tex");
                    break;
                case DUMP:
                    output_file_name =
                        get_output_filename(output_basename, "dump");
                    break;
                }
            }
            check_input_clobber(input_file_name, output_file_name);
            output_file = fopen(output_file_name, "w");
            if (!output_file) {
                fprintf(stderr, "error: can't write in file %s",
                        output_file_name);
            }
            free(output_basename);
        }
    } else {
        if (!output_file) {
            if (!input_file) {
                check_input_clobber(input_file_name, output_file_name);
            }
            output_file = fopen(output_file_name, "w");
            if (!output_file) {
                fprintf(stderr, "error: can't write in file %s",
                        output_file_name);
            }
        }
    }

    // we always have input_file or input_file_name
    if (!input_file) {
        input_file = fopen(input_file_name, "r");
        if (!input_file) {
            fprintf(stderr, "error: can't open file %s for reading\n",
                    input_file_name);
            exit(-1);
        }
        gregorio_set_file_name(basename(input_file_name));
    }

    if (!error_file_name) {
        error_file = stderr;
        gregorio_set_error_out(error_file);
    } else {
        error_file = fopen(error_file_name, "w");
        if (!error_file) {
            fprintf(stderr, "error: can't open file %s for writing\n",
                    error_file_name);
            exit(-1);
        }
        gregorio_set_error_out(error_file);
    }

    free(current_directory);
    free(input_file_name);
    free(output_file_name);

    if (!verb_mode) {
        verb_mode = VERB_ERRORS;
    }

    gregorio_set_verbosity_mode(verb_mode);

    switch (input_format) {
    case GABC:
        score = gabc_read_score(input_file);
        break;
    default:
        fprintf(stderr, "error : invalid input format\n");
        fclose(input_file);
        fclose(output_file);
        exit(-1);
        break;
    }

    fclose(input_file);
    if (score == NULL) {
        fclose(output_file);
        fprintf(stderr, "error in file parsing\n");
        exit(-1);
    }

    gregorio_fix_initial_keys(score, DEFAULT_KEY);

    switch (output_format) {
    case GABC:
        gabc_write_score(output_file, score);
        break;
    case GTEX:
        gregoriotex_write_score(output_file, score);
        break;
    case DUMP:
        dump_write_score(output_file, score);
        break;
    default:
        fprintf(stderr, "error : invalid output format\n");
        gregorio_free_score(score);
        fclose(output_file);
        exit(-1);
        break;
    }
    fclose(output_file);
    gregorio_free_score(score);

    exit(gregorio_get_return_value());
}
