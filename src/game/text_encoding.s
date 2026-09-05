; Character-to-tile mapping and random numbers.
; ROM $010DE8-$010E87.

Text_CharToTileIndex:
                movem.l d0-d1,-(sp)  ; was: sub_10DE8
                clr.w   d5
                subi.w  #$20,d4
                bcc.s   loc_10E08
                cmpi.w  #$FFF3,d4
                bne.s   loc_10E02
                move.w  #$79,d4
                moveq   #1,d5
                bra.s   loc_10E3C

loc_10E02:
                addi.w  #$C0,d4
                bra.s   loc_10E3C

loc_10E08:
                moveq   #$40,d0
                cmp.w   d0,d4
                bcs.s   loc_10E3C
                sub.w   d0,d4
                moveq   #$40,d1
                moveq   #$50,d0
                cmp.w   d0,d4
                bcs.s   loc_10E1C
                sub.w   d0,d4
                moveq   #$77,d1

loc_10E1C:
                cmpi.w  #$37,d4
                bcs.s   loc_10E3A
                moveq   #1,d5
                cmpi.w  #$46,d4
                bcs.s   loc_10E36
                cmpi.w  #$4B,d4
                bcc.s   loc_10E34
                addq.w  #5,d4
                bra.s   loc_10E36

loc_10E34:
                moveq   #2,d5

loc_10E36:
                subi.w  #$32,d4

loc_10E3A:
                add.w   d1,d4

loc_10E3C:
                addi.w  #$40,d4
                tst.w   d5
                beq.s   loc_10E48
                addi.w  #$AD,d5

loc_10E48:
                addi.w  #$40,d5
                movem.l (sp)+,d0-d1
                rts

; Gets random byte via trap 0 and rotate
Math_GetRandomByte:
                trap    #0              ; ErrorTrap  ; was: sub_10E52
                ror.l   #8,d1
                rts

; Calculates sum of random values modulo counter
Math_CalcRandomSum:
                movem.l d0-d1/d7,-(sp)  ; was: sub_10E58
                clr.w   (word_FFE630).w
                addq.w  #1,(word_FFE634).w
                move.w  (word_FFE632).w,d7
                subq.w  #1,d7
                bcs.s   loc_10E82

loc_10E6C:
                bsr.s Math_GetRandomByte
                andi.l  #$FFFF,d1
                divu.w  (word_FFE634).w,d1
                swap    d1
                add.w   d1,(word_FFE630).w
                dbf     d7,loc_10E6C

loc_10E82:
                movem.l (sp)+,d0-d1/d7
                rts

; VBlank interrupt entry point with dispatch table
