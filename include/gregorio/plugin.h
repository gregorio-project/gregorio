/*
 * Gregorio plugin declaration headers.
 * Copyright (C) 2008 Jeremie Corbier
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef PLUGIN_H
#define PLUGIN_H

#include <stdio.h>
#include <gregorio/struct.h>

#define GREGORIO_PLUGIN_INPUT   1
#define GREGORIO_PLUGIN_OUTPUT  2
#define GREGORIO_PLUGIN_BOTH    GREGORIO_PLUGIN_INPUT | GREGORIO_PLUGIN_OUTPUT

typedef gregorio_score *(*gregorio_read_func)(FILE *);
typedef void (*gregorio_write_func)(FILE *, gregorio_score *);

typedef struct {
  char *id;
  char *name;
  char *author;
  char *description;

  char *file_extension;

  int type;

  gregorio_read_func read;
  gregorio_write_func write;
} gregorio_plugin_info;

#define DECLARE_PLUGIN(_id) gregorio_plugin_info _id##_LTX_info =

#endif
