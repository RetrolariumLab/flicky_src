; Camera scrolling and the collision map.
; ROM $01130C-$011421.

Camera_UpdateScroll:
                move.l  (dword_FFD004).w,d0  ; was: sub_1130C
                move.l  (dword_FFFFA8).w,d1
                add.l   d0,d1
                move.l  d1,(dword_FFFFA8).w
                move.l  (dword_FFD008).w,d0
                move.l  (dword_FFFFA4).w,d1
                add.l   d0,d1
                move.l  d1,(dword_FFFFA4).w
                rts

; Writes horizontal and vertical scroll to VDP registers
Gfx_UpdateScrollRegs:
                lea     (VDP_CTRL).l,a6  ; was: sub_1132A
                lea     (VDP_DATA).l,a5
                move.w  (dword_FFFFA8).w,d7
                neg.w   d7
                move.w  #$8F20,(a6)
                move.l  #$78400002,(VDP_CTRL).l
                moveq   #$17,d0

loc_1134C:
                move.w  d7,(a5)
                dbf     d0,loc_1134C
                move.l  #$78020002,(VDP_CTRL).l
                moveq   #$1B,d0

loc_1135E:
                move.w  d7,(a5)
                dbf     d0,loc_1135E
                move.w  #$8F02,(a6)
                move.w  (dword_FFFFA4).w,d7
                move.l  #$40000010,(VDP_CTRL).l
                move.w  d7,(a5)
                rts

; Animation timer countdown with frame advance and wrap
Anim_ProcessTimer:
                subq.b  #1,1(a0)  ; was: sub_1137A
                bpl.s   loc_1138A
                move.b  1(a1),1(a0)
                addq.b  #1,0.w(a0)

loc_1138A:
                moveq   #0,d0
                move.b  0.w(a0),d0
                cmp.b   (a1),d0
                bcs.s   loc_113A0
                clr.b   0.w(a0)
                moveq   #0,d0
                move.b  #1,2(a0)

loc_113A0:
                asl.w   #2,d0
                movea.l 2(a1,d0.w),a6
                bsr.w   Gfx_DrawTilemapRect
                rts

; Clears 896-byte collision map at FFC800
Collision_ClearMap:
                lea     (unk_FFC800).w,a0  ; was: sub_113AC
                move.w  #$DF,d0

loc_113B4:
                clr.l   (a0)+
                dbf     d0,loc_113B4
                rts

; Clears camera position and velocity variables
Camera_ClearScroll:
                clr.l   (dword_FFFFA8).w  ; was: sub_113BC
                clr.l   (dword_FFFFA4).w
                clr.l   (dword_FFD004).w
                clr.l   (dword_FFD008).w
                rts

; Sets collision value d4 at map position d6/d7
Collision_SetTile:
                movem.w d4/d6-d7/a6,-(sp)  ; was: sub_113CE
                lea     (unk_FFC800).w,a6
                lsl.w   #5,d6
                add.w   d7,d6
                move.b  d4,(a6,d6.w)
                movem.w (sp)+,d4/d6-d7/a6
                rts

; Loads collision map from compressed data at (a6)
Collision_LoadMap:
                bsr.s   Collision_ClearMap  ; was: sub_113E4
                lea     (unk_FFC840).w,a0

loc_113EA:
                moveq   #0,d7
                move.b  (a6)+,d7
                beq.s   locret_113FA
                bclr    #7,d7
                bne.s   loc_113FC
                adda.l  d7,a0
                bra.s   loc_113EA

locret_113FA:
                rts

loc_113FC:
                bclr    #6,d7
                bne.s   loc_1140E
                subq.b  #1,d7

loc_11404:
                move.b  #1,(a0)+
                dbf     d7,loc_11404
                bra.s   loc_113EA

loc_1140E:
                movea.w a0,a1
                subq.b  #1,d7

loc_11412:
                move.b  #1,(a1)
                lea     $20(a1),a1
                dbf     d7,loc_11412
                addq.l  #1,a0
                bra.s   loc_113EA

; Master level init: collision, objects, player, enemies
