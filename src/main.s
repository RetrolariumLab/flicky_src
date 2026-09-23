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

                include "macros/macros.inc"
                include "memory/hardware.inc"
                include "memory/constants.inc"
                include "memory/ram.inc"

; Reconstructed from a disassembly of the following cartridge dump:
; SHA-256 4DF1A91E08376AE773A6EB8E5ABE310F94CA39D8F81583B91A9477FEDCB68C11
; MD5     805CC0B3724F041126A57A4D956FD251
; CRC32   4291C8AB
; The initial disassembly was produced with IDA Pro 7.6 SP1

                include "system/startup.s"              ; $000000-$000855
                include "system/dma.s"                  ; $000856-$000AD3
                include "compression/nemesis_enigma.s"  ; $000AD4-$000DBF
                include "system/input.s"                ; $000DC0-$000E41
                include "rendering/vdp.s"               ; $000E42-$001013
                include "sound/z80/host.s"              ; $001014-$001195
                include "rendering/tilemap.s"           ; $001196-$001315
                include "data/bank0.s"                  ; $001316-$00FFFF
                include "system/game_entry.s"           ; $010000-$0101D3
                include "sound/z80/load_data.s"         ; $0101D4-$010CD3
                include "sound/engine.s"                ; $010CD4-$010D6D
                include "rendering/rle.s"               ; $010D6E-$010DE7
                include "game/text_encoding.s"          ; $010DE8-$010E87
                include "system/vblank.s"               ; $010E88-$010F23
                include "rendering/text.s"              ; $010F24-$01105B
                include "game/world.s"                  ; $01105C-$011673
                include "game/rules.s"                  ; $011674-$01190F
                include "rendering/level_draw.s"        ; $011910-$011BC1
                include "rendering/hud.s"               ; $011BC2-$011FAF
                include "game/screens/front_end.s"      ; $011FB0-$0125BD
                include "game/round/select_and_setup.s"  ; $0125BE-$012A93
                include "game/round/main_loop.s"        ; $012A94-$012F2F
                include "game/bonus/mode.s"             ; $012F30-$01310F
                include "game/screens/ending.s"         ; $013110-$0139A1
                include "game/screens/attract_mode.s"   ; $0139A2-$013E6F
                include "game/actors/player.s"          ; $013E70-$0144DB
                include "game/actors/window_girl_and_throwable.s"  ; $0144DC-$01483D
                include "game/actors/chirp.s"           ; $01483E-$014EC5
                include "game/enemies/tiger.s"          ; $014EC6-$015507
                include "data/level_layout.s"           ; $015508-$015D57
                include "game/enemies/iggy.s"           ; $015D58-$016311
                include "game/enemies/spawner.s"        ; $016312-$0164EB
                include "game/bonus/objects.s"          ; $0164EC-$016DA9
                include "game/screens/game_over.s"      ; $016DAA-$016E57
                include "data/art.s"                    ; $016E58-$01A195
                include "data/tables.s"                 ; $01A196-$01FFFF
