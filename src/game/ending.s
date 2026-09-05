; Ending sequence and credits.
; ROM $013110-$0139A1.

Ending_Init:
                jsr     Sys_InitTitleScreen  ; was: sub_13110
                clr.b   (byte_FFD88E).w
                bsr.w   LoadTilesToVRAM_LoadFont
                lea     (Gfx_ScreenInitData).l,a5
                jsr     unk_FFFBBA
                move.w  #$800,(word_FFF7E0).w
                bsr.w   Ending_DrawGraphics
                move    #$2700,sr
                moveq   #2,d2
                move.w  #$3BA,d0
                move.w  #$125B,d1
                lea     (Ending_CongratsArt).l,a0
                jsr     unk_FFFB54
                move    #$2500,sr
                move.b  #$81,d0
                jsr     unk_FFFB66
                clr.w   (word_FFFF92).w
                jsr     unk_FFFB6C
                jmp     unk_FFFB6C

; Ending sequence main loop with state dispatcher
Ending_MainLoop:
                move.w  (word_FFD29E).w,d0  ; was: sub_13162
                andi.w  #$7FFC,d0
                jsr     Ending_StateTable(pc,d0.w)
                bsr.w   Object_UpdateAll
                jmp     unk_FFFB6C

Ending_StateTable:  ; was: loc_13176
                bra.w   Ending_StateWait
                bra.w   Ending_StateCredits
                bra.w   Ending_StateRestart

; Ending state: wait then show congratulations
Ending_StateWait:
                bsr.w   Ending_BlinkText  ; was: sub_13182
                cmpi.w  #$C8,(word_FFFF92).w
                bne.s   Ending_StateWait_Return
                move.w  #4,(word_FFD29E).w
                move.w  #$8100,(word_FFD884).w
                move.w  #$EEE,(word_FFF7E6).w
                bsr.w   Ending_DrawCongrats
                move.l  #$EFFFFFFF,(dword_FFFFB8).w
                move.l  #$FFFFFFFF,(dword_FFFFBC).w
                bsr.w   Gfx_FadeInPalette
                lea     (VDP_DATA).l,a0
                move.l  #$40000003,(VDP_CTRL).l
                move.w  #$3FF,d0

Ending_StateWait_ClearPlaneLoop:  ; was: loc_131CC
                move.w  #0,(a0)
                dbf     d0,Ending_StateWait_ClearPlaneLoop

Ending_StateWait_Return:  ; was: locret_131D4
                rts

; Cycles text blink effect for ending screen
Ending_BlinkText:
                bsr.w   Text_CycleBlink  ; was: sub_131D6

; Draws congratulations messages on ending
Ending_DrawCongrats:
                lea     Ending_CongratsLabel(pc),a6  ; was: sub_131DA
                bsr.w   Text_DrawString
                lea     Ending_SuperPlayerLabel(pc),a6
                bsr.w   Text_DrawString
                rts

Ending_CongratsLabel: dc.b    $C2, $90  ; was: byte_131EC
aCongratulation: dc.b    "CONGRATULATIONS!",0
                dc.b    0
Ending_SuperPlayerLabel: dc.b    $C3, $8A  ; was: byte_13200
aYouAreASuperPl: dc.b    "YOU ARE A SUPER PLAYER.",0
; Ending state: scrolling credits sequence
Ending_StateCredits:
                bset    #7,(word_FFD29E).w  ; was: sub_1321A
                bne.s   Ending_StateCredits_Scroll
                lea     (Gfx_ScreenInitData).l,a5
                jsr     unk_FFFBBA
                move.w  #$EEE,(word_FFF7E6).w
                clr.l   (dword_FFFFB8).w
                clr.l   (dword_FFFFBC).w
                move.w  #$4000,(dword_FFD008+2).w
                lea     (word_FFC000).w,a0
                moveq   #0,d1
                moveq   #4,d0

Ending_StateCredits_SpawnLoop:  ; was: loc_13248
                move.w  #$50,(a0)
                move.w  d1,$38(a0)
                lea     $40(a0),a0
                addq.w  #1,d1
                dbf     d0,Ending_StateCredits_SpawnLoop

Ending_StateCredits_Scroll:  ; was: loc_1325A
                bsr.w   Camera_UpdateScroll
                addq.b  #1,(byte_FFD29D).w
                cmpi.b  #$20,(byte_FFD29D).w
                bne.s   Ending_StateCredits_Return
                clr.b   (byte_FFD29D).w
                bsr.w   Ending_DrawCreditsLine
                addq.b  #1,(byte_FFD29C).w
                cmpi.b  #$5D,(byte_FFD29C).w
                bne.s   Ending_StateCredits_Return
                move.w  #8,(word_FFD29E).w
                lea     (word_FFC000).w,a0
                move.w  #$44,(a0)

Ending_StateCredits_Return:  ; was: locret_1328C
                rts

; Draws single credits line during scroll
Ending_DrawCreditsLine:
                moveq   #0,d0  ; was: sub_1328E
                moveq   #0,d5
                move.w  (dword_FFFFA4).w,d0
                andi.w  #$FF,d0
                lsr.w   #3,d0
                subq.w  #2,d0
                bpl.s   Ending_DrawCreditsLine_Wrap
                addi.w  #$20,d0

Ending_DrawCreditsLine_Wrap:  ; was: loc_132A4
                lsl.w   #6,d0
                addi.w  #-$3FF8,d0
                move.w  d0,d5
                move.w  d5,d6
                bsr.w   Gfx_MakeVDPWriteCmd
                move.l  d5,(VDP_CTRL).l
                moveq   #$1F,d1

Ending_DrawCreditsLine_ClearRowLoop:  ; was: loc_132BA
                move.w  #0,(VDP_DATA).l
                dbf     d1,Ending_DrawCreditsLine_ClearRowLoop
                moveq   #0,d1
                move.b  (byte_FFD29C).w,d1
                lsl.w   #1,d1
                moveq   #$FFFFFFFF,d2
                lea     Ending_CreditsLinePointers(pc),a6  ; "     STAFF"
                move.w  (a6,d1.w),d2
                movea.l d2,a6
                bsr.w   Text_DrawString_Loop
                rts

Ending_CreditsLinePointers: dc.w    aStaff-Sys_GameEntryPoint  ; was: off_132E0
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    aDirector-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    aKFuzzy-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    aDesigner-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    aYumi-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    aProgrammer-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    aOSamu-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    aSoundDesign-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    aTSMusic-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    aAnd-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    aSpecialThanks-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    aLee-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    aBo-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    aArcadeFlickySt-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    aTestPlayers-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    aChallengeTheNe-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
                dc.w    Ending_BlankLine-Sys_GameEntryPoint
Ending_BlankLine: dc.b    0, 0  ; was: byte_1339C
aStaff:         dc.b    "     STAFF",0
                dc.b    0
aDirector:      dc.b    "    DIRECTOR",0
                dc.b    0
aKFuzzy:        dc.b    "     K.FUZZY",0
                dc.b    0
aDesigner:      dc.b    "    DESIGNER",0
                dc.b    0
aYumi:          dc.b    "     YUMI",0
aProgrammer:    dc.b    "    PROGRAMMER",0
                dc.b    0
aOSamu:         dc.b    "     O.SAMU",0
aSoundDesign:   dc.b    "    SOUND DESIGN",0
                dc.b    0
aTSMusic:       dc.b    "     T@S MUSIC",0
                dc.b    0
aAnd:           dc.b    "      AND",0
aSpecialThanks: dc.b    "    SPECIAL THANKS",0
                dc.b    0
aArcadeFlickySt: dc.b    "     ARCADE FLICKY STAFF",0
                dc.b    0
aTestPlayers:   dc.b    "     TEST PLAYERS",0
aLee:           dc.b    "     LEE",0
                dc.b    0
aBo:            dc.b    "     BO",0
aChallengeTheNe: dc.b    "CHALLENGE THE NEXT STAGE.",0
; Ending state: wait for start to restart game
Ending_StateRestart:
                btst    #7,(word_FFFF8E+1).w  ; was: sub_13492
                beq.s   Ending_StateRestart_Return
                bsr.w   Gfx_FadeInPalette
                move.b  #1,(byte_FFD88E).w
                bsr.w   LoadTilesToVRAM_LoadFont
                move.w  #$18,(word_FFFFC0).w
                move    #$2700,sr
                bsr.w   Sound_InitDriver
                move    #$2500,sr

Ending_StateRestart_Return:  ; was: locret_134BA
                rts

; Credits character object appearing during scroll
Obj_CreditsCharacter:
                bset    #7,(a0)  ; was: sub_134BC
                bne.s   Obj_CreditsCharacter_Dispatch
                bset    #1,2(a0)
                move.w  $38(a0),d0
                move.b  Ending_CreditsAppearLines(pc,d0.w),$3A(a0)
                lsl.w   #1,d0
                move.w  Ending_CreditsAnimIndexTable(pc,d0.w),6(a0)
                lsl.w   #1,d0
                move.l  Ending_CreditsAnimPointers(pc,d0.w),8(a0)

Obj_CreditsCharacter_Dispatch:  ; was: loc_134E2
                move.w  $3C(a0),d0
                andi.w  #$7FFC,d0
                jsr     Ending_CreditsStateTable(pc,d0.w)
                rts

Ending_CreditsStateTable:  ; was: loc_134F0
                bra.w   Obj_CreditsWait
                bra.w   Obj_CreditsFlyUp

Ending_CreditsAnimPointers: dc.l    Player_AnimPointers  ; was: off_134F8
                dc.l    Cat_AnimPointers
                dc.l    Cat_AnimPointersAlt
                dc.l    Lizard_AnimPointers
                dc.l    Snake_AnimPointers
Ending_CreditsAnimIndexTable: dc.w    4, 0, 0, 8, $10  ; was: word_1350C
Ending_CreditsAppearLines: dc.w    $D17, $212B, $3D00  ; was: word_13516
; Credits character wait state: waits for scroll line
Obj_CreditsWait:
                move.b  (byte_FFD29C).w,d0  ; was: sub_1351C
                cmp.b   $3A(a0),d0
                bne.s   Obj_CreditsWait_Return
                move.w  #4,$3C(a0)

Obj_CreditsWait_Return:  ; was: locret_1352C
                rts

; Credits character fly state: exits upward
Obj_CreditsFlyUp:
                bset    #7,$3C(a0)  ; was: sub_1352E
                bne.s   Obj_CreditsFlyUp_Move
                move.w  #$E4,$30(a0)
                move.w  #$178,$24(a0)
                move.l  #$FFFFC000,$2C(a0)
                bclr    #1,2(a0)

Obj_CreditsFlyUp_Move:  ; was: loc_13550
                bsr.w   Object_UpdatePosition
                cmpi.w  #$78,$24(a0)
                bgt.s   Obj_CreditsFlyUp_Animate
                bsr.w   Object_ClearSlot

Obj_CreditsFlyUp_Animate:  ; was: loc_13560
                bsr.w   Anim_UpdateFrame
                rts

; Draws congratulations screen tilemaps
Ending_DrawGraphics:
                moveq   #9,d0  ; was: sub_13566
                moveq   #0,d1

Ending_DrawGraphics_Loop:  ; was: loc_1356A
                moveq   #0,d5
                movem.l d0-d1,-(sp)
                lsl.w   #1,d1
                move.w  Ending_GraphicsPositions(pc,d1.w),d5
                moveq   #$FFFFFFFF,d2
                move.w  Ending_GraphicsMappingPointers(pc,d1.w),d2
                movea.l d2,a6
                lsl.w   #1,d1
                move.w  Ending_GraphicsSizeTable(pc,d1.w),d7
                move.w  Ending_GraphicsSizeTable+2(pc,d1.w),d6
                bsr.w   Gfx_DrawTilemapStart
                movem.l (sp)+,d0-d1
                addq.w  #1,d1
                dbf     d0,Ending_DrawGraphics_Loop
                rts

Ending_GraphicsMappingPointers: dc.w    Ending_GraphicsMap0-Sys_GameEntryPoint  ; was: off_13598
                dc.w    Ending_GraphicsMap1-Sys_GameEntryPoint
                dc.w    Ending_GraphicsMap2-Sys_GameEntryPoint
                dc.w    Ending_GraphicsMap2-Sys_GameEntryPoint
                dc.w    Ending_GraphicsMap2-Sys_GameEntryPoint
                dc.w    Ending_GraphicsMap2-Sys_GameEntryPoint
                dc.w    Ending_GraphicsMap2-Sys_GameEntryPoint
                dc.w    Ending_GraphicsMap2-Sys_GameEntryPoint
                dc.w    Ending_GraphicsMap0-Sys_GameEntryPoint
                dc.w    Ending_GraphicsMap1-Sys_GameEntryPoint
Ending_GraphicsSizeTable: dc.b    0, 3, 0, 3, 0, 4, 0, 2, 0, 4  ; was: byte_135AC
                dc.b    0, 2, 0, 4, 0, 2, 0, 4, 0, 2
                dc.b    0, 4, 0, 2, 0, 4, 0, 2, 0, 4
                dc.b    0, 2, 0, 3, 0, 3, 0, 4, 0, 2
Ending_GraphicsPositions: dc.w    $E132, $E4B2, $E642, $E64C, $E656, $E660, $E66A, $E674, $E446, $E146  ; was: word_135D4
Ending_CongratsArt: binclude "data/other/data_word_135E8.bin"  ; was: word_135E8
Ending_CongratsArt_End:  ; was: word_135E8_End
; Demo/attract mode initialization
