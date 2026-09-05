; Object slots, animation, sprite rendering, handler dispatch.
; ROM $01105C-$01130B.

Object_UpdatePosition:
                btst    #0,2(a0)  ; was: sub_1105C
                bne.s   locret_110B8
                move.l  $34(a0),d1
                move.l  $30(a0),d2
                add.l   d1,d2
                cmpi.l  #$800000,d2
                bge.s   loc_1107C
                addi.l  #$1000000,d2

loc_1107C:
                cmpi.l  #$1800000,d2
                blt.s   loc_1108A
                subi.l  #$1000000,d2

loc_1108A:
                move.l  d2,$30(a0)
                swap    d2
                sub.w   (dword_FFFFA8).w,d2

loc_11094:
                cmpi.w  #$80,d2
                bge.s   loc_110A0
                addi.w  #$100,d2
                bra.s   loc_11094

loc_110A0:
                cmpi.w  #$180,d2
                blt.s   loc_110AC
                subi.w  #$100,d2
                bra.s   loc_110A0

loc_110AC:
                move.w  d2,$20(a0)
                move.l  $2C(a0),d3
                add.l   d3,$24(a0)

locret_110B8:
                rts

; Calculates screen position from world pos minus camera
Object_CalcScreenPos:
                move.l  $30(a0),d2  ; was: sub_110BA
                sub.l   (dword_FFFFA8).w,d2

loc_110C2:
                cmpi.l  #$800000,d2
                bge.s   loc_110D2
                addi.l  #$1000000,d2
                bra.s   loc_110C2

loc_110D2:
                cmpi.l  #$1800000,d2
                blt.s   loc_110E2
                subi.l  #$1000000,d2
                bra.s   loc_110D2

loc_110E2:
                move.l  d2,$20(a0)
                move.l  $2C(a0),d3
                add.l   d3,$24(a0)
                rts

; Clears single 64-byte object slot at a0
Object_ClearSlot:
                movea.w a0,a6  ; was: sub_110F0
                moveq   #$F,d7
                moveq   #0,d6

loc_110F6:
                move.l  d6,(a6)+
                dbf     d7,loc_110F6
                rts

; Clears all 32 object slots starting at FFC000
Object_ClearAllSlots:
                movem.l d5/a0,-(sp)  ; was: sub_110FE
                move.w  #$1F,d5
                lea     (word_FFC000).w,a0

loc_1110A:
                bsr.s   Object_ClearSlot
                movea.w a6,a0
                dbf     d5,loc_1110A
                movem.l (sp)+,d5/a0
                rts

; Clears sprite link chain (31 entries)
Sprite_ClearLinkTable:
                movea.w a0,a6  ; was: sub_11118
                moveq   #$1E,d7
                moveq   #0,d6

loc_1111E:
                move.w  d6,(a6)+
                dbf     d7,loc_1111E
                rts

; Updates animation timer and advances frame index
Anim_UpdateFrame:
                move.w  6(a0),d0  ; was: sub_11126
                movea.l 8(a0),a1
                movea.l (a1,d0.w),a1
                subq.b  #1,$11(a0)
                bpl.s   loc_11142
                move.b  1(a1),$11(a0)
                addq.b  #1,$10(a0)

loc_11142:
                moveq   #0,d0
                move.b  $10(a0),d0
                cmp.b   (a1),d0
                bcs.s   loc_11158
                clr.b   $10(a0)
                moveq   #0,d0
                bset    #2,2(a0)

loc_11158:
                lsl.w   #1,d0
                moveq   #$FFFFFFFF,d1
                move.w  2(a1,d0.w),d1
                move.l  d1,$C(a0)
                rts

; Renders object sprite to sprite table from mappings
Sprite_RenderObject:
                btst    #1,2(a0)  ; was: sub_11166
                beq.s   loc_11170
                rts

loc_11170:
                movea.l $C(a0),a1
                moveq   #0,d1
                move.b  (a1)+,d1
                move.b  (a1)+,4(a0)
                move.w  $24(a0),d2
                cmpi.w  #$180,d2
                bhi.s   locret_111D2
                move.w  $20(a0),d3

loc_1118A:
                move.b  (a1)+,d0
                ext.w   d0
                add.w   d2,d0
                move.w  d0,(a2)+
                move.b  (a1)+,(a2)+
                move.b  d6,(a2)+
                move.b  (a1)+,d0
                or.b    $13(a0),d0
                move.b  d0,(a2)+
                move.b  (a1)+,(a2)+
                move.b  (a1)+,d0
                tst.b   2(a0)
                bpl.s   loc_111B0
                bchg    #3,-2(a2)
                move.b  (a1),d0

loc_111B0:
                addq.w  #1,a1
                ext.w   d0
                add.w   d3,d0
                move.w  d0,d4
                subi.w  #$41,d4
                cmpi.w  #$17F,d4
                bcs.s   loc_111CA
                subq.w  #6,a2
                dbf     d1,loc_1118A
                rts

loc_111CA:
                move.w  d0,(a2)+
                addq.b  #1,d6
                dbf     d1,loc_1118A

locret_111D2:
                rts

; Updates main object slot and builds sprite list
Object_UpdateMain:
                lea     (word_FFC000).w,a0  ; was: sub_111D4
                bsr.w   Object_CallHandler
                bsr.w   loc_11254
                rts

; Updates all active objects and builds sprite table
Object_UpdateAll:
                tst.b   (byte_FFD24E).w  ; was: sub_111E2
                bne.s   loc_11228
                lea     (word_FFC440).w,a0
                bsr.w   Object_CallHandler
                lea     (unk_FFC200).w,a0
                moveq   #8,d0

loc_111F6:
                bsr.w   Object_CallHandler
                lea     $40(a0),a0
                dbf     d0,loc_111F6
                lea     (unk_FFC480).w,a0
                moveq   #$D,d0

loc_11208:
                bsr.w   Object_CallHandler
                lea     $40(a0),a0
                dbf     d0,loc_11208
                lea     (word_FFC000).w,a0
                moveq   #7,d0

loc_1121A:
                bsr.w   Object_CallHandler
                lea     $40(a0),a0
                dbf     d0,loc_1121A
                bra.s   loc_11254

loc_11228:
                lea     (unk_FFC580).w,a0
                bsr.w   Object_CallHandler
                lea     (word_FFC040).w,a0
                moveq   #$14,d0

loc_11236:
                bsr.w   Object_CallHandler
                lea     $40(a0),a0
                dbf     d0,loc_11236
                lea     (unk_FFC5C0).w,a0
                moveq   #3,d0

loc_11248:
                bsr.w   Object_CallHandler
                lea     $40(a0),a0
                dbf     d0,loc_11248

loc_11254:
                move.w  #$F550,(word_FFD000).w
                move.w  #1,(word_FFD002).w
                lea     (word_FFC000).w,a0
                moveq   #$1F,d7

loc_11266:
                move.w  d7,-(sp)
                tst.w   (a0)
                beq.s   loc_11280
                movea.w (word_FFD000).w,a2
                move.w  (word_FFD002).w,d6
                bsr.w   Sprite_RenderObject
                move.w  d6,(word_FFD002).w
                move.w  a2,(word_FFD000).w

loc_11280:
                lea     $40(a0),a0
                move.w  (sp)+,d7
                dbf     d7,loc_11266
                movea.w (word_FFD000).w,a2
                cmpa.w  #$F550,a2
                beq.s   loc_1129A
                clr.b   -5(a2)
                rts

loc_1129A:
                clr.l   (a2)

locret_1129C:
                rts

; Dispatches to object type handler via jump table
Object_CallHandler:
                move.w  d0,-(sp)  ; was: sub_1129E
                move.w  (a0),d0
                beq.s   loc_112AC
                andi.w  #$7FFC,d0
                jsr     loc_112B0(pc,d0.w)

loc_112AC:
                move.w  (sp)+,d0
                rts

loc_112B0:
                bra.w   locret_1129C
                bra.w   Obj_Chick
                bra.w   Obj_Cat
                bra.w   Obj_Player
                bra.w   Obj_Lizard
                bra.w   Obj_Snake
                bra.w   Obj_Spawner
                bra.w   Obj_ScorePopup
                bra.w   Obj_ChickCountPopup
                bra.w   Obj_BonusScorePopup
                bra.w   Obj_StarBonus
                bra.w   Obj_BonusHeldChick
                bra.w   Obj_BonusCatOuter
                bra.w   Obj_BonusCatInner
                bra.w   Obj_BonusChick
                bra.w   Obj_GameOverText
                bra.w   Obj_TitleBird
                bra.w   Obj_TitleCursor
                bra.w   Obj_TitleStatic
                bra.w   Obj_GuideCharacter
                bra.w   Obj_CreditsCharacter
                bra.w   Obj_ExitDoor
                bra.w   Obj_TimeOverText

; Adds scroll velocity to camera position
