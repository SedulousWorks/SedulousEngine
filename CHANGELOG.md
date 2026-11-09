# Changelog

What changed in SedulousEngine between releases, newest first. A change that someone using the
engine, the editor or a game made with it would notice gets a line under **Unreleased** in the
commit that makes it; a release turns Unreleased into its version and date. The steps are in
[AGENTS.md](AGENTS.md), under Releases.

## Unreleased

### Added

- Scripts: `Input.Describe(action)` names the control an action takes on the device in hand
  ("Space", or "Pad South" once a pad is picked up), as a GUI prompt shows it, for a sentence that
  tells the player what to press.
- Scripts: `Component::addTo(entity)` and `Component::removeFrom(entity)` beside
  `Component::of`, on every component a script reaches.

### Changed

- Samples: Lamplight's, Snowline's and Sky Hopper's hints and controls lists name the control on
  the device in hand (and follow a rebinding) instead of an action's name or a fixed key and pad
  button.
- Editor: a scene's Simulate runs on its own, apart from every other page: its scripts' screens
  draw over the page's viewport while it simulates and go when it stops.

### Fixed

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
