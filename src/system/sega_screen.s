; Sega logo screen and its compressed art
; ROM $000402-$000855

Gfx_ClearVRAMAndCRAM:
                move.l  #$C0000000,(VDP_CTRL).l         ; was: sub_402
                moveq   #$3F,d0

Gfx_ClearVRAMAndCRAM_CRAMLoop:                          ; was: loc_40E
                move.w  #0,(VDP_DATA).l
                dbf     d0,Gfx_ClearVRAMAndCRAM_CRAMLoop
                move.l  #$40000000,(VDP_CTRL).l
                lea     (VDP_DATA).l,a5
                move.w  #0,d6
                move.w  #$53FF,d7

Gfx_ClearVRAMAndCRAM_VRAMLoop:                          ; was: loc_432
                move.w  d6,(a5)
                dbf     d7,Gfx_ClearVRAMAndCRAM_VRAMLoop
                rts

; Initializes single VDP register from table
Gfx_InitVDPRegister:
                movem.l d1-d2/a1,-(sp)                  ; was: sub_43A
                lea     Gfx_VDPProbeTable(pc),a1
                move.b  (a1),6(a0)
                moveq   #0,d0
                moveq   #8,d1

Gfx_InitVDPRegister_ProbeLoop:                          ; was: loc_44A
                move.b  (a1)+,(a0)
                nop
                nop
                move.b  (a0),d2
                and.b   (a1)+,d2
                beq.s   Gfx_InitVDPRegister_NextBit
                or.b    d1,d0

Gfx_InitVDPRegister_NextBit:                            ; was: loc_458
                lsr.b   #1,d1
                bne.s   Gfx_InitVDPRegister_ProbeLoop
                clr.b   6(a0)
                movem.l (sp)+,d1-d2/a1
                rts

Gfx_VDPProbeTable:      dc.b    $40, $C, $40, 3, 0, $C, 0, 3  ; was: byte_466
LoadSegaScreen:
                bsr.w   Sys_InitGameState
                lea     SegaScreenData(pc),a5           ; palette cycle data?
                bsr.w   Gfx_LoadFullTilemap
                move.w  #$B4,d1
                moveq   #0,d2

LoadSegaScreen_WaitLoop:                                ; was: loc_480
                bsr.w   Sys_WaitVBlank
                subq.w  #1,d1
                move.w  d1,d0
                andi.w  #3,d0
                bne.s   LoadSegaScreen_WaitLoop
                cmpi.w  #$28,d2
                bgt.s   LoadSegaScreen_Return
                move.w  d2,d3
                addq.w  #2,d2
                lea     (Ram_PaletteEntry2).w,a1
                moveq   #$A,d7

LoadSegaScreen_PaletteLoop:                             ; was: loc_49E
                cmpi.w  #$28,d3
                blt.s   LoadSegaScreen_PaletteWrap
                moveq   #0,d3

LoadSegaScreen_PaletteWrap:                             ; was: loc_4A6
                move.w  sega_pal(pc,d3.w),(a1)+
                addq.w  #2,d3
                dbf     d7,LoadSegaScreen_PaletteLoop
                bra.s   LoadSegaScreen_WaitLoop

LoadSegaScreen_Return:                                  ; was: locret_4B2
                rts

sega_pal:       dc.b    $E, $C0, $E, $A0, $E, $80, $E, $60, $E, $40
                dc.b    $E, $20, $E, 0, $C, 0, $A, 0, 8, 0
                dc.b    6, 0, 8, 0, $A, 0, $C, 0, $E, 0
                dc.b    $E, $20, $E, $40, $E, $60, $E, $80, $E, $A0
SegaScreen:
                btst    #7,(Ram_Joypad+1).w
                bne.s   SegaScreen_SkipDelay
                cmpi.w  #$78,(Ram_FrameCounter).w
                bcs.s   SegaScreen_PlaySound

SegaScreen_SkipDelay:                                   ; was: loc_4EC
                move.w  #0,(Ram_NextGameMode).w

SegaScreen_PlaySound:                                   ; was: loc_4F2
                bra.w   Sound_QueueSFX

SegaScreenData:                                         ; was: word_4F6
SegaPalette:    binclude "data/other/data_SegaPalette.bin"
SegaPalette_End:
; Tilemap header for SEGA screen (read by Gfx_ReadTilemapHeader)
SegaTilemapHeader:
                dc.w    $E316                           ; position X
                dc.w    $0001                           ; position Y
                dc.b    $0C                             ; width adjustment
                dc.b    $04                             ; height adjustment
SegaEnigma:     binclude "data/arteni/data_SegaEnigma.bin"
SegaEnigma_End:
SegaTiles:      binclude "data/artnem/data_SegaTiles.bin"
SegaTiles_End:
; Unused interrupt handler (RTE)
