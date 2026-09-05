; Cat enemy.
; ROM $01483E-$014EC5.

Obj_Cat:
                bset    #7,(a0)  ; was: sub_1483E
                bne.s   Obj_Cat_Dispatch
                move.l  #Cat_AnimPointers,8(a0)
                tst.b   $3A(a0)
                beq.s   Obj_Cat_SetPosition
                move.l  #Cat_AnimPointersAlt,8(a0)

Obj_Cat_SetPosition:  ; was: loc_1485A
                move.b  $3E(a0),d7
                move.b  $3F(a0),d6
                bsr.w   Math_GridToScreen
                addq.w  #8,d7
                addi.w  #$10,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)

Obj_Cat_Dispatch:  ; was: loc_14874
                tst.b   (byte_FFD27B).w
                bne.s   Obj_Cat_Return
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     Cat_StateTable(pc,d0.w)
                move.l  $34(a0),d0
                beq.s   Obj_Cat_Return
                move.b  #1,$39(a0)
                tst.l   d0
                bmi.s   Obj_Cat_Return
                clr.b   $39(a0)

Obj_Cat_Return:  ; was: locret_14898
                rts

Cat_StateTable:  ; was: loc_1489A
                bra.w   Cat_StatePatrol
                bra.w   Cat_StateFollowing
                bra.w   Cat_StateWalking
                bra.w   Cat_StateStunWalk

; Cat state: patrolling and bouncing
Cat_StatePatrol:
                tst.b   (byte_FFD24F).w  ; was: sub_148AA
                bne.s   Cat_StatePatrol_Return
                bset    #7,$3C(a0)
                bne.s   Cat_StatePatrol_Bounce
                move.b  #$30,$3B(a0)
                move.l  #$FFFFE000,$2C(a0)

Cat_StatePatrol_Bounce:  ; was: loc_148C6
                clr.w   6(a0)
                subq.b  #1,$3B(a0)
                bne.s   Cat_StatePatrol_CheckPlayer
                neg.l   $2C(a0)
                move.b  #$30,$3B(a0)

Cat_StatePatrol_CheckPlayer:  ; was: loc_148DA
                lea     (word_FFC440).w,a1
                bsr.w   Collision_CheckObjectPair
                tst.b   d0
                beq.s   Cat_StatePatrol_Animate
                move.l  a0,-(sp)
                move.b  #$90,d0
                bsr.w   Sound_PlayNoteIfActive
                movea.l (sp)+,a0
                move.w  #4,$3C(a0)
                addq.b  #1,(byte_FFD27A).w
                move.b  (byte_FFD27A).w,$38(a0)
                move.l  #$10,(dword_FFD262).w
                bsr.w   Score_AddAndCheck

Cat_StatePatrol_Animate:  ; was: loc_1490E
                bsr.w   Anim_UpdateFrame
                bsr.w   Object_UpdatePosition

Cat_StatePatrol_Return:  ; was: locret_14916
                rts

; Cat state: following rescued chick chain
Cat_StateFollowing:
                bset    #7,$3C(a0)  ; was: sub_14918
                bne.s   Cat_StateFollowing_CheckHit
                clr.l   $34(a0)
                clr.l   $2C(a0)

Cat_StateFollowing_CheckHit:  ; was: loc_14928
                tst.b   (byte_FFD26D).w
                beq.s   Cat_StateFollowing_TrackChain
                clr.b   $38(a0)
                subq.b  #1,(byte_FFD27A).w
                move.w  #8,$3C(a0)
                bra.w   Cat_StateFollowing_Animate

Cat_StateFollowing_TrackChain:  ; was: loc_14940
                moveq   #0,d0
                move.b  $38(a0),d0
                lsl.w   #1,d0
                moveq   #$FFFFFFFF,d1
                lea     Cat_ChainPositionPointers(pc),a1
                move.w  (a1,d0.w),d1
                movea.l d1,a1
                move.l  (a1),$30(a0)
                move.l  4(a1),$24(a0)
                bsr.w   Object_CalcScreenPos
                lea     Cat_ChainDirectionPointers(pc),a1
                move.w  (a1,d0.w),d1
                movea.l d1,a1
                moveq   #0,d1
                move.b  (a1),d1
                move.w  d1,-(sp)
                tst.b   (byte_FFD24F).w
                bne.s   Cat_StateFollowing_CheckDelivery
                bsr.w   Chick_CheckEnemyHit

Cat_StateFollowing_CheckDelivery:  ; was: loc_1497C
                move.w  (sp)+,d1
                tst.b   (byte_FFD24F).w
                beq.s   Cat_StateFollowing_CheckRoundEnd
                lea     (word_FFC440).w,a1
                move.w  dword_FFC470-word_FFC440(a1),d7
                move.w  $24(a1),d6
                cmp.w   $30(a0),d7
                bne.s   Cat_StateFollowing_CheckRoundEnd
                cmp.w   $24(a0),d6
                bne.s   Cat_StateFollowing_CheckRoundEnd
                move.l  a0,-(sp)
                move.b  #$94,d0
                bsr.w   Sound_PlayNoteIfActive
                movea.l (sp)+,a0
                clr.w   (a0)
                bsr.w   Chick_AwardPoints
                subq.b  #1,(byte_FFD883).w
                bne.s   Cat_StateFollowing_DeliverDelay
                move.b  #1,(byte_FFD281).w
                clr.w   (word_FFFF92).w
                move.b  (dword_FFD888).w,(byte_FFD266).w
                move.b  (dword_FFD888+1).w,(byte_FFD267).w
                bsr.w   Score_CalcTimeBonus

Cat_StateFollowing_DeliverDelay:  ; was: loc_149CE
                move.l  a0,-(sp)
                moveq   #2,d1

Cat_StateFollowing_DelayLoop:  ; was: loc_149D2
                jsr     unk_FFFB6C
                dbf     d1,Cat_StateFollowing_DelayLoop
                movea.l (sp)+,a0
                clr.b   $38(a0)
                subq.b  #1,(byte_FFD27A).w
                bne.s   Cat_StateFollowing_CheckRoundEnd
                clr.b   (byte_FFD24F).w
                move.l  a0,-(sp)
                bsr.w   UI_AnimateBonus
                movea.l (sp)+,a0

Cat_StateFollowing_CheckRoundEnd:  ; was: loc_149F2
                tst.b   (byte_FFD281).w
                beq.s   Cat_StateFollowing_Animate
                move.b  #1,(byte_FFD24F).w
                move.w  #$C,(word_FFD2A0).w
                cmpi.b  #1,(byte_FFD88D).w
                beq.s   Cat_StateFollowing_Animate
                move.b  #1,(byte_FFD88F).w

Cat_StateFollowing_Animate:  ; was: loc_14A12
                bclr    #7,2(a0)
                clr.b   $39(a0)
                move.b  d1,d0
                andi.b  #3,d0
                bne.s   Cat_StateFollowing_SetFacing
                clr.w   6(a0)
                bra.s   Cat_StateFollowing_Draw

Cat_StateFollowing_SetFacing:  ; was: loc_14A2A
                btst    #0,d1
                bne.s   Cat_StateFollowing_SelectFrame
                bset    #7,2(a0)
                move.b  #1,$39(a0)

Cat_StateFollowing_SelectFrame:  ; was: loc_14A3C
                tst.b   d1
                bmi.s   Cat_StateFollowing_FrameUp
                move.w  #8,6(a0)
                bra.s   Cat_StateFollowing_Draw

Cat_StateFollowing_FrameUp:  ; was: loc_14A48
                move.w  #4,6(a0)

Cat_StateFollowing_Draw:  ; was: loc_14A4E
                bsr.w   Anim_UpdateFrame
                bsr.w   Object_CalcScreenPos
                rts

Cat_ChainPositionPointers: dc.b    0, 0  ; was: byte_14A58
                dc.w    $D036, $D05E, $D086, $D0AE, $D0D6, $D0FE, $D126, $D14E
Cat_ChainDirectionPointers: dc.b    0, 0  ; was: byte_14A6A
                dc.w    $D213, $D218, $D21D, $D222, $D227, $D22C, $D231, $D236
; Awards points when chick delivered to door
Chick_AwardPoints:
                moveq   #0,d0  ; was: sub_14A7C
                move.b  $38(a0),d0
                subq.b  #1,d0
                lsl.w   #2,d0
                move.l  Chick_DeliveryScoreTable(pc,d0.w),d0
                move.l  d0,(dword_FFD262).w
                bsr.w   Score_AddAndCheck
                moveq   #0,d0
                move.b  $38(a0),d0
                move.b  d0,d1
                subq.b  #1,d0
                lsl.w   #1,d0
                moveq   #$FFFFFFFF,d2
                lea     Chick_PopupSlotTable(pc),a2
                move.w  (a2,d0.w),d2
                movea.l d2,a2
                move.w  #$20,(a2)
                move.b  d1,$3A(a2)
                lea     (word_FFC440).w,a1
                move.w  dword_FFC470-word_FFC440(a1),d7
                move.w  d7,$30(a2)
                rts

Chick_DeliveryScoreTable: dc.l    $100  ; was: dword_14AC0
                dc.l    $200
                dc.l    $300
                dc.l    $400
                dc.l    $500
                dc.l    $1000
                dc.l    $2000
                dc.l    $5000
Chick_PopupSlotTable: dc.w    $C100, $C140, $C180, $C1C0, $C100, $C140, $C180, $C1C0  ; was: word_14AE0
; Checks if chick chain hit by enemy
Chick_CheckEnemyHit:
                lea     (unk_FFC380).w,a1  ; was: sub_14AF0
                moveq   #1,d0

Chick_CheckEnemyHit_Loop:  ; was: loc_14AF6
                move.w  d0,-(sp)
                btst    #1,5(a1)
                beq.s   Chick_CheckEnemyHit_Next
                bsr.w   Collision_CheckObjectPair
                tst.b   d0
                beq.s   Chick_CheckEnemyHit_Next
                move.b  $38(a0),d0
                lea     (unk_FFC480).w,a2
                moveq   #7,d1

Chick_CheckEnemyHit_DropLoop:  ; was: loc_14B12
                cmp.b   $38(a2),d0
                bhi.s   Chick_CheckEnemyHit_DropNext
                clr.b   $38(a2)
                subq.b  #1,(byte_FFD27A).w
                move.w  #8,$3C(a2)

Chick_CheckEnemyHit_DropNext:  ; was: loc_14B26
                lea     $40(a2),a2
                dbf     d1,Chick_CheckEnemyHit_DropLoop
                bra.s   Chick_CheckEnemyHit_Return

Chick_CheckEnemyHit_Next:  ; was: loc_14B30
                lea     $40(a1),a1
                move.w  (sp)+,d0
                dbf     d0,Chick_CheckEnemyHit_Loop
                rts

Chick_CheckEnemyHit_Return:  ; was: loc_14B3C
                move.w  (sp)+,d0
                rts

; Cat idle state (shared RTS)
Cat_StateIdle:
                rts  ; was: nullsub_4

; Cat state: walking on ground turning at walls
Cat_StateWalking:
                tst.b   $3A(a0)  ; was: sub_14B42
                bne.w   Cat_StateWalkAlt
                bset    #7,$3C(a0)
                bne.s   Cat_StateWalking_Move
                moveq   #0,d0
                move.w  a0,d0
                subi.w  #$C480,d0
                lsr.w   #4,d0
                lea     Cat_WalkSpeedTable(pc),a1
                move.l  (a1,d0.w),$34(a0)
                tst.b   $39(a0)
                beq.s   Cat_StateWalking_SetFrame
                neg.l   $34(a0)

Cat_StateWalking_SetFrame:  ; was: loc_14B70
                move.w  #8,6(a0)

Cat_StateWalking_Move:  ; was: loc_14B76
                bsr.w   Object_UpdatePosition
                tst.l   $2C(a0)
                bne.w   Cat_StateWalking_Falling
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                addq.w  #1,d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                bne.s   Cat_StateWalking_OnGround
                addi.l  #$1000,$2C(a0)
                move.w  #4,6(a0)
                bra.s   Cat_StateWalking_Finish

Cat_StateWalking_OnGround:  ; was: loc_14BA4
                move.l  $34(a0),d0
                beq.s   Cat_StateWalking_Stop
                tst.b   $39(a0)
                bne.s   Cat_StateWalking_AccelerateRight
                subi.l  #$400,$34(a0)
                bra.s   Cat_CheckWallCollision

Cat_StateWalking_Stop:  ; was: loc_14BBA
                clr.l   $34(a0)
                move.w  #$C,$3C(a0)
                bra.s   Cat_StateWalking_Finish

Cat_StateWalking_AccelerateRight:  ; was: loc_14BC6
                addi.l  #$400,$34(a0)
                bra.s   Cat_CheckWallCollision

; Clears cat horizontal velocity
Cat_ClearVelocity:
                clr.l   $34(a0)  ; was: sub_14BD0
                move.w  #$C,$3C(a0)
                bra.s   Cat_StateWalking_Finish

; Cat wall collision: reverses at walls
Cat_CheckWallCollision:
                subq.w  #6,d6  ; was: sub_14BDC
                moveq   #4,d0
                tst.l   $34(a0)
                bpl.s   Cat_CheckWallCollision_Probe
                neg.w   d0

Cat_CheckWallCollision_Probe:  ; was: loc_14BE8
                add.w   d0,d7
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Cat_StateWalking_Finish
                neg.l   $34(a0)

Cat_StateWalking_Finish:  ; was: loc_14BF6
                bra.s   Cat_StateWalking_Animate

Cat_StateWalking_Falling:  ; was: loc_14BF8
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Cat_StateWalking_KeepFalling
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)
                move.w  #8,6(a0)
                bra.s   Cat_StateWalking_Animate

Cat_StateWalking_KeepFalling:  ; was: loc_14C20
                addi.l  #$1000,$2C(a0)
                move.w  #4,6(a0)

Cat_StateWalking_Animate:  ; was: loc_14C2E
                bclr    #7,2(a0)
                tst.l   $34(a0)
                bpl.s   Cat_StateWalking_Draw
                bset    #7,2(a0)

Cat_StateWalking_Draw:  ; was: loc_14C40
                bsr.w   Anim_UpdateFrame
                bsr.w   Cat_CheckPlayerPickup
                rts

Cat_WalkSpeedTable: dc.l    $A000  ; was: dword_14C4A
                dc.l    $C000
                dc.l    $E000
                dc.l    $10000
                dc.l    $12000
                dc.l    $14000
                dc.l    $16000
                dc.l    $18000
; Cat state: alternate walking pattern
Cat_StateWalkAlt:
                bset    #7,$3C(a0)  ; was: sub_14C6A
                bne.s   Cat_StateWalkAlt_Move
                moveq   #0,d0
                move.w  a0,d0
                subi.w  #$C480,d0
                lsr.w   #4,d0
                lea     Cat_WalkAltSpeedTable(pc),a1
                move.l  (a1,d0.w),$34(a0)
                tst.b   $39(a0)
                beq.s   Cat_StateWalkAlt_SetFrame
                neg.l   $34(a0)

Cat_StateWalkAlt_SetFrame:  ; was: loc_14C90
                move.w  #8,6(a0)

Cat_StateWalkAlt_Move:  ; was: loc_14C96
                bsr.w   Object_UpdatePosition
                tst.l   $2C(a0)
                bne.w   Cat_StateWalkAlt_Falling
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                addq.w  #1,d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                bne.s   Cat_StateWalkAlt_CheckWall
                addi.l  #$1000,$2C(a0)
                move.w  #4,6(a0)
                bra.s   Cat_StateWalkAlt_Finish

Cat_StateWalkAlt_CheckWall:  ; was: loc_14CC4
                subq.w  #6,d6
                moveq   #4,d0
                tst.l   $34(a0)
                bpl.s   Cat_StateWalkAlt_Probe
                neg.w   d0

Cat_StateWalkAlt_Probe:  ; was: loc_14CD0
                add.w   d0,d7
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Cat_StateWalkAlt_Finish
                neg.l   $34(a0)

Cat_StateWalkAlt_Finish:  ; was: loc_14CDE
                bra.s   Cat_StateWalkAlt_Animate

Cat_StateWalkAlt_Falling:  ; was: loc_14CE0
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Cat_StateWalkAlt_KeepFalling
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)
                move.w  #8,6(a0)
                bra.s   Cat_StateWalkAlt_Animate

Cat_StateWalkAlt_KeepFalling:  ; was: loc_14D08
                addi.l  #$1000,$2C(a0)
                move.w  #4,6(a0)

Cat_StateWalkAlt_Animate:  ; was: loc_14D16
                bclr    #7,2(a0)
                tst.l   $34(a0)
                bpl.s   Cat_StateWalkAlt_Draw
                bset    #7,2(a0)

Cat_StateWalkAlt_Draw:  ; was: loc_14D28
                bsr.w   Anim_UpdateFrame
                bsr.w   Cat_CheckPlayerPickup
                rts

Cat_WalkAltSpeedTable: dc.l    $C000  ; was: dword_14D32
                dc.l    $D000
                dc.l    $E000
                dc.l    $F000
                dc.l    $10000
                dc.l    $11000
                dc.l    $12000
                dc.l    $13000
; Checks if player picked up cat/chick
Cat_CheckPlayerPickup:
                lea     (word_FFC440).w,a1  ; was: sub_14D52
                move.w  word_FFC47C-word_FFC440(a1),d0
                andi.w  #$7C,d0
                bne.s   Cat_CheckPlayerPickup_Return
                bsr.w   Collision_CheckObjectPair
                tst.b   d0
                beq.s   Cat_CheckPlayerPickup_Return
                move.l  a0,-(sp)
                move.b  #$90,d0
                bsr.w   Sound_PlayNoteIfActive
                movea.l (sp)+,a0
                move.w  #4,$3C(a0)
                addq.b  #1,(byte_FFD27A).w
                move.b  (byte_FFD27A).w,$38(a0)

Cat_CheckPlayerPickup_Return:  ; was: locret_14D84
                rts

; Cat state: stunned walking animation
Cat_StateStunWalk:
                bsr.w   Object_UpdatePosition  ; was: sub_14D86
                bset    #7,$3C(a0)
                bne.s   Cat_StateStunWalk_Move
                bclr    #2,2(a0)
                move.w  #$C,6(a0)
                clr.b   $10(a0)

Cat_StateStunWalk_Move:  ; was: loc_14DA2
                bsr.w   Object_UpdatePosition
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   Cat_StateStunWalk_Animate
                bset    #7,2(a0)

Cat_StateStunWalk_Animate:  ; was: loc_14DB8
                bsr.w   Anim_UpdateFrame
                bclr    #2,2(a0)
                beq.s   Cat_StateStunWalk_CheckPickup
                bchg    #0,$39(a0)
                move.w  #8,$3C(a0)

Cat_StateStunWalk_CheckPickup:  ; was: loc_14DD0
                bsr.s   Cat_CheckPlayerPickup
                rts

; Calculates time bonus from remaining time
Score_CalcTimeBonus:
                clr.l   (dword_FFD268).w  ; was: sub_14DD4
                tst.b   (byte_FFD266).w
                bne.s   Score_CalcTimeBonus_Return
                moveq   #0,d0
                move.b  (byte_FFD267).w,d0
                lsr.w   #4,d0
                lsl.w   #2,d0
                move.l  Score_TimeBonusTable(pc,d0.w),d0
                move.l  d0,(dword_FFD268).w
                move.l  d0,(dword_FFD262).w
                bsr.w   Score_AddAndCheck

Score_CalcTimeBonus_Return:  ; was: locret_14DF8
                rts

Score_TimeBonusTable: dc.l    $20000  ; was: dword_14DFA
                dc.l    $20000
                dc.l    $10000
                dc.l    $5000
                dc.l    $3000
                dc.l    $1000
Cat_AnimPointers: dc.l    Cat_AnimWalk  ; was: off_14E12
                dc.l    Cat_AnimIdle
                dc.l    Cat_AnimCarried
                dc.l    Cat_AnimStunned
Cat_AnimPointersAlt: dc.l    Cat_AnimWalkAlt  ; was: off_14E22
                dc.l    Cat_AnimIdleAlt
                dc.l    Cat_AnimCarriedAlt
                dc.l    Cat_AnimStunnedAlt
Cat_AnimWalk:   dc.b    $18, 4  ; was: byte_14E32
                dc.w    Cat_WalkFrame0-Sys_GameEntryPoint
                dc.w    Cat_WalkFrame1-Sys_GameEntryPoint
                dc.w    Cat_WalkFrame0-Sys_GameEntryPoint
                dc.w    Cat_WalkFrame1-Sys_GameEntryPoint
                dc.w    Cat_WalkFrame0-Sys_GameEntryPoint
                dc.w    Cat_WalkFrame1-Sys_GameEntryPoint
                dc.w    Cat_WalkFrame0-Sys_GameEntryPoint
                dc.w    Cat_WalkFrame1-Sys_GameEntryPoint
                dc.w    Cat_WalkFrame0-Sys_GameEntryPoint
                dc.w    Cat_WalkFrame1-Sys_GameEntryPoint
                dc.w    Cat_WalkFrame0-Sys_GameEntryPoint
                dc.w    Cat_WalkFrame1-Sys_GameEntryPoint
                dc.w    Cat_WalkFrame2-Sys_GameEntryPoint
                dc.w    Cat_WalkFrame3-Sys_GameEntryPoint
                dc.w    Cat_WalkFrame2-Sys_GameEntryPoint
                dc.w    Cat_WalkFrame3-Sys_GameEntryPoint
                dc.w    Cat_WalkFrame2-Sys_GameEntryPoint
                dc.w    Cat_WalkFrame3-Sys_GameEntryPoint
                dc.w    Cat_WalkFrame2-Sys_GameEntryPoint
                dc.w    Cat_WalkFrame3-Sys_GameEntryPoint
                dc.w    Cat_WalkFrame2-Sys_GameEntryPoint
                dc.w    Cat_WalkFrame3-Sys_GameEntryPoint
                dc.w    Cat_WalkFrame2-Sys_GameEntryPoint
                dc.w    Cat_WalkFrame3-Sys_GameEntryPoint
Cat_AnimWalkAlt: dc.b    $18, 4  ; was: byte_14E64
                dc.w    Cat_WalkAltFrame0-Sys_GameEntryPoint
                dc.w    Cat_WalkAltFrame1-Sys_GameEntryPoint
                dc.w    Cat_WalkAltFrame0-Sys_GameEntryPoint
                dc.w    Cat_WalkAltFrame1-Sys_GameEntryPoint
                dc.w    Cat_WalkAltFrame0-Sys_GameEntryPoint
                dc.w    Cat_WalkAltFrame1-Sys_GameEntryPoint
                dc.w    Cat_WalkAltFrame0-Sys_GameEntryPoint
                dc.w    Cat_WalkAltFrame1-Sys_GameEntryPoint
                dc.w    Cat_WalkAltFrame0-Sys_GameEntryPoint
                dc.w    Cat_WalkAltFrame1-Sys_GameEntryPoint
                dc.w    Cat_WalkAltFrame0-Sys_GameEntryPoint
                dc.w    Cat_WalkAltFrame1-Sys_GameEntryPoint
                dc.w    Cat_WalkAltFrame2-Sys_GameEntryPoint
                dc.w    Cat_WalkAltFrame3-Sys_GameEntryPoint
                dc.w    Cat_WalkAltFrame2-Sys_GameEntryPoint
                dc.w    Cat_WalkAltFrame3-Sys_GameEntryPoint
                dc.w    Cat_WalkAltFrame2-Sys_GameEntryPoint
                dc.w    Cat_WalkAltFrame3-Sys_GameEntryPoint
                dc.w    Cat_WalkAltFrame2-Sys_GameEntryPoint
                dc.w    Cat_WalkAltFrame3-Sys_GameEntryPoint
                dc.w    Cat_WalkAltFrame2-Sys_GameEntryPoint
                dc.w    Cat_WalkAltFrame3-Sys_GameEntryPoint
                dc.w    Cat_WalkAltFrame2-Sys_GameEntryPoint
                dc.w    Cat_WalkAltFrame3-Sys_GameEntryPoint
Cat_AnimIdle:   dc.b    2, 3  ; was: byte_14E96
                dc.w    Cat_IdleFrame0-Sys_GameEntryPoint
                dc.w    Cat_IdleFrame1-Sys_GameEntryPoint
Cat_AnimIdleAlt: dc.b    2, 3  ; was: byte_14E9C
                dc.w    Cat_IdleAltFrame0-Sys_GameEntryPoint
                dc.w    Cat_IdleAltFrame1-Sys_GameEntryPoint
Cat_AnimCarried: dc.b    3, 4  ; was: byte_14EA2
                dc.w    Cat_CarriedFrame0-Sys_GameEntryPoint
                dc.w    Cat_CarriedFrame1-Sys_GameEntryPoint
                dc.w    Cat_CarriedFrame2-Sys_GameEntryPoint
Cat_AnimCarriedAlt: dc.b    3, 4  ; was: byte_14EAA
                dc.w    Cat_CarriedAltFrame0-Sys_GameEntryPoint
                dc.w    Cat_CarriedAltFrame1-Sys_GameEntryPoint
                dc.w    Cat_CarriedAltFrame2-Sys_GameEntryPoint
Cat_AnimStunned: dc.b    4, $A  ; was: byte_14EB2
                dc.w    Cat_StunnedFrame0-Sys_GameEntryPoint
                dc.w    Cat_StunnedFrame0-Sys_GameEntryPoint
                dc.w    Cat_StunnedFrame1-Sys_GameEntryPoint
                dc.w    Cat_StunnedFrame2-Sys_GameEntryPoint
Cat_AnimStunnedAlt: dc.b    4, $A  ; was: byte_14EBC
                dc.w    Cat_StunnedAltFrame0-Sys_GameEntryPoint
                dc.w    Cat_StunnedAltFrame0-Sys_GameEntryPoint
                dc.w    Cat_StunnedAltFrame1-Sys_GameEntryPoint
                dc.w    Cat_StunnedAltFrame2-Sys_GameEntryPoint
; Lizard enemy main object with state machine
