# Contributing

The original Flicky instruction stream, its layout and its timing are the
baseline: `make verify` must keep reproducing the cartridge byte for byte.

## Local inputs

Use a legally obtained ROM (`assets/manifest.json` gives its name and hash) and
put it in the project root as `Flicky (UE) [!].bin`. Run `make split` once; it checks the dump and cuts out the
seventeen data segments (`rltool assets` by `assets/manifest.json`).

Never add the ROM, anything under `data/` or `build/` to Git. The tracked
movies are controller input and contain no game data.

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
must not be published and run `make lint` before each commit.
