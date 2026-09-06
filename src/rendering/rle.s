; VRAM address helpers and RLE tilemap decompression
; ROM $010D6E-$010DE7

Gfx_MakeVRAMAddr:
                movem.l d1,-(sp)                        ; was: sub_10D6E
                clr.l   d1
                move.w  d0,d1
                lsl.l   #2,d1
                move.w  d0,d1
                andi.w  #$3FFF,d1
                ori.w   #$4000,d1
                swap    d1
                move.l  d1,d0
                movem.l (sp)+,d1
                rts

; RLE decompression to vertical columns with stride d0
Data_DecompVerticalRLE:
                movea.l a4,a1                           ; was: sub_10D8C
                clr.w   d1

Data_DecompVerticalRLE_NextRun:                         ; was: loc_10D90
                clr.w   d2
                move.b  (a0)+,d2
                beq.s   Data_DecompVerticalRLE_NextColumn
                bclr    #7,d2
                beq.s   Data_DecompVerticalRLE_RepeatSetup
                subq.b  #1,d2

Data_DecompVerticalRLE_LiteralLoop:                     ; was: loc_10D9E
                move.b  (a0)+,(a1)
                adda.w  d0,a1
                dbf     d2,Data_DecompVerticalRLE_LiteralLoop
                bra.s   Data_DecompVerticalRLE_NextRun

Data_DecompVerticalRLE_RepeatSetup:                     ; was: loc_10DA8
                subq.b  #1,d2
                move.b  (a0)+,d3

Data_DecompVerticalRLE_RepeatLoop:                      ; was: loc_10DAC
                move.b  d3,(a1)
                adda.w  d0,a1
                dbf     d2,Data_DecompVerticalRLE_RepeatLoop
                bra.s   Data_DecompVerticalRLE_NextRun

Data_DecompVerticalRLE_NextColumn:                      ; was: loc_10DB6
                movea.l a4,a1
                addq.w  #1,d1
                adda.w  d1,a1
                cmp.w   d1,d0
                bhi.s   Data_DecompVerticalRLE_NextRun
                rts

; RLE decompression horizontally to (a4)+ buffer
Data_DecompHorizontalRLE:
                clr.w   d2                              ; was: sub_10DC2
                move.b  (a0)+,d2
                beq.s   Data_DecompHorizontalRLE_Return
                bclr    #7,d2
                beq.s   Data_DecompHorizontalRLE_RunSetup
                subq.b  #1,d2

Data_DecompHorizontalRLE_LiteralLoop:                   ; was: loc_10DD0
                move.b  (a0)+,(a4)+
                dbf     d2,Data_DecompHorizontalRLE_LiteralLoop
                bra.s   Data_DecompHorizontalRLE

Data_DecompHorizontalRLE_RunSetup:                      ; was: loc_10DD8
                subq.b  #1,d2
                move.b  (a0)+,d3

Data_DecompHorizontalRLE_IncrementLoop:                 ; was: loc_10DDC
                move.b  d3,(a4)+
                addq.b  #1,d3
                dbf     d2,Data_DecompHorizontalRLE_IncrementLoop
                bra.s   Data_DecompHorizontalRLE

Data_DecompHorizontalRLE_Return:                        ; was: locret_10DE6
                rts

; Converts ASCII/Japanese char code to tile indices d4/d5
