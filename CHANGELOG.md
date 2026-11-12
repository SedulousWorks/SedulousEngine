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

### Changed

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
