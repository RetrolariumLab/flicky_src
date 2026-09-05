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
                bra.s   Gfx_WriteTile_Emit

; Writes tile d4 at VRAM offset d5
Gfx_WriteTileAtOffset:
                bsr.s   Gfx_MakeVDPWriteCmd  ; was: sub_10F3E

Gfx_WriteTile_Emit:  ; was: loc_10F40
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

Gfx_CopyTilesToVRAM_Loop:  ; was: loc_10F66
                move.w  (a6)+,(a3)
                dbf     d4,Gfx_CopyTilesToVRAM_Loop
                rts

; Prepares VDP command and calls DrawTilemapRows
Gfx_DrawTilemapStart:
                bsr.s   Gfx_MakeVDPWriteCmd  ; was: sub_10F6E

; Draws d6+1 rows of d7+1 tiles from (a6)+
Gfx_DrawTilemapRect:
                lea     (VDP_CTRL).l,a4  ; was: sub_10F70
                lea     (VDP_DATA).l,a3
                move.l  #$400000,d0

Gfx_DrawTilemapRect_RowLoop:  ; was: loc_10F82
                move.l  d5,(a4)
                move.w  d7,d1

Gfx_DrawTilemapRect_ColumnLoop:  ; was: loc_10F86
                move.w  (a6)+,(a3)
                dbf     d1,Gfx_DrawTilemapRect_ColumnLoop
                add.l   d0,d5
                dbf     d6,Gfx_DrawTilemapRect_RowLoop
                rts

; Writes single character tile with base offset
Text_WriteCharTile:
                cmpi.w  #$FFFF,(word_FFD884).w  ; was: sub_10F94
                bne.s   Text_WriteCharTile_AddBase
                move.w  #$8020,d4
                bra.s   Text_WriteCharTile_Emit

Text_WriteCharTile_AddBase:  ; was: loc_10FA2
                add.w   (word_FFD884).w,d4

Text_WriteCharTile_Emit:  ; was: loc_10FA6
                bsr.s   Gfx_WriteTileAtOffset
                rts

; Draws null-terminated string from (a6) at VRAM pos
Text_DrawString:
                moveq   #0,d6  ; was: sub_10FAA
                move.w  (a6)+,d6

Text_DrawString_Loop:  ; was: loc_10FAE
                moveq   #0,d4
                moveq   #0,d5
                move.w  d6,d5
                move.b  (a6)+,d4
                beq.s   Text_DrawString_Return
                bsr.s   Text_WriteCharTile
                addq.w  #2,d6
                bra.s   Text_DrawString_Loop

Text_DrawString_Return:  ; was: locret_10FBE
                rts

; Draws double-height text with upper/lower tiles
Text_DrawDoubleHeight:
                moveq   #0,d6  ; was: sub_10FC0
                move.w  (a6)+,d6

Text_DrawDoubleHeight_Loop:  ; was: loc_10FC4
                moveq   #0,d4
                moveq   #0,d5
                move.b  (a6)+,d4
                beq.s   Text_DrawDoubleHeight_Return
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
                bra.s   Text_DrawDoubleHeight_Loop

Text_DrawDoubleHeight_Return:  ; was: locret_10FF2
                rts

; Draws BCD number from (a6) with leading zero handling
Text_DrawBCDNumber:
                clr.b   (byte_FFD00D).w  ; was: sub_10FF4
                subq.w  #2,d5

Text_DrawBCDNumber_Loop:  ; was: loc_10FFA
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
                dbf     d0,Text_DrawBCDNumber_Loop
                tst.b   (byte_FFD00D).w
                bne.s   Text_DrawBCDNumber_Return
                moveq   #$30,d4
                bsr.w   Text_WriteCharTile

Text_DrawBCDNumber_Return:  ; was: locret_11034
                rts

; Draws single digit with leading zero suppression
Text_DrawDigit:
                tst.b   d4  ; was: sub_11036
                bne.s   Text_DrawDigit_SeenNonZero
                tst.b   (byte_FFD00D).w
                bne.s   Text_DrawDigit_Emit
                tst.b   (byte_FFD29A).w
                beq.s   Text_DrawDigit_Return
                bsr.w   Text_WriteCharTile

Text_DrawDigit_Return:  ; was: locret_1104A
                rts

Text_DrawDigit_SeenNonZero:  ; was: loc_1104C
                move.b  #1,(byte_FFD00D).w

Text_DrawDigit_Emit:  ; was: loc_11052
                addi.w  #$30,d4
                bsr.w   Text_WriteCharTile
                rts

; Updates object X/Y position from velocity with wrapping
