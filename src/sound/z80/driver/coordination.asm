; Dispatch a per-track coordination flag. The handler returns through
; zCoordFlagReturn, which resumes event parsing.
zDispatchCoordFlag:
                ld hl,zCoordFlagReturn

zDispatchCoordFlagFromTable:
                push hl
                sub 0E0h
                ld hl,zCoordFlagTable
                rst zGetWordTableEntry
                ld a,(de)
                jp (hl)

zCoordFlagReturn:
                inc de
                jp zLoc_01E4

zDispatchFMOperatorFlag:
                ld hl,zFMOperatorFlagTable
                rst zGetWordTableEntry
                inc de
                ld a,(de)
                jp (hl)

; E0h-FFh per-track coordination-flag handler table.
zCoordFlagTable:
                dw      zSetAMSAndFMS, zSetFrequencyOffset, zSetCoordFlagValue, zStopTrackCommand
                dw      zSetupModulation, zAddFrequency, zLoc_0DCA, zSetHold
                dw      zSetNoteFill, zSetLFO, zSetROMBankCommand, zAddROMBankCommand
                dw      zAdjustPSGVolume, zWriteFMChannelCommand, zWriteFMPort0Command, zSetVoice
                dw      zSetPitchEnvelope, zSetPitchSlide, zStopTrack, zSetPSGNoise
                dw      zLoc_0E12, zSetPSGVolumeEnvelope, zSequenceReturn, zSequenceLoop
                dw      zSequenceCall, zSequenceReturnFromCall, zSetDurationMultiplier, zAddTranspose
                dw      zSetRawFrequencyMode, zSetPitchMode, zSetFM3SpecialMode, zDispatchFMOperatorFlag

zFMOperatorFlagTable:
                dw      zSetUpdateFlag, zAddTempo, zProcessNestedSoundCommand, zSetChannelOverride
                dw      zCopyCommandData, zSetAllTrackTempoDividers, zFMOperatorSpecialMode, zSetFMEnvelope

zFMOperatorSpecialMode:
                ld (ix+zTrackFMEnvelope),80h
                ld (ix+zTrackFMEnvelopeMask),e
                ld (ix+zTrackPSGNoise),d

zLoc_0C09:
                ld hl,zFMVoiceAlgorithmRegisterOrder
                ld b,4

zLoc_0C0E:
                ld a,(de)
                inc de
                ld c,a
                ld a,(hl)
                inc hl
                rst zWriteFMChannel
                djnz zLoc_0C0E
                dec de
                ret

zSetAllTrackTempoDividers:
                exx
                ld b,10
                ld de,zReadPointer
                ld hl,zMusicTrackTempoDivider

zLoc_0C21:
                ld (hl),a
                add hl,de
                djnz zLoc_0C21
                exx
                ret

zSetUpdateFlag:
                ld (zUpdatePending),a
                ret

zSetROMBankCommand:
                ld hl,zTimerAValue
                ex de,hl
                ldi
                ldi
                ldi
                ex de,hl
                dec de
                ret

zAddROMBankCommand:
                ex de,hl
                ld c,(hl)
                inc hl
                ld b,(hl)
                inc hl
                ex de,hl
                ld hl,(zTimerAValue)
                add hl,bc
                ld (zTimerAValue),hl
                ld a,(de)
                ld hl,zTimerBValue
                add a,(hl)
                ld (hl),a
                ret

zProcessNestedSoundCommand:
                push ix
                call zLoc_050E
                pop ix
                ret

zSetChannelOverride:
                ld (zChannelOverride),a
                or a
                jr z,zLoc_0C77
                push ix
                push de
                ld ix,zMusicFMTrack0
                ld b,10
                ld de,zReadPointer

zLoc_0C66:
                res 7,(ix+zTrackFlags)
                call zLoc_042A
                add ix,de
                djnz zLoc_0C66
                pop de
                pop ix
                jp zSilencePSG

zLoc_0C77:
                push ix
                push de
                ld ix,zMusicFMTrack0
                ld b,10
                ld de,zReadPointer

zLoc_0C83:
                set 7,(ix+zTrackFlags)
                add ix,de
                djnz zLoc_0C83
                pop de
                pop ix
                ret

zCopyCommandData:
                ex de,hl
                ld e,(hl)
                inc hl
                ld d,(hl)
                inc hl
                ld c,(hl)
                ld b,0
                inc hl
                ex de,hl
                ldir
                dec de
                ret

zSetFrequencyOffset:
                ld (ix+zTrackFrequencyOffset),a
                ret

zSetFMEnvelope:
                ld (ix+zTrackFMEnvelope),a
                inc de
                ld a,(de)
                ld (ix+zTrackFMEnvelopeMask),a
                ret

zAddTempo:
                ld hl,zTempoReload
                add a,(hl)
                ld (hl),a
                dec hl
                ld (hl),a
                ret

zSetCoordFlagValue:
                ld (zCoordFlagValue),a
                ret

zAdjustPSGVolume:
                bit 7,(ix+zTrackChannel)
                ret z
                res 4,(ix+zTrackFlags)
                dec (ix+zTrackPSGEnvelopeCursor)
                add a,(ix+zTrackVolume)
                ld (ix+zTrackVolume),a
                ret

zWriteFMChannelCommand:
                call zReadCommandWord
                rst zWriteFMChannel
                ret

zWriteFMPort0Command:
                call zReadCommandWord
                rst zWriteFMPort0
                ret

zReadCommandWord:
                ex de,hl
                ld a,(hl)
                inc hl
                ld c,(hl)
                ex de,hl
                ret

zSetPitchEnvelope:
                ld (ix+zTrackPitchEnvelopeData),e
                ld (ix+21h),d
                ld (ix+zTrackPitchEnvelope),80h
                inc de
                inc de
                inc de
                ret

zStopTrackCommand:
                call zSilenceFMChannel
                jp zStopTrack

zSetNoteFill:
                call zScaleDuration
                ld (ix+zTrackNoteFillCounter),a
                ld (ix+zTrackNoteFillReload),a
                ret

zSetupModulation:
                push ix
                pop hl
                ld bc,11h
                add hl,bc
                ex de,hl
                ld bc,5
                ldir
                ld a,1
                ld (de),a
                ex de,hl
                dec de
                ret

zSetHold:
                set 1,(ix+zTrackFlags)
                dec de
                ret

zSetFM3SpecialMode:
                ld a,(ix+zTrackChannel)
                cp 2
                jr nz,zLoc_0D41
                set 0,(ix+zTrackFlags)
                exx
                call zSelectFMOperatorState
                ld b,4

zLoc_0D21:
                push bc
                exx
                ld a,(de)
                inc de
                exx
                ld hl,zFM3FrequencyOffsets
                add a,a
                ld c,a
                ld b,0
                add hl,bc
                ldi
                ldi
                pop bc
                djnz zLoc_0D21
                exx
                dec de
                ld a,4Fh

zLoc_0D39:
                ld (zFM3Mode),a
                ld c,a
                ld a,27h
                rst zWriteFMPort0
                ret

zLoc_0D41:
                inc de
                inc de
                inc de
                ret

zFM3FrequencyOffsets:
                dw      0, 132h, 18Ah, 1E4h

; Select an FM voice, load its 25 register bytes, and remember any
; per-voice envelope selector that follows the voice number.
zSetVoice:
                bit 7,(ix+zTrackChannel)
                jr nz,zLoc_0D84
                call zResetFMOperators
                ld a,(de)
                ld (ix+zTrackVolumeEnvelope),a
                or a
                jp p,zLoc_0D7A
                inc de
                ld a,(de)
                ld (ix+zTrackVoiceIndex),a

zLoc_0D63:
                push de
                ld a,(ix+zTrackVoiceIndex)
                sub 81h
                ld c,4
                call zLoc_05EB
                rst zReadPointer
                ld a,(ix+zTrackVolumeEnvelope)
                and 7Fh
                ld b,a
                call zLoc_0497
                jr zLoc_0D7F

zLoc_0D7A:
                push de
                ld b,a
                call zGetFMVoice

zLoc_0D7F:
                call zLoadFMVoice
                pop de
                ret

zLoc_0D84:
                ld a,(de)
                or a
                ret p
                inc de
                ret

zSetAMSAndFMS:
                ld c,3Fh

zLoc_0D8B:
                ld a,(ix+zTrackVoiceControl)
                and c
                ex de,hl
                or (hl)
                ld (ix+zTrackVoiceControl),a
                ld c,a
                ld a,0B4h
                rst zWriteFMChannel
                ex de,hl
                ret

zSetLFO:
                ld c,a
                ld a,22h
                rst zWriteFMPort0
                inc de
                ld c,0C0h
                jr zLoc_0D8B

; Write the current frequency to A4h/A0h (or all four FM3 operators).
zSendFMFrequency:
                exx
                ld de,zFMVoiceLevelRegisterOrder
                ld l,(ix+zTrackFMLevels)
                ld h,(ix+1Dh)
                ld b,4

zLoc_0DAF:
                ld a,(hl)
                or a
                jp p,zLoc_0DB7
                add a,(ix+zTrackVolume)

zLoc_0DB7:
                and 7Fh
                ld c,a
                ld a,(de)
                rst zWriteFMChannel
                inc de
                inc hl
                djnz zLoc_0DAF
                exx
                ret

zAddFrequency:
                inc de
                add a,(ix+zTrackVolume)
                ld (ix+zTrackVolume),a
                ld a,(de)

zLoc_0DCA:
                bit 7,(ix+zTrackChannel)
                ret nz
                add a,(ix+zTrackVolume)
                ld (ix+zTrackVolume),a
                jr zSendFMFrequency

zAddTranspose:
                add a,(ix+zTrackTranspose)
                ld (ix+zTrackTranspose),a
                ret

zSetDurationMultiplier:
                ld (ix+zTrackDurationScale),a
                ret

zSetPSGNoise:
                bit 2,(ix+zTrackChannel)
                ret nz
                ld a,0DFh
                ld (zPSG),a
                ld a,(de)
                ld (ix+zTrackPSGNoise),a
                set 0,(ix+zTrackFlags)
                or a
                jr nz,zLoc_0DFD
                res 0,(ix+zTrackFlags)
                ld a,0FFh

zLoc_0DFD:
                ld (zPSG),a
                ret

zSetPSGVolumeEnvelope:
                bit 7,(ix+zTrackChannel)
                ret z
                ld (ix+zTrackVolumeEnvelope),a
                ret
