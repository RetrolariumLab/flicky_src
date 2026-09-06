; VBlank interrupt handler
; ROM $010E88-$010F23

Int_VBlankHandler:
                move    #$2700,sr                       ; was: sub_10E88
                movem.l d0-d7/a0-a6,-(sp)
                lea     (VDP_CTRL).l,a6
                move.w  (Ram_VBlankRequest).w,d0
                andi.w  #$C,d0
                jsr     Int_VBlankModeTable(pc,d0.w)
                clr.w   (Ram_VBlankRequest).w
                movem.l (sp)+,d0-d7/a0-a6
                rte

Int_VBlankModeTable:                                    ; was: loc_10EAC
                bra.w   Int_VBlank_Return
                bra.w   Int_VBlankMain
                bra.w   Int_VBlankMain

Int_VBlank_Return:                                      ; was: locret_10EB8
                rts

; VBlank main processing: scroll DMA and palette update
Int_VBlankMain:
                bsr.w   Gfx_UpdateScrollRegs            ; was: sub_10EBA
                jsr     j_Input_ProcessJoypads
                move.w  #$F550,d1
                move.w  #$BE00,d2
                move.w  #$200,d0
                jsr     j_Gfx_CopyToVRAM
                moveq   #$F,d7
                lea     (Ram_Palette).w,a0
                lea     (Ram_PaletteBackup).w,a1

Int_VBlankMain_ComparePaletteLoop:                      ; was: loc_10EDC
                cmpm.l  (a0)+,(a1)+
                bne.s   Int_VBlankMain_PaletteChanged
                dbf     d7,Int_VBlankMain_ComparePaletteLoop
                bclr    #0,(Ram_PaletteDirty).w
                bne.s   Int_VBlankMain_TransferPalette
                bra.s   Int_VBlankMain_EnableDisplay

Int_VBlankMain_PaletteChanged:                          ; was: loc_10EEE
                move.b  #1,(Ram_PaletteDirty).w

Int_VBlankMain_TransferPalette:                         ; was: loc_10EF4
                btst    #6,(IO_PCBVER+1).l
                beq.s   Int_VBlankMain_QueuePaletteDMA
                move.w  #$100,d0

Int_VBlankMain_DelayLoop:                               ; was: loc_10F02
                dbf     d0,Int_VBlankMain_DelayLoop

Int_VBlankMain_QueuePaletteDMA:                         ; was: loc_10F06
                move.w  #$F7E0,d1
                moveq   #0,d2
                move.w  #$80,d0
                jsr     j_Gfx_CopyToCRAM

Int_VBlankMain_EnableDisplay:                           ; was: loc_10F14
                move.w  #$8100,d0
                move.b  (Ram_VDPMode2).w,d0
                ori.b   #$40,d0
                move.w  d0,(a6)
                rts

; Converts tilemap row d7 col d6 offset d5 to VDP command
