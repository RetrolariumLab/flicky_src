; Window girl and throwable item objects
; ROM $0144DC-$01483D

Obj_WindowGirl:
                bset    #7,(a0)
                bne.s   Obj_WindowGirl_Dispatch
                move.b  (Ram_WindowGirlGridX).w,d7
                move.b  (Ram_WindowGirlGridY).w,d6
                bsr.w   Math_GridToScreen
                addq.w  #8,d7
                addi.w  #$18,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)
                move.l  #WindowGirl_AnimPointers,8(a0)

Obj_WindowGirl_Dispatch:
                move.w  $3C(a0),d0
                andi.w  #$7FFC,d0
                jsr     WindowGirl_StateTable(pc,d0.w)
                bsr.w   Object_UpdatePosition
                rts

WindowGirl_StateTable:
                bra.w   WindowGirl_StateAnimate
                bra.w   WindowGirl_StateIdle

; Window girl animation state
WindowGirl_StateAnimate:
                bsr.w   Anim_UpdateFrame

; Window girl idle state (shared RTS)
WindowGirl_StateIdle:
                rts

WindowGirl_AnimPointers:    dc.l    WindowGirl_AnimIdle
WindowGirl_AnimIdle:        dc.b    2, 8
                dc.w    WindowGirl_Frame0-Sys_GameEntryPoint
                dc.w    WindowGirl_Frame1-Sys_GameEntryPoint
; Throwable item: collectible that can be held and thrown
Obj_Throwable:
                bset    #7,(a0)
                bne.s   Obj_Throwable_Dispatch
                move.l  (Ram_ThrowableMappingPtr).w,d0
                move.l  d0,$C(a0)
                move.b  #$60,$13(a0)
                moveq   #0,d7
                moveq   #0,d6
                move.b  $3E(a0),d7
                move.b  $3F(a0),d6
                bsr.w   Math_GridToScreen
                addq.w  #8,d7
                addq.w  #8,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)

Obj_Throwable_Dispatch:
                tst.b   (Ram_CutsceneFlag).w
                bne.s   Obj_Throwable_Return
                tst.b   (Ram_RoundEndingFlag).w
                bne.s   Obj_Throwable_Return
                tst.b   (Ram_PlayerHitFlag).w
                bne.s   Obj_Throwable_Return
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     Throwable_StateTable(pc,d0.w)

Obj_Throwable_Return:
                rts

Throwable_StateTable:
                bra.w   Throwable_StateIdle
                bra.w   Throwable_StateFollowing
                bra.w   Throwable_StateThrown

; Throwable item state: idle waiting to be picked up
Throwable_StateIdle:
                move.b  #1,5(a0)
                lea     (Ram_PlayerObject).w,a1
                tst.l   Ram_PlayerVelocityY-Ram_PlayerObject(a1)
                bmi.s   Throwable_StateIdle_Move
                bsr.w   Collision_CheckObjectPair
                tst.b   d0
                beq.s   Throwable_StateIdle_Move
                tst.b   $3B(a1)
                bne.s   Throwable_StateIdle_Move
                move.w  #4,$3C(a0)
                move.b  #1,$3B(a1)
                move.l  a0,(Ram_HeldItemObject).w

Throwable_StateIdle_Move:
                bsr.w   Object_UpdatePosition
                rts

; Throwable item state: held by player after pickup
Throwable_StateFollowing:
                bset    #7,$3C(a0)
                bne.s   Throwable_StateFollowing_Track
                move.l  a0,-(sp)
                move.b  #$92,d0
                bsr.w   Sound_PlayNoteIfActive
                movea.l (sp)+,a0

Throwable_StateFollowing_Track:
                clr.b   5(a0)
                lea     (Ram_PlayerObject).w,a1
                move.l  Ram_PlayerWorldX-Ram_PlayerObject(a1),d7
                move.l  $24(a1),d6
                tst.b   $38(a1)
                beq.s   Throwable_StateFollowing_OnGround
                addi.l  #$60000,d6
                bra.s   Throwable_StateFollowing_Store

Throwable_StateFollowing_OnGround:
                tst.b   $39(a1)
                bne.s   Throwable_StateFollowing_FacingLeft
                addi.l  #$80000,d7
                bra.s   Throwable_StateFollowing_Store

Throwable_StateFollowing_FacingLeft:
                subi.l  #$80000,d7

Throwable_StateFollowing_Store:
                move.l  d7,$30(a0)
                move.l  d6,$24(a0)
                bsr.w   Object_UpdatePosition
                rts

; Throwable item state: thrown and bouncing
Throwable_StateThrown:
                bset    #7,$3C(a0)
                bne.s   Throwable_StateThrown_Move
                move.l  a0,-(sp)
                move.b  #$96,d0
                bsr.w   Sound_PlayNoteIfActive
                movea.l (sp)+,a0
                move.b  #$18,5(a0)
                move.l  #Throwable_ThrownAnimPointers,8(a0)
                clr.b   $3B(a0)
                moveq   #0,d0
                move.b  (Ram_RoundNumber+1).w,d0

Throwable_StateThrown_ReduceRound:
                cmpi.b  #$F,d0
                bls.s   Throwable_StateThrown_SelectAnim
                subi.b  #$F,d0
                bra.s   Throwable_StateThrown_ReduceRound

Throwable_StateThrown_SelectAnim:
                subq.b  #1,d0
                lsl.w   #2,d0
                move.w  d0,6(a0)

Throwable_StateThrown_Move:
                bsr.w   Throwable_UpdatePhysics
                tst.l   $34(a0)
                bne.s   Throwable_StateThrown_CheckRange
                clr.w   (a0)

Throwable_StateThrown_CheckRange:
                bsr.w   Throwable_CheckOffscreen
                rts

; Throwable item checks if too far from player
Throwable_CheckOffscreen:
                move.w  $20(a0),d7
                move.w  d7,d6
                lea     (Ram_PlayerObject).w,a1
                move.w  Ram_PlayerScreenX-Ram_PlayerObject(a1),d5
                move.w  d5,d4
                sub.w   d7,d5
                cmpi.w  #$7C,d5
                bge.s   Throwable_CheckOffscreen_Despawn
                sub.w   d4,d6
                cmpi.w  #$7C,d6
                bge.s   Throwable_CheckOffscreen_Despawn
                bra.s   Throwable_CheckOffscreen_Return

Throwable_CheckOffscreen_Despawn:
                clr.w   (a0)

Throwable_CheckOffscreen_Return:
                rts

; Throwable item physics: movement and collision
Throwable_UpdatePhysics:
                move.l  $34(a0),d7
                move.l  $2C(a0),d6
                bclr    #7,2(a0)
                tst.l   d7
                bpl.s   Throwable_UpdatePhysics_Animate
                bset    #7,2(a0)

Throwable_UpdatePhysics_Animate:
                bsr.w   Anim_UpdateFrame
                tst.b   $38(a0)
                bne.s   Throwable_UpdatePhysics_ApplyGravity
                tst.l   d7
                bpl.s   Throwable_UpdatePhysics_DecelerateRight
                addi.l  #$800,d7
                bra.s   Throwable_UpdatePhysics_Decelerated

Throwable_UpdatePhysics_DecelerateRight:
                subi.l  #$800,d7

Throwable_UpdatePhysics_Decelerated:
                bra.s   Throwable_UpdatePhysics_Move

Throwable_UpdatePhysics_ApplyGravity:
                addi.l  #$1000,d6

Throwable_UpdatePhysics_Move:
                move.l  d7,$34(a0)
                move.l  d6,$2C(a0)
                bsr.w   Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                addq.w  #1,d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Throwable_UpdatePhysics_Airborne
                clr.l   $2C(a0)
                clr.b   $38(a0)
                move.w  d6,d5
                andi.w  #$FFF8,d5
                move.w  d5,$24(a0)
                clr.w   $26(a0)
                bra.s   Throwable_UpdatePhysics_CheckWalls

Throwable_UpdatePhysics_Airborne:
                move.b  #1,$38(a0)

Throwable_UpdatePhysics_CheckWalls:
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subq.w  #4,d6
                tst.l   $34(a0)
                bpl.s   Throwable_UpdatePhysics_TestRight
                subq.w  #4,d7
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Throwable_UpdatePhysics_LeftReturn
                neg.l   $34(a0)

Throwable_UpdatePhysics_LeftReturn:
                rts

Throwable_UpdatePhysics_TestRight:
                addq.w  #4,d7
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Throwable_UpdatePhysics_RightReturn
                neg.l   $34(a0)

Throwable_UpdatePhysics_RightReturn:
                rts

Throwable_ThrownAnimPointers:   dc.l    Throwable_ThrownAnim0
                dc.l    Throwable_ThrownAnim1
                dc.l    Throwable_ThrownAnim2
                dc.l    Throwable_ThrownAnim3
                dc.l    Throwable_ThrownAnim4
                dc.l    Throwable_ThrownAnim5
                dc.l    Throwable_ThrownAnim6
                dc.l    Throwable_ThrownAnim7
                dc.l    Throwable_ThrownAnim8
                dc.l    Throwable_ThrownAnim9
                dc.l    Throwable_ThrownAnim10
                dc.l    Throwable_ThrownAnim11
                dc.l    Throwable_ThrownAnim12
                dc.l    Throwable_ThrownAnim13
                dc.l    Throwable_ThrownAnim14
Throwable_ThrownAnim0:  dc.b    6, 1
                dc.w    Throwable_ThrownAnim0Data0-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim0Data1-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim0Data2-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim0Data3-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim0Data4-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim0Data5-Sys_GameEntryPoint
Throwable_ThrownAnim1:  dc.b    6, 1
                dc.w    Throwable_ThrownAnim1Data0-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim1Data1-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim1Data2-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim1Data3-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim1Data4-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim1Data5-Sys_GameEntryPoint
Throwable_ThrownAnim2:  dc.b    6, 1
                dc.w    Throwable_ThrownAnim2Data0-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim2Data1-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim2Data2-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim2Data3-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim2Data4-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim2Data5-Sys_GameEntryPoint
Throwable_ThrownAnim3:  dc.b    6, 1
                dc.w    Throwable_ThrownAnim3Data0-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim3Data1-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim3Data2-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim3Data3-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim3Data4-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim3Data5-Sys_GameEntryPoint
Throwable_ThrownAnim4:  dc.b    6, 1
                dc.w    Throwable_ThrownAnim4Data0-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim4Data1-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim4Data2-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim4Data3-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim4Data4-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim4Data5-Sys_GameEntryPoint
Throwable_ThrownAnim5:  dc.b    6, 1
                dc.w    Throwable_ThrownAnim5Data0-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim5Data1-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim5Data2-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim5Data3-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim5Data4-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim5Data5-Sys_GameEntryPoint
Throwable_ThrownAnim6:  dc.b    6, 1
                dc.w    Throwable_ThrownAnim6Data0-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim6Data1-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim6Data2-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim6Data3-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim6Data4-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim6Data5-Sys_GameEntryPoint
Throwable_ThrownAnim7:  dc.b    6, 1
                dc.w    Throwable_ThrownAnim7Data0-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim7Data1-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim7Data2-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim7Data3-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim7Data4-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim7Data5-Sys_GameEntryPoint
Throwable_ThrownAnim8:  dc.b    6, 1
                dc.w    Throwable_ThrownAnim8Data0-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim8Data1-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim8Data2-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim8Data3-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim8Data4-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim8Data5-Sys_GameEntryPoint
Throwable_ThrownAnim9:  dc.b    6, 1
                dc.w    Throwable_ThrownAnim9Data0-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim9Data1-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim9Data2-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim9Data3-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim9Data4-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim9Data5-Sys_GameEntryPoint
Throwable_ThrownAnim10: dc.b    6, 1
                dc.w    Throwable_ThrownAnim10Data0-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim10Data1-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim10Data2-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim10Data3-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim10Data4-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim10Data5-Sys_GameEntryPoint
Throwable_ThrownAnim11: dc.b    6, 1
                dc.w    Throwable_ThrownAnim11Data0-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim11Data1-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim11Data2-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim11Data3-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim11Data4-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim11Data5-Sys_GameEntryPoint
Throwable_ThrownAnim12: dc.b    6, 1
                dc.w    Throwable_ThrownAnim12Data0-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim12Data1-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim12Data2-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim12Data3-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim12Data4-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim12Data5-Sys_GameEntryPoint
Throwable_ThrownAnim13: dc.b    6, 1
                dc.w    Throwable_ThrownAnim13Data0-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim13Data1-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim13Data2-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim13Data3-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim13Data4-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim13Data5-Sys_GameEntryPoint
Throwable_ThrownAnim14: dc.b    6, 1
                dc.w    Throwable_ThrownAnim14Data0-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim14Data1-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim14Data2-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim14Data3-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim14Data4-Sys_GameEntryPoint
                dc.w    Throwable_ThrownAnim14Data5-Sys_GameEntryPoint
; Chirp rescue actor
