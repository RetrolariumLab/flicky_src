; Sound driver init and note playback
; ROM $010CD4-$010D6D

Gfx_InitCRAMAndClearVDP:
                move.l  #$C0000000,(VDP_CTRL).l         ; was: sub_10CD4
                moveq   #$3F,d0

Gfx_InitCRAMAndClearVDP_ClearLoop:                      ; was: loc_10CE0
                move.w  #0,(VDP_DATA).l
                dbf     d0,Gfx_InitCRAMAndClearVDP_ClearLoop
                moveq   #0,d2
                move.w  #$A800,d0
                jmp     j_Gfx_FillVRAMZero

; Loads Z80 sound driver and initializes audio system
Sound_InitDriver:
                jsr     j_LoadZ80Driver                 ; was: sub_10CF6
                lea     (z80_part2).l,a1
                bsr.s   Sound_LoadZ80Table
                bsr.s   Sound_LoadZ80Table
                moveq   #8,d0
                move.w  #$1C00,d1
                moveq   #1,d2
                lea     Sound_InitCommandData(pc),a0
                jsr     j_Sound_CopyToZ80RAM
                clr.w   (Ram_SoundQueueCount).w
                rts

Sound_InitCommandData:  dc.b    0, $80, 0, $12, $B4, 0, $E6, $80, $20, 0  ; was: byte_10D1A
; Loads Z80 data using table pointer in a1
Sound_LoadZ80Table:
                moveq   #2,d2                           ; was: sub_10D24
                movem.w (a1)+,d0-d1/a0
                suba.l  #Sys_GameEntryPoint,a0          ; !(UNKNOWN) DATA-001 offsets assume $10000
                jmp     j_Sound_CopyToZ80RAM

; Sends note/command to Z80 sound driver
Sound_PlayNote:
                move.l  a0,-(sp)                        ; was: sub_10D34
                jsr     j_Sound_RequestZ80Bus
                move.b  d0,(Z80_MusicCommand).l
                jsr     j_ReleaseZ80Bus
                movea.l (sp)+,a0
                rts

; Plays note only if sound channel is active
Sound_PlayNoteIfActive:
                tst.b   (Ram_SoundBusyFlag).w           ; was: sub_10D48
                bne.s   Sound_PlayNoteIfActive_Return
                bsr.s   Sound_PlayNote

Sound_PlayNoteIfActive_Return:                          ; was: locret_10D50
                rts

; Counts down sound channel cooldown timer
Sound_ChannelCooldown:
                tst.b   (Ram_SoundBusyFlag).w           ; was: sub_10D52
                beq.s   Sound_ChannelCooldown_Return
                addq.w  #1,(Ram_SoundCooldown).w
                cmpi.w  #$1E,(Ram_SoundCooldown).w
                bcs.s   Sound_ChannelCooldown_Return
                clr.w   (Ram_SoundCooldown).w
                clr.b   (Ram_SoundBusyFlag).w

Sound_ChannelCooldown_Return:                           ; was: locret_10D6C
                rts

; Converts offset d0 to VDP VRAM write command format
