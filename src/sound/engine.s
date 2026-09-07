; Sound driver init and note playback
; ROM $010CD4-$010D6D

Gfx_InitCRAMAndClearVDP:
                move.l  #$C0000000,(VDP_CTRL).l
                moveq   #$3F,d0

Gfx_InitCRAMAndClearVDP_ClearLoop:
                move.w  #0,(VDP_DATA).l
                dbf     d0,Gfx_InitCRAMAndClearVDP_ClearLoop
                moveq   #0,d2
                move.w  #$A800,d0
                jmp     j_Gfx_FillVRAMZero

; Loads Z80 sound driver and initializes audio system
Sound_InitDriver:
                jsr     j_Sound_LoadZ80Driver
                lea     (Data_Z80Driver2).l,a1
                bsr.s   Sound_LoadZ80Table
                bsr.s   Sound_LoadZ80Table
                moveq   #8,d0
                move.w  #$1C00,d1
                moveq   #1,d2
                lea     Sound_InitCommandData(pc),a0
                jsr     j_Sound_CopyToZ80RAM
                clr.w   (Ram_SoundQueueCount).w
                rts

Sound_InitCommandData:  dc.b    0, $80, 0, $12, $B4, 0, $E6, $80, $20, 0
; Loads Z80 data using table pointer in a1
Sound_LoadZ80Table:
                moveq   #2,d2
                movem.w (a1)+,d0-d1/a0
                ; !(OBS) DATA-001 Relative offset maps into the 64-KiB work-RAM image
                suba.l  #M68K_RAM_SIZE,a0
                jmp     j_Sound_CopyToZ80RAM

; Sends note/command to Z80 sound driver
Sound_PlayNote:
                move.l  a0,-(sp)
                jsr     j_Sound_RequestZ80Bus
                move.b  d0,(Z80_MusicCommand).l
                jsr     j_Sound_ReleaseZ80Bus
                movea.l (sp)+,a0
                rts

; Plays note only if sound channel is active
Sound_PlayNoteIfActive:
                tst.b   (Ram_SoundBusyFlag).w
                bne.s   Sound_PlayNoteIfActive_Return
                bsr.s   Sound_PlayNote

Sound_PlayNoteIfActive_Return:
                rts

; Counts down sound channel cooldown timer
Sound_ChannelCooldown:
                tst.b   (Ram_SoundBusyFlag).w
                beq.s   Sound_ChannelCooldown_Return
                addq.w  #1,(Ram_SoundCooldown).w
                cmpi.w  #$1E,(Ram_SoundCooldown).w
                bcs.s   Sound_ChannelCooldown_Return
                clr.w   (Ram_SoundCooldown).w
                clr.b   (Ram_SoundBusyFlag).w

Sound_ChannelCooldown_Return:
                rts

; Converts offset d0 to VDP VRAM write command format
