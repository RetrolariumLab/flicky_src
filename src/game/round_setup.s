; Round init, tileset and palette loading.
; ROM $012656-$012A93.

Game_InitRound:
                bsr.w   Sys_InitTitleScreen  ; was: sub_12656
                lea     (word_16DE8).l,a5
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
                bne.s   loc_12688
                move.w  #$28,(word_FFFFC0).w

loc_12688:
                jsr     unk_FFFB6C
                rts

; Loads level tileset based on round number
Level_LoadTileset:
                moveq   #$18,d7  ; was: sub_1268E
                bsr.w   Math_ModuloLower
                lsr.w   #2,d0
                lsl.w   #2,d0
                lea     off_12728(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(dword_FFD804).w
                lea     off_12740(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(dword_FFD800).w
                lea     off_12758(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(dword_FFD808).w
                lea     off_12770(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(dword_FFD80C).w
                lea     off_127B8(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(dword_FFD814).w
                lea     off_127D0(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(dword_FFD818).w
                moveq   #$20,d7
                bsr.w   Math_ModuloUpper
                subq.b  #1,d0
                lsr.w   #2,d0
                lsl.w   #2,d0
                lea     off_12788(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(dword_FFD810).w
                moveq   #$F,d7
                bsr.w   Math_ModuloUpper
                subq.b  #1,d0
                lsl.w   #2,d0
                lea     off_127E8(pc),a0
                move.l  (a0,d0.w),d1
                move.l  d1,(dword_FFD828).w
                move.l  #word_1A274,(dword_FFD81C).w
                move.l  #word_1A292,(dword_FFD820).w
                move.l  #word_1A286,(dword_FFD824).w
                rts

off_12728:      dc.l    byte_1A196
                dc.l    byte_1A198
                dc.l    byte_1A19A
                dc.l    byte_1A19C
                dc.l    byte_1A19E
                dc.l    byte_1A1A0
off_12740:      dc.l    word_1A2D6
                dc.l    word_1A2E6
                dc.l    word_1A2F6
                dc.l    word_1A306
                dc.l    word_1A316
                dc.l    word_1A326
off_12758:      dc.l    word_1A1A2
                dc.l    word_1A1B2
                dc.l    word_1A1C2
                dc.l    word_1A1D2
                dc.l    word_1A1E2
                dc.l    word_1A1F2
off_12770:      dc.l    word_1A202
                dc.l    word_1A212
                dc.l    word_1A222
                dc.l    word_1A232
                dc.l    word_1A242
                dc.l    word_1A252
off_12788:      dc.l    word_1A29A
                dc.l    word_1A2A6
                dc.l    word_1A2B2
                dc.l    word_1A2BE
                dc.l    word_1A2CA
                dc.l    word_1A29A
                dc.l    word_1A2A6
                dc.l    word_1A2B2
                dc.l    word_1A29A
                dc.l    word_1A2A6
                dc.l    word_1A2B2
                dc.l    word_1A29A
off_127B8:      dc.l    word_1A336
                dc.l    word_1A336
                dc.l    word_1A374
                dc.l    word_1A3D2
                dc.l    word_1A44E
                dc.l    word_1A410
off_127D0:      dc.l    word_1A354
                dc.l    word_1A354
                dc.l    word_1A392
                dc.l    word_1A3B2
                dc.l    word_1A3F0
                dc.l    word_1A42E
off_127E8:      dc.l    word_1A4E8
                dc.l    word_1A518
                dc.l    word_1A548
                dc.l    word_1A578
                dc.l    word_1A5A8
                dc.l    word_1A5D8
                dc.l    word_1A608
                dc.l    word_1A638
                dc.l    word_1A668
                dc.l    word_1A698
                dc.l    word_1A6C8
                dc.l    word_1A6F8
                dc.l    word_1A728
                dc.l    word_1A758
                dc.l    word_1A788
; Loads level palette based on round number
Level_LoadPalette:
                moveq   #$30,d7  ; was: sub_12824
                bsr.w   Math_ModuloLower
                lsr.w   #2,d0
                lsl.w   #1,d0
                lea     off_12866(pc),a0
                moveq   #$FFFFFFFF,d1
                move.w  (a0,d0.w),d1
                movea.l d1,a0
                lea     (unk_FFF800).w,a1
                moveq   #7,d0

loc_12840:
                move.l  (a0)+,(a1)+
                dbf     d0,loc_12840
                moveq   #$F,d7
                bsr.w   Math_ModuloUpper
                subq.w  #1,d0
                lsl.w   #1,d0
                lea     off_129FE(pc),a0
                lea     (unk_FFF858).w,a1
                moveq   #$FFFFFFFF,d1
                move.w  (a0,d0.w),d1
                movea.l d1,a0
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                rts

off_12866:      dc.w    word_1287E-Sys_GameEntryPoint
                dc.w    word_1289E-Sys_GameEntryPoint
                dc.w    word_128BE-Sys_GameEntryPoint
                dc.w    word_128DE-Sys_GameEntryPoint
                dc.w    word_128FE-Sys_GameEntryPoint
                dc.w    word_1291E-Sys_GameEntryPoint
                dc.w    word_1293E-Sys_GameEntryPoint
                dc.w    word_1295E-Sys_GameEntryPoint
                dc.w    word_1297E-Sys_GameEntryPoint
                dc.w    word_1299E-Sys_GameEntryPoint
                dc.w    word_129BE-Sys_GameEntryPoint
                dc.w    word_129DE-Sys_GameEntryPoint
word_1287E:     binclude "data/palettes/level-00.bin"
word_1289E:     binclude "data/palettes/level-01.bin"
word_128BE:     binclude "data/palettes/level-02.bin"
word_128DE:     binclude "data/palettes/level-03.bin"
word_128FE:     binclude "data/palettes/level-04.bin"
word_1291E:     binclude "data/palettes/level-05.bin"
word_1293E:     binclude "data/palettes/level-06.bin"
word_1295E:     binclude "data/palettes/level-07.bin"
word_1297E:     binclude "data/palettes/level-08.bin"
word_1299E:     binclude "data/palettes/level-09.bin"
word_129BE:     binclude "data/palettes/level-10.bin"
word_129DE:     binclude "data/palettes/level-11.bin"
off_129FE:      dc.w    word_12A1C-Sys_GameEntryPoint
                dc.w    word_12A24-Sys_GameEntryPoint
                dc.w    word_12A2C-Sys_GameEntryPoint
                dc.w    word_12A34-Sys_GameEntryPoint
                dc.w    word_12A3C-Sys_GameEntryPoint
                dc.w    word_12A44-Sys_GameEntryPoint
                dc.w    word_12A4C-Sys_GameEntryPoint
                dc.w    word_12A54-Sys_GameEntryPoint
                dc.w    word_12A5C-Sys_GameEntryPoint
                dc.w    word_12A64-Sys_GameEntryPoint
                dc.w    word_12A6C-Sys_GameEntryPoint
                dc.w    word_12A74-Sys_GameEntryPoint
                dc.w    word_12A7C-Sys_GameEntryPoint
                dc.w    word_12A84-Sys_GameEntryPoint
                dc.w    word_12A8C-Sys_GameEntryPoint
word_12A1C:     binclude "data/palettes/accent-00.bin"
word_12A24:     binclude "data/palettes/accent-01.bin"
word_12A2C:     binclude "data/palettes/accent-02.bin"
word_12A34:     binclude "data/palettes/accent-03.bin"
word_12A3C:     binclude "data/palettes/accent-04.bin"
word_12A44:     binclude "data/palettes/accent-05.bin"
word_12A4C:     binclude "data/palettes/accent-06.bin"
word_12A54:     binclude "data/palettes/accent-07.bin"
word_12A5C:     binclude "data/palettes/accent-08.bin"
word_12A64:     binclude "data/palettes/accent-09.bin"
word_12A6C:     binclude "data/palettes/accent-10.bin"
word_12A74:     binclude "data/palettes/accent-11.bin"
word_12A7C:     binclude "data/palettes/accent-12.bin"
word_12A84:     binclude "data/palettes/accent-13.bin"
word_12A8C:     binclude "data/palettes/accent-14.bin"
; Main game round entry: init level and start play
