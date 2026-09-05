; Enemy spawner and score popups.
; ROM $016312-$0164EB.

Obj_Spawner:
                bset    #7,(a0)  ; was: sub_16312
                bne.s   Obj_Spawner_Dispatch
                move.b  $3E(a0),d7
                move.b  $3F(a0),d6
                bsr.w   Math_GridToScreen
                addq.w  #8,d7
                addi.w  #$10,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)
                tst.b   (Ram_ActiveEnemyCount).w
                beq.s   Obj_Spawner_Dispatch
                move.w  (Ram_SpawnerDelay).w,$38(a0)

Obj_Spawner_Dispatch:  ; was: loc_1633E
                move.l  #Spawner_AnimPointers,8(a0)
                tst.b   (Ram_RoundEndingFlag).w
                bne.s   Obj_Spawner_Return
                tst.b   (Ram_CutsceneFlag).w
                bne.s   Obj_Spawner_Return
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     Spawner_StateTable(pc,d0.w)

Obj_Spawner_Return:  ; was: locret_1635C
                rts

Spawner_StateTable:  ; was: loc_1635E
                bra.w   Spawner_StateCountdown
                bra.w   Spawner_StateSpawn

; Spawner state: countdown before spawn
Spawner_StateCountdown:
                bset    #7,$3C(a0)  ; was: sub_16366
                bne.s   Spawner_StateCountdown_Tick
                addq.b  #1,(Ram_ActiveEnemyCount).w
                bset    #1,2(a0)

Spawner_StateCountdown_Tick:  ; was: loc_16378
                bsr.w   Object_UpdatePosition
                tst.w   $38(a0)
                bne.s   Spawner_StateCountdown_Decrement
                bclr    #1,2(a0)
                move.w  #4,$3C(a0)
                rts

Spawner_StateCountdown_Decrement:  ; was: loc_16390
                subq.w  #1,$38(a0)
                rts

; Spawner state: spawn animation
Spawner_StateSpawn:
                bset    #7,$3C(a0)  ; was: sub_16396
                bne.s   Spawner_StateSpawn_Animate
                bclr    #2,2(a0)
                clr.b   $10(a0)
                clr.w   6(a0)

Spawner_StateSpawn_Animate:  ; was: loc_163AC
                bsr.w   Object_UpdatePosition
                bsr.w   Anim_UpdateFrame
                bclr    #2,2(a0)
                beq.s   Spawner_StateSpawn_Return
                movea.l a0,a1
                suba.l  #$300,a1
                move.b  $16(a0),d0
                move.w  #$10,(a1)
                move.b  d0,$16(a1)
                cmpi.b  #2,d0
                bne.s   Spawner_StateSpawn_ClearSprites
                move.w  #$14,(a1)

Spawner_StateSpawn_ClearSprites:  ; was: loc_163DA
                bsr.w   Sprite_ClearLinkTable

Spawner_StateSpawn_Return:  ; was: locret_163DE
                rts

Spawner_AnimPointers: dc.l    Spawner_AnimAppear  ; was: off_163E0
Spawner_AnimAppear: dc.b    $1C, 4  ; was: byte_163E4
                dc.w    Spawner_AppearFrame0-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame0-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame0-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame1-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame1-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame1-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame2-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame3-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame4-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame5-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame6-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame5-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame4-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame3-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame2-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame3-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame4-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame5-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame6-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame5-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame4-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame3-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame2-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame3-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame4-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame5-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame6-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame5-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame4-Sys_GameEntryPoint
                dc.w    Spawner_AppearFrame3-Sys_GameEntryPoint
; Floating score popup display object
Obj_ScorePopup:
                bset    #7,(a0)  ; was: sub_16422
                bne.s   Obj_ScorePopup_Countdown
                moveq   #0,d0
                move.b  $3A(a0),d0
                subq.b  #1,d0
                lsl.w   #1,d0
                moveq   #$FFFFFFFF,d1
                move.w  ScorePopup_MappingPointers(pc,d0.w),d1
                move.l  d1,$C(a0)
                move.w  #$3C,$38(a0)

Obj_ScorePopup_Countdown:  ; was: loc_16442
                bsr.w   Object_UpdatePosition
                subq.w  #1,$38(a0)
                bne.s   Obj_ScorePopup_Return
                clr.w   (a0)

Obj_ScorePopup_Return:  ; was: locret_1644E
                rts

ScorePopup_MappingPointers: dc.w    ScorePopup_Map0-Sys_GameEntryPoint  ; was: off_16450
                dc.w    ScorePopup_Map1-Sys_GameEntryPoint
                dc.w    ScorePopup_Map2-Sys_GameEntryPoint
; Chick delivery count popup object
Obj_ChickCountPopup:
                bset    #7,(a0)  ; was: sub_16456
                bne.s   Obj_ChickCountPopup_Countdown
                move.b  $3A(a0),d0
                subq.b  #1,d0
                lsl.w   #1,d0
                moveq   #$FFFFFFFF,d1
                move.w  ChickCountPopup_MappingPointers(pc,d0.w),d1
                move.l  d1,$C(a0)
                lsl.w   #2,d0
                move.w  (Ram_ExitDoorY).w,d6
                cmpi.w  #$F0,d6
                bcs.s   Obj_ChickCountPopup_BelowDoor
                sub.w   d0,d6
                subi.w  #$18,d6
                bra.s   Obj_ChickCountPopup_SetPosition

Obj_ChickCountPopup_BelowDoor:  ; was: loc_16482
                add.w   d0,d6
                addq.w  #8,d6

Obj_ChickCountPopup_SetPosition:  ; was: loc_16486
                move.w  d6,$24(a0)
                move.w  #$1E,$38(a0)

Obj_ChickCountPopup_Countdown:  ; was: loc_16490
                bsr.w   Object_UpdatePosition
                subq.w  #1,$38(a0)
                bne.s   Obj_ChickCountPopup_Return
                clr.w   (a0)

Obj_ChickCountPopup_Return:  ; was: locret_1649C
                rts

ChickCountPopup_MappingPointers: dc.w    ChickCountPopup_Map0-Sys_GameEntryPoint  ; was: off_1649E
                dc.w    ScorePopup_Map0-Sys_GameEntryPoint
                dc.w    ChickCountPopup_Map2-Sys_GameEntryPoint
                dc.w    ScorePopup_Map1-Sys_GameEntryPoint
                dc.w    ChickCountPopup_Map4-Sys_GameEntryPoint
                dc.w    ChickCountPopup_Map5-Sys_GameEntryPoint
                dc.w    ChickCountPopup_Map6-Sys_GameEntryPoint
                dc.w    ChickCountPopup_Map7-Sys_GameEntryPoint
; Bonus round score popup object
Obj_BonusScorePopup:
                bset    #7,(a0)  ; was: sub_164AE
                bne.s   Obj_BonusScorePopup_Countdown
                moveq   #0,d0
                move.b  $3A(a0),d0
                lsl.w   #1,d0
                moveq   #$FFFFFFFF,d1
                move.w  BonusScorePopup_MappingPointers(pc,d0.w),d1
                move.l  d1,$C(a0)
                move.w  #$3C,$38(a0)

Obj_BonusScorePopup_Countdown:  ; was: loc_164CC
                bsr.w   Object_UpdatePosition
                subq.w  #1,$38(a0)
                bne.s   Obj_BonusScorePopup_Return
                clr.w   (a0)

Obj_BonusScorePopup_Return:  ; was: locret_164D8
                rts

BonusScorePopup_MappingPointers: dc.w    ChickCountPopup_Map0-Sys_GameEntryPoint  ; was: off_164DA
                dc.w    ScorePopup_Map0-Sys_GameEntryPoint
                dc.w    ChickCountPopup_Map2-Sys_GameEntryPoint
                dc.w    ScorePopup_Map1-Sys_GameEntryPoint
                dc.w    ChickCountPopup_Map4-Sys_GameEntryPoint
                dc.w    ScorePopup_Map2-Sys_GameEntryPoint
                dc.w    ChickCountPopup_Map5-Sys_GameEntryPoint
                dc.w    ChickCountPopup_Map6-Sys_GameEntryPoint
                dc.w    BonusScorePopup_Map8-Sys_GameEntryPoint
; Collectible star bonus object
