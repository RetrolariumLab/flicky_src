; Exit door and chick objects.
; ROM $0144DC-$01483D.

Obj_ExitDoor:
                bset    #7,(a0)  ; was: sub_144DC
                bne.s   Obj_ExitDoor_Dispatch
                move.b  (Ram_ExitDoorGridX).w,d7
                move.b  (Ram_ExitDoorGridY).w,d6
                bsr.w   Math_GridToScreen
                addq.w  #8,d7
                addi.w  #$18,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)
                move.l  #ExitDoor_AnimPointers,8(a0)

Obj_ExitDoor_Dispatch:  ; was: loc_14504
                move.w  $3C(a0),d0
                andi.w  #$7FFC,d0
                jsr     ExitDoor_StateTable(pc,d0.w)
                bsr.w   Object_UpdatePosition
                rts

ExitDoor_StateTable:  ; was: loc_14516
                bra.w   Obj_ExitDoorAnim
                bra.w   Obj_ExitDoorIdle

; Exit door animation state
Obj_ExitDoorAnim:
                bsr.w   Anim_UpdateFrame  ; was: sub_1451E

; Exit door idle state (shared RTS)
Obj_ExitDoorIdle:
                rts  ; was: nullsub_3

ExitDoor_AnimPointers: dc.l    ExitDoor_AnimOpen  ; was: off_14524
ExitDoor_AnimOpen: dc.b    2, 8  ; was: byte_14528
                dc.w    ExitDoor_OpenFrame0-Sys_GameEntryPoint
                dc.w    ExitDoor_OpenFrame1-Sys_GameEntryPoint
; Chick main object: collectable that follows player
Obj_Chick:
                bset    #7,(a0)  ; was: sub_1452E
                bne.s   Obj_Chick_Dispatch
                move.l  (Ram_ChickMappingPtr).w,d0
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

Obj_Chick_Dispatch:  ; was: loc_1455E
                tst.b   (Ram_CutsceneFlag).w
                bne.s   Obj_Chick_Return
                tst.b   (Ram_RoundEndingFlag).w
                bne.s   Obj_Chick_Return
                tst.b   (Ram_PlayerHitFlag).w
                bne.s   Obj_Chick_Return
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     Chick_StateTable(pc,d0.w)

Obj_Chick_Return:  ; was: locret_1457A
                rts

Chick_StateTable:  ; was: loc_1457C
                bra.w   Chick_StateIdle
                bra.w   Chick_StateFollowing
                bra.w   Chick_StateThrown

; Chick state: idle waiting to be picked up
Chick_StateIdle:
                move.b  #1,5(a0)  ; was: sub_14588
                lea     (Ram_PlayerObject).w,a1
                tst.l   Ram_PlayerVelocityY-Ram_PlayerObject(a1)
                bmi.s   Chick_StateIdle_Move
                bsr.w   Collision_CheckObjectPair
                tst.b   d0
                beq.s   Chick_StateIdle_Move
                tst.b   $3B(a1)
                bne.s   Chick_StateIdle_Move
                move.w  #4,$3C(a0)
                move.b  #1,$3B(a1)
                move.l  a0,(Ram_HeldChickObject).w

Chick_StateIdle_Move:  ; was: loc_145B6
                bsr.w   Object_UpdatePosition
                rts

; Chick state: following player after pickup
Chick_StateFollowing:
                bset    #7,$3C(a0)  ; was: sub_145BC
                bne.s   Chick_StateFollowing_Track
                move.l  a0,-(sp)
                move.b  #$92,d0
                bsr.w   Sound_PlayNoteIfActive
                movea.l (sp)+,a0

Chick_StateFollowing_Track:  ; was: loc_145D0
                clr.b   5(a0)
                lea     (Ram_PlayerObject).w,a1
                move.l  Ram_PlayerWorldX-Ram_PlayerObject(a1),d7
                move.l  $24(a1),d6
                tst.b   $38(a1)
                beq.s   Chick_StateFollowing_OnGround
                addi.l  #$60000,d6
                bra.s   Chick_StateFollowing_Store

Chick_StateFollowing_OnGround:  ; was: loc_145EE
                tst.b   $39(a1)
                bne.s   Chick_StateFollowing_FacingLeft
                addi.l  #$80000,d7
                bra.s   Chick_StateFollowing_Store

Chick_StateFollowing_FacingLeft:  ; was: loc_145FC
                subi.l  #$80000,d7

Chick_StateFollowing_Store:  ; was: loc_14602
                move.l  d7,$30(a0)
                move.l  d6,$24(a0)
                bsr.w   Object_UpdatePosition
                rts

; Chick state: thrown and bouncing
Chick_StateThrown:
                bset    #7,$3C(a0)  ; was: sub_14610
                bne.s   Chick_StateThrown_Move
                move.l  a0,-(sp)
                move.b  #$96,d0
                bsr.w   Sound_PlayNoteIfActive
                movea.l (sp)+,a0
                move.b  #$18,5(a0)
                move.l  #Chick_ThrownAnimPointers,8(a0)
                clr.b   $3B(a0)
                moveq   #0,d0
                move.b  (Ram_RoundNumber+1).w,d0

Chick_StateThrown_ReduceRound:  ; was: loc_1463C
                cmpi.b  #$F,d0
                bls.s   Chick_StateThrown_SelectAnim
                subi.b  #$F,d0
                bra.s   Chick_StateThrown_ReduceRound

Chick_StateThrown_SelectAnim:  ; was: loc_14648
                subq.b  #1,d0
                lsl.w   #2,d0
                move.w  d0,6(a0)

Chick_StateThrown_Move:  ; was: loc_14650
                bsr.w   Chick_UpdatePhysics
                tst.l   $34(a0)
                bne.s   Chick_StateThrown_CheckRange
                clr.w   (a0)

Chick_StateThrown_CheckRange:  ; was: loc_1465C
                bsr.w   Chick_CheckOffscreen
                rts

; Chick checks if too far from player
Chick_CheckOffscreen:
                move.w  $20(a0),d7  ; was: sub_14662
                move.w  d7,d6
                lea     (Ram_PlayerObject).w,a1
                move.w  Ram_PlayerScreenX-Ram_PlayerObject(a1),d5
                move.w  d5,d4
                sub.w   d7,d5
                cmpi.w  #$7C,d5
                bge.s   Chick_CheckOffscreen_Despawn
                sub.w   d4,d6
                cmpi.w  #$7C,d6
                bge.s   Chick_CheckOffscreen_Despawn
                bra.s   Chick_CheckOffscreen_Return

Chick_CheckOffscreen_Despawn:  ; was: loc_14684
                clr.w   (a0)

Chick_CheckOffscreen_Return:  ; was: locret_14686
                rts

; Chick physics: movement and collision
Chick_UpdatePhysics:
                move.l  $34(a0),d7  ; was: sub_14688
                move.l  $2C(a0),d6
                bclr    #7,2(a0)
                tst.l   d7
                bpl.s   Chick_UpdatePhysics_Animate
                bset    #7,2(a0)

Chick_UpdatePhysics_Animate:  ; was: loc_146A0
                bsr.w   Anim_UpdateFrame
                tst.b   $38(a0)
                bne.s   Chick_UpdatePhysics_ApplyGravity
                tst.l   d7
                bpl.s   Chick_UpdatePhysics_DecelerateRight
                addi.l  #$800,d7
                bra.s   Chick_UpdatePhysics_Decelerated

Chick_UpdatePhysics_DecelerateRight:  ; was: loc_146B6
                subi.l  #$800,d7

Chick_UpdatePhysics_Decelerated:  ; was: loc_146BC
                bra.s   Chick_UpdatePhysics_Move

Chick_UpdatePhysics_ApplyGravity:  ; was: loc_146BE
                addi.l  #$1000,d6

Chick_UpdatePhysics_Move:  ; was: loc_146C4
                move.l  d7,$34(a0)
                move.l  d6,$2C(a0)
                bsr.w   Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                addq.w  #1,d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Chick_UpdatePhysics_Airborne
                clr.l   $2C(a0)
                clr.b   $38(a0)
                move.w  d6,d5
                andi.w  #$FFF8,d5
                move.w  d5,$24(a0)
                clr.w   $26(a0)
                bra.s   Chick_UpdatePhysics_CheckWalls

Chick_UpdatePhysics_Airborne:  ; was: loc_146FA
                move.b  #1,$38(a0)

Chick_UpdatePhysics_CheckWalls:  ; was: loc_14700
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subq.w  #4,d6
                tst.l   $34(a0)
                bpl.s   Chick_UpdatePhysics_TestRight
                subq.w  #4,d7
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Chick_UpdatePhysics_LeftReturn
                neg.l   $34(a0)

Chick_UpdatePhysics_LeftReturn:  ; was: locret_1471E
                rts

Chick_UpdatePhysics_TestRight:  ; was: loc_14720
                addq.w  #4,d7
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Chick_UpdatePhysics_RightReturn
                neg.l   $34(a0)

Chick_UpdatePhysics_RightReturn:  ; was: locret_1472E
                rts

Chick_ThrownAnimPointers: dc.l    Chick_ThrownAnim0  ; was: off_14730
                dc.l    Chick_ThrownAnim1
                dc.l    Chick_ThrownAnim2
                dc.l    Chick_ThrownAnim3
                dc.l    Chick_ThrownAnim4
                dc.l    Chick_ThrownAnim5
                dc.l    Chick_ThrownAnim6
                dc.l    Chick_ThrownAnim7
                dc.l    Chick_ThrownAnim8
                dc.l    Chick_ThrownAnim9
                dc.l    Chick_ThrownAnim10
                dc.l    Chick_ThrownAnim11
                dc.l    Chick_ThrownAnim12
                dc.l    Chick_ThrownAnim13
                dc.l    Chick_ThrownAnim14
Chick_ThrownAnim0: dc.b    6, 1  ; was: byte_1476C
                dc.w    Chick_ThrownAnim0Data0-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim0Data1-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim0Data2-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim0Data3-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim0Data4-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim0Data5-Sys_GameEntryPoint
Chick_ThrownAnim1: dc.b    6, 1  ; was: byte_1477A
                dc.w    Chick_ThrownAnim1Data0-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim1Data1-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim1Data2-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim1Data3-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim1Data4-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim1Data5-Sys_GameEntryPoint
Chick_ThrownAnim2: dc.b    6, 1  ; was: byte_14788
                dc.w    Chick_ThrownAnim2Data0-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim2Data1-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim2Data2-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim2Data3-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim2Data4-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim2Data5-Sys_GameEntryPoint
Chick_ThrownAnim3: dc.b    6, 1  ; was: byte_14796
                dc.w    Chick_ThrownAnim3Data0-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim3Data1-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim3Data2-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim3Data3-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim3Data4-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim3Data5-Sys_GameEntryPoint
Chick_ThrownAnim4: dc.b    6, 1  ; was: byte_147A4
                dc.w    Chick_ThrownAnim4Data0-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim4Data1-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim4Data2-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim4Data3-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim4Data4-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim4Data5-Sys_GameEntryPoint
Chick_ThrownAnim5: dc.b    6, 1  ; was: byte_147B2
                dc.w    Chick_ThrownAnim5Data0-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim5Data1-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim5Data2-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim5Data3-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim5Data4-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim5Data5-Sys_GameEntryPoint
Chick_ThrownAnim6: dc.b    6, 1  ; was: byte_147C0
                dc.w    Chick_ThrownAnim6Data0-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim6Data1-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim6Data2-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim6Data3-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim6Data4-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim6Data5-Sys_GameEntryPoint
Chick_ThrownAnim7: dc.b    6, 1  ; was: byte_147CE
                dc.w    Chick_ThrownAnim7Data0-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim7Data1-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim7Data2-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim7Data3-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim7Data4-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim7Data5-Sys_GameEntryPoint
Chick_ThrownAnim8: dc.b    6, 1  ; was: byte_147DC
                dc.w    Chick_ThrownAnim8Data0-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim8Data1-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim8Data2-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim8Data3-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim8Data4-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim8Data5-Sys_GameEntryPoint
Chick_ThrownAnim9: dc.b    6, 1  ; was: byte_147EA
                dc.w    Chick_ThrownAnim9Data0-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim9Data1-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim9Data2-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim9Data3-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim9Data4-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim9Data5-Sys_GameEntryPoint
Chick_ThrownAnim10: dc.b    6, 1  ; was: byte_147F8
                dc.w    Chick_ThrownAnim10Data0-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim10Data1-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim10Data2-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim10Data3-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim10Data4-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim10Data5-Sys_GameEntryPoint
Chick_ThrownAnim11: dc.b    6, 1  ; was: byte_14806
                dc.w    Chick_ThrownAnim11Data0-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim11Data1-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim11Data2-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim11Data3-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim11Data4-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim11Data5-Sys_GameEntryPoint
Chick_ThrownAnim12: dc.b    6, 1  ; was: byte_14814
                dc.w    Chick_ThrownAnim12Data0-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim12Data1-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim12Data2-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim12Data3-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim12Data4-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim12Data5-Sys_GameEntryPoint
Chick_ThrownAnim13: dc.b    6, 1  ; was: byte_14822
                dc.w    Chick_ThrownAnim13Data0-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim13Data1-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim13Data2-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim13Data3-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim13Data4-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim13Data5-Sys_GameEntryPoint
Chick_ThrownAnim14: dc.b    6, 1  ; was: byte_14830
                dc.w    Chick_ThrownAnim14Data0-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim14Data1-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim14Data2-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim14Data3-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim14Data4-Sys_GameEntryPoint
                dc.w    Chick_ThrownAnim14Data5-Sys_GameEntryPoint
; Enemy cat main object that chases player
