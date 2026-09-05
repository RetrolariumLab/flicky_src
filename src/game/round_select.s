; Round select screen.
; ROM $0125BE-$012655.

RoundSelect_Init:
                bsr.w   Sys_InitTitleScreen  ; was: sub_125BE
                lea     (Gfx_ScreenInitData).l,a5
                jsr     unk_FFFBBA
                lea     RoundSelect_RoundLabel(pc),a6
                bsr.w   Text_DrawString
                move.b  #3,(byte_FFD882).w
                move.b  #1,(byte_FFD29A).w
                jsr     unk_FFFB6C
                jmp     unk_FFFB6C

RoundSelect_RoundLabel: dc.b    $C3, $54  ; was: byte_125E8
aRound:         dc.b    "ROUND ",0
                dc.b    0
; Round select: handles up/down input
RoundSelect_Update:
                move.b  (word_FFD82C).w,d1  ; was: sub_125F2
                move.b  #1,d2
                move.b  (word_FFFF8E+1).w,d0
                btst    #0,d0
                beq.s   RoundSelect_Update_CheckDown
                cmpi.b  #$36,d1
                beq.s   RoundSelect_Update_DrawNumber
                addi.b  #0,d0
                abcd    d2,d1
                addq.b  #1,(word_FFD82C+1).w
                move.b  d1,(word_FFD82C).w
                bra.s   RoundSelect_Update_DrawNumber

RoundSelect_Update_CheckDown:  ; was: loc_1261A
                btst    #1,d0
                beq.s   RoundSelect_Update_CheckStart
                cmpi.b  #1,d1
                beq.s   RoundSelect_Update_DrawNumber
                addi.b  #0,d0
                sbcd    d2,d1
                subq.b  #1,(word_FFD82C+1).w
                move.b  d1,(word_FFD82C).w
                bra.s   RoundSelect_Update_DrawNumber

RoundSelect_Update_CheckStart:  ; was: loc_12636
                btst    #7,d0
                beq.s   RoundSelect_Update_DrawNumber
                move.w  #$18,(word_FFFFC0).w

RoundSelect_Update_DrawNumber:  ; was: loc_12642
                lea     (word_FFD82C).w,a6
                moveq   #0,d5
                move.w  #$C360,d5
                moveq   #0,d0
                bsr.w   Text_DrawBCDNumber
                jmp     unk_FFFB6C

; Game round init: clears timer, loads level
