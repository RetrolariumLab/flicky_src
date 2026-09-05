; Ground tilemap construction and background objects.
; ROM $011910-$011BC1.

UI_DrawGroundTile:
                lsl.w   #1,d4  ; was: sub_11910
                move.w  UI_GroundTileTable(pc,d4.w),d4
                bsr.w   Gfx_WriteTileAtOffset
                rts

UI_GroundTileTable: dc.w    $220D, $2206, $2207, $2208, $2209, $220A, $220B, $220C  ; was: word_1191C
                dc.w    $220D, $220E, $220F, $2210, $2211, $2212, $2213, $2214
; Writes ground tile from pointer table to VRAM
UI_DrawGroundTilePtr:
                lsl.w   #1,d4  ; was: sub_1193C
                movea.l (Ram_GroundTilePtr).w,a1
                move.w  (a1,d4.w),d4
                bsr.w   Gfx_WriteTileAtOffset
                rts

; Draws 8 columns of upper ground decoration
Level_DrawUpperGround:
                moveq   #0,d5  ; was: sub_1194C
                move.w  #$E000,d5
                moveq   #7,d0

Level_DrawUpperGround_ColumnLoop:  ; was: loc_11954
                move.w  d0,-(sp)
                bsr.s   Level_DrawUpperGroundBlock
                move.w  (sp)+,d0
                addq.w  #8,d5
                dbf     d0,Level_DrawUpperGround_ColumnLoop
                rts

; Draws single 4x2 upper ground block
Level_DrawUpperGroundBlock:
                lea     (Ram_UpperGroundPtr).w,a6  ; was: sub_11962
                movea.l (a6),a6
                moveq   #3,d7
                moveq   #1,d6
                move.l  d5,-(sp)
                bsr.w   Gfx_DrawTilemapStart
                move.l  (sp)+,d5
                rts

; Draws 8 columns of lower ground decoration
Level_DrawLowerGround:
                moveq   #0,d5  ; was: sub_11976
                move.w  #$E680,d5
                moveq   #7,d0

Level_DrawLowerGround_ColumnLoop:  ; was: loc_1197E
                move.w  d0,-(sp)
                bsr.s   Level_DrawLowerGroundBlock
                move.w  (sp)+,d0
                addq.w  #8,d5
                dbf     d0,Level_DrawLowerGround_ColumnLoop
                rts

; Draws single 4x2 lower ground block
Level_DrawLowerGroundBlock:
                lea     (Ram_LowerGroundPtr).w,a6  ; was: sub_1198C
                movea.l (a6),a6
                moveq   #3,d7
                moveq   #1,d6
                move.l  d5,-(sp)
                bsr.w   Gfx_DrawTilemapStart
                move.l  (sp)+,d5
                rts

; Fills background plane with repeated tile pattern
Gfx_FillBackground:
                move.l  #$60800003,(VDP_CTRL).l  ; was: sub_119A0
                movea.l (Ram_BackgroundTilePtr).w,a0
                move.w  (a0),d1
                move.w  #$2FF,d0

Gfx_FillBackground_Loop:  ; was: loc_119B4
                move.w  d1,(VDP_DATA).l
                dbf     d0,Gfx_FillBackground_Loop
                rts

; Builds ground tilemap from collision flags
Level_BuildGroundTilemap:
                lea     (Ram_CollisionMapRow1).w,a0  ; was: sub_119C0
                moveq   #0,d1
                moveq   #0,d2
                moveq   #0,d6
                move.w  #$E080,d6
                move.w  d6,d5
                move.w  #$2FF,d0

Level_BuildGroundTilemap_CellLoop:  ; was: loc_119D4
                moveq   #0,d4
                moveq   #0,d5
                move.w  d6,d5
                tst.b   (a0)
                beq.w   Level_BuildGroundTilemap_EmptyCell
                andi.w  #$1F,d2
                beq.w   Level_GroundTile_SolidLeftEdge
                cmpi.w  #$1F,d2
                beq.w   Level_GroundTile_SolidRightEdge
                bra.w   Level_GroundTile_SolidMiddle

Level_BuildGroundTilemap_EmptyCell:  ; was: loc_119F4
                andi.w  #$1F,d2
                beq.w   Level_GroundTile_EmptyLeftEdge
                bra.w   Level_GroundTile_EmptyMiddle

Level_BuildGroundTilemap_NextCell:  ; was: loc_11A00
                addq.l  #1,a0
                addq.w  #1,d1
                move.w  d1,d2
                addq.w  #2,d6
                dbf     d0,Level_BuildGroundTilemap_CellLoop
                lea     (Ram_CollisionMapRow1).w,a0
                moveq   #0,d5
                move.w  #$E080,d5
                moveq   #$1F,d0

Level_BuildGroundTilemap_TopRowLoop:  ; was: loc_11A18
                tst.b   (a0)+
                bne.s   Level_BuildGroundTilemap_TopRowNext
                move.w  #3,d4
                movem.l d5/a0,-(sp)
                bsr.w   UI_DrawGroundTilePtr
                movem.l (sp)+,d5/a0

Level_BuildGroundTilemap_TopRowNext:  ; was: loc_11A2C
                addq.w  #2,d5
                dbf     d0,Level_BuildGroundTilemap_TopRowLoop
                rts

Level_GroundTile_SolidLeftEdge:  ; was: loc_11A34
                tst.b   -$20(a0)
                beq.s   Level_GroundTile_SolidLeftEdge_TestBelow
                bset    #0,d4

Level_GroundTile_SolidLeftEdge_TestBelow:  ; was: loc_11A3E
                tst.b   $20(a0)
                beq.s   Level_GroundTile_SolidLeftEdge_TestBelowLeft
                bset    #1,d4

Level_GroundTile_SolidLeftEdge_TestBelowLeft:  ; was: loc_11A48
                tst.b   $1F(a0)
                beq.s   Level_GroundTile_SolidLeftEdge_TestRight
                bset    #2,d4

Level_GroundTile_SolidLeftEdge_TestRight:  ; was: loc_11A52
                tst.b   1(a0)
                beq.s   Level_GroundTile_SolidLeftEdge_Draw
                bset    #3,d4

Level_GroundTile_SolidLeftEdge_Draw:  ; was: loc_11A5C
                move.b  d4,(a0)
                bsr.w   UI_DrawGroundTile
                bra.w   Level_BuildGroundTilemap_NextCell

Level_GroundTile_SolidRightEdge:  ; was: loc_11A66
                tst.b   -$20(a0)
                beq.s   Level_GroundTile_SolidRightEdge_TestBelow
                bset    #0,d4

Level_GroundTile_SolidRightEdge_TestBelow:  ; was: loc_11A70
                tst.b   $20(a0)
                beq.s   Level_GroundTile_SolidRightEdge_TestLeft
                bset    #1,d4

Level_GroundTile_SolidRightEdge_TestLeft:  ; was: loc_11A7A
                tst.b   -1(a0)
                beq.s   Level_GroundTile_SolidRightEdge_TestAboveRight
                bset    #2,d4

Level_GroundTile_SolidRightEdge_TestAboveRight:  ; was: loc_11A84
                tst.b   -$1F(a0)
                beq.s   Level_GroundTile_SolidRightEdge_Draw
                bset    #3,d4

Level_GroundTile_SolidRightEdge_Draw:  ; was: loc_11A8E
                move.b  d4,(a0)
                bsr.w   UI_DrawGroundTile
                bra.w   Level_BuildGroundTilemap_NextCell

Level_GroundTile_SolidMiddle:  ; was: loc_11A98
                tst.b   -$20(a0)
                beq.s   Level_GroundTile_SolidMiddle_TestBelow
                bset    #0,d4

Level_GroundTile_SolidMiddle_TestBelow:  ; was: loc_11AA2
                tst.b   $20(a0)
                beq.s   Level_GroundTile_SolidMiddle_TestLeft
                bset    #1,d4

Level_GroundTile_SolidMiddle_TestLeft:  ; was: loc_11AAC
                tst.b   -1(a0)
                beq.s   Level_GroundTile_SolidMiddle_TestRight
                bset    #2,d4

Level_GroundTile_SolidMiddle_TestRight:  ; was: loc_11AB6
                tst.b   1(a0)
                beq.s   Level_GroundTile_SolidMiddle_Draw
                bset    #3,d4

Level_GroundTile_SolidMiddle_Draw:  ; was: loc_11AC0
                move.b  d4,(a0)
                bsr.w   UI_DrawGroundTile
                bra.w   Level_BuildGroundTilemap_NextCell

Level_GroundTile_EmptyLeftEdge:  ; was: loc_11ACA
                tst.b   -$20(a0)
                beq.s   Level_GroundTile_EmptyLeftEdge_TestLeft
                bset    #0,d4

Level_GroundTile_EmptyLeftEdge_TestLeft:  ; was: loc_11AD4
                tst.b   -1(a0)
                beq.s   Level_GroundTile_EmptyLeftEdge_TestBelowLeft
                bset    #1,d4

Level_GroundTile_EmptyLeftEdge_TestBelowLeft:  ; was: loc_11ADE
                tst.b   $1F(a0)
                beq.s   Level_GroundTile_EmptyLeftEdge_Draw
                bset    #2,d4

Level_GroundTile_EmptyLeftEdge_Draw:  ; was: loc_11AE8
                bsr.w   UI_DrawGroundTilePtr
                bra.w   Level_BuildGroundTilemap_NextCell

Level_GroundTile_EmptyMiddle:  ; was: loc_11AF0
                tst.b   -$20(a0)
                beq.s   Level_GroundTile_EmptyMiddle_TestAboveLeft
                bset    #0,d4

Level_GroundTile_EmptyMiddle_TestAboveLeft:  ; was: loc_11AFA
                tst.b   -$21(a0)
                beq.s   Level_GroundTile_EmptyMiddle_TestLeft
                bset    #1,d4

Level_GroundTile_EmptyMiddle_TestLeft:  ; was: loc_11B04
                tst.b   -1(a0)
                beq.s   Level_GroundTile_EmptyMiddle_Draw
                bset    #2,d4

Level_GroundTile_EmptyMiddle_Draw:  ; was: loc_11B0E
                bsr.w   UI_DrawGroundTilePtr
                bra.w   Level_BuildGroundTilemap_NextCell

; Draws background object at grid position d7/d6
Level_DrawBackgroundObject:
                moveq   #0,d5  ; was: sub_11B16
                move.w  #$C000,d5
                bsr.w   Gfx_TilemapCoordToAddr
                lsl.w   #2,d4
                move.w  Level_BackgroundWidthTable(pc,d4.w),d7
                move.w  Level_BackgroundHeightTable(pc,d4.w),d6
                lsr.w   #1,d4
                moveq   #$FFFFFFFF,d2
                move.w  Level_BackgroundMappingPointers(pc,d4.w),d2
                movea.l d2,a6
                movea.l (a6),a6
                bsr.w   Gfx_DrawTilemapRect
                rts

Level_BackgroundWidthTable: dc.w    2  ; was: word_11B3C
Level_BackgroundHeightTable: dc.w    2, 1, 1, 1, 2, 1, 2, 4, 2, 3, 3  ; was: word_11B3E
Level_BackgroundMappingPointers: dc.w    $D81C, $D820, $D824, $D810, $D814, $D818  ; was: word_11B54
; Draws cat exit door at level start position
Level_DrawCatDoor:
                moveq   #0,d7  ; was: sub_11B60
                moveq   #0,d6
                moveq   #0,d5
                move.b  (Ram_PlayerStartX).w,d7
                move.b  (Ram_PlayerStartY).w,d6
                move.w  #$E000,d5
                bsr.w   Gfx_TilemapCoordToAddr
                moveq   #2,d7
                moveq   #2,d6
                lea     (Level_DrawCatDoorData).l,a6
                bsr.w   Gfx_DrawTilemapRect
                rts

; Draws player entry indicator above start pos
Level_DrawEntryArrow:
                lea     (Ram_PlayerStartX).w,a0  ; was: sub_11B86
                moveq   #0,d7
                moveq   #0,d6
                moveq   #0,d5
                move.b  0.w(a0),d7
                move.b  1(a0),d6
                subq.b  #1,d6
                move.w  #$E000,d5
                bsr.w   Gfx_TilemapCoordToAddr
                moveq   #2,d7
                moveq   #0,d6
                lea     (UI_EntryArrowData0).l,a6
                btst    #7,(IO_PCBVER+1).l
                beq.s   Level_DrawEntryArrow_Draw
                lea     (UI_EntryArrowFrame1).l,a6

Level_DrawEntryArrow_Draw:  ; was: loc_11BBC
                bsr.w   Gfx_DrawTilemapRect
                rts

; Draws HUD: score labels and life indicators
