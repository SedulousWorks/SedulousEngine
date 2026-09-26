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
  `scene.Scripts.Send(entity, "Name", payload)` to one entity's behaviors,
  `scene.Scripts.Emit("Name", payload)` to the whole scene and its Level, `Run.Emit` to the
  game.

## The engine from a script

Engine verbs live on facades, in script shape: `scene.Physics.RayCast(...)`,
`scene.Audio.Play(...)`, `scene.Render`, `scene.Animation`, `scene.Particles`,
`scene.Splines`, `scene.Prefabs.Spawn(...)`, `scene.Debug`; the services `Audio`, `Input`,
`Ui`, `Run`, `Random`; and the globals `Print`, `PrintWarning`, `PrintError` with the math
free functions. `script_api` lists exactly what each one binds.

Components are not script types: a script reaches one through the facade that fronts it,
passing the entity. A character controller, for instance, is driven with
`scene.Physics.MoveCharacter(self, vx, vz)`, `JumpCharacter`, `SetCharacterPosition` and
`IsCharacterGrounded`.

## Editor properties

Public fields of the authored kinds (float, int, bool, string, Float3, Color, asset
references) are the class's properties, harvested at cook time and editable per instance.
Keep field initialisers to plain values: they run during cooking too.

## Working through the MCP tools

- `script_api`: the live bound API. Read it before writing code.
- `script_create` seeds the tier's starter; `script_validate` is the loop; scripts are
  project assets, imported and cooked like any other (see Assets.md).
- Coroutines: a handler may `yield()` and continue on a later tick.

## Gotchas

- The class names `Game` and `Level` are reserved for their tiers; do not use them for a
  behavior.
- `script_validate` compiles; it does not run. A field initialiser with side effects
  misbehaves at cook time.
