; Bonus-round objects.
; ROM $0164EC-$016DA9.

Obj_StarBonus:
                bset    #7,(a0)  ; was: sub_164EC
                bne.s   Obj_StarBonus_Update
                clr.b   5(a0)
                clr.l   $34(a0)
                clr.l   $2C(a0)
                addq.w  #7,$24(a0)
                move.l  #StarBonus_AnimPointers,8(a0)
                clr.w   6(a0)
                move.w  #$12C,$38(a0)
                bclr    #7,2(a0)

Obj_StarBonus_Update:  ; was: loc_1651A
                bsr.w   Object_UpdatePosition
                bsr.w   Anim_UpdateFrame
                lea     (word_FFC440).w,a1
                bsr.w   Collision_CheckObjectPair
                tst.b   d0
                beq.s   Obj_StarBonus_Countdown
                move.l  a0,-(sp)
                move.b  #$98,d0
                bsr.w   Sound_PlayNoteIfActive
                movea.l (sp)+,a0
                lea     (unk_FFC0C0).w,a2
                moveq   #3,d0

Obj_StarBonus_PopupLoop:  ; was: loc_16540
                tst.w   (a2)
                bne.s   Obj_StarBonus_PopupNext
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                move.w  d7,$30(a2)
                subq.w  #8,d6
                move.w  d6,$24(a2)
                moveq   #0,d7
                move.b  (byte_FFD27A).w,d7
                move.b  d7,$3A(a2)
                move.w  #$24,(a2)
                lsl.w   #2,d7
                move.l  Bonus_StarScoreTable(pc,d7.w),d7
                move.l  d7,(dword_FFD262).w
                bsr.w   Score_AddAndCheck
                bra.s   Obj_StarBonus_Despawn

Obj_StarBonus_PopupNext:  ; was: loc_16574
                lea     -$40(a2),a2
                dbf     d0,Obj_StarBonus_PopupLoop

Obj_StarBonus_Countdown:  ; was: loc_1657C
                subq.w  #1,$38(a0)
                bne.s   Obj_StarBonus_Return

Obj_StarBonus_Despawn:  ; was: loc_16582
                bsr.w   Sprite_ClearLinkTable

Obj_StarBonus_Return:  ; was: locret_16586
                rts

Bonus_StarScoreTable: dc.l    $100, $200, $300, $400, $500, $800, $1000, $2000, $3000  ; was: dword_16588
StarBonus_AnimPointers: dc.b    0, 1  ; was: byte_165AC
                dc.w    StarBonus_AnimSpin-Sys_GameEntryPoint
StarBonus_AnimSpin: dc.b    4, 5  ; was: byte_165B0
                dc.w    StarBonus_SpinFrame0-Sys_GameEntryPoint
                dc.w    StarBonus_SpinFrame1-Sys_GameEntryPoint
                dc.w    StarBonus_SpinFrame2-Sys_GameEntryPoint
                dc.w    StarBonus_SpinFrame3-Sys_GameEntryPoint
; Bonus round cat object (outer position)
Obj_BonusCatOuter:
                bset    #7,(a0)  ; was: sub_165BA
                bne.s   Obj_BonusCatOuter_Update
                move.w  #$140,$30(a0)
                bclr    #7,2(a0)
                tst.b   $16(a0)
                beq.s   Obj_BonusCatOuter_SetPosition
                move.w  #$C0,$30(a0)
                bset    #7,2(a0)

Obj_BonusCatOuter_SetPosition:  ; was: loc_165DE
                move.w  #$150,$24(a0)
                move.l  #BonusCat_AnimPointers,8(a0)
                clr.w   6(a0)

Obj_BonusCatOuter_Update:  ; was: loc_165F0
                tst.b   (byte_FFD27B).w
                bne.s   Obj_BonusCatOuter_Return
                bsr.w   Object_UpdatePosition
                bsr.w   Anim_UpdateFrame

Obj_BonusCatOuter_Return:  ; was: locret_165FE
                rts

; Bonus round cat object (inner position)
Obj_BonusCatInner:
                bset    #7,(a0)  ; was: sub_16600
                bne.s   Obj_BonusCatInner_Update
                move.w  #$130,$30(a0)
                bclr    #7,2(a0)
                tst.b   $16(a0)
                beq.s   Obj_BonusCatInner_SetPosition
                move.w  #$D0,$30(a0)
                bset    #7,2(a0)

Obj_BonusCatInner_SetPosition:  ; was: loc_16624
                move.w  #$150,$24(a0)
                move.l  #BonusCat_AnimPointers,8(a0)
                move.w  #4,6(a0)

Obj_BonusCatInner_Update:  ; was: loc_16638
                tst.b   (byte_FFD27B).w
                bne.s   Obj_BonusCatInner_Return
                bsr.w   Object_UpdatePosition
                bsr.w   Anim_UpdateFrame

Obj_BonusCatInner_Return:  ; was: locret_16646
                rts

; Bonus round held chick follows player
Obj_BonusHeldChick:
                lea     (unk_FFC580).w,a1  ; was: sub_16648
                move.l  dword_FFC5B0-unk_FFC580(a1),d7
                move.l  $24(a1),d6
                move.l  d7,$30(a0)
                move.l  d6,$24(a0)
                addi.w  #$A,$24(a0)
                tst.b   $39(a1)
                beq.s   Obj_BonusHeldChick_FacingLeft
                bclr    #7,2(a0)
                subq.w  #8,$30(a0)
                bra.s   Obj_BonusHeldChick_Update

Obj_BonusHeldChick_FacingLeft:  ; was: loc_16674
                bset    #7,2(a0)
                addq.w  #8,$30(a0)

Obj_BonusHeldChick_Update:  ; was: loc_1667E
                bsr.w   Object_UpdatePosition
                move.l  #Obj_BonusHeldChick_UpdateData0,$C(a0)
                tst.l   $34(a1)
                beq.s   Obj_BonusHeldChick_Return
                move.l  #Obj_BonusHeldChick_UpdateData1,$C(a0)

Obj_BonusHeldChick_Return:  ; was: locret_16698
                rts

BonusCat_AnimPointers: dc.l    BonusCat_AnimOuter  ; was: off_1669A
                dc.l    BonusCat_AnimInner
BonusCat_AnimOuter: dc.b    8, 7  ; was: byte_166A2
                dc.w    BonusCat_OuterFrame0-Sys_GameEntryPoint
                dc.w    BonusCat_OuterFrame1-Sys_GameEntryPoint
                dc.w    BonusCat_OuterFrame2-Sys_GameEntryPoint
                dc.w    BonusCat_OuterFrame3-Sys_GameEntryPoint
                dc.w    BonusCat_OuterFrame4-Sys_GameEntryPoint
                dc.w    BonusCat_OuterFrame3-Sys_GameEntryPoint
                dc.w    BonusCat_OuterFrame2-Sys_GameEntryPoint
                dc.w    BonusCat_OuterFrame1-Sys_GameEntryPoint
BonusCat_AnimInner: dc.b    8, 7  ; was: byte_166B4
                dc.w    BonusCat_InnerFrame0-Sys_GameEntryPoint
                dc.w    BonusCat_InnerFrame1-Sys_GameEntryPoint
                dc.w    BonusCat_InnerFrame2-Sys_GameEntryPoint
                dc.w    BonusCat_InnerFrame3-Sys_GameEntryPoint
                dc.w    BonusCat_InnerFrame4-Sys_GameEntryPoint
                dc.w    BonusCat_InnerFrame3-Sys_GameEntryPoint
                dc.w    BonusCat_InnerFrame2-Sys_GameEntryPoint
                dc.w    BonusCat_InnerFrame1-Sys_GameEntryPoint
; Bonus round thrown chick object
Obj_BonusChick:
                bset    #7,(a0)  ; was: sub_166C6
                bne.s   Obj_BonusChick_Dispatch
                bset    #1,2(a0)
                move.l  #Cat_AnimPointers,8(a0)
                movea.l (dword_FFD282).w,a1
                moveq   #0,d0
                move.b  $38(a0),d0
                lsl.w   #1,d0
                move.w  (a1,d0.w),$3A(a0)

Obj_BonusChick_Dispatch:  ; was: loc_166EC
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     BonusChick_StateTable(pc,d0.w)
                bsr.w   Anim_UpdateFrame
                rts

BonusChick_StateTable:  ; was: loc_166FC
                bra.w   BonusChick_StateWait
                bra.w   BonusChick_StateFly
                bra.w   BonusChick_StateFall

; Bonus chick state: waiting to be thrown
BonusChick_StateWait:
                tst.w   $3A(a0)  ; was: sub_16708
                bne.s   BonusChick_StateWait_Countdown
                bset    #7,$3C(a0)
                bne.s   BonusChick_StateWait_Move
                bclr    #1,2(a0)
                move.w  #4,6(a0)
                move.w  #$150,$24(a0)
                move.w  #$80,$30(a0)
                move.l  #$8000,$34(a0)
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   BonusChick_StateWait_Move
                move.w  #$17F,$30(a0)
                move.l  #$FFFF8000,$34(a0)
                bset    #7,2(a0)

BonusChick_StateWait_Move:  ; was: loc_16756
                bsr.w   Object_UpdatePosition
                lea     (unk_FFC640).w,a1
                tst.b   $39(a0)
                bne.s   BonusChick_StateWait_CheckCat
                lea     $40(a1),a1

BonusChick_StateWait_CheckCat:  ; was: loc_16768
                bsr.w   Collision_CheckObjectPair
                tst.b   d0
                beq.s   BonusChick_StateWait_Return
                move.w  #4,$3C(a0)

BonusChick_StateWait_Return:  ; was: locret_16776
                rts

BonusChick_StateWait_Countdown:  ; was: loc_16778
                subq.w  #1,$3A(a0)
                bsr.w   Object_UpdatePosition
                rts

; Bonus chick state: flying through air
BonusChick_StateFly:
                bset    #7,$3C(a0)  ; was: sub_16782
                bne.s   BonusChick_StateFly_Move
                movea.l (dword_FFD286).w,a1
                moveq   #0,d0
                move.b  $38(a0),d0
                lsl.w   #1,d0
                move.b  (a1,d0.w),d7
                move.b  1(a1,d0.w),d6
                ext.w   d7
                ext.l   d7
                ext.w   d6
                ext.l   d6
                moveq   #$C,d0
                lsl.l   d0,d7
                lsl.l   d0,d6
                move.l  d7,$34(a0)
                move.l  d6,$2C(a0)
                bsr.w   BonusChick_LoadTraj

BonusChick_StateFly_Move:  ; was: loc_167B8
                addi.l  #$1000,$2C(a0)
                bne.s   BonusChick_StateFly_Update
                move.w  #8,$3C(a0)

BonusChick_StateFly_Update:  ; was: loc_167C8
                bsr.w   BonusChick_UpdateTraj
                bsr.w   Object_UpdatePosition
                bsr.w   Anim_UpdateFrame
                rts

; Bonus chick state: falling/bouncing
BonusChick_StateFall:
                bset    #7,$3C(a0)  ; was: sub_167D6
                bne.s   BonusChick_StateFall_ApplyGravity
                clr.w   6(a0)
                move.l  $34(a0),d7
                bpl.s   BonusChick_StateFall_HalveRight
                neg.l   d7
                lsr.l   #1,d7
                neg.l   d7
                bra.s   BonusChick_StateFall_StoreSpeed

BonusChick_StateFall_HalveRight:  ; was: loc_167F0
                lsr.l   #1,d7

BonusChick_StateFall_StoreSpeed:  ; was: loc_167F2
                move.l  d7,$34(a0)
                cmpi.w  #$FFFF,$3A(a0)
                beq.s   BonusChick_StateFall_ApplyGravity
                addq.b  #1,$3E(a0)
                bsr.w   BonusChick_LoadTraj

BonusChick_StateFall_ApplyGravity:  ; was: loc_16806
                cmpi.l  #$18000,$2C(a0)
                bgt.s   BonusChick_StateFall_Move
                addi.l  #$400,$2C(a0)

BonusChick_StateFall_Move:  ; was: loc_16818
                bsr.w   BonusChick_UpdateTraj
                bsr.w   Object_UpdatePosition
                bsr.w   BonusChick_CheckCatch
                cmpi.w  #$180,$24(a0)
                bcs.s   BonusChick_StateFall_Animate
                bsr.w   Object_ClearSlot
                subq.b  #1,(byte_FFD883).w

BonusChick_StateFall_Animate:  ; was: loc_16834
                bsr.w   Anim_UpdateFrame
                tst.b   (byte_FFD883).w
                bne.s   BonusChick_StateFall_Return
                clr.w   (word_FFFF92).w
                move.b  #1,(byte_FFD281).w
                move.w  #4,(word_FFD2A6).w
                bsr.w   Bonus_CalcScore

BonusChick_StateFall_Return:  ; was: locret_16852
                rts

; Bonus chick trajectory curve update
BonusChick_UpdateTraj:
                move.w  $3A(a0),d0  ; was: sub_16854
                cmpi.w  #$FFFF,d0
                beq.s   BonusChick_UpdateTraj_Return
                subq.w  #1,d0
                bne.s   BonusChick_UpdateTraj_Step
                addq.b  #1,$3E(a0)
                bsr.w   BonusChick_LoadTraj
                bra.s   BonusChick_UpdateTraj

BonusChick_UpdateTraj_Step:  ; was: loc_1686C
                move.w  d0,$3A(a0)
                move.l  $34(a0),d7
                move.l  $1C(a0),d6
                bmi.s   BonusChick_UpdateTraj_Negative
                cmp.l   d6,d7
                bge.s   BonusChick_UpdateTraj_PositiveDone
                add.l   $18(a0),d7

BonusChick_UpdateTraj_PositiveDone:  ; was: loc_16882
                bra.s   BonusChick_UpdateTraj_Store

BonusChick_UpdateTraj_Negative:  ; was: loc_16884
                cmp.l   d6,d7
                ble.s   BonusChick_UpdateTraj_Store
                add.l   $18(a0),d7

BonusChick_UpdateTraj_Store:  ; was: loc_1688C
                move.l  d7,$34(a0)

BonusChick_UpdateTraj_Return:  ; was: locret_16890
                rts

; Bonus chick loads trajectory from tables
BonusChick_LoadTraj:
                moveq   #0,d0  ; was: sub_16892
                move.b  $38(a0),d0
                movea.l (dword_FFD28A).w,a1
                move.b  (a1,d0.w),d0
                lsl.w   #2,d0
                lea     Bonus_TrajectoryPointers(pc),a1
                movea.l (a1,d0.w),a1
                moveq   #0,d0
                move.b  $3E(a0),d0
                lsl.w   #2,d0
                move.w  (a1,d0.w),$3A(a0)
                move.b  2(a1,d0.w),d7
                move.b  3(a1,d0.w),d6
                ext.w   d7
                ext.l   d7
                ext.w   d6
                ext.l   d6
                lsl.l   #8,d7
                moveq   #$C,d0
                lsl.l   d0,d6
                tst.b   $39(a0)
                beq.s   BonusChick_LoadTraj_Store
                neg.l   d7
                neg.l   d6

BonusChick_LoadTraj_Store:  ; was: loc_168D8
                move.l  d7,$18(a0)
                move.l  d6,$1C(a0)
                rts

; Bonus chick collision catch detection
BonusChick_CheckCatch:
                lea     (word_FFC040).w,a1  ; was: sub_168E2
                bsr.w   Collision_CheckObjectPair
                tst.b   d0
                beq.s   BonusChick_CheckCatch_Return
                move.l  a0,-(sp)
                move.b  #$90,d0
                bsr.w   Sound_PlayNoteIfActive
                movea.l (sp)+,a0
                bsr.w   Object_ClearSlot
                subq.b  #1,(byte_FFD883).w
                addq.b  #1,(byte_FFD28E).w
                moveq   #1,d0
                move.b  (byte_FFD28F).w,d1
                addi.b  #0,d1
                abcd    d0,d1
                move.b  d1,(byte_FFD28F).w
                bsr.w   Bonus_DrawCaughtCount

BonusChick_CheckCatch_Return:  ; was: locret_1691A
                rts

; Draws bonus round result text labels
Bonus_DrawResultLabels:
                tst.b   (byte_FFD28E).w  ; was: sub_1691C
                beq.s   Bonus_DrawResultLabels_NoBonus
                lea     Bonus_PtsPerChickLabel(pc),a6
                bsr.w   Text_DrawString
                cmpi.b  #$14,(byte_FFD28E).w
                bne.s   Bonus_DrawResultLabels_Return
                lea     Bonus_PerfectLabel(pc),a6
                bsr.w   Text_DrawString
                lea     Bonus_PtsLabel(pc),a6
                bsr.w   Text_DrawString

Bonus_DrawResultLabels_Return:  ; was: locret_16942
                rts

Bonus_DrawResultLabels_NoBonus:  ; was: loc_16944
                lea     Bonus_NoBonusLabel(pc),a6
                bra.w   Text_DrawString

Bonus_PtsPerChickLabel: dc.b    $C2, $4E  ; was: byte_1694C
a250PtsPts:     dc.b    "; 250 PTS.=      PTS.",0
Bonus_PerfectLabel: dc.b    $C3, $12  ; was: byte_16964
aPerfectBonus:  dc.b    "PERFECT BONUS",0
Bonus_PtsLabel: dc.b    $C3, $A2  ; was: byte_16974
aPts_0:         dc.b    "PTS.",0
                dc.b    0
Bonus_NoBonusLabel: dc.b    $C3, $16  ; was: byte_1697C
aNoBonus_0:     dc.b    "NO BONUS",0
                dc.b    0
; Calculates bonus round score total
Bonus_CalcScore:
                moveq   #0,d0  ; was: sub_16988
                move.b  (byte_FFD28E).w,d0
                beq.s   Bonus_CalcScore_Return
                subq.w  #1,d0

Bonus_CalcScore_OuterLoop:  ; was: loc_16992
                move.l  #$250,(dword_FFD262).w
                lea     (byte_FFD266).w,a2
                lea     (word_FFD294).w,a1
                moveq   #3,d1
                move    #4,ccr

Bonus_CalcScore_InnerLoop:  ; was: loc_169A8
                abcd    -(a2),-(a1)
                dbf     d1,Bonus_CalcScore_InnerLoop
                dbf     d0,Bonus_CalcScore_OuterLoop
                move.l  (dword_FFD290).w,d0
                move.l  d0,(dword_FFD262).w
                bsr.w   Score_AddAndCheck
                cmpi.b  #$14,(byte_FFD28E).w
                bne.s   Bonus_CalcScore_Return
                move.l  #$10000,(dword_FFD262).w
                bsr.w   Score_AddAndCheck

Bonus_CalcScore_Return:  ; was: locret_169D2
                rts

; Draws caught chick count tiles in bonus round
Bonus_DrawCaughtCount:
                moveq   #0,d0  ; was: sub_169D4
                move.b  (byte_FFD28E).w,d0
                subq.w  #1,d0
                move.l  #$414C0003,(VDP_CTRL).l

Bonus_DrawCaughtCount_Loop:  ; was: loc_169E6
                move.w  #$E351,(VDP_DATA).l
                dbf     d0,Bonus_DrawCaughtCount_Loop
                rts

Bonus_ChickDelayPointers: dc.l    Bonus_ChickDelays0  ; was: off_169F4
                dc.l    Bonus_ChickDelays0
                dc.l    Bonus_ChickDelays0
                dc.l    Bonus_ChickDelays1
                dc.l    Bonus_ChickDelays2
                dc.l    Bonus_ChickDelays2
                dc.l    Bonus_ChickDelays2
                dc.l    Bonus_ChickDelays2
                dc.l    Bonus_ChickDelays2
                dc.l    Bonus_ChickDelays2
                dc.l    Bonus_ChickDelays2
                dc.l    Bonus_ChickDelays2
Bonus_ChickDelays0: dc.w    0, $F, $1E, $2D, $6E, $7D, $8C, $9B, $DC, $EB  ; was: word_16A24
                dc.w    $FA, $109, $14A, $159, $168, $177, $1B8, $1C7, $1D6, $1E5
Bonus_ChickDelays1: dc.w    $1E, $2D, $3C, $4B, 0, $F, $1E, $2D, $FA, $109  ; was: word_16A4C
                dc.w    $118, $127, $DC, $EB, $FA, $109, $1B8, $1C7, $1D6, $1E5
Bonus_ChickDelays2: dc.w    0, $F, $1E, $2D, $64, $73, $82, $91, $C8, $D7  ; was: word_16A74
                dc.w    $E6, $F5, $12C, $13B, $14A, $159, $190, $19F, $1AE, $1BD
Bonus_ChickVelocityPointers: dc.l    Bonus_ChickVelocities0  ; was: off_16A9C
                dc.l    Bonus_ChickVelocities1
                dc.l    Bonus_ChickVelocities2
                dc.l    Bonus_ChickVelocities3
                dc.l    Bonus_ChickVelocities4
                dc.l    Bonus_ChickVelocities5
                dc.l    Bonus_ChickVelocities6
                dc.l    Bonus_ChickVelocities5
                dc.l    Bonus_ChickVelocities0
                dc.l    Bonus_ChickVelocities7
                dc.l    Bonus_ChickVelocities8
                dc.l    Bonus_ChickVelocities5
Bonus_ChickVelocities0: dc.w    $EB4, $EB4, $EB4, $EB4, $F2B4, $F2B4, $F2B4, $F2B4, $EB4, $EB4  ; was: word_16ACC
                dc.w    $EB4, $EB4, $F2B4, $F2B4, $F2B4, $F2B4, $EB4, $EB4, $EB4, $EB4
Bonus_ChickVelocities1: dc.w    $EB4, $CB4, $AB4, $8B4, $F2B4, $F4B4, $F6B4, $F8B4, $EB4, $CB4  ; was: word_16AF4
                dc.w    $AB4, $8B4, $F2B4, $F4B4, $F6B4, $F8B4, $EB4, $CB4, $AB4, $8B4
Bonus_ChickVelocities2: dc.w    $EB4, $EB8, $EBC, $EC0, $F2B4, $F2B8, $F2BC, $F2C0, $EB4, $EB8  ; was: word_16B1C
                dc.w    $EBC, $EC0, $F2B4, $F2B8, $F2BC, $F2C0, $EB4, $EB8, $EBC, $EC0
Bonus_ChickVelocities3: dc.w    $AB4, $AB4, $AB4, $AB4, $F6B4, $F6B4, $F6B4, $F6B4, $AB4, $AB4  ; was: word_16B44
                dc.w    $AB4, $AB4, $F6B4, $F6B4, $F6B4, $F6B4, $5B4, $8B4, $BB4, $EB4
Bonus_ChickVelocities4: dc.w    $22B4, $22B4, $22B4, $22B4, $DEB4, $DEB4, $DEB4, $DEB4, $22B4, $22B4  ; was: word_16B6C
                dc.w    $22B4, $22B4, $DEB4, $DEB4, $DEB4, $DEB4, $22B4, $22B4, $22B4, $22B4
Bonus_ChickVelocities5: dc.w    $9B4, $9B4, $9B4, $9B4, $F7B4, $F7B4, $F7B4, $F7B4, $9B4, $9B4  ; was: word_16B94
                dc.w    $9B4, $9B4, $F7B4, $F7B4, $F7B4, $F7B4, $9B4, $9B4, $9B4, $9B4
Bonus_ChickVelocities6: dc.w    $12B4, $12B4, $12B4, $12B4, $EEB4, $EEB4, $EEB4, $EEB4, $12B4, $12B4  ; was: word_16BBC
                dc.w    $12B4, $12B4, $EEB4, $EEB4, $EEB4, $EEB4, $12B4, $12B4, $12B4, $12B4
Bonus_ChickVelocities7: dc.w    $E0B4, $E0B4, $E0B4, $E0B4, $20B4, $20B4, $20B4, $20B4, $E0B4, $E0B4  ; was: word_16BE4
                dc.w    $E0B4, $E0B4, $20B4, $20B4, $20B4, $20B4, $E0B4, $E0B4, $E0B4, $E0B4
Bonus_ChickVelocities8: dc.w    $40B4, $40B4, $40B4, $40B4, $C0B4, $C0B4, $C0B4, $C0B4, $40B4, $40B4  ; was: word_16C0C
                dc.w    $40B4, $40B4, $C0B4, $C0B4, $C0B4, $C0B4, $40B4, $40B4, $40B4, $40B4
Bonus_ChickTrajIndexPointers: dc.l    Bonus_ChickTrajIndex0  ; was: off_16C34
                dc.l    Bonus_ChickTrajIndex0
                dc.l    Bonus_ChickTrajIndex0
                dc.l    Bonus_ChickTrajIndex0
                dc.l    Bonus_ChickTrajIndex1
                dc.l    Bonus_ChickTrajIndex2
                dc.l    Bonus_ChickTrajIndex3
                dc.l    Bonus_ChickTrajIndex4
                dc.l    Bonus_ChickTrajIndex5
                dc.l    Bonus_ChickTrajIndex6
                dc.l    Bonus_ChickTrajIndex7
                dc.l    Bonus_ChickTrajIndex8
Bonus_ChickTrajIndex0: dc.w    0, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; was: word_16C64
Bonus_ChickTrajIndex1: dc.w    $101, $101, $101, $101, $101, $101, $101, $101, $101, $101  ; was: word_16C78
Bonus_ChickTrajIndex2: dc.w    $202, $202, $202, $202, $202, $202, $202, $202, $202, $202  ; was: word_16C8C
Bonus_ChickTrajIndex3: dc.w    $303, $303, $303, $303, $303, $303, $303, $303, $303, $303  ; was: word_16CA0
Bonus_ChickTrajIndex4: dc.w    $404, $404, $404, $404, $404, $404, $404, $404, $404, $404  ; was: word_16CB4
Bonus_ChickTrajIndex5: dc.w    $505, $505, $505, $505, $505, $505, $505, $505, $505, $505  ; was: word_16CC8
Bonus_ChickTrajIndex6: dc.w    $606, $606, $606, $606, $606, $606, $606, $606, $606, $606  ; was: word_16CDC
Bonus_ChickTrajIndex7: dc.w    $707, $707, $707, $707, $707, $707, $707, $707, $707, $707  ; was: word_16CF0
Bonus_ChickTrajIndex8: dc.w    $808, $808, $808, $808, $808, $808, $808, $808, $808, $808  ; was: word_16D04
Bonus_TrajectoryPointers: dc.l    Bonus_Trajectory0  ; was: off_16D18
                dc.l    Bonus_Trajectory1
                dc.l    Bonus_Trajectory2
                dc.l    Bonus_Trajectory3
                dc.l    Bonus_Trajectory4
                dc.l    Bonus_Trajectory5
                dc.l    Bonus_Trajectory6
                dc.l    Bonus_Trajectory7
                dc.l    Bonus_Trajectory8
Bonus_Trajectory0: dc.w    $FFFF  ; was: word_16D3C
Bonus_Trajectory1: dc.w    $12C, $F4E8, $12C, $310, $FFFF  ; was: word_16D3E
Bonus_Trajectory2: dc.w    $12C, $FEF8, $14, $C10, $40, $FAF0, $12C, $610, $FFFF  ; was: word_16D48
Bonus_Trajectory3: dc.w    $12C, 0, $58, 0, $12C, $C0DE, $FFFF  ; was: word_16D5A
Bonus_Trajectory4: dc.w    $12C, $FEF8, $30, $1220, $3A, $EEE0, $12C, $620, $FFFF  ; was: word_16D68
Bonus_Trajectory5: dc.w    $12C, 0, $32, 0, $18, $E4E0, $12C, $1C0C, $FFFF  ; was: word_16D7A
Bonus_Trajectory6: dc.w    $12C, $D1C, $FFFF  ; was: word_16D8C
Bonus_Trajectory7: dc.w    $12C, $F2E0, $28, $FCE0, $12C, $320, $FFFF  ; was: word_16D92
Bonus_Trajectory8: dc.w    $12C, $FEF8, $12C, $320, $FFFF  ; was: word_16DA0
; Game over text display object
