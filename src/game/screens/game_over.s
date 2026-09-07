; Game over and time over text
; ROM $016DAA-$016E57

Obj_GameOverText:
                bset    #7,(a0)
                bne.s   Obj_GameOverText_Return
                move.w  #$D8,$20(a0)
                move.w  #$118,$24(a0)
                move.l  #Obj_GameOverTextData,$C(a0)
                move.b  #1,(Ram_CutsceneFlag).w

Obj_GameOverText_Return:
                rts

; Time over text display object
Obj_TimeOverText:
                bset    #7,(a0)
                bne.s   Obj_TimeOverText_Return
                move.l  #Obj_TimeOverTextData,$C(a0)
                move.w  #$F0,$20(a0)
                move.w  #$108,$24(a0)

Obj_TimeOverText_Return:
                rts

Gfx_SharedPalette:  binclude "data/palettes/shared-compact.bin"
