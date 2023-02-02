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

#ifndef KICK_FLASH_H
#define KICK_FLASH_H

#include <exec/types.h>
#include <stdbool.h>

void kick_flash_unlock_sdp();
void kick_flash_erase_chip();
void kick_flash_command(UWORD);
void kick_flash_writeWord(ULONG, UWORD);
bool kick_flash_init(UWORD *, UWORD *);
void kick_flash_poll(ULONG);
void kick_flash_reset();
void kick_flash_erase_bank(int);
void kick_flash_erase_block(ULONG);

#endif