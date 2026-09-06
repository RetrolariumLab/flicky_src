; Object-pair collision testing
; ROM $0117C0-$01190F

Collision_CheckObjectPair:
                tst.w   (a1)
                beq.w   Collision_CheckObjectPair_Miss
                moveq   #0,d0
                moveq   #0,d1
                move.b  4(a0),d0
                cmpi.b  #$FF,d0
                beq.w   Collision_CheckObjectPair_Miss
                move.b  4(a1),d1
                cmpi.b  #$FF,d1
                beq.w   Collision_CheckObjectPair_Miss
                lsl.w   #3,d0
                lsl.w   #3,d1
                move.w  $20(a0),d3
                lea     Collision_BoxLeftTable(pc),a6
                add.w   (a6,d0.w),d3
                move.w  d3,d2
                addq.l  #2,a6
                add.w   (a6,d0.w),d3
                move.w  $20(a1),d5
                add.w   Collision_BoxLeftTable(pc,d1.w),d5
                move.w  d5,d4
                add.w   Collision_BoxWidthTable(pc,d1.w),d5
                cmp.w   d2,d4
                blt.s   Collision_CheckObjectPair_TestXCase2
                cmp.w   d3,d4
                bgt.s   Collision_CheckObjectPair_TestXCase2
                bra.s   Collision_CheckObjectPair_TestY

Collision_CheckObjectPair_TestXCase2:
                cmp.w   d2,d5
                blt.s   Collision_CheckObjectPair_TestXCase3
                cmp.w   d3,d5
                bgt.s   Collision_CheckObjectPair_TestXCase3
                bra.s   Collision_CheckObjectPair_TestY

Collision_CheckObjectPair_TestXCase3:
                cmp.w   d4,d2
                blt.s   Collision_CheckObjectPair_TestXCase4
                cmp.w   d5,d2
                bgt.s   Collision_CheckObjectPair_TestXCase4
                bra.s   Collision_CheckObjectPair_TestY

Collision_CheckObjectPair_TestXCase4:
                cmp.w   d4,d3
                blt.s   Collision_CheckObjectPair_Miss
                cmp.w   d5,d3
                bgt.s   Collision_CheckObjectPair_Miss

Collision_CheckObjectPair_TestY:
                move.w  $24(a0),d3
                add.w   Collision_BoxTopTable(pc,d0.w),d3
                move.w  d3,d2
                add.w   Collision_BoxHeightTable(pc,d0.w),d3
                move.w  $24(a1),d5
                add.w   Collision_BoxTopTable(pc,d1.w),d5
                move.w  d5,d4
                add.w   Collision_BoxHeightTable(pc,d1.w),d5
                cmp.w   d2,d4
                blt.s   Collision_CheckObjectPair_TestYCase2
                cmp.w   d3,d4
                bgt.s   Collision_CheckObjectPair_TestYCase2
                bra.s   Collision_CheckObjectPair_Hit

Collision_CheckObjectPair_TestYCase2:
                cmp.w   d2,d5
                blt.s   Collision_CheckObjectPair_TestYCase3
                cmp.w   d3,d5
                bgt.s   Collision_CheckObjectPair_TestYCase3
                bra.s   Collision_CheckObjectPair_Hit

Collision_CheckObjectPair_TestYCase3:
                cmp.w   d4,d2
                blt.s   Collision_CheckObjectPair_TestYCase4
                cmp.w   d5,d2
                bgt.s   Collision_CheckObjectPair_TestYCase4
                bra.s   Collision_CheckObjectPair_Hit

Collision_CheckObjectPair_TestYCase4:
                cmp.w   d4,d3
                blt.s   Collision_CheckObjectPair_Miss
                cmp.w   d5,d3
                bgt.s   Collision_CheckObjectPair_Miss

Collision_CheckObjectPair_Hit:
                moveq   #1,d0
                rts

Collision_CheckObjectPair_Miss:
                moveq   #0,d0
                rts

; Bounding boxes, eight bytes per object type, indexed by (type * 8):
; left offset, width, top offset, height. The four labels below are the field
; bases; the code indexes each of them by the type to reach the right entry
Collision_BoxLeftTable:     dc.w    $FFFF
Collision_BoxWidthTable:    dc.w    2
Collision_BoxTopTable:      dc.w    $FFEE
Collision_BoxHeightTable:   dc.w    $12
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
