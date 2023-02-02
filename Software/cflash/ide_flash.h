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

#ifndef IDE_FLASH_H
#define IDE_FLASH_H

#include <exec/types.h>
#include <stdbool.h>

void ide_flash_unlock_sdp();
void ide_flash_erase_chip();
void ide_flash_command(UWORD);
void ide_flash_writeByte(UWORD, UBYTE);
bool ide_flash_init(UBYTE *, UBYTE *, ULONG *);
void ide_flash_poll(UWORD);
void ide_flash_erase_block(UWORD);

#endif