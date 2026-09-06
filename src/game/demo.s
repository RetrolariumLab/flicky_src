; Attract-mode demo playback
; ROM $0139A2-$013E6F
;
; !(OBS) The longplay presses start before the attract demos begin, so this file
; is only reached by the demos recording. Replaying it holds Ram_Score at zero
; across the whole demo while chicks are caught, which is how the two round
; tables below were told apart: the index one feeds Ram_RoundNumber+1 and the
; display one the BCD byte the HUD prints

Demo_Init:
                jsr     Sys_InitTitleScreen
                lea     (Gfx_SharedPalette).l,a5
                jsr     j_Gfx_LoadPaletteCompact
                move.w  (Ram_DemoIndex).w,d0
                andi.w  #3,d0
                move.b  Demo_RoundIndexTable(pc,d0.w),(Ram_RoundNumber+1).w
                move.b  Demo_RoundDisplayTable(pc,d0.w),(Ram_RoundNumber).w
                lsl.w   #1,d0
                move.w  Demo_InputStreamPointers(pc,d0.w),(Ram_DemoStreamPtr).w
                moveq   #$FFFFFFFF,d1
                move.w  (Ram_DemoStreamPtr).w,d1
                movea.l d1,a0
                move.b  (a0),(Ram_DemoInputByte).w
                move.b  1(a0),(Ram_DemoHoldFrames).w
                addq.w  #1,(Ram_DemoIndex).w
                bsr.w   Game_SetupLevel
                clr.l   (Ram_RoundTime).w
                clr.b   (Ram_ExitReachedFlag).w
                move.b  #1,(Ram_DemoModeFlag).w
                move.w  #$44,(Ram_ObjectSlots).w
                bsr.w   Game_RoundStartSequence
                bsr.w   Game_CalcDifficulty
                jmp     j_Sound_QueueSFX

Demo_RoundIndexTable:       dc.b    1, $A, $14, $18
Demo_RoundDisplayTable:     dc.b    1, $10, $20, $24
Demo_InputStreamPointers:   dc.w    Demo_InputStream0-Sys_GameEntryPoint
                dc.w    Demo_InputStream1-Sys_GameEntryPoint
                dc.w    Demo_InputStream2-Sys_GameEntryPoint
                dc.w    Demo_InputStream3-Sys_GameEntryPoint
; Demo mode update: processes recorded input
Demo_Update:
                btst    #7,(Ram_Joypad+1).w
                beq.s   Demo_Update_Run
                bsr.w   Gfx_FadeInPalette
                move.w  #0,(Ram_NextGameMode).w

Demo_Update_Run:
                bsr.w   Demo_ReadInput
                cmpi.l  #$1C000,(Ram_LizardSpeed).w
                bgt.s   Demo_Update_Objects
                addq.l  #7,(Ram_LizardSpeed).w

Demo_Update_Objects:
                bsr.w   Enemy_SpawnCats
                bsr.w   Object_UpdateAll
                bsr.w   Timer_IncrementTime
                bclr    #0,(Ram_RestoreEnemiesFlag).w
                beq.s   Demo_Update_Return
                bsr.w   Gfx_FadeInPalette
                move.w  #$40,(Ram_NextGameMode).w

Demo_Update_Return:
                jmp     j_Sound_QueueSFX

; Reads next input from demo data stream
Demo_ReadInput:
                moveq   #$FFFFFFFF,d0
                move.w  (Ram_DemoStreamPtr).w,d0
                movea.l d0,a0
                move.b  (a0),(Ram_Joypad).w
                subq.b  #1,(Ram_DemoHoldFrames).w
                bne.s   Demo_ReadInput_Return
                addq.l  #2,a0
                move.b  (a0),(Ram_DemoInputByte).w
                move.b  1(a0),(Ram_DemoHoldFrames).w
                move.w  a0,(Ram_DemoStreamPtr).w

Demo_ReadInput_Return:
                rts

Demo_InputStream0:  binclude "data/other/data_DemoInputStream0.bin"
Demo_InputStream0_End:
Demo_InputStream1:  dc.w    $12, $801, $A09, $4A11, $A17, $14, $4004, $4A0B
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
Demo_InputStream2:  binclude "data/other/data_DemoInputStream2.bin"
Demo_InputStream2_End:
Demo_InputStream3:  binclude "data/other/data_DemoInputStream3.bin"
Demo_InputStream3_End:
; Player main object: states and collision
