; Sound driver init and note playback.
; ROM $010CD4-$010D6D.

Gfx_InitCRAMAndClearVDP:
                move.l  #$C0000000,(VDP_CTRL).l  ; was: sub_10CD4
                moveq   #$3F,d0

loc_10CE0:
                move.w  #0,(VDP_DATA).l
                dbf     d0,loc_10CE0
                moveq   #0,d2
                move.w  #$A800,d0
                jmp     unk_FFFAD6

; Loads Z80 sound driver and initializes audio system
Sound_InitDriver:
                jsr     j_LoadZ80Driver  ; was: sub_10CF6
                lea     (z80_part2).l,a1
                bsr.s   Sound_LoadZ80Table
                bsr.s   Sound_LoadZ80Table
                moveq   #8,d0
                move.w  #$1C00,d1
                moveq   #1,d2
                lea     byte_10D1A(pc),a0
                jsr     unk_FFFB54
                clr.w   (word_FFFFA2).w
                rts

byte_10D1A:     dc.b    0, $80, 0, $12, $B4, 0, $E6, $80, $20, 0
; Loads Z80 data using table pointer in a1
Sound_LoadZ80Table:
                moveq   #2,d2  ; was: sub_10D24
                movem.w (a1)+,d0-d1/a0
                suba.l  #Sys_GameEntryPoint,a0
                jmp     unk_FFFB54

; Sends note/command to Z80 sound driver
Sound_PlayNote:
                move.l  a0,-(sp)  ; was: sub_10D34
                jsr     unk_FFFB36
                move.b  d0,(byte_A01C09).l
                jsr     unk_FFFB3C
                movea.l (sp)+,a0
                rts

; Plays note only if sound channel is active
Sound_PlayNoteIfActive:
                tst.b   (byte_FFD2A4).w  ; was: sub_10D48
                bne.s   locret_10D50
                bsr.s   Sound_PlayNote

locret_10D50:
                rts

; Counts down sound channel cooldown timer
Sound_ChannelCooldown:
                tst.b   (byte_FFD2A4).w  ; was: sub_10D52
                beq.s   locret_10D6C
                addq.w  #1,(word_FFD2A2).w
                cmpi.w  #$1E,(word_FFD2A2).w
                bcs.s   locret_10D6C
                clr.w   (word_FFD2A2).w
                clr.b   (byte_FFD2A4).w

locret_10D6C:
                rts

; Converts offset d0 to VDP VRAM write command format
