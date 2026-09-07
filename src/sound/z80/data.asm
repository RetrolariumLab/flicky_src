; Flicky Z80 sound banks
; ROM $0101E0-$010CD3, loaded at Z80 $1000 (sound effects) and $1200 (indices,
; priorities, envelopes and music).
;
; The banks are the game's sound data, so the source keeps none of it: the
; build includes them as they are cut from the user's ROM into
; data/sound/data_z80_part2.bin, after the twelve bytes of 68000 load
; descriptors. Every pointer in the banks is a Z80 address inside them, so
; they load wherever the 68000 image puts them.

                cpu     68000
                page    0
                org     0

zSFXBank:
                binclude "data/sound/data_z80_part2.bin",12,$1C8
zMusicBank:
                binclude "data/sound/data_z80_part2.bin",12+$1C8,$92C
zSoundBanksEnd:

; Retrolarium Kit reads this file as the banks' assembly and needs this
; label; here it holds nothing, so its sound view has nothing to edit.
zPriorityAndEnvelopeData:
