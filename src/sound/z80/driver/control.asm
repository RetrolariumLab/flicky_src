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
