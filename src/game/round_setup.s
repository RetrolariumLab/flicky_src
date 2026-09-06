; Round init, tileset and palette loading
; ROM $012656-$012A93

Game_InitRound:
                bsr.w   Sys_InitTitleScreen             ; was: sub_12656
                lea     (Gfx_SharedPalette).l,a5
                jsr     j_Gfx_LoadPaletteCompact
                clr.l   (Ram_RoundTime).w
                clr.b   (Ram_ExitReachedFlag).w
                rts

; Short delay before round based on round mod 4
Game_PreRoundDelay:
                move.w  #$20,(Ram_NextGameMode).w       ; was: sub_1266E
                move.b  (Ram_RoundNumber+1).w,d0
                andi.b  #3,d0
                cmpi.b  #3,d0
                bne.s   Game_PreRoundDelay_Wait
                move.w  #$28,(Ram_NextGameMode).w

Game_PreRoundDelay_Wait:                                ; was: loc_12688
                jsr     j_Sound_QueueSFX
                rts

; Loads level tileset based on round number
Level_LoadTileset:
                moveq   #$18,d7                         ; was: sub_1268E
                bsr.w   Math_ModuloLower
                lsr.w   #2,d0
                lsl.w   #2,d0
                lea     Level_BackgroundTilePointers(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(Ram_BackgroundTilePtr).w
                lea     Level_GroundTilePointers(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(Ram_GroundTilePtr).w
                lea     Level_UpperGroundPointers(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(Ram_UpperGroundPtr).w
                lea     Level_LowerGroundPointers(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(Ram_LowerGroundPtr).w
                lea     Level_BgObject4Pointers(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(Ram_BgObject4Ptr).w
                lea     Level_BgObject5Pointers(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(Ram_BgObject5Ptr).w
                moveq   #$20,d7
                bsr.w   Math_ModuloUpper
                subq.b  #1,d0
                lsr.w   #2,d0
                lsl.w   #2,d0
                lea     Level_BgObject3Pointers(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(Ram_BgObject3Ptr).w
                moveq   #$F,d7
                bsr.w   Math_ModuloUpper
                subq.b  #1,d0
                lsl.w   #2,d0
                lea     Level_ChickMappingPointers(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(Ram_ChickMappingPtr).w
                move.l  #Level_BgObject0Data,(Ram_BgObject0Ptr).w
                move.l  #Level_BgObject1Data,(Ram_BgObject1Ptr).w
                move.l  #Level_BgObject2Data,(Ram_BgObject2Ptr).w
                rts

Level_BackgroundTilePointers:   dc.l    Level_BackgroundTileData0  ; was: off_12728
                dc.l    Level_BackgroundTileData1
                dc.l    Level_BackgroundTileData2
                dc.l    Level_BackgroundTileData3
                dc.l    Level_BackgroundTileData4
                dc.l    Level_BackgroundTileData5
Level_GroundTilePointers:       dc.l    Level_GroundTileData0  ; was: off_12740
                dc.l    Level_GroundTileData1
                dc.l    Level_GroundTileData2
                dc.l    Level_GroundTileData3
                dc.l    Level_GroundTileData4
                dc.l    Level_GroundTileData5
Level_UpperGroundPointers:      dc.l    Level_UpperGroundData0  ; was: off_12758
                dc.l    Level_UpperGroundData1
                dc.l    Level_UpperGroundData2
                dc.l    Level_UpperGroundData3
                dc.l    Level_UpperGroundData4
                dc.l    Level_UpperGroundData5
Level_LowerGroundPointers:      dc.l    Level_LowerGroundData0  ; was: off_12770
                dc.l    Level_LowerGroundData1
                dc.l    Level_LowerGroundData2
                dc.l    Level_LowerGroundData3
                dc.l    Level_LowerGroundData4
                dc.l    Level_LowerGroundData5
Level_BgObject3Pointers:        dc.l    Level_BgObject3Data0  ; was: off_12788
                dc.l    Level_BgObject3Data1
                dc.l    Level_BgObject3Data2
                dc.l    Level_BgObject3Data3
                dc.l    Level_BgObject3Data4
                dc.l    Level_BgObject3Data0
                dc.l    Level_BgObject3Data1
                dc.l    Level_BgObject3Data2
                dc.l    Level_BgObject3Data0
                dc.l    Level_BgObject3Data1
                dc.l    Level_BgObject3Data2
                dc.l    Level_BgObject3Data0
Level_BgObject4Pointers:        dc.l    Ending_GraphicsMap1  ; was: off_127B8
                dc.l    Ending_GraphicsMap1
                dc.l    Ending_GraphicsMap2
                dc.l    Level_BgObject4Data2
                dc.l    Level_BgObject4Data3
                dc.l    Level_BgObject4Data4
Level_BgObject5Pointers:        dc.l    Ending_GraphicsMap0  ; was: off_127D0
                dc.l    Ending_GraphicsMap0
                dc.l    Level_BgObject5Data1
                dc.l    Level_BgObject5Data2
                dc.l    Level_BgObject5Data3
                dc.l    Level_BgObject5Data4
Level_ChickMappingPointers:     dc.l    Chick_ThrownAnim0Data0  ; was: off_127E8
                dc.l    Chick_ThrownAnim1Data0
                dc.l    Chick_ThrownAnim2Data0
                dc.l    Chick_ThrownAnim3Data0
                dc.l    Chick_ThrownAnim4Data0
                dc.l    Chick_ThrownAnim5Data0
                dc.l    Chick_ThrownAnim6Data0
                dc.l    Chick_ThrownAnim7Data0
                dc.l    Chick_ThrownAnim8Data0
                dc.l    Chick_ThrownAnim9Data0
                dc.l    Chick_ThrownAnim10Data0
                dc.l    Chick_ThrownAnim11Data0
                dc.l    Chick_ThrownAnim12Data0
                dc.l    Chick_ThrownAnim13Data0
                dc.l    Chick_ThrownAnim14Data0
; Loads level palette based on round number
Level_LoadPalette:
                moveq   #$30,d7                         ; was: sub_12824
                bsr.w   Math_ModuloLower
                lsr.w   #2,d0
                lsl.w   #1,d0
                lea     Level_PalettePointers(pc),a0
                moveq   #$FFFFFFFF,d1
                move.w  (a0,d0.w),d1
                movea.l d1,a0
                lea     (Ram_LevelPalette).w,a1
                moveq   #7,d0

Level_LoadPalette_CopyLoop:                             ; was: loc_12840
                move.l  (a0)+,(a1)+
                dbf     d0,Level_LoadPalette_CopyLoop
                moveq   #$F,d7
                bsr.w   Math_ModuloUpper
                subq.w  #1,d0
                lsl.w   #1,d0
                lea     Level_AccentPalettePointers(pc),a0
                lea     (Ram_AccentPaletteSlot).w,a1
                moveq   #$FFFFFFFF,d1
                move.w  (a0,d0.w),d1
                movea.l d1,a0
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                rts

Level_PalettePointers:  dc.w    Level_Palette0-Sys_GameEntryPoint  ; was: off_12866
                dc.w    Level_Palette1-Sys_GameEntryPoint
                dc.w    Level_Palette2-Sys_GameEntryPoint
                dc.w    Level_Palette3-Sys_GameEntryPoint
                dc.w    Level_Palette4-Sys_GameEntryPoint
                dc.w    Level_Palette5-Sys_GameEntryPoint
                dc.w    Level_Palette6-Sys_GameEntryPoint
                dc.w    Level_Palette7-Sys_GameEntryPoint
                dc.w    Level_Palette8-Sys_GameEntryPoint
                dc.w    Level_Palette9-Sys_GameEntryPoint
                dc.w    Level_Palette10-Sys_GameEntryPoint
                dc.w    Level_Palette11-Sys_GameEntryPoint
Level_Palette0:                 dc.w    0, 6, $E, $CC4, $4AA, $6EE, $64, $64, $A2, $A2, $6EE, $8C, $8EE, $AE, $6E, $4CA  ; was: word_1287E
Level_Palette1:                 dc.w    0, $68, $2AA, $4A, $EA8, $444, $C86, $CCC, $EA8, $AAA, 0, $A4, $AC, $C6, $62, $A8  ; was: word_1289E
Level_Palette2:                 dc.w    0, $EE, $46C, $E28, $A0A, $C2A, $A8A, $E4E, $ACA, $64A, $CAC, $888, $EEE, $AAA, $444, $888  ; was: word_128BE
Level_Palette3:                 dc.w    0, $A86, $C, $AAA, $464, $4A, $242, $8A, 0, $420, $864, $C6E, $CCE, $E8E, $A0E, $CAE  ; was: word_128DE
Level_Palette4:                 dc.w    0, $E00, $E60, $AAA, $286, $2CA, $44, $A8, 0, 0, 0, $CC, $EEE, $EE, $86, $8EE  ; was: word_128FE
Level_Palette5:                 dc.w    0, $62E, $EC0, $E00, $EE, $AEE, $66, $CA, 0, 0, 0, $888, $EEE, $AAA, $444, $888  ; was: word_1291E
Level_Palette6:                 dc.w    0, 6, $E, $CC4, $4A8, $6EE, $AAA, $8CC, $CCC, $AEE, 0, $C2, $EEE, $E6, $A0, $4CA  ; was: word_1293E
Level_Palette7:                 dc.w    0, $48, $8E, $4E, $4E4, $444, $8A, $AA2, $AE, $882, 0, $8E, $EE, $28E, $2A, $AA  ; was: word_1295E
Level_Palette8:                 dc.w    0, $6A, $EE, $E0, $AE, $E0, $86, $68, $8A, $66, $AC, $888, $EEE, $AAA, $444, $888  ; was: word_1297E
Level_Palette9:                 dc.w    0, $EAE, $E6E, $E48, $C06, $4A, $8A, $4E, 0, $44, 0, $AA, $6CC, $CC, $66, $A8  ; was: word_1299E
Level_Palette10:                dc.w    0, $E00, $E60, $AAA, $666, $A6E, 0, 0, $4AE, 6, 2, $EE0, $EEE, $EE6, $E60, $EEA  ; was: word_129BE
Level_Palette11:                dc.w    0, $62E, $EC0, $E00, $EE, $AEE, 0, 0, $4AE, $A, 2, $A6C, $EE6, $C8E, $406, $EEC  ; was: word_129DE
Level_AccentPalettePointers:    dc.w    Level_AccentPalette0-Sys_GameEntryPoint  ; was: off_129FE
                dc.w    Level_AccentPalette1-Sys_GameEntryPoint
                dc.w    Level_AccentPalette2-Sys_GameEntryPoint
                dc.w    Level_AccentPalette3-Sys_GameEntryPoint
                dc.w    Level_AccentPalette4-Sys_GameEntryPoint
                dc.w    Level_AccentPalette5-Sys_GameEntryPoint
                dc.w    Level_AccentPalette6-Sys_GameEntryPoint
                dc.w    Level_AccentPalette7-Sys_GameEntryPoint
                dc.w    Level_AccentPalette8-Sys_GameEntryPoint
                dc.w    Level_AccentPalette9-Sys_GameEntryPoint
                dc.w    Level_AccentPalette10-Sys_GameEntryPoint
                dc.w    Level_AccentPalette11-Sys_GameEntryPoint
                dc.w    Level_AccentPalette12-Sys_GameEntryPoint
                dc.w    Level_AccentPalette13-Sys_GameEntryPoint
                dc.w    Level_AccentPalette14-Sys_GameEntryPoint
Level_AccentPalette0:   dc.w    $EE, $60, $48, $4E      ; was: word_12A1C
Level_AccentPalette1:   dc.w    $EE, $40, $A, $6A       ; was: word_12A24
Level_AccentPalette2:   dc.w    $EEE, $666, $EE0, $E44  ; was: word_12A2C
Level_AccentPalette3:   dc.w    $AA, $8EE, $CC, $E      ; was: word_12A34
Level_AccentPalette4:   dc.w    $AC, $EC, $8EE, $666    ; was: word_12A3C
Level_AccentPalette5:   dc.w    $8EE, $AAA, $CCA, $8C2  ; was: word_12A44
Level_AccentPalette6:   dc.w    $EE, 0, $28E, $E        ; was: word_12A4C
Level_AccentPalette7:   dc.w    $A, 0, $EE, $22E        ; was: word_12A54
Level_AccentPalette8:   dc.w    $444, $AAA, $EEE, $20E  ; was: word_12A5C
Level_AccentPalette9:   dc.w    $EEE, $AAA, $4A, $8C    ; was: word_12A64
Level_AccentPalette10:  dc.w    $EEE, 0, $E, $CAE       ; was: word_12A6C
Level_AccentPalette11:  dc.w    $88E, 0, $2C, $A        ; was: word_12A74
Level_AccentPalette12:  dc.w    $EEE, 0, $E22, $600     ; was: word_12A7C
Level_AccentPalette13:  dc.w    $EEE, $666, $40C, $A8E  ; was: word_12A84
Level_AccentPalette14:  dc.w    $EEE, $222, $AAA, $666  ; was: word_12A8C
; Main game round entry: init level and start play
