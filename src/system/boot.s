; Reset entry, hardware bring-up, checksum verification.
; ROM $000200-$000401.

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
                bsr.w Gfx_InitVDPRegister
                cmpi.b  #0,d0
                beq.s   loc_374
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
                bsr.w Gfx_WriteVDPRegs
                bsr.w Gfx_ClearVRAMAndCRAM
                bsr.w   LoadZ80Driver
                lea (Sys_GameEntryPoint).l,a0
                lea     (M68K_RAM).l,a1
                move.w  #$2FFF,d0

loc_3D8:
                move.l  (a0)+,(a1)+
                dbf     d0,loc_3D8
                jmp     M68K_RAM

CheckSumError:
                bsr.w Gfx_ClearVRAMAndCRAM
                move.l  #$C0000000,(VDP_CTRL).l
                moveq   #$3F,d7

fill_red_screen:
                move.w  #$E,(VDP_DATA).l
                dbf     d7,fill_red_screen

endless_loop:
                bra.s   endless_loop

; Clears CRAM (palette) and VRAM with zeros
