; Game-state init, DMA helpers and VRAM fills.
; ROM $000856-$000AD3.

Int_UnusedHandler:
                rte  ; was: nullsub_1

LoadFuncTable:
                lea     func_table(pc),a0
                lea     (EXT).w,a1
                move.w  (a0)+,d0

loc_862:
                move.w  #$4EF9,(a1)+
                moveq   #0,d1
                move.w  (a0)+,d1
                move.l  d1,(a1)+
                dbf     d0,loc_862
                rts

; Initializes RAM areas, VDP registers, checks console version
Sys_InitGameState:
                lea     (unk_FFFF70).w,a6  ; was: sub_872
                moveq   #0,d7
                move.w  #$13,d6

loc_87C:
                move.l  d7,(a6)+
                dbf     d6,loc_87C
                lea     (word_FFF7E0).w,a6
                moveq   #0,d7
                move.w  #$3F,d6

loc_88C:
                move.l  d7,(a6)+
                dbf     d6,loc_88C
                move.w  #4,(word_FFFF98).w
                addq.w  #4,(word_FFFFC0).w
                clr.l   (dword_FFF550).w
                movem.w word_8D4(pc),d0-d5
                movem.w d0-d5,(word_FFFFD8).w
                bsr.w   SetInitialVDPRegs
                btst    #6,(IO_PCBVER+1).l
                beq.s   loc_8C0
                move.b  #$3C,(byte_FFFF71).w

loc_8C0:
                bsr.w   Gfx_WriteVDPRegs
                move.l  #$C0000000,(a6)
                move.w  #0,-4(a6)
                bra.w   Gfx_ClearSpriteArea

word_8D4:       dc.w    $BE00, $B800, $B000, $C000, $E000, $40
; DMA VRAM fill with >$400 byte chunking
DMA_FillVRAMLarge:
                movem.w d0-d2,-(sp)  ; was: sub_8E0
                move.w  #$400,d0
                bsr.s   loc_906
                movem.w (sp)+,d0-d2
                addi.w  #$400,d2
                subi.w  #$400,d0
                cmpi.w  #$400,d0
                bls.s   loc_906
                bra.s   DMA_FillVRAMLarge

; DMA fill setup: initializes d1=0
DMA_FillVRAMSetup:
                moveq   #0,d1  ; was: sub_8FE

loc_900:
                cmpi.w  #$400,d0
                bhi.s   DMA_FillVRAMLarge

loc_906:
                lea     (VDP_CTRL).l,a6
                subq.w  #1,d0
                swap    d1
                move.w  #$8F01,(a6)
                move.w  d0,d1
                andi.w  #$FF,d0
                ori.w   #$9300,d0
                move.w  d0,(a6)
                lsr.w   #8,d1
                ori.w   #$9400,d1
                move.w  d1,(a6)
                swap    d1
                move.w  #$9780,(a6)
                move.l  #$200000,d0
                move.w  d2,d0
                lsl.l   #2,d0
                move.w  d2,d0
                andi.w  #$3FFF,d0
                ori.w   #$4000,d0
                swap    d0
                move.l  d0,(a6)
                move.b  d1,-4(a6)
                bsr.w   DMA_WaitComplete
                move.w  #$8F02,(a6)
                rts

; DMA copy with >$200 byte chunking
DMA_CopyLarge:
                movem.w d0-d2,-(sp)  ; was: sub_954
                move.w  #$200,d0
                bsr.s   loc_97C
                movem.w (sp)+,d0-d2
                addi.w  #$200,d2
                addi.w  #$200,d1
                subi.w  #$200,d0
                cmpi.w  #$200,d0
                bls.s   loc_97C
                bra.s   DMA_CopyLarge

; DMA copy size check entry point
DMA_CopyCheck:
                cmpi.w  #$200,d0  ; was: sub_976
                bhi.s   DMA_CopyLarge

loc_97C:
                lea     (VDP_CTRL).l,a6
                swap    d1
                move.w  #$8F01,(a6)
                move.w  d0,d1
                andi.w  #$FF,d0
                ori.w   #$9300,d0
                move.w  d0,(a6)
                lsr.w   #8,d1
                ori.w   #$9400,d1
                move.w  d1,(a6)
                swap    d1
                move.w  d1,d0
                andi.w  #$FF,d0
                ori.w   #$9500,d0
                move.w  d0,(a6)
                lsr.w   #8,d1
                ori.w   #$9600,d1
                move.w  d1,(a6)
                move.w  #$97C0,(a6)
                move.l  #$300000,d0
                move.w  d2,d0
                lsl.l   #2,d0
                move.w  d2,d0
                andi.w  #$3FFF,d0
                ori.w   #$4000,d0
                swap    d0
                move.l  d0,(a6)
                bsr.w   DMA_WaitComplete
                move.w  #$8F02,(a6)
                rts

; Waits for DMA completion via VDP status
DMA_WaitComplete:
                move.w  (a6),d0  ; was: sub_9D8
                andi.w  #2,d0
                bne.s   DMA_WaitComplete
                rts

; DMA to VRAM with large chunk handling
DMA_ToVRAMLarge:
                movem.w d0-d2,-(sp)  ; was: sub_9E2
                move.w  #$400,d0
                bsr.s   loc_A12
                movem.w (sp)+,d0-d2
                addi.w  #$400,d1
                addi.w  #$400,d2
                subi.w  #$400,d0
                cmpi.w  #$400,d0
                bls.s   loc_A12
                bra.s   DMA_ToVRAMLarge

; DMA transfer to CRAM (palette)
DMA_ToCRAM:
                bsr.s   DMA_SetupRegs  ; was: sub_A04
                ori.w   #$C000,d0
                bra.s   DMA_Commit

; DMA to VRAM size check entry point
DMA_ToVRAMCheck:
                cmpi.w  #$400,d0  ; was: sub_A0C
                bhi.s   DMA_ToVRAMLarge

loc_A12:
                bsr.s   DMA_SetupRegs
                ori.w   #$4000,d0
                bra.s   DMA_Commit

; Sets up DMA registers 93-96
DMA_SetupRegs:
                lea     (VDP_CTRL).l,a6  ; was: sub_A1A
                lsr.w   #1,d0
                swap    d1
                move.w  d0,d1
                andi.w  #$FF,d0
                ori.w   #$9300,d0
                move.w  d0,(a6)
                lsr.w   #8,d1
                ori.w   #$9400,d1
                move.w  d1,(a6)
                swap    d1
                lsr.w   #1,d1
                move.w  d1,d0
                andi.w  #$FF,d0
                ori.w   #$9500,d0
                move.w  d0,(a6)
                lsr.w   #8,d1
                ori.w   #$9680,d1
                move.w  d1,(a6)
                move.w  #$977F,(a6)
                move.l  #$200000,d0
                move.w  d2,d0
                lsl.l   #2,d0
                move.w  d2,d0
                andi.w  #$3FFF,d0
                rts

; Commits DMA command to VDP
DMA_Commit:
                move.w  d0,(a6)  ; was: sub_A66
                swap    d0
                move.w  d0,(word_FFFFAE).w
                move.w  (word_FFFFAE).w,(a6)
                rts

; Fills VRAM area at address d2 with zeros, length d0
Gfx_FillVRAMZero:
                moveq   #0,d1  ; was: sub_A74

; Fills VRAM area at d2 with value d1, length d0
Gfx_FillVRAMValue:
                movem.l d3/a5,-(sp)  ; was: loc_A76
                lea     (VDP_CTRL).l,a6
                lea     VDP_DATA-VDP_CTRL(a6),a5
                move.b  d1,d3
                lsl.w   #8,d3
                move.b  d1,d3
                move.w  d3,d1
                swap    d3
                move.w  d1,d3
                clr.l   d1
                move.w  d2,d1
                lsl.l   #2,d1
                move.w  d2,d1
                andi.w  #$3FFF,d1
                ori.w   #$4000,d1
                swap    d1
                move.l  d1,(a6)
                addq.w  #3,d0
                lsr.w   #2,d0
                move.w  d0,d1
                lsr.w   #3,d1
                bra.s   loc_ABE

loc_AAE:
                move.l  d3,(a5)
                move.l  d3,(a5)
                move.l  d3,(a5)
                move.l  d3,(a5)
                move.l  d3,(a5)
                move.l  d3,(a5)
                move.l  d3,(a5)
                move.l  d3,(a5)

loc_ABE:
                dbf     d1,loc_AAE
                andi.w  #7,d0
                bra.s   loc_ACA

loc_AC8:
                move.l  d3,(a5)

loc_ACA:
                dbf     d0,loc_AC8
                movem.l (sp)+,d3/a5
                rts
