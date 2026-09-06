; Title screen and its objects
; ROM $011FB0-$01228D

Title_Init:
                bsr.w   Sys_InitTitleScreen
                move.w  #$740,d0
                jsr     j_Gfx_SetTileWriteAddr
                lea     (Data_FlickyLogoTiles).l,a0
                jsr     j_Nem_Decomp
                clr.b   (Ram_FontBankFlag).w
                bsr.w   Gfx_LoadTilesToVRAM_LoadFont
                lea     (Gfx_SharedPalette).l,a5
                jsr     j_Gfx_LoadPaletteCompact
                lea     Title_LogoPalette(pc),a0
                lea     (Ram_TitlePaletteSlot).w,a1
                moveq   #3,d0

Title_Init_CopyPaletteLoop:
                move.l  (a0)+,(a1)+
                dbf     d0,Title_Init_CopyPaletteLoop
                moveq   #5,d0
                lea     Title_TextPointers(pc),a0
                btst    #7,(IO_PCBVER+1).l
                beq.s   Title_Init_DrawTextLoop
                lea     Title_TextPointersAlt(pc),a0

Title_Init_DrawTextLoop:
                movea.l (a0)+,a6
                bsr.w   Text_DrawString
                dbf     d0,Title_Init_DrawTextLoop
                move.b  #3,(Ram_Lives).w
                move.w  #$101,(Ram_RoundNumber).w
                move.b  #1,(Ram_SkipBonusFlag).w
                lea     (Ram_ObjectSlots).w,a0
                moveq   #0,d1
                moveq   #3,d0

Title_Init_SpawnBirdsLoop:
                move.w  #$40,(a0)
                move.w  d1,$38(a0)
                lea     $40(a0),a0
                addq.w  #1,d1
                dbf     d0,Title_Init_SpawnBirdsLoop
                move.w  #$44,(a0)
                lea     (Ram_TitleStaticSlots).w,a0
                moveq   #0,d1
                moveq   #5,d0

Title_Init_SpawnStaticLoop:
                move.w  #$48,(a0)
                move.w  d1,$38(a0)
                lea     $40(a0),a0
                addq.w  #1,d1
                dbf     d0,Title_Init_SpawnStaticLoop
                btst    #7,(IO_PCBVER+1).l
                beq.s   Title_Init_DrawHUD
                lea     Title_TrademarkLabel(pc),a6
                bsr.w   Text_DrawDoubleHeight

Title_Init_DrawHUD:
                bsr.w   UI_Draw1UPAndHILabels
                bsr.w   UI_DrawScore
                bsr.w   UI_DrawHighScore
                bsr.w   Object_UpdateAll
                clr.w   (Ram_FrameCounter).w
                move.b  #$85,d0
                jsr     j_Sound_QueueToBuffer
                jsr     j_Sound_QueueSFX
                jmp     j_Sound_QueueSFX

Title_TextPointers: dc.l    Title_CastLabel
                dc.l    Title_FlickyLabel
                dc.l    Title_PiopioLabel
                dc.l    Title_NyannyanLabel
                dc.l    Title_ChoroLabel
                dc.l    Title_CopyrightLabel
Title_TextPointersAlt:  dc.l    Title_CastLabel
                dc.l    Title_FlickyLabel
                dc.l    Title_ChirpLabel
                dc.l    Title_TigerLabel
                dc.l    Title_IggyLabel
                dc.l    Title_CopyrightLabel
Title_CastLabel:    dc.b    $C2, $9C
Title_CastText:     dc.b    "CAST",0
                dc.b    0
Title_FlickyLabel:  dc.b    $C3, $10
Title_FlickyText:   dc.b    "FLICKY",0
                dc.b    0
Title_PiopioLabel:  dc.b    $C3, $28
Title_PiopioText:   dc.b    "PIOPIO",0
                dc.b    0
Title_NyannyanLabel:    dc.b    $C3, $D0
Title_NyannyanText:     dc.b    "NYANNYAN",0
                dc.b    0
Title_ChoroLabel:       dc.b    $C3, $E8
Title_ChoroText:        dc.b    "CHORO",0
Title_CopyrightLabel:   dc.b    $C6, $54
Title_Sega1991Text:     dc.b    $27," SEGA 1991",0
Title_ChirpLabel:       dc.b    $C3, $28
Title_ChirpText:        dc.b    "CHIRP",0
Title_TigerLabel:       dc.b    $C3, $D0
Title_TigerText:        dc.b    "TIGER",0
Title_IggyLabel:        dc.b    $C3, $E8
Title_IggyText:         dc.b    "IGGY",0
                dc.b    0
Title_LogoPalette:      dc.w    0, $EEE, $EAE, $C6E, $A4E, $A2E, $60A, 0
Title_TrademarkLabel:   dc.b    $C0, $EE
Title_TmText:           dc.b    "TM",0
                dc.b    0
; Title screen update: handles start button and fade
Title_Update:
                btst    #7,(Ram_Joypad+1).w
                beq.s   Title_Update_CheckTimeout
                bsr.w   Gfx_FadeInPalette
                move.b  #$E0,d0
                bsr.w   Sound_PlayNote
                move.b  #1,(Ram_FontBankFlag).w
                bsr.w   Gfx_LoadTilesToVRAM_LoadFont
                move.w  #8,(Ram_NextGameMode).w

Title_Update_CheckTimeout:
                cmpi.w  #$400,(Ram_FrameCounter).w
                bcs.s   Title_Update_Draw
                bsr.w   Gfx_FadeInPalette
                move.b  #$E0,d0
                bsr.w   Sound_PlayNote
                move.b  #1,(Ram_FontBankFlag).w
                bsr.w   Gfx_LoadTilesToVRAM_LoadFont
                move.w  #$38,(Ram_NextGameMode).w

Title_Update_Draw:
                bsr.w   Object_UpdateAll
                jmp     j_Sound_QueueSFX

; Title screen Flicky bird animation object
Obj_TitleBird:
                bset    #7,(a0)
                bne.s   Obj_TitleBird_Animate
                bset    #7,2(a0)
                move.w  $38(a0),d0
                lsl.w   #1,d0
                move.w  Title_BirdAnimIndexTable(pc,d0.w),6(a0)
                lsl.w   #1,d0
                move.l  Title_BirdAnimPointers(pc,d0.w),8(a0)
                move.w  Title_BirdXTable(pc,d0.w),$20(a0)
                move.w  Title_BirdYTable(pc,d0.w),$24(a0)

Obj_TitleBird_Animate:
                bsr.w   Anim_UpdateFrame
                rts

Title_BirdAnimPointers: dc.l    Player_AnimPointers
                dc.l    Cat_AnimPointers
                dc.l    Lizard_AnimPointers
                dc.l    Snake_AnimPointers
Title_BirdAnimIndexTable:   dc.w    0, 4, 4, 0
Title_BirdXTable:           dc.w    $B0
Title_BirdYTable:           dc.w    $F0, $110, $EC, $B0, $108, $110, $100
; Title screen cursor with blink state machine
Obj_TitleCursor:
                bset    #7,(a0)
                bne.s   Obj_TitleCursor_Dispatch
                move.l  #Obj_TitleCursorData,$C(a0)
                move.w  #$F0,$20(a0)
                move.w  #$120,$24(a0)

Obj_TitleCursor_Dispatch:
                move.w  $3C(a0),d0
                andi.w  #$7C,d0
                jsr     Title_CursorStateTable(pc,d0.w)
                rts

Title_CursorStateTable:
                bra.w   Obj_CursorWait
                bra.w   Obj_CursorBlink

; Cursor wait state: timer before showing
Obj_CursorWait:
                bset    #7,$3C(a0)
                bne.s   Obj_CursorWait_Countdown
                bclr    #1,2(a0)
                move.w  #$3C,$3A(a0)

Obj_CursorWait_Countdown:
                subq.w  #1,$3A(a0)
                bne.s   Obj_CursorWait_Return
                move.w  #4,$3C(a0)

Obj_CursorWait_Return:
                rts

; Cursor blink state: show then hide cycle
Obj_CursorBlink:
                bset    #7,$3C(a0)
                bne.s   Obj_CursorBlink_Countdown
                bset    #1,2(a0)
                move.w  #$14,$3A(a0)

Obj_CursorBlink_Countdown:
                subq.w  #1,$3A(a0)
                bne.s   Obj_CursorBlink_Return
                clr.w   $3C(a0)

Obj_CursorBlink_Return:
                rts

; Title screen static sprite objects
Obj_TitleStatic:
                bset    #7,(a0)
                bne.s   Obj_TitleStatic_Return
                move.w  $38(a0),d0
                lsl.w   #2,d0
                move.l  Title_StaticMappingPointers(pc,d0.w),$C(a0)
                move.w  Title_StaticXTable(pc,d0.w),$20(a0)
                move.w  Title_StaticYTable(pc,d0.w),$24(a0)

Obj_TitleStatic_Return:
                rts

Title_StaticMappingPointers:    dc.l    Title_StaticMap0
                dc.l    Title_StaticMap1
                dc.l    Title_StaticMap2
                dc.l    Title_StaticMap3
                dc.l    Title_StaticMap4
                dc.l    Title_StaticMap5
Title_StaticXTable: dc.w    $D0
Title_StaticYTable: dc.w    $C0, $E5, $C0, $F7, $C0, $107, $C0, $11C, $C0, $133, $C0
; Guide/How-to-play screen initialization
