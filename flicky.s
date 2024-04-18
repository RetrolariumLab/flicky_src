    cpu 68000
    supmode on
    padding off
    include "flicky_equals.inc"
    include "flicky_rams.inc"
    include "flicky_externs.inc"
    include "flicky_funcs.inc"

; segment "ROM"
; ROM segment
off_0:          dc.l unk_FFFF70
                dc.l EntryPoint
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l EXT
                dc.l ErrorTrap
                dc.l HBLANK
                dc.l ErrorTrap
                dc.l VBLANK
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
                dc.l ErrorTrap
CopyRights:     dc.b "SEGA MEGA DRIVE (C)SEGA 1991.FEB"
DomesticName:   dc.b "FLICKY                                                         "
                dc.b " FLICKY                          GM 00001022-00"
Checksum:       dc.w $B7E0
Peripherials:   dc.b "J               "
RomStart:       dc.l         0
RomEnd:         dc.l byte_1FFFF
RamStart:       dc.l M68K_RAM
RamEnd:         dc.l dword_FFFFFC+3
SramCode:       dc.b "            "
ModemCode:      dc.b "            "
Reserved:       dc.b "                                        "
CountryCode:    dc.b "JUE             "
ErrorTrap:
                nop
                nop
                bra.s   ErrorTrap
EntryPoint:
                tst.l   (IO_CT1_CTRL).l
                bne.s   port_A_ok
                tst.w   (IO_EXT_CTRL).l

port_A_ok:
                bne.s   skip_setup
                lea     SetupValues(pc),a5
                movem.w (a5)+,d5-d7
                movem.l (a5)+,a0-a4
                move.b  -$10FF(a1),d0
                andi.b  #$F,d0
                beq.s   skip_security
                move.l  #'SEGA',$2F00(a1)

skip_security:
                move.w  (a4),d0
                moveq   #0,d0
                movea.l d0,a6
                move    a6,usp
                moveq   #$17,d1

vdp_init_loop:
                move.b  (a5)+,d5
                move.w  d5,(a4)
                add.w   d7,d5
                dbf     d1,vdp_init_loop
                move.l  (a5)+,(a4)
                move.w  d0,(a3)
                move.w  d7,(a1)
                move.w  d7,(a2)

wait_for_z80:
                btst    d0,(a1)
                bne.s   wait_for_z80
                moveq   #$25,d2

z80_init_loop:
                move.b  (a5)+,(a0)+
                dbf     d2,z80_init_loop
                move.w  d0,(a2)
                move.w  d0,(a1)
                move.w  d7,(a2)

clr_ram_loop:
                move.l  d0,-(a6)
                dbf     d6,clr_ram_loop
                move.l  (a5)+,(a4)
                move.l  (a5)+,(a4)
                moveq   #$1F,d3

clr_cram_loop:
                move.l  d0,(a3)
                dbf     d3,clr_cram_loop
                move.l  (a5)+,(a4)
                moveq   #$13,d4

clr_vsram_loop:
                move.l  d0,(a3)
                dbf     d4,clr_vsram_loop
                moveq   #3,d5

psg_init_loop:
                move.b  (a5)+,$11(a3)
                dbf     d5,psg_init_loop
                move.w  d0,(a2)
                movem.l (a6),d0-d7/a0-a6
                move    #$2700,sr

skip_setup:
                bra.s   GameProgram
SetupValues:
                dc.w $8000
                dc.w $3FFF
                dc.w $100
                dc.l Z80_RAM
                dc.l IO_Z80BUS
                dc.l IO_Z80RES
                dc.l VDP_DATA
                dc.l VDP_CTRL
                dc.b 4, $14, $30, $3C, 7, $6C, 0, 0
                dc.b 0, 0, $FF, 0, $81, $37, 0, 1
                dc.b 1, 0, 0, $FF, $FF, 0, 0, $80
                dc.l $40000080
                dc.b $AF, 1, $D9, $1F, $11, $27, 0, $21
                dc.b $26, 0, $F9, $77, $ED, $B0, $DD, $E1
                dc.b $FD, $E1, $ED, $47, $ED, $4F, $D1, $E1
                dc.b $F1, 8, $D9, $C1, $D1, $E1, $F1, $F9
                dc.b $F3, $ED, $56, $36, $E9, $E9
                dc.l $81048F02
                dc.l $C0000000
                dc.l $40000010
                dc.b $9F,$BF,$DF,$FF

GameProgram:
                tst.w   (VDP_CTRL).l
                move    #$2700,sr
                move.b  (IO_PCBVER+1).l,d0
                andi.b  #$F,d0
                beq.s   checksum_check
                move.l  #'SEGA',(IO_TMSS).l

checksum_check:
                movea.l #RomEnd,a0
                move.l  (a0),d1
                addq.l  #1,d1
                movea.l #ErrorTrap,a0
                sub.l   a0,d1
                asr.l   #1,d1
                move.w  d1,d2
                subq.w  #1,d2
                swap    d1
                moveq   #0,d0

checksum_loop:
                add.w   (a0)+,d0
                dbf     d2,checksum_loop
                dbf     d1,checksum_loop
                cmp.w   (Checksum).w,d0
                beq.s   CheckSumOk
                bra.w   CheckSumError

CheckSumOk:
                btst    #6,(IO_EXT_CTRL+1).l
                bne.s   loc_3AA
                move    #$2700,sr
                lea     ((IO_CT1_DATA+1)).l,a0
                bsr.w   sub_43A
                cmpi.b  #0,d0
                beq.s   loc_374
                nop
                nop
                nop
                nop
                nop

loc_374:
                moveq   #$40,d0
                move.b  d0,(IO_CT1_CTRL+1).l
                move.b  d0,(IO_CT2_CTRL+1).l
                move.b  d0,(IO_EXT_CTRL+1).l

loc_388:
                lea     (M68K_RAM).l,a6
                moveq   #0,d7
                move.w  #$3FFF,d6

loc_394:
                move.l  d7,(a6)+
                dbf     d6,loc_394
                move.l  #'init',(dword_FFFFFC).w
                move.l  #$100000,(dword_FFCC00).w

loc_3AA:
                cmpi.l  #'init',(dword_FFFFFC).w
                bne.s   loc_388
                bsr.w   LoadFuncTable
                bsr.w   SetInitialVDPRegs
                bsr.w   sub_E82
                bsr.w   sub_402
                bsr.w   LoadZ80Driver
                lea     (sub_10000).l,a0
                lea     (M68K_RAM).l,a1
                move.w  #$2FFF,d0

loc_3D8:
                move.l  (a0)+,(a1)+
                dbf     d0,loc_3D8
                jmp     M68K_RAM

CheckSumError:
                bsr.w   sub_402
                move.l  #$C0000000,(VDP_CTRL).l
                moveq   #$3F,d7

fill_red_screen:
                move.w  #$E,(VDP_DATA).l
                dbf     d7,fill_red_screen

endless_loop:
                bra.s   endless_loop

sub_402:
                move.l  #$C0000000,(VDP_CTRL).l
                moveq   #$3F,d0

loc_40E:
                move.w  #0,(VDP_DATA).l
                dbf     d0,loc_40E
                move.l  #$40000000,(VDP_CTRL).l
                lea     (VDP_DATA).l,a5
                move.w  #0,d6
                move.w  #$53FF,d7

loc_432:
                move.w  d6,(a5)
                dbf     d7,loc_432
                rts

sub_43A:
                movem.l d1-d2/a1,-(sp)
                lea     byte_466(pc),a1
                move.b  (a1),6(a0)
                moveq   #0,d0
                moveq   #8,d1

loc_44A:
                move.b  (a1)+,(a0)
                nop
                nop
                move.b  (a0),d2
                and.b   (a1)+,d2
                beq.s   loc_458
                or.b    d1,d0

loc_458:
                lsr.b   #1,d1
                bne.s   loc_44A
                clr.b   6(a0)
                movem.l (sp)+,d1-d2/a1
                rts

byte_466:       dc.b $40, $C, $40, 3, 0, $C, 0, 3
LoadSegaScreen:
                bsr.w   sub_872
                lea     word_4F6(pc),a5 ; palette cycle data?
                bsr.w   sub_1280
                move.w  #$B4,d1
                moveq   #0,d2

loc_480:
                bsr.w   sub_F3C
                subq.w  #1,d1
                move.w  d1,d0
                andi.w  #3,d0
                bne.s   loc_480
                cmpi.w  #$28,d2
                bgt.s   locret_4B2
                move.w  d2,d3
                addq.w  #2,d2
                lea     (unk_FFF7E4).w,a1
                moveq   #$A,d7

loc_49E:
                cmpi.w  #$28,d3
                blt.s   loc_4A6
                moveq   #0,d3

loc_4A6:
                move.w  sega_pal(pc,d3.w),(a1)+
                addq.w  #2,d3
                dbf     d7,loc_49E
                bra.s   loc_480

locret_4B2:
                rts

sega_pal:       binclude "data/palettes/sega-fade.bin"
SegaScreen:
                btst    #7,(word_FFFF8E+1).w
                bne.s   loc_4EC
                cmpi.w  #$78,(word_FFFF92).w
                bcs.s   loc_4F2

loc_4EC:
                move.w  #0,(word_FFFFC0).w

loc_4F2:
                bra.w   sub_1114

word_4F6:       binclude "data/other/data_SegaPalette.bin",$0,$12  ; rom-asset dc.w
                binclude "data/other/data_SegaPalette.bin",$12,$2  ; rom-asset dc.b
                dc.b $E3, $16, $00, $01, $0C, $04
                binclude "data/arteni/data_SegaEnigma.bin"
sega_tiles:     binclude "data/artnem/data_SegaTiles.bin",$0,$33C
nullsub_1:
                rte

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

sub_872:
                lea     (unk_FFFF70).w,a6
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
                bsr.w   sub_E82
                move.l  #$C0000000,(a6)
                move.w  #0,-4(a6)
                bra.w   sub_EA2

word_8D4:       dc.w $BE00, $B800, $B000, $C000, $E000, $40
sub_8E0:
                movem.w d0-d2,-(sp)
                move.w  #$400,d0
                bsr.s   loc_906
                movem.w (sp)+,d0-d2
                addi.w  #$400,d2
                subi.w  #$400,d0
                cmpi.w  #$400,d0
                bls.s   loc_906
                bra.s   sub_8E0

sub_8FE:
                moveq   #0,d1

loc_900:
                cmpi.w  #$400,d0
                bhi.s   sub_8E0

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
                bsr.w   sub_9D8
                move.w  #$8F02,(a6)
                rts

sub_954:
                movem.w d0-d2,-(sp)
                move.w  #$200,d0
                bsr.s   loc_97C
                movem.w (sp)+,d0-d2
                addi.w  #$200,d2
                addi.w  #$200,d1
                subi.w  #$200,d0
                cmpi.w  #$200,d0
                bls.s   loc_97C
                bra.s   sub_954

sub_976:
                cmpi.w  #$200,d0
                bhi.s   sub_954

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
                bsr.w   sub_9D8
                move.w  #$8F02,(a6)
                rts

sub_9D8:
                move.w  (a6),d0
                andi.w  #2,d0
                bne.s   sub_9D8
                rts

sub_9E2:
                movem.w d0-d2,-(sp)
                move.w  #$400,d0
                bsr.s   loc_A12
                movem.w (sp)+,d0-d2
                addi.w  #$400,d1
                addi.w  #$400,d2
                subi.w  #$400,d0
                cmpi.w  #$400,d0
                bls.s   loc_A12
                bra.s   sub_9E2

sub_A04:
                bsr.s   sub_A1A
                ori.w   #$C000,d0
                bra.s   sub_A66

sub_A0C:
                cmpi.w  #$400,d0
                bhi.s   sub_9E2

loc_A12:
                bsr.s   sub_A1A
                ori.w   #$4000,d0
                bra.s   sub_A66

sub_A1A:
                lea     (VDP_CTRL).l,a6
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

sub_A66:
                move.w  d0,(a6)
                swap    d0
                move.w  d0,(word_FFFFAE).w
                move.w  (word_FFFFAE).w,(a6)
                rts

sub_A74:
                moveq   #0,d1

loc_A76:
                movem.l d3/a5,-(sp)
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

Nem_Decomp:
                movem.l d0-d7/a0-a1/a3-a5,-(sp)
                lea     (Nem_PCD_WriteRowToVDP).l,a3
                lea     (VDP_DATA).l,a4
                bra.s   Nem_Decomp_Main

Nem_Decomp_To_RAM:
                movem.l d0-d7/a0-a1/a3-a5,-(sp)
                lea     (Nem_PCD_WriteRowToRAM).l,a3

Nem_Decomp_Main:
                lea     (word_FFE630).w,a1
                move.w  (a0)+,d2
                lsl.w   #1,d2
                bcc.s   loc_AFE
                adda.w  #(Nem_PCD_WriteRowToRAM-2-Nem_PCD_WriteRowToVDP_XOR),a3

loc_AFE:
                lsl.w   #2,d2
                movea.w d2,a5
                moveq   #8,d3
                moveq   #0,d2
                moveq   #0,d4
                bsr.w   Nem_Build_Code_Table
                bsr.w   sub_C0C

Nem_Process_Compressed_Data:
                moveq   #8,d0
                bsr.w   sub_C16
                cmpi.w  #$FC,d1
                bcc.s   loc_B4C
                add.w   d1,d1
                move.b  (a1,d1.w),d0
                ext.w   d0
                bsr.w   Nem_PCD_InlineData
                move.b  1(a1,d1.w),d1

Nem_PCD_GetRepeatCount:
                move.w  d1,d0
                andi.w  #$F,d1
                andi.w  #$F0,d0
                lsr.w   #4,d0

Nem_PCD_WritePixel:
                lsl.l   #4,d4
                or.b    d1,d4
                subq.w  #1,d3
                bne.s   Nem_PCD_WritePixel_Loop
                jmp     (a3)

Nem_PCD_NewRow:
                moveq   #0,d4
                moveq   #8,d3

Nem_PCD_WritePixel_Loop:
                dbf     d0,Nem_PCD_WritePixel
                bra.s   Nem_Process_Compressed_Data

loc_B4C:
                moveq   #6,d0
                bsr.w   Nem_PCD_InlineData
                moveq   #7,d0
                bsr.w   sub_C26
                bra.s   Nem_PCD_GetRepeatCount

Nem_PCD_WriteRowToVDP:
                move.l  d4,(a4)
                subq.w  #1,a5
                move.w  a5,d4
                bne.s   Nem_PCD_NewRow
                bra.s   loc_B84

Nem_PCD_WriteRowToVDP_XOR:
                eor.l   d4,d2
                move.l  d2,(a4)
                subq.w  #1,a5
                move.w  a5,d4
                bne.s   Nem_PCD_NewRow

loc_B6E:
                bra.s   loc_B84

Nem_PCD_WriteRowToRAM:
                move.l  d4,(a4)+
                subq.w  #1,a5
                move.w  a5,d4
                bne.s   Nem_PCD_NewRow
                bra.s   loc_B84
                eor.l   d4,d2
                move.l  d2,(a4)+
                subq.w  #1,a5
                move.w  a5,d4
                bne.s   Nem_PCD_NewRow

loc_B84:
                movem.l (sp)+,d0-d7/a0-a1/a3-a5
                rts

Nem_Build_Code_Table:
                move.b  (a0)+,d0

Nem_BCT_ChkEnd:
                cmpi.b  #$FF,d0
                bne.s   Nem_BCT_NewPalIndex
                rts

Nem_BCT_NewPalIndex:
                move.w  d0,d7

Nem_BCT_Loop:
                move.b  (a0)+,d0
                cmpi.b  #$80,d0
                bcc.s   Nem_BCT_ChkEnd
                move.b  d0,d1
                andi.w  #$F,d7
                andi.w  #$70,d1
                or.w    d1,d7
                andi.w  #$F,d0
                move.b  d0,d1
                lsl.w   #8,d1
                or.w    d1,d7
                moveq   #8,d1
                sub.w   d0,d1
                bne.s   Nem_BCT_ShortCode
                move.b  (a0)+,d0
                add.w   d0,d0
                move.w  d7,(a1,d0.w)
                bra.s   Nem_BCT_Loop

Nem_BCT_ShortCode:
                move.b  (a0)+,d0
                lsl.w   d1,d0
                add.w   d0,d0
                moveq   #1,d5
                lsl.w   d1,d5
                subq.w  #1,d5

Nem_BCT_ShortCode_Loop:
                move.w  d7,(a1,d0.w)
                addq.w  #2,d0
                dbf     d5,Nem_BCT_ShortCode_Loop
                bra.s   Nem_BCT_Loop

sub_BDC:
                lsl.w   d0,d5
                add.w   d0,d6
                add.w   d0,d0
                and.w   locret_C38(pc,d0.w),d1
                add.w   d1,d5
                move.w  d6,d0
                subq.w  #8,d0
                bcs.s   locret_BFE
                bne.s   loc_BF6
                clr.w   d6
                move.b  d5,(a0)+
                rts

loc_BF6:
                move.w  d5,d6
                lsr.w   d0,d6
                move.b  d6,(a0)+
                move.w  d0,d6

locret_BFE:
                rts

sub_C00:
                neg.w   d6
                beq.s   locret_C0A
                addq.w  #8,d6
                lsl.w   d6,d5
                move.b  d5,(a0)+

locret_C0A:
                rts

sub_C0C:
                move.b  (a0)+,d5
                asl.w   #8,d5
                move.b  (a0)+,d5
                moveq   #$10,d6
                rts

sub_C16:
                move.w  d6,d7
                sub.w   d0,d7
                move.w  d5,d1
                lsr.w   d7,d1
                add.w   d0,d0
                and.w   word_C3A-2(pc,d0.w),d1
                rts

sub_C26:
                bsr.s   sub_C16
                lsr.w   #1,d0

Nem_PCD_InlineData:
                sub.w   d0,d6
                cmpi.w  #9,d6
                bcc.s   locret_C38
                addq.w  #8,d6
                asl.w   #8,d5
                move.b  (a0)+,d5

locret_C38:
                rts

word_C3A:       dc.w 1
                dc.w 3
                dc.w 7
                dc.w $F
                dc.w $1F
                dc.w $3F
                dc.w $7F
                dc.w $FF
                dc.w $1FF
                dc.w $3FF
                dc.w $7FF
                dc.w $FFF
                dc.w $1FFF
                dc.w $3FFF
                dc.w $7FFF
                dc.w $FFFF
sub_C5A:
                move.w  a3,d3
                swap    d4
                bpl.s   loc_C6A
                subq.w  #1,d6
                btst    d6,d5
                beq.s   loc_C6A
                ori.w   #$1000,d3

loc_C6A:
                swap    d4
                bpl.s   loc_C78
                subq.w  #1,d6
                btst    d6,d5
                beq.s   loc_C78
                ori.w   #$800,d3

loc_C78:
                move.w  d5,d1
                move.w  d6,d7
                sub.w   a5,d7
                bcc.s   loc_CA8
                move.w  d7,d6
                addi.w  #$10,d6
                neg.w   d7
                lsl.w   d7,d1
                move.b  (a0),d5
                rol.b   d7,d5
                add.w   d7,d7
                and.w   locret_C38(pc,d7.w),d5
                add.w   d5,d1

loc_C96:
                move.w  a5,d0
                add.w   d0,d0
                and.w   locret_C38(pc,d0.w),d1
                add.w   d3,d1
                move.b  (a0)+,d5
                lsl.w   #8,d5
                move.b  (a0)+,d5
                rts

loc_CA8:
                beq.s   loc_CBC
                lsr.w   d7,d1
                move.w  a5,d0
                add.w   d0,d0
                and.w   locret_C38(pc,d0.w),d1
                add.w   d3,d1
                move.w  a5,d0
                bra.w   Nem_PCD_InlineData

loc_CBC:
                moveq   #$10,d6
                bra.s   loc_C96

sub_CC0:
                movem.l d0-d6/a0/a4,-(sp)
                moveq   #0,d4
                lea     (VDP_DATA).l,a4
                bra.s   loc_CD4

sub_CCE:
                movem.l d0-d6/a0/a4,-(sp)
                moveq   #4,d4

loc_CD4:
                asl.w   #3,d1
                subq.w  #1,d1
                move.b  d0,d2
                move.b  d2,d3
                lsr.b   #4,d2
                andi.b  #$F,d3

loc_CE2:
                moveq   #7,d6
                move.b  (a0)+,d0

loc_CE6:
                lsl.l   #4,d5
                btst    d6,d0
                beq.s   loc_CF0
                or.b    d2,d5
                bra.s   loc_CF2

loc_CF0:
                or.b    d3,d5

loc_CF2:
                dbf     d6,loc_CE6
                move.l  d5,(a4)
                adda.l  d4,a4
                dbf     d1,loc_CE2
                movem.l (sp)+,d0-d6/a0/a4
                rts

sub_D04:
                movem.l d0-d7/a1-a5,-(sp)
                movea.w d0,a3
                move.b  (a0)+,d0
                ext.w   d0
                movea.w d0,a5
                move.b  (a0)+,d0
                ext.w   d0
                ext.l   d0
                ror.l   #1,d0
                ror.w   #1,d0
                move.l  d0,d4
                movea.w (a0)+,a2
                adda.w  a3,a2
                movea.w (a0)+,a4
                adda.w  a3,a4
                bsr.w   sub_C0C

loc_D28:
                moveq   #7,d0
                bsr.w   sub_C16
                move.w  d1,d2
                moveq   #7,d0
                cmpi.w  #$40,d1
                bcc.s   loc_D3C
                moveq   #6,d0
                lsr.w   #1,d2

loc_D3C:
                bsr.w   Nem_PCD_InlineData
                andi.w  #$F,d2
                lsr.w   #4,d1
                add.w   d1,d1
                jmp     loc_D98(pc,d1.w)

sub_D4C:
                move.w  a2,(a1)+
                addq.w  #1,a2
                dbf     d2,sub_D4C
                bra.s   loc_D28

sub_D56:
                move.w  a4,(a1)+
                dbf     d2,sub_D56
                bra.s   loc_D28

sub_D5E:
                bsr.w   sub_C5A

loc_D62:
                move.w  d1,(a1)+
                dbf     d2,loc_D62
                bra.s   loc_D28

sub_D6A:
                bsr.w   sub_C5A

loc_D6E:
                move.w  d1,(a1)+
                addq.w  #1,d1
                dbf     d2,loc_D6E
                bra.s   loc_D28

sub_D78:
                bsr.w   sub_C5A

loc_D7C:
                move.w  d1,(a1)+
                subq.w  #1,d1
                dbf     d2,loc_D7C
                bra.s   loc_D28

sub_D86:
                cmpi.w  #$F,d2
                beq.s   loc_DA8

loc_D8C:
                bsr.w   sub_C5A
                move.w  d1,(a1)+
                dbf     d2,loc_D8C
                bra.s   loc_D28

loc_D98:
                bra.s   sub_D4C
                bra.s   sub_D4C
                bra.s   sub_D56
                bra.s   sub_D56
                bra.s   sub_D5E
                bra.s   sub_D6A
                bra.s   sub_D78
                bra.s   sub_D86

loc_DA8:
                subq.w  #1,a0
                cmpi.w  #$10,d6
                bne.s   loc_DB2
                subq.w  #1,a0

loc_DB2:
                move.w  a0,d0
                lsr.w   #1,d0
                bcc.s   loc_DBA
                addq.w  #1,a0

loc_DBA:
                movem.l (sp)+,d0-d7/a1-a5
                rts

sub_DC0:
                bsr.w   InitJoypads
                lea     (unk_FFFF83).w,a0
                move.w  (word_FFFF8E).w,d0
                moveq   #$E,d1
                moveq   #6,d2

loc_DD0:
                btst    d1,d0
                sne     (a0)+
                subq.b  #1,d1
                dbf     d2,loc_DD0
                moveq   #6,d1
                moveq   #2,d2

loc_DDE:
                btst    d1,d0
                sne     (a0)+
                subq.b  #1,d1
                dbf     d2,loc_DDE
                andi.b  #$70,d0
                sne     (a0)+
                tst.b   (byte_FFFF87).w
                beq.s   locret_DF8
                clr.b   (byte_FFFF86).w

locret_DF8:
                rts

InitJoypads:
                bsr.w   RequestZ80Bus
                lea     (word_FFFF8E).w,a0
                lea     ((IO_CT1_DATA+1)).l,a1
                bsr.s   sub_E12
                addq.w  #2,a1
                bsr.s   sub_E12
                bra.w   sub_107E

sub_E12:
                move.b  #0,(a1)
                nop
                nop
                move.b  (a1),d0
                lsl.b   #2,d0
                andi.b  #$C0,d0
                move.b  #$40,(a1)
                nop
                nop
                move.b  (a1),d1
                andi.b  #$3F,d1
                or.b    d1,d0
                not.b   d0
                move.b  d0,d1
                move.b  (a0),d2
                eor.b   d2,d0
                move.b  d1,(a0)+
                and.b   d1,d0
                move.b  d0,(a0)+
                rts

sub_E42:
                lea     byte_E6E(pc),a1
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

initial_vdp_regs:dc.b 4, $34, $30, $2C, 7, $5F, 0, 0, 0, 0
                dc.b $30, 2, 0, $2E, 0, 2, 0, 0, 0, 0
byte_E6E:       dc.b 4, $14, $30, $2C, 7, $54, 0, 0, 0, 0
                dc.b $30, 0, $81, $2B, 0, 2, 1, 0, 0, 0
sub_E82:
                lea     (unk_FFFF70).w,a1
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

sub_EA2:
                move.w  #$B000,d2
                move.w  #$5000,d0
                bsr.w   sub_A74
                clr.l   (dword_FFFFA4).w
                clr.l   (dword_FFFFA8).w
                lea     (dword_FFF550).w,a6
                moveq   #0,d7
                move.w  #$7F,d6

loc_EC0:
                move.l  d7,(a6)+
                dbf     d6,loc_EC0
                rts

sub_EC8:
                lea     (VDP_CTRL).l,a2
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

sub_EEC:
                lea     (VDP_CTRL).l,a2
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

sub_F10:
                asl.w   #5,d0

sub_F12:
                clr.l   d1
                move.w  d0,d1
                lsl.l   #2,d1
                move.w  d0,d1
                andi.w  #$3FFF,d1
                ori.w   #$4000,d1
                swap    d1
                move.l  d1,(a6)
                rts

sub_F28:
                asl.w   #5,d0

loc_F2A:
                clr.l   d1
                move.w  d0,d1
                lsl.l   #2,d1
                move.w  d0,d1
                andi.w  #$3FFF,d1
                swap    d1
                move.l  d1,(a6)
                rts

sub_F3C:
                move.w  (word_FFFF98).w,(word_FFFF96).w

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

sub_F70:
                movem.l d2-d5,-(sp)
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

sub_FD6:
                cmpi.w  #$40,d0
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

sub_1000:
                lea     (word_FFF7E0).w,a0
                lea     (unk_FFF860).w,a1
                moveq   #$1F,d0

loc_100A:
                move.l  (a0),(a1)+
                clr.l   (a0)+
                dbf     d0,loc_100A
                rts

LoadZ80Driver:
                bsr.w   sub_105E
                bsr.w   sub_108E
                bsr.w   sub_115E
                move.w  #$FE5,d0
                moveq   #0,d1
                moveq   #2,d2
                lea     z80_part1(pc),a0
                bsr.w   sub_10A6
                moveq   #8,d0
                move.w  #$1C00,d1
                moveq   #1,d2
                lea     byte_1046(pc),a0
                bsr.w   sub_10A6
                clr.w   (word_FFFFA2).w
                rts

byte_1046:      dc.b 0, $80, 0, $80, 0, 0, 0, 0, $20, 0
RequestZ80Bus:
                btst    #0,(IO_Z80BUS).l
                sne     (byte_FFFFC8).w
                beq.s   locret_107C

sub_105E:
                movem.w d0,-(sp)
                move.w  #$100,(IO_Z80BUS).l
                moveq   #$F,d0

loc_106C:
                btst    #0,(IO_Z80BUS).l
                dbeq    d0,loc_106C
                movem.w (sp)+,d0

locret_107C:
                rts

sub_107E:
                tst.b   (byte_FFFFC8).w
                beq.s   locret_108C

ReleaseZ80Bus:
                move.w  #0,(IO_Z80BUS).l

locret_108C:
                rts

sub_108E:
                move.w  #0,(IO_Z80RES).l
                bsr.s   nullsub_2
                bsr.s   nullsub_2
                bsr.s   nullsub_2
                move.w  #$100,(IO_Z80RES).l

nullsub_2:
                rts

sub_10A6:
                movem.l d0-d3/a0-a1,-(sp)
                bsr.s   sub_105E
                lea     (Z80_RAM).l,a1
                adda.w  d1,a1

loc_10B4:
                move.b  (a0)+,d1
                moveq   #$F,d3

loc_10B8:
                move.b  d1,(a1)
                cmp.b   (a1),d1
                beq.s   loc_10C4
                dbf     d3,loc_10B8
                bra.s   loc_10D4

loc_10C4:
                addq.w  #1,a1
                dbf     d0,loc_10B4
                lsr.w   #1,d2
                bcc.s   loc_10D0
                bsr.s   sub_108E

loc_10D0:
                lsr.w   #1,d2
                bcs.s   loc_10D6

loc_10D4:
                bsr.s   ReleaseZ80Bus

loc_10D6:
                movem.l (sp)+,d0-d3/a0-a1
                rts

sub_10DC:
                movem.l d1/a0,-(sp)
                bsr.w   sub_105E
                lea     (unk_A01C04).l,a0
                moveq   #0,d1
                move.b  d1,(a0)+
                move.b  d1,(a0)+
                move.b  d1,(a0)+
                move.b  d1,(a0)
                addq.w  #2,a0
                move.b  d0,(a0)
                bsr.s   ReleaseZ80Bus
                movem.l (sp)+,d1/a0
                rts

sub_1100:
                movea.w (word_FFFFA2).w,a0
                cmpa.w  #8,a0
                bcc.s   locret_1112
                move.b  d0,-$66(a0)
                addq.w  #1,(word_FFFFA2).w

locret_1112:
                rts

sub_1114:
                movea.w (word_FFFFA2).w,a0
                move.w  a0,d0
                beq.s   loc_115A
                move.b  -$67(a0),d0
                subq.w  #1,(word_FFFFA2).w
                bsr.w   sub_105E
                tst.b   (byte_A01C0A).l
                bne.s   loc_1138
                move.b  d0,(byte_A01C0A).l
                bra.s   loc_1156

loc_1138:
                tst.b   (byte_A01C0B).l
                bne.s   loc_1148
                move.b  d0,(byte_A01C0B).l
                bra.s   loc_1156

loc_1148:
                tst.b   (byte_A01C0C).l
                bne.s   loc_1156
                move.b  d0,(byte_A01C0C).l

loc_1156:
                bsr.w   ReleaseZ80Bus

loc_115A:
                bra.w   sub_F3C

sub_115E:
                move.w  #$1FFF,d0
                lea     (Z80_RAM).l,a0

loc_1168:
                moveq   #$F,d1

loc_116A:
                move.b  #0,(a0)
                tst.b   (a0)
                dbeq    d1,loc_116A
                addq.l  #1,a0
                dbf     d0,loc_1168
                rts

sub_117C:
                movem.w d1,-(sp)
                bsr.w   sub_105E
                move.b  (byte_A01C0A).l,d1
                bsr.w   ReleaseZ80Bus
                cmp.b   d0,d1
                movem.w (sp)+,d1
                rts

sub_1196:
                movem.l d0-d2/a0,-(sp)
                lea     (word_FFF7E0).w,a0

loc_119E:
                move.w  (a5),d0
                andi.w  #$10,d0
                move.w  (a5),d1
                rol.w   #4,d1
                andi.w  #$F,d1
                or.w    d1,d0
                move.w  (a5),d1
                andi.w  #$100,d1
                lsr.w   #3,d1
                or.w    d1,d0
                add.w   d0,d0
                move.w  (a5)+,d2
                move.w  d2,d1
                andi.w  #$EEE,d1
                move.w  d1,(a0,d0.w)
                lsr.w   #1,d2
                bcc.s   loc_119E
                movem.l (sp)+,d0-d2/a0
                rts

sub_11D0:
                move.w  #$8100,d0
                move.b  (byte_FFFF71).w,d0
                ori.b   #$40,d0
                move.w  d0,(a6)
                move.l  #$40000010,(VDP_CTRL).l
                move.l  (dword_FFFFA4).w,-4(a6)
                move.w  (word_FFFFDA).w,d0
                bsr.w   sub_F12
                move.l  (dword_FFFFA8).w,d0
                neg.w   d0
                swap    d0
                neg.w   d0
                swap    d0
                move.l  d0,-4(a6)
                rts

sub_1208:
                lea     (VDP_CTRL).l,a6
                move.w  d0,d3
                move.w  d0,(word_FFFFE4).w
                lsl.w   #5,d3
                clr.b   d4

loc_1218:
                move.w  d3,d2
                move.w  d4,d1
                moveq   #$20,d0
                add.w   d0,d3
                bsr.w   loc_A76
                addi.b  #$11,d4
                bcc.s   loc_1218
                rts

sub_122C:
                movem.l d1-d5/a0,-(sp)
                movea.l a5,a0
                bsr.s   sub_124A
                clr.w   d0
                lea     (unk_FFC3E0).w,a1
                bsr.w   sub_D04
                movea.l a0,a5
                movea.l a1,a0
                bsr.s   sub_1260
                movem.l (sp)+,d1-d5/a0
                rts

sub_124A:
                lea     (VDP_CTRL).l,a6
                move.w  (a0)+,d2
                move.w  (a0)+,d3
                move.w  #$FF,d4
                move.w  d4,d5
                add.b   (a0)+,d4
                add.b   (a0)+,d5
                rts

sub_1260:
                move.w  d2,d0
                bsr.w   sub_F12
                move.w  d4,d0

loc_1268:
                move.w  (a0)+,d1
                add.w   d3,d1
                move.w  d1,-4(a6)
                dbf     d0,loc_1268
                add.w   (word_FFFFE2).w,d2
                dbf     d5,sub_1260
                move.w  d3,d0
                rts

sub_1280:
                bsr.w   sub_1196
                bsr.s   sub_122C
                bsr.w   sub_F10
                movea.l a5,a0
                bra.w   Nem_Decomp

sub_1290:
                movem.l a0/a5,-(sp)
                lea     (VDP_CTRL).l,a6
                lea     VDP_DATA-VDP_CTRL(a6),a5
                ori.l   #$FFFF0000,d1
                movea.l d1,a0
                clr.l   d1
                move.w  d2,d1
                lsl.l   #2,d1
                move.w  d2,d1
                andi.w  #$3FFF,d1
                ori.w   #$C000,d1
                swap    d1
                move.l  d1,(a6)
                bra.s   loc_12E6

sub_12BC:
                movem.l a0/a5,-(sp)
                lea     (VDP_CTRL).l,a6
                lea     VDP_DATA-VDP_CTRL(a6),a5
                ori.l   #$FFFF0000,d1
                movea.l d1,a0
                clr.l   d1
                move.w  d2,d1
                lsl.l   #2,d1
                move.w  d2,d1
                andi.w  #$3FFF,d1
                ori.w   #$4000,d1
                swap    d1
                move.l  d1,(a6)

loc_12E6:
                addq.w  #3,d0
                lsr.w   #2,d0
                move.w  d0,d1
                lsr.w   #3,d1
                bra.s   loc_1300

loc_12F0:
                move.l  (a0)+,(a5)
                move.l  (a0)+,(a5)
                move.l  (a0)+,(a5)
                move.l  (a0)+,(a5)
                move.l  (a0)+,(a5)
                move.l  (a0)+,(a5)
                move.l  (a0)+,(a5)
                move.l  (a0)+,(a5)

loc_1300:
                dbf     d1,loc_12F0
                andi.w  #7,d0
                bra.s   loc_130C

loc_130A:
                move.l  (a0)+,(a5)

loc_130C:
                dbf     d0,loc_130A
                movem.l (sp)+,a0/a5
                rts

z80_part1:      binclude "data/sound/data_z80_part1.bin",$0,$FE6
func_table:     dc.w $39
                dc.w nullsub_1
                dc.w nullsub_1
                dc.w nullsub_1
                dc.w Nem_Decomp
                dc.w Nem_Decomp_To_RAM
                dc.w sub_CC0
                dc.w sub_CCE
                dc.w sub_C0C
                dc.w sub_C16
                dc.w sub_C26
                dc.w Nem_PCD_InlineData
                dc.w sub_BDC
                dc.w sub_C00
                dc.w sub_D04
                dc.w sub_1290
                dc.w sub_12BC
                dc.w sub_1208
                dc.w sub_A74
                dc.w loc_A76
                dc.w sub_9D8
                dc.w sub_8FE
                dc.w loc_900
                dc.w sub_976
                dc.w sub_A04
                dc.w sub_A0C
                dc.w sub_11D0
                dc.w sub_FD6
                dc.w sub_DC0
                dc.w InitJoypads
                dc.w SetInitialVDPRegs
                dc.w sub_E82
                dc.w sub_EA2
                dc.w LoadZ80Driver
                dc.w sub_105E
                dc.w ReleaseZ80Bus
                dc.w RequestZ80Bus
                dc.w sub_107E
                dc.w sub_108E
                dc.w sub_10A6
                dc.w sub_115E
                dc.w sub_10DC
                dc.w sub_1100
                dc.w sub_1114
                dc.w sub_F3C
                dc.w RandomNumber
                dc.w sub_EC8
                dc.w sub_EEC
                dc.w sub_F10
                dc.w sub_F12
                dc.w sub_F28
                dc.w loc_F2A
                dc.w sub_117C
                dc.w sub_F70
                dc.w sub_1000
                dc.w sub_872
                dc.w sub_1196
                dc.w sub_122C
                dc.w sub_1280
Jap1BPPTiles:   binclude "data/artunc/data_Jap1BPPTiles.bin",$0,$598
;empty_block_1:  dc.b [$D6F6]$FF
;                org $3000
sub_10000:
                move    #$2700,sr
                move.l  #sub_10E88,(dword_FFFA7E).w
                clr.w   (word_FFFF96).w
                move.w  #$40,(word_FFFFC0).w
                clr.w   (word_FFFFC4).w
                clr.w   (word_FFFFC2).w
                bsr.w   sub_10CD4
                bsr.w   sub_10CF6
                bsr.w   LoadTilesToVRAM
                lea     (dword_FFD800).w,a6
                moveq   #0,d7
                move.w  #$1FF,d6

loc_10034:
                move.l  d7,(a6)+
                dbf     d6,loc_10034
                move.l  #$40000010,(VDP_CTRL).l
                move.w  #0,(VDP_DATA).l
                move.l  #$40020010,(VDP_CTRL).l
                move.w  #0,(VDP_DATA).l
                bsr.w   sub_113BC
                move.w  #$101,(word_FFD82C).w
                move    #$2500,sr

loc_1006C:
                movea.w (off_0+2).w,sp
                move.w  (word_FFFFC0).w,d0
                andi.l  #$7C,d0
                jsr     loc_10084(pc,d0.w)
                addq.w  #1,(word_FFFF92).w
                bra.s   loc_1006C

loc_10084:
                bra.w   sub_11FB0
                bra.w   sub_12122
                bra.w   sub_1228E
                bra.w   sub_122E0
                bra.w   sub_125BE
                bra.w   sub_125F2
                bra.w   sub_12656
                bra.w   sub_1266E
                bra.w   sub_12A94
                bra.w   sub_12B46
                bra.w   sub_12F30
                bra.w   sub_12FDC
                bra.w   sub_13110
                bra.w   sub_13162
                bra.w   sub_139A2
                bra.w   sub_13A18
                bra.w   loc_100CC
                bra.w   loc_100D0

loc_100CC:
                jmp     LoadSegaScreen

loc_100D0:
                jmp     SegaScreen

sub_100D4:
                jsr     unk_FFFBB4
                lea     (word_FFD000).w,a6
                moveq   #0,d7
                move.w  #$1FF,d6

loc_100E2:
                move.l  d7,(a6)+
                dbf     d6,loc_100E2
                bsr.w   sub_113BC
                bsr.w   sub_110FE
                move.w  #$8000,(word_FFD884).w
                jmp     LoadLogoAndExitToVRAM

LoadTilesToVRAM:
                move.w  #$200,d0
                jsr     unk_FFFB8A
                lea     (LevelTiles).l,a0
                jsr     j_Nem_Decomp
                move.w  #$400,d0
                jsr     unk_FFFB8A
                lea     (SpritesTiles).l,a0
                jsr     j_Nem_Decomp
                move.b  #1,(byte_FFD88E).w

loc_10126:
                moveq   #$20,d0
                lea     (VDP_CTRL).l,a6
                jsr     unk_FFFB8A
                lea     (Jap1BPPTiles).w,a0
                moveq   #$20,d0
                add.b   (byte_FFD88E).w,d0
                move.w  #$B3,d1
                jsr     unk_FFFA8E
                moveq   #$30,d0
                lea     (VDP_CTRL).l,a6
                jsr     unk_FFFB8A
                lea     (Latin1BPPTiles).l,a0
                moveq   #$20,d0
                add.b   (byte_FFD88E).w,d0
                move.w  #$2B,d1
                jsr     unk_FFFA8E
                move.w  #$120,d0
                lea     (VDP_CTRL).l,a6
                jsr     unk_FFFB8A
                lea     (Jap1BPPTiles).w,a0
                moveq   #$30,d0
                add.b   (byte_FFD88E).w,d0
                move.w  #$B3,d1
                jsr     unk_FFFA8E
                move.w  #$130,d0
                lea     (VDP_CTRL).l,a6
                jsr     unk_FFFB8A
                lea     (Latin1BPPTiles).l,a0
                moveq   #$30,d0
                add.b   (byte_FFD88E).w,d0
                move.w  #$2B,d1
                jsr     unk_FFFA8E
                rts

LoadLogoAndExitToVRAM:
                lea     (VDP_CTRL).l,a6
                move.w  #$640,d0
                jsr     unk_FFFB8A
                lea     (ScoresTiles).l,a0
                jsr     j_Nem_Decomp
                move.w  #$693,d0
                jsr     unk_FFFB8A
                lea     (ExitTiles).l,a0
                jsr     j_Nem_Decomp
                rts

                ;org $81D4
z80_part2:      binclude "data/sound/data_z80_part2.bin",$0,$B00
sub_10CD4:
                move.l  #$C0000000,(VDP_CTRL).l
                moveq   #$3F,d0

loc_10CE0:
                move.w  #0,(VDP_DATA).l
                dbf     d0,loc_10CE0
                moveq   #0,d2
                move.w  #$A800,d0
                jmp     unk_FFFAD6

sub_10CF6:
                jsr     j_LoadZ80Driver
                lea     (z80_part2).l,a1
                bsr.s   sub_10D24
                bsr.s   sub_10D24
                moveq   #8,d0
                move.w  #$1C00,d1
                moveq   #1,d2
                lea     byte_10D1A(pc),a0
                jsr     unk_FFFB54
                clr.w   (word_FFFFA2).w
                rts

byte_10D1A:     dc.b 0, $80, 0, $12, $B4, 0, $E6, $80, $20, 0
sub_10D24:
                moveq   #2,d2
                movem.w (a1)+,d0-d1/a0
                suba.l  #$10000,a0
                jmp     unk_FFFB54

sub_10D34:
                move.l  a0,-(sp)
                jsr     unk_FFFB36
                move.b  d0,(byte_A01C09).l
                jsr     unk_FFFB3C
                movea.l (sp)+,a0
                rts

sub_10D48:
                tst.b   (byte_FFD2A4).w
                bne.s   locret_10D50
                bsr.s   sub_10D34

locret_10D50:
                rts

sub_10D52:
                tst.b   (byte_FFD2A4).w
                beq.s   locret_10D6C
                addq.w  #1,(word_FFD2A2).w
                cmpi.w  #$1E,(word_FFD2A2).w
                bcs.s   locret_10D6C
                clr.w   (word_FFD2A2).w
                clr.b   (byte_FFD2A4).w

locret_10D6C:
                rts

sub_10D6E:
                movem.l d1,-(sp)
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

sub_10D8C:
                movea.l a4,a1
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

sub_10DC2:
                clr.w   d2
                move.b  (a0)+,d2
                beq.s   locret_10DE6
                bclr    #7,d2
                beq.s   loc_10DD8
                subq.b  #1,d2

loc_10DD0:
                move.b  (a0)+,(a4)+
                dbf     d2,loc_10DD0
                bra.s   sub_10DC2

loc_10DD8:
                subq.b  #1,d2
                move.b  (a0)+,d3

loc_10DDC:
                move.b  d3,(a4)+
                addq.b  #1,d3
                dbf     d2,loc_10DDC
                bra.s   sub_10DC2

locret_10DE6:
                rts

sub_10DE8:
                movem.l d0-d1,-(sp)
                clr.w   d5
                subi.w  #$20,d4
                bcc.s   loc_10E08
                cmpi.w  #$FFF3,d4
                bne.s   loc_10E02
                move.w  #$79,d4
                moveq   #1,d5
                bra.s   loc_10E3C

loc_10E02:
                addi.w  #$C0,d4
                bra.s   loc_10E3C

loc_10E08:
                moveq   #$40,d0
                cmp.w   d0,d4
                bcs.s   loc_10E3C
                sub.w   d0,d4
                moveq   #$40,d1
                moveq   #$50,d0
                cmp.w   d0,d4
                bcs.s   loc_10E1C
                sub.w   d0,d4
                moveq   #$77,d1

loc_10E1C:
                cmpi.w  #$37,d4
                bcs.s   loc_10E3A
                moveq   #1,d5
                cmpi.w  #$46,d4
                bcs.s   loc_10E36
                cmpi.w  #$4B,d4
                bcc.s   loc_10E34
                addq.w  #5,d4
                bra.s   loc_10E36

loc_10E34:
                moveq   #2,d5

loc_10E36:
                subi.w  #$32,d4

loc_10E3A:
                add.w   d1,d4

loc_10E3C:
                addi.w  #$40,d4
                tst.w   d5
                beq.s   loc_10E48
                addi.w  #$AD,d5

loc_10E48:
                addi.w  #$40,d5
                movem.l (sp)+,d0-d1
                rts

sub_10E52:
                trap    #0              ; ErrorTrap
                ror.l   #8,d1
                rts

sub_10E58:
                movem.l d0-d1/d7,-(sp)
                clr.w   (word_FFE630).w
                addq.w  #1,(word_FFE634).w
                move.w  (word_FFE632).w,d7
                subq.w  #1,d7
                bcs.s   loc_10E82

loc_10E6C:
                bsr.s   sub_10E52
                andi.l  #$FFFF,d1
                divu.w  (word_FFE634).w,d1
                swap    d1
                add.w   d1,(word_FFE630).w
                dbf     d7,loc_10E6C

loc_10E82:
                movem.l (sp)+,d0-d1/d7
                rts

sub_10E88:
                move    #$2700,sr
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
                bra.w   sub_10EBA
                bra.w   sub_10EBA

locret_10EB8:
                rts

sub_10EBA:
                bsr.w   sub_1132A
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

sub_10F24:
                add.w   d7,d7
                lsl.w   #6,d6
                add.w   d6,d7
                add.w   d5,d7
                move.w  d7,d5

sub_10F2E:
                lsl.l   #2,d5
                lsr.w   #2,d5
                bset    #$E,d5
                swap    d5
                rts

sub_10F3A:
                bsr.s   sub_10F24
                bra.s   loc_10F40

sub_10F3E:
                bsr.s   sub_10F2E

loc_10F40:
                move.l  d5,(VDP_CTRL).l
                move.w  d4,(VDP_DATA).l
                rts

sub_10F4E:
                lea     (VDP_CTRL).l,a4
                lea     (VDP_DATA).l,a3
                lsl.l   #2,d5
                lsr.w   #2,d5
                bset    #$E,d5
                swap    d5
                move.l  d5,(a4)

loc_10F66:
                move.w  (a6)+,(a3)
                dbf     d4,loc_10F66
                rts

sub_10F6E:
                bsr.s   sub_10F2E

sub_10F70:
                lea     (VDP_CTRL).l,a4
                lea     (VDP_DATA).l,a3
                move.l  #$400000,d0

loc_10F82:
                move.l  d5,(a4)
                move.w  d7,d1

loc_10F86:
                move.w  (a6)+,(a3)
                dbf     d1,loc_10F86
                add.l   d0,d5
                dbf     d6,loc_10F82
                rts

sub_10F94:
                cmpi.w  #$FFFF,(word_FFD884).w
                bne.s   loc_10FA2
                move.w  #$8020,d4
                bra.s   loc_10FA6

loc_10FA2:
                add.w   (word_FFD884).w,d4

loc_10FA6:
                bsr.s   sub_10F3E
                rts

sub_10FAA:
                moveq   #0,d6
                move.w  (a6)+,d6

loc_10FAE:
                moveq   #0,d4
                moveq   #0,d5
                move.w  d6,d5
                move.b  (a6)+,d4
                beq.s   locret_10FBE
                bsr.s   sub_10F94
                addq.w  #2,d6
                bra.s   loc_10FAE

locret_10FBE:
                rts

sub_10FC0:
                moveq   #0,d6
                move.w  (a6)+,d6

loc_10FC4:
                moveq   #0,d4
                moveq   #0,d5
                move.b  (a6)+,d4
                beq.s   locret_10FF2
                bsr.w   sub_10DE8
                move.w  d5,d3
                move.w  d6,d5
                subi.w  #$20,d4
                move.l  d5,-(sp)
                bsr.w   sub_10F3E
                move.l  (sp)+,d5
                subi.w  #$40,d5
                move.w  d3,d4
                subi.w  #$20,d4
                bsr.w   sub_10F3E
                addq.w  #2,d6
                bra.s   loc_10FC4

locret_10FF2:
                rts

sub_10FF4:
                clr.b   (byte_FFD00D).w
                subq.w  #2,d5

loc_10FFA:
                moveq   #0,d1
                move.b  (a6)+,d1
                move.w  d1,d4
                lsr.w   #4,d4
                addq.w  #2,d5
                movem.l d0-d1/d5,-(sp)
                bsr.w   sub_11036
                movem.l (sp)+,d0-d1/d5
                andi.w  #$F,d1
                move.w  d1,d4
                addq.w  #2,d5
                movem.l d0-d1/d5,-(sp)
                bsr.w   sub_11036
                movem.l (sp)+,d0-d1/d5
                dbf     d0,loc_10FFA
                tst.b   (byte_FFD00D).w
                bne.s   locret_11034
                moveq   #$30,d4
                bsr.w   sub_10F94

locret_11034:
                rts

sub_11036:
                tst.b   d4
                bne.s   loc_1104C
                tst.b   (byte_FFD00D).w
                bne.s   loc_11052
                tst.b   (byte_FFD29A).w
                beq.s   locret_1104A
                bsr.w   sub_10F94

locret_1104A:
                rts

loc_1104C:
                move.b  #1,(byte_FFD00D).w

loc_11052:
                addi.w  #$30,d4
                bsr.w   sub_10F94
                rts

sub_1105C:
                btst    #0,2(a0)
                bne.s   locret_110B8
                move.l  $34(a0),d1
                move.l  $30(a0),d2
                add.l   d1,d2
                cmpi.l  #$800000,d2
                bge.s   loc_1107C
                addi.l  #$1000000,d2

loc_1107C:
                cmpi.l  #$1800000,d2
                blt.s   loc_1108A
                subi.l  #$1000000,d2

loc_1108A:
                move.l  d2,$30(a0)
                swap    d2
                sub.w   (dword_FFFFA8).w,d2

loc_11094:
                cmpi.w  #$80,d2
                bge.s   loc_110A0
                addi.w  #$100,d2
                bra.s   loc_11094

loc_110A0:
                cmpi.w  #$180,d2
                blt.s   loc_110AC
                subi.w  #$100,d2
                bra.s   loc_110A0

loc_110AC:
                move.w  d2,$20(a0)
                move.l  $2C(a0),d3
                add.l   d3,$24(a0)

locret_110B8:
                rts

sub_110BA:
                move.l  $30(a0),d2
                sub.l   (dword_FFFFA8).w,d2

loc_110C2:
                cmpi.l  #$800000,d2
                bge.s   loc_110D2
                addi.l  #$1000000,d2
                bra.s   loc_110C2

loc_110D2:
                cmpi.l  #$1800000,d2
                blt.s   loc_110E2
                subi.l  #$1000000,d2
                bra.s   loc_110D2

loc_110E2:
                move.l  d2,$20(a0)
                move.l  $2C(a0),d3
                add.l   d3,$24(a0)
                rts

sub_110F0:
                movea.w a0,a6
                moveq   #$F,d7
                moveq   #0,d6

loc_110F6:
                move.l  d6,(a6)+
                dbf     d7,loc_110F6
                rts

sub_110FE:
                movem.l d5/a0,-(sp)
                move.w  #$1F,d5
                lea     (word_FFC000).w,a0

loc_1110A:
                bsr.s   sub_110F0
                movea.w a6,a0
                dbf     d5,loc_1110A
                movem.l (sp)+,d5/a0
                rts

sub_11118:
                movea.w a0,a6
                moveq   #$1E,d7
                moveq   #0,d6

loc_1111E:
                move.w  d6,(a6)+
                dbf     d7,loc_1111E
                rts

sub_11126:
                move.w  6(a0),d0
                movea.l 8(a0),a1
                movea.l (a1,d0.w),a1
                subq.b  #1,$11(a0)
                bpl.s   loc_11142
                move.b  1(a1),$11(a0)
                addq.b  #1,$10(a0)

loc_11142:
                moveq   #0,d0
                move.b  $10(a0),d0
                cmp.b   (a1),d0
                bcs.s   loc_11158
                clr.b   $10(a0)
                moveq   #0,d0
                bset    #2,2(a0)

loc_11158:
                lsl.w   #1,d0
                moveq   #$FFFFFFFF,d1
                move.w  2(a1,d0.w),d1
                move.l  d1,$C(a0)
                rts

sub_11166:
                btst    #1,2(a0)
                beq.s   loc_11170
                rts

loc_11170:
                movea.l $C(a0),a1
                moveq   #0,d1
                move.b  (a1)+,d1
                move.b  (a1)+,4(a0)
                move.w  $24(a0),d2
                cmpi.w  #$180,d2
                bhi.s   locret_111D2
                move.w  $20(a0),d3

loc_1118A:
                move.b  (a1)+,d0
                ext.w   d0
                add.w   d2,d0
                move.w  d0,(a2)+
                move.b  (a1)+,(a2)+
                move.b  d6,(a2)+
                move.b  (a1)+,d0
                or.b    $13(a0),d0
                move.b  d0,(a2)+
                move.b  (a1)+,(a2)+
                move.b  (a1)+,d0
                tst.b   2(a0)
                bpl.s   loc_111B0
                bchg    #3,-2(a2)
                move.b  (a1),d0

loc_111B0:
                addq.w  #1,a1
                ext.w   d0
                add.w   d3,d0
                move.w  d0,d4
                subi.w  #$41,d4
                cmpi.w  #$17F,d4
                bcs.s   loc_111CA
                subq.w  #6,a2
                dbf     d1,loc_1118A
                rts

loc_111CA:
                move.w  d0,(a2)+
                addq.b  #1,d6
                dbf     d1,loc_1118A

locret_111D2:
                rts

sub_111D4:
                lea     (word_FFC000).w,a0
                bsr.w   sub_1129E
                bsr.w   loc_11254
                rts

sub_111E2:
                tst.b   (byte_FFD24E).w
                bne.s   loc_11228
                lea     (word_FFC440).w,a0
                bsr.w   sub_1129E
                lea     (unk_FFC200).w,a0
                moveq   #8,d0

loc_111F6:
                bsr.w   sub_1129E
                lea     $40(a0),a0
                dbf     d0,loc_111F6
                lea     (unk_FFC480).w,a0
                moveq   #$D,d0

loc_11208:
                bsr.w   sub_1129E
                lea     $40(a0),a0
                dbf     d0,loc_11208
                lea     (word_FFC000).w,a0
                moveq   #7,d0

loc_1121A:
                bsr.w   sub_1129E
                lea     $40(a0),a0
                dbf     d0,loc_1121A
                bra.s   loc_11254

loc_11228:
                lea     (unk_FFC580).w,a0
                bsr.w   sub_1129E
                lea     (word_FFC040).w,a0
                moveq   #$14,d0

loc_11236:
                bsr.w   sub_1129E
                lea     $40(a0),a0
                dbf     d0,loc_11236
                lea     (unk_FFC5C0).w,a0
                moveq   #3,d0

loc_11248:
                bsr.w   sub_1129E
                lea     $40(a0),a0
                dbf     d0,loc_11248

loc_11254:
                move.w  #$F550,(word_FFD000).w
                move.w  #1,(word_FFD002).w
                lea     (word_FFC000).w,a0
                moveq   #$1F,d7

loc_11266:
                move.w  d7,-(sp)
                tst.w   (a0)
                beq.s   loc_11280
                movea.w (word_FFD000).w,a2
                move.w  (word_FFD002).w,d6
                bsr.w   sub_11166
                move.w  d6,(word_FFD002).w
                move.w  a2,(word_FFD000).w

loc_11280:
                lea     $40(a0),a0
                move.w  (sp)+,d7
                dbf     d7,loc_11266
                movea.w (word_FFD000).w,a2
                cmpa.w  #$F550,a2
                beq.s   loc_1129A
                clr.b   -5(a2)
                rts

loc_1129A:
                clr.l   (a2)

locret_1129C:
                rts

sub_1129E:
                move.w  d0,-(sp)
                move.w  (a0),d0
                beq.s   loc_112AC
                andi.w  #$7FFC,d0
                jsr     loc_112B0(pc,d0.w)

loc_112AC:
                move.w  (sp)+,d0
                rts

loc_112B0:
                bra.w   locret_1129C
                bra.w   sub_1452E
                bra.w   sub_1483E
                bra.w   sub_13E70
                bra.w   sub_14EC6
                bra.w   sub_15D58
                bra.w   sub_16312
                bra.w   sub_16422
                bra.w   sub_16456
                bra.w   sub_164AE
                bra.w   sub_164EC
                bra.w   sub_16648
                bra.w   sub_165BA
                bra.w   sub_16600
                bra.w   sub_166C6
                bra.w   sub_16DAA
                bra.w   sub_12172
                bra.w   sub_121CC
                bra.w   sub_1223E
                bra.w   sub_12476
                bra.w   sub_134BC
                bra.w   sub_144DC
                bra.w   sub_16DCC

sub_1130C:
                move.l  (dword_FFD004).w,d0
                move.l  (dword_FFFFA8).w,d1
                add.l   d0,d1
                move.l  d1,(dword_FFFFA8).w
                move.l  (dword_FFD008).w,d0
                move.l  (dword_FFFFA4).w,d1
                add.l   d0,d1
                move.l  d1,(dword_FFFFA4).w
                rts

sub_1132A:
                lea     (VDP_CTRL).l,a6
                lea     (VDP_DATA).l,a5
                move.w  (dword_FFFFA8).w,d7
                neg.w   d7
                move.w  #$8F20,(a6)
                move.l  #$78400002,(VDP_CTRL).l
                moveq   #$17,d0

loc_1134C:
                move.w  d7,(a5)
                dbf     d0,loc_1134C
                move.l  #$78020002,(VDP_CTRL).l
                moveq   #$1B,d0

loc_1135E:
                move.w  d7,(a5)
                dbf     d0,loc_1135E
                move.w  #$8F02,(a6)
                move.w  (dword_FFFFA4).w,d7
                move.l  #$40000010,(VDP_CTRL).l
                move.w  d7,(a5)
                rts

sub_1137A:
                subq.b  #1,1(a0)
                bpl.s   loc_1138A
                move.b  1(a1),1(a0)
                addq.b  #1,0.w(a0)

loc_1138A:
                moveq   #0,d0
                move.b  0.w(a0),d0
                cmp.b   (a1),d0
                bcs.s   loc_113A0
                clr.b   0.w(a0)
                moveq   #0,d0
                move.b  #1,2(a0)

loc_113A0:
                asl.w   #2,d0
                movea.l 2(a1,d0.w),a6
                bsr.w   sub_10F70
                rts

sub_113AC:
                lea     (unk_FFC800).w,a0
                move.w  #$DF,d0

loc_113B4:
                clr.l   (a0)+
                dbf     d0,loc_113B4
                rts

sub_113BC:
                clr.l   (dword_FFFFA8).w
                clr.l   (dword_FFFFA4).w
                clr.l   (dword_FFD004).w
                clr.l   (dword_FFD008).w
                rts

sub_113CE:
                movem.w d4/d6-d7/a6,-(sp)
                lea     (unk_FFC800).w,a6
                lsl.w   #5,d6
                add.w   d7,d6
                move.b  d4,(a6,d6.w)
                movem.w (sp)+,d4/d6-d7/a6
                rts

sub_113E4:
                bsr.s   sub_113AC
                lea     (unk_FFC840).w,a0

loc_113EA:
                moveq   #0,d7
                move.b  (a6)+,d7
                beq.s   locret_113FA
                bclr    #7,d7
                bne.s   loc_113FC
                adda.l  d7,a0
                bra.s   loc_113EA

locret_113FA:
                rts

loc_113FC:
                bclr    #6,d7
                bne.s   loc_1140E
                subq.b  #1,d7

loc_11404:
                move.b  #1,(a0)+
                dbf     d7,loc_11404
                bra.s   loc_113EA

loc_1140E:
                movea.w a0,a1
                subq.b  #1,d7

loc_11412:
                move.b  #1,(a1)
                lea     $20(a1),a1
                dbf     d7,loc_11412
                addq.l  #1,a0
                bra.s   loc_113EA

sub_11422:
                bsr.s   sub_113E4
                bsr.s   sub_1148A
                bsr.w   sub_119C0
                bsr.w   sub_1194C
                bsr.w   sub_11976
                bsr.w   sub_11B86
                bsr.s   sub_1143A
                rts

sub_1143A:
                lea     (unk_FFC800).w,a0
                moveq   #$1F,d0

loc_11440:
                move.b  #$C,(a0)+
                dbf     d0,loc_11440
                lea     (unk_FFCB40).w,a0
                moveq   #$3F,d0

loc_1144E:
                move.b  #$C,(a0)+
                dbf     d0,loc_1144E
                lea     (unk_FFC840).w,a0
                moveq   #$1F,d0

loc_1145C:
                tst.b   (a0)
                beq.s   loc_1146C
                move.b  #3,-$20(a0)
                move.b  #$E,-$40(a0)

loc_1146C:
                addq.l  #1,a0
                dbf     d0,loc_1145C
                lea     (unk_FFCB20).w,a0
                moveq   #$1F,d0

loc_11478:
                tst.b   (a0)
                beq.s   loc_11482
                move.b  #$D,$20(a0)

loc_11482:
                addq.l  #1,a0
                dbf     d0,loc_11478
                rts

sub_1148A:
                lea     (byte_FFD82E).w,a0
                move.b  (a6),(a0)+
                move.b  1(a6),(a0)
                moveq   #0,d4
                moveq   #0,d0
                bsr.w   sub_11562
                lea     (byte_FFD830).w,a0
                moveq   #0,d0
                move.b  (a6),(a0)+
                move.b  1(a6),(a0)+
                moveq   #1,d4
                bsr.w   sub_11562
                lea     (unk_FFD832).w,a0
                moveq   #0,d0
                move.b  (a6),(a0)+
                move.b  1(a6),(a0)+
                moveq   #1,d4
                bsr.w   sub_11562
                lea     (byte_FFD834).w,a0
                move.b  (a6),(a0)+
                move.b  1(a6),(a0)
                moveq   #2,d4
                moveq   #0,d0
                bsr.w   sub_11562
                moveq   #3,d4
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   loc_114E0
                subq.b  #1,d0
                bsr.w   sub_11562

loc_114E0:
                moveq   #4,d4
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   loc_114EC
                subq.b  #1,d0
                bsr.s   sub_11562

loc_114EC:
                moveq   #5,d4
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   loc_114F8
                subq.b  #1,d0
                bsr.s   sub_11562

loc_114F8:
                lea     (unk_FFC200).w,a0
                moveq   #5,d0

loc_114FE:
                move.w  #4,(a0)
                move.b  (a6)+,$3E(a0)
                move.b  (a6)+,$3F(a0)
                lea     $40(a0),a0
                dbf     d0,loc_114FE
                lea     (unk_FFC480).w,a0
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   loc_1153A
                add.b   d0,(byte_FFD883).w
                subq.b  #1,d0

loc_11522:
                move.w  #8,(a0)
                move.b  (a6)+,$3E(a0)
                move.b  (a6)+,$3F(a0)
                clr.b   $3A(a0)
                lea     $40(a0),a0
                dbf     d0,loc_11522

loc_1153A:
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   locret_11560
                add.b   d0,(byte_FFD883).w
                subq.b  #1,d0

loc_11546:
                move.w  #8,(a0)
                move.b  (a6)+,$3E(a0)
                move.b  (a6)+,$3F(a0)
                move.b  #1,$3A(a0)
                lea     $40(a0),a0
                dbf     d0,loc_11546

locret_11560:
                rts

sub_11562:
                moveq   #0,d7
                moveq   #0,d6
                move.b  (a6)+,d7
                move.b  (a6)+,d6
                movem.l d0/d4/a6,-(sp)
                bsr.w   sub_11B16
                movem.l (sp)+,d0/d4/a6
                dbf     d0,sub_11562
                rts

sub_1157C:
                movem.l d6-d7/a1,-(sp)
                cmpi.w  #$80,d7
                bge.s   loc_1158A
                addi.w  #$100,d7

loc_1158A:
                cmpi.w  #$180,d7
                blt.s   loc_11594
                subi.w  #$100,d7

loc_11594:
                lea     (unk_FFC800).w,a1
                move.l  #$FFFF,d4
                and.l   d4,d7
                and.l   d4,d6
                subi.w  #$80,d7
                subi.w  #$80,d6
                lsr.w   #3,d7
                lsr.w   #3,d6
                lsl.w   #5,d6
                adda.l  d7,a1
                adda.l  d6,a1
                move.b  (a1),d4
                andi.b  #$F,d4
                movem.l (sp)+,d6-d7/a1
                rts

sub_115C0:
                add.w   $30(a0),d7
                add.w   $24(a0),d6
                cmpi.w  #$80,d7
                bge.s   loc_115D2
                addi.w  #$100,d7

loc_115D2:
                cmpi.w  #$180,d7
                blt.s   loc_115DC
                subi.w  #$100,d7

loc_115DC:
                movem.l d6-d7,-(sp)
                lea     (unk_FFC800).w,a1
                move.l  #$FFFF,d4
                and.l   d4,d7
                and.l   d4,d6
                subi.w  #$80,d7
                subi.w  #$80,d6
                lsr.w   #3,d7
                lsr.w   #3,d6
                lsl.w   #5,d6
                adda.l  d7,a1
                adda.l  d6,a1
                move.b  (a1),d4
                movem.l (sp)+,d6-d7
                rts

sub_11608:
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   loc_1162A
                subq.w  #1,d0

loc_11610:
                moveq   #0,d7
                moveq   #0,d6
                lea     (unk_FFC800).w,a0
                move.b  (a6)+,d7
                move.b  (a6)+,d6
                adda.l  d7,a0
                lsl.w   #5,d6
                adda.l  d6,a0
                bset    #7,(a0)
                dbf     d0,loc_11610

loc_1162A:
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   loc_11650
                subq.w  #1,d0

loc_11632:
                moveq   #0,d7
                moveq   #0,d6
                lea     (unk_FFC800).w,a0
                move.b  (a6)+,d7
                move.b  (a6)+,d6
                adda.l  d7,a0
                lsl.w   #5,d6
                adda.l  d6,a0
                bset    #7,(a0)
                bset    #6,(a0)
                dbf     d0,loc_11632

loc_11650:
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   locret_11672
                subq.w  #1,d0

loc_11658:
                moveq   #0,d7
                moveq   #0,d6
                lea     (unk_FFC800).w,a0
                move.b  (a6)+,d7
                move.b  (a6)+,d6
                adda.l  d7,a0
                lsl.w   #5,d6
                adda.l  d6,a0
                bset    #5,(a0)
                dbf     d0,loc_11658

locret_11672:
                rts

sub_11674:
                andi.w  #$FF,d7
                andi.w  #$FF,d6
                lsl.w   #3,d7
                lsl.w   #3,d6
                addi.w  #$80,d7
                addi.w  #$80,d6
                rts

sub_1168A:
                tst.b   (byte_FFD2A5).w
                bne.s   locret_116BC
                lea     (byte_FFD266).w,a2
                lea     (byte_FFD882).w,a1
                moveq   #3,d0
                move    #4,ccr

loc_1169E:
                abcd    -(a2),-(a1)
                dbf     d0,loc_1169E
                bsr.w   sub_11DC2
                move.l  (dword_FFD87E).w,d0
                move.l  (dword_FFCC00).w,d1
                cmp.l   d0,d1
                bge.s   locret_116BC
                move.l  d0,(dword_FFCC00).w
                bsr.w   sub_11DD4

locret_116BC:
                rts

sub_116BE:
                moveq   #1,d1
                move.b  (dword_FFD888+2).w,d0
                addi.b  #0,d0
                abcd    d1,d0
                move.b  d0,(dword_FFD888+2).w
                cmpi.b  #$60,d0
                bcs.s   locret_116FE
                clr.b   (dword_FFD888+2).w
                move.b  (dword_FFD888+1).w,d0
                addi.b  #0,d0
                abcd    d1,d0
                move.b  d0,(dword_FFD888+1).w
                cmpi.b  #$60,d0
                bcs.s   locret_116FE
                clr.b   (dword_FFD888+1).w
                move.b  (dword_FFD888).w,d0
                addi.b  #0,d0
                abcd    d1,d0
                move.b  d0,(dword_FFD888).w

locret_116FE:
                rts

sub_11700:
                lea     (byte_FFD82E).w,a0
                move.w  (a0)+,(word_FFC47E).w
                move.w  (a0),(word_FFC3BE).w
                move.w  (a0)+,(word_FFC6BE).w
                move.w  (a0),(word_FFC3FE).w
                move.w  (a0),(word_FFC6FE).w
                move.w  (a0),(word_FFC43E).w
                move.w  (a0),(word_FFC73E).w
                rts

sub_11722:
                lea     (unk_FFC480).w,a3
                lea     (unk_FFDE00).w,a4
                bra.s   loc_11734

sub_1172C:
                lea     (unk_FFDE00).w,a3
                lea     (unk_FFC480).w,a4

loc_11734:
                move.w  #$7F,d0

loc_11738:
                move.l  (a3)+,(a4)+
                dbf     d0,loc_11738
                rts

sub_11740:
                moveq   #0,d0
                move.b  (byte_FFD280).w,d0
                addq.b  #1,d0
                andi.b  #$F,d0
                move.b  d0,(byte_FFD280).w
                lsr.w   #2,d0
                lsl.w   #1,d0
                move.w  word_1175C(pc,d0.w),(word_FFD884).w
                rts

word_1175C:     dc.w $8100, $8000, $FFFF, $8000
sub_11764:
                moveq   #0,d0
                move.b  (word_FFD82C+1).w,d0

loc_1176A:
                cmp.b   d7,d0
                bcs.s   locret_11772
                sub.b   d7,d0
                bra.s   loc_1176A

locret_11772:
                rts

sub_11774:
                moveq   #0,d0
                move.b  (word_FFD82C+1).w,d0

loc_1177A:
                cmp.b   d7,d0
                bls.s   locret_11782
                sub.b   d7,d0
                bra.s   loc_1177A

locret_11782:
                rts

sub_11784:
                lea     (word_FFF7E0).w,a0
                lea     (unk_FFF860).w,a1
                moveq   #$1F,d0

loc_1178E:
                move.l  (a0)+,(a1)+
                dbf     d0,loc_1178E
                move.w  #$FFC0,(word_FFFFAC).w

loc_1179A:
                move.w  (word_FFFFAC).w,d2
                addq.w  #2,d2
                beq.s   locret_117BE
                cmpi.w  #$40,d2
                ble.s   loc_117AA
                subq.w  #2,d2

loc_117AA:
                move.w  d2,(word_FFFFAC).w
                moveq   #$FFFFFFC0,d3
                jsr     unk_FFFBA8
                jsr     unk_FFFB0C
                jsr     unk_FFFB6C
                bra.s   loc_1179A

locret_117BE:
                rts

sub_117C0:
                tst.w   (a1)
                beq.w   loc_11874
                moveq   #0,d0
                moveq   #0,d1
                move.b  4(a0),d0
                cmpi.b  #$FF,d0
                beq.w   loc_11874
                move.b  4(a1),d1
                cmpi.b  #$FF,d1
                beq.w   loc_11874
                lsl.w   #3,d0
                lsl.w   #3,d1
                move.w  $20(a0),d3
                lea     word_11878(pc),a6
                add.w   (a6,d0.w),d3
                move.w  d3,d2
                addq.l  #2,a6
                add.w   (a6,d0.w),d3
                move.w  $20(a1),d5
                add.w   word_11878(pc,d1.w),d5
                move.w  d5,d4
                add.w   word_1187A(pc,d1.w),d5
                cmp.w   d2,d4
                blt.s   loc_11812
                cmp.w   d3,d4
                bgt.s   loc_11812
                bra.s   loc_1182E

loc_11812:
                cmp.w   d2,d5
                blt.s   loc_1181C
                cmp.w   d3,d5
                bgt.s   loc_1181C
                bra.s   loc_1182E

loc_1181C:
                cmp.w   d4,d2
                blt.s   loc_11826
                cmp.w   d5,d2
                bgt.s   loc_11826
                bra.s   loc_1182E

loc_11826:
                cmp.w   d4,d3
                blt.s   loc_11874
                cmp.w   d5,d3
                bgt.s   loc_11874

loc_1182E:
                move.w  $24(a0),d3
                add.w   word_1187C(pc,d0.w),d3
                move.w  d3,d2
                add.w   word_1187E(pc,d0.w),d3
                move.w  $24(a1),d5
                add.w   word_1187C(pc,d1.w),d5
                move.w  d5,d4
                add.w   word_1187E(pc,d1.w),d5
                cmp.w   d2,d4
                blt.s   loc_11854
                cmp.w   d3,d4
                bgt.s   loc_11854
                bra.s   loc_11870

loc_11854:
                cmp.w   d2,d5
                blt.s   loc_1185E
                cmp.w   d3,d5
                bgt.s   loc_1185E
                bra.s   loc_11870

loc_1185E:
                cmp.w   d4,d2
                blt.s   loc_11868
                cmp.w   d5,d2
                bgt.s   loc_11868
                bra.s   loc_11870

loc_11868:
                cmp.w   d4,d3
                blt.s   loc_11874
                cmp.w   d5,d3
                bgt.s   loc_11874

loc_11870:
                moveq   #1,d0
                rts

loc_11874:
                moveq   #0,d0
                rts

word_11878:     dc.w $FFFF
word_1187A:     dc.w 2
word_1187C:     dc.w $FFEE
word_1187E:     dc.w $12
                dc.l $FFFF0002
                dc.l $FFF00010
                dc.l $FFFC0008
                dc.l $FFF2000C
                dc.l $FFF9000E
                dc.l $FFF4000C
                dc.l $FFFC0008
                dc.l $FFFA0006
                dc.l $FFFF0002
                dc.l $FFEE0012
                dc.l $FFFE0004
                dc.l $FFF60004
                dc.l $FFFC0008
                dc.l $FFF90007
                dc.l $FFFF0002
                dc.l $FFFA0006
                dc.l $FFFC0008
                dc.l $FFF6000A
                dc.l $FFFC0008
                dc.l $FFFC0002
                dc.l $FFFC0008
                dc.l $30002
                dc.l $FFFC0002
                dc.l $FFFC0008
                dc.l $40002
                dc.l $FFFC0008
                dc.l $FFFF0002
                dc.l $FFFD0006
                dc.l $FFFE0004
                dc.l 8
                dc.l $FFF80010
                dc.l $FFF00010
                dc.l $FFF80010
                dc.l $FFF00002
                dc.l $FFFF0002
                dc.l $FFEE000E
sub_11910:
                lsl.w   #1,d4
                move.w  word_1191C(pc,d4.w),d4
                bsr.w   sub_10F3E
                rts

word_1191C:     dc.w $220D, $2206, $2207, $2208, $2209, $220A, $220B, $220C
                dc.w $220D, $220E, $220F, $2210, $2211, $2212, $2213, $2214
sub_1193C:
                lsl.w   #1,d4
                movea.l (dword_FFD800).w,a1
                move.w  (a1,d4.w),d4
                bsr.w   sub_10F3E
                rts

sub_1194C:
                moveq   #0,d5
                move.w  #$E000,d5
                moveq   #7,d0

loc_11954:
                move.w  d0,-(sp)
                bsr.s   sub_11962
                move.w  (sp)+,d0
                addq.w  #8,d5
                dbf     d0,loc_11954
                rts

sub_11962:
                lea     (dword_FFD808).w,a6
                movea.l (a6),a6
                moveq   #3,d7
                moveq   #1,d6
                move.l  d5,-(sp)
                bsr.w   sub_10F6E
                move.l  (sp)+,d5
                rts

sub_11976:
                moveq   #0,d5
                move.w  #$E680,d5
                moveq   #7,d0

loc_1197E:
                move.w  d0,-(sp)
                bsr.s   sub_1198C
                move.w  (sp)+,d0
                addq.w  #8,d5
                dbf     d0,loc_1197E
                rts

sub_1198C:
                lea     (dword_FFD80C).w,a6
                movea.l (a6),a6
                moveq   #3,d7
                moveq   #1,d6
                move.l  d5,-(sp)
                bsr.w   sub_10F6E
                move.l  (sp)+,d5
                rts

sub_119A0:
                move.l  #$60800003,(VDP_CTRL).l
                movea.l (dword_FFD804).w,a0
                move.w  (a0),d1
                move.w  #$2FF,d0

loc_119B4:
                move.w  d1,(VDP_DATA).l
                dbf     d0,loc_119B4
                rts

sub_119C0:
                lea     (unk_FFC840).w,a0
                moveq   #0,d1
                moveq   #0,d2
                moveq   #0,d6
                move.w  #$E080,d6
                move.w  d6,d5
                move.w  #$2FF,d0

loc_119D4:
                moveq   #0,d4
                moveq   #0,d5
                move.w  d6,d5
                tst.b   (a0)
                beq.w   loc_119F4
                andi.w  #$1F,d2
                beq.w   loc_11A34
                cmpi.w  #$1F,d2
                beq.w   loc_11A66
                bra.w   loc_11A98

loc_119F4:
                andi.w  #$1F,d2
                beq.w   loc_11ACA
                bra.w   loc_11AF0

loc_11A00:
                addq.l  #1,a0
                addq.w  #1,d1
                move.w  d1,d2
                addq.w  #2,d6
                dbf     d0,loc_119D4
                lea     (unk_FFC840).w,a0
                moveq   #0,d5
                move.w  #$E080,d5
                moveq   #$1F,d0

loc_11A18:
                tst.b   (a0)+
                bne.s   loc_11A2C
                move.w  #3,d4
                movem.l d5/a0,-(sp)
                bsr.w   sub_1193C
                movem.l (sp)+,d5/a0

loc_11A2C:
                addq.w  #2,d5
                dbf     d0,loc_11A18
                rts

loc_11A34:
                tst.b   -$20(a0)
                beq.s   loc_11A3E
                bset    #0,d4

loc_11A3E:
                tst.b   $20(a0)
                beq.s   loc_11A48
                bset    #1,d4

loc_11A48:
                tst.b   $1F(a0)
                beq.s   loc_11A52
                bset    #2,d4

loc_11A52:
                tst.b   1(a0)
                beq.s   loc_11A5C
                bset    #3,d4

loc_11A5C:
                move.b  d4,(a0)
                bsr.w   sub_11910
                bra.w   loc_11A00

loc_11A66:
                tst.b   -$20(a0)
                beq.s   loc_11A70
                bset    #0,d4

loc_11A70:
                tst.b   $20(a0)
                beq.s   loc_11A7A
                bset    #1,d4

loc_11A7A:
                tst.b   -1(a0)
                beq.s   loc_11A84
                bset    #2,d4

loc_11A84:
                tst.b   -$1F(a0)
                beq.s   loc_11A8E
                bset    #3,d4

loc_11A8E:
                move.b  d4,(a0)
                bsr.w   sub_11910
                bra.w   loc_11A00

loc_11A98:
                tst.b   -$20(a0)
                beq.s   loc_11AA2
                bset    #0,d4

loc_11AA2:
                tst.b   $20(a0)
                beq.s   loc_11AAC
                bset    #1,d4

loc_11AAC:
                tst.b   -1(a0)
                beq.s   loc_11AB6
                bset    #2,d4

loc_11AB6:
                tst.b   1(a0)
                beq.s   loc_11AC0
                bset    #3,d4

loc_11AC0:
                move.b  d4,(a0)
                bsr.w   sub_11910
                bra.w   loc_11A00

loc_11ACA:
                tst.b   -$20(a0)
                beq.s   loc_11AD4
                bset    #0,d4

loc_11AD4:
                tst.b   -1(a0)
                beq.s   loc_11ADE
                bset    #1,d4

loc_11ADE:
                tst.b   $1F(a0)
                beq.s   loc_11AE8
                bset    #2,d4

loc_11AE8:
                bsr.w   sub_1193C
                bra.w   loc_11A00

loc_11AF0:
                tst.b   -$20(a0)
                beq.s   loc_11AFA
                bset    #0,d4

loc_11AFA:
                tst.b   -$21(a0)
                beq.s   loc_11B04
                bset    #1,d4

loc_11B04:
                tst.b   -1(a0)
                beq.s   loc_11B0E
                bset    #2,d4

loc_11B0E:
                bsr.w   sub_1193C
                bra.w   loc_11A00

sub_11B16:
                moveq   #0,d5
                move.w  #$C000,d5
                bsr.w   sub_10F24
                lsl.w   #2,d4
                move.w  word_11B3C(pc,d4.w),d7
                move.w  word_11B3E(pc,d4.w),d6
                lsr.w   #1,d4
                moveq   #$FFFFFFFF,d2
                move.w  word_11B54(pc,d4.w),d2
                movea.l d2,a6
                movea.l (a6),a6
                bsr.w   sub_10F70
                rts

word_11B3C:     dc.w 2
word_11B3E:     dc.w 2, 1, 1, 1, 2, 1, 2, 4, 2, 3, 3
word_11B54:     dc.w $D81C, $D820, $D824, $D810, $D814, $D818
sub_11B60:
                moveq   #0,d7
                moveq   #0,d6
                moveq   #0,d5
                move.b  (byte_FFD82E).w,d7
                move.b  (byte_FFD82F).w,d6
                move.w  #$E000,d5
                bsr.w   sub_10F24
                moveq   #2,d7
                moveq   #2,d6
                lea     (word_1A4B4).l,a6
                bsr.w   sub_10F70
                rts

sub_11B86:
                lea     (byte_FFD82E).w,a0
                moveq   #0,d7
                moveq   #0,d6
                moveq   #0,d5
                move.b  0.w(a0),d7
                move.b  1(a0),d6
                subq.b  #1,d6
                move.w  #$E000,d5
                bsr.w   sub_10F24
                moveq   #2,d7
                moveq   #0,d6
                lea     (word_1A262).l,a6
                btst    #7,(IO_PCBVER+1).l
                beq.s   loc_11BBC
                lea     (word_11C98).l,a6

loc_11BBC:
                bsr.w   sub_10F70
                rts

sub_11BC2:
                moveq   #4,d0
                moveq   #5,d3

loc_11BC6:
                move.w  word_11BDC(pc,d0.w),d1
                move.w  word_11BDE(pc,d0.w),d4
                lsr.w   #1,d0
                moveq   #$FFFFFFFF,d2
                move.w  word_11BF8(pc,d0.w),d2
                lsl.w   #1,d0
                movea.l d2,a0
                bra.s   loc_11C06
word_11BDC:     dc.w 0
word_11BDE:     dc.w 0, 0, 0, 1, 1, 0, 2, $13, 3, 7, 4, 7, 5
word_11BF8:     dc.w 0, $D82E, $D830, $D834, $D836, $D85E, $D86E

loc_11C06:
                tst.b   2(a0)
                beq.s   loc_11C24
                moveq   #0,d7
                moveq   #0,d6
                move.b  0.w(a0),d7
                move.b  1(a0),d6
                movem.w d0-d4/a0,-(sp)
                bsr.w   sub_11B16
                movem.w (sp)+,d0-d4/a0

loc_11C24:
                addq.l  #4,a0
                dbf     d1,loc_11C06
                addq.w  #4,d0
                dbf     d3,loc_11BC6
                tst.b   (byte_FFD830).w
                beq.s   locret_11C3A
                bsr.w   sub_11B86

locret_11C3A:
                rts

sub_11C3C:
                lea     (unk_FFD258).w,a0
                lea     byte_11C74(pc),a1
                btst    #7,(IO_PCBVER+1).l
                beq.s   loc_11C52
                lea     byte_11C86(pc),a1

loc_11C52:
                moveq   #0,d7
                moveq   #0,d6
                moveq   #0,d5
                move.b  (byte_FFD82E).w,d7
                move.b  (byte_FFD82F).w,d6
                subq.b  #1,d6
                move.w  #$E000,d5
                bsr.w   sub_10F24
                moveq   #2,d7
                moveq   #0,d6
                bsr.w   sub_1137A
                rts

byte_11C74:     dc.b 4
                dc.b 4
                dc.l word_1A262
                dc.l word_1A26E
                dc.l word_1A268
                dc.l word_1A26E
byte_11C86:     dc.b 4
                dc.b 4
                dc.l word_11C98
                dc.l word_11CA4
                dc.l word_11C9E
                dc.l word_11CA4
word_11C98:     dc.w $693, $694, $695
word_11C9E:     dc.w $696, $697, $698
word_11CA4:     dc.w $699, $69A, $69B
sub_11CAA:
                lea     byte_11CB8(pc),a1
                bsr.w   sub_11D38
                bsr.w   sub_116BE
                rts

byte_11CB8:     dc.b 4
                dc.b $F
                dc.l word_1A490
                dc.l word_1A46C
                dc.l word_1A47E
                dc.l word_1A490
sub_11CCA:
                lea     byte_11CD4(pc),a1
                jmp     sub_11D38

byte_11CD4:     dc.b 4
                dc.b 2
                dc.l word_1A274
                dc.l word_1A490
                dc.l word_1A47E
                dc.l word_1A46C
sub_11CE6:
                lea     byte_11CF0(pc),a1
                jmp     sub_11D38

byte_11CF0:     dc.b 5
                dc.b 2
                dc.l word_11D06
                dc.l word_1A46C
                dc.l word_1A47E
                dc.l word_1A490
                dc.l word_1A4A2
word_11D06:     dc.w 0, 0, 0, 0, 0, 0, 0, 0, 0
sub_11D18:
                lea     byte_11D22(pc),a1
                jmp     sub_11D38

byte_11D22:     dc.b 5
                dc.b 1
                dc.l word_1A274
                dc.l word_1A4A2
                dc.l word_1A490
                dc.l word_1A47E
                dc.l word_1A46C
sub_11D38:
                move.b  #1,(byte_FFD27B).w
                lea     (unk_FFD254).w,a0
                clr.l   (a0)
                moveq   #0,d7
                moveq   #0,d6
                moveq   #0,d5
                move.b  (byte_FFD82E).w,d7
                move.b  (byte_FFD82F).w,d6
                move.w  #$C000,d5
                bsr.w   sub_10F24
                moveq   #2,d7
                moveq   #2,d6

loc_11D5E:
                movem.l d5-d7/a0-a4,-(sp)
                bsr.w   sub_1137A
                tst.b   2(a0)
                bne.s   loc_11D7E
                bsr.w   sub_111E2
                bsr.w   sub_116BE
                jsr     unk_FFFB6C
                movem.l (sp)+,d5-d7/a0-a4
                bra.s   loc_11D5E

loc_11D7E:
                clr.b   (byte_FFD27B).w
                movem.l (sp)+,d5-d7/a0-a4
                rts

sub_11D88:
                moveq   #0,d0
                move.b  (byte_FFD882).w,d0
                beq.s   locret_11DC0
                subq.w  #1,d0
                beq.s   locret_11DC0
                subq.w  #1,d0
                move.l  #$46840003,(VDP_CTRL).l
                btst    #6,(IO_PCBVER+1).l
                beq.s   loc_11DB4
                move.l  #$47440003,(VDP_CTRL).l

loc_11DB4:
                move.w  #$4350,(VDP_DATA).l
                dbf     d0,loc_11DB4

locret_11DC0:
                rts

sub_11DC2:
                lea     (dword_FFD87E).w,a6
                moveq   #0,d5
                move.w  #$C04A,d5
                moveq   #3,d0
                bsr.w   sub_10FF4
                rts

sub_11DD4:
                lea     (dword_FFCC00).w,a6
                moveq   #0,d5
                move.w  #$C068,d5
                moveq   #3,d0
                bsr.w   sub_10FF4
                rts

sub_11DE6:
                lea     (word_FFD82C).w,a6
                moveq   #0,d5
                move.w  #$C6BA,d5
                btst    #6,(IO_PCBVER+1).l
                beq.s   loc_11DFE
                move.w  #$C77A,d5

loc_11DFE:
                moveq   #0,d0
                bsr.w   sub_10FF4
                rts

sub_11E06:
                lea     byte_11E46(pc),a6
                btst    #6,(IO_PCBVER+1).l
                beq.s   loc_11E18
                lea     byte_11E4C(pc),a6

loc_11E18:
                bsr.w   sub_10FAA

sub_11E1C:
                lea     (word_1A4CA).l,a6
                moveq   #1,d7
                moveq   #0,d6
                moveq   #0,d5
                move.w  #$C048,d5
                bsr.w   sub_10F6E
                lea     (word_1A4D2).l,a6
                moveq   #2,d7
                moveq   #0,d6
                moveq   #0,d5
                move.w  #$C064,d5
                bsr.w   sub_10F6E
                rts

byte_11E46:     dc.b $C6, $B4
aRd:            dc.b "RD.",0
byte_11E4C:     dc.b $C7, $74
aRd_0:          dc.b "RD.",0
sub_11E52:
                lea     (byte_FFD266).w,a6
                moveq   #0,d5
                move.w  #$C160,d5
                btst    #7,(IO_PCBVER+1).l
                beq.s   loc_11E68
                subq.w  #4,d5

loc_11E68:
                moveq   #0,d0
                bsr.w   sub_10FF4
                lea     (byte_FFD267).w,a6
                moveq   #0,d5
                move.w  #$C16C,d5
                moveq   #0,d0
                bsr.w   sub_10FF4
                tst.b   (byte_FFD266).w
                bne.s   locret_11E94
                lea     (dword_FFD268).w,a6
                moveq   #0,d5
                move.w  #$C260,d5
                moveq   #3,d0
                bsr.w   sub_10FF4

locret_11E94:
                rts

sub_11E96:
                lea     byte_11F04(pc),a6
                btst    #7,(IO_PCBVER+1).l
                beq.s   loc_11EA8
                lea     byte_11F40(pc),a6

loc_11EA8:
                bsr.w   sub_10FAA
                lea     byte_11F10(pc),a6
                btst    #7,(IO_PCBVER+1).l
                beq.s   loc_11EBE
                lea     byte_11F4E(pc),a6

loc_11EBE:
                bsr.w   sub_10FAA
                btst    #7,(IO_PCBVER+1).l
                beq.s   loc_11ED4
                lea     byte_11F56(pc),a6
                bsr.w   sub_10FAA

loc_11ED4:
                lea     byte_11F1E(pc),a6
                btst    #7,(IO_PCBVER+1).l
                beq.s   loc_11EE6
                lea     byte_11F5E(pc),a6

loc_11EE6:
                bsr.w   sub_10FAA
                tst.b   (byte_FFD266).w
                bne.s   loc_11EFA
                lea     byte_11F2C(pc),a6
                bsr.w   sub_10FAA
                bra.s   locret_11F02

loc_11EFA:
                lea     byte_11F34(pc),a6
                bsr.w   sub_10FAA

locret_11F02:
                rts

byte_11F04:     dc.b $C1, $4A
aGameTime:      dc.b "GAME TIME",0
byte_11F10:     dc.b $C1, $64
aMinSec:        dc.b "MIN.  SEC.",0
                dc.b 0
byte_11F1E:     dc.b $C2, $4A
aTimeBonus:     dc.b "TIME BONUS",0
                dc.b 0
byte_11F2C:     dc.b $C2, $72
aPts:           dc.b "PTS.",0
                dc.b 0
byte_11F34:     dc.b $C2, $68
aNoBonus:       dc.b "NO BONUS",0
                dc.b 0
byte_11F40:     dc.b $C1, $48
aRoundTime:     dc.b "ROUND TIME",0
                dc.b 0
byte_11F4E:     dc.b $C1, $62
aMin:           dc.b "MIN.",0
                dc.b 0
byte_11F56:     dc.b $C1, $72
aSec:           dc.b "SEC.",0
                dc.b 0
byte_11F5E:     dc.b $C2, $48
aTimeBonus_0:   dc.b "TIME BONUS",0
                dc.b 0
sub_11F6C:
                tst.b   (byte_FFD28E).w
                beq.s   locret_11FAA
                lea     (byte_FFD28F).w,a6
                moveq   #0,d5
                move.w  #$C248,d5
                moveq   #0,d0
                bsr.w   sub_10FF4
                lea     ((dword_FFD290+2)).w,a6
                moveq   #0,d5
                move.w  #$C266,d5
                moveq   #1,d0
                bsr.w   sub_10FF4
                cmpi.b  #$14,(byte_FFD28E).w
                bne.s   locret_11FAA
                lea     byte_11FAC(pc),a6
                moveq   #0,d5
                move.w  #$C390,d5
                moveq   #3,d0
                bsr.w   sub_10FF4

locret_11FAA:
                rts

byte_11FAC:     dc.b 0, 1, 0, 0
sub_11FB0:
                bsr.w   sub_100D4
                move.w  #$740,d0
                jsr     unk_FFFB8A
                lea     (FlickyLogoTiles).l,a0
                jsr     j_Nem_Decomp
                clr.b   (byte_FFD88E).w
                bsr.w   loc_10126
                lea     (word_16DE8).l,a5
                jsr     unk_FFFBBA
                lea     word_1210C(pc),a0
                lea     (unk_FFF840).w,a1
                moveq   #3,d0

loc_11FE2:
                move.l  (a0)+,(a1)+
                dbf     d0,loc_11FE2
                moveq   #5,d0
                lea     off_12086(pc),a0
                btst    #7,(IO_PCBVER+1).l
                beq.s   loc_11FFC
                lea     off_1209E(pc),a0

loc_11FFC:
                movea.l (a0)+,a6
                bsr.w   sub_10FAA
                dbf     d0,loc_11FFC
                move.b  #3,(byte_FFD882).w
                move.w  #$101,(word_FFD82C).w
                move.b  #1,(byte_FFD88F).w
                lea     (word_FFC000).w,a0
                moveq   #0,d1
                moveq   #3,d0

loc_12020:
                move.w  #$40,(a0)
                move.w  d1,$38(a0)
                lea     $40(a0),a0
                addq.w  #1,d1
                dbf     d0,loc_12020
                move.w  #$44,(a0)
                lea     (unk_FFC140).w,a0
                moveq   #0,d1
                moveq   #5,d0

loc_1203E:
                move.w  #$48,(a0)
                move.w  d1,$38(a0)
                lea     $40(a0),a0
                addq.w  #1,d1
                dbf     d0,loc_1203E
                btst    #7,(IO_PCBVER+1).l
                beq.s   loc_12062
                lea     byte_1211C(pc),a6
                bsr.w   sub_10FC0

loc_12062:
                bsr.w   sub_11E1C
                bsr.w   sub_11DC2
                bsr.w   sub_11DD4
                bsr.w   sub_111E2
                clr.w   (word_FFFF92).w
                move.b  #$85,d0
                jsr     unk_FFFB66
                jsr     unk_FFFB6C
                jmp     unk_FFFB6C

off_12086:      dc.l byte_120B6
                dc.l byte_120BE
                dc.l byte_120C8
                dc.l byte_120D2
                dc.l byte_120DE
                dc.l byte_120E6
off_1209E:      dc.l byte_120B6
                dc.l byte_120BE
                dc.l byte_120F4
                dc.l byte_120FC
                dc.l byte_12104
                dc.l byte_120E6
byte_120B6:     dc.b $C2, $9C
aCast:          dc.b "CAST",0
                dc.b 0
byte_120BE:     dc.b $C3, $10
aFlicky:        dc.b "FLICKY",0
                dc.b 0
byte_120C8:     dc.b $C3, $28
aPiopio:        dc.b "PIOPIO",0
                dc.b 0
byte_120D2:     dc.b $C3, $D0
aNyannyan:      dc.b "NYANNYAN",0
                dc.b 0
byte_120DE:     dc.b $C3, $E8
aChoro:         dc.b "CHORO",0
byte_120E6:     dc.b $C6, $54
aSega1991:      dc.b $27," SEGA 1991",0
byte_120F4:     dc.b $C3, $28
aChirp:         dc.b "CHIRP",0
byte_120FC:     dc.b $C3, $D0
aTiger:         dc.b "TIGER",0
byte_12104:     dc.b $C3, $E8
aIggy:          dc.b "IGGY",0
                dc.b 0
word_1210C:     binclude "data/palettes/title-logo.bin"
byte_1211C:     dc.b $C0, $EE
aTm:            dc.b "TM",0
                dc.b 0
sub_12122:
                btst    #7,(word_FFFF8E+1).w
                beq.s   loc_12146
                bsr.w   sub_11784
                move.b  #$E0,d0
                bsr.w   sub_10D34
                move.b  #1,(byte_FFD88E).w
                bsr.w   loc_10126
                move.w  #8,(word_FFFFC0).w

loc_12146:
                cmpi.w  #$400,(word_FFFF92).w
                bcs.s   loc_1216A
                bsr.w   sub_11784
                move.b  #$E0,d0
                bsr.w   sub_10D34
                move.b  #1,(byte_FFD88E).w
                bsr.w   loc_10126
                move.w  #$38,(word_FFFFC0).w

loc_1216A:
                bsr.w   sub_111E2
                jmp     unk_FFFB6C

sub_12172:
                bset    #7,(a0)
                bne.s   loc_1219E
                bset    #7,2(a0)
                move.w  $38(a0),d0
                lsl.w   #1,d0
                move.w  word_121B4(pc,d0.w),6(a0)
                lsl.w   #1,d0
                move.l  off_121A4(pc,d0.w),8(a0)
                move.w  word_121BC(pc,d0.w),$20(a0)
                move.w  word_121BE(pc,d0.w),$24(a0)

loc_1219E:
                bsr.w   sub_11126
                rts

off_121A4:      dc.l off_144AC
                dc.l off_14E12
                dc.l off_154AE
                dc.l off_162BC
word_121B4:     dc.w 0, 4, 4, 0
word_121BC:     dc.w $B0
word_121BE:     dc.w $F0, $110, $EC, $B0, $108, $110, $100
sub_121CC:
                bset    #7,(a0)
                bne.s   loc_121E6
                move.l  #word_1ACDC,$C(a0)
                move.w  #$F0,$20(a0)
                move.w  #$120,$24(a0)

loc_121E6:
                move.w  $3C(a0),d0
                andi.w  #$7C,d0
                jsr     loc_121F4(pc,d0.w)
                rts

loc_121F4:
                bra.w   sub_121FC
                bra.w   sub_1221E

sub_121FC:
                bset    #7,$3C(a0)
                bne.s   loc_12210
                bclr    #1,2(a0)
                move.w  #$3C,$3A(a0)

loc_12210:
                subq.w  #1,$3A(a0)
                bne.s   locret_1221C
                move.w  #4,$3C(a0)

locret_1221C:
                rts

sub_1221E:
                bset    #7,$3C(a0)
                bne.s   loc_12232
                bset    #1,2(a0)
                move.w  #$14,$3A(a0)

loc_12232:
                subq.w  #1,$3A(a0)
                bne.s   locret_1223C
                clr.w   $3C(a0)

locret_1223C:
                rts

sub_1223E:
                bset    #7,(a0)
                bne.s   locret_1225C
                move.w  $38(a0),d0
                lsl.w   #2,d0
                move.l  off_1225E(pc,d0.w),$C(a0)
                move.w  word_12276(pc,d0.w),$20(a0)
                move.w  word_12278(pc,d0.w),$24(a0)

locret_1225C:
                rts

off_1225E:      dc.l word_1AD52
                dc.l word_1AD5A
                dc.l word_1AD62
                dc.l word_1AD6A
                dc.l word_1AD72
                dc.l word_1AD7A
word_12276:     dc.w $D0
word_12278:     dc.w $C0, $E5, $C0, $F7, $C0, $107, $C0, $11C, $C0, $133, $C0
sub_1228E:
                moveq   #7,d1

loc_12290:
                jsr     unk_FFFB6C
                dbf     d1,loc_12290
                bsr.w   sub_100D4
                lea     (word_16DE8).l,a5
                jsr     unk_FFFBBA
                clr.l   (dword_FFD87E).w
                clr.b   (byte_FFD887).w
                bsr.w   sub_1268E
                bsr.w   sub_12824
                bsr.w   sub_1230A
                lea     (word_FFC000).w,a0
                moveq   #0,d1
                moveq   #$13,d0

loc_122C2:
                move.w  #$4C,(a0)
                move.w  d1,$38(a0)
                lea     $40(a0),a0
                addq.w  #1,d1
                dbf     d0,loc_122C2
                bsr.w   sub_111E2
                jsr     unk_FFFB6C
                jmp     unk_FFFB6C

sub_122E0:
                btst    #7,(word_FFFF8E+1).w
                beq.s   loc_12306
                move.w  #$18,(word_FFFFC0).w
                move.b  (word_FFFF8E).w,d0
                bclr    #7,d0
                cmpi.b  #$61,d0
                bne.s   loc_12302
                move.w  #$10,(word_FFFFC0).w

loc_12302:
                bsr.w   sub_11784

loc_12306:
                jmp     unk_FFFB6C

sub_1230A:
                moveq   #5,d0
                lea     off_12384(pc),a0
                btst    #7,(IO_PCBVER+1).l
                beq.s   loc_1231E
                lea     off_123F0(pc),a0

loc_1231E:
                movea.l (a0)+,a6
                bsr.w   sub_10FC0
                dbf     d0,loc_1231E
                lea     (byte_FFD82E).w,a0
                moveq   #$E,d7
                btst    #7,(IO_PCBVER+1).l
                beq.s   loc_1233A
                moveq   #$F,d7

loc_1233A:
                moveq   #6,d6
                moveq   #0,d4
                move.b  d7,(a0)
                move.b  d6,1(a0)
                bsr.w   sub_11B16
                bsr.w   sub_11B86
                moveq   #5,d7
                moveq   #$17,d6
                moveq   #0,d4
                move.b  d7,(a0)
                move.b  d6,1(a0)
                bsr.w   sub_11B16
                bsr.w   sub_11B86
                bsr.w   sub_11976
                bsr.w   sub_1194C
                lea     (VDP_DATA).l,a0
                move.l  #$648A0003,(VDP_CTRL).l
                moveq   #$15,d0

loc_1237A:
                move.w  #$220D,(a0)
                dbf     d0,loc_1237A
                rts

off_12384:      dc.l byte_1239C
                dc.l byte_123A4
                dc.l byte_123AE
                dc.l byte_123B2
                dc.l byte_123C2
                dc.l byte_123DA
byte_1239C:     dc.b $C0, $DA
                dc.b $60, $6E, $A7, $65, $6F, 0
byte_123A4:     dc.b $C2, 8
                dc.b $8C, $6E, $62, $6A, $6B, $72, 0, 0
byte_123AE:     dc.b $C2, $18
                dc.b $8C, 0
byte_123B2:     dc.b $C2, $24
                dc.b $7E, $A4, $71, $89, $72, $61, $93, $72
                dc.b $67, $A1, $6A, $61, $12, 0
byte_123C2:     dc.b $C3, 6
                dc.b $FA, $BF, $DD, $8C, $64, $6C, $73, $11
                dc.b $ED, $E4, $DD, $FD, $20, $26, $20, $BB
                dc.b $E6, $E3, $C3, $12, 0, 0
byte_123DA:     dc.b $C5, $94
                dc.b $7E, $73, $81, $72, $71, $89, $72, $65
                dc.b $63, $88, $73, $11, $69, $62, $73, $67
                dc.b $72, $8D, $21, 0
off_123F0:      dc.l byte_12408
                dc.l byte_1241A
                dc.l byte_12422
                dc.l byte_1242A
                dc.l byte_1243A
                dc.l byte_1245C
byte_12408:     dc.b $C0, $D2
aMakeYourMove:  dc.b "MAKE YOUR MOVE",0
                dc.b 0
byte_1241A:     dc.b $C2, 2
aHelp:          dc.b "HELP",0
                dc.b 0
byte_12422:     dc.b $C2, $E
aGuide:         dc.b "GUIDE",0
byte_1242A:     dc.b $C2, $26
aToTheDoor:     dc.b "TO THE DOOR!",0
                dc.b 0
byte_1243A:     dc.b $C2, $C2
aPressButtonToJ:dc.b "PRESS BUTTON TO JUMP AND SHOOT",0
                dc.b 0
byte_1245C:     dc.b $C5, $92
aRackUpASuperSc:dc.b "RACK UP A SUPER SCORE!",0
                dc.b 0
sub_12476:
                bset    #7,(a0)
                bne.s   locret_124B8
                move.w  $38(a0),d0
                bclr    #7,2(a0)
                move.b  byte_124BA(pc,d0.w),d1
                beq.s   loc_12492
                bset    #7,2(a0)

loc_12492:
                lsl.w   #2,d0
                move.l  off_124CE(pc,d0.w),$C(a0)
                lea     word_1251E(pc),a1
                btst    #7,(IO_PCBVER+1).l
                beq.s   loc_124AC
                lea     word_1256E(pc),a1

loc_124AC:
                move.w  (a1,d0.w),$20(a0)
                move.w  2(a1,d0.w),$24(a0)

locret_124B8:
                rts

byte_124BA:     dc.b 0, 0, 1, 0, 1, 1, 1, 0, 0, 0
                dc.b 0, 0, 0, 1, 1, 1, 1, 1, 1, 1
off_124CE:      dc.l word_1A848
                dc.l word_1A7F0
                dc.l word_1A800
                dc.l word_1A7D8
                dc.l word_1A7C8
                dc.l word_1A7D8
                dc.l word_1A7F0
                dc.l word_1A830
                dc.l word_1A898
                dc.l word_1A7B8
                dc.l word_1A8D0
                dc.l word_1A528
                dc.l word_1A99A
                dc.l byte_1A8A8
                dc.l word_1A7E8
                dc.l word_1A848
                dc.l word_1A850
                dc.l word_1A7F8
                dc.l word_1A7F0
                dc.l word_1A858
word_1251E:     dc.w $B4, $A0, $C0, $A0, $CC, $A0, $D8, $A0, $120, $A0
                dc.w $12C, $A0, $138, $A0, $144, $A0, $98, $C8, $D8, $C8
                dc.w $D0, $100, $118, $100, $118, $110, $C0, $150, $C8, $150
                dc.w $D0, $150, $D8, $150, $E0, $150, $E8, $150, $F0, $150
word_1256E:     dc.w $94, $A0, $A0, $A0, $AC, $A0, $B8, $A0, $148, $A0
                dc.w $154, $A0, $160, $A0, $16C, $A0, $B0, $C8, $E8, $C8
                dc.w $D0, $100, $118, $100, $118, $110, $C0, $150, $C8, $150
                dc.w $D0, $150, $D8, $150, $E0, $150, $E8, $150, $F0, $150
sub_125BE:
                bsr.w   sub_100D4
                lea     (word_16DE8).l,a5
                jsr     unk_FFFBBA
                lea     byte_125E8(pc),a6
                bsr.w   sub_10FAA
                move.b  #3,(byte_FFD882).w
                move.b  #1,(byte_FFD29A).w
                jsr     unk_FFFB6C
                jmp     unk_FFFB6C

byte_125E8:     dc.b $C3, $54
aRound:         dc.b "ROUND ",0
                dc.b 0
sub_125F2:
                move.b  (word_FFD82C).w,d1
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
                bsr.w   sub_10FF4
                jmp     unk_FFFB6C

sub_12656:
                bsr.w   sub_100D4
                lea     (word_16DE8).l,a5
                jsr     unk_FFFBBA
                clr.l   (dword_FFD888).w
                clr.b   (byte_FFD88D).w
                rts

sub_1266E:
                move.w  #$20,(word_FFFFC0).w
                move.b  (word_FFD82C+1).w,d0
                andi.b  #3,d0
                cmpi.b  #3,d0
                bne.s   loc_12688
                move.w  #$28,(word_FFFFC0).w

loc_12688:
                jsr     unk_FFFB6C
                rts

sub_1268E:
                moveq   #$18,d7
                bsr.w   sub_11764
                lsr.w   #2,d0
                lsl.w   #2,d0
                lea     off_12728(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(dword_FFD804).w
                lea     off_12740(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(dword_FFD800).w
                lea     off_12758(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(dword_FFD808).w
                lea     off_12770(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(dword_FFD80C).w
                lea     off_127B8(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(dword_FFD814).w
                lea     off_127D0(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(dword_FFD818).w
                moveq   #$20,d7
                bsr.w   sub_11774
                subq.b  #1,d0
                lsr.w   #2,d0
                lsl.w   #2,d0
                lea     off_12788(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(dword_FFD810).w
                moveq   #$F,d7
                bsr.w   sub_11774
                subq.b  #1,d0
                lsl.w   #2,d0
                lea     off_127E8(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(dword_FFD828).w
                move.l  #word_1A274,(dword_FFD81C).w
                move.l  #word_1A292,(dword_FFD820).w
                move.l  #word_1A286,(dword_FFD824).w
                rts

off_12728:      dc.l byte_1A196
                dc.l byte_1A198
                dc.l byte_1A19A
                dc.l byte_1A19C
                dc.l byte_1A19E
                dc.l byte_1A1A0
off_12740:      dc.l word_1A2D6
                dc.l word_1A2E6
                dc.l word_1A2F6
                dc.l word_1A306
                dc.l word_1A316
                dc.l word_1A326
off_12758:      dc.l word_1A1A2
                dc.l word_1A1B2
                dc.l word_1A1C2
                dc.l word_1A1D2
                dc.l word_1A1E2
                dc.l word_1A1F2
off_12770:      dc.l word_1A202
                dc.l word_1A212
                dc.l word_1A222
                dc.l word_1A232
                dc.l word_1A242
                dc.l word_1A252
off_12788:      dc.l word_1A29A
                dc.l word_1A2A6
                dc.l word_1A2B2
                dc.l word_1A2BE
                dc.l word_1A2CA
                dc.l word_1A29A
                dc.l word_1A2A6
                dc.l word_1A2B2
                dc.l word_1A29A
                dc.l word_1A2A6
                dc.l word_1A2B2
                dc.l word_1A29A
off_127B8:      dc.l word_1A336
                dc.l word_1A336
                dc.l word_1A374
                dc.l word_1A3D2
                dc.l word_1A44E
                dc.l word_1A410
off_127D0:      dc.l word_1A354
                dc.l word_1A354
                dc.l word_1A392
                dc.l word_1A3B2
                dc.l word_1A3F0
                dc.l word_1A42E
off_127E8:      dc.l word_1A4E8
                dc.l word_1A518
                dc.l word_1A548
                dc.l word_1A578
                dc.l word_1A5A8
                dc.l word_1A5D8
                dc.l word_1A608
                dc.l word_1A638
                dc.l word_1A668
                dc.l word_1A698
                dc.l word_1A6C8
                dc.l word_1A6F8
                dc.l word_1A728
                dc.l word_1A758
                dc.l word_1A788
sub_12824:
                moveq   #$30,d7
                bsr.w   sub_11764
                lsr.w   #2,d0
                lsl.w   #1,d0
                lea     off_12866(pc),a0
                moveq   #$FFFFFFFF,d1
                move.w  (a0,d0.w),d1
                movea.l d1,a0
                lea     (unk_FFF800).w,a1
                moveq   #7,d0

loc_12840:
                move.l  (a0)+,(a1)+
                dbf     d0,loc_12840
                moveq   #$F,d7
                bsr.w   sub_11774
                subq.w  #1,d0
                lsl.w   #1,d0
                lea     off_129FE(pc),a0
                lea     (unk_FFF858).w,a1
                moveq   #$FFFFFFFF,d1
                move.w  (a0,d0.w),d1
                movea.l d1,a0
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                rts

off_12866:      dc.w word_1287E-sub_10000
                dc.w word_1289E-sub_10000
                dc.w word_128BE-sub_10000
                dc.w word_128DE-sub_10000
                dc.w word_128FE-sub_10000
                dc.w word_1291E-sub_10000
                dc.w word_1293E-sub_10000
                dc.w word_1295E-sub_10000
                dc.w word_1297E-sub_10000
                dc.w word_1299E-sub_10000
                dc.w word_129BE-sub_10000
                dc.w word_129DE-sub_10000
word_1287E:     binclude "data/palettes/level-00.bin"
word_1289E:     binclude "data/palettes/level-01.bin"
word_128BE:     binclude "data/palettes/level-02.bin"
word_128DE:     binclude "data/palettes/level-03.bin"
word_128FE:     binclude "data/palettes/level-04.bin"
word_1291E:     binclude "data/palettes/level-05.bin"
word_1293E:     binclude "data/palettes/level-06.bin"
word_1295E:     binclude "data/palettes/level-07.bin"
word_1297E:     binclude "data/palettes/level-08.bin"
word_1299E:     binclude "data/palettes/level-09.bin"
word_129BE:     binclude "data/palettes/level-10.bin"
word_129DE:     binclude "data/palettes/level-11.bin"
off_129FE:      dc.w word_12A1C-sub_10000
                dc.w word_12A24-sub_10000
                dc.w word_12A2C-sub_10000
                dc.w word_12A34-sub_10000
                dc.w word_12A3C-sub_10000
                dc.w word_12A44-sub_10000
                dc.w word_12A4C-sub_10000
                dc.w word_12A54-sub_10000
                dc.w word_12A5C-sub_10000
                dc.w word_12A64-sub_10000
                dc.w word_12A6C-sub_10000
                dc.w word_12A74-sub_10000
                dc.w word_12A7C-sub_10000
                dc.w word_12A84-sub_10000
                dc.w word_12A8C-sub_10000
word_12A1C:     binclude "data/palettes/accent-00.bin"
word_12A24:     binclude "data/palettes/accent-01.bin"
word_12A2C:     binclude "data/palettes/accent-02.bin"
word_12A34:     binclude "data/palettes/accent-03.bin"
word_12A3C:     binclude "data/palettes/accent-04.bin"
word_12A44:     binclude "data/palettes/accent-05.bin"
word_12A4C:     binclude "data/palettes/accent-06.bin"
word_12A54:     binclude "data/palettes/accent-07.bin"
word_12A5C:     binclude "data/palettes/accent-08.bin"
word_12A64:     binclude "data/palettes/accent-09.bin"
word_12A6C:     binclude "data/palettes/accent-10.bin"
word_12A74:     binclude "data/palettes/accent-11.bin"
word_12A7C:     binclude "data/palettes/accent-12.bin"
word_12A84:     binclude "data/palettes/accent-13.bin"
word_12A8C:     binclude "data/palettes/accent-14.bin"
sub_12A94:
                jsr     sub_100D4
                lea     (word_16DE8).l,a5
                jsr     unk_FFFBBA
                bsr.s   sub_12ABA
                move.w  #$83,d0
                jsr     unk_FFFB66
                bsr.w   sub_12E00
                bsr.w   sub_12E2E
                jmp     unk_FFFB6C

sub_12ABA:
                clr.b   (byte_FFD883).w
                bsr.w   sub_1268E
                bsr.w   sub_12824
                move.w  #1,(dword_FFFFA8).w
                moveq   #$30,d7
                bsr.w   sub_11774
                subq.b  #1,d0
                lsl.w   #1,d0
                moveq   #$FFFFFFFF,d1
                lea     (off_1AD92).l,a0
                move.w  (a0,d0.w),d1
                movea.l d1,a6
                move.w  d0,-(sp)
                bsr.w   sub_11422
                move.w  (sp)+,d0
                moveq   #$FFFFFFFF,d1
                lea     off_15508(pc),a0
                move.w  (a0,d0.w),d1
                movea.l d1,a6
                move.w  d0,-(sp)
                bsr.w   sub_11608
                move.w  (sp)+,d0
                lsl.w   #2,d0
                lea     dword_15B94(pc),a0
                move.l  (a0,d0.w),(dword_FFD26E).w
                move.l  4(a0,d0.w),(dword_FFD272).w
                tst.b   (byte_FFD886).w
                beq.s   loc_12B20
                clr.b   (byte_FFD886).w
                bsr.w   sub_1172C

loc_12B20:
                bsr.w   sub_12DE4
                bsr.w   sub_11B60
                bsr.w   sub_12D1A
                bsr.w   sub_11700
                bsr.w   sub_11E06
                bsr.w   sub_11DC2
                bsr.w   sub_11DD4
                bsr.w   sub_11DE6
                bsr.w   sub_11D88
                rts

sub_12B46:
                move.w  (word_FFD2A0).w,d0
                andi.w  #$7FFC,d0
                jsr     loc_12B6A(pc,d0.w)
                btst    #7,(word_FFFF8E+1).w
                beq.s   loc_12B5E
                bsr.w   sub_12EF4

loc_12B5E:
                bsr.w   sub_12E90
                bsr.w   sub_10D52
                jmp     unk_FFFB6C

loc_12B6A:
                bra.w   sub_12B7E
                bra.w   sub_12B9A
                bra.w   sub_12BDC
                bra.w   sub_12C9A
                bra.w   sub_12CDA

sub_12B7E:
                cmpi.l  #$1C000,(dword_FFD296).w
                bgt.s   loc_12B8C
                addq.l  #7,(dword_FFD296).w

loc_12B8C:
                bsr.w   sub_12D84
                bsr.w   sub_111E2
                bsr.w   sub_116BE
                rts

sub_12B9A:
                bset    #7,(word_FFD2A0).w
                bne.s   loc_12BD2

loc_12BA2:
                tst.b   (byte_FFD2A4).w
                beq.s   loc_12BB2
                bsr.w   sub_10D52
                jsr     unk_FFFB6C
                bra.s   loc_12BA2

loc_12BB2:
                move.b  #$82,d0
                jsr     unk_FFFB66
                move.w  #$8000,(word_FFD884).w
                bsr.w   sub_11E96
                clr.w   (word_FFFF92).w
                lea     (word_FFC040).w,a0
                move.w  #4,word_FFC07C-word_FFC040(a0)

loc_12BD2:
                bsr.w   sub_111E2
                bsr.w   sub_12D42
                rts

sub_12BDC:
                bset    #7,(word_FFD2A0).w
                bne.s   loc_12C2E
                clr.w   (word_FFFF92).w
                moveq   #$30,d7
                bsr.w   sub_11774
                move.b  d0,d1
                moveq   #0,d0
                move.b  (word_FFD82C+1).w,d0
                addq.b  #5,d0
                moveq   #$30,d7
                bsr.w   loc_1176A
                lsr.w   #3,d0
                cmp.b   byte_12C7C(pc,d0.w),d1
                bne.s   loc_12C74
                tst.b   (byte_FFD88F).w
                bne.s   loc_12C70
                lsl.w   #2,d0
                move.l  dword_12C82(pc,d0.w),(dword_FFD262).w
                moveq   #$A,d1

loc_12C16:
                jsr     unk_FFFB6C
                dbf     d1,loc_12C16
                lea     (word_FFC040).w,a0
                move.w  #$54,(a0)
                move.b  #$E1,d0
                jsr     unk_FFFB66

loc_12C2E:
                lea     (word_FFFF92).w,a0
                cmpi.w  #8,(a0)
                bne.s   loc_12C6A
                clr.w   (a0)
                move.w  #$8000,(word_FFD884).w
                bsr.w   sub_1168A
                movem.l d0/a0,-(sp)
                move.b  #$98,d0
                bsr.w   sub_10D48
                movem.l (sp)+,d0/a0
                addq.b  #1,(byte_FFD88C).w
                cmpi.b  #$A,(byte_FFD88C).w
                bne.s   loc_12C6A
                clr.b   (byte_FFD88C).w
                clr.b   (byte_FFD88D).w
                bra.s   loc_12C74

loc_12C6A:
                bsr.w   sub_111E2
                rts

loc_12C70:
                clr.b   (byte_FFD88F).w

loc_12C74:
                move.w  #4,(word_FFD2A0).w
                rts

byte_12C7C:     dc.b 2, $A, $12, $1A, $22, $2A
dword_12C82:    dc.l $200000, $1000, $5000, $10000, $50000, $100000
sub_12C9A:
                moveq   #0,d0
                move.b  (word_FFD82C+1).w,d0
                addq.b  #5,d0
                moveq   #$30,d7
                bsr.w   loc_1176A
                lsr.w   #3,d0
                lsl.w   #1,d0
                move.w  (dword_FFD888).w,d1
                cmp.w   word_12CCE(pc,d0.w),d1
                bhi.s   loc_12CC0
                cmpi.b  #1,(byte_FFD88D).w
                bne.s   loc_12CC0
                bra.s   loc_12CC6

loc_12CC0:
                move.b  #1,(byte_FFD88F).w

loc_12CC6:
                move.w  #8,(word_FFD2A0).w
                rts

word_12CCE:     dc.w $25, $30, $35, $40, $45, $50
sub_12CDA:
                bset    #7,(word_FFD2A0).w
                bne.s   loc_12CFE
                moveq   #$1E,d1

loc_12CE4:
                jsr     unk_FFFB6C
                dbf     d1,loc_12CE4
                move.b  #$84,d0
                jsr     unk_FFFB66
                move.w  #$3C,(word_FFC000).w
                clr.b   (byte_FFD886).w

loc_12CFE:
                bsr.w   sub_111D4
                move.w  #$B4,d1

loc_12D06:
                jsr     unk_FFFB6C
                dbf     d1,loc_12D06
                bsr.w   sub_11784
                move.w  #$40,(word_FFFFC0).w
                rts

sub_12D1A:
                moveq   #0,d7
                moveq   #0,d6
                lea     (byte_FFD82E).w,a0
                move.b  (a0),d7
                move.b  1(a0),d6
                bsr.w   sub_11674
                move.w  d7,(word_FFD25E).w
                addi.w  #$17,d7
                move.w  d7,(word_FFD260).w
                addi.w  #$18,d6
                move.w  d6,(word_FFD25C).w
                rts

sub_12D42:
                move.w  (word_FFFF92).w,d0
                cmpi.w  #$FA,d0
                bhi.s   loc_12D56
                bsr.w   sub_11740
                bsr.w   sub_11E52
                rts

loc_12D56:
                addq.b  #1,(word_FFD82C+1).w
                bne.s   loc_12D60
                addq.b  #1,(word_FFD82C+1).w

loc_12D60:
                move.b  (word_FFD82C).w,d0
                moveq   #1,d1
                addi.b  #0,d0
                abcd    d1,d0
                move.b  d0,(word_FFD82C).w
                move.w  #$18,(word_FFFFC0).w
                cmpi.b  #$49,d0
                bne.s   locret_12D82
                move.w  #$30,(word_FFFFC0).w

locret_12D82:
                rts

sub_12D84:
                lea     (unk_FFC380).w,a0
                lea     (unk_FFC680).w,a1
                tst.w   (a0)
                bne.s   loc_12D98
                tst.w   (a1)
                bne.s   loc_12D98
                move.w  #$18,(a1)

loc_12D98:
                lea     (unk_FFC3C0).w,a0
                lea     (unk_FFC400).w,a1
                lea     (unk_FFC6C0).w,a2
                lea     (unk_FFC700).w,a3
                tst.w   (a0)
                bne.s   loc_12DBE
                tst.w   (a2)
                bne.s   loc_12DBE
                tst.w   (a3)
                bne.s   loc_12DBE
                move.w  #$18,(a2)
                move.b  #1,$16(a2)

loc_12DBE:
                cmpi.b  #$A,(word_FFD82C+1).w
                bcs.s   locret_12DE2
                tst.w   (a1)
                bne.s   locret_12DE2
                tst.w   (a3)
                bne.s   locret_12DE2
                tst.w   (a2)
                bne.s   locret_12DE2
                move.w  #$18,(a3)
                move.w  #4,$3C(a3)
                move.b  #2,$16(a3)

locret_12DE2:
                rts

sub_12DE4:
                lea     (unk_FFC480).w,a0
                moveq   #0,d1
                moveq   #7,d0

loc_12DEC:
                tst.w   (a0)
                beq.s   loc_12DF2
                addq.b  #1,d1

loc_12DF2:
                lea     $40(a0),a0
                dbf     d0,loc_12DEC
                move.b  d1,(byte_FFD883).w
                rts

sub_12E00:
                bsr.w   sub_111E2
                jsr     unk_FFFB6C
                moveq   #$3C,d2

loc_12E0A:
                bsr.w   sub_116BE
                jsr     unk_FFFB6C
                dbf     d2,loc_12E0A
                bsr.w   sub_11CAA
                move.w  #$C,(word_FFC440).w
                bsr.w   sub_111E2
                jsr     unk_FFFB6C
                bsr.w   sub_11CCA
                rts

sub_12E2E:
                move.w  #$136,d1
                move.l  #loc_14000,d2
                move.b  (word_FFD82C+1).w,d0
                cmpi.b  #$20,d0
                bls.s   loc_12E44
                moveq   #$20,d0

loc_12E44:
                subq.w  #5,d1
                addi.l  #$200,d2
                dbf     d0,loc_12E44
                move.w  d1,(word_FFD294).w
                move.l  d2,(dword_FFD27C).w
                move.l  #loc_14000,(dword_FFD296).w
                cmpi.b  #$30,(word_FFD82C+1).w
                bls.s   loc_12E70
                move.l  #$18000,(dword_FFD296).w

loc_12E70:
                moveq   #0,d1
                moveq   #$30,d7
                bsr.w   sub_11774
                subq.b  #1,d0
                lea     byte_15D28(pc),a0
                move.b  (a0,d0.w),d1
                lsl.w   #2,d1
                lea     dword_15D14(pc),a0
                move.l  (a0,d1.w),(dword_FFD276).w
                rts

sub_12E90:
                move.l  (dword_FFD87E).w,d0
                moveq   #0,d1
                moveq   #4,d7

loc_12E98:
                btst    d1,(byte_FFD887).w
                bne.s   loc_12EB2
                move.w  d1,d2
                lsl.w   #2,d2
                cmp.l   dword_12EE0(pc,d2.w),d0
                bcs.s   loc_12EB2
                bset    d1,(byte_FFD887).w
                bsr.w   sub_12EBA
                bra.s   locret_12EB8

loc_12EB2:
                addq.b  #1,d1
                dbf     d7,loc_12E98

locret_12EB8:
                rts

sub_12EBA:
                move.l  d0,-(sp)
                move.b  #1,(byte_FFD2A4).w
                move.b  #$97,d0
                jsr     unk_FFFB36
                move.b  d0,(byte_A01C09).l
                jsr     unk_FFFB3C
                move.l  (sp)+,d0
                addq.b  #1,(byte_FFD882).w
                bsr.w   sub_11D88
                rts

dword_12EE0:    dc.l $30000, $80000, $160000, $240000, $320000
sub_12EF4:
                jsr     unk_FFFB36
                move.b  #1,(byte_A01C10).l
                jsr     unk_FFFB3C
                move.w  #$58,(word_FFC000).w

loc_12F0A:
                bsr.w   sub_111D4
                jsr     unk_FFFB6C
                btst    #7,(word_FFFF8E+1).w
                beq.s   loc_12F0A
                jsr     unk_FFFB36
                move.b  #$80,(byte_A01C10).l
                jsr     unk_FFFB3C
                clr.w   (word_FFC000).w
                rts

sub_12F30:
                bsr.w   sub_100D4
                move.w  #$8F02,(VDP_CTRL).l
                lea     (word_16DE8).l,a5
                jsr     unk_FFFBBA
                move.w  #$2C,(word_FFF82E).w
                bsr.w   sub_113AC
                bsr.w   sub_1268E
                bsr.w   sub_12824
                move.b  #1,(byte_FFD24E).w
                move.b  #$14,(byte_FFD883).w
                bsr.w   sub_1194C
                bsr.w   sub_11976
                lea     (unk_FFCAA0).w,a0
                moveq   #$1F,d0

loc_12F72:
                move.b  #1,(a0)+
                dbf     d0,loc_12F72
                lea     (VDP_DATA).l,a0
                move.l  #$65400003,(VDP_CTRL).l
                moveq   #$1F,d0

loc_12F8C:
                move.w  #$220D,(a0)
                dbf     d0,loc_12F8C
                lea     byte_12FCC(pc),a6
                bsr.w   sub_10FAA
                lea     byte_12FD4(pc),a6
                bsr.w   sub_10FAA
                bsr.w   sub_1303C
                bsr.w   sub_11E06
                bsr.w   sub_11DC2
                bsr.w   sub_11DD4
                bsr.w   sub_11DE6
                bsr.w   sub_11D88
                move.b  #$81,d0
                jsr     unk_FFFB66
                jsr     unk_FFFB6C
                jmp     unk_FFFB6C

byte_12FCC:     dc.b $C0, $D4
aBonus:         dc.b "BONUS",0
byte_12FD4:     dc.b $C0, $E0
aRound_0:       dc.b "ROUND",0
sub_12FDC:
                move.w  (word_FFD2A6).w,d0
                andi.w  #$7FFC,d0
                jsr     loc_13000(pc,d0.w)
                btst    #7,(word_FFFF8E+1).w
                beq.s   loc_12FF4
                bsr.w   sub_12EF4

loc_12FF4:
                bsr.w   sub_12E90
                bsr.w   sub_10D52
                jmp     unk_FFFB6C

loc_13000:
                bra.w   sub_13008
                bra.w   sub_1300E

sub_13008:
                bsr.w   sub_111E2
                rts

sub_1300E:
                bset    #7,(word_FFD2A6).w
                bne.s   loc_13032

loc_13016:
                tst.b   (byte_FFD2A4).w
                beq.s   loc_13026
                bsr.w   sub_10D52
                jsr     unk_FFFB6C
                bra.s   loc_13016

loc_13026:
                move.b  #$82,d0
                jsr     unk_FFFB66
                bsr.w   sub_1691C

loc_13032:
                bsr.w   sub_111E2
                bsr.w   sub_130D4
                rts

sub_1303C:
                lea     (unk_FFC580).w,a0
                move.w  #$C,(a0)
                move.w  #$D11,$3E(a0)
                move.w  #$2C,(word_FFC040).w
                lea     (unk_FFC640).w,a0
                move.w  #$30,(a0)
                lea     $40(a0),a0
                move.w  #$30,(a0)
                move.b  #1,$16(a0)
                lea     (unk_FFC5C0).w,a0
                move.w  #$34,(a0)
                lea     $40(a0),a0
                move.w  #$34,(a0)
                move.b  #1,$16(a0)
                lea     (unk_FFC080).w,a0
                moveq   #0,d1
                moveq   #$13,d0

loc_13084:
                move.w  #$38,(a0)
                move.b  d1,$38(a0)
                btst    #2,d1
                beq.s   loc_13098
                move.b  #1,$39(a0)

loc_13098:
                lea     $40(a0),a0
                addq.b  #1,d1
                dbf     d0,loc_13084
                moveq   #0,d0
                move.b  (word_FFD82C+1).w,d0
                moveq   #$30,d7
                bsr.w   sub_11764
                subq.b  #3,d0
                lsr.w   #2,d0
                lsl.w   #2,d0
                lea     off_169F4(pc),a0
                move.l  (a0,d0.w),(dword_FFD282).w
                lea     off_16A9C(pc),a0
                move.l  (a0,d0.w),(dword_FFD286).w
                lea     off_16C34(pc),a0
                move.l  (a0,d0.w),(dword_FFD28A).w
                rts

sub_130D4:
                move.b  #1,(byte_FFD27B).w
                move.w  (word_FFFF92).w,d0
                cmpi.w  #$FA,d0
                bhi.s   loc_130EE
                bsr.w   sub_11740
                bsr.w   sub_11F6C
                rts

loc_130EE:
                addq.b  #1,(word_FFD82C+1).w
                bne.s   loc_130F8
                addq.b  #1,(word_FFD82C+1).w

loc_130F8:
                move.b  (word_FFD82C).w,d0
                moveq   #1,d1
                addi.b  #0,d0
                abcd    d1,d0
                move.b  d0,(word_FFD82C).w
                move.w  #$18,(word_FFFFC0).w
                rts

sub_13110:
                jsr     sub_100D4
                clr.b   (byte_FFD88E).w
                bsr.w   loc_10126
                lea     (word_16DE8).l,a5
                jsr     unk_FFFBBA
                move.w  #$800,(word_FFF7E0).w
                bsr.w   sub_13566
                move    #$2700,sr
                moveq   #2,d2
                move.w  #$3BA,d0
                move.w  #$125B,d1
                lea     (word_135E8).l,a0
                jsr     unk_FFFB54
                move    #$2500,sr
                move.b  #$81,d0
                jsr     unk_FFFB66
                clr.w   (word_FFFF92).w
                jsr     unk_FFFB6C
                jmp     unk_FFFB6C

sub_13162:
                move.w  (word_FFD29E).w,d0
                andi.w  #$7FFC,d0
                jsr     loc_13176(pc,d0.w)
                bsr.w   sub_111E2
                jmp     unk_FFFB6C

loc_13176:
                bra.w   sub_13182
                bra.w   sub_1321A
                bra.w   sub_13492

sub_13182:
                bsr.w   sub_131D6
                cmpi.w  #$C8,(word_FFFF92).w
                bne.s   locret_131D4
                move.w  #4,(word_FFD29E).w
                move.w  #$8100,(word_FFD884).w
                move.w  #$EEE,(word_FFF7E6).w
                bsr.w   sub_131DA
                move.l  #$EFFFFFFF,(dword_FFFFB8).w
                move.l  #$FFFFFFFF,(dword_FFFFBC).w
                bsr.w   sub_11784
                lea     (VDP_DATA).l,a0
                move.l  #$40000003,(VDP_CTRL).l
                move.w  #$3FF,d0

loc_131CC:
                move.w  #0,(a0)
                dbf     d0,loc_131CC

locret_131D4:
                rts

sub_131D6:
                bsr.w   sub_11740

sub_131DA:
                lea     byte_131EC(pc),a6
                bsr.w   sub_10FAA
                lea     byte_13200(pc),a6
                bsr.w   sub_10FAA
                rts

byte_131EC:     dc.b $C2, $90
aCongratulation:dc.b "CONGRATULATIONS!",0
                dc.b 0
byte_13200:     dc.b $C3, $8A
aYouAreASuperPl:dc.b "YOU ARE A SUPER PLAYER.",0
sub_1321A:
                bset    #7,(word_FFD29E).w
                bne.s   loc_1325A
                lea     (word_16DE8).l,a5
                jsr     unk_FFFBBA
                move.w  #$EEE,(word_FFF7E6).w
                clr.l   (dword_FFFFB8).w
                clr.l   (dword_FFFFBC).w
                move.w  #$4000,(dword_FFD008+2).w
                lea     (word_FFC000).w,a0
                moveq   #0,d1
                moveq   #4,d0

loc_13248:
                move.w  #$50,(a0)
                move.w  d1,$38(a0)
                lea     $40(a0),a0
                addq.w  #1,d1
                dbf     d0,loc_13248

loc_1325A:
                bsr.w   sub_1130C
                addq.b  #1,(byte_FFD29D).w
                cmpi.b  #$20,(byte_FFD29D).w
                bne.s   locret_1328C
                clr.b   (byte_FFD29D).w
                bsr.w   sub_1328E
                addq.b  #1,(byte_FFD29C).w
                cmpi.b  #$5D,(byte_FFD29C).w
                bne.s   locret_1328C
                move.w  #8,(word_FFD29E).w
                lea     (word_FFC000).w,a0
                move.w  #$44,(a0)

locret_1328C:
                rts

sub_1328E:
                moveq   #0,d0
                moveq   #0,d5
                move.w  (dword_FFFFA4).w,d0
                andi.w  #$FF,d0
                lsr.w   #3,d0
                subq.w  #2,d0
                bpl.s   loc_132A4
                addi.w  #$20,d0

loc_132A4:
                lsl.w   #6,d0
                addi.w  #-$3FF8,d0
                move.w  d0,d5
                move.w  d5,d6
                bsr.w   sub_10F2E
                move.l  d5,(VDP_CTRL).l
                moveq   #$1F,d1

loc_132BA:
                move.w  #0,(VDP_DATA).l
                dbf     d1,loc_132BA
                moveq   #0,d1
                move.b  (byte_FFD29C).w,d1
                lsl.w   #1,d1
                moveq   #$FFFFFFFF,d2
                lea     off_132E0(pc),a6 ; "     STAFF"
                move.w  (a6,d1.w),d2
                movea.l d2,a6
                bsr.w   loc_10FAE
                rts

off_132E0:      dc.w aStaff-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w aDirector-sub_10000  
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w aKFuzzy-sub_10000    
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w aDesigner-sub_10000  
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w aYumi-sub_10000      
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w aProgrammer-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w aOSamu-sub_10000     
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w aSoundDesign-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w aTSMusic-sub_10000   
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w aAnd-sub_10000       
                dc.w byte_1339C-sub_10000
                dc.w aSpecialThanks-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w aLee-sub_10000       
                dc.w byte_1339C-sub_10000
                dc.w aBo-sub_10000        
                dc.w byte_1339C-sub_10000
                dc.w aArcadeFlickySt-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w aTestPlayers-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w aChallengeTheNe-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
                dc.w byte_1339C-sub_10000
byte_1339C:     dc.b 0, 0
aStaff:         dc.b "     STAFF",0
                dc.b 0
aDirector:      dc.b "    DIRECTOR",0
                dc.b 0
aKFuzzy:        dc.b "     K.FUZZY",0
                dc.b 0
aDesigner:      dc.b "    DESIGNER",0
                dc.b 0
aYumi:          dc.b "     YUMI",0
aProgrammer:    dc.b "    PROGRAMMER",0
                dc.b 0
aOSamu:         dc.b "     O.SAMU",0
aSoundDesign:   dc.b "    SOUND DESIGN",0
                dc.b 0
aTSMusic:       dc.b "     T@S MUSIC",0
                dc.b 0
aAnd:           dc.b "      AND",0
aSpecialThanks: dc.b "    SPECIAL THANKS",0
                dc.b 0
aArcadeFlickySt:dc.b "     ARCADE FLICKY STAFF",0
                dc.b 0
aTestPlayers:   dc.b "     TEST PLAYERS",0
aLee:           dc.b "     LEE",0
                dc.b 0
aBo:            dc.b "     BO",0
aChallengeTheNe:dc.b "CHALLENGE THE NEXT STAGE.",0
sub_13492:
                btst    #7,(word_FFFF8E+1).w
                beq.s   locret_134BA
                bsr.w   sub_11784
                move.b  #1,(byte_FFD88E).w
                bsr.w   loc_10126
                move.w  #$18,(word_FFFFC0).w
                move    #$2700,sr
                bsr.w   sub_10CF6
                move    #$2500,sr

locret_134BA:
                rts

sub_134BC:
                bset    #7,(a0)
                bne.s   loc_134E2
                bset    #1,2(a0)
                move.w  $38(a0),d0
                move.b  word_13516(pc,d0.w),$3A(a0)
                lsl.w   #1,d0
                move.w  word_1350C(pc,d0.w),6(a0)
                lsl.w   #1,d0
                move.l  off_134F8(pc,d0.w),8(a0)

loc_134E2:
                move.w  $3C(a0),d0
                andi.w  #$7FFC,d0
                jsr     loc_134F0(pc,d0.w)
                rts

loc_134F0:
                bra.w   sub_1351C
                bra.w   sub_1352E

off_134F8:      dc.l off_144AC
                dc.l off_14E12
                dc.l off_14E22
                dc.l off_154AE
                dc.l off_162BC
word_1350C:     dc.w 4, 0, 0, 8, $10
word_13516:     dc.w $D17, $212B, $3D00
sub_1351C:
                move.b  (byte_FFD29C).w,d0
                cmp.b   $3A(a0),d0
                bne.s   locret_1352C
                move.w  #4,$3C(a0)

locret_1352C:
                rts

sub_1352E:
                bset    #7,$3C(a0)
                bne.s   loc_13550
                move.w  #$E4,$30(a0)
                move.w  #$178,$24(a0)
                move.l  #$FFFFC000,$2C(a0)
                bclr    #1,2(a0)

loc_13550:
                bsr.w   sub_1105C
                cmpi.w  #$78,$24(a0)
                bgt.s   loc_13560
                bsr.w   sub_110F0

loc_13560:
                bsr.w   sub_11126
                rts

sub_13566:
                moveq   #9,d0
                moveq   #0,d1

loc_1356A:
                moveq   #0,d5
                movem.l d0-d1,-(sp)
                lsl.w   #1,d1
                move.w  word_135D4(pc,d1.w),d5
                moveq   #$FFFFFFFF,d2
                move.w  off_13598(pc,d1.w),d2
                movea.l d2,a6
                lsl.w   #1,d1
                move.w  byte_135AC(pc,d1.w),d7
                move.w  byte_135AC+2(pc,d1.w),d6
                bsr.w   sub_10F6E
                movem.l (sp)+,d0-d1
                addq.w  #1,d1
                dbf     d0,loc_1356A
                rts

off_13598:      dc.w word_1A354-sub_10000
                dc.w word_1A336-sub_10000
                dc.w word_1A374-sub_10000
                dc.w word_1A374-sub_10000
                dc.w word_1A374-sub_10000
                dc.w word_1A374-sub_10000
                dc.w word_1A374-sub_10000
                dc.w word_1A374-sub_10000
                dc.w word_1A354-sub_10000
                dc.w word_1A336-sub_10000
byte_135AC:     dc.b 0, 3, 0, 3, 0, 4, 0, 2, 0, 4
                dc.b 0, 2, 0, 4, 0, 2, 0, 4, 0, 2
                dc.b 0, 4, 0, 2, 0, 4, 0, 2, 0, 4
                dc.b 0, 2, 0, 3, 0, 3, 0, 4, 0, 2
word_135D4:     dc.w $E132, $E4B2, $E642, $E64C, $E656, $E660, $E66A, $E674, $E446, $E146
word_135E8:     binclude "data/other/data_EndingMusic81Overlay.bin"
sub_139A2:
                jsr     sub_100D4
                lea     (word_16DE8).l,a5
                jsr     unk_FFFBBA
                move.w  (word_FFD890).w,d0
                andi.w  #3,d0
                move.b  byte_13A08(pc,d0.w),(word_FFD82C+1).w
                move.b  byte_13A0C(pc,d0.w),(word_FFD82C).w
                lsl.w   #1,d0
                move.w  off_13A10(pc,d0.w),(word_FFD2AA).w
                moveq   #$FFFFFFFF,d1
                move.w  (word_FFD2AA).w,d1
                movea.l d1,a0
                move.b  (a0),(byte_FFD2A8).w
                move.b  1(a0),(byte_FFD2AC).w
                addq.w  #1,(word_FFD890).w
                bsr.w   sub_12ABA
                clr.l   (dword_FFD888).w
                clr.b   (byte_FFD88D).w
                move.b  #1,(byte_FFD2A5).w
                move.w  #$44,(word_FFC000).w
                bsr.w   sub_12E00
                bsr.w   sub_12E2E
                jmp     unk_FFFB6C

byte_13A08:     dc.b 1, $A, $14, $18
byte_13A0C:     dc.b 1, $10, $20, $24
off_13A10:      dc.w word_13A82-sub_10000
                dc.w word_13B82-sub_10000
                dc.w word_13C52-sub_10000
                dc.w word_13D70-sub_10000
sub_13A18:
                btst    #7,(word_FFFF8E+1).w
                beq.s   loc_13A2A
                bsr.w   sub_11784
                move.w  #0,(word_FFFFC0).w

loc_13A2A:
                bsr.w   sub_13A5E
                cmpi.l  #$1C000,(dword_FFD296).w
                bgt.s   loc_13A3C
                addq.l  #7,(dword_FFD296).w

loc_13A3C:
                bsr.w   sub_12D84
                bsr.w   sub_111E2
                bsr.w   sub_116BE
                bclr    #0,(byte_FFD886).w
                beq.s   loc_13A5A
                bsr.w   sub_11784
                move.w  #$40,(word_FFFFC0).w

loc_13A5A:
                jmp     unk_FFFB6C

sub_13A5E:
                moveq   #$FFFFFFFF,d0
                move.w  (word_FFD2AA).w,d0
                movea.l d0,a0
                move.b  (a0),(word_FFFF8E).w
                subq.b  #1,(byte_FFD2AC).w
                bne.s   locret_13A80
                addq.l  #2,a0
                move.b  (a0),(byte_FFD2A8).w
                move.b  1(a0),(byte_FFD2AC).w
                move.w  a0,(word_FFD2AA).w

locret_13A80:
                rts

word_13A82:     dc.w $12, $801, $A15, $4A12, $4201, $4402, $40E, $1C
                dc.w $400A, $A, $40D, $C, $404, $50E, $405, 2
                dc.w $A14, $801, $27, $801, $A16, $40D, $1B, $801
                dc.w $A0B, $4A06, $4201, $440A, $411, $22, $801, $A07
                dc.w $801, $29, $406, $F, $4018, $F, $40B, $440D
                dc.w $401, 8, $A0D, $801, 6, $42E, $440B, $401
                dc.w $2A, $A0C, $D, $418, $33, $42A, $4406, $4004
                dc.w $A13, $801, $3F, $801, $A0B, $803, $A01, $201
                dc.w $409, $6B, $A02, $4A08, $A25, $4A04, $4201, $4001
                dc.w $4417, $4003, $A, $40F, $4409, $415, $D, $A1B
                dc.w $801, 8, $801, $4A0C, $A27, $202, $40E, $25
                dc.w $4009, $4403, $4504, $4403, $1C, $801, $A07, $4A07
                dc.w $A03, $201, $401, $510, $402, $E, $801, $A13
                dc.w $4A06, $A02, $201, $415, 7, $801, $A38, $201
                dc.w $43C, $4407, $416, $23, $A2C, $601, $40A, $38
                dc.w 0, 0, 0, 0, 0, 0, 0, 0
word_13B82:     dc.w $12, $801, $A09, $4A11, $A17, $14, $4004, $4A0B
                dc.w $A5A, $1C, $A0C, 9, $403, $502, $409, $1E
                dc.w $407, 3, $801, $A0F, $602, $40D, $4405, $400B
                dc.w $23, $408, 9, $40E, $441F, $D, $410, $440F
                dc.w $41C, $17, $A1B, $802, $46, $410, $2B, $40E
                dc.w $400C, $1F, $A0B, $4A12, $A35, $4A17, $4802, $4001
                dc.w 3, $410, $21, $404, $507, $4508, $4403, $4008
                dc.w $4801, $4A0D, $A05, $B, $40A, 7, $408, $33
                dc.w $420, 3, $A12, $A, $40A, $501, 1, $A10
                dc.w $201, $17, $A17, $801, 4, $802, $A07, $4A0D
                dc.w $4201, $4407, $4502, $4403, $4001, $19, $801, $A07
                dc.w $201, $406, $4405, $4003, 8, $A1E, $10, $A13
                dc.w $801, $1A, $414, $1F, $403, $504, $40C, $43
word_13C52:     dc.w $42C, $240C, $408, $A0E, $C, $41B, $2409, $2001
                dc.w $803, $A18, $802, $F, $515, $250B, $522, $401
                dc.w 8, $813, $12, $409, $A, $200B, 8, $80C
                dc.w $12, $814, 7, $409, $510, $402, $C, $808
                dc.w $20, $812, $A, $403, $509, $403, $1C, $816
                dc.w $1A, $80E, $A, $40A, $26, $200C, 4, $403
                dc.w $508, $403, $C, $80C, $14, $402, $522, $403
                dc.w $601, $202, $A0D, $801, $11, $403, $505, $402
                dc.w 8, $80C, $1F, $860, 9, $403, $504, $402
                dc.w $1E, $2001, $2809, $813, $901, $50F, 2, $803
                dc.w $2A13, $A01, $803, $A, $200C, 8, $82C, 9
                dc.w $409, 1, $200F, $38, $2001, $240D, $2501, $2401
                dc.w $2001, $21, $200F, $1F, $200A, $2803, $818, $1E
                dc.w $818, $2805, $2001, $2508, $506, $1A, $2005, $2402
                dc.w $200C, $D, $516, $101, $903, $801, $C, $508
                dc.w $101, $82E, $901, $101, $2509, $2002, $E, $40E
                dc.w $59, $51E, $101, $902, $808, $901, $F, $412
                dc.w $10, $426, $24, 0, 0, 0, 0
word_13D70:     dc.w $13, $A48, $202, 1, $401, $4407, $4008, $2E
                dc.w $40E, $4403, $4006, $4A03, $A11, $801, $1C, $40A
                dc.w 2, $4008, $14, $A09, $11, $40C, $440D, $407
                dc.w $4F, $41B, $A, $404, $4503, $4404, $4004, 1
                dc.w $409, $15, $A08, 8, $4013, $1E, $407, 5
                dc.w $A0A, $201, 1, $400E, $40B, $16, $410, $D
                dc.w $A0B, $17, $A11, $48, $203, $A2C, $202, $601
                dc.w $409, 2, $4023, 8, $40F, $4406, $4003, $4201
                dc.w $4A07, $4201, $13, $201, $A05, $201, $F, $202
                dc.w 3, $4009, $4206, $4003, $F, $40A, $D, $A36
                dc.w $4A13, $4202, $601, $40A, $12, $405, $4407, $4002
                dc.w 7, $A16, 5, $40A, $B, $205, 3, $404
                dc.w $10, $401B, $23, $A0E, $201, 2, $201, $A0B
                dc.w $4A03, $4005, $B, $A06, $201, $B, $408, $14
                dc.w $400E, $A1A, $15, $403, $514, $408, $4A, $4006
                dc.w $34, $410, $10, $A08, $801, $39, 0, 0
sub_13E70:
                bset    #7,(a0)
                bne.s   loc_13EA0
                move.l  #off_144AC,8(a0)
                move.b  $3E(a0),d7
                move.b  $3F(a0),d6
                bsr.w   sub_11674
                addi.w  #$C,d7
                addi.w  #$18,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)
                move.b  #3,$3A(a0)

loc_13EA0:
                tst.b   (byte_FFD27B).w
                bne.s   locret_13EDC
                tst.b   (byte_FFD24F).w
                bne.s   loc_13EB6
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     loc_13EDE(pc,d0.w)

loc_13EB6:
                move.w  $3C(a0),d0
                andi.w  #$7C,d0
                cmpi.w  #4,d0
                bcc.s   loc_13ECE
                tst.b   (byte_FFD24F).w
                bne.s   loc_13ECE
                bsr.w   sub_14476

loc_13ECE:
                bsr.w   sub_14272
                tst.b   (byte_FFD24E).w
                bne.s   locret_13EDC
                bsr.w   sub_11C3C

locret_13EDC:
                rts

loc_13EDE:
                bra.w   sub_13EEA
                bra.w   sub_1438C
                bra.w   sub_143FC

sub_13EEA:
                move.b  #$1E,5(a0)
                bsr.s   sub_13F26
                bsr.w   sub_142D6
                tst.b   (byte_FFD24F).w
                bne.s   loc_13F00
                bsr.w   sub_1130C

loc_13F00:
                bsr.w   sub_1105C
                bsr.w   sub_1407E
                bsr.w   sub_14128
                bsr.w   sub_14318
                move.l  $34(a0),d0
                beq.s   locret_13F24
                move.b  #1,$39(a0)
                tst.l   d0
                bmi.s   locret_13F24
                clr.b   $39(a0)

locret_13F24:
                rts

sub_13F26:
                move.b  (word_FFFF8E).w,d0
                andi.b  #$C,d0
                beq.w   loc_13FAA
                btst    #3,d0
                bne.w   loc_13FCE
                btst    #2,d0
                bne.w   loc_13FEC

loc_13F42:
                move.l  $30(a0),d2
                move.l  d1,$34(a0)
                tst.b   (byte_FFD24E).w
                bne.s   loc_13F54
                move.l  d1,(dword_FFD004).w

loc_13F54:
                bsr.w   sub_14038
                tst.b   $38(a0)
                bne.w   loc_1400A
                btst    #0,$3A(a0)
                beq.s   loc_13F98
                move.b  (word_FFFF8E).w,d0
                andi.b  #$70,d0
                beq.s   loc_13F98
                move.l  a0,-(sp)
                move.b  #$91,d0
                bsr.w   sub_10D48
                movea.l (sp)+,a0
                move.b  #1,$38(a0)
                move.l  #$FFFD7000,$2C(a0)
                bclr    #0,$3A(a0)
                bclr    #1,$3A(a0)

loc_13F98:
                move.b  (word_FFFF8E).w,d0
                andi.b  #$70,d0
                bne.s   locret_13FA8
                move.b  #3,$3A(a0)

locret_13FA8:
                rts

loc_13FAA:
                move.l  $34(a0),d1
                tst.b   $38(a0)
                bne.s   loc_13F42
                tst.l   d1
                beq.s   loc_13FCA
                tst.l   d1
                bmi.s   loc_13FC4
                subi.l  #$600,d1
                bra.s   loc_13FCA

loc_13FC4:
                addi.l  #$600,d1

loc_13FCA:
                bra.w   loc_13F42

loc_13FCE:
                move.l  $34(a0),d1
                cmpi.l  #$18000,d1
                bge.s   loc_13FE2
                addi.l  #$1800,d1
                bra.s   loc_13FE8

loc_13FE2:
                move.l  #$18000,d1

loc_13FE8:
                bra.w   loc_13F42

loc_13FEC:
                move.l  $34(a0),d1
                cmpi.l  #$FFFE8000,d1
                ble.s   loc_14000
                subi.l  #$1800,d1
                bra.s   loc_14006

loc_14000:
                move.l  #$FFFE8000,d1

loc_14006:
                bra.w   loc_13F42

loc_1400A:
                cmpi.l  #$30000,$2C(a0)
                bge.s   loc_1401C
                addi.l  #$1000,$2C(a0)

loc_1401C:
                move.b  (word_FFFF8E).w,d0
                andi.b  #$70,d0
                bne.s   locret_1402C
                move.b  #3,$3A(a0)

locret_1402C:
                rts

sub_1402E:
                clr.b   $38(a0)
                clr.l   $2C(a0)
                rts

sub_14038:
                btst    #1,$3A(a0)
                beq.s   locret_1407C
                move.b  (word_FFFF8E).w,d0
                andi.b  #$70,d0
                beq.s   locret_1407C
                tst.b   $3B(a0)
                beq.s   locret_1407C
                movea.l (dword_FFD250).w,a1
                move.w  #4,$34(a1)
                tst.b   $39(a0)
                beq.s   loc_14066
                move.w  #$FFFC,$34(a1)

loc_14066:
                move.w  #8,$3C(a1)
                move.l  $30(a0),$30(a1)
                clr.b   $3B(a0)
                bclr    #1,$3A(a0)

locret_1407C:
                rts

sub_1407E:
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                tst.b   $38(a0)
                bne.s   loc_1409E
                addq.w  #1,d6
                bsr.w   sub_1157C
                tst.b   d4
                bne.s   locret_1409C
                move.b  #1,$38(a0)

locret_1409C:
                rts

loc_1409E:
                tst.l   $34(a0)
                bne.s   loc_140DA
                tst.l   $2C(a0)
                bpl.s   loc_140BC
                subi.w  #$E,d6
                bsr.w   sub_1157C
                tst.b   d4
                beq.s   locret_140BA
                clr.l   $2C(a0)

locret_140BA:
                rts

loc_140BC:
                bsr.w   sub_1157C
                tst.b   d4
                beq.s   locret_140D8
                clr.b   $38(a0)
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)

locret_140D8:
                rts

loc_140DA:
                tst.l   $2C(a0)
                bpl.s   loc_140FE
                subi.w  #$E,d6
                addq.w  #4,d7
                bsr.w   sub_1157C
                tst.b   d4
                bne.s   loc_140F8
                subq.w  #8,d7
                bsr.w   sub_1157C
                tst.b   d4
                beq.s   locret_140FC

loc_140F8:
                clr.l   $2C(a0)

locret_140FC:
                rts

loc_140FE:
                subq.w  #4,d7
                bsr.w   sub_1157C
                tst.b   d4
                bne.s   loc_14112
                addq.w  #8,d7
                bsr.w   sub_1157C
                tst.b   d4
                beq.s   locret_14126

loc_14112:
                clr.b   $38(a0)
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)

locret_14126:
                rts

sub_14128:
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                move.l  $34(a0),d5
                tst.b   $38(a0)
                bne.s   loc_1419A
                subi.w  #$A,d6
                tst.l   d5
                beq.s   locret_1416E
                tst.l   d5
                bpl.s   loc_14170
                subq.w  #6,d7
                bsr.w   sub_1157C
                tst.b   d4
                beq.s   locret_1416E
                move.l  $34(a0),d0
                subi.l  #$3000,d0
                cmpi.l  #$FFFE0200,d0
                bge.s   loc_14168
                move.l  #$FFFE0200,d0

loc_14168:
                neg.l   d0
                move.l  d0,$34(a0)

locret_1416E:
                rts

loc_14170:
                addq.w  #6,d7
                bsr.w   sub_1157C
                tst.b   d4
                beq.s   locret_14198
                move.l  $34(a0),d0
                addi.l  #$3000,d0
                cmpi.l  #$1FE00,d0
                ble.s   loc_14192
                move.l  #$1FE00,d0

loc_14192:
                neg.l   d0
                move.l  d0,$34(a0)

locret_14198:
                rts

loc_1419A:
                subq.w  #8,d6
                tst.l   d5
                beq.w   loc_14248
                tst.l   d5
                bpl.s   loc_141DC
                subq.w  #6,d7
                bsr.w   sub_1157C
                tst.b   d4
                beq.s   locret_141DA
                btst    #1,d4
                bne.s   loc_141BC
                btst    #0,d4
                beq.s   loc_14212

loc_141BC:
                move.l  $34(a0),d0
                subi.l  #$3000,d0
                cmpi.l  #$FFFE0200,d0
                bge.s   loc_141D4
                move.l  #$FFFE0200,d0

loc_141D4:
                neg.l   d0
                move.l  d0,$34(a0)

locret_141DA:
                rts

loc_141DC:
                addq.w  #6,d7
                bsr.w   sub_1157C
                tst.b   d4
                beq.s   locret_14210
                btst    #1,d4
                bne.s   loc_141F2
                btst    #0,d4
                beq.s   loc_14212

loc_141F2:
                move.l  $34(a0),d0
                addi.l  #$3000,d0
                cmpi.l  #$1FE00,d0
                ble.s   loc_1420A
                move.l  #$1FE00,d0

loc_1420A:
                neg.l   d0
                move.l  d0,$34(a0)

locret_14210:
                rts

loc_14212:
                tst.l   $2C(a0)
                bpl.s   loc_14232
                move.w  d6,d0
                andi.w  #7,d0
                cmpi.w  #3,d0
                blt.s   locret_14230
                addi.w  #$10,d6
                move.w  d6,$24(a0)
                clr.l   $2C(a0)

locret_14230:
                rts

loc_14232:
                andi.w  #$FFF8,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                clr.l   $2C(a0)
                clr.b   $38(a0)
                rts

loc_14248:
                addq.w  #6,d7
                bsr.w   sub_1157C
                tst.b   d4
                beq.s   loc_1425C
                move.l  #$FFFF4000,$34(a0)
                bra.s   locret_14270

loc_1425C:
                subi.w  #$C,d7
                bsr.w   sub_1157C
                tst.b   d4
                beq.s   locret_14270
                move.l  #$C000,$34(a0)

locret_14270:
                rts

sub_14272:
                lea     (unk_FFD206).w,a2
                lea     (unk_FFD1FE).w,a1
                lea     (unk_FFD20A).w,a4
                lea     (unk_FFD202).w,a3
                moveq   #$3F,d0

loc_14284:
                move.l  (a1),(a2)
                move.l  (a3),(a4)
                subq.l  #8,a1
                subq.l  #8,a2
                subq.l  #8,a3
                subq.l  #8,a4
                dbf     d0,loc_14284
                lea     (byte_FFD24E).w,a2
                lea     (unk_FFD24D).w,a1
                moveq   #$3F,d0

loc_1429E:
                move.b  -(a1),-(a2)
                dbf     d0,loc_1429E
                move.l  $30(a0),(dword_FFD00E).w
                move.l  $24(a0),(dword_FFD012).w
                moveq   #0,d0
                tst.b   $38(a0)
                beq.s   loc_142BC
                bset    #7,d0

loc_142BC:
                move.l  $34(a0),d7
                beq.s   loc_142D0
                tst.l   d7
                bpl.s   loc_142CC
                bset    #1,d0
                bra.s   loc_142D0

loc_142CC:
                bset    #0,d0

loc_142D0:
                move.b  d0,(byte_FFD20E).w
                rts

sub_142D6:
                tst.b   (byte_FFD27A).w
                beq.s   locret_14316
                tst.b   $38(a0)
                bne.s   locret_14316
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                cmp.w   (word_FFD25C).w,d6
                bne.s   locret_14316
                cmp.w   (word_FFD25E).w,d7
                blt.s   locret_14316
                cmp.w   (word_FFD260).w,d7
                bgt.s   locret_14316
                move.b  #1,(byte_FFD24F).w
                clr.l   $34(a0)
                clr.l   (dword_FFD004).w
                addq.b  #1,(byte_FFD88D).w
                move.l  a0,-(sp)
                bsr.w   sub_11CE6
                movea.l (sp)+,a0

locret_14316:
                rts

sub_14318:
                bclr    #7,2(a0)
                move.l  $34(a0),d0
                move.b  (word_FFFF8E).w,d1
                tst.b   $38(a0)
                bne.s   loc_14366
                tst.l   d0
                beq.s   loc_1435C
                tst.l   d0
                bpl.s   loc_14342
                bset    #7,2(a0)
                btst    #2,d1
                bne.s   loc_14352
                bra.s   loc_14348

loc_14342:
                btst    #3,d1
                bne.s   loc_14352

loc_14348:
                move.l  #word_1A8A0,$C(a0)
                rts

loc_14352:
                clr.w   6(a0)
                bsr.w   sub_11126
                rts

loc_1435C:
                move.l  #word_1A898,$C(a0)
                rts

loc_14366:
                tst.l   d0
                beq.s   loc_14380
                move.w  #8,6(a0)
                tst.l   d0
                bpl.s   loc_1437A
                bset    #7,2(a0)

loc_1437A:
                bsr.w   sub_11126
                rts

loc_14380:
                move.w  #4,6(a0)
                bsr.w   sub_11126
                rts

sub_1438C:
                bset    #7,$3C(a0)
                bne.s   loc_143AE
                move.l  a0,-(sp)
                move.b  #$87,d0
                jsr     unk_FFFB66
                movea.l (sp)+,a0
                clr.b   5(a0)
                clr.l   $34(a0)
                move.w  #$C,6(a0)

loc_143AE:
                addi.l  #$1000,$2C(a0)
                bsr.w   sub_1105C
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   sub_1157C
                tst.b   d4
                bne.s   loc_143E4
                tst.l   $2C(a0)
                bpl.s   loc_143DE
                subq.w  #8,d6
                bsr.w   sub_1157C
                tst.b   d4
                beq.s   loc_143DE
                clr.l   $2C(a0)

loc_143DE:
                bsr.w   sub_11126
                rts

loc_143E4:
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)
                move.w  #8,$3C(a0)
                rts

sub_143FC:
                bset    #7,$3C(a0)
                bne.s   loc_14418
                clr.b   5(a0)
                clr.b   $10(a0)
                bclr    #2,2(a0)
                move.b  #3,$39(a0)

loc_14418:
                bsr.w   sub_1105C
                bsr.w   sub_11126
                bclr    #2,2(a0)
                beq.s   loc_14430
                subq.b  #1,$39(a0)
                bsr.w   sub_14464

loc_14430:
                tst.b   $39(a0)
                bne.s   locret_14462
                subq.b  #1,(byte_FFD882).w
                beq.s   loc_1445C
                move.b  #1,(byte_FFD886).w
                bsr.w   sub_11722
                move.w  #$20,(word_FFFFC0).w
                moveq   #$3C,d2

loc_1444E:
                bsr.w   sub_116BE
                jsr     unk_FFFB6C
                dbf     d2,loc_1444E
                bra.s   locret_14462

loc_1445C:
                move.w  #$10,(word_FFD2A0).w

locret_14462:
                rts

sub_14464:
                lea     (unk_FFC380).w,a1
                moveq   #2,d0

loc_1446A:
                clr.w   (a1)
                lea     $40(a1),a1
                dbf     d0,loc_1446A
                rts

sub_14476:
                lea     (unk_FFC380).w,a1
                moveq   #2,d1

loc_1447C:
                btst    #0,5(a1)
                beq.s   loc_144A2
                movem.w d1,-(sp)
                bsr.w   sub_117C0
                movem.w (sp)+,d1
                tst.b   d0
                beq.s   loc_144A2
                move.w  #4,$3C(a0)
                move.b  #1,(byte_FFD26D).w
                bra.s   locret_144AA

loc_144A2:
                lea     $40(a1),a1
                dbf     d1,loc_1447C

locret_144AA:
                rts

off_144AC:      dc.l byte_144BC
                dc.l byte_144C2
                dc.l byte_144C8
                dc.l byte_144CE
byte_144BC:     dc.b 2, 2
                dc.w byte_1A8A8-sub_10000
                dc.w byte_1A8B0-sub_10000
byte_144C2:     dc.b 2, 2
                dc.w byte_1A8B8-sub_10000
                dc.w byte_1A8C0-sub_10000
byte_144C8:     dc.b 2, 2
                dc.w byte_1A8C8-sub_10000
                dc.w word_1A8D0-sub_10000
byte_144CE:     dc.b 6, 3
                dc.w word_1A878-sub_10000
                dc.w word_1A880-sub_10000
                dc.w byte_1A888-sub_10000
                dc.w word_1A890-sub_10000
                dc.w byte_1A888-sub_10000
                dc.w word_1A890-sub_10000
sub_144DC:
                bset    #7,(a0)
                bne.s   loc_14504
                move.b  (byte_FFD834).w,d7
                move.b  (byte_FFD835).w,d6
                bsr.w   sub_11674
                addq.w  #8,d7
                addi.w  #$18,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)
                move.l  #off_14524,8(a0)

loc_14504:
                move.w  $3C(a0),d0
                andi.w  #$7FFC,d0
                jsr     loc_14516(pc,d0.w)
                bsr.w   sub_1105C
                rts

loc_14516:
                bra.w   sub_1451E
                bra.w   nullsub_3

sub_1451E:
                bsr.w   sub_11126

nullsub_3:
                rts

off_14524:      dc.l byte_14528
byte_14528:     dc.b 2, 8
                dc.w word_1AD82-sub_10000
                dc.w word_1AD8A-sub_10000
sub_1452E:
                bset    #7,(a0)
                bne.s   loc_1455E
                move.l  (dword_FFD828).w,d0
                move.l  d0,$C(a0)
                move.b  #$60,$13(a0)
                moveq   #0,d7
                moveq   #0,d6
                move.b  $3E(a0),d7
                move.b  $3F(a0),d6
                bsr.w   sub_11674
                addq.w  #8,d7
                addq.w  #8,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)

loc_1455E:
                tst.b   (byte_FFD27B).w
                bne.s   locret_1457A
                tst.b   (byte_FFD24F).w
                bne.s   locret_1457A
                tst.b   (byte_FFD26D).w
                bne.s   locret_1457A
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     loc_1457C(pc,d0.w)

locret_1457A:
                rts

loc_1457C:
                bra.w   sub_14588
                bra.w   sub_145BC
                bra.w   sub_14610

sub_14588:
                move.b  #1,5(a0)
                lea     (word_FFC440).w,a1
                tst.l   dword_FFC46C-word_FFC440(a1)
                bmi.s   loc_145B6
                bsr.w   sub_117C0
                tst.b   d0
                beq.s   loc_145B6
                tst.b   $3B(a1)
                bne.s   loc_145B6
                move.w  #4,$3C(a0)
                move.b  #1,$3B(a1)
                move.l  a0,(dword_FFD250).w

loc_145B6:
                bsr.w   sub_1105C
                rts

sub_145BC:
                bset    #7,$3C(a0)
                bne.s   loc_145D0
                move.l  a0,-(sp)
                move.b  #$92,d0
                bsr.w   sub_10D48
                movea.l (sp)+,a0

loc_145D0:
                clr.b   5(a0)
                lea     (word_FFC440).w,a1
                move.l  dword_FFC470-word_FFC440(a1),d7
                move.l  $24(a1),d6
                tst.b   $38(a1)
                beq.s   loc_145EE
                addi.l  #$60000,d6
                bra.s   loc_14602

loc_145EE:
                tst.b   $39(a1)
                bne.s   loc_145FC
                addi.l  #$80000,d7
                bra.s   loc_14602

loc_145FC:
                subi.l  #$80000,d7

loc_14602:
                move.l  d7,$30(a0)
                move.l  d6,$24(a0)
                bsr.w   sub_1105C
                rts

sub_14610:
                bset    #7,$3C(a0)
                bne.s   loc_14650
                move.l  a0,-(sp)
                move.b  #$96,d0
                bsr.w   sub_10D48
                movea.l (sp)+,a0
                move.b  #$18,5(a0)
                move.l  #off_14730,8(a0)
                clr.b   $3B(a0)
                moveq   #0,d0
                move.b  (word_FFD82C+1).w,d0

loc_1463C:
                cmpi.b  #$F,d0
                bls.s   loc_14648
                subi.b  #$F,d0
                bra.s   loc_1463C

loc_14648:
                subq.b  #1,d0
                lsl.w   #2,d0
                move.w  d0,6(a0)

loc_14650:
                bsr.w   sub_14688
                tst.l   $34(a0)
                bne.s   loc_1465C
                clr.w   (a0)

loc_1465C:
                bsr.w   sub_14662
                rts

sub_14662:
                move.w  $20(a0),d7
                move.w  d7,d6
                lea     (word_FFC440).w,a1
                move.w  word_FFC460-word_FFC440(a1),d5
                move.w  d5,d4
                sub.w   d7,d5
                cmpi.w  #$7C,d5
                bge.s   loc_14684
                sub.w   d4,d6
                cmpi.w  #$7C,d6
                bge.s   loc_14684
                bra.s   locret_14686

loc_14684:
                clr.w   (a0)

locret_14686:
                rts

sub_14688:
                move.l  $34(a0),d7
                move.l  $2C(a0),d6
                bclr    #7,2(a0)
                tst.l   d7
                bpl.s   loc_146A0
                bset    #7,2(a0)

loc_146A0:
                bsr.w   sub_11126
                tst.b   $38(a0)
                bne.s   loc_146BE
                tst.l   d7
                bpl.s   loc_146B6
                addi.l  #$800,d7
                bra.s   loc_146BC

loc_146B6:
                subi.l  #$800,d7

loc_146BC:
                bra.s   loc_146C4

loc_146BE:
                addi.l  #$1000,d6

loc_146C4:
                move.l  d7,$34(a0)
                move.l  d6,$2C(a0)
                bsr.w   sub_1105C
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                addq.w  #1,d6
                bsr.w   sub_1157C
                tst.b   d4
                beq.s   loc_146FA
                clr.l   $2C(a0)
                clr.b   $38(a0)
                move.w  d6,d5
                andi.w  #$FFF8,d5
                move.w  d5,$24(a0)
                clr.w   $26(a0)
                bra.s   loc_14700

loc_146FA:
                move.b  #1,$38(a0)

loc_14700:
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subq.w  #4,d6
                tst.l   $34(a0)
                bpl.s   loc_14720
                subq.w  #4,d7
                bsr.w   sub_1157C
                tst.b   d4
                beq.s   locret_1471E
                neg.l   $34(a0)

locret_1471E:
                rts

loc_14720:
                addq.w  #4,d7
                bsr.w   sub_1157C
                tst.b   d4
                beq.s   locret_1472E
                neg.l   $34(a0)

locret_1472E:
                rts

off_14730:      dc.l byte_1476C
                dc.l byte_1477A
                dc.l byte_14788
                dc.l byte_14796
                dc.l byte_147A4
                dc.l byte_147B2
                dc.l byte_147C0
                dc.l byte_147CE
                dc.l byte_147DC
                dc.l byte_147EA
                dc.l byte_147F8
                dc.l byte_14806
                dc.l byte_14814
                dc.l byte_14822
                dc.l byte_14830
byte_1476C:     dc.b 6, 1
                dc.w word_1A4E8-sub_10000
                dc.w word_1A4F8-sub_10000
                dc.w word_1A508-sub_10000
                dc.w word_1A4F0-sub_10000
                dc.w word_1A510-sub_10000
                dc.w word_1A500-sub_10000
byte_1477A:     dc.b 6, 1
                dc.w word_1A518-sub_10000
                dc.w word_1A528-sub_10000
                dc.w word_1A538-sub_10000
                dc.w word_1A520-sub_10000
                dc.w word_1A540-sub_10000
                dc.w word_1A530-sub_10000
byte_14788:     dc.b 6, 1
                dc.w word_1A548-sub_10000
                dc.w word_1A558-sub_10000
                dc.w word_1A568-sub_10000
                dc.w word_1A550-sub_10000
                dc.w word_1A570-sub_10000
                dc.w word_1A560-sub_10000
byte_14796:     dc.b 6, 1
                dc.w word_1A578-sub_10000
                dc.w word_1A588-sub_10000
                dc.w word_1A598-sub_10000
                dc.w word_1A580-sub_10000
                dc.w word_1A5A0-sub_10000
                dc.w word_1A590-sub_10000
byte_147A4:     dc.b 6, 1
                dc.w word_1A5A8-sub_10000
                dc.w word_1A5B8-sub_10000
                dc.w word_1A5C8-sub_10000
                dc.w word_1A5B0-sub_10000
                dc.w word_1A5D0-sub_10000
                dc.w word_1A5C0-sub_10000
byte_147B2:     dc.b 6, 1
                dc.w word_1A5D8-sub_10000
                dc.w word_1A5E8-sub_10000
                dc.w word_1A5F8-sub_10000
                dc.w word_1A5E0-sub_10000
                dc.w word_1A600-sub_10000
                dc.w word_1A5F0-sub_10000
byte_147C0:     dc.b 6, 1
                dc.w word_1A608-sub_10000
                dc.w word_1A618-sub_10000
                dc.w word_1A628-sub_10000
                dc.w word_1A610-sub_10000
                dc.w word_1A630-sub_10000
                dc.w word_1A620-sub_10000
byte_147CE:     dc.b 6, 1
                dc.w word_1A638-sub_10000
                dc.w word_1A648-sub_10000
                dc.w word_1A658-sub_10000
                dc.w word_1A640-sub_10000
                dc.w word_1A660-sub_10000
                dc.w word_1A650-sub_10000
byte_147DC:     dc.b 6, 1
                dc.w word_1A668-sub_10000
                dc.w word_1A678-sub_10000
                dc.w word_1A688-sub_10000
                dc.w word_1A670-sub_10000
                dc.w word_1A690-sub_10000
                dc.w word_1A680-sub_10000
byte_147EA:     dc.b 6, 1
                dc.w word_1A698-sub_10000
                dc.w word_1A6A8-sub_10000
                dc.w word_1A6B8-sub_10000
                dc.w word_1A6A0-sub_10000
                dc.w word_1A6C0-sub_10000
                dc.w word_1A6B0-sub_10000
byte_147F8:     dc.b 6, 1
                dc.w word_1A6C8-sub_10000
                dc.w word_1A6D8-sub_10000
                dc.w word_1A6E8-sub_10000
                dc.w word_1A6D0-sub_10000
                dc.w word_1A6F0-sub_10000
                dc.w word_1A6E0-sub_10000
byte_14806:     dc.b 6, 1
                dc.w word_1A6F8-sub_10000
                dc.w word_1A708-sub_10000
                dc.w word_1A718-sub_10000
                dc.w word_1A700-sub_10000
                dc.w word_1A720-sub_10000
                dc.w word_1A710-sub_10000
byte_14814:     dc.b 6, 1
                dc.w word_1A728-sub_10000
                dc.w word_1A738-sub_10000
                dc.w word_1A748-sub_10000
                dc.w word_1A730-sub_10000
                dc.w word_1A750-sub_10000
                dc.w word_1A740-sub_10000
byte_14822:     dc.b 6, 1
                dc.w word_1A758-sub_10000
                dc.w word_1A768-sub_10000
                dc.w word_1A778-sub_10000
                dc.w word_1A760-sub_10000
                dc.w word_1A780-sub_10000
                dc.w word_1A770-sub_10000
byte_14830:     dc.b 6, 1
                dc.w word_1A788-sub_10000
                dc.w word_1A798-sub_10000
                dc.w word_1A7A8-sub_10000
                dc.w word_1A790-sub_10000
                dc.w word_1A7B0-sub_10000
                dc.w word_1A7A0-sub_10000
sub_1483E:
                bset    #7,(a0)
                bne.s   loc_14874
                move.l  #off_14E12,8(a0)
                tst.b   $3A(a0)
                beq.s   loc_1485A
                move.l  #off_14E22,8(a0)

loc_1485A:
                move.b  $3E(a0),d7
                move.b  $3F(a0),d6
                bsr.w   sub_11674
                addq.w  #8,d7
                addi.w  #$10,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)

loc_14874:
                tst.b   (byte_FFD27B).w
                bne.s   locret_14898
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     loc_1489A(pc,d0.w)
                move.l  $34(a0),d0
                beq.s   locret_14898
                move.b  #1,$39(a0)
                tst.l   d0
                bmi.s   locret_14898
                clr.b   $39(a0)

locret_14898:
                rts

loc_1489A:
                bra.w   sub_148AA
                bra.w   sub_14918
                bra.w   sub_14B42
                bra.w   sub_14D86

sub_148AA:
                tst.b   (byte_FFD24F).w
                bne.s   locret_14916
                bset    #7,$3C(a0)
                bne.s   loc_148C6
                move.b  #$30,$3B(a0)
                move.l  #$FFFFE000,$2C(a0)

loc_148C6:
                clr.w   6(a0)
                subq.b  #1,$3B(a0)
                bne.s   loc_148DA
                neg.l   $2C(a0)
                move.b  #$30,$3B(a0)

loc_148DA:
                lea     (word_FFC440).w,a1
                bsr.w   sub_117C0
                tst.b   d0
                beq.s   loc_1490E
                move.l  a0,-(sp)
                move.b  #$90,d0
                bsr.w   sub_10D48
                movea.l (sp)+,a0
                move.w  #4,$3C(a0)
                addq.b  #1,(byte_FFD27A).w
                move.b  (byte_FFD27A).w,$38(a0)
                move.l  #$10,(dword_FFD262).w
                bsr.w   sub_1168A

loc_1490E:
                bsr.w   sub_11126
                bsr.w   sub_1105C

locret_14916:
                rts

sub_14918:
                bset    #7,$3C(a0)
                bne.s   loc_14928
                clr.l   $34(a0)
                clr.l   $2C(a0)

loc_14928:
                tst.b   (byte_FFD26D).w
                beq.s   loc_14940
                clr.b   $38(a0)
                subq.b  #1,(byte_FFD27A).w
                move.w  #8,$3C(a0)
                bra.w   loc_14A12

loc_14940:
                moveq   #0,d0
                move.b  $38(a0),d0
                lsl.w   #1,d0
                moveq   #$FFFFFFFF,d1
                lea     byte_14A58(pc),a1
                move.w  (a1,d0.w),d1
                movea.l d1,a1
                move.l  (a1),$30(a0)
                move.l  4(a1),$24(a0)
                bsr.w   sub_110BA
                lea     byte_14A6A(pc),a1
                move.w  (a1,d0.w),d1
                movea.l d1,a1
                moveq   #0,d1
                move.b  (a1),d1
                move.w  d1,-(sp)
                tst.b   (byte_FFD24F).w
                bne.s   loc_1497C
                bsr.w   sub_14AF0

loc_1497C:
                move.w  (sp)+,d1
                tst.b   (byte_FFD24F).w
                beq.s   loc_149F2
                lea     (word_FFC440).w,a1
                move.w  dword_FFC470-word_FFC440(a1),d7
                move.w  $24(a1),d6
                cmp.w   $30(a0),d7
                bne.s   loc_149F2
                cmp.w   $24(a0),d6
                bne.s   loc_149F2
                move.l  a0,-(sp)
                move.b  #$94,d0
                bsr.w   sub_10D48
                movea.l (sp)+,a0
                clr.w   (a0)
                bsr.w   sub_14A7C
                subq.b  #1,(byte_FFD883).w
                bne.s   loc_149CE
                move.b  #1,(byte_FFD281).w
                clr.w   (word_FFFF92).w
                move.b  (dword_FFD888).w,(byte_FFD266).w
                move.b  (dword_FFD888+1).w,(byte_FFD267).w
                bsr.w   sub_14DD4

loc_149CE:
                move.l  a0,-(sp)
                moveq   #2,d1

loc_149D2:
                jsr     unk_FFFB6C
                dbf     d1,loc_149D2
                movea.l (sp)+,a0
                clr.b   $38(a0)
                subq.b  #1,(byte_FFD27A).w
                bne.s   loc_149F2
                clr.b   (byte_FFD24F).w
                move.l  a0,-(sp)
                bsr.w   sub_11D18
                movea.l (sp)+,a0

loc_149F2:
                tst.b   (byte_FFD281).w
                beq.s   loc_14A12
                move.b  #1,(byte_FFD24F).w
                move.w  #$C,(word_FFD2A0).w
                cmpi.b  #1,(byte_FFD88D).w
                beq.s   loc_14A12
                move.b  #1,(byte_FFD88F).w

loc_14A12:
                bclr    #7,2(a0)
                clr.b   $39(a0)
                move.b  d1,d0
                andi.b  #3,d0
                bne.s   loc_14A2A
                clr.w   6(a0)
                bra.s   loc_14A4E

loc_14A2A:
                btst    #0,d1
                bne.s   loc_14A3C
                bset    #7,2(a0)
                move.b  #1,$39(a0)

loc_14A3C:
                tst.b   d1
                bmi.s   loc_14A48
                move.w  #8,6(a0)
                bra.s   loc_14A4E

loc_14A48:
                move.w  #4,6(a0)

loc_14A4E:
                bsr.w   sub_11126
                bsr.w   sub_110BA
                rts

byte_14A58:     dc.b 0, 0
                dc.w $D036, $D05E, $D086, $D0AE, $D0D6, $D0FE, $D126, $D14E
byte_14A6A:     dc.b 0, 0
                dc.w $D213, $D218, $D21D, $D222, $D227, $D22C, $D231, $D236
sub_14A7C:
                moveq   #0,d0
                move.b  $38(a0),d0
                subq.b  #1,d0
                lsl.w   #2,d0
                move.l  dword_14AC0(pc,d0.w),d0
                move.l  d0,(dword_FFD262).w
                bsr.w   sub_1168A
                moveq   #0,d0
                move.b  $38(a0),d0
                move.b  d0,d1
                subq.b  #1,d0
                lsl.w   #1,d0
                moveq   #$FFFFFFFF,d2
                lea     word_14AE0(pc),a2
                move.w  (a2,d0.w),d2
                movea.l d2,a2
                move.w  #$20,(a2)
                move.b  d1,$3A(a2)
                lea     (word_FFC440).w,a1
                move.w  dword_FFC470-word_FFC440(a1),d7
                move.w  d7,$30(a2)
                rts

dword_14AC0:    dc.l $100
                dc.l $200
                dc.l $300
                dc.l $400
                dc.l $500
                dc.l $1000
                dc.l $2000
                dc.l $5000
word_14AE0:     dc.w $C100, $C140, $C180, $C1C0, $C100, $C140, $C180, $C1C0
sub_14AF0:
                lea     (unk_FFC380).w,a1
                moveq   #1,d0

loc_14AF6:
                move.w  d0,-(sp)
                btst    #1,5(a1)
                beq.s   loc_14B30
                bsr.w   sub_117C0
                tst.b   d0
                beq.s   loc_14B30
                move.b  $38(a0),d0
                lea     (unk_FFC480).w,a2
                moveq   #7,d1

loc_14B12:
                cmp.b   $38(a2),d0
                bhi.s   loc_14B26
                clr.b   $38(a2)
                subq.b  #1,(byte_FFD27A).w
                move.w  #8,$3C(a2)

loc_14B26:
                lea     $40(a2),a2
                dbf     d1,loc_14B12
                bra.s   loc_14B3C

loc_14B30:
                lea     $40(a1),a1
                move.w  (sp)+,d0
                dbf     d0,loc_14AF6
                rts

loc_14B3C:
                move.w  (sp)+,d0
                rts

nullsub_4:
                rts

sub_14B42:
                tst.b   $3A(a0)
                bne.w   sub_14C6A
                bset    #7,$3C(a0)
                bne.s   loc_14B76
                moveq   #0,d0
                move.w  a0,d0
                subi.w  #$C480,d0
                lsr.w   #4,d0
                lea     dword_14C4A(pc),a1
                move.l  (a1,d0.w),$34(a0)
                tst.b   $39(a0)
                beq.s   loc_14B70
                neg.l   $34(a0)

loc_14B70:
                move.w  #8,6(a0)

loc_14B76:
                bsr.w   sub_1105C
                tst.l   $2C(a0)
                bne.w   loc_14BF8
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                addq.w  #1,d6
                bsr.w   sub_1157C
                tst.b   d4
                bne.s   loc_14BA4
                addi.l  #$1000,$2C(a0)
                move.w  #4,6(a0)
                bra.s   loc_14BF6

loc_14BA4:
                move.l  $34(a0),d0
                beq.s   loc_14BBA
                tst.b   $39(a0)
                bne.s   loc_14BC6
                subi.l  #$400,$34(a0)
                bra.s   sub_14BDC

loc_14BBA:
                clr.l   $34(a0)
                move.w  #$C,$3C(a0)
                bra.s   loc_14BF6

loc_14BC6:
                addi.l  #$400,$34(a0)
                bra.s   sub_14BDC

sub_14BD0:
                clr.l   $34(a0)
                move.w  #$C,$3C(a0)
                bra.s   loc_14BF6

sub_14BDC:
                subq.w  #6,d6
                moveq   #4,d0
                tst.l   $34(a0)
                bpl.s   loc_14BE8
                neg.w   d0

loc_14BE8:
                add.w   d0,d7
                bsr.w   sub_1157C
                tst.b   d4
                beq.s   loc_14BF6
                neg.l   $34(a0)

loc_14BF6:
                bra.s   loc_14C2E

loc_14BF8:
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   sub_1157C
                tst.b   d4
                beq.s   loc_14C20
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)
                move.w  #8,6(a0)
                bra.s   loc_14C2E

loc_14C20:
                addi.l  #$1000,$2C(a0)
                move.w  #4,6(a0)

loc_14C2E:
                bclr    #7,2(a0)
                tst.l   $34(a0)
                bpl.s   loc_14C40
                bset    #7,2(a0)

loc_14C40:
                bsr.w   sub_11126
                bsr.w   sub_14D52
                rts

dword_14C4A:    dc.l $A000
                dc.l $C000
                dc.l $E000
                dc.l $10000
                dc.l $12000
                dc.l $14000
                dc.l $16000
                dc.l $18000
sub_14C6A:
                bset    #7,$3C(a0)
                bne.s   loc_14C96
                moveq   #0,d0
                move.w  a0,d0
                subi.w  #$C480,d0
                lsr.w   #4,d0
                lea     dword_14D32(pc),a1
                move.l  (a1,d0.w),$34(a0)
                tst.b   $39(a0)
                beq.s   loc_14C90
                neg.l   $34(a0)

loc_14C90:
                move.w  #8,6(a0)

loc_14C96:
                bsr.w   sub_1105C
                tst.l   $2C(a0)
                bne.w   loc_14CE0
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                addq.w  #1,d6
                bsr.w   sub_1157C
                tst.b   d4
                bne.s   loc_14CC4
                addi.l  #$1000,$2C(a0)
                move.w  #4,6(a0)
                bra.s   loc_14CDE

loc_14CC4:
                subq.w  #6,d6
                moveq   #4,d0
                tst.l   $34(a0)
                bpl.s   loc_14CD0
                neg.w   d0

loc_14CD0:
                add.w   d0,d7
                bsr.w   sub_1157C
                tst.b   d4
                beq.s   loc_14CDE
                neg.l   $34(a0)

loc_14CDE:
                bra.s   loc_14D16

loc_14CE0:
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   sub_1157C
                tst.b   d4
                beq.s   loc_14D08
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)
                move.w  #8,6(a0)
                bra.s   loc_14D16

loc_14D08:
                addi.l  #$1000,$2C(a0)
                move.w  #4,6(a0)

loc_14D16:
                bclr    #7,2(a0)
                tst.l   $34(a0)
                bpl.s   loc_14D28
                bset    #7,2(a0)

loc_14D28:
                bsr.w   sub_11126
                bsr.w   sub_14D52
                rts

dword_14D32:    dc.l $C000
                dc.l $D000
                dc.l $E000
                dc.l $F000
                dc.l $10000
                dc.l $11000
                dc.l $12000
                dc.l $13000
sub_14D52:
                lea     (word_FFC440).w,a1
                move.w  word_FFC47C-word_FFC440(a1),d0
                andi.w  #$7C,d0
                bne.s   locret_14D84
                bsr.w   sub_117C0
                tst.b   d0
                beq.s   locret_14D84
                move.l  a0,-(sp)
                move.b  #$90,d0
                bsr.w   sub_10D48
                movea.l (sp)+,a0
                move.w  #4,$3C(a0)
                addq.b  #1,(byte_FFD27A).w
                move.b  (byte_FFD27A).w,$38(a0)

locret_14D84:
                rts

sub_14D86:
                bsr.w   sub_1105C
                bset    #7,$3C(a0)
                bne.s   loc_14DA2
                bclr    #2,2(a0)
                move.w  #$C,6(a0)
                clr.b   $10(a0)

loc_14DA2:
                bsr.w   sub_1105C
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   loc_14DB8
                bset    #7,2(a0)

loc_14DB8:
                bsr.w   sub_11126
                bclr    #2,2(a0)
                beq.s   loc_14DD0
                bchg    #0,$39(a0)
                move.w  #8,$3C(a0)

loc_14DD0:
                bsr.s   sub_14D52
                rts

sub_14DD4:
                clr.l   (dword_FFD268).w
                tst.b   (byte_FFD266).w
                bne.s   locret_14DF8
                moveq   #0,d0
                move.b  (byte_FFD267).w,d0
                lsr.w   #4,d0
                lsl.w   #2,d0
                move.l  dword_14DFA(pc,d0.w),d0
                move.l  d0,(dword_FFD268).w
                move.l  d0,(dword_FFD262).w
                bsr.w   sub_1168A

locret_14DF8:
                rts

dword_14DFA:    dc.l $20000
                dc.l $20000
                dc.l $10000
                dc.l $5000
                dc.l $3000
                dc.l $1000
off_14E12:      dc.l byte_14E32
                dc.l byte_14E96
                dc.l byte_14EA2
                dc.l byte_14EB2
off_14E22:      dc.l byte_14E64
                dc.l byte_14E9C
                dc.l byte_14EAA
                dc.l byte_14EBC
byte_14E32:     dc.b $18, 4
                dc.w word_1A7B8-sub_10000
                dc.w word_1A7C0-sub_10000
                dc.w word_1A7B8-sub_10000
                dc.w word_1A7C0-sub_10000
                dc.w word_1A7B8-sub_10000
                dc.w word_1A7C0-sub_10000
                dc.w word_1A7B8-sub_10000
                dc.w word_1A7C0-sub_10000
                dc.w word_1A7B8-sub_10000
                dc.w word_1A7C0-sub_10000
                dc.w word_1A7B8-sub_10000
                dc.w word_1A7C0-sub_10000
                dc.w word_1A7C8-sub_10000
                dc.w word_1A7D0-sub_10000
                dc.w word_1A7C8-sub_10000
                dc.w word_1A7D0-sub_10000
                dc.w word_1A7C8-sub_10000
                dc.w word_1A7D0-sub_10000
                dc.w word_1A7C8-sub_10000
                dc.w word_1A7D0-sub_10000
                dc.w word_1A7C8-sub_10000
                dc.w word_1A7D0-sub_10000
                dc.w word_1A7C8-sub_10000
                dc.w word_1A7D0-sub_10000
byte_14E64:     dc.b $18, 4
                dc.w word_1A818-sub_10000
                dc.w word_1A820-sub_10000
                dc.w word_1A818-sub_10000
                dc.w word_1A820-sub_10000
                dc.w word_1A818-sub_10000
                dc.w word_1A820-sub_10000
                dc.w word_1A818-sub_10000
                dc.w word_1A820-sub_10000
                dc.w word_1A818-sub_10000
                dc.w word_1A820-sub_10000
                dc.w word_1A818-sub_10000
                dc.w word_1A820-sub_10000
                dc.w word_1A828-sub_10000
                dc.w word_1A830-sub_10000
                dc.w word_1A828-sub_10000
                dc.w word_1A830-sub_10000
                dc.w word_1A828-sub_10000
                dc.w word_1A830-sub_10000
                dc.w word_1A828-sub_10000
                dc.w word_1A830-sub_10000
                dc.w word_1A828-sub_10000
                dc.w word_1A830-sub_10000
                dc.w word_1A828-sub_10000
                dc.w word_1A830-sub_10000
byte_14E96:     dc.b 2, 3
                dc.w word_1A7D8-sub_10000
                dc.w word_1A7E0-sub_10000
byte_14E9C:     dc.b 2, 3
                dc.w word_1A838-sub_10000
                dc.w word_1A840-sub_10000
byte_14EA2:     dc.b 3, 4
                dc.w word_1A7E8-sub_10000
                dc.w word_1A7F0-sub_10000
                dc.w word_1A7F8-sub_10000
byte_14EAA:     dc.b 3, 4
                dc.w word_1A848-sub_10000
                dc.w word_1A850-sub_10000
                dc.w word_1A858-sub_10000
byte_14EB2:     dc.b 4, $A
                dc.w word_1A800-sub_10000
                dc.w word_1A800-sub_10000
                dc.w word_1A808-sub_10000
                dc.w word_1A810-sub_10000
byte_14EBC:     dc.b 4, $A
                dc.w word_1A860-sub_10000
                dc.w word_1A860-sub_10000
                dc.w word_1A868-sub_10000
                dc.w word_1A870-sub_10000
sub_14EC6:
                bset    #7,(a0)
                bne.s   loc_14EFA
                moveq   #0,d7
                moveq   #0,d6
                move.b  $3E(a0),d7
                move.b  $3F(a0),d6
                bsr.w   sub_11674
                addq.w  #8,d7
                addi.w  #$10,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)
                move.l  #off_154AE,8(a0)
                clr.l   $34(a0)
                clr.l   $2C(a0)

loc_14EFA:
                tst.b   (byte_FFD27B).w
                bne.s   loc_14F2E
                tst.b   (byte_FFD24F).w
                bne.s   loc_14F2E
                tst.b   (byte_FFD26D).w
                bne.s   loc_14F2E
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     loc_14F44(pc,d0.w)
                move.w  $3C(a0),d0
                andi.w  #$7FFC,d0
                cmpi.w  #$14,d0
                beq.s   loc_14F2E
                cmpi.w  #$1C,d0
                beq.s   loc_14F2E
                bsr.w   sub_1540A

loc_14F2E:
                move.l  $34(a0),d0
                beq.s   locret_14F42
                move.b  #1,$39(a0)
                tst.l   d0
                bmi.s   locret_14F42
                clr.b   $39(a0)

locret_14F42:
                rts

loc_14F44:
                bra.w   sub_14F64
                bra.w   sub_14FD2
                bra.w   sub_15068
                bra.w   sub_1515A
                bra.w   sub_15256
                bra.w   sub_152B4
                bra.w   sub_152F6
                bra.w   sub_153A4

sub_14F64:
                bset    #7,$3C(a0)
                bne.s   loc_14F80
                clr.w   6(a0)
                bclr    #2,2(a0)
                clr.b   $10(a0)
                move.b  #6,5(a0)

loc_14F80:
                bsr.w   sub_1105C
                bsr.w   sub_11126
                bclr    #2,2(a0)
                beq.s   locret_14FD0
                move.w  #8,$3C(a0)
                lea     (word_FFC440).w,a1
                move.w  $20(a0),d7
                move.w  $20(a1),d6
                clr.b   $39(a0)
                cmp.w   d7,d6
                bgt.s   loc_14FB0
                move.b  #1,$39(a0)

loc_14FB0:
                cmpi.w  #$30,(dword_FFD888).w
                bhi.s   locret_14FD0
                cmpi.b  #$31,(word_FFD82C+1).w
                bhi.s   locret_14FD0
                clr.b   $39(a0)
                tst.b   $16(a0)
                beq.s   locret_14FD0
                move.b  #1,$39(a0)

locret_14FD0:
                rts

sub_14FD2:
                bset    #7,$3C(a0)
                bne.s   loc_15004
                move.b  #7,5(a0)
                clr.l   $34(a0)
                move.b  #$14,$3B(a0)
                move.l  #word_1A918,$C(a0)
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   loc_15004
                bset    #7,2(a0)

loc_15004:
                bsr.w   sub_1105C
                move.w  $20(a0),d7
                move.w  $24(a0),d6
                lea     (word_FFC440).w,a1
                move.w  word_FFC460-word_FFC440(a1),d5
                move.w  $24(a1),d4
                cmp.w   d6,d4
                beq.s   loc_1502E
                move.b  #2,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

loc_1502E:
                tst.b   $39(a0)
                bne.s   loc_1504E
                cmp.w   d7,d5
                bgt.s   loc_15040
                move.w  #$10,$3C(a0)
                rts

loc_15040:
                move.b  #1,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

loc_1504E:
                cmp.w   d7,d5
                blt.s   loc_1505A
                move.w  #$10,$3C(a0)
                rts

loc_1505A:
                move.b  #1,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

sub_15068:
                bset    #7,$3C(a0)
                bne.s   loc_15094
                move.b  #7,5(a0)
                move.l  (dword_FFD296).w,$34(a0)
                tst.b   $16(a0)
                beq.s   loc_1508A
                move.l  #loc_14000,$34(a0)

loc_1508A:
                tst.b   $39(a0)
                beq.s   loc_15094
                neg.l   $34(a0)

loc_15094:
                bsr.w   sub_1105C
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subq.w  #8,d6
                tst.l   $34(a0)
                bpl.s   loc_150AC
                subq.w  #8,d7
                bra.s   loc_150AE

loc_150AC:
                addq.w  #8,d7

loc_150AE:
                bsr.w   sub_1157C
                tst.b   d4
                beq.s   loc_150BA
                neg.l   $34(a0)

loc_150BA:
                moveq   #0,d7
                moveq   #1,d6
                bsr.w   sub_115C0
                btst    #7,d4
                bne.s   loc_150EA
                tst.l   $34(a0)
                bpl.s   loc_150DC
                btst    #2,d4
                bne.s   loc_150DA
                move.w  #4,$3C(a0)

loc_150DA:
                bra.s   loc_15114

loc_150DC:
                btst    #3,d4
                bne.s   loc_150E8
                move.w  #4,$3C(a0)

loc_150E8:
                bra.s   loc_15114

loc_150EA:
                tst.b   $39(a0)
                bne.s   loc_150F8
                btst    #6,d4
                bne.s   loc_15114
                bra.s   loc_150FE

loc_150F8:
                btst    #6,d4
                beq.s   loc_15114

loc_150FE:
                lea     (word_FFC440).w,a1
                move.w  $24(a0),d6
                cmp.w   $24(a1),d6
                blt.s   loc_15114
                beq.s   loc_15132
                move.w  #$18,$3C(a0)

loc_15114:
                bclr    #7,2(a0)
                tst.l   $34(a0)
                bpl.s   loc_15126
                bset    #7,2(a0)

loc_15126:
                move.w  #4,6(a0)
                bsr.w   sub_11126
                rts

loc_15132:
                cmpi.w  #$30,(dword_FFD888).w
                bls.s   loc_15114
                move.w  $20(a1),d7
                tst.b   $39(a0)
                beq.s   loc_1514C
                cmp.w   $20(a0),d7
                blt.s   loc_15114
                bra.s   loc_15152

loc_1514C:
                cmp.w   $20(a0),d7
                bgt.s   loc_15114

loc_15152:
                move.w  #$18,$3C(a0)
                bra.s   loc_15114

sub_1515A:
                tst.b   $3B(a0)
                bne.w   loc_1524C
                bset    #7,$3C(a0)
                bne.s   loc_151B4
                move.b  #7,5(a0)
                move.b  $3A(a0),d0
                beq.s   loc_1518C
                cmpi.b  #1,d0
                beq.s   loc_1519A
                move.l  (dword_FFD276).w,$34(a0)
                move.l  #$FFFF8000,$2C(a0)
                bra.s   loc_151AA

loc_1518C:
                move.l  (dword_FFD26E).w,$34(a0)
                move.l  (dword_FFD272).w,$2C(a0)
                bra.s   loc_151AA

loc_1519A:
                move.l  #$1A000,$34(a0)
                move.l  #$FFFF0000,$2C(a0)

loc_151AA:
                tst.b   $39(a0)
                beq.s   loc_151B4
                neg.l   $34(a0)

loc_151B4:
                addi.l  #$1000,$2C(a0)
                bsr.w   sub_1105C
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   sub_1157C
                tst.b   d4
                bne.s   loc_1520C
                subq.w  #8,d6
                tst.l   $34(a0)
                bpl.s   loc_151DC
                subq.w  #8,d7
                bra.s   loc_151DE

loc_151DC:
                addq.w  #8,d7

loc_151DE:
                bsr.w   sub_1157C
                tst.b   d4
                beq.s   loc_151EC
                neg.l   $34(a0)
                bra.s   loc_15222

loc_151EC:
                tst.l   $2C(a0)
                bpl.s   loc_1520A
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subi.w  #$D,d6
                bsr.w   sub_1157C
                tst.b   d4
                beq.s   loc_1520A
                clr.l   $2C(a0)

loc_1520A:
                bra.s   loc_15222

loc_1520C:
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)
                move.w  #8,$3C(a0)

loc_15222:
                move.l  #word_1A970,$C(a0)
                tst.l   $2C(a0)
                bmi.s   loc_15238
                move.l  #word_1A97E,$C(a0)

loc_15238:
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   locret_1524A
                bset    #7,2(a0)

locret_1524A:
                rts

loc_1524C:
                subq.b  #1,$3B(a0)
                bsr.w   sub_1105C
                rts

sub_15256:
                tst.b   $3B(a0)
                bne.s   loc_152AA
                bset    #7,$3C(a0)
                bne.s   loc_1527A
                move.b  #7,5(a0)
                bclr    #2,2(a0)
                move.w  #$C,6(a0)
                clr.b   $10(a0)

loc_1527A:
                bsr.w   sub_1105C
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   loc_15290
                bset    #7,2(a0)

loc_15290:
                bsr.w   sub_11126
                bclr    #2,2(a0)
                beq.s   locret_152A8
                bchg    #0,$39(a0)
                move.w  #8,$3C(a0)

locret_152A8:
                rts

loc_152AA:
                subq.b  #1,$3B(a0)
                bsr.w   sub_1105C
                rts

sub_152B4:
                bset    #7,$3C(a0)
                bne.s   loc_152E4
                move.l  a0,-(sp)
                move.b  #$93,d0
                bsr.w   sub_10D48
                movea.l (sp)+,a0
                tst.b   $16(a0)
                bne.s   loc_152D6
                addi.l  #$1000,(dword_FFD296).w

loc_152D6:
                clr.b   5(a0)
                move.w  #8,6(a0)
                subq.b  #1,(byte_FFD26C).w

loc_152E4:
                bsr.w   sub_14688
                tst.l   $34(a0)
                bne.s   locret_152F4
                move.w  #$1C,$3C(a0)

locret_152F4:
                rts

sub_152F6:
                bset    #7,$3C(a0)
                bne.s   loc_15328
                move.b  #7,5(a0)
                clr.l   $34(a0)
                move.b  #$14,$3B(a0)
                move.l  #word_1A918,$C(a0)
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   loc_15328
                bset    #7,2(a0)

loc_15328:
                bsr.w   sub_1105C
                move.w  $20(a0),d7
                move.w  $24(a0),d6
                lea     (word_FFC440).w,a1
                move.w  word_FFC460-word_FFC440(a1),d5
                move.w  $24(a1),d4
                cmp.w   d6,d4
                beq.s   loc_15360
                bgt.s   loc_15352
                clr.b   $3A(a0)
                move.w  #$C,$3C(a0)
                rts

loc_15352:
                move.b  #2,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

loc_15360:
                tst.b   $39(a0)
                bne.s   loc_15380
                cmp.w   d7,d5
                bgt.s   loc_15372
                move.w  #$10,$3C(a0)
                rts

loc_15372:
                move.b  #1,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

loc_15380:
                cmp.w   d7,d5
                blt.s   loc_1538C
                move.w  #$10,$3C(a0)
                rts

loc_1538C:
                move.b  #1,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

sub_1539A:
                subq.b  #1,$3B(a0)
                bsr.w   sub_1105C
                rts

sub_153A4:
                bset    #7,$3C(a0)
                bne.s   loc_153C8
                clr.b   5(a0)
                bclr    #2,2(a0)
                move.w  #$10,6(a0)
                clr.b   $10(a0)
                move.l  #$FFFFC000,$2C(a0)

loc_153C8:
                bsr.w   sub_1105C
                bsr.w   sub_11126
                btst    #2,2(a0)
                beq.s   locret_15408
                move.b  (dword_FFD888+2).w,d0
                andi.b  #$F0,d0
                bne.s   loc_15404
                lea     (unk_FFC740).w,a1
                tst.b   $16(a0)
                beq.s   loc_153F0
                lea     $40(a1),a1

loc_153F0:
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                move.w  d7,$30(a1)
                move.w  d6,$24(a1)
                move.w  #$28,(a1)

loc_15404:
                bsr.w   sub_11118

locret_15408:
                rts

sub_1540A:
                lea     (unk_FFC200).w,a1
                moveq   #5,d0

loc_15410:
                move.w  d0,-(sp)
                btst    #3,5(a1)
                beq.s   loc_1548E
                bsr.w   sub_117C0
                tst.b   d0
                beq.s   loc_1548E
                move.w  #$14,$3C(a0)
                clr.b   5(a0)
                move.l  $34(a1),d7
                move.l  $2C(a1),d6
                move.l  d7,$34(a0)
                move.l  d6,$2C(a0)
                addq.b  #1,$3B(a1)
                moveq   #0,d0
                move.b  $3B(a1),d0
                subq.b  #1,d0
                lsl.w   #2,d0
                move.l  dword_1549E(pc,d0.w),d0
                move.l  d0,(dword_FFD262).w
                move.l  a1,-(sp)
                bsr.w   sub_1168A
                movea.l (sp)+,a1
                lea     (unk_FFC0C0).w,a2
                moveq   #3,d0

loc_15460:
                tst.b   (a2)
                bne.s   loc_15484
                move.w  #$1C,(a2)
                move.b  $3B(a1),d1
                move.b  d1,$3A(a2)
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subq.w  #8,d6
                move.w  d7,$30(a2)
                move.w  d6,$24(a2)
                bra.s   loc_1549A

loc_15484:
                lea     -$40(a2),a2
                dbf     d0,loc_15460
                bra.s   loc_1549A

loc_1548E:
                lea     $40(a1),a1
                move.w  (sp)+,d0
                dbf     d0,loc_15410
                rts

loc_1549A:
                move.w  (sp)+,d0
                rts

dword_1549E:    dc.l $200
                dc.l $400
                dc.l $800
                dc.l $1600
off_154AE:      dc.l byte_154C2
                dc.l byte_154D0
                dc.l byte_154E2
                dc.l byte_154F4
                dc.l byte_154FE
byte_154C2:     dc.b 6, $C
                dc.w word_1A8F8-sub_10000
                dc.w word_1A900-sub_10000
                dc.w word_1A8F8-sub_10000
                dc.w word_1A900-sub_10000
                dc.w word_1A908-sub_10000
                dc.w word_1A910-sub_10000
byte_154D0:     dc.b 8, 1
                dc.w word_1A918-sub_10000
                dc.w word_1A926-sub_10000
                dc.w word_1A93A-sub_10000
                dc.w word_1A94E-sub_10000
                dc.w word_1A94E-sub_10000
                dc.w word_1A95C-sub_10000
                dc.w word_1A93A-sub_10000
                dc.w word_1A926-sub_10000
byte_154E2:     dc.b 8, 1
                dc.w word_1A992-sub_10000
                dc.w word_1A99A-sub_10000
                dc.w word_1A9AE-sub_10000
                dc.w word_1A9B6-sub_10000
                dc.w word_1A9CA-sub_10000
                dc.w word_1A9D2-sub_10000
                dc.w word_1A9E6-sub_10000
                dc.w word_1A9EE-sub_10000
byte_154F4:     dc.b 4, 5
                dc.w word_1AA02-sub_10000
                dc.w word_1AA02-sub_10000
                dc.w word_1AA0A-sub_10000
                dc.w word_1AA12-sub_10000
byte_154FE:     dc.b 4, 6
                dc.w word_1AA7E-sub_10000
                dc.w word_1AA7E-sub_10000
                dc.w word_1AA86-sub_10000
                dc.w word_1AA8E-sub_10000
off_15508:      dc.w word_15568-sub_10000
                dc.w word_155A4-sub_10000
                dc.w word_155A4-sub_10000
                dc.w word_155C0-sub_10000
                dc.w word_155DC-sub_10000
                dc.w word_15610-sub_10000
                dc.w word_15610-sub_10000
                dc.w word_15624-sub_10000
                dc.w word_15646-sub_10000
                dc.w word_1566A-sub_10000
                dc.w word_1566A-sub_10000
                dc.w word_156A2-sub_10000
                dc.w word_156CE-sub_10000
                dc.w word_15714-sub_10000
                dc.w word_15714-sub_10000
                dc.w word_15740-sub_10000
                dc.w word_1576E-sub_10000
                dc.w word_157D2-sub_10000
                dc.w word_157D2-sub_10000
                dc.w word_157FA-sub_10000
                dc.w word_15822-sub_10000
                dc.w word_1584E-sub_10000
                dc.w word_1584E-sub_10000
                dc.w word_15886-sub_10000
                dc.w word_158A6-sub_10000
                dc.w word_158C6-sub_10000
                dc.w word_158C6-sub_10000
                dc.w word_158E2-sub_10000
                dc.w word_1590E-sub_10000
                dc.w word_1592A-sub_10000
                dc.w word_1592A-sub_10000
                dc.w word_15942-sub_10000
                dc.w word_15962-sub_10000
                dc.w word_15982-sub_10000
                dc.w word_15982-sub_10000
                dc.w word_159B6-sub_10000
                dc.w word_159DE-sub_10000
                dc.w word_15A02-sub_10000
                dc.w word_15A02-sub_10000
                dc.w word_15A2E-sub_10000
                dc.w word_15A46-sub_10000
                dc.w word_15AE6-sub_10000
                dc.w word_15AE6-sub_10000
                dc.w word_15B02-sub_10000
                dc.w word_15B1C-sub_10000
                dc.w word_15B52-sub_10000
                dc.w word_15B52-sub_10000
                dc.w word_15B70-sub_10000
word_15568:     dc.w $705, $A05, $1005, $1615, $715, $D15, $1315, $1A07, $1A0A, $1A10
                dc.w $1A16, $A07, $A0D, $A13, $A1A, $E0E, $80D, $C0E, $E0D, $120E
                dc.w $140D, $191E, $51D, $91E, $B1D, $F1E, $111D, $151E, $171D, $1900
word_155A4:     dc.w $30D, $141D, $1A1D, $E03, $20E, $21A, $1214, $60F, $1310, $910
                dc.w $1911, $1519, $F18, $1300
word_155C0:     dc.w $30C, $E0C, $140C, $1A03, $130E, $1314, $131A, $61A, $D1A, $131A
                dc.w $191B, $91B, $F1B, $1500
word_155DC:     dc.w $507, $A07, $1A0F, $1617, $121F, $E05, $E, $812, $1016, $180A
                dc.w $181A, $E05, $1105, $1906, $B06, $130D, $150D, $190E, $70E, $1715
                dc.w $1116, $B17, $1918, $131D, $191E, $F00
word_15610:     dc.w $606, $E0B, $1410, $1A16, $1E1B, $1400, $1A00, $208, $1309, $F00
word_15624:     dc.w $504, $C06, $1411, $1A13, $817, $1406, $30C, $A1A, $B0E, $161A
                dc.w $1B10, $1A14, $40D, $D0D, $190E, $90E, $1500
word_15646:     dc.w $419, $100D, $B09, $151D, $1A04, $21A, $1615, $120B, $610, $806
                dc.w $1406, $1907, $1107, $1619, $1419, $191A, $111A, $1600
word_1566A:     dc.w $607, $C07, $1213, $713, $D13, $1313, $1A0A, $606, $60C, $612
                dc.w $61A, $C07, $C0D, $C13, $1908, $180E, $1814, $A00, $B00, $170F
                dc.w $C0F, $120F, $1910, $810, $E10, $141F, $F1F, $1900
word_156A2:     dc.w $501, $908, $1A0A, $160C, $1110, $D05, $F0D, $1311, $1516, $171A
                dc.w $1E09, $A0D, $190E, $150F, $C0F, $1010, $510, $E11, $1211, $1713
                dc.w $814, $500
word_156CE:     dc.w $802, $1106, $706, $1A0E, $1612, $111A, $1A1E, $1515, $909, $115
                dc.w $51A, $60D, $D11, $1116, $191A, $1D11, $190D, $1409, $1000, $800
                dc.w $1603, $1904, $1208, $C09, $80C, $150C, $190D, $1212, $1513, $1213
                dc.w $171B, $191C, $121F, $141F, $1900
word_15714:     dc.w $404, $1009, $A1A, $1A1F, $1604, $16, $51A, $160A, $1B10, $C04
                dc.w $1905, $1109, $190A, $B0E, $190F, $615, $1916, $B19, $191A, $111E
                dc.w $191F, $1700
word_15740:     dc.w $703, $B04, $1609, $1A12, $1516, $111C, $1A15, $706, $B, $216
                dc.w $911, $1A11, $F07, $B1A, $801, $1502, $C07, $1908, $170F, $A0F
                dc.w $1910, $810, $1600
word_1576E:     dc.w $A02, $1206, $E0A, $A0A, $1A0E, $161A, $1A1E, $1612, $1216, $E1A
                dc.w $A0A, $116, $50A, $51A, $90E, $D12, $1116, $150A, $1D12, $151A
                dc.w $190E, $1C00, $700, $1703, $1103, $1904, $B04, $1307, $1908, $F0B
                dc.w $110B, $190C, $B0C, $130F, $150F, $1910, $710, $1713, $1113, $1914
                dc.w $B14, $1317, $1918, $F1B, $111B, $191C, $B1C, $131F, $151F, $1900
word_157D2:     dc.w $403, $A0F, $1A14, $161D, $1004, $210, $B16, $101A, $1C0A, $A03
                dc.w $F04, $B09, $190A, $170F, $1910, $914, $1915, $170A, $F0B, $B00
word_157FA:     dc.w $50D, $C0E, $1A19, $C19, $1219, $1A05, $A16, $120C, $1F0C, $1F12
                dc.w $1E16, $800, $1501, $1303, $B06, $713, $1714, $1315, $B16, $700
word_15822:     dc.w $500, $1A03, $1506, $1009, $C0C, $805, $1308, $160C, $1910, $1C15
                dc.w $1F1A, $A09, $140A, $110F, $70F, $B0F, $F10, $510, $910, $D14
                dc.w $1915, $1600
word_1584E:     dc.w $700, $1104, $A0F, $1515, $1015, $1A1A, $A1B, $1607, $416, $50A
                dc.w $A10, $A1A, $1015, $1B0A, $1F11, $C05, $1505, $1906, $B07, $1709
                dc.w $F0A, $50D, $190E, $1615, $F16, $519, $151A, $B00
word_15886:     dc.w $502, $1405, $F07, $1A08, $A1F, $1A05, $1A, $170A, $181A, $1A0F
                dc.w $1D14, $40B, $190C, $1713, $1914, $1700
word_158A6:     dc.w $51E, $1A02, $110C, $151D, $151B, $1103, $11A, $D0D, $1E09, $607
                dc.w $C08, $A15, $1016, $E1A, $191B, $1600
word_158C6:     dc.w $60F, $1502, $1A06, $150A, $110E, $D13, $902, $1409, $1A1A, $415
                dc.w $1916, $1617, $418, $100
word_158E2:     dc.w $500, $900, $1100, $1A0F, $D0F, $1505, $100D, $1015, $1F09, $1F11
                dc.w $1F1A, $A08, $C08, $1409, $A09, $1217, $817, $1017, $1918, $618
                dc.w $E18, $1600
word_1590E:     dc.w $405, $1509, $F1F, $A00, $1A02, $1D0A, $1F1A, $612, $912, $1413
                dc.w $613, $1019, $191A, $1600
word_1592A:     dc.w $801, $905, $140B, $F11, $90F, $1A15, $141B, $F1F, $1A02, 9
                dc.w $1009, 0
word_15942:     dc.w $403, $1A0C, $A0C, $100D, $1504, $1115, $120A, $1210, $1B1A, $613
                dc.w $1413, $1914, $1114, $1609, $140A, $1100
word_15962:     dc.w $400, $130A, $130E, $1A0E, $C04, $111A, $1513, $1F13, $110C, $60A
                dc.w $120B, $60F, $1910, $D1B, $191C, $1400
word_15982:     dc.w $806, $706, $D06, $1306, $1A16, $A16, $1016, $161D, $708, $A0A
                dc.w $A10, $A16, $1A07, $1A0D, $1A13, $1A1A, $207, $805, $1906, $140A
                dc.w $190B, $1715, $1916, $171A, $191B, $1400
word_159B6:     dc.w $805, $C05, $130E, $C0E, $130E, $1A14, $C14, $1318, $1A08, $81A
                dc.w $C0C, $C13, $120C, $1213, $121A, $1B0C, $1B13, $21B, $161C, $1400
word_159DE:     dc.w $409, $1A09, $811, $161D, $1A08, $213, $30C, $E16, $120C, $161A
                dc.w $1708, $1713, $1D0C, $40E, $190F, $1711, $B12, $500
word_15A02:     dc.w $601, $1402, $1A0B, $140E, $1A17, $1418, $1A06, $71A, $814, $111A
                dc.w $1414, $1D1A, $1E14, $800, $1509, $190A, $150F, $1910, $E15, $1916
                dc.w $151F, $1900
word_15A2E:     dc.w $40B, $814, $D14, $160A, $1102, $B11, $B1A, $400, $1706, $707
                dc.w $51F, $1900
word_15A46:     dc.w $1203, $803, $1003, $1A07, $C07, $140B, $80B, $100B, $1A1B, $1A0F
                dc.w $C0F, $1413, $813, $1013, $1A17, $C17, $141B, $81B, $1014, $10C
                dc.w $114, $508, $510, $51A, $90C, $914, $D08, $D10, $D1A, $110C
                dc.w $1114, $1508, $1510, $151A, $190C, $1914, $1D08, $1D10, $1D1A, $2800
                dc.w $500, $D00, $1504, $F04, $1905, $905, $1107, $B07, $1307, $1908
                dc.w $508, $D08, $150B, $F0B, $190C, $90C, $110F, $B0F, $130F, $1910
                dc.w $510, $D10, $1513, $F13, $1914, $914, $1118, $B17, $1317, $1919
                dc.w $518, $D18, $151B, $F1B, $191C, $91C, $111F, $B1F, $131F, $1900
word_15AE6:     dc.w $C, $10C, $90C, $110C, $190C, $413, $C13, $1413, $1C13, $71A
                dc.w $F1A, $171A, $1F1A, 0
word_15B02:     dc.w $20B, $1A19, $1A03, $213, $E1A, $180C, $603, $1904, $140F, $1910
                dc.w $618, $1919, $D00
word_15B1C:     dc.w $701, $1103, $1A09, $B0A, $160E, $1A12, $1019, $B06, $70B, $E10
                dc.w $1616, $170B, $1D1A, $1F11, $C01, $901, $1507, $1908, $F0F, $F0F
                dc.w $1911, $911, $1117, $1919, $F1F, $101F, $1900
word_15B52:     dc.w $702, $1305, $C06, $1A09, $160C, $F0D, $1A1F, $1A06, $1A, $130F
                dc.w $1616, $191A, $1A0C, $1D13, 0
word_15B70:     dc.w $40F, $C13, $1A18, $131F, $C04, $10C, $813, $D1A, $110C, $802
                dc.w $1203, $100B, $B0F, $120F, $1911, $1011, $1616, $900
dword_15B94:    dc.l $14000, $FFFE0000
                dc.l $10000, $FFFD8000
                dc.l $10000, $FFFD8000
                dc.l $14000, $FFFD8000
                dc.l $14000, $FFFE0000
                dc.l $14000, $FFFD8000
                dc.l $14000, $FFFD8000
                dc.l $14000, $FFFD8000
                dc.l $18000, $FFFDE000
                dc.l $14000, $FFFD8000
                dc.l $14000, $FFFD8000
                dc.l $4800, $FFFD9000
                dc.l $C000, $FFFDE000
                dc.l $8000, $FFFD8000
                dc.l $8000, $FFFD8000
                dc.l $10000, $FFFD8000
                dc.l $10000, $FFFE0000
                dc.l $A000, $FFFD5000
                dc.l $A000, $FFFD5000
                dc.l $10000, $FFFD9000
                dc.l $8000, $FFFDC000
                dc.l $A000, $FFFD8000
                dc.l $A000, $FFFD8000
                dc.l $7000, $FFFD8000
                dc.l $1A000, $FFFDC000
                dc.l $8000, $FFFD8000
                dc.l $8000, $FFFD8000
                dc.l $10000, $FFFDC000
                dc.l $A000, $FFFD8000
                dc.l $C000, $FFFD8000
                dc.l $C000, $FFFD8000
                dc.l $10000, $FFFD8000
                dc.l $8000, $FFFD0000
                dc.l $10000, $FFFE0000
                dc.l $10000, $FFFE0000
                dc.l $8000, $FFFD3000
                dc.l $A000, $FFFD4000
                dc.l $A000, $FFFD0000
                dc.l $A000, $FFFD0000
                dc.l $C000, $FFFD8000
                dc.l $8000, $FFFD8000
                dc.l $6000, $FFFD2000
                dc.l $10000, $FFFE0000
                dc.l $10000, $FFFD0000
                dc.l $C000, $FFFD4000
                dc.l $6000, $FFFD2000
                dc.l $6000, $FFFD2000
                dc.l $C000, $FFFD4000
dword_15D14:    dc.l $10000
                dc.l $14000
                dc.l $12000
                dc.l $E000
                dc.l $16000
byte_15D28:     dc.b 0, 0, 0, 1, 4, 0, 0, 2
                dc.b 2, 2, 0, 0, 0, 3, 0, 2
                dc.b 0, 0, 0, 0, 0, 3, 0, 2
                dc.b 0, 2, 0, 0, 0, 0, 0, 1
                dc.b 0, 4, 0, 3, 0, 0, 0, 0
                dc.b 0, 0, 0, 0, 0, 3, 0, 0
sub_15D58:
                bset    #7,(a0)
                bne.s   loc_15D8C
                moveq   #0,d7
                moveq   #0,d6
                move.b  $3E(a0),d7
                move.b  $3F(a0),d6
                bsr.w   sub_11674
                addq.w  #8,d7
                addi.w  #$10,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)
                move.l  #off_162BC,8(a0)
                clr.l   $34(a0)
                clr.l   $2C(a0)

loc_15D8C:
                tst.b   (byte_FFD27B).w
                bne.s   locret_15DC0
                tst.b   (byte_FFD24F).w
                bne.s   locret_15DC0
                tst.b   (byte_FFD26D).w
                bne.s   locret_15DC0
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     loc_15DC2(pc,d0.w)
                move.w  $3C(a0),d0
                andi.w  #$7C,d0
                cmpi.w  #$C,d0
                beq.s   locret_15DC0
                cmpi.w  #$10,d0
                beq.s   locret_15DC0
                bsr.w   sub_16218

locret_15DC0:
                rts

loc_15DC2:
                bra.w   sub_15DD6
                bra.w   sub_15E04
                bra.w   sub_160C8
                bra.w   sub_16188
                bra.w   sub_161BC

sub_15DD6:
                bset    #7,$3C(a0)
                bne.s   loc_15DF2
                move.b  #4,5(a0)
                move.l  #word_1AB74,$C(a0)
                move.b  #$A,$3B(a0)

loc_15DF2:
                bsr.w   sub_1105C
                subq.b  #1,$3B(a0)
                bne.s   locret_15E02
                move.w  #4,$3C(a0)

locret_15E02:
                rts

sub_15E04:
                bset    #7,$3C(a0)
                bne.s   loc_15E12
                move.b  #5,5(a0)

loc_15E12:
                moveq   #0,d0
                move.b  $3A(a0),d0
                lsl.w   #2,d0
                jsr     loc_15E20(pc,d0.w)
                rts

loc_15E20:
                bra.w   sub_15E40
                bra.w   sub_15EE6
                bra.w   sub_15EE6
                bra.w   sub_15EE6
                bra.w   sub_15F9E
                bra.w   sub_15F9E
                bra.w   sub_16036
                bra.w   sub_160C8

sub_15E40:
                clr.w   6(a0)
                bclr    #7,2(a0)
                move.l  (dword_FFD27C).w,$34(a0)
                clr.l   $2C(a0)
                bsr.w   sub_1105C
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   sub_1157C
                tst.b   d4
                beq.s   loc_15E86
                addq.w  #4,d7
                subq.w  #4,d6
                bsr.w   sub_1157C
                tst.b   d4
                bne.s   loc_15EA8
                moveq   #0,d7
                moveq   #$FFFFFFFC,d6
                bsr.w   sub_115C0
                tst.b   d4
                bne.s   loc_15ED6
                bsr.w   sub_11126
                rts

loc_15E86:
                move.b  #6,$3A(a0)
                move.w  $30(a0),d7
                andi.w  #$FFF8,d7
                subq.w  #1,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                move.l  #word_1AC04,$C(a0)
                rts

loc_15EA8:
                move.b  #5,$3A(a0)
                andi.w  #$FFF8,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                addq.w  #4,$20(a0)
                andi.w  #$FFF8,d6
                addq.w  #7,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #word_1ABCC,$C(a0)
                rts

loc_15ED6:
                move.w  #8,$3C(a0)
                move.l  #word_1AC4C,$C(a0)
                rts

sub_15EE6:
                move.w  #4,6(a0)
                bset    #7,2(a0)
                move.l  (dword_FFD27C).w,d0
                neg.l   d0
                move.l  d0,$34(a0)
                clr.l   $2C(a0)
                bsr.w   sub_1105C
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   sub_1157C
                tst.b   d4
                beq.s   loc_15F32
                subq.w  #4,d7
                addq.w  #4,d6
                bsr.w   sub_1157C
                tst.b   d4
                bne.s   loc_15F5A
                moveq   #0,d7
                moveq   #4,d6
                bsr.w   sub_115C0
                tst.b   d4
                bne.s   loc_15F8E
                bsr.w   sub_11126
                rts

loc_15F32:
                move.b  #5,$3A(a0)
                move.w  $30(a0),d7
                andi.w  #$FFF8,d7
                addq.w  #8,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                move.l  #word_1AC20,$C(a0)
                bclr    #7,2(a0)
                rts

loc_15F5A:
                move.b  #6,$3A(a0)
                andi.w  #$FFF8,d7
                addq.w  #7,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                subq.w  #4,$20(a0)
                andi.w  #$FFF8,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #word_1ABE8,$C(a0)
                bclr    #7,2(a0)
                rts

loc_15F8E:
                move.w  #8,$3C(a0)
                move.l  #word_1AC64,$C(a0)
                rts

sub_15F9E:
                move.w  #8,6(a0)
                bclr    #7,2(a0)
                clr.l   $34(a0)
                move.l  (dword_FFD27C).w,d0
                neg.l   d0
                move.l  d0,$2C(a0)
                bsr.w   sub_1105C
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   sub_1157C
                tst.b   d4
                beq.s   loc_15FDE
                subq.w  #4,d7
                subq.w  #4,d6
                bsr.w   sub_1157C
                tst.b   d4
                bne.s   loc_16004
                bsr.w   sub_11126
                rts

loc_15FDE:
                clr.b   $3A(a0)
                move.w  $24(a0),d6
                andi.w  #$FFF8,d6
                addq.w  #8,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #word_1AC2E,$C(a0)
                bclr    #7,2(a0)
                rts

loc_16004:
                move.b  #3,$3A(a0)
                andi.w  #$FFF8,d7
                addq.w  #7,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                andi.w  #$FFF8,d6
                addq.w  #7,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #word_1ABDA,$C(a0)
                bclr    #7,2(a0)
                rts

sub_16036:
                move.w  #$C,6(a0)
                bset    #7,2(a0)
                clr.l   $34(a0)
                move.l  (dword_FFD27C).w,$2C(a0)
                bsr.w   sub_1105C
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   sub_1157C
                tst.b   d4
                beq.s   loc_16072
                addq.w  #4,d7
                addq.w  #4,d6
                bsr.w   sub_1157C
                tst.b   d4
                bne.s   loc_1609A
                bsr.w   sub_11126
                rts

loc_16072:
                move.b  #3,$3A(a0)
                move.w  $24(a0),d6
                andi.w  #$FFF8,d6
                subq.w  #1,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #word_1AC12,$C(a0)
                bclr    #7,2(a0)
                rts

loc_1609A:
                move.b  #0,$3A(a0)
                andi.w  #$FFF8,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                andi.w  #$FFF8,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #word_1ABF6,$C(a0)
                bclr    #7,2(a0)
                rts

sub_160C8:
                bset    #7,$3C(a0)
                bne.s   loc_160D6
                move.b  #5,5(a0)

loc_160D6:
                btst    #1,$3A(a0)
                bne.s   loc_16136
                move.w  #$10,6(a0)
                clr.l   $34(a0)
                move.l  (dword_FFD27C).w,d0
                neg.l   d0
                move.l  d0,$2C(a0)
                bsr.w   sub_1105C
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subq.w  #8,d6
                bsr.w   sub_1157C
                bne.s   loc_1610C
                bsr.w   sub_11126
                rts

loc_1610C:
                move.w  #4,$3C(a0)
                bchg    #0,$3A(a0)
                bchg    #1,$3A(a0)
                andi.w  #$FFF8,d6
                addq.w  #7,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #word_1AC64,$C(a0)
                rts

loc_16136:
                move.w  #$14,6(a0)
                clr.l   $34(a0)
                move.l  (dword_FFD27C).w,$2C(a0)
                bsr.w   sub_1105C
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                addq.w  #8,d6
                bsr.w   sub_1157C
                bne.s   loc_16160
                bsr.w   sub_11126
                rts

loc_16160:
                move.w  #4,$3C(a0)
                bchg    #0,$3A(a0)
                bchg    #1,$3A(a0)
                andi.w  #$FFF8,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #word_1AC4C,$C(a0)
                rts

sub_16188:
                bset    #7,$3C(a0)
                bne.s   loc_161AA
                move.l  a0,-(sp)
                move.b  #$93,d0
                bsr.w   sub_10D48
                movea.l (sp)+,a0
                move.w  #$18,6(a0)
                subq.b  #1,(byte_FFD26C).w
                clr.b   5(a0)

loc_161AA:
                bsr.w   sub_14688
                tst.l   $34(a0)
                bne.s   locret_161BA
                move.w  #$10,$3C(a0)

locret_161BA:
                rts

sub_161BC:
                bset    #7,$3C(a0)
                bne.s   loc_161E0
                bclr    #2,2(a0)
                move.w  #$1C,6(a0)
                clr.b   $10(a0)
                move.l  #$FFFFC000,$2C(a0)
                clr.b   5(a0)

loc_161E0:
                bsr.w   sub_1105C
                bsr.w   sub_11126
                btst    #2,2(a0)
                beq.s   locret_16216
                move.b  (dword_FFD888+2).w,d0
                andi.b  #$F0,d0
                bne.s   loc_16212
                lea     (unk_FFC7C0).w,a1
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                move.w  d7,$30(a1)
                move.w  d6,$24(a1)
                move.w  #$28,(a1)

loc_16212:
                bsr.w   sub_11118

locret_16216:
                rts

sub_16218:
                lea     (unk_FFC200).w,a1
                moveq   #5,d0

loc_1621E:
                move.w  d0,-(sp)
                btst    #4,5(a1)
                beq.s   loc_1629C
                bsr.w   sub_117C0
                tst.b   d0
                beq.s   loc_1629C
                move.w  #$C,$3C(a0)
                clr.b   5(a0)
                move.l  $34(a1),d7
                move.l  $2C(a1),d6
                move.l  d7,$34(a0)
                move.l  d6,$2C(a0)
                addq.b  #1,$3B(a1)
                moveq   #0,d0
                move.b  $3B(a1),d0
                subq.b  #1,d0
                lsl.w   #2,d0
                move.l  dword_162AC(pc,d0.w),d0
                move.l  d0,(dword_FFD262).w
                move.l  a1,-(sp)
                bsr.w   sub_1168A
                movea.l (sp)+,a1
                lea     (unk_FFC0C0).w,a2
                moveq   #3,d0

loc_1626E:
                tst.b   (a2)
                bne.s   loc_16292
                move.w  #$1C,(a2)
                move.b  $3B(a1),d1
                move.b  d1,$3A(a2)
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subq.w  #8,d6
                move.w  d7,$30(a2)
                move.w  d6,$24(a2)
                bra.s   loc_162A8

loc_16292:
                lea     -$40(a2),a2
                dbf     d0,loc_1626E
                bra.s   loc_162A8

loc_1629C:
                lea     $40(a1),a1
                move.w  (sp)+,d0
                dbf     d0,loc_1621E
                rts

loc_162A8:
                move.w  (sp)+,d0
                rts

dword_162AC:    dc.l $200, $400, $800, $1600
off_162BC:      dc.l byte_162DC
                dc.l byte_162E6
                dc.l byte_162F0
                dc.l byte_162F6
                dc.l byte_162FC
                dc.l byte_16302
                dc.l byte_16308
                dc.l byte_154FE
byte_162DC:     dc.b 4, 1
                dc.w word_1AB7C-sub_10000
                dc.w word_1AB84-sub_10000
                dc.w word_1AB8C-sub_10000
                dc.w word_1AB84-sub_10000
byte_162E6:     dc.b 4, 1
                dc.w word_1AB94-sub_10000
                dc.w word_1AB9C-sub_10000
                dc.w word_1ABA4-sub_10000
                dc.w word_1AB9C-sub_10000
byte_162F0:     dc.b 2, 1
                dc.w word_1ABAC-sub_10000
                dc.w word_1ABB4-sub_10000
byte_162F6:     dc.b 2, 1
                dc.w word_1ABBC-sub_10000
                dc.w word_1ABC4-sub_10000
byte_162FC:     dc.b 2, 1
                dc.w word_1AC3C-sub_10000
                dc.w word_1AC44-sub_10000
byte_16302:     dc.b 2, 1
                dc.w word_1AC54-sub_10000
                dc.w word_1AC5C-sub_10000
byte_16308:     dc.b 4, 1
                dc.w word_1AC6C-sub_10000
                dc.w word_1AC7A-sub_10000
                dc.w word_1AC88-sub_10000
                dc.w word_1AC96-sub_10000
sub_16312:
                bset    #7,(a0)
                bne.s   loc_1633E
                move.b  $3E(a0),d7
                move.b  $3F(a0),d6
                bsr.w   sub_11674
                addq.w  #8,d7
                addi.w  #$10,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)
                tst.b   (byte_FFD26C).w
                beq.s   loc_1633E
                move.w  (word_FFD294).w,$38(a0)

loc_1633E:
                move.l  #off_163E0,8(a0)
                tst.b   (byte_FFD24F).w
                bne.s   locret_1635C
                tst.b   (byte_FFD27B).w
                bne.s   locret_1635C
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     loc_1635E(pc,d0.w)

locret_1635C:
                rts

loc_1635E:
                bra.w   sub_16366
                bra.w   sub_16396

sub_16366:
                bset    #7,$3C(a0)
                bne.s   loc_16378
                addq.b  #1,(byte_FFD26C).w
                bset    #1,2(a0)

loc_16378:
                bsr.w   sub_1105C
                tst.w   $38(a0)
                bne.s   loc_16390
                bclr    #1,2(a0)
                move.w  #4,$3C(a0)
                rts

loc_16390:
                subq.w  #1,$38(a0)
                rts

sub_16396:
                bset    #7,$3C(a0)
                bne.s   loc_163AC
                bclr    #2,2(a0)
                clr.b   $10(a0)
                clr.w   6(a0)

loc_163AC:
                bsr.w   sub_1105C
                bsr.w   sub_11126
                bclr    #2,2(a0)
                beq.s   locret_163DE
                movea.l a0,a1
                suba.l  #$300,a1
                move.b  $16(a0),d0
                move.w  #$10,(a1)
                move.b  d0,$16(a1)
                cmpi.b  #2,d0
                bne.s   loc_163DA
                move.w  #$14,(a1)

loc_163DA:
                bsr.w   sub_11118

locret_163DE:
                rts

off_163E0:      dc.l byte_163E4
byte_163E4:     dc.b $1C, 4
                dc.w word_1AAEC-sub_10000
                dc.w word_1AAEC-sub_10000
                dc.w word_1AAEC-sub_10000
                dc.w word_1AAF4-sub_10000
                dc.w word_1AAF4-sub_10000
                dc.w word_1AAF4-sub_10000
                dc.w word_1AAFC-sub_10000
                dc.w word_1AB04-sub_10000
                dc.w word_1AB0C-sub_10000
                dc.w word_1AB14-sub_10000
                dc.w word_1AB1C-sub_10000
                dc.w word_1AB14-sub_10000
                dc.w word_1AB0C-sub_10000
                dc.w word_1AB04-sub_10000
                dc.w word_1AAFC-sub_10000
                dc.w word_1AB04-sub_10000
                dc.w word_1AB0C-sub_10000
                dc.w word_1AB14-sub_10000
                dc.w word_1AB1C-sub_10000
                dc.w word_1AB14-sub_10000
                dc.w word_1AB0C-sub_10000
                dc.w word_1AB04-sub_10000
                dc.w word_1AAFC-sub_10000
                dc.w word_1AB04-sub_10000
                dc.w word_1AB0C-sub_10000
                dc.w word_1AB14-sub_10000
                dc.w word_1AB1C-sub_10000
                dc.w word_1AB14-sub_10000
                dc.w word_1AB0C-sub_10000
                dc.w word_1AB04-sub_10000
sub_16422:
                bset    #7,(a0)
                bne.s   loc_16442
                moveq   #0,d0
                move.b  $3A(a0),d0
                subq.b  #1,d0
                lsl.w   #1,d0
                moveq   #$FFFFFFFF,d1
                move.w  off_16450(pc,d0.w),d1
                move.l  d1,$C(a0)
                move.w  #$3C,$38(a0)

loc_16442:
                bsr.w   sub_1105C
                subq.w  #1,$38(a0)
                bne.s   locret_1644E
                clr.w   (a0)

locret_1644E:
                rts

off_16450:      dc.w byte_1AB2C-sub_10000
                dc.w word_1AB3C-sub_10000
                dc.w word_1AB4C-sub_10000
sub_16456:
                bset    #7,(a0)
                bne.s   loc_16490
                move.b  $3A(a0),d0
                subq.b  #1,d0
                lsl.w   #1,d0
                moveq   #$FFFFFFFF,d1
                move.w  off_1649E(pc,d0.w),d1
                move.l  d1,$C(a0)
                lsl.w   #2,d0
                move.w  (word_FFD25C).w,d6
                cmpi.w  #$F0,d6
                bcs.s   loc_16482
                sub.w   d0,d6
                subi.w  #$18,d6
                bra.s   loc_16486

loc_16482:
                add.w   d0,d6
                addq.w  #8,d6

loc_16486:
                move.w  d6,$24(a0)
                move.w  #$1E,$38(a0)

loc_16490:
                bsr.w   sub_1105C
                subq.w  #1,$38(a0)
                bne.s   locret_1649C
                clr.w   (a0)

locret_1649C:
                rts

off_1649E:      dc.w word_1AB24-sub_10000
                dc.w byte_1AB2C-sub_10000
                dc.w word_1AB34-sub_10000
                dc.w word_1AB3C-sub_10000
                dc.w word_1AB44-sub_10000
                dc.w word_1AB54-sub_10000
                dc.w word_1AB5C-sub_10000
                dc.w word_1AB6C-sub_10000
sub_164AE:
                bset    #7,(a0)
                bne.s   loc_164CC
                moveq   #0,d0
                move.b  $3A(a0),d0
                lsl.w   #1,d0
                moveq   #$FFFFFFFF,d1
                move.w  off_164DA(pc,d0.w),d1
                move.l  d1,$C(a0)
                move.w  #$3C,$38(a0)

loc_164CC:
                bsr.w   sub_1105C
                subq.w  #1,$38(a0)
                bne.s   locret_164D8
                clr.w   (a0)

locret_164D8:
                rts

off_164DA:      dc.w word_1AB24-sub_10000
                dc.w byte_1AB2C-sub_10000
                dc.w word_1AB34-sub_10000
                dc.w word_1AB3C-sub_10000
                dc.w word_1AB44-sub_10000
                dc.w word_1AB4C-sub_10000
                dc.w word_1AB54-sub_10000
                dc.w word_1AB5C-sub_10000
                dc.w word_1AB64-sub_10000
sub_164EC:
                bset    #7,(a0)
                bne.s   loc_1651A
                clr.b   5(a0)
                clr.l   $34(a0)
                clr.l   $2C(a0)
                addq.w  #7,$24(a0)
                move.l  #byte_165AC,8(a0)
                clr.w   6(a0)
                move.w  #$12C,$38(a0)
                bclr    #7,2(a0)

loc_1651A:
                bsr.w   sub_1105C
                bsr.w   sub_11126
                lea     (word_FFC440).w,a1
                bsr.w   sub_117C0
                tst.b   d0
                beq.s   loc_1657C
                move.l  a0,-(sp)
                move.b  #$98,d0
                bsr.w   sub_10D48
                movea.l (sp)+,a0
                lea     (unk_FFC0C0).w,a2
                moveq   #3,d0

loc_16540:
                tst.w   (a2)
                bne.s   loc_16574
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                move.w  d7,$30(a2)
                subq.w  #8,d6
                move.w  d6,$24(a2)
                moveq   #0,d7
                move.b  (byte_FFD27A).w,d7
                move.b  d7,$3A(a2)
                move.w  #$24,(a2)
                lsl.w   #2,d7
                move.l  dword_16588(pc,d7.w),d7
                move.l  d7,(dword_FFD262).w
                bsr.w   sub_1168A
                bra.s   loc_16582

loc_16574:
                lea     -$40(a2),a2
                dbf     d0,loc_16540

loc_1657C:
                subq.w  #1,$38(a0)
                bne.s   locret_16586

loc_16582:
                bsr.w   sub_11118

locret_16586:
                rts

dword_16588:    dc.l $100, $200, $300, $400, $500, $800, $1000, $2000, $3000
byte_165AC:     dc.b 0, 1
                dc.w byte_165B0-sub_10000
byte_165B0:     dc.b 4, 5
                dc.w word_1A8D8-sub_10000
                dc.w word_1A8E0-sub_10000
                dc.w word_1A8E8-sub_10000
                dc.w word_1A8F0-sub_10000
sub_165BA:
                bset    #7,(a0)
                bne.s   loc_165F0
                move.w  #$140,$30(a0)
                bclr    #7,2(a0)
                tst.b   $16(a0)
                beq.s   loc_165DE
                move.w  #$C0,$30(a0)
                bset    #7,2(a0)

loc_165DE:
                move.w  #$150,$24(a0)
                move.l  #off_1669A,8(a0)
                clr.w   6(a0)

loc_165F0:
                tst.b   (byte_FFD27B).w
                bne.s   locret_165FE
                bsr.w   sub_1105C
                bsr.w   sub_11126

locret_165FE:
                rts

sub_16600:
                bset    #7,(a0)
                bne.s   loc_16638
                move.w  #$130,$30(a0)
                bclr    #7,2(a0)
                tst.b   $16(a0)
                beq.s   loc_16624
                move.w  #$D0,$30(a0)
                bset    #7,2(a0)

loc_16624:
                move.w  #$150,$24(a0)
                move.l  #off_1669A,8(a0)
                move.w  #4,6(a0)

loc_16638:
                tst.b   (byte_FFD27B).w
                bne.s   locret_16646
                bsr.w   sub_1105C
                bsr.w   sub_11126

locret_16646:
                rts

sub_16648:
                lea     (unk_FFC580).w,a1
                move.l  dword_FFC5B0-unk_FFC580(a1),d7
                move.l  $24(a1),d6
                move.l  d7,$30(a0)
                move.l  d6,$24(a0)
                addi.w  #$A,$24(a0)
                tst.b   $39(a1)
                beq.s   loc_16674
                bclr    #7,2(a0)
                subq.w  #8,$30(a0)
                bra.s   loc_1667E

loc_16674:
                bset    #7,2(a0)
                addq.w  #8,$30(a0)

loc_1667E:
                bsr.w   sub_1105C
                move.l  #word_1AAD6,$C(a0)
                tst.l   $34(a1)
                beq.s   locret_16698
                move.l  #word_1AAE4,$C(a0)

locret_16698:
                rts

off_1669A:      dc.l byte_166A2
                dc.l byte_166B4
byte_166A2:     dc.b 8, 7
                dc.w word_1AA96-sub_10000
                dc.w word_1AAA4-sub_10000
                dc.w word_1AAB2-sub_10000
                dc.w word_1AABA-sub_10000
                dc.w word_1AAC8-sub_10000
                dc.w word_1AABA-sub_10000
                dc.w word_1AAB2-sub_10000
                dc.w word_1AAA4-sub_10000
byte_166B4:     dc.b 8, 7
                dc.w word_1AA1A-sub_10000
                dc.w word_1AA2E-sub_10000
                dc.w word_1AA42-sub_10000
                dc.w word_1AA56-sub_10000
                dc.w word_1AA6A-sub_10000
                dc.w word_1AA56-sub_10000
                dc.w word_1AA42-sub_10000
                dc.w word_1AA2E-sub_10000
sub_166C6:
                bset    #7,(a0)
                bne.s   loc_166EC
                bset    #1,2(a0)
                move.l  #off_14E12,8(a0)
                movea.l (dword_FFD282).w,a1
                moveq   #0,d0
                move.b  $38(a0),d0
                lsl.w   #1,d0
                move.w  (a1,d0.w),$3A(a0)

loc_166EC:
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     loc_166FC(pc,d0.w)
                bsr.w   sub_11126
                rts

loc_166FC:
                bra.w   sub_16708
                bra.w   sub_16782
                bra.w   sub_167D6

sub_16708:
                tst.w   $3A(a0)
                bne.s   loc_16778
                bset    #7,$3C(a0)
                bne.s   loc_16756
                bclr    #1,2(a0)
                move.w  #4,6(a0)
                move.w  #$150,$24(a0)
                move.w  #$80,$30(a0)
                move.l  #$8000,$34(a0)
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   loc_16756
                move.w  #$17F,$30(a0)
                move.l  #$FFFF8000,$34(a0)
                bset    #7,2(a0)

loc_16756:
                bsr.w   sub_1105C
                lea     (unk_FFC640).w,a1
                tst.b   $39(a0)
                bne.s   loc_16768
                lea     $40(a1),a1

loc_16768:
                bsr.w   sub_117C0
                tst.b   d0
                beq.s   locret_16776
                move.w  #4,$3C(a0)

locret_16776:
                rts

loc_16778:
                subq.w  #1,$3A(a0)
                bsr.w   sub_1105C
                rts

sub_16782:
                bset    #7,$3C(a0)
                bne.s   loc_167B8
                movea.l (dword_FFD286).w,a1
                moveq   #0,d0
                move.b  $38(a0),d0
                lsl.w   #1,d0
                move.b  (a1,d0.w),d7
                move.b  1(a1,d0.w),d6
                ext.w   d7
                ext.l   d7
                ext.w   d6
                ext.l   d6
                moveq   #$C,d0
                lsl.l   d0,d7
                lsl.l   d0,d6
                move.l  d7,$34(a0)
                move.l  d6,$2C(a0)
                bsr.w   sub_16892

loc_167B8:
                addi.l  #$1000,$2C(a0)
                bne.s   loc_167C8
                move.w  #8,$3C(a0)

loc_167C8:
                bsr.w   sub_16854
                bsr.w   sub_1105C
                bsr.w   sub_11126
                rts

sub_167D6:
                bset    #7,$3C(a0)
                bne.s   loc_16806
                clr.w   6(a0)
                move.l  $34(a0),d7
                bpl.s   loc_167F0
                neg.l   d7
                lsr.l   #1,d7
                neg.l   d7
                bra.s   loc_167F2

loc_167F0:
                lsr.l   #1,d7

loc_167F2:
                move.l  d7,$34(a0)
                cmpi.w  #$FFFF,$3A(a0)
                beq.s   loc_16806
                addq.b  #1,$3E(a0)
                bsr.w   sub_16892

loc_16806:
                cmpi.l  #$18000,$2C(a0)
                bgt.s   loc_16818
                addi.l  #$400,$2C(a0)

loc_16818:
                bsr.w   sub_16854
                bsr.w   sub_1105C
                bsr.w   sub_168E2
                cmpi.w  #$180,$24(a0)
                bcs.s   loc_16834
                bsr.w   sub_110F0
                subq.b  #1,(byte_FFD883).w

loc_16834:
                bsr.w   sub_11126
                tst.b   (byte_FFD883).w
                bne.s   locret_16852
                clr.w   (word_FFFF92).w
                move.b  #1,(byte_FFD281).w
                move.w  #4,(word_FFD2A6).w
                bsr.w   sub_16988

locret_16852:
                rts

sub_16854:
                move.w  $3A(a0),d0
                cmpi.w  #$FFFF,d0
                beq.s   locret_16890
                subq.w  #1,d0
                bne.s   loc_1686C
                addq.b  #1,$3E(a0)
                bsr.w   sub_16892
                bra.s   sub_16854

loc_1686C:
                move.w  d0,$3A(a0)
                move.l  $34(a0),d7
                move.l  $1C(a0),d6
                bmi.s   loc_16884
                cmp.l   d6,d7
                bge.s   loc_16882
                add.l   $18(a0),d7

loc_16882:
                bra.s   loc_1688C

loc_16884:
                cmp.l   d6,d7
                ble.s   loc_1688C
                add.l   $18(a0),d7

loc_1688C:
                move.l  d7,$34(a0)

locret_16890:
                rts

sub_16892:
                moveq   #0,d0
                move.b  $38(a0),d0
                movea.l (dword_FFD28A).w,a1
                move.b  (a1,d0.w),d0
                lsl.w   #2,d0
                lea     off_16D18(pc),a1
                movea.l (a1,d0.w),a1
                moveq   #0,d0
                move.b  $3E(a0),d0
                lsl.w   #2,d0
                move.w  (a1,d0.w),$3A(a0)
                move.b  2(a1,d0.w),d7
                move.b  3(a1,d0.w),d6
                ext.w   d7
                ext.l   d7
                ext.w   d6
                ext.l   d6
                lsl.l   #8,d7
                moveq   #$C,d0
                lsl.l   d0,d6
                tst.b   $39(a0)
                beq.s   loc_168D8
                neg.l   d7
                neg.l   d6

loc_168D8:
                move.l  d7,$18(a0)
                move.l  d6,$1C(a0)
                rts

sub_168E2:
                lea     (word_FFC040).w,a1
                bsr.w   sub_117C0
                tst.b   d0
                beq.s   locret_1691A
                move.l  a0,-(sp)
                move.b  #$90,d0
                bsr.w   sub_10D48
                movea.l (sp)+,a0
                bsr.w   sub_110F0
                subq.b  #1,(byte_FFD883).w
                addq.b  #1,(byte_FFD28E).w
                moveq   #1,d0
                move.b  (byte_FFD28F).w,d1
                addi.b  #0,d1
                abcd    d0,d1
                move.b  d1,(byte_FFD28F).w
                bsr.w   sub_169D4

locret_1691A:
                rts

sub_1691C:
                tst.b   (byte_FFD28E).w
                beq.s   loc_16944
                lea     byte_1694C(pc),a6
                bsr.w   sub_10FAA
                cmpi.b  #$14,(byte_FFD28E).w
                bne.s   locret_16942
                lea     byte_16964(pc),a6
                bsr.w   sub_10FAA
                lea     byte_16974(pc),a6
                bsr.w   sub_10FAA

locret_16942:
                rts

loc_16944:
                lea     byte_1697C(pc),a6
                bra.w   sub_10FAA

byte_1694C:     dc.b $C2, $4E
a250PtsPts:     dc.b "; 250 PTS.=      PTS.",0
byte_16964:     dc.b $C3, $12
aPerfectBonus:  dc.b "PERFECT BONUS",0
byte_16974:     dc.b $C3, $A2
aPts_0:         dc.b "PTS.",0
                dc.b 0
byte_1697C:     dc.b $C3, $16
aNoBonus_0:     dc.b "NO BONUS",0
                dc.b 0
sub_16988:
                moveq   #0,d0
                move.b  (byte_FFD28E).w,d0
                beq.s   locret_169D2
                subq.w  #1,d0

loc_16992:
                move.l  #$250,(dword_FFD262).w
                lea     (byte_FFD266).w,a2
                lea     (word_FFD294).w,a1
                moveq   #3,d1
                move    #4,ccr

loc_169A8:
                abcd    -(a2),-(a1)
                dbf     d1,loc_169A8
                dbf     d0,loc_16992
                move.l  (dword_FFD290).w,d0
                move.l  d0,(dword_FFD262).w
                bsr.w   sub_1168A
                cmpi.b  #$14,(byte_FFD28E).w
                bne.s   locret_169D2
                move.l  #$10000,(dword_FFD262).w
                bsr.w   sub_1168A

locret_169D2:
                rts

sub_169D4:
                moveq   #0,d0
                move.b  (byte_FFD28E).w,d0
                subq.w  #1,d0
                move.l  #$414C0003,(VDP_CTRL).l

loc_169E6:
                move.w  #$E351,(VDP_DATA).l
                dbf     d0,loc_169E6
                rts

off_169F4:      dc.l word_16A24
                dc.l word_16A24
                dc.l word_16A24
                dc.l word_16A4C
                dc.l word_16A74
                dc.l word_16A74
                dc.l word_16A74
                dc.l word_16A74
                dc.l word_16A74
                dc.l word_16A74
                dc.l word_16A74
                dc.l word_16A74
word_16A24:     dc.w 0, $F, $1E, $2D, $6E, $7D, $8C, $9B, $DC, $EB
                dc.w $FA, $109, $14A, $159, $168, $177, $1B8, $1C7, $1D6, $1E5
word_16A4C:     dc.w $1E, $2D, $3C, $4B, 0, $F, $1E, $2D, $FA, $109
                dc.w $118, $127, $DC, $EB, $FA, $109, $1B8, $1C7, $1D6, $1E5
word_16A74:     dc.w 0, $F, $1E, $2D, $64, $73, $82, $91, $C8, $D7
                dc.w $E6, $F5, $12C, $13B, $14A, $159, $190, $19F, $1AE, $1BD
off_16A9C:      dc.l word_16ACC
                dc.l word_16AF4
                dc.l word_16B1C
                dc.l word_16B44
                dc.l word_16B6C
                dc.l word_16B94
                dc.l word_16BBC
                dc.l word_16B94
                dc.l word_16ACC
                dc.l word_16BE4
                dc.l word_16C0C
                dc.l word_16B94
word_16ACC:     dc.w $EB4, $EB4, $EB4, $EB4, $F2B4, $F2B4, $F2B4, $F2B4, $EB4, $EB4
                dc.w $EB4, $EB4, $F2B4, $F2B4, $F2B4, $F2B4, $EB4, $EB4, $EB4, $EB4
word_16AF4:     dc.w $EB4, $CB4, $AB4, $8B4, $F2B4, $F4B4, $F6B4, $F8B4, $EB4, $CB4
                dc.w $AB4, $8B4, $F2B4, $F4B4, $F6B4, $F8B4, $EB4, $CB4, $AB4, $8B4
word_16B1C:     dc.w $EB4, $EB8, $EBC, $EC0, $F2B4, $F2B8, $F2BC, $F2C0, $EB4, $EB8
                dc.w $EBC, $EC0, $F2B4, $F2B8, $F2BC, $F2C0, $EB4, $EB8, $EBC, $EC0
word_16B44:     dc.w $AB4, $AB4, $AB4, $AB4, $F6B4, $F6B4, $F6B4, $F6B4, $AB4, $AB4
                dc.w $AB4, $AB4, $F6B4, $F6B4, $F6B4, $F6B4, $5B4, $8B4, $BB4, $EB4
word_16B6C:     dc.w $22B4, $22B4, $22B4, $22B4, $DEB4, $DEB4, $DEB4, $DEB4, $22B4, $22B4
                dc.w $22B4, $22B4, $DEB4, $DEB4, $DEB4, $DEB4, $22B4, $22B4, $22B4, $22B4
word_16B94:     dc.w $9B4, $9B4, $9B4, $9B4, $F7B4, $F7B4, $F7B4, $F7B4, $9B4, $9B4
                dc.w $9B4, $9B4, $F7B4, $F7B4, $F7B4, $F7B4, $9B4, $9B4, $9B4, $9B4
word_16BBC:     dc.w $12B4, $12B4, $12B4, $12B4, $EEB4, $EEB4, $EEB4, $EEB4, $12B4, $12B4
                dc.w $12B4, $12B4, $EEB4, $EEB4, $EEB4, $EEB4, $12B4, $12B4, $12B4, $12B4
word_16BE4:     dc.w $E0B4, $E0B4, $E0B4, $E0B4, $20B4, $20B4, $20B4, $20B4, $E0B4, $E0B4
                dc.w $E0B4, $E0B4, $20B4, $20B4, $20B4, $20B4, $E0B4, $E0B4, $E0B4, $E0B4
word_16C0C:     dc.w $40B4, $40B4, $40B4, $40B4, $C0B4, $C0B4, $C0B4, $C0B4, $40B4, $40B4
                dc.w $40B4, $40B4, $C0B4, $C0B4, $C0B4, $C0B4, $40B4, $40B4, $40B4, $40B4
off_16C34:      dc.l word_16C64
                dc.l word_16C64
                dc.l word_16C64
                dc.l word_16C64
                dc.l word_16C78
                dc.l word_16C8C
                dc.l word_16CA0
                dc.l word_16CB4
                dc.l word_16CC8
                dc.l word_16CDC
                dc.l word_16CF0
                dc.l word_16D04
word_16C64:     dc.w 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
word_16C78:     dc.w $101, $101, $101, $101, $101, $101, $101, $101, $101, $101
word_16C8C:     dc.w $202, $202, $202, $202, $202, $202, $202, $202, $202, $202
word_16CA0:     dc.w $303, $303, $303, $303, $303, $303, $303, $303, $303, $303
word_16CB4:     dc.w $404, $404, $404, $404, $404, $404, $404, $404, $404, $404
word_16CC8:     dc.w $505, $505, $505, $505, $505, $505, $505, $505, $505, $505
word_16CDC:     dc.w $606, $606, $606, $606, $606, $606, $606, $606, $606, $606
word_16CF0:     dc.w $707, $707, $707, $707, $707, $707, $707, $707, $707, $707
word_16D04:     dc.w $808, $808, $808, $808, $808, $808, $808, $808, $808, $808
off_16D18:      dc.l word_16D3C
                dc.l word_16D3E
                dc.l word_16D48
                dc.l word_16D5A
                dc.l word_16D68
                dc.l word_16D7A
                dc.l word_16D8C
                dc.l word_16D92
                dc.l word_16DA0
word_16D3C:     dc.w $FFFF
word_16D3E:     dc.w $12C, $F4E8, $12C, $310, $FFFF
word_16D48:     dc.w $12C, $FEF8, $14, $C10, $40, $FAF0, $12C, $610, $FFFF
word_16D5A:     dc.w $12C, 0, $58, 0, $12C, $C0DE, $FFFF
word_16D68:     dc.w $12C, $FEF8, $30, $1220, $3A, $EEE0, $12C, $620, $FFFF
word_16D7A:     dc.w $12C, 0, $32, 0, $18, $E4E0, $12C, $1C0C, $FFFF
word_16D8C:     dc.w $12C, $D1C, $FFFF
word_16D92:     dc.w $12C, $F2E0, $28, $FCE0, $12C, $320, $FFFF
word_16DA0:     dc.w $12C, $FEF8, $12C, $320, $FFFF
sub_16DAA:
                bset    #7,(a0)
                bne.s   locret_16DCA
                move.w  #$D8,$20(a0)
                move.w  #$118,$24(a0)
                move.l  #word_1ACA4,$C(a0)
                move.b  #1,(byte_FFD27B).w

locret_16DCA:
                rts

sub_16DCC:
                bset    #7,(a0)
                bne.s   locret_16DE6
                move.l  #word_1AD32,$C(a0)
                move.w  #$F0,$20(a0)
                move.w  #$108,$24(a0)

locret_16DE6:
                nop
                rts

word_16DE8:     binclude "data/palettes/shared-compact.bin"
LevelTiles:     binclude "data/artnem/data_LevelTiles.bin",$0,$17A4
Latin1BPPTiles: binclude "data/artunc/data_Latin1BPPTiles.bin",$0,$158
ExitTiles:      binclude "data/artnem/data_ExitTiles.bin",$0,$80
SpritesTiles:   binclude "data/artnem/data_SpritesTiles.bin",$0,$116A
ScoresTiles:    binclude "data/artnem/data_ScoresTiles.bin",$0,$5B0
FlickyLogoTiles: binclude "data/artnem/data_FlickyLogoTiles.bin",$0,$2A8
byte_1A196:     dc.b $22, 0
byte_1A198:     dc.b $22, 1
byte_1A19A:     dc.b $22, 2
byte_1A19C:     dc.b $22, 3
byte_1A19E:     dc.b $22, 4
byte_1A1A0:     dc.b 0, 0
word_1A1A2:     dc.w $222B, $222C, $222D, $222E, $222F, $2230, $2231, $2232
word_1A1B2:     dc.w $2233, $2234, $2235, $2236, $2237, $2238, $2239, $223A
word_1A1C2:     dc.w $223B, $223C, $223D, $223E, $223F, $2240, $2241, $2242
word_1A1D2:     dc.w $2243, $2244, $2245, $2246, $2247, $2248, $2249, $224A
word_1A1E2:     dc.w $224B, $224C, $224D, $224E, $224F, $2250, $2251, $2252
word_1A1F2:     dc.w $2253, $2205, $2205, $2205, $2254, $2255, $2256, $2257
word_1A202:     dc.w $2258, $2258, $2258, $2258, $2258, $2258, $2258, $2258
word_1A212:     dc.w $2259, $225A, $225B, $225C, $225D, $225E, $225F, $2260
word_1A222:     dc.w $2261, $2262, $2263, $2264, $2265, $2240, $2241, $2266
word_1A232:     dc.w $2267, $2268, $2269, $226A, $226B, $226C, $226D, $226E
word_1A242:     dc.w $226F, $2270, $2271, $2272, $2273, $2274, $2275, $2276
word_1A252:     dc.w $2277, $2277, $2277, $2277, $2278, $2279, $227A, $227B
word_1A262:     dc.w $29E, $29F, $2A0
word_1A268:     dc.w $2A1, $2A2, $2A3
word_1A26E:     dc.w $2A4, $2A5, $2A6
word_1A274:     dc.w $62A7, $62A8, $62A9, $62AA, $62AB, $62AC, $62AD, $62AE, $62AF
word_1A286:     dc.w $62B0, $62B1, $62B2, $62B3, $62B4, $62B5
word_1A292:     dc.w $629A, $629B, $629C, $629D
word_1A29A:     dc.w $627C, $627D, $627E, $627F, $6280, $6281
word_1A2A6:     dc.w $6282, $6283, $6284, $6285, $6286, $6287
word_1A2B2:     dc.w $6288, $6289, $628A, $628B, $628C, $628D
word_1A2BE:     dc.w $628E, $628F, $6290, $6291, $6292, $6293
word_1A2CA:     dc.w $6294, $6295, $6296, $6297, $6298, $6299
word_1A2D6:     dc.w $2200, $2215, $2216, $2217, $2218, $2217, $2216, $2217
word_1A2E6:     dc.w $2201, $2219, $221A, $221B, $221C, $221B, $221A, $221B
word_1A2F6:     dc.w $2202, $221D, $221E, $221F, $2220, $221F, $221E, $221F
word_1A306:     dc.w $2203, $2221, $2222, $2223, $2224, $2223, $2222, $2223
word_1A316:     dc.w $2204, $2225, $2226, $2227, $2228, $2227, $2226, $2227
word_1A326:     dc.w $2205, $2229, $2205, $2205, $222A, $2205, $2205, $2205
word_1A336:     dc.w $2B6, $2B7, $2B8, $2B9, $2BA, $2BB, $2BC, $2BD
                dc.w $2BE, $2BF, $2C0, $2C1, $2C2, $2C3, $2C4
word_1A354:     dc.w $2C5, $2C6, $2C7, $205, $2C8, $2C9, $2CA, $2CB
                dc.w $2CC, $2CD, $2CE, $2CF, $2D0, $2D1, $2D2, $2D3
word_1A374:     dc.w $205, $205, $2D4, $2D5, $2D6, $2D7, $2D8, $2D9
                dc.w $2DA, $2DB, $2DC, $2DD, $2DE, $205, $205
word_1A392:     dc.w $2DF, $2E0, $2E1, $205, $2E2, $2E3, $2E4, $205
                dc.w $2E5, $2E6, $2E7, $205, $205, $205, $205, $205
word_1A3B2:     dc.w $2E8, $2E9, $2EA, $205, $2EB, $2EC, $2ED, $205
                dc.w $2EE, $2EF, $2F0, $205, $205, $205, $205, $205
word_1A3D2:     dc.w $2F1, $2F2, $2F3, $2F4, $2F5, $2F6, $2F7, $2F8
                dc.w $2F9, $2FA, $205, $205, $205, $205, $205
word_1A3F0:     dc.w $2FB, $2FC, $2FD, $2FE, $2FF, $300, $301, $302
                dc.w $303, $304, $305, $306, $307, $308, $309, $30A
word_1A410:     dc.w $30B, $30C, $30D, $30E, $30F, $310, $311, $312
                dc.w $313, $314, $315, $316, $317, $318, $319
word_1A42E:     dc.w $31A, $31B, $31C, $31D, $31E, $31F, $320, $321
                dc.w $322, $323, $324, $325, $326, $327, $328, $329
word_1A44E:     dc.w $32A, $32A, $32A, 0, 0, 0, $32A, $32A
                dc.w $32A, $32A, $32A, $32A, $32A, $32A, 0
word_1A46C:     dc.w $632B, $632C, $632D, $632E, $632F, $6330, $6331, $6332, $6333
word_1A47E:     dc.w $6334, $6335, $6336, $6337, $6335, $6338, $6339, $6335, $633A
word_1A490:     dc.w $633B, $6205, $633C, $633D, $6205, $633E, $633F, $6205, $6340
word_1A4A2:     dc.w $6341, $6205, $6342, $6343, $6205, $6344, $6345, $6205, $6346
word_1A4B4:     dc.w $347, $348, $349, $34A, $34B, $34C, $34D, $34E, $34F, $351, $4350
word_1A4CA:     dc.w $8352, $8353, $8354, $8353
word_1A4D2:     dc.w $8355, $8356, $8353, 0, 0, $2A, $F8, 0, 0, $300, $F8
word_1A4E8:     dc.w 4, $F804, $6456, $F8F8
word_1A4F0:     dc.w 4, $F804, $7456, $F8F8
word_1A4F8:     dc.w 4, $F401, $6458, $FCFC
word_1A500:     dc.w 4, $F401, $6C58, $FCFC
word_1A508:     dc.w 4, $F401, $7458, $FCFC
word_1A510:     dc.w 4, $F401, $7C58, $FCFC
word_1A518:     dc.w 4, $F804, $645A, $F8F8
word_1A520:     dc.w 4, $F804, $745A, $F8F8
word_1A528:     dc.w 4, $F401, $645C, $FCFC
word_1A530:     dc.w 4, $F401, $6C5C, $FCFC
word_1A538:     dc.w 4, $F401, $745C, $FCFC
word_1A540:     dc.w 4, $F401, $7C5C, $FCFC
word_1A548:     dc.w 4, $F804, $645E, $F8F8
word_1A550:     dc.w 4, $F804, $745E, $F8F8
word_1A558:     dc.w 4, $F401, $6460, $FCFC
word_1A560:     dc.w 4, $F401, $6C60, $FCFC
word_1A568:     dc.w 4, $F401, $7460, $FCFC
word_1A570:     dc.w 4, $F401, $7C60, $FCFC
word_1A578:     dc.w 4, $F804, $6462, $F8F8
word_1A580:     dc.w 4, $F804, $7462, $F8F8
word_1A588:     dc.w 4, $F401, $6464, $FCFC
word_1A590:     dc.w 4, $F401, $6C64, $FCFC
word_1A598:     dc.w 4, $F401, $7464, $FCFC
word_1A5A0:     dc.w 4, $F401, $7C64, $FCFC
word_1A5A8:     dc.w 4, $F804, $6466, $F8F8
word_1A5B0:     dc.w 4, $F804, $7466, $F8F8
word_1A5B8:     dc.w 4, $F401, $6468, $FCFC
word_1A5C0:     dc.w 4, $F401, $6C68, $FCFC
word_1A5C8:     dc.w 4, $F401, $7468, $FCFC
word_1A5D0:     dc.w 4, $F401, $7C68, $FCFC
word_1A5D8:     dc.w 4, $F804, $646A, $F8F8
word_1A5E0:     dc.w 4, $F804, $746A, $F8F8
word_1A5E8:     dc.w 4, $F401, $646C, $FCFC
word_1A5F0:     dc.w 4, $F401, $6C6C, $FCFC
word_1A5F8:     dc.w 4, $F401, $746C, $FCFC
word_1A600:     dc.w 4, $F401, $7C6C, $FCFC
word_1A608:     dc.w 4, $F804, $646E, $F8F8
word_1A610:     dc.w 4, $F804, $746E, $F8F8
word_1A618:     dc.w 4, $F401, $6470, $FCFC
word_1A620:     dc.w 4, $F401, $6C70, $FCFC
word_1A628:     dc.w 4, $F401, $7470, $FCFC
word_1A630:     dc.w 4, $F401, $7C70, $FCFC
word_1A638:     dc.w 4, $F804, $6472, $F8F8
word_1A640:     dc.w 4, $F804, $7472, $F8F8
word_1A648:     dc.w 4, $F401, $6474, $FCFC
word_1A650:     dc.w 4, $F401, $6C74, $FCFC
word_1A658:     dc.w 4, $F401, $7474, $FCFC
word_1A660:     dc.w 4, $F401, $7C74, $FCFC
word_1A668:     dc.w 4, $F804, $6476, $F8F8
word_1A670:     dc.w 4, $F804, $7476, $F8F8
word_1A678:     dc.w 4, $F401, $6478, $FCFC
word_1A680:     dc.w 4, $F401, $6C78, $FCFC
word_1A688:     dc.w 4, $F401, $7478, $FCFC
word_1A690:     dc.w 4, $F401, $7C78, $FCFC
word_1A698:     dc.w 4, $F804, $647A, $F8F8
word_1A6A0:     dc.w 4, $F804, $747A, $F8F8
word_1A6A8:     dc.w 4, $F401, $647C, $FCFC
word_1A6B0:     dc.w 4, $F401, $6C7C, $FCFC
word_1A6B8:     dc.w 4, $F401, $747C, $FCFC
word_1A6C0:     dc.w 4, $F401, $7C7C, $FCFC
word_1A6C8:     dc.w 4, $F804, $647E, $F8F8
word_1A6D0:     dc.w 4, $F804, $747E, $F8F8
word_1A6D8:     dc.w 4, $F401, $6480, $FCFC
word_1A6E0:     dc.w 4, $F401, $6C80, $FCFC
word_1A6E8:     dc.w 4, $F401, $7480, $FCFC
word_1A6F0:     dc.w 4, $F401, $7C80, $FCFC
word_1A6F8:     dc.w 4, $F804, $6482, $F8F8
word_1A700:     dc.w 4, $F804, $7482, $F8F8
word_1A708:     dc.w 4, $F401, $6484, $FCFC
word_1A710:     dc.w 4, $F401, $6C84, $FCFC
word_1A718:     dc.w 4, $F401, $7484, $FCFC
word_1A720:     dc.w 4, $F401, $7C84, $FCFC
word_1A728:     dc.w 4, $F804, $6486, $F8F8
word_1A730:     dc.w 4, $F804, $7486, $F8F8
word_1A738:     dc.w 4, $F401, $6488, $FCFC
word_1A740:     dc.w 4, $F401, $6C88, $FCFC
word_1A748:     dc.w 4, $F401, $7488, $FCFC
word_1A750:     dc.w 4, $F401, $7C88, $FCFC
word_1A758:     dc.w 4, $F804, $648A, $F8F8
word_1A760:     dc.w 4, $F804, $748A, $F8F8
word_1A768:     dc.w 4, $F401, $648C, $FCFC
word_1A770:     dc.w 4, $F401, $6C8C, $FCFC
word_1A778:     dc.w 4, $F401, $748C, $FCFC
word_1A780:     dc.w 4, $F401, $7C8C, $FCFC
word_1A788:     dc.w 4, $F804, $648E, $F8F8
word_1A790:     dc.w 4, $F804, $748E, $F8F8
word_1A798:     dc.w 4, $F401, $6490, $FCFC
word_1A7A0:     dc.w 4, $F401, $6C90, $FCFC
word_1A7A8:     dc.w 4, $F401, $7490, $FCFC
word_1A7B0:     dc.w 4, $F401, $7C90, $FCFC
word_1A7B8:     dc.w 3, $F005, $4436, $F8F8
word_1A7C0:     dc.w 3, $F005, $443A, $F8F8
word_1A7C8:     dc.w 3, $F005, $4C36, $F8F8
word_1A7D0:     dc.w 3, $F005, $4C3A, $F8F8
word_1A7D8:     dc.w 6, $F005, $443E, $F8F8
word_1A7E0:     dc.w 6, $F005, $4442, $F8F8
word_1A7E8:     dc.w 6, $F005, $4446, $F8F8
word_1A7F0:     dc.w 6, $F005, $444A, $F8F8
word_1A7F8:     dc.w 6, $F005, $444E, $F8F8
word_1A800:     dc.w 6, $F001, $4452, $FCFC
word_1A808:     dc.w 6, $F001, $4454, $FCFC
word_1A810:     dc.w 6, $F001, $4C52, $FCFC
word_1A818:     dc.w 3, $F005, $4492, $F8F8
word_1A820:     dc.w 3, $F005, $4496, $F8F8
word_1A828:     dc.w 3, $F005, $4C92, $F8F8
word_1A830:     dc.w 3, $F005, $4C96, $F8F8
word_1A838:     dc.w 6, $F005, $449A, $F8F8
word_1A840:     dc.w 6, $F005, $449E, $F8F8
word_1A848:     dc.w 6, $F005, $44A2, $F8F8
word_1A850:     dc.w 6, $F005, $44A6, $F8F8
word_1A858:     dc.w 6, $F005, $44AA, $F8F8
word_1A860:     dc.w 6, $F001, $44AE, $FCFC
word_1A868:     dc.w 6, $F001, $44B0, $FCFC
word_1A870:     dc.w 6, $F001, $4CAE, $FCFC
word_1A878:     dc.w $FF, $F005, $4400, $F8F8
word_1A880:     dc.w $FF, $F005, $4404, $F8F8
byte_1A888:     dc.b 0, $FF, $F0, 5, $44, 8, $F8, $F8
word_1A890:     dc.w $FF, $F005, $440C, $F8F8
word_1A898:     dc.w 0, $E806, $4410, $F8F8
word_1A8A0:     dc.w 1, $F005, $4416, $F8F8
byte_1A8A8:     dc.b 0, 0
                dc.w $E806, $441A, $F8F8
byte_1A8B0:     dc.b 0, 0
                dc.w $E806, $4420, $F8F8
byte_1A8B8:     dc.b 0, 1
                dc.w $F005, $4426, $F8F8
byte_1A8C0:     dc.b 0, 1
                dc.w $F005, $442A, $F8F8
byte_1A8C8:     dc.b 0, 2
                dc.w $F005, $442E, $F8F8
word_1A8D0:     dc.w 2, $F005, $4432, $F8F8
word_1A8D8:     dc.w 7, $F800, $4B2, $FCFC
word_1A8E0:     dc.w 7, $F800, $4B3, $FCFC
word_1A8E8:     dc.w 7, $F800, $4B4, $FCFC
word_1A8F0:     dc.w 7, $F800, $686, $FCFC
word_1A8F8:     dc.w 8, $F005, $44B5, $F8F8
word_1A900:     dc.w 8, $F005, $44B9, $F8F8
word_1A908:     dc.w 8, $F005, $44BD, $F8F8
word_1A910:     dc.w 8, $F005, $44C1, $F8F8
word_1A918:     dc.w $105, $E802, $44C5, $FCFC, $F001, $44C8, $F404
word_1A926:     dc.w $205, $E802, $44CA, $FCFC, $F001, $44CD, $F404, $F000, $44CF, $4F4
word_1A93A:     dc.w $205, $E802, $44D0, $FCFC, $F000, $44D3, $4F4, $F800, $44D4, $F404
word_1A94E:     dc.w $105, $E806, $44D5, $FCF4, $F800, $44DB, $F404
word_1A95C:     dc.w $205, $E802, $44DC, $FCFC, $F001, $44DF, $4F4, $F800, $44E1, $F404
word_1A970:     dc.w $112, $EB06, $44E2, $FCF4, $FB00, $44E8, $F404
word_1A97E:     dc.w $212, $EB05, $44E9, $FCF4, $F301, $44ED, $F404, $FB00, $44EF, $FCFC
word_1A992:     dc.w $FF, $E806, $44F0, $F8F8
word_1A99A:     dc.w $2FF, $EE05, $44F6, $FAF6, $F600, $44FA, $F206, $FE00, $44FB, $FAFE
word_1A9AE:     dc.w $FF, $F409, $44FC, $F4F4
word_1A9B6:     dc.w $2FF, $E802, $4502, $FAFE, $F000, $54FA, $F206, $F001, $54F8, $2F6
word_1A9CA:     dc.w $FF, $EB06, $54F0, $F8F8
word_1A9D2:     dc.w $2FF, $E802, $4D02, $FEFA, $F001, $5CF8, $F602, $F000, $5CFA, $6F2
word_1A9E6:     dc.w $FF, $F409, $4CFC, $F4F4
word_1A9EE:     dc.w $2FF, $EE05, $4CF6, $F6FA, $F600, $4CFA, $6F2, $FE00, $4CFB, $FEFA
word_1AA02:     dc.w 5, $E806, $4505, $F8F8
word_1AA0A:     dc.w 5, $E806, $44F0, $F8F8
word_1AA12:     dc.w 5, $E806, $4D05, $F8F8
word_1AA1A:     dc.w $205, $DC02, $44CA, $FCFC, $E401, $44CD, $F404, $E400, $44CF, $4F4
word_1AA2E:     dc.w $205, $DE02, $44CA, $FCFC, $E601, $44CD, $F404, $E600, $44CF, $4F4
word_1AA42:     dc.w $205, $E402, $44CA, $FCFC, $EC01, $44CD, $F404, $EC00, $44CF, $4F4
word_1AA56:     dc.w $205, $E802, $44D0, $FCFC, $F000, $44D3, $4F4, $F800, $44D4, $F404
word_1AA6A:     dc.w $205, $EA02, $44D0, $FCFC, $F200, $44D3, $4F4, $FA00, $44D4, $F404
word_1AA7E:     dc.w $FF, $F800, $450B, $FCFC
word_1AA86:     dc.w $FF, $F800, $450C, $FCFC
word_1AA8E:     dc.w $FF, $F800, $450D, $FCFC
word_1AA96:     dc.w $110, $F008, $650E, $F0F8, $F808, $6511, $F8F0
word_1AAA4:     dc.w $110, $F008, $6514, $F0F8, $F808, $6517, $F8F0
word_1AAB2:     dc.w $10, $F00D, $651A, $F0F0
word_1AABA:     dc.w $110, $F008, $6D14, $F8F0, $F808, $6D17, $F0F8
word_1AAC8:     dc.w $110, $F008, $6D0E, $F8F0, $F808, $6D11, $F0F8
word_1AAD6:     dc.w $111, $F004, $522, $F8F8, $F800, $524, $F800
word_1AAE4:     dc.w $11, $F005, $525, $F8F8
word_1AAEC:     dc.w 0, $F300, $529, $FDFB
word_1AAF4:     dc.w 0, $F300, $52A, $FDFB
word_1AAFC:     dc.w 0, $F300, $52B, $FDFB
word_1AB04:     dc.w 0, $F300, $52B, $FDFB
word_1AB0C:     dc.w 0, $F300, $52C, $FDFB
word_1AB14:     dc.w 0, $F300, $52D, $FDFB
word_1AB1C:     dc.w 0, $F300, $52E, $FDFB
word_1AB24:     dc.w $FF, $F808, $640, $F4F4
byte_1AB2C:     dc.b 0, $FF, $F8, 8, 6, $43, $F4, $F4
word_1AB34:     dc.w $FF, $F808, $646, $F4F4
word_1AB3C:     dc.w $FF, $F808, $649, $F4F4
word_1AB44:     dc.w $FF, $F808, $64C, $F4F4
word_1AB4C:     dc.w $FF, $F808, $64F, $F4F4
word_1AB54:     dc.w $FF, $F808, $652, $F2F6
word_1AB5C:     dc.w $FF, $F808, $655, $F2F6
word_1AB64:     dc.w $FF, $F808, $658, $F2F6
word_1AB6C:     dc.w $FF, $F808, $65B, $F2F6
word_1AB74:     dc.w 9, $F001, $465E, $FCFC
word_1AB7C:     dc.w $A, $F804, $4660, $F8F8
word_1AB84:     dc.w $A, $F804, $4662, $F8F8
word_1AB8C:     dc.w $A, $F804, $4664, $F8F8
word_1AB94:     dc.w $B, 4, $4666, $F8F8
word_1AB9C:     dc.w $B, 4, $4668, $F8F8
word_1ABA4:     dc.w $B, 4, $466A, $F8F8
word_1ABAC:     dc.w $C, $F801, $466C, $F800
word_1ABB4:     dc.w $C, $F801, $466E, $F800
word_1ABBC:     dc.w $D, $F801, $566C, $F800
word_1ABC4:     dc.w $D, $F801, $566E, $F800
word_1ABCC:     dc.w $1FF, $F001, $4670, $F800, $F800, $4672, $F008
word_1ABDA:     dc.w $1FF, 4, $4673, $F000, $800, $4675, $F800
word_1ABE8:     dc.w $1FF, 4, $4676, $F0, $800, $5E70, $F8
word_1ABF6:     dc.w $1FF, $F001, $4678, $F8, $F800, $5E73, $8F0
word_1AC04:     dc.w $1FF, $F804, $467A, $F8F8, 0, $467C, $F8
word_1AC12:     dc.w $1FF, $F801, $467D, $F8, 0, $467F, $F800
word_1AC20:     dc.w $1FF, $F801, $5E7B, $F800, 0, $5E7A, $F8
word_1AC2E:     dc.w $1FF, $F804, $4680, $F8F8
                dc.w 0, $5E7D, $F800
word_1AC3C:     dc.w $E, $F801, $4682, $FCFC
word_1AC44:     dc.w $E, $F801, $4E82, $FCFC
word_1AC4C:     dc.w 9, $F001, $4684, $FCFC
word_1AC54:     dc.w $E, $F801, $5682, $FCFC
word_1AC5C:     dc.w $E, $F801, $5E82, $FCFC
word_1AC64:     dc.w $F, 1, $5684, $FCFC
word_1AC6C:     dc.w $1FF, $F604, $467A, $F6FA, $FE00, $467C, $FEFA
word_1AC7A:     dc.w $1FF, $F001, $467D, $FCFC, $F800, $467F, $F404
word_1AC88:     dc.w $1FF, $F001, $5E7B, $FCFC, $F800, $5E7A, $4F4
word_1AC96:     dc.w $1FF, $F304, $4680, $FBF5, $FB00, $5E7D, $FBFD
word_1ACA4:     dc.w $8FF
                dc.w 0, $8047, $F8
                dc.w 0, $8041, $8F0
                dc.w 0, $804D, $10E8
                dc.w 0, $8045, $18E0
                dc.w 0, $8020, $20D8
                dc.w 0, $804F, $28D0
                dc.w 0, $8056, $30C8
                dc.w 0, $8045, $38C0
                dc.w 0, $8052, $40B8
word_1ACDC:     dc.w $DFF
                dc.w 0, $8050, $C830
                dc.w 0, $8055, $D028
                dc.w 0, $8053, $D820
                dc.w 0, $8048, $E018
                dc.w 4, $8053, $F000
                dc.w 0, $8041, $F8
                dc.w 0, $8052, $8F0
                dc.w 0, $8054, $10E8
                dc.w 0, $8042, $20D8
                dc.w 0, $8055, $28D0
                dc.w 0, $8054, $30C8
                dc.w 0, $8054, $38C0
                dc.w 0, $804F, $40B8
                dc.w 0, $804E, $48B0
word_1AD32:     dc.w $4FF
                dc.w 0, $8050, $F8
                dc.w 0, $8041, $8F0
                dc.w 0, $8055, $10E8
                dc.w 0, $8053, $18E0
                dc.w 0, $8045, $20D8
word_1AD52:     dc.w $FF, $E00B, $6740, $F4F4
word_1AD5A:     dc.w $FF, $E80A, $674C, $F4F4
word_1AD62:     dc.w $FF, $E806, $6755, $F8F8
word_1AD6A:     dc.w $FF, $E80A, $675B, $F4F4
word_1AD72:     dc.w $FF, $E80A, $6764, $F4F4
word_1AD7A:     dc.w $FF, $E00B, $676D, $F4F4
word_1AD82:     dc.w $FF, $E806, $4687, $F8F8
word_1AD8A:     dc.w $FF, $E806, $468D, $F8F8
off_1AD92:      dc.w byte_1ADF2-sub_10000
                dc.w byte_1AE40-sub_10000
                dc.w byte_1AE40-sub_10000
                dc.w byte_1AE7C-sub_10000
                dc.w byte_1AEDC-sub_10000
                dc.w byte_1AF20-sub_10000
                dc.w byte_1AF20-sub_10000
                dc.w byte_1AF6C-sub_10000
                dc.w byte_1AFBE-sub_10000
                dc.w byte_1B012-sub_10000
                dc.w byte_1B012-sub_10000
                dc.w byte_1B070-sub_10000
                dc.w byte_1B0B0-sub_10000
                dc.w byte_1B108-sub_10000
                dc.w byte_1B108-sub_10000
                dc.w byte_1B152-sub_10000
                dc.w byte_1B1A0-sub_10000
                dc.w byte_1B1F8-sub_10000
                dc.w byte_1B1F8-sub_10000
                dc.w byte_1B242-sub_10000
                dc.w byte_1B2A4-sub_10000
                dc.w byte_1B2E8-sub_10000
                dc.w byte_1B2E8-sub_10000
                dc.w byte_1B346-sub_10000
                dc.w byte_1B3A2-sub_10000
                dc.w byte_1B3EE-sub_10000
                dc.w byte_1B3EE-sub_10000
                dc.w byte_1B43C-sub_10000
                dc.w byte_1B486-sub_10000
                dc.w byte_1B4C8-sub_10000
                dc.w byte_1B4C8-sub_10000
                dc.w byte_1B522-sub_10000
                dc.w byte_1B56C-sub_10000
                dc.w byte_1B5AE-sub_10000
                dc.w byte_1B5AE-sub_10000
                dc.w byte_1B602-sub_10000
                dc.w byte_1B66C-sub_10000
                dc.w byte_1B6C0-sub_10000
                dc.w byte_1B6C0-sub_10000
                dc.w byte_1B700-sub_10000
                dc.w byte_1B74E-sub_10000
                dc.w byte_1B7B4-sub_10000
                dc.w byte_1B7B4-sub_10000
                dc.w byte_1B81C-sub_10000
                dc.w byte_1B85E-sub_10000
                dc.w byte_1B8C8-sub_10000
                dc.w byte_1B8C8-sub_10000
                dc.w byte_1B91C-sub_10000
byte_1ADF2:     dc.b $40, $86, $14, $86, $4A, $8C, $4A, $86, $14, $86
                dc.b $4A, $8C, $4A, $86, $14, $86, $4A, $8C, $4A, $86
                dc.b $14, $86, 0, $F, $17, $F, $B, $F, 5, $13
                dc.b 3, 8, $1E, 6, $1E, $C, $1E, $12, 0, $12
                dc.b 0, $C, 0, 6, $E, $F, $10, $F, 1, 7
                dc.b 3, 0, $B, 6, $B, $C, $B, $12, $13, $12
                dc.b $13, $C, $13, 6, 6, $F, $F, $13, $15, $1F
                dc.b $12, $1F, $C, $C, 9, $12, 9, 0
byte_1AE40:     dc.b $7F, $44, $9A, $7F, $24, $8D, 6, $8D, $7F, $24
                dc.b $9A, $7F, 0, $F, 5, 7, 6, $16, $12, 6
                dc.b $10, 4, 9, $A, 9, $16, $18, $16, $1C, $A
                dc.b 0, 1, $E, $A, 9, 7, 9, $D, 9, $13
                dc.b $17, $13, $17, $D, $17, 7, 6, 0, 6, 6
                dc.b $A, 0, $15, $F, $16, $19, $A, $17, 3, 0
byte_1AE7C:     dc.b $7F, $41, $8D, 6, $8D, $7F, $21, $8D, 6, $8D
                dc.b $7F, $21, $8D, 6, $8D, $7F, 0, $F, $17, $1B
                dc.b 6, $16, $18, $14, 3, $13, 1, 4, 3, 4
                dc.b 7, 4, $1D, 4, $15, $A, $17, $A, $1B, $A
                dc.b $1D, $A, 7, $A, 9, $A, 7, $10, 1, $10
                dc.b 3, $10, $15, $10, $1B, $16, $1D, $16, 0, $16
                dc.b 3, $16, 5, $16, 0, 0, 5, 7, 5, $D
                dc.b 5, $13, $19, $13, $19, $D, $19, 7, 8, 7
                dc.b 3, 6, $A, 7, $10, 7, $16, $19, $16, $19
                dc.b $10, $1A, $A, $17, 3, 0
byte_1AEDC:     dc.b $7F, $D, $88, $70, $88, 8, $88, $64, $84, $18
                dc.b $84, $64, $88, 8, $88, $70, $88, 0, $F, 3
                dc.b 7, 8, $17, $10, 1, $16, 4, 6, $E, 8
                dc.b $E, $E, $12, $10, $12, 0, 0, 9, 9, 9
                dc.b $11, $F, $15, $15, $11, $15, 9, $1F, $D, 6
                dc.b 7, 3, 0, 9, 7, $D, $F, $10, $F, $A
                dc.b 5, $14, 2, $17, 5, $19, $15, 0
byte_1AF20:     dc.b 6, $C7, $7F, $3A, $86, 5, $C7, $8A, 5, $C7
                dc.b $84, $7F, $21, $C7, $8A, 5, $C7, $8A, $7F, $2B
                dc.b $C6, $8A, 5, $8B, $7F, 0, $F, 5, $1D, 6
                dc.b $15, $18, $C, $16, 4, $C, 4, $13, 4, 7
                dc.b $10, 9, $10, 0, 0, $1B, 7, 3, 7, 5
                dc.b $D, 5, $13, $19, $13, $18, $D, 6, $A, 4
                dc.b 3, $A, 9, $16, $12, $10, $12, $A, $18, 4
                dc.b 2, $1D, $10, $1A, $16, 0
byte_1AF6C:     dc.b $57, $C5, $86, $6D, $8C, 1, $87, $1F, $C4, $41
                dc.b $85, $1A, $81, 4, $C4, $26, $C7, $8B, $29, $84
                dc.b $17, $85, $60, $87, 5, $86, 4, $8A, 6, $C5
                dc.b $7F, 0, $F, 5, $1A, 2, $1A, $18, 1, 8
                dc.b 3, $D, $A, $F, $A, $16, $16, 1, 2, 5
                dc.b 0, $C, 7, $C, $D, $C, $13, $C, $19, $18
                dc.b $19, $18, $13, 6, 4, 3, 0, $16, 7, $A
                dc.b 7, $F, $E, $10, $D, $16, 2, $18, $B, $13
                dc.b 3, 0
byte_1AFBE:     dc.b $7F, 3, $CB, $8B, 4, $8C, $1F, $CA, $6A, $86
                dc.b 4, $CB, $85, $15, $CA, $75, $85, $10, $85, $7F
                dc.b 6, $8B, 6, $8B, $7F, 0, $F, $17, $1A, 4
                dc.b 7, $18, 4, 2, 6, 9, 2, $B, 2, 4
                dc.b $C, $A, $11, $15, $11, $1A, $C, 2, 6, 8
                dc.b $17, $17, 0, 9, 5, 9, $A, 9, $14, $15
                dc.b $14, $15, $A, $15, 5, 4, 7, 2, $17, 2
                dc.b 9, 8, $1F, $B, 4, $15, 8, $15, $E, 9
                dc.b $E, $F, $C, 0
byte_1B012:     dc.b $40, $84, $18, $C7, $83, 3, $C2, $20, $84, $24
                dc.b $88, $25, $83, $24, $84, $19, $83, 3, $C2, $20
                dc.b $84, $24, $88, $24, $84, $1F, $C8, 4, $84, $18
                dc.b $84, 3, $C2, $20, $84, $24, $88, $24, $83, $25
                dc.b $84, $18, $84, 0, $F, 4, 0, 8, $11, $18
                dc.b $D, $16, 3, 5, $E, $F, $F, $18, $10, 0
                dc.b 1, 7, $16, $F, $12, $F, $19, $1D, $15, $1D
                dc.b $F, $1D, 9, $1D, 3, 4, 6, 2, 5, 8
                dc.b 5, $E, $19, 2, 4, $19, $A, $15, $F, $F
                dc.b $16, $F, 9, 0
byte_1B070:     dc.b $43, $9A, $7F, 4, $8E, 4, $8E, $6E, $84, $7A
                dc.b $88, $7F, $17, $8C, 0, $F, $13, 2, $18, $19
                dc.b 7, $1C, $E, 1, $1A, $16, 1, $18, $13, 2
                dc.b 0, $10, 5, $D, 5, 3, 9, 3, $D, 3
                dc.b $11, 3, $15, 3, $19, 3, 4, $F, 1, 9
                dc.b 5, $15, 5, $F, 9, 4, 6, $F, 2, $13
                dc.b $1A, $14, $18, $E
byte_1B0B0:     dc.b $6A, $C3, $87, $1F, $C4, $E, $82, 4, $84, $12
                dc.b $84, $32, $84, $70, $84, $C, $C5, $83, $F, $C4
                dc.b $58, $84, 4, $84, 4, $84, 4, $84, $62, $82
                dc.b $1C, $82, $A, $8C, 0, $F, $13, $14, 7, 4
                dc.b $18, $1B, $16, 3, $1B, $D, $13, $D, $B, $D
                dc.b 1, 4, $15, 2, 0, $B, $18, 3, $B, 4
                dc.b $13, 8, $13, $10, $13, $15, $B, $15, $B, $10
                dc.b 4, 3, 2, $D, 2, $1D, 3, $18, 6, 4
                dc.b 2, $B, $C, $B, $12, $D, $19, $15
byte_1B108:     dc.b $6C, $88, $7F, $14, $86, 6, $86, $7F, $2A, $86
                dc.b $10, $86, $7F, $23, $83, $1A, $83, 0, $F, $17
                dc.b 9, 8, $1B, $E, $10, $11, 2, $16, 6, 4
                dc.b $C, 2, 6, $17, $15, $15, 3, $19, 4, $1B
                dc.b $A, 0, 4, $B, 9, 6, $F, 1, $15, $1D
                dc.b $15, $18, $F, $13, 9, 4, 0, 6, 4, $C
                dc.b 1, $12, $C, $11, 4, $13, $11, $1D, $12, $1C
                dc.b 7, $15, 6, 0
byte_1B152:     dc.b $68, $85, $B, $C3, $83, $10, $C2, $20, $8B, $68
                dc.b $84, 8, $89, 7, $84, $14, $CA, $7F, $14, $C6
                dc.b $87, 5, $87, $72, $86, $C, $88, 0, $F, 4
                dc.b $1A, 3, $C, $F, $1B, $16, 3, 2, $12, $17
                dc.b $D, $19, $D, 0, 1, 5, $A, $A, 4, $C
                dc.b $A, $E, $14, 6, $15, $15, $10, $19, 4, 4
                dc.b 4, 5, 3, $11, 9, 8, $17, 9, 4, $11
                dc.b $E, $10, $17, $17, $14, $A, $14, 0
byte_1B1A0:     dc.b $7F, 1, $82, $C, $84, $C, $82, $62, $84, 4
                dc.b $84, 4, $84, 4, $84, $68, $84, $C, $84, $68
                dc.b $84, 4, $84, 4, $84, 4, $84, $62, $82, $C
                dc.b $84, $C, $82, 0, $F, 3, 3, 8, $17, $18
                dc.b 9, $16, 4, $B, $E, $B, 6, $13, 6, $13
                dc.b $E, 0, 2, $16, 4, 0, $C, $C, 9, $A
                dc.b $11, 0, $15, $1E, $15, $14, $11, $12, 9, 4
                dc.b 8, 5, 7, $A, 6, $15, $F, $B, 4, $13
                dc.b $15, $17, 9, $1B, 5, $1D, $F, 0
byte_1B1F8:     dc.b $47, $C7, $85, 6, $86, $1F, $C6, $55, $84, $30
                dc.b $85, $12, $85, $7F, $25, $86, $10, $C7, $85, 9
                dc.b $C6, $7F, $21, $85, 6, $85, 0, $F, 5, $A
                dc.b 2, $14, $18, $1C, $16, 2, $1A, 6, 4, 6
                dc.b 0, 1, 0, $13, 7, 3, 9, 3, $B, 3
                dc.b $13, 3, $15, 3, $17, 3, 4, 0, $C, 3
                dc.b 6, $A, $F, 2, $14, 4, $F, $D, $14, $F
                dc.b $1A, $15, $1B, 5
byte_1B242:     dc.b $7F, 1, $8D, 6, $87, 5, $81, $7F, $21, $9A
                dc.b 5, $81, $C, $CA, $7F, $14, $86, 7, $8D, 5
                dc.b $81, $60, $8C, $12, $82, $32, $C2, $C2, $C2, $C2
                dc.b 0, $F, 9, 4, 4, $F, $18, $13, $14, 0
                dc.b 8, 8, 3, $E, 3, $18, 3, $1A, 8, $11
                dc.b $F, $17, $15, 5, $E, 4, 8, 5, $A, 8
                dc.b 7, $11, $1B, $B, $17, $E, 0, 2, 3, $11
                dc.b 5, $15, 5, 5, $17, 5, $17, $B, $17, $11
                dc.b 4, $A, 2, 4, 8, 8, $10, $E, $14, 4
                dc.b $1B, $15, $F, $E, $15, 8, $1C, 3
byte_1B2A4:     dc.b $4E, $84, $7A, $88, $75, $8E, $6F, $94, $7F, $A
                dc.b $9A, $7F, 0, $F, $17, $F, 6, $17, $18, 0
                dc.b $B, 0, 4, 2, $B, 7, 3, $15, 4, $17
                dc.b 7, 3, 1, 7, 5, 6, $1C, $D, $F, 7
                dc.b $F, $B, $D, $F, $11, $F, $13, $14, $B, $14
                dc.b 4, 4, $A, $A, 4, $C, $12, 8, $17, 4
                dc.b $15, $17, $12, $12, $15, 5, $1D, 9
byte_1B2E8:     dc.b $48, $85, 6, $C6, $84, 8, $82, $A, $C5, $11
                dc.b $82, $7F, 4, $85, $10, $85, $7F, $2C, $85, 6
                dc.b $C6, $84, 8, $84, 8, $C5, $F, $C6, $83, 3
                dc.b $C5, $69, $86, $11, $84, $10, $84, 0, $F, $17
                dc.b $1E, 3, 5, $18, $1C, $D, 0, 5, 0, $C
                dc.b 6, $C, 5, $13, 9, $17, $13, $D, 2, $F
                dc.b $E, $E, 3, 9, 3, 9, $F, $15, 3, $15
                dc.b $F, $1E, $10, $1F, 4, 4, $F, 3, 5, 4
                dc.b 9, $A, 7, $12, 4, $15, $B, $19, 5, $17
                dc.b $13, $1F, $D, 0
byte_1B346:     dc.b $6B, $C6, $82, 4, $D2, $82, $18, $D1, 6, $C5
                dc.b $73, $C6, $82, $A, $83, $1F, $C5, $6D, $C6, $82
                dc.b $10, $83, $1F, $C5, $67, $83, $16, $83, $2C, $83
                dc.b 6, $83, 0, $F, $17, $13, 3, 3, $18, $1E
                dc.b 4, 8, 8, 6, 5, $B, 2, $10, $1C, $10
                dc.b $19, $A, $16, 6, $14, $12, $A, $12, 1, 1
                dc.b 5, 0, $C, 4, 9, 9, 6, $E, $18, $E
                dc.b $15, 9, $12, 4, 4, 8, 3, 4, 8, $A
                dc.b $E, $1F, $E, 4, $14, $E, $F, $B, $16, 3
                dc.b $1A, 8
byte_1B3A2:     dc.b $62, $94, $1F, $C4, $4A, $8A, $C, $84, 4, $82
                dc.b $19, $C4, $4C, $C5, $92, $68, $85, $A, $8C, 6
                dc.b $C4, $60, $9B, $7F, 0, $F, 2, $F, $B, $F
                dc.b $18, $1E, $10, 4, $12, 9, $A, $11, $C, $11
                dc.b $C, 9, 0, 1, $1C, $B, $14, $C, $15, $C
                dc.b $16, $C, 3, $14, 4, $14, 5, $14, 4, 2
                dc.b $C, 8, 2, 9, $10, 9, $16, 4, $D, 8
                dc.b $1C, $C, $1C, 4, $14, $16
byte_1B3EE:     dc.b $D8, $60, $91, 4, $86, $1F, $D0, $55, $C5, $85
                dc.b $1F, $C8, $56, $C5, $83, $78, $C5, $83, 5, $84
                dc.b $6F, $84, 1, $8D, $7F, 0, $F, $17, 8, 3
                dc.b 6, $18, 2, $D, 4, $A, $D, 6, $11, $E
                dc.b 9, $13, 5, 1, 3, 9, 0, 1, 4, $A
                dc.b $14, $B, $14, $12, $10, $13, $10, $14, $10, 4
                dc.b $B, 9, 5, $D, 2, $15, $F, $10, 4, $13
                dc.b $C, $18, $B, $1D, $B, $19, 2, 0
byte_1B43C:     dc.b $64, $98, $64, $8D, 6, $8D, $64, $98, $64, $8D
                dc.b 6, $8D, $64, $98, $7F, 0, $F, 2, $F, $B
                dc.b $F, $18, $1C, $16, 8, $1E, $16, 0, $16, 0
                dc.b $D, 0, 5, $1E, 5, $1E, $D, $E, $11, $10
                dc.b $11, 0, 0, 9, 8, 9, $10, $15, $10, $14
                dc.b 8, $F, $C, $F, $14, 4, $B, 2, 9, $16
                dc.b $F, 8, $F, $10, 4, $15, $16, $1F, $14, $1F
                dc.b $C, $1F, 2, 0
byte_1B486:     dc.b $63, $D1, $97, $7F, $12, $94, $7F, 9, $91, $7F
                dc.b $2C, $99, $7F, 0, $F, 2, $15, 8, $D, $18
                dc.b $1A, $C, 5, 9, $B, $B, $11, $D, $11, $12
                dc.b $11, $14, $11, 0, 0, $C, 9, $C, $E, $C
                dc.b $14, $17, $14, $17, $E, $17, 9, 4, $11, $C
                dc.b 7, 9, 5, $F, $1F, $14, 4, $11, $11, $13
                dc.b $17, $1C, $F, $1D, 4, 0
byte_1B4C8:     dc.b $46, $C6, $85, $A, $C6, $85, $7F, 5, $C7, $85
                dc.b $A, $C7, $85, $7F, $35, $C6, $85, $A, $C6, $85
                dc.b $7F, 5, $C6, $85, $A, $C6, $85, $7F, 0, $F
                dc.b $17, 8, 2, $18, 2, $1E, $16, $A, $15, $10
                dc.b $17, $10, $1C, $B, $1E, $B, 5, $10, 7, $10
                dc.b $B, $B, $D, $B, $11, 5, $13, 5, 0, 0
                dc.b 4, 8, $E, $E, 5, $19, $15, $19, $14, 8
                dc.b $1E, $E, 4, 1, 3, 5, $D, $B, 8, 6
                dc.b $16, 4, $E, $13, $15, $E, $12, 2, $18, $16
byte_1B522:     dc.b $1F, $D8, $43, $CC, $88, 7, $89, $1F, $CB, $68
                dc.b $89, 5, $89, $7F, $2A, $89, 5, $89, $7F, $E
                dc.b $8F, $7F, 0, $F, $17, 7, 3, $F, $13, 1
                dc.b $12, 4, 4, $15, $A, $C, $13, $C, $19, $15
                dc.b 1, $14, 7, 0, 9, 9, 9, $F, 9, $14
                dc.b $13, $14, $13, $F, $13, 9, 4, $F, 3, 0
                dc.b 8, 3, $12, 5, $C, 4, $F, $D, $18, $C
                dc.b $1A, $14, $1D, 9
byte_1B56C:     dc.b $60, $8E, 4, $8E, $7F, $4F, $84, $7F, $4F, $8E
                dc.b 4, $8E, $7F, 0, $F, 9, $1A, 3, 4, $11
                dc.b 1, $B, 4, $B, $F, 9, $F, $13, $F, $15
                dc.b $F, 1, 4, $16, 0, 2, $19, 2, $12, 2
                dc.b 4, $1D, 4, $1D, $12, $1D, $19, 4, 6, 2
                dc.b 2, $E, 9, 9, 6, $15, 4, $18, 2, $14
                dc.b 9, $1C, $F, $18, $15, 0
byte_1B5AE:     dc.b $4A, $85, 3, $D3, $84, $17, $D2, $33, $CD, $84
                dc.b $13, $85, $1F, $CC, $2B, $84, 5, $84, $4C, $84
                dc.b $13, $84, $4C, $84, 5, $84, $4C, $84, $13, $84
                dc.b $4C, $84, 5, $84, 0, $F, $17, $1B, 5, 3
                dc.b $18, $10, $D, 4, 4, 9, 4, $F, $1B, $F
                dc.b $1B, 9, 0, 0, $B, 3, $B, 9, $B, $F
                dc.b $12, $F, $12, 9, $12, 3, 4, $B, 6, $B
                dc.b $12, 8, $C, $1F, $C, 4, $15, 6, $14, $12
                dc.b $17, $C, $10, $A
byte_1B602:     dc.b $60, $CF, $8E, 3, $8E, $67, $C4, $83, $B, $C4
                dc.b $83, $10, $C3, $E, $C3, $27, $86, 1, $82, 1
                dc.b $84, 3, $84, 1, $82, 1, $86, $67, $C4, $83
                dc.b $B, $C4, $83, $10, $C3, $E, $C3, $27, $86, 1
                dc.b $82, 1, $84, 3, $84, 1, $82, 1, $86, $60
                dc.b $87, $13, $C3, $85, 6, $C2, 0, $F, $17, $1C
                dc.b 3, 8, $18, 2, 8, 4, $C, 8, $C, $F
                dc.b $13, $F, $13, 8, 0, 0, $C, 4, $C, $B
                dc.b $C, $12, $13, $12, $13, $B, $13, 4, 4, $10
                dc.b 7, 3, 8, 3, $F, 9, $15, 4, $10, $F
                dc.b $15, $15, $1D, $F, $1D, 7
byte_1B66C:     dc.b $4C, $89, $1F, $C4, $51, $CC, $89, 5, $85, $1F
                dc.b $CB, $49, $83, $A, $84, 6, $85, $7F, $43, $85
                dc.b 1, $85, 8, $C4, $84, 1, $83, $E, $C3, $40
                dc.b $88, 0, $F, $13, $10, 2, $1E, $18, $F, $17
                dc.b 4, 8, $F, $A, $F, $14, $F, $16, $F, 1
                dc.b 0, $16, 0, 7, 7, 4, $12, 8, $12, $12
                dc.b 3, $1B, $B, $16, $12, 4, 9, 3, 0, 7
                dc.b 0, $F, 6, $16, 4, $B, $D, $16, $D, $19
                dc.b $16, $1B, 3, 0
byte_1B6C0:     dc.b $7F, $7F, $70, $84, $7F, $4F, $82, 6, $84, 8
                dc.b $84, 6, $82, $7F, 0, $F, $A, 9, $18, $15
                dc.b $12, $F, $10, 4, 3, $A, 5, $A, $19, $A
                dc.b $1B, $A, 0, 0, 9, $13, $15, $13, $1F, $13
                dc.b 4, $19, $F, $19, $1A, $19, 4, 3, $10, 7
                dc.b 9, $B, 7, $1F, 9, 4, $14, 7, $F, $13
                dc.b $18, 9, $1A, $10
byte_1B700:     dc.b $40, $89, 5, $92, $12, $D2, $4D, $8E, 8, $8A
                dc.b $D, $C4, $72, $8A, 9, $8D, $60, $8E, 9, $89
                dc.b $D, $C8, $72, $89, $A, $8D, 0, $F, $17, $B
                dc.b 6, $B, $F, $F, $E, 4, $17, 9, $19, 9
                dc.b $17, $12, $19, $12, 1, 3, $13, 0, $1A, $19
                dc.b $1A, $15, $1A, $10, $1A, $C, $1A, 7, $1A, 3
                dc.b 4, 6, 2, $A, $A, $F, $A, $14, $A, 4
                dc.b $E, 2, $A, $14, $F, $13, $14, $13
byte_1B74E:     dc.b $40, $83, 3, $85, 3, $85, 3, $85, 3, $82
                dc.b $62, $85, 3, $85, 3, $85, 3, $85, $61, $83
                dc.b 3, $85, 3, $85, 3, $85, 3, $82, $62, $85
                dc.b 3, $85, 3, $85, 3, $85, $61, $83, 3, $85
                dc.b 3, $85, 3, $85, 3, $82, $7F, 0, $F, $17
                dc.b 7, $A, $17, $A, $F, 9, 4, 3, $16, 5
                dc.b $16, $19, $16, $1B, $16, 2, 8, $17, $12, $17
                dc.b 0, $B, 7, $14, 7, $17, $B, 7, $B, $F
                dc.b $B, $F, $13, 4, 7, 2, 7, $D, 7, $16
                dc.b $C, $B, 4, $14, $B, $17, 2, $18, $E, $17
                dc.b $17, 0
byte_1B7B4:     dc.b $63, $84, 4, $84, 4, $84, 4, $84, 7, $C7
                dc.b 7, $C7, 7, $C7, 7, $C7, $7F, $22, $82, 5
                dc.b $83, 5, $83, 5, $83, 5, $81, 1, $C7, 7
                dc.b $C7, 7, $C7, 7, $C7, $7F, $29, $83, 5, $83
                dc.b 5, $83, 5, $83, 7, $C6, 7, $C6, 7, $C6
                dc.b 7, $C6, $7F, 0, $F, $17, $C, 3, $1C, 3
                dc.b $B, $A, 4, 0, 8, 2, 8, $10, 8, $12
                dc.b 8, 0, 0, 4, 4, $C, 4, $14, 4, $1C
                dc.b 4, $18, $19, 7, $19, 4, 1, $15, 6, $F
                dc.b $B, 8, 9, $16, 4, $E, $E, $16, $E, $1E
                dc.b $E, $19, $15, 0
byte_1B81C:     dc.b $6E, $84, $7F, $65, $86, $7F, $45, $88, $7F, 0
                dc.b $F, 2, 3, $11, $13, $18, 0, 6, 0, 7
                dc.b 4, $E, 7, $B, 9, 8, $16, 4, $19, $E
                dc.b $19, $17, $B, $13, 0, $D, 4, $D, 4, $D
                dc.b 4, $D, 4, $D, 4, $D, 4, 4, 6, $F
                dc.b 6, 6, $F, 7, $F, $D, 4, $F, $14, $1B
                dc.b $F, $17, 6, $1E, 6, 0
byte_1B85E:     dc.b $60, $82, $D, $C4, $82, $D, $C4, 1, $C3, $F
                dc.b $C3, $2E, $81, $F, $81, $56, $C4, $82, $D, $C4
                dc.b $82, $F, $C3, $F, $C3, $2E, $81, $F, $81, $35
                dc.b $85, $D, $82, $1D, $C4, 1, $C3, $3E, $81, $49
                dc.b $C4, $82, 7, $C4, $82, $15, $C3, 9, $C3, $34
                dc.b $81, 9, $81, 0, $F, $D, 8, 9, $1B, $18
                dc.b $1B, 4, 0, 5, 2, $B, 4, $16, $A, 6
                dc.b $13, 3, $19, 7, 0, 7, $A, $1F, 4, $1F
                dc.b $10, $E, $F, $11, $F, $17, $A, 4, 7, 5
                dc.b $A, $14, $1F, $C, $1F, $17, 4, $15, $14, $10
                dc.b $16, $F, 2, $18, 6, 0
byte_1B8C8:     dc.b $68, $C8, $8F, $1F, $C7, $77, $C6, $C6, $34, $C8
                dc.b $82, $10, $83, $1F, $C7, $31, $C8, $82, 2, $83
                dc.b $1F, $C7, $4E, $C4, $82, $16, $83, $1F, $C6, $2B
                dc.b $C4, $82, 4, $83, 1, $83, 0, $F, 2, 5
                dc.b $A, $19, $18, $F, 7, 0, 3, 2, 7, $19
                dc.b 3, $1A, 6, 0, $F, 9, $D, $E, $11, $E
                dc.b $11, $15, $14, $15, $A, $19, 4, 4, 3, $C
                dc.b 7, $F, $12, 8, $11, 4, $13, 7, $17, $11
                dc.b $1B, 3, $1F, $B
byte_1B91C:     dc.b 5, $C4, 5, $C4, 9, $C4, 5, $C4, $47, $C4
                dc.b $81, 7, $82, 5, $C4, $81, 7, $82, $F, $C3
                dc.b $F, $C3, $26, $89, 7, $89, $63, $85, 5, $C4
                dc.b $8C, 5, $C4, $83, 4, $C3, $11, $C3, $29, $84
                dc.b 7, $8B, 7, $83, $60, $8A, 5, $C3, $82, 5
                dc.b $C7, $88, 9, $C6, 7, $C2, $F, $C5, $82, 1
                dc.b $C5, $82, 8, $81, 8, $C3, $82, 1, $C5, $82
                dc.b 7, $C4, $1B, $C3, 2, $81, $13, $82, 2, $82
                dc.b $1B, $C2, 6, $81, $16, $82, 3, $82, 0, $F
                dc.b $17, $10, $A, 0, $11, $10, 4, 0, 0, 0
                dc.b $B, $B, $14, $B, $1E, $B, $1D, $12, 2, $12
                dc.b 0, $B, 4, 3, 3, $C, 3, 7, $B, $E
                dc.b $11, 4, $11, $11, $18, $B, $13, 3, $1C, 3
                dc.b 0, 0
;empty_block_2:  dc.b [$465F]$FF
                org $FFFF
byte_1FFFF:     dc.b $FF
