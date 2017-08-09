/*
 * Copyright (C) 2017  Roel Janssen <roel@gnu.org>
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

#include "GenomePosition.h"
#include "RuntimeConfiguration.h"
#include "helper.h"

#include <stdio.h>
#include <gcrypt.h>

extern RuntimeConfiguration program_config;

char *
hash_GenomePosition (GenomePosition *g, bool use_cache)
{
  if (g == NULL) return NULL;

  /* Cache the hash generation. */
  if (g->hash != NULL && use_cache) return g->hash;

  gcry_error_t error;
  gcry_md_hd_t handler = NULL;

  error = gcry_md_open (&handler, GCRY_MD_SHA256, 0);
  if (error)
    {
      fprintf (stderr, "ERROR: %s/%s\n",
               gcry_strsource (error),
               gcry_strerror (error));
      return NULL;
    }

  unsigned char *binary_hash = NULL;

  int32_t position_strlen = 0;
  char position_str[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
  position_strlen = sprintf (position_str, "%d", g->position);

  gcry_md_write (handler, g->chromosome, g->chromosome_len);
  gcry_md_write (handler, position_str, position_strlen);

  binary_hash = gcry_md_read (handler, 0);
  g->hash = get_pretty_hash (binary_hash, HASH_LENGTH);

  gcry_md_close (handler);
  return g->hash;
}

void
print_GenomePosition (GenomePosition *g)
{
  if (g == NULL) return;

  printf ("p:%s a :GenomePosition ;\n", hash_GenomePosition (g, true));
  printf ("  :position   %d ;\n", g->position);
  printf ("  :chromosome \"%s\" .\n\n", g->chromosome);
}
