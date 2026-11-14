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
- Editor: Preferences' templates folder has a Browse button, which picks the folder with the
  system's folder dialog.
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
- Rendering: a Render Quality asset (File > New, under Quality/) is one quality level a game
  offers: the MSAA count and antialiasing, and a tier from Off to High for shadows, ambient
  occlusion, reflections, global illumination and bloom, with a cap on the shadow reach and the
  environment's resolution. The player starts at its export preset's level and play-in-editor at
  the project's; an Off tier turns its effect off whatever a scene asks, and no tier turns one on.
  High is each effect's full cost, as before the levels; Medium and Low cost less: fewer AO
  samples, SSR steps, SSGI rays and bloom levels, smaller shadow maps, and at Low a smaller
  environment.
- Editor: quality levels. A Render Quality asset's page draws its preview at the level as it is
  edited. The Game tab has a quality dropdown (the preset's level, or any of the project's), a
  scene viewport's Shading chip a Quality Level menu, and the Export dialog a Quality level row
  for the preset's own level. MCP: `pie_quality` reads and sets a Game tab's level.
- Player: `--quality <label>` starts a run at one of the game's quality levels, ahead of the saved
  choice, without keeping it.
- MCP: `asset_rename` renames an asset within its group as the Assets browser does, keeping its
  guid; the default scene's path follows.
- Scripting: the `RenderQuality` service, an options menu's graphics setting. `Count()` and
  `Label(index)` list the project's quality levels by label, `Current()` reads the one the game
  plays at, and `Set(label)` switches at once. The player keeps the choice in the user's settings
  and starts the next run at it; in the Game tab it picks the level in the quality dropdown.
- Project Settings: a Quality tab lists the game's quality levels and the one it starts at, and
  an export preset can start its platform at another of them (`qualityLevelId`), which its dist
  carries as the default.

### Changed

- Samples: each sample game offers Low, Medium and High quality levels; High is how it drew
  before the levels. Their Steam Deck and Web exports start at Medium, and Sky Hopper's and
  PaperKid's settings choose the graphics level.
- Rendering: the MSAA count and the antialiasing are the quality level's. The project's MSAA
  setting and a scene's or post profile's antialiasing mode are gone; a project saved before opens
  with one level, Default, at its MSAA count. The antialiasing is not carried over: an older scene
  or profile that ran TAA or FXAA says so in the log when it loads, and its level's `antialiasing`
  takes it. A scene's post settings keep how TAA and FXAA look.
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

### Fixed

- Editor and games: a floating window closed by a click inside it (its close button, a docked
  panel's) closes once the click has been handled, in the same frame; it was freed while the click
  was still being delivered to it.
- Networking: `Net.Disconnect`, `Net.StartServer` or `Net.Connect` from a `Net.On` handler no
  longer crashes the game. The handler freed the connection that was delivering its message; it is
  now closed at once and freed after the message delivery returns, and no further message from it
  is delivered.
- Scripting: `Run.LoadScene` loads the scene before it returns, and the scene becomes the level at
  the next frame's start, as `Run.LoadSceneAsync`'s does; the level it replaces is destroyed then.
  Called from the fixed step or an event handler, it started the new level inside the old one's
  step and destroyed the scene the script was running in.
- Scripting: destroying an entity or a scene from the fixed step, an event handler, a network
  message or a destroy hook waits until that step or handler is done, as it did inside an update;
  it was done at once, under the code still walking the scene, and could crash the game. The
  entity stays valid until then.
- Scripting: an event handler may subscribe and unsubscribe, itself included, and a scene may
  stop from inside one. Unsubscribing freed the handler while it ran and skipped the next one, and
  subscribing could move the handlers under the one running.
- Editor: a navigation bake that finds no geometry, or no walkable surface, leaves the zone its
  last navmesh and says so. It wrote an empty one over it.
- Editor: Export stops, and says so, when the cook before it failed an asset or could not read
  one; it exported without them. It also waits for a cook asked for during the first one.
  Exports from MCP and the command line stop as well on an asset the game uses whose source does
  not read. MCP: `asset_cook` reports `unreadable` apart from `unbuildable` (types with no
  builder, as scenes and prefabs).
- Editor: terrain and vegetation brush strokes, and a scene's edits to a settings profile, are saved
  with the page they were made on, by Save, Save All and the save when closing or exiting; only
  Save wrote them, and wrote every page's. Discard, or closing the page without saving, drops them
  and shows the asset as last saved.
- Editor: Discard Changes goes back to the page's last save. It undid every step since the page
  opened, past a save, and marked the page saved; during Simulate it froze the editor. It stops
  Simulate first now, and a page whose history no longer reaches the save reads its file again.
  Undoing back to the save marks the page saved.
- Editor: Save during Simulate writes the scene as it was when Simulate started. It wrote what the
  run had done to it.
- Editor: names and paths read from files stay where they belong. Removing an export template
  deletes the folder whose `template.xml` names it, never a path built from that id, and a template
  whose id is a path is not imported. A script, GUI document or shader made with the name of one in
  another group takes its own source file instead of writing over the first one's, and
  `asset_create` refuses a name the New dialog refuses. A glTF's sidecar whose uri is absolute or
  leaves the model's folder is not copied.
- Files: a game's save, the editor's settings and a project's export presets that do not read are
  set aside as `<file>.unreadable` before anything is written, and the log says where. They were
  replaced by an empty store or the defaults, which the next save wrote over the file.
- Files: an XML file that is not well-formed, or could not be read whole, fails to load and says
  why. It was read as empty, so whatever loaded it got its defaults and could save them over it.
- Files: every save replaces its file whole or not at all. Assets, scenes, settings, sources and
  exports were written over in place, so a crash, a power loss or a full disk mid-save could leave
  a file cut short; each write now goes to a temporary beside it, flushed to the disk, then moved
  over. The editor's MCP token file is readable by its user alone (it was readable by every account
  on the machine).
- Content: an asset's files are its own exactly. Deleting, renaming, moving or cloning `Rock`
  took the files of a `Rock.2` beside it (the name the editor gives a second `Rock`), and an export
  that pruned or stripped `Rock` dropped or packed `Rock.2`'s as well. A data stream's name may no
  longer contain a dot.
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
- Scripts: an entity, a scene, a component or a scene's service (`scene.Physics` and the like)
  kept in a script past its scene (a Game class member across a level load) reads as gone, and
  its calls do nothing; they reached the freed scene.
- Scripts: an `onDestroy` that moves entities between parents, or adds or removes components,
  no longer corrupts the scene or crashes it.
- Scripts: a coroutine that starts coroutines, or whose owner is destroyed while it runs, no
  longer crashes the game; a cancelled coroutine never runs again.
- GUI: a node can no longer be added under itself or one of its descendants, and `Popup` refuses
  content that holds its anchor; either made the tree a loop and froze the game.
- GUI: a menu or list box row a script destroys leaves the menu or list; it stayed listed, freed,
  and the next hover, key or redraw reached it. A list's selection follows its row.
