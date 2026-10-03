# Backlog

Open items, so they are not lost between sessions. Each says what it is, where it lives and
what is known; remove an item in the commit that resolves it.

## Decisions pending

### Music keeps playing after play in editor stops
Stopping a Game tab tears down the run's scenes, script and input but not its audio: music
plays on the audio engine's single music slot, not in a scene, so it outlives the run.

- The script `Audio` service is ONE object for every run (the embedded runtime's
  `DefaultApplication.mAudioFacade`, installed into every script runtime), unlike `Input`, which
  each `GameInstance` makes and installs on its own run host.
- Music is one slot (`AudioEngine.mMusicVoice`): two PIE runs already fight over it, the second
  run's `PlayMusic` replacing the first's.
- Stopping the music in `GameEditorPageRun.Stop()` was tried and reverted: it would cut another
  run's music.

Options:
1. A per-run `Audio` service, as `Input` is: it records the voices it started and stops them
   at teardown. Music stays the engine's one slot. (Recommended.)
2. Option 1, and the service plays music as its own looping voice on the Music bus, so each run
   has independent music.
3. The shared service remembers which run started the current music and stops only its own.

Related, unchecked: whether a paused run's music keeps playing. An owned service could pause it
with the run.

### Input action sets for UI and gameplay
`ActionRuntime` already has named sets with priorities, `EnableSet` / `DisableSet`, and a modal
`PushExclusiveSet` / `PopExclusiveSet` stack that latches held input across the boundary. None
of it is reachable from scripts, and the UI reads the pad directly (`UIInputPump.PumpGamepad`).

- A. Scripts push and pop sets (`InputFacade` forwards to the run's runtime). A game's "Menu"
  set silences gameplay under menus and gives B / Escape a "Back" action.
- B. A screen declares its set in markup (`<screen input-set="Menu">`) and the screen stack
  pushes and pops it; needs balanced notifications from `ScreenStack` and a decision on which
  run's runtime the screen tier feeds.
- C. The UI pump reads Navigate / Confirm / Back actions instead of raw pad buttons:
  rebindable UI and, later, per-device prompts. Touches the editor's play mode and the UI tests
  that fake a pad.

Suggested order: A, then B, then C when rebinding or prompts are a goal. It also decides whether
B (circle) closes Sky Hopper's settings menu. Waiting on the Raptor port settling.

### Project themes replace the built-in theme
`UISubsystem.SetDefaultTheme` parses ONLY the project's sheet and installs it: anything it does
not style falls back to each control's own drawing colours, not to `GameTheme`. A small override
(buttons only) means restyling everything, or starting with `@import` of a base sheet. Layering
the project's sheet over `GameTheme` would make overrides easy but changes what existing themes
resolve to.

### The Beef requirement wording
The README and `AGENTS.md` say upstream Beef is sufficient. The engine needs the fork's
`working` branch again: `fix/interface-slots-past-incomplete-base` (a type's interfaces were
slotted over `IHashable` when a base further up was mid rebuild; `PhysicsWorld` static geometry
depends on it) is pushed and awaiting its upstream PR. Reword once it merges, or say so now.

### `vnext` and `polish`
Both sit at fa11f9ab, behind `master`, which is the default branch again. Bring them along with
`master`, or retire them.

### Rebuild the Jolt Windows binaries
`jcb_shape_world_triangles` (added to `Dependencies/joltc-Beef/joltc_beef.cpp` for
`PhysicsWorld.AppendBodyTriangles`) is in the Linux `.so` and the wasm archives, not yet in
`dist/Debug-Win64` and `dist/Release-Win64`: run `build-native.ps1` on Windows and commit them,
or a Windows build fails to link.

## The Raptor sync

The sync from Raptor 122035b2 to 0b60c738, and the PaperKid rebuild after it, are mapped and
ordered in [RaptorSync.md](RaptorSync.md).

## Engine findings

### Script references are invisible to `asset_uses` and `asset_delete`
`ScriptClassAssetBuilder` reports no dependencies, so an asset a script names
(`Guid::FromString("...")`, a sound, a scene, a document) has no edge to the script: `asset_uses`
misses it and `asset_delete` deletes it without refusing. Fix: report the guids a script's
source names as its dependencies.

### An unexplained segfault in the MCP integration tests
One `Sedulous.Integration.Mcp` run printed `Segmentation fault` between
`ExportFlowTests.ProjectExportMakesARealDistFromAnAuthoredProject` and the next test; every test
passed, and it did not recur. Cause unknown.

### `DxcCreateInstance failed` at player startup
A player without DXC (the Steam Deck build, any export) logs it twice while using its shader
pack, which is expected but reads like an error. Quieten it when a pack is in use.

### The Linux desktop preset picks the Steam Deck template
A preset that names no template resolves by platform and config, and the installed
`sedulous-steamdeck-release-*` template ranks first for Linux64 Release. Works (the Deck player
is a portable Linux player) but is surprising; consider ranking or naming.

### Game scripts do not hot reload in play in editor
Game-tier scripts are not reloaded while a Game tab runs.

### The sample-project test covers PaperKid only
`Integration/Sedulous.Integration.Mcp/src/SampleProjectTests.bf` reads and cooks PaperKid so a
data-version change cannot leave it unreadable. Sky Hopper (`Data/SampleProjects/PlatformerGame`)
has no such guard.

### Beef folds a constant `&*` of uint64 constants wrongly
`(FnvOffsetBasis ^ (uint64)'a') &* FnvPrime`, all constants, evaluates to 0xe08601ec8c; the
same steps on a variable give 0xaf63dc4c8601ec8c (FNV-1a of "a"). The folded value is the low 32
bits of the left operand times the prime, cut to 40 bits. Nothing in the engine folds one (the
comptime `TypeId` runs `TypeIdOf` in the interpreter and is tested against it). Reduce to a
repro and report it upstream.

## Documentation and content

- Port Raptor's documentation (`Documentation/Systems`, `Guides`, `GETTING-STARTED.md`) doc by
  doc, every type, path and behaviour checked against this engine; export, templates and the
  Steam Deck first.
- Write a `CONTRIBUTING.md`; v0's describes the old engine.
- Finish PaperKid (`Data/SampleProjects/PaperKid`).

## Housekeeping

- The Raptor sync marker is still 122035b2: Raptor 9ac175be (thin physics boxes) was ported on
  its own, so the next full sync starts from the marker and skips it.
