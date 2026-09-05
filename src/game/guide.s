; Guide screen.
; ROM $01228E-$0125BD.

Guide_Init:
                moveq   #7,d1  ; was: sub_1228E

loc_12290:
                jsr     unk_FFFB6C
                dbf     d1,loc_12290
                bsr.w Sys_InitTitleScreen
                lea     (word_16DE8).l,a5
                jsr     unk_FFFBBA
                clr.l   (dword_FFD87E).w
                clr.b   (byte_FFD887).w
                bsr.w Level_LoadTileset
                bsr.w Level_LoadPalette
                bsr.w Guide_DrawText
                lea     (word_FFC000).w,a0
                moveq   #0,d1
                moveq   #$13,d0

loc_122C2:
                move.w  #$4C,(a0)
                move.w  d1,$38(a0)
                lea     $40(a0),a0
                addq.w  #1,d1
                dbf     d0,loc_122C2
                bsr.w Object_UpdateAll
                jsr     unk_FFFB6C
                jmp     unk_FFFB6C

; Guide screen update: handles input and fade
Guide_Update:
                btst    #7,(word_FFFF8E+1).w  ; was: sub_122E0
                beq.s   loc_12306
                move.w  #$18,(word_FFFFC0).w
                move.b  (word_FFFF8E).w,d0
                bclr    #7,d0
                cmpi.b  #$61,d0
                bne.s   loc_12302
                move.w  #$10,(word_FFFFC0).w

loc_12302:
                bsr.w Gfx_FadeInPalette

loc_12306:
                jmp     unk_FFFB6C

; Draws guide screen text and demo level graphics
Guide_DrawText:
                moveq   #5,d0  ; was: sub_1230A
                lea     off_12384(pc),a0
                btst    #7,(IO_PCBVER+1).l
                beq.s   loc_1231E
                lea     off_123F0(pc),a0

loc_1231E:
                movea.l (a0)+,a6
                bsr.w Text_DrawDoubleHeight
                dbf     d0,loc_1231E
                lea     (byte_FFD82E).w,a0
                moveq   #$E,d7
                btst    #7,(IO_PCBVER+1).l
                beq.s   loc_1233A
                moveq   #$F,d7

loc_1233A:
                moveq   #6,d6
                moveq   #0,d4
                move.b  d7,(a0)
                move.b  d6,1(a0)
                bsr.w Level_DrawBackgroundObject
                bsr.w Level_DrawEntryArrow
                moveq   #5,d7
                moveq   #$17,d6
                moveq   #0,d4
                move.b  d7,(a0)
                move.b  d6,1(a0)
                bsr.w Level_DrawBackgroundObject
                bsr.w Level_DrawEntryArrow
                bsr.w Level_DrawLowerGround
                bsr.w Level_DrawUpperGround
                lea     (VDP_DATA).l,a0
                move.l  #$648A0003,(VDP_CTRL).l
                moveq   #$15,d0

loc_1237A:
                move.w  #$220D,(a0)
                dbf     d0,loc_1237A
                rts

off_12384:      dc.l byte_1239C
                dc.l byte_123A4
                dc.l byte_123AE
                dc.l byte_123B2
                dc.l byte_123C2
                dc.l byte_123DA
byte_1239C:     dc.b $C0, $DA
                dc.b $60, $6E, $A7, $65, $6F, 0
byte_123A4:     dc.b $C2, 8
                dc.b $8C, $6E, $62, $6A, $6B, $72, 0, 0
byte_123AE:     dc.b $C2, $18
                dc.b $8C, 0
byte_123B2:     dc.b $C2, $24
                dc.b $7E, $A4, $71, $89, $72, $61, $93, $72
                dc.b $67, $A1, $6A, $61, $12, 0
byte_123C2:     dc.b $C3, 6
                dc.b $FA, $BF, $DD, $8C, $64, $6C, $73, $11
                dc.b $ED, $E4, $DD, $FD, $20, $26, $20, $BB
                dc.b $E6, $E3, $C3, $12, 0, 0
byte_123DA:     dc.b $C5, $94
                dc.b $7E, $73, $81, $72, $71, $89, $72, $65
                dc.b $63, $88, $73, $11, $69, $62, $73, $67
                dc.b $72, $8D, $21, 0
off_123F0:      dc.l byte_12408
                dc.l byte_1241A
                dc.l byte_12422
                dc.l byte_1242A
                dc.l byte_1243A
                dc.l byte_1245C
byte_12408:     dc.b $C0, $D2
aMakeYourMove:  dc.b "MAKE YOUR MOVE",0
                dc.b 0
byte_1241A:     dc.b $C2, 2
aHelp:          dc.b "HELP",0
                dc.b 0
byte_12422:     dc.b $C2, $E
aGuide:         dc.b "GUIDE",0
byte_1242A:     dc.b $C2, $26
aToTheDoor:     dc.b "TO THE DOOR!",0
                dc.b 0
byte_1243A:     dc.b $C2, $C2
aPressButtonToJ:dc.b "PRESS BUTTON TO JUMP AND SHOOT",0
                dc.b 0
byte_1245C:     dc.b $C5, $92
aRackUpASuperSc:dc.b "RACK UP A SUPER SCORE!",0
                dc.b 0
; Guide screen character objects (Flicky, cats)
Obj_GuideCharacter:
                bset    #7,(a0)  ; was: sub_12476
                bne.s   locret_124B8
                move.w  $38(a0),d0
                bclr    #7,2(a0)
                move.b  byte_124BA(pc,d0.w),d1
                beq.s   loc_12492
                bset    #7,2(a0)

loc_12492:
                lsl.w   #2,d0
                move.l  off_124CE(pc,d0.w),$C(a0)
                lea     word_1251E(pc),a1
                btst    #7,(IO_PCBVER+1).l
                beq.s   loc_124AC
                lea     word_1256E(pc),a1

loc_124AC:
                move.w  (a1,d0.w),$20(a0)
                move.w  2(a1,d0.w),$24(a0)

locret_124B8:
                rts

byte_124BA:     dc.b 0, 0, 1, 0, 1, 1, 1, 0, 0, 0
                dc.b 0, 0, 0, 1, 1, 1, 1, 1, 1, 1
off_124CE:      dc.l word_1A848
                dc.l word_1A7F0
                dc.l word_1A800
                dc.l word_1A7D8
                dc.l word_1A7C8
                dc.l word_1A7D8
                dc.l word_1A7F0
                dc.l word_1A830
                dc.l word_1A898
                dc.l word_1A7B8
                dc.l word_1A8D0
                dc.l word_1A528
                dc.l word_1A99A
                dc.l byte_1A8A8
                dc.l word_1A7E8
                dc.l word_1A848
                dc.l word_1A850
                dc.l word_1A7F8
                dc.l word_1A7F0
                dc.l word_1A858
word_1251E:     dc.w $B4, $A0, $C0, $A0, $CC, $A0, $D8, $A0, $120, $A0
                dc.w $12C, $A0, $138, $A0, $144, $A0, $98, $C8, $D8, $C8
                dc.w $D0, $100, $118, $100, $118, $110, $C0, $150, $C8, $150
                dc.w $D0, $150, $D8, $150, $E0, $150, $E8, $150, $F0, $150
word_1256E:     dc.w $94, $A0, $A0, $A0, $AC, $A0, $B8, $A0, $148, $A0
                dc.w $154, $A0, $160, $A0, $16C, $A0, $B0, $C8, $E8, $C8
                dc.w $D0, $100, $118, $100, $118, $110, $C0, $150, $C8, $150
                dc.w $D0, $150, $D8, $150, $E0, $150, $E8, $150, $F0, $150
; Round select screen initialization
