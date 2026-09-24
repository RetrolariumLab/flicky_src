# Z80 sound driver

Flicky runs its complete music and sound-effect sequencer on the Z80. This is
the important difference from Sonic 1: Sonic's extensively documented driver
runs the SMPS sequencer on the 68000 and leaves PCM playback to the Z80, while
Flicky's Z80 writes both the YM2612 and SN76489 directly.

The resident program is now reconstructed in
`src/sound/z80/driver.asm`. It contains symbolic routines, hardware and RAM
names, a 48-byte track layout, frequency and register-order tables, and the
full `$E0-$FF` coordination-flag dispatch. `scripts/build/build_z80_driver.py`
assembles it before the 68000 pass and requires the resulting 4,070 bytes to
match `data_z80_part1.bin` exactly. The main ROM then includes that generated
image at `$001316`. This closes [SND-001](unknowns.md).

## Runtime layout

| Z80 range | Size | Owner |
| --- | ---: | --- |
| `$0000-$0FE5` | 4,070 | Resident driver assembled from source |
| `$1000-$11C8` | 457 | Loaded sound-effect data bank |
| `$1200-$1B2C` | 2,349 | Loaded indices, priorities, music and sequence data |
| `$1C00-$1C3F` | 64 | Global driver state and the 68000 command mailbox |
| `$1C40-$1F9F` | 18 x 48 | Music, DAC, special-SFX and ordinary-SFX tracks |
| `$1FFD-$1FFF` | 3 | Stack and interrupt countdown |
| `$4000-$4003` | 4 ports | YM2612 address/data ports |
| `$6000` | serial | 68000 ROM bank register |
| `$7F11` | 1 port | SN76489 PSG |
| `$8000-$FFFF` | 32 KiB | Banked 68000 ROM window |

The two records at the start of the original `data_z80_part2.bin` are now
expressions in `src/sound/z80/load_data.s`. They are big-endian 68000 load
descriptors. Each is `last_index, z80_destination, source_offset`; the copy
loop uses `dbf`, so `last_index` is one less than the byte count:

| Descriptor | Source in copied 68000 RAM | Z80 destination | Bytes |
| --- | --- | --- | ---: |
| `01C8 1000 01E0` | `$FF01E0` | `$1000` | 457 |
| `092C 1200 03A8` | `$FF03A8` | `$1200` | 2,349 |

The second copy includes the byte at ROM `$010CD4`, immediately after the
nominal binary segment. This follows directly from the `dbf` count and is why
the loaded size is 2,349 although only 2,348 bytes remain in
`data_z80_part2.bin` after its second descriptor.

The payload itself is `src/sound/z80/data.asm`. Its `zMusicBank` label defines
the boundary between the generated SFX and music includes in
`src/sound/z80/load_data.s`; no fixed source offset is needed there. The source
declares nine ordinary SFX slots (`$90-$98`), the special `$D0` alias, seven music slots (`$81-$87`,
with `$86` empty), and symbolic voice/sequence pointers for every header.
`$88` has no table entry: reading it would consume the first word of the `$81`
header. FM voices and event bodies remain explicit bytes until the editor's
command-level encoder is added, but they are no longer hidden in a binary
include. `make z80-data-check` requires the assembled payload to match all
2,804 original bytes.

## 68000 interface

After loading the driver, the 68000 writes ten initialization bytes at `$1C00`.
They provide the ROM bank, the data-index pointer, YM timers, the update flag,
and the number of resident SFX slots. Normal operation uses only these mailbox
bytes:

| Z80 address | 68000 alias | Meaning |
| --- | --- | --- |
| `$1C09` | `Z80_MusicCommand` | Music or global sound command |
| `$1C0A` | `Z80_SFXSlot0` | First queued sound effect |
| `$1C0B` | `Z80_SFXSlot1` | Second queued sound effect |
| `$1C0C` | `Z80_SFXSlot2` | Third queued sound effect |
| `$1C10` | `Z80_PauseFlag` | Pause/resume request |

`zProcessSoundCommand` divides command bytes into four ranges:

| Range | Meaning |
| --- | --- |
| `$81-$8F` | Music |
| `$90-$CF` | Ordinary SFX |
| `$D0-$DF` | Special SFX with dedicated track slots |
| `$E0-$F8` | Global driver commands |

The three SFX mailboxes are arbitrated through the priority table addressed by
the data index at `$1200`. A new request replaces the pending request only when
its priority permits it. The selected command is copied to `$1C09` and cleared
from all three SFX mailboxes before dispatch.

## Scheduler and chips

The reset vector selects Z80 interrupt mode 1. The `$0038` handler preserves
the main registers and counts three timer interrupts before setting the update
request. The main loop polls YM2612 status and services timer A and timer B
independently. This explains why the driver contains two update paths and why
music timing must be previewed against the emulator rather than assumed to be
one sequencer tick per video frame.

At the YM2612 master clock, timer A advances once per 24 operators times the
fixed prescale 6: `(1024-A) * 144` clock cycles. Timer B adds its 16-fold
divider: `(256-B) * 2304` cycles. Music tracks advance on timer A and ordinary
SFX tracks on timer B; a standalone SFX preview must not also advance them on
timer A.

YM2612 writes wait for the busy bit before touching an address/data pair.
Channel bit 2 selects port 1; the other FM channels use port 0. PSG tracks are
identified by bit 7 of the channel byte and write latched tone/noise and volume
commands to `$7F11`.

## Track structure

Every channel has a `$30`-byte state block. The same layout is used for music,
ordinary SFX and special SFX. Confirmed fields are named as `zTrack*` constants
in the source, so instructions read as `(ix+zTrackData)` rather than anonymous
offsets. The central fields are:

| Offset | Source name | Meaning |
| ---: | --- | --- |
| `$00` | `zTrackFlags` | Active, rest/hold and processing-mode bits |
| `$01` | `zTrackChannel` | YM2612 channel or PSG latch bits |
| `$02` | `zTrackDurationScale` | Duration multiplier |
| `$03` | `zTrackData` | Little-endian sequence cursor |
| `$05` | `zTrackTranspose` | Signed note transposition |
| `$06` | `zTrackVolume` | FM attenuation or PSG volume |
| `$0B/$0C` | `zTrackDuration` / `zTrackSavedDuration` | Tick counters |
| `$0D` | `zTrackFrequency` | Current 16-bit chip frequency value |
| `$11-$16` | `zTrackModulation*` | Modulation setup and counters |
| `$17` | `zTrackPSGEnvelopeCursor` | PSG envelope position |
| `$1C` | `zTrackFMLevels` | Cached FM total levels |
| `$20-$27` | `zTrackPitchEnvelope*` | Pitch-envelope state |
| `$28-$2F` | `zTrackLoopCounters` | Loop/call scratch and SFX voice override |

The tail is deliberately reused. An ordinary SFX may store its own voice-table
pointer at `$2A`, while sequence calls and loops use the same eight-byte area
as a small stack and counter array. An editor must therefore treat it as
runtime state, not as eight independent persistent fields.

## Sequence format

Values below `$E0` are notes, rests, explicit frequencies or durations,
depending on track flags. Values `$E0-$FF` index `zCoordFlagTable`; the handler
table and every target are now symbolic. Confirmed operations include tempo
changes, transposition, duration scaling, FM voice selection, AMS/FMS and LFO,
modulation, note fill, PSG noise and envelopes, track stop, subroutine call,
return and counted loops.

This is SMPS-like in architecture but not wire-compatible with the Sonic 1
music files. In particular, it has a Z80-native pointer resolver that can draw
headers either from the resident `$1000/$1200` banks or through the banked ROM
window at `$8000`. A sound editor should use this command table as its format
authority rather than importing a Sonic SMPS parser.

## Editor and standalone playback

Sound Studio uses this reconstructed command table as its format authority.
It presents linear note data as a piano roll and decodes every 25-byte voice
into algorithm, feedback, and the four YM2612 operators. Its headless Python
sequencer follows the same track states, duration inheritance, calls, loops,
timers, voice loads, key events, and register writes as the resident driver.

The register log is exported as VGM 1.50. A compact project frontend around
the pinned upstream ymfm core renders YM2612 output to WAV; its small internal
SN76489 implementation covers PSG writes without introducing a second runtime
dependency. This makes ordinary preview independent of Gens. Emulator tracing
remains the fidelity oracle used to test the Python sequencer against the
original Z80 implementation.

The resident bank declares PSG tracks in music `$84` and `$87`, but both point
to a one-byte `$F2` stop sequence; all eight resident SFX tracks are FM. Thus
the shipped material exercises PSG channel muting, but contains no active PSG
tone sequence whose pitch or envelope playback could be compared. The VGM
path retains SN76489 writes, while the executable fidelity claim below is
deliberately limited to the YM2612 traffic that the original content emits.

The oracle is `make verify-sound-sequencer`. The sibling Gens hook sits in
`Z80_WriteB_YM2612` and records a logical CSV row only when the emulated Z80
performs the corresponding data-port write. The validation window is frames
320-457 of the pinned longplay: music `$85` starts there, and the later global
fade-out is outside the window. After aligning on the song's first 32 writes,
all 2,624 audible YM2612 writes match the Python sequencer exactly, and their
timing agrees with the frame-resolution trace within 2.1 frames. Registers
`$24-$27` are deliberately omitted from the value comparison because they are
the driver's timer scheduling traffic. The capture uses
`config/runtime/gens_sound_trace.cfg`, so a persisted sound-off development setting
cannot silently produce an empty trace.
