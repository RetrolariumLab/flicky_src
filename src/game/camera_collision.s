; Camera scrolling and the collision map.
; ROM $01130C-$011421.

Camera_UpdateScroll:
                move.l  (Ram_CameraVelocityX).w,d0  ; was: sub_1130C
                move.l  (Ram_CameraX).w,d1
                add.l   d0,d1
                move.l  d1,(Ram_CameraX).w
                move.l  (Ram_CameraVelocityY).w,d0
                move.l  (Ram_CameraY).w,d1
                add.l   d0,d1
                move.l  d1,(Ram_CameraY).w
                rts

; Writes horizontal and vertical scroll to VDP registers
Gfx_UpdateScrollRegs:
                lea     (VDP_CTRL).l,a6  ; was: sub_1132A
                lea     (VDP_DATA).l,a5
                move.w  (Ram_CameraX).w,d7
                neg.w   d7
                move.w  #$8F20,(a6)
                move.l  #$78400002,(VDP_CTRL).l
                moveq   #$17,d0

Gfx_UpdateScrollRegs_HScrollLoop:  ; was: loc_1134C
                move.w  d7,(a5)
                dbf     d0,Gfx_UpdateScrollRegs_HScrollLoop
                move.l  #$78020002,(VDP_CTRL).l
                moveq   #$1B,d0

Gfx_UpdateScrollRegs_VScrollLoop:  ; was: loc_1135E
                move.w  d7,(a5)
                dbf     d0,Gfx_UpdateScrollRegs_VScrollLoop
                move.w  #$8F02,(a6)
                move.w  (Ram_CameraY).w,d7
                move.l  #$40000010,(VDP_CTRL).l
                move.w  d7,(a5)
                rts

; Animation timer countdown with frame advance and wrap
Anim_ProcessTimer:
                subq.b  #1,1(a0)  ; was: sub_1137A
                bpl.s   Anim_ProcessTimer_CheckWrap
                move.b  1(a1),1(a0)
                addq.b  #1,0.w(a0)

Anim_ProcessTimer_CheckWrap:  ; was: loc_1138A
                moveq   #0,d0
                move.b  0.w(a0),d0
                cmp.b   (a1),d0
                bcs.s   Anim_ProcessTimer_DrawFrame
                clr.b   0.w(a0)
                moveq   #0,d0
                move.b  #1,2(a0)

Anim_ProcessTimer_DrawFrame:  ; was: loc_113A0
                asl.w   #2,d0
                movea.l 2(a1,d0.w),a6
                bsr.w   Gfx_DrawTilemapRect
                rts

; Clears 896-byte collision map at FFC800
Collision_ClearMap:
                lea     (Ram_CollisionMap).w,a0  ; was: sub_113AC
                move.w  #$DF,d0

Collision_ClearMap_Loop:  ; was: loc_113B4
                clr.l   (a0)+
                dbf     d0,Collision_ClearMap_Loop
                rts

; Clears camera position and velocity variables
Camera_ClearScroll:
                clr.l   (Ram_CameraX).w  ; was: sub_113BC
                clr.l   (Ram_CameraY).w
                clr.l   (Ram_CameraVelocityX).w
                clr.l   (Ram_CameraVelocityY).w
                rts

; Sets collision value d4 at map position d6/d7
Collision_SetTile:
                movem.w d4/d6-d7/a6,-(sp)  ; was: sub_113CE
                lea     (Ram_CollisionMap).w,a6
                lsl.w   #5,d6
                add.w   d7,d6
                move.b  d4,(a6,d6.w)
                movem.w (sp)+,d4/d6-d7/a6
                rts

; Loads collision map from compressed data at (a6)
Collision_LoadMap:
                bsr.s   Collision_ClearMap  ; was: sub_113E4
                lea     (Ram_CollisionMapRow1).w,a0

Collision_LoadMap_NextRun:  ; was: loc_113EA
                moveq   #0,d7
                move.b  (a6)+,d7
                beq.s   Collision_LoadMap_Return
                bclr    #7,d7
                bne.s   Collision_LoadMap_CheckOrientation
                adda.l  d7,a0
                bra.s   Collision_LoadMap_NextRun

Collision_LoadMap_Return:  ; was: locret_113FA
                rts

Collision_LoadMap_CheckOrientation:  ; was: loc_113FC
                bclr    #6,d7
                bne.s   Collision_LoadMap_VerticalSetup
                subq.b  #1,d7

Collision_LoadMap_HorizontalLoop:  ; was: loc_11404
                move.b  #1,(a0)+
                dbf     d7,Collision_LoadMap_HorizontalLoop
                bra.s   Collision_LoadMap_NextRun

Collision_LoadMap_VerticalSetup:  ; was: loc_1140E
                movea.w a0,a1
                subq.b  #1,d7

Collision_LoadMap_VerticalLoop:  ; was: loc_11412
                move.b  #1,(a1)
                lea     $20(a1),a1
                dbf     d7,Collision_LoadMap_VerticalLoop
                addq.l  #1,a0
                bra.s   Collision_LoadMap_NextRun

; Master level init: collision, objects, player, enemies
