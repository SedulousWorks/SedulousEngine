# Backlog

Open items, so they are not lost between sessions. Each says what it is, where it lives and
what is known; remove an item in the commit that resolves it.

## Decisions pending

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

The sync from Raptor 0b60c738 to 8be4094d, and the PaperKid rebuild after it, are done; their
map is [RaptorSync.md](RaptorSync.md).

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

### Sprite and decal textures have no `ref` in the scene schema
`SpriteComponent.TextureAsset` and `DecalComponent.TextureAsset` are written under the key
`texture`, so the scene format reference matches no reflected field to that key and gives it no
`ref`: `component_schema` does not say the guid names a Texture (TextureAsset or
RenderTextureAsset). The key and the field name need to agree, or the reference a way to map
them.

### Scripts cannot compare two guids
The script surface gives `Guid` `Nil`, `IsNil` and `FromString`, but no equality: AngelScript
refuses `a == b` ("No matching operator that takes the types 'Guid' and 'Guid'"), so a script
cannot check that an image's `Source` or an entity's asset is the one it expects.

### TAA still looks jittery
Raptor's finding (2026-10-03), the same here: with the stale history fixed, the resolve itself
leaves visible jitter on edges. The suspects: the Halton sequence's length and its scale, taken
from the target's size rather than the viewport's (`RenderFrame.bf`, `TaaJitter.HaltonJitter(
mJitterIndex, view.Width, view.Height)`), the variance clip's gamma (1.25) and blend factor
(0.97) in `taa.ps.hlsl`, the depth disocclusion reject, and whether the history wants
Catmull-Rom sampling or a sharpening pass. Measure frame to frame edge change on a static scene
before and after each change.

### Auto exposure settles visibly at the start of a scene
Raptor's finding (2026-10-03), the same here: a scene loads with the exposure where the last one
left it and adapts toward its target over a second or two, a dim and brighten every time a level
starts. `ExposurePass` keeps a history per view (`cMaxViews` slots indexed by view order) that is
valid from its first frame on, and nothing resets it on a scene load. A new scene, or a view's
first frame, should start at its target and adapt from there.

### `var()` inside a drawable's arguments draws white, silently
Raptor's finding (2026-10-03), the same here: `background: rounded-rect(var(--paper), radius=6,
border=var(--ink))` in a theme draws a plain white rect with no border, and nothing is logged.
A factory argument goes through `SSSParser.ParseColorArg` and `ParseColorValue`, which take hex,
a `$palette` name, a named colour, `rgb`/`rgba` and the colour functions; an `Ident` `var` falls
through to `Color.White` without consuming its tokens. `var()` resolves only as a whole property
value (`ParseVarReference`). Resolve it in factory arguments, and warn on an argument that does
not parse.

### Every new particle system has the same random seed
Raptor's finding (2026-10-03), the same here: `ParticleSystem.cDefaultSeed` is one constant, the
default of `ParticleEffect.AddSystem`, which both the particle page's Add System and the effect
creator call. Two systems in an effect spawn their particles in the same places, and only the
last drawn shows. A system added by the page or a creator should get a fresh seed.

## Documentation and content

- Port Raptor's documentation (`Documentation/Systems`, `Guides`, `GETTING-STARTED.md`) doc by
  doc, every type, path and behaviour checked against this engine; export, templates and the
  Steam Deck first.
- Write a `CONTRIBUTING.md`; v0's describes the old engine.

## Housekeeping

- The Raptor sync marker is 2a42abf0 (master): every item of [RaptorSync.md](RaptorSync.md) is
  ported (rumble, a game's save, UI tweens and SVG icons, the web page and export, Sky Hopper's
  stakes and two more levels), then PaperKid's Blender models (4fb5d7ef..405447c7) and the font
  atlas sized to its glyphs (2a42abf0). Not ported: a49bf057 (the credits name Raptor's engine;
  Sedulous names itself), e841c88a and 38f25975 (Raptor's own backlog notes; Sedulous's pie_run
  reads a behaviour's Float3 field by its path, so the second does not apply, by reading).
