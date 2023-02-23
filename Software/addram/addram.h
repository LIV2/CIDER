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
#ifndef _ADDRAM_H
#define _ADDRAM_H

#include "exec/types.h"
#include "config.h"

// Compiler warning fixes
#ifndef CacheClearE
// Silence the "implicit declaration of function" warning for this...
void CacheClearE(APTR,ULONG,ULONG);
#endif
#undef FindConfigDev
// NDK 1.3 definition of FindConfigDev is incorrect which causes "makes pointer from integer without a cast" warning
struct ConfigDev* FindConfigDev(struct ConfigDev*, LONG, LONG);

// End fixes
#define BOARDSTRING "GottaGoFast!!!\0"
#define BOARD_MANUF 2011
#define BOARD_PROD  74
#define BONUSRAM_EN 1<<13
#define SET_FLAG    1<<12

#define BONUSRAM_START 0xA00000
#define BONUSRAM_END   0xBF0000

void enableBonusRam();
void disableBonusRam();
ULONG sizeBonusRam(Config *);
void fixPriorities(char *, Config *);
bool getArgs(int, char*[]);
bool addBonusRam(ULONG, char*, struct Config*);

#endif