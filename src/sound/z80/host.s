; Z80 bus arbitration and the sound command queue
; ROM $001014-$001195

Sound_LoadZ80Driver:
                bsr.w   Sound_RequestZ80Bus
                bsr.w   Sound_ResetZ80
                bsr.w   Sound_ClearZ80RAM
                move.w  #$FE5,d0
                moveq   #0,d1
                moveq   #2,d2
                lea     Data_Z80Driver1(pc),a0
                bsr.w   Sound_CopyToZ80RAM
                moveq   #8,d0
                move.w  #$1C00,d1
                moveq   #1,d2
                lea     Sound_ChannelInitData(pc),a0
                bsr.w   Sound_CopyToZ80RAM
                clr.w   (Ram_SoundQueueCount).w
                rts

Sound_ChannelInitData:  dc.b    0, $80, 0, $80, 0, 0, 0, 0, $20, 0
Sound_RequestZ80BusIfFree:
                btst    #0,(IO_Z80BUS).l
                sne     (Ram_Z80BusHeld).w
                beq.s   Sound_RequestZ80Bus_Return

; Requests Z80 bus access with busy wait
Sound_RequestZ80Bus:
                movem.w d0,-(sp)
                move.w  #$100,(IO_Z80BUS).l
                moveq   #$F,d0

Sound_RequestZ80Bus_WaitLoop:
                btst    #0,(IO_Z80BUS).l
                dbeq    d0,Sound_RequestZ80Bus_WaitLoop
                movem.w (sp)+,d0

Sound_RequestZ80Bus_Return:
                rts

; Release Z80 bus if flag set
Sound_ReleaseZ80Check:
                tst.b   (Ram_Z80BusHeld).w
                beq.s   Sound_ReleaseZ80Check_Return

Sound_ReleaseZ80Bus:
                move.w  #0,(IO_Z80BUS).l

Sound_ReleaseZ80Check_Return:
                rts

; Resets Z80 processor via IO_Z80RES
Sound_ResetZ80:
                move.w  #0,(IO_Z80RES).l
                bsr.s   Sys_DelayNop
                bsr.s   Sys_DelayNop
                bsr.s   Sys_DelayNop
                move.w  #$100,(IO_Z80RES).l

; Delay NOP for Z80 reset timing
Sys_DelayNop:
                rts

; Copies d0 bytes from a0 to Z80 RAM at offset d1
Sound_CopyToZ80RAM:
                movem.l d0-d3/a0-a1,-(sp)
                bsr.s   Sound_RequestZ80Bus
                lea     (Z80_RAM).l,a1
                adda.w  d1,a1

Sound_CopyToZ80RAM_ByteLoop:
                move.b  (a0)+,d1
                moveq   #$F,d3

Sound_CopyToZ80RAM_RetryLoop:
                move.b  d1,(a1)
                cmp.b   (a1),d1
                beq.s   Sound_CopyToZ80RAM_NextByte
                dbf     d3,Sound_CopyToZ80RAM_RetryLoop
                bra.s   Sound_CopyToZ80RAM_Release

Sound_CopyToZ80RAM_NextByte:
                addq.w  #1,a1
                dbf     d0,Sound_CopyToZ80RAM_ByteLoop
                lsr.w   #1,d2
                bcc.s   Sound_CopyToZ80RAM_CheckHold
                bsr.s   Sound_ResetZ80

Sound_CopyToZ80RAM_CheckHold:
                lsr.w   #1,d2
                bcs.s   Sound_CopyToZ80RAM_Done

Sound_CopyToZ80RAM_Release:
                bsr.s   Sound_ReleaseZ80Bus

Sound_CopyToZ80RAM_Done:
                movem.l (sp)+,d0-d3/a0-a1
                rts

; Sends command directly to Z80 RAM
Sound_SendZ80Command:
                movem.l d1/a0,-(sp)
                bsr.w   Sound_RequestZ80Bus
                lea     (Z80_CommandBlock).l,a0
                moveq   #0,d1
                move.b  d1,(a0)+
                move.b  d1,(a0)+
                move.b  d1,(a0)+
                move.b  d1,(a0)
                addq.w  #2,a0
                move.b  d0,(a0)
                bsr.s   Sound_ReleaseZ80Bus
                movem.l (sp)+,d1/a0
                rts

; Queues sound byte to internal buffer
Sound_QueueToBuffer:
                movea.w (Ram_SoundQueueCount).w,a0
                cmpa.w  #8,a0
                bcc.s   Sound_QueueToBuffer_Return
                move.b  d0,-$66(a0)
                addq.w  #1,(Ram_SoundQueueCount).w

Sound_QueueToBuffer_Return:
                rts

; Queues sound effect from object to Z80 sound driver
Sound_QueueSFX:
                movea.w (Ram_SoundQueueCount).w,a0
                move.w  a0,d0
                beq.s   Sound_QueueSFX_Wait
                move.b  -$67(a0),d0
                subq.w  #1,(Ram_SoundQueueCount).w
                bsr.w   Sound_RequestZ80Bus
                tst.b   (Z80_SFXSlot0).l
                bne.s   Sound_QueueSFX_TrySlot2
                move.b  d0,(Z80_SFXSlot0).l
                bra.s   Sound_QueueSFX_Release

Sound_QueueSFX_TrySlot2:
                tst.b   (Z80_SFXSlot1).l
                bne.s   Sound_QueueSFX_TrySlot3
                move.b  d0,(Z80_SFXSlot1).l
                bra.s   Sound_QueueSFX_Release

Sound_QueueSFX_TrySlot3:
                tst.b   (Z80_SFXSlot2).l
                bne.s   Sound_QueueSFX_Release
                move.b  d0,(Z80_SFXSlot2).l

Sound_QueueSFX_Release:
                bsr.w   Sound_ReleaseZ80Bus

Sound_QueueSFX_Wait:
                bra.w   Sys_WaitVBlank

; Clears entire Z80 RAM (8KB)
Sound_ClearZ80RAM:
                move.w  #$1FFF,d0
                lea     (Z80_RAM).l,a0

Sound_ClearZ80RAM_ByteLoop:
                moveq   #$F,d1

Sound_ClearZ80RAM_RetryLoop:
                move.b  #0,(a0)
                tst.b   (a0)
                dbeq    d1,Sound_ClearZ80RAM_RetryLoop
                addq.l  #1,a0
                dbf     d0,Sound_ClearZ80RAM_ByteLoop
                rts

; Checks if specific sound is playing
Sound_CheckPlaying:
                movem.w d1,-(sp)
                bsr.w   Sound_RequestZ80Bus
                move.b  (Z80_SFXSlot0).l,d1
                bsr.w   Sound_ReleaseZ80Bus
                cmp.b   d0,d1
                movem.w (sp)+,d1
                rts

; Loads palette from compact format with position flags
