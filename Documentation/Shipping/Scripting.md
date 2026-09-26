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
  and the Game. Emit an event once; emitting it through both calls delivers it twice.

## The engine from a script

Engine verbs live on facades, in script shape: `scene.Physics.RayCast(...)`,
`scene.Audio.Play(...)`, `scene.Render`, `scene.Animation`, `scene.Particles`,
`scene.Splines`, `scene.Prefabs.Spawn(...)`, `scene.Debug`; the services `Audio`, `Input`,
`Ui`, `Run`, `Random`; and the globals `Print`, `PrintWarning`, `PrintError` with the math
free functions. `script_api` lists exactly what each one binds.

Components are script types too, as data with a few verbs: a script takes one from an
entity, `CharacterComponent character = CharacterComponent(self);`, then reads and sets its
fields and calls its verbs (`character.Move(vx, vz)`, `character.Jump(speed)`). The handle is
the entity, so it always reaches the component the entity has now; on an entity without one,
the access fails the handler. An asset field takes the asset's guid (`sprite.TextureAsset`).
Components with nothing for gameplay code are not script types: the script component itself
(use `scene.Scripts`), the replication components, and a navigation zone's bake settings.

The facades are the stable verbs and the first place to look; a component is the direct route
to its data. `script_api` lists both.

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
