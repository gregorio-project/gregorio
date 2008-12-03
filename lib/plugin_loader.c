/*
 * Gregorio plugin loader.
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
#include <stdlib.h>
#include <string.h>
#include <ltdl.h>

#include "plugin_loader.h"

int gregorio_plugin_loader_init ()
{
    return lt_dlinit();
}

int gregorio_plugin_loader_exit ()
{
    return lt_dlexit();
}

/*
 * Holds LTDL handle and plugin infos - should only be accessed through
 * gregorio_plugin_get_info.
 */
struct gregorio_plugin {
  gregorio_plugin_info *info;
  lt_dlhandle handle;
};

/*
 * Internal struct - workaround to pass two parameters to lt_dlforeachfiles
 * utility function
 */
struct load_params {
  const char *id;
  gregorio_plugin *plugin;
};

static int do_load_plugin(const char *filename, void *data)
{
  struct load_params *params = (struct load_params *)data;

  params->plugin->handle = lt_dlopenext(filename);
  if (params->plugin->handle == NULL)
    {
      return 0;
    }

  params->plugin->info = lt_dlsym(params->plugin->handle, "info");
  if (params->plugin->info == NULL)
    {
      goto end;
    }

  if (strcmp(params->plugin->info->id, params->id) == 0)
    {
      return 1;
    }

end:
  lt_dlclose(params->plugin->handle);
  params->plugin->handle = NULL;
  return 0;
}

gregorio_plugin *gregorio_plugin_load (const char *path, const char *id)
{
  struct load_params params;

  params.id = id;
  params.plugin = malloc (sizeof(gregorio_plugin));

  if (params.plugin == NULL)
    {
      return NULL;
    }

  /* Find the first plugin in path matching params.id */
  lt_dlforeachfile (path, do_load_plugin, (void *)&params);

  if (params.plugin->handle == NULL)
    {
      free(params.plugin);
      return NULL;
    }

  return params.plugin;
}

void gregorio_plugin_unload (gregorio_plugin *plugin)
{
  if (plugin != NULL)
    {
      lt_dlclose(plugin->handle);
      free(plugin);
    }
}

gregorio_plugin_info *gregorio_plugin_get_info(gregorio_plugin *plugin)
{
  if (plugin != NULL)
    {
      return plugin->info;
    }
  return NULL;
}
