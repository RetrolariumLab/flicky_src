; Level init, object spawning, collision queries
; ROM $011422-$011673

Level_Init:
                bsr.s   Collision_LoadMap
                bsr.s   Level_SpawnObjects
                bsr.w   Level_BuildGroundTilemap
                bsr.w   Level_DrawUpperGround
                bsr.w   Level_DrawLowerGround
                bsr.w   Level_DrawEntryArrow
                bsr.s   Collision_SetBoundaries
                rts

; Fills map edges with solid collision type
Collision_SetBoundaries:
                lea     (Ram_CollisionMap).w,a0
                moveq   #$1F,d0

Collision_SetBoundaries_TopRowLoop:
                move.b  #$C,(a0)+
                dbf     d0,Collision_SetBoundaries_TopRowLoop
                lea     (Ram_CollisionMapEnd).w,a0
                moveq   #$3F,d0

Collision_SetBoundaries_BottomRowsLoop:
                move.b  #$C,(a0)+
                dbf     d0,Collision_SetBoundaries_BottomRowsLoop
                lea     (Ram_CollisionMapRow1).w,a0
                moveq   #$1F,d0

Collision_SetBoundaries_TopEdgeLoop:
                tst.b   (a0)
                beq.s   Collision_SetBoundaries_TopEdgeNext
                move.b  #3,-$20(a0)
                move.b  #$E,-$40(a0)

Collision_SetBoundaries_TopEdgeNext:
                addq.l  #1,a0
                dbf     d0,Collision_SetBoundaries_TopEdgeLoop
                lea     (Ram_CollisionMapLastRow).w,a0
                moveq   #$1F,d0

Collision_SetBoundaries_BottomEdgeLoop:
                tst.b   (a0)
                beq.s   Collision_SetBoundaries_BottomEdgeNext
                move.b  #$D,$20(a0)

Collision_SetBoundaries_BottomEdgeNext:
                addq.l  #1,a0
                dbf     d0,Collision_SetBoundaries_BottomEdgeLoop
                rts

; Spawns level objects from level data at (a6)
Level_SpawnObjects:
                lea     (Ram_PlayerStartX).w,a0
                move.b  (a6),(a0)+
                move.b  1(a6),(a0)
                moveq   #0,d4
                moveq   #0,d0
                bsr.w   Level_SpawnBackgroundLoop
                lea     (Ram_EntryArrowPos).w,a0
                moveq   #0,d0
                move.b  (a6),(a0)+
                move.b  1(a6),(a0)+
                moveq   #1,d4
                bsr.w   Level_SpawnBackgroundLoop
                lea     (Ram_CatDoorPos).w,a0
                moveq   #0,d0
                move.b  (a6),(a0)+
                move.b  1(a6),(a0)+
                moveq   #1,d4
                bsr.w   Level_SpawnBackgroundLoop
                lea     (Ram_ExitDoorGridX).w,a0
                move.b  (a6),(a0)+
                move.b  1(a6),(a0)
                moveq   #2,d4
                moveq   #0,d0
                bsr.w   Level_SpawnBackgroundLoop
                moveq   #3,d4
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   Level_SpawnObjects_Group4
                subq.b  #1,d0
                bsr.w   Level_SpawnBackgroundLoop

Level_SpawnObjects_Group4:
                moveq   #4,d4
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   Level_SpawnObjects_Group5
                subq.b  #1,d0
                bsr.s   Level_SpawnBackgroundLoop

Level_SpawnObjects_Group5:
                moveq   #5,d4
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   Level_SpawnObjects_Spawners
                subq.b  #1,d0
                bsr.s   Level_SpawnBackgroundLoop

Level_SpawnObjects_Spawners:
                lea     (Ram_SpawnerSlots).w,a0
                moveq   #5,d0

Level_SpawnObjects_SpawnerLoop:
                move.w  #4,(a0)
                move.b  (a6)+,$3E(a0)
                move.b  (a6)+,$3F(a0)
                lea     $40(a0),a0
                dbf     d0,Level_SpawnObjects_SpawnerLoop
                lea     (Ram_ChickSlots).w,a0
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   Level_SpawnObjects_SecondChickGroup
                add.b   d0,(Ram_ChicksRemaining).w
                subq.b  #1,d0

Level_SpawnObjects_ChickLoop:
                move.w  #8,(a0)
                move.b  (a6)+,$3E(a0)
                move.b  (a6)+,$3F(a0)
                clr.b   $3A(a0)
                lea     $40(a0),a0
                dbf     d0,Level_SpawnObjects_ChickLoop

Level_SpawnObjects_SecondChickGroup:
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   Level_SpawnObjects_Return
                add.b   d0,(Ram_ChicksRemaining).w
                subq.b  #1,d0

Level_SpawnObjects_SecondChickLoop:
                move.w  #8,(a0)
                move.b  (a6)+,$3E(a0)
                move.b  (a6)+,$3F(a0)
                move.b  #1,$3A(a0)
                lea     $40(a0),a0
                dbf     d0,Level_SpawnObjects_SecondChickLoop

Level_SpawnObjects_Return:
                rts

; Spawns background objects from position list at (a6)
Level_SpawnBackgroundLoop:
                moveq   #0,d7
                moveq   #0,d6
                move.b  (a6)+,d7
                move.b  (a6)+,d6
                movem.l d0/d4/a6,-(sp)
                bsr.w   Level_DrawBackgroundObject
                movem.l (sp)+,d0/d4/a6
                dbf     d0,Level_SpawnBackgroundLoop
                rts

; Gets collision tile value at world position d7/d6
Collision_GetTileAtPos:
                movem.l d6-d7/a1,-(sp)
                cmpi.w  #$80,d7
                bge.s   Collision_GetTileAtPos_WrapHigh
                addi.w  #$100,d7

Collision_GetTileAtPos_WrapHigh:
                cmpi.w  #$180,d7
                blt.s   Collision_GetTileAtPos_Lookup
                subi.w  #$100,d7

Collision_GetTileAtPos_Lookup:
                lea     (Ram_CollisionMap).w,a1
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
                add.w   $30(a0),d7
                add.w   $24(a0),d6
                cmpi.w  #$80,d7
                bge.s   Collision_GetTileAtObject_WrapHigh
                addi.w  #$100,d7

Collision_GetTileAtObject_WrapHigh:
                cmpi.w  #$180,d7
                blt.s   Collision_GetTileAtObject_Lookup
                subi.w  #$100,d7

Collision_GetTileAtObject_Lookup:
                movem.l d6-d7,-(sp)
                lea     (Ram_CollisionMap).w,a1
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
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   Collision_SetSpecialTiles_Flag76
                subq.w  #1,d0

Collision_SetSpecialTiles_Flag7Loop:
                moveq   #0,d7
                moveq   #0,d6
                lea     (Ram_CollisionMap).w,a0
                move.b  (a6)+,d7
                move.b  (a6)+,d6
                adda.l  d7,a0
                lsl.w   #5,d6
                adda.l  d6,a0
                bset    #7,(a0)
                dbf     d0,Collision_SetSpecialTiles_Flag7Loop

Collision_SetSpecialTiles_Flag76:
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   Collision_SetSpecialTiles_Flag5
                subq.w  #1,d0

Collision_SetSpecialTiles_Flag76Loop:
                moveq   #0,d7
                moveq   #0,d6
                lea     (Ram_CollisionMap).w,a0
                move.b  (a6)+,d7
                move.b  (a6)+,d6
                adda.l  d7,a0
                lsl.w   #5,d6
                adda.l  d6,a0
                bset    #7,(a0)
                bset    #6,(a0)
                dbf     d0,Collision_SetSpecialTiles_Flag76Loop

Collision_SetSpecialTiles_Flag5:
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   Collision_SetSpecialTiles_Return
                subq.w  #1,d0

Collision_SetSpecialTiles_Flag5Loop:
                moveq   #0,d7
                moveq   #0,d6
                lea     (Ram_CollisionMap).w,a0
                move.b  (a6)+,d7
                move.b  (a6)+,d6
                adda.l  d7,a0
                lsl.w   #5,d6
                adda.l  d6,a0
                bset    #5,(a0)
                dbf     d0,Collision_SetSpecialTiles_Flag5Loop

Collision_SetSpecialTiles_Return:
                rts

; Converts grid coords to screen pixels (x8 + $80)
