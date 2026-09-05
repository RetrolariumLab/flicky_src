; HUD elements, animations, score and label drawing.
; ROM $011BC2-$011FAF.

UI_DrawHUDElements:
                moveq   #4,d0  ; was: sub_11BC2
                moveq   #5,d3

UI_DrawHUDElements_GroupLoop:  ; was: loc_11BC6
                move.w  UI_HUDCountTable(pc,d0.w),d1
                move.w  UI_HUDTypeTable(pc,d0.w),d4
                lsr.w   #1,d0
                moveq   #$FFFFFFFF,d2
                move.w  UI_HUDDataPointers(pc,d0.w),d2
                lsl.w   #1,d0
                movea.l d2,a0
                bra.s   UI_DrawHUDElements_ItemLoop
UI_HUDCountTable: dc.w    0  ; was: word_11BDC
UI_HUDTypeTable: dc.w    0, 0, 0, 1, 1, 0, 2, $13, 3, 7, 4, 7, 5  ; was: word_11BDE
UI_HUDDataPointers: dc.w    0, $D82E, $D830, $D834, $D836, $D85E, $D86E  ; was: word_11BF8

UI_DrawHUDElements_ItemLoop:  ; was: loc_11C06
                tst.b   2(a0)
                beq.s   UI_DrawHUDElements_NextItem
                moveq   #0,d7
                moveq   #0,d6
                move.b  0.w(a0),d7
                move.b  1(a0),d6
                movem.w d0-d4/a0,-(sp)
                bsr.w   Level_DrawBackgroundObject
                movem.w (sp)+,d0-d4/a0

UI_DrawHUDElements_NextItem:  ; was: loc_11C24
                addq.l  #4,a0
                dbf     d1,UI_DrawHUDElements_ItemLoop
                addq.w  #4,d0
                dbf     d3,UI_DrawHUDElements_GroupLoop
                tst.b   (Ram_EntryArrowPos).w
                beq.s   UI_DrawHUDElements_Return
                bsr.w   Level_DrawEntryArrow

UI_DrawHUDElements_Return:  ; was: locret_11C3A
                rts

; Animates player entry arrow indicator
UI_AnimateEntryArrow:
                lea     (Ram_ArrowAnimState).w,a0  ; was: sub_11C3C
                lea     UI_EntryArrowAnim(pc),a1
                btst    #7,(IO_PCBVER+1).l
                beq.s   UI_AnimateEntryArrow_Play
                lea     UI_EntryArrowAnimAlt(pc),a1

UI_AnimateEntryArrow_Play:  ; was: loc_11C52
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

UI_EntryArrowAnim: dc.b    4  ; was: byte_11C74
                dc.b    4
                dc.l    UI_EntryArrowData0
                dc.l    UI_EntryArrowData1
                dc.l    UI_EntryArrowData2
                dc.l    UI_EntryArrowData1
UI_EntryArrowAnimAlt: dc.b    4  ; was: byte_11C86
                dc.b    4
                dc.l    UI_EntryArrowFrame1
                dc.l    UI_EntryArrowFrame3
                dc.l    UI_EntryArrowFrame2
                dc.l    UI_EntryArrowFrame3
UI_EntryArrowFrame1: dc.w    $693, $694, $695  ; was: word_11C98
UI_EntryArrowFrame2: dc.w    $696, $697, $698  ; was: word_11C9E
UI_EntryArrowFrame3: dc.w    $699, $69A, $69B  ; was: word_11CA4
; Updates and animates timer display
UI_AnimateTimer:
                lea     UI_TimerAnim(pc),a1  ; was: sub_11CAA
                bsr.w   UI_PlayAnimation
                bsr.w   Timer_IncrementTime
                rts

UI_TimerAnim:   dc.b    4  ; was: byte_11CB8
                dc.b    $F
                dc.l    UI_TimerData0
                dc.l    UI_TimerData1
                dc.l    UI_TimerData2
                dc.l    UI_TimerData0
; Plays cat rescue countdown animation
UI_AnimateCatCountdown:
                lea     UI_CatCountdownAnim(pc),a1  ; was: sub_11CCA
                jmp     UI_PlayAnimation

UI_CatCountdownAnim: dc.b    4  ; was: byte_11CD4
                dc.b    2
                dc.l    Level_BgObject0Data
                dc.l    UI_TimerData0
                dc.l    UI_TimerData2
                dc.l    UI_TimerData1
; Plays reverse cat countdown animation
UI_AnimateCatCountReverse:
                lea     UI_CatCountReverseAnim(pc),a1  ; was: sub_11CE6
                jmp     UI_PlayAnimation

UI_CatCountReverseAnim: dc.b    5  ; was: byte_11CF0
                dc.b    2
                dc.l    UI_BlankFrameMappings
                dc.l    UI_TimerData1
                dc.l    UI_TimerData2
                dc.l    UI_TimerData0
                dc.l    UI_CatCountReverseData3
UI_BlankFrameMappings: dc.w    0, 0, 0, 0, 0, 0, 0, 0, 0  ; was: word_11D06
; Plays bonus animation on score screen
UI_AnimateBonus:
                lea     UI_BonusAnim(pc),a1  ; was: sub_11D18
                jmp     UI_PlayAnimation

UI_BonusAnim:   dc.b    5  ; was: byte_11D22
                dc.b    1
                dc.l    Level_BgObject0Data
                dc.l    UI_CatCountReverseData3
                dc.l    UI_TimerData0
                dc.l    UI_TimerData2
                dc.l    UI_TimerData1
; Generic animation loop until completion flag
UI_PlayAnimation:
                move.b  #1,(Ram_CutsceneFlag).w  ; was: sub_11D38
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

UI_PlayAnimation_Loop:  ; was: loc_11D5E
                movem.l d5-d7/a0-a4,-(sp)
                bsr.w   Anim_ProcessTimer
                tst.b   2(a0)
                bne.s   UI_PlayAnimation_Done
                bsr.w   Object_UpdateAll
                bsr.w   Timer_IncrementTime
                jsr     j_Sound_QueueSFX
                movem.l (sp)+,d5-d7/a0-a4
                bra.s   UI_PlayAnimation_Loop

UI_PlayAnimation_Done:  ; was: loc_11D7E
                clr.b   (Ram_CutsceneFlag).w
                movem.l (sp)+,d5-d7/a0-a4
                rts

; Draws life indicator icons based on lives count
UI_DrawLives:
                moveq   #0,d0  ; was: sub_11D88
                move.b  (Ram_Lives).w,d0
                beq.s   UI_DrawLives_Return
                subq.w  #1,d0
                beq.s   UI_DrawLives_Return
                subq.w  #1,d0
                move.l  #$46840003,(VDP_CTRL).l
                btst    #6,(IO_PCBVER+1).l
                beq.s   UI_DrawLives_IconLoop
                move.l  #$47440003,(VDP_CTRL).l

UI_DrawLives_IconLoop:  ; was: loc_11DB4
                move.w  #$4350,(VDP_DATA).l
                dbf     d0,UI_DrawLives_IconLoop

UI_DrawLives_Return:  ; was: locret_11DC0
                rts

; Draws current score BCD value
UI_DrawScore:
                lea     (Ram_Score).w,a6  ; was: sub_11DC2
                moveq   #0,d5
                move.w  #$C04A,d5
                moveq   #3,d0
                bsr.w   Text_DrawBCDNumber
                rts

; Draws high score BCD value
UI_DrawHighScore:
                lea     (Ram_HighScore).w,a6  ; was: sub_11DD4
                moveq   #0,d5
                move.w  #$C068,d5
                moveq   #3,d0
                bsr.w   Text_DrawBCDNumber
                rts

; Draws current round number with region check
UI_DrawRoundNumber:
                lea     (Ram_RoundNumber).w,a6  ; was: sub_11DE6
                moveq   #0,d5
                move.w  #$C6BA,d5
                btst    #6,(IO_PCBVER+1).l
                beq.s   UI_DrawRoundNumber_Draw
                move.w  #$C77A,d5

UI_DrawRoundNumber_Draw:  ; was: loc_11DFE
                moveq   #0,d0
                bsr.w   Text_DrawBCDNumber
                rts

; Draws RD label and calls score/hiscore labels
UI_DrawScoreLabels:
                lea     UI_RoundLabel(pc),a6  ; was: sub_11E06
                btst    #6,(IO_PCBVER+1).l
                beq.s   UI_DrawScoreLabels_Draw
                lea     UI_RoundLabelAlt(pc),a6

UI_DrawScoreLabels_Draw:  ; was: loc_11E18
                bsr.w   Text_DrawString

; Draws 1UP and HI label graphics
UI_Draw1UPAndHILabels:
                lea     (UI_Draw1UPAndHILabelsData0).l,a6  ; was: sub_11E1C
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

UI_RoundLabel:  dc.b    $C6, $B4  ; was: byte_11E46
UI_RdText:      dc.b    "RD.",0
UI_RoundLabelAlt: dc.b    $C7, $74  ; was: byte_11E4C
UI_RdText2:     dc.b    "RD.",0
; Draws detailed score breakdown on results
UI_DrawScoreBreakdown:
                lea     (Ram_RoundMinutes).w,a6  ; was: sub_11E52
                moveq   #0,d5
                move.w  #$C160,d5
                btst    #7,(IO_PCBVER+1).l
                beq.s   UI_DrawScoreBreakdown_DrawSeconds
                subq.w  #4,d5

UI_DrawScoreBreakdown_DrawSeconds:  ; was: loc_11E68
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

UI_DrawScoreBreakdown_Return:  ; was: locret_11E94
                rts

; Draws score screen text labels with region check
UI_DrawScoreScreenLabels:
                lea     UI_GameTimeLabel(pc),a6  ; was: sub_11E96
                btst    #7,(IO_PCBVER+1).l
                beq.s   UI_DrawScoreScreenLabels_DrawTitle
                lea     UI_RoundTimeLabel(pc),a6

UI_DrawScoreScreenLabels_DrawTitle:  ; was: loc_11EA8
                bsr.w   Text_DrawString
                lea     UI_MinSecLabel(pc),a6
                btst    #7,(IO_PCBVER+1).l
                beq.s   UI_DrawScoreScreenLabels_DrawUnits
                lea     UI_MinLabel(pc),a6

UI_DrawScoreScreenLabels_DrawUnits:  ; was: loc_11EBE
                bsr.w   Text_DrawString
                btst    #7,(IO_PCBVER+1).l
                beq.s   UI_DrawScoreScreenLabels_DrawSecLabel
                lea     UI_SecLabel(pc),a6
                bsr.w   Text_DrawString

UI_DrawScoreScreenLabels_DrawSecLabel:  ; was: loc_11ED4
                lea     UI_TimeBonusLabel(pc),a6
                btst    #7,(IO_PCBVER+1).l
                beq.s   UI_DrawScoreScreenLabels_DrawBonusLabel
                lea     UI_TimeBonusLabelAlt(pc),a6

UI_DrawScoreScreenLabels_DrawBonusLabel:  ; was: loc_11EE6
                bsr.w   Text_DrawString
                tst.b   (Ram_RoundMinutes).w
                bne.s   UI_DrawScoreScreenLabels_NoBonus
                lea     UI_PtsLabel(pc),a6
                bsr.w   Text_DrawString
                bra.s   UI_DrawScoreScreenLabels_Return

UI_DrawScoreScreenLabels_NoBonus:  ; was: loc_11EFA
                lea     UI_NoBonusLabel(pc),a6
                bsr.w   Text_DrawString

UI_DrawScoreScreenLabels_Return:  ; was: locret_11F02
                rts

UI_GameTimeLabel: dc.b    $C1, $4A  ; was: byte_11F04
UI_GameTimeText: dc.b    "GAME TIME",0
UI_MinSecLabel: dc.b    $C1, $64  ; was: byte_11F10
UI_MinSecText:  dc.b    "MIN.  SEC.",0
                dc.b    0
UI_TimeBonusLabel: dc.b    $C2, $4A  ; was: byte_11F1E
UI_TimeBonusText: dc.b    "TIME BONUS",0
                dc.b    0
UI_PtsLabel:    dc.b    $C2, $72  ; was: byte_11F2C
UI_PtsText:     dc.b    "PTS.",0
                dc.b    0
UI_NoBonusLabel: dc.b    $C2, $68  ; was: byte_11F34
UI_NoBonusText: dc.b    "NO BONUS",0
                dc.b    0
UI_RoundTimeLabel: dc.b    $C1, $48  ; was: byte_11F40
UI_RoundTimeText: dc.b    "ROUND TIME",0
                dc.b    0
UI_MinLabel:    dc.b    $C1, $62  ; was: byte_11F4E
UI_MinText:     dc.b    "MIN.",0
                dc.b    0
UI_SecLabel:    dc.b    $C1, $72  ; was: byte_11F56
UI_SecText:     dc.b    "SEC.",0
                dc.b    0
UI_TimeBonusLabelAlt: dc.b    $C2, $48  ; was: byte_11F5E
UI_TimeBonusText2: dc.b    "TIME BONUS",0
                dc.b    0
; Draws bonus round chicks collected and score
UI_DrawBonusRoundScore:
                tst.b   (Ram_BonusCaughtCount).w  ; was: sub_11F6C
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

UI_DrawBonusRoundScore_Return:  ; was: locret_11FAA
                rts

UI_PerfectBonusValue: dc.b    0, 1, 0, 0  ; was: byte_11FAC
; Initializes title screen: tiles, objects, music
