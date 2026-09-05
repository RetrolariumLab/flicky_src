; HUD elements, animations, score and label drawing.
; ROM $011BC2-$011FAF.

UI_DrawHUDElements:
                moveq   #4,d0  ; was: sub_11BC2
                moveq   #5,d3

loc_11BC6:
                move.w  word_11BDC(pc,d0.w),d1
                move.w  word_11BDE(pc,d0.w),d4
                lsr.w   #1,d0
                moveq   #$FFFFFFFF,d2
                move.w  word_11BF8(pc,d0.w),d2
                lsl.w   #1,d0
                movea.l d2,a0
                bra.s   loc_11C06
word_11BDC:     dc.w    0
word_11BDE:     dc.w    0, 0, 0, 1, 1, 0, 2, $13, 3, 7, 4, 7, 5
word_11BF8:     dc.w    0, $D82E, $D830, $D834, $D836, $D85E, $D86E

loc_11C06:
                tst.b   2(a0)
                beq.s   loc_11C24
                moveq   #0,d7
                moveq   #0,d6
                move.b  0.w(a0),d7
                move.b  1(a0),d6
                movem.w d0-d4/a0,-(sp)
                bsr.w   Level_DrawBackgroundObject
                movem.w (sp)+,d0-d4/a0

loc_11C24:
                addq.l  #4,a0
                dbf     d1,loc_11C06
                addq.w  #4,d0
                dbf     d3,loc_11BC6
                tst.b   (byte_FFD830).w
                beq.s   locret_11C3A
                bsr.w   Level_DrawEntryArrow

locret_11C3A:
                rts

; Animates player entry arrow indicator
UI_AnimateEntryArrow:
                lea     (unk_FFD258).w,a0  ; was: sub_11C3C
                lea     byte_11C74(pc),a1
                btst    #7,(IO_PCBVER+1).l
                beq.s   loc_11C52
                lea     byte_11C86(pc),a1

loc_11C52:
                moveq   #0,d7
                moveq   #0,d6
                moveq   #0,d5
                move.b  (byte_FFD82E).w,d7
                move.b  (byte_FFD82F).w,d6
                subq.b  #1,d6
                move.w  #$E000,d5
                bsr.w   Gfx_TilemapCoordToAddr
                moveq   #2,d7
                moveq   #0,d6
                bsr.w   Anim_ProcessTimer
                rts

byte_11C74:     dc.b    4
                dc.b    4
                dc.l    word_1A262
                dc.l    word_1A26E
                dc.l    word_1A268
                dc.l    word_1A26E
byte_11C86:     dc.b    4
                dc.b    4
                dc.l    word_11C98
                dc.l    word_11CA4
                dc.l    word_11C9E
                dc.l    word_11CA4
word_11C98:     dc.w    $693, $694, $695
word_11C9E:     dc.w    $696, $697, $698
word_11CA4:     dc.w    $699, $69A, $69B
; Updates and animates timer display
UI_AnimateTimer:
                lea     byte_11CB8(pc),a1  ; was: sub_11CAA
                bsr.w   UI_PlayAnimation
                bsr.w   Timer_IncrementTime
                rts

byte_11CB8:     dc.b    4
                dc.b    $F
                dc.l    word_1A490
                dc.l    word_1A46C
                dc.l    word_1A47E
                dc.l    word_1A490
; Plays cat rescue countdown animation
UI_AnimateCatCountdown:
                lea     byte_11CD4(pc),a1  ; was: sub_11CCA
                jmp     UI_PlayAnimation

byte_11CD4:     dc.b    4
                dc.b    2
                dc.l    word_1A274
                dc.l    word_1A490
                dc.l    word_1A47E
                dc.l    word_1A46C
; Plays reverse cat countdown animation
UI_AnimateCatCountReverse:
                lea     byte_11CF0(pc),a1  ; was: sub_11CE6
                jmp     UI_PlayAnimation

byte_11CF0:     dc.b    5
                dc.b    2
                dc.l    word_11D06
                dc.l    word_1A46C
                dc.l    word_1A47E
                dc.l    word_1A490
                dc.l    word_1A4A2
word_11D06:     dc.w    0, 0, 0, 0, 0, 0, 0, 0, 0
; Plays bonus animation on score screen
UI_AnimateBonus:
                lea     byte_11D22(pc),a1  ; was: sub_11D18
                jmp     UI_PlayAnimation

byte_11D22:     dc.b    5
                dc.b    1
                dc.l    word_1A274
                dc.l    word_1A4A2
                dc.l    word_1A490
                dc.l    word_1A47E
                dc.l    word_1A46C
; Generic animation loop until completion flag
UI_PlayAnimation:
                move.b  #1,(byte_FFD27B).w  ; was: sub_11D38
                lea     (unk_FFD254).w,a0
                clr.l   (a0)
                moveq   #0,d7
                moveq   #0,d6
                moveq   #0,d5
                move.b  (byte_FFD82E).w,d7
                move.b  (byte_FFD82F).w,d6
                move.w  #$C000,d5
                bsr.w   Gfx_TilemapCoordToAddr
                moveq   #2,d7
                moveq   #2,d6

loc_11D5E:
                movem.l d5-d7/a0-a4,-(sp)
                bsr.w   Anim_ProcessTimer
                tst.b   2(a0)
                bne.s   loc_11D7E
                bsr.w   Object_UpdateAll
                bsr.w   Timer_IncrementTime
                jsr     unk_FFFB6C
                movem.l (sp)+,d5-d7/a0-a4
                bra.s   loc_11D5E

loc_11D7E:
                clr.b   (byte_FFD27B).w
                movem.l (sp)+,d5-d7/a0-a4
                rts

; Draws life indicator icons based on lives count
UI_DrawLives:
                moveq   #0,d0  ; was: sub_11D88
                move.b  (byte_FFD882).w,d0
                beq.s   locret_11DC0
                subq.w  #1,d0
                beq.s   locret_11DC0
                subq.w  #1,d0
                move.l  #$46840003,(VDP_CTRL).l
                btst    #6,(IO_PCBVER+1).l
                beq.s   loc_11DB4
                move.l  #$47440003,(VDP_CTRL).l

loc_11DB4:
                move.w  #$4350,(VDP_DATA).l
                dbf     d0,loc_11DB4

locret_11DC0:
                rts

; Draws current score BCD value
UI_DrawScore:
                lea     (dword_FFD87E).w,a6  ; was: sub_11DC2
                moveq   #0,d5
                move.w  #$C04A,d5
                moveq   #3,d0
                bsr.w   Text_DrawBCDNumber
                rts

; Draws high score BCD value
UI_DrawHighScore:
                lea     (dword_FFCC00).w,a6  ; was: sub_11DD4
                moveq   #0,d5
                move.w  #$C068,d5
                moveq   #3,d0
                bsr.w   Text_DrawBCDNumber
                rts

; Draws current round number with region check
UI_DrawRoundNumber:
                lea     (word_FFD82C).w,a6  ; was: sub_11DE6
                moveq   #0,d5
                move.w  #$C6BA,d5
                btst    #6,(IO_PCBVER+1).l
                beq.s   loc_11DFE
                move.w  #$C77A,d5

loc_11DFE:
                moveq   #0,d0
                bsr.w   Text_DrawBCDNumber
                rts

; Draws RD label and calls score/hiscore labels
UI_DrawScoreLabels:
                lea     byte_11E46(pc),a6  ; was: sub_11E06
                btst    #6,(IO_PCBVER+1).l
                beq.s   loc_11E18
                lea     byte_11E4C(pc),a6

loc_11E18:
                bsr.w   Text_DrawString

; Draws 1UP and HI label graphics
UI_Draw1UPAndHILabels:
                lea     (word_1A4CA).l,a6  ; was: sub_11E1C
                moveq   #1,d7
                moveq   #0,d6
                moveq   #0,d5
                move.w  #$C048,d5
                bsr.w   Gfx_DrawTilemapStart
                lea     (word_1A4D2).l,a6
                moveq   #2,d7
                moveq   #0,d6
                moveq   #0,d5
                move.w  #$C064,d5
                bsr.w   Gfx_DrawTilemapStart
                rts

byte_11E46:     dc.b    $C6, $B4
aRd:            dc.b    "RD.",0
byte_11E4C:     dc.b    $C7, $74
aRd_0:          dc.b    "RD.",0
; Draws detailed score breakdown on results
UI_DrawScoreBreakdown:
                lea     (byte_FFD266).w,a6  ; was: sub_11E52
                moveq   #0,d5
                move.w  #$C160,d5
                btst    #7,(IO_PCBVER+1).l
                beq.s   loc_11E68
                subq.w  #4,d5

loc_11E68:
                moveq   #0,d0
                bsr.w   Text_DrawBCDNumber
                lea     (byte_FFD267).w,a6
                moveq   #0,d5
                move.w  #$C16C,d5
                moveq   #0,d0
                bsr.w   Text_DrawBCDNumber
                tst.b   (byte_FFD266).w
                bne.s   locret_11E94
                lea     (dword_FFD268).w,a6
                moveq   #0,d5
                move.w  #$C260,d5
                moveq   #3,d0
                bsr.w   Text_DrawBCDNumber

locret_11E94:
                rts

; Draws score screen text labels with region check
UI_DrawScoreScreenLabels:
                lea     byte_11F04(pc),a6  ; was: sub_11E96
                btst    #7,(IO_PCBVER+1).l
                beq.s   loc_11EA8
                lea     byte_11F40(pc),a6

loc_11EA8:
                bsr.w   Text_DrawString
                lea     byte_11F10(pc),a6
                btst    #7,(IO_PCBVER+1).l
                beq.s   loc_11EBE
                lea     byte_11F4E(pc),a6

loc_11EBE:
                bsr.w   Text_DrawString
                btst    #7,(IO_PCBVER+1).l
                beq.s   loc_11ED4
                lea     byte_11F56(pc),a6
                bsr.w   Text_DrawString

loc_11ED4:
                lea     byte_11F1E(pc),a6
                btst    #7,(IO_PCBVER+1).l
                beq.s   loc_11EE6
                lea     byte_11F5E(pc),a6

loc_11EE6:
                bsr.w   Text_DrawString
                tst.b   (byte_FFD266).w
                bne.s   loc_11EFA
                lea     byte_11F2C(pc),a6
                bsr.w   Text_DrawString
                bra.s   locret_11F02

loc_11EFA:
                lea     byte_11F34(pc),a6
                bsr.w   Text_DrawString

locret_11F02:
                rts

byte_11F04:     dc.b    $C1, $4A
aGameTime:      dc.b    "GAME TIME",0
byte_11F10:     dc.b    $C1, $64
aMinSec:        dc.b    "MIN.  SEC.",0
                dc.b    0
byte_11F1E:     dc.b    $C2, $4A
aTimeBonus:     dc.b    "TIME BONUS",0
                dc.b    0
byte_11F2C:     dc.b    $C2, $72
aPts:           dc.b    "PTS.",0
                dc.b    0
byte_11F34:     dc.b    $C2, $68
aNoBonus:       dc.b    "NO BONUS",0
                dc.b    0
byte_11F40:     dc.b    $C1, $48
aRoundTime:     dc.b    "ROUND TIME",0
                dc.b    0
byte_11F4E:     dc.b    $C1, $62
aMin:           dc.b    "MIN.",0
                dc.b    0
byte_11F56:     dc.b    $C1, $72
aSec:           dc.b    "SEC.",0
                dc.b    0
byte_11F5E:     dc.b    $C2, $48
aTimeBonus_0:   dc.b    "TIME BONUS",0
                dc.b    0
; Draws bonus round chicks collected and score
UI_DrawBonusRoundScore:
                tst.b   (byte_FFD28E).w  ; was: sub_11F6C
                beq.s   locret_11FAA
                lea     (byte_FFD28F).w,a6
                moveq   #0,d5
                move.w  #$C248,d5
                moveq   #0,d0
                bsr.w   Text_DrawBCDNumber
                lea     ((dword_FFD290+2)).w,a6
                moveq   #0,d5
                move.w  #$C266,d5
                moveq   #1,d0
                bsr.w   Text_DrawBCDNumber
                cmpi.b  #$14,(byte_FFD28E).w
                bne.s   locret_11FAA
                lea     byte_11FAC(pc),a6
                moveq   #0,d5
                move.w  #$C390,d5
                moveq   #3,d0
                bsr.w   Text_DrawBCDNumber

locret_11FAA:
                rts

byte_11FAC:     dc.b    0, 1, 0, 0
; Initializes title screen: tiles, objects, music
