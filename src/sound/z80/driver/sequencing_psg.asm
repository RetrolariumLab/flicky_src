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
