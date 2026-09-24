; Scoring, timers, enemy placement, and object-pair collisions
; ROM $011674-$01190F
Math_GridToScreen:
                andi.w  #$FF,d7
                andi.w  #$FF,d6
                lsl.w   #3,d7
                lsl.w   #3,d6
                addi.w  #$80,d7
                addi.w  #$80,d6
                rts

; Adds BCD score and updates high score if exceeded
Score_AddAndCheck:
                tst.b   (Ram_DemoModeFlag).w
                bne.s   Score_AddAndCheck_Return
                lea     (Ram_RoundMinutes).w,a2
                lea     (Ram_Lives).w,a1
                moveq   #3,d0
                move    #4,ccr

Score_AddAndCheck_AddLoop:
                abcd    -(a2),-(a1)
                dbf     d0,Score_AddAndCheck_AddLoop
                bsr.w   UI_DrawScore
                move.l  (Ram_Score).w,d0
                move.l  (Ram_HighScore).w,d1
                cmp.l   d0,d1
                bge.s   Score_AddAndCheck_Return
                move.l  d0,(Ram_HighScore).w
                bsr.w   UI_DrawHighScore

Score_AddAndCheck_Return:
                rts

; Increments game time BCD counter with overflow
Timer_IncrementTime:
                moveq   #1,d1
                move.b  (Ram_RoundTime+2).w,d0
                addi.b  #0,d0
                abcd    d1,d0
                move.b  d0,(Ram_RoundTime+2).w
                cmpi.b  #$60,d0
                bcs.s   Timer_IncrementTime_Return
                clr.b   (Ram_RoundTime+2).w
                move.b  (Ram_RoundTime+1).w,d0
                addi.b  #0,d0
                abcd    d1,d0
                move.b  d0,(Ram_RoundTime+1).w
                cmpi.b  #$60,d0
                bcs.s   Timer_IncrementTime_Return
                clr.b   (Ram_RoundTime+1).w
                move.b  (Ram_RoundTime).w,d0
                addi.b  #0,d0
                abcd    d1,d0
                move.b  d0,(Ram_RoundTime).w

Timer_IncrementTime_Return:
                rts

; Copies enemy spawn positions to object slots
Level_SetEnemyPositions:
                lea     (Ram_PlayerStartX).w,a0
                move.w  (a0)+,(Ram_PlayerGridPos).w
                move.w  (a0),(Ram_EnemySlot0_GridPos).w
                move.w  (a0)+,(Ram_EnemySlot3_GridPos).w
                move.w  (a0),(Ram_EnemySlot1_GridPos).w
                move.w  (a0),(Ram_EnemySlot4_GridPos).w
                move.w  (a0),(Ram_EnemySlot2_GridPos).w
                move.w  (a0),(Ram_EnemySlot5_GridPos).w
                rts

; Copies enemy data FFC480 to backup area FFDE00
Enemy_BackupToBuffer:
                lea     (Ram_ChickSlots).w,a3
                lea     (Ram_EnemyBackup).w,a4
                bra.s   Enemy_CopyBuffer

; Restores enemy data from FFDE00 to FFC480
Enemy_RestoreFromBuffer:
                lea     (Ram_EnemyBackup).w,a3
                lea     (Ram_ChickSlots).w,a4

Enemy_CopyBuffer:
                move.w  #$7F,d0

Enemy_CopyBuffer_Loop:
                move.l  (a3)+,(a4)+
                dbf     d0,Enemy_CopyBuffer_Loop
                rts

; Cycles tile base offset for text blink effect
Text_CycleBlink:
                moveq   #0,d0
                move.b  (Ram_BlinkTimer).w,d0
                addq.b  #1,d0
                andi.b  #$F,d0
                move.b  d0,(Ram_BlinkTimer).w
                lsr.w   #2,d0
                lsl.w   #1,d0
                move.w  Text_BlinkTileBases(pc,d0.w),(Ram_TextTileBase).w
                rts

Text_BlinkTileBases:    dc.w    $8100, $8000, $FFFF, $8000
; Calculates (Ram_RoundNumber+1) mod d7 with bcs
Math_ModuloLower:
                moveq   #0,d0
                move.b  (Ram_RoundNumber+1).w,d0

; Alternate entry: reduce d0 modulo d7 without reloading d0 from the round
; counter. Game_StateBonusCheck and Game_CheckSkipBonus call in here
Math_ModuloFromD0:
                cmp.b   d7,d0
                bcs.s   Math_ModuloLower_Return
                sub.b   d7,d0
                bra.s   Math_ModuloFromD0

Math_ModuloLower_Return:
                rts

; Calculates (Ram_RoundNumber+1) mod d7 with bls
Math_ModuloUpper:
                moveq   #0,d0
                move.b  (Ram_RoundNumber+1).w,d0

Math_ModuloUpper_Loop:
                cmp.b   d7,d0
                bls.s   Math_ModuloUpper_Return
                sub.b   d7,d0
                bra.s   Math_ModuloUpper_Loop

Math_ModuloUpper_Return:
                rts

; Copies palette to buffer and fades in
Gfx_FadeInPalette:
                lea     (Ram_Palette).w,a0
                lea     (Ram_PaletteBackup).w,a1
                moveq   #$1F,d0

Gfx_FadeInPalette_CopyLoop:
                move.l  (a0)+,(a1)+
                dbf     d0,Gfx_FadeInPalette_CopyLoop
                move.w  #$FFC0,(Ram_FadeLevel).w

Gfx_FadeInPalette_StepLoop:
                move.w  (Ram_FadeLevel).w,d2
                addq.w  #2,d2
                beq.s   Gfx_FadeInPalette_Return
                cmpi.w  #$40,d2
                ble.s   Gfx_FadeInPalette_ApplyStep
                subq.w  #2,d2

Gfx_FadeInPalette_ApplyStep:
                move.w  d2,(Ram_FadeLevel).w
                moveq   #$FFFFFFC0,d3
                jsr     j_Gfx_FadePalette
                jsr     j_Gfx_ApplyPaletteMask
                jsr     j_Sound_QueueSFX
                bra.s   Gfx_FadeInPalette_StepLoop

Gfx_FadeInPalette_Return:
                rts

; AABB collision test between objects a0 and a1
Collision_CheckObjectPair:
                tst.w   (a1)
                beq.w   Collision_CheckObjectPair_Miss
                moveq   #0,d0
                moveq   #0,d1
                move.b  4(a0),d0
                cmpi.b  #$FF,d0
                beq.w   Collision_CheckObjectPair_Miss
                move.b  4(a1),d1
                cmpi.b  #$FF,d1
                beq.w   Collision_CheckObjectPair_Miss
                lsl.w   #3,d0
                lsl.w   #3,d1
                move.w  $20(a0),d3
                lea     Collision_BoxLeftTable(pc),a6
                add.w   (a6,d0.w),d3
                move.w  d3,d2
                addq.l  #2,a6
                add.w   (a6,d0.w),d3
                move.w  $20(a1),d5
                add.w   Collision_BoxLeftTable(pc,d1.w),d5
                move.w  d5,d4
                add.w   Collision_BoxWidthTable(pc,d1.w),d5
                cmp.w   d2,d4
                blt.s   Collision_CheckObjectPair_TestXCase2
                cmp.w   d3,d4
                bgt.s   Collision_CheckObjectPair_TestXCase2
                bra.s   Collision_CheckObjectPair_TestY

Collision_CheckObjectPair_TestXCase2:
                cmp.w   d2,d5
                blt.s   Collision_CheckObjectPair_TestXCase3
                cmp.w   d3,d5
                bgt.s   Collision_CheckObjectPair_TestXCase3
                bra.s   Collision_CheckObjectPair_TestY

Collision_CheckObjectPair_TestXCase3:
                cmp.w   d4,d2
                blt.s   Collision_CheckObjectPair_TestXCase4
                cmp.w   d5,d2
                bgt.s   Collision_CheckObjectPair_TestXCase4
                bra.s   Collision_CheckObjectPair_TestY

Collision_CheckObjectPair_TestXCase4:
                cmp.w   d4,d3
                blt.s   Collision_CheckObjectPair_Miss
                cmp.w   d5,d3
                bgt.s   Collision_CheckObjectPair_Miss

Collision_CheckObjectPair_TestY:
                move.w  $24(a0),d3
                add.w   Collision_BoxTopTable(pc,d0.w),d3
                move.w  d3,d2
                add.w   Collision_BoxHeightTable(pc,d0.w),d3
                move.w  $24(a1),d5
                add.w   Collision_BoxTopTable(pc,d1.w),d5
                move.w  d5,d4
                add.w   Collision_BoxHeightTable(pc,d1.w),d5
                cmp.w   d2,d4
                blt.s   Collision_CheckObjectPair_TestYCase2
                cmp.w   d3,d4
                bgt.s   Collision_CheckObjectPair_TestYCase2
                bra.s   Collision_CheckObjectPair_Hit

Collision_CheckObjectPair_TestYCase2:
                cmp.w   d2,d5
                blt.s   Collision_CheckObjectPair_TestYCase3
                cmp.w   d3,d5
                bgt.s   Collision_CheckObjectPair_TestYCase3
                bra.s   Collision_CheckObjectPair_Hit

Collision_CheckObjectPair_TestYCase3:
                cmp.w   d4,d2
                blt.s   Collision_CheckObjectPair_TestYCase4
                cmp.w   d5,d2
                bgt.s   Collision_CheckObjectPair_TestYCase4
                bra.s   Collision_CheckObjectPair_Hit

Collision_CheckObjectPair_TestYCase4:
                cmp.w   d4,d3
                blt.s   Collision_CheckObjectPair_Miss
                cmp.w   d5,d3
                bgt.s   Collision_CheckObjectPair_Miss

Collision_CheckObjectPair_Hit:
                moveq   #1,d0
                rts

Collision_CheckObjectPair_Miss:
                moveq   #0,d0
                rts

; Bounding boxes, eight bytes per object type, indexed by (type * 8):
; left offset, width, top offset, height. The four labels below are the field
; bases; the code indexes each of them by the type to reach the right entry
Collision_BoxLeftTable:     dc.w    $FFFF
Collision_BoxWidthTable:    dc.w    2
Collision_BoxTopTable:      dc.w    $FFEE
Collision_BoxHeightTable:   dc.w    $12
                dc.l    $FFFF0002
                dc.l    $FFF00010
                dc.l    $FFFC0008
                dc.l    $FFF2000C
                dc.l    $FFF9000E
                dc.l    $FFF4000C
                dc.l    $FFFC0008
                dc.l    $FFFA0006
                dc.l    $FFFF0002
                dc.l    $FFEE0012
                dc.l    $FFFE0004
                dc.l    $FFF60004
                dc.l    $FFFC0008
                dc.l    $FFF90007
                dc.l    $FFFF0002
                dc.l    $FFFA0006
                dc.l    $FFFC0008
                dc.l    $FFF6000A
                dc.l    $FFFC0008
                dc.l    $FFFC0002
                dc.l    $FFFC0008
                dc.l    $30002
                dc.l    $FFFC0002
                dc.l    $FFFC0008
                dc.l    $40002
                dc.l    $FFFC0008
                dc.l    $FFFF0002
                dc.l    $FFFD0006
                dc.l    $FFFE0004
                dc.l    8
                dc.l    $FFF80010
                dc.l    $FFF00010
                dc.l    $FFF80010
                dc.l    $FFF00002
                dc.l    $FFFF0002
                dc.l    $FFEE000E
; Writes ground tile from lookup table to VRAM
