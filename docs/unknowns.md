# Unknowns Registry

This registry keeps uncertain readings from turning into source facts. Every
evidence tag in the source except `!(OBS)` names an entry here, and every entry
here is referenced from at least one place in the source. `make lint` checks
both directions, so neither side can quietly rot.

A plausible interpretation is not enough to rename a symbol or close an entry.
If the evidence only supports "this byte is written and never read", that is
what the entry says.

## Status vocabulary

- **Status** is `open`, `testing` or `resolved`.
- **Confidence** is `low`, `medium` or `high`.
- **Experiment** is the cheapest test that would settle it. Entries that are
  resolved carry a **Resolution** instead.

Identifiers are stable: `CODE-nnn` for code, `DATA-nnn` for authored data,
`RAM-nnn` for work RAM, `SND-nnn` for the sound driver. An identifier is never
reused, even after the entry is resolved.

---

### RAM-001 Two game-mode words written and never read

- **Status:** open
- **Confidence:** medium
- **Location:** `src/system/game_entry.s`, `src/memory/ram.inc`
- **Evidence:** `Sys_GameEntryPoint` clears `Ram_GameModeSpare1` (`$FFFFC2`) and
  `Ram_GameModeSpare2` (`$FFFFC4`) at startup. Those are the only two
  references anywhere in the ROM. They sit immediately after
  `Ram_NextGameMode` (`$FFFFC0`), which the mode dispatcher reads every frame,
  so they look like a three-word block of which only the first is live.
- **Experiment:** Break on read of `$FFFFC2`-`$FFFFC5` for a full longplay. If
  nothing hits, they are dead storage and can be labelled `Unused_`; if the
  RAM-resident routines read them, the reader identifies the owner.

### RAM-002 The Enigma output buffer overlaps the object array

- **Status:** open
- **Confidence:** medium
- **Location:** `src/rendering/tilemap.s`, `src/memory/ram.inc`
- **Evidence:** `Gfx_DecompEnigmaTilemap` decompresses into `Ram_EnigmaBuffer`
  at `$FFC3E0`. That address is inside the 32-slot object array that starts at
  `Ram_ObjectSlots` (`$FFC000`), one and a half slots into slot 15. Every
  caller runs during a screen transition, when the array is being rebuilt
  anyway, so the overlap may be deliberate reuse of scratch space.
- **Experiment:** Decompress a tilemap with live objects present -- the guide
  screen redraw is the closest natural case -- and watch whether slots 15 and
  16 are corrupted. If they are and nothing visibly breaks, the overlap is
  intentional; if the game misbehaves, it is a latent bug.

### RAM-003 A button-repeat flag whose enable is never set

- **Status:** open
- **Confidence:** medium
- **Location:** `src/system/input.s`, `src/memory/ram.inc`
- **Evidence:** `Input_ProcessJoypads` tests `Ram_ButtonRepeatEnable`
  (`$FFFF87`) and, when it is non-zero, clears `Ram_ButtonRepeatFlag`
  (`$FFFF86`). Nothing in the ROM ever writes `$FFFF87`, and work RAM is
  cleared to zero at boot, so the clear is unreachable in a normal session.
  The names describe the mechanism, not a proven purpose.
- **Experiment:** Force `$FFFF87` to a non-zero value and observe what changes
  in the expanded per-button bytes at `Ram_ButtonStates`. That should show what
  the suppressed byte controls.

### CODE-001 Three NOPs where a branch target should be

- **Status:** open
- **Confidence:** high
- **Location:** `src/system/startup.s`
- **Evidence:** After `Gfx_InitVDPRegister` returns, the boot path compares its
  result against zero and branches to `Boot_SetupControllerPorts` when it
  matches. The fall-through path is three `nop` instructions that run straight
  into the branch target, so the comparison has no effect on this ROM. The same
  shape appears again after `beq.s Boot_SetupControllerPorts`. This is the
  signature of code removed late in development and padded rather than
  reassembled.
- **Experiment:** None needed to establish the behaviour, which is already
  certain. Resolving the entry means finding what the removed code did, most
  likely by comparing against another Sega first-party boot sequence of the
  same era.

### CODE-002 An immediate the disassembler mistook for an address

- **Status:** resolved
- **Confidence:** high, verified by a relocation build
- **Location:** `src/game/round/main_loop.s`, `src/game/enemies/lizard.s`
- **Evidence:** IDA read the immediate `$14000` in `Game_CalcDifficulty` as an
  address and invented a label `loc_14000` for it, which happened to land inside
  `Player_ProcessInput`. The disassembly then wrote three instructions as
  `move.l #loc_14000,...`, so the difficulty accumulator and the lizard's speed
  read as pointers into an unrelated procedure. The value is not an address: it
  is compared against `$1C000` and incremented by 7.
- **Resolution:** All three are written as the literal `$14000` they always
  were. This changed nothing about the assembled ROM, which is exactly the
  problem it poses.
- **Why it matters beyond the instance:** `#loc_14000` and `#$14000` assemble to
  the same bytes at the original layout, so `make verify` cannot tell them
  apart. The difference only appears once the code moves: a label follows the
  move, a constant does not. Byte identity proves this project builds the same
  ROM; it does not prove the source understands what each number *is*.
- **How to check for others:** build with the two `org` directives removed so
  the image packs to about 58 KB, recompute the header checksum, and replay the
  recorded longplay against the reference state. A surviving mistaken label
  shows up as gameplay divergence, not as a build error.
- **Result of that check:** the current source passes. The padding-free build
  replays all 67,000 frames and reaches the credits with the same round, lives
  and score, and VRAM and CRAM are byte-identical at the frames compared. The
  pre-reconstruction source does not: it diverges at frame 4,000 and reaches
  game over by frame 10,000, because the enemy speed becomes `$68FC` instead of
  `$14000`. That is the observable form of this defect class.

### DATA-001 Z80 sound data holds pointers that assume a fixed ROM address

- **Status:** resolved on `source-2.0`
- **Confidence:** high, and the symptom is now measured rather than predicted
- **Location:** `src/sound/z80/load_data.s`, `src/sound/engine.s`
- **Original evidence:** `Sound_LoadZ80Table` converted ROM addresses to Z80-relative
  offsets with `suba.l #Sys_GameEntryPoint,a0`, which only holds while
  `Sys_GameEntryPoint` sits at exactly `$10000`. The offsets baked into
  `data/sound/data_z80_part2.bin` are not recomputed by the build.
- **Observed:** A build with both padding gaps removed puts
  `Sys_GameEntryPoint` at `$00290A`, 55,030 bytes lower, and shrinks the image
  to 58,013 bytes. The 68000 side is entirely unaffected: the recorded longplay
  replays all 67,000 frames and reaches the credits with the same round, lives
  and score, `$02862440`, and VRAM and CRAM are byte-identical to the reference
  at the frames compared. Of 185 named work RAM fields, 173 match and the 12
  that differ are all the high word of a ROM pointer, `$0001` against `$0000`,
  which is the shorter image and not a fault.

  The Z80 side is where it breaks, and quietly. 2,649 of 8,192 bytes of Z80 RAM
  differ, and the pointer table the reference holds at `$1000` --
  `14 10 42 10 7d 10 b0 10`, Z80 addresses `$1014`, `$1042`, `$107D`, `$10B0` --
  is all zeroes in the moved build. The sound data is never copied.
- **Correction:** this entry previously predicted that the game "hangs at
  specific points". It does not. It plays to the end with identical scoring and
  identical video, and only the audio is lost. The failure is silent, which is
  worse for anyone relocating this code and expecting a crash to tell them.
  The entry also blamed inserting padding; removing it breaks the same way, so
  the constraint is that `Sys_GameEntryPoint` must not move at all.
- **Resolution:** `src/sound/z80/data.asm` now authors the two data banks,
  including the resident SFX and music pointer tables and every voice/sequence
  pointer in their headers. Its address macros produce Z80 little-endian
  pointers from labels. The six 68000 descriptor words in
  `src/sound/z80/load_data.s` are expressions over the actual ROM labels instead of
  bytes inherited from the extracted image. `make z80-data-check` assembles the
  2,804-byte payload and requires byte identity with the original payload.
- **Relocation check:** The loader conversion must subtract the fixed 64-KiB
  RAM-image size, not the movable `Sys_GameEntryPoint` label. With that
  correction, `make verify-relocation` removes both padding gaps and moves the
  entry point from `$010000` to `$00290A`. The assembler recomputes the two
  source offsets as `$01DE` and `$03A6`; the loader maps them to `$FF01DE` and
  `$FF03A6`, and the gate verifies that the packed ROM contains the authored
  sound payload at those exact sources. The normal ROM remains byte-identical.

### DATA-002 Nemesis cannot be re-encoded byte for byte

- **Status:** open
- **Confidence:** high
- **Location:** `src/compression/nemesis_enigma.s`, `tools/nemesis_enc.py`,
  `tools/enigma_enc.py`
- **Evidence:** `tools/nemesis_enc.py` re-encodes using the code table carried
  by the original stream, so the only remaining freedom is how the nybble
  sequence is split into runs. A greedy split and a bit-optimal split both
  produce valid streams that decode to identical pixels, and neither reproduces
  the original bytes. The optimal split is consistently *smaller* than the
  original -- 117 against 128 bytes for `ExitTiles`, 6,037 against 6,052 for
  `LevelTiles` -- which shows the original compressor was not minimising size
  and used a heuristic that has not been identified. Enigma is no longer part
  of the unknown: `tools/enigma_enc.py` exactly reproduces the ten-byte Sega
  tilemap and round-trips arbitrary word streams through the decoder.
- **Experiment:** Compare against Nemesis streams from other Sega titles of the
  same period, whose compressor is likely the same tool. If a splitting rule
  reproduces those byte for byte, it should reproduce these. Until then the
  formats are proven semantically -- decode, re-encode, decode again yields the
  same pixels -- and `config/data_formats.json` records `semantic` rather than
  `exact` for them so the weaker claim is visible.

### SND-001 The Z80 driver itself is not disassembled

- **Status:** resolved on `source-2.0`
- **Confidence:** high
- **Location:** `src/sound/z80/driver.asm`,
  `scripts/build/build_z80_driver.py`, `docs/z80_sound_driver.md`
- **Correction:** Only `z80_part1` is executable. `z80_part2` begins with two
  68000 load descriptors and supplies the data banks copied to Z80 `$1000` and
  `$1200`; no control-flow target enters either bank.
- **Resolution:** The 4,070-byte resident image is a symbolic Z80 source with
  named routines, hardware ports, global RAM, all 48-byte track fields, chip
  tables and all `$E0-$FF` coordination-flag handlers. `make verify` assembles
  it as a separate CPU pass, requires it to match the extracted image byte for
  byte, then includes that generated image in the 68000 ROM. The resulting ROM
  remains byte-identical.
- **Remaining data work:** The music/SFX banks, indices and headers are authored
  and all their header pointers are symbolic. Event streams and FM voices are
  still emitted as explicit source bytes; converting those bytes into command
  and operator macros is the next semantic pass for the sound editor, not
  executable-code debt under SND-001.
