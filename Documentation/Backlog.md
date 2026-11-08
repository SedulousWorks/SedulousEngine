# Backlog

Open items, so they are not lost between sessions. Each says what it is, where it lives and
what is known; remove an item in the commit that resolves it.

## Decisions pending

### A script's write to a field of a struct property is lost
`LightComponent::of(e).Color.R = 0.9f` compiles and runs, and changes nothing: reflected structs
are AngelScript value types and properties `get_X`/`set_X`, so the field lands in the copy
`get_Color` returns. A whole value (`light.Color = Color(...)`) goes through the setter and works
(`EngineSurfaceScriptTests.AStructPropertyWrittenThroughAHandleReachesTheComponent`). The fix
(refuse it at compile time, or write it back through the setter) waits on the same ruling as
Raptor's fix for its handle writes, so the two engines stay alike.

### Input action sets for UI and gameplay
`ActionRuntime` has named sets with priorities, `EnableSet` / `DisableSet`, and a modal
`PushExclusiveSet` / `PopExclusiveSet` stack that latches held input across the boundary.
Scripts reach it (`Input.PushSet`, `PopSet`, `EnableSet`, as Raptor's do); the UI still reads
the pad directly (`UIInputPump.PumpGamepad`).

- B. A screen declares its set in markup (`<screen input-set="Menu">`) and the screen stack
  pushes and pops it; needs balanced notifications from `ScreenStack` and a decision on which
  run's runtime the screen tier feeds.
- C. The UI pump reads Navigate / Confirm / Back actions instead of raw pad buttons:
  rebindable UI and, later, per-device prompts. Touches the editor's play mode and the UI tests
  that fake a pad.

Suggested order: B, then C when rebinding or prompts are a goal. It also decides whether
B (circle) closes Sky Hopper's settings menu. Waiting on the Raptor port settling.

### The Beef requirement wording
`Documentation/BUILDING.md` and `AGENTS.md` say upstream Beef is sufficient. The engine needs the fork's
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

### A page save re-records a scene's prefab instances
Saving the Snowline Meadow page after painting its vegetation mask re-recorded the scene's
prefab instances (40 to 77, with member lists) though its entities (47) and components (55)
were unchanged; `scene_write` says it stores a scene as the editor saves it, so the two
disagree. Found rebuilding Snowline (f1d081d4f); the commit kept course.py's scene.

### `pie_stop` takes no `pie: "all"`
It wants an instance name, though McpGuide's wording reads as if "all" stops every Game tab.
Decide which, and make the tool or the guide match.

### Beef: an early `return` in a destructor skips the fields' cleanups
A `return` inside `~this` also skips every field's `~ delete _` (or other `~` cleanup), which
run after the body; C++ runs member destructors however the body exits. Verified on the fork's
`working` (2026-10-24) with:

```beef
class Tracked { public static int Live; public this() { Live++; } public ~this() { Live--; } }
class Holder
{
	Tracked mA = new .() ~ delete _;
	bool mEarly;
	public this(bool early) { mEarly = early; }
	public ~this() { if (mEarly) return; }
}
// delete new Holder(false): Live 0. delete new Holder(true): Live 1, mA leaked.
```

GUI.Hosting's pass renderer leaked this way under ASan; it and the three other destructors
that returned early (ValidationFixture, ProbeTextures, UnattendedDialogs) now release through
an `if` instead. Still to do: a compiler fix on a `fix/` branch of the fork (the cleanups
belong on the destructor's exit path), with a test in `IDEHelper/Tests`. Until then, never
`return` from a destructor.

### VG probes draw without a stencil reference under the Vulkan validation layer
With `VK_INSTANCE_LAYERS=VK_LAYER_KHRONOS_validation`, `Sedulous.VG.Backend.Tests`'
`FillRulesAndStencilClipsHold` and `ClipPathsNestAsIntersectionsWithAClipRectInsideOne` each
report `VUID-vkCmdDrawIndexed-None-07839` twice: a draw with a stencil-testing pipeline bound "but
the command buffer never called vkCmdSetStencilReference". `VGRenderer.Render` sets the reference
before its first draw whenever the cover pipeline exists, and every Vulkan pipeline declares the
reference dynamic, so which draws these are is not yet known. Seen at 1ae83008, before the
layers came; Raptor reports its probes clean under the same layer.

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

### Samples.WebScene.Web ships a dead shader pack
`Code/Samples/Samples.WebScene.Web/webdata/Data/Shaders/shaders.dpak` is committed and preloaded
into the sample's web build (`--preload-file webdata/Data@Data` in its BeefProj.toml). It is a
version 2 pack, which the reader has refused since version 3 (entry points; the reader now
takes 4 alone, the effect tables), and it sits at `Data/Shaders/`, where nothing looks: the
host loads `Engine/Shaders/shaders.dpak` (`ShaderSystemHost.cShaderPackPath`). It is dead
weight in the repository and in the page's download. The web build should cook its own pack
(Sedulous.Tools.ShaderPack, as an export does) into `webdata/Data/Engine/Shaders/` rather than
carry a committed one, which goes stale with every format change.

### Game scripts do not hot reload in play in editor
Game-tier scripts are not reloaded while a Game tab runs.

### The sample-project test covers PaperKid, the Shader Gallery and Masquerade only
`Integration/Sedulous.Integration.Mcp/src/SampleProjectTests.bf` reads and cooks PaperKid, the
Shader Gallery and Masquerade (CheckSampleProject) so a data-version change cannot leave them
unreadable. Sky Hopper (`Data/SampleProjects/SkyHopper`), Snowline and Lamplight have no such
guard: a case each, with their floors.

### Sprite and decal textures have no `ref` in the scene schema
`SpriteComponent.TextureAsset` and `DecalComponent.TextureAsset` are written under the key
`texture`, so the scene format reference matches no reflected field to that key and gives it no
`ref`: `component_schema` does not say the guid names a Texture (TextureAsset or
RenderTextureAsset). The key and the field name need to agree, or the reference a way to map
them.

### A list of resource references does not cross to scripts
The script surface carries a `Ref<T>` field as a `Guid` and a `List<EntityRef>` as an
`array<EntityRef>@`, but not a `List<Ref<T>>`: the element has no surface kind, and writing one
back would have to set each id and bind it. So `InstancedSkinningComponent.Clips` (and
`MeshComponent.Materials`) are not `[Scriptable]`, where Raptor's script sees `clips`.

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

### Shadow edges trace the shadow map's texels
Raptor's finding (2026-10-12, checking the toon's shadows), the same here: a directional shadow
is filtered by a fixed 3x3 PCF grid (`SampleCascade` in `Data/Engine/Shaders/lighting.hlsli`), at 1024
texels per cascade (`ShadowSystem.cShadowResolution`). Soft shading hides the grid; a hard edge
(a toon's) traces it as a wavy outline. Filter with a disk of 12 to 16 taps rotated per pixel,
and make the resolution a render setting (1024, 2048, 4096); local light shadows
(`SampleLocalShadow`) the same. Contact hardening (PCSS) after, if wanted. Changes every game's
shadows slightly: the full test lanes and a visual check on the sample games.

### A slot's own depth and shadow program
The forward pass draws each submesh with its slot's material (2026-10-15), but the depth prepass,
shadows and picking still draw a mesh (and an instanced set) whole with its first material
(`MeshRenderer.DepthLikeFor` over `md.Material`): a custom shader that moves its vertices or
cuts out, on any slot but the first, casts and occludes as if it did neither. Wanted: per
submesh depth draws where a slot's material has its own depth program, wind, or a cutout.

### No GPU test draws a reflection probe
Raptor's finding (2026-10-29, naming the probe lanes), the same here: `Sedulous.Render.Tests`
checks which records each scene gets and their values by name (`ReflectionProbeSystemTests`), and
`Integration.ShaderBlocks` that `GpuProbe` and `lighting.hlsli` agree, but nothing captures a
probe and reads back what it reflects, so the forward's probe loop is unexercised. Wanted: a
probe in `Sedulous.Render.Backend.Tests` on Vulkan, WebGPU and Direct3D 12, a metallic sphere in a
probe's box with a coloured surround the probe captures (through
`ReflectionProbeSystem.Captures`), its reflection read back at a texel; the same sphere outside
the box reflecting the sky instead; parallax on and off moving the reflection.

### The GPU particle simulation is a stub
Raptor's finding (2026-10-29), the same here: a particle system's `DesiredMode` offers CPU, GPU
and Auto, and each behaviour and initializer declares where it can run (`BehaviorSupport`), but
`CPUSimulator` is the only `ParticleSimulator`: `ParticleSystem.ResolveSimulationMode` records
the choice and nothing reads `ResolvedMode`, so every system updates on the CPU. Wanted: a
compute pass that spawns, updates and compacts each GPU system's particles in a buffer the
billboard, trail and mesh renderers draw from, the behaviours that declare GPU support given
compute versions, and the resolved mode acted on (Auto already picks GPU above 1024 particles),
on Vulkan, Direct3D 12 and WebGPU (the light clusters already run compute there,
`ClusterSystem`).

### A model's clips from other files
Raptor's finding (2026-11-05), the same here: a model import takes the skeleton and clips of its
own file only (`ModelImportSkeleton`, `ModelCook`: a skeleton from the file's first skin, a clip
per animation in it), so a character whose clips each come in a file of their own (as animation
packs ship them, each with its own copy of the skin) imports as one model, skeleton and mesh per
clip file, every clip named by its file's take. Wanted: a model's import takes animation files
beside it as its clips, bound to the model's skeleton, each named by its file (a naming rule such
as `Model@Clip`, or listed in the import's settings), root motion per clip as now; a mesh in a
clip file is ignored, and the import says so when it differs from the model's. A file of clips
with no model of its own names the skeleton it animates.

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
