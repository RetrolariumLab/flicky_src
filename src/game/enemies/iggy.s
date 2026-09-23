; Iggy lizard enemy
; ROM $015D58-$016311

Obj_Iggy:
                bset    #7,(a0)
                bne.s   Obj_Iggy_Dispatch
                moveq   #0,d7
                moveq   #0,d6
                move.b  $3E(a0),d7
                move.b  $3F(a0),d6
                bsr.w   Math_GridToScreen
                addq.w  #8,d7
                addi.w  #$10,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)
                move.l  #Iggy_AnimPointers,8(a0)
                clr.l   $34(a0)
                clr.l   $2C(a0)

Obj_Iggy_Dispatch:
                tst.b   (Ram_CutsceneFlag).w
                bne.s   Obj_Iggy_Return
                tst.b   (Ram_RoundEndingFlag).w
                bne.s   Obj_Iggy_Return
                tst.b   (Ram_PlayerHitFlag).w
                bne.s   Obj_Iggy_Return
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     Iggy_StateTable(pc,d0.w)
                move.w  $3C(a0),d0
                andi.w  #$7C,d0
                cmpi.w  #$C,d0
                beq.s   Obj_Iggy_Return
                cmpi.w  #$10,d0
                beq.s   Obj_Iggy_Return
                bsr.w   Iggy_CheckPlayerHit

Obj_Iggy_Return:
                rts

Iggy_StateTable:
                bra.w   Iggy_StateSpawn
                bra.w   Iggy_StateMove
                bra.w   Iggy_StateTurn
                bra.w   Iggy_StateHit
                bra.w   Iggy_StateDeath

; Iggy state: initial spawn animation
Iggy_StateSpawn:
                bset    #7,$3C(a0)
                bne.s   Iggy_StateSpawn_Countdown
                move.b  #4,5(a0)
                move.l  #Iggy_StateSpawnData,$C(a0)
                move.b  #$A,$3B(a0)

Iggy_StateSpawn_Countdown:
                bsr.w   Object_UpdatePosition
                subq.b  #1,$3B(a0)
                bne.s   Iggy_StateSpawn_Return
                move.w  #4,$3C(a0)

Iggy_StateSpawn_Return:
                rts

; Iggy state: movement direction dispatcher
Iggy_StateMove:
                bset    #7,$3C(a0)
                bne.s   Iggy_StateMove_Dispatch
                move.b  #5,5(a0)

Iggy_StateMove_Dispatch:
                moveq   #0,d0
                move.b  $3A(a0),d0
                lsl.w   #2,d0
                jsr     Iggy_DirectionTable(pc,d0.w)
                rts

Iggy_DirectionTable:
                bra.w   Iggy_MoveRight
                bra.w   Iggy_MoveLeft
                bra.w   Iggy_MoveLeft
                bra.w   Iggy_MoveLeft
                bra.w   Iggy_MoveUp
                bra.w   Iggy_MoveUp
                bra.w   Iggy_MoveDown
                bra.w   Iggy_StateTurn

; Iggy state: moving right on wall
Iggy_MoveRight:
                clr.w   6(a0)
                bclr    #7,2(a0)
                move.l  (Ram_IggySpeed).w,$34(a0)
                clr.l   $2C(a0)
                bsr.w   Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Iggy_MoveRight_TurnDown
                addq.w  #4,d7
                subq.w  #4,d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                bne.s   Iggy_MoveRight_TurnUp
                moveq   #0,d7
                moveq   #$FFFFFFFC,d6
                bsr.w   Collision_GetTileAtObject
                tst.b   d4
                bne.s   Iggy_MoveRight_StartTurn
                bsr.w   Anim_UpdateFrame
                rts

Iggy_MoveRight_TurnDown:
                move.b  #6,$3A(a0)
                move.w  $30(a0),d7
                andi.w  #$FFF8,d7
                subq.w  #1,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                move.l  #Iggy_MoveRight_TurnDownData,$C(a0)
                rts

Iggy_MoveRight_TurnUp:
                move.b  #5,$3A(a0)
                andi.w  #$FFF8,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                addq.w  #4,$20(a0)
                andi.w  #$FFF8,d6
                addq.w  #7,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #Iggy_MoveRight_TurnUpData,$C(a0)
                rts

Iggy_MoveRight_StartTurn:
                move.w  #8,$3C(a0)
                move.l  #Iggy_MoveRight_StartTurnData,$C(a0)
                rts

; Iggy state: moving left on wall
Iggy_MoveLeft:
                move.w  #4,6(a0)
                bset    #7,2(a0)
                move.l  (Ram_IggySpeed).w,d0
                neg.l   d0
                move.l  d0,$34(a0)
                clr.l   $2C(a0)
                bsr.w   Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Iggy_MoveLeft_TurnUp
                subq.w  #4,d7
                addq.w  #4,d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                bne.s   Iggy_MoveLeft_TurnDown
                moveq   #0,d7
                moveq   #4,d6
                bsr.w   Collision_GetTileAtObject
                tst.b   d4
                bne.s   Iggy_MoveLeft_StartTurn
                bsr.w   Anim_UpdateFrame
                rts

Iggy_MoveLeft_TurnUp:
                move.b  #5,$3A(a0)
                move.w  $30(a0),d7
                andi.w  #$FFF8,d7
                addq.w  #8,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                move.l  #Iggy_MoveLeft_TurnUpData,$C(a0)
                bclr    #7,2(a0)
                rts

Iggy_MoveLeft_TurnDown:
                move.b  #6,$3A(a0)
                andi.w  #$FFF8,d7
                addq.w  #7,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                subq.w  #4,$20(a0)
                andi.w  #$FFF8,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #Iggy_MoveLeft_TurnDownData,$C(a0)
                bclr    #7,2(a0)
                rts

Iggy_MoveLeft_StartTurn:
                move.w  #8,$3C(a0)
                move.l  #Iggy_MoveLeft_StartTurnData,$C(a0)
                rts

; Iggy state: moving up on wall
Iggy_MoveUp:
                move.w  #8,6(a0)
                bclr    #7,2(a0)
                clr.l   $34(a0)
                move.l  (Ram_IggySpeed).w,d0
                neg.l   d0
                move.l  d0,$2C(a0)
                bsr.w   Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Iggy_MoveUp_TurnLeft
                subq.w  #4,d7
                subq.w  #4,d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                bne.s   Iggy_MoveUp_TurnRight
                bsr.w   Anim_UpdateFrame
                rts

Iggy_MoveUp_TurnLeft:
                clr.b   $3A(a0)
                move.w  $24(a0),d6
                andi.w  #$FFF8,d6
                addq.w  #8,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #Iggy_MoveUp_TurnLeftData,$C(a0)
                bclr    #7,2(a0)
                rts

Iggy_MoveUp_TurnRight:
                move.b  #3,$3A(a0)
                andi.w  #$FFF8,d7
                addq.w  #7,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                andi.w  #$FFF8,d6
                addq.w  #7,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #Iggy_MoveUp_TurnRightData,$C(a0)
                bclr    #7,2(a0)
                rts

; Iggy state: moving down on wall
Iggy_MoveDown:
                move.w  #$C,6(a0)
                bset    #7,2(a0)
                clr.l   $34(a0)
                move.l  (Ram_IggySpeed).w,$2C(a0)
                bsr.w   Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Iggy_MoveUp_StartTurn
                addq.w  #4,d7
                addq.w  #4,d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                bne.s   Iggy_MoveDown_TurnRight
                bsr.w   Anim_UpdateFrame
                rts

Iggy_MoveUp_StartTurn:
                move.b  #3,$3A(a0)
                move.w  $24(a0),d6
                andi.w  #$FFF8,d6
                subq.w  #1,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #Iggy_MoveUp_StartTurnData,$C(a0)
                bclr    #7,2(a0)
                rts

Iggy_MoveDown_TurnRight:
                move.b  #0,$3A(a0)
                andi.w  #$FFF8,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                andi.w  #$FFF8,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #Iggy_MoveDown_TurnRightData,$C(a0)
                bclr    #7,2(a0)
                rts

; Iggy state: turning at corners
Iggy_StateTurn:
                bset    #7,$3C(a0)
                bne.s   Iggy_MoveDown_TurnLeft
                move.b  #5,5(a0)

Iggy_MoveDown_TurnLeft:
                btst    #1,$3A(a0)
                bne.s   Iggy_StateTurn_Continue
                move.w  #$10,6(a0)
                clr.l   $34(a0)
                move.l  (Ram_IggySpeed).w,d0
                neg.l   d0
                move.l  d0,$2C(a0)
                bsr.w   Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subq.w  #8,d6
                bsr.w   Collision_GetTileAtPos
                bne.s   Iggy_MoveDown_StartTurn
                bsr.w   Anim_UpdateFrame
                rts

Iggy_MoveDown_StartTurn:
                move.w  #4,$3C(a0)
                bchg    #0,$3A(a0)
                bchg    #1,$3A(a0)
                andi.w  #$FFF8,d6
                addq.w  #7,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #Iggy_MoveLeft_StartTurnData,$C(a0)
                rts

Iggy_StateTurn_Continue:
                move.w  #$14,6(a0)
                clr.l   $34(a0)
                move.l  (Ram_IggySpeed).w,$2C(a0)
                bsr.w   Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                addq.w  #8,d6
                bsr.w   Collision_GetTileAtPos
                bne.s   Iggy_StateTurn_Finish
                bsr.w   Anim_UpdateFrame
                rts

Iggy_StateTurn_Finish:
                move.w  #4,$3C(a0)
                bchg    #0,$3A(a0)
                bchg    #1,$3A(a0)
                andi.w  #$FFF8,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #Iggy_MoveRight_StartTurnData,$C(a0)
                rts

; Iggy state: hit by player bouncing
Iggy_StateHit:
                bset    #7,$3C(a0)
                bne.s   Iggy_StateHit_Move
                move.l  a0,-(sp)
                move.b  #$93,d0
                bsr.w   Sound_PlayNoteIfActive
                movea.l (sp)+,a0
                move.w  #$18,6(a0)
                subq.b  #1,(Ram_ActiveEnemyCount).w
                clr.b   5(a0)

Iggy_StateHit_Move:
                bsr.w   Throwable_UpdatePhysics
                tst.l   $34(a0)
                bne.s   Iggy_StateHit_Return
                move.w  #$10,$3C(a0)

Iggy_StateHit_Return:
                rts

; Iggy state: death anim spawns new enemy
Iggy_StateDeath:
                bset    #7,$3C(a0)
                bne.s   Iggy_StateDeath_Update
                bclr    #2,2(a0)
                move.w  #$1C,6(a0)
                clr.b   $10(a0)
                move.l  #$FFFFC000,$2C(a0)
                clr.b   5(a0)

Iggy_StateDeath_Update:
                bsr.w   Object_UpdatePosition
                bsr.w   Anim_UpdateFrame
                btst    #2,2(a0)
                beq.s   Iggy_StateDeath_Return
                move.b  (Ram_RoundTime+2).w,d0
                andi.b  #$F0,d0
                bne.s   Iggy_StateDeath_ClearSprites
                lea     (Ram_IggyRespawnSlot).w,a1
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                move.w  d7,$30(a1)
                move.w  d6,$24(a1)
                move.w  #$28,(a1)

Iggy_StateDeath_ClearSprites:
                bsr.w   Sprite_ClearLinkTable

Iggy_StateDeath_Return:
                rts

; Iggy collision with player hit detection
Iggy_CheckPlayerHit:
                lea     (Ram_SpawnerSlots).w,a1
                moveq   #5,d0

Iggy_CheckPlayerHit_Loop:
                move.w  d0,-(sp)
                btst    #4,5(a1)
                beq.s   Iggy_CheckPlayerHit_Next
                bsr.w   Collision_CheckObjectPair
                tst.b   d0
                beq.s   Iggy_CheckPlayerHit_Next
                move.w  #$C,$3C(a0)
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
                move.l  Iggy_HitScoreTable(pc,d0.w),d0
                move.l  d0,(Ram_ScoreDelta).w
                move.l  a1,-(sp)
                bsr.w   Score_AddAndCheck
                movea.l (sp)+,a1
                lea     (Ram_PopupSlots).w,a2
                moveq   #3,d0

Iggy_CheckPlayerHit_PopupLoop:
                tst.b   (a2)
                bne.s   Iggy_CheckPlayerHit_PopupNext
                move.w  #$1C,(a2)
                move.b  $3B(a1),d1
                move.b  d1,$3A(a2)
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subq.w  #8,d6
                move.w  d7,$30(a2)
                move.w  d6,$24(a2)
                bra.s   Iggy_CheckPlayerHit_Return

Iggy_CheckPlayerHit_PopupNext:
                lea     -$40(a2),a2
                dbf     d0,Iggy_CheckPlayerHit_PopupLoop
                bra.s   Iggy_CheckPlayerHit_Return

Iggy_CheckPlayerHit_Next:
                lea     $40(a1),a1
                move.w  (sp)+,d0
                dbf     d0,Iggy_CheckPlayerHit_Loop
                rts

Iggy_CheckPlayerHit_Return:
                move.w  (sp)+,d0
                rts

Iggy_HitScoreTable: dc.l    $200, $400, $800, $1600
Iggy_AnimPointers:  dc.l    Iggy_AnimRight
                dc.l    Iggy_AnimLeft
                dc.l    Iggy_AnimUp
                dc.l    Iggy_AnimDown
                dc.l    Iggy_AnimTurnA
                dc.l    Iggy_AnimTurnB
                dc.l    Iggy_AnimSpawn
                dc.l    Tiger_AnimDeath
Iggy_AnimRight: dc.b    4, 1
                dc.w    Iggy_RightFrame0-Sys_GameEntryPoint
                dc.w    Iggy_RightFrame1-Sys_GameEntryPoint
                dc.w    Iggy_RightFrame2-Sys_GameEntryPoint
                dc.w    Iggy_RightFrame1-Sys_GameEntryPoint
Iggy_AnimLeft:  dc.b    4, 1
                dc.w    Iggy_LeftFrame0-Sys_GameEntryPoint
                dc.w    Iggy_LeftFrame1-Sys_GameEntryPoint
                dc.w    Iggy_LeftFrame2-Sys_GameEntryPoint
                dc.w    Iggy_LeftFrame1-Sys_GameEntryPoint
Iggy_AnimUp:    dc.b    2, 1
                dc.w    Iggy_UpFrame0-Sys_GameEntryPoint
                dc.w    Iggy_UpFrame1-Sys_GameEntryPoint
Iggy_AnimDown:  dc.b    2, 1
                dc.w    Iggy_DownFrame0-Sys_GameEntryPoint
                dc.w    Iggy_DownFrame1-Sys_GameEntryPoint
Iggy_AnimTurnA: dc.b    2, 1
                dc.w    Iggy_TurnAFrame0-Sys_GameEntryPoint
                dc.w    Iggy_TurnAFrame1-Sys_GameEntryPoint
Iggy_AnimTurnB: dc.b    2, 1
                dc.w    Iggy_TurnBFrame0-Sys_GameEntryPoint
                dc.w    Iggy_TurnBFrame1-Sys_GameEntryPoint
Iggy_AnimSpawn: dc.b    4, 1
                dc.w    Iggy_SpawnFrame0-Sys_GameEntryPoint
                dc.w    Iggy_SpawnFrame1-Sys_GameEntryPoint
                dc.w    Iggy_SpawnFrame2-Sys_GameEntryPoint
                dc.w    Iggy_SpawnFrame3-Sys_GameEntryPoint
; Enemy spawner object with countdown timer
