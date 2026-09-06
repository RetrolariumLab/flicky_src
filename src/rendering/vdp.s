; VDP registers, sprite area, tilemap writes, palette fade
; ROM $000E42-$001013

Gfx_LoadVDPRegsAlt:
                lea     Gfx_AltVDPRegs(pc),a1
                bra.s   Gfx_LoadVDPRegs_Copy

Gfx_SetInitialVDPRegs:
                lea     Gfx_InitialVDPRegs(pc),a1

Gfx_LoadVDPRegs_Copy:
                lea     (Ram_VDPRegisters).w,a2
                moveq   #$12,d7

Gfx_LoadVDPRegs_CopyLoop:
                move.b  (a1)+,(a2)+
                dbf     d7,Gfx_LoadVDPRegs_CopyLoop
                rts

Gfx_InitialVDPRegs: dc.b    4, $34, $30, $2C, 7, $5F, 0, 0, 0, 0
                dc.b    $30, 2, 0, $2E, 0, 2, 0, 0, 0, 0
Gfx_AltVDPRegs: dc.b    4, $14, $30, $2C, 7, $54, 0, 0, 0, 0
                dc.b    $30, 0, $81, $2B, 0, 2, 1, 0, 0, 0
; Writes VDP registers 0-18 from RAM buffer
Gfx_WriteVDPRegs:
                lea     (Ram_VDPRegisters).w,a1
                lea     (VDP_CTRL).l,a6
                move.w  #$8000,d7

Gfx_WriteVDPRegs_Loop:
                move.w  d7,d0
                move.b  (a1)+,d0
                move.w  d0,(a6)
                addi.w  #$100,d7
                cmpi.w  #$9300,d7
                bcs.s   Gfx_WriteVDPRegs_Loop
                rts

; Clears sprite table VRAM area and sprite variables
Gfx_ClearSpriteArea:
                move.w  #$B000,d2
                move.w  #$5000,d0
                bsr.w   Gfx_FillVRAMZero
                clr.l   (Ram_CameraY).w
                clr.l   (Ram_CameraX).w
                lea     (Ram_SpriteTable).w,a6
                moveq   #0,d7
                move.w  #$7F,d6

Gfx_ClearSpriteArea_ClearVarsLoop:
                move.l  d7,(a6)+
                dbf     d6,Gfx_ClearSpriteArea_ClearVarsLoop
                rts

; Writes tilemap rows to VRAM
Gfx_WriteTilemapBlock:
                lea     (VDP_CTRL).l,a2
                lea     (VDP_DATA).l,a3
                move.l  #$800000,d7

Gfx_WriteTilemapBlock_RowLoop:
                move.l  d0,(a2)
                move.w  d1,d4

Gfx_WriteTilemapBlock_ColumnLoop:
                move.w  (a1)+,(a3)
                dbf     d4,Gfx_WriteTilemapBlock_ColumnLoop
                add.l   d7,d0
                dbf     d2,Gfx_WriteTilemapBlock_RowLoop
                rts

; Fills tilemap area with repeated value
Gfx_FillTilemapArea:
                lea     (VDP_CTRL).l,a2
                lea     (VDP_DATA).l,a3
                move.l  #$800000,d5

Gfx_FillTilemapArea_RowLoop:
                move.l  d0,(a2)
                move.w  d1,d3

Gfx_FillTilemapArea_ColumnLoop:
                move.w  d4,(a3)
                dbf     d3,Gfx_FillTilemapArea_ColumnLoop
                add.l   d5,d0
                dbf     d2,Gfx_FillTilemapArea_RowLoop
                rts

; Sets VRAM write address for tile index d0
Gfx_SetTileWriteAddr:
                asl.w   #5,d0

; Sets VRAM write address from d0
Gfx_SetVRAMWriteAddr:
                clr.l   d1
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
                asl.w   #5,d0

Gfx_TileToVDPCmd_FromAddress:
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
                move.w  (Ram_VBlankMode).w,(Ram_VBlankRequest).w

Sys_WaitVBlank_Loop:
                tst.w   (Ram_VBlankRequest).w
                bne.s   Sys_WaitVBlank_Loop
                rts

Math_RandomNumber:
                move.l  (Ram_RandomSeed).w,d1
                bne.s   Math_RandomNumber_Advance
                move.l  #'*m6Z',d1

Math_RandomNumber_Advance:
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
                movem.l d2-d5,-(sp)
                moveq   #$40,d0
                cmp.w   d0,d2
                bcs.s   Gfx_FadePalette_Apply
                tst.w   d3
                beq.s   Gfx_FadePalette_UseMax
                cmp.w   d2,d3
                bcs.s   Gfx_FadePalette_Interpolate

Gfx_FadePalette_UseMax:
                move.w  d0,d2
                bra.s   Gfx_FadePalette_Apply

Gfx_FadePalette_Interpolate:
                sub.w   d3,d2
                neg.w   d2
                add.w   d0,d2
                cmp.w   d2,d0
                bcc.s   Gfx_FadePalette_Apply
                moveq   #0,d2

Gfx_FadePalette_Apply:
                lea     (Ram_Palette).w,a0
                lea     (Ram_PaletteBackup).w,a1
                cmpi.w  #$40,d2
                bne.s   Gfx_FadePalette_ScaleColours
                moveq   #$1F,d4

Gfx_FadePalette_CopyLoop:
                move.l  (a1)+,(a0)+
                dbf     d4,Gfx_FadePalette_CopyLoop
                bra.s   Gfx_FadePalette_Done

Gfx_FadePalette_ScaleColours:
                moveq   #$3F,d4

Gfx_FadePalette_ColourLoop:
                move.w  (a1)+,d0
                rol.w   #4,d0
                moveq   #0,d3
                moveq   #2,d5

Gfx_FadePalette_ChannelLoop:
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

Gfx_FadePalette_Done:
                move.w  d2,d0
                movem.l (sp)+,d2-d5
                rts

; Selectively copies palette entries by bitmask
Gfx_ApplyPaletteMask:
                cmpi.w  #$40,d0
                beq.s   Gfx_ApplyPaletteMask_Return
                lea     (Ram_PaletteBackup).w,a0
                lea     (Ram_Palette).w,a1
                movem.l (Ram_PaletteMaskHigh).w,d0-d1
                moveq   #$3F,d2

Gfx_ApplyPaletteMask_Loop:
                roxl.l  #1,d1
                roxl.l  #1,d0
                bcc.s   Gfx_ApplyPaletteMask_Skip
                move.w  (a0)+,(a1)+
                bra.s   Gfx_ApplyPaletteMask_Next

Gfx_ApplyPaletteMask_Skip:
                addq.w  #2,a0
                addq.w  #2,a1

Gfx_ApplyPaletteMask_Next:
                dbf     d2,Gfx_ApplyPaletteMask_Loop

Gfx_ApplyPaletteMask_Return:
                rts

; Copies palette to backup buffer and clears
Gfx_BackupPalette:
                lea     (Ram_Palette).w,a0
                lea     (Ram_PaletteBackup).w,a1
                moveq   #$1F,d0

Gfx_BackupPalette_Loop:
                move.l  (a0),(a1)+
                clr.l   (a0)+
                dbf     d0,Gfx_BackupPalette_Loop
                rts
