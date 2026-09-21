# What changed from v0

`v0` is the first version of the engine. This version keeps the same layering (Foundation,
Engine, Editor, Samples, Tools) and mostly the same module names, but every module was
rewritten. Projects and content made with v0 will not load.

## Content and resources

The resource system in v0 was a single database shared by the runtime and the editor. The
same asset files the editor edited were the files the runtime loaded. There was no
optimized format for shipping, and a runtime asset could carry data that only meant
something to the editor, like the node positions in a node graph asset.

This version introduces the content database, and separates edit time assets from runtime
resources. A project has two databases: a source database holding the assets you edit, and
a cooked database holding the products the runtime loads. Both are trees of serializable
objects looked up by guid, with large data (pixels, samples, vertices) in a sidecar stream
next to its object. The database does not know about file formats; the serializer it is
given decides, so the editor reads and writes XML while a shipped build reads binary.
Editor only data stays in the source asset and never reaches the runtime.

Assets in v0 were OpenDDL, with serializers written by hand for every type. Now source
assets are XML, and `[Serializable]` generates the read and write code from a type's fields
at compile time; the per project registry of serializable types is generated the same way.
Field order defines the binary layout.

The runtime resource manager loads by guid, synchronously or asynchronously, through a
factory per resource type. When the cook rebuilds an asset, the new product replaces the
old one in place and the old one is kept alive for a few frames in case work in flight still
references it.

## Pipeline, tools and agents

In v0 importing happened inside the editor, and there was no cook step because the runtime
read the edited assets directly. The pipeline is now its own tier: importers (glTF, FBX,
OBJ, images, audio, fonts), a cook per asset type that turns a source asset into its runtime
product, dependency tracking, and an export that packages a project for the desktop player
or the web. The editor, the command line tools (`Cook`, `Export`, `ShaderPack`) and the MCP
host all run the same builders, so a project can be built without opening the editor.

Two things the pipeline does that v0 could not: build LOD chains for meshes, and compress
textures (BC7 and ASTC, chosen by what the target can decode).

The MCP host (`Sedulous.Tools.Mcp`) is new. It lets an AI agent work on a project headlessly:
query the engine's reflection and the script API, import and cook assets, read, write and
validate scenes, run health checks, and read the shipping docs. The `.claude/` skill in the
repo is the recipe for launching it.

## Scripting

v0 had no scripting; gameplay was written in Beef against the engine. This version adds
AngelScript, with bindings generated at compile time from everything marked `[Scriptable]`,
so the script API cannot drift from the engine API. Scripts attach to entities as
behaviours with start, enable and destroy hooks, can run as coroutines that `wait` on the
game clock, and can hand callbacks to native code. Each domain exposes a facade. Script
assets go through the pipeline like everything else, the editor has a script page with
breakpoints, and the MCP `script_api` tool describes the surface to an agent.

## Rendering

The renderer was already driven by a render graph in v0, with parallel extraction and
sorted draws, cascaded and local shadows, GPU prefiltered reflection probes, IBL, mesh
LODs and instancing. Its internals were rewritten but the shape is the same. What you
will notice:

- The post stack had AO, bloom, TAA, tonemap and FXAA. It now also has SSR, SSGI
  (experimental), MSAA, auto exposure and colour grading, and can be configured per view.
- Terrain rendering.
- v0 compiled shaders on first run and cached them. Shaders are now cooked into per backend
  packs by the pipeline, and cross compiled to WGSL for the web.
- Depth is reverse-Z throughout, defined in one place and checked by pixel level tests on
  each backend.
- A WebGPU backend beside Vulkan and D3D12.

## UI

The UI framework is the same design, evolved.

In v0 layout went through `LayoutParams` objects attached to views, and an imposed style
cost an allocation per view. This version has a proper box model: margin, border and
padding go through one metrics type, layout style fields know whether they were explicitly
set, and lengths are sums of units so `calc(100% - 20dp)` is just a value. `LayoutParams`
and the extra allocation are gone.

The style cascade now supports ancestor and compound selectors, style variables with
fallbacks, transitions with easing, box shadows, and image sets in themes. The
built in themes are real `.sss` files embedded at compile time, where v0 built them in code.

Gamepad navigation now goes through the shell bridge. The toolkit gained a code editor
(lexers, highlighting, completion, find), a timeline and dopesheet, toasts, floating
panels, a split pane, a bottom dock, and vector and quaternion fields; the node graph
canvas, toolbar and colour pickers carried over. A new game kit provides menus, screens,
bars, button prompts, tickers and toasts for in game UI, and world space UI grew from
billboards to canvases and panels.

The vector graphics layer keeps its gradients and SVG loading, and its path cache is now
keyed by path id rather than by pointer, which could serve a dead path's geometry to a new
one at the same address.

## Fonts

v0 rasterised TrueType glyphs at runtime into a baked coverage atlas. This version adds
MSDF text rendering: distance field atlases baked by the pipeline with msdfgen, alongside
the coverage atlases, each baker in its own module. The font library was reorganised around
a parser interface (`TrueType`), atlas bakers and caches, scaled views and a font manager.

## Physics, audio, navigation, animation

v0 put an `IPhysicsWorld` interface in front of Jolt. That was code for a backend that did
not exist, so this version uses Jolt directly; the abstraction may return if a second
backend (box3d) lands.

v0 had its own audio mixer over SDL3. Audio now runs on miniaudio: four fixed buses,
custom named buses arranged in a tree, an effect chain per bus (low pass, high pass, delay,
reverb), spatial voices, sound cues with variants, and user volume settings layered over
the project's bus layout.

v0 built navmeshes at runtime and kept a tile cache for dynamic obstacles. Navigation
meshes are now baked per zone by the pipeline: a zone component carries the bake settings,
the cook produces the tiled mesh, and the runtime loads it and runs the crowd on it.
Intermediate bake stages can be captured for debugging. The dynamic obstacle tile cache
has not been brought over yet.

Animation graphs, property animation and their editor pages existed in v0 and carried
over; skinning gained instanced skinning with shared pose palettes.

## Networking

v0's networking stopped at sockets, buffers and an HTTP layer. This version builds a game
layer above them: sessions with peers and roles over a datagram interface, reliability with
acks and resends, an RPC table, state replication of `[Replicated]` fields with delta
encoding and interpolation, a networked transform component, a simulated network with
configurable conditions for tests, a loopback, and a websocket carrier so browser clients
can join the same session. The HTTP client and server now support server sent events.

## Terrain, splines and the web

None of these existed in v0. Terrain: heightfields stored as sidecar streams, splat
weights over a base layer and a paint palette, sculpt and paint tools in the editor, and
its own render path. Splines, with a viewport tool for editing them. The web: a WebGPU
backend, a wasm build through emscripten, browser samples, and a web player produced by
the export.

## Editor

v0's editor was one project holding every page. It is now a core plus one module per
domain, and each module registers its own pages, tools, inspectors and asset creators, so a
domain can be added or left out without touching the rest. Thumbnails, the asset picker,
play in editor, the project manager and project settings all existed in v0 and carried
over. New:

- Inspectors are generated at compile time from the component types, including computed
  properties, conditional visibility and ranges, where v0 described properties at runtime.
- A viewport tool framework: select and transform, terrain sculpt and paint, and spline
  editing are all tools on the same footing.
- The asset browser sits on top of the cook: cook status badges, favourites, and import
  through the pipeline.
- Pages for audio bus layouts, input maps, collision shapes, heightfields, terrain,
  scripts, UI documents and UI themes, and a generic page for any asset without one.
- Export presets and templates, and the editor's own MCP tools.

## Testing and platforms

Every module has a test project next to it, and `Integration/` holds tests that cross
modules: 878 test files, up from 213 in v0. Linux is a development platform alongside
Windows, with AddressSanitizer based leak checking and a live leak probe in the editor.
Executables locate the engine's data by walking up to a `.dataroot` marker instead of
using baked in paths.

## Coming back

GPU entity picking through an id buffer is planned; for now the select tool picks by
distance to the entity origin. Some other things from v0, such as the manual and the sample
projects, will return as this branch settles.
