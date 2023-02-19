// SPDX-License-Identifier: GPL-2.0-only
/* This file is part of cflash
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
#ifndef CONFIG_H
#define CONFIG_H

typedef enum {
  OP_NONE,
  OP_PROGRAM,
  OP_VERIFY,
  OP_ERASE_BANK,
  OP_ERASE_CHIP,
  OP_IDENTIFY
} operation_type;

typedef enum {
  SOURCE_NONE,
  SOURCE_FILE,
  SOURCE_ROM
} source_type;

struct Config {
  ULONG          programBank;
  UBYTE          programSlot;
  operation_type op;
  source_type    source;
  bool           skipVerify;
  char           *ks_filename;
  bool           flash_ide_rom;
  char           *ide_rom_filename;
};

struct Config* configure(int, char* []);

void usage();

#endif