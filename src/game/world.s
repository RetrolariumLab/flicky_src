; Object framework, camera, collision map, and level lifecycle
; ROM $01105C-$011673
Object_UpdatePosition:
                btst    #0,2(a0)
                bne.s   Object_UpdatePosition_Return
                move.l  $34(a0),d1
                move.l  $30(a0),d2
                add.l   d1,d2
                cmpi.l  #$800000,d2
                bge.s   Object_UpdatePosition_ClampHigh
                addi.l  #$1000000,d2

Object_UpdatePosition_ClampHigh:
                cmpi.l  #$1800000,d2
                blt.s   Object_UpdatePosition_StoreWorldX
                subi.l  #$1000000,d2

Object_UpdatePosition_StoreWorldX:
                move.l  d2,$30(a0)
                swap    d2
                sub.w   (Ram_CameraX).w,d2

Object_UpdatePosition_WrapLow:
                cmpi.w  #$80,d2
                bge.s   Object_UpdatePosition_WrapHigh
                addi.w  #$100,d2
                bra.s   Object_UpdatePosition_WrapLow

Object_UpdatePosition_WrapHigh:
                cmpi.w  #$180,d2
                blt.s   Object_UpdatePosition_StoreScreenPos
                subi.w  #$100,d2
                bra.s   Object_UpdatePosition_WrapHigh

Object_UpdatePosition_StoreScreenPos:
                move.w  d2,$20(a0)
                move.l  $2C(a0),d3
                add.l   d3,$24(a0)

Object_UpdatePosition_Return:
                rts

; Calculates screen position from world pos minus camera
Object_CalcScreenPos:
                move.l  $30(a0),d2
                sub.l   (Ram_CameraX).w,d2

Object_CalcScreenPos_WrapLow:
                cmpi.l  #$800000,d2
                bge.s   Object_CalcScreenPos_WrapHigh
                addi.l  #$1000000,d2
                bra.s   Object_CalcScreenPos_WrapLow

Object_CalcScreenPos_WrapHigh:
                cmpi.l  #$1800000,d2
                blt.s   Object_CalcScreenPos_Store
                subi.l  #$1000000,d2
                bra.s   Object_CalcScreenPos_WrapHigh

Object_CalcScreenPos_Store:
                move.l  d2,$20(a0)
                move.l  $2C(a0),d3
                add.l   d3,$24(a0)
                rts

; Clears single 64-byte object slot at a0
Object_ClearSlot:
                movea.w a0,a6
                moveq   #$F,d7
                moveq   #0,d6

Object_ClearSlot_Loop:
                move.l  d6,(a6)+
                dbf     d7,Object_ClearSlot_Loop
                rts

; Clears all 32 object slots starting at FFC000
Object_ClearAllSlots:
                movem.l d5/a0,-(sp)
                move.w  #$1F,d5
                lea     (Ram_ObjectSlots).w,a0

Object_ClearAllSlots_Loop:
                bsr.s   Object_ClearSlot
                movea.w a6,a0
                dbf     d5,Object_ClearAllSlots_Loop
                movem.l (sp)+,d5/a0
                rts

; Clears sprite link chain (31 entries)
Sprite_ClearLinkTable:
                movea.w a0,a6
                moveq   #$1E,d7
                moveq   #0,d6

Sprite_ClearLinkTable_Loop:
                move.w  d6,(a6)+
                dbf     d7,Sprite_ClearLinkTable_Loop
                rts

; Updates animation timer and advances frame index
Anim_UpdateFrame:
                move.w  6(a0),d0
                movea.l 8(a0),a1
                movea.l (a1,d0.w),a1
                subq.b  #1,$11(a0)
                bpl.s   Anim_UpdateFrame_CheckWrap
                move.b  1(a1),$11(a0)
                addq.b  #1,$10(a0)

Anim_UpdateFrame_CheckWrap:
                moveq   #0,d0
                move.b  $10(a0),d0
                cmp.b   (a1),d0
                bcs.s   Anim_UpdateFrame_StoreMapping
                clr.b   $10(a0)
                moveq   #0,d0
                bset    #2,2(a0)

Anim_UpdateFrame_StoreMapping:
                lsl.w   #1,d0
                moveq   #$FFFFFFFF,d1
                move.w  2(a1,d0.w),d1
                move.l  d1,$C(a0)
                rts

; Renders object sprite to sprite table from mappings
Sprite_RenderObject:
                btst    #1,2(a0)
                beq.s   Sprite_RenderObject_Build
                rts

Sprite_RenderObject_Build:
                movea.l $C(a0),a1
                moveq   #0,d1
                move.b  (a1)+,d1
                move.b  (a1)+,4(a0)
                move.w  $24(a0),d2
                cmpi.w  #$180,d2
                bhi.s   Sprite_RenderObject_Return
                move.w  $20(a0),d3

Sprite_RenderObject_PieceLoop:
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
                bpl.s   Sprite_RenderObject_ApplyX
                bchg    #3,-2(a2)
                move.b  (a1),d0

Sprite_RenderObject_ApplyX:
                addq.w  #1,a1
                ext.w   d0
                add.w   d3,d0
                move.w  d0,d4
                subi.w  #$41,d4
                cmpi.w  #$17F,d4
                bcs.s   Sprite_RenderObject_EmitPiece
                subq.w  #6,a2
                dbf     d1,Sprite_RenderObject_PieceLoop
                rts

Sprite_RenderObject_EmitPiece:
                move.w  d0,(a2)+
                addq.b  #1,d6
                dbf     d1,Sprite_RenderObject_PieceLoop

Sprite_RenderObject_Return:
                rts

; Updates main object slot and builds sprite list
Object_UpdateMain:
                lea     (Ram_ObjectSlots).w,a0
                bsr.w   Object_CallHandler
                bsr.w   Sprite_BuildTable
                rts

; Updates all active objects and builds sprite table
Object_UpdateAll:
                tst.b   (Ram_BonusRoundFlag).w
                bne.s   Object_UpdateAll_BonusMode
                lea     (Ram_PlayerObject).w,a0
                bsr.w   Object_CallHandler
                lea     (Ram_SpawnerSlots).w,a0
                moveq   #8,d0

Object_UpdateAll_EnemyLoop:
                bsr.w   Object_CallHandler
                lea     $40(a0),a0
                dbf     d0,Object_UpdateAll_EnemyLoop
                lea     (Ram_ChickSlots).w,a0
                moveq   #$D,d0

Object_UpdateAll_ChickLoop:
                bsr.w   Object_CallHandler
                lea     $40(a0),a0
                dbf     d0,Object_UpdateAll_ChickLoop
                lea     (Ram_ObjectSlots).w,a0
                moveq   #7,d0

Object_UpdateAll_MainLoop:
                bsr.w   Object_CallHandler
                lea     $40(a0),a0
                dbf     d0,Object_UpdateAll_MainLoop
                bra.s   Sprite_BuildTable

Object_UpdateAll_BonusMode:
                lea     (Ram_BonusPlayerObject).w,a0
                bsr.w   Object_CallHandler
                lea     (Ram_Object01).w,a0
                moveq   #$14,d0

Object_UpdateAll_BonusLoop:
                bsr.w   Object_CallHandler
                lea     $40(a0),a0
                dbf     d0,Object_UpdateAll_BonusLoop
                lea     (Ram_BonusCatInnerSlots).w,a0
                moveq   #3,d0

Object_UpdateAll_BonusExtraLoop:
                bsr.w   Object_CallHandler
                lea     $40(a0),a0
                dbf     d0,Object_UpdateAll_BonusExtraLoop

Sprite_BuildTable:
                move.w  #$F550,(Ram_SpriteTableCursor).w
                move.w  #1,(Ram_SpriteLinkCounter).w
                lea     (Ram_ObjectSlots).w,a0
                moveq   #$1F,d7

Sprite_BuildTable_SlotLoop:
                move.w  d7,-(sp)
                tst.w   (a0)
                beq.s   Sprite_BuildTable_NextSlot
                movea.w (Ram_SpriteTableCursor).w,a2
                move.w  (Ram_SpriteLinkCounter).w,d6
                bsr.w   Sprite_RenderObject
                move.w  d6,(Ram_SpriteLinkCounter).w
                move.w  a2,(Ram_SpriteTableCursor).w

Sprite_BuildTable_NextSlot:
                lea     $40(a0),a0
                move.w  (sp)+,d7
                dbf     d7,Sprite_BuildTable_SlotLoop
                movea.w (Ram_SpriteTableCursor).w,a2
                cmpa.w  #$F550,a2
                beq.s   Sprite_BuildTable_Empty
                clr.b   -5(a2)
                rts

Sprite_BuildTable_Empty:
                clr.l   (a2)

Object_NullHandler:
                rts

; Dispatches to object type handler via jump table
Object_CallHandler:
                move.w  d0,-(sp)
                move.w  (a0),d0
                beq.s   Object_CallHandler_Return
                andi.w  #$7FFC,d0
                jsr     Object_HandlerTable(pc,d0.w)

Object_CallHandler_Return:
                move.w  (sp)+,d0
                rts

Object_HandlerTable:
                bra.w   Object_NullHandler
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
Camera_UpdateScroll:
                move.l  (Ram_CameraVelocityX).w,d0
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
                lea     (VDP_CTRL).l,a6
                lea     (VDP_DATA).l,a5
                move.w  (Ram_CameraX).w,d7
                neg.w   d7
                move.w  #$8F20,(a6)
                move.l  #$78400002,(VDP_CTRL).l
                moveq   #$17,d0

Gfx_UpdateScrollRegs_HScrollLoop:
                move.w  d7,(a5)
                dbf     d0,Gfx_UpdateScrollRegs_HScrollLoop
                move.l  #$78020002,(VDP_CTRL).l
                moveq   #$1B,d0

Gfx_UpdateScrollRegs_VScrollLoop:
                move.w  d7,(a5)
                dbf     d0,Gfx_UpdateScrollRegs_VScrollLoop
                move.w  #$8F02,(a6)
                move.w  (Ram_CameraY).w,d7
                move.l  #$40000010,(VDP_CTRL).l
                move.w  d7,(a5)
                rts

; Animation timer countdown with frame advance and wrap
Anim_ProcessTimer:
                subq.b  #1,1(a0)
                bpl.s   Anim_ProcessTimer_CheckWrap
                move.b  1(a1),1(a0)
                addq.b  #1,0.w(a0)

Anim_ProcessTimer_CheckWrap:
                moveq   #0,d0
                move.b  0.w(a0),d0
                cmp.b   (a1),d0
                bcs.s   Anim_ProcessTimer_DrawFrame
                clr.b   0.w(a0)
                moveq   #0,d0
                move.b  #1,2(a0)

Anim_ProcessTimer_DrawFrame:
                asl.w   #2,d0
                movea.l 2(a1,d0.w),a6
                bsr.w   Gfx_DrawTilemapRect
                rts

; Clears 896-byte collision map at FFC800
Collision_ClearMap:
                lea     (Ram_CollisionMap).w,a0
                move.w  #$DF,d0

Collision_ClearMap_Loop:
                clr.l   (a0)+
                dbf     d0,Collision_ClearMap_Loop
                rts

; Clears camera position and velocity variables
Camera_ClearScroll:
                clr.l   (Ram_CameraX).w
                clr.l   (Ram_CameraY).w
                clr.l   (Ram_CameraVelocityX).w
                clr.l   (Ram_CameraVelocityY).w
                rts

; Sets collision value d4 at map position d6/d7
Collision_SetTile:
                movem.w d4/d6-d7/a6,-(sp)
                lea     (Ram_CollisionMap).w,a6
                lsl.w   #5,d6
                add.w   d7,d6
                move.b  d4,(a6,d6.w)
                movem.w (sp)+,d4/d6-d7/a6
                rts

; Loads collision map from compressed data at (a6)
Collision_LoadMap:
                bsr.s   Collision_ClearMap
                lea     (Ram_CollisionMapRow1).w,a0

Collision_LoadMap_NextRun:
                moveq   #0,d7
                move.b  (a6)+,d7
                beq.s   Collision_LoadMap_Return
                bclr    #7,d7
                bne.s   Collision_LoadMap_CheckOrientation
                adda.l  d7,a0
                bra.s   Collision_LoadMap_NextRun

Collision_LoadMap_Return:
                rts

Collision_LoadMap_CheckOrientation:
                bclr    #6,d7
                bne.s   Collision_LoadMap_VerticalSetup
                subq.b  #1,d7

Collision_LoadMap_HorizontalLoop:
                move.b  #1,(a0)+
                dbf     d7,Collision_LoadMap_HorizontalLoop
                bra.s   Collision_LoadMap_NextRun

Collision_LoadMap_VerticalSetup:
                movea.w a0,a1
                subq.b  #1,d7

Collision_LoadMap_VerticalLoop:
                move.b  #1,(a1)
                lea     $20(a1),a1
                dbf     d7,Collision_LoadMap_VerticalLoop
                addq.l  #1,a0
                bra.s   Collision_LoadMap_NextRun

; Master level init: collision, objects, player, enemies
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
