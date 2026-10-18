# Scripting

How gameplay code works in a game project. This is the workflow guide; the AUTHORITATIVE
API surface, every bound type, member and facade per backend, comes from the MCP
`script_api` tool. Always prefer it over memorised signatures.

## Backends

Scripts are AngelScript. Each script asset declares its language, so a second backend can
join later without changing the assets. The bound surface is described per backend by
`script_api`, spelled the way that language writes it.

## The three script tiers

- **Behavior**: attached to an entity through a Script component. One class per script; the
  engine fills in its `Entity self` and `Scene@ scene` fields. This is where most gameplay
  lives.
- **Level**: the per scene script, the reserved class `Level`, set on the scene's script
  settings. One instance per scene with `scene` filled in. Use it for scene wide
  orchestration: spawning, win conditions, sequencing.
- **Game**: the run's orchestrator, the reserved class `Game`, set as the project's startup
  script. It runs for the whole game run, across scene loads, and reaches the run through
  the `Run` service: `Run.LoadScene(sceneId)`, `Run.RequestExit()`, `Run.Emit(...)`.
  A debug menu can show the profiler overlay with `Run.SetProfilerOverlay(true)`;
  `Run.ProfilerAvailable()` says whether this build and app have one (never in a shipped
  build), so the menu can hide its entry. Both compile in every build.

## Lifecycle and events

Handlers dispatch **by presence**: implement only what you need.

- Behaviors and levels: `onStart()`, `onUpdate(float dt)`, `onFixedUpdate(float dt)`,
  `onEnable()`, `onDisable()`, `onDestroy()` (behaviors), `onStop()` (levels).
  Scripts update before the systems that act on what they write (the navigation crowd,
  animation), so a destination or a graph parameter set in `onUpdate` takes effect this frame;
  positions read there are where those systems left things last frame. So a speed is not a
  moved position over `dt`: that move was made last frame, with last frame's time, and on uneven
  frames the quotient swings (a navigation agent's speed fed to its graph jerks its walk). Read
  the speed the system reports, a navigation agent's `DesiredVelocity` say. A scene's Level
  script updates before its entities' behaviors.
- The game: `launch()`, `update(float dt)`, `exit()`.
- `on<Event>(...)`: named events. Physics contacts arrive as events; any script can send one:
  `scene.Scripts.Send(entity, "Name", payload)` to one entity's behaviors, and
  `scene.Scripts.Emit("Name", payload)` or `Run.Emit(...)` to everyone listening. In a game run
  the scene's event bus IS the run's bus: one bus per run, heard by every behaviour, each Level
  and the Game. Emit an event once; emitting it through both calls delivers it twice. A payload
  is a float, an int, a bool, a string, an entity, a `Float3` (a lock's place) or a `Float4` (a
  place and a measure together: a noise's origin and its loudness), and the handler takes it by
  value: `void onPicking(Float3 at)`, `void onNoise(Float4 n)`.
- Networked entities: gate on `NetworkComponent::of(self).Authority` (`NetworkAuthority::Server` or
  `Client`): the owning side drives, the rest interpolate. It reads; replication owns the
  identity, so nothing on it is assignable from a script.

## The engine from a script

Engine verbs live on facades, in script shape: `scene.Physics.RayCast(...)`,
`scene.Audio.Play(...)`, `scene.Render`, `scene.Animation`, `scene.Particles`,
`scene.Splines`, `scene.Prefabs.Spawn(...)`, `scene.Debug`; the services `Audio`, `Input`,
`Save`, `Ui`, `Run`, `Random`; and the globals `Print`, `PrintWarning`, `PrintError` with the math
free functions. `script_api` lists exactly what each one binds.

`Input.Rumble(low, high, seconds)` runs the gamepad's two motors, `low` the heavy one and
`high` the light one, each 0 to 1 (a crash 0.8, 0.4, 0.25; a footstep 0, 0.2, 0.05);
`Input.Rumble(gamepad, low, high, seconds)` picks the pad, and `Input.StopRumble()` stops them
all. It reaches only the calling run's pad (a Game tab's, the player's), and the run's end
stops it.

An input map's sets switch from a script: `Input.PushSet("Menu")` makes that set modal, so only
its actions read while a menu is up and gameplay hears nothing, and `Input.PopSet()` takes it off
again. What is held across either needs a fresh press, so a held Jump neither confirms the menu
that opened nor fires as it closes. `Input.EnableSet(name, enabled)` turns a set on or off
outside that stack.

`Audio` plays a clip or a cue by its asset id (`Audio.PlayOneShot(id)`, `PlayCue`, `PlayMusic`),
or by its content path as the project names it: `Audio.PlayOneShotPath("Audio/Jump")`,
`PlayOneShot3DPath(path, position)`, `PlayCuePath(path)`, `PlayMusicPath(path, fadeSeconds)`. A
path resolves by type, a cue to one of its variants; a path that names nothing plays nothing
and does not fault. A bus is named as a settings screen names it: `SetNamedBusVolume("music",
0.5)`, `SetNamedBusMuted`, `NamedBusVolume`, `NamedBusMuted` take the four fixed buses (master,
effects, music, ui, any case) and the bus layout's own named buses; an unknown bus reads full
volume and unmuted.

An entity's place, turn and size in the world, every ancestor's included, are
`entity.GetWorldPosition()`, `GetWorldRotation()` and `GetWorldScale()` (identity and one for an
invalid entity); `GetLocalTransform()` is its own. A lantern on a guard aims along
`RotateVector(lantern.GetWorldRotation(), Float3(0, 0, -1))` whatever the guard's parent is.

A world-space UI component (`UICanvasComponent`, `UIBillboardComponent`,
`UIWorldPanelComponent`) hands a script its instantiated tree as `Root`, the same
`ViewGroup` handle `Ui.Root` gives the screen tier, so the same finders reach inside it: a meter
over a guard's head is `UIBillboardComponent::of(guard).Root.FindProgressBar("meter")`. Before
the tree is built the handle is null but valid, and every finder misses quietly.

`scene.Physics.RayCast(...)` answers a `PhysicsHit`: whether it hit, the entity, the distance,
position and normal, the struck face's `Surface` slot on a cooked mesh, and the `Material` of the
struck body (its rigid body's physical material, nil without one): what is underfoot, for a
step's sound.

A body's motion from a script: `scene.Physics.ApplyImpulse(entity, impulse)` for a kick,
`SetVelocity(entity, velocity)` to set its speed now (a launch, a dash, a stop) and `Velocity(entity)`
to read it, and `SetForce(entity, force)` for a steady push in newtons: thrust, wind. A force is
held, added before every physics step until set again (zero lets go), so it acts the same at any
frame rate; a push repeated each frame would not. An impulse or a velocity given to a body
spawned this frame waits for its body to be built.

`scene.Render.LightAt(position)` answers how much light reaches a place, linear RGB: every
enabled light by the renderer's own range falloff and spot cone, plus the environment's
ambient. A light that casts shadows is stopped by what stands between (a ray through the
scene's solid surfaces; `LightAt(position, groupMask)` picks the collision groups), by its
shadow strength; one without shadows shines through walls, as it does on screen. It is a CPU
estimate for a light meter or a guard's eye, not a read of the frame (the sky's image-based
light is not in it). Ask from a point off any surface, a character's chest say: a ray that
starts inside a wall is stopped by it.

`scene.Render.SetMaterialFloat(entity, slot, name, value)` and `SetMaterialFloat4(...)` set one
of a mesh's material properties for it alone: a glow, a tint, a flash, or a value faded over
time, every other mesh using that material unchanged. The name is the property's as the
material editor shows it (`Roughness`, `BaseColor`, `EmissiveColor`), the slot the mesh's
material slot (0 for a single material). A colour goes as authored, sRGB rgba, and an HDR
colour (`EmissiveColor`) sRGB rgb with its intensity in w. `ClearMaterialProperty(entity, slot,
name)` puts it back to the material's own value. They are runtime state, not saved with the
scene; a name the material does not have, or a value wider than the property, changes
nothing. Such a mesh draws on its own rather than batched with its twins, so set them on the
few meshes that need them.

The scene's environment and post processing are a script's to tune live:
`scene.Render.GetEnvironment()` gives the ambient, sky, fog and shadow settings in effect, and
`SetEnvironment(settings)` puts them back; `GetPostProcess()` / `SetPostProcess(settings)` do the
same for exposure, tonemapping, bloom and anti aliasing. Read, change, set:
`EnvironmentSettings env = scene.Render.GetEnvironment(); env.AmbientIntensity = 0.2f;
scene.Render.SetEnvironment(env);`. While the scene uses a profile the edit changes the profile,
so every scene using it changes too, as an edit in the editor does. A script sets values, not
assets: the profile and the sky texture keep theirs. Runtime only, not saved with the scene.

Components are script types too, as data with a few verbs: a script takes a handle to one
from an entity, `CharacterComponent@ character = CharacterComponent::of(self);`, then reads
and sets its fields and calls its verbs (`character.Move(vx, vz)`, `character.Jump(speed)`).
`of` is null when the entity has no such component, so `if (character !is null)` is the test.
The handle holds the entity, so it reaches the component the entity has now. A handle kept
after its component has gone answers `IsValid` false; any other use fails the handler with
"the object is gone". An asset field takes the asset's guid (`sprite.TextureAsset`).
Components with nothing for gameplay code are not script types: the script component itself
(use `scene.Scripts`), the networked transform (replication drives it), and a navigation
zone's bake settings. A network identity is one, read only. A navigation agent reports why it
is or is not moving, read only: `CrowdState` (walking, off the mesh, or not in a crowd),
`CrowdTargetState` (where its move request has got to: requesting, valid, failed),
`CrowdDesiredSpeed`, and `PathCorners`, the corners left on its path.

The facades are the stable verbs and the first place to look; a component is the direct route
to its data. `script_api` lists both.

## Networking

The `Net` service is the run's networking. A game's menu hosts with `Net.StartServer(port)`
(or `Net.StartDedicatedServer(port)`, which does not play), joins with
`Net.Connect(host, port)` and leaves with `Net.Disconnect()`; `Net.IsServer`, `Net.IsClient`,
`Net.PeerCount`, `Net.NetworkTick` and `Net.NetworkTimeMs` say where it stands. A web build
joins the same port: the host opens a browser gateway one port above it. Messages go by
name: `Net.Rpc("ready")`, `Net.RpcNumber("score", 12)` or `Net.RpcText("chat", "hi")` from a
client reach the host, and from the host every client. A script receives one with
`Net.On("ready", NetHandler(this.onReady))`, `Net.OnNumber("score", NetNumberHandler(this.onScore))`
or `Net.OnText("chat", NetTextHandler(this.onChat))`: the handler gets the sender's id first
(on the host the client that sent it, on a client the host), then the number or the text.
Register before hosting or joining too; a later registration of a name replaces it, and a
message of another kind than its handler takes is dropped. The host puts a networked prefab
into the game with `Net.Spawn(prefab, position)`: it spawns in the replicated scene with a
network id, so every client builds its own copy (a player who joins later too); the prefab's
root needs a networked transform for its movement to follow. A client's call spawns nothing.
Players are named by id: nought is the host, a client the id the host's welcome gives it.
`Net.LocalPlayer` is this game's own (-1 offline, or on a client before the welcome);
`Net.OnJoin(NetHandler(this.onJoin))` and `Net.OnLeave(...)` hear players come and go (on a
client, its own join once welcomed, and the host leaving as player nought). The host sends to
one player with `Net.RpcTo`, `Net.RpcNumberTo` and `Net.RpcTextTo`, and spawns a prefab a
player owns with `Net.SpawnFor(player, prefab, position)`; `Net.IsMine(entity)` says whether
an entity is this game's own. On a client every message's sender is the host, nought.
Offline every call does nothing.

## Saving

The `Save` service keeps values between runs: a best time, a high score, an unlocked level, the
game's own options. Values are typed (int, float, bool, string, a list of floats) and keyed by any string you
choose:

```
Save.SetInt("best.level2", 4210);
int best = Save.GetInt("best.level2", 0);   // the fallback when there is none yet
```

- `Has`, `Remove` and `Clear` do what they say. A value read as another kind than it was
  written answers the fallback, except that an int reads as a float.
- A list of numbers (a recorded run, a ghost) is saved and read whole:
  `Save.SetFloats("ghost.Course1", samples)` and `Save.GetFloats("ghost.Course1", samples)`,
  which fills the array and answers false, leaving it empty, when there is no list under that
  key. A list does not read as a number through `GetFloat`.
- The run writes what changed when it ends. Call `Save.Flush()` at the moment that matters (a
  level clear, leaving a settings screen) so a crash or a forced quit loses nothing.
- The player keeps the file, `<project>.save.xml`, in the user's data directory; a Game tab
  keeps its own in the project's ignored `Editor/` folder, so testing never touches a
  player's save.
- The audio bus volumes a settings screen sets are saved by the player on its own; a game
  does not need to save them.

## Editor properties

A property is a field with an annotation, `[default, "description"]` in front of its
declaration; a field without one is plain state, whatever its access. The editor shows each
property with its description as the tooltip and saves per instance values over the default.

```
[4.0, "Units per second"]            float speed;
[3, "Lives at the start"]            int lives;
[true]                               bool armed;
["Hero", "Shown over the head"]      string title;
[(1, 0, 0, 1)]                       Color tint;
[(0, 1.5, 0), "Where to aim"]        Float3 aimOffset;
[null, "What to follow"]             Entity target;
["asset:AudioClip", "Played on a hit"] Guid hitSound;
```

- The first token is the default: a number, `true` or `false`, a quoted string, a
  `(r, g, b[, a])` or `(x, y, z)` list, or `null`. A quoted second token is the description.
- Types: float, int, bool, string, Color, Float3, Entity, and Guid tagged `"asset:<Type>"`
  for a reference to an asset of that type. An annotated field of any other type fails the
  cook, naming the field.
- The annotation's default is what applies, so leave the field without an initialiser.
- A bare `replicated` after the default and description keeps the property the same on
  every peer of a networked game: `[0, "What the guest is doing", replicated] int activity;`.
  The host sends a networked entity's live value and clients write it in. Any other bare
  word fails the cook, as does a replicated Entity or asset reference (it means nothing on
  another machine).

## Working through the MCP tools

- `script_api`: the live bound API. Read it before writing code.
- `script_create` seeds the tier's starter; `script_validate` is the loop; scripts are
  project assets, imported and cooked like any other (see Assets.md).
- Coroutines: a handler may `yield()` and continue on a later tick.

## Gotchas

- The class names `Game` and `Level` are reserved for their tiers; do not use them for a
  behavior.
- `script_validate` compiles; it does not run. A global variable's initialiser does run
  whenever the module builds, cook time included, so keep it to plain values.
- A plain field is not a property: if the inspector does not show a field, it has no
  annotation.
- Some engine fields are read only on purpose (a network identity's `Authority` and `Id`):
  a script reads them, and an assignment fails to compile, since no setter exists.
