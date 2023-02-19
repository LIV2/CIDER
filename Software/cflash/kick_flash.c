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

#include <proto/expansion.h>
#include <exec/types.h>
#include <stdbool.h>

#include "kick_flash.h"
#include "kick_flash_constants.h"
#include "constants.h"

ULONG flashbase = FLASHBASE;
void *controlBase = NULL;

enum {
  TOP,
  BOTTOM
} flash_bootbank;

/** kick_flash_writeWord
 *
 * @brief Write a word to the Flash
 * @param address Address to write to
 * @param data The word to write
*/
void kick_flash_writeWord(ULONG address, UWORD data) {
  address &= (FLASH_SIZE-1);
  kick_flash_unlock_sdp();
  kick_flash_command(CMD_WORD_PROGRAM);
  *(UWORD *)(flashbase + address) = data;
  kick_flash_poll(address);

  return;
}

/** kick_flash_command
 *
 * @brief send a command to the Flash
 * @param command
*/
void kick_flash_command(UWORD command) {
  *(UWORD *)(flashbase + ADDR_CMD_STEP_1) = command;

  return;
}

/** kick_flash_unlock_sdp
 *
 * @brief Send the SDP command sequence
*/
void kick_flash_unlock_sdp() {
  *(UWORD *)(flashbase + ADDR_CMD_STEP_1) = CMD_SDP_STEP_1;
  *(UWORD *)(flashbase + ADDR_CMD_STEP_2) = CMD_SDP_STEP_2;

  return;
}

/** kick_flash_erase_chip
 *
 * @brief Perform a chip erase
*/
void kick_flash_erase_chip() {
  kick_flash_unlock_sdp();
  kick_flash_command(CMD_ERASE);
  kick_flash_unlock_sdp();
  kick_flash_command(CMD_ERASE_CHIP);

  kick_flash_poll(0);
}

/** kick_flash_poll
 *
 * @brief Poll the status bits at address, until they indicate that the operation has completed.
 * @param address Address to poll
*/
void kick_flash_poll(ULONG address) {
  address &= (FLASH_SIZE-1);
  volatile UWORD *read1 = ((void *)flashbase + address);
  volatile UWORD *read2 = ((void *)flashbase + address);
  while (((*read1 & 1<<6) != (*read2 & 1<<6))) {;;}
}

/** kick_flash_init
 *
 * @brief Check the manufacturer id of the device, return manuf and dev id
 * @param manuf Pointer to a UWORD that will be updated with the returned manufacturer id
 * @param devid Pointer to a UWORD that will be updatet with the returned device id
 * @return True if the manufacturer ID matches the expected value
*/
bool kick_flash_init(UWORD *manuf, UWORD *devid) {
  bool ret = false;
  UWORD manufId;
  UWORD deviceId;

  kick_flash_unlock_sdp();
  kick_flash_command(CMD_ID_ENTRY);

  manufId  = *(UWORD *)flashbase;
  deviceId = *(UWORD *)(flashbase + 2);

  kick_flash_command(CMD_CFI_ID_EXIT);

  if (manuf) *manuf = manufId;
  if (devid) *devid = deviceId;

  if (manufId == FLASH_MANUF) {
    if (deviceId == FLASH_DEV_TOP) {
      flash_bootbank = TOP;
      ret = true;
    } else if (deviceId == FLASH_DEV_BOTTOM) {
      flash_bootbank = BOTTOM;
      ret = true;
    }
  }

  return (ret);
}

/** kick_flash_reset
 *
 * @brief Reset the flash to read mode
*/
void kick_flash_reset() {
  kick_flash_command(CMD_READ_RESET);
}

/** kick_flash_erase_block
 *
 * @brief Erase a block of flash
 * @param address Address of the block to erase
 */
void kick_flash_erase_block(ULONG address) {
  address &= (ROM_1M - 1);
  kick_flash_unlock_sdp();
  kick_flash_command(CMD_ERASE);
  kick_flash_unlock_sdp();
  *(UWORD *)(flashbase + address) = CMD_ERASE_BLOCK;

  kick_flash_poll(address);
}

/** kick_flash_erase_bank
 * 
 * @brief Erase the specified bank, taking into account top/bottom boot blocks
 * @param bank The bank number (0-3) to erase
*/
void kick_flash_erase_bank(int bank) {
  ULONG block;
  if (flash_bootbank == TOP && bank == 3) {
    // Top of 29F160 consists of 32K+8K+8K+16K boot blocks
    //
    // Erase all of the 64K blocks + the 32K one
    for (int i = 0; i < BANK_SIZE/BLOCK_SIZE; i++) {
      block = (BANK_SIZE * bank) + (BLOCK_SIZE * i);
      kick_flash_erase_block(block);
    }

    // Erase the smaller blocks
    block += 32767;
    kick_flash_erase_block(block);
    block += 8192;
    kick_flash_erase_block(block);
    block += 8192;
    kick_flash_erase_block(block);
  } else if (flash_bootbank == BOTTOM && bank == 0) {
    ULONG block = 0;
    kick_flash_erase_block(block); // Erase 16K
    block += 16384;
    kick_flash_erase_block(block); // Erase 8K
    block += 8192;
    kick_flash_erase_block(block); // Erase 8K
    block += 8192;
    kick_flash_erase_block(block); // Erase 32K
 
    // Erase the rest of the blocks
    for (int i = 1; i < BANK_SIZE/BLOCK_SIZE; i++) {
      block = (BANK_SIZE * bank) + (BLOCK_SIZE * i);
      kick_flash_erase_block(block);
    }
  } else {
    for (int i = 0; i < BANK_SIZE/BLOCK_SIZE; i++) {
      block = (BANK_SIZE * bank) + (BLOCK_SIZE * i);
      kick_flash_erase_block(block);
    }
  }
}