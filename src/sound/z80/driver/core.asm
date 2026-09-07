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
