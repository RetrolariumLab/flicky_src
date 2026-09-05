; Level init, object spawning, collision queries.
; ROM $011422-$011673.

Level_Init:
                bsr.s Collision_LoadMap  ; was: sub_11422
                bsr.s Level_SpawnObjects
                bsr.w Level_BuildGroundTilemap
                bsr.w Level_DrawUpperGround
                bsr.w Level_DrawLowerGround
                bsr.w Level_DrawEntryArrow
                bsr.s Collision_SetBoundaries
                rts

; Fills map edges with solid collision type
Collision_SetBoundaries:
                lea     (unk_FFC800).w,a0  ; was: sub_1143A
                moveq   #$1F,d0

loc_11440:
                move.b  #$C,(a0)+
                dbf     d0,loc_11440
                lea     (unk_FFCB40).w,a0
                moveq   #$3F,d0

loc_1144E:
                move.b  #$C,(a0)+
                dbf     d0,loc_1144E
                lea     (unk_FFC840).w,a0
                moveq   #$1F,d0

loc_1145C:
                tst.b   (a0)
                beq.s   loc_1146C
                move.b  #3,-$20(a0)
                move.b  #$E,-$40(a0)

loc_1146C:
                addq.l  #1,a0
                dbf     d0,loc_1145C
                lea     (unk_FFCB20).w,a0
                moveq   #$1F,d0

loc_11478:
                tst.b   (a0)
                beq.s   loc_11482
                move.b  #$D,$20(a0)

loc_11482:
                addq.l  #1,a0
                dbf     d0,loc_11478
                rts

; Spawns level objects from level data at (a6)
Level_SpawnObjects:
                lea     (byte_FFD82E).w,a0  ; was: sub_1148A
                move.b  (a6),(a0)+
                move.b  1(a6),(a0)
                moveq   #0,d4
                moveq   #0,d0
                bsr.w Level_SpawnBackgroundLoop
                lea     (byte_FFD830).w,a0
                moveq   #0,d0
                move.b  (a6),(a0)+
                move.b  1(a6),(a0)+
                moveq   #1,d4
                bsr.w Level_SpawnBackgroundLoop
                lea     (unk_FFD832).w,a0
                moveq   #0,d0
                move.b  (a6),(a0)+
                move.b  1(a6),(a0)+
                moveq   #1,d4
                bsr.w Level_SpawnBackgroundLoop
                lea     (byte_FFD834).w,a0
                move.b  (a6),(a0)+
                move.b  1(a6),(a0)
                moveq   #2,d4
                moveq   #0,d0
                bsr.w Level_SpawnBackgroundLoop
                moveq   #3,d4
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   loc_114E0
                subq.b  #1,d0
                bsr.w Level_SpawnBackgroundLoop

loc_114E0:
                moveq   #4,d4
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   loc_114EC
                subq.b  #1,d0
                bsr.s Level_SpawnBackgroundLoop

loc_114EC:
                moveq   #5,d4
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   loc_114F8
                subq.b  #1,d0
                bsr.s Level_SpawnBackgroundLoop

loc_114F8:
                lea     (unk_FFC200).w,a0
                moveq   #5,d0

loc_114FE:
                move.w  #4,(a0)
                move.b  (a6)+,$3E(a0)
                move.b  (a6)+,$3F(a0)
                lea     $40(a0),a0
                dbf     d0,loc_114FE
                lea     (unk_FFC480).w,a0
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   loc_1153A
                add.b   d0,(byte_FFD883).w
                subq.b  #1,d0

loc_11522:
                move.w  #8,(a0)
                move.b  (a6)+,$3E(a0)
                move.b  (a6)+,$3F(a0)
                clr.b   $3A(a0)
                lea     $40(a0),a0
                dbf     d0,loc_11522

loc_1153A:
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   locret_11560
                add.b   d0,(byte_FFD883).w
                subq.b  #1,d0

loc_11546:
                move.w  #8,(a0)
                move.b  (a6)+,$3E(a0)
                move.b  (a6)+,$3F(a0)
                move.b  #1,$3A(a0)
                lea     $40(a0),a0
                dbf     d0,loc_11546

locret_11560:
                rts

; Spawns background objects from position list at (a6)
Level_SpawnBackgroundLoop:
                moveq   #0,d7  ; was: sub_11562
                moveq   #0,d6
                move.b  (a6)+,d7
                move.b  (a6)+,d6
                movem.l d0/d4/a6,-(sp)
                bsr.w Level_DrawBackgroundObject
                movem.l (sp)+,d0/d4/a6
                dbf d0,Level_SpawnBackgroundLoop
                rts

; Gets collision tile value at world position d7/d6
Collision_GetTileAtPos:
                movem.l d6-d7/a1,-(sp)  ; was: sub_1157C
                cmpi.w  #$80,d7
                bge.s   loc_1158A
                addi.w  #$100,d7

loc_1158A:
                cmpi.w  #$180,d7
                blt.s   loc_11594
                subi.w  #$100,d7

loc_11594:
                lea     (unk_FFC800).w,a1
                move.l  #$FFFF,d4
                and.l   d4,d7
                and.l   d4,d6
                subi.w  #$80,d7
                subi.w  #$80,d6
                lsr.w   #3,d7
                lsr.w   #3,d6
                lsl.w   #5,d6
                adda.l  d7,a1
                adda.l  d6,a1
                move.b  (a1),d4
                andi.b  #$F,d4
                movem.l (sp)+,d6-d7/a1
                rts

; Gets collision tile at object-relative position
Collision_GetTileAtObject:
                add.w   $30(a0),d7  ; was: sub_115C0
                add.w   $24(a0),d6
                cmpi.w  #$80,d7
                bge.s   loc_115D2
                addi.w  #$100,d7

loc_115D2:
                cmpi.w  #$180,d7
                blt.s   loc_115DC
                subi.w  #$100,d7

loc_115DC:
                movem.l d6-d7,-(sp)
                lea     (unk_FFC800).w,a1
                move.l  #$FFFF,d4
                and.l   d4,d7
                and.l   d4,d6
                subi.w  #$80,d7
                subi.w  #$80,d6
                lsr.w   #3,d7
                lsr.w   #3,d6
                lsl.w   #5,d6
                adda.l  d7,a1
                adda.l  d6,a1
                move.b  (a1),d4
                movem.l (sp)+,d6-d7
                rts

; Marks special collision tiles with flag bits 7/6/5
Collision_SetSpecialTiles:
                moveq   #0,d0  ; was: sub_11608
                move.b  (a6)+,d0
                beq.s   loc_1162A
                subq.w  #1,d0

loc_11610:
                moveq   #0,d7
                moveq   #0,d6
                lea     (unk_FFC800).w,a0
                move.b  (a6)+,d7
                move.b  (a6)+,d6
                adda.l  d7,a0
                lsl.w   #5,d6
                adda.l  d6,a0
                bset    #7,(a0)
                dbf     d0,loc_11610

loc_1162A:
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   loc_11650
                subq.w  #1,d0

loc_11632:
                moveq   #0,d7
                moveq   #0,d6
                lea     (unk_FFC800).w,a0
                move.b  (a6)+,d7
                move.b  (a6)+,d6
                adda.l  d7,a0
                lsl.w   #5,d6
                adda.l  d6,a0
                bset    #7,(a0)
                bset    #6,(a0)
                dbf     d0,loc_11632

loc_11650:
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   locret_11672
                subq.w  #1,d0

loc_11658:
                moveq   #0,d7
                moveq   #0,d6
                lea     (unk_FFC800).w,a0
                move.b  (a6)+,d7
                move.b  (a6)+,d6
                adda.l  d7,a0
                lsl.w   #5,d6
                adda.l  d6,a0
                bset    #5,(a0)
                dbf     d0,loc_11658

locret_11672:
                rts

; Converts grid coords to screen pixels (x8 + $80)
