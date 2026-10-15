# Contributing

The original Flicky instruction stream, its layout and its timing are the
baseline: `make verify` must keep reproducing the cartridge byte for byte.

## Local inputs

Use a legally obtained ROM whose SHA-1 is
`83d8bbf0a9b38c42a0bf492d105cc3abe9644a96` and put it in the project root as
`Flicky (UE) [!].bin`. Run `make init` once; it validates the dump, extracts the
seventeen data segments and proves the build matches.

Never add the ROM, anything under `data/`, `fbuilt.bin`, `build/` or the listing
to Git. The tracked `.gmv` movies are controller input and contain no game data.

## Source changes

Find the owning module with [`docs/source_layout.md`](docs/source_layout.md) and
its callers with [`docs/subsystems.md`](docs/subsystems.md). Keep the include
order in `src/main.s` -- it is the ROM layout, and moving a line moves code.
Name symbols with the vocabulary in [`docs/naming.md`](docs/naming.md); comments
and documentation are English. Record an uncertain reading in
[`docs/unknowns.md`](docs/unknowns.md) rather than presenting a guess as fact.

For each change:

```bash
make format
make test
```

Run `make test-full` (MAME) after changing control flow or anything
timing-sensitive. Data is edited in Retrolarium Studio
([`docs/retrolarium.md`](docs/retrolarium.md)).

`make hooks` installs Git hooks that check commits and pushes for words that
must not be published and run `make lint` and `make format-check` before each
commit.
