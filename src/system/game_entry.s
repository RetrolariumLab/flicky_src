; Game entry point and title-screen VRAM setup.
; ROM $010000-$0101D3.

Sys_GameEntryPoint:
                move    #$2700,sr  ; was: sub_10000
                move.l  #Int_VBlankHandler,(dword_FFFA7E).w
                clr.w   (word_FFFF96).w
                move.w  #$40,(word_FFFFC0).w
                clr.w   (word_FFFFC4).w
                clr.w   (word_FFFFC2).w
                bsr.w   Gfx_InitCRAMAndClearVDP
                bsr.w   Sound_InitDriver
                bsr.w   LoadTilesToVRAM
                lea     (dword_FFD800).w,a6
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
                move.w  #$101,(word_FFD82C).w
                move    #$2500,sr

Sys_MainLoop:  ; was: loc_1006C
                movea.w (Sys_VectorTable+2).w,sp
                move.w  (word_FFFFC0).w,d0
                andi.l  #$7C,d0
                jsr     Sys_GameModeTable(pc,d0.w)
                addq.w  #1,(word_FFFF92).w
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
                jsr     unk_FFFBB4  ; was: sub_100D4
                lea     (word_FFD000).w,a6
                moveq   #0,d7
                move.w  #$1FF,d6

Sys_InitTitleScreen_ClearLoop:  ; was: loc_100E2
                move.l  d7,(a6)+
                dbf     d6,Sys_InitTitleScreen_ClearLoop
                bsr.w   Camera_ClearScroll
                bsr.w   Object_ClearAllSlots
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

LoadTilesToVRAM_LoadFont:  ; was: loc_10126
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

                ; org $81D4
