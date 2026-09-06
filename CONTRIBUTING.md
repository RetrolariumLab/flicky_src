# Contributing

This repository treats the original Flicky instruction stream, its layout and
its timing as the artifact being preserved. Read
[`docs/roadmap.md`](docs/roadmap.md) before changing anything that affects the
assembled bytes.

## Local inputs

Use a legally obtained ROM whose SHA-1 is
`83d8bbf0a9b38c42a0bf492d105cc3abe9644a96` and put it in the project root as
`Flicky (UE) [!].bin`. Run `make init` once; it validates the dump, extracts the
seventeen data segments and proves the build matches.

Never add the ROM, anything under `data/`, `fbuilt.bin`, `build/main.p` or the
listing to Git. The tracked `.gmv` movies are controller input and contain no
game data.

## Source changes

Find the owning module with [`docs/source_layout.md`](docs/source_layout.md) and
its callers with [`docs/subsystems.md`](docs/subsystems.md). Keep the include
order in `src/main.s` -- it is the ROM layout, and moving a line moves code.

Name symbols with the vocabulary in [`docs/naming.md`](docs/naming.md) and let
`make format` handle the layout. Comments and documentation are English; the
style checker rejects non-ASCII in `.s` and `.inc` files and asks for a manual
rewrite rather than translating anything itself.

For each coherent change:

```bash
make format
make lint
make verify
```

`make format` only normalizes whitespace, label layout and directive case.
Names, comments, contracts and data are a review responsibility.

## When you are not sure

Do not guess. A neutral name plus an entry in
[`docs/unknowns.md`](docs/unknowns.md) is worth more than a confident wrong
name, because the confident one stops the next person from looking. Tag the
source location with the matching evidence tag; `make lint` checks that the tag
and the entry point at each other.

If you resolve an entry, replace its **Experiment** with a **Resolution** and
keep the evidence history. Do not delete entries.

## Data changes

Read [`docs/data_formats.md`](docs/data_formats.md) before touching a packed
format. Extraction is governed by `assets/manifest.json`: a segment's boundaries
and SHA-1 live there, and `make split` is the only command allowed to overwrite
`data/`. Adding a new extracted segment means proving its boundaries, recording
its checksum and keeping the rebuild byte-identical.

## The gate

`make verify` is the permanent gate and is not negotiable. A change that moves
a byte is wrong unless the whole point of the change is to correct the
reconstruction -- and then the commit message has to say which bytes moved and
why the new ones are right.

Weakening the gate, comparing against a previous build instead of the dump, or
skipping it because "it is only a comment" are not acceptable shortcuts. That
last one is how the checksum verification stayed disabled for as long as it did.

## Before proposing a change

```bash
make lint
make verify
```

`make release-check` runs those plus the data round trips, the unit tests, the
runtime evidence and the release audit. It is the full gate and it is slow --
the runtime layer replays 67,000 frames -- so run the two above while working
and the whole gate before proposing.

## Commit messages

The project follows the shared release contract's rules, because the history is
part of the evidence: a reader tracing why a byte moved has only the commit that
moved it.

- **English, title and body.** The documentation language is a separate choice;
  commit messages are not.
- **The title says what was completed**, and does not end with a full stop.
  `Fix`, `Update`, `Changes` and `WIP` say nothing and are not accepted.
- **Two or three substantial paragraphs** after a blank line: what changed and
  which subsystems it touched; why, and which contracts or evidence it adds or
  preserves; and for a release commit, which aggregate gates passed and what the
  release does and does not cover.
- **The body describes the actual diff.** Do not write `Complete Source
  Reconstruction X.Y` before the manifest, the documentation and the full gate
  are all ready.
- **One commit, one comprehensible task.** A mechanical move may be combined
  with the import or path fixes it requires, when splitting them would leave the
  tree broken in between.
- **Attribution is truthful.** A trailer naming a tool goes on a commit that
  tool actually helped prepare, and nowhere else.

History is only rewritten before it is published, never in place on `main`, and
never without agreeing the new shape first. The same applies to the release tag:
it moves only while it is unpublished, and a published tag is corrected by a new
version rather than by moving it.
