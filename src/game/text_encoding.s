; Character-to-tile mapping and random numbers.
; ROM $010DE8-$010E87.

Text_CharToTileIndex:
                movem.l d0-d1,-(sp)  ; was: sub_10DE8
                clr.w   d5
                subi.w  #$20,d4
                bcc.s   Text_CharToTileIndex_Printable
                cmpi.w  #$FFF3,d4
                bne.s   Text_CharToTileIndex_Punctuation
                move.w  #$79,d4
                moveq   #1,d5
                bra.s   Text_CharToTileIndex_Finish

Text_CharToTileIndex_Punctuation:  ; was: loc_10E02
                addi.w  #$C0,d4
                bra.s   Text_CharToTileIndex_Finish

Text_CharToTileIndex_Printable:  ; was: loc_10E08
                moveq   #$40,d0
                cmp.w   d0,d4
                bcs.s   Text_CharToTileIndex_Finish
                sub.w   d0,d4
                moveq   #$40,d1
                moveq   #$50,d0
                cmp.w   d0,d4
                bcs.s   Text_CharToTileIndex_CheckRange
                sub.w   d0,d4
                moveq   #$77,d1

Text_CharToTileIndex_CheckRange:  ; was: loc_10E1C
                cmpi.w  #$37,d4
                bcs.s   Text_CharToTileIndex_AddBase
                moveq   #1,d5
                cmpi.w  #$46,d4
                bcs.s   Text_CharToTileIndex_AdjustBank
                cmpi.w  #$4B,d4
                bcc.s   Text_CharToTileIndex_ThirdBank
                addq.w  #5,d4
                bra.s   Text_CharToTileIndex_AdjustBank

Text_CharToTileIndex_ThirdBank:  ; was: loc_10E34
                moveq   #2,d5

Text_CharToTileIndex_AdjustBank:  ; was: loc_10E36
                subi.w  #$32,d4

Text_CharToTileIndex_AddBase:  ; was: loc_10E3A
                add.w   d1,d4

Text_CharToTileIndex_Finish:  ; was: loc_10E3C
                addi.w  #$40,d4
                tst.w   d5
                beq.s   Text_CharToTileIndex_Return
                addi.w  #$AD,d5

Text_CharToTileIndex_Return:  ; was: loc_10E48
                addi.w  #$40,d5
                movem.l (sp)+,d0-d1
                rts

; Gets random byte via trap 0 and rotate
Math_GetRandomByte:
                trap    #0  ; ErrorTrap  ; was: sub_10E52
                ror.l   #8,d1
                rts

; Calculates sum of random values modulo counter
Math_CalcRandomSum:
                movem.l d0-d1/d7,-(sp)  ; was: sub_10E58
                clr.w   (Ram_DecompCodeTable).w
                addq.w  #1,(Ram_RandomDivisor).w
                move.w  (Ram_RandomCount).w,d7
                subq.w  #1,d7
                bcs.s   Math_CalcRandomSum_Done

Math_CalcRandomSum_Loop:  ; was: loc_10E6C
                bsr.s   Math_GetRandomByte
                andi.l  #$FFFF,d1
                divu.w  (Ram_RandomDivisor).w,d1
                swap    d1
                add.w   d1,(Ram_DecompCodeTable).w
                dbf     d7,Math_CalcRandomSum_Loop

Math_CalcRandomSum_Done:  ; was: loc_10E82
                movem.l (sp)+,d0-d1/d7
                rts

; VBlank interrupt entry point with dispatch table
