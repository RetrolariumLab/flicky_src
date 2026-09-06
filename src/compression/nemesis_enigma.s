; Nemesis and Enigma decompressors
; ROM $000AD4-$000DBF

; !(UNKNOWN) DATA-002 no encoder reproduces these streams byte for byte
Nem_Decomp:
                movem.l d0-d7/a0-a1/a3-a5,-(sp)
                lea     (Nem_PCD_WriteRowToVDP).l,a3
                lea     (VDP_DATA).l,a4
                bra.s   Nem_Decomp_Main

Nem_Decomp_To_RAM:
                movem.l d0-d7/a0-a1/a3-a5,-(sp)
                lea     (Nem_PCD_WriteRowToRAM).l,a3

Nem_Decomp_Main:
                lea     (Ram_DecompCodeTable).w,a1
                move.w  (a0)+,d2
                lsl.w   #1,d2
                bcc.s   Nem_Decomp_Main_Setup
                adda.w  #(Nem_PCD_WriteRowToRAM-2-Nem_PCD_WriteRowToVDP_XOR),a3

Nem_Decomp_Main_Setup:                                  ; was: loc_AFE
                lsl.w   #2,d2
                movea.w d2,a5
                moveq   #8,d3
                moveq   #0,d2
                moveq   #0,d4
                bsr.w   Nem_Build_Code_Table
                bsr.w   Nem_GetCodeWord

Nem_Process_Compressed_Data:
                moveq   #8,d0
                bsr.w   Nem_GetBits
                cmpi.w  #$FC,d1
                bcc.s   Nem_Process_Compressed_Data_Inline
                add.w   d1,d1
                move.b  (a1,d1.w),d0
                ext.w   d0
                bsr.w   Nem_PCD_InlineData
                move.b  1(a1,d1.w),d1

Nem_PCD_GetRepeatCount:
                move.w  d1,d0
                andi.w  #$F,d1
                andi.w  #$F0,d0
                lsr.w   #4,d0

Nem_PCD_WritePixel:
                lsl.l   #4,d4
                or.b    d1,d4
                subq.w  #1,d3
                bne.s   Nem_PCD_WritePixel_Loop
                jmp     (a3)

Nem_PCD_NewRow:
                moveq   #0,d4
                moveq   #8,d3

Nem_PCD_WritePixel_Loop:
                dbf     d0,Nem_PCD_WritePixel
                bra.s   Nem_Process_Compressed_Data

Nem_Process_Compressed_Data_Inline:                     ; was: loc_B4C
                moveq   #6,d0
                bsr.w   Nem_PCD_InlineData
                moveq   #7,d0
                bsr.w   Nem_GetBitsShift
                bra.s   Nem_PCD_GetRepeatCount

Nem_PCD_WriteRowToVDP:
                move.l  d4,(a4)
                subq.w  #1,a5
                move.w  a5,d4
                bne.s   Nem_PCD_NewRow
                bra.s   Nem_Decomp_Done

Nem_PCD_WriteRowToVDP_XOR:
                eor.l   d4,d2
                move.l  d2,(a4)
                subq.w  #1,a5
                move.w  a5,d4
                bne.s   Nem_PCD_NewRow

Nem_PCD_WriteRowToVDP_XOR_Done:                         ; was: loc_B6E
                bra.s   Nem_Decomp_Done

Nem_PCD_WriteRowToRAM:
                move.l  d4,(a4)+
                subq.w  #1,a5
                move.w  a5,d4
                bne.s   Nem_PCD_NewRow
                bra.s   Nem_Decomp_Done
                eor.l   d4,d2
                move.l  d2,(a4)+
                subq.w  #1,a5
                move.w  a5,d4
                bne.s   Nem_PCD_NewRow

Nem_Decomp_Done:                                        ; was: loc_B84
                movem.l (sp)+,d0-d7/a0-a1/a3-a5
                rts

Nem_Build_Code_Table:
                move.b  (a0)+,d0

Nem_BCT_ChkEnd:
                cmpi.b  #$FF,d0
                bne.s   Nem_BCT_NewPalIndex
                rts

Nem_BCT_NewPalIndex:
                move.w  d0,d7

Nem_BCT_Loop:
                move.b  (a0)+,d0
                cmpi.b  #$80,d0
                bcc.s   Nem_BCT_ChkEnd
                move.b  d0,d1
                andi.w  #$F,d7
                andi.w  #$70,d1
                or.w    d1,d7
                andi.w  #$F,d0
                move.b  d0,d1
                lsl.w   #8,d1
                or.w    d1,d7
                moveq   #8,d1
                sub.w   d0,d1
                bne.s   Nem_BCT_ShortCode
                move.b  (a0)+,d0
                add.w   d0,d0
                move.w  d7,(a1,d0.w)
                bra.s   Nem_BCT_Loop

Nem_BCT_ShortCode:
                move.b  (a0)+,d0
                lsl.w   d1,d0
                add.w   d0,d0
                moveq   #1,d5
                lsl.w   d1,d5
                subq.w  #1,d5

Nem_BCT_ShortCode_Loop:
                move.w  d7,(a1,d0.w)
                addq.w  #2,d0
                dbf     d5,Nem_BCT_ShortCode_Loop
                bra.s   Nem_BCT_Loop

; Nemesis bit shift helper for decompression
Nem_BitShift:
                lsl.w   d0,d5                           ; was: sub_BDC
                add.w   d0,d6
                add.w   d0,d0
                and.w   Nem_PCD_InlineData_Return(pc,d0.w),d1
                add.w   d1,d5
                move.w  d6,d0
                subq.w  #8,d0
                bcs.s   Nem_BitShift_Return
                bne.s   Nem_BitShift_EmitPartial
                clr.w   d6
                move.b  d5,(a0)+
                rts

Nem_BitShift_EmitPartial:                               ; was: loc_BF6
                move.w  d5,d6
                lsr.w   d0,d6
                move.b  d6,(a0)+
                move.w  d0,d6

Nem_BitShift_Return:                                    ; was: locret_BFE
                rts

; Nemesis flush remaining bits to output
Nem_FlushBits:
                neg.w   d6                              ; was: sub_C00
                beq.s   Nem_FlushBits_Return
                addq.w  #8,d6
                lsl.w   d6,d5
                move.b  d5,(a0)+

Nem_FlushBits_Return:                                   ; was: locret_C0A
                rts

; Reads 2 bytes from (a0)+ into d5, sets d6=16 (Nemesis decompressor)
Nem_GetCodeWord:
                move.b  (a0)+,d5                        ; was: sub_C0C
                asl.w   #8,d5
                move.b  (a0)+,d5
                moveq   #$10,d6
                rts

; Extracts d0 bits from code word d5 (Nemesis decompressor)
Nem_GetBits:
                move.w  d6,d7                           ; was: sub_C16
                sub.w   d0,d7
                move.w  d5,d1
                lsr.w   d7,d1
                add.w   d0,d0
                and.w   Nem_BitMaskTable-2(pc,d0.w),d1
                rts

; Gets bits and shifts for inline data (Nemesis decompressor)
Nem_GetBitsShift:
                bsr.s   Nem_GetBits                     ; was: sub_C26
                lsr.w   #1,d0

Nem_PCD_InlineData:
                sub.w   d0,d6
                cmpi.w  #9,d6
                bcc.s   Nem_PCD_InlineData_Return
                addq.w  #8,d6
                asl.w   #8,d5
                move.b  (a0)+,d5

; Shared return for the bit reader. It doubles as the base of the mask table
; that starts two bytes later, which is why several routines index it
; pc-relative as Nem_PCD_InlineData_Return(pc,dN.w)
Nem_PCD_InlineData_Return:                              ; was: locret_C38
                rts

; Masks of the low 1..16 bits, indexed by (bit count * 2)
Nem_BitMaskTable:       dc.w    1                       ; was: word_C3A
                dc.w    3
                dc.w    7
                dc.w    $F
                dc.w    $1F
                dc.w    $3F
                dc.w    $7F
                dc.w    $FF
                dc.w    $1FF
                dc.w    $3FF
                dc.w    $7FF
                dc.w    $FFF
                dc.w    $1FFF
                dc.w    $3FFF
                dc.w    $7FFF
                dc.w    $FFFF
; Enigma tile decode with pattern bits
Eni_DecodeTile:
                move.w  a3,d3                           ; was: sub_C5A
                swap    d4
                bpl.s   Eni_DecodeTile_CheckHFlip
                subq.w  #1,d6
                btst    d6,d5
                beq.s   Eni_DecodeTile_CheckHFlip
                ori.w   #$1000,d3

Eni_DecodeTile_CheckHFlip:                              ; was: loc_C6A
                swap    d4
                bpl.s   Eni_DecodeTile_ReadIndex
                subq.w  #1,d6
                btst    d6,d5
                beq.s   Eni_DecodeTile_ReadIndex
                ori.w   #$800,d3

Eni_DecodeTile_ReadIndex:                               ; was: loc_C78
                move.w  d5,d1
                move.w  d6,d7
                sub.w   a5,d7
                bcc.s   Eni_DecodeTile_HaveEnoughBits
                move.w  d7,d6
                addi.w  #$10,d6
                neg.w   d7
                lsl.w   d7,d1
                move.b  (a0),d5
                rol.b   d7,d5
                add.w   d7,d7
                and.w   Nem_PCD_InlineData_Return(pc,d7.w),d5
                add.w   d5,d1

Eni_DecodeTile_MaskAndCombine:                          ; was: loc_C96
                move.w  a5,d0
                add.w   d0,d0
                and.w   Nem_PCD_InlineData_Return(pc,d0.w),d1
                add.w   d3,d1
                move.b  (a0)+,d5
                lsl.w   #8,d5
                move.b  (a0)+,d5
                rts

Eni_DecodeTile_HaveEnoughBits:                          ; was: loc_CA8
                beq.s   Eni_DecodeTile_RefillWord
                lsr.w   d7,d1
                move.w  a5,d0
                add.w   d0,d0
                and.w   Nem_PCD_InlineData_Return(pc,d0.w),d1
                add.w   d3,d1
                move.w  a5,d0
                bra.w   Nem_PCD_InlineData

Eni_DecodeTile_RefillWord:                              ; was: loc_CBC
                moveq   #$10,d6
                bra.s   Eni_DecodeTile_MaskAndCombine

; Sets up Nemesis decompression to VDP_DATA
Nem_DecompSetup:
                movem.l d0-d6/a0/a4,-(sp)               ; was: sub_CC0
                moveq   #0,d4
                lea     (VDP_DATA).l,a4
                bra.s   Nem_Decomp1bpp_Begin

; Nemesis decompress to RAM buffer
Nem_DecompToRAM:
                movem.l d0-d6/a0/a4,-(sp)               ; was: sub_CCE
                moveq   #4,d4

Nem_Decomp1bpp_Begin:                                   ; was: loc_CD4
                asl.w   #3,d1
                subq.w  #1,d1
                move.b  d0,d2
                move.b  d2,d3
                lsr.b   #4,d2
                andi.b  #$F,d3

Nem_Decomp1bpp_RowLoop:                                 ; was: loc_CE2
                moveq   #7,d6
                move.b  (a0)+,d0

Nem_Decomp1bpp_PixelLoop:                               ; was: loc_CE6
                lsl.l   #4,d5
                btst    d6,d0
                beq.s   Nem_Decomp1bpp_PixelLow
                or.b    d2,d5
                bra.s   Nem_Decomp1bpp_PixelNext

Nem_Decomp1bpp_PixelLow:                                ; was: loc_CF0
                or.b    d3,d5

Nem_Decomp1bpp_PixelNext:                               ; was: loc_CF2
                dbf     d6,Nem_Decomp1bpp_PixelLoop
                move.l  d5,(a4)
                adda.l  d4,a4
                dbf     d1,Nem_Decomp1bpp_RowLoop
                movem.l (sp)+,d0-d6/a0/a4
                rts

; Main Enigma tilemap decompression routine
Eni_Decompress:
                movem.l d0-d7/a1-a5,-(sp)               ; was: sub_D04
                movea.w d0,a3
                move.b  (a0)+,d0
                ext.w   d0
                movea.w d0,a5
                move.b  (a0)+,d0
                ext.w   d0
                ext.l   d0
                ror.l   #1,d0
                ror.w   #1,d0
                move.l  d0,d4
                movea.w (a0)+,a2
                adda.w  a3,a2
                movea.w (a0)+,a4
                adda.w  a3,a4
                bsr.w   Nem_GetCodeWord

Eni_Decompress_NextOpcode:                              ; was: loc_D28
                moveq   #7,d0
                bsr.w   Nem_GetBits
                move.w  d1,d2
                moveq   #7,d0
                cmpi.w  #$40,d1
                bcc.s   Eni_Decompress_Dispatch
                moveq   #6,d0
                lsr.w   #1,d2

Eni_Decompress_Dispatch:                                ; was: loc_D3C
                bsr.w   Nem_PCD_InlineData
                andi.w  #$F,d2
                lsr.w   #4,d1
                add.w   d1,d1
                jmp     Eni_OpcodeJumpTable(pc,d1.w)

; Writes incrementing tile pattern (Enigma decompressor)
Eni_WriteTileInc:
                move.w  a2,(a1)+                        ; was: sub_D4C
                addq.w  #1,a2
                dbf     d2,Eni_WriteTileInc
                bra.s   Eni_Decompress_NextOpcode

; Enigma write repeated tile pattern
Eni_WriteRepeat:
                move.w  a4,(a1)+                        ; was: sub_D56
                dbf     d2,Eni_WriteRepeat
                bra.s   Eni_Decompress_NextOpcode

; Enigma write static tile value
Eni_WriteStatic:
                bsr.w   Eni_DecodeTile                  ; was: sub_D5E

Eni_WriteStatic_Loop:                                   ; was: loc_D62
                move.w  d1,(a1)+
                dbf     d2,Eni_WriteStatic_Loop
                bra.s   Eni_Decompress_NextOpcode

; Enigma write incrementing tile values
Eni_WriteIncrement:
                bsr.w   Eni_DecodeTile                  ; was: sub_D6A

Eni_WriteIncrement_Loop:                                ; was: loc_D6E
                move.w  d1,(a1)+
                addq.w  #1,d1
                dbf     d2,Eni_WriteIncrement_Loop
                bra.s   Eni_Decompress_NextOpcode

; Enigma write decrementing tile values
Eni_WriteDecrement:
                bsr.w   Eni_DecodeTile                  ; was: sub_D78

Eni_WriteDecrement_Loop:                                ; was: loc_D7C
                move.w  d1,(a1)+
                subq.w  #1,d1
                dbf     d2,Eni_WriteDecrement_Loop
                bra.s   Eni_Decompress_NextOpcode

; Decodes inline tile data (Enigma decompressor)
Eni_DecodeInline:
                cmpi.w  #$F,d2                          ; was: sub_D86
                beq.s   Eni_DecodeInline_Finish

Eni_DecodeInline_Loop:                                  ; was: loc_D8C
                bsr.w   Eni_DecodeTile
                move.w  d1,(a1)+
                dbf     d2,Eni_DecodeInline_Loop
                bra.s   Eni_Decompress_NextOpcode

; Enigma opcode dispatch: the decoded opcode indexes this table of branches
Eni_OpcodeJumpTable:                                    ; was: loc_D98
                bra.s   Eni_WriteTileInc
                bra.s   Eni_WriteTileInc
                bra.s   Eni_WriteRepeat
                bra.s   Eni_WriteRepeat
                bra.s   Eni_WriteStatic
                bra.s   Eni_WriteIncrement
                bra.s   Eni_WriteDecrement
                bra.s   Eni_DecodeInline

Eni_DecodeInline_Finish:                                ; was: loc_DA8
                subq.w  #1,a0
                cmpi.w  #$10,d6
                bne.s   Eni_DecodeInline_AlignCheck
                subq.w  #1,a0

Eni_DecodeInline_AlignCheck:                            ; was: loc_DB2
                move.w  a0,d0
                lsr.w   #1,d0
                bcc.s   Eni_Decompress_Done
                addq.w  #1,a0

Eni_Decompress_Done:                                    ; was: loc_DBA
                movem.l (sp)+,d0-d7/a1-a5
                rts

; Reads joypad state and sets individual button flags
