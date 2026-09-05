; Lizard enemy and its animation tables.
; ROM $014EC6-$015507.

Obj_Lizard:
                bset    #7,(a0)  ; was: sub_14EC6
                bne.s   loc_14EFA
                moveq   #0,d7
                moveq   #0,d6
                move.b  $3E(a0),d7
                move.b  $3F(a0),d6
                bsr.w Math_GridToScreen
                addq.w  #8,d7
                addi.w  #$10,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)
                move.l  #off_154AE,8(a0)
                clr.l   $34(a0)
                clr.l   $2C(a0)

loc_14EFA:
                tst.b   (byte_FFD27B).w
                bne.s   loc_14F2E
                tst.b   (byte_FFD24F).w
                bne.s   loc_14F2E
                tst.b   (byte_FFD26D).w
                bne.s   loc_14F2E
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     loc_14F44(pc,d0.w)
                move.w  $3C(a0),d0
                andi.w  #$7FFC,d0
                cmpi.w  #$14,d0
                beq.s   loc_14F2E
                cmpi.w  #$1C,d0
                beq.s   loc_14F2E
                bsr.w Lizard_CheckPlayerHit

loc_14F2E:
                move.l  $34(a0),d0
                beq.s   locret_14F42
                move.b  #1,$39(a0)
                tst.l   d0
                bmi.s   locret_14F42
                clr.b   $39(a0)

locret_14F42:
                rts

loc_14F44:
                bra.w Lizard_StateWait
                bra.w Lizard_StateLocate
                bra.w Lizard_StateChase
                bra.w Lizard_StateJump
                bra.w Lizard_StateStunned
                bra.w Lizard_StateHit
                bra.w Lizard_StateTrack
                bra.w Lizard_StateDeath

; Lizard state: waiting/idle after hit
Lizard_StateWait:
                bset    #7,$3C(a0)  ; was: sub_14F64
                bne.s   loc_14F80
                clr.w   6(a0)
                bclr    #2,2(a0)
                clr.b   $10(a0)
                move.b  #6,5(a0)

loc_14F80:
                bsr.w Object_UpdatePosition
                bsr.w Anim_UpdateFrame
                bclr    #2,2(a0)
                beq.s   locret_14FD0
                move.w  #8,$3C(a0)
                lea     (word_FFC440).w,a1
                move.w  $20(a0),d7
                move.w  $20(a1),d6
                clr.b   $39(a0)
                cmp.w   d7,d6
                bgt.s   loc_14FB0
                move.b  #1,$39(a0)

loc_14FB0:
                cmpi.w  #$30,(dword_FFD888).w
                bhi.s   locret_14FD0
                cmpi.b  #$31,(word_FFD82C+1).w
                bhi.s   locret_14FD0
                clr.b   $39(a0)
                tst.b   $16(a0)
                beq.s   locret_14FD0
                move.b  #1,$39(a0)

locret_14FD0:
                rts

; Lizard state: locating player direction
Lizard_StateLocate:
                bset    #7,$3C(a0)  ; was: sub_14FD2
                bne.s   loc_15004
                move.b  #7,5(a0)
                clr.l   $34(a0)
                move.b  #$14,$3B(a0)
                move.l  #word_1A918,$C(a0)
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   loc_15004
                bset    #7,2(a0)

loc_15004:
                bsr.w Object_UpdatePosition
                move.w  $20(a0),d7
                move.w  $24(a0),d6
                lea     (word_FFC440).w,a1
                move.w  word_FFC460-word_FFC440(a1),d5
                move.w  $24(a1),d4
                cmp.w   d6,d4
                beq.s   loc_1502E
                move.b  #2,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

loc_1502E:
                tst.b   $39(a0)
                bne.s   loc_1504E
                cmp.w   d7,d5
                bgt.s   loc_15040
                move.w  #$10,$3C(a0)
                rts

loc_15040:
                move.b  #1,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

loc_1504E:
                cmp.w   d7,d5
                blt.s   loc_1505A
                move.w  #$10,$3C(a0)
                rts

loc_1505A:
                move.b  #1,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

; Lizard state: running/chasing horizontally
Lizard_StateChase:
                bset    #7,$3C(a0)  ; was: sub_15068
                bne.s   loc_15094
                move.b  #7,5(a0)
                move.l  (dword_FFD296).w,$34(a0)
                tst.b   $16(a0)
                beq.s   loc_1508A
                move.l  #loc_14000,$34(a0)

loc_1508A:
                tst.b   $39(a0)
                beq.s   loc_15094
                neg.l   $34(a0)

loc_15094:
                bsr.w Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subq.w  #8,d6
                tst.l   $34(a0)
                bpl.s   loc_150AC
                subq.w  #8,d7
                bra.s   loc_150AE

loc_150AC:
                addq.w  #8,d7

loc_150AE:
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                beq.s   loc_150BA
                neg.l   $34(a0)

loc_150BA:
                moveq   #0,d7
                moveq   #1,d6
                bsr.w Collision_GetTileAtObject
                btst    #7,d4
                bne.s   loc_150EA
                tst.l   $34(a0)
                bpl.s   loc_150DC
                btst    #2,d4
                bne.s   loc_150DA
                move.w  #4,$3C(a0)

loc_150DA:
                bra.s   loc_15114

loc_150DC:
                btst    #3,d4
                bne.s   loc_150E8
                move.w  #4,$3C(a0)

loc_150E8:
                bra.s   loc_15114

loc_150EA:
                tst.b   $39(a0)
                bne.s   loc_150F8
                btst    #6,d4
                bne.s   loc_15114
                bra.s   loc_150FE

loc_150F8:
                btst    #6,d4
                beq.s   loc_15114

loc_150FE:
                lea     (word_FFC440).w,a1
                move.w  $24(a0),d6
                cmp.w   $24(a1),d6
                blt.s   loc_15114
                beq.s   loc_15132
                move.w  #$18,$3C(a0)

loc_15114:
                bclr    #7,2(a0)
                tst.l   $34(a0)
                bpl.s   loc_15126
                bset    #7,2(a0)

loc_15126:
                move.w  #4,6(a0)
                bsr.w Anim_UpdateFrame
                rts

loc_15132:
                cmpi.w  #$30,(dword_FFD888).w
                bls.s   loc_15114
                move.w  $20(a1),d7
                tst.b   $39(a0)
                beq.s   loc_1514C
                cmp.w   $20(a0),d7
                blt.s   loc_15114
                bra.s   loc_15152

loc_1514C:
                cmp.w   $20(a0),d7
                bgt.s   loc_15114

loc_15152:
                move.w  #$18,$3C(a0)
                bra.s   loc_15114

; Lizard state: jumping/leaping toward player
Lizard_StateJump:
                tst.b   $3B(a0)  ; was: sub_1515A
                bne.w   loc_1524C
                bset    #7,$3C(a0)
                bne.s   loc_151B4
                move.b  #7,5(a0)
                move.b  $3A(a0),d0
                beq.s   loc_1518C
                cmpi.b  #1,d0
                beq.s   loc_1519A
                move.l  (dword_FFD276).w,$34(a0)
                move.l  #$FFFF8000,$2C(a0)
                bra.s   loc_151AA

loc_1518C:
                move.l  (dword_FFD26E).w,$34(a0)
                move.l  (dword_FFD272).w,$2C(a0)
                bra.s   loc_151AA

loc_1519A:
                move.l  #$1A000,$34(a0)
                move.l  #$FFFF0000,$2C(a0)

loc_151AA:
                tst.b   $39(a0)
                beq.s   loc_151B4
                neg.l   $34(a0)

loc_151B4:
                addi.l  #$1000,$2C(a0)
                bsr.w Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                bne.s   loc_1520C
                subq.w  #8,d6
                tst.l   $34(a0)
                bpl.s   loc_151DC
                subq.w  #8,d7
                bra.s   loc_151DE

loc_151DC:
                addq.w  #8,d7

loc_151DE:
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                beq.s   loc_151EC
                neg.l   $34(a0)
                bra.s   loc_15222

loc_151EC:
                tst.l   $2C(a0)
                bpl.s   loc_1520A
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subi.w  #$D,d6
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                beq.s   loc_1520A
                clr.l   $2C(a0)

loc_1520A:
                bra.s   loc_15222

loc_1520C:
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)
                move.w  #8,$3C(a0)

loc_15222:
                move.l  #word_1A970,$C(a0)
                tst.l   $2C(a0)
                bmi.s   loc_15238
                move.l  #word_1A97E,$C(a0)

loc_15238:
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   locret_1524A
                bset    #7,2(a0)

locret_1524A:
                rts

loc_1524C:
                subq.b  #1,$3B(a0)
                bsr.w Object_UpdatePosition
                rts

; Lizard state: stunned/recovering after hit
Lizard_StateStunned:
                tst.b   $3B(a0)  ; was: sub_15256
                bne.s   loc_152AA
                bset    #7,$3C(a0)
                bne.s   loc_1527A
                move.b  #7,5(a0)
                bclr    #2,2(a0)
                move.w  #$C,6(a0)
                clr.b   $10(a0)

loc_1527A:
                bsr.w Object_UpdatePosition
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   loc_15290
                bset    #7,2(a0)

loc_15290:
                bsr.w Anim_UpdateFrame
                bclr    #2,2(a0)
                beq.s   locret_152A8
                bchg    #0,$39(a0)
                move.w  #8,$3C(a0)

locret_152A8:
                rts

loc_152AA:
                subq.b  #1,$3B(a0)
                bsr.w Object_UpdatePosition
                rts

; Lizard state: hit by player bouncing
Lizard_StateHit:
                bset    #7,$3C(a0)  ; was: sub_152B4
                bne.s   loc_152E4
                move.l  a0,-(sp)
                move.b  #$93,d0
                bsr.w Sound_PlayNoteIfActive
                movea.l (sp)+,a0
                tst.b   $16(a0)
                bne.s   loc_152D6
                addi.l  #$1000,(dword_FFD296).w

loc_152D6:
                clr.b   5(a0)
                move.w  #8,6(a0)
                subq.b  #1,(byte_FFD26C).w

loc_152E4:
                bsr.w Chick_UpdatePhysics
                tst.l   $34(a0)
                bne.s   locret_152F4
                move.w  #$1C,$3C(a0)

locret_152F4:
                rts

; Lizard state: tracking player alternate
Lizard_StateTrack:
                bset    #7,$3C(a0)  ; was: sub_152F6
                bne.s   loc_15328
                move.b  #7,5(a0)
                clr.l   $34(a0)
                move.b  #$14,$3B(a0)
                move.l  #word_1A918,$C(a0)
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   loc_15328
                bset    #7,2(a0)

loc_15328:
                bsr.w Object_UpdatePosition
                move.w  $20(a0),d7
                move.w  $24(a0),d6
                lea     (word_FFC440).w,a1
                move.w  word_FFC460-word_FFC440(a1),d5
                move.w  $24(a1),d4
                cmp.w   d6,d4
                beq.s   loc_15360
                bgt.s   loc_15352
                clr.b   $3A(a0)
                move.w  #$C,$3C(a0)
                rts

loc_15352:
                move.b  #2,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

loc_15360:
                tst.b   $39(a0)
                bne.s   loc_15380
                cmp.w   d7,d5
                bgt.s   loc_15372
                move.w  #$10,$3C(a0)
                rts

loc_15372:
                move.b  #1,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

loc_15380:
                cmp.w   d7,d5
                blt.s   loc_1538C
                move.w  #$10,$3C(a0)
                rts

loc_1538C:
                move.b  #1,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

; Decrements lizard action timer
Lizard_DecrementTimer:
                subq.b  #1,$3B(a0)  ; was: sub_1539A
                bsr.w Object_UpdatePosition
                rts

; Lizard state: death anim spawns new enemy
Lizard_StateDeath:
                bset    #7,$3C(a0)  ; was: sub_153A4
                bne.s   loc_153C8
                clr.b   5(a0)
                bclr    #2,2(a0)
                move.w  #$10,6(a0)
                clr.b   $10(a0)
                move.l  #$FFFFC000,$2C(a0)

loc_153C8:
                bsr.w Object_UpdatePosition
                bsr.w Anim_UpdateFrame
                btst    #2,2(a0)
                beq.s   locret_15408
                move.b  (dword_FFD888+2).w,d0
                andi.b  #$F0,d0
                bne.s   loc_15404
                lea     (unk_FFC740).w,a1
                tst.b   $16(a0)
                beq.s   loc_153F0
                lea     $40(a1),a1

loc_153F0:
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                move.w  d7,$30(a1)
                move.w  d6,$24(a1)
                move.w  #$28,(a1)

loc_15404:
                bsr.w Sprite_ClearLinkTable

locret_15408:
                rts

; Lizard collision with player hit detection
Lizard_CheckPlayerHit:
                lea     (unk_FFC200).w,a1  ; was: sub_1540A
                moveq   #5,d0

loc_15410:
                move.w  d0,-(sp)
                btst    #3,5(a1)
                beq.s   loc_1548E
                bsr.w Collision_CheckObjectPair
                tst.b   d0
                beq.s   loc_1548E
                move.w  #$14,$3C(a0)
                clr.b   5(a0)
                move.l  $34(a1),d7
                move.l  $2C(a1),d6
                move.l  d7,$34(a0)
                move.l  d6,$2C(a0)
                addq.b  #1,$3B(a1)
                moveq   #0,d0
                move.b  $3B(a1),d0
                subq.b  #1,d0
                lsl.w   #2,d0
                move.l  dword_1549E(pc,d0.w),d0
                move.l  d0,(dword_FFD262).w
                move.l  a1,-(sp)
                bsr.w Score_AddAndCheck
                movea.l (sp)+,a1
                lea     (unk_FFC0C0).w,a2
                moveq   #3,d0

loc_15460:
                tst.b   (a2)
                bne.s   loc_15484
                move.w  #$1C,(a2)
                move.b  $3B(a1),d1
                move.b  d1,$3A(a2)
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subq.w  #8,d6
                move.w  d7,$30(a2)
                move.w  d6,$24(a2)
                bra.s   loc_1549A

loc_15484:
                lea     -$40(a2),a2
                dbf     d0,loc_15460
                bra.s   loc_1549A

loc_1548E:
                lea     $40(a1),a1
                move.w  (sp)+,d0
                dbf     d0,loc_15410
                rts

loc_1549A:
                move.w  (sp)+,d0
                rts

dword_1549E:    dc.l $200
                dc.l $400
                dc.l $800
                dc.l $1600
off_154AE:      dc.l byte_154C2
                dc.l byte_154D0
                dc.l byte_154E2
                dc.l byte_154F4
                dc.l byte_154FE
byte_154C2:     dc.b 6, $C
                dc.w word_1A8F8-Sys_GameEntryPoint
                dc.w word_1A900-Sys_GameEntryPoint
                dc.w word_1A8F8-Sys_GameEntryPoint
                dc.w word_1A900-Sys_GameEntryPoint
                dc.w word_1A908-Sys_GameEntryPoint
                dc.w word_1A910-Sys_GameEntryPoint
byte_154D0:     dc.b 8, 1
                dc.w word_1A918-Sys_GameEntryPoint
                dc.w word_1A926-Sys_GameEntryPoint
                dc.w word_1A93A-Sys_GameEntryPoint
                dc.w word_1A94E-Sys_GameEntryPoint
                dc.w word_1A94E-Sys_GameEntryPoint
                dc.w word_1A95C-Sys_GameEntryPoint
                dc.w word_1A93A-Sys_GameEntryPoint
                dc.w word_1A926-Sys_GameEntryPoint
byte_154E2:     dc.b 8, 1
                dc.w word_1A992-Sys_GameEntryPoint
                dc.w word_1A99A-Sys_GameEntryPoint
                dc.w word_1A9AE-Sys_GameEntryPoint
                dc.w word_1A9B6-Sys_GameEntryPoint
                dc.w word_1A9CA-Sys_GameEntryPoint
                dc.w word_1A9D2-Sys_GameEntryPoint
                dc.w word_1A9E6-Sys_GameEntryPoint
                dc.w word_1A9EE-Sys_GameEntryPoint
byte_154F4:     dc.b 4, 5
                dc.w word_1AA02-Sys_GameEntryPoint
                dc.w word_1AA02-Sys_GameEntryPoint
                dc.w word_1AA0A-Sys_GameEntryPoint
                dc.w word_1AA12-Sys_GameEntryPoint
byte_154FE:     dc.b 4, 6
                dc.w word_1AA7E-Sys_GameEntryPoint
                dc.w word_1AA7E-Sys_GameEntryPoint
                dc.w word_1AA86-Sys_GameEntryPoint
                dc.w word_1AA8E-Sys_GameEntryPoint
