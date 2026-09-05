; VDP registers, sprite area, tilemap writes, palette fade.
; ROM $000E42-$001013.

Gfx_LoadVDPRegsAlt:
                lea     byte_E6E(pc),a1  ; was: sub_E42
                bra.s   loc_E4C

SetInitialVDPRegs:
                lea     initial_vdp_regs(pc),a1

loc_E4C:
                lea     (unk_FFFF70).w,a2
                moveq   #$12,d7

loc_E52:
                move.b  (a1)+,(a2)+
                dbf     d7,loc_E52
                rts

initial_vdp_regs:dc.b    4, $34, $30, $2C, 7, $5F, 0, 0, 0, 0
                dc.b    $30, 2, 0, $2E, 0, 2, 0, 0, 0, 0
byte_E6E:       dc.b    4, $14, $30, $2C, 7, $54, 0, 0, 0, 0
                dc.b    $30, 0, $81, $2B, 0, 2, 1, 0, 0, 0
; Writes VDP registers 0-18 from RAM buffer
Gfx_WriteVDPRegs:
                lea     (unk_FFFF70).w,a1  ; was: sub_E82
                lea     (VDP_CTRL).l,a6
                move.w  #$8000,d7

loc_E90:
                move.w  d7,d0
                move.b  (a1)+,d0
                move.w  d0,(a6)
                addi.w  #$100,d7
                cmpi.w  #$9300,d7
                bcs.s   loc_E90
                rts

; Clears sprite table VRAM area and sprite variables
Gfx_ClearSpriteArea:
                move.w  #$B000,d2  ; was: sub_EA2
                move.w  #$5000,d0
                bsr.w   Gfx_FillVRAMZero
                clr.l   (dword_FFFFA4).w
                clr.l   (dword_FFFFA8).w
                lea     (dword_FFF550).w,a6
                moveq   #0,d7
                move.w  #$7F,d6

loc_EC0:
                move.l  d7,(a6)+
                dbf     d6,loc_EC0
                rts

; Writes tilemap rows to VRAM
Gfx_WriteTilemapBlock:
                lea     (VDP_CTRL).l,a2  ; was: sub_EC8
                lea     (VDP_DATA).l,a3
                move.l  #$800000,d7

loc_EDA:
                move.l  d0,(a2)
                move.w  d1,d4

loc_EDE:
                move.w  (a1)+,(a3)
                dbf     d4,loc_EDE
                add.l   d7,d0
                dbf     d2,loc_EDA
                rts

; Fills tilemap area with repeated value
Gfx_FillTilemapArea:
                lea     (VDP_CTRL).l,a2  ; was: sub_EEC
                lea     (VDP_DATA).l,a3
                move.l  #$800000,d5

loc_EFE:
                move.l  d0,(a2)
                move.w  d1,d3

loc_F02:
                move.w  d4,(a3)
                dbf     d3,loc_F02
                add.l   d5,d0
                dbf     d2,loc_EFE
                rts

; Sets VRAM write address for tile index d0
Gfx_SetTileWriteAddr:
                asl.w   #5,d0  ; was: sub_F10

; Sets VRAM write address from d0
Gfx_SetVRAMWriteAddr:
                clr.l   d1  ; was: sub_F12
                move.w  d0,d1
                lsl.l   #2,d1
                move.w  d0,d1
                andi.w  #$3FFF,d1
                ori.w   #$4000,d1
                swap    d1
                move.l  d1,(a6)
                rts

; Converts tile index to VDP write command
Gfx_TileToVDPCmd:
                asl.w   #5,d0  ; was: sub_F28

loc_F2A:
                clr.l   d1
                move.w  d0,d1
                lsl.l   #2,d1
                move.w  d0,d1
                andi.w  #$3FFF,d1
                swap    d1
                move.l  d1,(a6)
                rts

; Waits for VBlank interrupt to complete
Sys_WaitVBlank:
                move.w  (word_FFFF98).w,(word_FFFF96).w  ; was: sub_F3C

loc_F42:
                tst.w   (word_FFFF96).w
                bne.s   loc_F42
                rts

RandomNumber:
                move.l  (dword_FFFFCA).w,d1
                bne.s   loc_F56
                move.l  #'*m6Z',d1

loc_F56:
                move.l  d1,d0
                asl.l   #2,d1
                add.l   d0,d1
                asl.l   #3,d1
                add.l   d0,d1
                move.w  d1,d0
                swap    d1
                add.w   d1,d0
                move.w  d0,d1
                swap    d1
                move.l  d1,(dword_FFFFCA).w
                rts

; Fades palette colors by factor d2 (0-64)
Gfx_FadePalette:
                movem.l d2-d5,-(sp)  ; was: sub_F70
                moveq   #$40,d0
                cmp.w   d0,d2
                bcs.s   loc_F92
                tst.w   d3
                beq.s   loc_F82
                cmp.w   d2,d3
                bcs.s   loc_F86

loc_F82:
                move.w  d0,d2
                bra.s   loc_F92

loc_F86:
                sub.w   d3,d2
                neg.w   d2
                add.w   d0,d2
                cmp.w   d2,d0
                bcc.s   loc_F92
                moveq   #0,d2

loc_F92:
                lea     (word_FFF7E0).w,a0
                lea     (unk_FFF860).w,a1
                cmpi.w  #$40,d2
                bne.s   loc_FAA
                moveq   #$1F,d4

loc_FA2:
                move.l  (a1)+,(a0)+
                dbf     d4,loc_FA2
                bra.s   loc_FCE

loc_FAA:
                moveq   #$3F,d4

loc_FAC:
                move.w  (a1)+,d0
                rol.w   #4,d0
                moveq   #0,d3
                moveq   #2,d5

loc_FB4:
                lsl.w   #4,d3
                rol.w   #4,d0
                move.w  d0,d1
                andi.w  #$F,d1
                mulu.w  d2,d1
                lsr.w   #6,d1
                or.w    d1,d3
                dbf     d5,loc_FB4
                move.w  d3,(a0)+
                dbf     d4,loc_FAC

loc_FCE:
                move.w  d2,d0
                movem.l (sp)+,d2-d5
                rts

; Selectively copies palette entries by bitmask
Gfx_ApplyPaletteMask:
                cmpi.w  #$40,d0  ; was: sub_FD6
                beq.s   locret_FFE
                lea     (unk_FFF860).w,a0
                lea     (word_FFF7E0).w,a1
                movem.l (dword_FFFFB8).w,d0-d1
                moveq   #$3F,d2

loc_FEC:
                roxl.l  #1,d1
                roxl.l  #1,d0
                bcc.s   loc_FF6
                move.w  (a0)+,(a1)+
                bra.s   loc_FFA

loc_FF6:
                addq.w  #2,a0
                addq.w  #2,a1

loc_FFA:
                dbf     d2,loc_FEC

locret_FFE:
                rts

; Copies palette to backup buffer and clears
Gfx_BackupPalette:
                lea     (word_FFF7E0).w,a0  ; was: sub_1000
                lea     (unk_FFF860).w,a1
                moveq   #$1F,d0

loc_100A:
                move.l  (a0),(a1)+
                clr.l   (a0)+
                dbf     d0,loc_100A
                rts
