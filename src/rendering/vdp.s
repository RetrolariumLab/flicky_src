; VDP registers, sprite area, tilemap writes, palette fade.
; ROM $000E42-$001013.

Gfx_LoadVDPRegsAlt:
                lea     Gfx_AltVDPRegs(pc),a1  ; was: sub_E42
                bra.s   Gfx_LoadVDPRegs_Copy

SetInitialVDPRegs:
                lea     initial_vdp_regs(pc),a1

Gfx_LoadVDPRegs_Copy:  ; was: loc_E4C
                lea     (Ram_VDPRegisters).w,a2
                moveq   #$12,d7

Gfx_LoadVDPRegs_CopyLoop:  ; was: loc_E52
                move.b  (a1)+,(a2)+
                dbf     d7,Gfx_LoadVDPRegs_CopyLoop
                rts

initial_vdp_regs: dc.b    4, $34, $30, $2C, 7, $5F, 0, 0, 0, 0
                dc.b    $30, 2, 0, $2E, 0, 2, 0, 0, 0, 0
Gfx_AltVDPRegs: dc.b    4, $14, $30, $2C, 7, $54, 0, 0, 0, 0  ; was: byte_E6E
                dc.b    $30, 0, $81, $2B, 0, 2, 1, 0, 0, 0
; Writes VDP registers 0-18 from RAM buffer
Gfx_WriteVDPRegs:
                lea     (Ram_VDPRegisters).w,a1  ; was: sub_E82
                lea     (VDP_CTRL).l,a6
                move.w  #$8000,d7

Gfx_WriteVDPRegs_Loop:  ; was: loc_E90
                move.w  d7,d0
                move.b  (a1)+,d0
                move.w  d0,(a6)
                addi.w  #$100,d7
                cmpi.w  #$9300,d7
                bcs.s   Gfx_WriteVDPRegs_Loop
                rts

; Clears sprite table VRAM area and sprite variables
Gfx_ClearSpriteArea:
                move.w  #$B000,d2  ; was: sub_EA2
                move.w  #$5000,d0
                bsr.w   Gfx_FillVRAMZero
                clr.l   (Ram_CameraY).w
                clr.l   (Ram_CameraX).w
                lea     (Ram_SpriteTable).w,a6
                moveq   #0,d7
                move.w  #$7F,d6

Gfx_ClearSpriteArea_ClearVarsLoop:  ; was: loc_EC0
                move.l  d7,(a6)+
                dbf     d6,Gfx_ClearSpriteArea_ClearVarsLoop
                rts

; Writes tilemap rows to VRAM
Gfx_WriteTilemapBlock:
                lea     (VDP_CTRL).l,a2  ; was: sub_EC8
                lea     (VDP_DATA).l,a3
                move.l  #$800000,d7

Gfx_WriteTilemapBlock_RowLoop:  ; was: loc_EDA
                move.l  d0,(a2)
                move.w  d1,d4

Gfx_WriteTilemapBlock_ColumnLoop:  ; was: loc_EDE
                move.w  (a1)+,(a3)
                dbf     d4,Gfx_WriteTilemapBlock_ColumnLoop
                add.l   d7,d0
                dbf     d2,Gfx_WriteTilemapBlock_RowLoop
                rts

; Fills tilemap area with repeated value
Gfx_FillTilemapArea:
                lea     (VDP_CTRL).l,a2  ; was: sub_EEC
                lea     (VDP_DATA).l,a3
                move.l  #$800000,d5

Gfx_FillTilemapArea_RowLoop:  ; was: loc_EFE
                move.l  d0,(a2)
                move.w  d1,d3

Gfx_FillTilemapArea_ColumnLoop:  ; was: loc_F02
                move.w  d4,(a3)
                dbf     d3,Gfx_FillTilemapArea_ColumnLoop
                add.l   d5,d0
                dbf     d2,Gfx_FillTilemapArea_RowLoop
                rts

; Sets VRAM write address for tile index d0
Gfx_SetTileWriteAddr:
                asl.w   #5,d0  ; was: sub_F10

; Sets VRAM write address from d0
Gfx_SetVRAMWriteAddr:
                clr.l   d1  ; was: sub_F12
                move.w  d0,d1
                lsl.l   #2,d1
                move.w  d0,d1
                andi.w  #$3FFF,d1
                ori.w   #$4000,d1
                swap    d1
                move.l  d1,(a6)
                rts

; Converts tile index to VDP write command
Gfx_TileToVDPCmd:
                asl.w   #5,d0  ; was: sub_F28

Gfx_TileToVDPCmd_FromAddress:  ; was: loc_F2A
                clr.l   d1
                move.w  d0,d1
                lsl.l   #2,d1
                move.w  d0,d1
                andi.w  #$3FFF,d1
                swap    d1
                move.l  d1,(a6)
                rts

; Waits for VBlank interrupt to complete
Sys_WaitVBlank:
                move.w  (Ram_VBlankMode).w,(Ram_VBlankRequest).w  ; was: sub_F3C

Sys_WaitVBlank_Loop:  ; was: loc_F42
                tst.w   (Ram_VBlankRequest).w
                bne.s   Sys_WaitVBlank_Loop
                rts

RandomNumber:
                move.l  (Ram_RandomSeed).w,d1
                bne.s   RandomNumber_Advance
                move.l  #'*m6Z',d1

RandomNumber_Advance:  ; was: loc_F56
                move.l  d1,d0
                asl.l   #2,d1
                add.l   d0,d1
                asl.l   #3,d1
                add.l   d0,d1
                move.w  d1,d0
                swap    d1
                add.w   d1,d0
                move.w  d0,d1
                swap    d1
                move.l  d1,(Ram_RandomSeed).w
                rts

; Fades palette colors by factor d2 (0-64)
Gfx_FadePalette:
                movem.l d2-d5,-(sp)  ; was: sub_F70
                moveq   #$40,d0
                cmp.w   d0,d2
                bcs.s   Gfx_FadePalette_Apply
                tst.w   d3
                beq.s   Gfx_FadePalette_UseMax
                cmp.w   d2,d3
                bcs.s   Gfx_FadePalette_Interpolate

Gfx_FadePalette_UseMax:  ; was: loc_F82
                move.w  d0,d2
                bra.s   Gfx_FadePalette_Apply

Gfx_FadePalette_Interpolate:  ; was: loc_F86
                sub.w   d3,d2
                neg.w   d2
                add.w   d0,d2
                cmp.w   d2,d0
                bcc.s   Gfx_FadePalette_Apply
                moveq   #0,d2

Gfx_FadePalette_Apply:  ; was: loc_F92
                lea     (Ram_Palette).w,a0
                lea     (Ram_PaletteBackup).w,a1
                cmpi.w  #$40,d2
                bne.s   Gfx_FadePalette_ScaleColours
                moveq   #$1F,d4

Gfx_FadePalette_CopyLoop:  ; was: loc_FA2
                move.l  (a1)+,(a0)+
                dbf     d4,Gfx_FadePalette_CopyLoop
                bra.s   Gfx_FadePalette_Done

Gfx_FadePalette_ScaleColours:  ; was: loc_FAA
                moveq   #$3F,d4

Gfx_FadePalette_ColourLoop:  ; was: loc_FAC
                move.w  (a1)+,d0
                rol.w   #4,d0
                moveq   #0,d3
                moveq   #2,d5

Gfx_FadePalette_ChannelLoop:  ; was: loc_FB4
                lsl.w   #4,d3
                rol.w   #4,d0
                move.w  d0,d1
                andi.w  #$F,d1
                mulu.w  d2,d1
                lsr.w   #6,d1
                or.w    d1,d3
                dbf     d5,Gfx_FadePalette_ChannelLoop
                move.w  d3,(a0)+
                dbf     d4,Gfx_FadePalette_ColourLoop

Gfx_FadePalette_Done:  ; was: loc_FCE
                move.w  d2,d0
                movem.l (sp)+,d2-d5
                rts

; Selectively copies palette entries by bitmask
Gfx_ApplyPaletteMask:
                cmpi.w  #$40,d0  ; was: sub_FD6
                beq.s   Gfx_ApplyPaletteMask_Return
                lea     (Ram_PaletteBackup).w,a0
                lea     (Ram_Palette).w,a1
                movem.l (Ram_PaletteMaskHigh).w,d0-d1
                moveq   #$3F,d2

Gfx_ApplyPaletteMask_Loop:  ; was: loc_FEC
                roxl.l  #1,d1
                roxl.l  #1,d0
                bcc.s   Gfx_ApplyPaletteMask_Skip
                move.w  (a0)+,(a1)+
                bra.s   Gfx_ApplyPaletteMask_Next

Gfx_ApplyPaletteMask_Skip:  ; was: loc_FF6
                addq.w  #2,a0
                addq.w  #2,a1

Gfx_ApplyPaletteMask_Next:  ; was: loc_FFA
                dbf     d2,Gfx_ApplyPaletteMask_Loop

Gfx_ApplyPaletteMask_Return:  ; was: locret_FFE
                rts

; Copies palette to backup buffer and clears
Gfx_BackupPalette:
                lea     (Ram_Palette).w,a0  ; was: sub_1000
                lea     (Ram_PaletteBackup).w,a1
                moveq   #$1F,d0

Gfx_BackupPalette_Loop:  ; was: loc_100A
                move.l  (a0),(a1)+
                clr.l   (a0)+
                dbf     d0,Gfx_BackupPalette_Loop
                rts
