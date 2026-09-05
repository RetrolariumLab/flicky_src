; Cat enemy.
; ROM $01483E-$014EC5.

Obj_Cat:
                bset    #7,(a0)  ; was: sub_1483E
                bne.s   loc_14874
                move.l  #off_14E12,8(a0)
                tst.b   $3A(a0)
                beq.s   loc_1485A
                move.l  #off_14E22,8(a0)

loc_1485A:
                move.b  $3E(a0),d7
                move.b  $3F(a0),d6
                bsr.w   Math_GridToScreen
                addq.w  #8,d7
                addi.w  #$10,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)

loc_14874:
                tst.b   (byte_FFD27B).w
                bne.s   locret_14898
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     loc_1489A(pc,d0.w)
                move.l  $34(a0),d0
                beq.s   locret_14898
                move.b  #1,$39(a0)
                tst.l   d0
                bmi.s   locret_14898
                clr.b   $39(a0)

locret_14898:
                rts

loc_1489A:
                bra.w   Cat_StatePatrol
                bra.w   Cat_StateFollowing
                bra.w   Cat_StateWalking
                bra.w   Cat_StateStunWalk

; Cat state: patrolling and bouncing
Cat_StatePatrol:
                tst.b   (byte_FFD24F).w  ; was: sub_148AA
                bne.s   locret_14916
                bset    #7,$3C(a0)
                bne.s   loc_148C6
                move.b  #$30,$3B(a0)
                move.l  #$FFFFE000,$2C(a0)

loc_148C6:
                clr.w   6(a0)
                subq.b  #1,$3B(a0)
                bne.s   loc_148DA
                neg.l   $2C(a0)
                move.b  #$30,$3B(a0)

loc_148DA:
                lea     (word_FFC440).w,a1
                bsr.w   Collision_CheckObjectPair
                tst.b   d0
                beq.s   loc_1490E
                move.l  a0,-(sp)
                move.b  #$90,d0
                bsr.w   Sound_PlayNoteIfActive
                movea.l (sp)+,a0
                move.w  #4,$3C(a0)
                addq.b  #1,(byte_FFD27A).w
                move.b  (byte_FFD27A).w,$38(a0)
                move.l  #$10,(dword_FFD262).w
                bsr.w   Score_AddAndCheck

loc_1490E:
                bsr.w   Anim_UpdateFrame
                bsr.w   Object_UpdatePosition

locret_14916:
                rts

; Cat state: following rescued chick chain
Cat_StateFollowing:
                bset    #7,$3C(a0)  ; was: sub_14918
                bne.s   loc_14928
                clr.l   $34(a0)
                clr.l   $2C(a0)

loc_14928:
                tst.b   (byte_FFD26D).w
                beq.s   loc_14940
                clr.b   $38(a0)
                subq.b  #1,(byte_FFD27A).w
                move.w  #8,$3C(a0)
                bra.w   loc_14A12

loc_14940:
                moveq   #0,d0
                move.b  $38(a0),d0
                lsl.w   #1,d0
                moveq   #$FFFFFFFF,d1
                lea     byte_14A58(pc),a1
                move.w  (a1,d0.w),d1
                movea.l d1,a1
                move.l  (a1),$30(a0)
                move.l  4(a1),$24(a0)
                bsr.w   Object_CalcScreenPos
                lea     byte_14A6A(pc),a1
                move.w  (a1,d0.w),d1
                movea.l d1,a1
                moveq   #0,d1
                move.b  (a1),d1
                move.w  d1,-(sp)
                tst.b   (byte_FFD24F).w
                bne.s   loc_1497C
                bsr.w   Chick_CheckEnemyHit

loc_1497C:
                move.w  (sp)+,d1
                tst.b   (byte_FFD24F).w
                beq.s   loc_149F2
                lea     (word_FFC440).w,a1
                move.w  dword_FFC470-word_FFC440(a1),d7
                move.w  $24(a1),d6
                cmp.w   $30(a0),d7
                bne.s   loc_149F2
                cmp.w   $24(a0),d6
                bne.s   loc_149F2
                move.l  a0,-(sp)
                move.b  #$94,d0
                bsr.w   Sound_PlayNoteIfActive
                movea.l (sp)+,a0
                clr.w   (a0)
                bsr.w   Chick_AwardPoints
                subq.b  #1,(byte_FFD883).w
                bne.s   loc_149CE
                move.b  #1,(byte_FFD281).w
                clr.w   (word_FFFF92).w
                move.b  (dword_FFD888).w,(byte_FFD266).w
                move.b  (dword_FFD888+1).w,(byte_FFD267).w
                bsr.w   Score_CalcTimeBonus

loc_149CE:
                move.l  a0,-(sp)
                moveq   #2,d1

loc_149D2:
                jsr     unk_FFFB6C
                dbf     d1,loc_149D2
                movea.l (sp)+,a0
                clr.b   $38(a0)
                subq.b  #1,(byte_FFD27A).w
                bne.s   loc_149F2
                clr.b   (byte_FFD24F).w
                move.l  a0,-(sp)
                bsr.w   UI_AnimateBonus
                movea.l (sp)+,a0

loc_149F2:
                tst.b   (byte_FFD281).w
                beq.s   loc_14A12
                move.b  #1,(byte_FFD24F).w
                move.w  #$C,(word_FFD2A0).w
                cmpi.b  #1,(byte_FFD88D).w
                beq.s   loc_14A12
                move.b  #1,(byte_FFD88F).w

loc_14A12:
                bclr    #7,2(a0)
                clr.b   $39(a0)
                move.b  d1,d0
                andi.b  #3,d0
                bne.s   loc_14A2A
                clr.w   6(a0)
                bra.s   loc_14A4E

loc_14A2A:
                btst    #0,d1
                bne.s   loc_14A3C
                bset    #7,2(a0)
                move.b  #1,$39(a0)

loc_14A3C:
                tst.b   d1
                bmi.s   loc_14A48
                move.w  #8,6(a0)
                bra.s   loc_14A4E

loc_14A48:
                move.w  #4,6(a0)

loc_14A4E:
                bsr.w   Anim_UpdateFrame
                bsr.w   Object_CalcScreenPos
                rts

byte_14A58:     dc.b    0, 0
                dc.w    $D036, $D05E, $D086, $D0AE, $D0D6, $D0FE, $D126, $D14E
byte_14A6A:     dc.b    0, 0
                dc.w    $D213, $D218, $D21D, $D222, $D227, $D22C, $D231, $D236
; Awards points when chick delivered to door
Chick_AwardPoints:
                moveq   #0,d0  ; was: sub_14A7C
                move.b  $38(a0),d0
                subq.b  #1,d0
                lsl.w   #2,d0
                move.l  dword_14AC0(pc,d0.w),d0
                move.l  d0,(dword_FFD262).w
                bsr.w   Score_AddAndCheck
                moveq   #0,d0
                move.b  $38(a0),d0
                move.b  d0,d1
                subq.b  #1,d0
                lsl.w   #1,d0
                moveq   #$FFFFFFFF,d2
                lea     word_14AE0(pc),a2
                move.w  (a2,d0.w),d2
                movea.l d2,a2
                move.w  #$20,(a2)
                move.b  d1,$3A(a2)
                lea     (word_FFC440).w,a1
                move.w  dword_FFC470-word_FFC440(a1),d7
                move.w  d7,$30(a2)
                rts

dword_14AC0:    dc.l    $100
                dc.l    $200
                dc.l    $300
                dc.l    $400
                dc.l    $500
                dc.l    $1000
                dc.l    $2000
                dc.l    $5000
word_14AE0:     dc.w    $C100, $C140, $C180, $C1C0, $C100, $C140, $C180, $C1C0
; Checks if chick chain hit by enemy
Chick_CheckEnemyHit:
                lea     (unk_FFC380).w,a1  ; was: sub_14AF0
                moveq   #1,d0

loc_14AF6:
                move.w  d0,-(sp)
                btst    #1,5(a1)
                beq.s   loc_14B30
                bsr.w   Collision_CheckObjectPair
                tst.b   d0
                beq.s   loc_14B30
                move.b  $38(a0),d0
                lea     (unk_FFC480).w,a2
                moveq   #7,d1

loc_14B12:
                cmp.b   $38(a2),d0
                bhi.s   loc_14B26
                clr.b   $38(a2)
                subq.b  #1,(byte_FFD27A).w
                move.w  #8,$3C(a2)

loc_14B26:
                lea     $40(a2),a2
                dbf     d1,loc_14B12
                bra.s   loc_14B3C

loc_14B30:
                lea     $40(a1),a1
                move.w  (sp)+,d0
                dbf     d0,loc_14AF6
                rts

loc_14B3C:
                move.w  (sp)+,d0
                rts

; Cat idle state (shared RTS)
Cat_StateIdle:
                rts  ; was: nullsub_4

; Cat state: walking on ground turning at walls
Cat_StateWalking:
                tst.b   $3A(a0)  ; was: sub_14B42
                bne.w   Cat_StateWalkAlt
                bset    #7,$3C(a0)
                bne.s   loc_14B76
                moveq   #0,d0
                move.w  a0,d0
                subi.w  #$C480,d0
                lsr.w   #4,d0
                lea     dword_14C4A(pc),a1
                move.l  (a1,d0.w),$34(a0)
                tst.b   $39(a0)
                beq.s   loc_14B70
                neg.l   $34(a0)

loc_14B70:
                move.w  #8,6(a0)

loc_14B76:
                bsr.w   Object_UpdatePosition
                tst.l   $2C(a0)
                bne.w   loc_14BF8
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                addq.w  #1,d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                bne.s   loc_14BA4
                addi.l  #$1000,$2C(a0)
                move.w  #4,6(a0)
                bra.s   loc_14BF6

loc_14BA4:
                move.l  $34(a0),d0
                beq.s   loc_14BBA
                tst.b   $39(a0)
                bne.s   loc_14BC6
                subi.l  #$400,$34(a0)
                bra.s   Cat_CheckWallCollision

loc_14BBA:
                clr.l   $34(a0)
                move.w  #$C,$3C(a0)
                bra.s   loc_14BF6

loc_14BC6:
                addi.l  #$400,$34(a0)
                bra.s   Cat_CheckWallCollision

; Clears cat horizontal velocity
Cat_ClearVelocity:
                clr.l   $34(a0)  ; was: sub_14BD0
                move.w  #$C,$3C(a0)
                bra.s   loc_14BF6

; Cat wall collision: reverses at walls
Cat_CheckWallCollision:
                subq.w  #6,d6  ; was: sub_14BDC
                moveq   #4,d0
                tst.l   $34(a0)
                bpl.s   loc_14BE8
                neg.w   d0

loc_14BE8:
                add.w   d0,d7
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   loc_14BF6
                neg.l   $34(a0)

loc_14BF6:
                bra.s   loc_14C2E

loc_14BF8:
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   loc_14C20
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)
                move.w  #8,6(a0)
                bra.s   loc_14C2E

loc_14C20:
                addi.l  #$1000,$2C(a0)
                move.w  #4,6(a0)

loc_14C2E:
                bclr    #7,2(a0)
                tst.l   $34(a0)
                bpl.s   loc_14C40
                bset    #7,2(a0)

loc_14C40:
                bsr.w   Anim_UpdateFrame
                bsr.w   Cat_CheckPlayerPickup
                rts

dword_14C4A:    dc.l    $A000
                dc.l    $C000
                dc.l    $E000
                dc.l    $10000
                dc.l    $12000
                dc.l    $14000
                dc.l    $16000
                dc.l    $18000
; Cat state: alternate walking pattern
Cat_StateWalkAlt:
                bset    #7,$3C(a0)  ; was: sub_14C6A
                bne.s   loc_14C96
                moveq   #0,d0
                move.w  a0,d0
                subi.w  #$C480,d0
                lsr.w   #4,d0
                lea     dword_14D32(pc),a1
                move.l  (a1,d0.w),$34(a0)
                tst.b   $39(a0)
                beq.s   loc_14C90
                neg.l   $34(a0)

loc_14C90:
                move.w  #8,6(a0)

loc_14C96:
                bsr.w   Object_UpdatePosition
                tst.l   $2C(a0)
                bne.w   loc_14CE0
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                addq.w  #1,d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                bne.s   loc_14CC4
                addi.l  #$1000,$2C(a0)
                move.w  #4,6(a0)
                bra.s   loc_14CDE

loc_14CC4:
                subq.w  #6,d6
                moveq   #4,d0
                tst.l   $34(a0)
                bpl.s   loc_14CD0
                neg.w   d0

loc_14CD0:
                add.w   d0,d7
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   loc_14CDE
                neg.l   $34(a0)

loc_14CDE:
                bra.s   loc_14D16

loc_14CE0:
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   Collision_GetTileAtPos
                tst.b   d4
                beq.s   loc_14D08
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)
                move.w  #8,6(a0)
                bra.s   loc_14D16

loc_14D08:
                addi.l  #$1000,$2C(a0)
                move.w  #4,6(a0)

loc_14D16:
                bclr    #7,2(a0)
                tst.l   $34(a0)
                bpl.s   loc_14D28
                bset    #7,2(a0)

loc_14D28:
                bsr.w   Anim_UpdateFrame
                bsr.w   Cat_CheckPlayerPickup
                rts

dword_14D32:    dc.l    $C000
                dc.l    $D000
                dc.l    $E000
                dc.l    $F000
                dc.l    $10000
                dc.l    $11000
                dc.l    $12000
                dc.l    $13000
; Checks if player picked up cat/chick
Cat_CheckPlayerPickup:
                lea     (word_FFC440).w,a1  ; was: sub_14D52
                move.w  word_FFC47C-word_FFC440(a1),d0
                andi.w  #$7C,d0
                bne.s   locret_14D84
                bsr.w   Collision_CheckObjectPair
                tst.b   d0
                beq.s   locret_14D84
                move.l  a0,-(sp)
                move.b  #$90,d0
                bsr.w   Sound_PlayNoteIfActive
                movea.l (sp)+,a0
                move.w  #4,$3C(a0)
                addq.b  #1,(byte_FFD27A).w
                move.b  (byte_FFD27A).w,$38(a0)

locret_14D84:
                rts

; Cat state: stunned walking animation
Cat_StateStunWalk:
                bsr.w   Object_UpdatePosition  ; was: sub_14D86
                bset    #7,$3C(a0)
                bne.s   loc_14DA2
                bclr    #2,2(a0)
                move.w  #$C,6(a0)
                clr.b   $10(a0)

loc_14DA2:
                bsr.w   Object_UpdatePosition
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   loc_14DB8
                bset    #7,2(a0)

loc_14DB8:
                bsr.w   Anim_UpdateFrame
                bclr    #2,2(a0)
                beq.s   loc_14DD0
                bchg    #0,$39(a0)
                move.w  #8,$3C(a0)

loc_14DD0:
                bsr.s   Cat_CheckPlayerPickup
                rts

; Calculates time bonus from remaining time
Score_CalcTimeBonus:
                clr.l   (dword_FFD268).w  ; was: sub_14DD4
                tst.b   (byte_FFD266).w
                bne.s   locret_14DF8
                moveq   #0,d0
                move.b  (byte_FFD267).w,d0
                lsr.w   #4,d0
                lsl.w   #2,d0
                move.l  dword_14DFA(pc,d0.w),d0
                move.l  d0,(dword_FFD268).w
                move.l  d0,(dword_FFD262).w
                bsr.w   Score_AddAndCheck

locret_14DF8:
                rts

dword_14DFA:    dc.l    $20000
                dc.l    $20000
                dc.l    $10000
                dc.l    $5000
                dc.l    $3000
                dc.l    $1000
off_14E12:      dc.l    byte_14E32
                dc.l    byte_14E96
                dc.l    byte_14EA2
                dc.l    byte_14EB2
off_14E22:      dc.l    byte_14E64
                dc.l    byte_14E9C
                dc.l    byte_14EAA
                dc.l    byte_14EBC
byte_14E32:     dc.b    $18, 4
                dc.w    word_1A7B8-Sys_GameEntryPoint
                dc.w    word_1A7C0-Sys_GameEntryPoint
                dc.w    word_1A7B8-Sys_GameEntryPoint
                dc.w    word_1A7C0-Sys_GameEntryPoint
                dc.w    word_1A7B8-Sys_GameEntryPoint
                dc.w    word_1A7C0-Sys_GameEntryPoint
                dc.w    word_1A7B8-Sys_GameEntryPoint
                dc.w    word_1A7C0-Sys_GameEntryPoint
                dc.w    word_1A7B8-Sys_GameEntryPoint
                dc.w    word_1A7C0-Sys_GameEntryPoint
                dc.w    word_1A7B8-Sys_GameEntryPoint
                dc.w    word_1A7C0-Sys_GameEntryPoint
                dc.w    word_1A7C8-Sys_GameEntryPoint
                dc.w    word_1A7D0-Sys_GameEntryPoint
                dc.w    word_1A7C8-Sys_GameEntryPoint
                dc.w    word_1A7D0-Sys_GameEntryPoint
                dc.w    word_1A7C8-Sys_GameEntryPoint
                dc.w    word_1A7D0-Sys_GameEntryPoint
                dc.w    word_1A7C8-Sys_GameEntryPoint
                dc.w    word_1A7D0-Sys_GameEntryPoint
                dc.w    word_1A7C8-Sys_GameEntryPoint
                dc.w    word_1A7D0-Sys_GameEntryPoint
                dc.w    word_1A7C8-Sys_GameEntryPoint
                dc.w    word_1A7D0-Sys_GameEntryPoint
byte_14E64:     dc.b    $18, 4
                dc.w    word_1A818-Sys_GameEntryPoint
                dc.w    word_1A820-Sys_GameEntryPoint
                dc.w    word_1A818-Sys_GameEntryPoint
                dc.w    word_1A820-Sys_GameEntryPoint
                dc.w    word_1A818-Sys_GameEntryPoint
                dc.w    word_1A820-Sys_GameEntryPoint
                dc.w    word_1A818-Sys_GameEntryPoint
                dc.w    word_1A820-Sys_GameEntryPoint
                dc.w    word_1A818-Sys_GameEntryPoint
                dc.w    word_1A820-Sys_GameEntryPoint
                dc.w    word_1A818-Sys_GameEntryPoint
                dc.w    word_1A820-Sys_GameEntryPoint
                dc.w    word_1A828-Sys_GameEntryPoint
                dc.w    word_1A830-Sys_GameEntryPoint
                dc.w    word_1A828-Sys_GameEntryPoint
                dc.w    word_1A830-Sys_GameEntryPoint
                dc.w    word_1A828-Sys_GameEntryPoint
                dc.w    word_1A830-Sys_GameEntryPoint
                dc.w    word_1A828-Sys_GameEntryPoint
                dc.w    word_1A830-Sys_GameEntryPoint
                dc.w    word_1A828-Sys_GameEntryPoint
                dc.w    word_1A830-Sys_GameEntryPoint
                dc.w    word_1A828-Sys_GameEntryPoint
                dc.w    word_1A830-Sys_GameEntryPoint
byte_14E96:     dc.b    2, 3
                dc.w    word_1A7D8-Sys_GameEntryPoint
                dc.w    word_1A7E0-Sys_GameEntryPoint
byte_14E9C:     dc.b    2, 3
                dc.w    word_1A838-Sys_GameEntryPoint
                dc.w    word_1A840-Sys_GameEntryPoint
byte_14EA2:     dc.b    3, 4
                dc.w    word_1A7E8-Sys_GameEntryPoint
                dc.w    word_1A7F0-Sys_GameEntryPoint
                dc.w    word_1A7F8-Sys_GameEntryPoint
byte_14EAA:     dc.b    3, 4
                dc.w    word_1A848-Sys_GameEntryPoint
                dc.w    word_1A850-Sys_GameEntryPoint
                dc.w    word_1A858-Sys_GameEntryPoint
byte_14EB2:     dc.b    4, $A
                dc.w    word_1A800-Sys_GameEntryPoint
                dc.w    word_1A800-Sys_GameEntryPoint
                dc.w    word_1A808-Sys_GameEntryPoint
                dc.w    word_1A810-Sys_GameEntryPoint
byte_14EBC:     dc.b    4, $A
                dc.w    word_1A860-Sys_GameEntryPoint
                dc.w    word_1A860-Sys_GameEntryPoint
                dc.w    word_1A868-Sys_GameEntryPoint
                dc.w    word_1A870-Sys_GameEntryPoint
; Lizard enemy main object with state machine
