; Flicky Z80 sound banks
; ROM $0101E0-$010CD3, loaded at Z80 $1000 (sound effects) and $1200 (indices,
; priorities, envelopes and music).
;
; The banks are the game's sound data, so the source keeps none of it: the
; build includes them as they are cut from the user's ROM into
; data/sound/data_z80_part2.bin, after the twelve bytes of 68000 load
; descriptors that src/sound/z80/load_data.s writes from labels. Every pointer
; in the banks is a Z80 address inside them, so they load wherever the 68000
; image puts them.
;
; config/z80_sound_data.layout is the assembly of the banks with each data
; value left as a placeholder: where every header, sequence and voice bank is
; and how it is written. Retrolarium Kit fills it from the ROM to give the
; assembly its studio edits, which then builds in place of this file.

                cpu     68000
                page    0
                org     0

zSFXBank:
                binclude "data/sound/data_z80_part2.bin",12,$1C8
zMusicBank:
                binclude "data/sound/data_z80_part2.bin",12+$1C8,$92C
zSoundBanksEnd:

; Retrolarium Kit releases before the layout read this file as the banks'
; assembly and need this label; here it holds nothing, so they see no sounds
; to edit but still build.
zPriorityAndEnvelopeData:
