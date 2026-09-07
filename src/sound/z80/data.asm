; Flicky Z80 sound banks
; Reconstructed from ROM $0101E0-$010CD3. This translation unit contains the
; bytes loaded at Z80 $1000 and $1200; the 68000 load descriptors live in
; src/sound/z80/load_data.s because their source fields depend on the ROM layout.
;
; The first bank occupies $1000-$11C7 in this file. The original DBF transfer
; deliberately copies one more byte, so its final byte is the first byte of
; zMusicBank. The second transfer similarly consumes one byte after this file.

                cpu     68000
                page    0
                org     0

z80ptr          macro   target,bank,zbase
                dc.b    ((zbase+target-bank)&$FF)
                dc.b    (((zbase+target-bank)>>8)&$FF)
                endm

sfxheader       macro   voices,scale,count
                z80ptr  voices,zSFXBank,$1000
                dc.b    scale,count
                endm

sfxtrack        macro   flags,channel,sequence,transpose,volume
                dc.b    flags,channel
                z80ptr  sequence,zSFXBank,$1000
                dc.b    transpose,volume
                endm

musicheader     macro   voices,fmcount,psgcount,scale,tempo
                z80ptr  voices,zMusicBank,$1200
                dc.b    fmcount,psgcount,scale,tempo
                endm

musicfm         macro   sequence,transpose,volume
                z80ptr  sequence,zMusicBank,$1200
                dc.b    transpose,volume
                endm

musicpsg        macro   sequence,transpose,volume,pitchenv,volumeenv
                z80ptr  sequence,zMusicBank,$1200
                dc.b    transpose,volume,pitchenv,volumeenv
                endm

zSFXBank:
zSFXPointerTable:
                z80ptr  zSFX90Header,zSFXBank,$1000 ; $90
                z80ptr  zSFX91Header,zSFXBank,$1000 ; $91
                z80ptr  zSFX92Header,zSFXBank,$1000 ; $92
                z80ptr  zSFX93Header,zSFXBank,$1000 ; $93
                z80ptr  zSFX94Header,zSFXBank,$1000 ; $94
                z80ptr  zSFX95And96Header,zSFXBank,$1000 ; $95
                z80ptr  zSFX95And96Header,zSFXBank,$1000 ; $96
                z80ptr  zSFX97Header,zSFXBank,$1000 ; $97
                z80ptr  zSFX98Header,zSFXBank,$1000 ; $98
zSpecialSFXPointerTable:
                z80ptr  zSFX90Header,zSFXBank,$1000 ; $D0 aliases $90
zSFX90Header:
                sfxheader zSFX90Voices,$01,1
                sfxtrack  $80,$05,zSFX90Sequence,$F4,$00
zSFX90Sequence:
                dc.b    $EF,$00,$F0,$01,$01,$32,$00,$D2,$0C,$CF,$F2 ; $101E
zSFX90Voices:
                dc.b    $6E,$13,$13,$13,$13,$13,$13,$13,$14,$12,$10,$10,$12,$17,$12,$17 ; $1029
                dc.b    $17,$45,$1A,$AC,$3D,$88,$80,$80,$80 ; $1039
zSFX91Header:
                sfxheader zSFX91Voices,$01,1
                sfxtrack  $80,$05,zSFX91Sequence,$00,$00
zSFX91Sequence:
                dc.b    $F0,$01,$01,$16,$00,$EF,$00,$E4,$02,$01,$00,$03,$01,$C2,$04,$C0 ; $104C
                dc.b    $BF,$BF,$C0,$BB,$BB,$C0,$C4,$F2 ; $105C
zSFX91Voices:
                dc.b    $FD,$03,$03,$16,$33,$0F,$0F,$1F,$0F,$00,$10,$10,$14,$00,$00,$00 ; $1064
                dc.b    $10,$6F,$4F,$5F,$6F,$98,$80,$80,$80 ; $1074
zSFX92Header:
                sfxheader zSFX92Voices,$01,1
                sfxtrack  $80,$05,zSFX92Sequence,$F4,$00
zSFX92Sequence:
                dc.b    $EF,$00,$F0,$03,$01,$F6,$02,$BE,$02,$80,$01,$C2,$06,$D1,$08,$F2 ; $1087
zSFX92Voices:
                dc.b    $3C,$46,$03,$24,$22,$1D,$19,$1C,$19,$14,$0F,$11,$13,$06,$0D,$10 ; $1097
                dc.b    $10,$1F,$1F,$1F,$1F,$14,$00,$06,$80 ; $10A7
zSFX93Header:
                sfxheader zSFX93Voices,$01,1
                sfxtrack  $80,$05,zSFX93Sequence,$00,$00
                dc.b    $E1,$02 ; $10BA
zSFX93Sequence:
                dc.b    $EF,$00,$F0,$04,$01,$60,$06,$E4,$02,$01,$02,$03,$01,$B1,$04,$B2 ; $10BC
                dc.b    $B3,$B2,$B3,$B4,$B5,$B6,$B3,$B6,$B7,$B6,$B7,$B8,$B9,$BA,$B8,$B9 ; $10CC
                dc.b    $BA,$BB,$F2 ; $10DC
zSFX93Voices:
                dc.b    $9C,$48,$23,$54,$22,$1F,$1F,$15,$3C,$08,$08,$18,$18,$0C,$0C,$0C ; $10DF
                dc.b    $0E,$6B,$4F,$5F,$3F,$36,$80,$2F,$90 ; $10EF
zSFX94Header:
                sfxheader zSFX94Voices,$01,1
                sfxtrack  $80,$05,zSFX94Sequence,$00,$00
zSFX94Sequence:
                dc.b    $EF,$00,$E4,$02,$03,$02,$03,$01,$BD,$18,$F2 ; $1102
zSFX94Voices:
                dc.b    $70,$16,$07,$07,$18,$1F,$1F,$1F,$1F,$47,$10,$3F,$8C,$16,$10,$11 ; $110D
                dc.b    $11,$11,$12,$11,$1A,$96,$95,$9D,$80 ; $111D
zSFX95And96Header:
                sfxheader zSFX95And96Voices,$01,1
                sfxtrack  $80,$05,zSFX95And96Sequence,$00,$00
zSFX95And96Sequence:
                dc.b    $E4,$03,$00,$03,$03,$01,$EF,$00,$AE,$03,$AD,$AC,$AB,$AA,$A9,$A8 ; $1130
                dc.b    $A7,$A6,$A5,$A4,$A3,$A2,$A1,$A0,$F2 ; $1140
zSFX95And96Voices:
                dc.b    $B4,$17,$17,$14,$14,$1F,$12,$1F,$08,$14,$14,$14,$14,$0D,$0E,$0E ; $1149
                dc.b    $10,$11,$1F,$17,$0C,$8E,$80,$84,$80 ; $1159
zSFX97Header:
                sfxheader zSFX97Voices,$01,1
                sfxtrack  $80,$05,zSFX97Sequence,$00,$00
zSFX97Sequence:
                dc.b    $EF,$00,$BF,$04,$C3,$C5,$C8,$10,$BF,$04,$C3,$C5,$C8,$10,$F2 ; $116C
zSFX97Voices:
                dc.b    $64,$04,$02,$14,$04,$2C,$19,$2C,$1C,$10,$00,$00,$00,$1D,$11,$10 ; $117B
                dc.b    $06,$02,$1F,$1F,$1F,$92,$80,$92,$80 ; $118B
zSFX98Header:
                sfxheader zSFX98Voices,$01,2
                sfxtrack  $80,$05,zSFX98Sequence0,$00,$00
                sfxtrack  $80,$06,zSFX98Sequence1,$00,$18
zSFX98Sequence1:
                dc.b    $80,$02 ; $11A4
zSFX98Sequence0:
                dc.b    $EF,$00,$C0,$06,$C4,$CF,$D4,$F2 ; $11A6
zSFX98Voices:
                dc.b    $65,$06,$07,$11,$12,$0F,$0F,$3F,$3A,$1F,$1F,$10,$1E,$1D,$00,$00 ; $11AE
                dc.b    $21,$89,$7F,$0C,$0C,$A2,$87,$8C,$80,$00 ; $11BE

; Indices, priorities, envelopes, music, and event streams.
zMusicBank:
zSoundDataIndex:
                z80ptr  zPriorityAndEnvelopeData,zMusicBank,$1200 ; priorities
                z80ptr  zSpecialSFXPointerTable,zSFXBank,$1000 ; special SFX
                z80ptr  zMusicPointerTable,zMusicBank,$1200 ; resident music
                z80ptr  zSFXPointerTable,zSFXBank,$1000 ; resident SFX
                z80ptr  zPriorityAndEnvelopeData,zMusicBank,$1200 ; pitch envelopes
                z80ptr  zPriorityAndEnvelopeData,zMusicBank,$1200 ; volume envelopes
                dc.b    $90,$00 ; $120C
zPriorityAndEnvelopeData:
                dc.b    $80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80 ; $120E
                dc.b    $80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$70 ; $121E
                dc.b    $80,$80,$80,$80,$80,$70,$70,$70,$00,$00,$80,$10,$20,$70,$00,$00 ; $122E
                dc.b    $00,$00,$00,$00,$70,$68,$78,$78,$80,$80,$80,$80,$80,$80,$80 ; $123E
zMusicPointerTable:
                z80ptr  zMusic81Header,zMusicBank,$1200 ; $81
                z80ptr  zMusic82Header,zMusicBank,$1200 ; $82
                z80ptr  zMusic83Header,zMusicBank,$1200 ; $83
                z80ptr  zMusic84Header,zMusicBank,$1200 ; $84
                z80ptr  zMusic85Header,zMusicBank,$1200 ; $85
                dc.b    0,0 ; $86 is unused
                z80ptr  zMusic87Header,zMusicBank,$1200 ; $87
; $88 is unused: its would-be table word is the first word of zMusic81Header.
zMusic81Header:
                musicheader zMusic81Voices,7,0,$02,$00
                musicfm zMusic81FM0,$00,$00
                musicfm zMusic81FM1,$F4,$06
                musicfm zMusic81FM2,$F4,$08
                musicfm zMusic81FM3,$F4,$20
                musicfm zMusic81FM4,$F4,$20
                musicfm zMusic81FM5,$F4,$10
                musicfm zMusic81FM6,$F4,$20
zMusic81FM5:
                dc.b    $80,$02,$E1,$08,$F6,$88,$12 ; $127D
zMusic81FM1:
                dc.b    $EA,$4E,$02,$E6,$EF,$02,$D7,$0C,$CB,$D7,$CB,$D7,$CB,$D7,$CB,$D5 ; $1284
                dc.b    $C9,$D5,$C9,$D5,$C9,$D5,$C9,$D4,$C8,$D4,$C8,$D4,$C8,$D4,$C8,$D2 ; $1294
                dc.b    $C6,$D2,$C6,$D2,$C6,$D2,$C6,$F6,$84,$12 ; $12A4
zMusic81FM6:
                dc.b    $80,$02 ; $12AE
zMusic81FM2:
                dc.b    $EF,$00,$E4,$02,$01,$03,$03,$03,$E8,$06,$CB,$06,$CD,$CF,$0C,$D2 ; $12B0
                dc.b    $CF,$CB,$06,$CD,$CF,$0C,$D2,$CF,$C9,$06,$CB,$CD,$0C,$D0,$CD,$C9 ; $12C0
                dc.b    $06,$CB,$CD,$0C,$D0,$CD,$C8,$06,$C9,$CB,$0C,$D0,$CB,$C8,$06,$C9 ; $12D0
                dc.b    $CB,$0C,$C4,$CB,$C6,$06,$C8,$CA,$0C,$CD,$CA,$C6,$06,$C5,$C6,$C8 ; $12E0
                dc.b    $CA,$C8,$CA,$CD,$F6,$B0,$12 ; $12F0
zMusic81FM3:
                dc.b    $EF,$01,$E8,$06,$B3,$0C,$B3,$B7,$B3,$B3,$B3,$B7,$06,$B5,$B3,$80 ; $12F7
                dc.b    $B5,$0C,$B1,$B5,$B1,$B1,$B1,$B5,$06,$B3,$B1,$0C,$B0,$B0,$B3,$B0 ; $1307
                dc.b    $B0,$B0,$B3,$06,$B1,$B0,$0C,$AE,$AE,$B2,$AE,$AE,$AE,$AE,$06,$B0 ; $1317
                dc.b    $B2,$0C,$F6,$F7,$12 ; $1327
zMusic81FM4:
                dc.b    $EF,$00,$D7,$0C,$D7,$06,$D9,$DB,$80,$D9,$80,$D7,$80,$D2,$80,$D4 ; $132C
                dc.b    $80,$D2,$80,$D9,$80,$D0,$D0,$D5,$80,$D0,$80,$D0,$80,$D5,$80,$D7 ; $133C
                dc.b    $80,$D9,$80,$D4,$80,$D4,$D5,$D7,$80,$D4,$80,$D4,$D5,$D7,$80,$D0 ; $134C
                dc.b    $80,$D0,$80,$D6,$0C,$D6,$06,$D4,$D6,$80,$D4,$80,$D6,$80,$D2,$80 ; $135C
                dc.b    $D4,$80,$D6,$80,$F6,$2C,$13 ; $136C
zMusic81FM0:
                dc.b    $F2 ; $1373
zMusic81Voices:
                dc.b    $2C,$72,$72,$32,$32,$1F,$16,$1F,$1F,$00,$0F,$00,$0F,$00,$09,$00 ; $1374
                dc.b    $09,$06,$36,$06,$36,$15,$80,$14,$80,$38,$36,$34,$30,$31,$1F,$1F ; $1384
                dc.b    $5F,$5F,$12,$1E,$11,$0A,$10,$08,$04,$03,$2F,$4F,$3F,$2F,$30,$20 ; $1394
                dc.b    $14,$80,$38,$64,$32,$11,$32,$55,$9B,$70,$D3,$02,$01,$01,$03,$03 ; $13A4
                dc.b    $01,$03,$00,$15,$0F,$0F,$A0,$21,$47,$21,$80 ; $13B4
zMusic82Header:
                musicheader zMusic82Voices,7,0,$02,$00
                musicfm zMusic82FM0,$00,$20
                musicfm zMusic82FM1,$F4,$06
                musicfm zMusic82FM2,$DC,$17
                musicfm zMusic82FM3,$00,$17
                musicfm zMusic82FM4,$00,$20
                musicfm zMusic82FM5,$00,$20
                musicfm zMusic82FM6,$F4,$04
zMusic82FM4:
                dc.b    $EF,$03,$F6,$F2,$13 ; $13E1
zMusic82FM1:
                dc.b    $EA,$68,$02,$E6,$EF,$01,$E4,$02,$02,$03,$03,$03,$D7,$06,$D5,$D4 ; $13E6
                dc.b    $80,$D4,$80,$D4,$80,$D7,$D5,$D4,$80,$D4,$80,$D4,$80,$D7,$D5,$D4 ; $13F6
                dc.b    $80,$DB,$D9,$D7,$80,$D9,$DB,$DC,$18,$F2 ; $1406
zMusic82FM5:
                dc.b    $E1,$02,$EF,$04,$F6,$19,$14 ; $1410
zMusic82FM2:
                dc.b    $EF,$00,$C8,$06,$C8,$CD,$80,$C8,$80,$CD,$80,$C8,$80,$CD,$80,$CD ; $1417
                dc.b    $80,$CD,$80,$CD,$80,$CD,$D0,$D4,$80,$C8,$CB,$CF,$80,$CD,$18,$F2 ; $1427
zMusic82FM6:
                dc.b    $EF,$05,$F6,$3E,$14 ; $1437
zMusic82FM3:
                dc.b    $EF,$02,$80,$0C,$D0,$06,$C8,$CB,$C8,$D0,$C8,$CB,$C8,$D0,$C8,$CB ; $143C
                dc.b    $C8,$D0,$C8,$CB,$C8,$D0,$C8,$CB,$C8,$D0,$CB,$CD,$CF,$D0,$03,$CF ; $144C
                dc.b    $CD,$CB,$C9,$C8,$C6,$C4,$DC,$0C ; $145C
zMusic82FM0:
                dc.b    $F2 ; $1464
zMusic82Voices:
                dc.b    $38,$38,$30,$30,$31,$1F,$1F,$5F,$5F,$12,$0E,$0A,$0A,$00,$04,$04 ; $1465
                dc.b    $03,$2F,$2F,$2F,$2F,$2A,$2C,$0D,$80,$36,$61,$44,$30,$31,$19,$1F ; $1475
                dc.b    $1F,$1F,$1A,$41,$41,$51,$10,$0A,$06,$09,$49,$5D,$A9,$8A,$01,$80 ; $1485
                dc.b    $85,$80,$20,$6B,$6A,$63,$61,$DF,$DF,$9F,$9F,$07,$06,$09,$06,$07 ; $1495
                dc.b    $06,$06,$08,$23,$12,$11,$54,$1C,$3A,$16,$80,$20,$6B,$6A,$63,$61 ; $14A5
                dc.b    $DF,$DF,$9F,$9F,$07,$06,$09,$06,$07,$06,$06,$08,$23,$12,$11,$54 ; $14B5
                dc.b    $1C,$3A,$16,$80,$14,$66,$41,$62,$61,$DF,$DF,$9F,$9F,$15,$14,$19 ; $14C5
                dc.b    $16,$07,$06,$06,$06,$23,$12,$1F,$5F,$1C,$8A,$16,$80,$22,$65,$64 ; $14D5
                dc.b    $63,$60,$9F,$DF,$9F,$9F,$0C,$16,$19,$16,$07,$06,$06,$08,$23,$12 ; $14E5
                dc.b    $11,$54,$1C,$1A,$36,$80 ; $14F5
zMusic83Header:
                musicheader zMusic83Voices,7,0,$02,$00
                musicfm zMusic83FM0,$00,$20
                musicfm zMusic83FM1,$F4,$10
                musicfm zMusic83FM2,$00,$18
                musicfm zMusic83FM3,$F4,$1C
                musicfm zMusic83FM4,$F4,$0C
                musicfm zMusic83FM5,$F4,$18
                musicfm zMusic83FM6,$F4,$18
zMusic83FM5:
                dc.b    $80,$03,$F0,$0C,$01,$04,$08,$EF,$00,$F6,$2F,$15 ; $151D
zMusic83FM1:
                dc.b    $EA,$34,$02,$E6,$EF,$00,$D7,$06,$D9,$D7,$D6,$D7,$80,$D6,$80,$D7 ; $1529
                dc.b    $12,$D5,$06,$D4,$80,$D2,$80,$D0,$12,$D2,$06,$D4,$80,$D5,$80,$D7 ; $1539
                dc.b    $0C,$80,$CB,$80,$CB,$3C,$C8,$0C,$C9,$CA,$CB,$3C,$D0,$0C,$CF,$CD ; $1549
                dc.b    $CB,$3C,$C9,$0C,$C8,$C6,$C9,$3C,$C6,$0C,$C8,$C9,$CB,$3C,$C8,$0C ; $1559
                dc.b    $C9,$CA,$CB,$3C,$D0,$0C,$CF,$D0,$D2,$0C,$80,$CB,$06,$CA,$CB,$80 ; $1569
                dc.b    $D2,$0C,$80,$CB,$06,$CA,$CB,$80,$CF,$0C,$CD,$CF,$D0,$D2,$30,$F6 ; $1579
                dc.b    $4D,$15 ; $1589
zMusic83FM2:
                dc.b    $EF,$01,$A7,$12,$A2,$06,$A7,$80,$A2,$80,$A7,$12,$A9,$06,$AA,$80 ; $158B
                dc.b    $AB,$80,$AC,$12,$AC,$06,$AC,$80,$AC,$80,$AC,$0C,$80,$A7,$80,$A0 ; $159B
                dc.b    $06,$80,$A7,$A7,$A0,$80,$A7,$80,$F7,$00,$03,$AA,$15,$A0,$80,$A0 ; $15AB
                dc.b    $A2,$A4,$80,$A5,$80,$A7,$80,$9F,$9F,$A2,$80,$9F,$80,$A7,$80,$9F ; $15BB
                dc.b    $9F,$A2,$80,$9F,$80,$A7,$80,$9F,$9F,$A2,$80,$9F,$A2,$A7,$80,$A7 ; $15CB
                dc.b    $A9,$AA,$80,$AB,$80,$A0,$06,$80,$A7,$A7,$A0,$80,$A7,$80,$A0,$80 ; $15DB
                dc.b    $A7,$A7,$A0,$80,$A7,$80,$A0,$80,$A7,$A7,$A0,$80,$9B,$80,$A0,$80 ; $15EB
                dc.b    $A0,$A2,$A4,$80,$A5,$80,$A7,$80,$A7,$A7,$A2,$80,$A2,$80,$A7,$80 ; $15FB
                dc.b    $A7,$A7,$A2,$80,$A2,$80,$A7,$80,$A6,$A6,$A7,$80,$A9,$80,$AB,$80 ; $160B
                dc.b    $A7,$80,$A9,$80,$AB,$80,$F6,$AA,$15 ; $161B
zMusic83FM6:
                dc.b    $80,$03 ; $1624
zMusic83FM3:
                dc.b    $EF,$02,$80,$30,$D4,$12,$D2,$06,$D0,$80,$CF,$80,$CB,$12,$CF,$06 ; $1626
                dc.b    $D0,$80,$D2,$80,$D4,$0C,$80,$CB,$80,$E4,$02,$02,$03,$03,$03,$F8 ; $1636
                dc.b    $9A,$16,$D4,$D5,$D4,$D2,$D4,$D0,$D2,$D4,$D2,$D4,$D2,$D4,$D5,$D4 ; $1646
                dc.b    $D5,$D4,$D2,$D4,$D2,$D4,$D5,$D4,$D5,$D4,$D2,$CB,$CD,$CF,$D0,$CF ; $1656
                dc.b    $D0,$D2,$CF,$CB,$CD,$CF,$D0,$D2,$D4,$D5,$F8,$9A,$16,$D4,$D5,$D7 ; $1666
                dc.b    $DC,$DB,$D9,$D7,$D4,$DE,$DD,$DE,$80,$1E,$DE,$06,$DD,$DE,$80,$1E ; $1676
                dc.b    $CB,$06,$CA,$CB,$CD,$CF,$CD,$CF,$D0,$D2,$D4,$D2,$D4,$D2,$CF,$D0 ; $1686
                dc.b    $D2,$F6,$3F,$16,$D4,$06,$D5,$D4,$D5,$D7,$D5,$D7,$D5,$F7,$00,$03 ; $1696
                dc.b    $9A,$16,$F9 ; $16A6
zMusic83FM4:
                dc.b    $EF,$03,$80,$30,$80,$80,$BA,$03,$BC,$BE,$BF,$C1,$C3,$C4,$C6,$CB ; $16A9
                dc.b    $06,$80,$12,$C8,$0C,$C4,$C8,$C4,$C8,$C4,$C6,$C7,$C8,$C4,$C8,$C4 ; $16B9
                dc.b    $C8,$CB,$C9,$C6,$F7,$00,$02,$BC,$16,$C8,$C4,$C8,$C4,$C8,$C4,$C8 ; $16C9
                dc.b    $C4,$C8,$C4,$C8,$C4,$C8,$C4,$C8,$C4,$CB,$06,$80,$CB,$80,$1E,$CB ; $16D9
                dc.b    $06,$80,$CB,$80,$1E,$CB,$06,$CB,$BF,$80,$CB,$CB,$BF,$80,$BF,$03 ; $16E9
                dc.b    $C1,$C3,$C4,$C6,$C8,$CA,$CB,$CD,$CF,$D0,$D2,$D4,$CA,$CB,$06,$F6 ; $16F9
                dc.b    $BC,$16,$F2 ; $1709
zMusic83FM0:
                dc.b    $F2 ; $170C
zMusic83Voices:
                dc.b    $34,$35,$41,$75,$71,$5B,$9F,$5F,$1F,$04,$07,$07,$08,$00,$00,$00 ; $170D
                dc.b    $00,$F0,$F4,$E0,$F6,$22,$80,$1F,$80,$38,$38,$30,$30,$31,$1F,$1F ; $171D
                dc.b    $5F,$5F,$12,$0E,$0A,$0A,$00,$04,$04,$03,$2F,$2F,$2F,$2F,$24,$2D ; $172D
                dc.b    $18,$80,$3C,$32,$32,$74,$40,$1F,$18,$1F,$1E,$07,$1F,$07,$1F,$00 ; $173D
                dc.b    $00,$00,$00,$1F,$0F,$1F,$0F,$21,$80,$19,$80,$2C,$72,$78,$34,$34 ; $174D
                dc.b    $1F,$12,$1F,$12,$00,$0A,$00,$0A,$00,$00,$00,$00,$0F,$1F,$0F,$1F ; $175D
                dc.b    $16,$90,$17,$90 ; $176D
zMusic84Header:
                musicheader zMusic84Voices,7,3,$02,$00
                musicfm zMusic84FM0,$00,$20
                musicfm zMusic84FM1,$F4,$10
                musicfm zMusic84FM2,$F4,$10
                musicfm zMusic84FM3,$F4,$10
                musicfm zMusic84FM4,$F4,$16
                musicfm zMusic84FM5,$F4,$10
                musicfm zMusic84FM6,$F4,$10
                musicpsg zMusic84PSGSequence,$F4,$08,$08,$00
                musicpsg zMusic84PSGSequence,$F4,$08,$00,$02
                musicpsg zMusic84PSGSequence,$F4,$08,$00,$03
zMusic84FM4:
                dc.b    $80,$06,$F0,$06,$01,$04,$06,$F6,$B3,$17 ; $17A5
zMusic84FM1:
                dc.b    $EA,$90,$02,$E6,$EF,$01,$D4,$06,$CF,$CC,$C8,$C8,$C3,$C0,$C8,$80 ; $17AF
                dc.b    $18,$D4,$06,$CF,$CC,$C8,$C8,$C3,$C0,$BC,$C0,$C3,$C8,$C0,$D4,$18 ; $17BF
                dc.b    $F2 ; $17CF
zMusic84FM5:
                dc.b    $D4,$17 ; $17D0
zMusic84FM2:
                dc.b    $E0,$80,$EF,$01,$F2 ; $17D2
zMusic84FM6:
                dc.b    $80,$01,$EF,$02,$E1,$02,$E4,$01,$01,$00,$01,$03,$F6,$E6,$17 ; $17D7
zMusic84FM3:
                dc.b    $EF,$00,$80,$30,$C8,$06,$C3,$C0,$BC,$C0,$BC,$C0,$B7,$BC,$C0,$C3 ; $17E6
                dc.b    $C0,$C3,$BC,$C0,$C3,$BC,$18,$F2 ; $17F6
zMusic84PSGSequence:
                dc.b    $F2 ; $17FE
zMusic84FM0:
                dc.b    $F2 ; $17FF
zMusic84Voices:
                dc.b    $14,$04,$01,$00,$00,$1F,$1F,$1F,$1F,$10,$0F,$09,$08,$07,$00,$00 ; $1800
                dc.b    $00,$3F,$0F,$0F,$4F,$10,$80,$10,$80,$14,$04,$02,$01,$02,$1F,$1F ; $1810
                dc.b    $1F,$1F,$10,$0F,$09,$08,$07,$00,$00,$00,$3F,$0F,$0F,$4F,$10,$80 ; $1820
                dc.b    $10,$80,$10,$04,$02,$08,$04,$1F,$1F,$1F,$1F,$10,$0F,$09,$08,$07 ; $1830
                dc.b    $00,$00,$00,$3F,$0F,$0F,$4F,$20,$20,$20,$80,$10,$04,$02,$08,$04 ; $1840
                dc.b    $1F,$1F,$1F,$1F,$10,$0F,$09,$08,$07,$00,$00,$00,$3F,$0F,$0F,$4F ; $1850
                dc.b    $20,$20,$20,$80,$35,$05,$03,$07,$02,$19,$20,$15,$0F,$0C,$09,$10 ; $1860
                dc.b    $06,$1F,$00,$10,$00,$1F,$3F,$3F,$3F,$10,$80,$80,$80 ; $1870
zMusic85Header:
                musicheader zMusic85Voices,7,0,$02,$00
                musicfm zMusic85FM0,$00,$20
                musicfm zMusic85FM1,$F4,$07
                musicfm zMusic85FM2,$E8,$17
                musicfm zMusic85FM3,$F4,$10
                musicfm zMusic85FM4,$E8,$1B
                musicfm zMusic85FM5,$F4,$10
                musicfm zMusic85FM6,$F4,$10
zMusic85FM5:
                dc.b    $80,$03,$F0,$03,$01,$04,$05,$EF,$00,$F6,$B7,$18 ; $189F
zMusic85FM1:
                dc.b    $EA,$44,$02,$E6,$EF,$00,$E4,$02,$01,$03,$02,$02,$D4,$0C,$D6,$D4 ; $18AB
                dc.b    $D6,$D4,$D6,$D4,$D6,$D4,$D9,$18,$0C,$D6,$80,$D4,$80,$D4,$D6,$D4 ; $18BB
                dc.b    $D6,$D4,$D6,$D4,$D6,$D4,$D9,$D8,$D6,$D4,$D6,$D8,$D9,$DB,$80,$D9 ; $18CB
                dc.b    $D6,$3C,$DB,$0C,$80,$D9,$D4,$3C,$DB,$0C,$80,$D9,$D6,$D4,$D6,$D8 ; $18DB
                dc.b    $DB,$D9,$D8,$D9,$D8,$D9,$F2 ; $18EB
zMusic85FM2:
                dc.b    $EF,$02,$E4,$02,$01,$03,$03,$03,$D4,$06,$CD,$D1,$CD,$D4,$CD,$D1 ; $18F2
                dc.b    $CD,$D4,$CD,$D1,$CD,$D4,$CD,$D3,$D4,$F7,$00,$04,$FA,$18,$D6,$CD ; $1902
                dc.b    $D2,$CD,$D6,$CD,$D2,$CD,$D6,$CD,$D2,$CD,$D6,$CD,$D5,$D6,$D4,$CD ; $1912
                dc.b    $D1,$CD,$D4,$CD,$D1,$CD,$D4,$CD,$D1,$CD,$D4,$CD,$D3,$D4,$D6,$CD ; $1922
                dc.b    $D2,$CD,$D6,$CD,$D2,$D6,$D8,$CF,$D4,$CF,$D8,$CF,$D4,$D8,$D9,$D1 ; $1932
                dc.b    $D8,$D1,$D9,$D1,$D8,$D1,$EF,$04,$D9,$03,$D8,$D6,$D4,$D2,$D1,$CF ; $1942
                dc.b    $CD,$D9,$0C,$F2 ; $1952
zMusic85FM3:
                dc.b    $EF,$03,$E4,$02,$01,$03,$03,$03,$80,$60,$80,$80,$80,$80,$30,$C6 ; $1956
                dc.b    $03,$C8,$CA,$CC,$CD,$CF,$D1,$D2,$D4,$D6,$D8,$D9,$DB,$DD,$DE,$06 ; $1966
                dc.b    $80,$30,$C8,$03,$CA,$CC,$CD,$CF,$D1,$D2,$D4,$D6,$D8,$D9,$DB,$DD ; $1976
                dc.b    $DE,$E0,$06,$F2 ; $1986
zMusic85FM4:
                dc.b    $EF,$02,$A9,$0C,$B5,$A9,$06,$A9,$B5,$0C,$F7,$00,$08,$8C,$19,$AE ; $198A
                dc.b    $BA,$AE,$06,$AE,$BA,$0C,$AE,$B0,$B2,$B4,$B5,$C1,$B5,$06,$B5,$C1 ; $199A
                dc.b    $0C,$B5,$B4,$B2,$B0,$AE,$BA,$AE,$06,$AE,$BA,$0C,$B0,$BC,$B0,$06 ; $19AA
                dc.b    $B0,$BC,$0C,$B5,$B4,$B5,$B4,$B5,$80,$A9,$F2 ; $19BA
zMusic85FM6:
                dc.b    $EF,$04,$EF,$04,$EF,$04,$F2,$F2 ; $19C5
zMusic85FM0:
                dc.b    $F2 ; $19CD
zMusic85Voices:
                dc.b    $33,$31,$01,$10,$32,$10,$1F,$1F,$0F,$0F,$01,$16,$0B,$0B,$07,$28 ; $19CE
                dc.b    $00,$5F,$5F,$3A,$3A,$97,$18,$E4,$80,$10,$04,$02,$08,$04,$1F,$1F ; $19DE
                dc.b    $1F,$1F,$10,$0F,$09,$08,$07,$00,$00,$00,$3F,$0F,$0F,$4F,$20,$20 ; $19EE
                dc.b    $20,$80,$2C,$72,$72,$32,$32,$1F,$16,$1F,$1F,$00,$0F,$00,$0F,$00 ; $19FE
                dc.b    $09,$00,$09,$06,$36,$06,$3F,$15,$80,$14,$80,$2C,$26,$26,$23,$23 ; $1A0E
                dc.b    $1F,$15,$1F,$14,$10,$10,$12,$09,$03,$03,$03,$03,$4F,$4F,$4F,$4F ; $1A1E
                dc.b    $15,$90,$14,$80,$3B,$06,$36,$63,$32,$DF,$54,$D0,$8F,$09,$07,$0B ; $1A2E
                dc.b    $04,$03,$00,$00,$00,$EF,$FF,$2F,$0F,$28,$29,$1C,$80 ; $1A3E
zMusic87Header:
                musicheader zMusic87Voices,6,2,$02,$00
                musicfm zMusic87FM0,$00,$00
                musicfm zMusic87FM1,$01,$00
                musicfm zMusic87FM2,$FF,$08
                musicfm zMusic87FM3,$F5,$10
                musicfm zMusic87FM4,$F5,$10
                musicfm zMusic87FM5,$F5,$20
                musicpsg zMusic87PSGSequence,$F5,$08,$01,$01
                musicpsg zMusic87PSGSequence,$F5,$08,$00,$02
zMusic87FM3:
                dc.b    $80,$05,$F0,$03,$01,$04,$09,$EF,$00,$F6,$87,$1A ; $1A75
zMusic87FM1:
                dc.b    $EA,$27,$03,$E6,$EF,$00,$E4,$02,$03,$02,$03,$03,$BE,$0C,$C0,$BE ; $1A81
                dc.b    $C0,$B9,$80,$B9,$80,$BC,$06,$BB,$BA,$B9,$B8,$B7,$B6,$B5,$B4,$B3 ; $1A91
                dc.b    $B2,$B1,$B0,$AF,$AE,$AD,$F2 ; $1AA1
zMusic87FM4:
                dc.b    $80,$03,$F0,$03,$01,$04,$09,$EF,$00,$F6,$B6,$1A ; $1AA8
zMusic87FM2:
                dc.b    $EF,$00,$E4,$02,$03,$02,$02,$03,$BE,$0C,$C0,$BE,$C0,$B9,$80,$B9 ; $1AB4
                dc.b    $80,$BC,$06,$BB,$BA,$B9,$B8,$B7,$B6,$B5,$B4,$B3,$B2,$B1,$B0,$AF ; $1AC4
                dc.b    $AE,$AD,$F2 ; $1AD4
zMusic87FM5:
                dc.b    $EF,$00,$EF,$00,$EF,$00,$F2 ; $1AD7
zMusic87PSGSequence:
                dc.b    $F2 ; $1ADE
zMusic87FM0:
                dc.b    $F2 ; $1ADF
zMusic87Voices:
                dc.b    $F1,$04,$04,$12,$14,$0F,$0F,$3C,$3A,$00,$10,$10,$14,$00,$00,$00 ; $1AE0
                dc.b    $10,$7F,$7F,$7F,$0C,$96,$93,$99,$80,$10,$04,$02,$08,$04,$1F,$1F ; $1AF0
                dc.b    $1F,$1F,$10,$0F,$09,$08,$07,$00,$00,$00,$3F,$0F,$0F,$4F,$20,$20 ; $1B00
                dc.b    $20,$80,$10,$04,$02,$08,$04,$1F,$1F,$1F,$1F,$10,$0F,$09,$08,$07 ; $1B10
                dc.b    $00,$00,$00,$3F,$0F,$0F,$4F,$20,$20,$20,$80,$00 ; $1B20

zSoundBanksEnd:
