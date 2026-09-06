; Snake enemy
; ROM $015D58-$016311

Obj_Snake:
                bset    #7,(a0)                         ; was: sub_15D58
                bne.s   Obj_Snake_Dispatch
                moveq   #0,d7
                moveq   #0,d6
                move.b  $3E(a0),d7
                move.b  $3F(a0),d6
                bsr.w   Math_GridToScreen
                addq.w  #8,d7
                addi.w  #$10,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)
                move.l  #Snake_AnimPointers,8(a0)
                clr.l   $34(a0)
                clr.l   $2C(a0)

Obj_Snake_Dispatch:                                     ; was: loc_15D8C
                tst.b   (Ram_CutsceneFlag).w
                bne.s   Obj_Snake_Return
                tst.b   (Ram_RoundEndingFlag).w
                bne.s   Obj_Snake_Return
                tst.b   (Ram_PlayerHitFlag).w
                bne.s   Obj_Snake_Return
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     Snake_StateTable(pc,d0.w)
                move.w  $3C(a0),d0
                andi.w  #$7C,d0
                cmpi.w  #$C,d0
                beq.s   Obj_Snake_Return
                cmpi.w  #$10,d0
                beq.s   Obj_Snake_Return
                bsr.w   Snake_CheckPlayerHit

Obj_Snake_Return:                                       ; was: locret_15DC0
                rts

Snake_StateTable:                                       ; was: loc_15DC2
                bra.w   Snake_StateSpawn
                bra.w   Snake_StateMove
                bra.w   Snake_StateTurn
                bra.w   Snake_StateHit
                bra.w   Snake_StateDeath

; Snake state: initial spawn animation
Snake_StateSpawn:
                bset    #7,$3C(a0)                      ; was: sub_15DD6
                bne.s   Snake_StateSpawn_Countdown
                move.b  #4,5(a0)
                move.l  #Snake_StateSpawnData,$C(a0)
                move.b  #$A,$3B(a0)

Snake_StateSpawn_Countdown:                             ; was: loc_15DF2
                bsr.w   Object_UpdatePosition
                subq.b  #1,$3B(a0)
                bne.s   Snake_StateSpawn_Return
                move.w  #4,$3C(a0)

Snake_StateSpawn_Return:                                ; was: locret_15E02
                rts

; Snake state: movement direction dispatcher
Snake_StateMove:
                bset    #7,$3C(a0)                      ; was: sub_15E04
                bne.s   Snake_StateMove_Dispatch
                move.b  #5,5(a0)

Snake_StateMove_Dispatch:                               ; was: loc_15E12
                moveq   #0,d0
                move.b  $3A(a0),d0
                lsl.w   #2,d0
                jsr     Snake_DirectionTable(pc,d0.w)
                rts

Snake_DirectionTable:                                   ; was: loc_15E20
                bra.w   Snake_MoveRight
                bra.w   Snake_MoveLeft
                bra.w   Snake_MoveLeft
                bra.w   Snake_MoveLeft
                bra.w   Snake_MoveUp
                bra.w   Snake_MoveUp
                bra.w   Snake_MoveDown
                bra.w   Snake_StateTurn

; Snake state: moving right on wall
Snake_MoveRight:
                clr.w   6(a0)                           ; was: sub_15E40
                bclr    #7,2(a0)
                move.l  (Ram_SnakeSpeed).w,$34(a0)
                clr.l   $2C(a0)
                bsr.w   Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Snake_MoveRight_TurnDown
                addq.w  #4,d7
                subq.w  #4,d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                bne.s   Snake_MoveRight_TurnUp
                moveq   #0,d7
                moveq   #$FFFFFFFC,d6
                bsr.w   Collision_GetTileAtObject
                tst.b   d4
                bne.s   Snake_MoveRight_StartTurn
                bsr.w   Anim_UpdateFrame
                rts

Snake_MoveRight_TurnDown:                               ; was: loc_15E86
                move.b  #6,$3A(a0)
                move.w  $30(a0),d7
                andi.w  #$FFF8,d7
                subq.w  #1,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                move.l  #Snake_MoveRight_TurnDownData,$C(a0)
                rts

Snake_MoveRight_TurnUp:                                 ; was: loc_15EA8
                move.b  #5,$3A(a0)
                andi.w  #$FFF8,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                addq.w  #4,$20(a0)
                andi.w  #$FFF8,d6
                addq.w  #7,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #Snake_MoveRight_TurnUpData,$C(a0)
                rts

Snake_MoveRight_StartTurn:                              ; was: loc_15ED6
                move.w  #8,$3C(a0)
                move.l  #Snake_MoveRight_StartTurnData,$C(a0)
                rts

; Snake state: moving left on wall
Snake_MoveLeft:
                move.w  #4,6(a0)                        ; was: sub_15EE6
                bset    #7,2(a0)
                move.l  (Ram_SnakeSpeed).w,d0
                neg.l   d0
                move.l  d0,$34(a0)
                clr.l   $2C(a0)
                bsr.w   Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Snake_MoveLeft_TurnUp
                subq.w  #4,d7
                addq.w  #4,d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                bne.s   Snake_MoveLeft_TurnDown
                moveq   #0,d7
                moveq   #4,d6
                bsr.w   Collision_GetTileAtObject
                tst.b   d4
                bne.s   Snake_MoveLeft_StartTurn
                bsr.w   Anim_UpdateFrame
                rts

Snake_MoveLeft_TurnUp:                                  ; was: loc_15F32
                move.b  #5,$3A(a0)
                move.w  $30(a0),d7
                andi.w  #$FFF8,d7
                addq.w  #8,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                move.l  #Snake_MoveLeft_TurnUpData,$C(a0)
                bclr    #7,2(a0)
                rts

Snake_MoveLeft_TurnDown:                                ; was: loc_15F5A
                move.b  #6,$3A(a0)
                andi.w  #$FFF8,d7
                addq.w  #7,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                subq.w  #4,$20(a0)
                andi.w  #$FFF8,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #Snake_MoveLeft_TurnDownData,$C(a0)
                bclr    #7,2(a0)
                rts

Snake_MoveLeft_StartTurn:                               ; was: loc_15F8E
                move.w  #8,$3C(a0)
                move.l  #Snake_MoveLeft_StartTurnData,$C(a0)
                rts

; Snake state: moving up on wall
Snake_MoveUp:
                move.w  #8,6(a0)                        ; was: sub_15F9E
                bclr    #7,2(a0)
                clr.l   $34(a0)
                move.l  (Ram_SnakeSpeed).w,d0
                neg.l   d0
                move.l  d0,$2C(a0)
                bsr.w   Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Snake_MoveUp_TurnLeft
                subq.w  #4,d7
                subq.w  #4,d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                bne.s   Snake_MoveUp_TurnRight
                bsr.w   Anim_UpdateFrame
                rts

Snake_MoveUp_TurnLeft:                                  ; was: loc_15FDE
                clr.b   $3A(a0)
                move.w  $24(a0),d6
                andi.w  #$FFF8,d6
                addq.w  #8,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #Snake_MoveUp_TurnLeftData,$C(a0)
                bclr    #7,2(a0)
                rts

Snake_MoveUp_TurnRight:                                 ; was: loc_16004
                move.b  #3,$3A(a0)
                andi.w  #$FFF8,d7
                addq.w  #7,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                andi.w  #$FFF8,d6
                addq.w  #7,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #Snake_MoveUp_TurnRightData,$C(a0)
                bclr    #7,2(a0)
                rts

; Snake state: moving down on wall
Snake_MoveDown:
                move.w  #$C,6(a0)                       ; was: sub_16036
                bset    #7,2(a0)
                clr.l   $34(a0)
                move.l  (Ram_SnakeSpeed).w,$2C(a0)
                bsr.w   Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   Snake_MoveUp_StartTurn
                addq.w  #4,d7
                addq.w  #4,d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                bne.s   Snake_MoveDown_TurnRight
                bsr.w   Anim_UpdateFrame
                rts

Snake_MoveUp_StartTurn:                                 ; was: loc_16072
                move.b  #3,$3A(a0)
                move.w  $24(a0),d6
                andi.w  #$FFF8,d6
                subq.w  #1,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #Snake_MoveUp_StartTurnData,$C(a0)
                bclr    #7,2(a0)
                rts

Snake_MoveDown_TurnRight:                               ; was: loc_1609A
                move.b  #0,$3A(a0)
                andi.w  #$FFF8,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                andi.w  #$FFF8,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #Snake_MoveDown_TurnRightData,$C(a0)
                bclr    #7,2(a0)
                rts

; Snake state: turning at corners
Snake_StateTurn:
                bset    #7,$3C(a0)                      ; was: sub_160C8
                bne.s   Snake_MoveDown_TurnLeft
                move.b  #5,5(a0)

Snake_MoveDown_TurnLeft:                                ; was: loc_160D6
                btst    #1,$3A(a0)
                bne.s   Snake_StateTurn_Continue
                move.w  #$10,6(a0)
                clr.l   $34(a0)
                move.l  (Ram_SnakeSpeed).w,d0
                neg.l   d0
                move.l  d0,$2C(a0)
                bsr.w   Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subq.w  #8,d6
                bsr.w   Collision_GetTileAtPos
                bne.s   Snake_MoveDown_StartTurn
                bsr.w   Anim_UpdateFrame
                rts

Snake_MoveDown_StartTurn:                               ; was: loc_1610C
                move.w  #4,$3C(a0)
                bchg    #0,$3A(a0)
                bchg    #1,$3A(a0)
                andi.w  #$FFF8,d6
                addq.w  #7,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #Snake_MoveLeft_StartTurnData,$C(a0)
                rts

Snake_StateTurn_Continue:                               ; was: loc_16136
                move.w  #$14,6(a0)
                clr.l   $34(a0)
                move.l  (Ram_SnakeSpeed).w,$2C(a0)
                bsr.w   Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                addq.w  #8,d6
                bsr.w   Collision_GetTileAtPos
                bne.s   Snake_StateTurn_Finish
                bsr.w   Anim_UpdateFrame
                rts

Snake_StateTurn_Finish:                                 ; was: loc_16160
                move.w  #4,$3C(a0)
                bchg    #0,$3A(a0)
                bchg    #1,$3A(a0)
                andi.w  #$FFF8,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #Snake_MoveRight_StartTurnData,$C(a0)
                rts

; Snake state: hit by player bouncing
Snake_StateHit:
                bset    #7,$3C(a0)                      ; was: sub_16188
                bne.s   Snake_StateHit_Move
                move.l  a0,-(sp)
                move.b  #$93,d0
                bsr.w   Sound_PlayNoteIfActive
                movea.l (sp)+,a0
                move.w  #$18,6(a0)
                subq.b  #1,(Ram_ActiveEnemyCount).w
                clr.b   5(a0)

Snake_StateHit_Move:                                    ; was: loc_161AA
                bsr.w   Chick_UpdatePhysics
                tst.l   $34(a0)
                bne.s   Snake_StateHit_Return
                move.w  #$10,$3C(a0)

Snake_StateHit_Return:                                  ; was: locret_161BA
                rts

; Snake state: death anim spawns new enemy
Snake_StateDeath:
                bset    #7,$3C(a0)                      ; was: sub_161BC
                bne.s   Snake_StateDeath_Update
                bclr    #2,2(a0)
                move.w  #$1C,6(a0)
                clr.b   $10(a0)
                move.l  #$FFFFC000,$2C(a0)
                clr.b   5(a0)

Snake_StateDeath_Update:                                ; was: loc_161E0
                bsr.w   Object_UpdatePosition
                bsr.w   Anim_UpdateFrame
                btst    #2,2(a0)
                beq.s   Snake_StateDeath_Return
                move.b  (Ram_RoundTime+2).w,d0
                andi.b  #$F0,d0
                bne.s   Snake_StateDeath_ClearSprites
                lea     (Ram_SnakeRespawnSlot).w,a1
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                move.w  d7,$30(a1)
                move.w  d6,$24(a1)
                move.w  #$28,(a1)

Snake_StateDeath_ClearSprites:                          ; was: loc_16212
                bsr.w   Sprite_ClearLinkTable

Snake_StateDeath_Return:                                ; was: locret_16216
                rts

; Snake collision with player hit detection
Snake_CheckPlayerHit:
                lea     (Ram_SpawnerSlots).w,a1         ; was: sub_16218
                moveq   #5,d0

Snake_CheckPlayerHit_Loop:                              ; was: loc_1621E
                move.w  d0,-(sp)
                btst    #4,5(a1)
                beq.s   Snake_CheckPlayerHit_Next
                bsr.w   Collision_CheckObjectPair
                tst.b   d0
                beq.s   Snake_CheckPlayerHit_Next
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
                move.l  Snake_HitScoreTable(pc,d0.w),d0
                move.l  d0,(Ram_ScoreDelta).w
                move.l  a1,-(sp)
                bsr.w   Score_AddAndCheck
                movea.l (sp)+,a1
                lea     (Ram_PopupSlots).w,a2
                moveq   #3,d0

Snake_CheckPlayerHit_PopupLoop:                         ; was: loc_1626E
                tst.b   (a2)
                bne.s   Snake_CheckPlayerHit_PopupNext
                move.w  #$1C,(a2)
                move.b  $3B(a1),d1
                move.b  d1,$3A(a2)
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subq.w  #8,d6
                move.w  d7,$30(a2)
                move.w  d6,$24(a2)
                bra.s   Snake_CheckPlayerHit_Return

Snake_CheckPlayerHit_PopupNext:                         ; was: loc_16292
                lea     -$40(a2),a2
                dbf     d0,Snake_CheckPlayerHit_PopupLoop
                bra.s   Snake_CheckPlayerHit_Return

Snake_CheckPlayerHit_Next:                              ; was: loc_1629C
                lea     $40(a1),a1
                move.w  (sp)+,d0
                dbf     d0,Snake_CheckPlayerHit_Loop
                rts

Snake_CheckPlayerHit_Return:                            ; was: loc_162A8
                move.w  (sp)+,d0
                rts

Snake_HitScoreTable:    dc.l    $200, $400, $800, $1600  ; was: dword_162AC
Snake_AnimPointers:     dc.l    Snake_AnimRight         ; was: off_162BC
                dc.l    Snake_AnimLeft
                dc.l    Snake_AnimUp
                dc.l    Snake_AnimDown
                dc.l    Snake_AnimTurnA
                dc.l    Snake_AnimTurnB
                dc.l    Snake_AnimSpawn
                dc.l    Lizard_AnimDeath
Snake_AnimRight:        dc.b    4, 1                    ; was: byte_162DC
                dc.w    Snake_RightFrame0-Sys_GameEntryPoint
                dc.w    Snake_RightFrame1-Sys_GameEntryPoint
                dc.w    Snake_RightFrame2-Sys_GameEntryPoint
                dc.w    Snake_RightFrame1-Sys_GameEntryPoint
Snake_AnimLeft: dc.b    4, 1                            ; was: byte_162E6
                dc.w    Snake_LeftFrame0-Sys_GameEntryPoint
                dc.w    Snake_LeftFrame1-Sys_GameEntryPoint
                dc.w    Snake_LeftFrame2-Sys_GameEntryPoint
                dc.w    Snake_LeftFrame1-Sys_GameEntryPoint
Snake_AnimUp:   dc.b    2, 1                            ; was: byte_162F0
                dc.w    Snake_UpFrame0-Sys_GameEntryPoint
                dc.w    Snake_UpFrame1-Sys_GameEntryPoint
Snake_AnimDown: dc.b    2, 1                            ; was: byte_162F6
                dc.w    Snake_DownFrame0-Sys_GameEntryPoint
                dc.w    Snake_DownFrame1-Sys_GameEntryPoint
Snake_AnimTurnA:        dc.b    2, 1                    ; was: byte_162FC
                dc.w    Snake_TurnAFrame0-Sys_GameEntryPoint
                dc.w    Snake_TurnAFrame1-Sys_GameEntryPoint
Snake_AnimTurnB:        dc.b    2, 1                    ; was: byte_16302
                dc.w    Snake_TurnBFrame0-Sys_GameEntryPoint
                dc.w    Snake_TurnBFrame1-Sys_GameEntryPoint
Snake_AnimSpawn:        dc.b    4, 1                    ; was: byte_16308
                dc.w    Snake_SpawnFrame0-Sys_GameEntryPoint
                dc.w    Snake_SpawnFrame1-Sys_GameEntryPoint
                dc.w    Snake_SpawnFrame2-Sys_GameEntryPoint
                dc.w    Snake_SpawnFrame3-Sys_GameEntryPoint
; Enemy spawner object with countdown timer
