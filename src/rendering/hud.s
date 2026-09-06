; HUD elements, animations, score and label drawing
; ROM $011BC2-$011FAF

UI_DrawHUDElements:
                moveq   #4,d0
                moveq   #5,d3

UI_DrawHUDElements_GroupLoop:
                move.w  UI_HUDCountTable(pc,d0.w),d1
                move.w  UI_HUDTypeTable(pc,d0.w),d4
                lsr.w   #1,d0
                moveq   #$FFFFFFFF,d2
                move.w  UI_HUDDataPointers(pc,d0.w),d2
                lsl.w   #1,d0
                movea.l d2,a0
                bra.s   UI_DrawHUDElements_ItemLoop
UI_HUDCountTable:   dc.w    0
UI_HUDTypeTable:    dc.w    0, 0, 0, 1, 1, 0, 2, $13, 3, 7, 4, 7, 5
UI_HUDDataPointers: dc.w    0, $D82E, $D830, $D834, $D836, $D85E, $D86E

UI_DrawHUDElements_ItemLoop:
                tst.b   2(a0)
                beq.s   UI_DrawHUDElements_NextItem
                moveq   #0,d7
                moveq   #0,d6
                move.b  0.w(a0),d7
                move.b  1(a0),d6
                movem.w d0-d4/a0,-(sp)
                bsr.w   Level_DrawBackgroundObject
                movem.w (sp)+,d0-d4/a0

UI_DrawHUDElements_NextItem:
                addq.l  #4,a0
                dbf     d1,UI_DrawHUDElements_ItemLoop
                addq.w  #4,d0
                dbf     d3,UI_DrawHUDElements_GroupLoop
                tst.b   (Ram_EntryArrowPos).w
                beq.s   UI_DrawHUDElements_Return
                bsr.w   Level_DrawEntryArrow

UI_DrawHUDElements_Return:
                rts

; Animates player entry arrow indicator
UI_AnimateEntryArrow:
                lea     (Ram_ArrowAnimState).w,a0
                lea     UI_EntryArrowAnim(pc),a1
                btst    #7,(IO_PCBVER+1).l
                beq.s   UI_AnimateEntryArrow_Play
                lea     UI_EntryArrowAnimAlt(pc),a1

UI_AnimateEntryArrow_Play:
                moveq   #0,d7
                moveq   #0,d6
                moveq   #0,d5
                move.b  (Ram_PlayerStartX).w,d7
                move.b  (Ram_PlayerStartY).w,d6
                subq.b  #1,d6
                move.w  #$E000,d5
                bsr.w   Gfx_TilemapCoordToAddr
                moveq   #2,d7
                moveq   #0,d6
                bsr.w   Anim_ProcessTimer
                rts

UI_EntryArrowAnim:  dc.b    4
                dc.b    4
                dc.l    UI_EntryArrowData0
                dc.l    UI_EntryArrowData1
                dc.l    UI_EntryArrowData2
                dc.l    UI_EntryArrowData1
UI_EntryArrowAnimAlt:   dc.b    4
                dc.b    4
                dc.l    UI_EntryArrowFrame1
                dc.l    UI_EntryArrowFrame3
                dc.l    UI_EntryArrowFrame2
                dc.l    UI_EntryArrowFrame3
UI_EntryArrowFrame1:    dc.w    $693, $694, $695
UI_EntryArrowFrame2:    dc.w    $696, $697, $698
UI_EntryArrowFrame3:    dc.w    $699, $69A, $69B
; Updates and animates timer display
UI_AnimateTimer:
                lea     UI_TimerAnim(pc),a1
                bsr.w   UI_PlayAnimation
                bsr.w   Timer_IncrementTime
                rts

UI_TimerAnim:   dc.b    4
                dc.b    $F
                dc.l    UI_TimerData0
                dc.l    UI_TimerData1
                dc.l    UI_TimerData2
                dc.l    UI_TimerData0
; Plays cat rescue countdown animation
UI_AnimateCatCountdown:
                lea     UI_CatCountdownAnim(pc),a1
                jmp     UI_PlayAnimation

UI_CatCountdownAnim:    dc.b    4
                dc.b    2
                dc.l    Level_BgObject0Data
                dc.l    UI_TimerData0
                dc.l    UI_TimerData2
                dc.l    UI_TimerData1
; Plays reverse cat countdown animation
UI_AnimateCatCountReverse:
                lea     UI_CatCountReverseAnim(pc),a1
                jmp     UI_PlayAnimation

UI_CatCountReverseAnim: dc.b    5
                dc.b    2
                dc.l    UI_BlankFrameMappings
                dc.l    UI_TimerData1
                dc.l    UI_TimerData2
                dc.l    UI_TimerData0
                dc.l    UI_CatCountReverseData3
UI_BlankFrameMappings:  dc.w    0, 0, 0, 0, 0, 0, 0, 0, 0
; Plays bonus animation on score screen
UI_AnimateBonus:
                lea     UI_BonusAnim(pc),a1
                jmp     UI_PlayAnimation

UI_BonusAnim:   dc.b    5
                dc.b    1
                dc.l    Level_BgObject0Data
                dc.l    UI_CatCountReverseData3
                dc.l    UI_TimerData0
                dc.l    UI_TimerData2
                dc.l    UI_TimerData1
; Generic animation loop until completion flag
UI_PlayAnimation:
                move.b  #1,(Ram_CutsceneFlag).w
                lea     (Ram_UIAnimState).w,a0
                clr.l   (a0)
                moveq   #0,d7
                moveq   #0,d6
                moveq   #0,d5
                move.b  (Ram_PlayerStartX).w,d7
                move.b  (Ram_PlayerStartY).w,d6
                move.w  #$C000,d5
                bsr.w   Gfx_TilemapCoordToAddr
                moveq   #2,d7
                moveq   #2,d6

UI_PlayAnimation_Loop:
                movem.l d5-d7/a0-a4,-(sp)
                bsr.w   Anim_ProcessTimer
                tst.b   2(a0)
                bne.s   UI_PlayAnimation_Done
                bsr.w   Object_UpdateAll
                bsr.w   Timer_IncrementTime
                jsr     j_Sound_QueueSFX
                movem.l (sp)+,d5-d7/a0-a4
                bra.s   UI_PlayAnimation_Loop

UI_PlayAnimation_Done:
                clr.b   (Ram_CutsceneFlag).w
                movem.l (sp)+,d5-d7/a0-a4
                rts

; Draws life indicator icons based on lives count
UI_DrawLives:
                moveq   #0,d0
                move.b  (Ram_Lives).w,d0
                beq.s   UI_DrawLives_Return
                subq.w  #1,d0
                beq.s   UI_DrawLives_Return
                subq.w  #1,d0
                move.l  #$46840003,(VDP_CTRL).l
                btst    #6,(IO_PCBVER+1).l
                beq.s   UI_DrawLives_IconLoop
                move.l  #$47440003,(VDP_CTRL).l

UI_DrawLives_IconLoop:
                move.w  #$4350,(VDP_DATA).l
                dbf     d0,UI_DrawLives_IconLoop

UI_DrawLives_Return:
                rts

; Draws current score BCD value
UI_DrawScore:
                lea     (Ram_Score).w,a6
                moveq   #0,d5
                move.w  #$C04A,d5
                moveq   #3,d0
                bsr.w   Text_DrawBCDNumber
                rts

; Draws high score BCD value
UI_DrawHighScore:
                lea     (Ram_HighScore).w,a6
                moveq   #0,d5
                move.w  #$C068,d5
                moveq   #3,d0
                bsr.w   Text_DrawBCDNumber
                rts

; Draws current round number with region check
UI_DrawRoundNumber:
                lea     (Ram_RoundNumber).w,a6
                moveq   #0,d5
                move.w  #$C6BA,d5
                btst    #6,(IO_PCBVER+1).l
                beq.s   UI_DrawRoundNumber_Draw
                move.w  #$C77A,d5

UI_DrawRoundNumber_Draw:
                moveq   #0,d0
                bsr.w   Text_DrawBCDNumber
                rts

; Draws RD label and calls score/hiscore labels
UI_DrawScoreLabels:
                lea     UI_RoundLabel(pc),a6
                btst    #6,(IO_PCBVER+1).l
                beq.s   UI_DrawScoreLabels_Draw
                lea     UI_RoundLabelAlt(pc),a6

UI_DrawScoreLabels_Draw:
                bsr.w   Text_DrawString

; Draws 1UP and HI label graphics
UI_Draw1UPAndHILabels:
                lea     (UI_Draw1UPAndHILabelsData0).l,a6
                moveq   #1,d7
                moveq   #0,d6
                moveq   #0,d5
                move.w  #$C048,d5
                bsr.w   Gfx_DrawTilemapStart
                lea     (UI_Draw1UPAndHILabelsData1).l,a6
                moveq   #2,d7
                moveq   #0,d6
                moveq   #0,d5
                move.w  #$C064,d5
                bsr.w   Gfx_DrawTilemapStart
                rts

UI_RoundLabel:      dc.b    $C6, $B4
UI_RdText:          dc.b    "RD.",0
UI_RoundLabelAlt:   dc.b    $C7, $74
UI_RdText2:         dc.b    "RD.",0
; Draws detailed score breakdown on results
UI_DrawScoreBreakdown:
                lea     (Ram_RoundMinutes).w,a6
                moveq   #0,d5
                move.w  #$C160,d5
                btst    #7,(IO_PCBVER+1).l
                beq.s   UI_DrawScoreBreakdown_DrawSeconds
                subq.w  #4,d5

UI_DrawScoreBreakdown_DrawSeconds:
                moveq   #0,d0
                bsr.w   Text_DrawBCDNumber
                lea     (Ram_RoundSeconds).w,a6
                moveq   #0,d5
                move.w  #$C16C,d5
                moveq   #0,d0
                bsr.w   Text_DrawBCDNumber
                tst.b   (Ram_RoundMinutes).w
                bne.s   UI_DrawScoreBreakdown_Return
                lea     (Ram_TimeBonus).w,a6
                moveq   #0,d5
                move.w  #$C260,d5
                moveq   #3,d0
                bsr.w   Text_DrawBCDNumber

UI_DrawScoreBreakdown_Return:
                rts

; Draws score screen text labels with region check
UI_DrawScoreScreenLabels:
                lea     UI_GameTimeLabel(pc),a6
                btst    #7,(IO_PCBVER+1).l
                beq.s   UI_DrawScoreScreenLabels_DrawTitle
                lea     UI_RoundTimeLabel(pc),a6

UI_DrawScoreScreenLabels_DrawTitle:
                bsr.w   Text_DrawString
                lea     UI_MinSecLabel(pc),a6
                btst    #7,(IO_PCBVER+1).l
                beq.s   UI_DrawScoreScreenLabels_DrawUnits
                lea     UI_MinLabel(pc),a6

UI_DrawScoreScreenLabels_DrawUnits:
                bsr.w   Text_DrawString
                btst    #7,(IO_PCBVER+1).l
                beq.s   UI_DrawScoreScreenLabels_DrawSecLabel
                lea     UI_SecLabel(pc),a6
                bsr.w   Text_DrawString

UI_DrawScoreScreenLabels_DrawSecLabel:
                lea     UI_TimeBonusLabel(pc),a6
                btst    #7,(IO_PCBVER+1).l
                beq.s   UI_DrawScoreScreenLabels_DrawBonusLabel
                lea     UI_TimeBonusLabelAlt(pc),a6

UI_DrawScoreScreenLabels_DrawBonusLabel:
                bsr.w   Text_DrawString
                tst.b   (Ram_RoundMinutes).w
                bne.s   UI_DrawScoreScreenLabels_NoBonus
                lea     UI_PtsLabel(pc),a6
                bsr.w   Text_DrawString
                bra.s   UI_DrawScoreScreenLabels_Return

UI_DrawScoreScreenLabels_NoBonus:
                lea     UI_NoBonusLabel(pc),a6
                bsr.w   Text_DrawString

UI_DrawScoreScreenLabels_Return:
                rts

UI_GameTimeLabel:   dc.b    $C1, $4A
UI_GameTimeText:    dc.b    "GAME TIME",0
UI_MinSecLabel:     dc.b    $C1, $64
UI_MinSecText:      dc.b    "MIN.  SEC.",0
                dc.b    0
UI_TimeBonusLabel:  dc.b    $C2, $4A
UI_TimeBonusText:   dc.b    "TIME BONUS",0
                dc.b    0
UI_PtsLabel:    dc.b    $C2, $72
UI_PtsText:     dc.b    "PTS.",0
                dc.b    0
UI_NoBonusLabel:    dc.b    $C2, $68
UI_NoBonusText:     dc.b    "NO BONUS",0
                dc.b    0
UI_RoundTimeLabel:  dc.b    $C1, $48
UI_RoundTimeText:   dc.b    "ROUND TIME",0
                dc.b    0
UI_MinLabel:    dc.b    $C1, $62
UI_MinText:     dc.b    "MIN.",0
                dc.b    0
UI_SecLabel:    dc.b    $C1, $72
UI_SecText:     dc.b    "SEC.",0
                dc.b    0
UI_TimeBonusLabelAlt:   dc.b    $C2, $48
UI_TimeBonusText2:      dc.b    "TIME BONUS",0
                dc.b    0
; Draws bonus round chicks collected and score
UI_DrawBonusRoundScore:
                tst.b   (Ram_BonusCaughtCount).w
                beq.s   UI_DrawBonusRoundScore_Return
                lea     (Ram_BonusCaughtBCD).w,a6
                moveq   #0,d5
                move.w  #$C248,d5
                moveq   #0,d0
                bsr.w   Text_DrawBCDNumber
                lea     ((Ram_BonusScore+2)).w,a6
                moveq   #0,d5
                move.w  #$C266,d5
                moveq   #1,d0
                bsr.w   Text_DrawBCDNumber
                cmpi.b  #$14,(Ram_BonusCaughtCount).w
                bne.s   UI_DrawBonusRoundScore_Return
                lea     UI_PerfectBonusValue(pc),a6
                moveq   #0,d5
                move.w  #$C390,d5
                moveq   #3,d0
                bsr.w   Text_DrawBCDNumber

UI_DrawBonusRoundScore_Return:
                rts

UI_PerfectBonusValue:   dc.b    0, 1, 0, 0
; Initializes title screen: tiles, objects, music
