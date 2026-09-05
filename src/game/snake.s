; Snake enemy.
; ROM $015D58-$016311.

Obj_Snake:
                bset    #7,(a0)  ; was: sub_15D58
                bne.s   loc_15D8C
                moveq   #0,d7
                moveq   #0,d6
                move.b  $3E(a0),d7
                move.b  $3F(a0),d6
                bsr.w Math_GridToScreen
                addq.w  #8,d7
                addi.w  #$10,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)
                move.l  #off_162BC,8(a0)
                clr.l   $34(a0)
                clr.l   $2C(a0)

loc_15D8C:
                tst.b   (byte_FFD27B).w
                bne.s   locret_15DC0
                tst.b   (byte_FFD24F).w
                bne.s   locret_15DC0
                tst.b   (byte_FFD26D).w
                bne.s   locret_15DC0
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     loc_15DC2(pc,d0.w)
                move.w  $3C(a0),d0
                andi.w  #$7C,d0
                cmpi.w  #$C,d0
                beq.s   locret_15DC0
                cmpi.w  #$10,d0
                beq.s   locret_15DC0
                bsr.w Snake_CheckPlayerHit

locret_15DC0:
                rts

loc_15DC2:
                bra.w Snake_StateSpawn
                bra.w Snake_StateMove
                bra.w Snake_StateTurn
                bra.w Snake_StateHit
                bra.w Snake_StateDeath

; Snake state: initial spawn animation
Snake_StateSpawn:
                bset    #7,$3C(a0)  ; was: sub_15DD6
                bne.s   loc_15DF2
                move.b  #4,5(a0)
                move.l  #word_1AB74,$C(a0)
                move.b  #$A,$3B(a0)

loc_15DF2:
                bsr.w Object_UpdatePosition
                subq.b  #1,$3B(a0)
                bne.s   locret_15E02
                move.w  #4,$3C(a0)

locret_15E02:
                rts

; Snake state: movement direction dispatcher
Snake_StateMove:
                bset    #7,$3C(a0)  ; was: sub_15E04
                bne.s   loc_15E12
                move.b  #5,5(a0)

loc_15E12:
                moveq   #0,d0
                move.b  $3A(a0),d0
                lsl.w   #2,d0
                jsr     loc_15E20(pc,d0.w)
                rts

loc_15E20:
                bra.w Snake_MoveRight
                bra.w Snake_MoveLeft
                bra.w Snake_MoveLeft
                bra.w Snake_MoveLeft
                bra.w Snake_MoveUp
                bra.w Snake_MoveUp
                bra.w Snake_MoveDown
                bra.w Snake_StateTurn

; Snake state: moving right on wall
Snake_MoveRight:
                clr.w   6(a0)  ; was: sub_15E40
                bclr    #7,2(a0)
                move.l  (dword_FFD27C).w,$34(a0)
                clr.l   $2C(a0)
                bsr.w Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                beq.s   loc_15E86
                addq.w  #4,d7
                subq.w  #4,d6
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                bne.s   loc_15EA8
                moveq   #0,d7
                moveq   #$FFFFFFFC,d6
                bsr.w Collision_GetTileAtObject
                tst.b   d4
                bne.s   loc_15ED6
                bsr.w Anim_UpdateFrame
                rts

loc_15E86:
                move.b  #6,$3A(a0)
                move.w  $30(a0),d7
                andi.w  #$FFF8,d7
                subq.w  #1,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                move.l  #word_1AC04,$C(a0)
                rts

loc_15EA8:
                move.b  #5,$3A(a0)
                andi.w  #$FFF8,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                addq.w  #4,$20(a0)
                andi.w  #$FFF8,d6
                addq.w  #7,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #word_1ABCC,$C(a0)
                rts

loc_15ED6:
                move.w  #8,$3C(a0)
                move.l  #word_1AC4C,$C(a0)
                rts

; Snake state: moving left on wall
Snake_MoveLeft:
                move.w  #4,6(a0)  ; was: sub_15EE6
                bset    #7,2(a0)
                move.l  (dword_FFD27C).w,d0
                neg.l   d0
                move.l  d0,$34(a0)
                clr.l   $2C(a0)
                bsr.w Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                beq.s   loc_15F32
                subq.w  #4,d7
                addq.w  #4,d6
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                bne.s   loc_15F5A
                moveq   #0,d7
                moveq   #4,d6
                bsr.w Collision_GetTileAtObject
                tst.b   d4
                bne.s   loc_15F8E
                bsr.w Anim_UpdateFrame
                rts

loc_15F32:
                move.b  #5,$3A(a0)
                move.w  $30(a0),d7
                andi.w  #$FFF8,d7
                addq.w  #8,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                move.l  #word_1AC20,$C(a0)
                bclr    #7,2(a0)
                rts

loc_15F5A:
                move.b  #6,$3A(a0)
                andi.w  #$FFF8,d7
                addq.w  #7,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                subq.w  #4,$20(a0)
                andi.w  #$FFF8,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #word_1ABE8,$C(a0)
                bclr    #7,2(a0)
                rts

loc_15F8E:
                move.w  #8,$3C(a0)
                move.l  #word_1AC64,$C(a0)
                rts

; Snake state: moving up on wall
Snake_MoveUp:
                move.w  #8,6(a0)  ; was: sub_15F9E
                bclr    #7,2(a0)
                clr.l   $34(a0)
                move.l  (dword_FFD27C).w,d0
                neg.l   d0
                move.l  d0,$2C(a0)
                bsr.w Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                beq.s   loc_15FDE
                subq.w  #4,d7
                subq.w  #4,d6
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                bne.s   loc_16004
                bsr.w Anim_UpdateFrame
                rts

loc_15FDE:
                clr.b   $3A(a0)
                move.w  $24(a0),d6
                andi.w  #$FFF8,d6
                addq.w  #8,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #word_1AC2E,$C(a0)
                bclr    #7,2(a0)
                rts

loc_16004:
                move.b  #3,$3A(a0)
                andi.w  #$FFF8,d7
                addq.w  #7,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                andi.w  #$FFF8,d6
                addq.w  #7,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #word_1ABDA,$C(a0)
                bclr    #7,2(a0)
                rts

; Snake state: moving down on wall
Snake_MoveDown:
                move.w  #$C,6(a0)  ; was: sub_16036
                bset    #7,2(a0)
                clr.l   $34(a0)
                move.l  (dword_FFD27C).w,$2C(a0)
                bsr.w Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                beq.s   loc_16072
                addq.w  #4,d7
                addq.w  #4,d6
                bsr.w Collision_GetTileAtPos
                tst.b   d4
                bne.s   loc_1609A
                bsr.w Anim_UpdateFrame
                rts

loc_16072:
                move.b  #3,$3A(a0)
                move.w  $24(a0),d6
                andi.w  #$FFF8,d6
                subq.w  #1,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #word_1AC12,$C(a0)
                bclr    #7,2(a0)
                rts

loc_1609A:
                move.b  #0,$3A(a0)
                andi.w  #$FFF8,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                andi.w  #$FFF8,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #word_1ABF6,$C(a0)
                bclr    #7,2(a0)
                rts

; Snake state: turning at corners
Snake_StateTurn:
                bset    #7,$3C(a0)  ; was: sub_160C8
                bne.s   loc_160D6
                move.b  #5,5(a0)

loc_160D6:
                btst    #1,$3A(a0)
                bne.s   loc_16136
                move.w  #$10,6(a0)
                clr.l   $34(a0)
                move.l  (dword_FFD27C).w,d0
                neg.l   d0
                move.l  d0,$2C(a0)
                bsr.w Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subq.w  #8,d6
                bsr.w Collision_GetTileAtPos
                bne.s   loc_1610C
                bsr.w Anim_UpdateFrame
                rts

loc_1610C:
                move.w  #4,$3C(a0)
                bchg    #0,$3A(a0)
                bchg    #1,$3A(a0)
                andi.w  #$FFF8,d6
                addq.w  #7,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #word_1AC64,$C(a0)
                rts

loc_16136:
                move.w  #$14,6(a0)
                clr.l   $34(a0)
                move.l  (dword_FFD27C).w,$2C(a0)
                bsr.w Object_UpdatePosition
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                addq.w  #8,d6
                bsr.w Collision_GetTileAtPos
                bne.s   loc_16160
                bsr.w Anim_UpdateFrame
                rts

loc_16160:
                move.w  #4,$3C(a0)
                bchg    #0,$3A(a0)
                bchg    #1,$3A(a0)
                andi.w  #$FFF8,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #word_1AC4C,$C(a0)
                rts

; Snake state: hit by player bouncing
Snake_StateHit:
                bset    #7,$3C(a0)  ; was: sub_16188
                bne.s   loc_161AA
                move.l  a0,-(sp)
                move.b  #$93,d0
                bsr.w Sound_PlayNoteIfActive
                movea.l (sp)+,a0
                move.w  #$18,6(a0)
                subq.b  #1,(byte_FFD26C).w
                clr.b   5(a0)

loc_161AA:
                bsr.w Chick_UpdatePhysics
                tst.l   $34(a0)
                bne.s   locret_161BA
                move.w  #$10,$3C(a0)

locret_161BA:
                rts

; Snake state: death anim spawns new enemy
Snake_StateDeath:
                bset    #7,$3C(a0)  ; was: sub_161BC
                bne.s   loc_161E0
                bclr    #2,2(a0)
                move.w  #$1C,6(a0)
                clr.b   $10(a0)
                move.l  #$FFFFC000,$2C(a0)
                clr.b   5(a0)

loc_161E0:
                bsr.w Object_UpdatePosition
                bsr.w Anim_UpdateFrame
                btst    #2,2(a0)
                beq.s   locret_16216
                move.b  (dword_FFD888+2).w,d0
                andi.b  #$F0,d0
                bne.s   loc_16212
                lea     (unk_FFC7C0).w,a1
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                move.w  d7,$30(a1)
                move.w  d6,$24(a1)
                move.w  #$28,(a1)

loc_16212:
                bsr.w Sprite_ClearLinkTable

locret_16216:
                rts

; Snake collision with player hit detection
Snake_CheckPlayerHit:
                lea     (unk_FFC200).w,a1  ; was: sub_16218
                moveq   #5,d0

loc_1621E:
                move.w  d0,-(sp)
                btst    #4,5(a1)
                beq.s   loc_1629C
                bsr.w Collision_CheckObjectPair
                tst.b   d0
                beq.s   loc_1629C
                move.w  #$C,$3C(a0)
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
                move.l  dword_162AC(pc,d0.w),d0
                move.l  d0,(dword_FFD262).w
                move.l  a1,-(sp)
                bsr.w Score_AddAndCheck
                movea.l (sp)+,a1
                lea     (unk_FFC0C0).w,a2
                moveq   #3,d0

loc_1626E:
                tst.b   (a2)
                bne.s   loc_16292
                move.w  #$1C,(a2)
                move.b  $3B(a1),d1
                move.b  d1,$3A(a2)
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subq.w  #8,d6
                move.w  d7,$30(a2)
                move.w  d6,$24(a2)
                bra.s   loc_162A8

loc_16292:
                lea     -$40(a2),a2
                dbf     d0,loc_1626E
                bra.s   loc_162A8

loc_1629C:
                lea     $40(a1),a1
                move.w  (sp)+,d0
                dbf     d0,loc_1621E
                rts

loc_162A8:
                move.w  (sp)+,d0
                rts

dword_162AC:    dc.l $200, $400, $800, $1600
off_162BC:      dc.l byte_162DC
                dc.l byte_162E6
                dc.l byte_162F0
                dc.l byte_162F6
                dc.l byte_162FC
                dc.l byte_16302
                dc.l byte_16308
                dc.l byte_154FE
byte_162DC:     dc.b 4, 1
                dc.w word_1AB7C-Sys_GameEntryPoint
                dc.w word_1AB84-Sys_GameEntryPoint
                dc.w word_1AB8C-Sys_GameEntryPoint
                dc.w word_1AB84-Sys_GameEntryPoint
byte_162E6:     dc.b 4, 1
                dc.w word_1AB94-Sys_GameEntryPoint
                dc.w word_1AB9C-Sys_GameEntryPoint
                dc.w word_1ABA4-Sys_GameEntryPoint
                dc.w word_1AB9C-Sys_GameEntryPoint
byte_162F0:     dc.b 2, 1
                dc.w word_1ABAC-Sys_GameEntryPoint
                dc.w word_1ABB4-Sys_GameEntryPoint
byte_162F6:     dc.b 2, 1
                dc.w word_1ABBC-Sys_GameEntryPoint
                dc.w word_1ABC4-Sys_GameEntryPoint
byte_162FC:     dc.b 2, 1
                dc.w word_1AC3C-Sys_GameEntryPoint
                dc.w word_1AC44-Sys_GameEntryPoint
byte_16302:     dc.b 2, 1
                dc.w word_1AC54-Sys_GameEntryPoint
                dc.w word_1AC5C-Sys_GameEntryPoint
byte_16308:     dc.b 4, 1
                dc.w word_1AC6C-Sys_GameEntryPoint
                dc.w word_1AC7A-Sys_GameEntryPoint
                dc.w word_1AC88-Sys_GameEntryPoint
                dc.w word_1AC96-Sys_GameEntryPoint
; Enemy spawner object with countdown timer
