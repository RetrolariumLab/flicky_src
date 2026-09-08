#!/usr/bin/env python3
"""Offline interpreter for Flicky's resident Z80 sound sequences.

The interpreter follows the reconstructed driver rather than a generic SMPS
dialect.  Its output is an ordered register log which can be written as VGM,
fed to a chip renderer, or compared with an emulator trace.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Iterable

from authoring import sound_studio_model


YM2612_CLOCK = 7_670_454
SN76489_CLOCK = 3_579_545
DEFAULT_SAMPLE_RATE = 44_100
FM_FREQUENCY_TABLE_ADDRESS = 0x0900
FM_SEMITONE_TABLE_ADDRESS = FM_FREQUENCY_TABLE_ADDRESS + 69 * 2
MODULATION_POINTERS = (0x02FE, 0x02FF, 0x0300, 0x0301, 0x80C0, 0x40C0, 0xC080)
MUSIC_FM_CHANNELS = (2, 0, 1, 4, 5, 6, 2)
MUSIC_PSG_CHANNELS = (0x80, 0xA0, 0xC0)
ADDRESS_RE = re.compile(r";\s*\$([0-9A-Fa-f]{4})\b")

VOICE_REGISTERS = (
    0xB0, 0x30, 0x38, 0x34, 0x3C, 0x50, 0x58, 0x54, 0x5C,
    0x60, 0x68, 0x64, 0x6C, 0x70, 0x78, 0x74, 0x7C, 0x80,
    0x88, 0x84, 0x8C,
)
LEVEL_REGISTERS = (0x40, 0x48, 0x44, 0x4C)


def signed_byte(value: int) -> int:
    return value - 0x100 if value & 0x80 else value


def timer_a_period_samples(value: int, sample_rate: int) -> float:
    """YM2612 timer-A overflow period, in output samples."""
    return sample_rate * 144.0 * (1024 - (value & 0x3FF)) / YM2612_CLOCK


def timer_b_period_samples(value: int, sample_rate: int) -> float:
    """YM2612 timer-B overflow period, in output samples."""
    return sample_rate * 2304.0 * (256 - (value & 0xFF)) / YM2612_CLOCK


@dataclass(frozen=True)
class ChipWrite:
    sample: int
    chip: str
    value: int
    port: int = 0
    address: int = 0
    channel: int | None = None


@dataclass
class NoteEvent:
    track: int
    channel: int
    start_sample: int
    end_sample: int
    note: int | None
    voice: int
    rest: bool = False


@dataclass
class RenderResult:
    header_id: str
    kind: str
    sample_rate: int
    total_samples: int
    writes: list[ChipWrite]
    notes: list[NoteEvent]


@dataclass
class TrackState:
    index: int
    kind: str
    channel: int
    cursor: int
    duration_scale: int
    transpose: int
    volume: int
    active: bool = True
    duration: int = 1
    saved_duration: int = 0
    frequency: int = 0
    frequency_offset: int = 0
    voice: int = 0
    voice_control: int = 0xC0
    flags: int = 0x80
    note_fill: int = 0
    note_fill_counter: int = 0
    modulation_delay: int = 0
    modulation_speed: int = 0
    modulation_step: int = 0
    modulation_steps: int = 0
    modulation_speed_reload: int = 0
    modulation_speed_counter: int = 0
    pitch_envelope: int = 0
    pitch_data: tuple[int, int, int, int] | None = None
    pitch_value: int = 0
    pitch_delay: int = 0
    pitch_cursor: int = 0
    pitch_step: int = 0
    pitch_step_counter: int = 0
    loops: dict[int, int] = field(default_factory=dict)
    stack: list[int] = field(default_factory=list)
    current_note: NoteEvent | None = None


def _sequence_addresses(baseline: Path, identifiers: Iterable[str]) -> dict[str, int]:
    source = baseline.read_text(encoding="utf-8")
    blocks = sound_studio_model._blocks(source)
    result = {}
    for identifier in identifiers:
        try:
            block = blocks[identifier][2]
        except KeyError as error:
            raise ValueError(f"sequence label missing from baseline: {identifier}") from error
        match = ADDRESS_RE.search(block)
        if not match:
            raise ValueError(f"sequence has no Z80 address annotation: {identifier}")
        result[identifier] = int(match.group(1), 16)
    return result


class SoundSequencer:
    """Interpret one resident song or SFX and record its chip writes."""

    def __init__(self, document: dict[str, Any], baseline: Path):
        sound_studio_model.validate_document(document, baseline)
        self.document = document
        self.headers = {item["id"]: item for item in document["headers"]}
        self.sequences = {item["id"]: item for item in document["sequences"]}
        self.voices = {item["id"]: item for item in document["voice_banks"]}
        addresses = _sequence_addresses(baseline, self.sequences)
        self.memory: dict[int, int] = {}
        for identifier, sequence in self.sequences.items():
            address = addresses[identifier]
            for offset, value in enumerate(sequence["bytes"]):
                location = address + offset
                if location in self.memory and self.memory[location] != value:
                    raise ValueError(f"overlapping sequence bytes at ${location:04X}")
                self.memory[location] = value
        self.addresses = addresses
        driver_path = baseline.resolve().parents[3] / "data/sound/data_z80_part1.bin"
        self.driver = driver_path.read_bytes()
        self.writes: list[ChipWrite] = []
        self.notes: list[NoteEvent] = []
        self.sample = 0
        self.timer_a = 0
        self.timer_b = 0
        self.enabled_channels: set[int] | None = None
        self.voice_bank: list[list[int]] = []

    @classmethod
    def from_source(cls, workspace: Path, baseline: Path) -> "SoundSequencer":
        return cls(sound_studio_model.export_document(workspace), baseline)

    def _byte(self, address: int) -> int:
        try:
            return self.memory[address]
        except KeyError as error:
            raise ValueError(f"sequence read outside resident data at ${address:04X}") from error

    def _take(self, track: TrackState) -> int:
        value = self._byte(track.cursor)
        track.cursor += 1
        return value

    def _channel_enabled(self, track: TrackState) -> bool:
        return self.enabled_channels is None or track.index in self.enabled_channels

    def _ym(self, track: TrackState, address: int, value: int) -> None:
        if not self._channel_enabled(track):
            return
        port = 1 if track.channel & 4 else 0
        register = address + (track.channel - 4 if port else track.channel)
        self.writes.append(ChipWrite(
            self.sample, "ym2612", value & 0xFF, port, register & 0xFF, track.index
        ))

    def _ym_global(self, address: int, value: int, channel: int | None = None) -> None:
        if channel is not None and self.enabled_channels is not None and channel not in self.enabled_channels:
            return
        self.writes.append(ChipWrite(
            self.sample, "ym2612", value & 0xFF, 0, address & 0xFF, channel
        ))

    def _psg(self, track: TrackState, value: int) -> None:
        if self._channel_enabled(track):
            self.writes.append(ChipWrite(
                self.sample, "sn76489", value & 0xFF, channel=track.index
            ))

    def _key_off(self, track: TrackState) -> None:
        if track.kind != "psg" and not track.flags & 6:
            self._ym_global(0x28, track.channel, track.index)

    def _key_on(self, track: TrackState) -> None:
        if track.kind != "psg" and track.frequency and not track.flags & 6:
            self._ym_global(0x28, 0xF0 | track.channel, track.index)

    def _close_note(self, track: TrackState) -> None:
        if track.current_note is not None:
            track.current_note.end_sample = max(track.current_note.start_sample + 1, self.sample)
            track.current_note = None

    def _stop(self, track: TrackState) -> None:
        self._close_note(track)
        self._key_off(track)
        if track.kind == "psg":
            self._psg(track, 0x1F + track.channel)
        track.active = False

    def _write_frequency(self, track: TrackState, pitch_offset: int = 0) -> None:
        frequency = (track.frequency + signed_byte(track.frequency_offset)) & 0xFFFF
        if track.kind == "psg":
            return
        low11 = frequency & 0x7FF
        if low11 <= 0x283:
            frequency = (frequency - 0x57B) & 0xFFFF
        elif low11 > 0x508:
            frequency = (frequency + 0x57C) & 0xFFFF
        frequency = (frequency + pitch_offset) & 0xFFFF
        self._ym(track, 0xA4, frequency >> 8)
        self._ym(track, 0xA0, frequency)

    def _load_voice(self, track: TrackState, index: int) -> None:
        if not 0 <= index < len(self.voice_bank):
            raise ValueError(f"voice {index} is outside {len(self.voice_bank)}-voice bank")
        track.voice = index
        voice = self.voice_bank[index]
        for register in (0x80, 0x84, 0x88, 0x8C):
            self._ym(track, register, 0xFF)
        self._ym(track, 0xB4, track.voice_control)
        for register, value in zip(VOICE_REGISTERS, voice[:21]):
            self._ym(track, register, value)
        for register, value in zip(LEVEL_REGISTERS, voice[21:25]):
            level = value & 0x7F
            if value & 0x80:
                level = (level + track.volume) & 0x7F
            self._ym(track, register, level)

    def _duration(self, track: TrackState, value: int) -> int:
        return (value * max(1, track.duration_scale)) & 0xFF

    def _frequency(self, note: int) -> int:
        # zReadFMEvent folds the 8-bit note index into a semitone and an
        # octave field.  The unfortunately named zPSGFrequencyTable is the
        # twelve-entry F-number table used by FM tracks for this operation.
        semitone = note % 12
        octave = note // 12
        offset = FM_SEMITONE_TABLE_ADDRESS + semitone * 2
        if offset + 2 > len(self.driver):
            raise ValueError("FM semitone table reads beyond the resident driver")
        base = int.from_bytes(self.driver[offset:offset + 2], "little")
        return ((((octave * 8) & 0xFF) | (base >> 8)) << 8) | (base & 0xFF)

    def _update_modulation(self, track: TrackState, *, new_event: bool) -> None:
        """Mirror zUpdateModulation/zLoc_02EE, including its code-byte waves."""
        if new_event:
            delay_minus_one = (track.modulation_delay - 1) & 0xFF
            if delay_minus_one & 0x80:
                return
            if delay_minus_one:
                track.modulation_step = 0
        elif track.modulation_delay < 2:
            return

        track.modulation_speed_counter = (track.modulation_speed_counter - 1) & 0xFF
        if track.modulation_speed_counter:
            return
        track.modulation_speed_counter = track.modulation_speed_reload
        try:
            pointer = MODULATION_POINTERS[track.modulation_speed]
        except IndexError as error:
            raise ValueError(
                f"modulation speed {track.modulation_speed} is outside the driver table"
            ) from error
        step = track.modulation_step
        track.modulation_step = (track.modulation_step + 1) & 0xFF
        if ((track.modulation_steps - 1) & 0xFF) == step:
            track.modulation_step = (track.modulation_step - 1) & 0xFF
            if track.modulation_delay != 2:
                track.modulation_step = 0
        address = pointer + step
        if not 0 <= address < len(self.driver):
            raise ValueError(f"modulation wave reads outside resident driver at ${address:04X}")
        track.voice_control = (track.voice_control & 0x3F) | self.driver[address]
        self._ym(track, 0xB4, track.voice_control)

    def _start_pitch_envelope(self, track: TrackState) -> None:
        if track.pitch_envelope != 0x80 or track.pitch_data is None or track.flags & 2:
            return
        delay, cursor, step, step_counter = track.pitch_data
        track.pitch_delay = delay
        track.pitch_cursor = cursor
        track.pitch_step = step
        track.pitch_step_counter = step_counter >> 1
        track.pitch_value = 0

    def _pitch_slide(self, track: TrackState) -> int:
        if track.pitch_envelope != 0x80 or track.pitch_data is None:
            return 0
        track.pitch_delay = (track.pitch_delay - 1) & 0xFF
        if track.pitch_delay:
            return 0
        track.pitch_delay = 1
        track.pitch_cursor = (track.pitch_cursor - 1) & 0xFF
        if track.pitch_cursor == 0:
            track.pitch_cursor = track.pitch_data[1]
            track.pitch_value = (
                track.pitch_value + signed_byte(track.pitch_step)
            ) & 0xFFFF
        track.pitch_step_counter = (track.pitch_step_counter - 1) & 0xFF
        if track.pitch_step_counter == 0:
            track.pitch_step_counter = track.pitch_data[3]
            track.pitch_step = (-signed_byte(track.pitch_step)) & 0xFF
        return track.pitch_value

    def _coordination(self, track: TrackState, command: int) -> None:
        if command == 0xE0:
            value = self._take(track)
            track.voice_control = (track.voice_control & 0x3F) | value
            self._ym(track, 0xB4, track.voice_control)
        elif command == 0xE1:
            track.frequency_offset = self._take(track)
        elif command == 0xE2:
            self._take(track)
        elif command == 0xE3:
            self._stop(track)
        elif command == 0xE4:
            track.modulation_delay = self._take(track)
            track.modulation_speed = self._take(track)
            track.modulation_step = self._take(track)
            track.modulation_steps = self._take(track)
            track.modulation_speed_reload = self._take(track)
            track.modulation_speed_counter = 1
        elif command in (0xE5, 0xED, 0xEE):
            first, second = self._take(track), self._take(track)
            if command == 0xED:
                self._ym(track, first, second)
            elif command == 0xEE:
                self._ym_global(first, second, track.index)
        elif command == 0xE6:
            track.volume = (track.volume + self._take(track)) & 0xFF
        elif command == 0xE7:
            track.flags |= 2
        elif command == 0xE8:
            track.note_fill = self._duration(track, self._take(track))
            track.note_fill_counter = track.note_fill
        elif command == 0xE9:
            value = self._take(track)
            ams_fms = self._take(track)
            self._ym_global(0x22, value, track.index)
            track.voice_control |= ams_fms
            self._ym(track, 0xB4, track.voice_control)
        elif command == 0xEA:
            low, high, timer_b = self._take(track), self._take(track), self._take(track)
            self.timer_a = low | high << 8
            self.timer_b = timer_b
            self._ym_global(0x25, self.timer_a & 3, track.index)
            self._ym_global(0x24, self.timer_a >> 2, track.index)
            self._ym_global(0x26, timer_b, track.index)
        elif command == 0xEB:
            low, high, timer_b = self._take(track), self._take(track), self._take(track)
            self.timer_a = (self.timer_a + (low | high << 8)) & 0xFFFF
            self.timer_b = (self.timer_b + timer_b) & 0xFF
        elif command == 0xEC:
            track.volume = (track.volume + self._take(track)) & 0xFF
        elif command == 0xEF:
            index = self._take(track)
            if index & 0x80:
                index = self._take(track)
            if track.kind != "psg":
                self._load_voice(track, index & 0x7F)
        elif command == 0xF0:
            track.pitch_data = tuple(self._take(track) for _ in range(4))
            track.pitch_envelope = 0x80
        elif command == 0xF1:
            first, second = self._take(track), self._take(track)
            track.pitch_envelope = first if track.kind == "psg" else second
        elif command == 0xF2:
            self._stop(track)
        elif command == 0xF3:
            self._psg(track, self._take(track) or 0xFF)
        elif command == 0xF4:
            self._take(track)
        elif command == 0xF5:
            self._take(track)
        elif command == 0xF6:
            low, high = self._take(track), self._take(track)
            track.cursor = low | high << 8
        elif command == 0xF7:
            slot = self._take(track)
            count = self._take(track)
            low, high = self._take(track), self._take(track)
            remaining = track.loops.get(slot, count) - 1
            if remaining:
                track.loops[slot] = remaining
                track.cursor = low | high << 8
            else:
                track.loops.pop(slot, None)
        elif command == 0xF8:
            low, high = self._take(track), self._take(track)
            track.stack.append(track.cursor)
            track.cursor = low | high << 8
        elif command == 0xF9:
            if not track.stack:
                raise ValueError(f"track {track.index}: sequence return with an empty stack")
            track.cursor = track.stack.pop()
        elif command == 0xFA:
            track.duration_scale = self._take(track)
        elif command == 0xFB:
            track.transpose = (track.transpose + self._take(track)) & 0xFF
        elif command == 0xFC:
            value = self._take(track)
            track.flags = track.flags | 0x20 if value == 1 else track.flags & ~0x22
        elif command == 0xFD:
            value = self._take(track)
            track.flags = track.flags | 8 if value == 1 else track.flags & ~8
        elif command == 0xFE:
            for _ in range(4):
                self._take(track)
        elif command == 0xFF:
            subcommand = self._take(track) & 7
            argument_count = 2 if subcommand == 7 else 1
            for _ in range(argument_count):
                self._take(track)
        else:
            raise ValueError(f"track {track.index}: unknown command ${command:02X}")

    def _read_event(self, track: TrackState) -> None:
        for _ in range(1024):
            value = self._take(track)
            if value >= 0xE0:
                self._coordination(track, value)
                if not track.active:
                    return
                continue

            self._close_note(track)
            self._key_off(track)
            self._update_modulation(track, new_event=True)

            if value < 0x80:
                duration = value
                if not duration:
                    raise ValueError(f"track {track.index}: zero duration at ${track.cursor - 1:04X}")
                track.saved_duration = self._duration(track, duration)
                track.duration = track.saved_duration
                return

            if value == 0x80:
                note = None
                track.flags |= 0x10
            else:
                note = (value - 0x81 + signed_byte(track.transpose)) & 0xFF
                track.frequency = self._frequency(note)
                track.flags &= ~0x10

            following = self._byte(track.cursor)
            if following < 0x80:
                track.cursor += 1
                track.saved_duration = self._duration(track, following)
            elif not track.saved_duration:
                raise ValueError(f"track {track.index}: first note omits its duration")
            track.duration = track.saved_duration
            track.note_fill_counter = track.note_fill
            event = NoteEvent(
                track.index, track.channel, self.sample, self.sample + 1,
                note, track.voice, rest=note is None,
            )
            self.notes.append(event)
            track.current_note = event
            if note is not None:
                self._start_pitch_envelope(track)
                self._write_frequency(track, self._pitch_slide(track))
                self._key_on(track)
            return
        raise ValueError(f"track {track.index}: coordination-command loop did not yield an event")

    def _update_track(self, track: TrackState) -> None:
        if not track.active:
            return
        track.duration = (track.duration - 1) & 0xFF
        if track.duration == 0:
            self._read_event(track)
        else:
            self._update_modulation(track, new_event=False)
            if track.flags & 0x10:
                return
            if track.note_fill_counter:
                track.note_fill_counter -= 1
                if track.note_fill_counter == 0:
                    self._key_off(track)
                    return
            self._write_frequency(track, self._pitch_slide(track))

    def _tracks(self, header: dict[str, Any]) -> list[TrackState]:
        tracks = []
        fm_index = 0
        psg_index = 0
        for index, record in enumerate(header["tracks"]):
            if record["type"] == "psg":
                channel = MUSIC_PSG_CHANNELS[psg_index]
                psg_index += 1
            elif header["kind"] == "music":
                channel = MUSIC_FM_CHANNELS[fm_index]
                fm_index += 1
            else:
                channel = record["channel"]
            tracks.append(TrackState(
                index=index,
                kind=record["type"],
                channel=channel,
                cursor=self.addresses[record["sequence"]],
                duration_scale=header["scale"],
                transpose=record["transpose"],
                volume=record["volume"],
                flags=record.get("flags", 0x80),
            ))
        return tracks

    def render(
        self,
        header_id: str,
        *,
        seconds: float = 30.0,
        sample_rate: int = DEFAULT_SAMPLE_RATE,
        enabled_channels: set[int] | None = None,
    ) -> RenderResult:
        if seconds <= 0 or sample_rate <= 0:
            raise ValueError("seconds and sample rate must be positive")
        try:
            header = self.headers[header_id]
        except KeyError as error:
            raise ValueError(f"unknown sound header: {header_id}") from error
        self.writes = []
        self.notes = []
        self.sample = 0
        self.timer_a = 0
        self.timer_b = 0
        self.enabled_channels = enabled_channels
        self.voice_bank = self.voices[header["voices"]]["voices"]
        tracks = self._tracks(header)
        limit = round(seconds * sample_rate)
        next_a = 0.0
        next_b = 0.0
        while self.sample < limit and any(track.active for track in tracks):
            if header["kind"] == "music":
                self.sample = min(limit, round(next_a))
                for track in tracks:
                    self._update_track(track)
                next_a += timer_a_period_samples(self.timer_a, sample_rate)
            else:
                # zStartSFX is serviced through zUpdateSFXTracks on timer B.
                # Timer A continues to update music in the real driver and
                # must not advance a standalone SFX preview a second time.
                self.sample = min(limit, round(next_b))
                for track in tracks:
                    self._update_track(track)
                next_b += timer_b_period_samples(self.timer_b or 0xE6, sample_rate)
            if self.sample == limit:
                break
        for track in tracks:
            self._close_note(track)
        total = min(limit, max((write.sample for write in self.writes), default=0) + 1)
        total = max(total, max((note.end_sample for note in self.notes), default=0), 1)
        return RenderResult(header_id, header["kind"], sample_rate, total, self.writes, self.notes)
