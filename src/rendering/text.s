; Tilemap coordinates, tile writes, string and number drawing.
; ROM $010F24-$01105B.

Gfx_TilemapCoordToAddr:
                add.w   d7,d7  ; was: sub_10F24
                lsl.w   #6,d6
                add.w   d6,d7
                add.w   d5,d7
                move.w  d7,d5

; Converts offset d5 to VDP write command format
Gfx_MakeVDPWriteCmd:
                lsl.l   #2,d5  ; was: sub_10F2E
                lsr.w   #2,d5
                bset    #$E,d5
                swap    d5
                rts

; Writes tile d4 at tilemap coordinates
Gfx_WriteTileAtCoord:
                bsr.s   Gfx_TilemapCoordToAddr  ; was: sub_10F3A
                bra.s   loc_10F40

; Writes tile d4 at VRAM offset d5
Gfx_WriteTileAtOffset:
                bsr.s   Gfx_MakeVDPWriteCmd  ; was: sub_10F3E

loc_10F40:
                move.l  d5,(VDP_CTRL).l
                move.w  d4,(VDP_DATA).l
                rts

; Copies d4+1 tiles from (a6)+ to VRAM at offset d5
Gfx_CopyTilesToVRAM:
                lea     (VDP_CTRL).l,a4  ; was: sub_10F4E
                lea     (VDP_DATA).l,a3
                lsl.l   #2,d5
                lsr.w   #2,d5
                bset    #$E,d5
                swap    d5
                move.l  d5,(a4)

loc_10F66:
                move.w  (a6)+,(a3)
                dbf     d4,loc_10F66
                rts

; Prepares VDP command and calls DrawTilemapRows
Gfx_DrawTilemapStart:
                bsr.s   Gfx_MakeVDPWriteCmd  ; was: sub_10F6E

; Draws d6+1 rows of d7+1 tiles from (a6)+
Gfx_DrawTilemapRect:
                lea     (VDP_CTRL).l,a4  ; was: sub_10F70
                lea     (VDP_DATA).l,a3
                move.l  #$400000,d0

loc_10F82:
                move.l  d5,(a4)
                move.w  d7,d1

loc_10F86:
                move.w  (a6)+,(a3)
                dbf     d1,loc_10F86
                add.l   d0,d5
                dbf     d6,loc_10F82
                rts

; Writes single character tile with base offset
Text_WriteCharTile:
                cmpi.w  #$FFFF,(word_FFD884).w  ; was: sub_10F94
                bne.s   loc_10FA2
                move.w  #$8020,d4
                bra.s   loc_10FA6

loc_10FA2:
                add.w   (word_FFD884).w,d4

loc_10FA6:
                bsr.s   Gfx_WriteTileAtOffset
                rts

; Draws null-terminated string from (a6) at VRAM pos
Text_DrawString:
                moveq   #0,d6  ; was: sub_10FAA
                move.w  (a6)+,d6

loc_10FAE:
                moveq   #0,d4
                moveq   #0,d5
                move.w  d6,d5
                move.b  (a6)+,d4
                beq.s   locret_10FBE
                bsr.s   Text_WriteCharTile
                addq.w  #2,d6
                bra.s   loc_10FAE

locret_10FBE:
                rts

; Draws double-height text with upper/lower tiles
Text_DrawDoubleHeight:
                moveq   #0,d6  ; was: sub_10FC0
                move.w  (a6)+,d6

loc_10FC4:
                moveq   #0,d4
                moveq   #0,d5
                move.b  (a6)+,d4
                beq.s   locret_10FF2
                bsr.w   Text_CharToTileIndex
                move.w  d5,d3
                move.w  d6,d5
                subi.w  #$20,d4
                move.l  d5,-(sp)
                bsr.w   Gfx_WriteTileAtOffset
                move.l  (sp)+,d5
                subi.w  #$40,d5
                move.w  d3,d4
                subi.w  #$20,d4
                bsr.w   Gfx_WriteTileAtOffset
                addq.w  #2,d6
                bra.s   loc_10FC4

locret_10FF2:
                rts

; Draws BCD number from (a6) with leading zero handling
Text_DrawBCDNumber:
                clr.b   (byte_FFD00D).w  ; was: sub_10FF4
                subq.w  #2,d5

loc_10FFA:
                moveq   #0,d1
                move.b  (a6)+,d1
                move.w  d1,d4
                lsr.w   #4,d4
                addq.w  #2,d5
                movem.l d0-d1/d5,-(sp)
                bsr.w   Text_DrawDigit
                movem.l (sp)+,d0-d1/d5
                andi.w  #$F,d1
                move.w  d1,d4
                addq.w  #2,d5
                movem.l d0-d1/d5,-(sp)
                bsr.w   Text_DrawDigit
                movem.l (sp)+,d0-d1/d5
                dbf     d0,loc_10FFA
                tst.b   (byte_FFD00D).w
                bne.s   locret_11034
                moveq   #$30,d4
                bsr.w   Text_WriteCharTile

locret_11034:
                rts

; Draws single digit with leading zero suppression
Text_DrawDigit:
                tst.b   d4  ; was: sub_11036
                bne.s   loc_1104C
                tst.b   (byte_FFD00D).w
                bne.s   loc_11052
                tst.b   (byte_FFD29A).w
                beq.s   locret_1104A
                bsr.w   Text_WriteCharTile

locret_1104A:
                rts

loc_1104C:
                move.b  #1,(byte_FFD00D).w

loc_11052:
                addi.w  #$30,d4
                bsr.w   Text_WriteCharTile
                rts

; Updates object X/Y position from velocity with wrapping
