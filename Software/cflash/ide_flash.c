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

#include "constants.h"
#include "ide_flash.h"
#include "ide_flash_constants.h"

void *ide_flashBase;

/** ide_flash_writeByte
 *
 * @brief Write a byte to the Flash
 * @param address Address to write to
 * @param data The data to be written
*/
void ide_flash_writeByte(UWORD address, UBYTE data) {
  address <<= 1;
  address &= (FLASH_SIZE-1);
  ide_flash_unlock_sdp();
  ide_flash_command(CMD_BYTE_PROGRAM);
  *(UBYTE *)(ide_flashBase + address) = data;
  ide_flash_poll(address);

  return;
}

/** ide_flash_command
 *
 * @brief send a command to the Flash
 * @param command
*/
void ide_flash_command(UWORD command) {
  *(UBYTE *)(ide_flashBase + ADDR_CMD_STEP_1) = command;

  return;
}

/** ide_flash_unlock_sdp
 *
 * @brief Send the SDP command sequence
*/
void ide_flash_unlock_sdp() {
  *(UBYTE *)(ide_flashBase + ADDR_CMD_STEP_1) = CMD_SDP_STEP_1;
  *(UBYTE *)(ide_flashBase + ADDR_CMD_STEP_2) = CMD_SDP_STEP_2;

  return;
}

/** ide_flash_erase_chip
 *
 * @brief Perform a chip erase
*/
void ide_flash_erase_chip() {
  ide_flash_unlock_sdp();
  ide_flash_command(CMD_ERASE);
  ide_flash_unlock_sdp();
  ide_flash_command(CMD_ERASE_CHIP);

  ide_flash_poll(0);
}

/** ide_flash_poll
 *
 * @brief Poll the status bits at address, until they indicate that the operation has completed.
 * @param address Address to poll
*/
void ide_flash_poll(UWORD address) {
  address <<= 1;
  address &= (FLASH_SIZE-1);
  volatile UBYTE *read1 = ((void *)ide_flashBase + address);
  volatile UBYTE *read2 = ((void *)ide_flashBase + address);
  while (((*read1 & 1<<6) != (*read2 & 1<<6))) {;;}
}

/** ide_flash_init
 *
 * @brief Check the manufacturer id of the device, return manuf and dev id
 * @param manuf Pointer to a UBYTE that will be updated with the returned manufacturer id
 * @param devid Pointer to a UBYTE that will be updatet with the returned device id
 * @param flashBase Pointer to the Flash base address
 * @return True if the manufacturer ID matches the expected value
*/
bool ide_flash_init(UBYTE *manuf, UBYTE *devid, ULONG *flashBase) {
  bool ret = false;
  UBYTE manufId;
  UBYTE deviceId;
  
  ide_flashBase = flashBase;

  ide_flash_unlock_sdp();
  ide_flash_command(CMD_ID_ENTRY);

  manufId  = *(UBYTE *)ide_flashBase;
  deviceId = *(UBYTE *)(ide_flashBase + 2);

  ide_flash_command(CMD_CFI_ID_EXIT);

  if (manuf) *manuf = manufId;
  if (devid) *devid = deviceId;

  if (manufId == FLASH_MANUF && deviceId == FLASH_DEV && flashBase) {
    ret = true;
  }

  return (ret);
}