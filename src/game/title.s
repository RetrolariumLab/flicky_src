; Title screen and its objects.
; ROM $011FB0-$01228D.

Title_Init:
                bsr.w   Sys_InitTitleScreen  ; was: sub_11FB0
                move.w  #$740,d0
                jsr     unk_FFFB8A
                lea     (FlickyLogoTiles).l,a0
                jsr     j_Nem_Decomp
                clr.b   (byte_FFD88E).w
                bsr.w   loc_10126
                lea     (word_16DE8).l,a5
                jsr     unk_FFFBBA
                lea     word_1210C(pc),a0
                lea     (unk_FFF840).w,a1
                moveq   #3,d0

loc_11FE2:
                move.l  (a0)+,(a1)+
                dbf     d0,loc_11FE2
                moveq   #5,d0
                lea     off_12086(pc),a0
                btst    #7,(IO_PCBVER+1).l
                beq.s   loc_11FFC
                lea     off_1209E(pc),a0

loc_11FFC:
                movea.l (a0)+,a6
                bsr.w   Text_DrawString
                dbf     d0,loc_11FFC
                move.b  #3,(byte_FFD882).w
                move.w  #$101,(word_FFD82C).w
                move.b  #1,(byte_FFD88F).w
                lea     (word_FFC000).w,a0
                moveq   #0,d1
                moveq   #3,d0

loc_12020:
                move.w  #$40,(a0)
                move.w  d1,$38(a0)
                lea     $40(a0),a0
                addq.w  #1,d1
                dbf     d0,loc_12020
                move.w  #$44,(a0)
                lea     (unk_FFC140).w,a0
                moveq   #0,d1
                moveq   #5,d0

loc_1203E:
                move.w  #$48,(a0)
                move.w  d1,$38(a0)
                lea     $40(a0),a0
                addq.w  #1,d1
                dbf     d0,loc_1203E
                btst    #7,(IO_PCBVER+1).l
                beq.s   loc_12062
                lea     byte_1211C(pc),a6
                bsr.w   Text_DrawDoubleHeight

loc_12062:
                bsr.w   UI_Draw1UPAndHILabels
                bsr.w   UI_DrawScore
                bsr.w   UI_DrawHighScore
                bsr.w   Object_UpdateAll
                clr.w   (word_FFFF92).w
                move.b  #$85,d0
                jsr     unk_FFFB66
                jsr     unk_FFFB6C
                jmp     unk_FFFB6C

off_12086:      dc.l    byte_120B6
                dc.l    byte_120BE
                dc.l    byte_120C8
                dc.l    byte_120D2
                dc.l    byte_120DE
                dc.l    byte_120E6
off_1209E:      dc.l    byte_120B6
                dc.l    byte_120BE
                dc.l    byte_120F4
                dc.l    byte_120FC
                dc.l    byte_12104
                dc.l    byte_120E6
byte_120B6:     dc.b    $C2, $9C
aCast:          dc.b    "CAST",0
                dc.b    0
byte_120BE:     dc.b    $C3, $10
aFlicky:        dc.b    "FLICKY",0
                dc.b    0
byte_120C8:     dc.b    $C3, $28
aPiopio:        dc.b    "PIOPIO",0
                dc.b    0
byte_120D2:     dc.b    $C3, $D0
aNyannyan:      dc.b    "NYANNYAN",0
                dc.b    0
byte_120DE:     dc.b    $C3, $E8
aChoro:         dc.b    "CHORO",0
byte_120E6:     dc.b    $C6, $54
aSega1991:      dc.b    $27," SEGA 1991",0
byte_120F4:     dc.b    $C3, $28
aChirp:         dc.b    "CHIRP",0
byte_120FC:     dc.b    $C3, $D0
aTiger:         dc.b    "TIGER",0
byte_12104:     dc.b    $C3, $E8
aIggy:          dc.b    "IGGY",0
                dc.b    0
word_1210C:     binclude "data/palettes/title-logo.bin"
byte_1211C:     dc.b    $C0, $EE
aTm:            dc.b    "TM",0
                dc.b    0
; Title screen update: handles start button and fade
Title_Update:
                btst    #7,(word_FFFF8E+1).w  ; was: sub_12122
                beq.s   loc_12146
                bsr.w   Gfx_FadeInPalette
                move.b  #$E0,d0
                bsr.w   Sound_PlayNote
                move.b  #1,(byte_FFD88E).w
                bsr.w   loc_10126
                move.w  #8,(word_FFFFC0).w

loc_12146:
                cmpi.w  #$400,(word_FFFF92).w
                bcs.s   loc_1216A
                bsr.w   Gfx_FadeInPalette
                move.b  #$E0,d0
                bsr.w   Sound_PlayNote
                move.b  #1,(byte_FFD88E).w
                bsr.w   loc_10126
                move.w  #$38,(word_FFFFC0).w

loc_1216A:
                bsr.w   Object_UpdateAll
                jmp     unk_FFFB6C

; Title screen Flicky bird animation object
Obj_TitleBird:
                bset    #7,(a0)  ; was: sub_12172
                bne.s   loc_1219E
                bset    #7,2(a0)
                move.w  $38(a0),d0
                lsl.w   #1,d0
                move.w  word_121B4(pc,d0.w),6(a0)
                lsl.w   #1,d0
                move.l  off_121A4(pc,d0.w),8(a0)
                move.w  word_121BC(pc,d0.w),$20(a0)
                move.w  word_121BE(pc,d0.w),$24(a0)

loc_1219E:
                bsr.w   Anim_UpdateFrame
                rts

off_121A4:      dc.l    off_144AC
                dc.l    off_14E12
                dc.l    off_154AE
                dc.l    off_162BC
word_121B4:     dc.w    0, 4, 4, 0
word_121BC:     dc.w    $B0
word_121BE:     dc.w    $F0, $110, $EC, $B0, $108, $110, $100
; Title screen cursor with blink state machine
Obj_TitleCursor:
                bset    #7,(a0)  ; was: sub_121CC
                bne.s   loc_121E6
                move.l  #word_1ACDC,$C(a0)
                move.w  #$F0,$20(a0)
                move.w  #$120,$24(a0)

loc_121E6:
                move.w  $3C(a0),d0
                andi.w  #$7C,d0
                jsr     loc_121F4(pc,d0.w)
                rts

loc_121F4:
                bra.w   Obj_CursorWait
                bra.w   Obj_CursorBlink

; Cursor wait state: timer before showing
Obj_CursorWait:
                bset    #7,$3C(a0)  ; was: sub_121FC
                bne.s   loc_12210
                bclr    #1,2(a0)
                move.w  #$3C,$3A(a0)

loc_12210:
                subq.w  #1,$3A(a0)
                bne.s   locret_1221C
                move.w  #4,$3C(a0)

locret_1221C:
                rts

; Cursor blink state: show then hide cycle
Obj_CursorBlink:
                bset    #7,$3C(a0)  ; was: sub_1221E
                bne.s   loc_12232
                bset    #1,2(a0)
                move.w  #$14,$3A(a0)

loc_12232:
                subq.w  #1,$3A(a0)
                bne.s   locret_1223C
                clr.w   $3C(a0)

locret_1223C:
                rts

; Title screen static sprite objects
Obj_TitleStatic:
                bset    #7,(a0)  ; was: sub_1223E
                bne.s   locret_1225C
                move.w  $38(a0),d0
                lsl.w   #2,d0
                move.l  off_1225E(pc,d0.w),$C(a0)
                move.w  word_12276(pc,d0.w),$20(a0)
                move.w  word_12278(pc,d0.w),$24(a0)

locret_1225C:
                rts

off_1225E:      dc.l    word_1AD52
                dc.l    word_1AD5A
                dc.l    word_1AD62
                dc.l    word_1AD6A
                dc.l    word_1AD72
                dc.l    word_1AD7A
word_12276:     dc.w    $D0
word_12278:     dc.w    $C0, $E5, $C0, $F7, $C0, $107, $C0, $11C, $C0, $133, $C0
; Guide/How-to-play screen initialization
