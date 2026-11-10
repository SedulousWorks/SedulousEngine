# Changelog

What changed in SedulousEngine between releases, newest first. A change that someone using the
engine, the editor or a game made with it would notice gets a line under **Unreleased** in the
commit that makes it; a release turns Unreleased into its version and date. The steps are in
[AGENTS.md](AGENTS.md), under Releases.

## Unreleased

### Added

- Rendering: the player draws its frame turned for a display that presents turned (a phone held
  away from its natural orientation), so the display has nothing to turn (pre-rotation); its scene,
  its screens and a screenshot follow the turn, and the pointer is unchanged. A window asks for it
  (`RenderWindowDesc.PreRotate`); the samples and the editor do not.
- Scripts: `scene.Animation.PlayOneShot(entity, clip)` plays a clip once over whatever an entity
  is animating (its clip or its graph), blending in and out, after which it carries on with its
  own animation; `StopOneShot` and `IsPlayingOneShot`, and `onAnimationFinished(clip)` on the
  entity's behaviours when it ends. `ClipLength(clip)` gives a clip's length, and
  `SetClip(entity, clip, blendSeconds)` crossfades instead of snapping.
- Scripts: `Input.Describe(action)` names the control an action takes on the device in hand
  ("Space", or "Pad South" once a pad is picked up), as a GUI prompt shows it, for a sentence that
  tells the player what to press.
- Scripts: `Component::addTo(entity)` and `Component::removeFrom(entity)` beside
  `Component::of`, on every component a script reaches.
- Scenes: a `SceneRef` field names a scene (a level's exit): the inspector picks a scene for it,
  a level loads by it, and a pruned export keeps the scene it names. Naming a scene never loads
  it.
- Tools: `ShaderPack --entries <dir> <output.dpak>` cooks every `.hlsl` under a folder whose
  shaders name their entry points in their own comments (`// entry: vertex VSMain`,
  `// model: 6_5`), each entry under `<file>:<entry>`, SPIR-V by default and DXIL on request.
- Export: `Sedulous.Tools.Export --content-only` stages the game's content, settings and shader
  pack with no player and no template, and `--platform <name>` exports a preset for another
  platform; an Android export's content is cooked for ASTC, which phones read.
- Runtime: an app the platform takes out of view (a phone's home button, another app in front)
  stops updating, drawing and sounding, writes what each run's game saved, and lets go of its
  window's surface, which a phone takes away; it comes back where it was. Applications and
  subsystems hear it through `OnEnterBackground` and `OnEnterForeground`.
- Input: a Back key (a phone's back button, a keyboard's or a browser's Back) that a game can bind;
  in a menu it backs out as Escape does. A Back press nothing in the game handles (no action binds
  it, no menu or screen uses it) goes to the platform: a phone puts the app in the background.
- Rendering: the game keeps inside the window's safe area, what a phone's status bar, navigation
  bar and camera cutout leave of it: its frame, its screens and its pointer are fitted there.

### Changed

- Samples: Lamplight and Masquerade smooth their edges with FXAA in place of TAA.
- Native code: the Dear ImGui plugin draws as a screen overlay of the render subsystem, over the
  game's screens, in the shared overlay pass (blending encoded colours as the screens do), and
  turned with a pre-rotated window. An application with a render subsystem no longer calls
  `ImguiSubsystem.Render`; one without (a plain `IApplication`) still does.
- Editor: an export preset's extra files are the project's: Add Files picks from the project's own
  files (not what the editor, a cook or an export writes) and names each relative to the project, so
  the preset travels with it; From Disk takes a file of the project's through the system's dialog and
  refuses one outside it.
- GUI: a command every handler passes on (`Propagate`: not mine) is unhandled: `RunCommand`
  returns false for it, and its key goes on as an unbound key does, where before any handler on
  the path took the key. A screen stack passes on a Back it pops nothing with.
- Animation: an animator's root motion mode `Script` is now `Manual` (held for game code or a
  script to apply, as `RootMotionMode::Manual` in a script); scenes that use it read as before.
- Export: an export builds the game's own player for its preset (its platform and config), with
  the game's code and the plugins it enables, instead of copying a prebuilt player; a project's
  first shipping or web export compiles the engine and takes minutes. A Windows preset exports
  on Windows.
- Export: a preset's Builder can be Steam Deck: its export builds the game's own Linux64 player
  in the Steam Deck container (podman or docker), so it runs on SteamOS and older Linux, instead
  of shipping a prebuilt Deck player.
- Export: the Export dialog names the player each preset builds ("SkyHopperPlayer,
  ShippingRelease, Linux64"), or says why it cannot be built on this machine, and Export All says
  which presets it skipped for another machine's platform.
- Editor: Project > Build Project builds the project's own editor alone; the players a game ships
  are built by its export.
- MCP: `project_build` builds the editor, or with `target` `player` the game's player for a
  platform (this machine's or Web) and config, to check it compiles without exporting.
- MCP: `project_export` reports the player's build (its state, time and first diagnostics),
  waits up to `timeoutSeconds` (default 1800) in the editor, and with `build: false` repackages
  over the last build instead of building; `export_presets` says for each preset whether this
  machine can build it, and why not, instead of listing templates.
- Prefabs: spawning a prefab no longer reads it from disk each time, and a prefab saved in the
  editor reaches the next spawn of a running game.
- Scenes: a level a game loads reads each prefab it places once, however many times it places
  it, and places the prefab as the game has it loaded (a save in the editor during Play included).
- MCP: `scene_write` and `prefab_write` given a `name` already taken in its group say what holds
  it and its guid: another type's asset (pick another name), or one of the tool's own type (pass
  its `guid` to overwrite it).
- Samples: Lamplight's, Snowline's and Sky Hopper's hints and controls lists name the control on
  the device in hand (and follow a rebinding) instead of an action's name or a fixed key and pad
  button.
- Editor: a scene's Simulate runs on its own, apart from every other page: its scripts' screens
  draw over the page's viewport while it simulates and go when it stops.
- Engine: the GUI, audio and input subsystems' facade members are named for game code, not
  scripts: `FacadeFor`, `RunFacadeCount` and `EndRunFacade` on the GUI's, `SharedFacade` on all
  three, `RunFacadeCount` and `FacadeResources` on the audio one.
- Net: a run's session stopping drops every `Net` handler a game registered.

### Fixed

- Editor: play-in-editor draws the game at the project's MSAA, as the player does; it drew at 1x.
- Rendering: a game with MSAA on keeps its scenes' post-processing in the player (auto exposure,
  AO, SSR and TAA, from the scene or its profile); the project's MSAA setting replaced them with the
  engine's defaults, so the player drew those games darker and plainer than the editor.
- Rendering: a scene's sky lighting (IBL) and its reflection probes bake once, not again in each of
  the scene's first 20 frames; on a phone those frames ran at about 4 fps, the first seconds of
  every game.
- Rendering: the MSAA resolve and TAA keep a bind group they replace until the frames in flight
  that may use it have finished; they freed it at once, which Vulkan's validation reports as a
  descriptor set freed while in use, at the start of a scene with MSAA.
- Rendering: a Vulkan surface that offers RGBA formats and no BGRA ones (an Android phone's) gets an
  sRGB swapchain and its UNORM view; it got a UNORM one, which drew every game too dark.
- Networking: a reliable message in a connection's first packet is resent when that packet is lost
  (it was dropped for good); a client can connect again from the same address, after a disconnect
  or a restart; sequenced messages are dropped when stale, never delivered out of order. Finding
  a connection no longer searches every connection, so a server's cost per player stays flat as
  players join.
- Editor: the Export dialog shows the selected preset's settings again; since the property grid
  measured its rows, the column beside the presets had shrunk to nothing.
- Rendering (Vulkan): the screen UI waits for the scene's last pass before drawing over it, where on
  a phone's GPU it could drop out of a frame and flicker. A render target reused every frame waits
  for the frame before it to finish with it, where before the two could overlap, which on a phone's
  GPU can lose the device (the picture froze while the game ran on).
- Touch: the on-screen controls appear after the first tap however quick it is, where a tap that
  landed and lifted within one slow frame went unseen.
- Vulkan: validation asked for where its layer is not installed (a machine without the Vulkan SDK,
  a phone) runs without it, with a warning, instead of failing to start.
- Vulkan: reading back what the GPU drew (a screenshot, a thumbnail, a pick, the profiler's GPU
  times) no longer comes back stale or as zeros now and then on GPUs whose readback memory is not
  coherent (Mali's among them): that memory is now made current before it is read.
- Editor: a project opened before it was cooked (a downloaded sample) shows its scenes' and
  prefabs' thumbnails whole: they wait for the cook to make what they show, where before they were
  drawn with those meshes missing and kept so, even after the cook. A thumbnail is drawn again
  when a cook remakes what it shows. Opening such a project no longer logs a warning for each
  reference still waiting for the cook; the page says once how many it waits for.
- MCP: scene_validate and scene_write no longer say a scene's records of components the host has
  no code for are dropped: a write keeps them; the warning says a cook by that host leaves them out.
- GUI: a tween of a property code set on a node (`node.Opacity = 0`, then a tween of `opacity`)
  moves it; it did nothing before, as the property was code's and the style the tween went through
  left it alone. A game's fade of a panel it made did not show.
- Export: a pruned export (a preset's `pruneToReachable`) keeps the assets a script property
  names: a behaviour's or a Level's asset value (a prefab it spawns, a clip it plays). Before, an
  asset named only there was left out and the exported game could not find it. The same for an
  asset named only by one placed prefab's override (a mesh swapped, a script property set on that
  placement).
- Scenes: each scene mints its entities' ids from a generator of its own, so two people adding
  entities to one scene on two branches no longer get the same id, which a merge would duplicate.
- Editor: New Splat Weights never writes over an asset holding its name: made again after an
  undo, it no longer zeroes the weights the undo left, and another asset of that name is kept.
- Editor: a scene, prefab or asset changed, added or deleted in the project's `Content/` outside
  the editor (a git pull, a text editor, another tool) is picked up: an open page reloads, or
  warns when it has unsaved edits, and a page whose file was deleted stays open and writes it
  back when saved; before, the editor kept the old copy and a later save overwrote the change.
- Play: a game run from its project folder spawns prefabs (a script's Spawn, a networked spawn);
  only the prefabs placed in its scenes came through.
- Physics: a destroyed entity, or a removed rigid body, character or joint, no longer leaves its
  body in the physics world (an invisible collider) until the scene ends.
- Audio: a destroyed entity's sound, or a removed audio source's, stops at once instead of playing
  on.
- Editor: importing an asset no longer freezes the editor for seconds in a large project: each
  import read every asset in the project to check one file name.
- Scripts: assigning a field of a struct-valued field, such as a light's colour
  (`light.Color.R = 0.5f`), now writes it; it landed in a copy and was lost.
- Editor: context menus open at the pointer under a UI scale other than 100%, and a tab's Move to
  opens below its tab.
- Editor: the UI scale preference shows its percentage while its slider is dragged.
- Editor: Add Component is disabled while a scene simulates, as the rest of the inspector is.
- Cook: GUI documents and style sheets no longer lose elements, or leak, when several cook at once.

### Removed

- Engine: game scripts no longer run: the Script component, a scene's level script and a project's
  startup script (the player and a Game tab start the native game alone), the scenes' script
  services, and `pie_state`'s `script` state. A game's code is native.
- Projects: the Startup script setting (Project Settings and the project's home page). A project
  that names one still opens, and the next save of its settings drops it.
- Scenes: a scene saved while scripts ran still opens, its Script components and level script
  dropped as it loads with a warning, and it saves without them.
- Assets: script files (`.as`) no longer import or cook, and an export no longer checks scripts
  against the plugins a platform enables. A project's existing script assets are kept as they
  are, listed under their old type, and no longer cooked.
- MCP: `script_api`, `script_validate`, `script_create`, `behavior_add` and `behavior_set`,
  play-in-editor's script probes (`pie_run`'s `script`, a level script's properties and a script
  behaviour's fields), `startupScriptId` in `project_info` and the script override section of the
  generated scene schema: a game's code is native.
- Editor: the script page (its code editor and API browser), the Game tab's script debugger and
  breakpoints, New Asset's script classes, and the inspector's sections for a Script component's
  behaviours and a scene's level script properties: a game's code is native.
- Scripts: the `Http` service; a game's own code sends web requests through `HttpFacade`.
- Engine: the script libraries and their AngelScript backend, with the script surfaces the GUI
  and the engine published for them.
- GUI: the verbs that took a script's function (a node's script `On`, `OnCommand`, `Bind`,
  `BindNumber` and `BindBool`, a tween's or a group's script `OnFinished` and `Call`, and
  `Gui.CaptureKey`'s script form) and the event object scripts were handed: game code passes
  delegates, as it did. A toast request is no longer reference counted: its maker owns it.
- Net: the script forms of `On`, `OnNumber`, `OnText`, `OnJoin` and `OnLeave`; game code passes
  delegates.
- GUI sandbox: its pages' and game menu's scripts no longer run, its Code page no longer checks
  the script it shows nor completes the script API, and `--menu-call` is gone.
- Editor: Edit > Export Templates, the Export dialog's template choice and its Export Templates
  button, and the templates folder in Preferences: an export builds its player, so there is no
  template to pick or install. A preset is shown by its platform's icon.
- Export: export templates and `Sedulous.Tools.Export --template list|import|create`, with the
  `SEDULOUS_TEMPLATES_DIR` variable: an export builds its player. A preset's template id is
  ignored and dropped the next time the presets are saved, and `export_preset_set` no longer takes
  `templateId`.
- Player: `--plugins`, which listed the plugins a player links for a template to record; with
  no templates nothing reads it.
