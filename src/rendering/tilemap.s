; Palette and tilemap loading, VRAM and CRAM transfers.
; ROM $001196-$001315.

Gfx_LoadPaletteCompact:
                movem.l d0-d2/a0,-(sp)  ; was: sub_1196
                lea     (Ram_Palette).w,a0

Gfx_LoadPaletteCompact_Loop:  ; was: loc_119E
                move.w  (a5),d0
                andi.w  #$10,d0
                move.w  (a5),d1
                rol.w   #4,d1
                andi.w  #$F,d1
                or.w    d1,d0
                move.w  (a5),d1
                andi.w  #$100,d1
                lsr.w   #3,d1
                or.w    d1,d0
                add.w   d0,d0
                move.w  (a5)+,d2
                move.w  d2,d1
                andi.w  #$EEE,d1
                move.w  d1,(a0,d0.w)
                lsr.w   #1,d2
                bcc.s   Gfx_LoadPaletteCompact_Loop
                movem.l (sp)+,d0-d2/a0
                rts

; Updates scroll registers during VBlank
Gfx_VBlankScrollUpdate:
                move.w  #$8100,d0  ; was: sub_11D0
                move.b  (Ram_VDPMode2).w,d0
                ori.b   #$40,d0
                move.w  d0,(a6)
                move.l  #$40000010,(VDP_CTRL).l
                move.l  (Ram_CameraY).w,-4(a6)
                move.w  (Ram_HScrollAddr).w,d0
                bsr.w   Gfx_SetVRAMWriteAddr
                move.l  (Ram_CameraX).w,d0
                neg.w   d0
                swap    d0
                neg.w   d0
                swap    d0
                move.l  d0,-4(a6)
                rts

; Initializes tilemap with color gradient
Gfx_InitTilemapGradient:
                lea     (VDP_CTRL).l,a6  ; was: sub_1208
                move.w  d0,d3
                move.w  d0,(Ram_TilemapGradientBase).w
                lsl.w   #5,d3
                clr.b   d4

Gfx_InitTilemapGradient_RowLoop:  ; was: loc_1218
                move.w  d3,d2
                move.w  d4,d1
                moveq   #$20,d0
                add.w   d0,d3
                bsr.w   Gfx_FillVRAMValue
                addi.b  #$11,d4
                bcc.s   Gfx_InitTilemapGradient_RowLoop
                rts

; Decompresses Enigma tilemap and draws to VRAM
Gfx_DecompEnigmaTilemap:
                movem.l d1-d5/a0,-(sp)  ; was: sub_122C
                movea.l a5,a0
                bsr.s   Gfx_ReadTilemapHeader
                clr.w   d0
                lea     (Ram_EnigmaBuffer).w,a1  ; !(UNKNOWN) RAM-002 overlaps the object array
                bsr.w   Eni_Decompress
                movea.l a0,a5
                movea.l a1,a0
                bsr.s   Gfx_DrawTilemapRows
                movem.l (sp)+,d1-d5/a0
                rts

; Reads tilemap header: position d2/d3, size d4/d5
Gfx_ReadTilemapHeader:
                lea     (VDP_CTRL).l,a6  ; was: sub_124A
                move.w  (a0)+,d2
                move.w  (a0)+,d3
                move.w  #$FF,d4
                move.w  d4,d5
                add.b   (a0)+,d4
                add.b   (a0)+,d5
                rts

; Draws decompressed tilemap rows to VDP
Gfx_DrawTilemapRows:
                move.w  d2,d0  ; was: sub_1260
                bsr.w   Gfx_SetVRAMWriteAddr
                move.w  d4,d0

Gfx_DrawTilemapRows_ColumnLoop:  ; was: loc_1268
                move.w  (a0)+,d1
                add.w   d3,d1
                move.w  d1,-4(a6)
                dbf     d0,Gfx_DrawTilemapRows_ColumnLoop
                add.w   (Ram_TilemapRowStride).w,d2
                dbf     d5,Gfx_DrawTilemapRows
                move.w  d3,d0
                rts

; Loads palette, tilemap, and Nemesis tiles
Gfx_LoadFullTilemap:
                bsr.w   Gfx_LoadPaletteCompact  ; was: sub_1280
                bsr.s   Gfx_DecompEnigmaTilemap
                bsr.w   Gfx_SetTileWriteAddr
                movea.l a5,a0
                bra.w   Nem_Decomp

; Copies tile data from ROM to CRAM
Gfx_CopyToCRAM:
                movem.l a0/a5,-(sp)  ; was: sub_1290
                lea     (VDP_CTRL).l,a6
                lea     VDP_DATA-VDP_CTRL(a6),a5
                ori.l   #$FFFF0000,d1
                movea.l d1,a0
                clr.l   d1
                move.w  d2,d1
                lsl.l   #2,d1
                move.w  d2,d1
                andi.w  #$3FFF,d1
                ori.w   #$C000,d1
                swap    d1
                move.l  d1,(a6)
                bra.s   Gfx_CopyToVRAM_Begin

; Copies tile data from ROM to VRAM
Gfx_CopyToVRAM:
                movem.l a0/a5,-(sp)  ; was: sub_12BC
                lea     (VDP_CTRL).l,a6
                lea     VDP_DATA-VDP_CTRL(a6),a5
                ori.l   #$FFFF0000,d1
                movea.l d1,a0
                clr.l   d1
                move.w  d2,d1
                lsl.l   #2,d1
                move.w  d2,d1
                andi.w  #$3FFF,d1
                ori.w   #$4000,d1
                swap    d1
                move.l  d1,(a6)

Gfx_CopyToVRAM_Begin:  ; was: loc_12E6
                addq.w  #3,d0
                lsr.w   #2,d0
                move.w  d0,d1
                lsr.w   #3,d1
                bra.s   Gfx_CopyToVRAM_BlockCheck

Gfx_CopyToVRAM_Block8Loop:  ; was: loc_12F0
                move.l  (a0)+,(a5)
                move.l  (a0)+,(a5)
                move.l  (a0)+,(a5)
                move.l  (a0)+,(a5)
                move.l  (a0)+,(a5)
                move.l  (a0)+,(a5)
                move.l  (a0)+,(a5)
                move.l  (a0)+,(a5)

Gfx_CopyToVRAM_BlockCheck:  ; was: loc_1300
                dbf     d1,Gfx_CopyToVRAM_Block8Loop
                andi.w  #7,d0
                bra.s   Gfx_CopyToVRAM_TailCheck

Gfx_CopyToVRAM_TailLoop:  ; was: loc_130A
                move.l  (a0)+,(a5)

Gfx_CopyToVRAM_TailCheck:  ; was: loc_130C
                dbf     d0,Gfx_CopyToVRAM_TailLoop
                movem.l (sp)+,a0/a5
                rts
