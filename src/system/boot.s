; Reset entry, hardware bring-up, checksum verification
; ROM $000200-$000401

Sys_ErrorTrap:
                nop
                nop
                bra.s   Sys_ErrorTrap
Boot_EntryPoint:
                tst.l   (IO_CT1_CTRL).l
                bne.s   Boot_PortAOk
                tst.w   (IO_EXT_CTRL).l

Boot_PortAOk:
                bne.s   Boot_SkipSetup
                lea     Boot_SetupValues(pc),a5
                movem.w (a5)+,d5-d7
                movem.l (a5)+,a0-a4
                move.b  -$10FF(a1),d0
                andi.b  #$F,d0
                beq.s   Boot_SkipSecurity
                move.l  #'SEGA',$2F00(a1)

Boot_SkipSecurity:
                move.w  (a4),d0
                moveq   #0,d0
                movea.l d0,a6
                move    a6,usp
                moveq   #$17,d1

Boot_VDPInitLoop:
                move.b  (a5)+,d5
                move.w  d5,(a4)
                add.w   d7,d5
                dbf     d1,Boot_VDPInitLoop
                move.l  (a5)+,(a4)
                move.w  d0,(a3)
                move.w  d7,(a1)
                move.w  d7,(a2)

Boot_WaitForZ80:
                btst    d0,(a1)
                bne.s   Boot_WaitForZ80
                moveq   #$25,d2

Boot_Z80InitLoop:
                move.b  (a5)+,(a0)+
                dbf     d2,Boot_Z80InitLoop
                move.w  d0,(a2)
                move.w  d0,(a1)
                move.w  d7,(a2)

Boot_ClearRAMLoop:
                move.l  d0,-(a6)
                dbf     d6,Boot_ClearRAMLoop
                move.l  (a5)+,(a4)
                move.l  (a5)+,(a4)
                moveq   #$1F,d3

Boot_ClearCRAMLoop:
                move.l  d0,(a3)
                dbf     d3,Boot_ClearCRAMLoop
                move.l  (a5)+,(a4)
                moveq   #$13,d4

Boot_ClearVSRAMLoop:
                move.l  d0,(a3)
                dbf     d4,Boot_ClearVSRAMLoop
                moveq   #3,d5

Boot_PSGInitLoop:
                move.b  (a5)+,$11(a3)
                dbf     d5,Boot_PSGInitLoop
                move.w  d0,(a2)
                movem.l (a6),d0-d7/a0-a6
                move    #$2700,sr

Boot_SkipSetup:
                bra.s   Sys_GameProgram
Boot_SetupValues:
                dc.w    $8000
                dc.w    $3FFF
                dc.w    $100
                dc.l    Z80_RAM
                dc.l    IO_Z80BUS
                dc.l    IO_Z80RES
                dc.l    VDP_DATA
                dc.l    VDP_CTRL
                dc.b    4, $14, $30, $3C, 7, $6C, 0, 0
                dc.b    0, 0, $FF, 0, $81, $37, 0, 1
                dc.b    1, 0, 0, $FF, $FF, 0, 0, $80
                dc.l    $40000080
                dc.b    $AF, 1, $D9, $1F, $11, $27, 0, $21
                dc.b    $26, 0, $F9, $77, $ED, $B0, $DD, $E1
                dc.b    $FD, $E1, $ED, $47, $ED, $4F, $D1, $E1
                dc.b    $F1, 8, $D9, $C1, $D1, $E1, $F1, $F9
                dc.b    $F3, $ED, $56, $36, $E9, $E9
                dc.l    $81048F02
                dc.l    $C0000000
                dc.l    $40000010
                dc.b    $9F,$BF,$DF,$FF

Sys_GameProgram:
                tst.w   (VDP_CTRL).l
                move    #$2700,sr
                move.b  (IO_PCBVER+1).l,d0
                andi.b  #$F,d0
                beq.s   Boot_ChecksumCheck
                move.l  #'SEGA',(IO_TMSS).l

Boot_ChecksumCheck:
                movea.l #RomEnd,a0
                move.l  (a0),d1
                addq.l  #1,d1
                movea.l #Sys_ErrorTrap,a0
                sub.l   a0,d1
                asr.l   #1,d1
                move.w  d1,d2
                subq.w  #1,d2
                swap    d1
                moveq   #0,d0

Boot_ChecksumLoop:
                add.w   (a0)+,d0
                dbf     d2,Boot_ChecksumLoop
                dbf     d1,Boot_ChecksumLoop
                cmp.w   (Checksum).w,d0
                beq.s   Boot_ChecksumOk
                bra.w   Boot_ChecksumError

Boot_ChecksumOk:
                btst    #6,(IO_EXT_CTRL+1).l
                bne.s   Boot_CheckInitFlag
                move    #$2700,sr
                lea     ((IO_CT1_DATA+1)).l,a0
                bsr.w   Gfx_InitVDPRegister
                cmpi.b  #0,d0
                beq.s   Boot_SetupControllerPorts
                ; !(UNUSED) CODE-001 the fall-through is three NOPs
                nop
                nop
                nop

Boot_SetupControllerPorts:
                moveq   #$40,d0
                move.b  d0,(IO_CT1_CTRL+1).l
                move.b  d0,(IO_CT2_CTRL+1).l
                move.b  d0,(IO_EXT_CTRL+1).l

Boot_ClearWorkRAM:
                lea     (M68K_RAM).l,a6
                moveq   #0,d7
                move.w  #$3FFF,d6

Boot_ClearWorkRAM_Loop:
                move.l  d7,(a6)+
                dbf     d6,Boot_ClearWorkRAM_Loop
                move.l  #'init',(Ram_InitFlag).w
                move.l  #$100000,(Ram_HighScore).w

Boot_CheckInitFlag:
                cmpi.l  #'init',(Ram_InitFlag).w
                bne.s   Boot_ClearWorkRAM
                bsr.w   Sys_LoadFuncTable
                bsr.w   Gfx_SetInitialVDPRegs
                bsr.w   Gfx_WriteVDPRegs
                bsr.w   Gfx_ClearVRAMAndCRAM
                bsr.w   Sound_LoadZ80Driver
                lea     (Sys_GameEntryPoint).l,a0
                lea     (M68K_RAM).l,a1
                move.w  #$2FFF,d0

Boot_CopyGameToRAM_Loop:
                move.l  (a0)+,(a1)+
                dbf     d0,Boot_CopyGameToRAM_Loop
                jmp     M68K_RAM

Boot_ChecksumError:
                bsr.w   Gfx_ClearVRAMAndCRAM
                move.l  #$C0000000,(VDP_CTRL).l
                moveq   #$3F,d7

Boot_FillRedScreen:
                move.w  #$E,(VDP_DATA).l
                dbf     d7,Boot_FillRedScreen

Boot_EndlessLoop:
                bra.s   Boot_EndlessLoop

; Clears CRAM (palette) and VRAM with zeros
