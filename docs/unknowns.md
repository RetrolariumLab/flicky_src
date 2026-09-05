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
- **Location:** `src/system/boot.s`
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

### DATA-001 Z80 sound data holds pointers that assume a fixed ROM address

- **Status:** open
- **Confidence:** high
- **Location:** `src/data/z80_sound.s`, `src/sound/engine.s`
- **Evidence:** `Sound_LoadZ80Table` converts ROM addresses to Z80-relative
  offsets with `suba.l #Sys_GameEntryPoint,a0`, which only works because
  `Sys_GameEntryPoint` sits at exactly `$10000`. The offsets baked into
  `data/sound/data_z80_part2.bin` are not recomputed by the build, so inserting
  padding anywhere before `$10000` shifts the code without shifting the data
  and the game hangs at specific points.
- **Experiment:** Decode the pointer fields inside the extracted Z80 blob and
  express them as expressions the assembler computes, the way the rest of the
  source does. Until then the constraint is a real one and belongs in
  `README.md` as a known gap.

### SND-001 The Z80 driver itself is not disassembled

- **Status:** open
- **Confidence:** high
- **Location:** `src/data/bank0.s`, `src/data/z80_sound.s`
- **Evidence:** Two Z80 images are copied into sound RAM verbatim:
  `z80_part1` (`$1316`-`$22FC`) and `z80_part2` (`$101D4`-`$10CD4`). The 68000
  side only writes command bytes into `Z80_MusicCommand` and the three
  `Z80_SFXSlot` bytes and polls them back. Everything the driver does with
  those commands is opaque to this reconstruction.
- **Experiment:** Disassemble the Z80 images as a separate pass. That is a
  milestone of its own, not a question to be answered in passing, and the
  byte-identical gate does not depend on it.
