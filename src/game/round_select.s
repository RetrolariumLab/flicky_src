; Round select screen.
; ROM $0125BE-$012655.

RoundSelect_Init:
                bsr.w Sys_InitTitleScreen  ; was: sub_125BE
                lea     (word_16DE8).l,a5
                jsr     unk_FFFBBA
                lea     byte_125E8(pc),a6
                bsr.w Text_DrawString
                move.b  #3,(byte_FFD882).w
                move.b  #1,(byte_FFD29A).w
                jsr     unk_FFFB6C
                jmp     unk_FFFB6C

byte_125E8:     dc.b $C3, $54
aRound:         dc.b "ROUND ",0
                dc.b 0
; Round select: handles up/down input
RoundSelect_Update:
                move.b  (word_FFD82C).w,d1  ; was: sub_125F2
                move.b  #1,d2
                move.b  (word_FFFF8E+1).w,d0
                btst    #0,d0
                beq.s   loc_1261A
                cmpi.b  #$36,d1
                beq.s   loc_12642
                addi.b  #0,d0
                abcd    d2,d1
                addq.b  #1,(word_FFD82C+1).w
                move.b  d1,(word_FFD82C).w
                bra.s   loc_12642

loc_1261A:
                btst    #1,d0
                beq.s   loc_12636
                cmpi.b  #1,d1
                beq.s   loc_12642
                addi.b  #0,d0
                sbcd    d2,d1
                subq.b  #1,(word_FFD82C+1).w
                move.b  d1,(word_FFD82C).w
                bra.s   loc_12642

loc_12636:
                btst    #7,d0
                beq.s   loc_12642
                move.w  #$18,(word_FFFFC0).w

loc_12642:
                lea     (word_FFD82C).w,a6
                moveq   #0,d5
                move.w  #$C360,d5
                moveq   #0,d0
                bsr.w Text_DrawBCDNumber
                jmp     unk_FFFB6C

; Game round init: clears timer, loads level
