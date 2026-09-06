; Bonus-round objects
; ROM $0164EC-$016DA9

Obj_StarBonus:
                bset    #7,(a0)
                bne.s   Obj_StarBonus_Update
                clr.b   5(a0)
                clr.l   $34(a0)
                clr.l   $2C(a0)
                addq.w  #7,$24(a0)
                move.l  #StarBonus_AnimPointers,8(a0)
                clr.w   6(a0)
                move.w  #$12C,$38(a0)
                bclr    #7,2(a0)

Obj_StarBonus_Update:
                bsr.w   Object_UpdatePosition
                bsr.w   Anim_UpdateFrame
                lea     (Ram_PlayerObject).w,a1
                bsr.w   Collision_CheckObjectPair
                tst.b   d0
                beq.s   Obj_StarBonus_Countdown
                move.l  a0,-(sp)
                move.b  #$98,d0
                bsr.w   Sound_PlayNoteIfActive
                movea.l (sp)+,a0
                lea     (Ram_PopupSlots).w,a2
                moveq   #3,d0

Obj_StarBonus_PopupLoop:
                tst.w   (a2)
                bne.s   Obj_StarBonus_PopupNext
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                move.w  d7,$30(a2)
                subq.w  #8,d6
                move.w  d6,$24(a2)
                moveq   #0,d7
                move.b  (Ram_ChickChainCount).w,d7
                move.b  d7,$3A(a2)
                move.w  #$24,(a2)
                lsl.w   #2,d7
                move.l  Bonus_StarScoreTable(pc,d7.w),d7
                move.l  d7,(Ram_ScoreDelta).w
                bsr.w   Score_AddAndCheck
                bra.s   Obj_StarBonus_Despawn

Obj_StarBonus_PopupNext:
                lea     -$40(a2),a2
                dbf     d0,Obj_StarBonus_PopupLoop

Obj_StarBonus_Countdown:
                subq.w  #1,$38(a0)
                bne.s   Obj_StarBonus_Return

Obj_StarBonus_Despawn:
                bsr.w   Sprite_ClearLinkTable

Obj_StarBonus_Return:
                rts

Bonus_StarScoreTable:   dc.l    $100, $200, $300, $400, $500, $800, $1000, $2000, $3000
StarBonus_AnimPointers: dc.b    0, 1
                dc.w    StarBonus_AnimSpin-Sys_GameEntryPoint
StarBonus_AnimSpin: dc.b    4, 5
                dc.w    StarBonus_SpinFrame0-Sys_GameEntryPoint
                dc.w    StarBonus_SpinFrame1-Sys_GameEntryPoint
                dc.w    StarBonus_SpinFrame2-Sys_GameEntryPoint
                dc.w    StarBonus_SpinFrame3-Sys_GameEntryPoint
; Bonus round cat object (outer position)
Obj_BonusCatOuter:
                bset    #7,(a0)
                bne.s   Obj_BonusCatOuter_Update
                move.w  #$140,$30(a0)
                bclr    #7,2(a0)
                tst.b   $16(a0)
                beq.s   Obj_BonusCatOuter_SetPosition
                move.w  #$C0,$30(a0)
                bset    #7,2(a0)

Obj_BonusCatOuter_SetPosition:
                move.w  #$150,$24(a0)
                move.l  #BonusCat_AnimPointers,8(a0)
                clr.w   6(a0)

Obj_BonusCatOuter_Update:
                tst.b   (Ram_CutsceneFlag).w
                bne.s   Obj_BonusCatOuter_Return
                bsr.w   Object_UpdatePosition
                bsr.w   Anim_UpdateFrame

Obj_BonusCatOuter_Return:
                rts

; Bonus round cat object (inner position)
Obj_BonusCatInner:
                bset    #7,(a0)
                bne.s   Obj_BonusCatInner_Update
                move.w  #$130,$30(a0)
                bclr    #7,2(a0)
                tst.b   $16(a0)
                beq.s   Obj_BonusCatInner_SetPosition
                move.w  #$D0,$30(a0)
                bset    #7,2(a0)

Obj_BonusCatInner_SetPosition:
                move.w  #$150,$24(a0)
                move.l  #BonusCat_AnimPointers,8(a0)
                move.w  #4,6(a0)

Obj_BonusCatInner_Update:
                tst.b   (Ram_CutsceneFlag).w
                bne.s   Obj_BonusCatInner_Return
                bsr.w   Object_UpdatePosition
                bsr.w   Anim_UpdateFrame

Obj_BonusCatInner_Return:
                rts

; Bonus round held chick follows player
Obj_BonusHeldChick:
                lea     (Ram_BonusPlayerObject).w,a1
                move.l  Ram_BonusPlayerWorldX-Ram_BonusPlayerObject(a1),d7
                move.l  $24(a1),d6
                move.l  d7,$30(a0)
                move.l  d6,$24(a0)
                addi.w  #$A,$24(a0)
                tst.b   $39(a1)
                beq.s   Obj_BonusHeldChick_FacingLeft
                bclr    #7,2(a0)
                subq.w  #8,$30(a0)
                bra.s   Obj_BonusHeldChick_Update

Obj_BonusHeldChick_FacingLeft:
                bset    #7,2(a0)
                addq.w  #8,$30(a0)

Obj_BonusHeldChick_Update:
                bsr.w   Object_UpdatePosition
                move.l  #Obj_BonusHeldChick_UpdateData0,$C(a0)
                tst.l   $34(a1)
                beq.s   Obj_BonusHeldChick_Return
                move.l  #Obj_BonusHeldChick_UpdateData1,$C(a0)

Obj_BonusHeldChick_Return:
                rts

BonusCat_AnimPointers:  dc.l    BonusCat_AnimOuter
                dc.l    BonusCat_AnimInner
BonusCat_AnimOuter: dc.b    8, 7
                dc.w    BonusCat_OuterFrame0-Sys_GameEntryPoint
                dc.w    BonusCat_OuterFrame1-Sys_GameEntryPoint
                dc.w    BonusCat_OuterFrame2-Sys_GameEntryPoint
                dc.w    BonusCat_OuterFrame3-Sys_GameEntryPoint
                dc.w    BonusCat_OuterFrame4-Sys_GameEntryPoint
                dc.w    BonusCat_OuterFrame3-Sys_GameEntryPoint
                dc.w    BonusCat_OuterFrame2-Sys_GameEntryPoint
                dc.w    BonusCat_OuterFrame1-Sys_GameEntryPoint
BonusCat_AnimInner: dc.b    8, 7
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
                bset    #7,(a0)
                bne.s   Obj_BonusChick_Dispatch
                bset    #1,2(a0)
                move.l  #Cat_AnimPointers,8(a0)
                movea.l (Ram_BonusChickDelayPtr).w,a1
                moveq   #0,d0
                move.b  $38(a0),d0
                lsl.w   #1,d0
                move.w  (a1,d0.w),$3A(a0)

Obj_BonusChick_Dispatch:
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     BonusChick_StateTable(pc,d0.w)
                bsr.w   Anim_UpdateFrame
                rts

BonusChick_StateTable:
                bra.w   BonusChick_StateWait
                bra.w   BonusChick_StateFly
                bra.w   BonusChick_StateFall

; Bonus chick state: waiting to be thrown
BonusChick_StateWait:
                tst.w   $3A(a0)
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

BonusChick_StateWait_Move:
                bsr.w   Object_UpdatePosition
                lea     (Ram_BonusCatOuterSlots).w,a1
                tst.b   $39(a0)
                bne.s   BonusChick_StateWait_CheckCat
                lea     $40(a1),a1

BonusChick_StateWait_CheckCat:
                bsr.w   Collision_CheckObjectPair
                tst.b   d0
                beq.s   BonusChick_StateWait_Return
                move.w  #4,$3C(a0)

BonusChick_StateWait_Return:
                rts

BonusChick_StateWait_Countdown:
                subq.w  #1,$3A(a0)
                bsr.w   Object_UpdatePosition
                rts

; Bonus chick state: flying through air
BonusChick_StateFly:
                bset    #7,$3C(a0)
                bne.s   BonusChick_StateFly_Move
                movea.l (Ram_BonusChickVelocityPtr).w,a1
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

BonusChick_StateFly_Move:
                addi.l  #$1000,$2C(a0)
                bne.s   BonusChick_StateFly_Update
                move.w  #8,$3C(a0)

BonusChick_StateFly_Update:
                bsr.w   BonusChick_UpdateTraj
                bsr.w   Object_UpdatePosition
                bsr.w   Anim_UpdateFrame
                rts

; Bonus chick state: falling/bouncing
BonusChick_StateFall:
                bset    #7,$3C(a0)
                bne.s   BonusChick_StateFall_ApplyGravity
                clr.w   6(a0)
                move.l  $34(a0),d7
                bpl.s   BonusChick_StateFall_HalveRight
                neg.l   d7
                lsr.l   #1,d7
                neg.l   d7
                bra.s   BonusChick_StateFall_StoreSpeed

BonusChick_StateFall_HalveRight:
                lsr.l   #1,d7

BonusChick_StateFall_StoreSpeed:
                move.l  d7,$34(a0)
                cmpi.w  #$FFFF,$3A(a0)
                beq.s   BonusChick_StateFall_ApplyGravity
                addq.b  #1,$3E(a0)
                bsr.w   BonusChick_LoadTraj

BonusChick_StateFall_ApplyGravity:
                cmpi.l  #$18000,$2C(a0)
                bgt.s   BonusChick_StateFall_Move
                addi.l  #$400,$2C(a0)

BonusChick_StateFall_Move:
                bsr.w   BonusChick_UpdateTraj
                bsr.w   Object_UpdatePosition
                bsr.w   BonusChick_CheckCatch
                cmpi.w  #$180,$24(a0)
                bcs.s   BonusChick_StateFall_Animate
                bsr.w   Object_ClearSlot
                subq.b  #1,(Ram_ChicksRemaining).w

BonusChick_StateFall_Animate:
                bsr.w   Anim_UpdateFrame
                tst.b   (Ram_ChicksRemaining).w
                bne.s   BonusChick_StateFall_Return
                clr.w   (Ram_FrameCounter).w
                move.b  #1,(Ram_RoundClearFlag).w
                move.w  #4,(Ram_BonusState).w
                bsr.w   Bonus_CalcScore

BonusChick_StateFall_Return:
                rts

; Bonus chick trajectory curve update
BonusChick_UpdateTraj:
                move.w  $3A(a0),d0
                cmpi.w  #$FFFF,d0
                beq.s   BonusChick_UpdateTraj_Return
                subq.w  #1,d0
                bne.s   BonusChick_UpdateTraj_Step
                addq.b  #1,$3E(a0)
                bsr.w   BonusChick_LoadTraj
                bra.s   BonusChick_UpdateTraj

BonusChick_UpdateTraj_Step:
                move.w  d0,$3A(a0)
                move.l  $34(a0),d7
                move.l  $1C(a0),d6
                bmi.s   BonusChick_UpdateTraj_Negative
                cmp.l   d6,d7
                bge.s   BonusChick_UpdateTraj_PositiveDone
                add.l   $18(a0),d7

BonusChick_UpdateTraj_PositiveDone:
                bra.s   BonusChick_UpdateTraj_Store

BonusChick_UpdateTraj_Negative:
                cmp.l   d6,d7
                ble.s   BonusChick_UpdateTraj_Store
                add.l   $18(a0),d7

BonusChick_UpdateTraj_Store:
                move.l  d7,$34(a0)

BonusChick_UpdateTraj_Return:
                rts

; Bonus chick loads trajectory from tables
BonusChick_LoadTraj:
                moveq   #0,d0
                move.b  $38(a0),d0
                movea.l (Ram_BonusChickTrajPtr).w,a1
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

BonusChick_LoadTraj_Store:
                move.l  d7,$18(a0)
                move.l  d6,$1C(a0)
                rts

; Bonus chick collision catch detection
BonusChick_CheckCatch:
                lea     (Ram_Object01).w,a1
                bsr.w   Collision_CheckObjectPair
                tst.b   d0
                beq.s   BonusChick_CheckCatch_Return
                move.l  a0,-(sp)
                move.b  #$90,d0
                bsr.w   Sound_PlayNoteIfActive
                movea.l (sp)+,a0
                bsr.w   Object_ClearSlot
                subq.b  #1,(Ram_ChicksRemaining).w
                addq.b  #1,(Ram_BonusCaughtCount).w
                moveq   #1,d0
                move.b  (Ram_BonusCaughtBCD).w,d1
                addi.b  #0,d1
                abcd    d0,d1
                move.b  d1,(Ram_BonusCaughtBCD).w
                bsr.w   Bonus_DrawCaughtCount

BonusChick_CheckCatch_Return:
                rts

; Draws bonus round result text labels
Bonus_DrawResultLabels:
                tst.b   (Ram_BonusCaughtCount).w
                beq.s   Bonus_DrawResultLabels_NoBonus
                lea     Bonus_PtsPerChickLabel(pc),a6
                bsr.w   Text_DrawString
                cmpi.b  #$14,(Ram_BonusCaughtCount).w
                bne.s   Bonus_DrawResultLabels_Return
                lea     Bonus_PerfectLabel(pc),a6
                bsr.w   Text_DrawString
                lea     Bonus_PtsLabel(pc),a6
                bsr.w   Text_DrawString

Bonus_DrawResultLabels_Return:
                rts

Bonus_DrawResultLabels_NoBonus:
                lea     Bonus_NoBonusLabel(pc),a6
                bra.w   Text_DrawString

Bonus_PtsPerChickLabel: dc.b    $C2, $4E
Bonus_PointsText:       dc.b    "; 250 PTS.=      PTS.",0
Bonus_PerfectLabel:     dc.b    $C3, $12
Bonus_PerfectBonusText: dc.b    "PERFECT BONUS",0
Bonus_PtsLabel:         dc.b    $C3, $A2
Bonus_PtsText:          dc.b    "PTS.",0
                dc.b    0
Bonus_NoBonusLabel: dc.b    $C3, $16
Bonus_NoBonusText:  dc.b    "NO BONUS",0
                dc.b    0
; Calculates bonus round score total
Bonus_CalcScore:
                moveq   #0,d0
                move.b  (Ram_BonusCaughtCount).w,d0
                beq.s   Bonus_CalcScore_Return
                subq.w  #1,d0

Bonus_CalcScore_OuterLoop:
                move.l  #$250,(Ram_ScoreDelta).w
                lea     (Ram_RoundMinutes).w,a2
                lea     (Ram_SpawnerDelay).w,a1
                moveq   #3,d1
                move    #4,ccr

Bonus_CalcScore_InnerLoop:
                abcd    -(a2),-(a1)
                dbf     d1,Bonus_CalcScore_InnerLoop
                dbf     d0,Bonus_CalcScore_OuterLoop
                move.l  (Ram_BonusScore).w,d0
                move.l  d0,(Ram_ScoreDelta).w
                bsr.w   Score_AddAndCheck
                cmpi.b  #$14,(Ram_BonusCaughtCount).w
                bne.s   Bonus_CalcScore_Return
                move.l  #$10000,(Ram_ScoreDelta).w
                bsr.w   Score_AddAndCheck

Bonus_CalcScore_Return:
                rts

; Draws caught chick count tiles in bonus round
Bonus_DrawCaughtCount:
                moveq   #0,d0
                move.b  (Ram_BonusCaughtCount).w,d0
                subq.w  #1,d0
                move.l  #$414C0003,(VDP_CTRL).l

Bonus_DrawCaughtCount_Loop:
                move.w  #$E351,(VDP_DATA).l
                dbf     d0,Bonus_DrawCaughtCount_Loop
                rts

Bonus_ChickDelayPointers:   dc.l    Bonus_ChickDelays0
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
Bonus_ChickDelays0: dc.w    0, $F, $1E, $2D, $6E, $7D, $8C, $9B, $DC, $EB
                dc.w    $FA, $109, $14A, $159, $168, $177, $1B8, $1C7, $1D6, $1E5
Bonus_ChickDelays1: dc.w    $1E, $2D, $3C, $4B, 0, $F, $1E, $2D, $FA, $109
                dc.w    $118, $127, $DC, $EB, $FA, $109, $1B8, $1C7, $1D6, $1E5
Bonus_ChickDelays2: dc.w    0, $F, $1E, $2D, $64, $73, $82, $91, $C8, $D7
                dc.w    $E6, $F5, $12C, $13B, $14A, $159, $190, $19F, $1AE, $1BD
Bonus_ChickVelocityPointers:    dc.l    Bonus_ChickVelocities0
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
Bonus_ChickVelocities0: dc.w    $EB4, $EB4, $EB4, $EB4, $F2B4, $F2B4, $F2B4, $F2B4, $EB4, $EB4
                dc.w    $EB4, $EB4, $F2B4, $F2B4, $F2B4, $F2B4, $EB4, $EB4, $EB4, $EB4
Bonus_ChickVelocities1: dc.w    $EB4, $CB4, $AB4, $8B4, $F2B4, $F4B4, $F6B4, $F8B4, $EB4, $CB4
                dc.w    $AB4, $8B4, $F2B4, $F4B4, $F6B4, $F8B4, $EB4, $CB4, $AB4, $8B4
Bonus_ChickVelocities2: dc.w    $EB4, $EB8, $EBC, $EC0, $F2B4, $F2B8, $F2BC, $F2C0, $EB4, $EB8
                dc.w    $EBC, $EC0, $F2B4, $F2B8, $F2BC, $F2C0, $EB4, $EB8, $EBC, $EC0
Bonus_ChickVelocities3: dc.w    $AB4, $AB4, $AB4, $AB4, $F6B4, $F6B4, $F6B4, $F6B4, $AB4, $AB4
                dc.w    $AB4, $AB4, $F6B4, $F6B4, $F6B4, $F6B4, $5B4, $8B4, $BB4, $EB4
Bonus_ChickVelocities4: dc.w    $22B4, $22B4, $22B4, $22B4, $DEB4, $DEB4, $DEB4, $DEB4, $22B4, $22B4
                dc.w    $22B4, $22B4, $DEB4, $DEB4, $DEB4, $DEB4, $22B4, $22B4, $22B4, $22B4
Bonus_ChickVelocities5: dc.w    $9B4, $9B4, $9B4, $9B4, $F7B4, $F7B4, $F7B4, $F7B4, $9B4, $9B4
                dc.w    $9B4, $9B4, $F7B4, $F7B4, $F7B4, $F7B4, $9B4, $9B4, $9B4, $9B4
Bonus_ChickVelocities6: dc.w    $12B4, $12B4, $12B4, $12B4, $EEB4, $EEB4, $EEB4, $EEB4, $12B4, $12B4
                dc.w    $12B4, $12B4, $EEB4, $EEB4, $EEB4, $EEB4, $12B4, $12B4, $12B4, $12B4
Bonus_ChickVelocities7: dc.w    $E0B4, $E0B4, $E0B4, $E0B4, $20B4, $20B4, $20B4, $20B4, $E0B4, $E0B4
                dc.w    $E0B4, $E0B4, $20B4, $20B4, $20B4, $20B4, $E0B4, $E0B4, $E0B4, $E0B4
Bonus_ChickVelocities8: dc.w    $40B4, $40B4, $40B4, $40B4, $C0B4, $C0B4, $C0B4, $C0B4, $40B4, $40B4
                dc.w    $40B4, $40B4, $C0B4, $C0B4, $C0B4, $C0B4, $40B4, $40B4, $40B4, $40B4
Bonus_ChickTrajIndexPointers:   dc.l    Bonus_ChickTrajIndex0
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
Bonus_ChickTrajIndex0:      dc.w    0, 0, 0, 0, 0, 0, 0, 0, 0, 0
Bonus_ChickTrajIndex1:      dc.w    $101, $101, $101, $101, $101, $101, $101, $101, $101, $101
Bonus_ChickTrajIndex2:      dc.w    $202, $202, $202, $202, $202, $202, $202, $202, $202, $202
Bonus_ChickTrajIndex3:      dc.w    $303, $303, $303, $303, $303, $303, $303, $303, $303, $303
Bonus_ChickTrajIndex4:      dc.w    $404, $404, $404, $404, $404, $404, $404, $404, $404, $404
Bonus_ChickTrajIndex5:      dc.w    $505, $505, $505, $505, $505, $505, $505, $505, $505, $505
Bonus_ChickTrajIndex6:      dc.w    $606, $606, $606, $606, $606, $606, $606, $606, $606, $606
Bonus_ChickTrajIndex7:      dc.w    $707, $707, $707, $707, $707, $707, $707, $707, $707, $707
Bonus_ChickTrajIndex8:      dc.w    $808, $808, $808, $808, $808, $808, $808, $808, $808, $808
Bonus_TrajectoryPointers:   dc.l    Bonus_Trajectory0
                dc.l    Bonus_Trajectory1
                dc.l    Bonus_Trajectory2
                dc.l    Bonus_Trajectory3
                dc.l    Bonus_Trajectory4
                dc.l    Bonus_Trajectory5
                dc.l    Bonus_Trajectory6
                dc.l    Bonus_Trajectory7
                dc.l    Bonus_Trajectory8
Bonus_Trajectory0:  dc.w    $FFFF
Bonus_Trajectory1:  dc.w    $12C, $F4E8, $12C, $310, $FFFF
Bonus_Trajectory2:  dc.w    $12C, $FEF8, $14, $C10, $40, $FAF0, $12C, $610, $FFFF
Bonus_Trajectory3:  dc.w    $12C, 0, $58, 0, $12C, $C0DE, $FFFF
Bonus_Trajectory4:  dc.w    $12C, $FEF8, $30, $1220, $3A, $EEE0, $12C, $620, $FFFF
Bonus_Trajectory5:  dc.w    $12C, 0, $32, 0, $18, $E4E0, $12C, $1C0C, $FFFF
Bonus_Trajectory6:  dc.w    $12C, $D1C, $FFFF
Bonus_Trajectory7:  dc.w    $12C, $F2E0, $28, $FCE0, $12C, $320, $FFFF
Bonus_Trajectory8:  dc.w    $12C, $FEF8, $12C, $320, $FFFF
; Game over text display object
