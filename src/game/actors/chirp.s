; Chirp rescue actor
; ROM $01483E-$014EC5

Obj_Chirp:
                bset    #7,(a0)
                bne.s   Obj_Chirp_Dispatch
                move.l  #Chirp_AnimPointers,8(a0)
                tst.b   $3A(a0)
                beq.s   Obj_Chirp_SetPosition
                move.l  #Chirp_AnimPointersAlt,8(a0)

Obj_Chirp_SetPosition:
                move.b  $3E(a0),d7
                move.b  $3F(a0),d6
                bsr.w   Math_GridToScreen
                addq.w  #8,d7
                addi.w  #$10,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)

Obj_Chirp_Dispatch:
                tst.b   (Ram_CutsceneFlag).w
                bne.s   Obj_Chirp_Return
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     Chirp_StateTable(pc,d0.w)
                move.l  $34(a0),d0
                beq.s   Obj_Chirp_Return
                move.b  #1,$39(a0)
                tst.l   d0
                bmi.s   Obj_Chirp_Return
                clr.b   $39(a0)

Obj_Chirp_Return:
                rts

Chirp_StateTable:
                bra.w   Chirp_StatePatrol
                bra.w   Chirp_StateFollowing
                bra.w   Chirp_StateWalking
                bra.w   Chirp_StateStunWalk

; Chirp state: patrolling and bouncing
Chirp_StatePatrol:
                tst.b   (Ram_RoundEndingFlag).w
                bne.s   Chirp_StatePatrol_Return
                bset    #7,$3C(a0)
                bne.s   Chirp_StatePatrol_Bounce
                move.b  #$30,$3B(a0)
                move.l  #$FFFFE000,$2C(a0)

Chirp_StatePatrol_Bounce:
                clr.w   6(a0)
                subq.b  #1,$3B(a0)
                bne.s   Chirp_StatePatrol_CheckPlayer
                neg.l   $2C(a0)
                move.b  #$30,$3B(a0)

Chirp_StatePatrol_CheckPlayer:
                lea     (Ram_PlayerObject).w,a1
                bsr.w   Collision_CheckObjectPair
                tst.b   d0
                beq.s   Chirp_StatePatrol_Animate
                move.l  a0,-(sp)
                move.b  #$90,d0
                bsr.w   Sound_PlayNoteIfActive
                movea.l (sp)+,a0
                move.w  #4,$3C(a0)
                addq.b  #1,(Ram_ChickChainCount).w
                move.b  (Ram_ChickChainCount).w,$38(a0)
                move.l  #$10,(Ram_ScoreDelta).w
                bsr.w   Score_AddAndCheck

Chirp_StatePatrol_Animate:
                bsr.w   Anim_UpdateFrame
                bsr.w   Object_UpdatePosition

Chirp_StatePatrol_Return:
                rts

; Chirp state: following the rescued Chirp chain
Chirp_StateFollowing:
                bset    #7,$3C(a0)
                bne.s   Chirp_StateFollowing_CheckHit
                clr.l   $34(a0)
                clr.l   $2C(a0)

Chirp_StateFollowing_CheckHit:
                tst.b   (Ram_PlayerHitFlag).w
                beq.s   Chirp_StateFollowing_TrackChain
                clr.b   $38(a0)
                subq.b  #1,(Ram_ChickChainCount).w
                move.w  #8,$3C(a0)
                bra.w   Chirp_StateFollowing_Animate

Chirp_StateFollowing_TrackChain:
                moveq   #0,d0
                move.b  $38(a0),d0
                lsl.w   #1,d0
                moveq   #$FFFFFFFF,d1
                lea     Chirp_ChainPositionPointers(pc),a1
                move.w  (a1,d0.w),d1
                movea.l d1,a1
                move.l  (a1),$30(a0)
                move.l  4(a1),$24(a0)
                bsr.w   Object_CalcScreenPos
                lea     Chirp_ChainDirectionPointers(pc),a1
                move.w  (a1,d0.w),d1
                movea.l d1,a1
                moveq   #0,d1
                move.b  (a1),d1
                move.w  d1,-(sp)
                tst.b   (Ram_RoundEndingFlag).w
                bne.s   Chirp_StateFollowing_CheckDelivery
                bsr.w   Chirp_CheckEnemyHit

Chirp_StateFollowing_CheckDelivery:
                move.w  (sp)+,d1
                tst.b   (Ram_RoundEndingFlag).w
                beq.s   Chirp_StateFollowing_CheckRoundEnd
                lea     (Ram_PlayerObject).w,a1
                move.w  Ram_PlayerWorldX-Ram_PlayerObject(a1),d7
                move.w  $24(a1),d6
                cmp.w   $30(a0),d7
                bne.s   Chirp_StateFollowing_CheckRoundEnd
                cmp.w   $24(a0),d6
                bne.s   Chirp_StateFollowing_CheckRoundEnd
                move.l  a0,-(sp)
                move.b  #$94,d0
                bsr.w   Sound_PlayNoteIfActive
                movea.l (sp)+,a0
                clr.w   (a0)
                bsr.w   Chirp_AwardPoints
                subq.b  #1,(Ram_ChicksRemaining).w
                bne.s   Chirp_StateFollowing_DeliverDelay
                move.b  #1,(Ram_RoundClearFlag).w
                clr.w   (Ram_FrameCounter).w
                move.b  (Ram_RoundTime).w,(Ram_RoundMinutes).w
                move.b  (Ram_RoundTime+1).w,(Ram_RoundSeconds).w
                bsr.w   Score_CalcTimeBonus

Chirp_StateFollowing_DeliverDelay:
                move.l  a0,-(sp)
                moveq   #2,d1

Chirp_StateFollowing_DelayLoop:
                jsr     j_Sound_QueueSFX
                dbf     d1,Chirp_StateFollowing_DelayLoop
                movea.l (sp)+,a0
                clr.b   $38(a0)
                subq.b  #1,(Ram_ChickChainCount).w
                bne.s   Chirp_StateFollowing_CheckRoundEnd
                clr.b   (Ram_RoundEndingFlag).w
                move.l  a0,-(sp)
                bsr.w   UI_AnimateBonus
                movea.l (sp)+,a0

Chirp_StateFollowing_CheckRoundEnd:
                tst.b   (Ram_RoundClearFlag).w
                beq.s   Chirp_StateFollowing_Animate
                move.b  #1,(Ram_RoundEndingFlag).w
                move.w  #$C,(Ram_GameState).w
                cmpi.b  #1,(Ram_ExitReachedFlag).w
                beq.s   Chirp_StateFollowing_Animate
                move.b  #1,(Ram_SkipBonusFlag).w

Chirp_StateFollowing_Animate:
                bclr    #7,2(a0)
                clr.b   $39(a0)
                move.b  d1,d0
                andi.b  #3,d0
                bne.s   Chirp_StateFollowing_SetFacing
                clr.w   6(a0)
                bra.s   Chirp_StateFollowing_Draw

Chirp_StateFollowing_SetFacing:
                btst    #0,d1
                bne.s   Chirp_StateFollowing_SelectFrame
                bset    #7,2(a0)
                move.b  #1,$39(a0)

Chirp_StateFollowing_SelectFrame:
                tst.b   d1
                bmi.s   Chirp_StateFollowing_FrameUp
                move.w  #8,6(a0)
                bra.s   Chirp_StateFollowing_Draw

Chirp_StateFollowing_FrameUp:
                move.w  #4,6(a0)

Chirp_StateFollowing_Draw:
                bsr.w   Anim_UpdateFrame
                bsr.w   Object_CalcScreenPos
                rts

Chirp_ChainPositionPointers:    dc.b    0, 0
                dc.w    $D036, $D05E, $D086, $D0AE, $D0D6, $D0FE, $D126, $D14E
Chirp_ChainDirectionPointers:   dc.b    0, 0
                dc.w    $D213, $D218, $D21D, $D222, $D227, $D22C, $D231, $D236
; Awards points when a Chirp reaches the exit door
Chirp_AwardPoints:
                moveq   #0,d0
                move.b  $38(a0),d0
                subq.b  #1,d0
                lsl.w   #2,d0
                move.l  Chirp_DeliveryScoreTable(pc,d0.w),d0
                move.l  d0,(Ram_ScoreDelta).w
                bsr.w   Score_AddAndCheck
                moveq   #0,d0
                move.b  $38(a0),d0
                move.b  d0,d1
                subq.b  #1,d0
                lsl.w   #1,d0
                moveq   #$FFFFFFFF,d2
                lea     Chirp_PopupSlotTable(pc),a2
                move.w  (a2,d0.w),d2
                movea.l d2,a2
                move.w  #$20,(a2)
                move.b  d1,$3A(a2)
                lea     (Ram_PlayerObject).w,a1
                move.w  Ram_PlayerWorldX-Ram_PlayerObject(a1),d7
                move.w  d7,$30(a2)
                rts

Chirp_DeliveryScoreTable:   dc.l    $100
                dc.l    $200
                dc.l    $300
                dc.l    $400
                dc.l    $500
                dc.l    $1000
                dc.l    $2000
                dc.l    $5000
Chirp_PopupSlotTable:   dc.w    $C100, $C140, $C180, $C1C0, $C100, $C140, $C180, $C1C0
; Checks if the Chirp chain was hit by an enemy
Chirp_CheckEnemyHit:
                lea     (Ram_ProjectileSlots).w,a1
                moveq   #1,d0

Chirp_CheckEnemyHit_Loop:
                move.w  d0,-(sp)
                btst    #1,5(a1)
                beq.s   Chirp_CheckEnemyHit_Next
                bsr.w   Collision_CheckObjectPair
                tst.b   d0
                beq.s   Chirp_CheckEnemyHit_Next
                move.b  $38(a0),d0
                lea     (Ram_ChickSlots).w,a2
                moveq   #7,d1

Chirp_CheckEnemyHit_DropLoop:
                cmp.b   $38(a2),d0
                bhi.s   Chirp_CheckEnemyHit_DropNext
                clr.b   $38(a2)
                subq.b  #1,(Ram_ChickChainCount).w
                move.w  #8,$3C(a2)

Chirp_CheckEnemyHit_DropNext:
                lea     $40(a2),a2
                dbf     d1,Chirp_CheckEnemyHit_DropLoop
                bra.s   Chirp_CheckEnemyHit_Return

Chirp_CheckEnemyHit_Next:
                lea     $40(a1),a1
                move.w  (sp)+,d0
                dbf     d0,Chirp_CheckEnemyHit_Loop
                rts

Chirp_CheckEnemyHit_Return:
                move.w  (sp)+,d0
                rts

; Chirp idle state (shared RTS)
Chirp_StateIdle:
                rts

; Chirp state: walking on ground and turning at walls
Chirp_StateWalking:
                tst.b   $3A(a0)
                bne.w   Chirp_StateWalkAlt
                bset    #7,$3C(a0)
                bne.s   Chirp_StateWalking_Move
                moveq   #0,d0
                move.w  a0,d0
                subi.w  #$C480,d0
                lsr.w   #4,d0
                lea     Chirp_WalkSpeedTable(pc),a1
                move.l  (a1,d0.w),$34(a0)
                tst.b   $39(a0)
                beq.s   Chirp_StateWalking_SetFrame
                neg.l   $34(a0)

Chirp_StateWalking_SetFrame:
                move.w  #8,6(a0)

Chirp_StateWalking_Move:
                bsr.w   Object_UpdatePosition
                tst.l   $2C(a0)
                bne.w   Chirp_StateWalking_Falling
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                addq.w  #1,d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                bne.s   Chirp_StateWalking_OnGround
                addi.l  #$1000,$2C(a0)
                move.w  #4,6(a0)
                bra.s   Chirp_StateWalking_Finish

Chirp_StateWalking_OnGround:
                move.l  $34(a0),d0
                beq.s   Chirp_StateWalking_Stop
                tst.b   $39(a0)
                bne.s   Chirp_StateWalking_AccelerateRight
                subi.l  #$400,$34(a0)
                bra.s   Chirp_CheckWallCollision

Chirp_StateWalking_Stop:
                clr.l   $34(a0)
                move.w  #$C,$3C(a0)
                bra.s   Chirp_StateWalking_Finish

Chirp_StateWalking_AccelerateRight:
                addi.l  #$400,$34(a0)
                bra.s   Chirp_CheckWallCollision

; Clears Chirp horizontal velocity
Chirp_ClearVelocity:
                clr.l   $34(a0)
                move.w  #$C,$3C(a0)
                bra.s   Chirp_StateWalking_Finish

; Chirp wall collision: reverses at walls
Chirp_CheckWallCollision:
                subq.w  #6,d6
                moveq   #4,d0
                tst.l   $34(a0)
                bpl.s   Chirp_CheckWallCollision_Probe
                neg.w   d0

Chirp_CheckWallCollision_Probe:
                add.w   d0,d7
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Chirp_StateWalking_Finish
                neg.l   $34(a0)

Chirp_StateWalking_Finish:
                bra.s   Chirp_StateWalking_Animate

Chirp_StateWalking_Falling:
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Chirp_StateWalking_KeepFalling
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)
                move.w  #8,6(a0)
                bra.s   Chirp_StateWalking_Animate

Chirp_StateWalking_KeepFalling:
                addi.l  #$1000,$2C(a0)
                move.w  #4,6(a0)

Chirp_StateWalking_Animate:
                bclr    #7,2(a0)
                tst.l   $34(a0)
                bpl.s   Chirp_StateWalking_Draw
                bset    #7,2(a0)

Chirp_StateWalking_Draw:
                bsr.w   Anim_UpdateFrame
                bsr.w   Chirp_CheckPlayerPickup
                rts

Chirp_WalkSpeedTable:   dc.l    $A000
                dc.l    $C000
                dc.l    $E000
                dc.l    $10000
                dc.l    $12000
                dc.l    $14000
                dc.l    $16000
                dc.l    $18000
; Chirp state: alternate walking pattern
Chirp_StateWalkAlt:
                bset    #7,$3C(a0)
                bne.s   Chirp_StateWalkAlt_Move
                moveq   #0,d0
                move.w  a0,d0
                subi.w  #$C480,d0
                lsr.w   #4,d0
                lea     Chirp_WalkAltSpeedTable(pc),a1
                move.l  (a1,d0.w),$34(a0)
                tst.b   $39(a0)
                beq.s   Chirp_StateWalkAlt_SetFrame
                neg.l   $34(a0)

Chirp_StateWalkAlt_SetFrame:
                move.w  #8,6(a0)

Chirp_StateWalkAlt_Move:
                bsr.w   Object_UpdatePosition
                tst.l   $2C(a0)
                bne.w   Chirp_StateWalkAlt_Falling
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                addq.w  #1,d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                bne.s   Chirp_StateWalkAlt_CheckWall
                addi.l  #$1000,$2C(a0)
                move.w  #4,6(a0)
                bra.s   Chirp_StateWalkAlt_Finish

Chirp_StateWalkAlt_CheckWall:
                subq.w  #6,d6
                moveq   #4,d0
                tst.l   $34(a0)
                bpl.s   Chirp_StateWalkAlt_Probe
                neg.w   d0

Chirp_StateWalkAlt_Probe:
                add.w   d0,d7
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Chirp_StateWalkAlt_Finish
                neg.l   $34(a0)

Chirp_StateWalkAlt_Finish:
                bra.s   Chirp_StateWalkAlt_Animate

Chirp_StateWalkAlt_Falling:
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Chirp_StateWalkAlt_KeepFalling
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)
                move.w  #8,6(a0)
                bra.s   Chirp_StateWalkAlt_Animate

Chirp_StateWalkAlt_KeepFalling:
                addi.l  #$1000,$2C(a0)
                move.w  #4,6(a0)

Chirp_StateWalkAlt_Animate:
                bclr    #7,2(a0)
                tst.l   $34(a0)
                bpl.s   Chirp_StateWalkAlt_Draw
                bset    #7,2(a0)

Chirp_StateWalkAlt_Draw:
                bsr.w   Anim_UpdateFrame
                bsr.w   Chirp_CheckPlayerPickup
                rts

Chirp_WalkAltSpeedTable:    dc.l    $C000
                dc.l    $D000
                dc.l    $E000
                dc.l    $F000
                dc.l    $10000
                dc.l    $11000
                dc.l    $12000
                dc.l    $13000
; Checks if the player collected this Chirp
Chirp_CheckPlayerPickup:
                lea     (Ram_PlayerObject).w,a1
                move.w  Ram_PlayerState-Ram_PlayerObject(a1),d0
                andi.w  #$7C,d0
                bne.s   Chirp_CheckPlayerPickup_Return
                bsr.w   Collision_CheckObjectPair
                tst.b   d0
                beq.s   Chirp_CheckPlayerPickup_Return
                move.l  a0,-(sp)
                move.b  #$90,d0
                bsr.w   Sound_PlayNoteIfActive
                movea.l (sp)+,a0
                move.w  #4,$3C(a0)
                addq.b  #1,(Ram_ChickChainCount).w
                move.b  (Ram_ChickChainCount).w,$38(a0)

Chirp_CheckPlayerPickup_Return:
                rts

; Chirp state: stunned walking animation
Chirp_StateStunWalk:
                bsr.w   Object_UpdatePosition
                bset    #7,$3C(a0)
                bne.s   Chirp_StateStunWalk_Move
                bclr    #2,2(a0)
                move.w  #$C,6(a0)
                clr.b   $10(a0)

Chirp_StateStunWalk_Move:
                bsr.w   Object_UpdatePosition
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   Chirp_StateStunWalk_Animate
                bset    #7,2(a0)

Chirp_StateStunWalk_Animate:
                bsr.w   Anim_UpdateFrame
                bclr    #2,2(a0)
                beq.s   Chirp_StateStunWalk_CheckPickup
                bchg    #0,$39(a0)
                move.w  #8,$3C(a0)

Chirp_StateStunWalk_CheckPickup:
                bsr.s   Chirp_CheckPlayerPickup
                rts

; Calculates time bonus from remaining time
Score_CalcTimeBonus:
                clr.l   (Ram_TimeBonus).w
                tst.b   (Ram_RoundMinutes).w
                bne.s   Score_CalcTimeBonus_Return
                moveq   #0,d0
                move.b  (Ram_RoundSeconds).w,d0
                lsr.w   #4,d0
                lsl.w   #2,d0
                move.l  Score_TimeBonusTable(pc,d0.w),d0
                move.l  d0,(Ram_TimeBonus).w
                move.l  d0,(Ram_ScoreDelta).w
                bsr.w   Score_AddAndCheck

Score_CalcTimeBonus_Return:
                rts

Score_TimeBonusTable:   dc.l    $20000
                dc.l    $20000
                dc.l    $10000
                dc.l    $5000
                dc.l    $3000
                dc.l    $1000
Chirp_AnimPointers: dc.l    Chirp_AnimWalk
                dc.l    Chirp_AnimIdle
                dc.l    Chirp_AnimCarried
                dc.l    Chirp_AnimStunned
Chirp_AnimPointersAlt:  dc.l    Chirp_AnimWalkAlt
                dc.l    Chirp_AnimIdleAlt
                dc.l    Chirp_AnimCarriedAlt
                dc.l    Chirp_AnimStunnedAlt
Chirp_AnimWalk: dc.b    $18, 4
                dc.w    Chirp_WalkFrame0-Sys_GameEntryPoint
                dc.w    Chirp_WalkFrame1-Sys_GameEntryPoint
                dc.w    Chirp_WalkFrame0-Sys_GameEntryPoint
                dc.w    Chirp_WalkFrame1-Sys_GameEntryPoint
                dc.w    Chirp_WalkFrame0-Sys_GameEntryPoint
                dc.w    Chirp_WalkFrame1-Sys_GameEntryPoint
                dc.w    Chirp_WalkFrame0-Sys_GameEntryPoint
                dc.w    Chirp_WalkFrame1-Sys_GameEntryPoint
                dc.w    Chirp_WalkFrame0-Sys_GameEntryPoint
                dc.w    Chirp_WalkFrame1-Sys_GameEntryPoint
                dc.w    Chirp_WalkFrame0-Sys_GameEntryPoint
                dc.w    Chirp_WalkFrame1-Sys_GameEntryPoint
                dc.w    Chirp_WalkFrame2-Sys_GameEntryPoint
                dc.w    Chirp_WalkFrame3-Sys_GameEntryPoint
                dc.w    Chirp_WalkFrame2-Sys_GameEntryPoint
                dc.w    Chirp_WalkFrame3-Sys_GameEntryPoint
                dc.w    Chirp_WalkFrame2-Sys_GameEntryPoint
                dc.w    Chirp_WalkFrame3-Sys_GameEntryPoint
                dc.w    Chirp_WalkFrame2-Sys_GameEntryPoint
                dc.w    Chirp_WalkFrame3-Sys_GameEntryPoint
                dc.w    Chirp_WalkFrame2-Sys_GameEntryPoint
                dc.w    Chirp_WalkFrame3-Sys_GameEntryPoint
                dc.w    Chirp_WalkFrame2-Sys_GameEntryPoint
                dc.w    Chirp_WalkFrame3-Sys_GameEntryPoint
Chirp_AnimWalkAlt:  dc.b    $18, 4
                dc.w    Chirp_WalkAltFrame0-Sys_GameEntryPoint
                dc.w    Chirp_WalkAltFrame1-Sys_GameEntryPoint
                dc.w    Chirp_WalkAltFrame0-Sys_GameEntryPoint
                dc.w    Chirp_WalkAltFrame1-Sys_GameEntryPoint
                dc.w    Chirp_WalkAltFrame0-Sys_GameEntryPoint
                dc.w    Chirp_WalkAltFrame1-Sys_GameEntryPoint
                dc.w    Chirp_WalkAltFrame0-Sys_GameEntryPoint
                dc.w    Chirp_WalkAltFrame1-Sys_GameEntryPoint
                dc.w    Chirp_WalkAltFrame0-Sys_GameEntryPoint
                dc.w    Chirp_WalkAltFrame1-Sys_GameEntryPoint
                dc.w    Chirp_WalkAltFrame0-Sys_GameEntryPoint
                dc.w    Chirp_WalkAltFrame1-Sys_GameEntryPoint
                dc.w    Chirp_WalkAltFrame2-Sys_GameEntryPoint
                dc.w    Chirp_WalkAltFrame3-Sys_GameEntryPoint
                dc.w    Chirp_WalkAltFrame2-Sys_GameEntryPoint
                dc.w    Chirp_WalkAltFrame3-Sys_GameEntryPoint
                dc.w    Chirp_WalkAltFrame2-Sys_GameEntryPoint
                dc.w    Chirp_WalkAltFrame3-Sys_GameEntryPoint
                dc.w    Chirp_WalkAltFrame2-Sys_GameEntryPoint
                dc.w    Chirp_WalkAltFrame3-Sys_GameEntryPoint
                dc.w    Chirp_WalkAltFrame2-Sys_GameEntryPoint
                dc.w    Chirp_WalkAltFrame3-Sys_GameEntryPoint
                dc.w    Chirp_WalkAltFrame2-Sys_GameEntryPoint
                dc.w    Chirp_WalkAltFrame3-Sys_GameEntryPoint
Chirp_AnimIdle: dc.b    2, 3
                dc.w    Chirp_IdleFrame0-Sys_GameEntryPoint
                dc.w    Chirp_IdleFrame1-Sys_GameEntryPoint
Chirp_AnimIdleAlt:  dc.b    2, 3
                dc.w    Chirp_IdleAltFrame0-Sys_GameEntryPoint
                dc.w    Chirp_IdleAltFrame1-Sys_GameEntryPoint
Chirp_AnimCarried:  dc.b    3, 4
                dc.w    Chirp_CarriedFrame0-Sys_GameEntryPoint
                dc.w    Chirp_CarriedFrame1-Sys_GameEntryPoint
                dc.w    Chirp_CarriedFrame2-Sys_GameEntryPoint
Chirp_AnimCarriedAlt:   dc.b    3, 4
                dc.w    Chirp_CarriedAltFrame0-Sys_GameEntryPoint
                dc.w    Chirp_CarriedAltFrame1-Sys_GameEntryPoint
                dc.w    Chirp_CarriedAltFrame2-Sys_GameEntryPoint
Chirp_AnimStunned:  dc.b    4, $A
                dc.w    Chirp_StunnedFrame0-Sys_GameEntryPoint
                dc.w    Chirp_StunnedFrame0-Sys_GameEntryPoint
                dc.w    Chirp_StunnedFrame1-Sys_GameEntryPoint
                dc.w    Chirp_StunnedFrame2-Sys_GameEntryPoint
Chirp_AnimStunnedAlt:   dc.b    4, $A
                dc.w    Chirp_StunnedAltFrame0-Sys_GameEntryPoint
                dc.w    Chirp_StunnedAltFrame0-Sys_GameEntryPoint
                dc.w    Chirp_StunnedAltFrame1-Sys_GameEntryPoint
                dc.w    Chirp_StunnedAltFrame2-Sys_GameEntryPoint
; Tiger cat enemy with state machine
