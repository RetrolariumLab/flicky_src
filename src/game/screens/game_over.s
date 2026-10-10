; Game over and pause text
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

; Pause text display object (the mapping spells PAUSE)
Obj_PauseText:
                bset    #7,(a0)
                bne.s   Obj_PauseText_Return
                move.l  #Obj_PauseTextData,$C(a0)
                move.w  #$F0,$20(a0)
                move.w  #$108,$24(a0)

Obj_PauseText_Return:
                rts

Gfx_SharedPalette:  binclude "data/palettes/shared-compact.bin"
