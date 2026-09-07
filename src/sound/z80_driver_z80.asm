; Flicky Z80 sound driver
; Reconstructed from ROM $001316-$0022FB (Z80 $0000-$0FE5).
;
; Unlike Sonic 1, Flicky runs the complete FM/PSG sequencer on the Z80. The
; 68000 only loads this image and the data banks, then writes command bytes at
; $1C09-$1C0C. Code and tables below assemble byte-for-byte to the original
; 4,070-byte image; build_z80_driver.py enforces that invariant.

                cpu     z80
                page    0
                org     0

; Hardware ports and the resident RAM ABI shared with the 68000.
zROMBankLow:                 equ     1C00h
zROMBankHigh:                equ     1C01h
zLoadedDataTable:            equ     1C02h
zTimerAValue:                equ     1C04h
zTimerBValue:                equ     1C06h
zUpdatePending:              equ     1C07h
zLoadedSFXCount:             equ     1C08h
zMusicCommand:               equ     1C09h
zSFXCommand0:                equ     1C0Ah
zSFXCommand1:                equ     1C0Bh
zSFXCommand2:                equ     1C0Ch
zFadeSteps:                  equ     1C0Dh
zFadeDelay:                  equ     1C0Eh
zFadeCounter:                equ     1C0Fh
zPauseFlag:                  equ     1C10h
zChannelOverride:            equ     1C11h
zFM3Mode:                    equ     1C12h
zTempoCounter:               equ     1C13h
zTempoReload:                equ     1C14h
zCurrentPriority:            equ     1C15h
zCoordFlagValue:             equ     1C16h
zRandomValue:                equ     1C17h
zCurrentSFXPriority:         equ     1C18h
zTrackContext:               equ     1C19h
zFM3OperatorFrequency0:      equ     1C1Ah
zFM3OperatorFrequency1:      equ     1C22h
zFM3OperatorFrequency2:      equ     1C2Ah
zCurrentTrackIndex:          equ     1C32h
zTrackHeaderCursor:          equ     1C33h
zTrackInitCursor:            equ     1C35h
zMusicVoiceTable:            equ     1C37h
zSFXVoiceTable:              equ     1C39h
zSFXTempoDivider:            equ     1C3Bh
zMusicFMTrack0:              equ     1C40h
zMusicTrackTempoDivider:     equ     1C42h
zMusicFMTrack0Duration:      equ     1C4Bh
zMusicFMTrack1:              equ     1C70h
zMusicFMTrack4:              equ     1D00h
zMusicFMTrack5:              equ     1D30h
zDACTrack:                   equ     1D60h
zDACTranspose:               equ     1D65h
zDACVolume:                  equ     1D66h
zDACVolumeEnvelope:          equ     1D68h
zMusicPSGTrack0:             equ     1D90h
zMusicPSGTrack1:             equ     1DC0h
zMusicPSGTrack2:             equ     1DF0h
zSpecialSFXTrack0:           equ     1E20h
zSpecialSFXTrack1:           equ     1E50h
zSFXTrack0:                  equ     1E80h
zSFXTrack1:                  equ     1EB0h
zSFXTrack2:                  equ     1EE0h
zSFXTrack3:                  equ     1F10h
zSFXTrack4:                  equ     1F40h
zSFXTrack5:                  equ     1F70h
zStack:                      equ     1FFDh
zInterruptCountdown:         equ     1FFFh
zYM2612_A0:                  equ     4000h
zYM2612_D0:                  equ     4001h
zYM2612_A1:                  equ     4002h
zYM2612_D1:                  equ     4003h
zBankRegister:               equ     6000h
zPSG:                        equ     7F11h
zROMWindow:                  equ     8000h

zTrackSize:                 equ     30h
zCoordFlagFirst:            equ     0E0h

; One channel occupies 30h bytes. Names below are the fields established
; by all reads/writes in the driver; the final eight bytes are reused as
; loop counters, the sequence-call stack, and an SFX voice-table pointer.
zTrackFlags:                 equ     0
zTrackChannel:               equ     1
zTrackDurationScale:         equ     2
zTrackData:                  equ     3
zTrackTranspose:             equ     5
zTrackVolume:                equ     6
zTrackPitchEnvelope:         equ     7
zTrackVolumeEnvelope:        equ     8
zTrackStackPointer:          equ     9
zTrackVoiceControl:          equ     0Ah
zTrackDuration:              equ     0Bh
zTrackSavedDuration:         equ     0Ch
zTrackFrequency:             equ     0Dh
zTrackVoiceIndex:            equ     0Fh
zTrackFrequencyOffset:       equ     10h
zTrackModulationDelay:       equ     11h
zTrackModulationSpeed:       equ     12h
zTrackModulationStep:        equ     13h
zTrackModulationSteps:       equ     14h
zTrackModulationSpeedReload: equ     15h
zTrackModulationSpeedCounter: equ     16h
zTrackPSGEnvelopeCursor:     equ     17h
zTrackFMEnvelope:            equ     18h
zTrackFMEnvelopeMask:        equ     19h
zTrackPSGNoise:              equ     1Ah
zTrackFMAlgorithm:           equ     1Bh
zTrackFMLevels:              equ     1Ch
zTrackNoteFillCounter:       equ     1Eh
zTrackNoteFillReload:        equ     1Fh
zTrackPitchEnvelopeData:     equ     20h
zTrackPitchEnvelopeValue:    equ     22h
zTrackPitchEnvelopeDelay:    equ     24h
zTrackPitchEnvelopeCursor:   equ     25h
zTrackPitchEnvelopeStep:     equ     26h
zTrackPitchEnvelopeStepCounter: equ     27h
zTrackLoopCounters:          equ     28h
zTrackVoiceTable:            equ     2Ah


; Reset vector. The driver uses IM 1 and executes one update every
; three timer interrupts.
zDriverStart:
                di
                di
                im 1
                jr zDriverMain

zLoc_0006:
                db      0, 0

zWaitForYM2612:
                ld a,(zYM2612_A0)
                bit 7,a
                jr nz,zWaitForYM2612
                ret

zWriteFMChannel:
                bit 7,(ix+zTrackChannel)
                ret nz
                jp zWriteFMRegister

zWriteFMPort0:
                ld (zYM2612_A0),a
                rst 8
                ld a,c
                jp zWriteFMPort0Data

zGetLoadedDataTable:
                ld hl,(zLoadedDataTable)
                jp zReadPointerTableEntry

zLoc_0026:
                db      0, 0

zGetWordTableEntry:
                ld c,a
                ld b,0
                add hl,bc
                add hl,bc
                nop
                nop
                nop

zReadPointer:
                ld a,(hl)
                inc hl
                ld h,(hl)
                ld l,a
                ret

zLoc_0035:
                db      0, 0, 0

; IM 1 interrupt handler. It only schedules the next sequencer tick;
; all chip writes happen in the main loop.
zTimerInterrupt:
                push af
                push bc
                push de
                push hl
                ld hl,zInterruptCountdown
                ld a,(hl)
                or a
                jr z,zLoc_0046
                dec (hl)
                jr zLoc_004D

zLoc_0046:
                ld a,(zUpdatePending)
                or a
                call z,zUpdateSound

zLoc_004D:
                pop hl
                pop de
                pop bc
                pop af
                ei
                ret

zDriverMain:
                ld sp,zStack
                ld a,3
                ld (zInterruptCountdown),a

zLoc_005B:
                ei
                ld a,(zInterruptCountdown)
                or a
                jp nz,zLoc_005B
                call zResetSoundDriver
                call zSetROMBank
                call zProgramTimerA
                call zProgramTimerB

zLoc_006F:
                ei
                call zPollSFXCommands
                ld a,(zUpdatePending)
                or a
                jr z,zLoc_006F
                di
                jp p,zLoc_00AA
                call zPollSFXCommands
                ld a,(zYM2612_A0)
                and 3
                jr z,zLoc_006F
                bit 1,a
                jr z,zLoc_009B
                call zProgramTimerB
                ld hl,zLoc_009B
                push hl
                call zProcessPause
                call zProcessSoundCommand
                jp zUpdateSFXTracks

zLoc_009B:
                ld a,(zYM2612_A0)
                bit 0,a
                jr z,zLoc_006F
                call zProgramTimerA
                call zUpdateSound
                jr zLoc_006F

zLoc_00AA:
                ld a,(zYM2612_A0)
                bit 1,a
                jr z,zLoc_006F
                call zProgramTimerB
                call zUpdateSound
                jr zLoc_006F

zProgramTimerA:
                ld hl,(zTimerAValue)
                ld a,l
                and 3
                ld c,a
                ld a,25h
                rst zWriteFMPort0
                srl h
                rr l
                srl h
                rr l
                ld c,l
                ld a,24h
                rst zWriteFMPort0
                ld a,1Fh
                jr zLoc_00DC

zProgramTimerB:
                ld a,(zTimerBValue)
                ld c,a
                ld a,26h
                rst zWriteFMPort0
                ld a,2Fh

zLoc_00DC:
                ld hl,zFM3Mode
                or (hl)
                ld c,a
                ld a,27h
                rst zWriteFMPort0
                ret

; Update music, normal SFX, special SFX and the DAC track once.
zUpdateSound:
                call zProcessPause
                call zUpdateTempo
                call zUpdateFadeOut
                call zProcessSoundCommand
                ld a,(zUpdatePending)
                or a
                call p,zUpdateSFXTracks
                xor a
                ld (zTrackContext),a
                ld ix,zMusicFMTrack0
                bit 7,(ix+zTrackFlags)
                call nz,zUpdateDACTrack
                ld b,9
                ld ix,zMusicFMTrack1
                jr zUpdateTrackLoop

zUpdateSFXTracks:
                ld a,1
                ld (zTrackContext),a
                ld ix,zSFXTrack0
                ld b,6
                call zUpdateTrackLoop
                ld a,80h
                ld (zTrackContext),a
                ld b,2
                ld ix,zSpecialSFXTrack0

zUpdateTrackLoop:
                push bc
                bit 7,(ix+zTrackFlags)
                call nz,zUpdateFMTrack
                ld de,zReadPointer
                add ix,de
                pop bc
                djnz zUpdateTrackLoop
                ret

; Update one FM track. IX points at a 30h-byte track structure.
zUpdateFMTrack:
                bit 7,(ix+zTrackChannel)
                jp nz,zUpdatePSGTrack
                call zTickTrackDuration
                jr nz,zLoc_015C
                call zReadFMEvent
                bit 4,(ix+zTrackFlags)
                ret nz
                call zUpdatePitchEnvelope
                call zCalculateTrackFrequency
                call zUpdatePitchSlide
                call zWriteFMFrequency
                jp zSendFMKeyOff

zLoc_015C:
                call zLoc_02EE
                bit 4,(ix+zTrackFlags)
                ret nz
                call zUpdateFMVolumeEnvelope
                ld a,(ix+zTrackNoteFillCounter)
                or a
                jr z,zLoc_0173
                dec (ix+zTrackNoteFillCounter)
                jp z,zLoc_042A

zLoc_0173:
                call zCalculateTrackFrequency
                bit 6,(ix+zTrackFlags)
                ret nz
                call zUpdatePitchSlide

zWriteFMFrequency:
                bit 2,(ix+zTrackFlags)
                ret nz
                bit 0,(ix+zTrackFlags)
                jp nz,zLoc_0193

zLoc_018A:
                ld a,0A4h
                ld c,h
                rst zWriteFMChannel
                ld a,0A0h
                ld c,l
                rst zWriteFMChannel
                ret

zLoc_0193:
                ld a,(ix+zTrackChannel)
                cp 2
                jr nz,zLoc_018A
                call zSelectFMOperatorState
                exx
                ld hl,zFM3RegisterOrder
                ld b,4

zLoc_01A3:
                ld a,(hl)
                push af
                inc hl
                exx
                ex de,hl
                ld c,(hl)
                inc hl
                ld b,(hl)
                inc hl
                ex de,hl
                ld l,(ix+zTrackFrequency)
                ld h,(ix+0Eh)
                add hl,bc
                pop af
                push af
                ld c,h
                rst zWriteFMPort0
                pop af
                sub 4
                ld c,l
                rst zWriteFMPort0
                exx
                djnz zLoc_01A3
                exx
                ret

zFM3RegisterOrder:
                db      0ADh, 0AEh, 0ACh, 0A6h

zSelectFMOperatorState:
                ld de,zFM3OperatorFrequency2
                ld a,(zTrackContext)
                or a
                ret z
                ld de,zFM3OperatorFrequency0
                ret p
                ld de,zFM3OperatorFrequency1
                ret

; Consume coordination flags (E0h-FFh), then decode the next note and
; duration from the track's sequence pointer.
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
zProcessSoundCommand:
                ld a,(zMusicCommand)

zLoc_050E:
                bit 7,a
                jp z,zResetSoundDriver
                cp 90h
                jp c,zStartMusic
                cp 0D0h
                jp c,zStartSFX
                cp 0E0h
                jp c,zStartSpecialSFX
                cp 0F9h
                jp nc,zResetSoundDriver
                sub 0E0h
                ld hl,zSoundCommandTable
                rst zGetWordTableEntry
                jp (hl)

zSoundCommandTable:
                dw      zBeginFadeOut, zResetSoundDriver, zSilencePSG, zStopSpecialSFX

zStopSpecialSFX:
                ld ix,zSpecialSFXTrack0
                ld b,2
                ld a,80h
                ld (zTrackContext),a

zLoc_0541:
                push bc
                bit 7,(ix+zTrackFlags)
                call nz,zStopSpecialSFXTrack
                ld de,zReadPointer
                add ix,de
                pop bc
                djnz zLoc_0541
                ret

zStopSpecialSFXTrack:
                push hl
                push hl
                jp zStopTrack

; Resolve a music header, initialise its FM and PSG tracks, and load
; the voice-table pointer. The header format is documented in sound_data.s.
zStartMusic:
                sub 81h
                ret m
                push af
                call zResetSoundDriver
                pop af
                ld c,4
                ld b,8
                call zResolveSoundPointer
                push hl
                push hl
                rst zReadPointer
                ld (zMusicVoiceTable),hl
                pop hl
                pop iy
                ld a,(iy+5)
                ld (zTempoCounter),a
                ld (zTempoReload),a
                ld de,6
                add hl,de
                ld (zTrackHeaderCursor),hl
                ld hl,zFMTrackInit
                ld (zTrackInitCursor),hl
                ld de,zMusicFMTrack0
                ld b,(iy+2)
                ld a,(iy+4)

zLoc_058E:
                push bc
                ld hl,(zTrackInitCursor)
                ldi
                ldi
                ld (de),a
                inc de
                ld (zTrackInitCursor),hl
                ld hl,(zTrackHeaderCursor)
                ldi
                ldi
                ldi
                ldi
                ld (zTrackHeaderCursor),hl
                call zClearTrackHeaderTail
                pop bc
                djnz zLoc_058E
                ld a,(iy+3)
                or a
                jp z,zLoc_05E1
                ld b,a
                ld hl,zPSGTrackInit
                ld (zTrackInitCursor),hl
                ld de,zMusicPSGTrack0
                ld a,(iy+4)

zLoc_05C3:
                push bc
                ld hl,(zTrackInitCursor)
                ldi
                ldi
                ld (de),a
                inc de
                ld (zTrackInitCursor),hl
                ld hl,(zTrackHeaderCursor)
                ld bc,6
                ldir
                ld (zTrackHeaderCursor),hl
                call zClearTrackState
                pop bc
                djnz zLoc_05C3

zLoc_05E1:
                ld a,80h
                ld (zMusicCommand),a
                ret

zResolveSoundPointer:
                cp b
                jr c,zLoc_05F3
                sub b

zLoc_05EB:
                ld hl,zROMWindow
                call zReadPointerTableEntry
                jr zLoc_05F4

zLoc_05F3:
                rst zGetLoadedDataTable

zLoc_05F4:
                rst zGetWordTableEntry
                ret

zFMTrackInit:
                db      80h, 2, 80h, 0, 80h, 1, 80h, 4, 80h, 5, 80h, 6
                db      80h, 2

zPSGTrackInit:
                db      80h, 80h, 80h, 0A0h, 80h, 0C0h

zStartSpecialSFX:
                sub 0D0h
                push af
                ld c,2
                rst zGetLoadedDataTable
                rst zGetWordTableEntry
                ld a,80h
                jr zLoc_0622

; Start one ordinary SFX, selecting an idle/replaceable hardware track.
zStartSFX:
                sub 90h
                push af
                ld c,6
                ld hl,zLoadedSFXCount
                ld b,(hl)
                call zResolveSoundPointer
                xor a

zLoc_0622:
                ld (zTrackContext),a
                pop af
                push hl
                rst zReadPointer
                ld (zSFXVoiceTable),hl
                xor a
                ld (zCurrentPriority),a
                pop hl
                push hl
                pop iy
                ld a,(iy+2)
                ld (zSFXTempoDivider),a
                ld de,4
                add hl,de
                ld b,(iy+3)

zLoc_0640:
                push bc
                push hl
                inc hl
                ld c,(hl)
                call zFindSFXTrack
                set 2,(hl)
                push ix
                ld a,(zTrackContext)
                or a
                jr z,zLoc_0654
                pop hl
                push iy

zLoc_0654:
                pop de
                pop hl
                ldi
                ld a,(de)
                cp 2
                call z,zSilencePSGAndFM3
                ldi
                ld a,(zSFXTempoDivider)
                ld (de),a
                inc de
                ldi
                ldi
                ldi
                ldi
                call zClearTrackHeaderTail
                bit 7,(ix+zTrackFlags)
                jr z,zLoc_0682
                ld a,(ix+zTrackChannel)
                cp (iy+1)
                jr nz,zLoc_0682
                set 2,(iy)

zLoc_0682:
                push hl
                ld hl,(zSFXVoiceTable)
                ld a,(zTrackContext)
                or a
                jr z,zLoc_0690
                push iy
                pop ix

zLoc_0690:
                ld (ix+zTrackVoiceTable),l
                ld (ix+2Bh),h
                call zKeyOffTrack
                call zSetPSGVolumeOff
                pop hl
                pop bc
                djnz zLoc_0640
                jp zLoc_05E1

; Map the encoded channel byte to its music, SFX and restore-track slots.
zFindSFXTrack:
                bit 7,c
                jr nz,zLoc_06AC
                ld a,c
                sub 2
                jr zLoc_06C2

zLoc_06AC:
                ld a,1Fh
                call zSilencePSGTrack
                ld a,0FFh
                ld (zPSG),a
                ld a,c
                srl a
                srl a
                srl a
                srl a
                srl a
                inc a

zLoc_06C2:
                ld (zCurrentTrackIndex),a
                push af
                ld hl,zSFXDestinationTrackTable
                rst zGetWordTableEntry
                push hl
                pop ix
                pop af
                push af
                ld hl,zSFXSourceTrackTable
                rst zGetWordTableEntry
                push hl
                pop iy
                pop af
                ld hl,zSFXRestoreTrackTable
                rst zGetWordTableEntry
                ret

zClearTrackHeaderTail:
                ex af,af'
                xor a
                ld (de),a
                inc de
                ld (de),a
                inc de
                ex af,af'

zClearTrackState:
                ex de,hl
                ld (hl),zReadPointer
                inc hl
                ld (hl),0C0h
                inc hl
                ld (hl),1
                ld b,24h

zLoc_06EE:
                inc hl
                ld (hl),0
                djnz zLoc_06EE
                inc hl
                ex de,hl
                ret

zSFXSourceTrackTable:
                dw      zSpecialSFXTrack0, zSpecialSFXTrack0, zSpecialSFXTrack0, zSpecialSFXTrack0
                dw      zSpecialSFXTrack1, zSpecialSFXTrack0, zSpecialSFXTrack0, zSpecialSFXTrack1

zSFXDestinationTrackTable:
                dw      zSFXTrack0, zSFXTrack1, zSFXTrack1, zSFXTrack1
                dw      zSFXTrack2, zSFXTrack3, zSFXTrack4, zSFXTrack5

zSFXRestoreTrackTable:
                dw      zDACTrack, zMusicFMTrack4, zMusicFMTrack4, zMusicFMTrack4
                dw      zMusicFMTrack5, zMusicPSGTrack0, zMusicPSGTrack1, zMusicPSGTrack2

; Program the serial Mega Drive Z80 bank register from zROMBankLow/High.
zSetROMBank:
                ld a,(zROMBankHigh)
                rlca
                ld (zBankRegister),a
                ld b,8
                ld a,(zROMBankLow)

zLoc_0732:
                ld (zBankRegister),a
                rrca
                djnz zLoc_0732
                ret

zProcessPause:
                ld hl,zPauseFlag
                ld a,(hl)
                or a
                ret z
                jp m,zLoc_074A
                pop de
                dec a
                ret nz
                ld (hl),2
                jp zSilenceAllChannels

zLoc_074A:
                xor a
                ld (hl),a
                ld a,(zFadeSteps)
                or a
                jp nz,zResetSoundDriver
                ld ix,zMusicFMTrack1
                ld b,6

zLoc_0759:
                ld a,(zChannelOverride)
                or a
                jr nz,zLoc_0765
                bit 7,(ix+zTrackFlags)
                jr z,zLoc_076B

zLoc_0765:
                ld c,(ix+zTrackVoiceControl)
                ld a,0B4h
                rst zWriteFMChannel

zLoc_076B:
                ld de,zReadPointer
                add ix,de
                djnz zLoc_0759
                ld ix,zSpecialSFXTrack0
                ld b,8

zLoc_0778:
                bit 7,(ix+zTrackFlags)
                jr z,zLoc_078A
                bit 7,(ix+zTrackChannel)
                jr nz,zLoc_078A
                ld c,(ix+zTrackVoiceControl)
                ld a,0B4h
                rst zWriteFMChannel

zLoc_078A:
                ld de,zReadPointer
                add ix,de
                djnz zLoc_0778
                ret

zBeginFadeOut:
                ld a,zGetWordTableEntry
                ld (zFadeSteps),a
                ld a,6
                ld (zFadeCounter),a
                ld (zFadeDelay),a

zStopMusicForFade:
                xor a
                ld (zMusicFMTrack0),a
                ld (zDACTrack),a
                ld (zMusicPSGTrack2),a
                ld (zMusicPSGTrack0),a
                ld (zMusicPSGTrack1),a
                call zSilencePSG
                jp zLoc_05E1

zUpdateFadeOut:
                ld hl,zFadeSteps
                ld a,(hl)
                or a
                ret z
                call m,zStopMusicForFade
                res 7,(hl)
                ld a,(zFadeCounter)
                dec a
                jr z,zLoc_07CA
                ld (zFadeCounter),a
                ret

zLoc_07CA:
                ld a,(zFadeDelay)
                ld (zFadeCounter),a
                ld a,(zFadeSteps)
                dec a
                ld (zFadeSteps),a
                jr z,zResetSoundDriver
                ld ix,zMusicFMTrack0
                ld b,6

zLoc_07DF:
                inc (ix+zTrackVolume)
                jp p,zLoc_07EA
                dec (ix+zTrackVolume)
                jr zLoc_07F9

zLoc_07EA:
                bit 7,(ix+zTrackFlags)
                jr z,zLoc_07F9
                bit 2,(ix+zTrackFlags)
                jr nz,zLoc_07F9
                call zSendFMFrequency

zLoc_07F9:
                ld de,zReadPointer
                add ix,de
                djnz zLoc_07DF
                ret

; Clear driver state and silence every FM/PSG channel.
zResetSoundDriver:
                ld hl,zMusicCommand
                ld de,zSFXCommand0
                ld bc,396h
                ld (hl),0
                ldir
                ld ix,zFMTrackInit
                ld b,6

zLoc_0814:
                push bc
                call zSilenceFMChannel
                call zSetPSGVolumeOff
                inc ix
                inc ix
                pop bc
                djnz zLoc_0814
                ld b,7
                xor a
                ld (zFadeSteps),a
                call zSilencePSG

zSilencePSGAndFM3:
                ld a,15
                ld (zFM3Mode),a
                ld c,a
                ld a,27h
                rst zWriteFMPort0
                jp zLoc_05E1

zSetPSGVolumeOff:
                ld a,90h
                ld c,0
                jp zWriteFourFMOperators

zSilenceAllChannels:
                call zSilencePSG
                push bc
                push af
                ld b,3
                ld a,0B4h
                ld c,0

zLoc_0849:
                push af
                rst zWriteFMPort0
                pop af
                inc a
                djnz zLoc_0849
                ld b,3
                ld a,0B4h

zLoc_0853:
                push af
                call zWriteFMPort1
                pop af
                inc a
                djnz zLoc_0853
                ld c,0
                ld b,7
                ld a,zGetWordTableEntry

zLoc_0861:
                push af
                rst zWriteFMPort0
                inc c
                pop af
                djnz zLoc_0861
                pop af
                pop bc

zSilencePSG:
                push hl
                push bc
                ld hl,zPSGSilenceCommands
                ld b,4

zLoc_0870:
                ld a,(hl)
                ld (zPSG),a
                inc hl
                djnz zLoc_0870
                pop bc
                pop hl
                jp zLoc_05E1

zPSGSilenceCommands:
                db      9Fh, 0BFh, 0DFh, 0FFh

zUpdateTempo:
                ld hl,zTempoCounter
                ld a,(hl)
                or a
                ret z
                dec (hl)
                ret nz
                ld a,(zTempoReload)
                ld (hl),a
                ld hl,zMusicFMTrack0Duration
                ld de,zReadPointer
                ld b,10

zLoc_0894:
                inc (hl)
                add hl,de
                djnz zLoc_0894
                ret

; Arbitrate the three SFX command slots by the priority table.
zPollSFXCommands:
                ld a,r
                ld (zRandomValue),a
                ld de,zSFXCommand0
                call zPollOneSFXCommand
                ld de,zSFXCommand1
                call zPollOneSFXCommand
                ld de,zSFXCommand2

zPollOneSFXCommand:
                ld a,(de)
                bit 7,a
                ret z
                sub 81h
                ld hl,(zLoadedDataTable)
                ld c,0
                rst zGetLoadedDataTable
                ld c,a
                ld b,0
                add hl,bc
                bit 7,(hl)
                jr z,zLoc_08CF
                ld a,(de)
                ld (zMusicCommand),a
                xor a
                ld hl,zSFXCommand0
                ld (hl),a
                inc hl
                ld (hl),a
                inc hl
                ld (hl),a
                ret

zLoc_08CF:
                ld a,(zCurrentSFXPriority)
                cp (hl)
                jr z,zLoc_08D7
                jr nc,zLoc_08DF

zLoc_08D7:
                ld a,(de)
                ld (zMusicCommand),a
                ld a,(hl)
                ld (zCurrentSFXPriority),a

zLoc_08DF:
                xor a
                ld (de),a
                ret

zSilenceFMChannel:
                call zResetFMOperators
                ld a,40h
                ld c,7Fh
                call zWriteFourFMOperators
                ld c,(ix+zTrackChannel)
                jp zLoc_0430

zResetFMOperators:
                ld a,80h
                ld c,0FFh

zWriteFourFMOperators:
                ld b,4

zLoc_08F8:
                push af
                rst zWriteFMChannel
                pop af
                add a,4
                djnz zLoc_08F8
                ret

zFMFrequencyTable:
                dw      356h, 326h, 2F9h, 2CEh
                dw      2A5h, 280h, 25Ch, 23Ah
                dw      21Ah, 1FBh, 1DFh, 1C4h
                dw      1ABh, 193h, 17Dh, 167h
                dw      153h, 140h, 12Eh, 11Dh
                dw      10Dh, 0FEh, 0EFh, 0E2h
                dw      0D6h, 0C9h, 0BEh, 0B4h
                dw      0A9h, 0A0h, 97h, 8Fh
                dw      87h, 7Fh, 78h, 71h
                dw      6Bh, 65h, 5Fh, 5Ah
                dw      55h, 50h, 4Bh, 47h
                dw      43h, 40h, 3Ch, 39h
                dw      36h, 33h, 30h, 2Dh
                dw      2Bh, 28h, 26h, 24h
                dw      22h, 20h, 1Fh, 1Dh
                dw      1Bh, 1Ah, 18h, 17h
                dw      16h, 15h, 13h, 12h
                dw      11h

zPSGFrequencyTable:
                dw      284h, 2ABh, 2D3h, 2FEh
                dw      32Dh, 35Ch, 38Fh, 3C5h
                dw      3FFh, 43Ch, 47Ch, 4C0h

; Update the DAC control track. Flicky has no PCM samples in this image;
; the track drives additional sound-event state through the same sequencer.
zUpdateDACTrack:
                call zTickTrackDuration
                call z,zReadDACEvent
                ret

zReadDACEvent:
                ld e,(ix+zTrackData)
                ld d,(ix+4)

zLoc_09AF:
                ld a,(de)
                inc de
                cp 0E0h
                jp nc,zDispatchDACCoordFlag
                or a
                jp m,zLoc_09BE
                dec de
                ld a,(ix+zTrackFrequency)

zLoc_09BE:
                ld (ix+zTrackFrequency),a
                cp 80h
                jp z,zLoc_0A40
                push de
                ld hl,zDACTrack
                bit 2,(hl)
                jr nz,zLoc_0A12
                and 15
                jr z,zLoc_0A12
                ex af,af'
                call zKeyOffTrack
                ex af,af'
                ld de,zDACTrackInit
                ex de,hl
                ldi
                ldi
                ldi
                dec a
                ld hl,zDACVoicePointerTable
                rst zGetWordTableEntry
                ld bc,6
                ldir
                call zClearTrackState
                ld hl,zDACTranspose
                ld a,(ix+zTrackTranspose)
                add a,(hl)
                ld (hl),a
                ld a,(zDACVolumeEnvelope)
                ld hl,zDACEnvelopePointerTable
                rst zGetWordTableEntry
                ld a,(zDACVolume)
                ld e,(ix+zTrackVolume)
                push de
                add a,e
                ld (ix+zTrackVolume),a
                call zLoadFMVoice
                pop de
                ld (ix+zTrackVolume),e
                call zSilencePSGAndFM3

zLoc_0A12:
                ld hl,zMusicPSGTrack2
                bit 2,(hl)
                jr nz,zLoc_0A3F
                ld a,(ix+zTrackFrequency)
                and 70h
                jr z,zLoc_0A3F
                ld de,zDACAuxTrackInit
                ex de,hl
                ldi
                ldi
                ldi
                srl a
                srl a
                srl a
                srl a
                dec a
                ld hl,zDACSequenceData
                rst zGetWordTableEntry
                ld bc,6
                ldir
                call zClearTrackState

zLoc_0A3F:
                pop de

zLoc_0A40:
                ld a,(de)
                inc de
                or a
                jp p,zLoc_0276
                dec de
                ld a,(ix+zTrackSavedDuration)
                ld (ix+zTrackDuration),a
                jp zLoc_027C

zDACTrackInit:
                db      80h, 2, 1

zDACAuxTrackInit:
                db      80h, 0C0h, 1

zDispatchDACCoordFlag:
                ld hl,zDACCoordFlagReturn
                jp zDispatchCoordFlagFromTable

zDACCoordFlagReturn:
                inc de
                jp zLoc_09AF

zDACSequenceData:
                db      64h, 0Ah, 6Fh, 0Ah, 6Ah, 0Ah, 0, 4, 0, 1, 0F3h, 0E7h
                db      0C2h, 8, 0F2h, 75h, 0Ah, 0, 6, 0, 2, 0F3h, 0E7h, 0C5h
                db      8, 0F2h

zDACVoicePointerTable:
                dw      0A9Ah, 0ABCh, 0AC7h, 0AD0h
                dw      0AE4h, 0B06h, 0ADBh, 0B28h
                dw      0B4Ah, 0B71h

zDACEnvelopePointerTable:
                dw      0AA3h, 0AEDh, 0B0Fh, 0B31h
                dw      0B58h, 0B7Fh, 0AA0h, 0E00h
                dw      81h, 10B9h

zLoc_0AA2:
                db      0F2h, 3Eh, 60h, 30h, 30h, 30h, 19h, 1Fh, 1Fh, 1Fh, 15h, 11h
                db      11h, 0Ch, 10h, 0Ah, 6, 9, 4Fh, 5Fh, 0AFh, 8Fh, 0, 82h
                db      83h, 80h, 0C2h, 0Ah, 0, 0Ch, 81h, 0, 0E0h, 80h, 0B6h, 0Ah
                db      0F2h, 0CDh, 0Ah, 0, 0Ch, 81h, 0, 0B3h, 0Ah, 0F2h, 0D6h, 0Ah
                db      0, 0Ch, 81h, 0, 0E0h, 40h, 0B0h, 0Ah, 0F2h, 0E1h, 0Ah, 0
                db      0Ch, 81h, 0, 0B2h, 0Ah, 0F2h, 0EAh, 0Ah, 0, 3, 81h, 1
                db      89h, 8, 0F2h, 72h, 33h, 30h, 32h, 31h, 1Eh, 1Bh, 1Ch, 15h
                db      16h, 12h, 17h, 10h, 10h, 18h, 1Eh, 14h, 4Fh, 5Fh, 4Fh, 4Fh
                db      8, 0, 10h, 80h, 0Ch, 0Bh, 0, 6, 81h, 2, 0B0h, 16h
                db      0F2h, 72h, 9Eh, 5Bh, 42h, 22h, 96h, 96h, 9Eh, 96h, 16h, 18h
                db      16h, 18h, 10h, 17h, 11h, 18h, 4Fh, 5Fh, 4Fh, 4Fh, 0, 0
                db      10h, 80h, 2Eh, 0Bh, 0, 0Eh, 0, 3, 0B4h, 10h, 0F2h, 3Ch
                db      0Fh, 0, 0, 0, 1Fh, 1Ah, 18h, 1Ch, 17h, 11h, 1Ah, 0Eh
                db      0, 0Fh, 14h, 10h, 1Fh, 0ECh, 0FFh, 0FFh, 7, 80h, 16h, 80h
                db      50h, 0Bh, 0F7h, 0Ah, 0, 4, 0FEh, 3, 0, 0, 0, 95h
                db      20h, 0F2h, 3Ch, 0Ah, 50h, 70h, 0, 1Fh, 17h, 19h, 1Dh, 1Dh
                db      15h, 1Ah, 17h, 6, 18h, 7, 19h, 0Fh, 5Fh, 6Fh, 1Fh, 0Ch
                db      95h, 0, 8Eh, 77h, 0Bh, 0, 7, 0, 7, 0FEh, 0, 3
                db      0, 3, 0D1h, 8, 0F2h, 3Dh, 0, 0Fh, 0Fh, 0Fh, 1Fh, 9Fh
                db      9Fh, 9Fh, 1Fh, 1Fh, 1Fh, 1Fh, 0, 0Eh, 10h, 0Fh, 0Fh, 4Fh
                db      4Fh, 4Fh, 0, 90h, 90h, 85h

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

zSetPitchSlide:
                inc de
                bit 7,(ix+zTrackChannel)
                jr nz,zLoc_0E12
                ld a,(de)

zLoc_0E12:
                ld (ix+zTrackPitchEnvelope),a
                ret

zSequenceReturn:
                ex de,hl
                ld e,(hl)
                inc hl
                ld d,(hl)
                dec de
                ret

zSetRawFrequencyMode:
                cp 1
                jr nz,zLoc_0E25
                set 5,(ix+zTrackFlags)
                ret

zLoc_0E25:
                res 1,(ix+zTrackFlags)
                res 5,(ix+zTrackFlags)
                xor a
                ld (ix+zTrackFrequencyOffset),a
                ret

zSetPitchMode:
                cp 1
                jr nz,zLoc_0E3B
                set 3,(ix+zTrackFlags)
                ret

zLoc_0E3B:
                res 3,(ix+zTrackFlags)
                ret

; Deactivate a track, key it off, silence it, and restore any music
; track that had been temporarily overridden by an SFX.
zStopTrack:
                res 7,(ix+zTrackFlags)
                ld a,1Fh
                ld (zCurrentPriority),a
                call zKeyOffTrack
                ld c,(ix+zTrackChannel)
                push ix
                call zFindSFXTrack
                ld a,(zTrackContext)
                or a
                jr z,zLoc_0EC3
                xor a
                ld (zCurrentSFXPriority),a
                bit 7,(iy)
                jr z,zLoc_0E76
                ld a,(ix+zTrackChannel)
                cp (iy+1)
                jr nz,zLoc_0E76
                push iy
                ld l,(iy+2Ah)
                ld h,(iy+2Bh)
                jr zLoc_0E7A

zLoc_0E76:
                push hl
                ld hl,(zMusicVoiceTable)

zLoc_0E7A:
                pop ix
                res 2,(ix+zTrackFlags)
                bit 7,(ix+zTrackChannel)
                jr nz,zLoc_0EC8
                bit 7,(ix+zTrackFlags)
                jr z,zLoc_0EC3
                ld a,2
                cp (ix+zTrackChannel)
                jr nz,zLoc_0EA0
                ld a,4Fh
                bit 0,(ix+zTrackFlags)
                jr nz,zLoc_0E9D
                and 15

zLoc_0E9D:
                call zLoc_0D39

zLoc_0EA0:
                ld a,(ix+zTrackVolumeEnvelope)
                or a
                jp p,zLoc_0EAC
                call zLoc_0D63
                jr zLoc_0EC0

zLoc_0EAC:
                ld b,a
                call zLoc_0497
                call zLoadFMVoice
                ld a,(ix+zTrackFMEnvelope)
                or a
                jp p,zLoc_0EC3
                ld e,(ix+zTrackFMEnvelopeMask)
                ld d,(ix+zTrackPSGNoise)

zLoc_0EC0:
                call zLoc_0C09

zLoc_0EC3:
                pop ix
                pop hl
                pop hl
                ret

zLoc_0EC8:
                bit 0,(ix+zTrackFlags)
                jr z,zLoc_0EC3
                ld a,(ix+zTrackPSGNoise)
                or a
                jp p,zLoc_0ED8
                ld (zPSG),a

zLoc_0ED8:
                jr zLoc_0EC3

zSequenceCall:
                ld c,a
                inc de
                ld a,(de)
                ld b,a
                push bc
                push ix
                pop hl
                dec (ix+zTrackStackPointer)
                ld c,(ix+zTrackStackPointer)
                dec (ix+zTrackStackPointer)
                ld b,0
                add hl,bc
                ld (hl),d
                dec hl
                ld (hl),e
                pop de
                dec de
                ret

zSequenceReturnFromCall:
                push ix
                pop hl
                ld c,(ix+zTrackStackPointer)
                ld b,0
                add hl,bc
                ld e,(hl)
                inc hl
                ld d,(hl)
                inc (ix+zTrackStackPointer)
                inc (ix+zTrackStackPointer)
                ret

zSequenceLoop:
                inc de
                add a,zGetWordTableEntry
                ld c,a
                ld b,0
                push ix
                pop hl
                add hl,bc
                ld a,(hl)
                or a
                jr nz,zLoc_0F17
                ld a,(de)
                ld (hl),a

zLoc_0F17:
                inc de
                dec (hl)
                jp nz,zSequenceReturn
                inc de
                ret

; Update one PSG track and emit tone/noise and attenuation writes.
zUpdatePSGTrack:
                call zTickTrackDuration
                jr nz,zLoc_0F30
                call zReadFMEvent
                bit 4,(ix+zTrackFlags)
                ret nz
                call zUpdatePitchEnvelope
                jr zLoc_0F3C

zLoc_0F30:
                ld a,(ix+zTrackNoteFillCounter)
                or a
                jr z,zLoc_0F3C
                dec (ix+zTrackNoteFillCounter)
                jp z,zStopPSGTrack

zLoc_0F3C:
                call zCalculateTrackFrequency
                call zUpdatePitchSlide
                bit 2,(ix+zTrackFlags)
                ret nz
                ld c,(ix+zTrackChannel)
                ld a,l
                and 15
                or c
                ld (zPSG),a
                ld a,l
                and 0F0h
                or h
                rrca
                rrca
                rrca
                rrca
                ld (zPSG),a
                ld a,(ix+zTrackVolumeEnvelope)
                or a
                ld c,0
                jr z,zLoc_0F70
                dec a
                ld c,10
                ld b,80h
                call zResolveSoundPointer
                call zReadPSGEnvelope
                ld c,a

zLoc_0F70:
                bit 4,(ix+zTrackFlags)
                ret nz
                ld a,(ix+zTrackVolume)
                add a,c
                bit 4,a
                jr z,zLoc_0F7F
                ld a,15

zLoc_0F7F:
                or (ix+zTrackChannel)
                add a,zWriteFMChannel
                bit 0,(ix+zTrackFlags)
                jr nz,zLoc_0F8E
                ld (zPSG),a
                ret

zLoc_0F8E:
                add a,zGetLoadedDataTable
                ld (zPSG),a
                ret

zResetPSGEnvelope:
                ld (ix+zTrackPSGEnvelopeCursor),a

zReadPSGEnvelope:
                push hl
                ld c,(ix+zTrackPSGEnvelopeCursor)
                call zReadByteTableEntry
                pop hl
                bit 7,a
                jr z,zLoc_0FC4
                cp 83h
                jr z,zLoc_0FB3
                cp 81h
                jr z,zLoc_0FBE
                cp 80h
                jr z,zLoc_0FBB
                inc bc
                ld a,(bc)
                jr zResetPSGEnvelope

zLoc_0FB3:
                set 4,(ix+zTrackFlags)
                pop hl
                jp zStopPSGTrack

zLoc_0FBB:
                xor a
                jr zResetPSGEnvelope

zLoc_0FBE:
                pop hl
                set 4,(ix+zTrackFlags)
                ret

zLoc_0FC4:
                inc (ix+zTrackPSGEnvelopeCursor)
                ret

zStopPSGTrack:
                set 4,(ix+zTrackFlags)
                bit 2,(ix+zTrackFlags)
                ret nz

zSilencePSGTrack:
                ld a,1Fh
                add a,(ix+zTrackChannel)
                or a
                ret p
                ld (zPSG),a
                bit 0,(ix+zTrackFlags)
                ret z
                ld a,0FFh
                ld (zPSG),a
                ret

zDriverEnd:
