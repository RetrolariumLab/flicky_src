; Score, timer, cat placement, palette fade-in.
; ROM $011674-$0117BF.

Math_GridToScreen:
                andi.w  #$FF,d7  ; was: sub_11674
                andi.w  #$FF,d6
                lsl.w   #3,d7
                lsl.w   #3,d6
                addi.w  #$80,d7
                addi.w  #$80,d6
                rts

; Adds BCD score and updates high score if exceeded
Score_AddAndCheck:
                tst.b   (byte_FFD2A5).w  ; was: sub_1168A
                bne.s   Score_AddAndCheck_Return
                lea     (byte_FFD266).w,a2
                lea     (byte_FFD882).w,a1
                moveq   #3,d0
                move    #4,ccr

Score_AddAndCheck_AddLoop:  ; was: loc_1169E
                abcd    -(a2),-(a1)
                dbf     d0,Score_AddAndCheck_AddLoop
                bsr.w   UI_DrawScore
                move.l  (dword_FFD87E).w,d0
                move.l  (dword_FFCC00).w,d1
                cmp.l   d0,d1
                bge.s   Score_AddAndCheck_Return
                move.l  d0,(dword_FFCC00).w
                bsr.w   UI_DrawHighScore

Score_AddAndCheck_Return:  ; was: locret_116BC
                rts

; Increments game time BCD counter with overflow
Timer_IncrementTime:
                moveq   #1,d1  ; was: sub_116BE
                move.b  (dword_FFD888+2).w,d0
                addi.b  #0,d0
                abcd    d1,d0
                move.b  d0,(dword_FFD888+2).w
                cmpi.b  #$60,d0
                bcs.s   Timer_IncrementTime_Return
                clr.b   (dword_FFD888+2).w
                move.b  (dword_FFD888+1).w,d0
                addi.b  #0,d0
                abcd    d1,d0
                move.b  d0,(dword_FFD888+1).w
                cmpi.b  #$60,d0
                bcs.s   Timer_IncrementTime_Return
                clr.b   (dword_FFD888+1).w
                move.b  (dword_FFD888).w,d0
                addi.b  #0,d0
                abcd    d1,d0
                move.b  d0,(dword_FFD888).w

Timer_IncrementTime_Return:  ; was: locret_116FE
                rts

; Copies cat spawn positions to object slots
Level_SetCatPositions:
                lea     (byte_FFD82E).w,a0  ; was: sub_11700
                move.w  (a0)+,(word_FFC47E).w
                move.w  (a0),(word_FFC3BE).w
                move.w  (a0)+,(word_FFC6BE).w
                move.w  (a0),(word_FFC3FE).w
                move.w  (a0),(word_FFC6FE).w
                move.w  (a0),(word_FFC43E).w
                move.w  (a0),(word_FFC73E).w
                rts

; Copies enemy data FFC480 to backup area FFDE00
Enemy_BackupToBuffer:
                lea     (unk_FFC480).w,a3  ; was: sub_11722
                lea     (unk_FFDE00).w,a4
                bra.s   Enemy_CopyBuffer

; Restores enemy data from FFDE00 to FFC480
Enemy_RestoreFromBuffer:
                lea     (unk_FFDE00).w,a3  ; was: sub_1172C
                lea     (unk_FFC480).w,a4

Enemy_CopyBuffer:  ; was: loc_11734
                move.w  #$7F,d0

Enemy_CopyBuffer_Loop:  ; was: loc_11738
                move.l  (a3)+,(a4)+
                dbf     d0,Enemy_CopyBuffer_Loop
                rts

; Cycles tile base offset for text blink effect
Text_CycleBlink:
                moveq   #0,d0  ; was: sub_11740
                move.b  (byte_FFD280).w,d0
                addq.b  #1,d0
                andi.b  #$F,d0
                move.b  d0,(byte_FFD280).w
                lsr.w   #2,d0
                lsl.w   #1,d0
                move.w  Text_BlinkTileBases(pc,d0.w),(word_FFD884).w
                rts

Text_BlinkTileBases: dc.w    $8100, $8000, $FFFF, $8000  ; was: word_1175C
; Calculates (word_FFD82C+1) mod d7 with bcs
Math_ModuloLower:
                moveq   #0,d0  ; was: sub_11764
                move.b  (word_FFD82C+1).w,d0

; Alternate entry: reduce d0 modulo d7 without reloading d0 from the round
; counter. Game_StateBonusCheck and Game_CheckSkipBonus call in here.
Math_ModuloFromD0:  ; was: loc_1176A
                cmp.b   d7,d0
                bcs.s   Math_ModuloLower_Return
                sub.b   d7,d0
                bra.s   Math_ModuloFromD0

Math_ModuloLower_Return:  ; was: locret_11772
                rts

; Calculates (word_FFD82C+1) mod d7 with bls
Math_ModuloUpper:
                moveq   #0,d0  ; was: sub_11774
                move.b  (word_FFD82C+1).w,d0

Math_ModuloUpper_Loop:  ; was: loc_1177A
                cmp.b   d7,d0
                bls.s   Math_ModuloUpper_Return
                sub.b   d7,d0
                bra.s   Math_ModuloUpper_Loop

Math_ModuloUpper_Return:  ; was: locret_11782
                rts

; Copies palette to buffer and fades in
Gfx_FadeInPalette:
                lea     (word_FFF7E0).w,a0  ; was: sub_11784
                lea     (unk_FFF860).w,a1
                moveq   #$1F,d0

Gfx_FadeInPalette_CopyLoop:  ; was: loc_1178E
                move.l  (a0)+,(a1)+
                dbf     d0,Gfx_FadeInPalette_CopyLoop
                move.w  #$FFC0,(word_FFFFAC).w

Gfx_FadeInPalette_StepLoop:  ; was: loc_1179A
                move.w  (word_FFFFAC).w,d2
                addq.w  #2,d2
                beq.s   Gfx_FadeInPalette_Return
                cmpi.w  #$40,d2
                ble.s   Gfx_FadeInPalette_ApplyStep
                subq.w  #2,d2

Gfx_FadeInPalette_ApplyStep:  ; was: loc_117AA
                move.w  d2,(word_FFFFAC).w
                moveq   #$FFFFFFC0,d3
                jsr     unk_FFFBA8
                jsr     unk_FFFB0C
                jsr     unk_FFFB6C
                bra.s   Gfx_FadeInPalette_StepLoop

Gfx_FadeInPalette_Return:  ; was: locret_117BE
                rts

; AABB collision test between objects a0 and a1
