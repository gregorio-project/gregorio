/*
 * Gregorio plugin skeleton.
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
#include "config.h"
#include "plugin.h"

static gregorio_score *skel_read_score (FILE *f)
{
  return NULL;
}

static void skel_write_score (FILE *f, gregorio_score *score)
{
}

DECLARE_PLUGIN(skel)
{
  .id = "skel",
  .name = "skeleton",
  .description = "Gregorio plugin skeleton",
  .author = "Jeremie Corbier <jeremie.corbier@resel.enst-bretagne.fr>",

  .type = GREGORIO_PLUGIN_BOTH,

  .file_extension = "txt",

  .read = skel_read_score,
  .write = skel_write_score
};

