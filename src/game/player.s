; Player object.
; ROM $013E70-$0144DB.

Obj_Player:
                bset    #7,(a0)  ; was: sub_13E70
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

Obj_Player_Update:  ; was: loc_13EA0
                tst.b   (byte_FFD27B).w
                bne.s   Obj_Player_Return
                tst.b   (byte_FFD24F).w
                bne.s   Obj_Player_CheckProjectiles
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     Player_StateTable(pc,d0.w)

Obj_Player_CheckProjectiles:  ; was: loc_13EB6
                move.w  $3C(a0),d0
                andi.w  #$7C,d0
                cmpi.w  #4,d0
                bcc.s   Obj_Player_RecordAndAnimate
                tst.b   (byte_FFD24F).w
                bne.s   Obj_Player_RecordAndAnimate
                bsr.w   Player_CheckProjectileHit

Obj_Player_RecordAndAnimate:  ; was: loc_13ECE
                bsr.w   Player_RecordHistory
                tst.b   (byte_FFD24E).w
                bne.s   Obj_Player_Return
                bsr.w   UI_AnimateEntryArrow

Obj_Player_Return:  ; was: locret_13EDC
                rts

Player_StateTable:  ; was: loc_13EDE
                bra.w   Player_StateNormal
                bra.w   Player_StateDeath
                bra.w   Player_StateRespawn

; Player state: normal walking/running gameplay
Player_StateNormal:
                move.b  #$1E,5(a0)  ; was: sub_13EEA
                bsr.s   Player_ProcessInput
                bsr.w   Player_CheckExit
                tst.b   (byte_FFD24F).w
                bne.s   Player_StateNormal_Move
                bsr.w   Camera_UpdateScroll

Player_StateNormal_Move:  ; was: loc_13F00
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

Player_StateNormal_Return:  ; was: locret_13F24
                rts

; Player input processing: joypad to velocity
Player_ProcessInput:
                move.b  (word_FFFF8E).w,d0  ; was: sub_13F26
                andi.b  #$C,d0
                beq.w   Player_ProcessInput_NoDirection
                btst    #3,d0
                bne.w   Player_ProcessInput_AccelerateRight
                btst    #2,d0
                bne.w   Player_ProcessInput_AccelerateLeft

Player_ProcessInput_Apply:  ; was: loc_13F42
                move.l  $30(a0),d2
                move.l  d1,$34(a0)
                tst.b   (byte_FFD24E).w
                bne.s   Player_ProcessInput_CheckJump
                move.l  d1,(dword_FFD004).w

Player_ProcessInput_CheckJump:  ; was: loc_13F54
                bsr.w   Player_ThrowChick
                tst.b   $38(a0)
                bne.w   Player_ProcessInput_Airborne
                btst    #0,$3A(a0)
                beq.s   Player_ProcessInput_CheckRelease
                move.b  (word_FFFF8E).w,d0
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

Player_ProcessInput_CheckRelease:  ; was: loc_13F98
                move.b  (word_FFFF8E).w,d0
                andi.b  #$70,d0
                bne.s   Player_ProcessInput_Return
                move.b  #3,$3A(a0)

Player_ProcessInput_Return:  ; was: locret_13FA8
                rts

Player_ProcessInput_NoDirection:  ; was: loc_13FAA
                move.l  $34(a0),d1
                tst.b   $38(a0)
                bne.s   Player_ProcessInput_Apply
                tst.l   d1
                beq.s   Player_ProcessInput_Decelerated
                tst.l   d1
                bmi.s   Player_ProcessInput_DecelerateLeft
                subi.l  #$600,d1
                bra.s   Player_ProcessInput_Decelerated

Player_ProcessInput_DecelerateLeft:  ; was: loc_13FC4
                addi.l  #$600,d1

Player_ProcessInput_Decelerated:  ; was: loc_13FCA
                bra.w   Player_ProcessInput_Apply

Player_ProcessInput_AccelerateRight:  ; was: loc_13FCE
                move.l  $34(a0),d1
                cmpi.l  #$18000,d1
                bge.s   Player_ProcessInput_ClampRight
                addi.l  #$1800,d1
                bra.s   Player_ProcessInput_RightDone

Player_ProcessInput_ClampRight:  ; was: loc_13FE2
                move.l  #$18000,d1

Player_ProcessInput_RightDone:  ; was: loc_13FE8
                bra.w   Player_ProcessInput_Apply

Player_ProcessInput_AccelerateLeft:  ; was: loc_13FEC
                move.l  $34(a0),d1
                cmpi.l  #$FFFE8000,d1
                ble.s   Player_ProcessInput_ClampLeft
                subi.l  #$1800,d1
                bra.s   Player_ProcessInput_LeftDone

Player_ProcessInput_ClampLeft:  ; was: loc_14000
                move.l  #$FFFE8000,d1

Player_ProcessInput_LeftDone:  ; was: loc_14006
                bra.w   Player_ProcessInput_Apply

Player_ProcessInput_Airborne:  ; was: loc_1400A
                cmpi.l  #$30000,$2C(a0)
                bge.s   Player_ProcessInput_AirReleaseCheck
                addi.l  #$1000,$2C(a0)

Player_ProcessInput_AirReleaseCheck:  ; was: loc_1401C
                move.b  (word_FFFF8E).w,d0
                andi.b  #$70,d0
                bne.s   Player_ProcessInput_AirReturn
                move.b  #3,$3A(a0)

Player_ProcessInput_AirReturn:  ; was: locret_1402C
                rts

; Clears player airborne/jump state
Player_ClearAirState:
                clr.b   $38(a0)  ; was: sub_1402E
                clr.l   $2C(a0)
                rts

; Player throws held chick when button pressed
Player_ThrowChick:
                btst    #1,$3A(a0)  ; was: sub_14038
                beq.s   Player_ThrowChick_Return
                move.b  (word_FFFF8E).w,d0
                andi.b  #$70,d0
                beq.s   Player_ThrowChick_Return
                tst.b   $3B(a0)
                beq.s   Player_ThrowChick_Return
                movea.l (dword_FFD250).w,a1
                move.w  #4,$34(a1)
                tst.b   $39(a0)
                beq.s   Player_ThrowChick_SetVelocity
                move.w  #$FFFC,$34(a1)

Player_ThrowChick_SetVelocity:  ; was: loc_14066
                move.w  #8,$3C(a1)
                move.l  $30(a0),$30(a1)
                clr.b   $3B(a0)
                bclr    #1,$3A(a0)

Player_ThrowChick_Return:  ; was: locret_1407C
                rts

; Player ground check: standing on solid
Player_CheckGround:
                move.w  $30(a0),d7  ; was: sub_1407E
                move.w  $24(a0),d6
                tst.b   $38(a0)
                bne.s   Player_CheckGround_Airborne
                addq.w  #1,d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                bne.s   Player_CheckGround_Return
                move.b  #1,$38(a0)

Player_CheckGround_Return:  ; was: locret_1409C
                rts

Player_CheckGround_Airborne:  ; was: loc_1409E
                tst.l   $34(a0)
                bne.s   Player_CheckGround_Moving
                tst.l   $2C(a0)
                bpl.s   Player_CheckGround_Falling
                subi.w  #$E,d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Player_CheckGround_RisingReturn
                clr.l   $2C(a0)

Player_CheckGround_RisingReturn:  ; was: locret_140BA
                rts

Player_CheckGround_Falling:  ; was: loc_140BC
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Player_CheckGround_LandReturn
                clr.b   $38(a0)
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)

Player_CheckGround_LandReturn:  ; was: locret_140D8
                rts

Player_CheckGround_Moving:  ; was: loc_140DA
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

Player_CheckGround_StopRise:  ; was: loc_140F8
                clr.l   $2C(a0)

Player_CheckGround_MovingRiseReturn:  ; was: locret_140FC
                rts

Player_CheckGround_MovingFall:  ; was: loc_140FE
                subq.w  #4,d7
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                bne.s   Player_CheckGround_MovingLand
                addq.w  #8,d7
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Player_CheckGround_MovingReturn

Player_CheckGround_MovingLand:  ; was: loc_14112
                clr.b   $38(a0)
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)

Player_CheckGround_MovingReturn:  ; was: locret_14126
                rts

; Player wall collision: left/right walls
Player_CheckWalls:
                move.w  $30(a0),d7  ; was: sub_14128
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

Player_CheckWalls_ClampLeftBounce:  ; was: loc_14168
                neg.l   d0
                move.l  d0,$34(a0)

Player_CheckWalls_Return:  ; was: locret_1416E
                rts

Player_CheckWalls_TestRight:  ; was: loc_14170
                addq.w  #6,d7
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Player_CheckWalls_RightReturn
                move.l  $34(a0),d0
                addi.l  #$3000,d0
                cmpi.l  #$1FE00,d0
                ble.s   Player_CheckWalls_ClampRightBounce
                move.l  #$1FE00,d0

Player_CheckWalls_ClampRightBounce:  ; was: loc_14192
                neg.l   d0
                move.l  d0,$34(a0)

Player_CheckWalls_RightReturn:  ; was: locret_14198
                rts

Player_CheckWalls_Airborne:  ; was: loc_1419A
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

Player_CheckWalls_AirBounceLeft:  ; was: loc_141BC
                move.l  $34(a0),d0
                subi.l  #$3000,d0
                cmpi.l  #$FFFE0200,d0
                bge.s   Player_CheckWalls_AirClampLeft
                move.l  #$FFFE0200,d0

Player_CheckWalls_AirClampLeft:  ; was: loc_141D4
                neg.l   d0
                move.l  d0,$34(a0)

Player_CheckWalls_AirLeftReturn:  ; was: locret_141DA
                rts

Player_CheckWalls_AirTestRight:  ; was: loc_141DC
                addq.w  #6,d7
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Player_CheckWalls_AirRightReturn
                btst    #1,d4
                bne.s   Player_CheckWalls_AirBounceRight
                btst    #0,d4
                beq.s   Player_CheckWalls_Ceiling

Player_CheckWalls_AirBounceRight:  ; was: loc_141F2
                move.l  $34(a0),d0
                addi.l  #$3000,d0
                cmpi.l  #$1FE00,d0
                ble.s   Player_CheckWalls_AirClampRight
                move.l  #$1FE00,d0

Player_CheckWalls_AirClampRight:  ; was: loc_1420A
                neg.l   d0
                move.l  d0,$34(a0)

Player_CheckWalls_AirRightReturn:  ; was: locret_14210
                rts

Player_CheckWalls_Ceiling:  ; was: loc_14212
                tst.l   $2C(a0)
                bpl.s   Player_CheckWalls_SnapToFloor
                move.w  d6,d0
                andi.w  #7,d0
                cmpi.w  #3,d0
                blt.s   Player_CheckWalls_CeilingReturn
                addi.w  #$10,d6
                move.w  d6,$24(a0)
                clr.l   $2C(a0)

Player_CheckWalls_CeilingReturn:  ; was: locret_14230
                rts

Player_CheckWalls_SnapToFloor:  ; was: loc_14232
                andi.w  #$FFF8,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                clr.l   $2C(a0)
                clr.b   $38(a0)
                rts

Player_CheckWalls_NoVelocity:  ; was: loc_14248
                addq.w  #6,d7
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Player_CheckWalls_PushRight
                move.l  #$FFFF4000,$34(a0)
                bra.s   Player_CheckWalls_PushReturn

Player_CheckWalls_PushRight:  ; was: loc_1425C
                subi.w  #$C,d7
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Player_CheckWalls_PushReturn
                move.l  #$C000,$34(a0)

Player_CheckWalls_PushReturn:  ; was: locret_14270
                rts

; Records player position history for chicks
Player_RecordHistory:
                lea     (unk_FFD206).w,a2  ; was: sub_14272
                lea     (unk_FFD1FE).w,a1
                lea     (unk_FFD20A).w,a4
                lea     (unk_FFD202).w,a3
                moveq   #$3F,d0

Player_RecordHistory_ShiftLoop:  ; was: loc_14284
                move.l  (a1),(a2)
                move.l  (a3),(a4)
                subq.l  #8,a1
                subq.l  #8,a2
                subq.l  #8,a3
                subq.l  #8,a4
                dbf     d0,Player_RecordHistory_ShiftLoop
                lea     (byte_FFD24E).w,a2
                lea     (unk_FFD24D).w,a1
                moveq   #$3F,d0

Player_RecordHistory_ShiftFlagsLoop:  ; was: loc_1429E
                move.b  -(a1),-(a2)
                dbf     d0,Player_RecordHistory_ShiftFlagsLoop
                move.l  $30(a0),(dword_FFD00E).w
                move.l  $24(a0),(dword_FFD012).w
                moveq   #0,d0
                tst.b   $38(a0)
                beq.s   Player_RecordHistory_EncodeDirection
                bset    #7,d0

Player_RecordHistory_EncodeDirection:  ; was: loc_142BC
                move.l  $34(a0),d7
                beq.s   Player_RecordHistory_Store
                tst.l   d7
                bpl.s   Player_RecordHistory_FacingRight
                bset    #1,d0
                bra.s   Player_RecordHistory_Store

Player_RecordHistory_FacingRight:  ; was: loc_142CC
                bset    #0,d0

Player_RecordHistory_Store:  ; was: loc_142D0
                move.b  d0,(byte_FFD20E).w
                rts

; Player checks if entered exit door
Player_CheckExit:
                tst.b   (byte_FFD27A).w  ; was: sub_142D6
                beq.s   Player_CheckExit_Return
                tst.b   $38(a0)
                bne.s   Player_CheckExit_Return
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                cmp.w   (word_FFD25C).w,d6
                bne.s   Player_CheckExit_Return
                cmp.w   (word_FFD25E).w,d7
                blt.s   Player_CheckExit_Return
                cmp.w   (word_FFD260).w,d7
                bgt.s   Player_CheckExit_Return
                move.b  #1,(byte_FFD24F).w
                clr.l   $34(a0)
                clr.l   (dword_FFD004).w
                addq.b  #1,(byte_FFD88D).w
                move.l  a0,-(sp)
                bsr.w   UI_AnimateCatCountReverse
                movea.l (sp)+,a0

Player_CheckExit_Return:  ; was: locret_14316
                rts

; Player animation based on movement state
Player_UpdateAnim:
                bclr    #7,2(a0)  ; was: sub_14318
                move.l  $34(a0),d0
                move.b  (word_FFFF8E).w,d1
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

Player_UpdateAnim_FacingRight:  ; was: loc_14342
                btst    #3,d1
                bne.s   Player_UpdateAnim_Walking

Player_UpdateAnim_Braking:  ; was: loc_14348
                move.l  #Player_UpdateAnim_BrakingData,$C(a0)
                rts

Player_UpdateAnim_Walking:  ; was: loc_14352
                clr.w   6(a0)
                bsr.w   Anim_UpdateFrame
                rts

Player_UpdateAnim_Standing:  ; was: loc_1435C
                move.l  #Guide_CharacterMap6,$C(a0)
                rts

Player_UpdateAnim_Airborne:  ; was: loc_14366
                tst.l   d0
                beq.s   Player_UpdateAnim_AirIdle
                move.w  #8,6(a0)
                tst.l   d0
                bpl.s   Player_UpdateAnim_AirFrame
                bset    #7,2(a0)

Player_UpdateAnim_AirFrame:  ; was: loc_1437A
                bsr.w   Anim_UpdateFrame
                rts

Player_UpdateAnim_AirIdle:  ; was: loc_14380
                move.w  #4,6(a0)
                bsr.w   Anim_UpdateFrame
                rts

; Player state: death falling animation
Player_StateDeath:
                bset    #7,$3C(a0)  ; was: sub_1438C
                bne.s   Player_StateDeath_Fall
                move.l  a0,-(sp)
                move.b  #$87,d0
                jsr     unk_FFFB66
                movea.l (sp)+,a0
                clr.b   5(a0)
                clr.l   $34(a0)
                move.w  #$C,6(a0)

Player_StateDeath_Fall:  ; was: loc_143AE
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

Player_StateDeath_Animate:  ; was: loc_143DE
                bsr.w   Anim_UpdateFrame
                rts

Player_StateDeath_Land:  ; was: loc_143E4
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)
                move.w  #8,$3C(a0)
                rts

; Player state: respawn with invincibility
Player_StateRespawn:
                bset    #7,$3C(a0)  ; was: sub_143FC
                bne.s   Player_StateRespawn_Update
                clr.b   5(a0)
                clr.b   $10(a0)
                bclr    #2,2(a0)
                move.b  #3,$39(a0)

Player_StateRespawn_Update:  ; was: loc_14418
                bsr.w   Object_UpdatePosition
                bsr.w   Anim_UpdateFrame
                bclr    #2,2(a0)
                beq.s   Player_StateRespawn_CheckDone
                subq.b  #1,$39(a0)
                bsr.w   Enemy_ClearProjectiles

Player_StateRespawn_CheckDone:  ; was: loc_14430
                tst.b   $39(a0)
                bne.s   Player_StateRespawn_Return
                subq.b  #1,(byte_FFD882).w
                beq.s   Player_StateRespawn_GameOver
                move.b  #1,(byte_FFD886).w
                bsr.w   Enemy_BackupToBuffer
                move.w  #$20,(word_FFFFC0).w
                moveq   #$3C,d2

Player_StateRespawn_DelayLoop:  ; was: loc_1444E
                bsr.w   Timer_IncrementTime
                jsr     unk_FFFB6C
                dbf     d2,Player_StateRespawn_DelayLoop
                bra.s   Player_StateRespawn_Return

Player_StateRespawn_GameOver:  ; was: loc_1445C
                move.w  #$10,(word_FFD2A0).w

Player_StateRespawn_Return:  ; was: locret_14462
                rts

; Clears enemy projectile object slots
Enemy_ClearProjectiles:
                lea     (unk_FFC380).w,a1  ; was: sub_14464
                moveq   #2,d0

Enemy_ClearProjectiles_Loop:  ; was: loc_1446A
                clr.w   (a1)
                lea     $40(a1),a1
                dbf     d0,Enemy_ClearProjectiles_Loop
                rts

; Checks player collision with projectiles
Player_CheckProjectileHit:
                lea     (unk_FFC380).w,a1  ; was: sub_14476
                moveq   #2,d1

Player_CheckProjectileHit_Loop:  ; was: loc_1447C
                btst    #0,5(a1)
                beq.s   Player_CheckProjectileHit_Next
                movem.w d1,-(sp)
                bsr.w   Collision_CheckObjectPair
                movem.w (sp)+,d1
                tst.b   d0
                beq.s   Player_CheckProjectileHit_Next
                move.w  #4,$3C(a0)
                move.b  #1,(byte_FFD26D).w
                bra.s   Player_CheckProjectileHit_Return

Player_CheckProjectileHit_Next:  ; was: loc_144A2
                lea     $40(a1),a1
                dbf     d1,Player_CheckProjectileHit_Loop

Player_CheckProjectileHit_Return:  ; was: locret_144AA
                rts

Player_AnimPointers: dc.l    Player_AnimWalk  ; was: off_144AC
                dc.l    Player_AnimFly
                dc.l    Player_AnimBrake
                dc.l    Player_AnimDeath
Player_AnimWalk: dc.b    2, 2  ; was: byte_144BC
                dc.w    Guide_CharacterMap11-Sys_GameEntryPoint
                dc.w    Player_WalkFrame1-Sys_GameEntryPoint
Player_AnimFly: dc.b    2, 2  ; was: byte_144C2
                dc.w    Player_FlyFrame0-Sys_GameEntryPoint
                dc.w    Player_FlyFrame1-Sys_GameEntryPoint
Player_AnimBrake: dc.b    2, 2  ; was: byte_144C8
                dc.w    Player_BrakeFrame0-Sys_GameEntryPoint
                dc.w    Guide_CharacterMap8-Sys_GameEntryPoint
Player_AnimDeath: dc.b    6, 3  ; was: byte_144CE
                dc.w    Player_DeathFrame0-Sys_GameEntryPoint
                dc.w    Player_DeathFrame1-Sys_GameEntryPoint
                dc.w    Player_DeathFrame2-Sys_GameEntryPoint
                dc.w    Player_DeathFrame3-Sys_GameEntryPoint
                dc.w    Player_DeathFrame2-Sys_GameEntryPoint
                dc.w    Player_DeathFrame3-Sys_GameEntryPoint
; Exit door object at level end
