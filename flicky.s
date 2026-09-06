; Flicky (Sega Mega Drive) -- top-level source index
;
; Modules are listed in ROM address order and assembled as a single AS
; translation unit, so every label stays global. The order is the ROM
; layout itself: moving an include moves code in the output and breaks
; "make verify"

                cpu     68000
                page    0
                supmode on
                padding off

                include "src/macros/macros.inc"
                include "src/memory/hardware.inc"
                include "src/memory/constants.inc"
                include "src/memory/ram.inc"

; Reconstructed from a disassembly of the following cartridge dump:
; SHA-256 4DF1A91E08376AE773A6EB8E5ABE310F94CA39D8F81583B91A9477FEDCB68C11
; MD5     805CC0B3724F041126A57A4D956FD251
; CRC32   4291C8AB
; The initial disassembly was produced with IDA Pro 7.6 SP1

                include "src/system/vectors_and_header.s"  ; $000000-$0001FF
                include "src/system/boot.s"             ; $000200-$000401
                include "src/system/sega_screen.s"      ; $000402-$000855
                include "src/system/dma.s"              ; $000856-$000AD3
                include "src/compression/nemesis_enigma.s"  ; $000AD4-$000DBF
                include "src/system/input.s"            ; $000DC0-$000E41
                include "src/rendering/vdp.s"           ; $000E42-$001013
                include "src/sound/z80_driver.s"        ; $001014-$001195
                include "src/rendering/tilemap.s"       ; $001196-$001315
                include "src/data/bank0.s"              ; $001316-$00FFFF
                include "src/system/game_entry.s"       ; $010000-$0101D3
                include "src/data/z80_sound.s"          ; $0101D4-$010CD3
                include "src/sound/engine.s"            ; $010CD4-$010D6D
                include "src/rendering/rle.s"           ; $010D6E-$010DE7
                include "src/game/text_encoding.s"      ; $010DE8-$010E87
                include "src/system/vblank.s"           ; $010E88-$010F23
                include "src/rendering/text.s"          ; $010F24-$01105B
                include "src/game/objects.s"            ; $01105C-$01130B
                include "src/game/camera_collision.s"   ; $01130C-$011421
                include "src/game/level.s"              ; $011422-$011673
                include "src/game/scoring.s"            ; $011674-$0117BF
                include "src/game/collision_pairs.s"    ; $0117C0-$01190F
                include "src/rendering/level_draw.s"    ; $011910-$011BC1
                include "src/rendering/hud.s"           ; $011BC2-$011FAF
                include "src/game/title.s"              ; $011FB0-$01228D
                include "src/game/guide.s"              ; $01228E-$0125BD
                include "src/game/round_select.s"       ; $0125BE-$012655
                include "src/game/round_setup.s"        ; $012656-$012A93
                include "src/game/main_loop.s"          ; $012A94-$012F2F
                include "src/game/bonus.s"              ; $012F30-$01310F
                include "src/game/ending.s"             ; $013110-$0139A1
                include "src/game/demo.s"               ; $0139A2-$013E6F
                include "src/game/player.s"             ; $013E70-$0144DB
                include "src/game/chick.s"              ; $0144DC-$01483D
                include "src/game/cat.s"                ; $01483E-$014EC5
                include "src/game/lizard.s"             ; $014EC6-$015507
                include "src/data/level_layout.s"       ; $015508-$015D57
                include "src/game/snake.s"              ; $015D58-$016311
                include "src/game/spawner.s"            ; $016312-$0164EB
                include "src/game/bonus_objects.s"      ; $0164EC-$016DA9
                include "src/game/game_over.s"          ; $016DAA-$016E57
                include "src/data/art.s"                ; $016E58-$01A195
                include "src/data/tables.s"             ; $01A196-$01FFFF
