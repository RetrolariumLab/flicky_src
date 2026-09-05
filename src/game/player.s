; Player object.
; ROM $013E70-$0144DB.

Obj_Player:
                bset    #7,(a0)  ; was: sub_13E70
                bne.s   loc_13EA0
                move.l  #off_144AC,8(a0)
                move.b  $3E(a0),d7
                move.b  $3F(a0),d6
                bsr.w Math_GridToScreen
                addi.w  #$C,d7
                addi.w  #$18,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)
                move.b  #3,$3A(a0)

loc_13EA0:
                tst.b   (byte_FFD27B).w
                bne.s   locret_13EDC
                tst.b   (byte_FFD24F).w
                bne.s   loc_13EB6
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     loc_13EDE(pc,d0.w)

loc_13EB6:
                move.w  $3C(a0),d0
                andi.w  #$7C,d0
                cmpi.w  #4,d0
                bcc.s   loc_13ECE
                tst.b   (byte_FFD24F).w
                bne.s   loc_13ECE
                bsr.w Player_CheckProjectileHit

loc_13ECE:
                bsr.w Player_RecordHistory
                tst.b   (byte_FFD24E).w
                bne.s   locret_13EDC
                bsr.w UI_AnimateEntryArrow

locret_13EDC:
                rts

loc_13EDE:
                bra.w Player_StateNormal
                bra.w Player_StateDeath
                bra.w Player_StateRespawn

; Player state: normal walking/running gameplay
Player_StateNormal:
                move.b  #$1E,5(a0)  ; was: sub_13EEA
                bsr.s Player_ProcessInput
                bsr.w Player_CheckExit
                tst.b   (byte_FFD24F).w
                bne.s   loc_13F00
                bsr.w Camera_UpdateScroll

loc_13F00:
                bsr.w Object_UpdatePosition
                bsr.w Player_CheckGround
                bsr.w Player_CheckWalls
                bsr.w Player_UpdateAnim
                move.l  $34(a0),d0
                beq.s   locret_13F24
                move.b  #1,$39(a0)
                tst.l   d0
                bmi.s   locret_13F24
                clr.b   $39(a0)

locret_13F24:
                rts

; Player input processing: joypad to velocity
Player_ProcessInput:
                move.b  (word_FFFF8E).w,d0  ; was: sub_13F26
                andi.b  #$C,d0
                beq.w   loc_13FAA
                btst    #3,d0
                bne.w   loc_13FCE
                btst    #2,d0
                bne.w   loc_13FEC

loc_13F42:
                move.l  $30(a0),d2
                move.l  d1,$34(a0)
                tst.b   (byte_FFD24E).w
                bne.s   loc_13F54
                move.l  d1,(dword_FFD004).w

loc_13F54:
                bsr.w Player_ThrowChick
                tst.b   $38(a0)
                bne.w   loc_1400A
                btst    #0,$3A(a0)
                beq.s   loc_13F98
                move.b  (word_FFFF8E).w,d0
                andi.b  #$70,d0
                beq.s   loc_13F98
                move.l  a0,-(sp)
                move.b  #$91,d0
                bsr.w Sound_PlayNoteIfActive
                movea.l (sp)+,a0
                move.b  #1,$38(a0)
                move.l  #$FFFD7000,$2C(a0)
                bclr    #0,$3A(a0)
                bclr    #1,$3A(a0)

loc_13F98:
                move.b  (word_FFFF8E).w,d0
                andi.b  #$70,d0
                bne.s   locret_13FA8
                move.b  #3,$3A(a0)

locret_13FA8:
                rts

loc_13FAA:
                move.l  $34(a0),d1
                tst.b   $38(a0)
                bne.s   loc_13F42
                tst.l   d1
                beq.s   loc_13FCA
                tst.l   d1
                bmi.s   loc_13FC4
                subi.l  #$600,d1
                bra.s   loc_13FCA

loc_13FC4:
                addi.l  #$600,d1

loc_13FCA:
                bra.w   loc_13F42

loc_13FCE:
                move.l  $34(a0),d1
                cmpi.l  #$18000,d1
                bge.s   loc_13FE2
                addi.l  #$1800,d1
                bra.s   loc_13FE8

loc_13FE2:
                move.l  #$18000,d1

loc_13FE8:
                bra.w   loc_13F42

loc_13FEC:
                move.l  $34(a0),d1
                cmpi.l  #$FFFE8000,d1
                ble.s   loc_14000
                subi.l  #$1800,d1
                bra.s   loc_14006

loc_14000:
                move.l  #$FFFE8000,d1

loc_14006:
                bra.w   loc_13F42

loc_1400A:
                cmpi.l  #$30000,$2C(a0)
                bge.s   loc_1401C
                addi.l  #$1000,$2C(a0)

loc_1401C:
                move.b  (word_FFFF8E).w,d0
                andi.b  #$70,d0
                bne.s   locret_1402C
                move.b  #3,$3A(a0)

locret_1402C:
                rts

; Clears player airborne/jump state
Player_ClearAirState:
                clr.b   $38(a0)  ; was: sub_1402E
                clr.l   $2C(a0)
                rts

; Player throws held chick when button pressed
Player_ThrowChick:
                btst    #1,$3A(a0)  ; was: sub_14038
                beq.s   locret_1407C
                move.b  (word_FFFF8E).w,d0
                andi.b  #$70,d0
                beq.s   locret_1407C
                tst.b   $3B(a0)
                beq.s   locret_1407C
                movea.l (dword_FFD250).w,a1
                move.w  #4,$34(a1)
                tst.b   $39(a0)
                beq.s   loc_14066
                move.w  #$FFFC,$34(a1)

loc_14066:
                move.w  #8,$3C(a1)
                move.l  $30(a0),$30(a1)
                clr.b   $3B(a0)
                bclr    #1,$3A(a0)

locret_1407C:
                rts

; Player ground check: standing on solid
Player_CheckGround:
                move.w  $30(a0),d7  ; was: sub_1407E
                move.w  $24(a0),d6
                tst.b   $38(a0)
                bne.s   loc_1409E
                addq.w  #1,d6
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                bne.s   locret_1409C
                move.b  #1,$38(a0)

locret_1409C:
                rts

loc_1409E:
                tst.l   $34(a0)
                bne.s   loc_140DA
                tst.l   $2C(a0)
                bpl.s   loc_140BC
                subi.w  #$E,d6
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                beq.s   locret_140BA
                clr.l   $2C(a0)

locret_140BA:
                rts

loc_140BC:
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                beq.s   locret_140D8
                clr.b   $38(a0)
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)

locret_140D8:
                rts

loc_140DA:
                tst.l   $2C(a0)
                bpl.s   loc_140FE
                subi.w  #$E,d6
                addq.w  #4,d7
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                bne.s   loc_140F8
                subq.w  #8,d7
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                beq.s   locret_140FC

loc_140F8:
                clr.l   $2C(a0)

locret_140FC:
                rts

loc_140FE:
                subq.w  #4,d7
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                bne.s   loc_14112
                addq.w  #8,d7
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                beq.s   locret_14126

loc_14112:
                clr.b   $38(a0)
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)

locret_14126:
                rts

; Player wall collision: left/right walls
Player_CheckWalls:
                move.w  $30(a0),d7  ; was: sub_14128
                move.w  $24(a0),d6
                move.l  $34(a0),d5
                tst.b   $38(a0)
                bne.s   loc_1419A
                subi.w  #$A,d6
                tst.l   d5
                beq.s   locret_1416E
                tst.l   d5
                bpl.s   loc_14170
                subq.w  #6,d7
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                beq.s   locret_1416E
                move.l  $34(a0),d0
                subi.l  #$3000,d0
                cmpi.l  #$FFFE0200,d0
                bge.s   loc_14168
                move.l  #$FFFE0200,d0

loc_14168:
                neg.l   d0
                move.l  d0,$34(a0)

locret_1416E:
                rts

loc_14170:
                addq.w  #6,d7
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                beq.s   locret_14198
                move.l  $34(a0),d0
                addi.l  #$3000,d0
                cmpi.l  #$1FE00,d0
                ble.s   loc_14192
                move.l  #$1FE00,d0

loc_14192:
                neg.l   d0
                move.l  d0,$34(a0)

locret_14198:
                rts

loc_1419A:
                subq.w  #8,d6
                tst.l   d5
                beq.w   loc_14248
                tst.l   d5
                bpl.s   loc_141DC
                subq.w  #6,d7
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                beq.s   locret_141DA
                btst    #1,d4
                bne.s   loc_141BC
                btst    #0,d4
                beq.s   loc_14212

loc_141BC:
                move.l  $34(a0),d0
                subi.l  #$3000,d0
                cmpi.l  #$FFFE0200,d0
                bge.s   loc_141D4
                move.l  #$FFFE0200,d0

loc_141D4:
                neg.l   d0
                move.l  d0,$34(a0)

locret_141DA:
                rts

loc_141DC:
                addq.w  #6,d7
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                beq.s   locret_14210
                btst    #1,d4
                bne.s   loc_141F2
                btst    #0,d4
                beq.s   loc_14212

loc_141F2:
                move.l  $34(a0),d0
                addi.l  #$3000,d0
                cmpi.l  #$1FE00,d0
                ble.s   loc_1420A
                move.l  #$1FE00,d0

loc_1420A:
                neg.l   d0
                move.l  d0,$34(a0)

locret_14210:
                rts

loc_14212:
                tst.l   $2C(a0)
                bpl.s   loc_14232
                move.w  d6,d0
                andi.w  #7,d0
                cmpi.w  #3,d0
                blt.s   locret_14230
                addi.w  #$10,d6
                move.w  d6,$24(a0)
                clr.l   $2C(a0)

locret_14230:
                rts

loc_14232:
                andi.w  #$FFF8,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                clr.l   $2C(a0)
                clr.b   $38(a0)
                rts

loc_14248:
                addq.w  #6,d7
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                beq.s   loc_1425C
                move.l  #$FFFF4000,$34(a0)
                bra.s   locret_14270

loc_1425C:
                subi.w  #$C,d7
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                beq.s   locret_14270
                move.l  #$C000,$34(a0)

locret_14270:
                rts

; Records player position history for chicks
Player_RecordHistory:
                lea     (unk_FFD206).w,a2  ; was: sub_14272
                lea     (unk_FFD1FE).w,a1
                lea     (unk_FFD20A).w,a4
                lea     (unk_FFD202).w,a3
                moveq   #$3F,d0

loc_14284:
                move.l  (a1),(a2)
                move.l  (a3),(a4)
                subq.l  #8,a1
                subq.l  #8,a2
                subq.l  #8,a3
                subq.l  #8,a4
                dbf     d0,loc_14284
                lea     (byte_FFD24E).w,a2
                lea     (unk_FFD24D).w,a1
                moveq   #$3F,d0

loc_1429E:
                move.b  -(a1),-(a2)
                dbf     d0,loc_1429E
                move.l  $30(a0),(dword_FFD00E).w
                move.l  $24(a0),(dword_FFD012).w
                moveq   #0,d0
                tst.b   $38(a0)
                beq.s   loc_142BC
                bset    #7,d0

loc_142BC:
                move.l  $34(a0),d7
                beq.s   loc_142D0
                tst.l   d7
                bpl.s   loc_142CC
                bset    #1,d0
                bra.s   loc_142D0

loc_142CC:
                bset    #0,d0

loc_142D0:
                move.b  d0,(byte_FFD20E).w
                rts

; Player checks if entered exit door
Player_CheckExit:
                tst.b   (byte_FFD27A).w  ; was: sub_142D6
                beq.s   locret_14316
                tst.b   $38(a0)
                bne.s   locret_14316
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                cmp.w   (word_FFD25C).w,d6
                bne.s   locret_14316
                cmp.w   (word_FFD25E).w,d7
                blt.s   locret_14316
                cmp.w   (word_FFD260).w,d7
                bgt.s   locret_14316
                move.b  #1,(byte_FFD24F).w
                clr.l   $34(a0)
                clr.l   (dword_FFD004).w
                addq.b  #1,(byte_FFD88D).w
                move.l  a0,-(sp)
                bsr.w UI_AnimateCatCountReverse
                movea.l (sp)+,a0

locret_14316:
                rts

; Player animation based on movement state
Player_UpdateAnim:
                bclr    #7,2(a0)  ; was: sub_14318
                move.l  $34(a0),d0
                move.b  (word_FFFF8E).w,d1
                tst.b   $38(a0)
                bne.s   loc_14366
                tst.l   d0
                beq.s   loc_1435C
                tst.l   d0
                bpl.s   loc_14342
                bset    #7,2(a0)
                btst    #2,d1
                bne.s   loc_14352
                bra.s   loc_14348

loc_14342:
                btst    #3,d1
                bne.s   loc_14352

loc_14348:
                move.l  #word_1A8A0,$C(a0)
                rts

loc_14352:
                clr.w   6(a0)
                bsr.w Anim_UpdateFrame
                rts

loc_1435C:
                move.l  #word_1A898,$C(a0)
                rts

loc_14366:
                tst.l   d0
                beq.s   loc_14380
                move.w  #8,6(a0)
                tst.l   d0
                bpl.s   loc_1437A
                bset    #7,2(a0)

loc_1437A:
                bsr.w Anim_UpdateFrame
                rts

loc_14380:
                move.w  #4,6(a0)
                bsr.w Anim_UpdateFrame
                rts

; Player state: death falling animation
Player_StateDeath:
                bset    #7,$3C(a0)  ; was: sub_1438C
                bne.s   loc_143AE
                move.l  a0,-(sp)
                move.b  #$87,d0
                jsr     unk_FFFB66
                movea.l (sp)+,a0
                clr.b   5(a0)
                clr.l   $34(a0)
                move.w  #$C,6(a0)

loc_143AE:
                addi.l  #$1000,$2C(a0)
                bsr.w Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                bne.s   loc_143E4
                tst.l   $2C(a0)
                bpl.s   loc_143DE
                subq.w  #8,d6
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                beq.s   loc_143DE
                clr.l   $2C(a0)

loc_143DE:
                bsr.w Anim_UpdateFrame
                rts

loc_143E4:
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)
                move.w  #8,$3C(a0)
                rts

; Player state: respawn with invincibility
Player_StateRespawn:
                bset    #7,$3C(a0)  ; was: sub_143FC
                bne.s   loc_14418
                clr.b   5(a0)
                clr.b   $10(a0)
                bclr    #2,2(a0)
                move.b  #3,$39(a0)

loc_14418:
                bsr.w Object_UpdatePosition
                bsr.w Anim_UpdateFrame
                bclr    #2,2(a0)
                beq.s   loc_14430
                subq.b  #1,$39(a0)
                bsr.w Enemy_ClearProjectiles

loc_14430:
                tst.b   $39(a0)
                bne.s   locret_14462
                subq.b  #1,(byte_FFD882).w
                beq.s   loc_1445C
                move.b  #1,(byte_FFD886).w
                bsr.w Enemy_BackupToBuffer
                move.w  #$20,(word_FFFFC0).w
                moveq   #$3C,d2

loc_1444E:
                bsr.w Timer_IncrementTime
                jsr     unk_FFFB6C
                dbf     d2,loc_1444E
                bra.s   locret_14462

loc_1445C:
                move.w  #$10,(word_FFD2A0).w

locret_14462:
                rts

; Clears enemy projectile object slots
Enemy_ClearProjectiles:
                lea     (unk_FFC380).w,a1  ; was: sub_14464
                moveq   #2,d0

loc_1446A:
                clr.w   (a1)
                lea     $40(a1),a1
                dbf     d0,loc_1446A
                rts

; Checks player collision with projectiles
Player_CheckProjectileHit:
                lea     (unk_FFC380).w,a1  ; was: sub_14476
                moveq   #2,d1

loc_1447C:
                btst    #0,5(a1)
                beq.s   loc_144A2
                movem.w d1,-(sp)
                bsr.w Collision_CheckObjectPair
                movem.w (sp)+,d1
                tst.b   d0
                beq.s   loc_144A2
                move.w  #4,$3C(a0)
                move.b  #1,(byte_FFD26D).w
                bra.s   locret_144AA

loc_144A2:
                lea     $40(a1),a1
                dbf     d1,loc_1447C

locret_144AA:
                rts

off_144AC:      dc.l byte_144BC
                dc.l byte_144C2
                dc.l byte_144C8
                dc.l byte_144CE
byte_144BC:     dc.b 2, 2
                dc.w byte_1A8A8-Sys_GameEntryPoint
                dc.w byte_1A8B0-Sys_GameEntryPoint
byte_144C2:     dc.b 2, 2
                dc.w byte_1A8B8-Sys_GameEntryPoint
                dc.w byte_1A8C0-Sys_GameEntryPoint
byte_144C8:     dc.b 2, 2
                dc.w byte_1A8C8-Sys_GameEntryPoint
                dc.w word_1A8D0-Sys_GameEntryPoint
byte_144CE:     dc.b 6, 3
                dc.w word_1A878-Sys_GameEntryPoint
                dc.w word_1A880-Sys_GameEntryPoint
                dc.w byte_1A888-Sys_GameEntryPoint
                dc.w word_1A890-Sys_GameEntryPoint
                dc.w byte_1A888-Sys_GameEntryPoint
                dc.w word_1A890-Sys_GameEntryPoint
; Exit door object at level end
