; VRAM address helpers and RLE tilemap decompression.
; ROM $010D6E-$010DE7.

Gfx_MakeVRAMAddr:
                movem.l d1,-(sp)  ; was: sub_10D6E
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
                movea.l a4,a1  ; was: sub_10D8C
                clr.w   d1

loc_10D90:
                clr.w   d2
                move.b  (a0)+,d2
                beq.s   loc_10DB6
                bclr    #7,d2
                beq.s   loc_10DA8
                subq.b  #1,d2

loc_10D9E:
                move.b  (a0)+,(a1)
                adda.w  d0,a1
                dbf     d2,loc_10D9E
                bra.s   loc_10D90

loc_10DA8:
                subq.b  #1,d2
                move.b  (a0)+,d3

loc_10DAC:
                move.b  d3,(a1)
                adda.w  d0,a1
                dbf     d2,loc_10DAC
                bra.s   loc_10D90

loc_10DB6:
                movea.l a4,a1
                addq.w  #1,d1
                adda.w  d1,a1
                cmp.w   d1,d0
                bhi.s   loc_10D90
                rts

; RLE decompression horizontally to (a4)+ buffer
Data_DecompHorizontalRLE:
                clr.w   d2  ; was: sub_10DC2
                move.b  (a0)+,d2
                beq.s   locret_10DE6
                bclr    #7,d2
                beq.s   loc_10DD8
                subq.b  #1,d2

loc_10DD0:
                move.b  (a0)+,(a4)+
                dbf     d2,loc_10DD0
                bra.s Data_DecompHorizontalRLE

loc_10DD8:
                subq.b  #1,d2
                move.b  (a0)+,d3

loc_10DDC:
                move.b  d3,(a4)+
                addq.b  #1,d3
                dbf     d2,loc_10DDC
                bra.s Data_DecompHorizontalRLE

locret_10DE6:
                rts

; Converts ASCII/Japanese char code to tile indices d4/d5
