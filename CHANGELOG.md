# Changelog

What changed in SedulousEngine between releases, newest first. A change that someone using the
engine, the editor or a game made with it would notice gets a line under **Unreleased** in the
commit that makes it; a release turns Unreleased into its version and date. The steps are in
[AGENTS.md](AGENTS.md), under Releases.

## Unreleased

### Added

- Networking: `Net.SetRelevanceRadius(r)` on the host sends each player only the networked
  entities within `r` of the one it owns, for less traffic in large worlds. Off by default.
- Scripts: `onAnimationEvent(string name)` on an entity's behaviours when its animation passes one
  of its clip's events (a footstep or hit marker authored on the clip), in the order passed.
- Export: a game exports to Android, as an APK to install or an App Bundle for Google Play. An
  Android preset gives the app's id, version, name, icon and release keystore (its password asked
  for at export, or read from `ANDROID_KEYSTORE_PASSWORD`); the export builds the app with the
  Android template's Gradle project, so the exporting machine needs the Android SDK and a JDK 17
  (the editor's Preferences > Export name their folders, else `ANDROID_HOME` and `JAVA_HOME`).
  `Code/Tools/android-app.sh Sedulous.Engine.Player.Android --template` makes the template.
- Scripting: the `script_declarations` MCP tool writes the bound script API as the declarations file
  an external editor reads (`as.predefined`), so VS Code and the like complete and check a project's
  scripts.
- Editor: a right click in a script, shader or GUI page's code opens a menu of its edit
  commands (Undo, Redo, Cut, Copy, Paste, Select all, Toggle comment), each with its keys; a
  script page adds Toggle breakpoint for the line. The click moves the caret unless it lands in
  the selection.
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

- Scripting: a struct value read from an engine property is a copy, as a C# struct is:
  `light.Color.R = 0.5f` no longer compiles (it would change the copy); copy, change and write
  back (`Color c = light.Color; c.R = 0.5f; light.Color = c;`). It wrote the light.
- Scripting: compiler warnings are shown as warnings in the script page's problems, the log and
  `script_validate` (its `warnings`), never as a reason a cook failed; they were shown as errors,
  with the compiler's notes beside them.
- Editor: its windows present with two swapchain images, as a game does, a frame less between
  input and the screen; they had three.
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

- Separate inspector actions of one kind (adding two components, two Active toggles) are separate
  undo steps; Undo took them all back at once.
- Prefab Apply and Revert can be undone, each as one step, and Apply marks the scene changed.
- Script, shader and GUI code pages no longer save over a source changed outside the editor: a
  clean page reloads it, and a page with edits says so and asks for a second Save before overwriting.
- Rendering: the clustered light lists take a fraction of the GPU memory they did (about 13 MB a view
  at 1080p at most, from 50 MB, and far less for a scene of a few lights).
- Code editor: with no selection, two carets on one line cut or copy that line once, rather than
  cutting the next line too.
- DirectX 12: a scene with more than 2048 material bind groups, or more than 4096 texture views, no
  longer fails or crashes; a tearing (Immediate) swap chain survives a window resize; and barriers
  over "the rest of the mips" and buffer barriers use the right ranges and states.
- Files of 2 GiB and more read and write whole.
- Text: malformed UTF-8 (overlong forms, surrogates, values past U+10FFFF) reads as the replacement
  character rather than as the character it spelt.
- Export: a failed build's errors at the end of a long log are kept in what the editor shows
  (only the first 64 KiB of a tool's output was), and the shader cook gives up on a WebGPU tool that
  hangs instead of waiting for good.
- Editor: "Add transition" in an animation graph's node menu starts the transition, rather than
  being cancelled by the click that chose it.
- Fonts: text whose size animates no longer builds a new font for every size it passes through,
  and a size that cannot be built is not rebuilt on every frame.
- SVG: an image with a width, a height and a `viewBox` is drawn at its size (it was scaled by its
  raw coordinates); `fill-rule` is honoured and defaults to nonzero as SVG says; an out-of-range
  number no longer turns a shape into nothing.
- Vector drawing: round and bevel stroke corners draw round and bevelled, with smooth edges, rather
  than as sharp mitres.
- GUI: a box sized in percent inside a container that sizes to its content now grows that container
  when something inside it grows, rather than leaving it at its old size.
- GUI: Chinese, Japanese and Korean text wraps between its characters, keeping closing punctuation
  off the start of a line, rather than running out of its box as one long word.
- Exported games start faster: reading an asset from the game's pak no longer copies it whole into
  memory twice, and startup reads only each asset's header.
- Text settings and assets saved as XML keep a value made only of spaces (a separator, padding),
  which read back empty before.
- Content: two asset files with one identity (a file copied outside the editor) are reported by
  name, rather than one silently hiding the other.
- Cook: a source file saved again within a second of the last cook, at the same size, is cooked
  again rather than kept stale; a change to a cooked format recooks its assets. The first cook after
  updating cooks everything once.
- Resources: an asset reloaded while it was still loading keeps the reloaded version, rather than
  the load in flight putting the old one back.
- HTTP: a server's interim answer (100 Continue, 103 Early Hints) is no longer taken as the response;
  the real one after it is read.
- HTTP: a request whose header, method or URL holds a line break is refused before anything is
  sent, so a game's data can no longer write headers of its own into a request.
- Networking: two scene objects whose ids happened to clash no longer drive each other; the later
  one takes another id, the same on every player, with a warning naming both.
- Networking: changing scenes in a networked game starts replication afresh, rather than keeping
  the last scene's entity ids and what each player had been sent.
- Networking: a player who joins late no longer sees scene objects that were destroyed before they
  joined.
- Runs: events a game posted just before it stopped no longer reach the next play. A game's scenes
  are stopped and torn down while the engine's systems are still running when the player quits,
  and the app's `MaxFixedStepsPerFrame` setting now applies to scenes (it was always 4).
- Web: keys and buttons held when the page loses focus or is hidden are let go, rather than staying
  held; a mouse button released outside the game's canvas is released in the game.
- Input: unplugging a gamepad no longer renumbers the others, so each player keeps their pad; a
  pad plugged in takes the free number.
- Editor: a file dialog's answer is handled on the editor's own thread, not the dialog's.
- Input: actions read the frame's own input, not the last frame's. `WasPressed` and `WasReleased`
  in `onFixedUpdate` see each press once, whether the frame runs two fixed steps or none; a key
  tapped inside one frame counts; and no action reads pressed before the first frame.
- Scene: moving one entity no longer recomputes every transform under its root; its parent and
  siblings stay as they were.
- Vegetation: changing a layer's scatter (its density, say) in the editor or a game redraws it;
  the old scatter could stay on screen.
- Audio: a looping sound that loses its voice to a more important one comes back once a voice is
  free, instead of staying silent; when every voice is busy, a new 2D sound replaces the oldest
  of its priority instead of the one just started.
- Particles: a one-shot effect finishes once its emitters run out, and playing it again starts it
  over; a slow emitter thinned by distance still emits (at its thinned rate) instead of stopping;
  an effect's first particles no longer fly off as if the emitter had travelled from the origin.
- Animation: an animation graph trigger set while the graph crossfades fires once the fade is
  done; it was cleared before anything could test it. A trigger now stays set until a transition
  that tests it fires.
- Animation: a glTF clip with cubic-spline keys plays as authored. Its keys were read from the
  wrong elements (a key's value from a tangent) and its tangents dropped, so it played the wrong
  poses; such a clip takes the fix at its next reimport.
- Navigation: an agent told to go somewhere it cannot walk to (off the navmesh, or with no path
  there) stops and reports finished, and the new `Failed` says why; before, it stood still and a
  script waiting for it to finish waited forever. Any new order clears it.
- Physics: a world that reaches its body limit, or whose contact caches run out in a step, says so
  once in the log, naming the setting to raise; before, bodies were silently not made or passed
  through each other. Scenes share one physics worker pool instead of each starting a thread per
  core.
- Physics: a terrain takes its entity's scale (it collided at its unscaled size), and a terrain
  hole's drawn rim has collision, so the player no longer falls through ground drawn around a hole.
- Physics: moving a simulated body's entity (from a script or the editor) moves the body; editing
  a body's shape, size or surface while the game runs rebuilds it, keeping its joints; a box,
  sphere, capsule or plane collider takes its entity's scale (it collided at its unscaled size).
- Physics: characters are solid to the world. Rays, sweeps and overlaps find them, dynamic bodies
  collide with them and two characters no longer walk through each other. A ray or sweep that
  starts inside a body now passes out of it instead of hitting it at distance 0, and `RayCast` and
  `SphereCast` take an entity to pass over. A script that casts a ray at a character (a guard's
  line of sight to the player) now hits the character itself.
- Physics: a body falling out of a trigger raises `onTriggerExit`; a body that comes to rest on
  another keeps its contact instead of ending it as it falls asleep; a compound body touching
  with two of its parts begins one contact.
- Navigation: a navmesh of more than 256 tiles loads; it failed silently before. A tile with more
  polygons than its grid can address is refused with an error that says to bake smaller tiles.
- Rendering: in a split screen, ambient occlusion and TAA work on each side as they do on a
  full screen; one side's occlusion was misplaced and a moving camera smeared under TAA.
- Rendering: in a scene with more than 256 lights, the lights near the camera and the brightest
  are the ones drawn; before, the ones extracted last were dropped wherever they were.
- Rendering: a tall object reaching toward the sun past a shadow cascade casts its shadow
  instead of losing it.
- Editor: editing an engine shader include rebuilds the project's own shaders that include it.
- Rendering: moving the sun no longer rebakes the lighting of an HDR, cubemap or coloured sky,
  and a slowly moving sun rebakes a procedural sky every half degree, not every frame.
- Rendering: on Vulkan, a texture updated after first use keeps its new contents.
- Rendering: a camera whose target is not a render texture (an imported image, a depth texture)
  is skipped with a warning instead of failing the frame. A camera with a near plane of 0, a far
  plane below its near one or a field of view of 0, and a spot light whose inner cone is wider
  than its outer one, draw clamped to sensible values instead of breaking the view.
- Rendering: a material with an unset cube texture slot gets a white cube instead of a flat
  texture its layout refuses.
- Rendering: a frame that draws more than eight views (cameras, render textures, editor
  previews) draws each with its own inputs. The ninth view shared the first's tone map, FXAA,
  sky and debug slots, its TAA, SSR, SSGI and exposure history, and its clustered lights, so one
  view could show another's image or ghost with its history.
- Rendering: a reflection probe captured in a scene with few meshes bakes them on every face;
  past the first face they drew nothing.
- Tools: `Sedulous.Tools.Cook` exits 1 when any cook fails; it exited with the failure count,
  which a shell reads modulo 256, so 256 failures read as success.
- Editor: a read-only code page no longer changes on Undo, Redo, Move lines or Duplicate lines;
  the curve editor no longer hangs on a flat curve at a large value; a value past a narrow integer
  field's range is clamped (300 into a uint8 was 44); an export no longer packs scenes a failed
  export left behind; a drag between windows over a node the other window removes no longer
  crashes.
- Games: a screen handler that pops screens while the stack settles no longer reads freed
  screens.
- Web: games draw in Safari and in every browser on iPhone and iPad. Their shaders wrote a very
  large number in full digits, which WebKit's WebGPU refused, so the screen stayed black while the
  game and its sound ran; the cook writes such numbers with an exponent.
- Rendering: the first frame a scene shows its particles draws them; it drew none and logged a
  full particle ring.
- Web: a game with a render size of its own (Sky Hopper, PaperKid) takes taps on phones and
  tablets. Its buttons answered a mouse but not a finger, since the browser shell, unlike the
  native ones, did not give the finger to the mouse; a quick tap or click within one frame also
  counts now.
- Scripting (AngelScript): a script that allocates past its heap budget (512 MB) fails its call with
  "Out of memory"; it took the machine's memory. The budget is one for the whole process.
- Scripting: reloading a behaviour script while the game runs no longer keeps every earlier
  version loaded until the play ends; one goes once nothing made from it is still running.
- Scripting (AngelScript): `#include` works: it resolves against the including file, inside the
  project's sources; editing an included file recooks the scripts that include it; an error or a
  breakpoint in one names that file; and a behaviour loaded in a run includes them as the cook
  did. An `#include` failed everywhere.
- Scripting: a behaviour script that fails to load no longer stops every behaviour loaded after it
  in the same play, and each new behaviour class loads alone rather than recompiling every class
  loaded before it.
- Scripting (AngelScript): a breakpoint inside a coroutine stops there; coroutines ran past every
  breakpoint.
- Scripting (AngelScript): an engine method of more than 16 parameters is not offered to scripts,
  and the log says so; it was offered and called reading past its arguments.
- Scripting: a runtime error's report includes the script call stack.
- Editor: a script page opens at once and checks an edit without a pause; each check made and
  bound a new script engine, about half a second, before compiling for a few milliseconds.
- Editor: in a script page, Return, Backspace, Delete, the arrow keys and the code editor's other
  keys work; the page took typed text and Tab and nothing else.
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
- VG: drawing past the 128 layers a batch holds logs a warning, once; those layers drew as plain
  opacity, losing their blend, blur and filters, without a word.
- GUI: a widget made at the address of a destroyed one styled outside any GUI starts with its own
  style; it took the old widget's cached style and transitioned from it.
- GUI: an event handler that removes its own node (the last reference to it) no longer leaves
  the dispatch reading freed memory: wheel, pointer move and press keep their nodes alive to the
  end, and a node's own listeners keep it alive while they run.
- GUI: a declaration whose `var()` references expand past 64 KB is left out, as a cycle is;
  variables that each name the one before twice expanded a short sheet to megabytes.
- GUI: a selector whose `:not()`, `:is()` or `:where()` nest more than 32 deep matches nothing
  instead of overflowing the stack, and an `:nth-child()` number too large for 32 bits is invalid
  instead of wrapping to a small one.
- GUI: a style sheet with `@media` nested more than 16 deep skips the deeper blocks with a warning
  instead of overflowing the stack, and a stray `}` is skipped with a warning; the rules after it
  were dropped.
- GUI: a grid item placed on a row line past the grid's rows widens the rows instead of hanging
  the layout (in a column flow) or writing past the grid's cells, and a grid line or span above
  1000 is taken as 1000 instead of allocating that many tracks.
- SVG: a path with a number after `Z` is an error instead of hanging the load; a self-closing
  element (`<g/>`) no longer swallows the elements after it as its children; groups nested more
  than 128 deep fail the load instead of overflowing the stack.
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
- Networking: the WebSocket gateway closes a connection that has not upgraded within 10 s or an
  upgraded one silent for 30 s, closes a browser's connection when the game drops that player,
  and reports every client it loses.
- HTTP: a redirect to another origin no longer carries the request's Authorization,
  Proxy-Authorization or Cookie headers.
- Scripting: a call into script that runs longer than its budget (5 s by default) is stopped with
  an error that fails that call, not the game; a script loop that never ended used to hang it.
  Recursion that never ends fails its call at 20000 nested calls. Global variable initializers
  run when the game loads the script, under the budget, and no longer during the cook: a
  faulting initializer fails the load, not the cook.
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
- GUI: a field that moves the focus elsewhere when it loses it (a validation on blur) no longer
  leaves the container it was moving into styled as holding the focus.
- Editor: a Play whose default scene does not load undoes its start as Stop does; the debugger,
  breakpoint sync and hover values stayed wired to the Game tab, and reached it after it closed.
- Animation: a skinned mesh whose animator is removed, or no longer names it, draws in its bind
  pose; it drew from the animator's freed matrices.
- Rendering: an instanced mesh set restored by an undo or a reload draws its restored instances;
  it drew the ones it held before, and read past them when it had fewer.
- Physics: a kinematic body over a mesh, plane or heightfield shape, simulated as static (as the
  log says), is no longer moved as a kinematic one, which crashed the game when its entity moved.
- Scripts: `Component::removeFrom(entity)` during a frame takes the component away at once for
  every lookup (`of`, `removeFrom` again) and frees it, its body or voice with it, at the end of
  that step, so the systems walking those components never see it move. `addTo` before then gives
  it back as it was.
- Core: a frame of infinite or enormous length (a clock gone wrong, a long debugger pause) runs at
  most the fixed step's cap and goes on; the fixed-step loop never ended.
- Rendering: meshes that share a mesh and their first material but differ in another slot's draw
  each with their own; drawn as one batch, they all took the first one's.
- Rendering: an animated and a still copy of one mesh, side by side, each draw as they are; batched
  together, the still ones were drawn with the animated one's skinning, or the animated ones
  without it.
- Rendering: a double-sided material (foliage cards, a sail, a flag) casts its shadow from both
  sides, and a material that culls front faces casts from its back; shadows always came from the
  front faces.
- Rendering: a shader that fails to build is tried again when it is edited, not on every draw
  (each draw of a broken material rebuilt it, every frame), and pipelines a shader reload replaces
  are freed once the frames using them are done; they were kept until the renderer closed.
- Rendering: the GPU copies of meshes that are gone (a level unloaded, an asset reimported) are
  freed and their space reused; every mesh ever drawn stayed in GPU memory until the renderer
  closed. A mesh rebuilt in place (`StaticMesh.ContentChanged`) uploads again.
- Rendering: a reflection probe added after sixteen others had ever existed (probes deleted and
  added in the editor, levels loaded one after another) now reflects; its slot was never handed
  back, so it was dropped.
- Rendering: two scenes drawn at once (two editor pages, a page and its play) no longer share
  an instanced mesh's instances or a reflection probe's cube when their entities have the same
  handle.
- Rendering: an animated character is culled where its pose puts it, not where its bind pose
  stands: a character walked or reaching away from its bind pose no longer vanishes at the edge of
  the view.
- Rendering: a Static spot or point light keeps its shadow while something moves near another
  Static light; the cached shadows of every other Static light were wiped whenever one of them
  redrew.
- Rendering: the sky's diffuse light is right along world z: one of its nine terms was three
  times too strong, so a sky brighter to the front or back over- or under-lit surfaces facing
  those ways. Scenes lit by such a sky look a little different.
- Rendering: lights no longer go missing, or come from another scene, when a scene has many
  lights or several scenes are drawn at once (editor pages side by side, a page and its play).
- Rendering: sprites and particles no longer vanish in a busy frame: past the eighth run of
  transparent draws in a frame, or the eighth view, the rest drew nothing.
- Terrain: a frame with many terrains or chunks draws all of them from the next frame on; the
  ones past the renderer's first budget never drew.
- GUI and vector graphics: a complex shape (concave, or several contours) filled inside a clip
  path no longer paints outside the clip; and a draw list whose indices outgrow the frame's
  buffers draws from the next frame instead of never.
- Rendering and GUI: a fixed per-frame budget that runs out (a renderer's ring, the vector
  renderer's uniform slots) now logs a warning the first time instead of dropping draws silently.
- Networking: a server makes a peer only for a client that answers its challenge, and holds at
  most `MaxPeers` (64 by default); data packets carry the session token. The wire format changed:
  a game built before this cannot connect to one built after.
- Networking: before the first round trip is measured, an unacknowledged message is resent after
  200 ms, then twice as long each time, instead of every 20 ms.
- Networking: at most 1024 reliable messages are in flight to a peer, and a receiver buffers none
  further ahead; a peer that leaves more than `MaxQueuedReliable` (16384) unacknowledged is
  disconnected.
- Networking: a received message is held to `MaxMessageBytes` as a sent one is; a peer's fragments
  past it are dropped instead of reassembled without limit.
- Networking: an empty UDP datagram no longer stops the frame's reads, which let a stream of them
  hold back every real packet.
- Networking: a length in a packet is checked against what the packet holds before anything is
  allocated for it; a crafted replication record could make a client allocate 4 GB.
- Networking: an HTTP, WebSocket or TLS connection whose peer stops reading is closed once 8 MB
  waits unsent, instead of the sender buffering without limit.
- Models: a glTF file that fails validation (an accessor or buffer view past its buffer) fails
  to import instead of being read past its buffers' ends.
- Fonts: a truncated or damaged font file is refused instead of read past its end (a crafted one
  could crash the game or editor that loaded it).
- XML: a document nested more than 512 elements deep is refused (`NestingTooDeep`) instead of
  overflowing the stack of whatever read it.
- Rendering: a window whose swapchain goes out of date without changing size (a surface lost, a
  display change) is made again instead of staying blank, and a failed rebuild keeps the old
  swapchain and is retried, where before the next frame read freed semaphores.
- Rendering (Vulkan): a frame is presented only after it is drawn. The swapchain's wait and signal
  went to whichever submit came first after the acquire, and an offscreen pass could take them.
  `IQueue.SubmitFrame` names the swapchain the frame renders; code that submits its own frames
  (the RHI samples) calls it in place of the fenced `Submit`.
