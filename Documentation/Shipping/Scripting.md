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

## Lifecycle and events

Handlers dispatch **by presence**: implement only what you need.

- Behaviors and levels: `onStart()`, `onUpdate(float dt)`, `onFixedUpdate(float dt)`,
  `onEnable()`, `onDisable()`, `onDestroy()` (behaviors), `onStop()` (levels).
- The game: `launch()`, `update(float dt)`, `exit()`.
- `on<Event>(...)`: named events. Physics contacts arrive as events; any script can send one:
  `scene.Scripts.Send(entity, "Name", payload)` to one entity's behaviors, and
  `scene.Scripts.Emit("Name", payload)` or `Run.Emit(...)` to everyone listening. In a game run
  the scene's event bus IS the run's bus: one bus per run, heard by every behaviour, each Level
  and the Game. Emit an event once; emitting it through both calls delivers it twice. A payload
  is a float, an int, a bool, a string, an entity or a `Float3` (a lock's place, a noise's
  origin), and the handler takes it by value: `void onPicking(Float3 at)`.
- Networked entities: gate on `NetworkComponent(self).Authority` (`NetworkAuthority::Server` or
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

`scene.Physics.RayCast(...)` answers a `PhysicsHit`: whether it hit, the entity, the distance,
position and normal, the struck face's `Surface` slot on a cooked mesh, and the `Material` of the
struck body (its rigid body's physical material, nil without one): what is underfoot, for a
step's sound.

`scene.Render.LightAt(position)` answers how much light reaches a place, linear RGB: every
enabled light by the renderer's own range falloff and spot cone, plus the environment's
ambient. A light that casts shadows is stopped by what stands between (a ray through the
scene's solid surfaces; `LightAt(position, groupMask)` picks the collision groups), by its
shadow strength; one without shadows shines through walls, as it does on screen. It is a CPU
estimate for a light meter or a guard's eye, not a read of the frame (the sky's image-based
light is not in it). Ask from a point off any surface, a character's chest say: a ray that
starts inside a wall is stopped by it.

Components are script types too, as data with a few verbs: a script takes one from an
entity, `CharacterComponent character = CharacterComponent(self);`, then reads and sets its
fields and calls its verbs (`character.Move(vx, vz)`, `character.Jump(speed)`). The handle is
the entity, so it always reaches the component the entity has now; on an entity without one,
the access fails the handler. An asset field takes the asset's guid (`sprite.TextureAsset`).
Components with nothing for gameplay code are not script types: the script component itself
(use `scene.Scripts`), the networked transform (replication drives it), and a navigation
zone's bake settings. A network identity is one, read only.

The facades are the stable verbs and the first place to look; a component is the direct route
to its data. `script_api` lists both.

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
