; VBlank interrupt handler.
; ROM $010E88-$010F23.

Int_VBlankHandler:
                move    #$2700,sr  ; was: sub_10E88
                movem.l d0-d7/a0-a6,-(sp)
                lea     (VDP_CTRL).l,a6
                move.w  (word_FFFF96).w,d0
                andi.w  #$C,d0
                jsr     loc_10EAC(pc,d0.w)
                clr.w   (word_FFFF96).w
                movem.l (sp)+,d0-d7/a0-a6
                rte

loc_10EAC:
                bra.w   locret_10EB8
                bra.w Int_VBlankMain
                bra.w Int_VBlankMain

locret_10EB8:
                rts

; VBlank main processing: scroll DMA and palette update
Int_VBlankMain:
                bsr.w Gfx_UpdateScrollRegs  ; was: sub_10EBA
                jsr     unk_FFFB12
                move.w  #$F550,d1
                move.w  #$BE00,d2
                move.w  #$200,d0
                jsr     unk_FFFACA
                moveq   #$F,d7
                lea     (word_FFF7E0).w,a0
                lea     (unk_FFF860).w,a1

loc_10EDC:
                cmpm.l  (a0)+,(a1)+
                bne.s   loc_10EEE
                dbf     d7,loc_10EDC
                bclr    #0,(byte_FFD00C).w
                bne.s   loc_10EF4
                bra.s   loc_10F14

loc_10EEE:
                move.b  #1,(byte_FFD00C).w

loc_10EF4:
                btst    #6,(IO_PCBVER+1).l
                beq.s   loc_10F06
                move.w  #$100,d0

loc_10F02:
                dbf     d0,loc_10F02

loc_10F06:
                move.w  #$F7E0,d1
                moveq   #0,d2
                move.w  #$80,d0
                jsr     unk_FFFAC4

loc_10F14:
                move.w  #$8100,d0
                move.b  (byte_FFFF71).w,d0
                ori.b   #$40,d0
                move.w  d0,(a6)
                rts

; Converts tilemap row d7 col d6 offset d5 to VDP command
