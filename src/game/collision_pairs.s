; Object-pair collision testing.
; ROM $0117C0-$01190F.

Collision_CheckObjectPair:
                tst.w   (a1)  ; was: sub_117C0
                beq.w   loc_11874
                moveq   #0,d0
                moveq   #0,d1
                move.b  4(a0),d0
                cmpi.b  #$FF,d0
                beq.w   loc_11874
                move.b  4(a1),d1
                cmpi.b  #$FF,d1
                beq.w   loc_11874
                lsl.w   #3,d0
                lsl.w   #3,d1
                move.w  $20(a0),d3
                lea     word_11878(pc),a6
                add.w   (a6,d0.w),d3
                move.w  d3,d2
                addq.l  #2,a6
                add.w   (a6,d0.w),d3
                move.w  $20(a1),d5
                add.w   word_11878(pc,d1.w),d5
                move.w  d5,d4
                add.w   word_1187A(pc,d1.w),d5
                cmp.w   d2,d4
                blt.s   loc_11812
                cmp.w   d3,d4
                bgt.s   loc_11812
                bra.s   loc_1182E

loc_11812:
                cmp.w   d2,d5
                blt.s   loc_1181C
                cmp.w   d3,d5
                bgt.s   loc_1181C
                bra.s   loc_1182E

loc_1181C:
                cmp.w   d4,d2
                blt.s   loc_11826
                cmp.w   d5,d2
                bgt.s   loc_11826
                bra.s   loc_1182E

loc_11826:
                cmp.w   d4,d3
                blt.s   loc_11874
                cmp.w   d5,d3
                bgt.s   loc_11874

loc_1182E:
                move.w  $24(a0),d3
                add.w   word_1187C(pc,d0.w),d3
                move.w  d3,d2
                add.w   word_1187E(pc,d0.w),d3
                move.w  $24(a1),d5
                add.w   word_1187C(pc,d1.w),d5
                move.w  d5,d4
                add.w   word_1187E(pc,d1.w),d5
                cmp.w   d2,d4
                blt.s   loc_11854
                cmp.w   d3,d4
                bgt.s   loc_11854
                bra.s   loc_11870

loc_11854:
                cmp.w   d2,d5
                blt.s   loc_1185E
                cmp.w   d3,d5
                bgt.s   loc_1185E
                bra.s   loc_11870

loc_1185E:
                cmp.w   d4,d2
                blt.s   loc_11868
                cmp.w   d5,d2
                bgt.s   loc_11868
                bra.s   loc_11870

loc_11868:
                cmp.w   d4,d3
                blt.s   loc_11874
                cmp.w   d5,d3
                bgt.s   loc_11874

loc_11870:
                moveq   #1,d0
                rts

loc_11874:
                moveq   #0,d0
                rts

word_11878:     dc.w    $FFFF
word_1187A:     dc.w    2
word_1187C:     dc.w    $FFEE
word_1187E:     dc.w    $12
                dc.l    $FFFF0002
                dc.l    $FFF00010
                dc.l    $FFFC0008
                dc.l    $FFF2000C
                dc.l    $FFF9000E
                dc.l    $FFF4000C
                dc.l    $FFFC0008
                dc.l    $FFFA0006
                dc.l    $FFFF0002
                dc.l    $FFEE0012
                dc.l    $FFFE0004
                dc.l    $FFF60004
                dc.l    $FFFC0008
                dc.l    $FFF90007
                dc.l    $FFFF0002
                dc.l    $FFFA0006
                dc.l    $FFFC0008
                dc.l    $FFF6000A
                dc.l    $FFFC0008
                dc.l    $FFFC0002
                dc.l    $FFFC0008
                dc.l    $30002
                dc.l    $FFFC0002
                dc.l    $FFFC0008
                dc.l    $40002
                dc.l    $FFFC0008
                dc.l    $FFFF0002
                dc.l    $FFFD0006
                dc.l    $FFFE0004
                dc.l    8
                dc.l    $FFF80010
                dc.l    $FFF00010
                dc.l    $FFF80010
                dc.l    $FFF00002
                dc.l    $FFFF0002
                dc.l    $FFEE000E
; Writes ground tile from lookup table to VRAM
