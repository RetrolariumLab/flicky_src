; Ground tilemap construction and background objects.
; ROM $011910-$011BC1.

UI_DrawGroundTile:
                lsl.w   #1,d4  ; was: sub_11910
                move.w  word_1191C(pc,d4.w),d4
                bsr.w Gfx_WriteTileAtOffset
                rts

word_1191C:     dc.w $220D, $2206, $2207, $2208, $2209, $220A, $220B, $220C
                dc.w $220D, $220E, $220F, $2210, $2211, $2212, $2213, $2214
; Writes ground tile from pointer table to VRAM
UI_DrawGroundTilePtr:
                lsl.w   #1,d4  ; was: sub_1193C
                movea.l (dword_FFD800).w,a1
                move.w  (a1,d4.w),d4
                bsr.w Gfx_WriteTileAtOffset
                rts

; Draws 8 columns of upper ground decoration
Level_DrawUpperGround:
                moveq   #0,d5  ; was: sub_1194C
                move.w  #$E000,d5
                moveq   #7,d0

loc_11954:
                move.w  d0,-(sp)
                bsr.s Level_DrawUpperGroundBlock
                move.w  (sp)+,d0
                addq.w  #8,d5
                dbf     d0,loc_11954
                rts

; Draws single 4x2 upper ground block
Level_DrawUpperGroundBlock:
                lea     (dword_FFD808).w,a6  ; was: sub_11962
                movea.l (a6),a6
                moveq   #3,d7
                moveq   #1,d6
                move.l  d5,-(sp)
                bsr.w Gfx_DrawTilemapStart
                move.l  (sp)+,d5
                rts

; Draws 8 columns of lower ground decoration
Level_DrawLowerGround:
                moveq   #0,d5  ; was: sub_11976
                move.w  #$E680,d5
                moveq   #7,d0

loc_1197E:
                move.w  d0,-(sp)
                bsr.s Level_DrawLowerGroundBlock
                move.w  (sp)+,d0
                addq.w  #8,d5
                dbf     d0,loc_1197E
                rts

; Draws single 4x2 lower ground block
Level_DrawLowerGroundBlock:
                lea     (dword_FFD80C).w,a6  ; was: sub_1198C
                movea.l (a6),a6
                moveq   #3,d7
                moveq   #1,d6
                move.l  d5,-(sp)
                bsr.w Gfx_DrawTilemapStart
                move.l  (sp)+,d5
                rts

; Fills background plane with repeated tile pattern
Gfx_FillBackground:
                move.l  #$60800003,(VDP_CTRL).l  ; was: sub_119A0
                movea.l (dword_FFD804).w,a0
                move.w  (a0),d1
                move.w  #$2FF,d0

loc_119B4:
                move.w  d1,(VDP_DATA).l
                dbf     d0,loc_119B4
                rts

; Builds ground tilemap from collision flags
Level_BuildGroundTilemap:
                lea     (unk_FFC840).w,a0  ; was: sub_119C0
                moveq   #0,d1
                moveq   #0,d2
                moveq   #0,d6
                move.w  #$E080,d6
                move.w  d6,d5
                move.w  #$2FF,d0

loc_119D4:
                moveq   #0,d4
                moveq   #0,d5
                move.w  d6,d5
                tst.b   (a0)
                beq.w   loc_119F4
                andi.w  #$1F,d2
                beq.w   loc_11A34
                cmpi.w  #$1F,d2
                beq.w   loc_11A66
                bra.w   loc_11A98

loc_119F4:
                andi.w  #$1F,d2
                beq.w   loc_11ACA
                bra.w   loc_11AF0

loc_11A00:
                addq.l  #1,a0
                addq.w  #1,d1
                move.w  d1,d2
                addq.w  #2,d6
                dbf     d0,loc_119D4
                lea     (unk_FFC840).w,a0
                moveq   #0,d5
                move.w  #$E080,d5
                moveq   #$1F,d0

loc_11A18:
                tst.b   (a0)+
                bne.s   loc_11A2C
                move.w  #3,d4
                movem.l d5/a0,-(sp)
                bsr.w UI_DrawGroundTilePtr
                movem.l (sp)+,d5/a0

loc_11A2C:
                addq.w  #2,d5
                dbf     d0,loc_11A18
                rts

loc_11A34:
                tst.b   -$20(a0)
                beq.s   loc_11A3E
                bset    #0,d4

loc_11A3E:
                tst.b   $20(a0)
                beq.s   loc_11A48
                bset    #1,d4

loc_11A48:
                tst.b   $1F(a0)
                beq.s   loc_11A52
                bset    #2,d4

loc_11A52:
                tst.b   1(a0)
                beq.s   loc_11A5C
                bset    #3,d4

loc_11A5C:
                move.b  d4,(a0)
                bsr.w UI_DrawGroundTile
                bra.w   loc_11A00

loc_11A66:
                tst.b   -$20(a0)
                beq.s   loc_11A70
                bset    #0,d4

loc_11A70:
                tst.b   $20(a0)
                beq.s   loc_11A7A
                bset    #1,d4

loc_11A7A:
                tst.b   -1(a0)
                beq.s   loc_11A84
                bset    #2,d4

loc_11A84:
                tst.b   -$1F(a0)
                beq.s   loc_11A8E
                bset    #3,d4

loc_11A8E:
                move.b  d4,(a0)
                bsr.w UI_DrawGroundTile
                bra.w   loc_11A00

loc_11A98:
                tst.b   -$20(a0)
                beq.s   loc_11AA2
                bset    #0,d4

loc_11AA2:
                tst.b   $20(a0)
                beq.s   loc_11AAC
                bset    #1,d4

loc_11AAC:
                tst.b   -1(a0)
                beq.s   loc_11AB6
                bset    #2,d4

loc_11AB6:
                tst.b   1(a0)
                beq.s   loc_11AC0
                bset    #3,d4

loc_11AC0:
                move.b  d4,(a0)
                bsr.w UI_DrawGroundTile
                bra.w   loc_11A00

loc_11ACA:
                tst.b   -$20(a0)
                beq.s   loc_11AD4
                bset    #0,d4

loc_11AD4:
                tst.b   -1(a0)
                beq.s   loc_11ADE
                bset    #1,d4

loc_11ADE:
                tst.b   $1F(a0)
                beq.s   loc_11AE8
                bset    #2,d4

loc_11AE8:
                bsr.w UI_DrawGroundTilePtr
                bra.w   loc_11A00

loc_11AF0:
                tst.b   -$20(a0)
                beq.s   loc_11AFA
                bset    #0,d4

loc_11AFA:
                tst.b   -$21(a0)
                beq.s   loc_11B04
                bset    #1,d4

loc_11B04:
                tst.b   -1(a0)
                beq.s   loc_11B0E
                bset    #2,d4

loc_11B0E:
                bsr.w UI_DrawGroundTilePtr
                bra.w   loc_11A00

; Draws background object at grid position d7/d6
Level_DrawBackgroundObject:
                moveq   #0,d5  ; was: sub_11B16
                move.w  #$C000,d5
                bsr.w Gfx_TilemapCoordToAddr
                lsl.w   #2,d4
                move.w  word_11B3C(pc,d4.w),d7
                move.w  word_11B3E(pc,d4.w),d6
                lsr.w   #1,d4
                moveq   #$FFFFFFFF,d2
                move.w  word_11B54(pc,d4.w),d2
                movea.l d2,a6
                movea.l (a6),a6
                bsr.w Gfx_DrawTilemapRect
                rts

word_11B3C:     dc.w 2
word_11B3E:     dc.w 2, 1, 1, 1, 2, 1, 2, 4, 2, 3, 3
word_11B54:     dc.w $D81C, $D820, $D824, $D810, $D814, $D818
; Draws cat exit door at level start position
Level_DrawCatDoor:
                moveq   #0,d7  ; was: sub_11B60
                moveq   #0,d6
                moveq   #0,d5
                move.b  (byte_FFD82E).w,d7
                move.b  (byte_FFD82F).w,d6
                move.w  #$E000,d5
                bsr.w Gfx_TilemapCoordToAddr
                moveq   #2,d7
                moveq   #2,d6
                lea     (word_1A4B4).l,a6
                bsr.w Gfx_DrawTilemapRect
                rts

; Draws player entry indicator above start pos
Level_DrawEntryArrow:
                lea     (byte_FFD82E).w,a0  ; was: sub_11B86
                moveq   #0,d7
                moveq   #0,d6
                moveq   #0,d5
                move.b  0.w(a0),d7
                move.b  1(a0),d6
                subq.b  #1,d6
                move.w  #$E000,d5
                bsr.w Gfx_TilemapCoordToAddr
                moveq   #2,d7
                moveq   #0,d6
                lea     (word_1A262).l,a6
                btst    #7,(IO_PCBVER+1).l
                beq.s   loc_11BBC
                lea     (word_11C98).l,a6

loc_11BBC:
                bsr.w Gfx_DrawTilemapRect
                rts

; Draws HUD: score labels and life indicators
