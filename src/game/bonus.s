; Bonus round flow.
; ROM $012F30-$01310F.

Bonus_Init:
                bsr.w   Sys_InitTitleScreen  ; was: sub_12F30
                move.w  #$8F02,(VDP_CTRL).l
                lea     (word_16DE8).l,a5
                jsr     unk_FFFBBA
                move.w  #$2C,(word_FFF82E).w
                bsr.w   Collision_ClearMap
                bsr.w   Level_LoadTileset
                bsr.w   Level_LoadPalette
                move.b  #1,(byte_FFD24E).w
                move.b  #$14,(byte_FFD883).w
                bsr.w   Level_DrawUpperGround
                bsr.w   Level_DrawLowerGround
                lea     (unk_FFCAA0).w,a0
                moveq   #$1F,d0

loc_12F72:
                move.b  #1,(a0)+
                dbf     d0,loc_12F72
                lea     (VDP_DATA).l,a0
                move.l  #$65400003,(VDP_CTRL).l
                moveq   #$1F,d0

loc_12F8C:
                move.w  #$220D,(a0)
                dbf     d0,loc_12F8C
                lea     byte_12FCC(pc),a6
                bsr.w   Text_DrawString
                lea     byte_12FD4(pc),a6
                bsr.w   Text_DrawString
                bsr.w   Bonus_SetupObjects
                bsr.w   UI_DrawScoreLabels
                bsr.w   UI_DrawScore
                bsr.w   UI_DrawHighScore
                bsr.w   UI_DrawRoundNumber
                bsr.w   UI_DrawLives
                move.b  #$81,d0
                jsr     unk_FFFB66
                jsr     unk_FFFB6C
                jmp     unk_FFFB6C

byte_12FCC:     dc.b    $C0, $D4
aBonus:         dc.b    "BONUS",0
byte_12FD4:     dc.b    $C0, $E0
aRound_0:       dc.b    "ROUND",0
; Bonus round main loop with state dispatcher
Bonus_MainLoop:
                move.w  (word_FFD2A6).w,d0  ; was: sub_12FDC
                andi.w  #$7FFC,d0
                jsr     loc_13000(pc,d0.w)
                btst    #7,(word_FFFF8E+1).w
                beq.s   loc_12FF4
                bsr.w   Game_Pause

loc_12FF4:
                bsr.w   Score_CheckExtraLife
                bsr.w   Sound_ChannelCooldown
                jmp     unk_FFFB6C

loc_13000:
                bra.w   Bonus_StatePlay
                bra.w   Bonus_StateComplete

; Bonus round play state
Bonus_StatePlay:
                bsr.w   Object_UpdateAll  ; was: sub_13008
                rts

; Bonus round complete state
Bonus_StateComplete:
                bset    #7,(word_FFD2A6).w  ; was: sub_1300E
                bne.s   loc_13032

loc_13016:
                tst.b   (byte_FFD2A4).w
                beq.s   loc_13026
                bsr.w   Sound_ChannelCooldown
                jsr     unk_FFFB6C
                bra.s   loc_13016

loc_13026:
                move.b  #$82,d0
                jsr     unk_FFFB66
                bsr.w   Bonus_DrawResultLabels

loc_13032:
                bsr.w   Object_UpdateAll
                bsr.w   Bonus_ScoreUpdate
                rts

; Sets up bonus round objects: player, cats, chicks
Bonus_SetupObjects:
                lea     (unk_FFC580).w,a0  ; was: sub_1303C
                move.w  #$C,(a0)
                move.w  #$D11,$3E(a0)
                move.w  #$2C,(word_FFC040).w
                lea     (unk_FFC640).w,a0
                move.w  #$30,(a0)
                lea     $40(a0),a0
                move.w  #$30,(a0)
                move.b  #1,$16(a0)
                lea     (unk_FFC5C0).w,a0
                move.w  #$34,(a0)
                lea     $40(a0),a0
                move.w  #$34,(a0)
                move.b  #1,$16(a0)
                lea     (unk_FFC080).w,a0
                moveq   #0,d1
                moveq   #$13,d0

loc_13084:
                move.w  #$38,(a0)
                move.b  d1,$38(a0)
                btst    #2,d1
                beq.s   loc_13098
                move.b  #1,$39(a0)

loc_13098:
                lea     $40(a0),a0
                addq.b  #1,d1
                dbf     d0,loc_13084
                moveq   #0,d0
                move.b  (word_FFD82C+1).w,d0
                moveq   #$30,d7
                bsr.w   Math_ModuloLower
                subq.b  #3,d0
                lsr.w   #2,d0
                lsl.w   #2,d0
                lea     off_169F4(pc),a0
                move.l  (a0,d0.w),(dword_FFD282).w
                lea     off_16A9C(pc),a0
                move.l  (a0,d0.w),(dword_FFD286).w
                lea     off_16C34(pc),a0
                move.l  (a0,d0.w),(dword_FFD28A).w
                rts

; Bonus round score display with blink and round advance
Bonus_ScoreUpdate:
                move.b  #1,(byte_FFD27B).w  ; was: sub_130D4
                move.w  (word_FFFF92).w,d0
                cmpi.w  #$FA,d0
                bhi.s   loc_130EE
                bsr.w   Text_CycleBlink
                bsr.w   UI_DrawBonusRoundScore
                rts

loc_130EE:
                addq.b  #1,(word_FFD82C+1).w
                bne.s   loc_130F8
                addq.b  #1,(word_FFD82C+1).w

loc_130F8:
                move.b  (word_FFD82C).w,d0
                moveq   #1,d1
                addi.b  #0,d0
                abcd    d1,d0
                move.b  d0,(word_FFD82C).w
                move.w  #$18,(word_FFFFC0).w
                rts

; Game complete/congratulations screen initialization
