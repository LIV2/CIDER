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
#ifndef KICK_FLASH_CONSTANTS_H
#define KICK_FLASH_CONSTANTS_H

// Micron 29F160
#define FLASH_MANUF      0x0001
#define FLASH_DEV_TOP    0x22D2
#define FLASH_DEV_BOTTOM 0x22D8

#define BLOCK_SIZE   0x010000
#define BANK_SIZE    0x080000
#define BANK_SECTORS (BANK_SIZE / SECTOR_SIZE)
#define FLASH_SIZE   0x100000

#define FLASHBASE     0xA00000

// Command addresses left-shifted because Flash A0 = CPU A1
#define ADDR_CMD_STEP_1  (0x555 << 1)
#define ADDR_CMD_STEP_2  (0x2AA << 1)

#define CMD_SDP_STEP_1   0xAA
#define CMD_SDP_STEP_2   0x55
#define CMD_WORD_PROGRAM 0xA0
#define CMD_ERASE        0x80
#define CMD_ERASE_BLOCK  0x30
#define CMD_ERASE_CHIP   0x10
#define CMD_ID_ENTRY     0x90
#define CMD_CFI_ENTRY    0x98
#define CMD_CFI_ID_EXIT  0xF0
#define CMD_READ_RESET   0xF0

#endif