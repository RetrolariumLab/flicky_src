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
