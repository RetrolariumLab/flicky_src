; Ending sequence and credits.
; ROM $013110-$0139A1.

Ending_Init:
                jsr Sys_InitTitleScreen  ; was: sub_13110
                clr.b   (byte_FFD88E).w
                bsr.w   loc_10126
                lea     (word_16DE8).l,a5
                jsr     unk_FFFBBA
                move.w  #$800,(word_FFF7E0).w
                bsr.w Ending_DrawGraphics
                move    #$2700,sr
                moveq   #2,d2
                move.w  #$3BA,d0
                move.w  #$125B,d1
                lea     (word_135E8).l,a0
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
                jsr     loc_13176(pc,d0.w)
                bsr.w Object_UpdateAll
                jmp     unk_FFFB6C

loc_13176:
                bra.w Ending_StateWait
                bra.w Ending_StateCredits
                bra.w Ending_StateRestart

; Ending state: wait then show congratulations
Ending_StateWait:
                bsr.w Ending_BlinkText  ; was: sub_13182
                cmpi.w  #$C8,(word_FFFF92).w
                bne.s   locret_131D4
                move.w  #4,(word_FFD29E).w
                move.w  #$8100,(word_FFD884).w
                move.w  #$EEE,(word_FFF7E6).w
                bsr.w Ending_DrawCongrats
                move.l  #$EFFFFFFF,(dword_FFFFB8).w
                move.l  #$FFFFFFFF,(dword_FFFFBC).w
                bsr.w Gfx_FadeInPalette
                lea     (VDP_DATA).l,a0
                move.l  #$40000003,(VDP_CTRL).l
                move.w  #$3FF,d0

loc_131CC:
                move.w  #0,(a0)
                dbf     d0,loc_131CC

locret_131D4:
                rts

; Cycles text blink effect for ending screen
Ending_BlinkText:
                bsr.w Text_CycleBlink  ; was: sub_131D6

; Draws congratulations messages on ending
Ending_DrawCongrats:
                lea     byte_131EC(pc),a6  ; was: sub_131DA
                bsr.w Text_DrawString
                lea     byte_13200(pc),a6
                bsr.w Text_DrawString
                rts

byte_131EC:     dc.b $C2, $90
aCongratulation:dc.b "CONGRATULATIONS!",0
                dc.b 0
byte_13200:     dc.b $C3, $8A
aYouAreASuperPl:dc.b "YOU ARE A SUPER PLAYER.",0
; Ending state: scrolling credits sequence
Ending_StateCredits:
                bset    #7,(word_FFD29E).w  ; was: sub_1321A
                bne.s   loc_1325A
                lea     (word_16DE8).l,a5
                jsr     unk_FFFBBA
                move.w  #$EEE,(word_FFF7E6).w
                clr.l   (dword_FFFFB8).w
                clr.l   (dword_FFFFBC).w
                move.w  #$4000,(dword_FFD008+2).w
                lea     (word_FFC000).w,a0
                moveq   #0,d1
                moveq   #4,d0

loc_13248:
                move.w  #$50,(a0)
                move.w  d1,$38(a0)
                lea     $40(a0),a0
                addq.w  #1,d1
                dbf     d0,loc_13248

loc_1325A:
                bsr.w Camera_UpdateScroll
                addq.b  #1,(byte_FFD29D).w
                cmpi.b  #$20,(byte_FFD29D).w
                bne.s   locret_1328C
                clr.b   (byte_FFD29D).w
                bsr.w Ending_DrawCreditsLine
                addq.b  #1,(byte_FFD29C).w
                cmpi.b  #$5D,(byte_FFD29C).w
                bne.s   locret_1328C
                move.w  #8,(word_FFD29E).w
                lea     (word_FFC000).w,a0
                move.w  #$44,(a0)

locret_1328C:
                rts

; Draws single credits line during scroll
Ending_DrawCreditsLine:
                moveq   #0,d0  ; was: sub_1328E
                moveq   #0,d5
                move.w  (dword_FFFFA4).w,d0
                andi.w  #$FF,d0
                lsr.w   #3,d0
                subq.w  #2,d0
                bpl.s   loc_132A4
                addi.w  #$20,d0

loc_132A4:
                lsl.w   #6,d0
                addi.w  #-$3FF8,d0
                move.w  d0,d5
                move.w  d5,d6
                bsr.w Gfx_MakeVDPWriteCmd
                move.l  d5,(VDP_CTRL).l
                moveq   #$1F,d1

loc_132BA:
                move.w  #0,(VDP_DATA).l
                dbf     d1,loc_132BA
                moveq   #0,d1
                move.b  (byte_FFD29C).w,d1
                lsl.w   #1,d1
                moveq   #$FFFFFFFF,d2
                lea     off_132E0(pc),a6 ; "     STAFF"
                move.w  (a6,d1.w),d2
                movea.l d2,a6
                bsr.w   loc_10FAE
                rts

off_132E0:      dc.w aStaff-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w aDirector-Sys_GameEntryPoint  
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w aKFuzzy-Sys_GameEntryPoint    
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w aDesigner-Sys_GameEntryPoint  
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w aYumi-Sys_GameEntryPoint      
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w aProgrammer-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w aOSamu-Sys_GameEntryPoint     
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w aSoundDesign-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w aTSMusic-Sys_GameEntryPoint   
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w aAnd-Sys_GameEntryPoint       
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w aSpecialThanks-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w aLee-Sys_GameEntryPoint       
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w aBo-Sys_GameEntryPoint        
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w aArcadeFlickySt-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w aTestPlayers-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w aChallengeTheNe-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
                dc.w byte_1339C-Sys_GameEntryPoint
byte_1339C:     dc.b 0, 0
aStaff:         dc.b "     STAFF",0
                dc.b 0
aDirector:      dc.b "    DIRECTOR",0
                dc.b 0
aKFuzzy:        dc.b "     K.FUZZY",0
                dc.b 0
aDesigner:      dc.b "    DESIGNER",0
                dc.b 0
aYumi:          dc.b "     YUMI",0
aProgrammer:    dc.b "    PROGRAMMER",0
                dc.b 0
aOSamu:         dc.b "     O.SAMU",0
aSoundDesign:   dc.b "    SOUND DESIGN",0
                dc.b 0
aTSMusic:       dc.b "     T@S MUSIC",0
                dc.b 0
aAnd:           dc.b "      AND",0
aSpecialThanks: dc.b "    SPECIAL THANKS",0
                dc.b 0
aArcadeFlickySt:dc.b "     ARCADE FLICKY STAFF",0
                dc.b 0
aTestPlayers:   dc.b "     TEST PLAYERS",0
aLee:           dc.b "     LEE",0
                dc.b 0
aBo:            dc.b "     BO",0
aChallengeTheNe:dc.b "CHALLENGE THE NEXT STAGE.",0
; Ending state: wait for start to restart game
Ending_StateRestart:
                btst    #7,(word_FFFF8E+1).w  ; was: sub_13492
                beq.s   locret_134BA
                bsr.w Gfx_FadeInPalette
                move.b  #1,(byte_FFD88E).w
                bsr.w   loc_10126
                move.w  #$18,(word_FFFFC0).w
                move    #$2700,sr
                bsr.w Sound_InitDriver
                move    #$2500,sr

locret_134BA:
                rts

; Credits character object appearing during scroll
Obj_CreditsCharacter:
                bset    #7,(a0)  ; was: sub_134BC
                bne.s   loc_134E2
                bset    #1,2(a0)
                move.w  $38(a0),d0
                move.b  word_13516(pc,d0.w),$3A(a0)
                lsl.w   #1,d0
                move.w  word_1350C(pc,d0.w),6(a0)
                lsl.w   #1,d0
                move.l  off_134F8(pc,d0.w),8(a0)

loc_134E2:
                move.w  $3C(a0),d0
                andi.w  #$7FFC,d0
                jsr     loc_134F0(pc,d0.w)
                rts

loc_134F0:
                bra.w Obj_CreditsWait
                bra.w Obj_CreditsFlyUp

off_134F8:      dc.l off_144AC
                dc.l off_14E12
                dc.l off_14E22
                dc.l off_154AE
                dc.l off_162BC
word_1350C:     dc.w 4, 0, 0, 8, $10
word_13516:     dc.w $D17, $212B, $3D00
; Credits character wait state: waits for scroll line
Obj_CreditsWait:
                move.b  (byte_FFD29C).w,d0  ; was: sub_1351C
                cmp.b   $3A(a0),d0
                bne.s   locret_1352C
                move.w  #4,$3C(a0)

locret_1352C:
                rts

; Credits character fly state: exits upward
Obj_CreditsFlyUp:
                bset    #7,$3C(a0)  ; was: sub_1352E
                bne.s   loc_13550
                move.w  #$E4,$30(a0)
                move.w  #$178,$24(a0)
                move.l  #$FFFFC000,$2C(a0)
                bclr    #1,2(a0)

loc_13550:
                bsr.w Object_UpdatePosition
                cmpi.w  #$78,$24(a0)
                bgt.s   loc_13560
                bsr.w Object_ClearSlot

loc_13560:
                bsr.w Anim_UpdateFrame
                rts

; Draws congratulations screen tilemaps
Ending_DrawGraphics:
                moveq   #9,d0  ; was: sub_13566
                moveq   #0,d1

loc_1356A:
                moveq   #0,d5
                movem.l d0-d1,-(sp)
                lsl.w   #1,d1
                move.w  word_135D4(pc,d1.w),d5
                moveq   #$FFFFFFFF,d2
                move.w  off_13598(pc,d1.w),d2
                movea.l d2,a6
                lsl.w   #1,d1
                move.w  byte_135AC(pc,d1.w),d7
                move.w  byte_135AC+2(pc,d1.w),d6
                bsr.w Gfx_DrawTilemapStart
                movem.l (sp)+,d0-d1
                addq.w  #1,d1
                dbf     d0,loc_1356A
                rts

off_13598:      dc.w word_1A354-Sys_GameEntryPoint
                dc.w word_1A336-Sys_GameEntryPoint
                dc.w word_1A374-Sys_GameEntryPoint
                dc.w word_1A374-Sys_GameEntryPoint
                dc.w word_1A374-Sys_GameEntryPoint
                dc.w word_1A374-Sys_GameEntryPoint
                dc.w word_1A374-Sys_GameEntryPoint
                dc.w word_1A374-Sys_GameEntryPoint
                dc.w word_1A354-Sys_GameEntryPoint
                dc.w word_1A336-Sys_GameEntryPoint
byte_135AC:     dc.b 0, 3, 0, 3, 0, 4, 0, 2, 0, 4
                dc.b 0, 2, 0, 4, 0, 2, 0, 4, 0, 2
                dc.b 0, 4, 0, 2, 0, 4, 0, 2, 0, 4
                dc.b 0, 2, 0, 3, 0, 3, 0, 4, 0, 2
word_135D4:     dc.w $E132, $E4B2, $E642, $E64C, $E656, $E660, $E66A, $E674, $E446, $E146
word_135E8:	binclude	"data/other/data_word_135E8.bin"	
word_135E8_End:
; Demo/attract mode initialization
