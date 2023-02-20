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

#include <exec/execbase.h>
#include <proto/exec.h>
#include <proto/expansion.h>
#include <string.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <proto/dos.h>

#include "addram.h"
#include "config.h"

struct ExpansionBase *ExpansionBase = NULL;

struct ConfigDev *cd;
struct List *MemList;
struct MemHeader *Node, *Next;

char board[] = BOARDSTRING;

UWORD *ConfigRegister = NULL;

int main (int argc, char *argv[])
{
  struct ExecBase *SysBase = *((struct ExecBase **)4UL);
  int rc = 0;

  MemList = &SysBase->MemList;

  struct Config *config = Configure(argc,argv);
  if (config == NULL) {
    usage();
  }

  if (config->dryRun) printf("Doing a dry-run.\n");

  for (Node = (struct MemHeader *)MemList->lh_Head; (Next = (struct MemHeader *)Node->mh_Node.ln_Succ) != NULL; Node = Next) {
    // It might seem like a mistake to check if mh_Upper is greater than BONUSRAM_START
    // But this will allow it to find the block even if it was merged with the Fast RAM block
    if ((int)Node->mh_Upper > BONUSRAM_START && (int)Node->mh_Upper <= BONUSRAM_END) {
      printf("Error: Memory block already added\n");
      rc = 5;
    }
  }

  if (rc == 0 && (ExpansionBase = (struct ExpansionBase *)OpenLibrary("expansion.library",0)) != NULL) {
    if ((cd = FindConfigDev(NULL,BOARD_MANUF,BOARD_PROD))) {
      ConfigRegister = (UWORD *)cd->cd_BoardAddr;
      char * boardName = NULL;

      if ((boardName = AllocMem(sizeof(board),MEMF_CLEAR)) != NULL) {

        strcpy(boardName,board);

        enableBonusRam();

        ULONG bonusRamSize = sizeBonusRam(config);

        if (bonusRamSize > 0x1FE000) {
          printf("Error: Detected more ram than should be in Bonus region somehow...\n");
          rc = 20;

        } else if (bonusRamSize > 0) {
          if (config->verbose) printf("Found Board at 0x%06lx! with BonusRam size of %ldkB\n",(ULONG)cd->cd_BoardAddr,(bonusRamSize >> 10));

          if (!config->dryRun) {
            if (addBonusRam(bonusRamSize,boardName,config) == false) {
              return 5;
            }
          }

          fixPriorities(boardName, config);

        } else {
          printf("Error: No memory found.\n");
          rc = 10;
        }

      } else {
        printf("Unable to allocate memory.\n");
        rc = 5;
      }

    } else {
      printf("Board not found.\n");
      rc = 5;
    }

  } else {
    printf("Couldn't open expansion.library\n");
    rc = 20;
  }
  if (config) FreeMem(config,sizeof(struct Config));
  if (ExpansionBase) CloseLibrary((struct Library *)ExpansionBase);
  return rc;
}

/** fixPriorities
 *
 * Change the priority of the Ranger/Fast RAM block
 * @param boardName Pointer to string containing the board name
 * @param config Pointer to the config struct
*/
void fixPriorities(char *boardName, struct Config *config) {
  struct MemHeader *FastNode = NULL;
  struct MemHeader *RangerNode = NULL;
  for (Node = (struct MemHeader *)MemList->lh_Head; (Next = (struct MemHeader *)Node->mh_Node.ln_Succ) != NULL; Node = Next) {
    if ((int)Node == 0xC00000) {
      RangerNode = Node;
    } else if (Node == cd->cd_BoardAddr) {
      FastNode = Node;
    }
  }
  if (!config->dryRun) {

    Forbid();

    if (FastNode) {

      FastNode->mh_Node.ln_Name = boardName;

      if (config->fastPriority > 0) {
        if (config->verbose) printf("Setting FastRAM priority to %d\n",config->fastPriority);
        FastNode->mh_Node.ln_Pri = (BYTE)config->fastPriority;

        // Re-enqueue the node because we changed the priority
        Remove((struct Node *)FastNode);
        Enqueue(MemList,(struct Node *)FastNode);
      }
    }

    if (RangerNode) {
      if (config->verbose) printf("Setting Ranger Priority to %d\n",(config->fastPriority-1));
      RangerNode->mh_Node.ln_Pri = (BYTE)(config->fastPriority-1);
      RangerNode->mh_Attributes &= ~(MEMF_24BITDMA | MEMF_KICK); // Make sure MEMF_24BITDMA and MEMF_KICK are not set for this block

      // Re-enqueue the node because we changed the priority
      Remove((struct Node *)RangerNode);
      Enqueue(MemList,(struct Node *)RangerNode);
    }

    Permit();

  }
}

/**
 * SizeBonusRam
 *
 * Perform a simple memory test and return the size of Bonus RAM
 * 
 * BonusRam uses address space $A00000-BEFFFF
 * Normally Gary decodes these as CIA accesses on the 500(+)/600/1000/2000/CDTV etc
 * It is therefore important to make sure our test won't trash the CIA if the access somehow hits a CIA
 * 
 * @param config Pointer to the config struct
 * @returns Size of Bonus RAM in bytes
*/
ULONG sizeBonusRam(struct Config *config) {
  ULONG bonusRamSize = 0;

  UWORD *testPtr = NULL;
  UWORD saveWord;

  if (config->verbose) {
    printf("Testing address       ");
  }

  for (ULONG i=BONUSRAM_START; i < BONUSRAM_END; i+=0x010000) {
    // Restore Saved value from last iteration
    if (testPtr != NULL) *testPtr = saveWord;
    // Test memory at Offset+0xB00 as this will be harmless if we access a CIA
    testPtr = (void *)(i+0xB00);
    saveWord = *testPtr;

    if (config->verbose) {
      fprintf(stdout,"\b\b\b\b\b\b%06lx", i);
      fflush(stdout);
    }

    *testPtr = (i>>8);

    if (SysBase->SoftVer >= 36) {
      CacheClearE(testPtr,2,CACRF_ClearI|CACRF_ClearD);
    }

    if (*testPtr != (i>>8)) {
      break;
    } else {
      bonusRamSize += 0x010000;
    }
  }
  // Restore Saved value
  *testPtr = saveWord;

  if (config->verbose) printf("\nDone.\n");
  return bonusRamSize;
}

/**
 * enableBonusRAM
 * 
 * Poke the control register to enable Bonus RAM
*/
void enableBonusRam() {
  *ConfigRegister |= BONUSRAM_EN | SET_FLAG;
}

/**
 * disableBonusRAM
 * 
 * Poke the control register to disable Bonus RAM
*/
void disableBonusRam() {
  *ConfigRegister |= BONUSRAM_EN;
}

/**
 * addBonusRam
 * 
 * Add Bonus RAM to the memory pool
 * Optionally try to expand the Fast RAM pool to contain Bonus RAM too
 * @param bonusRamSize Bonus RAM size in bytes
 * @param boardName String pointer to board name string
 * @param config Pointer to the config struct
 * @returns success
*/
bool addBonusRam(ULONG bonusRamSize, char *boardName, struct Config *config) {
  if (config->mergeFastAndBonus == true) {
    // Try to expand the Fast RAM block to include the Bonus RAM
    // 
    // Maybe not a smart idea to modify the memory & chunk lists like this - but this is why it's not the default option!
    //

    struct MemHeader *Node = NULL;

    // Search for a memory block bordering Bonus RAM
    for (Node = (struct MemHeader *)MemList->lh_Head; (Next = (struct MemHeader *)Node->mh_Node.ln_Succ) != NULL; Node = Next) {
      if (Node->mh_Upper == (void *)BONUSRAM_START) {
        if (config->verbose) printf("Merging Fast ram & Bonus ram pools\n");
        Forbid();

        struct MemChunk *CurChunk = Node->mh_First;

        // Find the last free memory chunk
        while (CurChunk->mc_Next != NULL) {
          CurChunk = CurChunk->mc_Next;
        }
        // Does the last chunk end where Bonus Ram begins?
        if ((ULONG)(void *)(CurChunk + CurChunk->mc_Bytes) == BONUSRAM_START) {
          // Yes, expand the chunk to include Bonus Ram
          CurChunk->mc_Bytes += bonusRamSize;
        } else {
          // No, Add a new chunk
          struct MemChunk *NewChunk = (void *)BONUSRAM_START;
          NewChunk->mc_Bytes = bonusRamSize;
          NewChunk->mc_Next = NULL;
          CurChunk->mc_Next = NewChunk;
        }

        // Expand the node to fill Bonus Ram
        Node->mh_Upper = (void*)(BONUSRAM_START + bonusRamSize);
        Node->mh_Free += bonusRamSize;

        Permit();
        return true;
      }
    }
  }

  for (Node = (struct MemHeader *)MemList->lh_Head; (Next = (struct MemHeader *)Node->mh_Node.ln_Succ) != NULL; Node = Next) {
    // It might seem like a mistake to check if mh_Upper is greater than BONUSRAM_START
    // But this will allow it to find the block even if it was merged with the Fast RAM block
    if ((int)Node->mh_Upper > BONUSRAM_START && (int)Node->mh_Upper <= BONUSRAM_END) {
      printf("Error: Memory block already added\n");
      return false;
    }
  }
  AddMemList(bonusRamSize,MEMF_FAST,(LONG)config->fastPriority,(APTR)BONUSRAM_START,(STRPTR)boardName);
  return true;
}