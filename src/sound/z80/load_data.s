; Z80 sound-data load descriptors and authored data banks
; ROM $0101D4-$010CD3
;
; Sound_LoadZ80Table copies one byte more than each stored last-index value
; because its inner loop uses DBF. The first transfer therefore includes the
; first byte of Data_Z80MusicBank, and the second includes the first byte of
; the following 68000 routine, exactly as in the original ROM

Data_Z80Driver2:
                dc.w    Data_Z80MusicBank-Data_Z80SFXBank
                dc.w    $1000
                dc.w    Data_Z80SFXBank-Sys_GameEntryPoint
                dc.w    Data_Z80Driver2_End-Data_Z80MusicBank
                dc.w    $1200
                dc.w    Data_Z80MusicBank-Sys_GameEntryPoint

Data_Z80SFXBank:
                binclude "build/z80_sound_data.bin"
Data_Z80MusicBank:  equ     Data_Z80SFXBank+$1C8
Data_Z80Driver2_End:
; Clears CRAM to black and initializes VDP state
