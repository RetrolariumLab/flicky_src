; Guide screen.
; ROM $01228E-$0125BD.

Guide_Init:
                moveq   #7,d1  ; was: sub_1228E

Guide_Init_WaitLoop:  ; was: loc_12290
                jsr     j_Sound_QueueSFX
                dbf     d1,Guide_Init_WaitLoop
                bsr.w   Sys_InitTitleScreen
                lea     (Gfx_SharedPalette).l,a5
                jsr     j_Gfx_LoadPaletteCompact
                clr.l   (Ram_Score).w
                clr.b   (Ram_ExtraLifeFlags).w
                bsr.w   Level_LoadTileset
                bsr.w   Level_LoadPalette
                bsr.w   Guide_DrawText
                lea     (Ram_ObjectSlots).w,a0
                moveq   #0,d1
                moveq   #$13,d0

Guide_Init_SpawnCharactersLoop:  ; was: loc_122C2
                move.w  #$4C,(a0)
                move.w  d1,$38(a0)
                lea     $40(a0),a0
                addq.w  #1,d1
                dbf     d0,Guide_Init_SpawnCharactersLoop
                bsr.w   Object_UpdateAll
                jsr     j_Sound_QueueSFX
                jmp     j_Sound_QueueSFX

; Guide screen update: handles input and fade
Guide_Update:
                btst    #7,(Ram_Joypad+1).w  ; was: sub_122E0
                beq.s   Guide_Update_Return
                move.w  #$18,(Ram_NextGameMode).w
                move.b  (Ram_Joypad).w,d0
                bclr    #7,d0
                cmpi.b  #$61,d0
                bne.s   Guide_Update_Fade
                move.w  #$10,(Ram_NextGameMode).w

Guide_Update_Fade:  ; was: loc_12302
                bsr.w   Gfx_FadeInPalette

Guide_Update_Return:  ; was: loc_12306
                jmp     j_Sound_QueueSFX

; Draws guide screen text and demo level graphics
Guide_DrawText:
                moveq   #5,d0  ; was: sub_1230A
                lea     Guide_TextPointersJP(pc),a0
                btst    #7,(IO_PCBVER+1).l
                beq.s   Guide_DrawText_Loop
                lea     Guide_TextPointers(pc),a0

Guide_DrawText_Loop:  ; was: loc_1231E
                movea.l (a0)+,a6
                bsr.w   Text_DrawDoubleHeight
                dbf     d0,Guide_DrawText_Loop
                lea     (Ram_PlayerStartX).w,a0
                moveq   #$E,d7
                btst    #7,(IO_PCBVER+1).l
                beq.s   Guide_DrawText_DrawScene
                moveq   #$F,d7

Guide_DrawText_DrawScene:  ; was: loc_1233A
                moveq   #6,d6
                moveq   #0,d4
                move.b  d7,(a0)
                move.b  d6,1(a0)
                bsr.w   Level_DrawBackgroundObject
                bsr.w   Level_DrawEntryArrow
                moveq   #5,d7
                moveq   #$17,d6
                moveq   #0,d4
                move.b  d7,(a0)
                move.b  d6,1(a0)
                bsr.w   Level_DrawBackgroundObject
                bsr.w   Level_DrawEntryArrow
                bsr.w   Level_DrawLowerGround
                bsr.w   Level_DrawUpperGround
                lea     (VDP_DATA).l,a0
                move.l  #$648A0003,(VDP_CTRL).l
                moveq   #$15,d0

Guide_DrawText_GroundLoop:  ; was: loc_1237A
                move.w  #$220D,(a0)
                dbf     d0,Guide_DrawText_GroundLoop
                rts

Guide_TextPointersJP: dc.l    Guide_TitleLabelJP  ; was: off_12384
                dc.l    Guide_HelpLabelJP
                dc.l    Guide_GuideLabelJP
                dc.l    Guide_DoorLabelJP
                dc.l    Guide_ButtonLabelJP
                dc.l    Guide_ScoreLabelJP
Guide_TitleLabelJP: dc.b    $C0, $DA  ; was: byte_1239C
                dc.b    $60, $6E, $A7, $65, $6F, 0
Guide_HelpLabelJP: dc.b    $C2, 8  ; was: byte_123A4
                dc.b    $8C, $6E, $62, $6A, $6B, $72, 0, 0
Guide_GuideLabelJP: dc.b    $C2, $18  ; was: byte_123AE
                dc.b    $8C, 0
Guide_DoorLabelJP: dc.b    $C2, $24  ; was: byte_123B2
                dc.b    $7E, $A4, $71, $89, $72, $61, $93, $72
                dc.b    $67, $A1, $6A, $61, $12, 0
Guide_ButtonLabelJP: dc.b    $C3, 6  ; was: byte_123C2
                dc.b    $FA, $BF, $DD, $8C, $64, $6C, $73, $11
                dc.b    $ED, $E4, $DD, $FD, $20, $26, $20, $BB
                dc.b    $E6, $E3, $C3, $12, 0, 0
Guide_ScoreLabelJP: dc.b    $C5, $94  ; was: byte_123DA
                dc.b    $7E, $73, $81, $72, $71, $89, $72, $65
                dc.b    $63, $88, $73, $11, $69, $62, $73, $67
                dc.b    $72, $8D, $21, 0
Guide_TextPointers: dc.l    Guide_MoveLabel  ; was: off_123F0
                dc.l    Guide_HelpLabel
                dc.l    Guide_GuideLabel
                dc.l    Guide_DoorLabel
                dc.l    Guide_ButtonLabel
                dc.l    Guide_ScoreLabel
Guide_MoveLabel: dc.b    $C0, $D2  ; was: byte_12408
aMakeYourMove:  dc.b    "MAKE YOUR MOVE",0
                dc.b    0
Guide_HelpLabel: dc.b    $C2, 2  ; was: byte_1241A
aHelp:          dc.b    "HELP",0
                dc.b    0
Guide_GuideLabel: dc.b    $C2, $E  ; was: byte_12422
aGuide:         dc.b    "GUIDE",0
Guide_DoorLabel: dc.b    $C2, $26  ; was: byte_1242A
aToTheDoor:     dc.b    "TO THE DOOR!",0
                dc.b    0
Guide_ButtonLabel: dc.b    $C2, $C2  ; was: byte_1243A
aPressButtonToJ: dc.b    "PRESS BUTTON TO JUMP AND SHOOT",0
                dc.b    0
Guide_ScoreLabel: dc.b    $C5, $92  ; was: byte_1245C
aRackUpASuperSc: dc.b    "RACK UP A SUPER SCORE!",0
                dc.b    0
; Guide screen character objects (Flicky, cats)
Obj_GuideCharacter:
                bset    #7,(a0)  ; was: sub_12476
                bne.s   Obj_GuideCharacter_Return
                move.w  $38(a0),d0
                bclr    #7,2(a0)
                move.b  Guide_CharacterFlagTable(pc,d0.w),d1
                beq.s   Obj_GuideCharacter_SetMapping
                bset    #7,2(a0)

Obj_GuideCharacter_SetMapping:  ; was: loc_12492
                lsl.w   #2,d0
                move.l  Guide_CharacterMappingPointers(pc,d0.w),$C(a0)
                lea     Guide_CharacterPositionsJP(pc),a1
                btst    #7,(IO_PCBVER+1).l
                beq.s   Obj_GuideCharacter_SetPosition
                lea     Guide_CharacterPositions(pc),a1

Obj_GuideCharacter_SetPosition:  ; was: loc_124AC
                move.w  (a1,d0.w),$20(a0)
                move.w  2(a1,d0.w),$24(a0)

Obj_GuideCharacter_Return:  ; was: locret_124B8
                rts

Guide_CharacterFlagTable: dc.b    0, 0, 1, 0, 1, 1, 1, 0, 0, 0  ; was: byte_124BA
                dc.b    0, 0, 0, 1, 1, 1, 1, 1, 1, 1
Guide_CharacterMappingPointers: dc.l    Cat_CarriedAltFrame0  ; was: off_124CE
                dc.l    Cat_CarriedFrame1
                dc.l    Cat_StunnedFrame0
                dc.l    Cat_IdleFrame0
                dc.l    Cat_WalkFrame2
                dc.l    Cat_IdleFrame0
                dc.l    Cat_CarriedFrame1
                dc.l    Cat_WalkAltFrame3
                dc.l    Guide_CharacterMap6
                dc.l    Cat_WalkFrame0
                dc.l    Guide_CharacterMap8
                dc.l    Chick_ThrownAnim1Data1
                dc.l    Guide_CharacterMap10
                dc.l    Guide_CharacterMap11
                dc.l    Cat_CarriedFrame0
                dc.l    Cat_CarriedAltFrame0
                dc.l    Cat_CarriedAltFrame1
                dc.l    Cat_CarriedFrame2
                dc.l    Cat_CarriedFrame1
                dc.l    Cat_CarriedAltFrame2
Guide_CharacterPositionsJP: dc.w    $B4, $A0, $C0, $A0, $CC, $A0, $D8, $A0, $120, $A0  ; was: word_1251E
                dc.w    $12C, $A0, $138, $A0, $144, $A0, $98, $C8, $D8, $C8
                dc.w    $D0, $100, $118, $100, $118, $110, $C0, $150, $C8, $150
                dc.w    $D0, $150, $D8, $150, $E0, $150, $E8, $150, $F0, $150
Guide_CharacterPositions: dc.w    $94, $A0, $A0, $A0, $AC, $A0, $B8, $A0, $148, $A0  ; was: word_1256E
                dc.w    $154, $A0, $160, $A0, $16C, $A0, $B0, $C8, $E8, $C8
                dc.w    $D0, $100, $118, $100, $118, $110, $C0, $150, $C8, $150
                dc.w    $D0, $150, $D8, $150, $E0, $150, $E8, $150, $F0, $150
; Round select screen initialization
