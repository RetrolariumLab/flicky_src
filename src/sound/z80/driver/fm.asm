zReadFMEvent:
                ld e,(ix+zTrackData)
                ld d,(ix+4)
                res 1,(ix+zTrackFlags)
                res 4,(ix+zTrackFlags)

zLoc_01E4:
                ld a,(de)
                inc de
                cp 0E0h
                jp nc,zDispatchCoordFlag
                ex af,af'
                call zKeyOffTrack
                call zUpdateModulation
                ex af,af'
                bit 3,(ix+zTrackFlags)
                jp nz,zLoc_0250
                or a
                jp p,zLoc_0276
                sub 81h
                jp p,zLoc_0208
                call zStopPSGTrack
                jr zLoc_0236

zLoc_0208:
                add a,(ix+zTrackTranspose)
                ld hl,zFMFrequencyTable
                push af
                rst zGetWordTableEntry
                pop af
                bit 7,(ix+zTrackChannel)
                jr nz,zLoc_0230
                push de
                ld d,8
                ld e,12
                ex af,af'
                xor a

zLoc_021E:
                ex af,af'
                sub e
                jr c,zLoc_0227
                ex af,af'
                add a,d
                jr zLoc_021E

zLoc_0226:
                db      8

zLoc_0227:
                add a,e
                ld hl,zPSGFrequencyTable
                rst zGetWordTableEntry
                ex af,af'
                or h
                ld h,a
                pop de

zLoc_0230:
                ld (ix+zTrackFrequency),l
                ld (ix+0Eh),h

zLoc_0236:
                bit 5,(ix+zTrackFlags)
                jr nz,zLoc_0249
                ld a,(de)
                or a
                jp p,zLoc_0275
                ld a,(ix+zTrackSavedDuration)
                ld (ix+zTrackDuration),a
                jr zLoc_027C

zLoc_0249:
                ld a,(de)
                inc de
                ld (ix+zTrackFrequencyOffset),a
                jr zLoc_0274

zLoc_0250:
                ld h,a
                ld a,(de)
                inc de
                ld l,a
                or h
                jr z,zLoc_0263
                ld a,(ix+zTrackTranspose)
                ld b,0
                or a
                jp p,zLoc_0261
                dec b

zLoc_0261:
                ld c,a
                add hl,bc

zLoc_0263:
                ld (ix+zTrackFrequency),l
                ld (ix+0Eh),h
                bit 5,(ix+zTrackFlags)
                jr z,zLoc_0274
                ld a,(de)
                inc de
                ld (ix+zTrackFrequencyOffset),a

zLoc_0274:
                ld a,(de)

zLoc_0275:
                inc de

zLoc_0276:
                call zScaleDuration
                ld (ix+zTrackSavedDuration),a

zLoc_027C:
                ld (ix+zTrackData),e
                ld (ix+4),d
                ld a,(ix+zTrackSavedDuration)
                ld (ix+zTrackDuration),a
                bit 1,(ix+zTrackFlags)
                ret nz
                xor a
                ld (ix+zTrackPitchEnvelopeCursor),a
                ld (ix+zTrackPitchEnvelopeValue),a
                ld a,(ix+zTrackNoteFillReload)
                ld (ix+zTrackNoteFillCounter),a
                ld (ix+zTrackPSGEnvelopeCursor),a
                ret

zScaleDuration:
                ld b,(ix+zTrackDurationScale)
                dec b
                ret z
                ld c,a

zLoc_02A4:
                add a,c
                djnz zLoc_02A4
                ret

zUpdateModulation:
                ld a,(ix+zTrackModulationDelay)
                dec a
                ret m
                jr nz,zLoc_02EA
                bit 1,(ix+zTrackFlags)
                ret nz

zLoc_02B4:
                dec (ix+zTrackModulationSpeedCounter)
                ret nz
                exx
                ld a,(ix+zTrackModulationSpeedReload)
                ld (ix+zTrackModulationSpeedCounter),a
                ld a,(ix+zTrackModulationSpeed)
                ld hl,zModulationStepTable
                rst zGetWordTableEntry
                ld e,(ix+zTrackModulationStep)
                inc (ix+zTrackModulationStep)
                ld a,(ix+zTrackModulationSteps)
                dec a
                cp e
                jr nz,zLoc_02E1
                dec (ix+zTrackModulationStep)
                ld a,(ix+zTrackModulationDelay)
                cp 2
                jr z,zLoc_02E1
                ld (ix+zTrackModulationStep),0

zLoc_02E1:
                ld d,0
                add hl,de
                ex de,hl
                call zSetAMSAndFMS
                exx
                ret

zLoc_02EA:
                xor a
                ld (ix+zTrackModulationStep),a

zLoc_02EE:
                ld a,(ix+zTrackModulationDelay)
                sub 2
                ret m
                jr zLoc_02B4

zModulationStepTable:
                dw      2FEh, 2FFh, 300h, 301h
                dw      80C0h, 40C0h, 0C080h

zTickTrackDuration:
                ld a,(ix+zTrackDuration)
                dec a
                ld (ix+zTrackDuration),a
                ret

zUpdateFMVolumeEnvelope:
                ld a,(ix+zTrackFMEnvelope)
                or a
                ret z
                dec a
                ld c,10
                rst zGetLoadedDataTable
                rst zGetWordTableEntry
                call zReadPSGEnvelope
                ld h,(ix+1Dh)
                ld l,(ix+zTrackFMLevels)
                ld de,zFMVoiceLevelRegisterOrder
                ld b,4
                ld c,(ix+zTrackFMEnvelopeMask)

zLoc_0327:
                push af
                sra c
                push bc
                jr nc,zLoc_0333
                add a,(hl)
                and 7Fh
                ld c,a
                ld a,(de)
                rst zWriteFMChannel

zLoc_0333:
                pop bc
                inc de
                inc hl
                pop af
                djnz zLoc_0327
                ret

zUpdatePitchEnvelope:
                bit 7,(ix+zTrackPitchEnvelope)
                ret z
                bit 1,(ix+zTrackFlags)
                ret nz
                ld e,(ix+zTrackPitchEnvelopeData)
                ld d,(ix+21h)
                push ix
                pop hl
                ld b,0
                ld c,24h
                add hl,bc
                ex de,hl
                ldi
                ldi
                ldi
                ld a,(hl)
                srl a
                ld (de),a
                xor a
                ld (ix+zTrackPitchEnvelopeValue),a
                ld (ix+23h),a
                ret

zUpdatePitchSlide:
                ld a,(ix+zTrackPitchEnvelope)
                or a
                ret z
                cp 80h
                jr nz,zLoc_03B6
                dec (ix+zTrackPitchEnvelopeDelay)
                ret nz
                inc (ix+zTrackPitchEnvelopeDelay)
                push hl
                ld l,(ix+zTrackPitchEnvelopeValue)
                ld h,(ix+23h)
                dec (ix+zTrackPitchEnvelopeCursor)
                jr nz,zLoc_03A1
                ld e,(ix+zTrackPitchEnvelopeData)
                ld d,(ix+21h)
                push de
                pop iy
                ld a,(iy+1)
                ld (ix+zTrackPitchEnvelopeCursor),a
                ld a,(ix+zTrackPitchEnvelopeStep)
                ld c,a
                and 80h
                rlca
                neg
                ld b,a
                add hl,bc
                ld (ix+zTrackPitchEnvelopeValue),l
                ld (ix+23h),h

zLoc_03A1:
                pop bc
                add hl,bc
                dec (ix+zTrackPitchEnvelopeStepCounter)
                ret nz
                ld a,(iy+3)
                ld (ix+zTrackPitchEnvelopeStepCounter),a
                ld a,(ix+zTrackPitchEnvelopeStep)
                neg
                ld (ix+zTrackPitchEnvelopeStep),a
                ret

zLoc_03B6:
                dec a
                ex de,hl
                ld c,8
                ld b,80h
                call zResolveSoundPointer
                jr zLoc_03C4

zLoc_03C1:
                ld (ix+zTrackPitchEnvelopeCursor),a

zLoc_03C4:
                push hl
                ld c,(ix+zTrackPitchEnvelopeCursor)
                call zReadByteTableEntry
                pop hl
                bit 7,a
                jp z,zLoc_03FE
                cp 82h
                jr z,zLoc_03E7
                cp 80h
                jr z,zLoc_03EB
                cp 84h
                jr z,zLoc_03EE
                ld h,0FFh
                jr nc,zLoc_0400
                set 6,(ix+zTrackFlags)
                pop hl
                ret

zLoc_03E7:
                inc bc
                ld a,(bc)
                jr zLoc_03C1

zLoc_03EB:
                xor a
                jr zLoc_03C1

zLoc_03EE:
                inc bc
                ld a,(bc)
                add a,(ix+zTrackPitchEnvelopeValue)
                ld (ix+zTrackPitchEnvelopeValue),a
                inc (ix+zTrackPitchEnvelopeCursor)
                inc (ix+zTrackPitchEnvelopeCursor)
                jr zLoc_03C4

zLoc_03FE:
                ld h,0

zLoc_0400:
                ld l,a
                ld b,(ix+zTrackPitchEnvelopeValue)
                inc b
                ex de,hl

zLoc_0406:
                add hl,de
                djnz zLoc_0406
                inc (ix+zTrackPitchEnvelopeCursor)
                ret

zSendFMKeyOff:
                ld a,(ix+zTrackFrequency)
                or (ix+0Eh)
                ret z
                ld a,(ix+zTrackFlags)
                and 6
                ret nz
                ld a,(ix+zTrackChannel)
                or 0F0h
                ld c,a
                ld a,zGetWordTableEntry
                rst zWriteFMPort0
                ret

zKeyOffTrack:
                ld a,(ix+zTrackFlags)
                and 6
                ret nz

zLoc_042A:
                ld c,(ix+zTrackChannel)
                bit 7,c
                ret nz

zLoc_0430:
                ld a,zGetWordTableEntry
                rst zWriteFMPort0
                ret

zCalculateTrackFrequency:
                ld b,0
                ld a,(ix+zTrackFrequencyOffset)
                or a
                jp p,zLoc_043E
                dec b

zLoc_043E:
                ld h,(ix+0Eh)
                ld l,(ix+zTrackFrequency)
                ld c,a
                add hl,bc
                bit 7,(ix+zTrackChannel)
                jr nz,zLoc_046E
                ex de,hl
                ld a,7
                and d
                ld b,a
                ld c,e
                or a
                ld hl,283h
                sbc hl,bc
                jr c,zLoc_0460
                ld hl,0FA85h
                add hl,de
                jr zLoc_046E

zLoc_0460:
                or a
                ld hl,508h
                sbc hl,bc
                jr nc,zLoc_046D
                ld hl,57Ch
                add hl,de
                ex de,hl

zLoc_046D:
                ex de,hl

zLoc_046E:
                bit 5,(ix+zTrackFlags)
                ret z
                ld (ix+0Eh),h
                ld (ix+zTrackFrequency),l
                ret

zReadPointerTableEntry:
                ld b,0
                add hl,bc
                ex af,af'
                rst zReadPointer
                ex af,af'
                ret

zReadByteTableEntry:
                ld b,0
                add hl,bc
                ld c,l
                ld b,h
                ld a,(bc)
                ret

zGetFMVoice:
                ld hl,(zMusicVoiceTable)
                ld a,(zTrackContext)
                or a
                jr z,zLoc_0497
                ld l,(ix+zTrackVoiceTable)
                ld h,(ix+2Bh)

zLoc_0497:
                xor a
                or b
                jr z,zLoc_04A1
                ld de,19h

zLoc_049E:
                add hl,de
                djnz zLoc_049E

zLoc_04A1:
                ret

zWriteFMRegister:
                bit 2,(ix+zTrackChannel)
                jr nz,zWriteFMRegisterPort1
                bit 2,(ix+zTrackFlags)
                ret nz
                add a,(ix+zTrackChannel)
                rst zWriteFMPort0
                ret

zWriteFMPort0Data:
                ld (zYM2612_D0),a
                ret

zWriteFMRegisterPort1:
                bit 2,(ix+zTrackFlags)
                ret nz
                add a,(ix+zTrackChannel)
                sub 4

zWriteFMPort1:
                ld (zYM2612_A1),a
                rst 8
                ld a,c
                ld (zYM2612_D1),a
                ret

zFMVoiceRegisterOrder:
                db      0B0h, 30h, 38h, 34h, 3Ch, 50h, 58h, 54h, 5Ch, 60h, 68h, 64h
                db      6Ch, 70h, 78h, 74h, 7Ch, 80h, 88h, 84h, 8Ch

zFMVoiceLevelRegisterOrder:
                db      40h, 48h, 44h, 4Ch

zFMVoiceAlgorithmRegisterOrder:
                db      90h, 98h, 94h, 9Ch

; Copy a 25-byte FM voice to YM2612 in the chip's operator order.
zLoadFMVoice:
                ld de,zFMVoiceRegisterOrder
                ld c,(ix+zTrackVoiceControl)
                ld a,0B4h
                rst zWriteFMChannel
                call zWriteFMVoiceRegister
                ld (ix+zTrackFMAlgorithm),a
                ld b,14h

zLoc_04F7:
                call zWriteFMVoiceRegister
                djnz zLoc_04F7
                ld (ix+zTrackFMLevels),l
                ld (ix+1Dh),h
                jp zSendFMFrequency

zWriteFMVoiceRegister:
                ld a,(de)
                inc de
                ld c,(hl)
                inc hl
                rst zWriteFMChannel
                ret

; Dispatch the 68k command byte: 81h-8Fh music, 90h-CFh SFX,
; D0h-DFh special SFX, and E0h-F8h global commands.
