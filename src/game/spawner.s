; Enemy spawner and score popups.
; ROM $016312-$0164EB.

Obj_Spawner:
                bset    #7,(a0)  ; was: sub_16312
                bne.s   loc_1633E
                move.b  $3E(a0),d7
                move.b  $3F(a0),d6
                bsr.w   Math_GridToScreen
                addq.w  #8,d7
                addi.w  #$10,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)
                tst.b   (byte_FFD26C).w
                beq.s   loc_1633E
                move.w  (word_FFD294).w,$38(a0)

loc_1633E:
                move.l  #off_163E0,8(a0)
                tst.b   (byte_FFD24F).w
                bne.s   locret_1635C
                tst.b   (byte_FFD27B).w
                bne.s   locret_1635C
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     loc_1635E(pc,d0.w)

locret_1635C:
                rts

loc_1635E:
                bra.w   Spawner_StateCountdown
                bra.w   Spawner_StateSpawn

; Spawner state: countdown before spawn
Spawner_StateCountdown:
                bset    #7,$3C(a0)  ; was: sub_16366
                bne.s   loc_16378
                addq.b  #1,(byte_FFD26C).w
                bset    #1,2(a0)

loc_16378:
                bsr.w   Object_UpdatePosition
                tst.w   $38(a0)
                bne.s   loc_16390
                bclr    #1,2(a0)
                move.w  #4,$3C(a0)
                rts

loc_16390:
                subq.w  #1,$38(a0)
                rts

; Spawner state: spawn animation
Spawner_StateSpawn:
                bset    #7,$3C(a0)  ; was: sub_16396
                bne.s   loc_163AC
                bclr    #2,2(a0)
                clr.b   $10(a0)
                clr.w   6(a0)

loc_163AC:
                bsr.w   Object_UpdatePosition
                bsr.w   Anim_UpdateFrame
                bclr    #2,2(a0)
                beq.s   locret_163DE
                movea.l a0,a1
                suba.l  #$300,a1
                move.b  $16(a0),d0
                move.w  #$10,(a1)
                move.b  d0,$16(a1)
                cmpi.b  #2,d0
                bne.s   loc_163DA
                move.w  #$14,(a1)

loc_163DA:
                bsr.w   Sprite_ClearLinkTable

locret_163DE:
                rts

off_163E0:      dc.l    byte_163E4
byte_163E4:     dc.b    $1C, 4
                dc.w    word_1AAEC-Sys_GameEntryPoint
                dc.w    word_1AAEC-Sys_GameEntryPoint
                dc.w    word_1AAEC-Sys_GameEntryPoint
                dc.w    word_1AAF4-Sys_GameEntryPoint
                dc.w    word_1AAF4-Sys_GameEntryPoint
                dc.w    word_1AAF4-Sys_GameEntryPoint
                dc.w    word_1AAFC-Sys_GameEntryPoint
                dc.w    word_1AB04-Sys_GameEntryPoint
                dc.w    word_1AB0C-Sys_GameEntryPoint
                dc.w    word_1AB14-Sys_GameEntryPoint
                dc.w    word_1AB1C-Sys_GameEntryPoint
                dc.w    word_1AB14-Sys_GameEntryPoint
                dc.w    word_1AB0C-Sys_GameEntryPoint
                dc.w    word_1AB04-Sys_GameEntryPoint
                dc.w    word_1AAFC-Sys_GameEntryPoint
                dc.w    word_1AB04-Sys_GameEntryPoint
                dc.w    word_1AB0C-Sys_GameEntryPoint
                dc.w    word_1AB14-Sys_GameEntryPoint
                dc.w    word_1AB1C-Sys_GameEntryPoint
                dc.w    word_1AB14-Sys_GameEntryPoint
                dc.w    word_1AB0C-Sys_GameEntryPoint
                dc.w    word_1AB04-Sys_GameEntryPoint
                dc.w    word_1AAFC-Sys_GameEntryPoint
                dc.w    word_1AB04-Sys_GameEntryPoint
                dc.w    word_1AB0C-Sys_GameEntryPoint
                dc.w    word_1AB14-Sys_GameEntryPoint
                dc.w    word_1AB1C-Sys_GameEntryPoint
                dc.w    word_1AB14-Sys_GameEntryPoint
                dc.w    word_1AB0C-Sys_GameEntryPoint
                dc.w    word_1AB04-Sys_GameEntryPoint
; Floating score popup display object
Obj_ScorePopup:
                bset    #7,(a0)  ; was: sub_16422
                bne.s   loc_16442
                moveq   #0,d0
                move.b  $3A(a0),d0
                subq.b  #1,d0
                lsl.w   #1,d0
                moveq   #$FFFFFFFF,d1
                move.w  off_16450(pc,d0.w),d1
                move.l  d1,$C(a0)
                move.w  #$3C,$38(a0)

loc_16442:
                bsr.w   Object_UpdatePosition
                subq.w  #1,$38(a0)
                bne.s   locret_1644E
                clr.w   (a0)

locret_1644E:
                rts

off_16450:      dc.w    byte_1AB2C-Sys_GameEntryPoint
                dc.w    word_1AB3C-Sys_GameEntryPoint
                dc.w    word_1AB4C-Sys_GameEntryPoint
; Chick delivery count popup object
Obj_ChickCountPopup:
                bset    #7,(a0)  ; was: sub_16456
                bne.s   loc_16490
                move.b  $3A(a0),d0
                subq.b  #1,d0
                lsl.w   #1,d0
                moveq   #$FFFFFFFF,d1
                move.w  off_1649E(pc,d0.w),d1
                move.l  d1,$C(a0)
                lsl.w   #2,d0
                move.w  (word_FFD25C).w,d6
                cmpi.w  #$F0,d6
                bcs.s   loc_16482
                sub.w   d0,d6
                subi.w  #$18,d6
                bra.s   loc_16486

loc_16482:
                add.w   d0,d6
                addq.w  #8,d6

loc_16486:
                move.w  d6,$24(a0)
                move.w  #$1E,$38(a0)

loc_16490:
                bsr.w   Object_UpdatePosition
                subq.w  #1,$38(a0)
                bne.s   locret_1649C
                clr.w   (a0)

locret_1649C:
                rts

off_1649E:      dc.w    word_1AB24-Sys_GameEntryPoint
                dc.w    byte_1AB2C-Sys_GameEntryPoint
                dc.w    word_1AB34-Sys_GameEntryPoint
                dc.w    word_1AB3C-Sys_GameEntryPoint
                dc.w    word_1AB44-Sys_GameEntryPoint
                dc.w    word_1AB54-Sys_GameEntryPoint
                dc.w    word_1AB5C-Sys_GameEntryPoint
                dc.w    word_1AB6C-Sys_GameEntryPoint
; Bonus round score popup object
Obj_BonusScorePopup:
                bset    #7,(a0)  ; was: sub_164AE
                bne.s   loc_164CC
                moveq   #0,d0
                move.b  $3A(a0),d0
                lsl.w   #1,d0
                moveq   #$FFFFFFFF,d1
                move.w  off_164DA(pc,d0.w),d1
                move.l  d1,$C(a0)
                move.w  #$3C,$38(a0)

loc_164CC:
                bsr.w   Object_UpdatePosition
                subq.w  #1,$38(a0)
                bne.s   locret_164D8
                clr.w   (a0)

locret_164D8:
                rts

off_164DA:      dc.w    word_1AB24-Sys_GameEntryPoint
                dc.w    byte_1AB2C-Sys_GameEntryPoint
                dc.w    word_1AB34-Sys_GameEntryPoint
                dc.w    word_1AB3C-Sys_GameEntryPoint
                dc.w    word_1AB44-Sys_GameEntryPoint
                dc.w    word_1AB4C-Sys_GameEntryPoint
                dc.w    word_1AB54-Sys_GameEntryPoint
                dc.w    word_1AB5C-Sys_GameEntryPoint
                dc.w    word_1AB64-Sys_GameEntryPoint
; Collectible star bonus object
