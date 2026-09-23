; Tiger cat and its animation tables
; ROM $014EC6-$015507

Obj_Tiger:
                bset    #7,(a0)
                bne.s   Obj_Tiger_Dispatch
                moveq   #0,d7
                moveq   #0,d6
                move.b  $3E(a0),d7
                move.b  $3F(a0),d6
                bsr.w   Math_GridToScreen
                addq.w  #8,d7
                addi.w  #$10,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)
                move.l  #Tiger_AnimPointers,8(a0)
                clr.l   $34(a0)
                clr.l   $2C(a0)

Obj_Tiger_Dispatch:
                tst.b   (Ram_CutsceneFlag).w
                bne.s   Obj_Tiger_UpdateFacing
                tst.b   (Ram_RoundEndingFlag).w
                bne.s   Obj_Tiger_UpdateFacing
                tst.b   (Ram_PlayerHitFlag).w
                bne.s   Obj_Tiger_UpdateFacing
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     Tiger_StateTable(pc,d0.w)
                move.w  $3C(a0),d0
                andi.w  #$7FFC,d0
                cmpi.w  #$14,d0
                beq.s   Obj_Tiger_UpdateFacing
                cmpi.w  #$1C,d0
                beq.s   Obj_Tiger_UpdateFacing
                bsr.w   Tiger_CheckPlayerHit

Obj_Tiger_UpdateFacing:
                move.l  $34(a0),d0
                beq.s   Obj_Tiger_Return
                move.b  #1,$39(a0)
                tst.l   d0
                bmi.s   Obj_Tiger_Return
                clr.b   $39(a0)

Obj_Tiger_Return:
                rts

Tiger_StateTable:
                bra.w   Tiger_StateWait
                bra.w   Tiger_StateLocate
                bra.w   Tiger_StateChase
                bra.w   Tiger_StateJump
                bra.w   Tiger_StateStunned
                bra.w   Tiger_StateHit
                bra.w   Tiger_StateTrack
                bra.w   Tiger_StateDeath

; Tiger state: waiting/idle after hit
Tiger_StateWait:
                bset    #7,$3C(a0)
                bne.s   Tiger_StateWait_Update
                clr.w   6(a0)
                bclr    #2,2(a0)
                clr.b   $10(a0)
                move.b  #6,5(a0)

Tiger_StateWait_Update:
                bsr.w   Object_UpdatePosition
                bsr.w   Anim_UpdateFrame
                bclr    #2,2(a0)
                beq.s   Tiger_StateWait_Return
                move.w  #8,$3C(a0)
                lea     (Ram_PlayerObject).w,a1
                move.w  $20(a0),d7
                move.w  $20(a1),d6
                clr.b   $39(a0)
                cmp.w   d7,d6
                bgt.s   Tiger_StateWait_CheckEarlyRound
                move.b  #1,$39(a0)

Tiger_StateWait_CheckEarlyRound:
                cmpi.w  #$30,(Ram_RoundTime).w
                bhi.s   Tiger_StateWait_Return
                cmpi.b  #$31,(Ram_RoundNumber+1).w
                bhi.s   Tiger_StateWait_Return
                clr.b   $39(a0)
                tst.b   $16(a0)
                beq.s   Tiger_StateWait_Return
                move.b  #1,$39(a0)

Tiger_StateWait_Return:
                rts

; Tiger state: locating player direction
Tiger_StateLocate:
                bset    #7,$3C(a0)
                bne.s   Tiger_StateLocate_Compare
                move.b  #7,5(a0)
                clr.l   $34(a0)
                move.b  #$14,$3B(a0)
                move.l  #Tiger_StateLocateData,$C(a0)
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   Tiger_StateLocate_Compare
                bset    #7,2(a0)

Tiger_StateLocate_Compare:
                bsr.w   Object_UpdatePosition
                move.w  $20(a0),d7
                move.w  $24(a0),d6
                lea     (Ram_PlayerObject).w,a1
                move.w  Ram_PlayerScreenX-Ram_PlayerObject(a1),d5
                move.w  $24(a1),d4
                cmp.w   d6,d4
                beq.s   Tiger_StateLocate_SameRow
                move.b  #2,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

Tiger_StateLocate_SameRow:
                tst.b   $39(a0)
                bne.s   Tiger_StateLocate_FacingLeft
                cmp.w   d7,d5
                bgt.s   Tiger_StateLocate_TurnRight
                move.w  #$10,$3C(a0)
                rts

Tiger_StateLocate_TurnRight:
                move.b  #1,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

Tiger_StateLocate_FacingLeft:
                cmp.w   d7,d5
                blt.s   Tiger_StateLocate_TurnLeft
                move.w  #$10,$3C(a0)
                rts

Tiger_StateLocate_TurnLeft:
                move.b  #1,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

; Tiger state: running/chasing horizontally
Tiger_StateChase:
                bset    #7,$3C(a0)
                bne.s   Tiger_StateChase_Move
                move.b  #7,5(a0)
                move.l  (Ram_TigerSpeed).w,$34(a0)
                tst.b   $16(a0)
                beq.s   Tiger_StateChase_ApplyFacing
                move.l  #$14000,$34(a0)

Tiger_StateChase_ApplyFacing:
                tst.b   $39(a0)
                beq.s   Tiger_StateChase_Move
                neg.l   $34(a0)

Tiger_StateChase_Move:
                bsr.w   Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subq.w  #8,d6
                tst.l   $34(a0)
                bpl.s   Tiger_StateChase_ProbeRight
                subq.w  #8,d7
                bra.s   Tiger_StateChase_ProbeWall

Tiger_StateChase_ProbeRight:
                addq.w  #8,d7

Tiger_StateChase_ProbeWall:
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Tiger_StateChase_CheckGround
                neg.l   $34(a0)

Tiger_StateChase_CheckGround:
                moveq   #0,d7
                moveq   #1,d6
                bsr.w   Collision_GetTileAtObject
                btst    #7,d4
                bne.s   Tiger_StateChase_SpecialTile
                tst.l   $34(a0)
                bpl.s   Tiger_StateChase_EdgeRight
                btst    #2,d4
                bne.s   Tiger_StateChase_LeftDone
                move.w  #4,$3C(a0)

Tiger_StateChase_LeftDone:
                bra.s   Tiger_StateChase_Animate

Tiger_StateChase_EdgeRight:
                btst    #3,d4
                bne.s   Tiger_StateChase_RightDone
                move.w  #4,$3C(a0)

Tiger_StateChase_RightDone:
                bra.s   Tiger_StateChase_Animate

Tiger_StateChase_SpecialTile:
                tst.b   $39(a0)
                bne.s   Tiger_StateChase_SpecialFacingLeft
                btst    #6,d4
                bne.s   Tiger_StateChase_Animate
                bra.s   Tiger_StateChase_ComparePlayerRow

Tiger_StateChase_SpecialFacingLeft:
                btst    #6,d4
                beq.s   Tiger_StateChase_Animate

Tiger_StateChase_ComparePlayerRow:
                lea     (Ram_PlayerObject).w,a1
                move.w  $24(a0),d6
                cmp.w   $24(a1),d6
                blt.s   Tiger_StateChase_Animate
                beq.s   Tiger_StateChase_MaybeJump
                move.w  #$18,$3C(a0)

Tiger_StateChase_Animate:
                bclr    #7,2(a0)
                tst.l   $34(a0)
                bpl.s   Tiger_StateChase_Draw
                bset    #7,2(a0)

Tiger_StateChase_Draw:
                move.w  #4,6(a0)
                bsr.w   Anim_UpdateFrame
                rts

Tiger_StateChase_MaybeJump:
                cmpi.w  #$30,(Ram_RoundTime).w
                bls.s   Tiger_StateChase_Animate
                move.w  $20(a1),d7
                tst.b   $39(a0)
                beq.s   Tiger_StateChase_CheckAhead
                cmp.w   $20(a0),d7
                blt.s   Tiger_StateChase_Animate
                bra.s   Tiger_StateChase_StartJump

Tiger_StateChase_CheckAhead:
                cmp.w   $20(a0),d7
                bgt.s   Tiger_StateChase_Animate

Tiger_StateChase_StartJump:
                move.w  #$18,$3C(a0)
                bra.s   Tiger_StateChase_Animate

; Tiger state: jumping/leaping toward player
Tiger_StateJump:
                tst.b   $3B(a0)
                bne.w   Tiger_StateJump_Delay
                bset    #7,$3C(a0)
                bne.s   Tiger_StateJump_Move
                move.b  #7,5(a0)
                move.b  $3A(a0),d0
                beq.s   Tiger_StateJump_UseLevelArc
                cmpi.b  #1,d0
                beq.s   Tiger_StateJump_UseFixedArc
                move.l  (Ram_TigerJumpSpeed).w,$34(a0)
                move.l  #$FFFF8000,$2C(a0)
                bra.s   Tiger_StateJump_ApplyFacing

Tiger_StateJump_UseLevelArc:
                move.l  (Ram_TigerJumpVelX).w,$34(a0)
                move.l  (Ram_TigerJumpVelY).w,$2C(a0)
                bra.s   Tiger_StateJump_ApplyFacing

Tiger_StateJump_UseFixedArc:
                move.l  #$1A000,$34(a0)
                move.l  #$FFFF0000,$2C(a0)

Tiger_StateJump_ApplyFacing:
                tst.b   $39(a0)
                beq.s   Tiger_StateJump_Move
                neg.l   $34(a0)

Tiger_StateJump_Move:
                addi.l  #$1000,$2C(a0)
                bsr.w   Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                bne.s   Tiger_StateJump_Land
                subq.w  #8,d6
                tst.l   $34(a0)
                bpl.s   Tiger_StateJump_ProbeRight
                subq.w  #8,d7
                bra.s   Tiger_StateJump_ProbeWall

Tiger_StateJump_ProbeRight:
                addq.w  #8,d7

Tiger_StateJump_ProbeWall:
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Tiger_StateJump_CheckCeiling
                neg.l   $34(a0)
                bra.s   Tiger_StateJump_SelectFrame

Tiger_StateJump_CheckCeiling:
                tst.l   $2C(a0)
                bpl.s   Tiger_StateJump_Airborne
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subi.w  #$D,d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Tiger_StateJump_Airborne
                clr.l   $2C(a0)

Tiger_StateJump_Airborne:
                bra.s   Tiger_StateJump_SelectFrame

Tiger_StateJump_Land:
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)
                move.w  #8,$3C(a0)

Tiger_StateJump_SelectFrame:
                move.l  #Tiger_StateJump_SelectFrameData0,$C(a0)
                tst.l   $2C(a0)
                bmi.s   Tiger_StateJump_SetFacing
                move.l  #Tiger_StateJump_SelectFrameData1,$C(a0)

Tiger_StateJump_SetFacing:
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   Tiger_StateJump_Return
                bset    #7,2(a0)

Tiger_StateJump_Return:
                rts

Tiger_StateJump_Delay:
                subq.b  #1,$3B(a0)
                bsr.w   Object_UpdatePosition
                rts

; Tiger state: stunned/recovering after hit
Tiger_StateStunned:
                tst.b   $3B(a0)
                bne.s   Tiger_StateStunned_Delay
                bset    #7,$3C(a0)
                bne.s   Tiger_StateStunned_Move
                move.b  #7,5(a0)
                bclr    #2,2(a0)
                move.w  #$C,6(a0)
                clr.b   $10(a0)

Tiger_StateStunned_Move:
                bsr.w   Object_UpdatePosition
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   Tiger_StateStunned_Animate
                bset    #7,2(a0)

Tiger_StateStunned_Animate:
                bsr.w   Anim_UpdateFrame
                bclr    #2,2(a0)
                beq.s   Tiger_StateStunned_Return
                bchg    #0,$39(a0)
                move.w  #8,$3C(a0)

Tiger_StateStunned_Return:
                rts

Tiger_StateStunned_Delay:
                subq.b  #1,$3B(a0)
                bsr.w   Object_UpdatePosition
                rts

; Tiger state: hit by player bouncing
Tiger_StateHit:
                bset    #7,$3C(a0)
                bne.s   Tiger_StateHit_Move
                move.l  a0,-(sp)
                move.b  #$93,d0
                bsr.w   Sound_PlayNoteIfActive
                movea.l (sp)+,a0
                tst.b   $16(a0)
                bne.s   Tiger_StateHit_Setup
                addi.l  #$1000,(Ram_TigerSpeed).w

Tiger_StateHit_Setup:
                clr.b   5(a0)
                move.w  #8,6(a0)
                subq.b  #1,(Ram_ActiveEnemyCount).w

Tiger_StateHit_Move:
                bsr.w   Throwable_UpdatePhysics
                tst.l   $34(a0)
                bne.s   Tiger_StateHit_Return
                move.w  #$1C,$3C(a0)

Tiger_StateHit_Return:
                rts

; Tiger state: tracking player alternate
Tiger_StateTrack:
                bset    #7,$3C(a0)
                bne.s   Tiger_StateTrack_Compare
                move.b  #7,5(a0)
                clr.l   $34(a0)
                move.b  #$14,$3B(a0)
                move.l  #Tiger_StateLocateData,$C(a0)
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   Tiger_StateTrack_Compare
                bset    #7,2(a0)

Tiger_StateTrack_Compare:
                bsr.w   Object_UpdatePosition
                move.w  $20(a0),d7
                move.w  $24(a0),d6
                lea     (Ram_PlayerObject).w,a1
                move.w  Ram_PlayerScreenX-Ram_PlayerObject(a1),d5
                move.w  $24(a1),d4
                cmp.w   d6,d4
                beq.s   Tiger_StateTrack_SameRow
                bgt.s   Tiger_StateTrack_PlayerBelow
                clr.b   $3A(a0)
                move.w  #$C,$3C(a0)
                rts

Tiger_StateTrack_PlayerBelow:
                move.b  #2,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

Tiger_StateTrack_SameRow:
                tst.b   $39(a0)
                bne.s   Tiger_StateTrack_FacingLeft
                cmp.w   d7,d5
                bgt.s   Tiger_StateTrack_TurnRight
                move.w  #$10,$3C(a0)
                rts

Tiger_StateTrack_TurnRight:
                move.b  #1,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

Tiger_StateTrack_FacingLeft:
                cmp.w   d7,d5
                blt.s   Tiger_StateTrack_TurnLeft
                move.w  #$10,$3C(a0)
                rts

Tiger_StateTrack_TurnLeft:
                move.b  #1,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

; Decrements Tiger action timer
Tiger_DecrementTimer:
                subq.b  #1,$3B(a0)
                bsr.w   Object_UpdatePosition
                rts

; Tiger state: death anim spawns new enemy
Tiger_StateDeath:
                bset    #7,$3C(a0)
                bne.s   Tiger_StateDeath_Update
                clr.b   5(a0)
                bclr    #2,2(a0)
                move.w  #$10,6(a0)
                clr.b   $10(a0)
                move.l  #$FFFFC000,$2C(a0)

Tiger_StateDeath_Update:
                bsr.w   Object_UpdatePosition
                bsr.w   Anim_UpdateFrame
                btst    #2,2(a0)
                beq.s   Tiger_StateDeath_Return
                move.b  (Ram_RoundTime+2).w,d0
                andi.b  #$F0,d0
                bne.s   Tiger_StateDeath_ClearSprites
                lea     (Ram_TigerRespawnSlot).w,a1
                tst.b   $16(a0)
                beq.s   Tiger_StateDeath_SpawnAt
                lea     $40(a1),a1

Tiger_StateDeath_SpawnAt:
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                move.w  d7,$30(a1)
                move.w  d6,$24(a1)
                move.w  #$28,(a1)

Tiger_StateDeath_ClearSprites:
                bsr.w   Sprite_ClearLinkTable

Tiger_StateDeath_Return:
                rts

; Tiger collision with player hit detection
Tiger_CheckPlayerHit:
                lea     (Ram_SpawnerSlots).w,a1
                moveq   #5,d0

Tiger_CheckPlayerHit_Loop:
                move.w  d0,-(sp)
                btst    #3,5(a1)
                beq.s   Tiger_CheckPlayerHit_Next
                bsr.w   Collision_CheckObjectPair
                tst.b   d0
                beq.s   Tiger_CheckPlayerHit_Next
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
                move.l  Tiger_HitScoreTable(pc,d0.w),d0
                move.l  d0,(Ram_ScoreDelta).w
                move.l  a1,-(sp)
                bsr.w   Score_AddAndCheck
                movea.l (sp)+,a1
                lea     (Ram_PopupSlots).w,a2
                moveq   #3,d0

Tiger_CheckPlayerHit_PopupLoop:
                tst.b   (a2)
                bne.s   Tiger_CheckPlayerHit_PopupNext
                move.w  #$1C,(a2)
                move.b  $3B(a1),d1
                move.b  d1,$3A(a2)
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subq.w  #8,d6
                move.w  d7,$30(a2)
                move.w  d6,$24(a2)
                bra.s   Tiger_CheckPlayerHit_Return

Tiger_CheckPlayerHit_PopupNext:
                lea     -$40(a2),a2
                dbf     d0,Tiger_CheckPlayerHit_PopupLoop
                bra.s   Tiger_CheckPlayerHit_Return

Tiger_CheckPlayerHit_Next:
                lea     $40(a1),a1
                move.w  (sp)+,d0
                dbf     d0,Tiger_CheckPlayerHit_Loop
                rts

Tiger_CheckPlayerHit_Return:
                move.w  (sp)+,d0
                rts

Tiger_HitScoreTable:    dc.l    $200
                dc.l    $400
                dc.l    $800
                dc.l    $1600
Tiger_AnimPointers: dc.l    Tiger_AnimWait
                dc.l    Tiger_AnimRun
                dc.l    Tiger_AnimJump
                dc.l    Tiger_AnimStunned
                dc.l    Tiger_AnimDeath
Tiger_AnimWait: dc.b    6, $C
                dc.w    Tiger_WaitFrame0-Sys_GameEntryPoint
                dc.w    Tiger_WaitFrame1-Sys_GameEntryPoint
                dc.w    Tiger_WaitFrame0-Sys_GameEntryPoint
                dc.w    Tiger_WaitFrame1-Sys_GameEntryPoint
                dc.w    Tiger_WaitFrame2-Sys_GameEntryPoint
                dc.w    Tiger_WaitFrame3-Sys_GameEntryPoint
Tiger_AnimRun:  dc.b    8, 1
                dc.w    Tiger_StateLocateData-Sys_GameEntryPoint
                dc.w    Tiger_RunFrame1-Sys_GameEntryPoint
                dc.w    Tiger_RunFrame2-Sys_GameEntryPoint
                dc.w    Tiger_RunFrame3-Sys_GameEntryPoint
                dc.w    Tiger_RunFrame3-Sys_GameEntryPoint
                dc.w    Tiger_RunFrame4-Sys_GameEntryPoint
                dc.w    Tiger_RunFrame2-Sys_GameEntryPoint
                dc.w    Tiger_RunFrame1-Sys_GameEntryPoint
Tiger_AnimJump: dc.b    8, 1
                dc.w    Tiger_JumpFrame0-Sys_GameEntryPoint
                dc.w    Guide_CharacterMap10-Sys_GameEntryPoint
                dc.w    Tiger_JumpFrame2-Sys_GameEntryPoint
                dc.w    Tiger_JumpFrame3-Sys_GameEntryPoint
                dc.w    Tiger_JumpFrame4-Sys_GameEntryPoint
                dc.w    Tiger_JumpFrame5-Sys_GameEntryPoint
                dc.w    Tiger_JumpFrame6-Sys_GameEntryPoint
                dc.w    Tiger_JumpFrame7-Sys_GameEntryPoint
Tiger_AnimStunned:  dc.b    4, 5
                dc.w    Tiger_StunnedFrame0-Sys_GameEntryPoint
                dc.w    Tiger_StunnedFrame0-Sys_GameEntryPoint
                dc.w    Tiger_StunnedFrame1-Sys_GameEntryPoint
                dc.w    Tiger_StunnedFrame2-Sys_GameEntryPoint
Tiger_AnimDeath:    dc.b    4, 6
                dc.w    Tiger_DeathFrame0-Sys_GameEntryPoint
                dc.w    Tiger_DeathFrame0-Sys_GameEntryPoint
                dc.w    Tiger_DeathFrame1-Sys_GameEntryPoint
                dc.w    Tiger_DeathFrame2-Sys_GameEntryPoint
