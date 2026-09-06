; Lizard enemy and its animation tables
; ROM $014EC6-$015507

Obj_Lizard:
                bset    #7,(a0)
                bne.s   Obj_Lizard_Dispatch
                moveq   #0,d7
                moveq   #0,d6
                move.b  $3E(a0),d7
                move.b  $3F(a0),d6
                bsr.w   Math_GridToScreen
                addq.w  #8,d7
                addi.w  #$10,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)
                move.l  #Lizard_AnimPointers,8(a0)
                clr.l   $34(a0)
                clr.l   $2C(a0)

Obj_Lizard_Dispatch:
                tst.b   (Ram_CutsceneFlag).w
                bne.s   Obj_Lizard_UpdateFacing
                tst.b   (Ram_RoundEndingFlag).w
                bne.s   Obj_Lizard_UpdateFacing
                tst.b   (Ram_PlayerHitFlag).w
                bne.s   Obj_Lizard_UpdateFacing
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     Lizard_StateTable(pc,d0.w)
                move.w  $3C(a0),d0
                andi.w  #$7FFC,d0
                cmpi.w  #$14,d0
                beq.s   Obj_Lizard_UpdateFacing
                cmpi.w  #$1C,d0
                beq.s   Obj_Lizard_UpdateFacing
                bsr.w   Lizard_CheckPlayerHit

Obj_Lizard_UpdateFacing:
                move.l  $34(a0),d0
                beq.s   Obj_Lizard_Return
                move.b  #1,$39(a0)
                tst.l   d0
                bmi.s   Obj_Lizard_Return
                clr.b   $39(a0)

Obj_Lizard_Return:
                rts

Lizard_StateTable:
                bra.w   Lizard_StateWait
                bra.w   Lizard_StateLocate
                bra.w   Lizard_StateChase
                bra.w   Lizard_StateJump
                bra.w   Lizard_StateStunned
                bra.w   Lizard_StateHit
                bra.w   Lizard_StateTrack
                bra.w   Lizard_StateDeath

; Lizard state: waiting/idle after hit
Lizard_StateWait:
                bset    #7,$3C(a0)
                bne.s   Lizard_StateWait_Update
                clr.w   6(a0)
                bclr    #2,2(a0)
                clr.b   $10(a0)
                move.b  #6,5(a0)

Lizard_StateWait_Update:
                bsr.w   Object_UpdatePosition
                bsr.w   Anim_UpdateFrame
                bclr    #2,2(a0)
                beq.s   Lizard_StateWait_Return
                move.w  #8,$3C(a0)
                lea     (Ram_PlayerObject).w,a1
                move.w  $20(a0),d7
                move.w  $20(a1),d6
                clr.b   $39(a0)
                cmp.w   d7,d6
                bgt.s   Lizard_StateWait_CheckEarlyRound
                move.b  #1,$39(a0)

Lizard_StateWait_CheckEarlyRound:
                cmpi.w  #$30,(Ram_RoundTime).w
                bhi.s   Lizard_StateWait_Return
                cmpi.b  #$31,(Ram_RoundNumber+1).w
                bhi.s   Lizard_StateWait_Return
                clr.b   $39(a0)
                tst.b   $16(a0)
                beq.s   Lizard_StateWait_Return
                move.b  #1,$39(a0)

Lizard_StateWait_Return:
                rts

; Lizard state: locating player direction
Lizard_StateLocate:
                bset    #7,$3C(a0)
                bne.s   Lizard_StateLocate_Compare
                move.b  #7,5(a0)
                clr.l   $34(a0)
                move.b  #$14,$3B(a0)
                move.l  #Lizard_StateLocateData,$C(a0)
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   Lizard_StateLocate_Compare
                bset    #7,2(a0)

Lizard_StateLocate_Compare:
                bsr.w   Object_UpdatePosition
                move.w  $20(a0),d7
                move.w  $24(a0),d6
                lea     (Ram_PlayerObject).w,a1
                move.w  Ram_PlayerScreenX-Ram_PlayerObject(a1),d5
                move.w  $24(a1),d4
                cmp.w   d6,d4
                beq.s   Lizard_StateLocate_SameRow
                move.b  #2,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

Lizard_StateLocate_SameRow:
                tst.b   $39(a0)
                bne.s   Lizard_StateLocate_FacingLeft
                cmp.w   d7,d5
                bgt.s   Lizard_StateLocate_TurnRight
                move.w  #$10,$3C(a0)
                rts

Lizard_StateLocate_TurnRight:
                move.b  #1,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

Lizard_StateLocate_FacingLeft:
                cmp.w   d7,d5
                blt.s   Lizard_StateLocate_TurnLeft
                move.w  #$10,$3C(a0)
                rts

Lizard_StateLocate_TurnLeft:
                move.b  #1,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

; Lizard state: running/chasing horizontally
Lizard_StateChase:
                bset    #7,$3C(a0)
                bne.s   Lizard_StateChase_Move
                move.b  #7,5(a0)
                move.l  (Ram_LizardSpeed).w,$34(a0)
                tst.b   $16(a0)
                beq.s   Lizard_StateChase_ApplyFacing
                move.l  #$14000,$34(a0)

Lizard_StateChase_ApplyFacing:
                tst.b   $39(a0)
                beq.s   Lizard_StateChase_Move
                neg.l   $34(a0)

Lizard_StateChase_Move:
                bsr.w   Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subq.w  #8,d6
                tst.l   $34(a0)
                bpl.s   Lizard_StateChase_ProbeRight
                subq.w  #8,d7
                bra.s   Lizard_StateChase_ProbeWall

Lizard_StateChase_ProbeRight:
                addq.w  #8,d7

Lizard_StateChase_ProbeWall:
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Lizard_StateChase_CheckGround
                neg.l   $34(a0)

Lizard_StateChase_CheckGround:
                moveq   #0,d7
                moveq   #1,d6
                bsr.w   Collision_GetTileAtObject
                btst    #7,d4
                bne.s   Lizard_StateChase_SpecialTile
                tst.l   $34(a0)
                bpl.s   Lizard_StateChase_EdgeRight
                btst    #2,d4
                bne.s   Lizard_StateChase_LeftDone
                move.w  #4,$3C(a0)

Lizard_StateChase_LeftDone:
                bra.s   Lizard_StateChase_Animate

Lizard_StateChase_EdgeRight:
                btst    #3,d4
                bne.s   Lizard_StateChase_RightDone
                move.w  #4,$3C(a0)

Lizard_StateChase_RightDone:
                bra.s   Lizard_StateChase_Animate

Lizard_StateChase_SpecialTile:
                tst.b   $39(a0)
                bne.s   Lizard_StateChase_SpecialFacingLeft
                btst    #6,d4
                bne.s   Lizard_StateChase_Animate
                bra.s   Lizard_StateChase_ComparePlayerRow

Lizard_StateChase_SpecialFacingLeft:
                btst    #6,d4
                beq.s   Lizard_StateChase_Animate

Lizard_StateChase_ComparePlayerRow:
                lea     (Ram_PlayerObject).w,a1
                move.w  $24(a0),d6
                cmp.w   $24(a1),d6
                blt.s   Lizard_StateChase_Animate
                beq.s   Lizard_StateChase_MaybeJump
                move.w  #$18,$3C(a0)

Lizard_StateChase_Animate:
                bclr    #7,2(a0)
                tst.l   $34(a0)
                bpl.s   Lizard_StateChase_Draw
                bset    #7,2(a0)

Lizard_StateChase_Draw:
                move.w  #4,6(a0)
                bsr.w   Anim_UpdateFrame
                rts

Lizard_StateChase_MaybeJump:
                cmpi.w  #$30,(Ram_RoundTime).w
                bls.s   Lizard_StateChase_Animate
                move.w  $20(a1),d7
                tst.b   $39(a0)
                beq.s   Lizard_StateChase_CheckAhead
                cmp.w   $20(a0),d7
                blt.s   Lizard_StateChase_Animate
                bra.s   Lizard_StateChase_StartJump

Lizard_StateChase_CheckAhead:
                cmp.w   $20(a0),d7
                bgt.s   Lizard_StateChase_Animate

Lizard_StateChase_StartJump:
                move.w  #$18,$3C(a0)
                bra.s   Lizard_StateChase_Animate

; Lizard state: jumping/leaping toward player
Lizard_StateJump:
                tst.b   $3B(a0)
                bne.w   Lizard_StateJump_Delay
                bset    #7,$3C(a0)
                bne.s   Lizard_StateJump_Move
                move.b  #7,5(a0)
                move.b  $3A(a0),d0
                beq.s   Lizard_StateJump_UseLevelArc
                cmpi.b  #1,d0
                beq.s   Lizard_StateJump_UseFixedArc
                move.l  (Ram_LizardJumpSpeed).w,$34(a0)
                move.l  #$FFFF8000,$2C(a0)
                bra.s   Lizard_StateJump_ApplyFacing

Lizard_StateJump_UseLevelArc:
                move.l  (Ram_LizardJumpVelX).w,$34(a0)
                move.l  (Ram_LizardJumpVelY).w,$2C(a0)
                bra.s   Lizard_StateJump_ApplyFacing

Lizard_StateJump_UseFixedArc:
                move.l  #$1A000,$34(a0)
                move.l  #$FFFF0000,$2C(a0)

Lizard_StateJump_ApplyFacing:
                tst.b   $39(a0)
                beq.s   Lizard_StateJump_Move
                neg.l   $34(a0)

Lizard_StateJump_Move:
                addi.l  #$1000,$2C(a0)
                bsr.w   Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                bne.s   Lizard_StateJump_Land
                subq.w  #8,d6
                tst.l   $34(a0)
                bpl.s   Lizard_StateJump_ProbeRight
                subq.w  #8,d7
                bra.s   Lizard_StateJump_ProbeWall

Lizard_StateJump_ProbeRight:
                addq.w  #8,d7

Lizard_StateJump_ProbeWall:
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Lizard_StateJump_CheckCeiling
                neg.l   $34(a0)
                bra.s   Lizard_StateJump_SelectFrame

Lizard_StateJump_CheckCeiling:
                tst.l   $2C(a0)
                bpl.s   Lizard_StateJump_Airborne
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subi.w  #$D,d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Lizard_StateJump_Airborne
                clr.l   $2C(a0)

Lizard_StateJump_Airborne:
                bra.s   Lizard_StateJump_SelectFrame

Lizard_StateJump_Land:
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)
                move.w  #8,$3C(a0)

Lizard_StateJump_SelectFrame:
                move.l  #Lizard_StateJump_SelectFrameData0,$C(a0)
                tst.l   $2C(a0)
                bmi.s   Lizard_StateJump_SetFacing
                move.l  #Lizard_StateJump_SelectFrameData1,$C(a0)

Lizard_StateJump_SetFacing:
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   Lizard_StateJump_Return
                bset    #7,2(a0)

Lizard_StateJump_Return:
                rts

Lizard_StateJump_Delay:
                subq.b  #1,$3B(a0)
                bsr.w   Object_UpdatePosition
                rts

; Lizard state: stunned/recovering after hit
Lizard_StateStunned:
                tst.b   $3B(a0)
                bne.s   Lizard_StateStunned_Delay
                bset    #7,$3C(a0)
                bne.s   Lizard_StateStunned_Move
                move.b  #7,5(a0)
                bclr    #2,2(a0)
                move.w  #$C,6(a0)
                clr.b   $10(a0)

Lizard_StateStunned_Move:
                bsr.w   Object_UpdatePosition
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   Lizard_StateStunned_Animate
                bset    #7,2(a0)

Lizard_StateStunned_Animate:
                bsr.w   Anim_UpdateFrame
                bclr    #2,2(a0)
                beq.s   Lizard_StateStunned_Return
                bchg    #0,$39(a0)
                move.w  #8,$3C(a0)

Lizard_StateStunned_Return:
                rts

Lizard_StateStunned_Delay:
                subq.b  #1,$3B(a0)
                bsr.w   Object_UpdatePosition
                rts

; Lizard state: hit by player bouncing
Lizard_StateHit:
                bset    #7,$3C(a0)
                bne.s   Lizard_StateHit_Move
                move.l  a0,-(sp)
                move.b  #$93,d0
                bsr.w   Sound_PlayNoteIfActive
                movea.l (sp)+,a0
                tst.b   $16(a0)
                bne.s   Lizard_StateHit_Setup
                addi.l  #$1000,(Ram_LizardSpeed).w

Lizard_StateHit_Setup:
                clr.b   5(a0)
                move.w  #8,6(a0)
                subq.b  #1,(Ram_ActiveEnemyCount).w

Lizard_StateHit_Move:
                bsr.w   Chick_UpdatePhysics
                tst.l   $34(a0)
                bne.s   Lizard_StateHit_Return
                move.w  #$1C,$3C(a0)

Lizard_StateHit_Return:
                rts

; Lizard state: tracking player alternate
Lizard_StateTrack:
                bset    #7,$3C(a0)
                bne.s   Lizard_StateTrack_Compare
                move.b  #7,5(a0)
                clr.l   $34(a0)
                move.b  #$14,$3B(a0)
                move.l  #Lizard_StateLocateData,$C(a0)
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   Lizard_StateTrack_Compare
                bset    #7,2(a0)

Lizard_StateTrack_Compare:
                bsr.w   Object_UpdatePosition
                move.w  $20(a0),d7
                move.w  $24(a0),d6
                lea     (Ram_PlayerObject).w,a1
                move.w  Ram_PlayerScreenX-Ram_PlayerObject(a1),d5
                move.w  $24(a1),d4
                cmp.w   d6,d4
                beq.s   Lizard_StateTrack_SameRow
                bgt.s   Lizard_StateTrack_PlayerBelow
                clr.b   $3A(a0)
                move.w  #$C,$3C(a0)
                rts

Lizard_StateTrack_PlayerBelow:
                move.b  #2,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

Lizard_StateTrack_SameRow:
                tst.b   $39(a0)
                bne.s   Lizard_StateTrack_FacingLeft
                cmp.w   d7,d5
                bgt.s   Lizard_StateTrack_TurnRight
                move.w  #$10,$3C(a0)
                rts

Lizard_StateTrack_TurnRight:
                move.b  #1,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

Lizard_StateTrack_FacingLeft:
                cmp.w   d7,d5
                blt.s   Lizard_StateTrack_TurnLeft
                move.w  #$10,$3C(a0)
                rts

Lizard_StateTrack_TurnLeft:
                move.b  #1,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

; Decrements lizard action timer
Lizard_DecrementTimer:
                subq.b  #1,$3B(a0)
                bsr.w   Object_UpdatePosition
                rts

; Lizard state: death anim spawns new enemy
Lizard_StateDeath:
                bset    #7,$3C(a0)
                bne.s   Lizard_StateDeath_Update
                clr.b   5(a0)
                bclr    #2,2(a0)
                move.w  #$10,6(a0)
                clr.b   $10(a0)
                move.l  #$FFFFC000,$2C(a0)

Lizard_StateDeath_Update:
                bsr.w   Object_UpdatePosition
                bsr.w   Anim_UpdateFrame
                btst    #2,2(a0)
                beq.s   Lizard_StateDeath_Return
                move.b  (Ram_RoundTime+2).w,d0
                andi.b  #$F0,d0
                bne.s   Lizard_StateDeath_ClearSprites
                lea     (Ram_LizardRespawnSlot).w,a1
                tst.b   $16(a0)
                beq.s   Lizard_StateDeath_SpawnAt
                lea     $40(a1),a1

Lizard_StateDeath_SpawnAt:
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                move.w  d7,$30(a1)
                move.w  d6,$24(a1)
                move.w  #$28,(a1)

Lizard_StateDeath_ClearSprites:
                bsr.w   Sprite_ClearLinkTable

Lizard_StateDeath_Return:
                rts

; Lizard collision with player hit detection
Lizard_CheckPlayerHit:
                lea     (Ram_SpawnerSlots).w,a1
                moveq   #5,d0

Lizard_CheckPlayerHit_Loop:
                move.w  d0,-(sp)
                btst    #3,5(a1)
                beq.s   Lizard_CheckPlayerHit_Next
                bsr.w   Collision_CheckObjectPair
                tst.b   d0
                beq.s   Lizard_CheckPlayerHit_Next
                move.w  #$14,$3C(a0)
                clr.b   5(a0)
                move.l  $34(a1),d7
                move.l  $2C(a1),d6
                move.l  d7,$34(a0)
                move.l  d6,$2C(a0)
                addq.b  #1,$3B(a1)
                moveq   #0,d0
                move.b  $3B(a1),d0
                subq.b  #1,d0
                lsl.w   #2,d0
                move.l  Lizard_HitScoreTable(pc,d0.w),d0
                move.l  d0,(Ram_ScoreDelta).w
                move.l  a1,-(sp)
                bsr.w   Score_AddAndCheck
                movea.l (sp)+,a1
                lea     (Ram_PopupSlots).w,a2
                moveq   #3,d0

Lizard_CheckPlayerHit_PopupLoop:
                tst.b   (a2)
                bne.s   Lizard_CheckPlayerHit_PopupNext
                move.w  #$1C,(a2)
                move.b  $3B(a1),d1
                move.b  d1,$3A(a2)
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subq.w  #8,d6
                move.w  d7,$30(a2)
                move.w  d6,$24(a2)
                bra.s   Lizard_CheckPlayerHit_Return

Lizard_CheckPlayerHit_PopupNext:
                lea     -$40(a2),a2
                dbf     d0,Lizard_CheckPlayerHit_PopupLoop
                bra.s   Lizard_CheckPlayerHit_Return

Lizard_CheckPlayerHit_Next:
                lea     $40(a1),a1
                move.w  (sp)+,d0
                dbf     d0,Lizard_CheckPlayerHit_Loop
                rts

Lizard_CheckPlayerHit_Return:
                move.w  (sp)+,d0
                rts

Lizard_HitScoreTable:   dc.l    $200
                dc.l    $400
                dc.l    $800
                dc.l    $1600
Lizard_AnimPointers:    dc.l    Lizard_AnimWait
                dc.l    Lizard_AnimRun
                dc.l    Lizard_AnimJump
                dc.l    Lizard_AnimStunned
                dc.l    Lizard_AnimDeath
Lizard_AnimWait:    dc.b    6, $C
                dc.w    Lizard_WaitFrame0-Sys_GameEntryPoint
                dc.w    Lizard_WaitFrame1-Sys_GameEntryPoint
                dc.w    Lizard_WaitFrame0-Sys_GameEntryPoint
                dc.w    Lizard_WaitFrame1-Sys_GameEntryPoint
                dc.w    Lizard_WaitFrame2-Sys_GameEntryPoint
                dc.w    Lizard_WaitFrame3-Sys_GameEntryPoint
Lizard_AnimRun: dc.b    8, 1
                dc.w    Lizard_StateLocateData-Sys_GameEntryPoint
                dc.w    Lizard_RunFrame1-Sys_GameEntryPoint
                dc.w    Lizard_RunFrame2-Sys_GameEntryPoint
                dc.w    Lizard_RunFrame3-Sys_GameEntryPoint
                dc.w    Lizard_RunFrame3-Sys_GameEntryPoint
                dc.w    Lizard_RunFrame4-Sys_GameEntryPoint
                dc.w    Lizard_RunFrame2-Sys_GameEntryPoint
                dc.w    Lizard_RunFrame1-Sys_GameEntryPoint
Lizard_AnimJump:    dc.b    8, 1
                dc.w    Lizard_JumpFrame0-Sys_GameEntryPoint
                dc.w    Guide_CharacterMap10-Sys_GameEntryPoint
                dc.w    Lizard_JumpFrame2-Sys_GameEntryPoint
                dc.w    Lizard_JumpFrame3-Sys_GameEntryPoint
                dc.w    Lizard_JumpFrame4-Sys_GameEntryPoint
                dc.w    Lizard_JumpFrame5-Sys_GameEntryPoint
                dc.w    Lizard_JumpFrame6-Sys_GameEntryPoint
                dc.w    Lizard_JumpFrame7-Sys_GameEntryPoint
Lizard_AnimStunned: dc.b    4, 5
                dc.w    Lizard_StunnedFrame0-Sys_GameEntryPoint
                dc.w    Lizard_StunnedFrame0-Sys_GameEntryPoint
                dc.w    Lizard_StunnedFrame1-Sys_GameEntryPoint
                dc.w    Lizard_StunnedFrame2-Sys_GameEntryPoint
Lizard_AnimDeath:   dc.b    4, 6
                dc.w    Lizard_DeathFrame0-Sys_GameEntryPoint
                dc.w    Lizard_DeathFrame0-Sys_GameEntryPoint
                dc.w    Lizard_DeathFrame1-Sys_GameEntryPoint
                dc.w    Lizard_DeathFrame2-Sys_GameEntryPoint
