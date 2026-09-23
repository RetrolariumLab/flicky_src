; Bonus round flow
; ROM $012F30-$01310F

Bonus_Init:
                bsr.w   Sys_InitTitleScreen
                move.w  #$8F02,(VDP_CTRL).l
                lea     (Gfx_SharedPalette).l,a5
                jsr     j_Gfx_LoadPaletteCompact
                move.w  #$2C,(Ram_BonusPaletteEntry).w
                bsr.w   Collision_ClearMap
                bsr.w   Level_LoadTileset
                bsr.w   Level_LoadPalette
                move.b  #1,(Ram_BonusRoundFlag).w
                move.b  #$14,(Ram_ChicksRemaining).w
                bsr.w   Level_DrawUpperGround
                bsr.w   Level_DrawLowerGround
                lea     (Ram_CollisionMapBonusRow).w,a0
                moveq   #$1F,d0

Bonus_Init_FillCollisionLoop:
                move.b  #1,(a0)+
                dbf     d0,Bonus_Init_FillCollisionLoop
                lea     (VDP_DATA).l,a0
                move.l  #$65400003,(VDP_CTRL).l
                moveq   #$1F,d0

Bonus_Init_FillGroundLoop:
                move.w  #$220D,(a0)
                dbf     d0,Bonus_Init_FillGroundLoop
                lea     Bonus_BonusLabel(pc),a6
                bsr.w   Text_DrawString
                lea     Bonus_RoundLabel(pc),a6
                bsr.w   Text_DrawString
                bsr.w   Bonus_SetupObjects
                bsr.w   UI_DrawScoreLabels
                bsr.w   UI_DrawScore
                bsr.w   UI_DrawHighScore
                bsr.w   UI_DrawRoundNumber
                bsr.w   UI_DrawLives
                move.b  #$81,d0
                jsr     j_Sound_QueueToBuffer
                jsr     j_Sound_QueueSFX
                jmp     j_Sound_QueueSFX

Bonus_BonusLabel:   dc.b    $C0, $D4
Bonus_BonusText:    dc.b    "BONUS",0
Bonus_RoundLabel:   dc.b    $C0, $E0
Bonus_RoundText:    dc.b    "ROUND",0
; Bonus round main loop with state dispatcher
Bonus_MainLoop:
                move.w  (Ram_BonusState).w,d0
                andi.w  #$7FFC,d0
                jsr     Bonus_StateTable(pc,d0.w)
                btst    #7,(Ram_Joypad+1).w
                beq.s   Bonus_MainLoop_PostFrame
                bsr.w   Game_Pause

Bonus_MainLoop_PostFrame:
                bsr.w   Score_CheckExtraLife
                bsr.w   Sound_ChannelCooldown
                jmp     j_Sound_QueueSFX

Bonus_StateTable:
                bra.w   Bonus_StatePlay
                bra.w   Bonus_StateComplete

; Bonus round play state
Bonus_StatePlay:
                bsr.w   Object_UpdateAll
                rts

; Bonus round complete state
Bonus_StateComplete:
                bset    #7,(Ram_BonusState).w
                bne.s   Bonus_StateComplete_Update

Bonus_StateComplete_WaitForSound:
                tst.b   (Ram_SoundBusyFlag).w
                beq.s   Bonus_StateComplete_ShowResults
                bsr.w   Sound_ChannelCooldown
                jsr     j_Sound_QueueSFX
                bra.s   Bonus_StateComplete_WaitForSound

Bonus_StateComplete_ShowResults:
                move.b  #$82,d0
                jsr     j_Sound_QueueToBuffer
                bsr.w   Bonus_DrawResultLabels

Bonus_StateComplete_Update:
                bsr.w   Object_UpdateAll
                bsr.w   Bonus_ScoreUpdate
                rts

; Sets up bonus round objects: player, seesaws, Tigers and Chirps
Bonus_SetupObjects:
                lea     (Ram_BonusPlayerObject).w,a0
                move.w  #$C,(a0)
                move.w  #$D11,$3E(a0)
                move.w  #$2C,(Ram_Object01).w
                lea     (Ram_BonusSeesawSlots).w,a0
                move.w  #$30,(a0)
                lea     $40(a0),a0
                move.w  #$30,(a0)
                move.b  #1,$16(a0)
                lea     (Ram_BonusTigerSlots).w,a0
                move.w  #$34,(a0)
                lea     $40(a0),a0
                move.w  #$34,(a0)
                move.b  #1,$16(a0)
                lea     (Ram_BonusChickSlots).w,a0
                moveq   #0,d1
                moveq   #$13,d0

Bonus_SetupObjects_ChickLoop:
                move.w  #$38,(a0)
                move.b  d1,$38(a0)
                btst    #2,d1
                beq.s   Bonus_SetupObjects_NextChick
                move.b  #1,$39(a0)

Bonus_SetupObjects_NextChick:
                lea     $40(a0),a0
                addq.b  #1,d1
                dbf     d0,Bonus_SetupObjects_ChickLoop
                moveq   #0,d0
                move.b  (Ram_RoundNumber+1).w,d0
                moveq   #$30,d7
                bsr.w   Math_ModuloLower
                subq.b  #3,d0
                lsr.w   #2,d0
                lsl.w   #2,d0
                lea     Bonus_ChickDelayPointers(pc),a0
                move.l  (a0,d0.w),(Ram_BonusChickDelayPtr).w
                lea     Bonus_ChickVelocityPointers(pc),a0
                move.l  (a0,d0.w),(Ram_BonusChickVelocityPtr).w
                lea     Bonus_ChickTrajIndexPointers(pc),a0
                move.l  (a0,d0.w),(Ram_BonusChickTrajPtr).w
                rts

; Bonus round score display with blink and round advance
Bonus_ScoreUpdate:
                move.b  #1,(Ram_CutsceneFlag).w
                move.w  (Ram_FrameCounter).w,d0
                cmpi.w  #$FA,d0
                bhi.s   Bonus_ScoreUpdate_AdvanceRound
                bsr.w   Text_CycleBlink
                bsr.w   UI_DrawBonusRoundScore
                rts

Bonus_ScoreUpdate_AdvanceRound:
                addq.b  #1,(Ram_RoundNumber+1).w
                bne.s   Bonus_ScoreUpdate_IncrementBCD
                addq.b  #1,(Ram_RoundNumber+1).w

Bonus_ScoreUpdate_IncrementBCD:
                move.b  (Ram_RoundNumber).w,d0
                moveq   #1,d1
                addi.b  #0,d0
                abcd    d1,d0
                move.b  d0,(Ram_RoundNumber).w
                move.w  #$18,(Ram_NextGameMode).w
                rts

; Game complete/congratulations screen initialization
