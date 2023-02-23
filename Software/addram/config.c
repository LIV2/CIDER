// SPDX-License-Identifier: GPL-2.0-only
/* This file is part of addram
 * Copyright (C) 2023 Matthew Harlum <matt@harlum.net>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */
#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <proto/exec.h>

#include "config.h"

/**
 * Configure
 * 
 * Parse the command args and set the configuration appropriately
 * @param argc
 * @param argv
 * @returns Pointer to a Config struct.
*/
struct Config* Configure(int argc, char *argv[]) {
  struct Config *config = AllocMem(sizeof(struct Config),MEMF_ANY);

  if (config == NULL) {
    printf("Failed to allocate memory.\n");
    return (NULL);
  }

  config->dryRun            = false;
  config->mergeFastAndBonus = false;
  config->verbose           = false;
  config->fastPriority      = 0;

  bool success = true;
  for (int i=1; i<argc; i++) {
    if (argv[i][0] == '-') {
      switch(argv[i][1]) {
        case 'D':
        case 'd':
          config->dryRun = true;
          break;
        case 'v':
        case 'V':
          config->verbose = true;
          break;
        case 'p':
        case 'P':
          if (i+1 < argc && strlen(argv[i+1]) > 0) {
            config->fastPriority = atoi(argv[i+1]);
            printf("Setting priority to %d\n",config->fastPriority);
          } else {
            printf("Error: argument %s requires a priority.\n",argv[i]);
            success = false;
          }
          break;
        case 'm':
        case 'M':
          config->mergeFastAndBonus = true;
          break;
        default:
        case '?':
        case 'h':
        case 'H':
          usage();
          success = false;
          break;
      }
    }
  }
  if (success) {
    return (config);
  } else {
    return (NULL);
  }
}

/** 
 * usage
 * 
 * Print the usage information
*/
void usage() {
  printf("Usage: addram [-d] [-v] [-p <Priority>] [-f] [-h]\n\n");
  printf("       -d - Dry run\n");
  printf("       -v - Verbose\n");
  printf("       -p - Priority\n");
  printf("       -m - Try to merge Fast and BonusRam blocks \n");
  printf("       -h - Help\n");
}