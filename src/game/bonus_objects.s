; Bonus-round objects.
; ROM $0164EC-$016DA9.

Obj_StarBonus:
                bset    #7,(a0)  ; was: sub_164EC
                bne.s   loc_1651A
                clr.b   5(a0)
                clr.l   $34(a0)
                clr.l   $2C(a0)
                addq.w  #7,$24(a0)
                move.l  #byte_165AC,8(a0)
                clr.w   6(a0)
                move.w  #$12C,$38(a0)
                bclr    #7,2(a0)

loc_1651A:
                bsr.w   Object_UpdatePosition
                bsr.w   Anim_UpdateFrame
                lea     (word_FFC440).w,a1
                bsr.w   Collision_CheckObjectPair
                tst.b   d0
                beq.s   loc_1657C
                move.l  a0,-(sp)
                move.b  #$98,d0
                bsr.w   Sound_PlayNoteIfActive
                movea.l (sp)+,a0
                lea     (unk_FFC0C0).w,a2
                moveq   #3,d0

loc_16540:
                tst.w   (a2)
                bne.s   loc_16574
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                move.w  d7,$30(a2)
                subq.w  #8,d6
                move.w  d6,$24(a2)
                moveq   #0,d7
                move.b  (byte_FFD27A).w,d7
                move.b  d7,$3A(a2)
                move.w  #$24,(a2)
                lsl.w   #2,d7
                move.l  dword_16588(pc,d7.w),d7
                move.l  d7,(dword_FFD262).w
                bsr.w   Score_AddAndCheck
                bra.s   loc_16582

loc_16574:
                lea     -$40(a2),a2
                dbf     d0,loc_16540

loc_1657C:
                subq.w  #1,$38(a0)
                bne.s   locret_16586

loc_16582:
                bsr.w   Sprite_ClearLinkTable

locret_16586:
                rts

dword_16588:    dc.l    $100, $200, $300, $400, $500, $800, $1000, $2000, $3000
byte_165AC:     dc.b    0, 1
                dc.w    byte_165B0-Sys_GameEntryPoint
byte_165B0:     dc.b    4, 5
                dc.w    word_1A8D8-Sys_GameEntryPoint
                dc.w    word_1A8E0-Sys_GameEntryPoint
                dc.w    word_1A8E8-Sys_GameEntryPoint
                dc.w    word_1A8F0-Sys_GameEntryPoint
; Bonus round cat object (outer position)
Obj_BonusCatOuter:
                bset    #7,(a0)  ; was: sub_165BA
                bne.s   loc_165F0
                move.w  #$140,$30(a0)
                bclr    #7,2(a0)
                tst.b   $16(a0)
                beq.s   loc_165DE
                move.w  #$C0,$30(a0)
                bset    #7,2(a0)

loc_165DE:
                move.w  #$150,$24(a0)
                move.l  #off_1669A,8(a0)
                clr.w   6(a0)

loc_165F0:
                tst.b   (byte_FFD27B).w
                bne.s   locret_165FE
                bsr.w   Object_UpdatePosition
                bsr.w   Anim_UpdateFrame

locret_165FE:
                rts

; Bonus round cat object (inner position)
Obj_BonusCatInner:
                bset    #7,(a0)  ; was: sub_16600
                bne.s   loc_16638
                move.w  #$130,$30(a0)
                bclr    #7,2(a0)
                tst.b   $16(a0)
                beq.s   loc_16624
                move.w  #$D0,$30(a0)
                bset    #7,2(a0)

loc_16624:
                move.w  #$150,$24(a0)
                move.l  #off_1669A,8(a0)
                move.w  #4,6(a0)

loc_16638:
                tst.b   (byte_FFD27B).w
                bne.s   locret_16646
                bsr.w   Object_UpdatePosition
                bsr.w   Anim_UpdateFrame

locret_16646:
                rts

; Bonus round held chick follows player
Obj_BonusHeldChick:
                lea     (unk_FFC580).w,a1  ; was: sub_16648
                move.l  dword_FFC5B0-unk_FFC580(a1),d7
                move.l  $24(a1),d6
                move.l  d7,$30(a0)
                move.l  d6,$24(a0)
                addi.w  #$A,$24(a0)
                tst.b   $39(a1)
                beq.s   loc_16674
                bclr    #7,2(a0)
                subq.w  #8,$30(a0)
                bra.s   loc_1667E

loc_16674:
                bset    #7,2(a0)
                addq.w  #8,$30(a0)

loc_1667E:
                bsr.w   Object_UpdatePosition
                move.l  #word_1AAD6,$C(a0)
                tst.l   $34(a1)
                beq.s   locret_16698
                move.l  #word_1AAE4,$C(a0)

locret_16698:
                rts

off_1669A:      dc.l    byte_166A2
                dc.l    byte_166B4
byte_166A2:     dc.b    8, 7
                dc.w    word_1AA96-Sys_GameEntryPoint
                dc.w    word_1AAA4-Sys_GameEntryPoint
                dc.w    word_1AAB2-Sys_GameEntryPoint
                dc.w    word_1AABA-Sys_GameEntryPoint
                dc.w    word_1AAC8-Sys_GameEntryPoint
                dc.w    word_1AABA-Sys_GameEntryPoint
                dc.w    word_1AAB2-Sys_GameEntryPoint
                dc.w    word_1AAA4-Sys_GameEntryPoint
byte_166B4:     dc.b    8, 7
                dc.w    word_1AA1A-Sys_GameEntryPoint
                dc.w    word_1AA2E-Sys_GameEntryPoint
                dc.w    word_1AA42-Sys_GameEntryPoint
                dc.w    word_1AA56-Sys_GameEntryPoint
                dc.w    word_1AA6A-Sys_GameEntryPoint
                dc.w    word_1AA56-Sys_GameEntryPoint
                dc.w    word_1AA42-Sys_GameEntryPoint
                dc.w    word_1AA2E-Sys_GameEntryPoint
; Bonus round thrown chick object
Obj_BonusChick:
                bset    #7,(a0)  ; was: sub_166C6
                bne.s   loc_166EC
                bset    #1,2(a0)
                move.l  #off_14E12,8(a0)
                movea.l (dword_FFD282).w,a1
                moveq   #0,d0
                move.b  $38(a0),d0
                lsl.w   #1,d0
                move.w  (a1,d0.w),$3A(a0)

loc_166EC:
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     loc_166FC(pc,d0.w)
                bsr.w   Anim_UpdateFrame
                rts

loc_166FC:
                bra.w   BonusChick_StateWait
                bra.w   BonusChick_StateFly
                bra.w   BonusChick_StateFall

; Bonus chick state: waiting to be thrown
BonusChick_StateWait:
                tst.w   $3A(a0)  ; was: sub_16708
                bne.s   loc_16778
                bset    #7,$3C(a0)
                bne.s   loc_16756
                bclr    #1,2(a0)
                move.w  #4,6(a0)
                move.w  #$150,$24(a0)
                move.w  #$80,$30(a0)
                move.l  #$8000,$34(a0)
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   loc_16756
                move.w  #$17F,$30(a0)
                move.l  #$FFFF8000,$34(a0)
                bset    #7,2(a0)

loc_16756:
                bsr.w   Object_UpdatePosition
                lea     (unk_FFC640).w,a1
                tst.b   $39(a0)
                bne.s   loc_16768
                lea     $40(a1),a1

loc_16768:
                bsr.w   Collision_CheckObjectPair
                tst.b   d0
                beq.s   locret_16776
                move.w  #4,$3C(a0)

locret_16776:
                rts

loc_16778:
                subq.w  #1,$3A(a0)
                bsr.w   Object_UpdatePosition
                rts

; Bonus chick state: flying through air
BonusChick_StateFly:
                bset    #7,$3C(a0)  ; was: sub_16782
                bne.s   loc_167B8
                movea.l (dword_FFD286).w,a1
                moveq   #0,d0
                move.b  $38(a0),d0
                lsl.w   #1,d0
                move.b  (a1,d0.w),d7
                move.b  1(a1,d0.w),d6
                ext.w   d7
                ext.l   d7
                ext.w   d6
                ext.l   d6
                moveq   #$C,d0
                lsl.l   d0,d7
                lsl.l   d0,d6
                move.l  d7,$34(a0)
                move.l  d6,$2C(a0)
                bsr.w   BonusChick_LoadTraj

loc_167B8:
                addi.l  #$1000,$2C(a0)
                bne.s   loc_167C8
                move.w  #8,$3C(a0)

loc_167C8:
                bsr.w   BonusChick_UpdateTraj
                bsr.w   Object_UpdatePosition
                bsr.w   Anim_UpdateFrame
                rts

; Bonus chick state: falling/bouncing
BonusChick_StateFall:
                bset    #7,$3C(a0)  ; was: sub_167D6
                bne.s   loc_16806
                clr.w   6(a0)
                move.l  $34(a0),d7
                bpl.s   loc_167F0
                neg.l   d7
                lsr.l   #1,d7
                neg.l   d7
                bra.s   loc_167F2

loc_167F0:
                lsr.l   #1,d7

loc_167F2:
                move.l  d7,$34(a0)
                cmpi.w  #$FFFF,$3A(a0)
                beq.s   loc_16806
                addq.b  #1,$3E(a0)
                bsr.w   BonusChick_LoadTraj

loc_16806:
                cmpi.l  #$18000,$2C(a0)
                bgt.s   loc_16818
                addi.l  #$400,$2C(a0)

loc_16818:
                bsr.w   BonusChick_UpdateTraj
                bsr.w   Object_UpdatePosition
                bsr.w   BonusChick_CheckCatch
                cmpi.w  #$180,$24(a0)
                bcs.s   loc_16834
                bsr.w   Object_ClearSlot
                subq.b  #1,(byte_FFD883).w

loc_16834:
                bsr.w   Anim_UpdateFrame
                tst.b   (byte_FFD883).w
                bne.s   locret_16852
                clr.w   (word_FFFF92).w
                move.b  #1,(byte_FFD281).w
                move.w  #4,(word_FFD2A6).w
                bsr.w   Bonus_CalcScore

locret_16852:
                rts

; Bonus chick trajectory curve update
BonusChick_UpdateTraj:
                move.w  $3A(a0),d0  ; was: sub_16854
                cmpi.w  #$FFFF,d0
                beq.s   locret_16890
                subq.w  #1,d0
                bne.s   loc_1686C
                addq.b  #1,$3E(a0)
                bsr.w   BonusChick_LoadTraj
                bra.s   BonusChick_UpdateTraj

loc_1686C:
                move.w  d0,$3A(a0)
                move.l  $34(a0),d7
                move.l  $1C(a0),d6
                bmi.s   loc_16884
                cmp.l   d6,d7
                bge.s   loc_16882
                add.l   $18(a0),d7

loc_16882:
                bra.s   loc_1688C

loc_16884:
                cmp.l   d6,d7
                ble.s   loc_1688C
                add.l   $18(a0),d7

loc_1688C:
                move.l  d7,$34(a0)

locret_16890:
                rts

; Bonus chick loads trajectory from tables
BonusChick_LoadTraj:
                moveq   #0,d0  ; was: sub_16892
                move.b  $38(a0),d0
                movea.l (dword_FFD28A).w,a1
                move.b  (a1,d0.w),d0
                lsl.w   #2,d0
                lea     off_16D18(pc),a1
                movea.l (a1,d0.w),a1
                moveq   #0,d0
                move.b  $3E(a0),d0
                lsl.w   #2,d0
                move.w  (a1,d0.w),$3A(a0)
                move.b  2(a1,d0.w),d7
                move.b  3(a1,d0.w),d6
                ext.w   d7
                ext.l   d7
                ext.w   d6
                ext.l   d6
                lsl.l   #8,d7
                moveq   #$C,d0
                lsl.l   d0,d6
                tst.b   $39(a0)
                beq.s   loc_168D8
                neg.l   d7
                neg.l   d6

loc_168D8:
                move.l  d7,$18(a0)
                move.l  d6,$1C(a0)
                rts

; Bonus chick collision catch detection
BonusChick_CheckCatch:
                lea     (word_FFC040).w,a1  ; was: sub_168E2
                bsr.w   Collision_CheckObjectPair
                tst.b   d0
                beq.s   locret_1691A
                move.l  a0,-(sp)
                move.b  #$90,d0
                bsr.w   Sound_PlayNoteIfActive
                movea.l (sp)+,a0
                bsr.w   Object_ClearSlot
                subq.b  #1,(byte_FFD883).w
                addq.b  #1,(byte_FFD28E).w
                moveq   #1,d0
                move.b  (byte_FFD28F).w,d1
                addi.b  #0,d1
                abcd    d0,d1
                move.b  d1,(byte_FFD28F).w
                bsr.w   Bonus_DrawCaughtCount

locret_1691A:
                rts

; Draws bonus round result text labels
Bonus_DrawResultLabels:
                tst.b   (byte_FFD28E).w  ; was: sub_1691C
                beq.s   loc_16944
                lea     byte_1694C(pc),a6
                bsr.w   Text_DrawString
                cmpi.b  #$14,(byte_FFD28E).w
                bne.s   locret_16942
                lea     byte_16964(pc),a6
                bsr.w   Text_DrawString
                lea     byte_16974(pc),a6
                bsr.w   Text_DrawString

locret_16942:
                rts

loc_16944:
                lea     byte_1697C(pc),a6
                bra.w   Text_DrawString

byte_1694C:     dc.b    $C2, $4E
a250PtsPts:     dc.b    "; 250 PTS.=      PTS.",0
byte_16964:     dc.b    $C3, $12
aPerfectBonus:  dc.b    "PERFECT BONUS",0
byte_16974:     dc.b    $C3, $A2
aPts_0:         dc.b    "PTS.",0
                dc.b    0
byte_1697C:     dc.b    $C3, $16
aNoBonus_0:     dc.b    "NO BONUS",0
                dc.b    0
; Calculates bonus round score total
Bonus_CalcScore:
                moveq   #0,d0  ; was: sub_16988
                move.b  (byte_FFD28E).w,d0
                beq.s   locret_169D2
                subq.w  #1,d0

loc_16992:
                move.l  #$250,(dword_FFD262).w
                lea     (byte_FFD266).w,a2
                lea     (word_FFD294).w,a1
                moveq   #3,d1
                move    #4,ccr

loc_169A8:
                abcd    -(a2),-(a1)
                dbf     d1,loc_169A8
                dbf     d0,loc_16992
                move.l  (dword_FFD290).w,d0
                move.l  d0,(dword_FFD262).w
                bsr.w   Score_AddAndCheck
                cmpi.b  #$14,(byte_FFD28E).w
                bne.s   locret_169D2
                move.l  #$10000,(dword_FFD262).w
                bsr.w   Score_AddAndCheck

locret_169D2:
                rts

; Draws caught chick count tiles in bonus round
Bonus_DrawCaughtCount:
                moveq   #0,d0  ; was: sub_169D4
                move.b  (byte_FFD28E).w,d0
                subq.w  #1,d0
                move.l  #$414C0003,(VDP_CTRL).l

loc_169E6:
                move.w  #$E351,(VDP_DATA).l
                dbf     d0,loc_169E6
                rts

off_169F4:      dc.l    word_16A24
                dc.l    word_16A24
                dc.l    word_16A24
                dc.l    word_16A4C
                dc.l    word_16A74
                dc.l    word_16A74
                dc.l    word_16A74
                dc.l    word_16A74
                dc.l    word_16A74
                dc.l    word_16A74
                dc.l    word_16A74
                dc.l    word_16A74
word_16A24:     dc.w    0, $F, $1E, $2D, $6E, $7D, $8C, $9B, $DC, $EB
                dc.w    $FA, $109, $14A, $159, $168, $177, $1B8, $1C7, $1D6, $1E5
word_16A4C:     dc.w    $1E, $2D, $3C, $4B, 0, $F, $1E, $2D, $FA, $109
                dc.w    $118, $127, $DC, $EB, $FA, $109, $1B8, $1C7, $1D6, $1E5
word_16A74:     dc.w    0, $F, $1E, $2D, $64, $73, $82, $91, $C8, $D7
                dc.w    $E6, $F5, $12C, $13B, $14A, $159, $190, $19F, $1AE, $1BD
off_16A9C:      dc.l    word_16ACC
                dc.l    word_16AF4
                dc.l    word_16B1C
                dc.l    word_16B44
                dc.l    word_16B6C
                dc.l    word_16B94
                dc.l    word_16BBC
                dc.l    word_16B94
                dc.l    word_16ACC
                dc.l    word_16BE4
                dc.l    word_16C0C
                dc.l    word_16B94
word_16ACC:     dc.w    $EB4, $EB4, $EB4, $EB4, $F2B4, $F2B4, $F2B4, $F2B4, $EB4, $EB4
                dc.w    $EB4, $EB4, $F2B4, $F2B4, $F2B4, $F2B4, $EB4, $EB4, $EB4, $EB4
word_16AF4:     dc.w    $EB4, $CB4, $AB4, $8B4, $F2B4, $F4B4, $F6B4, $F8B4, $EB4, $CB4
                dc.w    $AB4, $8B4, $F2B4, $F4B4, $F6B4, $F8B4, $EB4, $CB4, $AB4, $8B4
word_16B1C:     dc.w    $EB4, $EB8, $EBC, $EC0, $F2B4, $F2B8, $F2BC, $F2C0, $EB4, $EB8
                dc.w    $EBC, $EC0, $F2B4, $F2B8, $F2BC, $F2C0, $EB4, $EB8, $EBC, $EC0
word_16B44:     dc.w    $AB4, $AB4, $AB4, $AB4, $F6B4, $F6B4, $F6B4, $F6B4, $AB4, $AB4
                dc.w    $AB4, $AB4, $F6B4, $F6B4, $F6B4, $F6B4, $5B4, $8B4, $BB4, $EB4
word_16B6C:     dc.w    $22B4, $22B4, $22B4, $22B4, $DEB4, $DEB4, $DEB4, $DEB4, $22B4, $22B4
                dc.w    $22B4, $22B4, $DEB4, $DEB4, $DEB4, $DEB4, $22B4, $22B4, $22B4, $22B4
word_16B94:     dc.w    $9B4, $9B4, $9B4, $9B4, $F7B4, $F7B4, $F7B4, $F7B4, $9B4, $9B4
                dc.w    $9B4, $9B4, $F7B4, $F7B4, $F7B4, $F7B4, $9B4, $9B4, $9B4, $9B4
word_16BBC:     dc.w    $12B4, $12B4, $12B4, $12B4, $EEB4, $EEB4, $EEB4, $EEB4, $12B4, $12B4
                dc.w    $12B4, $12B4, $EEB4, $EEB4, $EEB4, $EEB4, $12B4, $12B4, $12B4, $12B4
word_16BE4:     dc.w    $E0B4, $E0B4, $E0B4, $E0B4, $20B4, $20B4, $20B4, $20B4, $E0B4, $E0B4
                dc.w    $E0B4, $E0B4, $20B4, $20B4, $20B4, $20B4, $E0B4, $E0B4, $E0B4, $E0B4
word_16C0C:     dc.w    $40B4, $40B4, $40B4, $40B4, $C0B4, $C0B4, $C0B4, $C0B4, $40B4, $40B4
                dc.w    $40B4, $40B4, $C0B4, $C0B4, $C0B4, $C0B4, $40B4, $40B4, $40B4, $40B4
off_16C34:      dc.l    word_16C64
                dc.l    word_16C64
                dc.l    word_16C64
                dc.l    word_16C64
                dc.l    word_16C78
                dc.l    word_16C8C
                dc.l    word_16CA0
                dc.l    word_16CB4
                dc.l    word_16CC8
                dc.l    word_16CDC
                dc.l    word_16CF0
                dc.l    word_16D04
word_16C64:     dc.w    0, 0, 0, 0, 0, 0, 0, 0, 0, 0
word_16C78:     dc.w    $101, $101, $101, $101, $101, $101, $101, $101, $101, $101
word_16C8C:     dc.w    $202, $202, $202, $202, $202, $202, $202, $202, $202, $202
word_16CA0:     dc.w    $303, $303, $303, $303, $303, $303, $303, $303, $303, $303
word_16CB4:     dc.w    $404, $404, $404, $404, $404, $404, $404, $404, $404, $404
word_16CC8:     dc.w    $505, $505, $505, $505, $505, $505, $505, $505, $505, $505
word_16CDC:     dc.w    $606, $606, $606, $606, $606, $606, $606, $606, $606, $606
word_16CF0:     dc.w    $707, $707, $707, $707, $707, $707, $707, $707, $707, $707
word_16D04:     dc.w    $808, $808, $808, $808, $808, $808, $808, $808, $808, $808
off_16D18:      dc.l    word_16D3C
                dc.l    word_16D3E
                dc.l    word_16D48
                dc.l    word_16D5A
                dc.l    word_16D68
                dc.l    word_16D7A
                dc.l    word_16D8C
                dc.l    word_16D92
                dc.l    word_16DA0
word_16D3C:     dc.w    $FFFF
word_16D3E:     dc.w    $12C, $F4E8, $12C, $310, $FFFF
word_16D48:     dc.w    $12C, $FEF8, $14, $C10, $40, $FAF0, $12C, $610, $FFFF
word_16D5A:     dc.w    $12C, 0, $58, 0, $12C, $C0DE, $FFFF
word_16D68:     dc.w    $12C, $FEF8, $30, $1220, $3A, $EEE0, $12C, $620, $FFFF
word_16D7A:     dc.w    $12C, 0, $32, 0, $18, $E4E0, $12C, $1C0C, $FFFF
word_16D8C:     dc.w    $12C, $D1C, $FFFF
word_16D92:     dc.w    $12C, $F2E0, $28, $FCE0, $12C, $320, $FFFF
word_16DA0:     dc.w    $12C, $FEF8, $12C, $320, $FFFF
; Game over text display object
