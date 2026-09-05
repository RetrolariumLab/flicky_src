; Exit door and chick objects.
; ROM $0144DC-$01483D.

Obj_ExitDoor:
                bset    #7,(a0)  ; was: sub_144DC
                bne.s   loc_14504
                move.b  (byte_FFD834).w,d7
                move.b  (byte_FFD835).w,d6
                bsr.w Math_GridToScreen
                addq.w  #8,d7
                addi.w  #$18,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)
                move.l  #off_14524,8(a0)

loc_14504:
                move.w  $3C(a0),d0
                andi.w  #$7FFC,d0
                jsr     loc_14516(pc,d0.w)
                bsr.w Object_UpdatePosition
                rts

loc_14516:
                bra.w Obj_ExitDoorAnim
                bra.w Obj_ExitDoorIdle

; Exit door animation state
Obj_ExitDoorAnim:
                bsr.w Anim_UpdateFrame  ; was: sub_1451E

; Exit door idle state (shared RTS)
Obj_ExitDoorIdle:
                rts  ; was: nullsub_3

off_14524:      dc.l byte_14528
byte_14528:     dc.b 2, 8
                dc.w word_1AD82-Sys_GameEntryPoint
                dc.w word_1AD8A-Sys_GameEntryPoint
; Chick main object: collectable that follows player
Obj_Chick:
                bset    #7,(a0)  ; was: sub_1452E
                bne.s   loc_1455E
                move.l  (dword_FFD828).w,d0
                move.l  d0,$C(a0)
                move.b  #$60,$13(a0)
                moveq   #0,d7
                moveq   #0,d6
                move.b  $3E(a0),d7
                move.b  $3F(a0),d6
                bsr.w Math_GridToScreen
                addq.w  #8,d7
                addq.w  #8,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)

loc_1455E:
                tst.b   (byte_FFD27B).w
                bne.s   locret_1457A
                tst.b   (byte_FFD24F).w
                bne.s   locret_1457A
                tst.b   (byte_FFD26D).w
                bne.s   locret_1457A
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     loc_1457C(pc,d0.w)

locret_1457A:
                rts

loc_1457C:
                bra.w Chick_StateIdle
                bra.w Chick_StateFollowing
                bra.w Chick_StateThrown

; Chick state: idle waiting to be picked up
Chick_StateIdle:
                move.b  #1,5(a0)  ; was: sub_14588
                lea     (word_FFC440).w,a1
                tst.l   dword_FFC46C-word_FFC440(a1)
                bmi.s   loc_145B6
                bsr.w Collision_CheckObjectPair
                tst.b   d0
                beq.s   loc_145B6
                tst.b   $3B(a1)
                bne.s   loc_145B6
                move.w  #4,$3C(a0)
                move.b  #1,$3B(a1)
                move.l  a0,(dword_FFD250).w

loc_145B6:
                bsr.w Object_UpdatePosition
                rts

; Chick state: following player after pickup
Chick_StateFollowing:
                bset    #7,$3C(a0)  ; was: sub_145BC
                bne.s   loc_145D0
                move.l  a0,-(sp)
                move.b  #$92,d0
                bsr.w Sound_PlayNoteIfActive
                movea.l (sp)+,a0

loc_145D0:
                clr.b   5(a0)
                lea     (word_FFC440).w,a1
                move.l  dword_FFC470-word_FFC440(a1),d7
                move.l  $24(a1),d6
                tst.b   $38(a1)
                beq.s   loc_145EE
                addi.l  #$60000,d6
                bra.s   loc_14602

loc_145EE:
                tst.b   $39(a1)
                bne.s   loc_145FC
                addi.l  #$80000,d7
                bra.s   loc_14602

loc_145FC:
                subi.l  #$80000,d7

loc_14602:
                move.l  d7,$30(a0)
                move.l  d6,$24(a0)
                bsr.w Object_UpdatePosition
                rts

; Chick state: thrown and bouncing
Chick_StateThrown:
                bset    #7,$3C(a0)  ; was: sub_14610
                bne.s   loc_14650
                move.l  a0,-(sp)
                move.b  #$96,d0
                bsr.w Sound_PlayNoteIfActive
                movea.l (sp)+,a0
                move.b  #$18,5(a0)
                move.l  #off_14730,8(a0)
                clr.b   $3B(a0)
                moveq   #0,d0
                move.b  (word_FFD82C+1).w,d0

loc_1463C:
                cmpi.b  #$F,d0
                bls.s   loc_14648
                subi.b  #$F,d0
                bra.s   loc_1463C

loc_14648:
                subq.b  #1,d0
                lsl.w   #2,d0
                move.w  d0,6(a0)

loc_14650:
                bsr.w Chick_UpdatePhysics
                tst.l   $34(a0)
                bne.s   loc_1465C
                clr.w   (a0)

loc_1465C:
                bsr.w Chick_CheckOffscreen
                rts

; Chick checks if too far from player
Chick_CheckOffscreen:
                move.w  $20(a0),d7  ; was: sub_14662
                move.w  d7,d6
                lea     (word_FFC440).w,a1
                move.w  word_FFC460-word_FFC440(a1),d5
                move.w  d5,d4
                sub.w   d7,d5
                cmpi.w  #$7C,d5
                bge.s   loc_14684
                sub.w   d4,d6
                cmpi.w  #$7C,d6
                bge.s   loc_14684
                bra.s   locret_14686

loc_14684:
                clr.w   (a0)

locret_14686:
                rts

; Chick physics: movement and collision
Chick_UpdatePhysics:
                move.l  $34(a0),d7  ; was: sub_14688
                move.l  $2C(a0),d6
                bclr    #7,2(a0)
                tst.l   d7
                bpl.s   loc_146A0
                bset    #7,2(a0)

loc_146A0:
                bsr.w Anim_UpdateFrame
                tst.b   $38(a0)
                bne.s   loc_146BE
                tst.l   d7
                bpl.s   loc_146B6
                addi.l  #$800,d7
                bra.s   loc_146BC

loc_146B6:
                subi.l  #$800,d7

loc_146BC:
                bra.s   loc_146C4

loc_146BE:
                addi.l  #$1000,d6

loc_146C4:
                move.l  d7,$34(a0)
                move.l  d6,$2C(a0)
                bsr.w Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                addq.w  #1,d6
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                beq.s   loc_146FA
                clr.l   $2C(a0)
                clr.b   $38(a0)
                move.w  d6,d5
                andi.w  #$FFF8,d5
                move.w  d5,$24(a0)
                clr.w   $26(a0)
                bra.s   loc_14700

loc_146FA:
                move.b  #1,$38(a0)

loc_14700:
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subq.w  #4,d6
                tst.l   $34(a0)
                bpl.s   loc_14720
                subq.w  #4,d7
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                beq.s   locret_1471E
                neg.l   $34(a0)

locret_1471E:
                rts

loc_14720:
                addq.w  #4,d7
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                beq.s   locret_1472E
                neg.l   $34(a0)

locret_1472E:
                rts

off_14730:      dc.l byte_1476C
                dc.l byte_1477A
                dc.l byte_14788
                dc.l byte_14796
                dc.l byte_147A4
                dc.l byte_147B2
                dc.l byte_147C0
                dc.l byte_147CE
                dc.l byte_147DC
                dc.l byte_147EA
                dc.l byte_147F8
                dc.l byte_14806
                dc.l byte_14814
                dc.l byte_14822
                dc.l byte_14830
byte_1476C:     dc.b 6, 1
                dc.w word_1A4E8-Sys_GameEntryPoint
                dc.w word_1A4F8-Sys_GameEntryPoint
                dc.w word_1A508-Sys_GameEntryPoint
                dc.w word_1A4F0-Sys_GameEntryPoint
                dc.w word_1A510-Sys_GameEntryPoint
                dc.w word_1A500-Sys_GameEntryPoint
byte_1477A:     dc.b 6, 1
                dc.w word_1A518-Sys_GameEntryPoint
                dc.w word_1A528-Sys_GameEntryPoint
                dc.w word_1A538-Sys_GameEntryPoint
                dc.w word_1A520-Sys_GameEntryPoint
                dc.w word_1A540-Sys_GameEntryPoint
                dc.w word_1A530-Sys_GameEntryPoint
byte_14788:     dc.b 6, 1
                dc.w word_1A548-Sys_GameEntryPoint
                dc.w word_1A558-Sys_GameEntryPoint
                dc.w word_1A568-Sys_GameEntryPoint
                dc.w word_1A550-Sys_GameEntryPoint
                dc.w word_1A570-Sys_GameEntryPoint
                dc.w word_1A560-Sys_GameEntryPoint
byte_14796:     dc.b 6, 1
                dc.w word_1A578-Sys_GameEntryPoint
                dc.w word_1A588-Sys_GameEntryPoint
                dc.w word_1A598-Sys_GameEntryPoint
                dc.w word_1A580-Sys_GameEntryPoint
                dc.w word_1A5A0-Sys_GameEntryPoint
                dc.w word_1A590-Sys_GameEntryPoint
byte_147A4:     dc.b 6, 1
                dc.w word_1A5A8-Sys_GameEntryPoint
                dc.w word_1A5B8-Sys_GameEntryPoint
                dc.w word_1A5C8-Sys_GameEntryPoint
                dc.w word_1A5B0-Sys_GameEntryPoint
                dc.w word_1A5D0-Sys_GameEntryPoint
                dc.w word_1A5C0-Sys_GameEntryPoint
byte_147B2:     dc.b 6, 1
                dc.w word_1A5D8-Sys_GameEntryPoint
                dc.w word_1A5E8-Sys_GameEntryPoint
                dc.w word_1A5F8-Sys_GameEntryPoint
                dc.w word_1A5E0-Sys_GameEntryPoint
                dc.w word_1A600-Sys_GameEntryPoint
                dc.w word_1A5F0-Sys_GameEntryPoint
byte_147C0:     dc.b 6, 1
                dc.w word_1A608-Sys_GameEntryPoint
                dc.w word_1A618-Sys_GameEntryPoint
                dc.w word_1A628-Sys_GameEntryPoint
                dc.w word_1A610-Sys_GameEntryPoint
                dc.w word_1A630-Sys_GameEntryPoint
                dc.w word_1A620-Sys_GameEntryPoint
byte_147CE:     dc.b 6, 1
                dc.w word_1A638-Sys_GameEntryPoint
                dc.w word_1A648-Sys_GameEntryPoint
                dc.w word_1A658-Sys_GameEntryPoint
                dc.w word_1A640-Sys_GameEntryPoint
                dc.w word_1A660-Sys_GameEntryPoint
                dc.w word_1A650-Sys_GameEntryPoint
byte_147DC:     dc.b 6, 1
                dc.w word_1A668-Sys_GameEntryPoint
                dc.w word_1A678-Sys_GameEntryPoint
                dc.w word_1A688-Sys_GameEntryPoint
                dc.w word_1A670-Sys_GameEntryPoint
                dc.w word_1A690-Sys_GameEntryPoint
                dc.w word_1A680-Sys_GameEntryPoint
byte_147EA:     dc.b 6, 1
                dc.w word_1A698-Sys_GameEntryPoint
                dc.w word_1A6A8-Sys_GameEntryPoint
                dc.w word_1A6B8-Sys_GameEntryPoint
                dc.w word_1A6A0-Sys_GameEntryPoint
                dc.w word_1A6C0-Sys_GameEntryPoint
                dc.w word_1A6B0-Sys_GameEntryPoint
byte_147F8:     dc.b 6, 1
                dc.w word_1A6C8-Sys_GameEntryPoint
                dc.w word_1A6D8-Sys_GameEntryPoint
                dc.w word_1A6E8-Sys_GameEntryPoint
                dc.w word_1A6D0-Sys_GameEntryPoint
                dc.w word_1A6F0-Sys_GameEntryPoint
                dc.w word_1A6E0-Sys_GameEntryPoint
byte_14806:     dc.b 6, 1
                dc.w word_1A6F8-Sys_GameEntryPoint
                dc.w word_1A708-Sys_GameEntryPoint
                dc.w word_1A718-Sys_GameEntryPoint
                dc.w word_1A700-Sys_GameEntryPoint
                dc.w word_1A720-Sys_GameEntryPoint
                dc.w word_1A710-Sys_GameEntryPoint
byte_14814:     dc.b 6, 1
                dc.w word_1A728-Sys_GameEntryPoint
                dc.w word_1A738-Sys_GameEntryPoint
                dc.w word_1A748-Sys_GameEntryPoint
                dc.w word_1A730-Sys_GameEntryPoint
                dc.w word_1A750-Sys_GameEntryPoint
                dc.w word_1A740-Sys_GameEntryPoint
byte_14822:     dc.b 6, 1
                dc.w word_1A758-Sys_GameEntryPoint
                dc.w word_1A768-Sys_GameEntryPoint
                dc.w word_1A778-Sys_GameEntryPoint
                dc.w word_1A760-Sys_GameEntryPoint
                dc.w word_1A780-Sys_GameEntryPoint
                dc.w word_1A770-Sys_GameEntryPoint
byte_14830:     dc.b 6, 1
                dc.w word_1A788-Sys_GameEntryPoint
                dc.w word_1A798-Sys_GameEntryPoint
                dc.w word_1A7A8-Sys_GameEntryPoint
                dc.w word_1A790-Sys_GameEntryPoint
                dc.w word_1A7B0-Sys_GameEntryPoint
                dc.w word_1A7A0-Sys_GameEntryPoint
; Enemy cat main object that chases player
