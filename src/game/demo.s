; Attract-mode demo playback.
; ROM $0139A2-$013E6F.

Demo_Init:
                jsr     Sys_InitTitleScreen  ; was: sub_139A2
                lea     (Gfx_ScreenInitData).l,a5
                jsr     unk_FFFBBA
                move.w  (word_FFD890).w,d0
                andi.w  #3,d0
                move.b  Demo_RoundHighTable(pc,d0.w),(word_FFD82C+1).w
                move.b  Demo_RoundLowTable(pc,d0.w),(word_FFD82C).w
                lsl.w   #1,d0
                move.w  Demo_InputStreamPointers(pc,d0.w),(word_FFD2AA).w
                moveq   #$FFFFFFFF,d1
                move.w  (word_FFD2AA).w,d1
                movea.l d1,a0
                move.b  (a0),(byte_FFD2A8).w
                move.b  1(a0),(byte_FFD2AC).w
                addq.w  #1,(word_FFD890).w
                bsr.w   Game_SetupLevel
                clr.l   (dword_FFD888).w
                clr.b   (byte_FFD88D).w
                move.b  #1,(byte_FFD2A5).w
                move.w  #$44,(word_FFC000).w
                bsr.w   Game_RoundStartSequence
                bsr.w   Game_CalcDifficulty
                jmp     unk_FFFB6C

Demo_RoundHighTable: dc.b    1, $A, $14, $18  ; was: byte_13A08
Demo_RoundLowTable: dc.b    1, $10, $20, $24  ; was: byte_13A0C
Demo_InputStreamPointers: dc.w    Demo_InputStream0-Sys_GameEntryPoint  ; was: off_13A10
                dc.w    Demo_InputStream1-Sys_GameEntryPoint
                dc.w    Demo_InputStream2-Sys_GameEntryPoint
                dc.w    Demo_InputStream3-Sys_GameEntryPoint
; Demo mode update: processes recorded input
Demo_Update:
                btst    #7,(word_FFFF8E+1).w  ; was: sub_13A18
                beq.s   Demo_Update_Run
                bsr.w   Gfx_FadeInPalette
                move.w  #0,(word_FFFFC0).w

Demo_Update_Run:  ; was: loc_13A2A
                bsr.w   Demo_ReadInput
                cmpi.l  #$1C000,(dword_FFD296).w
                bgt.s   Demo_Update_Objects
                addq.l  #7,(dword_FFD296).w

Demo_Update_Objects:  ; was: loc_13A3C
                bsr.w   Enemy_SpawnCats
                bsr.w   Object_UpdateAll
                bsr.w   Timer_IncrementTime
                bclr    #0,(byte_FFD886).w
                beq.s   Demo_Update_Return
                bsr.w   Gfx_FadeInPalette
                move.w  #$40,(word_FFFFC0).w

Demo_Update_Return:  ; was: loc_13A5A
                jmp     unk_FFFB6C

; Reads next input from demo data stream
Demo_ReadInput:
                moveq   #$FFFFFFFF,d0  ; was: sub_13A5E
                move.w  (word_FFD2AA).w,d0
                movea.l d0,a0
                move.b  (a0),(word_FFFF8E).w
                subq.b  #1,(byte_FFD2AC).w
                bne.s   Demo_ReadInput_Return
                addq.l  #2,a0
                move.b  (a0),(byte_FFD2A8).w
                move.b  1(a0),(byte_FFD2AC).w
                move.w  a0,(word_FFD2AA).w

Demo_ReadInput_Return:  ; was: locret_13A80
                rts

Demo_InputStream0: binclude "data/other/data_word_13A82.bin"  ; was: word_13A82
Demo_InputStream0_End:  ; was: word_13A82_End
Demo_InputStream1: dc.w    $12, $801, $A09, $4A11, $A17, $14, $4004, $4A0B  ; was: word_13B82
                dc.w    $A5A, $1C, $A0C, 9, $403, $502, $409, $1E
                dc.w    $407, 3, $801, $A0F, $602, $40D, $4405, $400B
                dc.w    $23, $408, 9, $40E, $441F, $D, $410, $440F
                dc.w    $41C, $17, $A1B, $802, $46, $410, $2B, $40E
                dc.w    $400C, $1F, $A0B, $4A12, $A35, $4A17, $4802, $4001
                dc.w    3, $410, $21, $404, $507, $4508, $4403, $4008
                dc.w    $4801, $4A0D, $A05, $B, $40A, 7, $408, $33
                dc.w    $420, 3, $A12, $A, $40A, $501, 1, $A10
                dc.w    $201, $17, $A17, $801, 4, $802, $A07, $4A0D
                dc.w    $4201, $4407, $4502, $4403, $4001, $19, $801, $A07
                dc.w    $201, $406, $4405, $4003, 8, $A1E, $10, $A13
                dc.w    $801, $1A, $414, $1F, $403, $504, $40C, $43
Demo_InputStream2: binclude "data/other/data_word_13C52.bin"  ; was: word_13C52
Demo_InputStream2_End:  ; was: word_13C52_End
Demo_InputStream3: binclude "data/other/data_word_13D70.bin"  ; was: word_13D70
Demo_InputStream3_End:  ; was: word_13D70_End
; Player main object: states and collision
