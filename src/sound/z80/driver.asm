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

                include "src/sound/z80/driver/abi.asm"
                include "src/sound/z80/driver/core.asm"
                include "src/sound/z80/driver/fm.asm"
                include "src/sound/z80/driver/control.asm"
                include "src/sound/z80/driver/mixer.asm"
                include "src/sound/z80/driver/coordination.asm"
                include "src/sound/z80/driver/sequencing_psg.asm"
