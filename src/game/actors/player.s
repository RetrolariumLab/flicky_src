; Player object
; ROM $013E70-$0144DB

Obj_Player:
                bset    #7,(a0)
                bne.s   Obj_Player_Update
                move.l  #Player_AnimPointers,8(a0)
                move.b  $3E(a0),d7
                move.b  $3F(a0),d6
                bsr.w   Math_GridToScreen
                addi.w  #$C,d7
                addi.w  #$18,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)
                move.b  #3,$3A(a0)

Obj_Player_Update:
                tst.b   (Ram_CutsceneFlag).w
                bne.s   Obj_Player_Return
                tst.b   (Ram_RoundEndingFlag).w
                bne.s   Obj_Player_CheckProjectiles
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     Player_StateTable(pc,d0.w)

Obj_Player_CheckProjectiles:
                move.w  $3C(a0),d0
                andi.w  #$7C,d0
                cmpi.w  #4,d0
                bcc.s   Obj_Player_RecordAndAnimate
                tst.b   (Ram_RoundEndingFlag).w
                bne.s   Obj_Player_RecordAndAnimate
                bsr.w   Player_CheckProjectileHit

Obj_Player_RecordAndAnimate:
                bsr.w   Player_RecordHistory
                tst.b   (Ram_BonusRoundFlag).w
                bne.s   Obj_Player_Return
                bsr.w   UI_AnimateEntryArrow

Obj_Player_Return:
                rts

Player_StateTable:
                bra.w   Player_StateNormal
                bra.w   Player_StateDeath
                bra.w   Player_StateRespawn

; Player state: normal walking/running gameplay
Player_StateNormal:
                move.b  #$1E,5(a0)
                bsr.s   Player_ProcessInput
                bsr.w   Player_CheckExit
                tst.b   (Ram_RoundEndingFlag).w
                bne.s   Player_StateNormal_Move
                bsr.w   Camera_UpdateScroll

Player_StateNormal_Move:
                bsr.w   Object_UpdatePosition
                bsr.w   Player_CheckGround
                bsr.w   Player_CheckWalls
                bsr.w   Player_UpdateAnim
                move.l  $34(a0),d0
                beq.s   Player_StateNormal_Return
                move.b  #1,$39(a0)
                tst.l   d0
                bmi.s   Player_StateNormal_Return
                clr.b   $39(a0)

Player_StateNormal_Return:
                rts

; Player input processing: joypad to velocity
Player_ProcessInput:
                move.b  (Ram_Joypad).w,d0
                andi.b  #$C,d0
                beq.w   Player_ProcessInput_NoDirection
                btst    #3,d0
                bne.w   Player_ProcessInput_AccelerateRight
                btst    #2,d0
                bne.w   Player_ProcessInput_AccelerateLeft

Player_ProcessInput_Apply:
                move.l  $30(a0),d2
                move.l  d1,$34(a0)
                tst.b   (Ram_BonusRoundFlag).w
                bne.s   Player_ProcessInput_CheckJump
                move.l  d1,(Ram_CameraVelocityX).w

Player_ProcessInput_CheckJump:
                bsr.w   Player_ThrowItem
                tst.b   $38(a0)
                bne.w   Player_ProcessInput_Airborne
                btst    #0,$3A(a0)
                beq.s   Player_ProcessInput_CheckRelease
                move.b  (Ram_Joypad).w,d0
                andi.b  #$70,d0
                beq.s   Player_ProcessInput_CheckRelease
                move.l  a0,-(sp)
                move.b  #$91,d0
                bsr.w   Sound_PlayNoteIfActive
                movea.l (sp)+,a0
                move.b  #1,$38(a0)
                move.l  #$FFFD7000,$2C(a0)
                bclr    #0,$3A(a0)
                bclr    #1,$3A(a0)

Player_ProcessInput_CheckRelease:
                move.b  (Ram_Joypad).w,d0
                andi.b  #$70,d0
                bne.s   Player_ProcessInput_Return
                move.b  #3,$3A(a0)

Player_ProcessInput_Return:
                rts

Player_ProcessInput_NoDirection:
                move.l  $34(a0),d1
                tst.b   $38(a0)
                bne.s   Player_ProcessInput_Apply
                tst.l   d1
                beq.s   Player_ProcessInput_Decelerated
                tst.l   d1
                bmi.s   Player_ProcessInput_DecelerateLeft
                subi.l  #$600,d1
                bra.s   Player_ProcessInput_Decelerated

Player_ProcessInput_DecelerateLeft:
                addi.l  #$600,d1

Player_ProcessInput_Decelerated:
                bra.w   Player_ProcessInput_Apply

Player_ProcessInput_AccelerateRight:
                move.l  $34(a0),d1
                cmpi.l  #$18000,d1
                bge.s   Player_ProcessInput_ClampRight
                addi.l  #$1800,d1
                bra.s   Player_ProcessInput_RightDone

Player_ProcessInput_ClampRight:
                move.l  #$18000,d1

Player_ProcessInput_RightDone:
                bra.w   Player_ProcessInput_Apply

Player_ProcessInput_AccelerateLeft:
                move.l  $34(a0),d1
                cmpi.l  #$FFFE8000,d1
                ble.s   Player_ProcessInput_ClampLeft
                subi.l  #$1800,d1
                bra.s   Player_ProcessInput_LeftDone

Player_ProcessInput_ClampLeft:
                move.l  #$FFFE8000,d1

Player_ProcessInput_LeftDone:
                bra.w   Player_ProcessInput_Apply

Player_ProcessInput_Airborne:
                cmpi.l  #$30000,$2C(a0)
                bge.s   Player_ProcessInput_AirReleaseCheck
                addi.l  #$1000,$2C(a0)

Player_ProcessInput_AirReleaseCheck:
                move.b  (Ram_Joypad).w,d0
                andi.b  #$70,d0
                bne.s   Player_ProcessInput_AirReturn
                move.b  #3,$3A(a0)

Player_ProcessInput_AirReturn:
                rts

; Clears player airborne/jump state
Player_ClearAirState:
                clr.b   $38(a0)
                clr.l   $2C(a0)
                rts

; Player throws held item when button pressed
Player_ThrowItem:
                btst    #1,$3A(a0)
                beq.s   Player_ThrowItem_Return
                move.b  (Ram_Joypad).w,d0
                andi.b  #$70,d0
                beq.s   Player_ThrowItem_Return
                tst.b   $3B(a0)
                beq.s   Player_ThrowItem_Return
                movea.l (Ram_HeldItemObject).w,a1
                move.w  #4,$34(a1)
                tst.b   $39(a0)
                beq.s   Player_ThrowItem_SetVelocity
                move.w  #$FFFC,$34(a1)

Player_ThrowItem_SetVelocity:
                move.w  #8,$3C(a1)
                move.l  $30(a0),$30(a1)
                clr.b   $3B(a0)
                bclr    #1,$3A(a0)

Player_ThrowItem_Return:
                rts

; Player ground check: standing on solid
Player_CheckGround:
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                tst.b   $38(a0)
                bne.s   Player_CheckGround_Airborne
                addq.w  #1,d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                bne.s   Player_CheckGround_Return
                move.b  #1,$38(a0)

Player_CheckGround_Return:
                rts

Player_CheckGround_Airborne:
                tst.l   $34(a0)
                bne.s   Player_CheckGround_Moving
                tst.l   $2C(a0)
                bpl.s   Player_CheckGround_Falling
                subi.w  #$E,d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Player_CheckGround_RisingReturn
                clr.l   $2C(a0)

Player_CheckGround_RisingReturn:
                rts

Player_CheckGround_Falling:
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Player_CheckGround_LandReturn
                clr.b   $38(a0)
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)

Player_CheckGround_LandReturn:
                rts

Player_CheckGround_Moving:
                tst.l   $2C(a0)
                bpl.s   Player_CheckGround_MovingFall
                subi.w  #$E,d6
                addq.w  #4,d7
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                bne.s   Player_CheckGround_StopRise
                subq.w  #8,d7
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Player_CheckGround_MovingRiseReturn

Player_CheckGround_StopRise:
                clr.l   $2C(a0)

Player_CheckGround_MovingRiseReturn:
                rts

Player_CheckGround_MovingFall:
                subq.w  #4,d7
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                bne.s   Player_CheckGround_MovingLand
                addq.w  #8,d7
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Player_CheckGround_MovingReturn

Player_CheckGround_MovingLand:
                clr.b   $38(a0)
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)

Player_CheckGround_MovingReturn:
                rts

; Player wall collision: left/right walls
Player_CheckWalls:
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                move.l  $34(a0),d5
                tst.b   $38(a0)
                bne.s   Player_CheckWalls_Airborne
                subi.w  #$A,d6
                tst.l   d5
                beq.s   Player_CheckWalls_Return
                tst.l   d5
                bpl.s   Player_CheckWalls_TestRight
                subq.w  #6,d7
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Player_CheckWalls_Return
                move.l  $34(a0),d0
                subi.l  #$3000,d0
                cmpi.l  #$FFFE0200,d0
                bge.s   Player_CheckWalls_ClampLeftBounce
                move.l  #$FFFE0200,d0

Player_CheckWalls_ClampLeftBounce:
                neg.l   d0
                move.l  d0,$34(a0)

Player_CheckWalls_Return:
                rts

Player_CheckWalls_TestRight:
                addq.w  #6,d7
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Player_CheckWalls_RightReturn
                move.l  $34(a0),d0
                addi.l  #$3000,d0
                cmpi.l  #$1FE00,d0
                ble.s   Player_CheckWalls_ClampRightBounce
                move.l  #$1FE00,d0

Player_CheckWalls_ClampRightBounce:
                neg.l   d0
                move.l  d0,$34(a0)

Player_CheckWalls_RightReturn:
                rts

Player_CheckWalls_Airborne:
                subq.w  #8,d6
                tst.l   d5
                beq.w   Player_CheckWalls_NoVelocity
                tst.l   d5
                bpl.s   Player_CheckWalls_AirTestRight
                subq.w  #6,d7
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Player_CheckWalls_AirLeftReturn
                btst    #1,d4
                bne.s   Player_CheckWalls_AirBounceLeft
                btst    #0,d4
                beq.s   Player_CheckWalls_Ceiling

Player_CheckWalls_AirBounceLeft:
                move.l  $34(a0),d0
                subi.l  #$3000,d0
                cmpi.l  #$FFFE0200,d0
                bge.s   Player_CheckWalls_AirClampLeft
                move.l  #$FFFE0200,d0

Player_CheckWalls_AirClampLeft:
                neg.l   d0
                move.l  d0,$34(a0)

Player_CheckWalls_AirLeftReturn:
                rts

Player_CheckWalls_AirTestRight:
                addq.w  #6,d7
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Player_CheckWalls_AirRightReturn
                btst    #1,d4
                bne.s   Player_CheckWalls_AirBounceRight
                btst    #0,d4
                beq.s   Player_CheckWalls_Ceiling

Player_CheckWalls_AirBounceRight:
                move.l  $34(a0),d0
                addi.l  #$3000,d0
                cmpi.l  #$1FE00,d0
                ble.s   Player_CheckWalls_AirClampRight
                move.l  #$1FE00,d0

Player_CheckWalls_AirClampRight:
                neg.l   d0
                move.l  d0,$34(a0)

Player_CheckWalls_AirRightReturn:
                rts

Player_CheckWalls_Ceiling:
                tst.l   $2C(a0)
                bpl.s   Player_CheckWalls_SnapToFloor
                move.w  d6,d0
                andi.w  #7,d0
                cmpi.w  #3,d0
                blt.s   Player_CheckWalls_CeilingReturn
                addi.w  #$10,d6
                move.w  d6,$24(a0)
                clr.l   $2C(a0)

Player_CheckWalls_CeilingReturn:
                rts

Player_CheckWalls_SnapToFloor:
                andi.w  #$FFF8,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                clr.l   $2C(a0)
                clr.b   $38(a0)
                rts

Player_CheckWalls_NoVelocity:
                addq.w  #6,d7
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Player_CheckWalls_PushRight
                move.l  #$FFFF4000,$34(a0)
                bra.s   Player_CheckWalls_PushReturn

Player_CheckWalls_PushRight:
                subi.w  #$C,d7
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Player_CheckWalls_PushReturn
                move.l  #$C000,$34(a0)

Player_CheckWalls_PushReturn:
                rts

; Records player position history for chicks
Player_RecordHistory:
                lea     (Ram_PlayerTrailXShift).w,a2
                lea     (Ram_PlayerTrailXLast).w,a1
                lea     (Ram_PlayerTrailYShift).w,a4
                lea     (Ram_PlayerTrailYLast).w,a3
                moveq   #$3F,d0

Player_RecordHistory_ShiftLoop:
                move.l  (a1),(a2)
                move.l  (a3),(a4)
                subq.l  #8,a1
                subq.l  #8,a2
                subq.l  #8,a3
                subq.l  #8,a4
                dbf     d0,Player_RecordHistory_ShiftLoop
                lea     (Ram_BonusRoundFlag).w,a2
                lea     (Ram_PlayerTrailFlagsLast).w,a1
                moveq   #$3F,d0

Player_RecordHistory_ShiftFlagsLoop:
                move.b  -(a1),-(a2)
                dbf     d0,Player_RecordHistory_ShiftFlagsLoop
                move.l  $30(a0),(Ram_PlayerTrailX).w
                move.l  $24(a0),(Ram_PlayerTrailY).w
                moveq   #0,d0
                tst.b   $38(a0)
                beq.s   Player_RecordHistory_EncodeDirection
                bset    #7,d0

Player_RecordHistory_EncodeDirection:
                move.l  $34(a0),d7
                beq.s   Player_RecordHistory_Store
                tst.l   d7
                bpl.s   Player_RecordHistory_FacingRight
                bset    #1,d0
                bra.s   Player_RecordHistory_Store

Player_RecordHistory_FacingRight:
                bset    #0,d0

Player_RecordHistory_Store:
                move.b  d0,(Ram_PlayerTrailFlags).w
                rts

; Player checks if entered exit door
Player_CheckExit:
                tst.b   (Ram_ChickChainCount).w
                beq.s   Player_CheckExit_Return
                tst.b   $38(a0)
                bne.s   Player_CheckExit_Return
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                cmp.w   (Ram_ExitDoorY).w,d6
                bne.s   Player_CheckExit_Return
                cmp.w   (Ram_ExitDoorLeftX).w,d7
                blt.s   Player_CheckExit_Return
                cmp.w   (Ram_ExitDoorRightX).w,d7
                bgt.s   Player_CheckExit_Return
                move.b  #1,(Ram_RoundEndingFlag).w
                clr.l   $34(a0)
                clr.l   (Ram_CameraVelocityX).w
                addq.b  #1,(Ram_ExitReachedFlag).w
                move.l  a0,-(sp)
                bsr.w   UI_AnimateCatCountReverse
                movea.l (sp)+,a0

Player_CheckExit_Return:
                rts

; Player animation based on movement state
Player_UpdateAnim:
                bclr    #7,2(a0)
                move.l  $34(a0),d0
                move.b  (Ram_Joypad).w,d1
                tst.b   $38(a0)
                bne.s   Player_UpdateAnim_Airborne
                tst.l   d0
                beq.s   Player_UpdateAnim_Standing
                tst.l   d0
                bpl.s   Player_UpdateAnim_FacingRight
                bset    #7,2(a0)
                btst    #2,d1
                bne.s   Player_UpdateAnim_Walking
                bra.s   Player_UpdateAnim_Braking

Player_UpdateAnim_FacingRight:
                btst    #3,d1
                bne.s   Player_UpdateAnim_Walking

Player_UpdateAnim_Braking:
                move.l  #Player_UpdateAnim_BrakingData,$C(a0)
                rts

Player_UpdateAnim_Walking:
                clr.w   6(a0)
                bsr.w   Anim_UpdateFrame
                rts

Player_UpdateAnim_Standing:
                move.l  #Guide_CharacterMap6,$C(a0)
                rts

Player_UpdateAnim_Airborne:
                tst.l   d0
                beq.s   Player_UpdateAnim_AirIdle
                move.w  #8,6(a0)
                tst.l   d0
                bpl.s   Player_UpdateAnim_AirFrame
                bset    #7,2(a0)

Player_UpdateAnim_AirFrame:
                bsr.w   Anim_UpdateFrame
                rts

Player_UpdateAnim_AirIdle:
                move.w  #4,6(a0)
                bsr.w   Anim_UpdateFrame
                rts

; Player state: death falling animation
Player_StateDeath:
                bset    #7,$3C(a0)
                bne.s   Player_StateDeath_Fall
                move.l  a0,-(sp)
                move.b  #$87,d0
                jsr     j_Sound_QueueToBuffer
                movea.l (sp)+,a0
                clr.b   5(a0)
                clr.l   $34(a0)
                move.w  #$C,6(a0)

Player_StateDeath_Fall:
                addi.l  #$1000,$2C(a0)
                bsr.w   Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                bne.s   Player_StateDeath_Land
                tst.l   $2C(a0)
                bpl.s   Player_StateDeath_Animate
                subq.w  #8,d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Player_StateDeath_Animate
                clr.l   $2C(a0)

Player_StateDeath_Animate:
                bsr.w   Anim_UpdateFrame
                rts

Player_StateDeath_Land:
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)
                move.w  #8,$3C(a0)
                rts

; Player state: respawn with invincibility
Player_StateRespawn:
                bset    #7,$3C(a0)
                bne.s   Player_StateRespawn_Update
                clr.b   5(a0)
                clr.b   $10(a0)
                bclr    #2,2(a0)
                move.b  #3,$39(a0)

Player_StateRespawn_Update:
                bsr.w   Object_UpdatePosition
                bsr.w   Anim_UpdateFrame
                bclr    #2,2(a0)
                beq.s   Player_StateRespawn_CheckDone
                subq.b  #1,$39(a0)
                bsr.w   Enemy_ClearProjectiles

Player_StateRespawn_CheckDone:
                tst.b   $39(a0)
                bne.s   Player_StateRespawn_Return
                subq.b  #1,(Ram_Lives).w
                beq.s   Player_StateRespawn_GameOver
                move.b  #1,(Ram_RestoreEnemiesFlag).w
                bsr.w   Enemy_BackupToBuffer
                move.w  #$20,(Ram_NextGameMode).w
                moveq   #$3C,d2

Player_StateRespawn_DelayLoop:
                bsr.w   Timer_IncrementTime
                jsr     j_Sound_QueueSFX
                dbf     d2,Player_StateRespawn_DelayLoop
                bra.s   Player_StateRespawn_Return

Player_StateRespawn_GameOver:
                move.w  #$10,(Ram_GameState).w

Player_StateRespawn_Return:
                rts

; Clears enemy projectile object slots
Enemy_ClearProjectiles:
                lea     (Ram_ProjectileSlots).w,a1
                moveq   #2,d0

Enemy_ClearProjectiles_Loop:
                clr.w   (a1)
                lea     $40(a1),a1
                dbf     d0,Enemy_ClearProjectiles_Loop
                rts

; Checks player collision with projectiles
Player_CheckProjectileHit:
                lea     (Ram_ProjectileSlots).w,a1
                moveq   #2,d1

Player_CheckProjectileHit_Loop:
                btst    #0,5(a1)
                beq.s   Player_CheckProjectileHit_Next
                movem.w d1,-(sp)
                bsr.w   Collision_CheckObjectPair
                movem.w (sp)+,d1
                tst.b   d0
                beq.s   Player_CheckProjectileHit_Next
                move.w  #4,$3C(a0)
                move.b  #1,(Ram_PlayerHitFlag).w
                bra.s   Player_CheckProjectileHit_Return

Player_CheckProjectileHit_Next:
                lea     $40(a1),a1
                dbf     d1,Player_CheckProjectileHit_Loop

Player_CheckProjectileHit_Return:
                rts

Player_AnimPointers:    dc.l    Player_AnimWalk
                dc.l    Player_AnimFly
                dc.l    Player_AnimBrake
                dc.l    Player_AnimDeath
Player_AnimWalk:    dc.b    2, 2
                dc.w    Guide_CharacterMap11-Sys_GameEntryPoint
                dc.w    Player_WalkFrame1-Sys_GameEntryPoint
Player_AnimFly: dc.b    2, 2
                dc.w    Player_FlyFrame0-Sys_GameEntryPoint
                dc.w    Player_FlyFrame1-Sys_GameEntryPoint
Player_AnimBrake:   dc.b    2, 2
                dc.w    Player_BrakeFrame0-Sys_GameEntryPoint
                dc.w    Guide_CharacterMap8-Sys_GameEntryPoint
Player_AnimDeath:   dc.b    6, 3
                dc.w    Player_DeathFrame0-Sys_GameEntryPoint
                dc.w    Player_DeathFrame1-Sys_GameEntryPoint
                dc.w    Player_DeathFrame2-Sys_GameEntryPoint
                dc.w    Player_DeathFrame3-Sys_GameEntryPoint
                dc.w    Player_DeathFrame2-Sys_GameEntryPoint
                dc.w    Player_DeathFrame3-Sys_GameEntryPoint
; Exit door object at level end
