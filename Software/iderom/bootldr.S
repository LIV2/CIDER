; Based on rom.S from Open Source A4091.device by Stefan Reinauer & Chris Hooper 
    include libraries/configvars.i
    include exec/resident.i
    include lvo/exec_lib.i


VERSION   = 0
REVISION  = 1
ROMOFFSET = $2000

*******  DiagStart  **************************************************
DiagStart
        ; This is the DiagArea structure whose relative offset from
        ; your board base appears as the Init Diag vector in your
        ; autoconfig ID information.  This structure is designed
        ; to use all relative pointers (no patching needed).
        dc.b    DAC_NIBBLEWIDE+DAC_CONFIGTIME  ; da_Config
        dc.b    0                              ; da_Flags
        dc.w    EndCopy-DiagStart              ; da_Size
        dc.w    DiagEntry-DiagStart            ; da_DiagPoint
        dc.w    BootEntry-DiagStart            ; da_BootPoint
        dc.w    DevName-DiagStart              ; da_Name
        dc.w    0                              ; da_Reserved01
        dc.w    0                              ; da_Reserved02


*******  DiagEntry  **************************************************
**********************************************************************
*
*   success = DiagEntry(BoardBase,DiagCopy, configDev)
*   d0                  a0         a2       a3
*
*   Called by expansion architecture to relocate any pointers
*   in the copied diagnostic area.   We will patch the romtag.
*   If you have pre-coded your MakeDosNode packet, BootNode,
*   or device initialization structures, they would also need
*   to be within this copy area, and patched by this routine.
*
**********************************************************************
* These are the calling conventions for the Diag routine
*
* A7 -- points to at least 2K of stack
* A6 -- ExecBase
* A5 -- ExpansionBase
* A3 -- your board's ConfigDev structure
* A2 -- Base of diag/init area that was copied
* A0 -- Base of your board
*
* The Diag routine shall return a non-zero value in D0 for success.
* If this value is NULL, then the diag/init area that was copied
* will be returned to the free memory pool.
*
DiagEntry
        movem.l d2-d7/a2-a6,-(sp)

        ; Patch up Romtag Resident Structure in memory
        lea.l   Romtag(pc),a4                ; find Romtag in memory
        move.l  a4,RT_MATCHTAG(a4)           ; pointer to itself
        lea.l   EndCopy(pc),a1
        move.l  a1,RT_ENDSKIP(a4)
        lea.l   DevName(pc),a1
        move.l  a1,RT_NAME(a4)
        lea.l   IdString(pc),a1
        move.l  a1,RT_IDSTRING(a4)

        move.l  #ROMOFFSET,d0
        bsr     _relocate
        tst.l   d0

        bne.s   .ok
.err
        *******  Show checkered purple failure screen **************************
        movem.l d2-d3,-(sp)
        move.w  #$0020,d2
.fc1
        move.w  #$ffff,d3
.fc2
        move.w  #$0000,$dff180               ; black
        move.w  #$0f0c,$dff180               ; purple
        dbra    d3,.fc2
        dbra    d2,.fc1
        movem.l (sp)+,d2-d3
        *******  End checkered purple failure screen **************************

        moveq.l #0,d0
        movem.l (sp)+,d2-d7/a2-a6
        rts
.ok
        move.l  #$1000,d3

        move.l  d0,a2
.findrt cmpi.w  #$4AFC,(a2)
        beq.s   .found
        addq.l  #2,a2
        dbra    d3,.findrt
        bra.s   .err

.found  lea.l   Romtag(pc),a4                ; find Romtag in memory
        move.l  RT_INIT(a2),d0
        move.l  d0,RT_INIT(a4)

        moveq.l #1,d0           ; indicate "success"
.done
        movem.l (sp)+,d2-d7/a2-a6
        rts

*******  BootEntry  **************************************************
**********************************************************************

BootEntry
        lea     DosName(PC),a1          ; 'dos.library',0
        jsr     _LVOFindResident(a6)    ; find the DOS resident tag
        tst.l   d0
        beq.s   .BadBoot
        move.l  d0,a0                   ; in order to bootstrap
        move.l  RT_INIT(A0),a0          ; set vector to DOS INIT
        jsr     (a0)                    ; and initialize DOS
.BadBoot
        rts

*******  Resident Structure  *****************************************
**********************************************************************
Romtag
        dc.w    RTC_MATCHWORD      ; UWORD RT_MATCHWORD
        dc.l    0                  ; APTR  RT_MATCHTAG
        dc.l    0                  ; APTR  RT_ENDSKIP
        dc.b    RTF_COLDSTART      ; UBYTE RT_FLAGS
        dc.b    VERSION            ; UBYTE RT_VERSION
        dc.b    0                  ; UBYTE RT_TYPE
        dc.b    0                  ; BYTE  RT_PRI
        dc.l    0                  ; APTR  RT_NAME
        dc.l    0                  ; APTR  RT_IDSTRING
        dc.l    0                  ; APTR  RT_INIT

*******  Strings referenced in Diag Copy area  **************************
*************************************************************************
DevName
        dc.b    'Oktagon',0                 ; Name string
        align 1
IdString
        dc.b    'Oktagon',0
DosName
        dc.b    'dos.library',0                    ; DOS library name
        align 1     ; word align

    include reloc.S
EndCopy:
