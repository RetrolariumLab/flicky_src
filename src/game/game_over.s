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

Gfx_SharedPalette:  dc.w    $2EEE, $300E, $4666, $5006, $62EE, $7E4E, $8E66, $9EE2
                dc.w    $A2A0, $B242, $CE00, $DC8E, $EC80, $FE40, $1016, $201E
                dc.w    $3CD4, $44BA, $56FE, $6094, $7094, $82D2, $92D2, $A6FE
                dc.w    $C8FE, $D0BE, $E07E, $F4DA, $1D60, $2920, $3900, $43EE
                dc.w    $51CE, $618C, $7D2E, $8700, $9FEA, $A322, $B148, $C9CE
                dc.w    $D1E8, $E1C0, $F140, $1FD0, $2DDC, $33BA, $4176, $5776
                dc.w    $6332, $71FE, $913C, $A17C, $C1FE, $D170, $E158, $F15F
