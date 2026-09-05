; Game over and time over text.
; ROM $016DAA-$016E57.

Obj_GameOverText:
                bset    #7,(a0)  ; was: sub_16DAA
                bne.s   locret_16DCA
                move.w  #$D8,$20(a0)
                move.w  #$118,$24(a0)
                move.l  #word_1ACA4,$C(a0)
                move.b  #1,(byte_FFD27B).w

locret_16DCA:
                rts

; Time over text display object
Obj_TimeOverText:
                bset    #7,(a0)  ; was: sub_16DCC
                bne.s   locret_16DE6
                move.l  #word_1AD32,$C(a0)
                move.w  #$F0,$20(a0)
                move.w  #$108,$24(a0)

locret_16DE6:
                rts

word_16DE8:     binclude "data/palettes/shared-compact.bin"
