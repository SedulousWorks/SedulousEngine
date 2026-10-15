# Working through the MCP server

The engine's MCP server (`engine-mcp`, the `Sedulous.Tools.Mcp` binary) is the headless
authoring surface: newline delimited JSON-RPC over stdio, the full project, asset, scene
and script workflow with the editor closed. This is the operating manual for any agent
connected to it. It is itself served as `docs://McpGuide.md`, so you can re-read it over
the wire.

## Two hosts, one surface

The headless host above is `Sedulous.Tools.Mcp`. The EDITOR serves the same engine tools over
HTTP (`engine-editor-mcp`) for the project it has open (the live one, one content database,
one writer), so an agent can work on what the user is looking at. Tell them apart by
`host_info.serverName` and `host_info.host.kind`. What differs: the stdio host has
`project_create` and `project_open` (the editor's project is the editor's), and the editor's
long tools (a cook) keep the call open until the editor's own background service finishes:
give the client a generous timeout rather than polling. The editor adds the page tools
(`page_list`, `page_open`, `page_reload`, `page_close`), the whole-window capture
(`editor_screenshot`), the action bridge (`action_list`,
`action_state`, `action_execute`: everything a user can do by menu, chord, toolbar or context
menu, over the active page, executed unattended; a dialog an action would open is closed as
cancelled and named under `suppressedDialogs`, so the action most likely did nothing: use a
dedicated tool or ask the user) and the scene page's live tools
(`selection_get`, `selection_set`, `simulate_start`, `simulate_stop`, `entity_inspect`,
`component_set`, `viewport_camera_get`, `viewport_camera_set`, `viewport_frame`, `viewport_screenshot`,
`navigation_bake`, each addressed by the page's asset guid). `viewport_camera_get` and `viewport_camera_set` read and
move the viewport's editor camera in degrees (a position, a yaw and pitch, or a `lookAt` point),
and switch it to `orthographic` (an `orthoHeight` zooms it about its focus; the height follows
the zoom in either projection); editor state only, no undo step. `viewport_frame` frames entities (by name, path or guid;
default the selection), each with everything under it, as the user's F does: the camera stands
back along its view until they fit and orbits about them, at once, so a screenshot after shows
it. `viewport_screenshot` writes what the viewport renders to a
PNG and returns its path and size: the scene with the grid, the markers, the selection's
gizmo and the tool's hint text, not the panels docked over the viewport. It brings the page to front first, since a
hidden viewport never renders. Move the camera, shoot, read the file. `editor_screenshot`
writes the whole editor window as the user sees it (panels, pages, menus, dialogs, toasts) the
same way, `window: "all"` adding each floating window beside it, for checking the editor's own
UI rather than a scene (the user's View > Screenshot Editor, F12, writes the same under
`<user-data>/screenshots`). `profiler_capture` profiles the editor's next few seconds, PIE
included (see **Performance** below). `entity_inspect` is the inspector's
view of one entity: hierarchy, transform, every component's fields with asset references as
guids and enums by name, the primary selection by default. `component_set` writes one of those
fields through the page's undo path, one labelled step per call, the page dirty after and
nothing saved. `value` takes the shape `entity_inspect` shows: numbers, booleans, strings,
guids, vectors, colours, quaternions, an enum case by name or number, an asset guid (or null)
for a reference, an entity guid (or null) for an entity reference, and for a list an array of
those: the whole list, resized to the array, in one undo step (a mesh's `Materials` as
`[guid, null, guid]`). A list of objects (foot IK's `Legs`, aim IK's `Bones`) takes an array of
objects, each naming the fields it sets as `entity_inspect` shows them, the rest at defaults:
the list is replaced whole, in one undo step. It refuses while simulating, on a read-only field,
on a structure, on a list of strings, on a list or object inside an element, and on a wrong
shape, any element's included.
`navigation_bake` bakes a zone, as the inspector's Bake Navigation button does: the static
geometry inside the zone's box (static, non-trigger rigid bodies and terrain; render meshes are
not read, so a floor or an obstacle agents should respect needs a static body, and what moves
never bakes) into the zone's Navigation Zone asset, which must be assigned first. The scene
itself is unchanged; cook for the game to see the navmesh. A `scene_write` or `prefab_write` over an asset the user has open reaches
its page at once: a clean page reloads in place, a page with unsaved edits keeps them and
warns the user. Ask before `page_reload` with `force`, which discards them.

Play in editor (PIE) is the editor's too, and it is how gameplay is tested: `simulate_start`
previews ONE scene in its page, while PIE runs the project as the player does (the default
scene, the startup script, the input map). PIE is not one game: every Game tab runs its own
instance, addressed by its `pie` id (`game-page`, the primary; `game-page-1`, ... for each new
instance), default the primary. `pie_start` cooks, opens and runs the primary (or with
`newInstance` another tab, a host and a client say) and answers once the first frame has
rendered; `pie_state` reports whether it runs, its scene, `runTime` (seconds of frames since
the start, unscaled, so it keeps going while the game pauses its scene at time scale 0, as
behind a menu), the frames rendered
and the startup script (`running`, or `faulted` with the reason);
`pie_list` shows every instance, the ones the user started too; `pie_stop` stops one (or
`all`), its tab staying open and the others running. `pie_screenshot` writes what an
instance's tab renders, the game through its own camera with its UI, as `viewport_screenshot`
does for a scene page: the pixels the tab drew, without the bars. A tab smaller than the game's
render resolution draws the game scaled down; the answer then adds `renderWidth`, `renderHeight`
and `scale`, the PNG is that scaled image (soft text in it is the scale, not the font), and
`pie_run`'s mouse positions, which are in render resolution pixels, are its pixels divided by
`scale`. With the tab's Phone toggle on, its screen is a phone held upright (720 x 1560, letterboxed
in the panel), and a game held to the other orientation (its project's, or a chosen export
preset's) is presented turned, as a phone shows it: the screenshot is portrait and the game
sideways in it, while `pie_run` still takes the game's own pixels. `pie_resolution` reads or sets
a tab's resolution dropdown and Phone toggle: an entry by its key (`project`, `export:<preset>`,
`preset:<name>`, `panel`), its label, or a size (`1280x720`); the choice is the dropdown's, kept
for the project, so every Game tab opens at it.

`pie_run` is the playtest: it plays a device-level input timeline into one running instance
for `duration` seconds of run time and answers what happened. The timeline takes keys by their
KeyCode names (`{"at": 0, "key": "D"}`, `{"at": 0.4, "key": "Space", "down": false}`), mouse
moves, buttons and the wheel (`{"at": 0, "mouseMove": [650, 253]}`, `{"at": 0.2, "mouseButton":
"Left"}`, in the game's render resolution pixels: a `pie_screenshot`'s, divided by its `scale`
when it reports one) and gamepads (`{"at": 0, "gamepad": 0, "axis":
"LeftX", "value": 1}`), and goes through the project's input map as a player's would. While it
runs, that tab ignores the real mouse and keys, the other instances keep theirs, and whatever
it holds is let go at the end. `probes` read entities (by guid, name or slash path) at field
paths (`worldPosition`, `position`, `rotation`, `scale`, `active`, or `<component>.<property>`
as `entity_inspect` names them, or `<BehaviorClass>.<field>` for a behaviour running on the
entity, private fields too, then `.x`/`.y`/`.z` or a key or an index) and game script
fields, private ones too (`{"script": "m_score"}`; an enum reads as its number), sampled `every` N seconds (0.5 by default) or at
`sampleAt` times; each row is `{t, frame, values}`, the last one at the end, and an entity
gone by then reads null. `screenshots` writes the tab at those run times. `until` ends the
run early, on a death or a win: `{"entity": "Player", "field": "worldPosition.y", "op": "<",
"value": -10}`. `endedBy` says why it stopped: `duration`, `until`, `stopped` or `timeout`. A menu
is played the same way: `pie_screenshot`, find the button, click it with a timeline. The tools
check probes and names against the running game before the run starts, so a typo fails at
once. Runs are real frames at real frame rates: a time lands within a frame of where it was
asked, so compare with tolerances, and start from `pie_start` for a run you mean to repeat. One
`pie_run` per instance at a time (a second is refused while the first plays); instances run
side by side. Over HTTP each call is its own, even two identical ones from two agents: two
`newInstance` starts open two tabs (they come to front in turn, since a hidden tab renders no
first frame), two screenshots of one tab each get their file, two `asset_import`s or
`project_export`s run side by side, and a call whose connection closes ends there (an
unfinished `pie_run` lets go of the tab's input). `entity_inspect` with `pie` (and
an `entity` by guid, name or path) reads a running game's entity outside a run, each running
behaviour's properties under `live` beside what is authored.

## First moves in a session

1. `tools/list`: read the real surface before guessing; the descriptions carry the contract,
   and each tool's `annotations` say what it does to the project: `readOnlyHint` (changes
   nothing), `destructiveHint` (overwrites what exists: the scene and prefab writes),
   `idempotentHint`.
2. `host_info`: the pid (kill a hung host by it) and the `buildStamp`. After rebuilding the
   engine, compare stamps: a stale host serves yesterday's engine.
3. `resources/list`: the curated `docs://` shipping docs (Scripting, Assets, Scenes,
   KnownIssues), the scene format reference this host generated from its own build
   (`docs://generated/SceneSchema.json` and `docs://generated/SceneExample.scene.xml`) and,
   once a project is open, every scene and prefab as `project://scene|prefab/<guid>`.

## The ground rules

- **Files are truth.** The tools read and write the project's files directly; no editor is
  involved. Do NOT run against a project an open editor is actively editing: two writers,
  one set of files.
- **Validate first writes.** `scene_write` and `prefab_write` refuse invalid content with the
  full report; a refusal is the tool working, never something to bypass. What they store is the
  scene exactly as the editor saves it (its layout and number formatting), however the XML was
  passed, so a generated file reads like a saved one and a later save in the editor changes
  only what changed.
- **Read before destructive changes.** `asset_uses` before deleting anything;
  `project_health` after: dangling references surface later, not at delete time.
- **Arguments are checked by name.** An argument a tool does not declare is refused as a
  protocol error, -32602, naming the tool, the argument and the ones it takes
  (`pie_run: no argument 'timeline' (it takes: ...)`): a misspelt argument never silently
  does nothing. The same holds at every depth, the field named by its path
  (`pie_run: no field 'probes[0].field' (it takes: entity, fields, script)`); only a map of
  names the tool resolves itself (asset_import's `options`, a behaviour's `properties`) takes
  any key, and the tool refuses one it does not know. `tools/list` gives each tool's schema.
- **Check `known_issues` before re-diagnosing** an odd symptom; if it matches a recorded
  issue, report the match and use its workaround.

## Workflows

**Project**: `project_create` makes the project with the editor's starter content, as New
Project does: Roboto as a distance-field font set as the default UI font (what an exported
game's text draws with: the engine's built-in font is not in a dist), the default sky, and a
cube, sphere and plane. Then `project_open` then `project_info`, which also reports the
settings play reads, keyed by their names: the asset settings (`defaultSceneId`,
`startupScriptId`, `defaultInputMapId`, `defaultBusLayoutId`, `defaultUiThemeId`,
`loadingDocumentId`, `defaultUiFontId`, each {guid, path} or null), `uiFontIds`, the other fonts
the game UI loads beside the default, each a family a label picks with
`font-family="<family>"`, a title face say; the display: `renderWidth`/`renderHeight`, the
resolution the game draws at, 0 for its output's size, `renderFit`, and the player's
`windowWidth`, `windowHeight`, `windowMode` and `windowResizable`; `orientation` (`Any`,
`Landscape` or `Portrait`: the shape the game is made for, presented turned a quarter on a
window of the other shape, a landscape game on a phone held upright); and `renderMsaaSamples`.
Beside them, `settingCategories` says how they group: the Project Settings dialog's tabs in
order (General, Startup, Audio, UI, Display), each with the names of its settings.
`project_settings_set` changes them by the names `project_info` reports (a name that is no
setting is refused with the list): each asset setting must name an asset of its type, `""`
clears it, `uiFontIds` takes the whole list, a choice takes one of its values by name
(`Borderless`, `IntegerScale`), and nothing changes when any of it is refused. `project_health` is
the one call soundness sweep (dangling refs, broken sources, cook state); a dirty count
alone is normal, clear it with `asset_cook`.

**Assets**: `asset_import` (an OS file into Sources/ plus a typed asset) then `asset_cook`
(incremental; `force` for a full one). When several importers claim an extension, `.png`
say, the first is used and the result lists the others under `alsoClaimableBy`; re-import
with `importer` set to choose. `options` sets the importer's toggles, the import dialog's
checkboxes by label (`{"Generate collision": true}` gives an imported model's prefab
colliders and a static body; a model also takes Textures, Materials, Animations, Generate
prefab, Generate scene, Generate LODs, Convex collision); the result lists every toggle's
value. An imported model gets its prefab, the `Prefab` asset beside its manifest, in both
hosts (and a scene with `Generate scene`). `asset_list` and `asset_info` inspect either database.
Assets that are authored rather than imported (input maps, materials, scenes, prefabs,
particle effects, animation graphs, physics, audio and UI assets, primitive meshes, script
classes) come from `asset_create`: `asset_creators` lists every creator with the `type` it
makes and the `defaultGroup` it lands in; pass `creator` by label (or `type` when one
creator makes it), optionally `name` and `group`. A name already taken in the target group
is refused rather than renamed. A data asset's content (an input map's actions and bindings,
a material, a physics material, a sound cue) is edited through its envelope:
`asset_data_read` gives the XML, and `asset_data_write` takes the edited whole back, loading it
exactly as the engine would and refusing it, unchanged, when it does not load. Enum fields are
numbers there; `type_info` on the field's type names the cases. The editor host holds the call while a cook is running and
requests the cook itself afterwards; the headless host does not, so `asset_cook` next.

**Scenes**: read `docs://generated/SceneSchema.json` once (or `component_schema` for one
component), copy from `docs://generated/SceneExample.scene.xml`, read the target with
`scene_read` (or the `project://` resource), author the XML, loop on `scene_validate` (`xml`
or `guid`; `valid` with empty `warnings` means the engine will load it), then `scene_write`.
Prefabs mirror it with the single root rule. To PLACE a prefab (an imported model's is the
`Prefab` asset beside its manifest), add an element to the scene's `prefabInstances`, in the
format's `prefabInstanceRecord` (the schema's `format` section): the prefab's guid, the root's
parent and transform, a fresh `rootLive` guid, and empty `members`, `destroyed`,
`transformOverrides` and `componentOps`; the load spawns it and a save fills those in.
`scene_validate` counts them as `prefabInstances`, apart from `entityCount`, and warns about
one whose prefab is not in the project.

To build ON AN OPEN PAGE instead, live and undoable (the editor host): `entity_create`,
`entity_update` (name, parent, active, transform), `entity_delete`, `component_add`,
`component_remove`, `prefab_spawn`, `behavior_add` and `behavior_set` (a script behaviour's
properties by name, typed by its cooked class), with `component_set` for a component's fields.
Each call is one undo step, the page dirty after and nothing saved; an entity is named by guid,
name or slash path; each answers the entity as `entity_inspect` shows it, a Script component's
`behaviors` included. The user watches the level take shape and can undo any step; `file.save`
(action_execute) keeps it. XML suits a whole level written at once, these tools an edit.

**A game's look (render profiles)**: a scene's `environment` and `postprocess` settings take
their values from the scene itself or from a shared profile, by their `source`: 0 (Scene) uses
the values stored in the scene, 1 (Profile) uses the `Environment Profile` or `Post Process
Profile` asset its `profile` names, and the scene's own values then do nothing. To give several
scenes one look, make the profile with `asset_create` (the creators of those names, under
`Profiles/`), set its values with `asset_data_read` / `asset_data_write` (its fields are the
block's, without `source` and `profile`), `asset_cook` it, and set each scene's block to `source`
1 and `profile` the profile's guid. A change to the look is then one profile edit and a cook. To
change one scene's look, edit the profile when every scene should follow, or set that scene back
to `source` 0 with its own values. In the editor, a profile opens on its own page with a preview,
and a scene's settings in profile mode show and edit the profile's values.

**Colours**: every colour is written as it is meant to look, in sRGB, the value a colour picker
and a hex code show (0.5 is `#808080`): component colours, the environment's ambient and sky, a
material's `Color` properties, particle colours, debug draw. The renderer decodes them; never
pre-convert. Brightness above white is an intensity, not a component above 1: a light's
`intensity`, or the w of a material's `ColorHdr` (its emissive). In a material's
`uniformDefaults` a colour is four floats (rgba, or rgb and the intensity).

**Scripts**: `script_api` first, the LIVE bound API per backend; never trust memorised
signatures. A member with `readOnly: true` (a network identity's `Authority`, for one) reads
and refuses assignment. `script_create` seeds a starter asset (the behavior, level or game tier), then
edit the returned source FILE, loop on `script_validate`, and `asset_cook` to make the
class attachable.

**Shaders**: a custom shader is one `.hlsl` with a `properties` block declaring its materials'
parameters, in one of two kinds. A SURFACE shader (a `// surface: lit` or `// surface: unlit`
line) holds `void Surface(SurfaceInput input, inout SurfaceOutput surface)` and optionally
`void Vertex(inout VertexInput v)` (world space; its shadows, depth and picking follow); the
engine wraps it in its forward, depth and pick programs and every variant, so it writes no
variants lines. A LOW-LEVEL shader is the whole program, `VSMain` and `PSMain` with its own
variants lines and the forward contract (`forward_vs.hlsli`, `lighting.hlsli`,
`forward_ps.hlsli`). `asset_create` with `Lit Surface Shader`, `Unlit Surface Shader` or
`Low-Level Shader` writes a starter to Sources/ and links it; edit that FILE, loop on
`shader_validate` (every program and variant, as the cook compiles them; each error with its
file, line and column, plus the parsed properties and the main program's variant flags), then
`asset_cook`. A property is a global name in the generated code: one the engine's shaders already
use (`Tint`) is an error at its line. A surface reads the camera and the clock through its input
and `Time()`, not the frame's constants. A material goes on a shader by `material_set_shader`
(the shader cooked first): laid out by the shader's properties and saved, the values whose name
and type fit kept; `pbr` or `unlit` puts it back on a built-in. Not by `asset_data_write` of its
`shaderId`, which leaves it in its old layout, warned about on every cook.

**Diagnostics**: `log_write` a marker, do the risky thing, then `log_read` with
`sinceSequence` set to the marker's sequence to see exactly what the engine said after it.

**Performance** (the editor host): `profiler_capture` with `seconds` (3 by default, at most 30)
records the editor's next frames, its pages and a running PIE game alike since they share the
process, and answers a summary: `frameMs` (min, median, max), `topScopes` (CPU scopes by total
time over the capture, nested ones counted inside their parents too) and `topGpuPasses` (render
graph passes on the GPU), each with its count, and `counterAverages` (draws, passes, pipeline
and bind group binds, GPU memory held and the budget). Set up what to measure first (`pie_start`
and play to the moment, or `viewport_camera_set` on a heavy view), capture, and compare two
captures rather than reading one number in isolation. The files stay: `path` is the
`.aeprofile` profile stream (`<user-data>/profiles/Editor-<ticks>.aeprofile`), `chromeTrace`
the same frames as Chrome trace JSON for Perfetto or chrome://tracing; hand those to the user
for a timeline. `action_execute` `profiler.record` starts and stops the editor's Profiler
tab, for the user to read; its Save writes the same two files. A debug editor is slower than an exported game, so measure the game's own
timing in its player: `<dist>/<player> --profile-capture <seconds>` writes the same two files
under `<user-data>/profiles` (F9 in any running game does too), and `--profile-overlay` shows
the profiler overlay (frame times, the longest scopes and passes, the counters) in its window
and so in its `--screenshot` (F3 toggles it). A ShippingRelease build has no profiler, and says
so.

**Screenshots**: four ways in, by what the picture is of. Each writes a PNG, by default under
`<user-data>/screenshots` (`~/.local/share/Sedulous/screenshots` on Linux), and answers its path;
read the file before trusting it, and leave the judgement of how it looks to the user.
- *The game (PIE)*, for a game's README, a store page or a playtest: `pie_start`, then
  `pie_screenshot` (`<pie>-<pid>-<n>.png`), or `pie_run` with `screenshots` at run times
  (`<pie>-<pid>-run<N>-<seconds>.png`, the seconds to two places), the pixels the Game tab drew.
  For a fixed size whatever the tab, set the game's render size first (`project_settings_set`
  `renderWidth`/`renderHeight`, 1280 x 720 for a README) and put it back after (0 / 0 when it
  was unset); the PNG is scaled to the tab when the tab is smaller (the answer's `scale`).
  Reach a screen by playing to it: a menu by a timeline (`Right`, `Return`), a level by a scene
  override (`project_settings_set` `defaultSceneId` to the level and `startupScriptId` to
  `""`, restored after, in a `finally`), a late moment by a scripted route, and a results
  screen by finishing a run. Take a few times around the moment (`[23.9, 24.3, 24.7, 25.1]`)
  and pick one. A run that finishes writes the game's save: copy the project's
  `Editor/<Game>.save.xml` aside right before, run with a test save that unlocks what the shot
  needs, and copy the user's back after; never reuse an older backup, since the user plays
  between runs.
- *A scene in the editor*: `viewport_frame` the entities (or `viewport_camera_set` a position and
  a `lookAt`), then `viewport_screenshot`, which brings the page to front since a hidden
  viewport never renders.
- *The editor itself* (panels, dialogs, menus, toasts): `editor_screenshot`
  (`editor-<pid>-<n>.png`; `window: "all"` adds each floating window), as the user's F12 (View >
  Screenshot Editor) does. For a run with no MCP, `Sedulous.Tools.Editor --project <dir>
  --screenshot <png> [--screenshot-after <s>] [--screenshot-exit]` writes the main window once it
  has drawn, and with `--screenshot-exit` quits once the file is written.
- *An exported game (the player)*, which is a different host from PIE: `<dist>/<player>
  --screenshot <png> [--screenshot-frame N | --screenshot-after S] [--screenshot-count N]
  [--screenshot-exit]` writes the window at frame N (30 by default) or after S seconds, N files
  in a row when counted (`shot-0.png`, ...: frame-to-frame changes such as TAA's jitter), and
  quits after the last. It plays no input, so it shows what the game opens on (`--scene <path>`
  opens another); its window is the project's `windowWidth` / `windowHeight`. Compare it with
  PIE's picture of the same screen: a difference is a finding.

**Export**: `project_health` first, to catch breakage before a long cook, then
`project_export` (`preset` optional; the default is the first, or the host platform preset
when the project has no `export_presets.xml`). The dist lands under `<project>/Dist` unless
`out` says otherwise: the player, its runtime libraries, `Content.pak`, `player.xml` and
`Data/Shaders/shaders.dpak`. A web export, its template and serving it: `docs://Web.md`.
A project's custom shaders ship as bytecode in the dist's shader pack, their HLSL left out unless
the preset's `includeShaderSource` is set.

`export_presets` lists the project's presets, each its fields by the names
`export_preset_set` takes, and the templates this machine can export them with;
`export_preset_set` creates, changes or removes one by `name` (only what is given changes; a
name that is no preset field is refused with the list). A preset for another device names
that device's template by `templateId`, and can override the project's render resolution and
window for it (`overridesRender` with `renderWidth`, `renderHeight` and `renderFit`;
`overridesWindow` with `windowWidth`, `windowHeight`, `windowMode` and `windowResizable`;
`overridesOrientation` with `orientation`, a phone-facing Web preset's `Landscape` say; a
choice by its value's name, `Fullscreen`). A template the machine lacks is kept, since presets travel with the
project and templates do not; the preset's `template` comes back null until one is installed.

## Per tool gotchas

- `script_validate` is a COMPILE check (`checkLevel: "compile"`): a call the language cannot
  see through, a misspelled member on a handle say, compiles and fails at runtime. Cross
  check against `script_api`.
- `shader_validate` compiles every variant, the cook's check; an error under one flag says so
  (`(under ALPHA_TEST)`). An error in an engine include names that file, not yours.
- `scene_validate` warnings mean component records of a type the engine does not know; they
  would be SKIPPED on load. Treat a warning as breakage to fix, not noise.
- `asset_uses` reports DIRECT users only; re-run on a user to walk the chain. An empty
  result plus empty `projectSettingsUses` is the "safe to touch" signal.
- `asset_delete` refuses while anything uses the asset (the same scan as `asset_uses`, and
  the refusal names the users); change those first, or pass `force` and fix the dangling
  references after. It removes the asset, not the original file an import copied under
  `Sources/`: delete that file yourself if it should go too.
- `log_read` is incremental: always pass the previous `lastSequence`; a non zero `dropped`
  means the ring overflowed and old lines are gone.
- `asset_cook` and `project_export` are long running calls (a full cook may run inside
  them); do not assume a hang before minutes have passed.
- `profiler_capture` keeps the call open for the capture plus a few frames for the GPU's
  last passes; the editor must be drawing (not minimised), or it gives up. One capture runs
  at a time, a game's F9 included.
- `project_export` failures say little in the response by design; the detail is in
  `log_read` (the Cook and Export categories).

## When something looks wrong

1. `host_info`: is the host the binary you think it is (`buildStamp`)?
2. `log_read`: what did the engine actually say?
3. `known_issues`: is it already recorded?
4. `project_health`: is the project itself broken?
Only then diagnose fresh, and write a `log_write` marker before retrying so the next read
starts at your action.
