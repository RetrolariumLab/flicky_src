; Game entry point and title-screen VRAM setup.
; ROM $010000-$0101D3.

Sys_GameEntryPoint:
                move    #$2700,sr  ; was: sub_10000
                move.l  #Int_VBlankHandler,(Ram_VBlankVector).w
                clr.w   (Ram_VBlankRequest).w
                move.w  #$40,(Ram_NextGameMode).w
                clr.w   (Ram_GameModeSpare2).w
                clr.w   (Ram_GameModeSpare1).w  ; !(UNKNOWN) RAM-001 written here and never read
                bsr.w   Gfx_InitCRAMAndClearVDP
                bsr.w   Sound_InitDriver
                bsr.w   LoadTilesToVRAM
                lea     (Ram_GroundTilePtr).w,a6
                moveq   #0,d7
                move.w  #$1FF,d6

Sys_GameEntryPoint_ClearObjectsLoop:  ; was: loc_10034
                move.l  d7,(a6)+
                dbf     d6,Sys_GameEntryPoint_ClearObjectsLoop
                move.l  #$40000010,(VDP_CTRL).l
                move.w  #0,(VDP_DATA).l
                move.l  #$40020010,(VDP_CTRL).l
                move.w  #0,(VDP_DATA).l
                bsr.w   Camera_ClearScroll
                move.w  #$101,(Ram_RoundNumber).w
                move    #$2500,sr

Sys_MainLoop:  ; was: loc_1006C
                movea.w (Sys_VectorTable+2).w,sp
                move.w  (Ram_NextGameMode).w,d0
                andi.l  #$7C,d0
                jsr     Sys_GameModeTable(pc,d0.w)
                addq.w  #1,(Ram_FrameCounter).w
                bra.s   Sys_MainLoop

Sys_GameModeTable:  ; was: loc_10084
                bra.w   Title_Init
                bra.w   Title_Update
                bra.w   Guide_Init
                bra.w   Guide_Update
                bra.w   RoundSelect_Init
                bra.w   RoundSelect_Update
                bra.w   Game_InitRound
                bra.w   Game_PreRoundDelay
                bra.w   Game_StartRound
                bra.w   Game_MainLoop
                bra.w   Bonus_Init
                bra.w   Bonus_MainLoop
                bra.w   Ending_Init
                bra.w   Ending_MainLoop
                bra.w   Demo_Init
                bra.w   Demo_Update
                bra.w   Sys_ModeLoadSegaScreen
                bra.w   Sys_ModeSegaScreen

Sys_ModeLoadSegaScreen:  ; was: loc_100CC
                jmp     LoadSegaScreen

Sys_ModeSegaScreen:  ; was: loc_100D0
                jmp     SegaScreen

; Initializes title screen objects and loads logo tiles
Sys_InitTitleScreen:
                jsr     j_Sys_InitGameState  ; was: sub_100D4
                lea     (Ram_SpriteTableCursor).w,a6
                moveq   #0,d7
                move.w  #$1FF,d6

Sys_InitTitleScreen_ClearLoop:  ; was: loc_100E2
                move.l  d7,(a6)+
                dbf     d6,Sys_InitTitleScreen_ClearLoop
                bsr.w   Camera_ClearScroll
                bsr.w   Object_ClearAllSlots
                move.w  #$8000,(Ram_TextTileBase).w
                jmp     LoadLogoAndExitToVRAM

LoadTilesToVRAM:
                move.w  #$200,d0
                jsr     j_Gfx_SetTileWriteAddr
                lea     (LevelTiles).l,a0
                jsr     j_Nem_Decomp
                move.w  #$400,d0
                jsr     j_Gfx_SetTileWriteAddr
                lea     (SpritesTiles).l,a0
                jsr     j_Nem_Decomp
                move.b  #1,(Ram_FontBankFlag).w

LoadTilesToVRAM_LoadFont:  ; was: loc_10126
                moveq   #$20,d0
                lea     (VDP_CTRL).l,a6
                jsr     j_Gfx_SetTileWriteAddr
                lea     (Jap1BPPTiles).w,a0
                moveq   #$20,d0
                add.b   (Ram_FontBankFlag).w,d0
                move.w  #$B3,d1
                jsr     j_Nem_DecompSetup
                moveq   #$30,d0
                lea     (VDP_CTRL).l,a6
                jsr     j_Gfx_SetTileWriteAddr
                lea     (Latin1BPPTiles).l,a0
                moveq   #$20,d0
                add.b   (Ram_FontBankFlag).w,d0
                move.w  #$2B,d1
                jsr     j_Nem_DecompSetup
                move.w  #$120,d0
                lea     (VDP_CTRL).l,a6
                jsr     j_Gfx_SetTileWriteAddr
                lea     (Jap1BPPTiles).w,a0
                moveq   #$30,d0
                add.b   (Ram_FontBankFlag).w,d0
                move.w  #$B3,d1
                jsr     j_Nem_DecompSetup
                move.w  #$130,d0
                lea     (VDP_CTRL).l,a6
                jsr     j_Gfx_SetTileWriteAddr
                lea     (Latin1BPPTiles).l,a0
                moveq   #$30,d0
                add.b   (Ram_FontBankFlag).w,d0
                move.w  #$2B,d1
                jsr     j_Nem_DecompSetup
                rts

LoadLogoAndExitToVRAM:
                lea     (VDP_CTRL).l,a6
                move.w  #$640,d0
                jsr     j_Gfx_SetTileWriteAddr
                lea     (ScoresTiles).l,a0
                jsr     j_Nem_Decomp
                move.w  #$693,d0
                jsr     j_Gfx_SetTileWriteAddr
                lea     (ExitTiles).l,a0
                jsr     j_Nem_Decomp
                rts

                ; org $81D4
