; Round init, tileset and palette loading.
; ROM $012656-$012A93.

Game_InitRound:
                bsr.w   Sys_InitTitleScreen  ; was: sub_12656
                lea     (Gfx_ScreenInitData).l,a5
                jsr     unk_FFFBBA
                clr.l   (dword_FFD888).w
                clr.b   (byte_FFD88D).w
                rts

; Short delay before round based on round mod 4
Game_PreRoundDelay:
                move.w  #$20,(word_FFFFC0).w  ; was: sub_1266E
                move.b  (word_FFD82C+1).w,d0
                andi.b  #3,d0
                cmpi.b  #3,d0
                bne.s   Game_PreRoundDelay_Wait
                move.w  #$28,(word_FFFFC0).w

Game_PreRoundDelay_Wait:  ; was: loc_12688
                jsr     unk_FFFB6C
                rts

; Loads level tileset based on round number
Level_LoadTileset:
                moveq   #$18,d7  ; was: sub_1268E
                bsr.w   Math_ModuloLower
                lsr.w   #2,d0
                lsl.w   #2,d0
                lea     Level_BackgroundTilePointers(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(dword_FFD804).w
                lea     Level_GroundTilePointers(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(dword_FFD800).w
                lea     Level_UpperGroundPointers(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(dword_FFD808).w
                lea     Level_LowerGroundPointers(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(dword_FFD80C).w
                lea     Level_BgObject4Pointers(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(dword_FFD814).w
                lea     Level_BgObject5Pointers(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(dword_FFD818).w
                moveq   #$20,d7
                bsr.w   Math_ModuloUpper
                subq.b  #1,d0
                lsr.w   #2,d0
                lsl.w   #2,d0
                lea     Level_BgObject3Pointers(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(dword_FFD810).w
                moveq   #$F,d7
                bsr.w   Math_ModuloUpper
                subq.b  #1,d0
                lsl.w   #2,d0
                lea     Level_ChickMappingPointers(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(dword_FFD828).w
                move.l  #Level_BgObject0Data,(dword_FFD81C).w
                move.l  #Level_BgObject1Data,(dword_FFD820).w
                move.l  #Level_BgObject2Data,(dword_FFD824).w
                rts

Level_BackgroundTilePointers: dc.l    Level_BackgroundTileData0  ; was: off_12728
                dc.l    Level_BackgroundTileData1
                dc.l    Level_BackgroundTileData2
                dc.l    Level_BackgroundTileData3
                dc.l    Level_BackgroundTileData4
                dc.l    Level_BackgroundTileData5
Level_GroundTilePointers: dc.l    Level_GroundTileData0  ; was: off_12740
                dc.l    Level_GroundTileData1
                dc.l    Level_GroundTileData2
                dc.l    Level_GroundTileData3
                dc.l    Level_GroundTileData4
                dc.l    Level_GroundTileData5
Level_UpperGroundPointers: dc.l    Level_UpperGroundData0  ; was: off_12758
                dc.l    Level_UpperGroundData1
                dc.l    Level_UpperGroundData2
                dc.l    Level_UpperGroundData3
                dc.l    Level_UpperGroundData4
                dc.l    Level_UpperGroundData5
Level_LowerGroundPointers: dc.l    Level_LowerGroundData0  ; was: off_12770
                dc.l    Level_LowerGroundData1
                dc.l    Level_LowerGroundData2
                dc.l    Level_LowerGroundData3
                dc.l    Level_LowerGroundData4
                dc.l    Level_LowerGroundData5
Level_BgObject3Pointers: dc.l    Level_BgObject3Data0  ; was: off_12788
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
Level_BgObject4Pointers: dc.l    Ending_GraphicsMap1  ; was: off_127B8
                dc.l    Ending_GraphicsMap1
                dc.l    Ending_GraphicsMap2
                dc.l    Level_BgObject4Data2
                dc.l    Level_BgObject4Data3
                dc.l    Level_BgObject4Data4
Level_BgObject5Pointers: dc.l    Ending_GraphicsMap0  ; was: off_127D0
                dc.l    Ending_GraphicsMap0
                dc.l    Level_BgObject5Data1
                dc.l    Level_BgObject5Data2
                dc.l    Level_BgObject5Data3
                dc.l    Level_BgObject5Data4
Level_ChickMappingPointers: dc.l    Chick_ThrownAnim0Data0  ; was: off_127E8
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
                moveq   #$30,d7  ; was: sub_12824
                bsr.w   Math_ModuloLower
                lsr.w   #2,d0
                lsl.w   #1,d0
                lea     Level_PalettePointers(pc),a0
                moveq   #$FFFFFFFF,d1
                move.w  (a0,d0.w),d1
                movea.l d1,a0
                lea     (unk_FFF800).w,a1
                moveq   #7,d0

Level_LoadPalette_CopyLoop:  ; was: loc_12840
                move.l  (a0)+,(a1)+
                dbf     d0,Level_LoadPalette_CopyLoop
                moveq   #$F,d7
                bsr.w   Math_ModuloUpper
                subq.w  #1,d0
                lsl.w   #1,d0
                lea     Level_AccentPalettePointers(pc),a0
                lea     (unk_FFF858).w,a1
                moveq   #$FFFFFFFF,d1
                move.w  (a0,d0.w),d1
                movea.l d1,a0
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                rts

Level_PalettePointers: dc.w    Level_Palette0-Sys_GameEntryPoint  ; was: off_12866
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
Level_Palette0: binclude "data/palettes/level-00.bin"
Level_Palette1: binclude "data/palettes/level-01.bin"
Level_Palette2: binclude "data/palettes/level-02.bin"
Level_Palette3: binclude "data/palettes/level-03.bin"
Level_Palette4: binclude "data/palettes/level-04.bin"
Level_Palette5: binclude "data/palettes/level-05.bin"
Level_Palette6: binclude "data/palettes/level-06.bin"
Level_Palette7: binclude "data/palettes/level-07.bin"
Level_Palette8: binclude "data/palettes/level-08.bin"
Level_Palette9: binclude "data/palettes/level-09.bin"
Level_Palette10: binclude "data/palettes/level-10.bin"
Level_Palette11: binclude "data/palettes/level-11.bin"
Level_AccentPalettePointers: dc.w    Level_AccentPalette0-Sys_GameEntryPoint  ; was: off_129FE
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
Level_AccentPalette0: binclude "data/palettes/accent-00.bin"
Level_AccentPalette1: binclude "data/palettes/accent-01.bin"
Level_AccentPalette2: binclude "data/palettes/accent-02.bin"
Level_AccentPalette3: binclude "data/palettes/accent-03.bin"
Level_AccentPalette4: binclude "data/palettes/accent-04.bin"
Level_AccentPalette5: binclude "data/palettes/accent-05.bin"
Level_AccentPalette6: binclude "data/palettes/accent-06.bin"
Level_AccentPalette7: binclude "data/palettes/accent-07.bin"
Level_AccentPalette8: binclude "data/palettes/accent-08.bin"
Level_AccentPalette9: binclude "data/palettes/accent-09.bin"
Level_AccentPalette10: binclude "data/palettes/accent-10.bin"
Level_AccentPalette11: binclude "data/palettes/accent-11.bin"
Level_AccentPalette12: binclude "data/palettes/accent-12.bin"
Level_AccentPalette13: binclude "data/palettes/accent-13.bin"
Level_AccentPalette14: binclude "data/palettes/accent-14.bin"
; Main game round entry: init level and start play
