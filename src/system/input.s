; Joypad initialization and polling
; ROM $000DC0-$000E41

Input_ProcessJoypads:
                bsr.w   InitJoypads                     ; was: sub_DC0
                lea     (Ram_ButtonStates).w,a0
                move.w  (Ram_Joypad).w,d0
                moveq   #$E,d1
                moveq   #6,d2

Input_ProcessJoypads_UpperBitLoop:                      ; was: loc_DD0
                btst    d1,d0
                sne     (a0)+
                subq.b  #1,d1
                dbf     d2,Input_ProcessJoypads_UpperBitLoop
                moveq   #6,d1
                moveq   #2,d2

Input_ProcessJoypads_LowerBitLoop:                      ; was: loc_DDE
                btst    d1,d0
                sne     (a0)+
                subq.b  #1,d1
                dbf     d2,Input_ProcessJoypads_LowerBitLoop
                andi.b  #$70,d0
                sne     (a0)+
                tst.b   (Ram_ButtonRepeatEnable).w      ; !(UNKNOWN) RAM-003 nothing ever sets this
                beq.s   Input_ProcessJoypads_Return
                clr.b   (Ram_ButtonRepeatFlag).w

Input_ProcessJoypads_Return:                            ; was: locret_DF8
                rts

InitJoypads:
                bsr.w   RequestZ80Bus
                lea     (Ram_Joypad).w,a0
                lea     ((IO_CT1_DATA+1)).l,a1
                bsr.s   Input_ReadPort
                addq.w  #2,a1
                bsr.s   Input_ReadPort
                bra.w   Sound_ReleaseZ80Check

; Reads controller port with 6-button protocol
Input_ReadPort:
                move.b  #0,(a1)                         ; was: sub_E12
                nop
                nop
                move.b  (a1),d0
                lsl.b   #2,d0
                andi.b  #$C0,d0
                move.b  #$40,(a1)
                nop
                nop
                move.b  (a1),d1
                andi.b  #$3F,d1
                or.b    d1,d0
                not.b   d0
                move.b  d0,d1
                move.b  (a0),d2
                eor.b   d2,d0
                move.b  d1,(a0)+
                and.b   d1,d0
                move.b  d0,(a0)+
                rts

; Loads alternate VDP register set
