; Cartridge header, boot sequence, and Sega screen
; ROM $000000-$000855
Sys_VectorTable:    dc.l    Ram_VDPRegisters
                dc.l    Boot_EntryPoint
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Ram_ExtIntTrampoline
                dc.l    Sys_ErrorTrap
                dc.l    Ram_HBlankTrampoline
                dc.l    Sys_ErrorTrap
                dc.l    Ram_VBlankTrampoline
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
CopyRights:     dc.b    "SEGA MEGA DRIVE (C)SEGA 1991.FEB"
DomesticName:   dc.b    "FLICKY                                                         "
                dc.b    " FLICKY                          GM 00001022-00"
Checksum:       dc.w    $B7E0
Peripherials:   dc.b    "J               "
RomStart:       dc.l    0
RomEnd:         dc.l    Sys_RomEndData
RamStart:       dc.l    M68K_RAM
RamEnd:         dc.l    Ram_InitFlag+3
SramCode:       dc.b    "            "
ModemCode:      dc.b    "            "
Reserved:       dc.b    "                                        "
CountryCode:    dc.b    "JUE             "
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
Gfx_ClearVRAMAndCRAM:
                move.l  #$C0000000,(VDP_CTRL).l
                moveq   #$3F,d0

Gfx_ClearVRAMAndCRAM_CRAMLoop:
                move.w  #0,(VDP_DATA).l
                dbf     d0,Gfx_ClearVRAMAndCRAM_CRAMLoop
                move.l  #$40000000,(VDP_CTRL).l
                lea     (VDP_DATA).l,a5
                move.w  #0,d6
                move.w  #$53FF,d7

Gfx_ClearVRAMAndCRAM_VRAMLoop:
                move.w  d6,(a5)
                dbf     d7,Gfx_ClearVRAMAndCRAM_VRAMLoop
                rts

; Initializes single VDP register from table
Gfx_InitVDPRegister:
                movem.l d1-d2/a1,-(sp)
                lea     Gfx_VDPProbeTable(pc),a1
                move.b  (a1),6(a0)
                moveq   #0,d0
                moveq   #8,d1

Gfx_InitVDPRegister_ProbeLoop:
                move.b  (a1)+,(a0)
                nop
                nop
                move.b  (a0),d2
                and.b   (a1)+,d2
                beq.s   Gfx_InitVDPRegister_NextBit
                or.b    d1,d0

Gfx_InitVDPRegister_NextBit:
                lsr.b   #1,d1
                bne.s   Gfx_InitVDPRegister_ProbeLoop
                clr.b   6(a0)
                movem.l (sp)+,d1-d2/a1
                rts

Gfx_VDPProbeTable:  dc.b    $40, $C, $40, 3, 0, $C, 0, 3
Sys_LoadSegaScreen:
                bsr.w   Sys_InitGameState
                lea     Sys_SegaScreenData(pc),a5       ; palette cycle data?
                bsr.w   Gfx_LoadFullTilemap
                move.w  #$B4,d1
                moveq   #0,d2

Sys_LoadSegaScreen_WaitLoop:
                bsr.w   Sys_WaitVBlank
                subq.w  #1,d1
                move.w  d1,d0
                andi.w  #3,d0
                bne.s   Sys_LoadSegaScreen_WaitLoop
                cmpi.w  #$28,d2
                bgt.s   Sys_LoadSegaScreen_Return
                move.w  d2,d3
                addq.w  #2,d2
                lea     (Ram_PaletteEntry2).w,a1
                moveq   #$A,d7

Sys_LoadSegaScreen_PaletteLoop:
                cmpi.w  #$28,d3
                blt.s   Sys_LoadSegaScreen_PaletteWrap
                moveq   #0,d3

Sys_LoadSegaScreen_PaletteWrap:
                move.w  Sys_SegaFadePalette(pc,d3.w),(a1)+
                addq.w  #2,d3
                dbf     d7,Sys_LoadSegaScreen_PaletteLoop
                bra.s   Sys_LoadSegaScreen_WaitLoop

Sys_LoadSegaScreen_Return:
                rts

Sys_SegaFadePalette:    dc.b    $E, $C0, $E, $A0, $E, $80, $E, $60, $E, $40
                dc.b    $E, $20, $E, 0, $C, 0, $A, 0, 8, 0
                dc.b    6, 0, 8, 0, $A, 0, $C, 0, $E, 0
                dc.b    $E, $20, $E, $40, $E, $60, $E, $80, $E, $A0
Sys_SegaScreen:
                btst    #7,(Ram_Joypad+1).w
                bne.s   SegaScreen_SkipDelay
                cmpi.w  #$78,(Ram_FrameCounter).w
                bcs.s   SegaScreen_PlaySound

SegaScreen_SkipDelay:
                move.w  #0,(Ram_NextGameMode).w

SegaScreen_PlaySound:
                bra.w   Sound_QueueSFX

Sys_SegaScreenData:
Data_SegaPalette:   binclude "data/other/data_SegaPalette.bin"
Data_SegaPalette_End:
; Tilemap header for SEGA screen (read by Gfx_ReadTilemapHeader)
Sys_SegaTilemapHeader:
                dc.w    $E316                           ; position X
                dc.w    $0001                           ; position Y
                dc.b    $0C                             ; width adjustment
                dc.b    $04                             ; height adjustment
Data_SegaEnigma:    binclude "data/arteni/data_SegaEnigma.bin"
Data_SegaEnigma_End:
Data_SegaTiles:     binclude "data/artnem/data_SegaTiles.bin"
Data_SegaTiles_End:
; Unused interrupt handler (RTE)
