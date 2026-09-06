; Main game state machine.
; ROM $012A94-$012F2F.

Game_StartRound:
                jsr     Sys_InitTitleScreen  ; was: sub_12A94
                lea     (Gfx_SharedPalette).l,a5
                jsr     j_Gfx_LoadPaletteCompact
                bsr.s   Game_SetupLevel
                move.w  #$83,d0
                jsr     j_Sound_QueueToBuffer
                bsr.w   Game_RoundStartSequence
                bsr.w   Game_CalcDifficulty
                jmp     j_Sound_QueueSFX

; Sets up level: collision, objects, enemies, HUD
Game_SetupLevel:
                clr.b   (Ram_ChicksRemaining).w  ; was: sub_12ABA
                bsr.w   Level_LoadTileset
                bsr.w   Level_LoadPalette
                move.w  #1,(Ram_CameraX).w
                moveq   #$30,d7
                bsr.w   Math_ModuloUpper
                subq.b  #1,d0
                lsl.w   #1,d0
                moveq   #$FFFFFFFF,d1
                lea     (Level_DataPointers).l,a0
                move.w  (a0,d0.w),d1
                movea.l d1,a6
                move.w  d0,-(sp)
                bsr.w   Level_Init
                move.w  (sp)+,d0
                moveq   #$FFFFFFFF,d1
                lea     Level_SpecialTilePointers(pc),a0
                move.w  (a0,d0.w),d1
                movea.l d1,a6
                move.w  d0,-(sp)
                bsr.w   Collision_SetSpecialTiles
                move.w  (sp)+,d0
                lsl.w   #2,d0
                lea     Lizard_JumpArcTable(pc),a0
                move.l  (a0,d0.w),(Ram_LizardJumpVelX).w
                move.l  4(a0,d0.w),(Ram_LizardJumpVelY).w
                tst.b   (Ram_RestoreEnemiesFlag).w
                beq.s   Game_SetupLevel_CountAndDraw
                clr.b   (Ram_RestoreEnemiesFlag).w
                bsr.w   Enemy_RestoreFromBuffer

Game_SetupLevel_CountAndDraw:  ; was: loc_12B20
                bsr.w   Level_CountChicks
                bsr.w   Level_DrawCatDoor
                bsr.w   Level_CalcExitPos
                bsr.w   Level_SetCatPositions
                bsr.w   UI_DrawScoreLabels
                bsr.w   UI_DrawScore
                bsr.w   UI_DrawHighScore
                bsr.w   UI_DrawRoundNumber
                bsr.w   UI_DrawLives
                rts

; Main gameplay loop with state dispatcher.
; !(OBS) The mask keeps bit 15, which the states set through bset to record that
; their entry code has run, out of the index. Captures of the score screen read
; $8004, not $0004, which is Game_StateRoundComplete already entered.
Game_MainLoop:
                move.w  (Ram_GameState).w,d0  ; was: sub_12B46
                andi.w  #$7FFC,d0
                jsr     Game_StateTable(pc,d0.w)
                btst    #7,(Ram_Joypad+1).w
                beq.s   Game_MainLoop_PostFrame
                bsr.w   Game_Pause

Game_MainLoop_PostFrame:  ; was: loc_12B5E
                bsr.w   Score_CheckExtraLife
                bsr.w   Sound_ChannelCooldown
                jmp     j_Sound_QueueSFX

Game_StateTable:  ; was: loc_12B6A
                bra.w   Game_StatePlay
                bra.w   Game_StateRoundComplete
                bra.w   Game_StateBonusCheck
                bra.w   Game_CheckSkipBonus
                bra.w   Game_StateNextRound

; Gameplay state: normal play with object updates
Game_StatePlay:
                cmpi.l  #$1C000,(Ram_LizardSpeed).w  ; was: sub_12B7E
                bgt.s   Game_StatePlay_Update
                addq.l  #7,(Ram_LizardSpeed).w

Game_StatePlay_Update:  ; was: loc_12B8C
                bsr.w   Enemy_SpawnCats
                bsr.w   Object_UpdateAll
                bsr.w   Timer_IncrementTime
                rts

; Gameplay state: round complete score screen
Game_StateRoundComplete:
                bset    #7,(Ram_GameState).w  ; was: sub_12B9A
                bne.s   Game_StateRoundComplete_Update

Game_StateRoundComplete_WaitForSound:  ; was: loc_12BA2
                tst.b   (Ram_SoundBusyFlag).w
                beq.s   Game_StateRoundComplete_ShowScoreScreen
                bsr.w   Sound_ChannelCooldown
                jsr     j_Sound_QueueSFX
                bra.s   Game_StateRoundComplete_WaitForSound

Game_StateRoundComplete_ShowScoreScreen:  ; was: loc_12BB2
                move.b  #$82,d0
                jsr     j_Sound_QueueToBuffer
                move.w  #$8000,(Ram_TextTileBase).w
                bsr.w   UI_DrawScoreScreenLabels
                clr.w   (Ram_FrameCounter).w
                lea     (Ram_Object01).w,a0
                move.w  #4,Ram_Object01_State-Ram_Object01(a0)

Game_StateRoundComplete_Update:  ; was: loc_12BD2
                bsr.w   Object_UpdateAll
                bsr.w   Score_UpdateDisplay
                rts

; Gameplay state: bonus life check and award
Game_StateBonusCheck:
                bset    #7,(Ram_GameState).w  ; was: sub_12BDC
                bne.s   Game_StateBonusCheck_AwardLoop
                clr.w   (Ram_FrameCounter).w
                moveq   #$30,d7
                bsr.w   Math_ModuloUpper
                move.b  d0,d1
                moveq   #0,d0
                move.b  (Ram_RoundNumber+1).w,d0
                addq.b  #5,d0
                moveq   #$30,d7
                bsr.w   Math_ModuloFromD0
                lsr.w   #3,d0
                cmp.b   Game_BonusThresholdTable(pc,d0.w),d1
                bne.s   Game_StateBonusCheck_Advance
                tst.b   (Ram_SkipBonusFlag).w
                bne.s   Game_StateBonusCheck_ClearFlag
                lsl.w   #2,d0
                move.l  Game_BonusValueTable(pc,d0.w),(Ram_ScoreDelta).w
                moveq   #$A,d1

Game_StateBonusCheck_WaitLoop:  ; was: loc_12C16
                jsr     j_Sound_QueueSFX
                dbf     d1,Game_StateBonusCheck_WaitLoop
                lea     (Ram_Object01).w,a0
                move.w  #$54,(a0)
                move.b  #$E1,d0
                jsr     j_Sound_QueueToBuffer

Game_StateBonusCheck_AwardLoop:  ; was: loc_12C2E
                lea     (Ram_FrameCounter).w,a0
                cmpi.w  #8,(a0)
                bne.s   Game_StateBonusCheck_Update
                clr.w   (a0)
                move.w  #$8000,(Ram_TextTileBase).w
                bsr.w   Score_AddAndCheck
                movem.l d0/a0,-(sp)
                move.b  #$98,d0
                bsr.w   Sound_PlayNoteIfActive
                movem.l (sp)+,d0/a0
                addq.b  #1,(Ram_BonusAwardCount).w
                cmpi.b  #$A,(Ram_BonusAwardCount).w
                bne.s   Game_StateBonusCheck_Update
                clr.b   (Ram_BonusAwardCount).w
                clr.b   (Ram_ExitReachedFlag).w
                bra.s   Game_StateBonusCheck_Advance

Game_StateBonusCheck_Update:  ; was: loc_12C6A
                bsr.w   Object_UpdateAll
                rts

Game_StateBonusCheck_ClearFlag:  ; was: loc_12C70
                clr.b   (Ram_SkipBonusFlag).w

Game_StateBonusCheck_Advance:  ; was: loc_12C74
                move.w  #4,(Ram_GameState).w
                rts

Game_BonusThresholdTable: dc.b    2, $A, $12, $1A, $22, $2A  ; was: byte_12C7C
Game_BonusValueTable: dc.l    $200000, $1000, $5000, $10000, $50000, $100000  ; was: dword_12C82
; Checks if should skip bonus based on time
Game_CheckSkipBonus:
                moveq   #0,d0  ; was: sub_12C9A
                move.b  (Ram_RoundNumber+1).w,d0
                addq.b  #5,d0
                moveq   #$30,d7
                bsr.w   Math_ModuloFromD0
                lsr.w   #3,d0
                lsl.w   #1,d0
                move.w  (Ram_RoundTime).w,d1
                cmp.w   Game_BonusTimeLimits(pc,d0.w),d1
                bhi.s   Game_CheckSkipBonus_Skip
                cmpi.b  #1,(Ram_ExitReachedFlag).w
                bne.s   Game_CheckSkipBonus_Skip
                bra.s   Game_CheckSkipBonus_Advance

Game_CheckSkipBonus_Skip:  ; was: loc_12CC0
                move.b  #1,(Ram_SkipBonusFlag).w

Game_CheckSkipBonus_Advance:  ; was: loc_12CC6
                move.w  #8,(Ram_GameState).w
                rts

Game_BonusTimeLimits: dc.w    $25, $30, $35, $40, $45, $50  ; was: word_12CCE
; Gameplay state: next round transition
Game_StateNextRound:
                bset    #7,(Ram_GameState).w  ; was: sub_12CDA
                bne.s   Game_StateNextRound_Update
                moveq   #$1E,d1

Game_StateNextRound_WaitLoop:  ; was: loc_12CE4
                jsr     j_Sound_QueueSFX
                dbf     d1,Game_StateNextRound_WaitLoop
                move.b  #$84,d0
                jsr     j_Sound_QueueToBuffer
                move.w  #$3C,(Ram_ObjectSlots).w
                clr.b   (Ram_RestoreEnemiesFlag).w

Game_StateNextRound_Update:  ; was: loc_12CFE
                bsr.w   Object_UpdateMain
                move.w  #$B4,d1

Game_StateNextRound_FadeLoop:  ; was: loc_12D06
                jsr     j_Sound_QueueSFX
                dbf     d1,Game_StateNextRound_FadeLoop
                bsr.w   Gfx_FadeInPalette
                move.w  #$40,(Ram_NextGameMode).w
                rts

; Calculates door exit position for player spawn
Level_CalcExitPos:
                moveq   #0,d7  ; was: sub_12D1A
                moveq   #0,d6
                lea     (Ram_PlayerStartX).w,a0
                move.b  (a0),d7
                move.b  1(a0),d6
                bsr.w   Math_GridToScreen
                move.w  d7,(Ram_ExitDoorLeftX).w
                addi.w  #$17,d7
                move.w  d7,(Ram_ExitDoorRightX).w
                addi.w  #$18,d6
                move.w  d6,(Ram_ExitDoorY).w
                rts

; Updates score screen display with blinking
Score_UpdateDisplay:
                move.w  (Ram_FrameCounter).w,d0  ; was: sub_12D42
                cmpi.w  #$FA,d0
                bhi.s   Score_UpdateDisplay_AdvanceRound
                bsr.w   Text_CycleBlink
                bsr.w   UI_DrawScoreBreakdown
                rts

Score_UpdateDisplay_AdvanceRound:  ; was: loc_12D56
                addq.b  #1,(Ram_RoundNumber+1).w
                bne.s   Score_UpdateDisplay_IncrementBCD
                addq.b  #1,(Ram_RoundNumber+1).w

Score_UpdateDisplay_IncrementBCD:  ; was: loc_12D60
                move.b  (Ram_RoundNumber).w,d0
                moveq   #1,d1
                addi.b  #0,d0
                abcd    d1,d0
                move.b  d0,(Ram_RoundNumber).w
                move.w  #$18,(Ram_NextGameMode).w
                cmpi.b  #$49,d0
                bne.s   Score_UpdateDisplay_Return
                move.w  #$30,(Ram_NextGameMode).w

Score_UpdateDisplay_Return:  ; was: locret_12D82
                rts

; Spawns enemy cats during gameplay
Enemy_SpawnCats:
                lea     (Ram_ProjectileSlots).w,a0  ; was: sub_12D84
                lea     (Ram_CatSlot3).w,a1
                tst.w   (a0)
                bne.s   Enemy_SpawnCats_CheckSecondPair
                tst.w   (a1)
                bne.s   Enemy_SpawnCats_CheckSecondPair
                move.w  #$18,(a1)

Enemy_SpawnCats_CheckSecondPair:  ; was: loc_12D98
                lea     (Ram_CatSlot1).w,a0
                lea     (Ram_CatSlot2).w,a1
                lea     (Ram_CatSlot4).w,a2
                lea     (Ram_CatSlot5).w,a3
                tst.w   (a0)
                bne.s   Enemy_SpawnCats_CheckThirdPair
                tst.w   (a2)
                bne.s   Enemy_SpawnCats_CheckThirdPair
                tst.w   (a3)
                bne.s   Enemy_SpawnCats_CheckThirdPair
                move.w  #$18,(a2)
                move.b  #1,$16(a2)

Enemy_SpawnCats_CheckThirdPair:  ; was: loc_12DBE
                cmpi.b  #$A,(Ram_RoundNumber+1).w
                bcs.s   Enemy_SpawnCats_Return
                tst.w   (a1)
                bne.s   Enemy_SpawnCats_Return
                tst.w   (a3)
                bne.s   Enemy_SpawnCats_Return
                tst.w   (a2)
                bne.s   Enemy_SpawnCats_Return
                move.w  #$18,(a3)
                move.w  #4,$3C(a3)
                move.b  #2,$16(a3)

Enemy_SpawnCats_Return:  ; was: locret_12DE2
                rts

; Counts active chicks in enemy slots
Level_CountChicks:
                lea     (Ram_ChickSlots).w,a0  ; was: sub_12DE4
                moveq   #0,d1
                moveq   #7,d0

Level_CountChicks_Loop:  ; was: loc_12DEC
                tst.w   (a0)
                beq.s   Level_CountChicks_Next
                addq.b  #1,d1

Level_CountChicks_Next:  ; was: loc_12DF2
                lea     $40(a0),a0
                dbf     d0,Level_CountChicks_Loop
                move.b  d1,(Ram_ChicksRemaining).w
                rts

; Round start sequence with countdown animation
Game_RoundStartSequence:
                bsr.w   Object_UpdateAll  ; was: sub_12E00
                jsr     j_Sound_QueueSFX
                moveq   #$3C,d2

Game_RoundStartSequence_DelayLoop:  ; was: loc_12E0A
                bsr.w   Timer_IncrementTime
                jsr     j_Sound_QueueSFX
                dbf     d2,Game_RoundStartSequence_DelayLoop
                bsr.w   UI_AnimateTimer
                move.w  #$C,(Ram_PlayerObject).w
                bsr.w   Object_UpdateAll
                jsr     j_Sound_QueueSFX
                bsr.w   UI_AnimateCatCountdown
                rts

; Calculates round difficulty: speed and patterns
Game_CalcDifficulty:
                move.w  #$136,d1  ; was: sub_12E2E
                move.l  #$14000,d2
                move.b  (Ram_RoundNumber+1).w,d0
                cmpi.b  #$20,d0
                bls.s   Game_CalcDifficulty_ScaleLoop
                moveq   #$20,d0

Game_CalcDifficulty_ScaleLoop:  ; was: loc_12E44
                subq.w  #5,d1
                addi.l  #$200,d2
                dbf     d0,Game_CalcDifficulty_ScaleLoop
                move.w  d1,(Ram_SpawnerDelay).w
                move.l  d2,(Ram_SnakeSpeed).w
                move.l  #$14000,(Ram_LizardSpeed).w
                cmpi.b  #$30,(Ram_RoundNumber+1).w
                bls.s   Game_CalcDifficulty_SelectPattern
                move.l  #$18000,(Ram_LizardSpeed).w

Game_CalcDifficulty_SelectPattern:  ; was: loc_12E70
                moveq   #0,d1
                moveq   #$30,d7
                bsr.w   Math_ModuloUpper
                subq.b  #1,d0
                lea     Lizard_JumpSpeedIndex(pc),a0
                move.b  (a0,d0.w),d1
                lsl.w   #2,d1
                lea     Lizard_JumpSpeedTable(pc),a0
                move.l  (a0,d1.w),(Ram_LizardJumpSpeed).w
                rts

; Checks score thresholds for extra lives
Score_CheckExtraLife:
                move.l  (Ram_Score).w,d0  ; was: sub_12E90
                moveq   #0,d1
                moveq   #4,d7

Score_CheckExtraLife_Loop:  ; was: loc_12E98
                btst    d1,(Ram_ExtraLifeFlags).w
                bne.s   Score_CheckExtraLife_Next
                move.w  d1,d2
                lsl.w   #2,d2
                cmp.l   Score_ExtraLifeThresholds(pc,d2.w),d0
                bcs.s   Score_CheckExtraLife_Next
                bset    d1,(Ram_ExtraLifeFlags).w
                bsr.w   Score_AwardExtraLife
                bra.s   Score_CheckExtraLife_Return

Score_CheckExtraLife_Next:  ; was: loc_12EB2
                addq.b  #1,d1
                dbf     d7,Score_CheckExtraLife_Loop

Score_CheckExtraLife_Return:  ; was: locret_12EB8
                rts

; Awards extra life: sound and increment
Score_AwardExtraLife:
                move.l  d0,-(sp)  ; was: sub_12EBA
                move.b  #1,(Ram_SoundBusyFlag).w
                move.b  #$97,d0
                jsr     j_Sound_RequestZ80Bus
                move.b  d0,(Z80_MusicCommand).l
                jsr     j_ReleaseZ80Bus
                move.l  (sp)+,d0
                addq.b  #1,(Ram_Lives).w
                bsr.w   UI_DrawLives
                rts

Score_ExtraLifeThresholds: dc.l    $30000, $80000, $160000, $240000, $320000  ; was: dword_12EE0
; Pause game and wait for unpause input
Game_Pause:
                jsr     j_Sound_RequestZ80Bus  ; was: sub_12EF4
                move.b  #1,(Z80_PauseFlag).l
                jsr     j_ReleaseZ80Bus
                move.w  #$58,(Ram_ObjectSlots).w

Game_Pause_WaitLoop:  ; was: loc_12F0A
                bsr.w   Object_UpdateMain
                jsr     j_Sound_QueueSFX
                btst    #7,(Ram_Joypad+1).w
                beq.s   Game_Pause_WaitLoop
                jsr     j_Sound_RequestZ80Bus
                move.b  #$80,(Z80_PauseFlag).l
                jsr     j_ReleaseZ80Bus
                clr.w   (Ram_ObjectSlots).w
                rts

; Bonus round initialization
