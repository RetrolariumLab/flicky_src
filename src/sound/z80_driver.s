; Z80 bus arbitration and the sound command queue.
; ROM $001014-$001195.

LoadZ80Driver:
                bsr.w   Sound_RequestZ80Bus
                bsr.w   Sound_ResetZ80
                bsr.w   Sound_ClearZ80RAM
                move.w  #$FE5,d0
                moveq   #0,d1
                moveq   #2,d2
                lea     z80_part1(pc),a0
                bsr.w   Sound_CopyToZ80RAM
                moveq   #8,d0
                move.w  #$1C00,d1
                moveq   #1,d2
                lea     Sound_ChannelInitData(pc),a0
                bsr.w   Sound_CopyToZ80RAM
                clr.w   (word_FFFFA2).w
                rts

Sound_ChannelInitData: dc.b    0, $80, 0, $80, 0, 0, 0, 0, $20, 0  ; was: byte_1046
RequestZ80Bus:
                btst    #0,(IO_Z80BUS).l
                sne     (byte_FFFFC8).w
                beq.s   Sound_RequestZ80Bus_Return

; Requests Z80 bus access with busy wait
Sound_RequestZ80Bus:
                movem.w d0,-(sp)  ; was: sub_105E
                move.w  #$100,(IO_Z80BUS).l
                moveq   #$F,d0

Sound_RequestZ80Bus_WaitLoop:  ; was: loc_106C
                btst    #0,(IO_Z80BUS).l
                dbeq    d0,Sound_RequestZ80Bus_WaitLoop
                movem.w (sp)+,d0

Sound_RequestZ80Bus_Return:  ; was: locret_107C
                rts

; Release Z80 bus if flag set
Sound_ReleaseZ80Check:
                tst.b   (byte_FFFFC8).w  ; was: sub_107E
                beq.s   Sound_ReleaseZ80Check_Return

ReleaseZ80Bus:
                move.w  #0,(IO_Z80BUS).l

Sound_ReleaseZ80Check_Return:  ; was: locret_108C
                rts

; Resets Z80 processor via IO_Z80RES
Sound_ResetZ80:
                move.w  #0,(IO_Z80RES).l  ; was: sub_108E
                bsr.s   Sys_DelayNop
                bsr.s   Sys_DelayNop
                bsr.s   Sys_DelayNop
                move.w  #$100,(IO_Z80RES).l

; Delay NOP for Z80 reset timing
Sys_DelayNop:
                rts  ; was: nullsub_2

; Copies d0 bytes from a0 to Z80 RAM at offset d1
Sound_CopyToZ80RAM:
                movem.l d0-d3/a0-a1,-(sp)  ; was: sub_10A6
                bsr.s   Sound_RequestZ80Bus
                lea     (Z80_RAM).l,a1
                adda.w  d1,a1

Sound_CopyToZ80RAM_ByteLoop:  ; was: loc_10B4
                move.b  (a0)+,d1
                moveq   #$F,d3

Sound_CopyToZ80RAM_RetryLoop:  ; was: loc_10B8
                move.b  d1,(a1)
                cmp.b   (a1),d1
                beq.s   Sound_CopyToZ80RAM_NextByte
                dbf     d3,Sound_CopyToZ80RAM_RetryLoop
                bra.s   Sound_CopyToZ80RAM_Release

Sound_CopyToZ80RAM_NextByte:  ; was: loc_10C4
                addq.w  #1,a1
                dbf     d0,Sound_CopyToZ80RAM_ByteLoop
                lsr.w   #1,d2
                bcc.s   Sound_CopyToZ80RAM_CheckHold
                bsr.s   Sound_ResetZ80

Sound_CopyToZ80RAM_CheckHold:  ; was: loc_10D0
                lsr.w   #1,d2
                bcs.s   Sound_CopyToZ80RAM_Done

Sound_CopyToZ80RAM_Release:  ; was: loc_10D4
                bsr.s   ReleaseZ80Bus

Sound_CopyToZ80RAM_Done:  ; was: loc_10D6
                movem.l (sp)+,d0-d3/a0-a1
                rts

; Sends command directly to Z80 RAM
Sound_SendZ80Command:
                movem.l d1/a0,-(sp)  ; was: sub_10DC
                bsr.w   Sound_RequestZ80Bus
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

; Queues sound byte to internal buffer
Sound_QueueToBuffer:
                movea.w (word_FFFFA2).w,a0  ; was: sub_1100
                cmpa.w  #8,a0
                bcc.s   Sound_QueueToBuffer_Return
                move.b  d0,-$66(a0)
                addq.w  #1,(word_FFFFA2).w

Sound_QueueToBuffer_Return:  ; was: locret_1112
                rts

; Queues sound effect from object to Z80 sound driver
Sound_QueueSFX:
                movea.w (word_FFFFA2).w,a0  ; was: sub_1114
                move.w  a0,d0
                beq.s   Sound_QueueSFX_Wait
                move.b  -$67(a0),d0
                subq.w  #1,(word_FFFFA2).w
                bsr.w   Sound_RequestZ80Bus
                tst.b   (byte_A01C0A).l
                bne.s   Sound_QueueSFX_TrySlot2
                move.b  d0,(byte_A01C0A).l
                bra.s   Sound_QueueSFX_Release

Sound_QueueSFX_TrySlot2:  ; was: loc_1138
                tst.b   (byte_A01C0B).l
                bne.s   Sound_QueueSFX_TrySlot3
                move.b  d0,(byte_A01C0B).l
                bra.s   Sound_QueueSFX_Release

Sound_QueueSFX_TrySlot3:  ; was: loc_1148
                tst.b   (byte_A01C0C).l
                bne.s   Sound_QueueSFX_Release
                move.b  d0,(byte_A01C0C).l

Sound_QueueSFX_Release:  ; was: loc_1156
                bsr.w   ReleaseZ80Bus

Sound_QueueSFX_Wait:  ; was: loc_115A
                bra.w   Sys_WaitVBlank

; Clears entire Z80 RAM (8KB)
Sound_ClearZ80RAM:
                move.w  #$1FFF,d0  ; was: sub_115E
                lea     (Z80_RAM).l,a0

Sound_ClearZ80RAM_ByteLoop:  ; was: loc_1168
                moveq   #$F,d1

Sound_ClearZ80RAM_RetryLoop:  ; was: loc_116A
                move.b  #0,(a0)
                tst.b   (a0)
                dbeq    d1,Sound_ClearZ80RAM_RetryLoop
                addq.l  #1,a0
                dbf     d0,Sound_ClearZ80RAM_ByteLoop
                rts

; Checks if specific sound is playing
Sound_CheckPlaying:
                movem.w d1,-(sp)  ; was: sub_117C
                bsr.w   Sound_RequestZ80Bus
                move.b  (byte_A01C0A).l,d1
                bsr.w   ReleaseZ80Bus
                cmp.b   d0,d1
                movem.w (sp)+,d1
                rts

; Loads palette from compact format with position flags
