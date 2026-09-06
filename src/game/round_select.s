; Round select screen
; ROM $0125BE-$012655

RoundSelect_Init:
                bsr.w   Sys_InitTitleScreen             ; was: sub_125BE
                lea     (Gfx_SharedPalette).l,a5
                jsr     j_Gfx_LoadPaletteCompact
                lea     RoundSelect_RoundLabel(pc),a6
                bsr.w   Text_DrawString
                move.b  #3,(Ram_Lives).w
                move.b  #1,(Ram_ShowLeadingZeros).w
                jsr     j_Sound_QueueSFX
                jmp     j_Sound_QueueSFX

RoundSelect_RoundLabel: dc.b    $C3, $54                ; was: byte_125E8
RoundSelect_RoundText:  dc.b    "ROUND ",0
                dc.b    0
; Round select: handles up/down input
RoundSelect_Update:
                move.b  (Ram_RoundNumber).w,d1          ; was: sub_125F2
                move.b  #1,d2
                move.b  (Ram_Joypad+1).w,d0
                btst    #0,d0
                beq.s   RoundSelect_Update_CheckDown
                cmpi.b  #$36,d1
                beq.s   RoundSelect_Update_DrawNumber
                addi.b  #0,d0
                abcd    d2,d1
                addq.b  #1,(Ram_RoundNumber+1).w
                move.b  d1,(Ram_RoundNumber).w
                bra.s   RoundSelect_Update_DrawNumber

RoundSelect_Update_CheckDown:                           ; was: loc_1261A
                btst    #1,d0
                beq.s   RoundSelect_Update_CheckStart
                cmpi.b  #1,d1
                beq.s   RoundSelect_Update_DrawNumber
                addi.b  #0,d0
                sbcd    d2,d1
                subq.b  #1,(Ram_RoundNumber+1).w
                move.b  d1,(Ram_RoundNumber).w
                bra.s   RoundSelect_Update_DrawNumber

RoundSelect_Update_CheckStart:                          ; was: loc_12636
                btst    #7,d0
                beq.s   RoundSelect_Update_DrawNumber
                move.w  #$18,(Ram_NextGameMode).w

RoundSelect_Update_DrawNumber:                          ; was: loc_12642
                lea     (Ram_RoundNumber).w,a6
                moveq   #0,d5
                move.w  #$C360,d5
                moveq   #0,d0
                bsr.w   Text_DrawBCDNumber
                jmp     j_Sound_QueueSFX

; Game round init: clears timer, loads level
